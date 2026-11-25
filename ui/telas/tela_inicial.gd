extends Control

enum Tela { MENU, EQUIPE, SAVES, OPCOES, CREDITOS, SUBSTITUIR, BANDEIRA }

const TemaAbertura = preload("res://ui/temas/tema_abertura.gd")
const SeletorDificuldade = preload("res://ui/componentes/seletor_dificuldade.gd")
const ListaSaves = preload("res://ui/componentes/lista_saves.gd")
const EditorBandeira = preload("res://ui/componentes/editor_bandeira.gd")
const ArteBandeira = preload("res://ui/componentes/arte_bandeira.gd")
const Bandeiras = preload("res://ui/componentes/bandeira_da_carreira.gd")
const TexturasWebp = preload("res://ui/componentes/texturas_webp.gd")
const ARENA: String = "res://assets/sprites/menu/arena.webp"
const OCLUSAO: Texture2D = preload("res://assets/sprites/menu/oclusao.webp")
const REFLETORES: Shader = preload("res://ui/componentes/refletores_abertura.gdshader")
const PREFERENCIAS: String = "user://preferencias_apresentacao.cfg"
var _tela: Tela = Tela.MENU
var _saves: Array[Dictionary] = []
var _ultimo_slot: int = -1
var _rascunho_equipe: Dictionary = {}
var _rascunho_bandeira: Dictionary = {}
var _imagem_bandeira: Image
var _editor_bandeira: EditorBandeira
var _animar: bool = true
var _tempo_luzes: float = 0.0
var _retrato: bool = false

var _fundo: TextureRect
var _material: ShaderMaterial
var _painel: ScrollContainer
var _conteudo: MarginContainer
var _nome: LineEdit
var _erro_nome: Label
var _erro_acao: Label
var _seletor: SeletorDificuldade
var _lista_saves: ListaSaves
var _botao_continuar: Button
var _confirmacao: ConfirmationDialog
var _foco_inicial: Control

func _ready() -> void:
	theme = TemaAbertura.criar()
	var config: ConfigFile = ConfigFile.new()
	if config.load(PREFERENCIAS) == OK:
		_animar = bool(config.get_value("abertura", "animacao", true))

	_saves = Jogo.listar_saves()
	_ultimo_slot = Jogo.ultimo_slot()
	Eventos.carreira_iniciada.connect(_abrir_carreira)
	Eventos.carreira_carregada.connect(_abrir_carreira)
	Eventos.saves_mudaram.connect(exibir_slots)
	Eventos.dificuldade_desbloqueada.connect(_atualizar_desbloqueio)

	var base: ColorRect = ColorRect.new()
	base.color = Color("#0a1718")
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fundo = TextureRect.new()
	_fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fundo.texture = TexturasWebp.carregar(ARENA)
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
		if _tela == Tela.BANDEIRA:
			_editor_bandeira.ajustar(_retrato)

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
	_erro_acao = null
	_lista_saves = null
	_botao_continuar = null

	match _tela:
		Tela.MENU: _montar_menu()
		Tela.EQUIPE: _montar_equipe()
		Tela.SAVES: _montar_saves()
		Tela.OPCOES: _montar_opcoes()
		Tela.CREDITOS: _montar_creditos()
		Tela.SUBSTITUIR: _montar_saves(true)
		Tela.BANDEIRA: _montar_bandeira()

	if _foco_inicial != null:
		_focar_inicio.call_deferred()
	set_process(_animar and _tela == Tela.MENU)


func _focar_inicio() -> void:
	if is_instance_valid(_foco_inicial) and _foco_inicial.is_inside_tree():
		_foco_inicial.grab_focus()

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
			_botao_continuar = botao
			_atualizar_continuar()
		if _animar:
			botao.modulate.a = 0.0
			var entrada: Tween = create_tween().bind_node(botao)
			entrada.tween_property(botao, "modulate:a", 1.0, 0.28).set_delay(indice * 0.045)
		if indice == 0:
			_foco_inicial = botao

	_erro_acao = _rotulo_erro(bloco)


