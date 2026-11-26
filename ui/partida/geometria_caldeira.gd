extends RefCounted
## Projeta os pontos publicados pela simulação na maquete. As âncoras são
## referências da arte, em um quadrado de mil unidades, independentes das regras.

const LADO: float = 1000.0
const RAIO_VISUAL: float = 46.0
const NOMES: Array[String] = ["azul", "vermelho"]
const TORRES: Dictionary = {
	"topo": [[Vector2(92, 379), Vector2(85, 538), Vector2(92, 698)],
		[Vector2(362, 72), Vector2(526, 74), Vector2(686, 87)]],
	"meio": [[Vector2(405, 580), Vector2(323, 653), Vector2(242, 726)],
		[Vector2(588, 405), Vector2(670, 331), Vector2(752, 256)]],
	"baixo": [[Vector2(496, 874), Vector2(336, 872), Vector2(175, 863)],
		[Vector2(922, 634), Vector2(922, 472), Vector2(916, 313)]],
}
const BASES: Array[Dictionary] = [
	{"fonte": Vector2(86, 889), "cristal": Vector2(83, 837), "guardiao": Vector2(108, 864)},
	{"fonte": Vector2(944, 86), "cristal": Vector2(929, 65), "guardiao": Vector2(893, 111)},
]
const EPICOS: Dictionary = {"hydra": Vector2(310, 320), "cerbero": Vector2(708, 665)}
const ACAMPAMENTOS: Dictionary = {
	"passaros": [Vector2(206, 490), Vector2(789, 453)],
	"sapo": [Vector2(189, 625), Vector2(813, 286)],
	"rato": [Vector2(410, 752), Vector2(429, 179)],
	"aranhas": [Vector2(457, 685), Vector2(523, 262)],
	"polvo": [Vector2(270, 572), Vector2(714, 362)],
	"golem": [Vector2(549, 771), Vector2(576, 169)],
}
const ACESSOS: Array[Array] = [
	[Vector2(196, 151), Vector2(159, 150), Vector2(133, 138), Vector2(108.165, 122.252)],
	[Vector2(433, 458), Vector2(449, 478), Vector2(468, 492), Vector2(500, 502)],
	[Vector2(537, 548), Vector2(511, 521), Vector2(497, 513), Vector2(500, 502)],
	[Vector2(768, 848), Vector2(786, 848), Vector2(805, 851), Vector2(801.311, 871.604)],
	[Vector2(94, 858), Vector2(129, 821), Vector2(155, 804), Vector2(177, 786),
		Vector2(207, 790), Vector2(249, 802), Vector2(283, 797), Vector2(310, 783), Vector2(343, 779)],
	[Vector2(923, 103), Vector2(858, 128), Vector2(823, 159), Vector2(790, 172),
		Vector2(741, 180), Vector2(692, 185), Vector2(643, 200), Vector2(613, 232)],
]

var _logicos: PackedVector2Array
var _visuais: PackedVector2Array
var _triangulos: PackedInt32Array
var _marcos: Dictionary[Vector2, Vector2] = {}


func configurar(mapa: Dictionary) -> void:
	_logicos.clear()
	_visuais.clear()
	_marcos.clear()
	for canto: Vector2 in [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]:
		_ancorar(canto, canto * LADO)
	for time: int in range(2):
		var base_logica: Dictionary = mapa.get("bases", {}).get(NOMES[time], {})
		for parte: String in BASES[time]:
			if base_logica.has(parte):
				_marcos[ponto(base_logica[parte])] = BASES[time][parte]
	for id: String in EPICOS:
		if mapa.get("monstros_epicos", {}).has(id):
			_ancorar(ponto(mapa["monstros_epicos"][id]), EPICOS[id])
	for id: String in ACAMPAMENTOS:
		if mapa.get("acampamentos", {}).has(id):
			var acampamento: Vector2 = ponto(mapa["acampamentos"][id])
			_marcos[acampamento] = ACAMPAMENTOS[id][0]
			_marcos[Vector2.ONE - acampamento] = ACAMPAMENTOS[id][1]
	var fracoes: Array = mapa.get("torres", {}).get("posicoes", [])
	for rota: String in TORRES:
		var trilha: Array = mapa.get("rotas", {}).get(rota, [])
		if trilha.size() < 2:
			continue
		for time: int in range(2):
			for indice: int in range(mini(3, fracoes.size())):
				var f: float = float(fracoes[indice])
				_ancorar(_ponto_na_trilha(trilha, f if time == 0 else 1.0 - f), TORRES[rota][time][indice])
		_ancorar(_ponto_na_trilha(trilha, 0.5), {"meio": Vector2(500, 502),
			"topo": Vector2(108.165, 122.252), "baixo": Vector2(801.311, 871.604)}[rota])
	_triangulos = Geometry2D.triangulate_delaunay(_logicos)


func projetar(origem: Vector2) -> Vector2:
	var alvo: Vector2 = origem.clamp(Vector2.ZERO, Vector2.ONE)
	# Os acampamentos nomeados e as estruturas da base são destinos exatos.
	# Mantê-los fora da triangulação evita inverter os corredores vizinhos.
	if _marcos.has(alvo):
		return _marcos[alvo]
	for i: int in range(0, _triangulos.size(), 3):
		var ia: int = _triangulos[i]
		var ib: int = _triangulos[i + 1]
		var ic: int = _triangulos[i + 2]
		var p: Vector2 = _logicos[ia]
		var u: Vector2 = _logicos[ib] - p
		var v: Vector2 = _logicos[ic] - p
		var d: Vector2 = alvo - p
		var det: float = u.cross(v)
		if absf(det) < 0.000001:
			continue
		var b: float = d.cross(v) / det
		var c: float = u.cross(d) / det
		var a: float = 1.0 - b - c
		if minf(a, minf(b, c)) >= -0.00001:
			return _visuais[ia] * a + _visuais[ib] * b + _visuais[ic] * c
	return alvo * LADO


func _ancorar(logico: Vector2, visual: Vector2) -> void:
	if not _logicos.has(logico):
		_logicos.append(logico)
		_visuais.append(visual)


static func _ponto_na_trilha(trilha: Array, fracao: float) -> Vector2:
	var extensoes: PackedFloat64Array = PackedFloat64Array()
	var comprimento: float = 0.0
	for i: int in range(trilha.size() - 1):
		var trecho: float = ponto(trilha[i]).distance_to(ponto(trilha[i + 1]))
		extensoes.append(trecho)
		comprimento += trecho
	var restante: float = comprimento * fracao
	for i: int in range(extensoes.size()):
		if restante <= extensoes[i] and extensoes[i] > 0.0:
			return ponto(trilha[i]).lerp(ponto(trilha[i + 1]), restante / extensoes[i])
		restante -= extensoes[i]
	return ponto(trilha[-1])


static func ponto(par: Array) -> Vector2:
	return Vector2(float(par[0]), float(par[1]))
