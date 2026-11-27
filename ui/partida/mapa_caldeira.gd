extends Control

const Geometria = preload("res://ui/partida/geometria_caldeira.gd")
const Animacao = preload("res://ui/partida/animacao_atlas.gd")
const Texturas = preload("res://ui/componentes/texturas_webp.gd")
const QUEIMA_EPICO = preload("res://ui/partida/queima_epico.gdshader")
const QUEIMA_DURACAO: float = 1.75
const RECORTES_ABATE: Dictionary = {
	"hydra": preload("res://assets/animacoes/caldeira/hydra_abate.png"),
	"cerbero": preload("res://assets/animacoes/caldeira/cerbero_abate.png"),
}
const HYDRA_TERCEIRA_CABECA = preload("res://assets/animacoes/caldeira/hydra_terceira_cabeca.png")
const CENTROS_QUEIMA: Dictionary = {"hydra": Vector2(0.51, 0.62), "cerbero": Vector2(0.50, 0.49)}
const MAPA: String = "res://assets/sprites/mapa/"
const EFEITOS: String = "res://assets/animacoes/caldeira/"
const CORES: Array[Color] = [Color("#78e3ff"), Color("#ffa089")]
const COR_FUNDO: Color = Color("#0c1521")
const COR_ACESSO: Color = Color("#bbefac")
const ARENAS: Dictionary = {
	"hydra": Rect2(184.5, 200.5, 247.0, 203.0),
	"cerbero": Rect2(603.0, 555.0, 196.0, 174.0),
}

var geometria: Geometria = Geometria.new()
var animar: bool = true
var aproximar: bool = true:
	set(ativo):
		aproximar = ativo
		if not ativo:
			_zoom = 1.0
			_centro = Vector2(500, 500)
			_dimensionar()
var alcances: bool
var acessos: bool

var _vista: Control
var _tabuleiro: Node2D
var _chao: Control
var _marcas: Control
var _fichas: Array[Dictionary] = []
var _torres: Dictionary = {}
var _epicos: Dictionary = {}
var _guardioes: Array[bool] = [true, true]
var _placas_torre: Dictionary = {}
var _atlas: Dictionary = {}
var _mascaras: Dictionary = {}
var _efeitos: Dictionary = {}
var _luta: Dictionary = {}
var _camera: Dictionary = {}
var _zoom: float = 1.0
var _centro: Vector2 = Vector2(500, 500)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(280.0, 265.0)
	_vista = Control.new()
	_vista.clip_contents = true
	_vista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vista)
	_tabuleiro = Node2D.new()
	_vista.add_child(_tabuleiro)
	_sprite(_tabuleiro, Texturas.carregar(MAPA + "caldeira_glacial.webp"), Rect2(0, 0, 1000, 1000))
	_chao = _camada(_desenhar_chao)
	for id: String in ["azul", "coral"]:
		for estado: String in ["inteira", "ruina"]:
			_placas_torre[id + "_" + estado] = Texturas.carregar(MAPA + "torre_%s_%s.webp" % [id, estado])
	for rota: String in Geometria.TORRES:
		for time: int in range(2):
			for i: int in range(3):
				var ponto: Vector2 = Geometria.TORRES[rota][time][i]
				var chave: String = _chave_torre(time, rota, i)
				var sprite: TextureRect = _sprite(_tabuleiro, _placas_torre[_lado(time) + "_inteira"],
					Rect2(ponto + Vector2(-62, -72), Vector2(124, 115)))
				_torres[chave] = {"sprite": sprite, "ponto": ponto, "time": time}
	for id: String in ARENAS:
		var placa: TextureRect = _sprite(_tabuleiro, Texturas.carregar(MAPA + "arena_" + id + ".webp"), ARENAS[id])
		var epico: Dictionary = {"placa": placa, "disponivel_em": -1.0}
		if animar:
			var queima: TextureRect = _sprite(_tabuleiro, RECORTES_ABATE[id], ARENAS[id])
			var material_queima: ShaderMaterial = ShaderMaterial.new()
			material_queima.shader = QUEIMA_EPICO
			material_queima.set_shader_parameter(&"centro", CENTROS_QUEIMA[id])
			material_queima.set_shader_parameter(&"proporcao", queima.size.x / queima.size.y)
			if id == "hydra":
				material_queima.set_shader_parameter(&"tem_terceira_cabeca", true)
				material_queima.set_shader_parameter(&"terceira_cabeca", HYDRA_TERCEIRA_CABECA)
			queima.material = material_queima
			queima.z_index = 1
			queima.hide()
			epico["queima"] = queima
			epico["tempo_queima"] = 0.0
		_epicos[id] = epico
	if animar:
		_carregar_atlas()
	_marcas = _camada(_desenhar_marcas)
	_marcas.z_index = 2
	resized.connect(_dimensionar)
	_dimensionar()


