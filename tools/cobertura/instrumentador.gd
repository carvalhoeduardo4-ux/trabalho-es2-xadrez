extends RefCounted

# Instrumentador de cobertura de linhas para GDScript.
#
# Recebe o código de um script e devolve uma versão com um contador antes de
# cada linha executável. Os contadores ficam em Engine.get_meta(chave), um
# Array com uma posição por linha do arquivo original.
#
# Não conta como linha executável: linhas vazias e comentários, declarações
# fora de funções (var, const, extends...), a linha "func", "else:", "elif",
# os padrões de "match" e as linhas de continuação de expressões entre
# parênteses/colchetes/chaves.


# Devolve { "codigo": String, "linhas": Array[int], "funcoes": Dictionary }
#   linhas  -> números (1 a N) das linhas executáveis do arquivo original
#   funcoes -> nome da função -> { "linha": int, "linhas": Array[int] }
static func instrumentar(codigo: String, chave: String) -> Dictionary:
	var origem = codigo.split("\n")
	var saida = PackedStringArray()
	var linhas_executaveis = []
	var funcoes = {}

	var profundidade = 0
	var funcao_atual = ""
	var pilha_match = []

	for i in origem.size():
		var linha = origem[i]
		var numero = i + 1
		var texto = linha.strip_edges()
		var recuo = linha.substr(0, linha.length() - linha.lstrip(" \t").length())
		var nivel = recuo.length()

		# Início e fim de funções
		if linha.begins_with("func ") or linha.begins_with("static func "):
			var nome = linha.replace("static func ", "").replace("func ", "").split("(")[0].strip_edges()
			funcao_atual = nome
			funcoes[nome] = {"linha": numero, "linhas": []}
		elif linha != "" and not (linha[0] == " " or linha[0] == "\t") and not texto.begins_with("#"):
			funcao_atual = ""

		# Blocos "match": as linhas de padrão não são executáveis
		if texto != "" and not texto.begins_with("#"):
			while pilha_match.size() > 0 and nivel <= pilha_match[-1]:
				pilha_match.pop_back()
		var padrao_de_match = pilha_match.size() > 0 and nivel == pilha_match[-1] + 1 and profundidade == 0

		var profundidade_inicial = profundidade
		profundidade += _saldo_de_parenteses(linha)

		var ignorar = (
			profundidade_inicial > 0
			or texto == ""
			or texto.begins_with("#")
			or recuo == ""
			or funcao_atual == ""
			or texto.begins_with("else:")
			or texto.begins_with("elif ")
			or padrao_de_match
		)

		if not ignorar:
			saida.append(recuo + "Engine.get_meta(\"" + chave + "\")[" + str(numero) + "] += 1")
			linhas_executaveis.append(numero)
			funcoes[funcao_atual]["linhas"].append(numero)

		saida.append(linha)

		if texto.begins_with("match ") and profundidade == 0:
			pilha_match.append(nivel)

	return {
		"codigo": "\n".join(saida),
		"linhas": linhas_executaveis,
		"funcoes": funcoes,
	}


# Quantos parênteses/colchetes/chaves a linha abre menos quantos fecha,
# ignorando o que está dentro de strings e depois de "#".
static func _saldo_de_parenteses(linha: String) -> int:
	var saldo = 0
	var aspas = ""

	for c in linha:
		if aspas != "":
			if c == aspas:
				aspas = ""
			continue
		if c == "\"" or c == "'":
			aspas = c
		elif c == "#":
			break
		elif c in "([{":
			saldo += 1
		elif c in ")]}":
			saldo -= 1

	return saldo
