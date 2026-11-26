extends TextureRect
## Um atlas compartilhado por tipo de efeito. Só interpola os dois quadros visíveis.

const TRANSICAO = preload("res://ui/partida/transicao_atlas.gdshader")
## [origem, tamanho exibido, célula no atlas, quadros, colunas, quadros por página, duração em segundos].
## Quadros gerados por tools/arte/animar_*.py (30 por segundo; o último é igual à arte do mapa).
const DADOS: Dictionary = {
	"hydra": [Vector2(186, 194), Vector2(245, 212), Vector2i(355, 308), 139, 5, 55, 4.63],
	"cerbero": [Vector2(598, 546), Vector2(206, 198), Vector2i(299, 287), 151, 6, 78, 5.03],
	"torre_azul": [Vector2(-90, -105), Vector2(180, 160), Vector2i(360, 320), 79, 5, 60, 2.63],
	"torre_coral": [Vector2(-90, -105), Vector2(180, 160), Vector2i(360, 320), 79, 5, 60, 2.63],
}

var duracao: float
var _dados: Array
var _paginas: Array[Texture2D]
var _shader: ShaderMaterial
var _anterior: int = -1


func configurar(tipo: String, paginas: Array[Texture2D], origem: Vector2) -> void:
	_dados = DADOS[tipo]
	_paginas = paginas
	duracao = _dados[6]
	position = origem + Vector2(_dados[0])
	size = _dados[1]
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shader = ShaderMaterial.new()
	_shader.shader = TRANSICAO
	material = _shader
	quadro(0.0)


func quadro(tempo: float) -> void:
	var fim: int = int(_dados[3]) - 1
	var ponto: float = clampf(tempo / duracao, 0.0, 1.0) * fim
	var indice: int = floori(ponto)
	if indice != _anterior:
		_anterior = indice
		_vincular(indice, &"atlas_atual", &"regiao_atual")
		_vincular(mini(indice + 1, fim), &"atlas_seguinte", &"regiao_seguinte")
	_shader.set_shader_parameter(&"mistura", ponto - indice)


func _vincular(indice: int, atlas: StringName, regiao: StringName) -> void:
	var por_pagina: int = _dados[5]
	var colunas: int = _dados[4]
	var celula: Vector2i = _dados[2]
	var pagina: int = floori(float(indice) / por_pagina)
	var local: int = indice % por_pagina
	var coordenada: Vector2 = Vector2(local % colunas, floori(float(local) / colunas))
	var textura_atlas: Texture2D = _paginas[pagina]
	if atlas == &"atlas_atual":
		texture = textura_atlas
	_shader.set_shader_parameter(atlas, textura_atlas)
	var tamanho: Vector2 = textura_atlas.get_size()
	var canto: Vector2 = (coordenada * (Vector2(celula) + Vector2(4, 4)) + Vector2(2.5, 2.5)) / tamanho
	var extensao: Vector2 = (Vector2(celula) - Vector2.ONE) / tamanho
	_shader.set_shader_parameter(regiao, Vector4(canto.x, canto.y, extensao.x, extensao.y))
