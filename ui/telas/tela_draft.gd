extends Control

const Tema = preload("res://ui/temas/tema_draft.gd")
const Cartao = preload("res://ui/componentes/cartao_campeao_draft.gd")
const Lado = preload("res://ui/componentes/lado_draft.gd")
const Texturas = preload("res://ui/componentes/texturas_webp.gd")
const Bandeiras = preload("res://ui/componentes/bandeira_da_carreira.gd")
const PARTIDA: String = "res://ui/partida/tela_partida.tscn"
const SEDE: String = "res://ui/telas/sede_carreira.tscn"
const POSICOES: Dictionary = {
	"topo": "Topo", "selva": "Selva", "meio": "Meio", "atirador": "Atirador", "suporte": "Suporte",
}
const LADOS: Array[String] = ["azul", "vermelho"]
const AJUDA_AUTO: String = "Marque uma rota livre para o titular escolher com o apoio do técnico. Sem rota marcada ou num banimento, a decisão é da equipe. A escolha pode ser diferente da sua."

var _base: Control
var _pagina: VBoxContainer
var _titulo: Label
var _proxima_acao: Label
var _sequencia: HBoxContainer
var _ajuda_auto: Button
var _aviso: Label
var _auto: Button
var _busca: LineEdit
var _grade: GridContainer
var _painel_catalogo: PanelContainer
var _contexto_rota: Label
var _botoes_filtro: Dictionary = {}
var _cartoes: Dictionary = {}
var _lados: Dictionary = {}
var _catalogo: Dictionary = {}
var _campeoes_draft: Dictionary = {}
var _estado: Dictionary
var _quadro: Control
var _formacao: VBoxContainer
var _cartas_formacao: Dictionary = {}
var _tabuleiro: BoxContainer
var _rolagem: ScrollContainer
var _ficha: PanelContainer
var _ficha_corpo: VBoxContainer
var _ficha_rolagem: ScrollContainer
var _ficha_titulo: Label
var _botao_ficha: Button
var _linha: Line2D
var _confirmacao: ConfirmationDialog
var _bandeira: Texture2D
var _consulta: String = ""
var _filtro: String = ""
var _inspecionado: String = ""
var _origem: Control
var _troca: String = ""
var _compacto: bool
var _ocupado: bool
var _saindo: bool
var _animar: bool = true


func _ready() -> void:
	_estado = Jogo.estado_draft()
	if _estado.is_empty():
		_voltar()
		return
	theme = Tema.criar()
	var original: Font = get_theme_font("font", "Label")
	if original is FontFile:
		var fonte: FontFile = original.duplicate()
		fonte.multichannel_signed_distance_field = true
		theme.default_font = fonte
	var config: ConfigFile = ConfigFile.new()
	if config.load("user://preferencias_apresentacao.cfg") == OK:
		_animar = bool(config.get_value("abertura", "animacao", true))
	for campeao: Dictionary in Jogo.listar_campeoes():
		_catalogo[campeao["id"]] = campeao
	var imagem: Image = Bandeiras.decodificar(str(Jogo.resumo_carreira().get("bandeira_png", "")))
	if imagem != null:
		_bandeira = ImageTexture.create_from_image(imagem)
	_montar()
	resized.connect(_dimensionar)
	Eventos.draft_mudou.connect(_receber_estado)
	_dimensionar()


