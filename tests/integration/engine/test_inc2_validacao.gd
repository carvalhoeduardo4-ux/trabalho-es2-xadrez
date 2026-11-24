extends "res://tests/integration/base_integracao.gd"

# ENGINE · INCREMENTO 2: M1 + M2 + M3 (validação de regras)
#
# Verifica a integração entre a geração de movimentos e a validação:
# a detecção de ataques precisa bater com o movimento de cada peça, e o filtro
# de get_moves() deve remover os lances que deixam o próprio rei em xeque.
#
# Classes cobertas: ataque por cada tipo de peça e cor; ataque bloqueado;
# cravada em coluna e em diagonal; xeque simples, de cavalo e duplo;
# en passant que expõe o rei; roque dos dois lados e das duas cores.


# [descrição, peça atacante, casa do atacante, casa atacada]
var ataques = [
	["peão branco", 1, "d4", "e5"],
	["peão preto", -1, "d5", "e4"],
	["cavalo", 2, "d4", "f5"],
	["bispo", 3, "a1", "h8"],
	["torre", -4, "a8", "a1"],
	["rainha", -5, "d8", "h4"],
	["rei", 6, "e4", "e5"],
]


func test_ataque_detectado_para_cada_tipo_de_peca(p = use_parameters(ataques)):
	limpar_tabuleiro()
	var atacante_branco = p[1] > 0
	colocar(p[2], p[1])

	assert_true(
		tabuleiro.is_square_attacked(casa(p[3]), atacante_branco),
		"O " + p[0] + " em " + p[2] + " deve atacar " + p[3] + "."
	)

	# Com o rei adversário na casa atacada, ele está em xeque.
	colocar(p[3], -6 if atacante_branco else 6)

	assert_true(
		tabuleiro.is_in_check(not atacante_branco),
		"O rei em " + p[3] + " deve estar em xeque pelo " + p[0] + "."
	)


func test_ataques_batem_com_os_movimentos_gerados():
	limpar_tabuleiro()
	colocar("d4", 5)
	colocar("d7", -1)
	colocar("f2", 1)

	tabuleiro.selected_piece = casa("d4")

	# Toda casa para onde a rainha pode ir é uma casa que ela ataca.
	for destino in tabuleiro.get_queen_moves():
		assert_true(
			tabuleiro.is_square_attacked(destino, true),
			"A rainha deve atacar " + nome_da_casa(destino) + "."
		)


func test_peca_no_caminho_bloqueia_o_ataque():
	limpar_tabuleiro()
	colocar("a1", 4)
	colocar("a4", -1)

	assert_true(tabuleiro.is_square_attacked(casa("a4"), true), "A torre ataca a peça em a4.")
	assert_false(tabuleiro.is_square_attacked(casa("a5"), true), "Mas não a casa atrás dela.")


func test_peao_nao_ataca_para_frente():
	limpar_tabuleiro()
	colocar("e4", 1)

	assert_false(tabuleiro.is_square_attacked(casa("e5"), true), "O peão só ataca na diagonal.")
	assert_true(tabuleiro.is_square_attacked(casa("d5"), true))


func test_peca_cravada_na_coluna():
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("e2", 3)    # bispo branco cravado
	colocar("e8", -4)
	colocar("a8", -6)

	assert_gt(movimentos_brutos("e2").size(), 0, "O gerador do bispo produz movimentos.")
	assert_eq(movimentos_de("e2"), [], "O bispo cravado não pode sair da coluna.")

	# Um peão cravado na mesma coluna ainda pode avançar, pois continua bloqueando.
	colocar("e2", 1)
	assert_eq(movimentos_de("e2"), ["e3", "e4"])


func test_peca_cravada_na_diagonal():
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("d2", 4)    # torre branca cravada na diagonal
	colocar("a5", -3)
	colocar("h8", -6)

	assert_eq(movimentos_de("d2"), [], "A torre não pode sair da diagonal.")

	# Um bispo cravado na diagonal pode andar por ela e capturar quem crava.
	colocar("d2", 3)
	assert_eq(movimentos_de("d2"), ["a5", "b4", "c3"])


func test_rei_nao_vai_para_casa_atacada_nem_captura_peca_defendida():
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("d8", -4)   # controla a coluna d
	colocar("f2", -1)   # peão preto defendido pelo cavalo
	colocar("g4", -2)
	colocar("h8", -6)

	assert_eq(
		movimentos_de("e1"), ["e2", "f1"],
		"O rei não vai para d1/d2 (torre) nem captura em f2 (defendido)."
	)


func test_xeque_simples_so_permite_bloquear_capturar_ou_fugir():
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("a3", 4)    # pode bloquear em e3
	colocar("h5", 3)    # pode bloquear em e2 ou capturar a torre em e8
	colocar("e8", -4)
	colocar("h7", -6)

	assert_true(tabuleiro.is_in_check(true))
	assert_eq(movimentos_de("a3"), ["e3"], "A torre só pode bloquear em e3.")
	assert_eq(movimentos_de("h5"), ["e2", "e8"], "O bispo bloqueia em e2 ou captura em e8.")
	assert_eq(movimentos_de("e1"), ["d1", "d2", "f1", "f2"], "O rei pode sair da coluna.")