func inicializar(mapa: Dictionary) -> void:
	geometria.configurar(mapa)
	for chave: String in _efeitos.keys():
		_finalizar(chave)
	_camera.clear()
	_zoom = 1.0
	_centro = Vector2(500, 500)
	_luta.clear()
	_fichas.clear()
	_guardioes = [true, true]
	for torre: Dictionary in _torres.values():
		var sprite: TextureRect = torre["sprite"]
		sprite.texture = _placas_torre[_lado(torre["time"]) + "_inteira"]
		sprite.show()
	for epico: Dictionary in _epicos.values():
		epico["disponivel_em"] = -1.0
		epico["restante"] = 0.0
		epico["placa"].show()
		_parar_queima(epico)
	atualizar_marcas()
	_dimensionar()


func atualizar(fichas: Array[Dictionary], segundo: float, delta: float) -> void:
	_fichas = fichas
	for epico: Dictionary in _epicos.values():
		epico["restante"] = maxf(0.0, float(epico["disponivel_em"]) - segundo)
		var queima: TextureRect = epico.get("queima")
		if queima != null and queima.visible:
			epico["tempo_queima"] += delta
			var progresso: float = epico["tempo_queima"] / QUEIMA_DURACAO
			if progresso >= 1.0:
				queima.hide()
			else:
				(queima.material as ShaderMaterial).set_shader_parameter(&"progresso", progresso)
	for id: String in _efeitos.keys():
		var efeito: Dictionary = _efeitos[id]
		var quadro: Animacao = efeito["no"]
		efeito["tempo"] += delta
		if efeito["tempo"] >= quadro.duracao:
			_finalizar(id)
		else:
			quadro.quadro(efeito["tempo"])
	if not _luta.is_empty():
		_luta["tempo"] += delta
		if float(_luta["tempo"]) >= 1.45:
			_luta.clear()
	_atualizar_camera(delta)
	_marcas.queue_redraw()


func atualizar_marcas() -> void:
	_chao.queue_redraw()
	_marcas.queue_redraw()


func cair_torre(time: int, rota: String, indice: int, destaque: bool) -> void:
	var chave: String = _chave_torre(time, rota, indice)
	if not _torres.has(chave) or _efeitos.has(chave):
		return
	var torre: Dictionary = _torres[chave]
	var sprite: TextureRect = torre["sprite"]
	var ruina: Texture2D = _placas_torre[_lado(time) + "_ruina"]
	if sprite.texture == ruina:
		return
	sprite.texture = ruina
	_chao.queue_redraw()
	if animar and not _atlas.is_empty():
		sprite.hide()
		_iniciar(chave, "torre_" + _lado(time), torre["ponto"])
		if destaque:
			_focar(Vector2(torre["ponto"]) - Vector2(0, 20), float(Animacao.DADOS["torre_" + _lado(time)][6]), 0.24)


func espera_epico(id: String, ate: float) -> void:
	if _efeitos.has(id):
		_finalizar(id)
	var epico: Dictionary = _epicos[id]
	_parar_queima(epico)
	epico["disponivel_em"] = ate
	epico["placa"].show()


func abater_epico(id: String, renasce_em: float, destaque: bool) -> void:
	espera_epico(id, renasce_em)
	var epico: Dictionary = _epicos[id]
	var queima: TextureRect = epico.get("queima")
	if not animar or queima == null:
		return
	(queima.material as ShaderMaterial).set_shader_parameter(&"progresso", 0.0)
	queima.show()
	if destaque:
		_focar(Geometria.EPICOS[id], QUEIMA_DURACAO, 0.24)


func _parar_queima(epico: Dictionary) -> void:
	var queima: TextureRect = epico.get("queima")
	if queima != null:
		queima.hide()
		epico["tempo_queima"] = 0.0


## Começa a animação de surgimento (a tela chama alguns segundos antes do horário oficial,
## para o monstro terminar de surgir no instante em que pode ser atacado).
func surgir(id: String) -> void:
	if _efeitos.has(id):
		return
	var epico: Dictionary = _epicos[id]
	_parar_queima(epico)
	epico["disponivel_em"] = -1.0
	epico["placa"].hide()
	if animar and not _atlas.is_empty():
		_iniciar(id, id, Vector2.ZERO)
		_focar(Geometria.EPICOS[id], float(Animacao.DADOS[id][6]), 0.40)