func _montar() -> void:
	var fundo: TextureRect = TextureRect.new()
	fundo.texture = Texturas.carregar("res://assets/sprites/sede/aurora.webp")
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sombra: ColorRect = ColorRect.new()
	sombra.color = Color("#0b1428e5")
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sombra)
	sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_base = Control.new()
	_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_base)
	var margens: MarginContainer = MarginContainer.new()
	for margem: String in ["left", "right", "top", "bottom"]:
		margens.add_theme_constant_override("margin_" + margem, 12)
	_base.add_child(margens)
	margens.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pagina = VBoxContainer.new()
	_pagina.add_theme_constant_override("separation", 10)
	margens.add_child(_pagina)

	var topo: HBoxContainer = HBoxContainer.new()
	_pagina.add_child(topo)
	var voltar: Button = Tema.botao("←", _voltar)
	voltar.accessibility_name = "Voltar à sede"
	voltar.tooltip_text = voltar.accessibility_name
	topo.add_child(voltar)
	var marca: Label = Tema.texto("MOBA MANAGER  ·  Draft de treino", 15, Tema.CIANO)
	marca.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marca.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	topo.add_child(marca)
	topo.add_child(Tema.botao("Reiniciar", _pedir_reinicio))

	var acoes: HBoxContainer = HBoxContainer.new()
	_pagina.add_child(acoes)
	var fase: VBoxContainer = VBoxContainer.new()
	fase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	acoes.add_child(fase)
	fase.add_child(Tema.texto("CRYSTAL LEGENDS", 13, Tema.CIANO))
	_titulo = Tema.texto("", 33)
	_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fase.add_child(_titulo)
	_sequencia = HBoxContainer.new()
	fase.add_child(_sequencia)
	_proxima_acao = Tema.texto("", 14, Tema.SUAVE)
	_proxima_acao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_proxima_acao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sequencia.add_child(_proxima_acao)
	var ordem: Button = Tema.botao("Ordem do draft", _mostrar_ordem)
	ordem.custom_minimum_size.y = 29.0
	ordem.add_theme_font_size_override("font_size", 14)
	_sequencia.add_child(ordem)
	_auto = Tema.botao("Automático", _delegar)
	_auto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	acoes.add_child(_auto)
	_ajuda_auto = Tema.botao("?", _mostrar_ajuda)
	_ajuda_auto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_ajuda_auto.accessibility_name = "Como funciona o Automático?"
	_ajuda_auto.tooltip_text = AJUDA_AUTO
	acoes.add_child(_ajuda_auto)
	_aviso = Tema.texto("", 15, Tema.CORAL)
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pagina.add_child(_aviso)
	_aviso.hide()

	_rolagem = ScrollContainer.new()
	_rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rolagem.follow_focus = true
	_pagina.add_child(_rolagem)
	_rolagem.get_v_scroll_bar().value_changed.connect(func(_valor: float) -> void: _posicionar_ficha())
	var area: VBoxContainer = VBoxContainer.new()
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rolagem.add_child(area)
	_quadro = area
	_montar_ficha()


func _dimensionar() -> void:
	if _base == null:
		return
	var retrato: bool = size.x < size.y
	var escala: float = maxf(0.1, size.x / 405.0) if retrato else clampf(size.x / 1430.0, 0.65, 1.65)
	_base.scale = Vector2.ONE * escala
	_base.size = size / escala
	var compacto: bool = retrato or _base.size.x < 910.0
	_titulo.add_theme_font_size_override("font_size", 23 if compacto else 34)
	if _tabuleiro == null or compacto != _compacto:
		_compacto = compacto
		_fechar_ficha()
		_montar_tabuleiro()
		_atualizar_tela()
	_posicionar_ficha()


func _montar_tabuleiro() -> void:
	if _tabuleiro != null:
		_quadro.remove_child(_tabuleiro)
		_tabuleiro.queue_free()
	if _formacao != null:
		_quadro.remove_child(_formacao)
		_formacao.queue_free()
	_cartoes.clear()
	_lados.clear()
	_tabuleiro = VBoxContainer.new() if _compacto else HBoxContainer.new()
	_tabuleiro.add_theme_constant_override("separation", 8)
	_quadro.add_child(_tabuleiro)
	var resumo: HBoxContainer
	if _compacto:
		resumo = HBoxContainer.new()
		_tabuleiro.add_child(resumo)
	var meu_lado: String = str(_estado["lado_jogador"])
	for lado: String in LADOS:
		if lado == "vermelho" and not _compacto:
			_montar_catalogo()
		var equipe: Control = Lado.new()
		_lados[lado] = equipe
		var pai: BoxContainer = resumo if _compacto else _tabuleiro
		pai.add_child(equipe)
		equipe.montar(lado, _compacto, lado == meu_lado, _catalogo, _bandeira if lado == meu_lado else null)
		equipe.inspecionar.connect(_inspecionar.bind(lado))
		equipe.filtrar_rota.connect(_alternar_rota)
	if _compacto:
		_montar_catalogo()
	_formacao = VBoxContainer.new()
	_formacao.add_theme_constant_override("separation", 13)
	_quadro.add_child(_formacao)


