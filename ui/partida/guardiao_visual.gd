extends TextureRect
## Cada base usa os mesmos destroços no último quadro da queda e no início do retorno.

const Texturas = preload("res://ui/componentes/texturas_webp.gd")
const TRANSICAO = preload("res://ui/partida/transicao_atlas.gdshader")
const QUEDA: float = 1.58
const RETORNO: float = 2.40
const ULTIMO_QUEDA: int = 48
const ULTIMO_RETORNO: int = 121
const COLUNAS: int = 10
const ESCALA_MAPA: float = 1000.0 / 1450.0
const REGIOES: Array[Rect2i] = [Rect2i(50, 1110, 166, 201), Rect2i(1255, 44, 106, 181)]

var _celula: Vector2i
var _material_animacao: ShaderMaterial
var _quadro: int = -1
var _tempo: float
var _duracao: float
var _primeiro: int
var _ultimo: int
var _retornando: bool


func configurar(time: int) -> void:
	var lado: String = "azul" if time == 0 else "coral"
	texture = Texturas.carregar("res://assets/animacoes/caldeira/guardiao_%s.webp" % lado)
	if texture == null:
		return
	var regiao: Rect2i = REGIOES[time]
	_celula = regiao.size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	position = Vector2(regiao.position) * ESCALA_MAPA
	size = Vector2(regiao.size) * ESCALA_MAPA
	_material_animacao = ShaderMaterial.new()
	_material_animacao.shader = TRANSICAO
	_material_animacao.set_shader_parameter(&"atlas_atual", texture)
	_material_animacao.set_shader_parameter(&"atlas_seguinte", texture)
	material = _material_animacao
	reiniciar()


func reiniciar() -> void:
	_duracao = 0.0
	hide()


func mudar_presenca(presente: bool, animar: bool) -> void:
	if _material_animacao == null:
		return
	if not animar:
		reiniciar()
		if not presente:
			_exibir_quadro(ULTIMO_QUEDA, ULTIMO_QUEDA)
			show()
		return
	_retornando = presente
	_tempo = 0.0
	_duracao = RETORNO if presente else QUEDA
	_primeiro = ULTIMO_QUEDA + 1 if presente else 0
	_ultimo = ULTIMO_RETORNO if presente else ULTIMO_QUEDA
	_exibir_quadro(_primeiro, _ultimo)
	show()


func atualizar(delta: float) -> void:
	if _duracao <= 0.0:
		return
	_tempo += delta
	var progresso: float = clampf(_tempo / _duracao, 0.0, 1.0)
	_exibir_quadro(lerpf(_primeiro, _ultimo, progresso), _ultimo)
	if progresso >= 1.0:
		_duracao = 0.0
		if _retornando:
			hide()


func _exibir_quadro(posicao: float, ultimo: int) -> void:
	var indice: int = floori(posicao)
	if indice != _quadro:
		_quadro = indice
		_material_animacao.set_shader_parameter(&"regiao_atual", _regiao(indice))
	# O segundo quadro pode mudar quando passamos de uma fase para outra.
	_material_animacao.set_shader_parameter(&"regiao_seguinte", _regiao(mini(indice + 1, ultimo)))
	_material_animacao.set_shader_parameter(&"mistura", posicao - indice)


func _regiao(indice: int) -> Vector4:
	var canto: Vector2 = Vector2(indice % COLUNAS, floori(float(indice) / COLUNAS))
	var extensao: Vector2 = texture.get_size()
	var inicio: Vector2 = (canto * (Vector2(_celula) + Vector2(4, 4)) + Vector2(2.5, 2.5)) / extensao
	var tamanho: Vector2 = (Vector2(_celula) - Vector2.ONE) / extensao
	return Vector4(inicio.x, inicio.y, tamanho.x, tamanho.y)
