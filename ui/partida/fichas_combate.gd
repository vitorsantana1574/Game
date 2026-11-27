extends Control
## Os retratos seguem os quadros da partida. As fichas não empurram umas às outras.

signal selecao_alterada

const Texturas = preload("res://ui/componentes/texturas_webp.gd")
const RETRATOS: Dictionary = {"eirafim": 0, "marulva": 1, "luminela": 2, "ravineo": 3, "veluria": 4, "clavento": 5}
const CORES: Array[Color] = [Color("#86e9ff"), Color("#ffac92")]
const FUNDO: Color = Color("#0c1721")
const QUEDA: float = 0.52
const RETORNO: float = 0.68
const RAIO: float = 17.5

var animar: bool = true
var _atlas: Texture2D
var _fichas: Dictionary = {}
var _quedas: Dictionary = {}
var _retornos: Dictionary = {}
var _bloqueios: Dictionary = {}
var _selecionada: String = ""
var _ultima_ficha: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_atlas = Texturas.carregar("res://assets/sprites/campeoes/fichas_caldeira.webp")


func reiniciar() -> void:
	_fichas.clear()
	_quedas.clear()
	_retornos.clear()
	_bloqueios.clear()
	_selecionada = ""
	_ultima_ficha.clear()
	queue_redraw()


func abater(id: String, ficha: Dictionary, ponto: Vector2, segundo: float) -> void:
	if id.is_empty() or ficha.is_empty():
		return
	_bloqueios[id] = segundo
	_retornos.erase(id)
	if _selecionada == id:
		_ultima_ficha["abatido"] = true
	_fichas.erase(id)
	if animar:
		_quedas[id] = {"ficha": ficha, "ponto": ponto, "tempo": 0.0}


func atualizar(fichas: Array[Dictionary], delta: float) -> void:
	_avancar(_quedas, QUEDA, delta)
	_avancar(_retornos, RETORNO, delta)
	_fichas.clear()
	for ficha: Dictionary in fichas:
		var id: String = ficha["jogador"]
		if _bloqueios.has(id):
			# O lance é mais preciso que o quadro anterior, que ainda pode mostrar a vítima viva.
			if float(ficha["quadro_em"]) <= float(_bloqueios[id]):
				continue
			_bloqueios.erase(id)
			_quedas.erase(id)
			if animar:
				_retornos[id] = {"ponto": ficha["ponto"], "tempo": 0.0}
		_fichas[id] = ficha
		if id == _selecionada:
			_ultima_ficha = ficha.duplicate()
	queue_redraw()


func detalhe() -> Dictionary:
	return _ultima_ficha


func _gui_input(evento: InputEvent) -> void:
	var toque: InputEventMouseButton = evento as InputEventMouseButton
	if toque == null or toque.button_index != MOUSE_BUTTON_LEFT or not toque.pressed:
		return
	var escolhido: String = ""
	var ids: Array = _fichas.keys()
	# A ficha selecionada é desenhada por cima das outras.
	if not _selecionada.is_empty() and _fichas.has(_selecionada):
		ids.erase(_selecionada)
		ids.append(_selecionada)
	ids.reverse()
	for id: String in ids:
		var ficha: Dictionary = _fichas[id]
		if float(ficha["opacidade"]) > 0.15 and toque.position.distance_squared_to(ficha["ponto"]) <= RAIO * RAIO:
			escolhido = id
			break
	_selecionada = "" if escolhido == _selecionada else escolhido
	_ultima_ficha = _fichas.get(_selecionada, {}).duplicate()
	queue_redraw()
	selecao_alterada.emit()
	accept_event()


func _avancar(animacoes: Dictionary, duracao: float, delta: float) -> void:
	for id: String in animacoes.keys():
		animacoes[id]["tempo"] += delta
		if float(animacoes[id]["tempo"]) >= duracao:
			animacoes.erase(id)


func _draw() -> void:
	for queda: Dictionary in _quedas.values():
		var p: float = float(queda["tempo"]) / QUEDA
		var ponto: Vector2 = queda["ponto"]
		var ficha: Dictionary = queda["ficha"]
		_pulso(ponto, p, CORES[ficha["time"]], true)
		_desenhar_ficha(ficha, ponto, RAIO * (1.0 - 0.25 * p), 1.0 - smoothstep(0.18, 1.0, p), true)
	var ids: Array = _fichas.keys()
	if _fichas.has(_selecionada):
		ids.erase(_selecionada)
		ids.append(_selecionada)
	for id: String in ids:
		var ficha: Dictionary = _fichas[id]
		var ponto: Vector2 = ficha["ponto"]
		var raio: float = RAIO
		var opacidade: float = ficha["opacidade"]
		if _retornos.has(id):
			var retorno: Dictionary = _retornos[id]
			var p: float = float(retorno["tempo"]) / RETORNO
			_pulso(retorno["ponto"], p, CORES[ficha["time"]], false)
			raio *= lerpf(0.77, 1.0, smoothstep(0.0, 0.78, p))
			opacidade *= smoothstep(0.0, 0.48, p)
		_desenhar_ficha(ficha, ponto, raio, opacidade, false)
		if id == _selecionada:
			draw_arc(ponto, raio + 4.0, 0.0, TAU, 40, Color(Color("#fff2bd"), opacidade), 1.7, true)


func _desenhar_ficha(ficha: Dictionary, ponto: Vector2, raio: float, opacidade: float, caida: bool) -> void:
	if opacidade <= 0.0:
		return
	var cor: Color = Color("#c6d2db") if caida else CORES[ficha["time"]]
	draw_circle(ponto + Vector2(1.5, 3.0), raio + 2.5, Color("#071019a0") * Color(1, 1, 1, opacidade), true, -1.0, true)
	draw_circle(ponto, raio + 1.5, Color(FUNDO, 0.95 * opacidade), true, -1.0, true)
	var indice: int = RETRATOS.get(ficha["campeao"], -1)
	if indice >= 0 and _atlas != null:
		var interno: float = raio - 1.1
		var recorte: Rect2 = Rect2(indice * 96, 96 if caida else 0, 96, 96)
		draw_texture_rect_region(_atlas, Rect2(ponto - Vector2.ONE * interno, Vector2.ONE * interno * 2.0),
			recorte, Color(1, 1, 1, opacidade))
	else:
		var fonte: Font = get_theme_default_font()
		var sigla: String = ficha["sigla"]
		var largura: float = fonte.get_string_size(sigla, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14).x
		draw_string(fonte, ponto + Vector2(-largura * 0.5, 5.0), sigla, HORIZONTAL_ALIGNMENT_LEFT,
			-1.0, 14, Color(Color.WHITE, opacidade))
	draw_arc(ponto, raio, 0.0, TAU, 38, Color(cor, opacidade), 2.25, true)


func _pulso(ponto: Vector2, progresso: float, cor: Color, queda: bool) -> void:
	var alcance: float = lerpf(9.0, 36.0, progresso)
	draw_arc(ponto, alcance, 0.0, TAU, 38, Color(cor, (1.0 - progresso) * 0.62), 1.6, true)
	for i: int in range(12):
		var angulo: float = float(i) * 2.39996
		var ponto_particula: Vector2 = ponto + Vector2.from_angle(angulo) * alcance * (0.6 + 0.12 * (i % 5))
		ponto_particula.y -= sin(progresso * PI) * (11.0 if queda else 18.0)
		draw_circle(ponto_particula, lerpf(1.9, 0.5, progresso), Color(cor, 0.75 * (1.0 - progresso)), true, -1.0, true)
