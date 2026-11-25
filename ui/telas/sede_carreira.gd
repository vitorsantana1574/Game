extends Control

const Tema = preload("res://ui/temas/tema_abertura.gd")
const Ficha = preload("res://ui/componentes/ficha_ancorada.gd")
const ARTE: Texture2D = preload("res://assets/sprites/sede/aurora.webp")
const MENU: String = "res://ui/telas/tela_inicial.tscn"
const ICONE_ESTACAO: Texture2D = preload("res://assets/sprites/icones/sede_estacao.svg")
const ICONES: Dictionary = {
	"calendario": preload("res://assets/sprites/icones/sede_calendario.svg"),
	"tecnico": preload("res://assets/sprites/icones/sede_reuniao.svg"),
	"financas": preload("res://assets/sprites/icones/sede_contas.svg"),
}
const LOCAIS: Dictionary = {"calendario": "Calendário", "tecnico": "Mesa de reunião", "financas": "Livro de contas"}
const POSICOES: Dictionary = {
	"topo": "Topo", "selva": "Selva", "meio": "Meio", "atirador": "Atirador", "suporte": "Suporte",
}
const MARCADORES: Dictionary = {
	"topo": Vector2(0.13, 0.57), "selva": Vector2(0.22, 0.49), "meio": Vector2(0.307, 0.42),
	"atirador": Vector2(0.391, 0.351), "suporte": Vector2(0.472, 0.284),
	"calendario": Vector2(0.673, 0.246), "tecnico": Vector2(0.615, 0.515),
	"financas": Vector2(0.827, 0.706),
}
const ATRIBUTOS: Dictionary = {
	"farm": "Farm", "micro": "Micro", "macro": "Macro", "resistencia": "Resistência", "mental": "Mental",
}
const ESTADOS: Dictionary = {
	"energia": "Energia", "satisfacao": "Satisfação", "lealdade": "Lealdade", "experiencia": "Experiência",
}
const VERMELHO: Color = Color("#ffa39b")
const AMBAR: Color = Color("#e6c597")
const FUNDO: Color = Color("#101a17")

var _espaco: Control
var _arte: TextureRect
var _topo: PanelContainer
var _rodape: PanelContainer
var _nome: Label
var _data: Label
var _data_compacta: Label
var _janela: Label
var _dinheiro: Button
var _botoes: Dictionary = {}
var _legendas: Dictionary = {}
var _ficha: Ficha
var _aviso: Label
var _tempo_aviso: Timer
var _resumo: Dictionary
var _titulares: Dictionary
var _historico: Array[Dictionary] = []
var _avisos_dia: PackedStringArray = []
var _alvo: String
var _detalhe: String
var _id_pessoa: String
var _animar: bool = true
var _fim: bool = false


func _ready() -> void:
	theme = Tema.criar()
	theme.default_font_size = 20
	var preferencias: ConfigFile = ConfigFile.new()
	if preferencias.load("user://preferencias_apresentacao.cfg") == OK:
		_animar = bool(preferencias.get_value("abertura", "animacao", true))
	_montar_cena()
	_ligar_sinais()
	_atualizar_sede()
	resized.connect(_posicionar)
	_posicionar()
	if bool(_resumo.get("encerrada", false)):
		_encerrar(_resumo)


