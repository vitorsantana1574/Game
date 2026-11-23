extends Control

signal nova_carreira_solicitada(escolhas: Dictionary)
signal carregamento_solicitado(slot: int)

enum Tela { MENU, EQUIPE, SAVES, OPCOES, CREDITOS, CHEGADA }

const TemaAbertura = preload("res://ui/temas/tema_abertura.gd")
const ARENA: Texture2D = preload("res://assets/sprites/menu/arena.webp")
const OCLUSAO: Texture2D = preload("res://assets/sprites/menu/oclusao.webp")
const CADEADOS: Texture2D = preload("res://assets/sprites/menu/cadeados.webp")
const REFLETORES: Shader = preload("res://ui/componentes/refletores_abertura.gdshader")
const PREFERENCIAS: String = "user://preferencias_apresentacao.cfg"
const MODOS: Array[String] = ["Fácil", "Médio", "Difícil", "Personalizado"]
const CAPITAIS_EXEMPLO: Array[int] = [40000, 80000, 120000]
const CAIXA_EXEMPLO: Array[String] = ["Menos dinheiro", "Caixa equilibrado", "Mais dinheiro"]
const RIVAIS_EXEMPLO: Array[String] = ["Adversários iniciantes", "Adversários equilibrados", "Adversários experientes"]
const MAXIMO_SLOTS: int = 4

## As opções e os saves abaixo servem para testar a apresentação isoladamente.
@export var demonstracao: bool = true

var _tela: Tela = Tela.MENU
var _saves: Array[Dictionary] = []
var _ultimo_slot: int = -1
var _slot_editado: int = -1
var _carreira_visivel: Dictionary = {}
var _rascunho_equipe: Dictionary = {}
var _animar: bool = true
var _tempo_luzes: float = 0.0
var _retrato: bool = false

var _fundo: TextureRect
var _material: ShaderMaterial
var _painel: ScrollContainer
var _conteudo: MarginContainer
var _nome: LineEdit
var _erro: Label
var _personalizar: VBoxContainer
var _escolha_capital: OptionButton
var _escolha_rivais: OptionButton
var _valor_capital: Label
var _itens_dificuldade: Label
var _modo_visivel: int = 1
var _foco_inicial: Control

func _ready() -> void:
	theme = TemaAbertura.criar()
	var config: ConfigFile = ConfigFile.new()
	if config.load(PREFERENCIAS) == OK:
		_animar = bool(config.get_value("abertura", "animacao", true))

	if demonstracao and _saves.is_empty():
		_saves = [
			{"nome": "Aurora Esports", "fase": "Regional · Dia 12", "exemplo": true},
			{"nome": "Vale Rift", "fase": "Regional · Dia 4", "exemplo": true}
		]
		_ultimo_slot = 0

	var base: ColorRect = ColorRect.new()
	base.color = Color("#0a1718")
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fundo = TextureRect.new()
	_fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fundo.texture = ARENA
	_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = REFLETORES
	_material.set_shader_parameter("oclusao", OCLUSAO)
	_fundo.material = _material
	add_child(_fundo)
	redimensionar()
	resized.connect(_ao_redimensionar)
	abrir(Tela.MENU)

func _process(delta: float) -> void:
	_tempo_luzes += minf(delta, 0.09)
	_material.set_shader_parameter("segundos", _tempo_luzes)

func _ao_redimensionar() -> void:
	var retrato_anterior: bool = _retrato
	redimensionar()
	if _painel == null:
		return
	if _tela == Tela.EQUIPE and _retrato != retrato_anterior:
		_rascunho_equipe = _ler_formulario()
		abrir(_tela)
	else:
		_posicionar_painel()

func redimensionar() -> void:
	_retrato = size.x < size.y * 1.06
	var altura: float = size.x * 9.0 / 16.0 if _retrato and _tela == Tela.MENU else size.y
	_fundo.size = Vector2(size.x, altura)
	_material.set_shader_parameter("proporcao_quadro", size.x / maxf(altura, 1.0))
	_material.set_shader_parameter("menu_retrato", _retrato and _tela == Tela.MENU)

