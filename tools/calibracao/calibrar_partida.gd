extends SceneTree
## Calibra o simulador de partidas contra as metas de ritmo (docs/GDD.md, seção 8).
##
## Uso (na raiz do projeto):
##   godot --headless --path . -s res://tools/calibracao/calibrar_partida.gd -- --partidas 400 --semente 7
##
## Cada time tem jogadores gerados com a qualidade pedida; cada um joga o campeão da sua posição
## que mais domina (como faria num draft sem disputa). Patch neutro.

const METAS: Dictionary = {
	"duracao_mediana": "≈ 32 min",
	"abates_medios": "≈ 33",
	"pct_virada_15": "≈ 33%",
	"forte_5": "≈ 63%", "forte_10": "≈ 73%", "forte_20": "≈ 90%",
	"ouro_suporte_atirador": "≈ 73%",
	"epicos": "3,5 a 3,9 de cada",
}

var _gerador: GeradorJogadores
var _por_posicao: Dictionary = {}


func _initialize() -> void:
	var args: Dictionary = _ler_argumentos()
	var partidas: int = int(args.get("partidas", 400))
	var semente: int = int(args.get("semente", 7))
	_gerador = GeradorJogadores.new(semente)
	for campeao: Dictionary in Dados.campeoes()["campeoes"]:
		var principal: String = str(campeao["posicoes"][0])
		if not _por_posicao.has(principal):
			_por_posicao[principal] = []
		_por_posicao[principal].append(campeao["id"])
	var inicio: int = Time.get_ticks_msec()
	var iguais: Array[Dictionary] = []
	for i: int in range(partidas):
		iguais.append(_jogar(50.0, 50.0, semente * 1000 + i))
	var m: Dictionary = _metricas(iguais)
	for diferenca: int in [5, 10, 20]:
		var vitorias: float = 0.0
		var n: int = maxi(150, partidas / 2)
		for i: int in range(n):
			# Alterna o lado do time mais forte para não misturar vantagem de lado.
			var forte_azul: bool = i % 2 == 0
			var qa: float = 50.0 + diferenca / 2.0 if forte_azul else 50.0 - diferenca / 2.0
			var r: Dictionary = _jogar(qa, 100.0 - qa, semente * 7919 + diferenca * 100003 + i)
			if (r["vencedor"] == 0) == forte_azul:
				vitorias += 1.0
		m["forte_%d" % diferenca] = 100.0 * vitorias / n
	_imprimir(m, partidas, Time.get_ticks_msec() - inicio)
	quit()


func _ler_argumentos() -> Dictionary:
	var lista: PackedStringArray = OS.get_cmdline_user_args()
	var args: Dictionary = {}
	var i: int = 0
	while i < lista.size():
		if lista[i].begins_with("--") and i + 1 < lista.size():
			args[lista[i].substr(2)] = lista[i + 1]
			i += 2
		else:
			i += 1
	return args


func _montar_time(qualidade: float, nome: String) -> Dictionary:
	var jogadores: Array = []
	for posicao: String in SimuladorPartida.POSICOES:
		var j: Jogador = _gerador.gerar({"qualidade": qualidade + _gerador.sortear_float(-5.0, 5.0), "posicao": posicao})
		var melhor: String = ""
		for id: String in _por_posicao.get(posicao, []):
			if melhor == "" or int(j.dominio_campeoes.get(id, 0)) > int(j.dominio_campeoes.get(melhor, 0)):
				melhor = id
		jogadores.append({"posicao": posicao, "jogador": j, "campeao": melhor})
	return {"nome": nome, "jogadores": jogadores}


func _jogar(qa: float, qb: float, semente: int) -> Dictionary:
	return SimuladorPartida.simular({
		"times": [_montar_time(qa, "Azul"), _montar_time(qb, "Vermelho")],
		"forcas_patch": {}, "semente": semente,
	})


func _metricas(partidas: Array[Dictionary]) -> Dictionary:
	var duracoes: Array[float] = []
	var abates: Array[float] = []
	var atras_15: int = 0
	var viradas: int = 0
	var razao_suporte: Array[float] = []
	var hydras: float = 0.0
	var cerberos: float = 0.0
	var vitorias_azul: int = 0
	for r: Dictionary in partidas:
		duracoes.append(r["duracao"] / 60.0)
		abates.append(float(r["placar"]["abates"][0] + r["placar"]["abates"][1]))
		hydras += float(r["placar"]["hydra"][0] + r["placar"]["hydra"][1])
		cerberos += float(r["placar"]["cerbero"][0] + r["placar"]["cerbero"][1])
		if r["vencedor"] == 0:
			vitorias_azul += 1
		for q: Dictionary in r["quadros"]:
			if int(q["t"]) >= 15 * 60:
				var dif: int = int(q["ouro"][0]) - int(q["ouro"][1])
				if absi(dif) >= 2500:
					atras_15 += 1
					if r["vencedor"] == (1 if dif > 0 else 0):
						viradas += 1
				break
		var ouro_pos: Dictionary = {}
		for j: Dictionary in r["jogadores"]:
			ouro_pos["%d_%s" % [j["time"], j["posicao"]]] = float(j["ouro"])
		for time: int in [0, 1]:
			razao_suporte.append(ouro_pos["%d_suporte" % time] / ouro_pos["%d_atirador" % time])
	duracoes.sort()
	var n: float = partidas.size()
	return {
		"duracao_mediana": duracoes[duracoes.size() / 2],
		"duracao_p10": duracoes[duracoes.size() / 10],
		"duracao_p90": duracoes[duracoes.size() * 9 / 10],
		"abates_medios": _media(abates),
		"pct_virada_15": 100.0 * viradas / atras_15 if atras_15 > 0 else 0.0,
		"ouro_suporte_atirador": 100.0 * _media(razao_suporte),
		"hydra": hydras / n, "cerbero": cerberos / n,
		"vitorias_azul": 100.0 * vitorias_azul / n,
	}


func _media(lista: Array[float]) -> float:
	var soma: float = 0.0
	for v: float in lista:
		soma += v
	return soma / maxf(1.0, lista.size())


func _imprimir(m: Dictionary, partidas: int, ms: int) -> void:
	print("=== Simulador de partidas: %d partidas entre times iguais (%.1f s) ===" % [partidas, ms / 1000.0])
	print("duração: mediana %.1f min (p10 %.1f, p90 %.1f)   meta %s" % [m["duracao_mediana"], m["duracao_p10"], m["duracao_p90"], METAS["duracao_mediana"]])
	print("abates por partida: %.1f   meta %s" % [m["abates_medios"], METAS["abates_medios"]])
	print("time atrás 2.500+ aos 15 min vence: %.1f%%   meta %s" % [m["pct_virada_15"], METAS["pct_virada_15"]])
	print("ouro do suporte / atirador: %.0f%%   meta %s" % [m["ouro_suporte_atirador"], METAS["ouro_suporte_atirador"]])
	print("Hydra %.2f, Cérbero %.2f por partida   meta %s" % [m["hydra"], m["cerbero"], METAS["epicos"]])
	print("vitórias do lado azul: %.1f%% (deve ficar perto de 50%%)" % m["vitorias_azul"])
	for d: int in [5, 10, 20]:
		print("time mais forte por %d pontos vence: %.0f%%   meta %s" % [d, m["forte_%d" % d], METAS["forte_%d" % d]])
