extends VBoxContainer

const Arte = preload("res://ui/componentes/arte_bandeira.gd")
const BandeiraNaSede = preload("res://ui/componentes/bandeira_na_sede.gd")
const TexturasWebp = preload("res://ui/componentes/texturas_webp.gd")
const SEDE: String = "res://assets/sprites/sede/aurora.webp"
const LIMITE_HISTORICO: int = 24

var _modelo: String = "dragao"
var _livre: bool
var _fundo: Color = Color("#102720")
var _luz: Color = Color("#f1d9a4")
var _sombra: Color = Color("#b98a4d")
var _pincel: Color = Color("#f1d9a4")
var _desenho: Image
var _textura: ImageTexture
var _historico: Array[Image] = []
var _refeitos: Array[Image] = []
var _borracha: bool
var _espessura: int = 12
var _ponteiro: int = -2
var _ultimo_ponto: Vector2
var _atualizacao_pendente: bool
var _grade: GridContainer
var _arranjo: BoxContainer
var _tela: TextureRect
var _painel_desenho: VBoxContainer
var _cores: Dictionary = {}
var _acoes_historico: Array[Button] = []
var _nome: Label
var _sede: TextureRect
var _bandeira_sede: BandeiraNaSede


func montar(dados: Dictionary, retrato: bool) -> void:
	_modelo = str(dados.get("modelo", "dragao"))
	_livre = bool(dados.get("livre", false))
	_fundo = dados.get("fundo", _fundo)
	_luz = dados.get("luz", _luz)
	_sombra = dados.get("sombra", _sombra)
	_pincel = dados.get("pincel", _pincel)
	var desenho_anterior: Image = dados.get("desenho")
	_desenho = desenho_anterior.duplicate() if desenho_anterior != null else (
		Image.create_empty(Arte.TAMANHO.x, Arte.TAMANHO.y, false, Image.FORMAT_RGBA8))

	_arranjo = BoxContainer.new()
	_arranjo.add_theme_constant_override("separation", 20)
	add_child(_arranjo)
	var controles: VBoxContainer = VBoxContainer.new()
	controles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controles.add_theme_constant_override("separation", 8)
	_arranjo.add_child(controles)

	var modos: HBoxContainer = HBoxContainer.new()
	controles.add_child(modos)
	var originais: Button = _botao(modos, "15 modelos", _selecionar_modo.bind(false))
	var desenho_livre: Button = _botao(modos, "Desenhar", _selecionar_modo.bind(true))
	var grupo_modo: ButtonGroup = ButtonGroup.new()
	for botao: Button in [originais, desenho_livre]:
		botao.toggle_mode = true
		botao.button_group = grupo_modo
	originais.set_pressed_no_signal(not _livre)
	desenho_livre.set_pressed_no_signal(_livre)

	_grade = GridContainer.new()
	_grade.add_theme_constant_override("h_separation", 5)
	_grade.add_theme_constant_override("v_separation", 5)
	controles.add_child(_grade)
	var grupo_modelos: ButtonGroup = ButtonGroup.new()
	for id: String in Arte.MODELOS:
		var botao: Button = _botao(_grade, str(Arte.MODELOS[id]), _escolher_modelo.bind(id))
		botao.add_theme_font_size_override("font_size", 14)
		botao.add_theme_constant_override("icon_max_width", 42)
		botao.custom_minimum_size.y = 69
		botao.icon = Arte.textura_modelo(id)
		botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botao.toggle_mode = true
		botao.button_group = grupo_modelos
		botao.set_pressed_no_signal(id == _modelo)

	_painel_desenho = VBoxContainer.new()
	controles.add_child(_painel_desenho)
	_montar_desenho()
	var linha_cores: HFlowContainer = HFlowContainer.new()
	controles.add_child(linha_cores)
	for nome: String in ["Fundo", "Luz", "Sombra", "Pincel"]:
		var seletor: ColorPickerButton = ColorPickerButton.new()
		seletor.edit_alpha = false
		seletor.custom_minimum_size = Vector2(36, 36)
		seletor.accessibility_name = nome
		seletor.color_changed.connect(_mudar_cor.bind(nome))
		var campo: HBoxContainer = HBoxContainer.new()
		linha_cores.add_child(campo)
		campo.add_child(_rotulo(nome))
		campo.add_child(seletor)
		_cores[nome] = campo

	var predefinicoes: HBoxContainer = HBoxContainer.new()
	controles.add_child(predefinicoes)
	predefinicoes.add_child(_rotulo("Paleta"))
	var paletas: OptionButton = OptionButton.new()
	paletas.accessibility_name = "Paleta"
	for nome: String in Arte.PALETAS:
		paletas.add_item(nome)
	paletas.select(-1)
	paletas.item_selected.connect(func(indice: int) -> void: _aplicar_paleta(paletas.get_item_text(indice)))
	predefinicoes.add_child(paletas)

	var tecido: VBoxContainer = VBoxContainer.new()
	_arranjo.add_child(tecido)
	_nome = _rotulo("")
	tecido.add_child(_nome)
	_tela = TextureRect.new()
	_tela.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tela.custom_minimum_size = Vector2(Arte.TAMANHO)
	_tela.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_tela.gui_input.connect(_pintar)
	tecido.add_child(_tela)
	_sede = TextureRect.new()
	_sede.texture = TexturasWebp.carregar(SEDE)
	_sede.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sede.custom_minimum_size = Vector2(254, 143)
	_sede.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tecido.add_child(_sede)
	_bandeira_sede = BandeiraNaSede.new()
	_bandeira_sede.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sede.add_child(_bandeira_sede)
	_bandeira_sede.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ajustar(retrato)
	_atualizar_modo()


