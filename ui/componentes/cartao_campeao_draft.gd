extends Button

const Tema = preload("res://ui/temas/tema_draft.gd")
const Texturas = preload("res://ui/componentes/texturas_webp.gd")
const ONDA = preload("res://ui/componentes/onda_escolha_draft.gdshader")
const DURACAO_ESCOLHA: float = 0.62
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
var _nota: Label
var _arte: ColorRect
var _material: ShaderMaterial
var _tem_retrato: bool
var _cor_classe: Color
var _risco: Control
var _banimento: float
var _efeito_ban: Tween
var _efeito_escolha: Tween


func _ready() -> void:
	clip_contents = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_arte = ColorRect.new()
	_material = ShaderMaterial.new()
	_material.shader = ONDA
	_arte.material = _material
	_arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_arte)
	_arte.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_arte.offset_left = 2.0
	_arte.offset_top = 2.0
	_arte.offset_right = -2.0
	_arte.offset_bottom = -3.0
	_arte.resized.connect(_atualizar_tamanho)
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
	_nota = Tema.texto("", 13, Tema.CIANO)
	_nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_nota)
	_nota.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_nota.offset_left = -37.0
	_nota.offset_right = -6.0
	_nota.offset_top = -23.0
	_nota.offset_bottom = -3.0
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


func configurar(campeao: Dictionary, dados: Dictionary, em_foco: bool, rota: String, animar: bool) -> void:
	var anterior: String = str(_dados.get("estado", ""))
	if _campeao.is_empty():
		_campeao = campeao
		_cor_classe = CLASSES.get(campeao.get("classe"), Tema.SUAVE)
		var caminho: String = "res://assets/sprites/campeoes/%s.webp" % campeao["id"]
		if ResourceLoader.exists(caminho) or FileAccess.file_exists(caminho):
			var retrato: Texture2D = Texturas.carregar(caminho)
			if retrato != null:
				_tem_retrato = true
				_material.set_shader_parameter("retrato", retrato)
				_material.set_shader_parameter("proporcao_retrato", float(retrato.get_width()) / retrato.get_height())
				_material.set_shader_parameter("tem_retrato", true)
		var nome: String = str(campeao["nome"])
		_sigla.text = nome.left(2).to_upper()
		_nome.text = nome
		_tipo.text = str(campeao.get("classe", "")).capitalize()
	_dados = dados
	var situacao: String = str(dados.get("estado", "livre"))
	var livre: bool = situacao == "livre"
	var mudou: bool = anterior != situacao
	var borda: Color = Tema.CIANO if em_foco else (_cor_classe.darkened(0.46) if livre else Color("#4e5157"))
	var fundo: Color = _cor_classe.lerp(Tema.PAINEL, 0.87)
	var estilo: StyleBoxFlat = Tema.caixa(fundo, borda, 3)
	estilo.border_width_bottom = 3
	add_theme_stylebox_override("normal", estilo)
	add_theme_stylebox_override("hover", Tema.caixa(fundo.lightened(0.12), Tema.CIANO, 3))
	_material.set_shader_parameter("cor_viva", fundo)
	_material.set_shader_parameter("cor_cinza", Color("#202125") if situacao == "escolhido" else Color("#141416"))
	_sigla.visible = not _tem_retrato
	_esquerda.visible = not dados.get("favorito_do_rival", []).is_empty()
	_direita.visible = false
	for perfil: Dictionary in dados.get("dominio", {}).values():
		if str(perfil.get("nivel", "")) in ["favorito", "main", "mono"]:
			_direita.show()
			break
	var conhecimento: Dictionary = dados.get("dominio", {}).get(rota, {})
	_nota.visible = conhecimento.has("conhecimento")
	_nota.text = str(conhecimento.get("conhecimento", ""))
	_risco.visible = situacao == "banido"
	accessibility_name = "%s%s" % [str(campeao["nome"]),
		" · %s" % situacao.capitalize() if not livre else ""]
	if _nota.visible:
		accessibility_name += " · %s · %s" % [_nota.text, conhecimento.get("nivel_nome", "")]
	tooltip_text = accessibility_name
	if _direita.visible:
		tooltip_text += "\nCampeão principal da sua equipe"
	if _esquerda.visible:
		tooltip_text += "\nCampeão principal do rival"
	if not mudou:
		return
	if _efeito_ban != null:
		_efeito_ban.kill()
	if _efeito_escolha != null:
		_efeito_escolha.kill()
	var transicao: bool = animar and anterior == "livre" and is_visible_in_tree()
	if _risco.visible and transicao:
		_progresso_ban(0.0)
		_efeito_ban = create_tween()
		_efeito_ban.tween_method(_progresso_ban, 0.0, 2.0, 0.27)
	else:
		_progresso_ban(2.0)
	if situacao == "escolhido" and transicao:
		_progresso_escolha(0.0)
		_efeito_escolha = create_tween()
		_efeito_escolha.tween_method(_progresso_escolha, 0.0, 1.0, DURACAO_ESCOLHA)
	else:
		_progresso_escolha(0.0 if livre else 1.0)


func _atualizar_tamanho() -> void:
	_material.set_shader_parameter("tamanho", _arte.size.max(Vector2.ONE))


func _progresso_escolha(valor: float) -> void:
	_material.set_shader_parameter("progresso", valor)
	var mistura: float = smoothstep(0.05, 0.53, valor)
	_sigla.add_theme_color_override("font_color", _cor_classe.lerp(Color("#b9b9bd"), mistura))
	_nome.modulate = Color.WHITE.lerp(Color("#d8d8da"), mistura)
	_tipo.modulate = _nome.modulate
	var cinza: Color = Color("#b0b0b0")
	_direita.add_theme_color_override("font_color", Tema.CIANO.lerp(cinza, mistura))
	_esquerda.add_theme_color_override("font_color", Tema.CORAL.lerp(cinza, mistura))
	_nota.add_theme_color_override("font_color", Tema.CIANO.lerp(cinza, mistura))


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
