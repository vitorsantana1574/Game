class_name CatalogoCampeoes
extends RefCounted
## Catálogo de campeões e itens de Crystal Legends, para leitura da interface.
##
## Fonte: data/campeoes/campeoes.json (gerado por tools/conversao/converter_campeoes.py) e data/itens/itens.json.
## As fichas públicas trazem textos, atributos e builds. A mecânica interna da simulação ("mecanica"), os registros
## de calibração ("ajustes") e a força no patch (meta) não saem daqui.

const NOMES_CLASSE: Dictionary = {
	"tanque": "Tanque", "assassino": "Assassino", "lutador": "Lutador",
	"mago": "Mago", "suporte": "Suporte", "atirador": "Atirador",
}
const NOMES_POSICAO: Dictionary = {
	"topo": "Topo", "selva": "Selva", "meio": "Meio", "atirador": "Atirador", "suporte": "Suporte",
}
const NOMES_CURVA: Dictionary = {
	"inicio": "Forte no início", "fim": "Forte no fim", "constante": "Constante", "pico_nivel_6": "Pico no nível 6",
}
const NOMES_RECURSO: Dictionary = {
	"mana": "Mana", "energia": "Energia", "furia": "Fúria", "vida": "Vida", "nenhum": "Sem recurso",
}
const NOMES_DANO: Dictionary = {
	"fisico": "físico", "magico": "mágico", "verdadeiro": "verdadeiro", "misto": "misto",
}
const NOMES_ATRIBUTO: Dictionary = {
	"vida": "Vida", "armadura": "Armadura", "resistencia_magica": "Resistência mágica",
	"dano_fisico": "Dano físico", "velocidade_ataque": "Velocidade de ataque",
	"alcance": "Alcance", "velocidade_movimento": "Velocidade de movimento",
}
const NIVEL_MAXIMO: int = 16


static func _dados() -> Array:
	return Dados.campeoes()["campeoes"]


## IDs estáveis de todos os campeões, em ordem alfabética do nome.
static func ids() -> Array[String]:
	var lista: Array = _dados().duplicate()
	lista.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["nome"]).naturalnocasecmp_to(b["nome"]) < 0)
	var saida: Array[String] = []
	for c: Dictionary in lista:
		saida.append(String(c["id"]))
	return saida


static func existe(id: String) -> bool:
	return not Dados.por_id(_dados(), id).is_empty()


## Resumo para listas e grades. Filtros opcionais: "classe", "posicao" (qualquer posição da ficha), "curva".
static func listar(filtros: Dictionary = {}) -> Array[Dictionary]:
	var saida: Array[Dictionary] = []
	for id: String in ids():
		var c: Dictionary = Dados.por_id(_dados(), id)
		if filtros.has("classe") and c["classe"] != filtros["classe"]:
			continue
		if filtros.has("posicao") and not (c["posicoes"] as Array).has(filtros["posicao"]):
			continue
		if filtros.has("curva") and c["curva_de_forca"] != filtros["curva"]:
			continue
		saida.append(_resumo(c))
	return saida


static func _resumo(c: Dictionary) -> Dictionary:
	var posicoes: Array[String] = []
	var nomes_posicoes: Array[String] = []
	for p: Variant in c["posicoes"]:
		posicoes.append(String(p))
		nomes_posicoes.append(NOMES_POSICAO.get(p, String(p)))
	return {
		"id": c["id"],
		"nome": c["nome"],
		"titulo": c["titulo"],
		"classe": c["classe"],
		"classe_nome": NOMES_CLASSE.get(c["classe"], c["classe"]),
		"posicoes": posicoes,
		"posicoes_nomes": nomes_posicoes,
		"posicao_principal": posicoes[0],
		"curva": c["curva_de_forca"],
		"curva_nome": NOMES_CURVA.get(c["curva_de_forca"], c["curva_de_forca"]),
		"dificuldade": int(c["dificuldade"]),
		"dependencia_macro": int(c["dependencia_macro"]),
		"recurso": c["recurso"]["tipo"],
		"recurso_nome": NOMES_RECURSO.get(c["recurso"]["tipo"], c["recurso"]["tipo"]),
	}