func _montar_cena() -> void:
	var fundo: ColorRect = ColorRect.new()
	fundo.color = Color("#0c1512")
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_espaco = Control.new()
	_espaco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_espaco)
	_arte = TextureRect.new()
	_arte.texture = ARTE
	_arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_espaco.add_child(_arte)
	for id: String in MARCADORES:
		var rotulo: String = str(POSICOES.get(id, LOCAIS.get(id, "")))
		var botao: Button = _botao(_espaco, "", _abrir.bind(id))
		botao.icon = ICONES.get(id, ICONE_ESTACAO)
		botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.add_theme_stylebox_override("normal", Tema.caixa(FUNDO, Tema.BORDA, 6))
		botao.accessibility_name = rotulo
		botao.tooltip_text = rotulo
		_botoes[id] = botao
		if LOCAIS.has(id):
			var legenda: Label = _texto(_espaco, rotulo, 15)
			legenda.mouse_filter = Control.MOUSE_FILTER_IGNORE
			legenda.add_theme_stylebox_override("normal", Tema.caixa(FUNDO, Tema.BORDA, 4))
			_legendas[id] = legenda

	_topo = _barra()
	var cabecalho: HBoxContainer = HBoxContainer.new()
	cabecalho.add_theme_constant_override("separation", 15)
	_topo.add_child(cabecalho)
	var identidade: VBoxContainer = VBoxContainer.new()
	identidade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecalho.add_child(identidade)
	_texto(identidade, "MOBA MANAGER", 14, Tema.VERDE)
	_nome = _texto(identidade, "", 26)
	_nome.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_data_compacta = _texto(identidade, "", 15, Tema.SUAVE)
	_data = _texto(cabecalho, "", 17, Tema.SUAVE)
	_dinheiro = _botao(cabecalho, "", _abrir.bind("dinheiro"))
	_dinheiro.add_theme_color_override("font_color", Tema.VERDE)

	_rodape = _barra()
	var rodape: HBoxContainer = HBoxContainer.new()
	rodape.add_theme_constant_override("separation", 10)
	_rodape.add_child(rodape)
	_janela = _texto(rodape, "", 17, Tema.SUAVE)
	_janela.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_botao(rodape, "Salvar", _salvar)
	_botao(rodape, "Menu principal", _pedir_saida)

	_ficha = Ficha.new()
	_espaco.add_child(_ficha)
	_ficha.voltar.connect(_voltar)
	_aviso = _texto(_espaco, "", 18, Color("#ffe5be"))
	_aviso.add_theme_stylebox_override("normal", Tema.caixa(Color("#30271d"), AMBAR, 10))
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.hide()
	_tempo_aviso = Timer.new()
	_tempo_aviso.one_shot = true
	_tempo_aviso.timeout.connect(_aviso.hide)
	add_child(_tempo_aviso)


func _barra() -> PanelContainer:
	var barra: PanelContainer = PanelContainer.new()
	barra.add_theme_stylebox_override("panel", Tema.caixa(FUNDO, Color("#27392f"), 9))
	add_child(barra)
	return barra


func _posicionar() -> void:
	var escala: float = clampf(size.x / 1450.0, 0.69, 1.7)
	var quadro: Vector2 = size / escala
	for camada: Control in [_espaco, _topo, _rodape]:
		camada.scale = Vector2.ONE * escala
	_topo.size = Vector2(quadro.x, 81.0)
	_rodape.size = Vector2(quadro.x, 59.0)
	_rodape.position.y = size.y - _rodape.size.y * escala
	_espaco.position.y = _topo.size.y * escala
	_espaco.size = Vector2(quadro.x, maxf(200.0, quadro.y - _topo.size.y - _rodape.size.y))
	_data.visible = quadro.x >= 720.0
	_data_compacta.visible = not _data.visible
	var largura: float = minf(_espaco.size.x, _espaco.size.y * 16.0 / 9.0)
	_arte.size = Vector2(largura, largura * 9.0 / 16.0)
	_arte.position = (_espaco.size - _arte.size) * Vector2(0.5, 0.5 if quadro.x >= 850.0 else 0.16)
	for id: String in _botoes:
		var botao: Button = _botoes[id]
		var lado: float = 42.0 if POSICOES.has(id) else 49.0
		if quadro.x < 760.0:
			lado = maxf(30.0, minf(lado, _arte.size.x / 14.0))
		botao.custom_minimum_size = Vector2(lado, lado)
		botao.size = Vector2(lado, lado)
		botao.position = _arte.position + _arte.size * MARCADORES[id] - botao.size * 0.5
		if _legendas.has(id):
			var legenda: Label = _legendas[id]
			legenda.visible = quadro.x >= 850.0
			legenda.position = botao.position + Vector2((lado - legenda.size.x) / 2.0, lado + 4.0)
	_ficha.size = _espaco.size
	_ficha.reposicionar()
	_aviso.position = Vector2(16.0, 14.0)
	_aviso.size = Vector2(minf(quadro.x - 32.0, 490.0), 0.0)


