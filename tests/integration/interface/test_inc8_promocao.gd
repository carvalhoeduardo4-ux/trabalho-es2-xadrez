extends "res://tests/integration/base_integracao.gd"

# INTERFACE · INCREMENTO 8: engine + M7 + M8 + M9 (promoção pela interface)
#
# Verifica a promoção do começo ao fim pela interface: o peão chega na última
# fileira por cliques, aparecem os botões da cor certa, o tabuleiro fica
# bloqueado, o clique no botão cria a peça escolhida, e o resto do jogo
# (tela, som, turno, fim de partida e IA) reage à escolha.


var botoes_brancos: Control
var botoes_pretos: Control


func before_each():
	await super()
	botoes_brancos = partida.get_node("CanvasLayer/white_pieces")
	botoes_pretos = partida.get_node("CanvasLayer/black_pieces")


# Peão branco em a7 pronto para promover, reis longe.
func preparar_promocao_branca():
	limpar_tabuleiro()
	colocar("a7", 1)
	colocar("e1", 6)
	colocar("h5", -6)
	tabuleiro.display_board()


func test_botoes_das_brancas_aparecem_na_promocao_das_brancas():
	preparar_promocao_branca()
	assert_false(botoes_brancos.visible, "Antes da promoção os botões estão escondidos.")

	await jogar("a7", "a8")

	assert_true(botoes_brancos.visible, "Os botões das brancas aparecem.")
	assert_false(botoes_pretos.visible, "Os botões das pretas não aparecem.")


func test_botoes_das_pretas_aparecem_na_promocao_das_pretas():
	limpar_tabuleiro()
	tabuleiro.white = false
	colocar("b2", -1)
	colocar("h4", 6)
	colocar("a8", -6)
	tabuleiro.display_board()

	await jogar("b2", "b1")

	assert_true(botoes_pretos.visible, "Os botões das pretas aparecem.")
	assert_false(botoes_brancos.visible)


func test_tabuleiro_ignora_cliques_durante_a_promocao():
	preparar_promocao_branca()
	await jogar("a7", "a8")

	await clicar("e1")

	assert_eq(pontos_na_tela(), [], "O rei não pode ser selecionado enquanto a escolha está aberta.")
	assert_true(tabuleiro.white, "O turno não muda antes da escolha.")


# [peça, textura]
var escolhas = [
	[5, "WHITE_QUEEN"],
	[4, "WHITE_ROOK"],
	[3, "WHITE_BISHOP"],
	[2, "WHITE_KNIGHT"],
]


func test_cada_botao_cria_a_peca_escolhida(p = use_parameters(escolhas)):
	preparar_promocao_branca()
	await jogar("a7", "a8")

	await clicar_no_botao(botoes_brancos.get_node(str(p[0])))

	assert_eq(peca_em("a8"), p[0], "O peão vira a peça " + str(p[0]) + ".")
	assert_eq(peca_na_tela("a8"), tabuleiro.get(p[1]), "A tela mostra a peça escolhida.")
	assert_false(botoes_brancos.visible, "Os botões somem.")
	assert_false(tabuleiro.white, "A vez passa para as pretas.")
	assert_eq(tabuleiro.turn.texture, tabuleiro.TURN_BLACK)
	assert_null(tabuleiro.promotion_square)


func test_botao_das_pretas_cria_peca_preta():
	limpar_tabuleiro()
	tabuleiro.white = false
	colocar("b2", -1)
	colocar("h4", 6)
	colocar("a8", -6)
	tabuleiro.display_board()

	await jogar("b2", "b1")
	await clicar_no_botao(botoes_pretos.get_node("2"))

	assert_eq(peca_em("b1"), -2, "O peão preto vira cavalo preto.")
	assert_eq(peca_na_tela("b1"), tabuleiro.BLACK_KNIGHT)
	assert_true(tabuleiro.white)


func test_promocao_com_captura_toca_som_de_captura():
	limpar_tabuleiro()
	colocar("b7", 1)
	colocar("a8", -4)
	colocar("e1", 6)
	colocar("h5", -6)
	tabuleiro.display_board()

	await jogar("b7", "a8")
	await clicar_no_botao(botoes_brancos.get_node("5"))

	assert_eq(peca_em("a8"), 5, "O peão captura a torre e vira rainha.")
	assert_eq(som_tocado(), tabuleiro.CAPTURE_SOUND)


func test_promocao_sem_captura_toca_som_de_movimento():
	preparar_promocao_branca()
	await jogar("a7", "a8")
	await clicar_no_botao(botoes_brancos.get_node("5"))

	assert_eq(som_tocado(), tabuleiro.MOVE_SOUND)


func test_promocao_zera_o_contador_de_50_lances():
	preparar_promocao_branca()
	tabuleiro.fifty_move_rule = 30

	await jogar("a7", "a8")
	await clicar_no_botao(botoes_brancos.get_node("4"))

	assert_eq(tabuleiro.fifty_move_rule, 0)


func test_escolha_da_peca_decide_se_ha_xeque_mate():
	# Rainha em a8 dá mate; cavalo em a8 não.
	# O peão em b2 evita que rei e cavalo contra rei vire empate por material.
	for peca in [5, 2]:
		limpar_tabuleiro()
		colocar("a7", 1)
		colocar("b2", 1)
		colocar("g6", 6)
		colocar("h8", -6)
		tabuleiro.display_board()

		await jogar("a7", "a8")
		await clicar_no_botao(botoes_brancos.get_node(str(peca)))

		if peca == 5:
			assert_true(tabuleiro.game_over, "A rainha em a8 dá xeque-mate.")
		else:
			assert_false(tabuleiro.game_over, "O cavalo em a8 não dá mate.")


func test_ia_responde_depois_da_promocao_humana():
	preparar_promocao_branca()
	ligar_ia(1)

	await jogar("a7", "a8")
	assert_false(tabuleiro.ai_thinking, "A IA espera a escolha da peça.")

	await clicar_no_botao(botoes_brancos.get_node("5"))
	await esperar_ia()

	assert_true(tabuleiro.white, "A IA jogou depois da promoção.")
	assert_eq(peca_em("a8"), 5)
