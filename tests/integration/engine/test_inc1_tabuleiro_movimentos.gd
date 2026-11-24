extends "res://tests/integration/base_integracao.gd"

# ENGINE · INCREMENTO 1: M1 (estado do tabuleiro) + M2 (geração de movimentos)
#
# Verifica se os geradores de movimento de cada peça usam corretamente
# o estado do tabuleiro: casas vazias, peças inimigas, limites, turno
# e a casa de en passant guardada no estado.
# Os geradores são chamados direto, ainda sem o filtro de xeque (M3).
#
# Classes cobertas: cada tipo de peça; peças brancas e pretas;
# centro, borda e canto; caminho livre, bloqueado por peça própria e por inimiga.


func test_estado_inicial_montado_pelo_ready():
	assert_eq(contar_pecas(), 32, "O jogo deve começar com 32 peças.")
	assert_eq(peca_em("e1"), 6, "O rei branco deve começar em e1.")
	assert_eq(peca_em("e8"), -6, "O rei preto deve começar em e8.")
	assert_eq(peca_em("d1"), 5, "A rainha branca deve começar em d1.")
	assert_eq(peca_em("d8"), -5, "A rainha preta deve começar em d8.")
	assert_true(tabuleiro.white, "As brancas devem começar jogando.")
	assert_eq(tabuleiro.en_passant, Vector2(-1, -1), "Não deve haver en passant no início.")
	assert_false(tabuleiro.w_king_moved, "O roque das brancas começa disponível.")
	assert_false(tabuleiro.b_king_moved, "O roque das pretas começa disponível.")


func test_peao_branco_anda_uma_ou_duas_casas_da_fileira_inicial():
	tabuleiro.selected_piece = casa("e2")
	assert_eq(nomes(tabuleiro.get_pawn_moves()), ["e3", "e4"])

	# Fora da fileira inicial, só uma casa.
	limpar_tabuleiro()
	colocar("e3", 1)
	tabuleiro.selected_piece = casa("e3")
	assert_eq(nomes(tabuleiro.get_pawn_moves()), ["e4"])


func test_peao_preto_anda_no_sentido_contrario():
	tabuleiro.white = false
	tabuleiro.selected_piece = casa("e7")

	assert_eq(
		nomes(tabuleiro.get_pawn_moves()), ["e5", "e6"],
		"Na vez das pretas, o peão anda para baixo no array."
	)


func test_peao_bloqueado_pela_frente():
	# Peça logo à frente: nenhum avanço.
	colocar("e3", -2)
	tabuleiro.selected_piece = casa("e2")
	assert_eq(nomes(tabuleiro.get_pawn_moves()), [])

	# Peça duas casas à frente: só o avanço simples.
	colocar("e3", 0)
	colocar("e4", -2)
	assert_eq(nomes(tabuleiro.get_pawn_moves()), ["e3"])


func test_peao_so_captura_na_diagonal_quando_ha_inimigo():
	colocar("d3", -2)   # cavalo preto
	colocar("f3", 2)    # cavalo branco

	tabuleiro.selected_piece = casa("e2")

	assert_eq(
		nomes(tabuleiro.get_pawn_moves()), ["d3", "e3", "e4"],
		"O peão captura o cavalo preto em d3, mas não o branco em f3."
	)


func test_peao_na_borda_nao_sai_do_tabuleiro():
	tabuleiro.selected_piece = casa("a2")
	assert_eq(nomes(tabuleiro.get_pawn_moves()), ["a3", "a4"])

	tabuleiro.selected_piece = casa("h2")
	assert_eq(nomes(tabuleiro.get_pawn_moves()), ["h3", "h4"])