func _montar_equipe() -> void:
	var bloco: VBoxContainer = _cartao("Criar Equipe")
	_texto(bloco, "Nome", 21)
	_nome = LineEdit.new()
	_nome.accessibility_name = "Nome da organização"
	_nome.placeholder_text = "Ex.: Aurora Esports"
	_nome.text = str(_rascunho_equipe.get("nome", ""))
	_nome.custom_minimum_size.y = 53 if _retrato else 44
	_nome.text_submitted.connect(func(_digitado: String) -> void: _confirmar_equipe())
	bloco.add_child(_nome)
	_foco_inicial = _nome
	_erro_nome = _rotulo_erro(bloco)
	_nome.text_changed.connect(func(texto: String) -> void:
		if _erro_nome.visible:
			var erro: String = Jogo.validar_nome_organizacao(texto)
			_erro_nome.text = erro
			_erro_nome.visible = not erro.is_empty()
	)

	_seletor = SeletorDificuldade.new()
	bloco.add_child(_seletor)
	_seletor.montar(Jogo.listar_dificuldades(), Jogo.opcoes_personalizado(), _rascunho_equipe, _retrato)
	_erro_acao = _rotulo_erro(bloco)
	var acoes: Container = _acoes(bloco)
	_botao(acoes, "Voltar", abrir.bind(Tela.MENU))
	var bandeira: Button = _botao(acoes, "Bandeira", _abrir_bandeira)
	if _imagem_bandeira != null:
		bandeira.icon = ImageTexture.create_from_image(_imagem_bandeira)
		bandeira.add_theme_constant_override("icon_max_width", 30)
	_botao(acoes, "Criar equipe", _confirmar_equipe, "AcaoPrincipal")


func _abrir_bandeira() -> void:
	_rascunho_equipe = _ler_formulario()
	abrir(Tela.BANDEIRA)


func _montar_bandeira() -> void:
	var bloco: VBoxContainer = _cartao("Bandeira da equipe")
	_editor_bandeira = EditorBandeira.new()
	bloco.add_child(_editor_bandeira)
	_editor_bandeira.montar(_rascunho_bandeira, _retrato)
	var acoes: Container = _acoes(bloco)
	_foco_inicial = _botao(acoes, "Voltar", abrir.bind(Tela.EQUIPE))
	_botao(acoes, "Usar bandeira", _escolher_bandeira, "AcaoPrincipal")


func _escolher_bandeira() -> void:
	_rascunho_bandeira = _editor_bandeira.rascunho()
	_imagem_bandeira = _editor_bandeira.imagem()
	abrir(Tela.EQUIPE)


func _montar_saves(substituir: bool = false) -> void:
	var bloco: VBoxContainer = _cartao("Substituir save" if substituir else "Carregar")
	if substituir:
		var instrucao: Label = _texto(bloco, "Os quatro espaços estão ocupados. Escolha qual save substituir.", 19)
		instrucao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_saves = ListaSaves.new()
	_lista_saves.add_theme_constant_override("separation", 7)
	bloco.add_child(_lista_saves)
	if substituir:
		_lista_saves.slot_selecionado.connect(_pedir_confirmacao)
	else:
		_lista_saves.slot_selecionado.connect(_carregar)
	_lista_saves.atualizar(_saves)
	_erro_acao = _rotulo_erro(bloco)
	_foco_inicial = _botao(bloco, "Voltar", abrir.bind(Tela.EQUIPE if substituir else Tela.MENU))


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
	var creditos: Label = _texto(bloco, "Arena, equipe, sede e emblemas gerados com IA para o MOBA Manager.\nCorrentes e cadeados modelados e renderizados no Blender.", 21)
	creditos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_foco_inicial = _botao(bloco, "Voltar", abrir.bind(Tela.MENU))

func _nova_equipe() -> void:
	_rascunho_equipe = {}
	_rascunho_bandeira = {}
	_imagem_bandeira = null
	abrir(Tela.EQUIPE)


func _ler_formulario() -> Dictionary:
	var dados: Dictionary = _seletor.rascunho()
	dados["nome"] = _nome.text
	return dados


func _confirmar_equipe() -> void:
	_rascunho_equipe = _ler_formulario()
	var escolhas: Dictionary = _seletor.escolhas()
	escolhas["nome"] = _nome.text
	var resultado: Dictionary = _criar_carreira(escolhas)
	if resultado["ok"]:
		return
	var erros: Dictionary = resultado["erros"]
	if erros.has("slot"):
		_saves = Jogo.listar_saves()
		if _todos_ocupados():
			abrir(Tela.SUBSTITUIR)
			return
	if erros.has("nome"):
		_erro_nome.text = str(erros["nome"])
		_erro_nome.show()
		_nome.grab_focus()
	_mostrar_erros(erros, ["nome"])


func _todos_ocupados() -> bool:
	for registro: Dictionary in _saves:
		if registro.is_empty():
			return false
	return not _saves.is_empty()


func _pedir_confirmacao(slot: int) -> void:
	if is_instance_valid(_confirmacao) or slot < 0 or slot >= _saves.size() or _saves[slot].is_empty():
		return
	var registro: Dictionary = _saves[slot].duplicate()
	var dialogo: ConfirmationDialog = ConfirmationDialog.new()
	_confirmacao = dialogo
	dialogo.title = "Substituir save"
	dialogo.dialog_text = "Substituir o Save %d de %s? O progresso desse save será perdido." % [
		slot + 1, registro["nome"]
	]
	dialogo.get_ok_button().text = "Substituir"
	dialogo.get_cancel_button().text = "Cancelar"
	dialogo.exclusive = true
	dialogo.confirmed.connect(func() -> void:
		_fechar_confirmacao(dialogo)
		_substituir_save(slot, registro)
	)
	dialogo.canceled.connect(_fechar_confirmacao.bind(dialogo))
	add_child(dialogo)
	dialogo.popup_centered()
	dialogo.get_cancel_button().grab_focus()