func ajustar(retrato: bool) -> void:
	_arranjo.vertical = retrato
	_grade.columns = 3 if retrato else 5
	_sede.visible = not retrato


func rascunho() -> Dictionary:
	return {"modelo": _modelo, "livre": _livre, "fundo": _fundo, "luz": _luz, "sombra": _sombra,
		"pincel": _pincel, "desenho": _desenho}


func imagem() -> Image:
	return Arte.compor(_modelo, _fundo, _luz, _sombra, _desenho if _livre else null)


func _montar_desenho() -> void:
	var ferramentas: HFlowContainer = HFlowContainer.new()
	_painel_desenho.add_child(ferramentas)
	var grupo: ButtonGroup = ButtonGroup.new()
	for nome: String in ["Pincel", "Borracha"]:
		var botao: Button = _botao(ferramentas, nome, func() -> void: _borracha = nome == "Borracha")
		botao.toggle_mode = true
		botao.button_group = grupo
		botao.set_pressed_no_signal(nome == "Pincel")
	_acoes_historico.append(_botao(ferramentas, "Desfazer", _recuperar.bind(_historico, _refeitos)))
	_acoes_historico.append(_botao(ferramentas, "Refazer", _recuperar.bind(_refeitos, _historico)))
	_botao(ferramentas, "Limpar", _limpar)
	var texto: Label = _rotulo("Espessura · %d px" % _espessura)
	_painel_desenho.add_child(texto)
	var espessura: HSlider = HSlider.new()
	espessura.accessibility_name = "Espessura do pincel"
	espessura.min_value = 2
	espessura.max_value = 32
	espessura.step = 1
	espessura.value = _espessura
	espessura.value_changed.connect(func(valor: float) -> void:
		_espessura = int(valor)
		texto.text = "Espessura · %d px" % _espessura)
	_painel_desenho.add_child(espessura)


func _botao(pai: Container, texto: String, acao: Callable) -> Button:
	var botao: Button = Button.new()
	botao.text = texto
	botao.theme_type_variation = "BotaoDificuldade"
	botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	botao.pressed.connect(acao)
	pai.add_child(botao)
	return botao


func _rotulo(texto: String) -> Label:
	var rotulo: Label = Label.new()
	rotulo.text = texto
	rotulo.add_theme_font_size_override("font_size", 16)
	return rotulo


func _mudar_cor(cor: Color, nome: String) -> void:
	match nome:
		"Fundo": _fundo = cor
		"Luz": _luz = cor
		"Sombra": _sombra = cor
		"Pincel": _pincel = cor
	_agendar_atualizacao()


func _aplicar_paleta(nome: String) -> void:
	var cores: Array = Arte.PALETAS[nome]
	_fundo = cores[0]
	if _livre:
		_pincel = cores[1]
	else:
		_luz = cores[1]
		_sombra = cores[2]
	_atualizar_modo()


