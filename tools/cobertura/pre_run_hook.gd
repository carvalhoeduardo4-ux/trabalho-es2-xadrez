extends GutHookScript

# Gancho executado pelo GUT ANTES dos testes.
# Troca o código dos scripts medidos por uma versão instrumentada
# (com contadores de linha). Os arquivos no disco não são alterados.

const Instrumentador = preload("res://tools/cobertura/instrumentador.gd")

# Scripts do jogo cuja cobertura será medida.
const SCRIPTS_MEDIDOS = [
	"res://Scripts/chess.gd",
	"res://Scripts/main_menu.gd",
]


func run():
	var dados = {}

	for i in SCRIPTS_MEDIDOS.size():
		var caminho = SCRIPTS_MEDIDOS[i]
		var chave = "_cobertura_" + str(i)
		var codigo = FileAccess.get_file_as_string(caminho)
		var resultado = Instrumentador.instrumentar(codigo, chave)

		# Um contador por linha do arquivo original (posição 0 não é usada).
		var contadores = []
		contadores.resize(codigo.split("\n").size() + 1)
		contadores.fill(0)
		Engine.set_meta(chave, contadores)

		var script: GDScript = load(caminho)
		script.source_code = resultado["codigo"]
		var erro = script.reload(true)

		if erro != OK:
			push_error("Cobertura: não foi possível instrumentar " + caminho)
			continue

		dados[caminho] = {
			"chave": chave,
			"codigo": codigo,
			"linhas": resultado["linhas"],
			"funcoes": resultado["funcoes"],
		}

	Engine.set_meta("_cobertura_dados", dados)
	gut.get_logger().log("Cobertura: %d script(s) instrumentado(s)." % dados.size())
