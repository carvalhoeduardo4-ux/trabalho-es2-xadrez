extends "res://tests/integration/base_integracao.gd"

# SISTEMA · INCREMENTO 9: todos os módulos + M10 (menu principal)
#
# Último incremento: o sistema inteiro integrado, do menu até o fim da partida,
# usando só a entrada do jogador (cliques).

const MENU_SCENE = preload("res://Scenes/MainMenu.tscn")


func test_botao_jogar_do_menu_abre_a_partida():
	var tela_menu = SubViewport.new()
	tela_menu.size = Vector2i(1280, 720)
	add_child_autofree(tela_menu)

	var menu = MENU_SCENE.instantiate()
	tela_menu.add_child(menu)
	await get_tree().process_frame

	# Clica no botão JOGAR pela interface.
	var botao = menu.get_node("CenterContainer/VBoxContainer/PlayButton")
	var centro = botao.get_global_transform_with_canvas() * (botao.size / 2)
	tela_jogo = tela_menu
	await clicar_na_tela(centro)
	await get_tree().process_frame
	await get_tree().process_frame

	var cena = get_tree().current_scene
	assert_not_null(cena, "Uma cena nova deve estar carregada.")
	assert_eq(cena.scene_file_path, "res://Scenes/main.tscn", "O JOGAR abre a cena da partida.")

	var tabuleiro_novo = cena.get_node("Camera2D/board")
	assert_eq(tabuleiro_novo.board[7][4], 6, "A partida começa na posição inicial.")
	assert_true(tabuleiro_novo.white, "As brancas começam.")
	assert_true(tabuleiro_novo.vs_ai, "A partida aberta pelo menu é contra a IA.")

	cena.queue_free()
	await get_tree().process_frame


func test_partida_completa_por_cliques_com_todas_as_regras_especiais():
	# En passant, roque, captura, promoção com captura e xeque-mate.
	await jogar_lances("e2e4 a7a6 e4e5 d7d5")

	await jogar("e5", "d6")   # en passant
	assert_eq(peca_em("d5"), 0, "En passant feito.")
	assert_eq(som_tocado(), tabuleiro.CAPTURE_SOUND)

	await jogar_lances("g8f6 g1f3 b8c6 f1c4 c8g4")

	await jogar("e1", "g1")   # roque pequeno
	assert_eq(peca_em("f1"), 4, "Roque feito.")

	await jogar_lances("a8a7 d2d4 c6d4 d6c7 d4f5")

	await jogar("c7", "d8")   # captura a rainha e promove
	assert_true(partida.get_node("CanvasLayer/white_pieces").visible)

	await clicar_no_botao(partida.get_node("CanvasLayer/white_pieces/5"))

	assert_eq(peca_em("d8"), 5, "O peão virou rainha em d8.")
	assert_true(tabuleiro.is_in_check(false), "A nova rainha dá xeque.")
	assert_true(tabuleiro.game_over, "E é xeque-mate.")
	assert_eq(diferencas_tela_e_tabuleiro(), [], "A tela termina igual ao tabuleiro.")

	# Depois do fim, o tabuleiro não aceita mais jogadas.
	await jogar("e8", "d8")
	assert_eq(peca_em("e8"), -6)


func test_partida_contra_a_ia_por_cliques():
	ligar_ia(1)

	for lance in ["e2e4", "g1f3", "f1e2"]:
		await jogar(lance.substr(0, 2), lance.substr(2, 2))
		assert_eq(peca_em(lance.substr(2, 2)) > 0, true, "O lance " + lance + " foi feito.")

		await esperar_ia()
		await get_tree().process_frame

		assert_true(tabuleiro.white, "A IA respondeu ao lance " + lance + ".")
		assert_eq(diferencas_tela_e_tabuleiro(), [], "A tela acompanha a partida.")

	assert_false(tabuleiro.game_over)
	assert_eq(tabuleiro.turn.texture, tabuleiro.TURN_WHITE)
