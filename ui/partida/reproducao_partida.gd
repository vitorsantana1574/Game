extends RefCounted
## Trilhas auxiliares de exibição. A partida original e seus quadros permanecem intactos.

const Mapa = preload("res://ui/partida/mapa_caldeira.gd")
const Geometria = preload("res://ui/partida/geometria_caldeira.gd")
# Horários de apresentação publicados no GDD 7.0. O contrato 2.7 só envia
# os abates hoje. Eventos de surgimento podem substituir essa trilha auxiliar.
const PRIMEIRA_APARICAO: Dictionary = {"cerbero": 262, "hydra": 594}
const INTERVALO_EPICOS: int = 360
const ANTES_DESTAQUE: float = 1.45
const DEPOIS_DESTAQUE: float = 4.15

var segundo: float = 0.0
var duracao: float
var quadro: Dictionary
var epicos: Dictionary = {}
var _eventos: Array
var _quadros: Array
var _destaques: PackedFloat64Array
var _jogadores: Dictionary = {}
var _projecoes: Dictionary = {}
var _mapa: Mapa
var _quadro_indice: int
var _lance_indice: int
var _destaque_indice: int


func preparar(partida: Dictionary, mapa: Mapa) -> void:
	_mapa = mapa
	segundo = 0.0
	duracao = float(partida.get("duracao", 0))
	_quadro_indice = 0
	_lance_indice = 0
	_destaque_indice = 0
	_destaques.clear()
	_jogadores.clear()
	_projecoes.clear()
	_quadros = partida.get("quadros", [])
	quadro = _quadros[0] if not _quadros.is_empty() else {}
	for ficha: Dictionary in partida.get("jogadores", []):
		var nome: String = ficha.get("campeao_nome", ficha.get("campeao", ""))
		_jogadores[ficha["jogador"]] = {"sigla": nome.left(2).to_upper(), "time": ficha["time"]}
	_eventos = partida.get("eventos", []).duplicate()
	_programar_epicos()
	_eventos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["t"]) < int(b["t"]) if a["t"] != b["t"] else int(a.get("indice", -1)) < int(b.get("indice", -1)))
	for lancamento: Dictionary in _eventos:
		var t: float = float(lancamento["t"])
		if lancamento.get("destaque", false) and (_destaques.is_empty() or _destaques[-1] != t):
			_destaques.append(t)


func avancar(delta: float, velocidade: float, melhores: bool) -> Array[Dictionary]:
	var destino: float = segundo + delta * velocidade
	if melhores:
		while _destaque_indice < _destaques.size() and segundo > _destaques[_destaque_indice] + DEPOIS_DESTAQUE:
			_destaque_indice += 1
		if _destaque_indice >= _destaques.size():
			destino = segundo + 48.0 * delta
		else:
			var inicio: float = _destaques[_destaque_indice] - ANTES_DESTAQUE
			if segundo < inicio:
				destino = minf(segundo + 48.0 * delta, inicio)
	segundo = minf(destino, duracao)
	while _quadro_indice + 1 < _quadros.size() and float(_quadros[_quadro_indice + 1]["t"]) <= segundo:
		_quadro_indice += 1
		quadro = _quadros[_quadro_indice]
	var lances: Array[Dictionary] = []
	while _lance_indice < _eventos.size() and float(_eventos[_lance_indice]["t"]) <= segundo:
		lances.append(_eventos[_lance_indice])
		_lance_indice += 1
	return lances


func fichas_no_mapa() -> Array[Dictionary]:
	var fichas: Array[Dictionary] = []
	if quadro.is_empty():
		return fichas
	var seguinte: int = mini(_quadro_indice + 1, _quadros.size() - 1)
	var futuro: Dictionary = _quadros[seguinte]
	var atuais: Dictionary = _posicoes(_quadro_indice)
	var proximas: Dictionary = _posicoes(seguinte)
	var intervalo: float = maxf(0.01, float(futuro["t"] - quadro["t"]))
	var fracao: float = clampf((segundo - float(quadro["t"])) / intervalo, 0.0, 1.0)
	for id: String in atuais:
		if not _jogadores.has(id) or not atuais[id]["vivo"]:
			continue
		var ficha: Dictionary = _jogadores[id].duplicate()
		var ponto: Vector2 = atuais[id]["ponto"]
		var alvo: Dictionary = proximas.get(id, atuais[id])
		var destino: Vector2 = alvo["ponto"]
		var opacidade: float = 1.0
		if alvo["vivo"] and ponto.distance_to(destino) < 120.0:
			ponto = ponto.lerp(destino, fracao)
		elif alvo["vivo"]:
			# Os quadros podem saltar entre acampamentos. Dissolver o marcador
			# evita desenhar uma travessia pelas paredes que a simulação não emitiu.
			opacidade = 1.0 - smoothstep(0.66, 0.99, fracao)
		if _quadro_indice > 0:
			var anterior: Dictionary = _posicoes(_quadro_indice - 1).get(id, atuais[id])
			if not anterior["vivo"] or Vector2(anterior["ponto"]).distance_to(atuais[id]["ponto"]) >= 120.0:
				opacidade *= smoothstep(0.0, 0.24, fracao)
		ficha["ponto"] = ponto
		ficha["opacidade"] = opacidade
		fichas.append(ficha)
	return fichas


func _posicoes(indice: int) -> Dictionary:
	if not _projecoes.has(indice):
		var registro: Dictionary = {}
		for ficha: Dictionary in _quadros[indice].get("campeoes", []):
			var origem: Vector2 = Vector2(float(ficha["x"]), float(ficha["y"]))
			registro[ficha["jogador"]] = {"ponto": _mapa.geometria.projetar(origem), "vivo": ficha["vivo"]}
		_projecoes[indice] = registro
	return _projecoes[indice]


func _programar_epicos() -> void:
	epicos.clear()
	var origem: Array = _eventos.duplicate()
	for id: String in PRIMEIRA_APARICAO:
		var tipo: String = id + "_surge"
		var oficiais: Array[int] = []
		for lance: Dictionary in origem:
			if lance.get("tipo") == tipo:
				oficiais.append(int(lance["t"]))
		var proximo: int = oficiais[0] if not oficiais.is_empty() else PRIMEIRA_APARICAO[id]
		epicos[id] = {"primeiro": proximo, "respawns": {}}
		for lance: Dictionary in origem:
			if lance.get("tipo") != id:
				continue
			var t: int = int(lance["t"])
			if oficiais.is_empty() and proximo <= t:
				_eventos_aparicao(id, proximo)
			if oficiais.is_empty():
				proximo = int(lance.get("renasce_em", t + INTERVALO_EPICOS))
			else:
				proximo = -1
				for aparicao: int in oficiais:
					if aparicao > t:
						proximo = aparicao
						break
			epicos[id]["respawns"][lance["indice"]] = proximo
		if oficiais.is_empty():
			_eventos_aparicao(id, proximo)


func _eventos_aparicao(id: String, instante: int) -> void:
	if instante >= 0 and instante < duracao:
		_eventos.append({"t": instante, "tipo": id + "_surge", "destaque": true})