func _atualizar_sede() -> void:
	_resumo = Jogo.resumo_carreira()
	_titulares = Jogo.titulares()
	var dia: Dictionary = _resumo.get("data", {})
	_nome.text = str(_resumo.get("nome", ""))
	_data_compacta.text = str(dia.get("texto", ""))
	_data.text = "%s  ·  %s" % [_data_compacta.text, dia.get("fase_nome", "")]
	_dinheiro.text = "Dinheiro   %s" % _reais(int(_resumo.get("dinheiro", 0)))
	_janela.text = "Transferências abertas" if _janela_aberta() else "Transferências fechadas"
	_janela.add_theme_color_override("font_color", Tema.VERDE if _janela_aberta() else AMBAR)
	for id: String in POSICOES:
		var botao: Button = _botoes[id]
		var titular: Dictionary = Jogo.detalhe_jogador(str(_titulares.get(id, "")))
		botao.tooltip_text = "%s · %s" % [POSICOES[id], titular.get("apelido", "Vaga aberta")]
		var vazio: bool = titular.is_empty()
		botao.add_theme_color_override("icon_normal_color", AMBAR if vazio else Tema.VERDE)
		botao.add_theme_stylebox_override("normal", Tema.caixa(
			Color("#32291e") if vazio else FUNDO, Color("#a88962") if vazio else Tema.BORDA, 5))


func _janela_aberta() -> bool:
	var data_atual: Dictionary = _resumo.get("data", {})
	return bool(data_atual.get("janela_transferencias", false))


func _ligar_sinais() -> void:
	Eventos.dia_avancou.connect(_dia_avancado)
	Eventos.dinheiro_mudou.connect(func(_valor: int) -> void: _atualizar_sede())
	Eventos.elenco_mudou.connect(_atualizar_sede)
	Eventos.contrato_vencendo.connect(_contrato_vencendo)
	Eventos.candidatos_chegaram.connect(func(candidatos: Array[Dictionary]) -> void:
		_avisos_dia.append("Candidatos a técnico: %d" % candidatos.size()))
	Eventos.verba_recebida.connect(func(valor: int) -> void:
		_registrar("Liga", valor))
	Eventos.salarios_pagos.connect(func(valor: int) -> void:
		_registrar("Salários pagos", -valor))
	Eventos.salarios_atrasados.connect(func(valor: int, _meses: int) -> void:
		_avisos_dia.append("Salários em atraso · %s" % _reais(valor)))
	Eventos.parcela_paga.connect(func(valor: int, _restantes: int) -> void:
		_registrar("Parcela do empréstimo", -valor))
	Eventos.parcela_atrasada.connect(func(valor: int, _parcelas: int) -> void:
		_avisos_dia.append("Parcelas em atraso · %s" % _reais(valor)))
	Eventos.falencia.connect(_encerrar)


func _contrato_vencendo(pessoa: Dictionary, tipo: String, restantes: int) -> void:
	var nome: String = str(pessoa.get("nome" if tipo == "tecnico" else "apelido", ""))
	var prazo: String = "em %d dias" % restantes if restantes > 1 else ("amanhã" if restantes == 1 else "hoje")
	_avisos_dia.append("Contrato de %s vence %s." % [nome, prazo])


func _dia_avancado(_dados: Dictionary) -> void:
	_atualizar_sede()
	if _fim:
		return
	if _ficha.visible:
		_montar_ficha()
	if not _avisos_dia.is_empty():
		_mostrar_aviso("\n".join(_avisos_dia))
		_avisos_dia.clear()


