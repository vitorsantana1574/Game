extends Button

const Tema = preload("res://ui/temas/tema_draft.gd")
const Texturas = preload("res://ui/componentes/texturas_webp.gd")
const CLASSES: Dictionary = {
	"tanque": Color("#c2a88a"), "assassino": Color("#da8ca4"), "lutador": Color("#d99870"),
	"mago": Color("#baadf2"), "suporte": Color("#a2d9bd"), "atirador": Color("#89cde4"),
}

var _campeao: Dictionary
var _dados: Dictionary
var _coluna: VBoxContainer
var _nome: Label
var _tipo: Label
var _sigla: Label
var _esquerda: Label
var _direita: Label
var _arte: TextureRect
var _risco: Control
var _banimento: float
var _efeito: Tween


func _ready() -> void:
	clip_contents = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_arte = TextureRect.new()
	_arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_arte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_arte)
	_arte.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_coluna = VBoxContainer.new()
	_coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	_coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_coluna.add_theme_constant_override("separation", 0)
	add_child(_coluna)
	_coluna.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sigla = _rotulo("", 25)
	_nome = _rotulo("", 16)
	_tipo = _rotulo("", 12)
	_esquerda = _marcador("◆", Tema.CORAL, false)
	_direita = _marcador("★", Tema.CIANO, true)
	_risco = Control.new()
	_risco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_risco)
	_risco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_risco.draw.connect(_desenhar_risco)
	_risco.hide()


func _rotulo(texto: String, tamanho: int) -> Label:
	var item: Label = Tema.texto(texto, tamanho)
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_coluna.add_child(item)
	return item


func _marcador(simbolo: String, cor: Color, na_direita: bool) -> Label:
	var item: Label = Tema.texto(simbolo, 15, cor)
	add_child(item)
	item.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT if na_direita else Control.PRESET_TOP_LEFT)
	item.position += Vector2(-24 if na_direita else 6, 3)
	return item


func configurar(campeao: Dictionary, dados: Dictionary, escolhido: bool, animar: bool) -> void:
	var mudou: bool = _dados.get("estado") != dados.get("estado")
	if _campeao.is_empty():
		_campeao = campeao
		var caminho: String = "res://assets/sprites/campeoes/%s.webp" % campeao["id"]
		if ResourceLoader.exists(caminho) or FileAccess.file_exists(caminho):
			_arte.texture = Texturas.carregar(caminho)
		var nome: String = str(campeao["nome"])
		_sigla.text = nome.left(2).to_upper()
		_nome.text = nome
		_tipo.text = str(campeao.get("classe", "")).capitalize()
	_dados = dados
	var situacao: String = str(dados.get("estado", "livre"))
	var livre: bool = situacao == "livre"
	var cor: Color = CLASSES.get(campeao.get("classe"), Tema.SUAVE)
	var borda: Color = Tema.CIANO if escolhido else cor.darkened(0.46)
	var fundo: Color = cor.lerp(Tema.PAINEL, 0.91) if livre else Tema.FUNDO
	var estilo: StyleBoxFlat = Tema.caixa(fundo, borda, 3)
	estilo.border_width_bottom = 3
	estilo.border_color = borda
	add_theme_stylebox_override("normal", estilo)
	add_theme_stylebox_override("hover", Tema.caixa(fundo.lightened(0.12), Tema.CIANO, 3))
	_sigla.add_theme_color_override("font_color", cor if livre else Tema.SUAVE.darkened(0.26))
	_arte.modulate = Color(0.62, 0.68, 0.77, 0.45 if livre else 0.24)
	_sigla.visible = _arte.texture == null
	_esquerda.visible = not dados.get("favorito_do_rival", []).is_empty()
	_direita.visible = false
	for perfil: Dictionary in dados.get("dominio", {}).values():
		if str(perfil.get("nivel", "")) in ["favorito", "main", "mono"]:
			_direita.show()
			break
	_risco.visible = situacao == "banido"
	accessibility_name = "%s%s" % [str(campeao["nome"]),
		" · %s" % situacao.capitalize() if not livre else ""]
	tooltip_text = accessibility_name
	if _direita.visible:
		tooltip_text += "\nCampeão principal da sua equipe"
	if _esquerda.visible:
		tooltip_text += "\nCampeão principal do rival"
	if mudou and _risco.visible and animar:
		_banimento = 0.0
		_efeito = create_tween()
		_efeito.tween_method(_progresso_ban, 0.0, 2.0, 0.27)
	elif mudou or _efeito == null or not _efeito.is_running():
		_progresso_ban(2.0)


func definir_compacto(compacto: bool) -> void:
	custom_minimum_size = Vector2(0, 80 if compacto else 88)
	_sigla.add_theme_font_size_override("font_size", 21 if compacto else 25)
	_nome.add_theme_font_size_override("font_size", 14 if compacto else 16)


func _progresso_ban(valor: float) -> void:
	_banimento = valor
	_risco.queue_redraw()


func _desenhar_risco() -> void:
	var a: Vector2 = _risco.size * Vector2(0.10, 0.20)
	var b: Vector2 = _risco.size * Vector2(0.90, 0.79)
	var c: Vector2 = Vector2(a.x, b.y)
	var d: Vector2 = Vector2(b.x, a.y)
	var cor: Color = Color("#e0767e")
	_risco.draw_line(a, a.lerp(b, minf(_banimento, 1.0)), cor, 3.0, true)
	if _banimento > 1.0:
		_risco.draw_line(c, c.lerp(d, _banimento - 1.0), cor, 3.0, true)
