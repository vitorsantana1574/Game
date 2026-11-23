extends VBoxContainer

const TemaAbertura = preload("res://ui/temas/tema_abertura.gd")
const CADEADOS: Texture2D = preload("res://assets/sprites/menu/cadeados.webp")
const PERSONALIZADO: String = "personalizado"

var _personalizar: BoxContainer
var _capital: OptionButton
var _rivais: OptionButton
var _valor: Label
var _descricao: Label
var _id: String = "normal"
var _predefinicoes: Array[Dictionary] = []


func montar(dificuldades: Array[Dictionary], opcoes: Dictionary, rascunho: Dictionary,
		retrato: bool) -> void:
	add_theme_constant_override("separation", 8)
	_predefinicoes = dificuldades
	_id = str(rascunho.get("dificuldade", "normal"))

	var corpo: BoxContainer
	if retrato:
		corpo = VBoxContainer.new()
	else:
		corpo = HBoxContainer.new()
	corpo.add_theme_constant_override("separation", 18)
	add_child(corpo)

	var escolhas: VBoxContainer = VBoxContainer.new()
	escolhas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	escolhas.add_theme_constant_override("separation", 8)
	corpo.add_child(escolhas)
	_rotulo(escolhas, "Dificuldade", 21)
	var fileira: HBoxContainer = HBoxContainer.new()
	fileira.add_theme_constant_override("separation", 6)
	escolhas.add_child(fileira)

	var grupo: ButtonGroup = ButtonGroup.new()
	var modo_personalizado: Dictionary = {}
	var condicao: String = ""
	for item: Dictionary in dificuldades:
		var id: String = str(item["id"])
		if id == PERSONALIZADO:
			modo_personalizado = item
		elif item["bloqueada"]:
			condicao = str(item["condicao_desbloqueio"])
			_modo_bloqueado(fileira, str(item["nome"]), condicao)
		else:
			_botao_modo(fileira, grupo, item, retrato)

	if not modo_personalizado.is_empty():
		_botao_modo(escolhas, grupo, modo_personalizado, retrato)
	if not condicao.is_empty():
		var ajuda: Label = _rotulo(escolhas, "Desbloqueie Pesadelo: " + condicao, 16, TemaAbertura.SUAVE)
		ajuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if retrato:
		_personalizar = VBoxContainer.new()
	else:
		_personalizar = HBoxContainer.new()
	_personalizar.add_theme_constant_override("separation", 8)
	escolhas.add_child(_personalizar)
	_capital = _seletor("Capital", opcoes["capitais"], str(rascunho.get("capital", "medio")))
	_rivais = _seletor("Rivais", opcoes["rivais"], str(rascunho.get("rivais", "equilibrados")))

	var leitura: VBoxContainer = VBoxContainer.new()
	if not retrato:
		leitura.custom_minimum_size.x = 224
	corpo.add_child(leitura)
	_rotulo(leitura, "Capital inicial:", 19, TemaAbertura.SUAVE)
	_valor = _rotulo(leitura, "", 38, TemaAbertura.DOURADO)
	_descricao = _rotulo(leitura, "", 18, TemaAbertura.SUAVE)
	_descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_atualizar()


func escolhas() -> Dictionary:
	var dados: Dictionary = {"dificuldade": _id}
	if _id == PERSONALIZADO:
		dados["capital"] = _opcao(_capital).get("id", "")
		dados["rivais"] = _opcao(_rivais).get("id", "")
	return dados


func rascunho() -> Dictionary:
	return {
		"dificuldade": _id,
		"capital": _opcao(_capital).get("id", ""),
		"rivais": _opcao(_rivais).get("id", ""),
	}


func _botao_modo(pai: Container, grupo: ButtonGroup, item: Dictionary, retrato: bool) -> void:
	var botao: Button = Button.new()
	var id: String = str(item["id"])
	botao.name = id
	botao.text = str(item["nome"])
	botao.toggle_mode = true
	botao.button_group = grupo
	botao.button_pressed = id == _id
	botao.theme_type_variation = "BotaoDificuldade"
	botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botao.custom_minimum_size.y = 49
	botao.add_theme_font_size_override("font_size", 15 if retrato else 19)
	botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	botao.pressed.connect(func() -> void:
		_id = id
		_atualizar()
	)
	pai.add_child(botao)


func _modo_bloqueado(pai: Container, rotulo: String, condicao: String) -> void:
	var painel: PanelContainer = PanelContainer.new()
	painel.name = "pesadelo_bloqueado"
	painel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	painel.add_theme_stylebox_override("panel", TemaAbertura.caixa(Color("#070a0d"), TemaAbertura.BORDA, 3))
	painel.tooltip_text = condicao
	painel.accessibility_name = rotulo + ", bloqueado"
	painel.accessibility_description = condicao
	pai.add_child(painel)

	var bloco: VBoxContainer = VBoxContainer.new()
	bloco.add_theme_constant_override("separation", 0)
	bloco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(bloco)
	var nome: Label = _rotulo(bloco, rotulo, 15, TemaAbertura.SUAVE)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var correntes: TextureRect = TextureRect.new()
	correntes.texture = CADEADOS
	correntes.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	correntes.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	correntes.custom_minimum_size.y = 27
	correntes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bloco.add_child(correntes)


func _seletor(titulo: String, itens: Array, selecionado: String) -> OptionButton:
	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_personalizar.add_child(coluna)
	_rotulo(coluna, titulo, 17)
	var seletor: OptionButton = OptionButton.new()
	seletor.name = titulo
	seletor.accessibility_name = titulo
	seletor.add_theme_font_size_override("font_size", 17)
	coluna.add_child(seletor)
	var indice: int = 0
	for item: Dictionary in itens:
		var texto: String = _formatar_reais(int(item["valor"])) if item.has("valor") else str(item["nome"])
		seletor.add_item(texto)
		var posicao: int = seletor.item_count - 1
		seletor.set_item_metadata(posicao, item)
		if str(item["id"]) == selecionado:
			indice = posicao
	if seletor.item_count > 0:
		seletor.select(indice)
	seletor.item_selected.connect(func(_indice: int) -> void: _atualizar())
	return seletor


func _atualizar() -> void:
	_personalizar.visible = _id == PERSONALIZADO
	if _personalizar.visible:
		var capital: Dictionary = _opcao(_capital)
		var rivais: Dictionary = _opcao(_rivais)
		_atualizar_resumo(int(capital.get("valor", 0)), str(capital.get("nome", "")), str(rivais.get("nome", "")))
	else:
		for item: Dictionary in _predefinicoes:
			if str(item["id"]) == _id:
				_atualizar_resumo(int(item["capital_valor"]), str(item["capital_nome"]), str(item["rivais_nome"]))
				break


func _atualizar_resumo(capital: int, caixa: String, rivais: String) -> void:
	_valor.text = _formatar_reais(capital)
	_descricao.text = "• %s\n• %s" % [caixa, rivais]


func _opcao(seletor: OptionButton) -> Dictionary:
	return seletor.get_item_metadata(seletor.selected) if seletor.selected >= 0 else {}


func _rotulo(pai: Container, texto: String, tamanho: int, cor: Color = TemaAbertura.TEXTO) -> Label:
	var rotulo: Label = Label.new()
	rotulo.text = texto
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(rotulo)
	return rotulo


func _formatar_reais(valor: int) -> String:
	var digitos: String = str(valor)
	var formatado: String = ""
	while digitos.length() > 3:
		formatado = "." + digitos.right(3) + formatado
		digitos = digitos.left(digitos.length() - 3)
	return "R$ " + digitos + formatado
