extends GutTest

func test_ambiente_funcionando():
	var resultado = 2 + 2

	assert_eq(resultado, 4, "O ambiente de testes deve funcionar.")