func _registrar(descricao: String, valor: int) -> void:
	var dia: Dictionary = Jogo.resumo_carreira().get("data", {})
	_historico.push_front({"descricao": descricao, "valor": valor, "data": str(dia.get("texto", ""))})
	_avisos_dia.append("%s · %s" % [descricao, _reais(absi(valor))])


func _mostrar_aviso(mensagem: String) -> void:
	_aviso.text = mensagem
	_aviso.size.y = 0.0
	_aviso.show()
	_tempo_aviso.start(5.2)


func _input(evento: InputEvent) -> void:
	if not is_instance_valid(_ficha) or not _ficha.visible or _fim:
		return
	if evento.is_action_pressed("ui_cancel"):
		_voltar()
		get_viewport().set_input_as_handled()
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		if _ficha.painel.get_global_rect().has_point(evento.position):
			return
		_ficha.esconder()
		for botao: Button in _botoes.values() + [_dinheiro]:
			if botao.get_global_rect().has_point(evento.position):
				get_viewport().set_input_as_handled()
				return


func _abrir(id: String) -> void:
	if _fim:
		return
	_alvo = "financas" if id == "dinheiro" else id
	_detalhe = "dinheiro" if id == "dinheiro" else ""
	_id_pessoa = ""
	_montar_ficha()
	_ficha.abrir(_dinheiro if id == "dinheiro" else _botoes[id], _animar)
	_ficha.ajustar_altura.call_deferred()


func _navegar(destino: String, pessoa: String = "") -> void:
	_detalhe = destino
	_id_pessoa = pessoa
	_montar_ficha()
	_ficha.seta.grab_focus()


func _voltar() -> void:
	if _fim:
		_ir_menu()
	elif _detalhe.is_empty():
		_ficha.esconder()
		_botoes[_alvo].grab_focus()
	else:
		_navegar("mercado" if _detalhe == "proposta" else "")


func _montar_ficha() -> void:
	match _alvo:
		"calendario": _calendario()
		"financas": _financas()
		"tecnico": _tecnico()
		_: _estacao()
	_ficha.ajustar_altura.call_deferred()


func _calendario() -> void:
	var dia: Dictionary = _resumo.get("data", {})
	var corpo: VBoxContainer = _ficha.atualizar("Quadro da temporada", str(dia.get("texto", "")), false)
	_texto(corpo, str(dia.get("fase_nome", "")), 19, Tema.SUAVE)
	_linha(corpo, "Dia de pagamento", _pagamento(Jogo.resumo_financeiro()))
	_linha(corpo, "Transferências", "Abertas" if _janela_aberta() else "Fechadas")
	_botao(corpo, "Avançar dia", _avancar, true)


func _avancar() -> void:
	_aviso.hide()
	var resultado: Dictionary = Jogo.avancar_dia()
	if not bool(resultado.get("ok", false)):
		_erro(resultado)
	elif not _fim:
		_ficha.corpo.get_child(-1).grab_focus()


func _estacao() -> void:
	var categoria: String = "Estação · %s" % POSICOES[_alvo]
	var jogador: Dictionary = Jogo.detalhe_jogador(str(_titulares.get(_alvo, "")))
	if not jogador.is_empty():
		_ficha_jogador(categoria, jogador, false)
		return
	if not _janela_aberta():
		_texto(_ficha.atualizar(categoria, "Vaga aberta", false), "Transferências fechadas.", 19, Tema.SUAVE)
		return
	if _detalhe == "proposta":
		jogador = Jogo.detalhe_jogador(_id_pessoa)
		if not jogador.is_empty():
			_ficha_jogador(categoria, jogador, true)
			return
		_detalhe = "mercado"
	if _detalhe == "mercado":
		var corpo: VBoxContainer = _ficha.atualizar(categoria, "Agentes livres", true)
		var agentes: Array[Dictionary] = Jogo.listar_mercado({"posicao": _alvo})
		for agente: Dictionary in agentes:
			_botao(corpo, "%s  ·  Nível %d  ·  %s" % [agente["apelido"], agente["nivel_geral"], _reais(int(agente["salario_pedido"]))], _navegar.bind("proposta", agente["id"]))
		if agentes.is_empty():
			_texto(corpo, "Sem agentes livres para esta posição.")
		return
	_botao(_ficha.atualizar(categoria, "Vaga aberta", false), "Ver agentes livres", _navegar.bind("mercado"), true)


