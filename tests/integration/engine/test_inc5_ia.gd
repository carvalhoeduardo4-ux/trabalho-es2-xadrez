extends "res://tests/integration/base_integracao.gd"

# ENGINE · INCREMENTO 5: M1 a M5 + M6 (inteligência artificial)
#
# Verifica a integração da IA com o resto da engine: ela responde sozinha
# depois da jogada humana, só faz lances legais, usa as regras de fim de jogo
# na busca, promove sozinha e não deixa rastro da simulação no estado real.
# A IA joga de pretas.


func test_ia_responde_automaticamente_a_jogada_humana():
	ligar_ia(1)

	executar("e2", "e4")
	assert_false(tabuleiro.white, "Logo após o lance, é a vez das pretas.")

	await esperar_ia()

	assert_true(tabuleiro.white, "A IA jogou e devolveu a vez às brancas.")
	assert_false(tabuleiro.ai_thinking, "A IA terminou de pensar.")
	assert_eq(pecas_pretas_fora_do_lugar(), 1, "Exatamente uma peça preta saiu da posição inicial.")


func test_ia_captura_peca_desprotegida():
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("d5", 5)    # rainha branca que pode ser capturada
	colocar("e6", -1)
	colocar("h8", -6)
	ligar_ia(2)

	executar("e1", "e2")
	await esperar_ia()

	assert_eq(peca_em("d5"), -1, "O peão preto deve capturar a rainha.")


func test_ia_da_xeque_mate_quando_possivel():
	limpar_tabuleiro()
	colocar("h1", 6)
	colocar("g2", 1)
	colocar("h2", 1)
	colocar("b2", 1)
	colocar("a8", -4)
	colocar("g8", -6)
	ligar_ia(2)

	executar("b2", "b3")
	await esperar_ia()

	assert_eq(peca_em("a1"), -4, "A torre deve ir para a1.")
	assert_true(tabuleiro.game_over, "A IA deve dar xeque-mate.")


func test_ia_sai_do_xeque():
	limpar_tabuleiro()
	colocar("e8", -6)
	colocar("a7", -1)
	colocar("h1", 4)
	colocar("a1", 6)
	ligar_ia(1)

	executar("h1", "e1")   # xeque pela coluna e
	assert_true(tabuleiro.is_in_check(false))

	await esperar_ia()

	assert_false(tabuleiro.is_in_check(false), "A IA deve tirar o rei do xeque.")
	assert_true(tabuleiro.white)


func test_ia_promove_sozinha_para_rainha():
	limpar_tabuleiro()
	colocar("h4", 6)
	colocar("a8", -6)
	colocar("b2", -1)
	ligar_ia(1)

	executar("h4", "h5")
	await esperar_ia()

	assert_eq(peca_em("b1"), -5, "O peão preto deve virar rainha.")
	assert_null(tabuleiro.promotion_square, "Não fica promoção pendente.")
	assert_false(partida.get_node("CanvasLayer/black_pieces").visible, "Os botões não aparecem.")
	assert_true(tabuleiro.white, "A vez volta para as brancas.")


func test_ia_nao_joga_depois_do_fim_da_partida():
	executar_lances("e2e4 e7e5 f1c4 b8c6 d1h5 g8f6")
	ligar_ia(1)

	executar("h5", "f7")   # xeque-mate
	await get_tree().create_timer(0.6).timeout

	assert_true(tabuleiro.game_over)
	assert_false(tabuleiro.ai_thinking, "A IA não deve começar a pensar.")
	assert_eq(peca_em("e8"), -6, "Nenhuma peça preta se move.")


func test_simulacao_da_ia_nao_altera_o_estado_real():
	ligar_ia(2)

	executar("e2", "e4")
	await esperar_ia()

	assert_true(tabuleiro.white, "A vez é das brancas.")
	assert_false(tabuleiro.w_king_moved, "O rei branco não se moveu de verdade.")
	assert_false(tabuleiro.w_rook_left_moved, "A torre de a1 não se moveu de verdade.")
	assert_false(tabuleiro.w_rook_right_moved, "A torre de h1 não se moveu de verdade.")
	assert_eq(peca_em("e4"), 1, "O lance humano continua no tabuleiro.")
	assert_eq(contar_pecas(), 32, "Nenhuma captura aconteceu.")


func test_ia_de_brancas_abre_a_partida():
	# Uma partida nova em que a IA joga de brancas começa sozinha.
	var outra = MAIN_SCENE.instantiate()
	var tab = outra.get_node("Camera2D/board")
	tab.vs_ai = true
	tab.ai_plays_white = true
	tab.ai_search_depth = 1
	tela_jogo.add_child(outra)

	var inicio = Time.get_ticks_msec()
	await get_tree().process_frame
	while tab.ai_thinking and Time.get_ticks_msec() - inicio < 10000:
		await get_tree().process_frame

	assert_false(tab.white, "A IA de brancas jogou o primeiro lance.")
	outra.queue_free()


func test_busca_da_ia_nao_altera_o_estado_com_regras_especiais():
	# As pretas têm en passant, roque e promoção disponíveis na busca.
	limpar_tabuleiro()
	colocar("e8", -6)
	colocar("h8", -4)
	colocar("a8", -4)
	colocar("d4", -1)
	colocar("b2", -1)
	colocar("e4", 1)
	colocar("h3", 6)
	liberar_roque()
	tabuleiro.white = false
	tabuleiro.en_passant = casa("e2")

	var antes = foto_do_estado()
	tabuleiro.choose_best_move(tabuleiro.get_all_legal_moves_for_current_turn(), 2)

	assert_eq(foto_do_estado(), antes, "A busca deve desfazer todos os lances simulados.")


func test_busca_profunda_das_brancas_nao_altera_o_estado():
	# Profundidade 3, a padrão do jogo, com en passant, roque e promoção das brancas.
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("h1", 4)
	colocar("a1", 4)
	colocar("e5", 1)
	colocar("d5", -1)
	colocar("b7", 1)
	colocar("g6", -6)
	liberar_roque()
	tabuleiro.en_passant = casa("d7")

	var antes = foto_do_estado()
	var lance = tabuleiro.choose_best_move(tabuleiro.get_all_legal_moves_for_current_turn(), 3)

	assert_eq(foto_do_estado(), antes, "A busca deve desfazer todos os lances simulados.")
	assert_false(lance.is_empty(), "A busca deve escolher um lance.")


# Cópia de tudo que a busca da IA mexe durante a simulação.
func foto_do_estado() -> Dictionary:
	return {
		"board": tabuleiro.board.duplicate(true),
		"white": tabuleiro.white,
		"en_passant": tabuleiro.en_passant,
		"w_king_moved": tabuleiro.w_king_moved,
		"b_king_moved": tabuleiro.b_king_moved,
		"w_rook_left_moved": tabuleiro.w_rook_left_moved,
		"w_rook_right_moved": tabuleiro.w_rook_right_moved,
		"b_rook_left_moved": tabuleiro.b_rook_left_moved,
		"b_rook_right_moved": tabuleiro.b_rook_right_moved,
	}


# Quantas casas da posição inicial das pretas ficaram diferentes.
func pecas_pretas_fora_do_lugar() -> int:
	var inicial = [
		[-4, -2, -3, -5, -6, -3, -2, -4],
		[-1, -1, -1, -1, -1, -1, -1, -1],
	]
	var diferentes = 0
	for linha in range(2):
		for coluna in range(8):
			if tabuleiro.board[linha][coluna] != inicial[linha][coluna]:
				diferentes += 1
	return diferentes