## Ficha completa e pública de um campeão. {} se o ID não existir.
static func detalhe(id: String) -> Dictionary:
	var c: Dictionary = Dados.por_id(_dados(), id)
	if c.is_empty():
		return {}
	var ficha: Dictionary = _resumo(c)
	ficha["tema"] = c["tema"]
	ficha["forte_contra"] = c["forte_contra"]
	ficha["fraco_contra"] = c["fraco_contra"]
	ficha["recurso_detalhe"] = _recurso_publico(c["recurso"])
	ficha["atributos"] = atributos(id, 1)
	ficha["crescimento"] = _crescimento(c["atributos"])
	ficha["passiva"] = {
		"nome": c["passiva"]["nome"],
		"descricao": c["passiva"]["descricao"],
		"efeito": c["passiva"]["efeito"],
	}
	var habilidades: Array[Dictionary] = []
	for h: Dictionary in c["habilidades"]:
		habilidades.append(_habilidade_publica(c, h))
	ficha["habilidades"] = habilidades
	ficha["build"] = _build_publica(c)
	ficha["itens_alternativos"] = _alternativos_publicos(c)
	return ficha


static func _recurso_publico(r: Dictionary) -> Dictionary:
	var saida: Dictionary = {"tipo": r["tipo"], "nome": NOMES_RECURSO.get(r["tipo"], r["tipo"])}
	if r.has("maximo"):
		saida["maximo_nivel_1"] = r["maximo"][0]
		saida["maximo_por_nivel"] = r["maximo"][1]
	if r.has("regeneracao_5s"):
		saida["regeneracao_5s_nivel_1"] = r["regeneracao_5s"][0]
		saida["regeneracao_5s_por_nivel"] = r["regeneracao_5s"][1]
	return saida


static func _crescimento(a: Dictionary) -> Dictionary:
	var saida: Dictionary = {}
	for chave: String in ["vida", "armadura", "resistencia_magica", "dano_fisico"]:
		saida[chave] = float(a[chave][1])
	saida["velocidade_ataque_pct"] = float(a["velocidade_ataque"][1])
	return saida


## Atributos de um campeão num nível (1 a 16), sem itens. {} se o ID não existir.
static func atributos(id: String, nivel: int) -> Dictionary:
	var c: Dictionary = Dados.por_id(_dados(), id)
	if c.is_empty():
		return {}
	var n: int = clampi(nivel, 1, NIVEL_MAXIMO)
	var a: Dictionary = c["atributos"]
	var saida: Dictionary = {"nivel": n}
	for chave: String in ["vida", "armadura", "resistencia_magica", "dano_fisico"]:
		saida[chave] = snappedf(float(a[chave][0]) + float(a[chave][1]) * (n - 1), 0.1)
	var va: Array = a["velocidade_ataque"]
	saida["velocidade_ataque"] = snappedf(float(va[0]) * (1.0 + float(va[1]) / 100.0 * (n - 1)), 0.001)
	saida["alcance"] = int(a["alcance"])
	saida["velocidade_movimento"] = int(a["velocidade_movimento"])
	return saida


static func _habilidade_publica(c: Dictionary, h: Dictionary) -> Dictionary:
	var mec: Dictionary = h.get("mecanica", {})
	var tipo_recurso: String = c["recurso"]["tipo"]
	var custo: Variant = h["custo"]
	var custo_texto: String = ""
	match tipo_recurso:
		"mana":
			custo_texto = "%d de mana" % roundi(float(custo))
		"energia":
			custo_texto = "%d de energia" % roundi(float(custo))
		"furia":
			custo_texto = "%d de fúria ao lançar com a barra cheia" % roundi(float(custo))
		"vida":
			custo_texto = "%s%% da vida máxima" % _num(float(custo))
		_:
			custo_texto = "Sem custo"
	return {
		"posicao": int(h["posicao"]),
		"nome": h["nome"],
		"descricao": h["descricao"],
		"narracao": h["narracao"],
		"tipo_dano": h["tipo_dano"],
		"alvo": h["alvo"],
		"efeitos": h["efeitos"],
		"tags": h["tags"],
		"especial": int(h["posicao"]) == 3,
		"nivel_minimo": int(mec.get("nivel_minimo", 1)),
		"recarga": float(h["recarga"]),
		"custo": custo,
		"custo_texto": custo_texto,
		"dano_texto": texto_dano(h),
	}