func _ficha_jogador(categoria: String, jogador: Dictionary, proposta: bool) -> void:
	var corpo: VBoxContainer = _ficha.atualizar("%s · %d anos" % [categoria, jogador["idade"]], jogador["apelido"], proposta)
	_texto(corpo, "Atributos", 19)
	var atributos: Dictionary = jogador.get("atributos", {})
	var notas: Dictionary = {"Nível": jogador["nivel_geral"]}
	for id: String in ATRIBUTOS:
		notas[ATRIBUTOS[id]] = atributos[id]
	_barras(corpo, notas)
	if proposta:
		_texto(corpo, "Proposta", 19)
		var salario: SpinBox = _salario(corpo, int(jogador["salario_pedido"]))
		var duracao: OptionButton = _duracoes(corpo)
		var titular: CheckButton = CheckButton.new()
		titular.text = "Cláusula de titular"
		corpo.add_child(titular)
		_botao(corpo, "Enviar proposta", func() -> void:
			_contratar_jogador(jogador["id"], int(salario.value), int(duracao.get_selected_id()), titular.button_pressed), true)
		return
	_texto(corpo, "Estado do jogador", 19)
	var estado: Dictionary = {}
	for id: String in ESTADOS:
		estado[ESTADOS[id]] = jogador[id]
	_barras(corpo, estado)
	var contrato: Dictionary = jogador.get("contrato", {})
	if not contrato.is_empty():
		_linha(corpo, "Salário mensal", _reais(int(contrato["salario"])))
		_linha(corpo, "Fim do contrato", "Dia %d" % int(contrato["dia_fim"]))


func _contratar_jogador(id: String, salario: int, meses: int, clausula: bool) -> void:
	var resultado: Dictionary = Jogo.fazer_proposta(id, {"salario": salario, "duracao_meses": meses, "clausula_titular": clausula})
	if not bool(resultado.get("ok", false)):
		_erro(resultado)
		return
	_mostrar_aviso(str(resultado.get("mensagem", "")))
	if bool(resultado.get("aceita", false)):
		var titulares: Dictionary = Jogo.titulares()
		titulares[_alvo] = id
		var escalacao: Dictionary = Jogo.definir_titulares(titulares)
		if not bool(escalacao.get("ok", false)):
			_erro(escalacao)
		_navegar("")


func _tecnico() -> void:
	var categoria: String = "Mesa de reunião"
	var atual: Dictionary = Jogo.tecnico_atual()
	if not atual.is_empty():
		_ficha_tecnico(_ficha.atualizar(categoria, atual["nome"], false), atual)
		return
	var candidatos: Array[Dictionary] = Jogo.listar_candidatos_tecnico()
	if _detalhe == "candidato":
		for candidato: Dictionary in candidatos:
			if candidato["id"] == _id_pessoa:
				var corpo: VBoxContainer = _ficha.atualizar(categoria, candidato["nome"], true)
				_ficha_tecnico(corpo, candidato)
				var duracao: OptionButton = _duracoes(corpo)
				_botao(corpo, "Confirmar contratação", _contratar_tecnico.bind(candidato["id"], duracao), true)
				return
		_detalhe = ""
	if not candidatos.is_empty():
		var lista: VBoxContainer = _ficha.atualizar(categoria, "Candidatos a técnico", false)
		for candidato: Dictionary in candidatos:
			_botao(lista, "%s  ·  %s/mês" % [candidato["nome"], _reais(int(candidato["salario_pedido"]))], _navegar.bind("candidato", candidato["id"]))
		return
	var anuncio: Dictionary = Jogo.estado_anuncio()
	if not anuncio.is_empty():
		_linha(_ficha.atualizar(categoria, "Anúncio em andamento", false), "Chegada dos candidatos", "Em %d dias" % anuncio["dias_restantes"])
		return
	if _detalhe == "anuncio":
		_formulario_anuncio(_ficha.atualizar(categoria, "Anúncio de vaga", true))
		return
	_botao(_ficha.atualizar(categoria, "Vaga de técnico", false), "Publicar anúncio", _navegar.bind("anuncio"), true)