func destacar_lance(ponto: Vector2, time: int, tipo: String) -> void:
	_luta = {"ponto": ponto, "time": time, "tipo": tipo, "tempo": 0.0}


func presenca_guardiao(time: int, presente: bool) -> void:
	if time in [0, 1]:
		_guardioes[time] = presente


func _dimensionar() -> void:
	if _vista == null:
		return
	var lado: float = minf(size.x, size.y)
	_vista.size = Vector2.ONE * lado
	_vista.position = (size - _vista.size) * 0.5
	var margem: Vector2 = Vector2.ONE * (500.0 / _zoom)
	var centro: Vector2 = _centro.clamp(margem, Vector2.ONE * 1000.0 - margem)
	_tabuleiro.scale = Vector2.ONE * (lado / Geometria.LADO) * _zoom
	_tabuleiro.position = _vista.size * 0.5 - centro * _tabuleiro.scale


func _atualizar_camera(delta: float) -> void:
	if not aproximar or (_camera.is_empty() and is_equal_approx(_zoom, 1.0)):
		return
	if not _camera.is_empty():
		_camera["tempo"] += delta
		if float(_camera["tempo"]) >= float(_camera["duracao"]):
			_camera.clear()
	var centro: Vector2 = Vector2(500, 500)
	var zoom: float = 1.0
	if not _camera.is_empty():
		var tempo: float = _camera["tempo"]
		var duracao: float = _camera["duracao"]
		var peso: float = smoothstep(0.0, 0.50, tempo) * (1.0 - smoothstep(duracao - 0.66, duracao, tempo))
		zoom += float(_camera["zoom"]) * peso
		centro = centro.lerp(_camera["ponto"], peso)
	var suave: float = 1.0 - exp(-10.0 * delta)
	_zoom = lerpf(_zoom, zoom, suave)
	_centro = _centro.lerp(centro, suave)
	_dimensionar()


func _carregar_atlas() -> void:
	for tipo: String in Animacao.DADOS:
		var dados: Array = Animacao.DADOS[tipo]
		var paginas: Array[Texture2D] = []
		for pagina: int in range(ceili(float(dados[3]) / int(dados[5]))):
			var textura: Texture2D = Texturas.carregar(EFEITOS + "%s_%d.webp" % [tipo, pagina])
			if textura == null:
				_atlas.clear()
				return
			paginas.append(textura)
		_atlas[tipo] = paginas
		if tipo in Animacao.COM_MASCARA:
			var mascara: Texture2D = Texturas.carregar(EFEITOS + "%s_mascara.webp" % tipo)
			if mascara == null:
				_atlas.clear()
				return
			_mascaras[tipo] = mascara


func _iniciar(id: String, tipo: String, origem: Vector2) -> void:
	if _efeitos.has(id):
		_finalizar(id)
	var efeito: Animacao = Animacao.new()
	_tabuleiro.add_child(efeito)
	efeito.z_index = 1
	efeito.configurar(tipo, _atlas[tipo], origem, _mascaras.get(tipo, null))
	_efeitos[id] = {"no": efeito, "tempo": 0.0}


func _finalizar(id: String) -> void:
	var efeito: Animacao = _efeitos[id]["no"]
	efeito.hide()
	efeito.queue_free()
	_efeitos.erase(id)
	if _torres.has(id):
		_torres[id]["sprite"].show()


func _focar(ponto: Vector2, duracao: float, zoom: float) -> void:
	_camera = {"ponto": ponto, "duracao": duracao, "zoom": zoom, "tempo": 0.0}


func _camada(desenhar: Callable) -> Control:
	var camada: Control = Control.new()
	camada.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.draw.connect(desenhar)
	_tabuleiro.add_child(camada)
	return camada


func _desenhar_chao() -> void:
	if alcances:
		for torre: Dictionary in _torres.values():
			var cor: Color = CORES[torre["time"]]
			var sprite: TextureRect = torre["sprite"]
			if sprite.texture == _placas_torre[_lado(torre["time"]) + "_inteira"]:
				_chao.draw_circle(torre["ponto"], Geometria.RAIO_VISUAL, Color(cor, 0.10), true, -1, true)
				_chao.draw_arc(torre["ponto"], Geometria.RAIO_VISUAL, 0, TAU, 64, Color(cor, 0.80), 1.65, true)
	if acessos:
		for trilha: Array in Geometria.ACESSOS:
			for i: int in range(trilha.size() - 1):
				_chao.draw_dashed_line(trilha[i], trilha[i + 1], Color(COR_ACESSO, 0.85), 3.1, 7.0, true, true)