func abrir(tela: Tela) -> void:
	_tela = tela
	redimensionar()
	if _painel != null:
		remove_child(_painel)
		_painel.queue_free()

	_painel = ScrollContainer.new()
	_painel.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_painel.follow_focus = true
	add_child(_painel)
	_posicionar_painel()
	_conteudo = MarginContainer.new()
	_conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_conteudo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for lado: String in ["left", "right", "top", "bottom"]:
		_conteudo.add_theme_constant_override("margin_" + lado, 26 if _retrato else 48)
	_painel.add_child(_conteudo)
	_foco_inicial = null

	match _tela:
		Tela.MENU: _montar_menu()
		Tela.EQUIPE: _montar_equipe()
		Tela.SAVES: _montar_saves()
		Tela.OPCOES: _montar_opcoes()
		Tela.CREDITOS: _montar_creditos()
		Tela.CHEGADA: _montar_chegada()

	if _foco_inicial != null:
		_foco_inicial.grab_focus.call_deferred()
	set_process(_animar and _tela == Tela.MENU)

func _posicionar_painel() -> void:
	var topo: float = _fundo.size.y if _retrato and _tela == Tela.MENU else 0.0
	var escala: float = maxf(0.1, size.x / (390.0 if _retrato else 1440.0))
	_painel.position = Vector2(0.0, topo)
	_painel.scale = Vector2.ONE * escala
	_painel.size = Vector2(size.x, maxf(0.0, size.y - topo)) / escala

func _montar_menu() -> void:
	var bloco: VBoxContainer = _coluna(_conteudo)
	bloco.alignment = BoxContainer.ALIGNMENT_CENTER
	bloco.add_theme_constant_override("separation", 3)
	_texto(bloco, "MOBA MANAGER", 40 if not _retrato else 34, TemaAbertura.VERDE)
	var espaco: Control = Control.new()
	espaco.custom_minimum_size.y = 12
	bloco.add_child(espaco)
	var menu: Array[String] = ["COMEÇAR", "CONTINUAR", "CARREGAR", "Opções", "Créditos"]
	var destinos: Array[Callable] = [
		_nova_equipe, _continuar, abrir.bind(Tela.SAVES),
		abrir.bind(Tela.OPCOES), abrir.bind(Tela.CREDITOS)
	]
	for indice: int in range(menu.size()):
		var botao: Button = _botao(bloco, menu[indice], destinos[indice], "OpcaoMenu")
		botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
		botao.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var tamanho_base: int = 27 if _retrato else 34
		botao.add_theme_font_size_override("font_size", roundi(1.42 * tamanho_base) if indice < 3 else tamanho_base)
		if indice == 1:
			botao.disabled = _ultimo_slot < 0 or _ultimo_slot >= _saves.size() or _saves[_ultimo_slot].is_empty()
		if _animar:
			botao.modulate.a = 0.0
			var entrada: Tween = create_tween().bind_node(botao)
			entrada.tween_property(botao, "modulate:a", 1.0, 0.28).set_delay(indice * 0.045)
		if indice == 0:
			_foco_inicial = botao