func _montar_catalogo() -> void:
	_painel_catalogo = PanelContainer.new()
	_painel_catalogo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_painel_catalogo.add_theme_stylebox_override("panel", Tema.caixa(Tema.PAINEL, Tema.BORDA, 10))
	_tabuleiro.add_child(_painel_catalogo)
	var corpo: VBoxContainer = VBoxContainer.new()
	corpo.add_theme_constant_override("separation", 9)
	_painel_catalogo.add_child(corpo)
	var cabecalho: HBoxContainer = HBoxContainer.new()
	corpo.add_child(cabecalho)
	var titulo: Label = Tema.texto("Campeões", 22)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecalho.add_child(titulo)
	_busca = LineEdit.new()
	_busca.placeholder_text = "Buscar"
	_busca.accessibility_name = "Buscar campeão"
	_busca.custom_minimum_size.x = 110.0 if _compacto else 175.0
	_busca.text = _consulta
	_busca.text_changed.connect(_buscar)
	cabecalho.add_child(_busca)
	var filtros: HFlowContainer = HFlowContainer.new()
	corpo.add_child(filtros)
	_botoes_filtro.clear()
	var nomes_filtros: Dictionary = {"": "Todas"}
	nomes_filtros.merge(POSICOES)
	for posicao: String in nomes_filtros:
		var botao: Button = Tema.botao(nomes_filtros[posicao], _filtrar.bind(posicao))
		botao.toggle_mode = true
		botao.custom_minimum_size.y = 30.0
		botao.add_theme_font_size_override("font_size", 14)
		filtros.add_child(botao)
		_botoes_filtro[posicao] = botao
	_contexto_rota = Tema.texto("", 14, Tema.CIANO)
	corpo.add_child(_contexto_rota)
	_grade = GridContainer.new()
	_grade.columns = 4 if _compacto else 6
	_grade.add_theme_constant_override("h_separation", 6)
	_grade.add_theme_constant_override("v_separation", 6)
	corpo.add_child(_grade)
	for id: String in _catalogo:
		var cartao: Button = Cartao.new()
		cartao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cartao.pressed.connect(_inspecionar.bind(id, ""))
		_grade.add_child(cartao)
		cartao.definir_compacto(_compacto)
		_cartoes[id] = cartao
	_filtrar_catalogo()


func _buscar(texto: String) -> void:
	_consulta = texto
	_filtrar_catalogo()


func _alternar_rota(posicao: String) -> void:
	_filtrar("" if _filtro == posicao else posicao)


func _filtrar(posicao: String) -> void:
	_filtro = posicao
	_aviso.hide()
	_filtrar_catalogo()
	_atualizar_cartoes()
	if _ficha.visible and is_instance_valid(_origem):
		var lado: String = ""
		for candidato: String in LADOS:
			if _lados[candidato].is_ancestor_of(_origem):
				lado = candidato
				break
		_inspecionar(_inspecionado, lado)


func _filtrar_catalogo() -> void:
	var lado: String = str(_estado["lado_jogador"])
	for posicao: String in _botoes_filtro:
		_botoes_filtro[posicao].set_pressed_no_signal(posicao == _filtro)
	if _lados.has(lado):
		_lados[lado].destacar_rota(_filtro)
	_contexto_rota.visible = not _filtro.is_empty()
	if _contexto_rota.visible:
		var titular: Dictionary = _estado["times"][lado]["jogadores"].get(_filtro, {})
		_contexto_rota.text = "Conhecimento de %s · %s" % [titular.get("apelido", ""), POSICOES[_filtro]]
	var consulta: String = _sem_acentos(_consulta.strip_edges())
	for id: String in _cartoes:
		var item: Dictionary = _catalogo[id]
		var na_rota: bool = _filtro.is_empty() or item.get("posicoes", []).has(_filtro)
		var no_nome: bool = consulta.is_empty() or _sem_acentos(str(item["nome"])).contains(consulta)
		_cartoes[id].visible = na_rota and no_nome
	if is_instance_valid(_origem) and not _origem.is_visible_in_tree():
		_fechar_ficha()


static func _sem_acentos(texto: String) -> String:
	var resultado: String = texto.to_lower()
	var acentos: String = "áàãâäéêèëíîìïóôõòöúûùüç"
	var simples: String = "aaaaaeeeeiiiiooooouuuuc"
	for i: int in range(acentos.length()):
		resultado = resultado.replace(acentos[i], simples[i])
	return resultado


func _receber_estado(estado: Dictionary) -> void:
	if _ocupado or _saindo:
		return
	_estado = estado
	_atualizar_tela()


