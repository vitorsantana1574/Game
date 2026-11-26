extends Control

const Tema = preload("res://ui/temas/tema_draft.gd")
const Mapa = preload("res://ui/partida/mapa_caldeira.gd")
const Reproducao = preload("res://ui/partida/reproducao_partida.gd")
const SEDE: String = "res://ui/telas/sede_carreira.tscn"
const GRAUS: Array[float] = [1.0, 1.0, 2.0, 4.0]

var _partida: Dictionary
var _reproducao: Reproducao = Reproducao.new()
var _mapa: Mapa
var _corpo: BoxContainer
var _normal: VBoxContainer
var _painel_lateral: PanelContainer
var _resultado: ScrollContainer
var _relogio: Label
var _placares: Array[Label] = []
var _ultimo_lance: Label
var _ritmo: OptionButton
var _progresso: ProgressBar
var _pausa: Button
var _pausado: bool
var _fim: bool
var _fim_em: float = 1.55


func _ready() -> void:
	_partida = Jogo.ultima_partida
	if _partida.is_empty():
		_voltar()
		return
	theme = Tema.criar()
	_montar()
	resized.connect(_dimensionar)
	_dimensionar()
	_recomecar()


func _montar() -> void:
	var fundo: ColorRect = ColorRect.new()
	fundo.color = Color("#0c151e")
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margens: MarginContainer = MarginContainer.new()
	for lado: String in ["top", "bottom", "left", "right"]:
		margens.add_theme_constant_override("margin_" + lado, 18)
	add_child(margens)
	margens.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var pagina: VBoxContainer = VBoxContainer.new()
	pagina.add_theme_constant_override("separation", 12)
	margens.add_child(pagina)
	var topo: HBoxContainer = HBoxContainer.new()
	pagina.add_child(topo)
	var voltar: Button = Tema.botao("←", _voltar)
	voltar.accessibility_name = "Voltar à sede"
	voltar.tooltip_text = "Voltar à sede"
	topo.add_child(voltar)
	var titulo: Label = Tema.texto("Caldeira Glacial", 31)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	if _partida.get("treino", false):
		topo.add_child(Tema.texto("Partida de treino", 16, Tema.SUAVE))
	_normal = VBoxContainer.new()
	_normal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_normal.add_theme_constant_override("separation", 10)
	pagina.add_child(_normal)
	_corpo = BoxContainer.new()
	_corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_corpo.add_theme_constant_override("separation", 14)
	_normal.add_child(_corpo)
	_mapa = Mapa.new()
	var prefs: ConfigFile = ConfigFile.new()
	if prefs.load("user://preferencias_apresentacao.cfg") == OK:
		_mapa.animar = bool(prefs.get_value("abertura", "animacao", true))
	_corpo.add_child(_mapa)
	_montar_placar()
	_montar_controles()
	_resultado = ScrollContainer.new()
	_resultado.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_resultado.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pagina.add_child(_resultado)


func _montar_placar() -> void:
	_painel_lateral = PanelContainer.new()
	_painel_lateral.add_theme_stylebox_override("panel", Tema.caixa(Color("#10212b"), Color("#34505a"), 18))
	_painel_lateral.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_corpo.add_child(_painel_lateral)
	var placar: VBoxContainer = VBoxContainer.new()
	placar.add_theme_constant_override("separation", 12)
	_painel_lateral.add_child(placar)
	_relogio = Tema.texto("00:00", 36, Tema.DOURADO)
	placar.add_child(_relogio)
	for i: int in range(2):
		if i > 0:
			placar.add_child(HSeparator.new())
		var time: Label = Tema.texto(str(_partida["times"][i]["nome"]), 24, Mapa.CORES[i])
		time.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		placar.add_child(time)
		var placar_time: Label = Tema.texto("", 18)
		placar_time.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_placares.append(placar_time)
		placar.add_child(placar_time)
	placar.add_child(HSeparator.new())
	_ultimo_lance = Tema.texto("", 17, Tema.SUAVE)
	_ultimo_lance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ultimo_lance.custom_minimum_size.y = 48.0
	placar.add_child(_ultimo_lance)


