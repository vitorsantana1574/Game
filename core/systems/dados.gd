class_name Dados
extends RefCounted
## Carrega os arquivos JSON de `data/` e guarda em cache.
## Toda constante de jogo vem daqui, nunca fixa no código.

const DIFICULDADES: String = "res://data/config/dificuldades.json"
const BALANCEAMENTO: String = "res://data/config/balanceamento.json"
const NOMES_JOGADORES: String = "res://data/nomes/jogadores.json"
const CONTRATOS: String = "res://data/config/contratos.json"
const MERCADO: String = "res://data/config/mercado.json"
const TECNICOS: String = "res://data/config/tecnicos.json"
const CAMPEOES: String = "res://data/campeoes/campeoes.json"
const ITENS: String = "res://data/itens/itens.json"
const COMBATE: String = "res://data/config/combate.json"
const DRAFT: String = "res://data/config/draft.json"
const PARTIDA: String = "res://data/config/partida.json"
const MAPA: String = "res://data/config/mapa.json"
const CURVAS: String = "res://data/campeoes/curvas_de_forca.json"
const NARRACAO: String = "res://data/narracao/narracao.json"

static var _cache: Dictionary = {}


## Devolve o conteúdo de um arquivo JSON de dados. Falha alto se o arquivo estiver quebrado.
static func carregar(caminho: String) -> Dictionary:
	if _cache.has(caminho):
		return _cache[caminho]
	var texto: String = FileAccess.get_file_as_string(caminho)
	assert(not texto.is_empty(), "Arquivo de dados vazio ou ausente: %s" % caminho)
	var conteudo: Variant = JSON.parse_string(texto)
	assert(conteudo is Dictionary, "JSON inválido em %s" % caminho)
	_cache[caminho] = conteudo
	return conteudo


static func dificuldades() -> Dictionary:
	return carregar(DIFICULDADES)


static func balanceamento() -> Dictionary:
	return carregar(BALANCEAMENTO)


static func nomes_jogadores() -> Dictionary:
	return carregar(NOMES_JOGADORES)


static func contratos() -> Dictionary:
	return carregar(CONTRATOS)


static func mercado() -> Dictionary:
	return carregar(MERCADO)


static func tecnicos() -> Dictionary:
	return carregar(TECNICOS)


static func campeoes() -> Dictionary:
	return carregar(CAMPEOES)


static func itens() -> Dictionary:
	return carregar(ITENS)


static func combate() -> Dictionary:
	return carregar(COMBATE)


static func draft() -> Dictionary:
	return carregar(DRAFT)


static func partida() -> Dictionary:
	return carregar(PARTIDA)


static func mapa() -> Dictionary:
	return carregar(MAPA)


static func curvas_de_forca() -> Dictionary:
	return carregar(CURVAS)


static func narracao() -> Dictionary:
	return carregar(NARRACAO)


static func dias_por_mes() -> int:
	return int(contratos()["dias_por_mes"])


## Procura, numa lista de dicionários, o item com o `id` informado. Devolve {} se não achar.
static func por_id(lista: Array, id: String) -> Dictionary:
	for item: Variant in lista:
		if item is Dictionary and item.get("id", "") == id:
			return item
	return {}
