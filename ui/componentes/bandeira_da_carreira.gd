extends RefCounted
## Converte a arte do save e lê bandeiras gravadas pela versão anterior da interface.

const Arte = preload("res://ui/componentes/arte_bandeira.gd")
const ARQUIVO: String = "user://bandeiras_apresentacao.cfg"
const MAXIMO_BASE64: int = 349528 # 256 KiB codificados.


static func codificar(imagem: Image) -> String:
	return Marshalls.raw_to_base64(imagem.save_png_to_buffer())


static func ler_legado(slot: int, registro: Dictionary) -> String:
	if slot < 0 or registro.is_empty():
		return ""
	var arquivo: ConfigFile = ConfigFile.new()
	if arquivo.load(ARQUIVO) != OK:
		return ""
	var secao: String = str(slot)
	var metadados: Variant = arquivo.get_value(secao, "registro", {})
	if not metadados is Dictionary:
		return ""
	var antigo: Dictionary = metadados.duplicate()
	var atual: Dictionary = registro.duplicate()
	antigo.erase("bandeira_png")
	atual.erase("bandeira_png")
	return str(arquivo.get_value(secao, "png", "")) if antigo == atual else ""


static func decodificar(base64: String) -> Image:
	if not base64.begins_with("iVBORw0KGgo") or base64.length() > MAXIMO_BASE64 or base64.length() % 4 != 0:
		return null
	var formato: RegEx = RegEx.create_from_string("^[A-Za-z0-9+/]+={0,2}$")
	if formato.search(base64) == null:
		return null
	var png: PackedByteArray = Marshalls.base64_to_raw(base64)
	if png.is_empty():
		return null
	var imagem: Image = Image.new()
	if imagem.load_png_from_buffer(png) != OK or imagem.get_size() != Arte.TAMANHO:
		return null
	return imagem