func _montar_controles() -> void:
	_progresso = ProgressBar.new()
	_progresso.show_percentage = false
	_progresso.custom_minimum_size.y = 4.0
	_progresso.max_value = maxf(1.0, float(_partida["duracao"]))
	_progresso.add_theme_stylebox_override("background", Tema.caixa(Color("#213847"), Color.TRANSPARENT, 0))
	_progresso.add_theme_stylebox_override("fill", Tema.caixa(Tema.CIANO, Color.TRANSPARENT, 0))
	_normal.add_child(_progresso)
	var acoes: HFlowContainer = HFlowContainer.new()
	acoes.add_theme_constant_override("h_separation", 10)
	_normal.add_child(acoes)
	_pausa = Tema.botao("Pausar", _alternar_pausa)
	acoes.add_child(_pausa)
	_ritmo = OptionButton.new()
	_ritmo.accessibility_name = "Modo de exibição"
	for modo: String in ["Melhores momentos", "Partida inteira · 1×", "Partida inteira · 2×", "Partida inteira · 4×"]:
		_ritmo.add_item(modo)
	acoes.add_child(_ritmo)
	_marcador(acoes, "Aproximar", _mapa.animar, func(ativo: bool) -> void:
		_mapa.aproximar = ativo)
	_marcador(acoes, "Alcance das torres", false, func(ativo: bool) -> void:
		_mapa.alcances = ativo
		_mapa.atualizar_marcas())
	_marcador(acoes, "Acessos", false, func(ativo: bool) -> void:
		_mapa.acessos = ativo
		_mapa.atualizar_marcas())
	acoes.add_child(Tema.botao("Ver resultado", _mostrar_resultado, true))


func _dimensionar() -> void:
	if _corpo == null:
		return
	_corpo.vertical = size.x < 820.0 or size.x < size.y
	_painel_lateral.custom_minimum_size.x = 0.0 if _corpo.vertical else minf(345.0, size.x * 0.30)
	_painel_lateral.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _recomecar() -> void:
	_mapa.inicializar(Jogo.mapa_partida())
	_reproducao.preparar(_partida, _mapa)
	for id: String in _reproducao.epicos:
		_mapa.espera_epico(id, _reproducao.epicos[id]["primeiro"])
	_pausado = false
	_pausa.text = "Pausar"
	_progresso.value = 0.0
	_relogio.text = "00:00"
	_ultimo_lance.text = ""
	_atualizar_placar()
	_resultado.hide()
	_normal.show()
	_fim = false
	_fim_em = 1.55
	_mapa.atualizar(_reproducao.fichas_no_mapa(), 0.0, 0.0)


func _process(delta: float) -> void:
	if _mapa == null or _pausado or _fim:
		return
	var lances: Array[Dictionary] = _reproducao.avancar(delta, GRAUS[_ritmo.selected], _ritmo.selected == 0)
	for lance: Dictionary in lances:
		_exibir_lance(lance)
	var segundo: int = floori(_reproducao.segundo)
	var agora: String = "%02d:%02d" % [floori(float(segundo) / 60.0), segundo % 60]
	if _relogio.text != agora:
		_relogio.text = agora
	_progresso.set_value_no_signal(_reproducao.segundo)
	_atualizar_placar()
	_mapa.atualizar(_reproducao.fichas_no_mapa(), _reproducao.segundo, delta)
	if _reproducao.segundo >= _reproducao.duracao:
		_fim_em -= delta
		if _fim_em <= 0.0:
			_mostrar_resultado()


func _exibir_lance(lance: Dictionary) -> void:
	var tipo: String = lance["tipo"]
	var time: int = int(lance.get("time", -1))
	match tipo:
		"torre":
			_mapa.cair_torre(1 - time, lance["rota"], lance["torre"], lance.get("destaque", false))
			_ultimo_lance.text = "%s · Torre destruída" % lance["minuto"]
		"hydra_surge", "cerbero_surge":
			var id: String = tipo.trim_suffix("_surge")
			_mapa.surgir(id)
			_ultimo_lance.text = "%s · %s em campo" % [_relogio_lance(lance), _nome_epico(id)]
		"hydra", "cerbero":
			_mapa.espera_epico(tipo, _reproducao.epicos[tipo]["respawns"].get(lance["indice"], -1))
			var queda: String = "abatida" if tipo == "hydra" else "abatido"
			var roubo: String = " · Roubo" if lance.get("roubado", false) else ""
			_ultimo_lance.text = "%s · %s %s%s" % [lance["minuto"], _nome_epico(tipo), queda, roubo]
			_mapa.destacar_lance(Mapa.Geometria.EPICOS[tipo], time, tipo)
		"guardiao", "guardiao_renasce":
			var presente: bool = tipo == "guardiao_renasce"
			_mapa.presenca_guardiao(time if presente else 1 - time, presente)
			_ultimo_lance.text = "%s · Guardião %s" % [lance["minuto"], "voltou" if presente else "caiu"]
		"vitoria":
			if time in [0, 1]:
				_mapa.destacar_lance(Mapa.Geometria.BASES[1 - time]["cristal"], time, tipo)
				_ultimo_lance.text = "%s · Cristal destruído" % lance["minuto"]
		"luta", "abate":
			if tipo == "luta" or lance.get("contexto") != "luta":
				var ponto: Vector2 = Vector2(lance["x"], lance["y"])
				_mapa.destacar_lance(_mapa.geometria.projetar(ponto), time if tipo == "abate" else -1, tipo)
				_ultimo_lance.text = "%s · %s" % [lance["minuto"], "Confronto" if tipo == "luta" else "Abate"]