func _atualizar_tela(animar_cartoes: bool = false, manter_grade: bool = false) -> void:
	var vez: Dictionary = _estado.get("vez", {})
	var terminou: bool = bool(_estado.get("concluido", false))
	if terminou:
		_titulo.text = "Draft concluído"
	elif not bool(vez.get("do_jogador", false)):
		_titulo.text = "Vez do rival"
	else:
		_titulo.text = "Sua vez de banir" if vez.get("acao") == "ban" else "Sua vez de escolher"
	_auto.visible = not terminou
	_ajuda_auto.visible = not terminou
	_sequencia.visible = not terminou
	_auto.disabled = _ocupado or not bool(vez.get("do_jogador", false))
	_formacao.visible = terminou and not manter_grade
	_tabuleiro.visible = not _formacao.visible
	_campeoes_draft.clear()
	for ficha: Dictionary in _estado.get("campeoes", []):
		var id: String = str(ficha["id"])
		if not bool(_estado.get("favoritos_do_rival_revelados", false)):
			ficha = ficha.duplicate()
			ficha.erase("favorito_do_rival")
		_campeoes_draft[id] = ficha
	if _formacao.visible:
		_montar_formacao()
		return
	_atualizar_proxima_acao(vez)
	for lado: String in LADOS:
		var contagem: Dictionary = {"pick": 0, "ban": 0}
		for passo: Dictionary in _estado.get("passos", []):
			if passo.get("time") == lado:
				contagem[passo["acao"]] += 1
		_lados[lado].atualizar(_estado["times"][lado], vez, contagem["pick"], contagem["ban"], _filtro)
	_atualizar_cartoes(animar_cartoes)


func _atualizar_cartoes(animar_cartoes: bool = false) -> void:
	for id: String in _cartoes:
		_cartoes[id].configurar(_catalogo[id], _campeoes_draft.get(id, {}), id == _inspecionado, _filtro,
			animar_cartoes and _animar and _cartao_em_tela(id))


func _cartao_em_tela(id: String) -> bool:
	var cartao: Control = _cartoes.get(id)
	return is_instance_valid(cartao) and cartao.is_visible_in_tree() and cartao.get_global_rect().intersects(_rolagem.get_global_rect())


func _atualizar_proxima_acao(vez: Dictionary) -> void:
	var passos: Array = _estado.get("passos", [])
	var indice: int = int(vez.get("numero", passos.size()))
	if indice >= passos.size():
		_proxima_acao.text = "Depois · Formações"
		return
	var proximo: Dictionary = passos[indice]
	var quantidade: int = 1
	for i: int in range(indice + 1, passos.size()):
		if passos[i]["time"] != proximo["time"] or passos[i]["acao"] != proximo["acao"]:
			break
		quantidade += 1
	var equipe: String = "Sua equipe" if proximo["time"] == _estado["lado_jogador"] else "Rival"
	var acao: String = "bane" if proximo["acao"] == "ban" else "escolhe"
	_proxima_acao.text = "Depois · %s %s%s" % [equipe, acao, " %d" % quantidade if quantidade > 1 else ""]


func _mostrar_ordem() -> void:
	var janela: AcceptDialog = AcceptDialog.new()
	janela.title = "Ordem do draft"
	janela.ok_button_text = "Fechar"
	janela.confirmed.connect(janela.queue_free)
	janela.canceled.connect(janela.queue_free)
	add_child(janela)
	var lista: ScrollContainer = ScrollContainer.new()
	lista.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	janela.add_child(lista)
	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_child(coluna)
	var passos: Array = _estado.get("passos", [])
	var atual: int = int(_estado.get("vez", {}).get("numero", -1))
	var ultimos: String = ""
	for i: int in range(passos.size()):
		var passo: Dictionary = passos[i]
		var escolha: bool = passo["acao"] == "pick"
		if passo["acao"] != ultimos:
			coluna.add_child(Tema.texto("Escolhas" if escolha else "Banimentos", 16))
			ultimos = passo["acao"]
		var nome: String = str(_catalogo.get(passo.get("campeao", ""), {}).get("nome", "Escolhe" if escolha else "Bane"))
		var equipe: String = "Sua equipe" if passo["time"] == _estado["lado_jogador"] else "Rival"
		var linha: Label = Tema.texto("%02d   %s · %s%s" % [i + 1, equipe, nome, " · Agora" if i + 1 == atual else ""],
			14, Tema.cor_lado(passo["time"]))
		coluna.add_child(linha)
	var limite: Vector2 = get_viewport_rect().size
	janela.popup_centered(Vector2i(minf(450.0, limite.x - 28.0), minf(610.0, limite.y - 28.0)))


