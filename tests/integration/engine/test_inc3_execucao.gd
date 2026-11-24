extends "res://tests/integration/base_integracao.gd"

# ENGINE · INCREMENTO 3: M1 + M2 + M3 + M4 (execução da jogada)
#
# Verifica se set_move() executa corretamente os lances calculados por
# get_moves() e atualiza o estado que os módulos de baixo usam depois:
# turno, casa de en passant, direitos de roque e contador de 50 lances.
#
# Observação: set_move() também chama display_board, play_move_sound e
# check_game_state, porque tudo está no mesmo script. Aqui só o estado
# do tabuleiro é verificado.


func test_jogada_valida_altera_tabuleiro_e_turno():
	executar("g1", "f3")

	assert_eq(peca_em("f3"), 2, "O cavalo deve estar em f3.")
	assert_eq(peca_em("g1"), 0, "A casa g1 deve ficar vazia.")
	assert_false(tabuleiro.white, "Deve ser a vez das pretas.")

	executar("g8", "f6")

	assert_eq(peca_em("f6"), -2, "O cavalo preto deve estar em f6.")
	assert_true(tabuleiro.white, "Deve voltar a ser a vez das brancas.")


func test_captura_remove_a_peca_adversaria():
	executar_lances("e2e4 d7d5 e4d5")

	assert_eq(peca_em("d5"), 1, "O peão branco deve ocupar d5.")
	assert_eq(contar_pecas(), 31, "Uma peça deve sair do tabuleiro.")


func test_jogada_fora_dos_movimentos_calculados_e_ignorada():
	executar("e2", "e5", false)

	assert_eq(peca_em("e2"), 1, "O peão deve continuar em e2.")
	assert_eq(peca_em("e5"), 0, "A casa e5 deve continuar vazia.")
	assert_true(tabuleiro.white, "O turno não deve mudar.")


func test_lance_bloqueado_pela_validacao_nao_e_executado():
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("e2", 3)
	colocar("e8", -4)
	colocar("a8", -6)

	# O bispo está cravado: a validação (M3) não deixa M4 executar.
	executar("e2", "d3", false)

	assert_eq(peca_em("e2"), 3, "O bispo cravado deve continuar em e2.")
	assert_true(tabuleiro.white, "O turno não deve mudar.")


func test_avanco_duplo_registra_e_limpa_en_passant():
	executar("e2", "e4")
	assert_eq(tabuleiro.en_passant, casa("e2"), "Avanço duplo das brancas registrado.")

	executar("c7", "c5")
	assert_eq(tabuleiro.en_passant, casa("c7"), "Avanço duplo das pretas registrado.")

	executar("g1", "f3")
	assert_eq(tabuleiro.en_passant, Vector2(-1, -1), "Outro lance limpa o en passant.")


func test_en_passant_das_brancas_remove_peao_capturado():
	executar_lances("e2e4 a7a6 e4e5 d7d5 e5d6")

	assert_eq(peca_em("d6"), 1, "O peão branco deve ir para d6.")
	assert_eq(peca_em("d5"), 0, "O peão preto de d5 deve ser removido.")
	assert_eq(peca_em("e5"), 0, "A casa e5 deve ficar vazia.")


func test_en_passant_das_pretas_remove_peao_capturado():
	executar_lances("a2a3 d7d5 a3a4 d5d4 e2e4 d4e3")

	assert_eq(peca_em("e3"), -1, "O peão preto deve ir para e3.")
	assert_eq(peca_em("e4"), 0, "O peão branco de e4 deve ser removido.")
	assert_eq(peca_em("d4"), 0, "A casa d4 deve ficar vazia.")


func test_en_passant_expira_depois_de_um_lance():
	executar_lances("e2e4 a7a6 e4e5 d7d5 h2h3 a6a5")

	assert_does_not_have(movimentos_de("e5"), "d6", "O en passant só vale no lance seguinte.")


# [descrição, branco?, rei de, rei para, torre de, torre para]
var roques = [
	["pequeno das brancas", true, "e1", "g1", "h1", "f1"],
	["grande das brancas", true, "e1", "c1", "a1", "d1"],
	["pequeno das pretas", false, "e8", "g8", "h8", "f8"],
	["grande das pretas", false, "e8", "c8", "a8", "d8"],
]