## Texto do dano de uma habilidade, ex.: "92 (+3,6 por nível) + 24% do poder mágico, dano mágico".
## Habilidades sem dano devolvem "".
static func texto_dano(h: Dictionary) -> String:
	var d: Dictionary = h["dano"]
	var base: Array = d["base"]
	var p: Dictionary = d["proporcoes"]
	var partes: Array[String] = []
	if float(base[0]) > 0.0 or float(base[1]) > 0.0:
		var texto: String = _num(float(base[0]))
		if float(base[1]) > 0.0:
			texto += " (+%s por nível)" % _num(float(base[1]))
		partes.append(texto)
	var rotulos: Dictionary = {
		"dano_fisico_bonus": "do dano físico bônus",
		"poder_magico": "do poder mágico",
		"vida_maxima_propria_pct": "da própria vida máxima",
		"vida_maxima_alvo_pct": "da vida máxima do alvo",
		"vida_perdida_alvo_pct": "da vida perdida do alvo",
	}
	for chave: String in rotulos:
		var v: float = float(p.get(chave, 0.0))
		if v > 0.0:
			partes.append("%s%% %s" % [_num(v * 100.0), rotulos[chave]])
	if partes.is_empty():
		return ""
	return "%s, dano %s" % [" + ".join(partes), NOMES_DANO.get(h["tipo_dano"], h["tipo_dano"])]


static func _build_publica(c: Dictionary) -> Array[Dictionary]:
	var saida: Array[Dictionary] = []
	for item_id: Variant in c["build_ids"]:
		saida.append(resumo_item(String(item_id)))
	return saida


static func _alternativos_publicos(c: Dictionary) -> Array[Dictionary]:
	var saida: Array[Dictionary] = []
	for alt: Dictionary in c["itens_alternativos"]:
		saida.append({
			"item": resumo_item(String(alt["item_id"])),
			"substitui": resumo_item(String(alt["substitui_id"])),
			"quando": alt["quando"],
			"condicao": alt.get("condicao", "situacional"),
		})
	return saida


# --- Itens -----------------------------------------------------------------------

static func _todos_itens() -> Array:
	var d: Dictionary = Dados.itens()
	var lista: Array = []
	lista.append_array(d["botas"])
	lista.append_array(d["itens"])
	return lista


static func _item(id: String) -> Dictionary:
	var item: Dictionary = Dados.por_id(_todos_itens(), id)
	if item.is_empty() and Dados.itens()["item_inicial_suporte"]["id"] == id:
		item = Dados.itens()["item_inicial_suporte"]
	return item


## Resumo de um item para listas e builds. {} se o ID não existir.
static func resumo_item(id: String) -> Dictionary:
	var item: Dictionary = _item(id)
	if item.is_empty():
		return {}
	var e_bota: bool = not Dados.por_id(Dados.itens()["botas"], id).is_empty()
	return {
		"id": item["id"],
		"nome": item["nome"],
		"preco": int(item["preco"]),
		"categoria": "bota" if e_bota else String(item.get("categoria", "suporte")),
	}


## Ficha pública de um item: atributos, passiva, classes que podem comprar e preço. {} se não existir.
static func detalhe_item(id: String) -> Dictionary:
	var item: Dictionary = _item(id)
	if item.is_empty():
		return {}
	var ficha: Dictionary = resumo_item(id)
	ficha["ideia"] = item.get("ideia", "")
	var atributos_texto: Array[Dictionary] = []
	var nomes: Dictionary = Dados.combate()["atributos"]
	for chave: String in item["estatisticas"]:
		var nome: String = String(nomes.get(chave, {}).get("nome", chave)) if nomes.get(chave) is Dictionary else chave
		atributos_texto.append({"id": chave, "nome": nome, "valor": item["estatisticas"][chave]})
	ficha["atributos"] = atributos_texto
	ficha["classes"] = item.get("classes", ["suporte"])
	if item.has("passiva"):
		ficha["passiva"] = {"nome": item["passiva"]["nome"], "descricao": item["passiva"]["descricao"]}
	return ficha


## Todos os itens (botas primeiro). Filtro opcional "classe": só os que essa classe pode comprar.
static func listar_itens(filtros: Dictionary = {}) -> Array[Dictionary]:
	var saida: Array[Dictionary] = []
	for item: Dictionary in _todos_itens():
		var classes: Array = item.get("classes", [])
		if filtros.has("classe") and not (classes.has("todas") or classes.has(filtros["classe"])):
			continue
		saida.append(detalhe_item(String(item["id"])))
	return saida


static func _num(v: float) -> String:
	# Até 2 casas, vírgula decimal, sem zeros sobrando: 3.6 -> "3,6"; 92.0 -> "92".
	var texto: String = String.num(snappedf(v, 0.01))
	return texto.replace(".", ",")