func _atualizar_placar() -> void:
	var quadro: Dictionary = _reproducao.quadro
	for i: int in range(2):
		var texto: String = "%s ouro\n%d abates  ·  %d torres" % [_separar_milhar(int(quadro.get("ouro", [0, 0])[i])),
			quadro.get("abates", [0, 0])[i], quadro.get("torres", [0, 0])[i]]
		if _placares[i].text != texto:
			_placares[i].text = texto


func _alternar_pausa() -> void:
	_pausado = not _pausado
	_pausa.text = "Retomar" if _pausado else "Pausar"


func _mostrar_resultado() -> void:
	_fim = true
	_normal.hide()
	_resultado.show()
	if _resultado.get_child_count() > 0:
		return
	var corpo: VBoxContainer = VBoxContainer.new()
	corpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	corpo.add_theme_constant_override("separation", 10)
	_resultado.add_child(corpo)
	var vencedor: int = _partida["vencedor"]
	var placar: Dictionary = _partida["placar"]
	corpo.add_child(Tema.texto("Vitória de %s" % _partida["times"][vencedor]["nome"], 32, Mapa.CORES[vencedor]))
	corpo.add_child(Tema.texto("%s  ·  %d a %d em abates" % [_relogio_lance({"t": _partida["duracao"]}),
		placar["abates"][0], placar["abates"][1]], 18, Tema.SUAVE))
	var botoes: HFlowContainer = HFlowContainer.new()
	corpo.add_child(botoes)
	botoes.add_child(Tema.botao("Rever partida", _recomecar))
	botoes.add_child(Tema.botao("Voltar à sede", _voltar, true))
	for i: int in range(2):
		var painel: PanelContainer = PanelContainer.new()
		painel.add_theme_stylebox_override("panel", Tema.caixa(Tema.PAINEL, Tema.BORDA, 12))
		corpo.add_child(painel)
		var time: VBoxContainer = VBoxContainer.new()
		painel.add_child(time)
		time.add_child(Tema.texto(str(_partida["times"][i]["nome"]), 21, Mapa.CORES[i]))
		for ficha: Dictionary in _partida["jogadores"]:
			if ficha["time"] == i:
				var jogador: Label = Tema.texto("%s · %s     %d/%d/%d    %d CS    %s ouro" % [
					ficha["apelido"], ficha["campeao_nome"], ficha["abates"], ficha["mortes"],
					ficha["assistencias"], ficha["cs"], _separar_milhar(ficha["ouro"])], 17)
				jogador.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				time.add_child(jogador)


func _voltar() -> void:
	get_tree().change_scene_to_file.call_deferred(SEDE)


static func _marcador(pai: Control, titulo: String, selecionado: bool, acao: Callable) -> void:
	var opcao: CheckBox = CheckBox.new()
	opcao.text = titulo
	opcao.button_pressed = selecionado
	opcao.toggled.connect(acao)
	pai.add_child(opcao)


static func _nome_epico(id: String) -> String:
	return "Hydra" if id == "hydra" else "Cérbero"


static func _relogio_lance(lance: Dictionary) -> String:
	var segundo: int = int(lance["t"])
	return "%02d:%02d" % [floori(float(segundo) / 60.0), segundo % 60]


static func _separar_milhar(valor: int) -> String:
	if valor < 1000:
		return str(valor)
	return "%s.%03d" % [_separar_milhar(floori(float(valor) / 1000.0)), valor % 1000]