func _montar_equipe() -> void:
	var bloco: VBoxContainer = _cartao("Criar Equipe")
	_texto(bloco, "Nome", 21)
	_nome = LineEdit.new()
	_nome.placeholder_text = "Ex.: Aurora Esports"
	_nome.text = str(_rascunho_equipe.get("nome", ""))
	_nome.custom_minimum_size.y = 53 if _retrato else 44
	_nome.text_submitted.connect(func(_nome_digitado: String) -> void: _confirmar_equipe())
	bloco.add_child(_nome)
	_foco_inicial = _nome
	_erro = _texto(bloco, "Digite um nome.", 18, Color("#ffb9a9"))
	_erro.hide()
	_nome.text_changed.connect(func(texto: String) -> void:
		if not texto.strip_edges().is_empty():
			_erro.hide()
	)

	var corpo: BoxContainer
	if _retrato:
		corpo = VBoxContainer.new()
	else:
		corpo = HBoxContainer.new()
	corpo.add_theme_constant_override("separation", 24)
	bloco.add_child(corpo)
	var escolhas: VBoxContainer = _coluna(corpo)
	escolhas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texto(escolhas, "Dificuldade", 21)
	var grade: GridContainer = GridContainer.new()
	grade.columns = 3
	grade.add_theme_constant_override("h_separation", 8)
	escolhas.add_child(grade)
	_modo_visivel = clampi(int(_rascunho_equipe.get("modo", 1)), 0, 3)
	var grupo: ButtonGroup = ButtonGroup.new()
	for indice: int in range(3):
		_modo(grade, grupo, indice)
	for indice: int in range(2):
		var vazio: Control = Control.new()
		grade.add_child(vazio)
	_montar_pesadelo(grade)
	_modo(escolhas, grupo, 3)
	_personalizar = _coluna(escolhas)
	_escolha_capital = _seletor(_personalizar, "Capital", [
		_formatar_capital(40000), _formatar_capital(80000), _formatar_capital(120000)
	], clampi(int(_rascunho_equipe.get("capital", 1)), 0, 2))
	_escolha_rivais = _seletor(_personalizar, "Rivais", ["Iniciantes", "Equilibrados", "Experientes"],
		clampi(int(_rascunho_equipe.get("rivais", 1)), 0, 2))

	var leitura: VBoxContainer = _coluna(corpo)
	leitura.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not _retrato:
		leitura.custom_minimum_size.x = 246
	_texto(leitura, "Capital inicial:", 19, TemaAbertura.SUAVE)
	_valor_capital = _texto(leitura, "", 40, TemaAbertura.DOURADO)
	_itens_dificuldade = _texto(leitura, "", 18, TemaAbertura.SUAVE)
	_itens_dificuldade.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_itens_dificuldade.custom_minimum_size.x = 180
	_atualizar_dificuldade()

	var acoes: HBoxContainer = _acoes(bloco)
	_botao(acoes, "Voltar", abrir.bind(Tela.MENU))
	_botao(acoes, "Criar equipe", _confirmar_equipe, "AcaoPrincipal")
	if not demonstracao:
		var aviso: Label = _texto(bloco, "Valores ilustrativos enquanto a configuração da carreira está em desenvolvimento.", 16, TemaAbertura.SUAVE)
		aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _montar_pesadelo(grade: GridContainer) -> void:
	var painel: PanelContainer = PanelContainer.new()
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_theme_stylebox_override("panel", TemaAbertura.caixa(Color("#070a0d"), TemaAbertura.BORDA, 4))
	grade.add_child(painel)
	var desenho: VBoxContainer = _coluna(painel)
	var rotulo: Label = _texto(desenho, "Pesadelo", 16, TemaAbertura.SUAVE)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.accessibility_name = "Pesadelo, bloqueado"
	var correntes: TextureRect = TextureRect.new()
	correntes.texture = CADEADOS
	correntes.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	correntes.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	correntes.custom_minimum_size.y = 43
	correntes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desenho.add_child(correntes)

func _montar_saves() -> void:
	var bloco: VBoxContainer = _cartao("Carregar")
	for indice: int in range(MAXIMO_SLOTS):
		var registro: Dictionary = _saves[indice] if indice < _saves.size() else {}
		var legenda: String = "Save %d · Vazio" % (indice + 1)
		if not registro.is_empty():
			legenda = "Save %d · %s · %s" % [indice + 1, registro.get("nome", ""), registro.get("fase", "")]
			if registro.get("exemplo", false):
				legenda += " · Exemplo"
		var botao: Button = _botao(bloco, legenda, _carregar.bind(indice))
		botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
		botao.disabled = registro.is_empty()
	var voltar: Button = _botao(bloco, "Voltar", abrir.bind(Tela.MENU))
	_foco_inicial = voltar