func _fechar_confirmacao(dialogo: ConfirmationDialog) -> void:
	_confirmacao = null
	dialogo.queue_free()


func _substituir_save(slot: int, registro: Dictionary) -> void:
	_saves = Jogo.listar_saves()
	if _saves[slot] != registro:
		_lista_saves.atualizar(_saves)
		_mostrar_erros({"slot": "O save mudou. Volte ao formulário ou escolha outro espaço."})
		return
	var escolhas: Dictionary = _rascunho_equipe.duplicate()
	if escolhas["dificuldade"] != "personalizado":
		escolhas.erase("capital")
		escolhas.erase("rivais")
	escolhas["slot"] = slot
	var resultado: Dictionary = _criar_carreira(escolhas)
	if not resultado["ok"]:
		_mostrar_erros(resultado["erros"])


func _criar_carreira(escolhas: Dictionary) -> Dictionary:
	var resultado: Dictionary = Jogo.nova_carreira(escolhas)
	if not resultado["ok"]:
		return resultado
	var slot: int = int(resultado["slot"])
	var imagem: Image = _imagem_bandeira if _imagem_bandeira != null else ArteBandeira.padrao()
	var erro: Error = Bandeiras.guardar(slot, Jogo.listar_saves()[slot], imagem)
	if erro != OK:
		push_warning("Não foi possível guardar a bandeira do Save %d. Código %d." % [slot + 1, erro])
	return resultado


func _continuar() -> void:
	var resultado: Dictionary = Jogo.continuar()
	if not resultado["ok"]:
		_mostrar_erros(resultado["erros"])


func _carregar(slot: int) -> void:
	var resultado: Dictionary = Jogo.carregar(slot)
	if not resultado["ok"]:
		exibir_slots(Jogo.listar_saves(), Jogo.ultimo_slot())
		_mostrar_erros(resultado["erros"])


func _abrir_carreira(_resumo: Dictionary) -> void:
	get_tree().change_scene_to_file.call_deferred("res://ui/telas/sede_carreira.tscn")


func _atualizar_continuar() -> void:
	if is_instance_valid(_botao_continuar):
		_botao_continuar.disabled = _ultimo_slot < 0 or _ultimo_slot >= _saves.size() or _saves[_ultimo_slot].is_empty()


func _atualizar_desbloqueio(_id: String) -> void:
	if _tela == Tela.EQUIPE:
		_rascunho_equipe = _ler_formulario()
		abrir(Tela.EQUIPE)


func exibir_slots(registros: Array[Dictionary], ultimo_slot: int) -> void:
	_saves = registros
	_ultimo_slot = ultimo_slot
	_atualizar_continuar()
	if is_instance_valid(_lista_saves):
		_lista_saves.atualizar(_saves)


func _mostrar_erros(erros: Dictionary, ignorar: Array[String] = []) -> void:
	var mensagens: PackedStringArray = []
	for campo: String in erros:
		if campo not in ignorar:
			mensagens.append(str(erros[campo]))
	_erro_acao.text = "\n".join(mensagens)
	_erro_acao.visible = not mensagens.is_empty()


func _rotulo_erro(pai: Container) -> Label:
	var rotulo: Label = _texto(pai, "", 18, Color("#ffb9a9"))
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.hide()
	return rotulo


func _guardar_animacao(ativa: bool) -> void:
	_animar = ativa
	var config: ConfigFile = ConfigFile.new()
	config.set_value("abertura", "animacao", ativa)
	config.save(PREFERENCIAS)

func _cartao(titulo: String) -> VBoxContainer:
	var central: CenterContainer = CenterContainer.new()
	_conteudo.add_child(central)
	var painel: PanelContainer = PanelContainer.new()
	painel.custom_minimum_size.x = minf(840.0, maxf(0.0, _painel.size.x - (58.0 if _retrato else 106.0)))
	central.add_child(painel)
	var bloco: VBoxContainer = _coluna(painel)
	_texto(bloco, titulo, 46 if not _retrato else 34)
	return bloco

func _coluna(pai: Container) -> VBoxContainer:
	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 9)
	pai.add_child(coluna)
	return coluna

func _acoes(pai: Container) -> Container:
	if _retrato:
		var fluxo: HFlowContainer = HFlowContainer.new()
		fluxo.add_theme_constant_override("h_separation", 8)
		pai.add_child(fluxo)
		return fluxo
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
