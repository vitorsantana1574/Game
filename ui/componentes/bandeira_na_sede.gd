extends Control

# Os cantos seguem o tecido que já existe na arte isométrica.
const CANTOS: PackedVector2Array = [
	Vector2(0.244, 0.181), Vector2(0.340, 0.112), Vector2(0.331, 0.293), Vector2(0.246, 0.325),
]
const UV: PackedVector2Array = [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]
const LUZ: PackedColorArray = [Color("#a5aaa0"), Color("#7e857c"), Color("#a2a699"), Color("#7e8178")]

var _textura: Texture2D


func aplicar(imagem: Image) -> void:
	exibir_textura(ImageTexture.create_from_image(imagem) if imagem != null else null)


func exibir_textura(textura: Texture2D) -> void:
	_textura = textura
	queue_redraw()


func _draw() -> void:
	if _textura == null:
		return
	var pontos: PackedVector2Array = []
	for canto: Vector2 in CANTOS:
		pontos.append(canto * size)
	draw_polygon(pontos, LUZ, UV, _textura)


func _notification(codigo: int) -> void:
	if codigo == NOTIFICATION_RESIZED:
		queue_redraw()
