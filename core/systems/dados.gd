class_name Dados
extends RefCounted
## Carrega os arquivos JSON de `data/` e guarda em cache.
## Toda constante de jogo vem daqui, nunca fixa no código.

const DIFICULDADES: String = "res://data/config/dificuldades.json"
const BALANCEAMENTO: String = "res://data/config/balanceamento.json"
const NOMES_JOGADORES: String = "res://data/nomes/jogadores.json"

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


## Procura, numa lista de dicionários, o item com o `id` informado. Devolve {} se não achar.
static func por_id(lista: Array, id: String) -> Dictionary:
	for item: Variant in lista:
		if item is Dictionary and item.get("id", "") == id:
			return item
	return {}
