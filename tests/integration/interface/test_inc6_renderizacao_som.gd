extends "res://tests/integration/base_integracao.gd"

# INTERFACE · INCREMENTO 6: engine (M1 a M6) + M7 (renderização e som)
#
# Verifica se o que aparece na tela e o som tocado acompanham o estado
# do jogo: peças desenhadas, pontos de movimento, indicador de turno e
# som de movimento ou de captura.
# As jogadas ainda são feitas pelo driver (sem cliques).


# Seleciona a peça pelo caminho da interface (show_options) e executa.
func executar_pela_interface(de: String, para: String):
	var destino = casa(para)

	tabuleiro.selected_piece = casa(de)
	tabuleiro.state = true
	tabuleiro.show_options()
	tabuleiro.set_move(int(destino.x), int(destino.y))
	await get_tree().process_frame


func executar_lances_pela_interface(lances: String):
	for lance in lances.split(" ", false):
		await executar_pela_interface(lance.substr(0, 2), lance.substr(2, 2))


func test_tela_inicial_bate_com_o_tabuleiro():
	assert_eq(diferencas_tela_e_tabuleiro(), [], "As 64 casas devem mostrar a peça certa.")
	assert_eq(pontos_na_tela(), [], "Nenhum ponto no início.")


func test_indicador_de_turno_muda_de_imagem_e_de_lado():
	assert_eq(tabuleiro.turn.texture, tabuleiro.TURN_WHITE)
	assert_gt(tabuleiro.turn.position.y, 0.0, "Na vez das brancas, a barra fica embaixo.")

	await executar_pela_interface("e2", "e4")

	assert_eq(tabuleiro.turn.texture, tabuleiro.TURN_BLACK)
	assert_lt(tabuleiro.turn.position.y, 0.0, "Na vez das pretas, a barra fica em cima.")


func test_pontos_mostram_exatamente_os_movimentos_legais():
	for nome in ["b1", "g1", "e2", "a2"]:
		tabuleiro.selected_piece = casa(nome)
		tabuleiro.show_options()

		assert_eq(
			pontos_na_tela(), nomes(tabuleiro.get_moves()),
			"Os pontos de " + nome + " devem ser os movimentos legais."
		)


func test_peca_sem_movimentos_nao_mostra_pontos():
	tabuleiro.selected_piece = casa("a1")   # torre presa na posição inicial
	tabuleiro.state = true
	tabuleiro.show_options()

	assert_eq(pontos_na_tela(), [])
	assert_false(tabuleiro.state, "A peça sem movimentos não fica selecionada.")


func test_pontos_respeitam_a_validacao_de_xeque():
	await executar_lances_pela_interface("e2e4 f7f5 d1h5")

	tabuleiro.selected_piece = casa("g7")
	tabuleiro.show_options()

	assert_eq(pontos_na_tela(), ["g6"], "Em xeque, só aparece o bloqueio em g6.")


func test_tela_acompanha_jogada_captura_e_turno():
	await executar_lances_pela_interface("e2e4 d7d5")
	assert_eq(diferencas_tela_e_tabuleiro(), [])

	await executar_pela_interface("e4", "d5")

	assert_eq(peca_na_tela("d5"), tabuleiro.WHITE_PAWN, "O peão branco aparece em d5.")
	assert_null(peca_na_tela("e4"))
	assert_eq(pontos_na_tela(), [], "Os pontos somem depois da jogada.")
	assert_eq(diferencas_tela_e_tabuleiro(), [])


func test_en_passant_remove_o_peao_da_tela():
	await executar_lances_pela_interface("e2e4 a7a6 e4e5 d7d5")

	tabuleiro.selected_piece = casa("e5")
	tabuleiro.show_options()
	assert_has(pontos_na_tela(), "d6", "O en passant aparece como ponto.")

	await executar_pela_interface("e5", "d6")

	assert_null(peca_na_tela("d5"), "O peão capturado some da tela.")
	assert_eq(diferencas_tela_e_tabuleiro(), [])


func test_roque_desenha_rei_e_torre_dos_dois_lados():
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("a1", 4)
	colocar("e8", -6)
	colocar("h8", -4)
	liberar_roque()
	tabuleiro.display_board()

	await executar_pela_interface("e1", "c1")
	await executar_pela_interface("e8", "g8")

	assert_eq(peca_na_tela("c1"), tabuleiro.WHITE_KING)
	assert_eq(peca_na_tela("d1"), tabuleiro.WHITE_ROOK)
	assert_eq(peca_na_tela("g8"), tabuleiro.BLACK_KING)
	assert_eq(peca_na_tela("f8"), tabuleiro.BLACK_ROOK)
	assert_eq(diferencas_tela_e_tabuleiro(), [])


func test_tela_continua_certa_ate_o_xeque_mate():
	var lances = "e2e4 e7e5 f1c4 b8c6 d1h5 g8f6 h5f7"

	for lance in lances.split(" "):
		await executar_pela_interface(lance.substr(0, 2), lance.substr(2, 2))
		assert_eq(diferencas_tela_e_tabuleiro(), [], "Tela certa depois de " + lance + ".")

	assert_true(tabuleiro.game_over)


func test_som_de_movimento_e_de_captura():
	await executar_pela_interface("e2", "e4")
	assert_eq(som_tocado(), tabuleiro.MOVE_SOUND, "Lance sem captura toca o som de movimento.")

	await executar_lances_pela_interface("d7d5 e4d5")
	assert_eq(som_tocado(), tabuleiro.CAPTURE_SOUND, "Captura toca o som de captura.")

	await executar_pela_interface("g8", "f6")
	assert_eq(som_tocado(), tabuleiro.MOVE_SOUND)


func test_en_passant_toca_som_de_captura():
	await executar_lances_pela_interface("e2e4 a7a6 e4e5 d7d5 e5d6")

	assert_eq(
		som_tocado(), tabuleiro.CAPTURE_SOUND,
		"No en passant a casa de destino está vazia, mas é uma captura."
	)


func test_roque_toca_som_de_movimento():
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("h1", 4)
	colocar("a8", -6)
	liberar_roque()

	await executar_pela_interface("e1", "g1")

	assert_eq(som_tocado(), tabuleiro.MOVE_SOUND)


func test_jogada_da_ia_aparece_na_tela_e_toca_som():
	ligar_ia(1)

	await executar_pela_interface("e2", "e4")
	await esperar_ia()
	await get_tree().process_frame

	assert_true(tabuleiro.white, "A IA já respondeu.")
	assert_eq(diferencas_tela_e_tabuleiro(), [], "O lance da IA aparece na tela.")
	assert_eq(tabuleiro.turn.texture, tabuleiro.TURN_WHITE)
	assert_not_null(som_tocado(), "O lance da IA também toca som.")
