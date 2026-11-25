class_name Narracao
extends RefCounted
## Narração da partida: escolhe frases de data/narracao/narracao.json para cada lance da linha do tempo.
##
## Dupla de vozes: o narrador conta o lance; o comentarista, às vezes, explica o porquê.
## Evita repetir a mesma frase do mesmo tipo de lance enquanto houver outra opção,
## e só usa frases cujos marcadores ({jogador}, {rota}...) foram todos preenchidos.

const MEMORIA_POR_TIPO: int = 4

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _recentes: Dictionary = {}


func _init(semente: int = 0) -> void:
	_rng.seed = semente


static func dados() -> Dictionary:
	return Dados.narracao()


## Linhas de narração para um lance: [{"voz": "narrador" | "comentarista", "nome": "...", "texto": "..."}].
## variante (opcional) escolhe uma lista específica do narrador, ex.: "narrador_3" para triple kill.
## contexto (opcional) escolhe a lista "comentarista_<contexto>" quando ela existe (ex.: "sem_luta", "virada").
## O simulador só passa um contexto quando ele é verdade na partida.
func narrar(tipo: String, valores: Dictionary, variante: String = "", contexto: String = "") -> Array[Dictionary]:
	var linhas: Array[Dictionary] = []
	var evento: Dictionary = dados()["eventos"].get(tipo, {})
	if evento.is_empty():
		return linhas
	var chave_narrador: String = variante if not variante.is_empty() and evento.has(variante) else "narrador"
	var frase: String = _escolher(tipo + ":" + chave_narrador, evento.get(chave_narrador, []), valores)
	if not frase.is_empty():
		linhas.append(_linha("narrador", frase))
	var chances: Dictionary = dados()["chance_comentario"]
	var chance: float = 1.0 if linhas.is_empty() else float(chances.get(tipo, chances["padrao"]))
	if _rng.randf() < chance:
		var chave_comentario: String = "comentarista"
		if not contexto.is_empty() and evento.has("comentarista_" + contexto):
			chave_comentario = "comentarista_" + contexto
		var comentario: String = _escolher(tipo + ":" + chave_comentario, evento.get(chave_comentario, []), valores)
		if not comentario.is_empty():
			linhas.append(_linha("comentarista", comentario))
	return linhas


func _linha(voz: String, texto: String) -> Dictionary:
	return {"voz": voz, "nome": str(dados()["vozes"][voz]["nome"]), "texto": texto}


func _escolher(chave: String, opcoes: Array, valores: Dictionary) -> String:
	var validas: Array[int] = []
	for indice: int in range(opcoes.size()):
		if _marcadores_preenchidos(String(opcoes[indice]), valores):
			validas.append(indice)
	if validas.is_empty():
		return ""
	var recentes: Array = _recentes.get(chave, [])
	var novas: Array[int] = validas.filter(func(i: int) -> bool: return not recentes.has(i))
	var lista: Array[int] = novas if not novas.is_empty() else validas
	var escolhida: int = lista[_rng.randi() % lista.size()]
	recentes.append(escolhida)
	while recentes.size() > mini(MEMORIA_POR_TIPO, maxi(1, validas.size() - 1)):
		recentes.pop_front()
	_recentes[chave] = recentes
	return preencher(String(opcoes[escolhida]), valores)


static func _marcadores_preenchidos(frase: String, valores: Dictionary) -> bool:
	var regex: RegEx = RegEx.create_from_string("\\{([a-z_]+)\\}")
	for achado: RegExMatch in regex.search_all(frase):
		var chave: String = achado.get_string(1)
		if not valores.has(chave) or str(valores[chave]).is_empty():
			return false
	return true


## Troca os marcadores pelos valores e põe maiúscula no começo de cada frase
## (um marcador como {objetivo} = "a Hydra" pode abrir a frase).
static func preencher(frase: String, valores: Dictionary) -> String:
	var texto: String = frase
	for chave: String in valores:
		texto = texto.replace("{%s}" % chave, str(valores[chave]))
	var resultado: String = ""
	var maiuscula: bool = true
	for i: int in range(texto.length()):
		var letra: String = texto[i]
		if maiuscula and letra != " ":
			letra = letra.to_upper()
			maiuscula = false
		resultado += letra
		var reticencias: bool = letra == "." and ((i > 0 and texto[i - 1] == ".") or (i + 1 < texto.length() and texto[i + 1] == "."))
		if letra in [".", "!", "?"] and not reticencias and i + 1 < texto.length() and texto[i + 1] == " ":
			maiuscula = true
	return resultado
