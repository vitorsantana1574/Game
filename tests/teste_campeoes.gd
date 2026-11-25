extends RefCounted
## Testes do catálogo de campeões e itens (data/campeoes/campeoes.json e data/itens/itens.json).

var executor: Object

const CLASSES: Array[String] = ["tanque", "assassino", "lutador", "mago", "suporte", "atirador"]
const POSICOES: Array[String] = ["topo", "selva", "meio", "atirador", "suporte"]


func teste_distribuicao_do_elenco() -> void:
	var todos: Array[Dictionary] = Jogo.listar_campeoes()
	executor.igual(todos.size(), 30, "30 campeões")
	for classe: String in CLASSES:
		executor.igual(Jogo.listar_campeoes({"classe": classe}).size(), 5, "5 campeões de %s" % classe)
	for posicao: String in POSICOES:
		var principal: int = 0
		for c: Dictionary in todos:
			if c["posicao_principal"] == posicao:
				principal += 1
		executor.igual(principal, 6, "6 campeões com %s como posição principal" % posicao)
	var curvas: Dictionary = {}
	for c: Dictionary in todos:
		curvas[c["curva"]] = int(curvas.get(c["curva"], 0)) + 1
	executor.igual(curvas, {"inicio": 10, "constante": 10, "fim": 10}, "10 campeões por curva de força")


func teste_ids_estaveis_e_unicos() -> void:
	var vistos: Dictionary = {}
	var ok: bool = true
	for id: String in CatalogoCampeoes.ids():
		ok = ok and not vistos.has(id) and id == id.to_lower() and not id.contains(" ")
		vistos[id] = true
	executor.verificar(ok, "IDs únicos, minúsculos e sem espaço")
	executor.verificar(CatalogoCampeoes.existe("veluria"), "Velúria existe pelo ID veluria")
	executor.igual(Jogo.detalhe_campeao("nao_existe"), {}, "ID desconhecido devolve {}")
	executor.igual(Jogo.atributos_campeao("nao_existe", 5), {}, "atributos de ID desconhecido devolvem {}")


func teste_ficha_publica_completa() -> void:
	var ok_hab: bool = true
	var ok_build: bool = true
	var ok_textos: bool = true
	for c: Dictionary in Jogo.listar_campeoes():
		var f: Dictionary = Jogo.detalhe_campeao(c["id"])
		var habs: Array = f["habilidades"]
		ok_hab = ok_hab and habs.size() == 3 and habs[2]["especial"] and habs[2]["nivel_minimo"] == 6
		var build: Array = f["build"]
		ok_build = ok_build and build.size() == 5 and build[0]["categoria"] == "bota"
		for item: Dictionary in build:
			ok_build = ok_build and not item.is_empty()
		for alt: Dictionary in f["itens_alternativos"]:
			ok_build = ok_build and not alt["item"].is_empty() and not alt["substitui"].is_empty()
		ok_textos = ok_textos and not String(f["passiva"]["efeito"]).is_empty() and not String(f["tema"]).is_empty()
		ok_textos = ok_textos and not String(f["classe_nome"]).is_empty() and not String(f["curva_nome"]).is_empty()
	executor.verificar(ok_hab, "toda ficha tem 3 habilidades e a 3ª é a especial do nível 6")
	executor.verificar(ok_build, "builds com bota + 4 itens existentes e alternativas válidas")
	executor.verificar(ok_textos, "textos públicos preenchidos")


func teste_nao_expoe_dados_internos() -> void:
	var texto: String = JSON.stringify(Jogo.detalhe_campeao("orvante"))
	executor.verificar(not texto.contains("\"mecanica\""), "a ficha pública não traz a mecânica interna")
	executor.verificar(not texto.contains("\"ajustes\""), "a ficha pública não traz os registros de calibração")
	executor.verificar(not texto.contains("meta"), "a ficha pública não traz força no patch")


func teste_atributos_por_nivel() -> void:
	var bruto: Dictionary = Dados.por_id(Dados.campeoes()["campeoes"], "orvante")
	var a1: Dictionary = Jogo.atributos_campeao("orvante", 1)
	var a16: Dictionary = Jogo.atributos_campeao("orvante", 16)
	executor.verificar(is_equal_approx(a1["vida"], snappedf(float(bruto["atributos"]["vida"][0]), 0.1)), "vida no nível 1 = base")
	var esperado: float = float(bruto["atributos"]["vida"][0]) + 15.0 * float(bruto["atributos"]["vida"][1])
	executor.verificar(absf(a16["vida"] - esperado) < 0.11, "vida no nível 16 = base + 15 × ganho")
	executor.igual(Jogo.atributos_campeao("orvante", 40)["nivel"], 16, "nível acima do máximo vira 16")
	executor.verificar(a16["velocidade_ataque"] > a1["velocidade_ataque"], "velocidade de ataque cresce com o nível")


func teste_textos_de_custo_e_dano() -> void:
	var veluria: Dictionary = Jogo.detalhe_campeao("veluria")
	executor.verificar(String(veluria["habilidades"][0]["custo_texto"]).ends_with("de mana"), "custo em mana")
	executor.verificar(String(veluria["habilidades"][0]["dano_texto"]).contains("poder mágico"), "texto de dano cita o poder mágico")
	var marulva: Dictionary = Jogo.detalhe_campeao("marulva")
	executor.verificar(String(marulva["habilidades"][0]["custo_texto"]).contains("vida máxima"), "custo em vida")
	var fulgaveu: Dictionary = Jogo.detalhe_campeao("fulgaveu")
	executor.igual(fulgaveu["habilidades"][2]["dano_texto"], "", "habilidade sem dano tem texto de dano vazio")


func teste_itens() -> void:
	var todos: Array[Dictionary] = Jogo.listar_itens()
	executor.igual(todos.size(), 33, "27 itens + 6 botas")
	executor.igual(todos[0]["categoria"], "bota", "botas primeiro")
	var orbe: Dictionary = Jogo.detalhe_item("orbe_da_tempestade")
	executor.verificar(orbe["preco"] > 0 and orbe.has("passiva"), "ficha de item com preço e passiva")
	executor.igual(Jogo.detalhe_item("nao_existe"), {}, "item desconhecido devolve {}")
	var ok: bool = true
	for item: Dictionary in Jogo.listar_itens({"classe": "suporte"}):
		ok = ok and (item["classes"].has("todas") or item["classes"].has("suporte"))
	executor.verificar(ok, "filtro por classe só traz itens permitidos")
