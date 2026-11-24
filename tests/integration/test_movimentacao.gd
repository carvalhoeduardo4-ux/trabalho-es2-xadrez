
extends GutTest

const MAIN_SCENE = preload("res://Scenes/main.tscn")

var partida: Node2D
var tabuleiro: Sprite2D


func before_each():
	partida = MAIN_SCENE.instantiate()
	add_child_autofree(partida)

	tabuleiro = partida.get_node("Camera2D/board")


func test_movimento_peao_atualiza_tabuleiro_e_turno():
	# O peão branco começa em e2.
	assert_eq(tabuleiro.board[6][4], 1)
	assert_true(tabuleiro.white)

	# Seleciona o peão e calcula seus movimentos.
	tabuleiro.selected_piece = Vector2(6, 4)
	tabuleiro.show_options()

	# Verifica se e4 é um destino permitido.
	assert_has(tabuleiro.moves, Vector2(4, 4))

	# Executa o movimento pela lógica do jogo.
	tabuleiro.set_move(4, 4)

	# Verifica a atualização do estado do tabuleiro.
	assert_eq(tabuleiro.board[4][4], 1,
		"O peão deve estar em e4.")

	assert_eq(tabuleiro.board[6][4], 0,
		"A posição e2 deve ficar vazia.")

	# Verifica a alternância de turno.
	assert_false(tabuleiro.white,
		"Agora deve ser a vez das pretas.")

	# Verifica a integração com a interface visual.
	assert_eq(tabuleiro.turn.texture,
		tabuleiro.TURN_BLACK,
		"O indicador visual deve mostrar o turno preto.")


func test_captura_peao_atualiza_tabuleiro_e_turno():
	# 1. Peão branco: e2 -> e4
	tabuleiro.selected_piece = Vector2(6, 4)
	tabuleiro.show_options()
	assert_has(tabuleiro.moves, Vector2(4, 4))
	tabuleiro.set_move(4, 4)

	# 2. Peão preto: d7 -> d5
	tabuleiro.selected_piece = Vector2(1, 3)
	tabuleiro.show_options()
	assert_has(tabuleiro.moves, Vector2(3, 3))
	tabuleiro.set_move(3, 3)

	# Confirma que o peão preto está em d5.
	assert_eq(tabuleiro.board[3][3], -1)

	# 3. Peão branco: e4 captura d5
	tabuleiro.selected_piece = Vector2(4, 4)
	tabuleiro.show_options()

	assert_has(
		tabuleiro.moves,
		Vector2(3, 3),
        "A captura diagonal deve ser permitida."
	)

	tabuleiro.set_move(3, 3)

	# A posição d5 deve conter o peão branco.
	assert_eq(
		tabuleiro.board[3][3], 1,
        "O peão branco deve ocupar d5."
	)

	# A posição e4 deve ficar vazia.
	assert_eq(
		tabuleiro.board[4][4], 0,
        "A posição e4 deve ficar vazia."
	)

	# O turno deve passar para as pretas.
	assert_false(
		tabuleiro.white,
        "O turno deve ser das pretas."
	)

	# A interface deve acompanhar a mudança.
	assert_eq(
		tabuleiro.turn.texture,
		tabuleiro.TURN_BLACK,
        "O indicador deve mostrar o turno preto."
	)
	

func test_movimento_invalido_nao_altera_partida():
	# Seleciona o peão branco em e2.
	tabuleiro.selected_piece = Vector2(6, 4)
	tabuleiro.show_options()

	# e5 não é um destino válido para esse peão.
	assert_does_not_have(
		tabuleiro.moves,
		Vector2(3, 4),
        "O peão não pode avançar três casas."
	)

	# Tenta executar o movimento inválido.
	tabuleiro.set_move(3, 4)

	# O peão deve continuar em e2.
	assert_eq(
		tabuleiro.board[6][4], 1,
        "O peão deve permanecer em e2."
	)

	# A posição e5 deve continuar vazia.
	assert_eq(
		tabuleiro.board[3][4], 0,
        "O destino inválido deve continuar vazio."
	)

	# O turno deve continuar sendo das brancas.
	assert_true(
		tabuleiro.white,
        "Uma jogada inválida não deve alterar o turno."
	)

	# O indicador visual deve permanecer branco.
	assert_eq(
		tabuleiro.turn.texture,
		tabuleiro.TURN_WHITE
	)
	

func test_torre_captura_peca_adversaria():
	# Configura um tabuleiro vazio.
	for linha in range(8):
		for coluna in range(8):
			tabuleiro.board[linha][coluna] = 0

	# Torre branca em a1.
	tabuleiro.board[7][0] = 4

	# Cavalo preto em a5.
	tabuleiro.board[3][0] = -2

	tabuleiro.white = true
	tabuleiro.display_board()

	# Seleciona a torre.
	tabuleiro.selected_piece = Vector2(7, 0)
	tabuleiro.show_options()

	# Verifica se a captura é permitida.
	assert_has(
		tabuleiro.moves,
		Vector2(3, 0),
        "A torre deve poder capturar o cavalo."
	)

	# Executa a captura.
	tabuleiro.set_move(3, 0)

	# A torre deve ocupar a posição capturada.
	assert_eq(
		tabuleiro.board[3][0], 4,
        "A torre deve ocupar a5."
	)

	# A posição original deve ficar vazia.
	assert_eq(
		tabuleiro.board[7][0], 0,
        "A posição a1 deve ficar vazia."
	)

	# O turno deve mudar.
	assert_false(
		tabuleiro.white,
        "O turno deve passar para as pretas."
	)

	# O indicador visual deve ser atualizado.
	assert_eq(
		tabuleiro.turn.texture,
		tabuleiro.TURN_BLACK
	)