func _ficha_tecnico(corpo: VBoxContainer, pessoa: Dictionary) -> void:
	var atributos: Dictionary = pessoa["atributos"]
	_barras(corpo, {"Nível": pessoa["nivel_geral"], "Macro": atributos["macro"],
		"Conhecimento": atributos["conhecimento"], "Olheiro": atributos["olheiro"], "Cansaço": pessoa["cansaco"]})
	var contrato: Dictionary = pessoa.get("contrato", {})
	_linha(corpo, "Salário mensal", _reais(int(contrato.get("salario", pessoa["salario_pedido"]))))


func _contratar_tecnico(id: String, duracao: OptionButton) -> void:
	var resultado: Dictionary = Jogo.contratar_tecnico(id, duracao.get_selected_id())
	if bool(resultado.get("ok", false)):
		_navegar("")
	else:
		_erro(resultado)


func _formulario_anuncio(corpo: VBoxContainer) -> void:
	var anuncios: Array[Dictionary] = Jogo.listar_anuncios()
	var tamanhos: OptionButton = OptionButton.new()
	for anuncio: Dictionary in anuncios:
		tamanhos.add_item("%s · %s" % [anuncio["nome"], _reais(int(anuncio["custo"]))])
	corpo.add_child(tamanhos)
	var oferta: SpinBox = _salario(corpo, 4000)
	var espera: Label = _texto(corpo, "", 18, Tema.SUAVE)
	var atualizar_espera: Callable = func(_valor: float = 0.0) -> void:
		var id: String = anuncios[tamanhos.selected]["id"]
		espera.text = "Espera prevista · %d dias" % Jogo.prever_espera_anuncio(id, int(oferta.value))
	tamanhos.item_selected.connect(atualizar_espera)
	oferta.value_changed.connect(atualizar_espera)
	atualizar_espera.call()
	_botao(corpo, "Publicar", func() -> void:
		var id: String = anuncios[tamanhos.selected]["id"]
		var resultado: Dictionary = Jogo.publicar_anuncio(id, int(oferta.value))
		if bool(resultado.get("ok", false)):
			_navegar("")
		else:
			_erro(resultado), true)