func _montar_ficha() -> void:
	_linha = Line2D.new()
	_linha.width = 2.0
	_linha.antialiased = true
	_linha.default_color = Tema.CIANO
	_base.add_child(_linha)
	_ficha = PanelContainer.new()
	_ficha.add_theme_stylebox_override("panel", Tema.caixa(Tema.PAINEL, Tema.CIANO, 10))
	_base.add_child(_ficha)
	var coluna: VBoxContainer = VBoxContainer.new()
	_ficha.add_child(coluna)
	var topo: HBoxContainer = HBoxContainer.new()
	coluna.add_child(topo)
	var fechar: Button = Tema.botao("←", _fechar_ficha.bind(true))
	fechar.accessibility_name = "Fechar ficha"
	topo.add_child(fechar)
	_ficha_titulo = Tema.texto("", 26)
	_ficha_titulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_ficha_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(_ficha_titulo)
	_ficha_rolagem = ScrollContainer.new()
	_ficha_rolagem.follow_focus = true
	_ficha_rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	coluna.add_child(_ficha_rolagem)
	_ficha_corpo = VBoxContainer.new()
	_ficha_corpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ficha_corpo.add_theme_constant_override("separation", 5)
	_ficha_rolagem.add_child(_ficha_corpo)
	_botao_ficha = Tema.botao("", _acao_manual, true)
	coluna.add_child(_botao_ficha)
	_ficha.hide()


func _inspecionar(id: String, lado: String) -> void:
	if _ocupado or _saindo or not _campeoes_draft.has(id):
		return
	_inspecionado = id
	_origem = _cartoes[id] if lado.is_empty() else _lados[lado].destino(id)
	_atualizar_cartoes()
	_apagar_filhos(_ficha_corpo)
	var ficha: Dictionary = _campeoes_draft[id]
	var campeao: Dictionary = _catalogo[id]
	_ficha_titulo.text = str(campeao["nome"])
	var detalhe: Label = Tema.texto(str(campeao.get("titulo", "")), 16, Tema.SUAVE)
	detalhe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ficha_corpo.add_child(detalhe)
	var posicoes: String = " / ".join(PackedStringArray(campeao.get("posicoes_nomes", [])))
	var resumo: Label = Tema.texto("%s  ·  %s  ·  %s" % [campeao.get("classe_nome", ""),
		posicoes, campeao.get("curva_nome", "")], 15, Tema.CIANO)
	resumo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ficha_corpo.add_child(resumo)
	_ficha_corpo.add_child(HSeparator.new())
	_ficha_corpo.add_child(Tema.texto("Conhecimento do campeão", 17))
	_barras_conhecimento(ficha.get("dominio", {}), campeao.get("posicoes", []))
	_principais_do_rival(ficha.get("favorito_do_rival", []))
	var situacao: String = str(ficha.get("estado", ""))
	var vez: Dictionary = _estado.get("vez", {})
	var pode_confirmar: bool = situacao == "livre" and bool(vez.get("do_jogador", false))
	_botao_ficha.visible = pode_confirmar
	if pode_confirmar:
		_botao_ficha.text = "%s %s" % ["Banir" if vez.get("acao") == "ban" else "Escolher", campeao["nome"]]
	elif situacao in ["banido", "escolhido", "indisponivel"]:
		var estado_rotulo: String = "Indisponível nesta partida" if situacao == "indisponivel" else situacao.capitalize()
		var lado_uso: String = str(ficha.get("por", ""))
		_ficha_corpo.add_child(Tema.texto("%s%s" % [estado_rotulo, " · " +
			str(_estado["times"][lado_uso]["nome"]) if lado_uso in LADOS else ""], 15, Tema.CORAL))
	_ficha_rolagem.scroll_vertical = 0
	_ficha.show()
	_posicionar_ficha()
	_posicionar_ficha.call_deferred()


func _barras_conhecimento(dominio: Dictionary, posicoes_campeao: Array) -> void:
	var lado: String = str(_estado["lado_jogador"])
	var titulares: Dictionary = _estado["times"][lado]["jogadores"]
	for posicao: String in POSICOES:
		var linha: HBoxContainer = HBoxContainer.new()
		_ficha_corpo.add_child(linha)
		var nome: String = "%s · %s" % [titulares.get(posicao, {}).get("apelido", ""), POSICOES[posicao]]
		var rotulo: Label = Tema.texto(nome, 15)
		rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rotulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		linha.add_child(rotulo)
		var perfil: Dictionary = dominio.get(posicao, {})
		var publicado: Variant = perfil.get("conhecimento")
		var disponivel: bool = (publicado is int or publicado is float) and float(publicado) >= 0.0 and float(publicado) <= 100.0
		var pontos: int = roundi(float(publicado)) if disponivel else 0
		var valor: String = "%d · %s" % [pontos, perfil.get("nivel_nome", "")] if disponivel else "—"
		linha.add_child(Tema.texto(valor, 15, _cor_conhecimento(pontos)))
		var barra: ProgressBar = ProgressBar.new()
		barra.max_value = 100
		barra.value = pontos
		barra.show_percentage = false
		barra.custom_minimum_size.y = 5
		barra.add_theme_stylebox_override("background", Tema.caixa(Color("#283b5a"), Color.TRANSPARENT, 0))
		barra.add_theme_stylebox_override("fill", Tema.caixa(_cor_conhecimento(pontos), Color.TRANSPARENT, 0))
		barra.accessibility_name = "%s · %s" % [nome, valor if disponivel else "Conhecimento indisponível"]
		_ficha_corpo.add_child(barra)
		if not posicoes_campeao.has(posicao):
			_ficha_corpo.add_child(Tema.texto("Fora da rota", 12, Tema.CORAL))


