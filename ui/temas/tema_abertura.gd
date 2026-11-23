extends RefCounted

const TEXTO: Color = Color("#f6f6ef")
const SUAVE: Color = Color("#b7c8bf")
const VERDE: Color = Color("#bcf1cf")
const DOURADO: Color = Color("#f3ce91")
const SOMBRA: Color = Color("#101b19")
const BORDA: Color = Color("#4b6359")

static func caixa(fundo: Color, contorno: Color, margem: int = 12) -> StyleBoxFlat:
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = fundo
	estilo.border_color = contorno
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(5)
	estilo.content_margin_top = margem
	estilo.content_margin_bottom = margem
	estilo.content_margin_left = margem
	estilo.content_margin_right = margem
	return estilo

static func criar() -> Theme:
	var tema: Theme = Theme.new()
	tema.default_font_size = 21
	tema.set_stylebox("panel", "PanelContainer", caixa(Color("#101d1bf8"), BORDA, 26))
	tema.set_stylebox("normal", "LineEdit", caixa(Color("#0c1716"), BORDA))
	tema.set_stylebox("focus", "LineEdit", caixa(Color.TRANSPARENT, DOURADO))
	tema.set_color("font_color", "Label", TEXTO)

	for tipo: String in ["Button", "CheckButton", "OptionButton"]:
		tema.set_color("font_color", tipo, TEXTO)
		tema.set_color("font_hover_color", tipo, VERDE)
		tema.set_color("font_pressed_color", tipo, VERDE)
		tema.set_color("font_focus_color", tipo, TEXTO)
		tema.set_color("font_disabled_color", tipo, SUAVE)
		tema.set_stylebox("normal", tipo, caixa(Color("#182722"), BORDA))
		tema.set_stylebox("hover", tipo, caixa(Color("#243b33"), VERDE))
		tema.set_stylebox("pressed", tipo, caixa(Color("#284a39"), VERDE))
		tema.set_stylebox("disabled", tipo, caixa(SOMBRA, BORDA))
		tema.set_stylebox("focus", tipo, caixa(Color.TRANSPARENT, DOURADO))

	tema.set_type_variation("AcaoPrincipal", "Button")
	tema.set_stylebox("normal", "AcaoPrincipal", caixa(VERDE, VERDE))
	tema.set_stylebox("hover", "AcaoPrincipal", caixa(Color("#d9ffe4"), VERDE))
	tema.set_stylebox("pressed", "AcaoPrincipal", caixa(Color("#91d9ad"), VERDE))
	for estado: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		tema.set_color(estado, "AcaoPrincipal", Color("#102318"))

	tema.set_type_variation("OpcaoMenu", "Button")
	for estado: String in ["normal", "hover", "pressed", "disabled"]:
		tema.set_stylebox(estado, "OpcaoMenu", StyleBoxEmpty.new())
	return tema
