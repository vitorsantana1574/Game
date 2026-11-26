extends RefCounted

const Base = preload("res://ui/temas/tema_abertura.gd")

const FUNDO: Color = Color("#0b1120")
const PAINEL: Color = Color("#101b30")
const BORDA: Color = Color("#344867")
const TEXTO: Color = Color("#f6f7fc")
const SUAVE: Color = Color("#bac8dd")
const CIANO: Color = Color("#9cd9ff")
const CORAL: Color = Color("#ff9f97")
const DOURADO: Color = Color("#f5dba7")


static func criar() -> Theme:
	var tema: Theme = Base.criar()
	tema.default_font_size = 17
	tema.set_color("font_color", "Label", TEXTO)
	for tipo: String in ["Button", "OptionButton"]:
		tema.set_stylebox("normal", tipo, Base.caixa(Color("#192741"), BORDA, 7))
		tema.set_stylebox("hover", tipo, Base.caixa(Color("#263f58"), CIANO, 7))
		tema.set_stylebox("pressed", tipo, Base.caixa(Color("#234265"), CIANO, 7))
		tema.set_stylebox("disabled", tipo, Base.caixa(FUNDO, BORDA, 7))
		tema.set_stylebox("focus", tipo, Base.caixa(Color.TRANSPARENT, DOURADO, 7))
		for estado: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			tema.set_color(estado, tipo, TEXTO)
	tema.set_stylebox("normal", "LineEdit", Base.caixa(FUNDO, BORDA, 8))
	tema.set_stylebox("normal", "AcaoPrincipal", Base.caixa(CIANO, CIANO, 7))
	tema.set_stylebox("hover", "AcaoPrincipal", Base.caixa(Color("#c1eeff"), CIANO, 7))
	tema.set_stylebox("pressed", "AcaoPrincipal", Base.caixa(Color("#83c5e9"), CIANO, 7))
	return tema


static func caixa(fundo: Color, contorno: Color, margem: int = 8) -> StyleBoxFlat:
	return Base.caixa(fundo, contorno, margem)


static func cor_lado(lado: String) -> Color:
	return CIANO if lado == "azul" else CORAL


static func texto(conteudo: String, tamanho: int = 17, cor: Color = TEXTO) -> Label:
	var rotulo: Label = Label.new()
	rotulo.text = conteudo
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rotulo


static func botao(conteudo: String, acao: Callable, principal: bool = false) -> Button:
	var botao_novo: Button = Button.new()
	botao_novo.text = conteudo
	botao_novo.custom_minimum_size.y = 37
	botao_novo.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if principal:
		botao_novo.theme_type_variation = "AcaoPrincipal"
	botao_novo.pressed.connect(acao)
	return botao_novo