func _cor_conhecimento(pontos: int) -> Color:
	if pontos >= 95:
		return Tema.DOURADO
	if pontos >= 80:
		return Tema.CIANO
	return Color("#75ade7") if pontos > 40 else Color("#7488aa")


func _principais_do_rival(posicoes: Array) -> void:
	if posicoes.is_empty():
		return
	var adversario: String = "vermelho" if _estado["lado_jogador"] == "azul" else "azul"
	var titulares: Dictionary = _estado["times"][adversario]["jogadores"]
	var nomes: PackedStringArray = []
	for posicao: String in posicoes:
		nomes.append("%s · %s" % [titulares.get(posicao, {}).get("apelido", ""), POSICOES.get(posicao, "")])
	var texto: Label = Tema.texto("◆ Campeão principal do rival\n%s" % ", ".join(nomes), 15, Tema.CORAL)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ficha_corpo.add_child(texto)


func _posicionar_ficha() -> void:
	if not is_instance_valid(_ficha) or not _ficha.visible or not is_instance_valid(_origem):
		return
	var quadro: Vector2 = _base.size
	var inversa: Transform2D = _base.get_global_transform_with_canvas().affine_inverse()
	var catalogo: Rect2 = inversa * _painel_catalogo.get_global_rect()
	var carta: Rect2 = inversa * _origem.get_global_rect()
	var largura: float = minf(386.0, quadro.x - 24.0) if _compacto else minf(338.0, catalogo.size.x * 0.68)
	var esquerda: bool = carta.get_center().x > catalogo.get_center().x
	var altura: float = minf(500.0, quadro.y * (0.59 if _compacto else 0.72))
	var x: float = (quadro.x - largura) * 0.5 if _compacto else (catalogo.position.x + 8.0 if esquerda else catalogo.end.x - largura - 8.0)
	var y: float = maxf(12.0, quadro.y - altura - 12.0)
	if not _compacto:
		y = minf(y, maxf(112.0, catalogo.position.y + 76.0))
	_ficha_rolagem.custom_minimum_size.y = maxf(30.0, minf(_ficha_corpo.get_combined_minimum_size().y + 2.0, altura - 103.0))
	_ficha.position = Vector2(x, y)
	_ficha.size = Vector2(largura, 0)
	_linha.clear_points()
	if _compacto or not _grade.is_ancestor_of(_origem):
		return
	var inicio: Vector2 = Vector2(carta.position.x if esquerda else carta.end.x, carta.get_center().y)
	var destino: Vector2 = Vector2(x + largura if esquerda else x, clampf(inicio.y + 9.0, y + 10.0, y + maxf(10.0, _ficha.size.y - 10.0)))
	var distancia: float = inicio.x - destino.x if esquerda else destino.x - inicio.x
	if distancia >= 3.0 and distancia <= 28.0 and absf(inicio.y - destino.y) <= 25.0:
		_linha.points = PackedVector2Array([inicio, Vector2(lerpf(inicio.x, destino.x, 0.5), inicio.y), destino])


func _fechar_ficha(restaurar: bool = false) -> void:
	if not is_instance_valid(_ficha):
		return
	_ficha.hide()
	_linha.clear_points()
	_inspecionado = ""
	if restaurar and is_instance_valid(_origem) and _origem.is_visible_in_tree():
		_origem.grab_focus()
	_origem = null


func _input(evento: InputEvent) -> void:
	if not is_instance_valid(_ficha) or not _ficha.visible:
		return
	if evento.is_action_pressed("ui_cancel"):
		_fechar_ficha(true)
		get_viewport().set_input_as_handled()
	elif evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		if not _ficha.get_global_rect().has_point(evento.position):
			_fechar_ficha()


