extends GutTest

# Base comum dos testes de integração incrementais (bottom-up).
#
# Os módulos são grupos de funções dos scripts do jogo:
#
#   ENGINE (Scripts/chess.gd)
#   M1  Estado do tabuleiro    board, _ready, is_valid_position, is_empty, is_enemy
#   M2  Geração de movimentos  get_pawn_moves, get_rook_moves, ..., get_king_moves
#   M3  Validação de regras    is_square_attacked, is_in_check, leaves_king_in_check
#   M4  Execução da jogada     set_move, roque, en passant, promote, contador de 50 lances
#   M5  Estado da partida      has_any_legal_move, check_game_state, empates
#   M6  Inteligência artificial trigger_ai_turn, minimax, make/undo_simulated_move
#
#   INTERFACE
#   M7  Renderização e som     display_board, show_options/show_dots, turno, play_move_sound
#   M8  Entrada do jogador     _input, local_to_board_position
#   M9  Promoção (UI)          botões de promoção, _on_button_pressed
#   M10 Menu principal         Scripts/main_menu.gd, Scenes/MainMenu.tscn
#
# Cada arquivo test_incN integra um módulo novo aos já testados.
# O próprio teste funciona como driver: chama o módulo mais alto do incremento.
#
# Este arquivo não começa com "test_", então o GUT não o executa sozinho.

const MAIN_SCENE = preload("res://Scenes/main.tscn")

var tela_jogo: SubViewport
var partida: Node2D
var tabuleiro: Sprite2D


# O jogo roda dentro de um SubViewport para que os cliques simulados
# funcionem também no modo headless (CI).
# A IA começa desligada para o teste controlar os dois lados;
# os testes de IA ligam com ligar_ia().
func before_each():
	tela_jogo = SubViewport.new()
	tela_jogo.size = Vector2i(1280, 720)
	add_child_autofree(tela_jogo)

	partida = MAIN_SCENE.instantiate()
	tabuleiro = partida.get_node("Camera2D/board")
	tabuleiro.vs_ai = false
	tela_jogo.add_child(partida)

	await get_tree().process_frame


# ============================================================
# POSIÇÕES
# ============================================================

# Converte a notação do xadrez ("e2") para (linha, coluna) do array.
func casa(nome: String) -> Vector2:
	var coluna = nome.unicode_at(0) - "a".unicode_at(0)
	var linha = 8 - int(nome.substr(1, 1))
	return Vector2(linha, coluna)


# Converte (linha, coluna) de volta para a notação do xadrez.
func nome_da_casa(pos: Vector2) -> String:
	return char("a".unicode_at(0) + int(pos.y)) + str(8 - int(pos.x))


# Converte uma lista de Vector2 em nomes de casas ordenados.
func nomes(lista: Array) -> Array:
	var resultado = []
	for pos in lista:
		resultado.append(nome_da_casa(pos))
	resultado.sort()
	return resultado


func colocar(nome: String, peca: int):
	var c = casa(nome)
	tabuleiro.board[c.x][c.y] = peca


func peca_em(nome: String) -> int:
	var c = casa(nome)
	return tabuleiro.board[c.x][c.y]


func contar_pecas() -> int:
	var total = 0
	for linha in range(8):
		for coluna in range(8):
			if tabuleiro.board[linha][coluna] != 0:
				total += 1
	return total


# Esvazia o tabuleiro, com as brancas jogando.
# Em posições montadas os reis não estão nas casas iniciais,
# então o roque começa desabilitado; os testes de roque usam liberar_roque().
func limpar_tabuleiro():
	for linha in range(8):
		for coluna in range(8):
			tabuleiro.board[linha][coluna] = 0

	tabuleiro.white = true
	tabuleiro.en_passant = Vector2(-1, -1)
	tabuleiro.w_king_moved = true
	tabuleiro.b_king_moved = true
	tabuleiro.game_over = false
	tabuleiro.fifty_move_rule = 0
	tabuleiro.unique_board_moves.clear()
	tabuleiro.amount_of_same.clear()


# Reabilita o roque de cada lado cujo rei está na casa inicial.
# (O jogo supõe que, se o rei "não se moveu", ele está em e1/e8.)
func liberar_roque():
	if peca_em("e1") == 6:
		tabuleiro.w_king_moved = false
		tabuleiro.w_rook_left_moved = false
		tabuleiro.w_rook_right_moved = false

	if peca_em("e8") == -6:
		tabuleiro.b_king_moved = false
		tabuleiro.b_rook_left_moved = false
		tabuleiro.b_rook_right_moved = false


# Movimentos legais (já filtrados) da peça em uma casa.
func movimentos_de(nome: String) -> Array:
	tabuleiro.selected_piece = casa(nome)
	return nomes(tabuleiro.get_moves())


# ============================================================
# DRIVERS
# ============================================================

# Driver de M4: escolhe a peça, calcula os movimentos legais e executa.
# Não passa por show_options (M7) nem por cliques (M8).
# Se o lance do teste for ilegal, o teste falha (a não ser que seja de propósito).
func executar(de: String, para: String, deve_ser_legal: bool = true):
	var origem = casa(de)
	var destino = casa(para)

	tabuleiro.selected_piece = origem
	tabuleiro.moves = tabuleiro.get_moves()

	if deve_ser_legal:
		assert_has(nomes(tabuleiro.moves), para, "O lance " + de + para + " do teste deveria ser legal.")
	tabuleiro.state = true
	tabuleiro.set_move(int(destino.x), int(destino.y))