func test_cavalo_no_centro_na_borda_e_pulando_pecas():
	# Na posição inicial, o cavalo pula os peões.
	tabuleiro.selected_piece = casa("b1")
	assert_eq(nomes(tabuleiro.get_knight_moves()), ["a3", "c3"], "O cavalo pula os peões.")

	limpar_tabuleiro()
	colocar("d4", 2)
	tabuleiro.selected_piece = casa("d4")
	assert_eq(tabuleiro.get_knight_moves().size(), 8, "No centro, o cavalo tem 8 casas.")

	colocar("a1", 2)
	tabuleiro.selected_piece = casa("a1")
	assert_eq(nomes(tabuleiro.get_knight_moves()), ["b3", "c2"], "No canto, só 2 casas.")


func test_bispo_para_em_peca_propria_e_captura_inimiga():
	limpar_tabuleiro()
	colocar("c1", 3)
	colocar("e3", 1)    # peão branco bloqueia a diagonal
	colocar("a3", -1)   # peão preto pode ser capturado

	tabuleiro.selected_piece = casa("c1")

	assert_eq(nomes(tabuleiro.get_bishop_moves()), ["a3", "b2", "d2"])


func test_torre_para_em_peca_propria_e_captura_inimiga():
	limpar_tabuleiro()
	colocar("a1", 4)
	colocar("a3", 1)    # peão branco bloqueia a coluna
	colocar("c1", -2)   # cavalo preto pode ser capturado

	tabuleiro.selected_piece = casa("a1")

	assert_eq(nomes(tabuleiro.get_rook_moves()), ["a2", "b1", "c1"])


func test_rainha_combina_movimentos_de_torre_e_bispo():
	limpar_tabuleiro()
	colocar("d4", 5)
	colocar("d6", -1)
	colocar("f6", 1)

	tabuleiro.selected_piece = casa("d4")
	var torre_mais_bispo = tabuleiro.get_rook_moves() + tabuleiro.get_bishop_moves()

	assert_eq(
		nomes(tabuleiro.get_queen_moves()), nomes(torre_mais_bispo),
		"A rainha deve alcançar exatamente as casas da torre e do bispo."
	)


func test_rei_anda_uma_casa_e_respeita_bordas_e_pecas_proprias():
	limpar_tabuleiro()
	colocar("d4", 6)
	tabuleiro.selected_piece = casa("d4")
	assert_eq(tabuleiro.get_king_moves().size(), 8, "No centro, o rei tem 8 casas.")

	limpar_tabuleiro()
	colocar("a1", 6)
	colocar("b2", 1)
	tabuleiro.selected_piece = casa("a1")
	assert_eq(nomes(tabuleiro.get_king_moves()), ["a2", "b1"], "No canto e com peça própria em b2.")


func test_en_passant_gerado_a_partir_do_estado():
	limpar_tabuleiro()
	colocar("e5", 1)
	colocar("d5", -1)
	colocar("f5", -1)

	tabuleiro.selected_piece = casa("e5")
	assert_eq(nomes(tabuleiro.get_pawn_moves()), ["e6"], "Sem en passant guardado.")

	# O peão preto de d5 acabou de sair de d7.
	tabuleiro.en_passant = casa("d7")
	assert_eq(nomes(tabuleiro.get_pawn_moves()), ["d6", "e6"], "En passant pela esquerda.")

	# O peão preto de f5 acabou de sair de f7.
	tabuleiro.en_passant = casa("f7")
	assert_eq(nomes(tabuleiro.get_pawn_moves()), ["e6", "f6"], "En passant pela direita.")


func test_en_passant_das_pretas_gerado_a_partir_do_estado():
	limpar_tabuleiro()
	tabuleiro.white = false
	colocar("d4", -1)
	colocar("e4", 1)
	colocar("c4", 1)
	tabuleiro.selected_piece = casa("d4")

	tabuleiro.en_passant = casa("e2")
	assert_eq(nomes(tabuleiro.get_pawn_moves()), ["d3", "e3"], "En passant das pretas para e3.")

	tabuleiro.en_passant = casa("c2")
	assert_eq(nomes(tabuleiro.get_pawn_moves()), ["c3", "d3"], "En passant das pretas para c3.")