func _montar_formacao() -> void:
	_cartas_formacao.clear()
	_apagar_filhos(_formacao)
	var meu_lado: String = str(_estado["lado_jogador"])
	for lado: String in LADOS:
		var time: Dictionary = _estado["times"][lado]
		var painel: PanelContainer = PanelContainer.new()
		painel.add_theme_stylebox_override("panel", Tema.caixa(Tema.PAINEL, Tema.BORDA, 14))
		_formacao.add_child(painel)
		var corpo: VBoxContainer = VBoxContainer.new()
		painel.add_child(corpo)
		corpo.add_child(Tema.texto(str(time["nome"]), 22, Tema.cor_lado(lado)))
		var grade: GridContainer = GridContainer.new()
		grade.columns = 2 if _compacto else 5
		corpo.add_child(grade)
		for posicao: String in POSICOES:
			var titular: Dictionary = time["jogadores"][posicao]
			var id: String = str(time["posicoes"][posicao])
			var texto: String = "%s · %s\n%s" % [POSICOES[posicao], titular["apelido"], _catalogo[id]["nome"]]
			if lado == meu_lado:
				var perfil: Dictionary = _campeoes_draft.get(id, {}).get("dominio", {}).get(posicao, {})
				if perfil.has("conhecimento"):
					texto += "\n%s %d" % [perfil.get("nivel_nome", ""), perfil["conhecimento"]]
				if not _catalogo[id].get("posicoes", []).has(posicao):
					texto += " · Fora da rota"
				var botao: Button = Tema.botao(texto, _trocar.bind(posicao), posicao == _troca)
				botao.custom_minimum_size.y = 78
				botao.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				grade.add_child(botao)
				_cartas_formacao[posicao] = botao
			else:
				var rotulo: Label = Tema.texto(texto, 16)
				rotulo.custom_minimum_size.y = 71
				rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				rotulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				grade.add_child(rotulo)
	var dica: Label = Tema.texto("Clique em duas posições da sua equipe para trocar os campeões.", 15, Tema.SUAVE)
	dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_formacao.add_child(dica)
	var acoes: HFlowContainer = HFlowContainer.new()
	acoes.alignment = FlowContainer.ALIGNMENT_END
	acoes.add_theme_constant_override("h_separation", 10)
	_formacao.add_child(acoes)
	acoes.add_child(Tema.botao("Voltar à sede", _voltar))
	acoes.add_child(Tema.botao("Jogar partida", _jogar_partida, true))


func _trocar(posicao: String) -> void:
	if _ocupado or _saindo:
		return
	var anterior: String = _troca
	_troca = posicao if anterior.is_empty() else ""
	if anterior.is_empty() or anterior == posicao:
		_montar_formacao()
		_cartas_formacao[posicao].grab_focus()
		return
	var inversa: Transform2D = _base.get_global_transform_with_canvas().affine_inverse()
	var origem_a: Vector2 = inversa * _cartas_formacao[anterior].get_global_rect().get_center()
	var origem_b: Vector2 = inversa * _cartas_formacao[posicao].get_global_rect().get_center()
	var mapa: Dictionary = _estado["times"][_estado["lado_jogador"]]["posicoes"].duplicate()
	var primeiro: String = str(mapa[anterior])
	mapa[anterior] = mapa[posicao]
	mapa[posicao] = primeiro
	_executar(Jogo.definir_posicoes_draft.bind(mapa))
	_cartas_formacao[posicao].grab_focus()
	if not _animar:
		return
	await get_tree().process_frame
	if _saindo or not _formacao.visible:
		return
	_animar_nome(str(_catalogo[primeiro]["nome"]), origem_a, _cartas_formacao[posicao])
	_animar_nome(str(_catalogo[mapa[anterior]]["nome"]), origem_b, _cartas_formacao[anterior])


func _acao_manual() -> void:
	var id: String = _inspecionado
	if id.is_empty() or not _botao_ficha.visible:
		return
	var acao: String = str(_estado.get("vez", {}).get("acao", ""))
	if acao == "ban":
		_executar(Jogo.banir_no_draft.bind(id))
	elif acao == "pick":
		_executar(Jogo.escolher_no_draft.bind(id))


func _delegar() -> void:
	_executar(Jogo.escolher_automatico_no_draft.bind(_filtro))


func _executar(acao: Callable) -> void:
	if _ocupado or _saindo:
		return
	_ocupado = true
	_aviso.hide()
	var anteriores: Dictionary = _campeoes_draft.duplicate()
	var resultado: Dictionary = acao.call()
	if not bool(resultado.get("ok", false)):
		_ocupado = false
		_mostrar_erros(resultado)
		return
	_fechar_ficha()
	_estado = resultado["estado"]
	var terminou: bool = bool(_estado.get("concluido", false))
	var manter_grade: bool = _animar and terminou and _tabuleiro.visible and _tem_nova_escolha_visivel(anteriores)
	_atualizar_tela(true, manter_grade)
	if manter_grade:
		await get_tree().create_timer(Cartao.DURACAO_ESCOLHA).timeout
		if _saindo:
			return
		_atualizar_tela()
	elif _animar and not terminou:
		await get_tree().process_frame
		_animar_escolhas(anteriores)
	_ocupado = false
	_auto.disabled = not bool(_estado.get("vez", {}).get("do_jogador", false))


