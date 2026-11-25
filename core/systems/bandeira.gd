class_name Bandeira
extends RefCounted
## Validação da bandeira desenhada pelo jogador na criação da equipe.
## A imagem chega como PNG em base64 e fica dentro do save, junto com a organização.

const LARGURA: int = 240
const ALTURA: int = 208
## Limite do PNG decodificado, para o save não crescer demais.
const BYTES_MAXIMOS: int = 262144

const ERRO_BASE64: String = "base64_invalido"
const ERRO_TAMANHO_ARQUIVO: String = "arquivo_grande"
const ERRO_PNG: String = "png_invalido"
const ERRO_DIMENSOES: String = "dimensoes_invalidas"


## "" se a bandeira é válida (ou vazia, que significa a arte padrão); senão, o código do erro.
static func validar(png_base64: String) -> String:
	if png_base64.is_empty():
		return ""
	# Confere o formato antes de decodificar (o decodificador da Godot reclama no console com texto inválido).
	var formato: RegEx = RegEx.create_from_string("^[A-Za-z0-9+/]+={0,2}$")
	if png_base64.length() % 4 != 0 or formato.search(png_base64) == null:
		return ERRO_BASE64
	if png_base64.length() > BYTES_MAXIMOS * 4 / 3 + 4:
		return ERRO_TAMANHO_ARQUIVO
	var bytes: PackedByteArray = Marshalls.base64_to_raw(png_base64)
	if bytes.is_empty():
		return ERRO_BASE64
	if bytes.size() > BYTES_MAXIMOS:
		return ERRO_TAMANHO_ARQUIVO
	var imagem: Image = Image.new()
	if imagem.load_png_from_buffer(bytes) != OK:
		return ERRO_PNG
	if imagem.get_width() != LARGURA or imagem.get_height() != ALTURA:
		return ERRO_DIMENSOES
	return ""


static func mensagem_erro(codigo: String) -> String:
	match codigo:
		ERRO_BASE64:
			return "A imagem da bandeira não pôde ser lida."
		ERRO_TAMANHO_ARQUIVO:
			return "A imagem da bandeira é grande demais."
		ERRO_PNG:
			return "A bandeira precisa ser uma imagem PNG."
		ERRO_DIMENSOES:
			return "A bandeira precisa ter %d × %d pixels." % [LARGURA, ALTURA]
	return "Bandeira inválida."
