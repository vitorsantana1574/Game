extends RefCounted
## Usa os WebP exportados como estão, sem recodificar as artes no pacote.

static var _cache: Dictionary[String, WeakRef] = {}


static func carregar(caminho: String) -> ImageTexture:
	var referencia: WeakRef = _cache.get(caminho)
	if referencia != null:
		var textura_existente: ImageTexture = referencia.get_ref()
		if textura_existente != null:
			return textura_existente

	var imagem: Image = Image.new()
	var dados: PackedByteArray = FileAccess.get_file_as_bytes(caminho)
	if dados.is_empty() or imagem.load_webp_from_buffer(dados) != OK:
		push_error("Não foi possível carregar a textura %s." % caminho)
		return null
	var textura: ImageTexture = ImageTexture.create_from_image(imagem)
	_cache[caminho] = weakref(textura)
	return textura