func _desenhar_marcas() -> void:
	var fonte: Font = get_theme_default_font()
	for id: String in Geometria.EPICOS:
		var epico: Dictionary = _epicos[id]
		var ponto: Vector2 = Geometria.EPICOS[id] + Vector2(0, 66)
		var cor: Color = Color("#c3f3ff") if id == "hydra" else Color("#ffd4ab")
		var restante: int = ceili(float(epico.get("restante", 0.0)))
		if float(epico["disponivel_em"]) >= 0.0 and restante > 0:
			ponto.y -= 26.0
			var ampulheta: Color = Color("#ffe381") if float(epico["restante"]) < 10.0 else Color.WHITE
			_ampulheta(ponto + Vector2(-20, -6), ampulheta)
			_rotulo(fonte, "%d:%02d" % [floori(float(restante) / 60.0), restante % 60], ponto + Vector2(10, 0), 18, ampulheta)
		else:
			_rotulo(fonte, "Hydra" if id == "hydra" else "Cérbero", ponto, 18, cor)
	for time: int in range(2):
		var local: Vector2 = Geometria.BASES[time]["guardiao"] + Vector2(22, 18)
		var cor: Color = CORES[time] if _guardioes[time] else Color("#b7b7c3")
		_rotulo(fonte, "Guardião" if _guardioes[time] else "Guardião caído", local, 15, cor)
	if not _luta.is_empty():
		var t: float = float(_luta["tempo"]) / 1.45
		var cor: Color = CORES[_luta["time"]] if _luta["time"] in [0, 1] else Color("#ffdea5")
		var p: Vector2 = _luta["ponto"]
		_marcas.draw_circle(p, lerpf(13.0, 49.0, t), Color(cor, 0.18 * (1.0 - t)), true, -1.0, true)
		_marcas.draw_arc(p, lerpf(11.0, 52.0, t), 0, TAU, 45, Color(cor, 1.0 - t), 3.0, true)
		if _luta["tipo"] == "luta":
			_rotulo(fonte, "Confronto", p + Vector2(0, -23), 19, Color(cor, 1.0 - t))
	for ficha: Dictionary in _fichas:
		var p: Vector2 = ficha["ponto"]
		var cor: Color = CORES[ficha["time"]]
		var opacidade: float = ficha["opacidade"]
		_marcas.draw_circle(p, 15.5, Color(COR_FUNDO, 0.94 * opacidade), true, -1.0, true)
		_marcas.draw_arc(p, 14.0, 0, TAU, 35, Color(cor, opacidade), 2.3, true)
		_rotulo(fonte, ficha["sigla"], p + Vector2(0, 4), 14, Color(Color.WHITE, opacidade))


func _ampulheta(p: Vector2, cor: Color) -> void:
	var linhas: PackedVector2Array = PackedVector2Array([p + Vector2(-5, -7), p + Vector2(5, -7),
		p + Vector2(-5, 7), p + Vector2(5, 7), p + Vector2(-5, -7)])
	_marcas.draw_polyline(linhas, Color(COR_FUNDO, 0.94), 5.0, true)
	_marcas.draw_polyline(linhas, cor, 1.8, true)


func _rotulo(fonte: Font, texto: String, ponto: Vector2, tamanho: int, cor: Color) -> void:
	var largura: float = fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1.0, tamanho).x
	var ancora: Vector2 = ponto - Vector2(largura * 0.5, 0)
	_marcas.draw_string_outline(fonte, ancora, texto, HORIZONTAL_ALIGNMENT_LEFT, -1.0, tamanho, 5, Color(COR_FUNDO, cor.a))
	_marcas.draw_string(fonte, ancora, texto, HORIZONTAL_ALIGNMENT_LEFT, -1.0, tamanho, cor)


static func _sprite(pai: Node, textura: Texture2D, regiao: Rect2) -> TextureRect:
	var sprite: TextureRect = TextureRect.new()
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture = textura
	sprite.position = regiao.position
	sprite.size = regiao.size
	pai.add_child(sprite)
	return sprite


static func _lado(time: int) -> String:
	return "azul" if time == 0 else "coral"


static func _chave_torre(time: int, rota: String, indice: int) -> String:
	return "%d:%s:%d" % [time, rota, indice]
