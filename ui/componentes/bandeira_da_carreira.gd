extends RefCounted
## Guarda a arte da interface em um arquivo auxiliar até o save ter um campo de bandeira.

const Arte = preload("res://ui/componentes/arte_bandeira.gd")
const ARQUIVO: String = "user://bandeiras_apresentacao.cfg"


static func guardar(slot: int, registro: Dictionary, imagem: Image) -> Error:
	if slot < 0 or registro.is_empty() or imagem == null:
		return ERR_INVALID_PARAMETER
	var arquivo: ConfigFile = ConfigFile.new()
	var erro: Error = arquivo.load(ARQUIVO)
	if erro != OK and erro != ERR_FILE_NOT_FOUND:
		return erro
	var secao: String = str(slot)
	arquivo.set_value(secao, "registro", registro.duplicate())
	arquivo.set_value(secao, "png", Marshalls.raw_to_base64(imagem.save_png_to_buffer()))
	erro = arquivo.save(ARQUIVO + ".tmp")
	if erro != OK:
		return erro
	return DirAccess.rename_absolute(ARQUIVO + ".tmp", ARQUIVO)


static func carregar(slot: int, registro: Dictionary) -> Image:
	if slot < 0 or registro.is_empty():
		return null
	var arquivo: ConfigFile = ConfigFile.new()
	if arquivo.load(ARQUIVO) != OK:
		return null
	var secao: String = str(slot)
	if arquivo.get_value(secao, "registro", {}) != registro:
		return null
	var base64: String = str(arquivo.get_value(secao, "png", ""))
	if base64.is_empty() or base64.length() > 300000:
		return null
	var imagem: Image = Image.new()
	if imagem.load_png_from_buffer(Marshalls.base64_to_raw(base64)) != OK or imagem.get_size() != Arte.TAMANHO:
		return null
	return imagem