func test_roque_move_rei_e_torre(p = use_parameters(roques)):
	limpar_tabuleiro()
	var s = 1 if p[1] else -1
	colocar(p[2], 6 * s)
	colocar(p[4], 4 * s)
	colocar("h4" if p[1] else "h5", -6 * s)
	tabuleiro.white = p[1]
	liberar_roque()

	executar(p[2], p[3])

	assert_eq(peca_em(p[3]), 6 * s, "Roque " + p[0] + ": rei em " + p[3] + ".")
	assert_eq(peca_em(p[5]), 4 * s, "Roque " + p[0] + ": torre em " + p[5] + ".")
	assert_eq(peca_em(p[2]), 0, "A casa de origem do rei fica vazia.")
	assert_eq(peca_em(p[4]), 0, "A casa de origem da torre fica vazia.")


func test_mover_o_rei_tira_os_dois_roques():
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("h1", 4)
	colocar("a1", 4)
	colocar("d5", -6)
	liberar_roque()

	executar_lances("e1f1 d5d6 f1e1 d6d5")

	assert_does_not_have(movimentos_de("e1"), "g1", "Sem roque pequeno.")
	assert_does_not_have(movimentos_de("e1"), "c1", "Sem roque grande.")


func test_mover_uma_torre_tira_so_o_roque_daquele_lado():
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("h1", 4)
	colocar("a1", 4)
	colocar("d5", -6)
	liberar_roque()

	executar_lances("h1h2 d5d6 h2h1 d6d5")

	assert_does_not_have(movimentos_de("e1"), "g1", "A torre de h1 se moveu: sem roque pequeno.")
	assert_has(movimentos_de("e1"), "c1", "A torre de a1 não se moveu: roque grande disponível.")


func test_torre_capturada_no_canto_perde_o_roque():
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("h1", 4)
	colocar("h5", 4)
	colocar("a8", -6)
	colocar("c6", -3)
	liberar_roque()
	tabuleiro.white = false

	# O bispo captura a torre de h1, e a outra torre volta para h1.
	executar_lances("c6h1 h5h1 a8b8")

	assert_eq(peca_em("h1"), 4, "Há de novo uma torre em h1.")
	assert_does_not_have(movimentos_de("e1"), "g1", "Mas não é a torre original: sem roque.")


func test_peao_na_ultima_fileira_aguarda_promocao():
	limpar_tabuleiro()
	colocar("a7", 1)
	colocar("e1", 6)
	colocar("h6", -6)

	executar("a7", "a8")

	assert_eq(tabuleiro.promotion_square, casa("a8"), "A jogada para aguardando a escolha.")
	assert_eq(peca_em("a7"), 0, "O peão sai de a7.")
	assert_true(tabuleiro.white, "O turno só muda depois da escolha.")


func test_peao_preto_na_ultima_fileira_aguarda_promocao():
	limpar_tabuleiro()
	tabuleiro.white = false
	colocar("b2", -1)
	colocar("a1", 4)    # o peão pode capturar a torre ao promover
	colocar("h3", 6)
	colocar("h8", -6)

	executar("b2", "a1")

	assert_eq(tabuleiro.promotion_square, casa("a1"), "A promoção com captura aguarda a escolha.")
	assert_eq(peca_em("b2"), 0)
	assert_false(tabuleiro.white)


func test_contador_de_50_lances_zera_com_peao_e_captura():
	executar("g1", "f3")
	assert_eq(tabuleiro.fifty_move_rule, 1, "Lance de peça soma 1.")

	executar("g8", "f6")
	assert_eq(tabuleiro.fifty_move_rule, 2)

	executar("e2", "e4")
	assert_eq(tabuleiro.fifty_move_rule, 0, "Lance de peão zera o contador.")

	executar("b8", "c6")
	executar("f3", "g1")
	assert_eq(tabuleiro.fifty_move_rule, 2)

	executar("f6", "e4")
	assert_eq(tabuleiro.fifty_move_rule, 0, "Captura zera o contador.")
