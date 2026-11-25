extends RefCounted

const TexturasWebp = preload("res://ui/componentes/texturas_webp.gd")
const TAMANHO: Vector2i = Vector2i(240, 208)
const MODELOS: Dictionary = {
	"dragao": "Dragão", "tigre": "Tigre", "meteoro": "Meteoro", "estrela": "Estrela",
	"lobo": "Lobo", "corvo": "Corvo", "serpente": "Serpente", "touro": "Touro",
	"coruja": "Coruja", "carneiro": "Carneiro", "falcao": "Falcão", "montanha": "Montanha",
	"eclipse": "Eclipse", "tridente": "Tridente", "tempestade": "Tempestade",
}
const PALETAS: Dictionary = {
	"Floresta": [Color("#102720"), Color("#f1d9a4"), Color("#b98a4d")],
	"Marinho": [Color("#172945"), Color("#e8f7ff"), Color("#7297c2")],
	"Bordô": [Color("#451c29"), Color("#ffdfb9"), Color("#be7c66")],
	"Ametista": [Color("#2e2041"), Color("#eee1ff"), Color("#a78ad2")],
	"Carvão": [Color("#1b2024"), Color("#f4f7f8"), Color("#8499a2")],
	"Cobre": [Color("#37231b"), Color("#ffdbb1"), Color("#bd7154")],
}

static var _mascaras: Dictionary = {}


static func compor(modelo: String, fundo: Color, luz: Color, sombra: Color, desenho: Image = null) -> Image:
	var resultado: Image = Image.create_empty(TAMANHO.x, TAMANHO.y, false, Image.FORMAT_RGBA8)
	resultado.fill(fundo)
	if desenho != null:
		resultado.blend_rect(desenho, Rect2i(Vector2i.ZERO, TAMANHO), Vector2i.ZERO)
	elif MODELOS.has(modelo):
		var mascara: Image = _mascara(modelo)
		var margem: Vector2i = (TAMANHO - mascara.get_size()) / 2
		for y: int in range(mascara.get_height()):
			for x: int in range(mascara.get_width()):
				var canal: Color = mascara.get_pixel(x, y)
				if canal.a > 0.0:
					resultado.set_pixel(x + margem.x, y + margem.y,
						fundo.lerp(sombra.lerp(luz, canal.r), canal.a))
	return resultado


static func padrao() -> Image:
	var cores: Array = PALETAS["Floresta"]
	return compor("dragao", cores[0], cores[1], cores[2])


static func textura_modelo(modelo: String) -> Texture2D:
	return TexturasWebp.carregar("res://assets/sprites/emblemas/%s.webp" % modelo)


static func _mascara(modelo: String) -> Image:
	if _mascaras.has(modelo):
		return _mascaras[modelo]
	var textura: Texture2D = textura_modelo(modelo)
	if textura == null:
		return Image.create_empty(1, 1, false, Image.FORMAT_LA8)
	var imagem: Image = textura.get_image()
	imagem.resize(198, 198, Image.INTERPOLATE_LANCZOS)
	imagem.convert(Image.FORMAT_RGBA8)
	var mascara: Image = Image.create_empty(198, 198, false, Image.FORMAT_LA8)
	for y: int in range(imagem.get_height()):
		for x: int in range(imagem.get_width()):
			var cor: Color = imagem.get_pixel(x, y)
			# As tintas quentes têm mais vermelho que verde. O fundo vira transparente.
			var opacidade: float = clampf((cor.r8 - cor.g8 + 5.0) / 20.0, 0.0, 1.0)
			opacidade *= clampf((cor.r8 - 32.0) / 62.0, 0.0, 1.0)
			var tom: float = clampf((cor.g8 - 124.0) / 90.0, 0.0, 1.0)
			mascara.set_pixel(x, y, Color(tom, tom, tom, opacidade))
	_mascaras[modelo] = mascara
	return mascara