func _selecionar_modo(livre: bool) -> void:
	_livre = livre
	_ponteiro = -2
	_atualizar_modo()


func _atualizar_modo() -> void:
	_grade.visible = not _livre
	_painel_desenho.visible = _livre
	_tela.mouse_default_cursor_shape = Control.CURSOR_CROSS if _livre else Control.CURSOR_ARROW
	for nome: String in _cores:
		var campo: HBoxContainer = _cores[nome]
		campo.visible = nome == "Fundo" or ((nome == "Pincel") == _livre)
		var seletor: ColorPickerButton = campo.get_child(1)
		seletor.color = {"Fundo": _fundo, "Luz": _luz, "Sombra": _sombra, "Pincel": _pincel}[nome]
	_atualizar()


func _escolher_modelo(id: String) -> void:
	_modelo = id
	_atualizar()


func _agendar_atualizacao() -> void:
	if not _atualizacao_pendente:
		_atualizacao_pendente = true
		_atualizar.call_deferred()


func _atualizar() -> void:
	_atualizacao_pendente = false
	var pixels: Image = imagem()
	if _textura == null:
		_textura = ImageTexture.create_from_image(pixels)
		_tela.texture = _textura
		_bandeira_sede.exibir_textura(_textura)
	else:
		_textura.update(pixels)
		_bandeira_sede.queue_redraw()
	_nome.text = "Desenho livre" if _livre else Arte.MODELOS[_modelo]
	_acoes_historico[0].disabled = _historico.is_empty()
	_acoes_historico[1].disabled = _refeitos.is_empty()


func _registrar() -> void:
	_historico.append(_desenho.duplicate())
	if _historico.size() > LIMITE_HISTORICO:
		_historico.pop_front()
	_refeitos.clear()


func _recuperar(origem: Array[Image], destino: Array[Image]) -> void:
	if not origem.is_empty():
		destino.append(_desenho.duplicate())
		_desenho = origem.pop_back()
		_atualizar()


func _limpar() -> void:
	_registrar()
	_desenho.fill(Color.TRANSPARENT)
	_atualizar()


func _pintar(evento: InputEvent) -> void:
	if not _livre:
		return
	if evento is InputEventScreenTouch:
		_inicio_ou_fim(evento.index, evento.position, evento.pressed)
	elif evento is InputEventScreenDrag and _ponteiro == evento.index:
		_traco(evento.position)
	elif evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_inicio_ou_fim(-1, evento.position, evento.pressed)
	elif evento is InputEventMouseMotion and _ponteiro == -1:
		_traco(evento.position)
	else:
		return
	_tela.accept_event()


func _inicio_ou_fim(id: int, ponto: Vector2, pressionado: bool) -> void:
	if pressionado and _ponteiro == -2:
		_registrar()
		_ponteiro = id
		_ultimo_ponto = _coordenada(ponto)
		_traco(ponto)
	elif not pressionado and _ponteiro == id:
		_ponteiro = -2


func _coordenada(ponto: Vector2) -> Vector2:
	var tamanho: Vector2 = Vector2(Arte.TAMANHO)
	return (ponto / _tela.size * tamanho).clamp(Vector2.ZERO, tamanho - Vector2.ONE)


func _traco(ponto: Vector2) -> void:
	var fim: Vector2 = _coordenada(ponto)
	var raio: float = _espessura / 2.0
	var passos: int = maxi(1, ceili(_ultimo_ponto.distance_to(fim) / maxf(1.0, raio * 0.45)))
	var cor: Color = Color.TRANSPARENT if _borracha else _pincel
	for indice: int in range(passos + 1):
		var centro: Vector2 = _ultimo_ponto.lerp(fim, float(indice) / passos)
		var inicio: Vector2i = Vector2i((centro - Vector2.ONE * raio).floor()).max(Vector2i.ZERO)
		var limite: Vector2i = Vector2i((centro + Vector2.ONE * raio).ceil()).min(Arte.TAMANHO - Vector2i.ONE)
		for y: int in range(inicio.y, limite.y + 1):
			for x: int in range(inicio.x, limite.x + 1):
				if centro.distance_squared_to(Vector2(x, y)) <= raio * raio:
					_desenho.set_pixel(x, y, cor)
	_ultimo_ponto = fim
	_agendar_atualizacao()