func _financas() -> void:
	var resumo: Dictionary = Jogo.resumo_financeiro()
	var renda: int = int(resumo["verba_mensal"])
	var gastos: int = int(resumo["folha_mensal"]) + int(resumo["parcela_emprestimo"])
	gastos += int(resumo["salarios_atrasados"])
	var emprestimo: Dictionary = Jogo.estado_emprestimo()
	if not emprestimo.is_empty():
		gastos += int(emprestimo.get("divida_atrasada", 0))
	var rotulos: Dictionary = {"dinheiro": "Dinheiro", "renda": "Renda mensal", "gastos": "Gastos"}
	var valores: Dictionary = {"dinheiro": resumo["dinheiro"], "renda": renda, "gastos": gastos}
	if _detalhe.is_empty():
		var inicio: VBoxContainer = _ficha.atualizar("Mesa da gestão", "Livro de contas", false)
		for id: String in rotulos:
			var botao: Button = _botao(inicio, "%s   ·   %s" % [rotulos[id], _reais(int(valores[id]))], _navegar.bind(id))
			botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
			if id == "gastos":
				botao.add_theme_color_override("font_color", VERMELHO)
		_linha(inicio, "Dia de pagamento", _pagamento(resumo))
		return
	var corpo: VBoxContainer = _ficha.atualizar("Livro de contas", rotulos[_detalhe], true)
	_texto(corpo, _reais(int(valores[_detalhe])), 31, VERMELHO if _detalhe == "gastos" else Tema.VERDE)
	if _detalhe == "renda":
		_linha(corpo, "Liga", _reais(renda))
	elif _detalhe == "gastos":
		for jogador: Dictionary in Jogo.listar_elenco():
			var contrato: Dictionary = jogador["contrato"]
			_linha(corpo, jogador["apelido"], _reais(int(contrato.get("salario", 0))))
		var tecnico: Dictionary = Jogo.tecnico_atual()
		if not tecnico.is_empty():
			var contrato: Dictionary = tecnico["contrato"]
			_linha(corpo, tecnico["nome"], _reais(int(contrato.get("salario", 0))))
		for extra: String in ["parcela_emprestimo", "salarios_atrasados", "divida_atrasada"]:
			var valor: int = int(resumo.get(extra, emprestimo.get(extra, 0)))
			if valor > 0:
				_linha(corpo, {"parcela_emprestimo": "Parcela do empréstimo", "salarios_atrasados": "Salários em atraso", "divida_atrasada": "Parcelas em atraso"}[extra], _reais(valor))
	if _detalhe != "dinheiro":
		_linha(corpo, "Dia de pagamento", _pagamento(resumo))
	var titulos: Dictionary = {"dinheiro": "Movimentações da sessão", "renda": "Recebido na sessão", "gastos": "Pago na sessão"}
	_texto(corpo, str(titulos[_detalhe]), 19)
	var tem_registro: bool = false
	for registro: Dictionary in _historico:
		var valor: int = registro["valor"]
		if (_detalhe == "renda" and valor < 0) or (_detalhe == "gastos" and valor > 0):
			continue
		tem_registro = true
		_linha(corpo, "%s · %s" % [registro["descricao"], registro["data"]], _reais(valor))
	if not tem_registro:
		_texto(corpo, "Nenhum lançamento.", 17, Tema.SUAVE)


func _pagamento(resumo: Dictionary) -> String:
	var dias: int = int(resumo["dias_ate_pagamento"])
	return "Dia 1 · amanhã" if dias == 1 else "Dia 1 · em %d dias" % dias


func _encerrar(_dados: Dictionary) -> void:
	_fim = true
	var corpo: VBoxContainer = _ficha.atualizar(_nome.text, "Fim da carreira", false)
	_texto(corpo, "A organização entrou em falência.", 20, Tema.SUAVE)
	_botao(corpo, "Voltar ao menu", _ir_menu, true)
	_ficha.abrir(_dinheiro, false)
	_ficha.ajustar_altura.call_deferred()
	_ficha.seta.grab_focus()


func _salvar() -> void:
	var resultado: Dictionary = Jogo.salvar()
	if bool(resultado.get("ok", false)):
		_mostrar_aviso("Carreira salva.")
	else:
		_erro(resultado)


func _pedir_saida() -> void:
	var dialogo: ConfirmationDialog = ConfirmationDialog.new()
	dialogo.title = "Voltar ao menu"
	dialogo.dialog_text = "O progresso desde o último save será perdido."
	dialogo.get_ok_button().text = "Sair sem salvar"
	dialogo.get_cancel_button().text = "Cancelar"
	dialogo.add_button("Salvar e sair", true, "salvar")
	dialogo.custom_action.connect(func(_acao: StringName) -> void:
		var resultado: Dictionary = Jogo.salvar()
		if bool(resultado.get("ok", false)):
			_ir_menu()
		else:
			dialogo.queue_free()
			_erro(resultado))
	dialogo.confirmed.connect(_ir_menu)
	dialogo.canceled.connect(dialogo.queue_free)
	add_child(dialogo)
	dialogo.popup_centered()
	dialogo.get_cancel_button().grab_focus()


