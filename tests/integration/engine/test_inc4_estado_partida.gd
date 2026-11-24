extends "res://tests/integration/base_integracao.gd"

# ENGINE · INCREMENTO 4: M1 a M4 + M5 (estado da partida)
#
# Verifica se, depois de cada jogada executada, o estado da partida
# é avaliado corretamente: partida em andamento, xeque, xeque-mate,
# afogamento e os empates (material insuficiente, 50 lances, repetição).


func test_partida_continua_apos_jogada_normal():
	executar("e2", "e4")

	assert_true(tabuleiro.has_any_legal_move(), "As pretas devem ter lances.")
	assert_false(tabuleiro.game_over, "A partida deve continuar.")


func test_xeque_sem_mate_nao_encerra_a_partida():
	executar_lances("e2e4 f7f5 d1h5")

	assert_true(tabuleiro.is_in_check(false), "O rei preto deve estar em xeque.")
	assert_eq(movimentos_de("g7"), ["g6"], "As pretas podem bloquear com g6.")
	assert_false(tabuleiro.game_over, "Xeque sem mate não encerra a partida.")


func test_xeque_mate_das_brancas_encerra_a_partida():
	# Mate do pastor.
	executar_lances("e2e4 e7e5 f1c4 b8c6 d1h5 g8f6")
	assert_false(tabuleiro.game_over, "A partida ainda não terminou.")

	executar("h5", "f7")

	assert_true(tabuleiro.is_in_check(false), "O rei preto deve estar em xeque.")
	assert_false(tabuleiro.has_any_legal_move(), "As pretas não devem ter lances.")
	assert_true(tabuleiro.game_over, "O xeque-mate deve encerrar a partida.")


func test_xeque_mate_das_pretas_encerra_a_partida():
	# Mate do louco.
	executar_lances("f2f3 e7e5 g2g4 d8h4")

	assert_true(tabuleiro.is_in_check(true), "O rei branco deve estar em xeque.")
	assert_true(tabuleiro.game_over, "O xeque-mate das pretas deve encerrar a partida.")


func test_afogamento_encerra_a_partida():
	limpar_tabuleiro()
	colocar("h8", -6)
	colocar("f7", 6)
	colocar("g5", 5)

	executar("g5", "g6")

	assert_false(tabuleiro.is_in_check(false), "O rei preto não está em xeque.")
	assert_false(tabuleiro.has_any_legal_move(), "As pretas não devem ter lances.")
	assert_true(tabuleiro.game_over, "O afogamento deve encerrar a partida.")


func test_rei_contra_rei_e_empate_por_material_insuficiente():
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("d2", -2)
	colocar("h8", -6)

	executar("e1", "d2")   # o rei captura a última peça

	assert_false(tabuleiro.is_in_check(false))
	assert_true(tabuleiro.game_over, "Rei contra rei é empate.")


func test_rei_e_bispo_contra_rei_e_empate():
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("f1", 3)
	colocar("g2", -2)
	colocar("h8", -6)

	executar("f1", "g2")

	assert_true(tabuleiro.game_over, "Rei e bispo contra rei é empate.")


func test_rei_e_torre_contra_rei_continua():
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("a1", 4)
	colocar("a2", -2)
	colocar("h8", -6)

	executar("a1", "a2")

	assert_false(tabuleiro.game_over, "Rei e torre ainda podem dar mate.")


func test_duas_pecas_menores_nao_sao_material_insuficiente():
	# Rei, bispo e cavalo contra rei ainda pode dar mate.
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("c1", 3)
	colocar("b1", 2)
	colocar("h8", -6)
	colocar("a7", -1)

	executar("b1", "c3")
	assert_false(tabuleiro.game_over, "Bispo e cavalo das brancas não é empate.")

	# O mesmo para as pretas.
	limpar_tabuleiro()
	tabuleiro.white = false
	colocar("e8", -6)
	colocar("c8", -3)
	colocar("b8", -2)
	colocar("h1", 6)
	colocar("a2", 1)

	executar("b8", "c6")
	assert_false(tabuleiro.game_over, "Bispo e cavalo das pretas não é empate.")


func test_regra_dos_50_lances_conta_100_meios_lances():
	# A regra vale para 50 lances de CADA jogador sem captura nem lance de peão,
	# ou seja, 100 meios-lances.
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("a1", 4)
	colocar("h8", -6)
	colocar("a8", -4)

	tabuleiro.fifty_move_rule = 49
	executar("a1", "b1")
	assert_false(tabuleiro.game_over, "Depois de 50 meios-lances a partida continua.")

	tabuleiro.fifty_move_rule = 99
	executar("a8", "b8")
	assert_true(tabuleiro.game_over, "Depois de 100 meios-lances é empate.")


func test_lance_de_peao_evita_o_empate_dos_50_lances():
	tabuleiro.fifty_move_rule = 99
	executar("e2", "e4")

	assert_eq(tabuleiro.fifty_move_rule, 0)
	assert_false(tabuleiro.game_over)


func test_tripla_repeticao_e_empate():
	# A posição inicial (brancas jogando) aparece pela 3ª vez
	# depois que os cavalos vão e voltam duas vezes.
	executar_lances("g1f3 g8f6 f3g1 f6g8")
	assert_false(tabuleiro.game_over, "2ª ocorrência da posição inicial.")

	executar_lances("g1f3 g8f6 f3g1")
	assert_false(tabuleiro.game_over)

	executar("f6", "g8")
	assert_true(tabuleiro.game_over, "3ª ocorrência da posição inicial: empate.")


func test_verificacao_do_fim_nao_altera_a_peca_selecionada():
	executar("e2", "e4")

	tabuleiro.selected_piece = casa("b8")
	tabuleiro.check_game_state()

	assert_eq(
		tabuleiro.selected_piece, casa("b8"),
		"Verificar o estado da partida não deve mudar a peça selecionada."
	)