func test_xeque_de_cavalo_nao_pode_ser_bloqueado():
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("d3", -2)   # cavalo preto dá xeque
	colocar("a3", 4)    # torre branca pode capturar o cavalo
	colocar("b1", 4)    # torre branca não ajuda
	colocar("h8", -6)

	assert_true(tabuleiro.is_in_check(true))
	assert_eq(movimentos_de("a3"), ["d3"], "Só capturar o cavalo resolve.")
	assert_eq(movimentos_de("b1"), [], "Não existe bloqueio contra cavalo.")


func test_xeque_duplo_so_o_rei_pode_se_mover():
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("e8", -4)   # xeque pela coluna
	colocar("d3", -2)   # xeque de cavalo
	colocar("a3", 4)    # capturaria o cavalo, mas o xeque da torre continua
	colocar("a8", -6)

	assert_eq(movimentos_de("a3"), [], "No xeque duplo, nenhuma outra peça resolve.")
	assert_gt(movimentos_de("e1").size(), 0, "O rei ainda tem para onde fugir.")


func test_en_passant_que_expoe_o_rei_e_removido():
	limpar_tabuleiro()
	# Rei branco, peão branco, peão preto e torre preta na mesma fileira.
	colocar("a5", 6)
	colocar("b5", 1)
	colocar("c5", -1)
	colocar("h5", -4)
	colocar("h8", -6)
	tabuleiro.en_passant = casa("c7")

	assert_has(movimentos_brutos_nomes("b5"), "c6", "O gerador produz o en passant.")
	assert_does_not_have(movimentos_de("b5"), "c6", "Mas ele exporia o rei à torre.")


# [descrição, branco?, casa do rei, casa da torre, destino do rei]
var roques = [
	["pequeno das brancas", true, "e1", "h1", "g1"],
	["grande das brancas", true, "e1", "a1", "c1"],
	["pequeno das pretas", false, "e8", "h8", "g8"],
	["grande das pretas", false, "e8", "a8", "c8"],
]


func test_roque_gerado_com_caminho_livre(p = use_parameters(roques)):
	limpar_tabuleiro()
	var s = 1 if p[1] else -1
	colocar(p[2], 6 * s)
	colocar(p[3], 4 * s)
	colocar("a4" if p[1] else "a5", -6 * s)   # rei adversário longe
	tabuleiro.white = p[1]
	liberar_roque()

	assert_has(movimentos_de(p[2]), p[4], "O roque " + p[0] + " deve ser gerado.")


func test_roque_bloqueado_por_peca_no_caminho():
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("a1", 4)
	colocar("b1", 2)    # cavalo entre o rei e a torre
	colocar("h8", -6)
	liberar_roque()

	assert_does_not_have(movimentos_de("e1"), "c1")


func test_roque_respeita_casas_atacadas():
	limpar_tabuleiro()
	colocar("e1", 6)
	colocar("h1", 4)
	colocar("a1", 4)
	colocar("h8", -6)
	liberar_roque()

	# Casa de passagem atacada (f1): sem roque pequeno.
	colocar("f8", -4)
	assert_does_not_have(movimentos_de("e1"), "g1", "Não pode passar por f1 atacada.")
	assert_has(movimentos_de("e1"), "c1", "O roque grande continua possível.")

	# Casa de destino atacada (g1): sem roque pequeno.
	colocar("f8", 0)
	colocar("g8", -4)
	assert_does_not_have(movimentos_de("e1"), "g1", "Não pode parar em g1 atacada.")

	# b1 atacada não impede o roque grande (o rei não passa por b1).
	colocar("g8", 0)
	colocar("b8", -4)
	assert_has(movimentos_de("e1"), "c1", "b1 atacada não impede o roque grande.")

	# Rei em xeque: nenhum roque.
	colocar("b8", 0)
	colocar("e8", -4)
	assert_does_not_have(movimentos_de("e1"), "g1", "Não pode rocar em xeque.")
	assert_does_not_have(movimentos_de("e1"), "c1", "Não pode rocar em xeque.")


func test_roque_das_pretas_respeita_casas_atacadas():
	limpar_tabuleiro()
	tabuleiro.white = false
	colocar("e8", -6)
	colocar("h8", -4)
	colocar("a4", 6)
	colocar("f1", 4)    # torre branca ataca f8
	liberar_roque()

	assert_does_not_have(movimentos_de("e8"), "g8")


# Movimentos do gerador, sem o filtro de xeque (M2 puro).
func movimentos_brutos(nome: String) -> Array:
	tabuleiro.selected_piece = casa(nome)
	match abs(peca_em(nome)):
		1: return tabuleiro.get_pawn_moves()
		2: return tabuleiro.get_knight_moves()
		3: return tabuleiro.get_bishop_moves()
		4: return tabuleiro.get_rook_moves()
		5: return tabuleiro.get_queen_moves()
		6: return tabuleiro.get_king_moves()
	return []


func movimentos_brutos_nomes(nome: String) -> Array:
	return nomes(movimentos_brutos(nome))