func _montar_opcoes() -> void:
	var bloco: VBoxContainer = _cartao("Opções")
	var escolha: CheckButton = CheckButton.new()
	escolha.text = "Animação do menu"
	escolha.button_pressed = _animar
	escolha.toggled.connect(_guardar_animacao)
	bloco.add_child(escolha)
	_foco_inicial = escolha
	_botao(bloco, "Voltar", abrir.bind(Tela.MENU))

func _montar_creditos() -> void:
	var bloco: VBoxContainer = _cartao("Créditos")
	var creditos: Label = _texto(bloco, "Arena e equipe geradas com IA para o MOBA Manager.\nCorrentes e cadeados modelados e renderizados no Blender.", 21)
	creditos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_foco_inicial = _botao(bloco, "Voltar", abrir.bind(Tela.MENU))

func _montar_chegada() -> void:
	var bloco: VBoxContainer = _coluna(_conteudo)
	bloco.alignment = BoxContainer.ALIGNMENT_END
	_texto(bloco, "LIGA REGIONAL", 21, TemaAbertura.DOURADO)
	var titulo: Label = _texto(bloco, str(_carreira_visivel.get("nome", "")), 60)
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var acoes: HBoxContainer = _acoes(bloco)
	_foco_inicial = _botao(acoes, "Menu principal", abrir.bind(Tela.MENU))
	if demonstracao and not _carreira_visivel.get("exemplo", false) and _ultimo_slot >= 0:
		_botao(acoes, "Editar equipe", _editar_equipe)

func _nova_equipe() -> void:
	_slot_editado = -1
	_rascunho_equipe = {}
	abrir(Tela.EQUIPE)

func _editar_equipe() -> void:
	_slot_editado = _ultimo_slot
	_rascunho_equipe = _carreira_visivel.duplicate()
	abrir(Tela.EQUIPE)

func _ler_formulario() -> Dictionary:
	return {
		"nome": _nome.text.strip_edges(),
		"modo": _modo_visivel,
		"capital": _escolha_capital.selected,
		"rivais": _escolha_rivais.selected,
	}

func _confirmar_equipe() -> void:
	var escolhas: Dictionary = _ler_formulario()
	if escolhas["nome"].is_empty():
		_erro.text = "Digite um nome."
		_erro.show()
		_nome.grab_focus()
		return
	if not demonstracao:
		_erro.text = "A criação de carreira depende da integração com a lógica do jogo."
		_erro.show()
		nova_carreira_solicitada.emit(escolhas)
		return

	_carreira_visivel = escolhas
	_carreira_visivel["fase"] = "Regional · Dia 1"
	var slot: int = _slot_editado if _slot_editado >= 0 else _primeiro_slot_vazio()
	_ultimo_slot = slot
	if slot >= 0:
		if slot == _saves.size():
			_saves.append(_carreira_visivel)
		else:
			_saves[slot] = _carreira_visivel
	abrir(Tela.CHEGADA)

func _primeiro_slot_vazio() -> int:
	for indice: int in range(MAXIMO_SLOTS):
		if indice >= _saves.size() or _saves[indice].is_empty():
			return indice
	return -1

func _continuar() -> void:
	_carregar(_ultimo_slot)

func _carregar(slot: int) -> void:
	if slot < 0 or slot >= _saves.size() or _saves[slot].is_empty():
		return
	if demonstracao:
		_ultimo_slot = slot
		_carreira_visivel = _saves[slot].duplicate()
		abrir(Tela.CHEGADA)
	else:
		carregamento_solicitado.emit(slot)