# Executa uma lista de lances no formato "e2e4".
func executar_lances(lances: String):
	for lance in lances.split(" ", false):
		executar(lance.substr(0, 2), lance.substr(2, 2))


# Escolhe a peça da promoção pendente pelo próprio botão da cena (M9).
func escolher_promocao(peca: int):
	var grupo = "CanvasLayer/white_pieces/" if tabuleiro.white else "CanvasLayer/black_pieces/"
	tabuleiro._on_button_pressed(partida.get_node(grupo + str(peca)))


# ============================================================
# INTELIGÊNCIA ARTIFICIAL (M6)
# ============================================================

func ligar_ia(profundidade: int = 1):
	tabuleiro.vs_ai = true
	tabuleiro.ai_plays_white = false
	tabuleiro.ai_search_depth = profundidade


# Espera a IA terminar a jogada (ela aguarda 0,4 s antes de jogar).
func esperar_ia(limite_segundos: float = 10.0):
	var inicio = Time.get_ticks_msec()

	await get_tree().process_frame
	while tabuleiro.ai_thinking and Time.get_ticks_msec() - inicio < limite_segundos * 1000:
		await get_tree().process_frame


# ============================================================
# TELA E SOM (M7)
# ============================================================

# Textura desenhada na casa (null se vazia).
func peca_na_tela(nome: String):
	var c = casa(nome)
	var posicao = tabuleiro.board_to_local_position(int(c.x), int(c.y))

	for holder in tabuleiro.pieces.get_children():
		if not holder.is_queued_for_deletion() and holder.position == posicao:
			return holder.texture

	return null


# Casas onde aparecem os pontos de movimento.
func pontos_na_tela() -> Array:
	var casas = []

	for ponto in tabuleiro.dots.get_children():
		if ponto.is_queued_for_deletion():
			continue

		for linha in range(8):
			for coluna in range(8):
				if ponto.position == tabuleiro.board_to_local_position(linha, coluna):
					casas.append(nome_da_casa(Vector2(linha, coluna)))

	casas.sort()
	return casas


# Textura que deveria aparecer para cada valor do array board.
func textura_esperada(valor: int):
	match valor:
		-6: return tabuleiro.BLACK_KING
		-5: return tabuleiro.BLACK_QUEEN
		-4: return tabuleiro.BLACK_ROOK
		-3: return tabuleiro.BLACK_BISHOP
		-2: return tabuleiro.BLACK_KNIGHT
		-1: return tabuleiro.BLACK_PAWN
		1: return tabuleiro.WHITE_PAWN
		2: return tabuleiro.WHITE_KNIGHT
		3: return tabuleiro.WHITE_BISHOP
		4: return tabuleiro.WHITE_ROOK
		5: return tabuleiro.WHITE_QUEEN
		6: return tabuleiro.WHITE_KING
	return null


# Lista as casas em que a tela não bate com o array board.
func diferencas_tela_e_tabuleiro() -> Array:
	var diferencas = []

	for linha in range(8):
		for coluna in range(8):
			var nome = nome_da_casa(Vector2(linha, coluna))
			if peca_na_tela(nome) != textura_esperada(tabuleiro.board[linha][coluna]):
				diferencas.append(nome)

	return diferencas


# Som tocado na última jogada.
func som_tocado():
	return tabuleiro.move_audio_player.stream


# ============================================================
# CLIQUES (M8, M9)
# ============================================================

func posicao_na_tela(nome: String) -> Vector2:
	var c = casa(nome)
	var local = tabuleiro.board_to_local_position(int(c.x), int(c.y))
	return tela_jogo.get_canvas_transform() * tabuleiro.to_global(local)


func clicar_na_tela(posicao: Vector2, botao_mouse: int = MOUSE_BUTTON_LEFT):
	var movimento = InputEventMouseMotion.new()
	movimento.position = posicao
	movimento.global_position = posicao
	tela_jogo.push_input(movimento)

	var clique = InputEventMouseButton.new()
	clique.button_index = botao_mouse
	clique.pressed = true
	clique.position = posicao
	clique.global_position = posicao
	tela_jogo.push_input(clique)

	var soltar = clique.duplicate()
	soltar.pressed = false
	tela_jogo.push_input(soltar)

	await get_tree().process_frame


func clicar(nome: String, botao_mouse: int = MOUSE_BUTTON_LEFT):
	await clicar_na_tela(posicao_na_tela(nome), botao_mouse)


func jogar(de: String, para: String):
	await clicar(de)
	await clicar(para)


# Joga uma lista de lances por cliques, no formato "e2e4".
func jogar_lances(lances: String):
	for lance in lances.split(" ", false):
		await jogar(lance.substr(0, 2), lance.substr(2, 2))


func clicar_no_botao(botao: Button):
	var centro = botao.get_global_transform_with_canvas() * (botao.size / 2)
	await clicar_na_tela(centro)
