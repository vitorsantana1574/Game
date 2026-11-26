extends PanelContainer

signal inspecionar(id: String)

const Tema = preload("res://ui/temas/tema_draft.gd")

var _coluna: VBoxContainer
var _nome: Label
var _grupo_picks: BoxContainer
var _grupo_bans: HBoxContainer
var _picks: Label
var _bans: Label
var _aliado: bool
var _lado: String
var _compacto: bool
var _catalogo: Dictionary
var _slots: Dictionary = {}


func montar(lado: String, compacto: bool, aliado: bool, dados_catalogo: Dictionary, bandeira: Texture2D) -> void:
	_lado = lado
	_compacto = compacto
	_aliado = aliado
	_catalogo = dados_catalogo
	custom_minimum_size.x = 0.0 if compacto else 205.0
	size_flags_horizontal = Control.SIZE_EXPAND_FILL if compacto else Control.SIZE_FILL
	_coluna = VBoxContainer.new()
	_coluna.add_theme_constant_override("separation", 6)
	add_child(_coluna)
	var identidade: HBoxContainer = HBoxContainer.new()
	_coluna.add_child(identidade)
	if bandeira != null:
		var imagem: TextureRect = TextureRect.new()
		imagem.texture = bandeira
		imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		imagem.custom_minimum_size = Vector2(24, 24) if compacto else Vector2(32, 32)
		identidade.add_child(imagem)
	_nome = Tema.texto("", 16 if compacto else 19, Tema.cor_lado(lado))
	_nome.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identidade.add_child(_nome)
	_picks = Tema.texto("", 14, Tema.SUAVE)
	_coluna.add_child(_picks)
	_grupo_picks = HBoxContainer.new() if compacto else VBoxContainer.new()
	_grupo_picks.add_theme_constant_override("separation", 4)
	_coluna.add_child(_grupo_picks)
	_bans = Tema.texto("", 14, Tema.SUAVE)
	_coluna.add_child(_bans)
	_grupo_bans = HBoxContainer.new()
	_grupo_bans.add_theme_constant_override("separation", 4)
	_coluna.add_child(_grupo_bans)


func atualizar(time: Dictionary, vez: Dictionary, teto_picks: int, teto_bans: int) -> void:
	var escolhas: Array = time.get("picks", [])
	var bans: Array = time.get("bans", [])
	var ativo: bool = vez.get("time") == _lado
	var cor: Color = Tema.cor_lado(_lado)
	add_theme_stylebox_override("panel", Tema.caixa(Tema.PAINEL, cor if ativo else Tema.BORDA, 8))
	_nome.text = str(time.get("nome", ""))
	_nome.tooltip_text = "%s · %s" % [_nome.text, "Sua equipe" if _aliado else "Adversário"]
	_picks.text = "Escolhas   %d/%d" % [escolhas.size(), teto_picks]
	_bans.text = "Banimentos   %d/%d" % [bans.size(), teto_bans]
	_slots.clear()
	_atualizar_slots(_grupo_picks, escolhas, teto_picks, cor, true, ativo and vez.get("acao") == "pick")
	_atualizar_slots(_grupo_bans, bans, teto_bans, cor, false, ativo and vez.get("acao") == "ban")


func _atualizar_slots(grupo: BoxContainer, ids: Array, teto: int, cor: Color, picks: bool, ativo: bool) -> void:
	for no: Node in grupo.get_children():
		grupo.remove_child(no)
		no.queue_free()
	for i: int in range(teto):
		var id: String = str(ids[i]) if i < ids.size() else ""
		var nome: String = str(_catalogo.get(id, {}).get("nome", id))
		var proximo: bool = id.is_empty() and ativo and i == ids.size()
		var texto: String = nome if picks and not _compacto else nome.left(2).to_upper()
		if id.is_empty():
			texto = "Escolha %d" % (i + 1) if picks and not _compacto else "·"
		elif not picks:
			texto = "×"
		var item: Button = Tema.botao(texto, func() -> void: inspecionar.emit(id))
		item.flat = false
		item.disabled = id.is_empty()
		item.custom_minimum_size.y = 43 if picks and not _compacto else 26
		item.add_theme_font_size_override("font_size", 15 if picks and not _compacto else 13)
		item.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.add_theme_stylebox_override("disabled", Tema.caixa(Tema.FUNDO, cor if proximo else Tema.BORDA, 2))
		item.add_theme_stylebox_override("normal", Tema.caixa(Tema.PAINEL.lightened(0.08), Tema.BORDA, 2))
		for estado: String in ["font_color", "font_hover_color", "font_focus_color", "font_disabled_color"]:
			item.add_theme_color_override(estado, cor if proximo or not picks else Tema.TEXTO)
		if not id.is_empty():
			item.tooltip_text = "%s · %s" % ["Escolhido" if picks else "Banido", nome]
			item.accessibility_name = item.tooltip_text
			_slots[id] = item
		grupo.add_child(item)


func destino(id: String) -> Control:
	return _slots.get(id)