func _tem_nova_escolha_visivel(anteriores: Dictionary) -> bool:
	for ficha: Dictionary in _estado.get("campeoes", []):
		var id: String = str(ficha["id"])
		if ficha.get("estado") == "escolhido" and anteriores.get(id, {}).get("estado") == "livre" and _cartao_em_tela(id):
			return true
	return false


func _animar_escolhas(anteriores: Dictionary) -> void:
	if _saindo or anteriores.is_empty():
		return
	for id: String in _campeoes_draft:
		var atual: Dictionary = _campeoes_draft[id]
		if atual.get("estado") != "escolhido" or anteriores.get(id, {}).get("estado") == "escolhido":
			continue
		var origem: Control = _cartoes[id]
		var destino: Control = _lados[atual["por"]].destino(id)
		if not origem.is_visible_in_tree() or not is_instance_valid(destino):
			continue
		var transformar: Transform2D = _base.get_global_transform_with_canvas().affine_inverse()
		var inicio: Vector2 = transformar * origem.get_global_rect().get_center()
		if inicio.y < 55.0 or inicio.y > _base.size.y:
			continue
		_animar_nome(str(_catalogo[id]["nome"]), inicio, destino)


func _animar_nome(nome: String, inicio: Vector2, destino: Control) -> void:
	var fim: Vector2 = _base.get_global_transform_with_canvas().affine_inverse() * destino.get_global_rect().get_center()
	var carta: Label = Tema.texto(nome, 15, Tema.CIANO)
	carta.add_theme_stylebox_override("normal", Tema.caixa(Tema.FUNDO, Tema.CIANO, 5))
	_base.add_child(carta)
	var meio: Vector2 = carta.get_combined_minimum_size() * 0.5
	carta.position = inicio - meio
	var movimento: Tween = create_tween().set_parallel(true)
	movimento.tween_property(carta, "position", fim - meio, 0.27).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	movimento.tween_property(carta, "modulate:a", 0.0, 0.12).set_delay(0.15)
	movimento.chain().tween_callback(carta.queue_free)


func _mostrar_erros(resultado: Dictionary) -> void:
	var erros: Dictionary = resultado.get("erros", {})
	var mensagens: PackedStringArray = []
	for mensagem: Variant in erros.values():
		mensagens.append(str(mensagem))
	_aviso.text = "\n".join(mensagens)
	_aviso.visible = not _aviso.text.is_empty()


func _mostrar_ajuda() -> void:
	_aviso.text = AJUDA_AUTO
	_aviso.visible = not _aviso.visible


func _pedir_reinicio() -> void:
	if _ocupado or _saindo or is_instance_valid(_confirmacao):
		return
	_confirmacao = ConfirmationDialog.new()
	_confirmacao.title = "Reiniciar o draft?"
	_confirmacao.get_ok_button().text = "Reiniciar"
	_confirmacao.get_cancel_button().text = "Cancelar"
	_confirmacao.confirmed.connect(_reiniciar)
	_confirmacao.canceled.connect(_fechar_confirmacao)
	add_child(_confirmacao)
	_confirmacao.popup_centered()
	_confirmacao.get_cancel_button().grab_focus()


func _fechar_confirmacao() -> void:
	if is_instance_valid(_confirmacao):
		_confirmacao.hide()
		_confirmacao.queue_free()
		_confirmacao = null


func _reiniciar() -> void:
	_fechar_confirmacao()
	_troca = ""
	_executar(Jogo.iniciar_draft.bind({"primeira_escolha": _estado["lado_jogador"] == "azul"}))


func _jogar_partida() -> void:
	if _ocupado or _saindo:
		return
	_ocupado = true
	var resultado: Dictionary = Jogo.simular_partida_do_draft()
	if not resultado.get("ok", false):
		_ocupado = false
		_mostrar_erros(resultado)
		return
	_saindo = true
	get_tree().change_scene_to_file.call_deferred(PARTIDA)


func _voltar() -> void:
	if _saindo:
		return
	_saindo = true
	get_tree().change_scene_to_file.call_deferred(SEDE)


static func _apagar_filhos(no: Node) -> void:
	for filho: Node in no.get_children():
		no.remove_child(filho)
		filho.queue_free()
