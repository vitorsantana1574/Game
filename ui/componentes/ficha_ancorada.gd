extends Control
## Mantém a linha ligada ao mesmo objeto enquanto os detalhes da ficha mudam.

signal voltar

const Tema = preload("res://ui/temas/tema_abertura.gd")
const BORDA: Color = Color("#789c85")

var corpo: VBoxContainer
var titulo: Label
var categoria: Label
var seta: Button
var painel: PanelContainer
var _coluna: VBoxContainer
var _rolagem: ScrollContainer
var _linha: Line2D
var _origem: Control
var _trajeto: PackedVector2Array
var _animacao: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_linha = Line2D.new()
	_linha.width = 2.0
	_linha.default_color = Color("#c8e7cb")
	_linha.antialiased = true
	add_child(_linha)

	painel = PanelContainer.new()
	painel.add_theme_stylebox_override("panel", Tema.caixa(Color("#13221cfb"), BORDA, 15))
	add_child(painel)
	_coluna = VBoxContainer.new()
	_coluna.add_theme_constant_override("separation", 12)
	painel.add_child(_coluna)
	var cabecalho: HBoxContainer = HBoxContainer.new()
	cabecalho.add_theme_constant_override("separation", 14)
	_coluna.add_child(cabecalho)
	seta = Button.new()
	seta.text = "←"
	seta.custom_minimum_size = Vector2(46, 46)
	seta.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	seta.pressed.connect(func() -> void: voltar.emit())
	cabecalho.add_child(seta)
	var titulos: VBoxContainer = VBoxContainer.new()
	titulos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecalho.add_child(titulos)
	categoria = Label.new()
	categoria.add_theme_font_size_override("font_size", 15)
	categoria.add_theme_color_override("font_color", Tema.VERDE)
	titulos.add_child(categoria)
	titulo = Label.new()
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titulo.add_theme_font_size_override("font_size", 29)
	titulos.add_child(titulo)
	_coluna.add_child(HSeparator.new())

	_rolagem = ScrollContainer.new()
	_rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rolagem.follow_focus = true
	_coluna.add_child(_rolagem)
	corpo = VBoxContainer.new()
	corpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	corpo.add_theme_constant_override("separation", 8)
	_rolagem.add_child(corpo)
	esconder()


func atualizar(categoria_nova: String, titulo_novo: String, detalhe: bool) -> VBoxContainer:
	categoria.text = categoria_nova
	titulo.text = titulo_novo
	seta.accessibility_name = "Voltar" if detalhe else "Voltar à sede"
	seta.tooltip_text = seta.accessibility_name
	for item: Node in corpo.get_children():
		corpo.remove_child(item)
		item.queue_free()
	_rolagem.scroll_vertical = 0
	return corpo


func abrir(origem: Control, animar: bool) -> void:
	_origem = origem
	show()
	reposicionar()
	_parar_animacao()
	seta.grab_focus()
	if not animar:
		return
	painel.modulate.a = 0.0
	_desenhar(0.0)
	_animacao = create_tween()
	_animacao.tween_method(_desenhar, 0.0, 1.0, 0.13)
	_animacao.tween_property(painel, "modulate:a", 1.0, 0.14)


func reposicionar() -> void:
	if not visible or not is_instance_valid(_origem):
		return
	var centro: Vector2 = get_global_transform().affine_inverse() * _origem.get_global_rect().get_center()
	var largura: float = minf(470.0, size.x - 28.0)
	var estreita: bool = size.x < 850.0
	var esquerda: bool = centro.x > size.x * 0.55
	var distancia: float = clampf(size.x * 0.068, 36.0, 110.0)
	var x: float = centro.x - largura - distancia if esquerda else centro.x + distancia
	var y: float = centro.y - 250.0 if centro.y > size.y * 0.46 else centro.y + 44.0
	if estreita:
		x = (size.x - largura) / 2.0
		y = minf(size.y * 0.47, size.y - 200.0)
	painel.position = Vector2(clampf(x, 14.0, size.x - largura - 14.0), clampf(y, 14.0, maxf(14.0, size.y - 260.0)))
	var destino: Vector2 = painel.position + Vector2(largura if esquerda else 0.0, 39.0)
	var dobra: Vector2 = destino + Vector2(18.0 if esquerda else -18.0, 0.0)
	if estreita:
		destino = Vector2(clampf(centro.x, painel.position.x + 28.0, painel.position.x + largura - 28.0), painel.position.y)
		dobra = destino - Vector2(0.0, 14.0)
	var inicio: Vector2 = centro + centro.direction_to(dobra) * minf(24.0, centro.distance_to(dobra) / 2.0)
	_trajeto = PackedVector2Array([inicio, dobra, destino])
	if _animacao == null or not _animacao.is_running():
		_desenhar(1.0)
	ajustar_altura()


func ajustar_altura() -> void:
	if not visible:
		return
	var altura_disponivel: float = maxf(95.0, size.y - painel.position.y - 18.0)
	_rolagem.custom_minimum_size.y = minf(corpo.get_combined_minimum_size().y + 2.0, maxf(30.0, altura_disponivel - 115.0))
	painel.size = Vector2(minf(470.0, size.x - 28.0), 0.0)


func _desenhar(fracao: float) -> void:
	var inicio: Vector2 = _trajeto[0]
	var dobra: Vector2 = _trajeto[1]
	var fim: Vector2 = _trajeto[2]
	var trecho: float = inicio.distance_to(dobra)
	var percorrido: float = fracao * (trecho + dobra.distance_to(fim))
	if percorrido < trecho:
		_linha.points = PackedVector2Array([inicio, inicio.move_toward(dobra, percorrido)])
	else:
		_linha.points = PackedVector2Array([inicio, dobra, dobra.move_toward(fim, percorrido - trecho)])


func _parar_animacao() -> void:
	if _animacao != null:
		_animacao.kill()
		_animacao = null
	painel.modulate.a = 1.0


func esconder() -> void:
	_parar_animacao()
	hide()