## Recebe cópias de resumos de carreiras para exibição, com índices de 0 a 3.
func exibir_slots(registros: Array[Dictionary], ultimo_slot: int) -> void:
	_saves.clear()
	for indice: int in range(mini(MAXIMO_SLOTS, registros.size())):
		_saves.append(registros[indice].duplicate())
	_ultimo_slot = ultimo_slot
	if is_node_ready() and (_tela == Tela.MENU or _tela == Tela.SAVES):
		abrir(_tela)

func _guardar_animacao(ativa: bool) -> void:
	_animar = ativa
	var config: ConfigFile = ConfigFile.new()
	config.set_value("abertura", "animacao", ativa)
	config.save(PREFERENCIAS)

func _modo(pai: Container, grupo: ButtonGroup, indice: int) -> void:
	var botao: Button = _botao(pai, MODOS[indice], _mudar_modo.bind(indice))
	botao.toggle_mode = true
	botao.button_group = grupo
	botao.button_pressed = indice == _modo_visivel
	botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botao.add_theme_font_size_override("font_size", 18)

func _mudar_modo(indice: int) -> void:
	_modo_visivel = indice
	_atualizar_dificuldade()

func _atualizar_dificuldade() -> void:
	var personalizado: bool = _modo_visivel == 3
	_personalizar.visible = personalizado
	var indice_dinheiro: int = _escolha_capital.selected if personalizado else 2 - _modo_visivel
	var indice_rivais: int = _escolha_rivais.selected if personalizado else _modo_visivel
	_valor_capital.text = _formatar_capital(CAPITAIS_EXEMPLO[indice_dinheiro])
	_itens_dificuldade.text = "• %s\n• %s" % [CAIXA_EXEMPLO[indice_dinheiro], RIVAIS_EXEMPLO[indice_rivais]]

func _seletor(pai: Container, rotulo: String, valores: Array[String], selecionado: int) -> OptionButton:
	_texto(pai, rotulo, 18)
	var seletor: OptionButton = OptionButton.new()
	for valor: String in valores:
		seletor.add_item(valor)
	seletor.selected = selecionado
	seletor.item_selected.connect(func(_indice: int) -> void: _atualizar_dificuldade())
	pai.add_child(seletor)
	return seletor

func _cartao(titulo: String) -> VBoxContainer:
	var central: CenterContainer = CenterContainer.new()
	_conteudo.add_child(central)
	var painel: PanelContainer = PanelContainer.new()
	painel.custom_minimum_size.x = minf(740.0, maxf(0.0, _painel.size.x - (58.0 if _retrato else 106.0)))
	central.add_child(painel)
	var bloco: VBoxContainer = _coluna(painel)
	_texto(bloco, titulo, 46 if not _retrato else 34)
	return bloco

func _coluna(pai: Container) -> VBoxContainer:
	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 9)
	pai.add_child(coluna)
	return coluna

func _acoes(pai: Container) -> HBoxContainer:
	var acoes: HBoxContainer = HBoxContainer.new()
	acoes.add_theme_constant_override("separation", 12)
	pai.add_child(acoes)
	return acoes

func _botao(pai: Container, texto: String, acao: Callable, variante: String = "") -> Button:
	var botao: Button = Button.new()
	botao.text = texto
	botao.custom_minimum_size.y = 54 if _retrato else 49
	botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if not variante.is_empty():
		botao.theme_type_variation = variante
	botao.pressed.connect(acao)
	pai.add_child(botao)
	return botao

func _texto(pai: Container, texto: String, tamanho: int, cor: Color = TemaAbertura.TEXTO) -> Label:
	var rotulo: Label = Label.new()
	rotulo.text = texto
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", cor)
	pai.add_child(rotulo)
	return rotulo

func _formatar_capital(valor: int) -> String:
	return "R$ %d.%03d" % [floori(valor / 1000.0), valor % 1000]
