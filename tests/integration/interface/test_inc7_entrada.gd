extends "res://tests/integration/base_integracao.gd"

# INTERFACE · INCREMENTO 7: engine + M7 + M8 (entrada do jogador)
#
# As jogadas agora são feitas por cliques do mouse, que passam por _input()
# e local_to_board_position(). Verifica a conversão do clique em casa,
# a seleção, os cliques que devem ser ignorados e o bloqueio da entrada
# durante a vez da IA e depois do fim da partida.


func test_clique_no_centro_de_cada_casa_cai_na_casa_certa():
	for linha in range(8):
		for coluna in range(8):
			var nome = nome_da_casa(Vector2(linha, coluna))
			var global_pos = tela_jogo.get_canvas_transform().affine_inverse() * posicao_na_tela(nome)

			assert_eq(
				tabuleiro.local_to_board_position(tabuleiro.to_local(global_pos)), casa(nome),
				"O clique em " + nome + " deve cair em " + nome + "."
			)


func test_clique_perto_da_borda_da_casa_ainda_cai_na_casa():
	# Um ponto a 40% do tamanho da casa a partir do centro.
	var desvio = tabuleiro.CELL_WIDTH * 0.4
	var centro = tabuleiro.board_to_local_position(4, 4)   # e4

	for d in [Vector2(desvio, desvio), Vector2(-desvio, -desvio), Vector2(desvio, -desvio)]:
		assert_eq(tabuleiro.local_to_board_position(centro + d), casa("e4"))


func test_clique_fora_do_tabuleiro_nao_corresponde_a_casa():
	var metade = tabuleiro.BOARD_PIXEL_SIZE / 2.0 + 1

	for ponto in [Vector2(-metade, 0), Vector2(metade, 0), Vector2(0, -metade), Vector2(0, metade)]:
		assert_null(tabuleiro.local_to_board_position(ponto), "O ponto " + str(ponto) + " está fora.")

	await clicar_na_tela(Vector2(5, 5))
	assert_false(tabuleiro.state, "Clique fora do tabuleiro não seleciona nada.")


func test_clique_seleciona_e_mostra_pontos():
	await clicar("b1")

	assert_true(tabuleiro.state, "O cavalo deve ficar selecionado.")
	assert_eq(tabuleiro.selected_piece, casa("b1"))
	assert_eq(pontos_na_tela(), ["a3", "c3"])


func test_dois_cliques_fazem_a_jogada():
	await jogar("b1", "c3")

	assert_eq(peca_em("c3"), 2, "O cavalo deve ir para c3.")
	assert_eq(peca_na_tela("c3"), tabuleiro.WHITE_KNIGHT)
	assert_eq(tabuleiro.turn.texture, tabuleiro.TURN_BLACK)
	assert_false(tabuleiro.state, "Depois da jogada nada fica selecionado.")


func test_pretas_jogam_por_clique_na_vez_delas():
	await jogar("e2", "e4")
	await jogar("e7", "e5")

	assert_eq(peca_em("e5"), -1)
	assert_true(tabuleiro.white)


func test_botao_direito_e_ignorado():
	await clicar("b1", MOUSE_BUTTON_RIGHT)

	assert_false(tabuleiro.state, "O botão direito não seleciona peças.")
	assert_eq(pontos_na_tela(), [])


func test_clique_em_peca_do_adversario_e_ignorado():
	await clicar("e7")

	assert_false(tabuleiro.state, "A peça preta não pode ser selecionada na vez das brancas.")
	assert_eq(pontos_na_tela(), [])


func test_clique_em_casa_vazia_sem_selecao_e_ignorado():
	await clicar("e4")

	assert_false(tabuleiro.state)
	assert_true(tabuleiro.white)


func test_clique_em_destino_invalido_cancela_a_selecao():
	await jogar("e2", "e5")

	assert_eq(peca_em("e2"), 1, "O peão continua em e2.")
	assert_true(tabuleiro.white, "Jogada inválida não passa a vez.")
	assert_false(tabuleiro.state, "A seleção é cancelada.")
	assert_eq(pontos_na_tela(), [], "Os pontos somem.")

	# Depois de cancelar, o jogador consegue jogar normalmente.
	await jogar("e2", "e4")
	assert_eq(peca_em("e4"), 1)


func test_clique_em_peca_sem_movimentos_nao_trava_a_selecao():
	await clicar("a1")   # torre sem movimentos no início
	assert_eq(pontos_na_tela(), [])

	await clicar("b1")
	assert_eq(pontos_na_tela(), ["a3", "c3"], "Outra peça deve poder ser selecionada em seguida.")


func test_cliques_sao_ignorados_depois_do_xeque_mate():
	await jogar_lances("e2e4 e7e5 f1c4 b8c6 d1h5 g8f6 h5f7")
	assert_true(tabuleiro.game_over)

	await jogar("a7", "a6")

	assert_eq(peca_em("a7"), -1, "Nenhuma peça se move após o mate.")
	assert_eq(pontos_na_tela(), [], "Nenhum ponto aparece após o mate.")


func test_cliques_sao_ignorados_na_vez_da_ia():
	ligar_ia(1)

	await jogar("e2", "e4")
	assert_true(tabuleiro.ai_thinking, "A IA está pensando.")

	# O jogador tenta mover uma peça preta e uma branca durante a vez da IA.
	await jogar("e7", "e5")
	await clicar("g1")

	assert_eq(pontos_na_tela(), [], "Nada é selecionado durante a vez da IA.")

	await esperar_ia()

	assert_true(tabuleiro.white, "A vez volta para o jogador.")
	await jogar("g1", "f3")
	assert_eq(peca_em("f3"), 2, "Depois da IA, o jogador volta a jogar por cliques.")
