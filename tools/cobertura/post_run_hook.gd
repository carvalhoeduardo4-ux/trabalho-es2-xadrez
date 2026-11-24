extends GutHookScript

# Gancho executado pelo GUT DEPOIS dos testes.
# Lê os contadores de linha, mostra o resumo no terminal e gera:
#   cobertura/lcov.info       -> formato padrão (VS Code Coverage Gutters, Codecov, genhtml)
#   cobertura/relatorio.html  -> relatório visual, abre em qualquer navegador

const PASTA_SAIDA = "res://cobertura/"


func run():
	if not Engine.has_meta("_cobertura_dados"):
		push_error("Cobertura: o pre_run_hook não foi executado.")
		return

	var dados = Engine.get_meta("_cobertura_dados")
	var logger = gut.get_logger()
	var lcov = PackedStringArray()
	var resumo = []
	var total_linhas = 0
	var total_cobertas = 0

	for caminho in dados:
		var d = dados[caminho]
		var contadores = Engine.get_meta(d["chave"])
		var cobertas = 0
		for n in d["linhas"]:
			if contadores[n] > 0:
				cobertas += 1

		var funcoes_com_codigo = 0
		var funcoes_cobertas = 0
		for nome in d["funcoes"]:
			var linhas_da_funcao = d["funcoes"][nome]["linhas"]
			if linhas_da_funcao.is_empty():
				continue
			funcoes_com_codigo += 1
			for n in linhas_da_funcao:
				if contadores[n] > 0:
					funcoes_cobertas += 1
					break

		total_linhas += d["linhas"].size()
		total_cobertas += cobertas
		resumo.append({
			"arquivo": caminho.replace("res://", ""),
			"linhas": d["linhas"].size(),
			"cobertas": cobertas,
			"funcoes": funcoes_com_codigo,
			"funcoes_cobertas": funcoes_cobertas,
			"contadores": contadores,
			"executaveis": d["linhas"],
			"codigo": d["codigo"],
		})

		lcov.append_array(_registro_lcov(caminho.replace("res://", ""), d, contadores))

	# Resumo no terminal
	logger.log("")
	logger.log("==================== COBERTURA DE CÓDIGO ====================")
	for r in resumo:
		logger.log("%-24s linhas %4d/%-4d (%5.1f%%)   funções %3d/%-3d" % [
			r["arquivo"], r["cobertas"], r["linhas"], _porcento(r["cobertas"], r["linhas"]),
			r["funcoes_cobertas"], r["funcoes"]])
	logger.log("%-24s linhas %4d/%-4d (%5.1f%%)" % [
		"TOTAL", total_cobertas, total_linhas, _porcento(total_cobertas, total_linhas)])
	logger.log("==============================================================")

	# Arquivos de saída
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_SAIDA))
	_salvar(PASTA_SAIDA + "lcov.info", "\n".join(lcov) + "\n")
	_salvar(PASTA_SAIDA + "relatorio.html", _relatorio_html(resumo, total_cobertas, total_linhas))
	logger.log("Relatórios salvos em " + ProjectSettings.globalize_path(PASTA_SAIDA))


func _registro_lcov(arquivo: String, d: Dictionary, contadores: Array) -> PackedStringArray:
	var r = PackedStringArray()
	r.append("TN:")
	r.append("SF:" + arquivo)

	var funcoes_com_codigo = 0
	var funcoes_cobertas = 0
	for nome in d["funcoes"]:
		var f = d["funcoes"][nome]
		if f["linhas"].is_empty():
			continue
		r.append("FN:%d,%s" % [f["linha"], nome])
	for nome in d["funcoes"]:
		var f = d["funcoes"][nome]
		if f["linhas"].is_empty():
			continue
		var chamadas = contadores[f["linhas"][0]]
		funcoes_com_codigo += 1
		if chamadas > 0:
			funcoes_cobertas += 1
		r.append("FNDA:%d,%s" % [chamadas, nome])
	r.append("FNF:%d" % funcoes_com_codigo)
	r.append("FNH:%d" % funcoes_cobertas)

	var cobertas = 0
	for n in d["linhas"]:
		r.append("DA:%d,%d" % [n, contadores[n]])
		if contadores[n] > 0:
			cobertas += 1
	r.append("LF:%d" % d["linhas"].size())
	r.append("LH:%d" % cobertas)
	r.append("end_of_record")
	return r


func _relatorio_html(resumo: Array, total_cobertas: int, total_linhas: int) -> String:
	var h = PackedStringArray()
	h.append("<!DOCTYPE html><html lang='pt-BR'><head><meta charset='utf-8'><title>Cobertura de código</title>")
	h.append("<style>body{font-family:system-ui,sans-serif;margin:2rem;color:#222}")
	h.append("table.resumo{border-collapse:collapse;margin-bottom:2rem}table.resumo td,table.resumo th{padding:.4rem .8rem;border-bottom:1px solid #ddd;text-align:left}")
	h.append("pre{margin:0;font-size:12px;line-height:1.45}.l{display:flex}.n{width:3.5rem;color:#888;text-align:right;padding-right:.6rem;user-select:none}")
	h.append(".c{width:3.5rem;color:#666;text-align:right;padding-right:.6rem}.ok{background:#e3f6e3}.nao{background:#fbe0e0}")
	h.append("h2{margin-top:2.5rem}</style></head><body>")
	h.append("<h1>Cobertura de código dos testes de integração</h1>")
	h.append("<p>Total: <b>%d de %d linhas executáveis (%.1f%%)</b>. Verde: linha executada pelos testes. Vermelho: linha não executada. Sem cor: não é linha executável.</p>" % [total_cobertas, total_linhas, _porcento(total_cobertas, total_linhas)])

	h.append("<table class='resumo'><tr><th>Arquivo</th><th>Linhas</th><th>%</th><th>Funções</th></tr>")
	for r in resumo:
		h.append("<tr><td><a href='#%s'>%s</a></td><td>%d / %d</td><td>%.1f%%</td><td>%d / %d</td></tr>" % [
			r["arquivo"], r["arquivo"], r["cobertas"], r["linhas"], _porcento(r["cobertas"], r["linhas"]),
			r["funcoes_cobertas"], r["funcoes"]])
	h.append("</table>")

	for r in resumo:
		h.append("<h2 id='%s'>%s — %.1f%%</h2><pre>" % [r["arquivo"], r["arquivo"], _porcento(r["cobertas"], r["linhas"])])
		var linhas = r["codigo"].split("\n")
		for i in linhas.size():
			var n = i + 1
			var classe = ""
			var vezes = ""
			if n in r["executaveis"]:
				classe = "ok" if r["contadores"][n] > 0 else "nao"
				vezes = str(r["contadores"][n]) + "×"
			h.append("<div class='l %s'><span class='n'>%d</span><span class='c'>%s</span><span>%s</span></div>" % [
				classe, n, vezes, linhas[i].xml_escape().replace("\t", "    ")])
		h.append("</pre>")

	h.append("</body></html>")
	return "\n".join(h)


func _salvar(caminho: String, conteudo: String):
	var arquivo = FileAccess.open(caminho, FileAccess.WRITE)
	if arquivo == null:
		push_error("Cobertura: não foi possível salvar " + caminho)
		return
	arquivo.store_string(conteudo)
	arquivo.close()


func _porcento(parte: int, total: int) -> float:
	return 100.0 * parte / total if total > 0 else 0.0