func _ir_menu() -> void:
	get_tree().change_scene_to_file.call_deferred(MENU)


func _erro(resultado: Dictionary) -> void:
	var mensagens: PackedStringArray = []
	var erros: Dictionary = resultado.get("erros", {})
	for mensagem: Variant in erros.values():
		mensagens.append(str(mensagem))
	if not mensagens.is_empty():
		_mostrar_aviso("\n".join(mensagens))


func _salario(pai: VBoxContainer, valor: int) -> SpinBox:
	_texto(pai, "Salário mensal", 17, Tema.SUAVE)
	var salario: SpinBox = SpinBox.new()
	salario.max_value = 9999999
	salario.step = 1
	salario.prefix = "R$"
	salario.value = valor
	salario.get_line_edit().accessibility_name = "Salário mensal"
	pai.add_child(salario)
	return salario


func _duracoes(pai: VBoxContainer) -> OptionButton:
	var seletor: OptionButton = OptionButton.new()
	for meses: Variant in Jogo.opcoes_contrato()["duracoes_meses"]:
		seletor.add_item("%d meses" % int(meses), int(meses))
	pai.add_child(seletor)
	return seletor


func _barras(pai: VBoxContainer, valores: Dictionary) -> void:
	var grade: GridContainer = GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 13)
	grade.add_theme_constant_override("v_separation", 7)
	pai.add_child(grade)
	for rotulo: String in valores:
		var coluna: VBoxContainer = VBoxContainer.new()
		coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grade.add_child(coluna)
		var valor: int = clampi(int(valores[rotulo]), 0, 100)
		_linha(coluna, rotulo, "%d / 100" % valor, 15)
		var barra: ProgressBar = ProgressBar.new()
		barra.custom_minimum_size.y = 6
		barra.show_percentage = false
		barra.accessibility_name = rotulo
		var trilho: StyleBoxFlat = Tema.caixa(Color("#294036"), Color("#294036"), 0)
		trilho.set_border_width_all(0)
		var preenchimento: StyleBoxFlat = trilho.duplicate()
		preenchimento.bg_color = Tema.VERDE
		barra.add_theme_stylebox_override("background", trilho)
		barra.add_theme_stylebox_override("fill", preenchimento)
		coluna.add_child(barra)
		if _animar:
			create_tween().bind_node(barra).tween_property(barra, "value", valor, 0.25).set_trans(Tween.TRANS_QUAD)
		else:
			barra.value = valor


func _linha(pai: Container, rotulo: String, valor: String, tamanho: int = 17) -> void:
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", 7)
	pai.add_child(linha)
	var campo: Label = _texto(linha, rotulo, tamanho, Tema.SUAVE)
	campo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto(linha, valor, tamanho)


func _botao(pai: Control, texto: String, acao: Callable, principal: bool = false) -> Button:
	var botao: Button = Button.new()
	botao.text = texto
	botao.custom_minimum_size.y = 42
	botao.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if principal:
		botao.theme_type_variation = "AcaoPrincipal"
	botao.pressed.connect(acao)
	pai.add_child(botao)
	return botao


func _texto(pai: Control, texto: String, tamanho: int = 19, cor: Color = Tema.TEXTO) -> Label:
	var rotulo: Label = Label.new()
	rotulo.text = texto
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", cor)
	pai.add_child(rotulo)
	return rotulo


static func _reais(valor: int) -> String:
	var digitos: String = str(absi(valor))
	var agrupado: String = ""
	for i: int in range(digitos.length()):
		if i > 0 and (digitos.length() - i) % 3 == 0:
			agrupado += "."
		agrupado += digitos[i]
	return ("−" if valor < 0 else "") + "R$ " + agrupado
