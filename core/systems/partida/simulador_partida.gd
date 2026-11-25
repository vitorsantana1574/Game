class_name SimuladorPartida
extends RefCounted
## Simulação de uma partida de Crystal Legends (etapa 5).
##
## A partida é simulada inteira antes de ser mostrada. O resultado é uma linha do tempo:
## lances (com narração), quadros com a posição de cada campeão e a estatística final.
## Mesma semente = mesma partida.
##
## Modelo (herdado do protótipo tools/prototipos/ritmo_partida.py, que calibrou o ritmo):
## - passos de 5 s; ondas dão XP e ouro conforme o Farm; o caçador limpa a selva;
## - força de cada campeão = habilidade do jogador × nível × itens × curva do campeão × patch × adequação à posição;
## - habilidade efetiva: o domínio do campeão pesa forte no Micro, de leve no Farm e nada no Macro;
## - fase de rotas (trocas, ganks), depois lutas em equipe nos objetivos e conversão em torres, Guardião e Cristal.
##
## Sobre o nível: a curva do campeão é RELATIVA (quem é mais forte que a média em cada momento).
## O ganho absoluto por nível (7,5%) vem só de "forca_por_nivel", que o laboratório confirmou (+6 a 8%).
## Assim o nível não é contado duas vezes.

const POSICOES: Array[String] = ["topo", "selva", "meio", "atirador", "suporte"]
const ROTAS: Array[String] = ["topo", "meio", "baixo"]
const ROTA_DE: Dictionary = {"topo": "topo", "meio": "meio", "atirador": "baixo", "suporte": "baixo", "selva": ""}
const LADOS: Array[String] = ["azul", "vermelho"]
## Tipos de lance que sempre entram nos melhores momentos; os demais decidem caso a caso ("destaque").
const SEMPRE_DESTAQUE: Array[String] = ["inicio", "hydra", "cerbero", "guardiao", "guardiao_renasce", "vitoria"]


class Participante:
	var time: int
	var posicao: String
	var jogador_id: String
	var apelido: String
	var campeao_id: String
	var campeao_nome: String
	var farm: float
	var micro: float
	var macro: float
	var mental: float
	var curva: Dictionary
	var forca_patch: float = 1.0
	var adequacao: float = 1.0
	var nivel_dominio: String = "conhece_bem"
	var build: Array = []
	var xp: float = 0.0
	var ouro_total: float = 500.0
	var morto_ate: float = 0.0
	var abates_seguidos: int = 0
	var abates: int = 0
	var mortes: int = 0
	var assistencias: int = 0
	var cs: float = 0.0
	var itens: int = 0
	var comentario_dominio: bool = false
	var posicao_temporaria: Dictionary = {}

	func vivo(t: float) -> bool:
		return t >= morto_ate


var cfg: Dictionary
var sim: Dictionary
var mapa: Dictionary
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var narracao: Narracao
var t: float = 0.0
var participantes: Array[Participante] = []
var _times: Array = [[] as Array[Participante], [] as Array[Participante]]
var nomes_times: Array[String] = ["", ""]
var macro_tecnico: Array[float] = [-1.0, -1.0]
var vencedor: int = -1
var semente: int = 0

# Estado do mapa
var torres: Array = []                 # [time][rota] = [vida 1ª, 2ª, 3ª]
var guardiao_vivo: Array[bool] = [true, true]
var guardiao_renasce: Array[float] = [0.0, 0.0]
var guardiao_vida: Array[float] = [100.0, 100.0]
var cristal: Array[float] = [100.0, 100.0]
var bonus_hydra: Array[float] = [0.0, 0.0]
var bonus_cerbero: Array[float] = [0.0, 0.0]
var hydra_disponivel_em: float = 0.0
var cerbero_disponivel_em: float = 0.0
var xp_onda: float
var ouro_onda: float
var _xp_acumulada: Array[float] = []   # XP total para chegar a cada nível (índice = nível)
var _taxa_selva_cache: Dictionary = {}

# Linha do tempo
var eventos: Array[Dictionary] = []
var quadros: Array[Dictionary] = []
var _primeiro_abate: bool = false
var _primeira_torre: bool = false
var _comentarios_ouro: int = 0
var _comentario_farm_feito: Dictionary = {}
var _maior_desvantagem: Array[float] = [0.0, 0.0]   # maior diferença de ouro contra cada time
var _foco: Array = [Vector2(0.5, 0.5), Vector2(0.5, 0.5)]
var _contagem: Dictionary = {"abates": [0, 0], "torres": [0, 0], "hydra": [0, 0], "cerbero": [0, 0]}


## Simula uma partida.
## entrada = {
##   "times": [ {"nome": String, "macro_tecnico": int (opcional), "jogadores": [{"posicao", "jogador": Jogador, "campeao": id}]} ×2 ],
##       o índice 0 é o time azul e o 1, o vermelho;
##   "forcas_patch": {id: multiplicador}, "semente": int
## }
static func simular(entrada: Dictionary) -> Dictionary:
	var s: SimuladorPartida = SimuladorPartida.new()
	s._preparar(entrada)
	s._jogar()
	return s._resultado()


func _preparar(entrada: Dictionary) -> void:
	cfg = Dados.partida()
	sim = cfg["simulacao"]
	mapa = Dados.mapa()
	semente = int(entrada.get("semente", 0))
	rng.seed = semente
	narracao = Narracao.new(int(entrada.get("semente", 0)) + 1)
	var curvas: Dictionary = Dados.curvas_de_forca().get("campeoes", {})
	var forcas: Dictionary = entrada.get("forcas_patch", {})
	for indice: int in range(2):
		var time: Dictionary = entrada["times"][indice]
		nomes_times[indice] = str(time.get("nome", LADOS[indice]))
		macro_tecnico[indice] = float(time.get("macro_tecnico", -1))
		torres.append({"topo": [100.0, 120.0, 150.0], "meio": [100.0, 120.0, 150.0], "baixo": [100.0, 120.0, 150.0]})
		for item: Dictionary in time["jogadores"]:
			var novo: Participante = _criar_participante(indice, item, curvas, forcas)
			participantes.append(novo)
			_times[indice].append(novo)
	for nivel: int in range(int(cfg["niveis"]["maximo"]) + 2):
		_xp_acumulada.append(_xp_para_nivel(nivel))
	var onda: Vector2 = _xp_e_ouro_por_onda()
	xp_onda = onda.x
	ouro_onda = onda.y
	var prog: Dictionary = _progressao_solo()
	var epicos: Dictionary = cfg["monstros_epicos"]
	cerbero_disponivel_em = float(prog[int(epicos["cerbero"]["aparece_no_nivel_teorico"])])
	hydra_disponivel_em = float(prog[int(epicos["hydra"]["aparece_no_nivel_teorico"])])


func _criar_participante(time: int, item: Dictionary, curvas: Dictionary, forcas: Dictionary) -> Participante:
	var j: Jogador = item["jogador"]
	var p: Participante = Participante.new()
	p.time = time
	p.posicao = str(item["posicao"])
	p.jogador_id = j.id
	p.apelido = j.apelido
	p.campeao_id = str(item["campeao"])
	var ficha: Dictionary = Dados.por_id(Dados.campeoes()["campeoes"], p.campeao_id)
	p.campeao_nome = str(ficha.get("nome", p.campeao_id))
	p.build = ficha.get("build_ids", [])
	p.curva = curvas.get(p.campeao_id, {"inicio": 0.5, "meio": 0.5, "fim": 0.5})
	p.forca_patch = float(forcas.get(p.campeao_id, 1.0))
	p.adequacao = DominioCampeoes.adequacao(p.campeao_id, p.posicao)
	var nivel: Dictionary = DominioCampeoes.nivel(int(j.dominio_campeoes.get(p.campeao_id, 0)))
	p.nivel_dominio = nivel["id"]
	var rendimento: float = float(nivel["rendimento"])
	# Forma do dia: o Mental deixa o jogador mais constante.
	var desvio: float = float(sim["forma_desvio_base"]) + float(sim["forma_desvio_mental"]) * (1.0 - float(j.atributos.get("mental", 50)) / 100.0)
	var forma: float = clampf(1.0 + rng.randfn(0.0, desvio), 0.85, 1.15)
	var energia: float = SistemaEnergia.fator_rendimento(j.energia)
	p.micro = clampf(float(j.atributos.get("micro", 50)) * rendimento * forma * energia, 1.0, 110.0)
	p.farm = clampf(float(j.atributos.get("farm", 50)) * (1.0 - (1.0 - rendimento) * 0.5) * forma, 1.0, 110.0)
	p.macro = clampf(float(j.atributos.get("macro", 50)) * forma * energia, 1.0, 110.0)
	p.mental = float(j.atributos.get("mental", 50))
	return p


# --- Progressão teórica -----------------------------------------------------------

func _xp_para_nivel(nivel: int) -> float:
	var n: Dictionary = cfg["niveis"]
	var total: float = 0.0
	for alvo: int in range(2, nivel + 1):
		total += float(n["xp_para_nivel_2"]) + float(n["xp_incremento_por_nivel"]) * (alvo - 2)
	return total


func nivel_de(p: Participante) -> int:
	var nivel: int = 1
	var maximo: int = _xp_acumulada.size() - 2
	while nivel < maximo and p.xp >= _xp_acumulada[nivel + 1]:
		nivel += 1
	return nivel


func _xp_e_ouro_por_onda() -> Vector2:
	var o: Dictionary = cfg["ondas"]
	var xp: float = float(o["corpo_a_corpo"]) * float(o["xp"]["corpo_a_corpo"]) + float(o["a_distancia"]) * float(o["xp"]["a_distancia"])
	var ouro: float = float(o["corpo_a_corpo"]) * float(o["ouro"]["corpo_a_corpo"]) + float(o["a_distancia"]) * float(o["ouro"]["a_distancia"])
	xp += float(o["xp"]["cerco"]) / float(o["cerco_a_cada_ondas"])
	ouro += float(o["ouro"]["cerco"]) / float(o["cerco_a_cada_ondas"])
	return Vector2(xp, ouro)


func _taxa_selva(farm: float) -> Vector2:
	if _taxa_selva_cache.has(farm):
		return _taxa_selva_cache[farm]
	var taxa: Vector2 = _calcular_taxa_selva(farm)
	_taxa_selva_cache[farm] = taxa
	return taxa


func _calcular_taxa_selva(farm: float) -> Vector2:
	var acamps: Array = cfg["selva"]["acampamentos"]
	var fator: float = 1.35 - 0.7 * farm / 100.0
	var limpeza: float = 45.0
	var menor_reaparece: float = INF
	for a: Dictionary in acamps:
		limpeza += float(a["limpeza"]) * fator
		menor_reaparece = minf(menor_reaparece, float(a["reaparece"]))
	var ciclo: float = maxf(limpeza, menor_reaparece)
	var xp: float = 0.0
	var ouro: float = 0.0
	for a: Dictionary in acamps:
		var parte: float = minf(1.0, ciclo / float(a["reaparece"]))
		xp += float(a["xp"]) * parte
		ouro += float(a["ouro"]) * parte
	return Vector2(xp / ciclo, ouro / ciclo)


func _progressao_solo() -> Dictionary:
	var o: Dictionary = cfg["ondas"]
	var taxa: float = xp_onda / float(o["intervalo"])
	var tempos: Dictionary = {}
	for nivel: int in range(2, int(cfg["niveis"]["maximo"]) + 1):
		tempos[nivel] = float(o["primeira_chegada"]) + _xp_para_nivel(nivel) / taxa
	return tempos


func _renascimento(nivel: int) -> float:
	var r: Dictionary = cfg["renascimento"]
	var tempo: float = float(r["base"]) + float(r["por_nivel"]) * nivel
	var minuto: float = t / 60.0
	if minuto > float(r["inicio_acrescimo_tardio_min"]):
		tempo *= 1.0 + minf(float(r["acrescimo_tardio_maximo"]), (minuto - float(r["inicio_acrescimo_tardio_min"])) * float(r["acrescimo_tardio_por_min"]))
	return tempo


# --- Força -----------------------------------------------------------------------

## Os cinco campeões de um time (lista compartilhada: não alterar).
func time_de(indice: int) -> Array[Participante]:
	return _times[indice]


func _ouro_itens(p: Participante) -> float:
	var it: Dictionary = cfg["itens"]
	var teto: float = float(it["preco_bota"]) + float(it["preco_item_medio"]) * (int(it["maximo_por_campeao"]) - 1)
	return minf(p.ouro_total - 500.0, teto) if p.ouro_total > 500.0 else 0.0


## Força relativa do campeão no momento (curva do laboratório), pelo nível: 6 = início, 10 = meio, 16 = fim.
func _curva(p: Participante) -> float:
	var nivel: float = float(nivel_de(p))
	var wr: float
	if nivel <= 6.0:
		wr = float(p.curva["inicio"])
	elif nivel <= 10.0:
		wr = lerpf(float(p.curva["inicio"]), float(p.curva["meio"]), (nivel - 6.0) / 4.0)
	else:
		wr = lerpf(float(p.curva["meio"]), float(p.curva["fim"]), minf(1.0, (nivel - 10.0) / 6.0))
	return 1.0 + float(sim["peso_curva_campeao"]) * (wr - 0.5)


func poder(p: Participante) -> float:
	var habilidade: float = float(sim["habilidade_base"]) + float(sim["habilidade_peso"]) * (0.5 * p.micro + 0.3 * p.macro + 0.2 * p.farm) / 100.0
	var oc: Dictionary = cfg["itens"]["ordem_de_compra"]
	var eficiencia: float = 1.0 + float(oc["bonus_maximo_macro"]) * (p.macro - 50.0) / 50.0 + float(oc["bonus_maximo_micro_arriscado"]) * (p.micro - 50.0) / 50.0
	var valor: float = habilidade * (1.0 + float(sim["forca_por_nivel"]) * (nivel_de(p) - 1)) * (1.0 + eficiencia * _ouro_itens(p) / 5000.0)
	valor *= _curva(p) * p.forca_patch * p.adequacao
	if t < bonus_hydra[p.time]:
		valor *= 1.10
	return valor


func macro_do_time(indice: int) -> float:
	var soma: float = 0.0
	for p: Participante in time_de(indice):
		soma += p.macro
	var media: float = soma / 5.0
	return media * 0.8 + macro_tecnico[indice] * 0.2 if macro_tecnico[indice] >= 0.0 else media


func ouro_do_time(indice: int) -> float:
	var soma: float = 0.0
	for p: Participante in time_de(indice):
		soma += p.ouro_total
	return soma


func _fragilidade() -> float:
	var ft: Dictionary = cfg["fim_de_jogo"]
	var minuto: float = t / 60.0
	if minuto < float(ft["inicio_tensao_final_min"]):
		return 1.0
	return 1.0 + float(ft["fragilidade_por_min"]) * (minuto - float(ft["inicio_tensao_final_min"]))


# --- Abates ------------------------------------------------------------------------

## Abate. contexto: "solo", "gank", "dive" ou "luta".
## opcoes: "narrar" (bool, padrão true), "assistentes" (Array[Participante] que dividem a assistência),
## "cacador" (Participante que gankou, para a narração).
## Devolve o lance registrado, ou {} se a vítima já estava morta.
func matar(vitima: Participante, assassino: Participante, contexto: String, opcoes: Dictionary = {}) -> Dictionary:
	if not vitima.vivo(t):
		return {}
	var ab: Dictionary = cfg["abates"]
	var nivel_vitima: int = nivel_de(vitima)
	var sequencia_vitima: int = vitima.abates_seguidos
	var recompensa: float = minf(float(ab["recompensa_maxima"]), sequencia_vitima * float(ab["recompensa_por_abate_seguido"]))
	var local: Vector2 = posicao_de(vitima, true)
	vitima.morto_ate = t + _renascimento(nivel_vitima)
	vitima.mortes += 1
	vitima.abates_seguidos = 0
	vitima.posicao_temporaria = {}
	var ids_assistentes: Array[String] = []
	var assistentes: Array = opcoes.get("assistentes", []).filter(func(c: Participante) -> bool: return c != assassino and c.vivo(t))
	assassino.ouro_total += float(ab["ouro"]) + recompensa
	assassino.xp += float(ab["xp_base"]) + float(ab["xp_por_nivel_vitima"]) * nivel_vitima
	assassino.abates += 1
	assassino.abates_seguidos += 1
	_contagem["abates"][assassino.time] += 1
	for c: Participante in assistentes:
		c.ouro_total += float(ab["ouro_assistencia_total"]) / assistentes.size()
		c.assistencias += 1
		ids_assistentes.append(c.jogador_id)
		if c.posicao == "suporte":
			c.ouro_total += float(cfg["itens"]["item_de_suporte"]["ouro_por_participacao"])
	var lance: Dictionary = _registrar("abate", {
		"time": assassino.time, "jogador": assassino.jogador_id, "campeao": assassino.campeao_id,
		"alvo": vitima.jogador_id, "alvo_campeao": vitima.campeao_id,
		"assistencias": ids_assistentes, "contexto": contexto,
		"x": snappedf(local.x, 0.001), "y": snappedf(local.y, 0.001),
	})
	var era_primeiro: bool = not _primeiro_abate
	_primeiro_abate = true
	if not bool(opcoes.get("narrar", true)):
		return lance
	var valores: Dictionary = _valores(assassino, vitima, opcoes.get("cacador", null))
	var tipo: String = "abate"
	if era_primeiro:
		tipo = "primeiro_sangue"
	elif sequencia_vitima >= 3:
		tipo = "shutdown"
	elif contexto == "gank":
		tipo = "abate_gank"
	elif contexto == "dive":
		tipo = "abate_dive"
	elif contexto == "solo":
		tipo = "abate_solo"
	lance["narracao"] = narracao.narrar(tipo, valores)
	lance["destaque"] = tipo in ["primeiro_sangue", "shutdown"] or assassino.abates_seguidos in [3, 5]
	if assassino.abates_seguidos in [3, 5]:
		valores["quantidade"] = assassino.abates_seguidos
		lance["narracao"].append_array(narracao.narrar("sequencia", valores))
	_comentar_dominio(assassino, vitima, lance)
	return lance


func _comentar_dominio(assassino: Participante, vitima: Participante, lance: Dictionary) -> void:
	if t > 20 * 60:
		return
	if vitima.nivel_dominio == "nao_conhece" and vitima.mortes >= 2 and not vitima.comentario_dominio:
		vitima.comentario_dominio = true
		lance["narracao"].append_array(narracao.narrar("desconforto", _valores(vitima, null)))
	elif assassino.nivel_dominio == "favorito" and assassino.abates >= 2 and not assassino.comentario_dominio:
		assassino.comentario_dominio = true
		lance["narracao"].append_array(narracao.narrar("conforto", _valores(assassino, null)))


# --- Renda contínua ----------------------------------------------------------------

func _renda() -> void:
	var o: Dictionary = cfg["ondas"]
	if t < float(o["primeira_chegada"]):
		return
	var passo: float = float(sim["passo"])
	var fase_rotas: bool = t < float(sim["fim_fase_de_rotas_min"]) * 60.0
	var minions_por_s: float = (float(o["corpo_a_corpo"]) + float(o["a_distancia"]) + 1.0 / float(o["cerco_a_cada_ondas"])) / float(o["intervalo"])
	for c: Participante in participantes:
		if not c.vivo(t):
			continue
		c.ouro_total += float(cfg["ouro_passivo_por_segundo"]) * passo
		c.ouro_total += float(sim["renda_super_minions"]) * passo * _rotas_abertas(c.time).size()
		if c.posicao == "selva":
			var taxa: Vector2 = _taxa_selva(c.farm)
			var fator: float = 1.0 if fase_rotas else 0.8
			c.xp += taxa.x * passo * fator
			c.ouro_total += taxa.y * passo * fator
			c.cs += 0.12 * passo * fator * (0.6 + 0.4 * c.farm / 100.0)
			continue
		var presenca: float = 1.0 if fase_rotas else 0.7
		var eficiencia: float = 0.45 + 0.5 * c.farm / 100.0
		var oponente: Participante = _oponente_de_rota(c)
		if oponente != null and oponente.vivo(t):
			eficiencia *= 1.0 + 0.25 * tanh((c.micro - oponente.micro) / 25.0)
		else:
			eficiencia *= 1.1
		var xp_s: float = xp_onda / float(o["intervalo"])
		var ouro_s: float = ouro_onda / float(o["intervalo"])
		if c.posicao in ["atirador", "suporte"]:
			xp_s *= float(o["bonus_xp_rota_dupla"]) / 2.0
			if c.posicao == "atirador":
				ouro_s *= 0.9
			else:
				var atirador: Participante = _da_posicao(c.time, "atirador")
				var efic_atirador: float = minf(1.0, 0.45 + 0.5 * atirador.farm / 100.0)
				ouro_s *= 0.9 * efic_atirador * float(cfg["itens"]["item_de_suporte"]["fracao_ouro_do_atirador"]) if atirador.vivo(t) else 0.0
				eficiencia = 1.0
		c.xp += xp_s * passo * presenca
		c.ouro_total += ouro_s * passo * presenca * minf(1.0, eficiencia)
		# O suporte só pega o farm que sobra (minion que o atirador não alcança).
		var parte_cs: float = 0.12 if c.posicao == "suporte" else 1.0
		c.cs += minions_por_s * passo * presenca * minf(1.0, eficiencia) * parte_cs
		_compras(c)


func _compras(c: Participante) -> void:
	var it: Dictionary = cfg["itens"]
	var gasto: float = _ouro_itens(c)
	var completos: int = 0
	if gasto >= float(it["preco_bota"]):
		completos = 1 + int((gasto - float(it["preco_bota"])) / float(it["preco_item_medio"]))
	completos = mini(completos, mini(int(it["maximo_por_campeao"]), c.build.size()))
	while c.itens < completos:
		_registrar("item", {"time": c.time, "jogador": c.jogador_id, "campeao": c.campeao_id, "item": c.build[c.itens]})
		c.itens += 1


func _oponente_de_rota(c: Participante) -> Participante:
	if ROTA_DE[c.posicao] == "":
		return null
	return _da_posicao(1 - c.time, c.posicao)


func _da_posicao(time: int, posicao: String) -> Participante:
	for p: Participante in participantes:
		if p.time == time and p.posicao == posicao:
			return p
	return null


# --- Fase de rotas -------------------------------------------------------------------

func _sig(x: float) -> float:
	return 1.0 / (1.0 + exp(-x))


func _trocas_de_rota() -> void:
	var passo: float = float(sim["passo"])
	for c: Participante in time_de(0):
		if c.posicao in ["selva", "suporte"]:
			continue
		var inimigo: Participante = _oponente_de_rota(c)
		if not (c.vivo(t) and inimigo.vivo(t)):
			continue
		if rng.randf() < passo / float(sim["troca_rota_a_cada"]):
			var p_a: float = _sig((poder(c) * (0.6 + c.micro / 250.0) - poder(inimigo) * (0.6 + inimigo.micro / 250.0)) * 6.0)
			var vence: Participante = c if rng.randf() < p_a else inimigo
			var perde: Participante = inimigo if vence == c else c
			# Abate sob a torre de quem perdeu, quando quem venceu está bem à frente: dive.
			var contexto: String = "dive" if poder(vence) > poder(perde) * 1.18 and rng.randf() < 0.35 else "solo"
			var ajuda: Array = []
			if contexto == "dive":
				var cacador_d: Participante = _da_posicao(vence.time, "selva")
				if rng.randf() < 0.5:
					ajuda.append(cacador_d)
			if vence.posicao == "atirador" and rng.randf() < 0.7:
				ajuda.append(_da_posicao(vence.time, "suporte"))
			matar(perde, vence, contexto, {"assistentes": ajuda})


func _ganks() -> void:
	var passo: float = float(sim["passo"])
	for time: int in [0, 1]:
		var cacador: Participante = _da_posicao(time, "selva")
		if not cacador.vivo(t) or t < 150.0 or t > float(sim["ganks_ate_min"]) * 60.0:
			continue
		if rng.randf() > passo / (float(sim["gank_base"]) - cacador.macro):
			continue
		var alvos: Array[Participante] = time_de(1 - time).filter(func(c: Participante) -> bool: return c.posicao != "selva" and c.vivo(t))
		if alvos.is_empty():
			continue
		var alvo: Participante = alvos[rng.randi() % alvos.size()]
		var aliado: Participante = _da_posicao(time, alvo.posicao)
		var suporte_inimigo: Participante = _da_posicao(1 - time, "suporte")
		var visao: float = (suporte_inimigo.macro - cacador.macro) / 100.0
		var forca: float = poder(cacador) + (poder(aliado) if aliado and aliado.vivo(t) else 0.0)
		var chance: float = _sig(1.0 + (forca - poder(alvo) * 1.6) * 2.5 + (cacador.micro - alvo.micro) / 40.0 - visao * 2.0)
		cacador.posicao_temporaria = {"ponto": posicao_de(alvo), "ate": t + 15.0}
		if rng.randf() < chance:
			var autor: Participante = cacador if rng.randf() < 0.4 or aliado == null or not aliado.vivo(t) else aliado
			var ajuda: Array = [cacador, aliado]
			if alvo.posicao in ["atirador", "suporte"]:
				ajuda.append(_da_posicao(time, "suporte" if alvo.posicao == "atirador" else "atirador"))
			matar(alvo, autor, "gank", {"assistentes": ajuda, "cacador": cacador})
		elif rng.randf() < 0.35:
			var primeiro: bool = not _primeiro_abate
			var lance_virado: Dictionary = matar(cacador, alvo, "solo", {"narrar": false})
			if not lance_virado.is_empty():
				lance_virado["narracao"] = narracao.narrar("primeiro_sangue" if primeiro else "gank_virado", _valores(alvo, cacador))
				lance_virado["destaque"] = true
		elif rng.randf() < 0.5:
			var ponto_g: Vector2 = posicao_de(alvo)
			_registrar("gank_falhou", {"time": time, "jogador": cacador.jogador_id, "alvo": alvo.jogador_id,
				"x": snappedf(ponto_g.x, 0.001), "y": snappedf(ponto_g.y, 0.001),
				"narracao": narracao.narrar("gank_falhou", _valores(cacador, alvo, cacador))})


# --- Estruturas ------------------------------------------------------------------------

func _proxima_torre(defensor: int, rota: String) -> int:
	var lista: Array = torres[defensor][rota]
	for i: int in range(lista.size()):
		if float(lista[i]) > 0.0:
			return i
	return -1


func _rotas_abertas(defensor: int) -> Array[String]:
	var lista: Array[String] = []
	for rota: String in ROTAS:
		if _proxima_torre(defensor, rota) == -1:
			lista.append(rota)
	return lista


func _pressao_torres() -> void:
	if t < float(cfg["ondas"]["primeira_chegada"]) + 30.0:
		return
	var passo: float = float(sim["passo"])
	for atacante: int in [0, 1]:
		var defensor: int = 1 - atacante
		for rota: String in ROTAS:
			var i: int = _proxima_torre(defensor, rota)
			if i == -1:
				continue
			var meus: Array[Participante] = time_de(atacante).filter(func(c: Participante) -> bool: return ROTA_DE[c.posicao] == rota and c.vivo(t))
			var deles: Array[Participante] = time_de(defensor).filter(func(c: Participante) -> bool: return ROTA_DE[c.posicao] == rota and c.vivo(t))
			if t > float(sim["fim_fase_de_rotas_min"]) * 60.0:
				meus = meus.slice(0, 1)
				deles = deles.slice(0, 1)
			var vantagem: float = 0.0
			for c: Participante in meus:
				vantagem += poder(c)
			for c: Participante in deles:
				vantagem -= poder(c)
			var dano: float = 0.10 + maxf(0.0, vantagem) * 0.9
			if deles.is_empty() and not meus.is_empty():
				dano += 1.0
			if t < float(cfg["torres"]["defesa_inicial_min"]) * 60.0:
				dano *= 0.4
			if t < bonus_cerbero[atacante]:
				dano *= 2.0
			torres[defensor][rota][i] = float(torres[defensor][rota][i]) - dano * passo * float(sim["dano_torre_rota"]) * _fragilidade()
			if float(torres[defensor][rota][i]) <= 0.0:
				_derrubar_torre(atacante, rota, i, meus[0] if not meus.is_empty() else null)


func _derrubar_torre(atacante: int, rota: String, indice: int, autor: Participante) -> void:
	var defensor: int = 1 - atacante
	torres[defensor][rota][indice] = 0.0
	for c: Participante in time_de(atacante):
		c.ouro_total += float(cfg["torres"]["ouro_time"]) / 5.0
	if autor != null:
		autor.ouro_total += float(cfg["torres"]["ouro_quem_destroi"])
	_contagem["torres"][atacante] += 1
	var ponto: Vector2 = _ponto_da_torre(defensor, rota, indice)
	var tipo: String = "torre"
	if not _primeira_torre:
		tipo = "primeira_torre"
	elif indice == 2:
		tipo = "base_aberta"
	elif t < bonus_cerbero[atacante]:
		tipo = "torre_cerbero"
	_primeira_torre = true
	var valores: Dictionary = _valores_time(atacante)
	valores.merge(_valores_rota(rota))
	_registrar("torre", {"time": atacante, "rota": rota, "torre": indice, "x": ponto.x, "y": ponto.y,
		"destaque": tipo in ["primeira_torre", "base_aberta"],
		"jogador": autor.jogador_id if autor else "", "narracao": narracao.narrar(tipo, valores)})


# --- Lutas em equipe ---------------------------------------------------------------------

## Luta em equipe num ponto do mapa. objetivo: "", "hydra" ou "cerbero". Devolve o time vencedor ou -1.
func _luta(objetivo: String) -> int:
	var vivos: Array = [time_de(0).filter(func(c: Participante) -> bool: return c.vivo(t)),
		time_de(1).filter(func(c: Participante) -> bool: return c.vivo(t))]
	if vivos[0].size() < 2 or vivos[1].size() < 2:
		return -1
	var ouro_antes: Array[float] = [ouro_do_time(0), ouro_do_time(1)]
	var forca: Array[float] = []
	for n: int in [0, 1]:
		var f: float = 0.0
		for c: Participante in vivos[n]:
			f += poder(c)
		f *= 1.0 + (macro_do_time(n) - 50.0) / 400.0
		if ouro_antes[n] < ouro_antes[1 - n] - 2000.0:
			var mental: float = 0.0
			for c: Participante in time_de(n):
				mental += c.mental / 5.0
			f *= 0.94 + 0.06 * mental / 100.0
		if not _rotas_abertas(n).is_empty():
			f *= float(sim["defesa_base"])
		forca.append(f)
	var p_a: float = _sig(float(sim["luta_sensibilidade"]) * log(forca[0] / forca[1]))
	var venc: int = 0 if rng.randf() < p_a else 1
	var perd: int = 1 - venc
	var margem: float = absf(p_a - 0.5) * 2.0
	var ponto: Vector2 = _ponto_objetivo(objetivo) if objetivo != "" else _foco[venc].lerp(_foco[perd], 0.5)
	for c: Participante in vivos[0] + vivos[1]:
		c.posicao_temporaria = {"ponto": ponto + Vector2(rng.randf_range(-0.03, 0.03), rng.randf_range(-0.03, 0.03)), "ate": t + 12.0}
	var mortes_perd: int = mini(vivos[perd].size(), 1 + int(rng.randf() * 2.0 + margem * 1.5))
	var mortes_venc: int = mini(vivos[venc].size() - 1, int(rng.randf() * 1.6 * (1.0 - margem)))
	# O resumo da luta entra na linha do tempo antes dos abates que ela contém.
	var lance_luta: Dictionary = _registrar("luta", {"time": venc, "x": snappedf(ponto.x, 0.001), "y": snappedf(ponto.y, 0.001), "objetivo": objetivo})
	var primeiro: bool = not _primeiro_abate
	var abates_por: Dictionary = {}
	var lances: Array[int] = []
	var vitimas_perd: Array = vivos[perd].duplicate()
	_embaralhar(vitimas_perd)
	var primeiro_lance: Dictionary = {}
	for vitima: Participante in vitimas_perd.slice(0, mortes_perd):
		var autor: Participante = vivos[venc][rng.randi() % vivos[venc].size()]
		var lance: Dictionary = matar(vitima, autor, "luta", {"narrar": false, "assistentes": _ajudantes(vivos[venc], autor)})
		if not lance.is_empty():
			lances.append(int(lance["indice"]))
			abates_por[autor] = int(abates_por.get(autor, 0)) + 1
			if primeiro_lance.is_empty():
				primeiro_lance = {"autor": autor, "vitima": vitima}
	var vitimas_venc: Array = vivos[venc].duplicate()
	_embaralhar(vitimas_venc)
	for vitima: Participante in vitimas_venc.slice(0, mortes_venc):
		var autor_p: Participante = vivos[perd][rng.randi() % vivos[perd].size()]
		var lance_p: Dictionary = matar(vitima, autor_p, "luta", {"narrar": false, "assistentes": _ajudantes(vivos[perd], autor_p)})
		if not lance_p.is_empty():
			lances.append(int(lance_p["indice"]))
	# Narração: o tipo depende do tamanho da briga e de onde foi.
	var valores: Dictionary = _valores_time(venc)
	valores["quantidade"] = mortes_perd
	valores["abates_texto"] = "1 abate" if mortes_perd == 1 else "%d abates" % mortes_perd
	valores["local"] = _descrever_local(ponto)
	var falas: Array[Dictionary] = []
	if primeiro and not primeiro_lance.is_empty():
		falas.append_array(narracao.narrar("primeiro_sangue", _valores(primeiro_lance["autor"], primeiro_lance["vitima"])))
	if mortes_perd + mortes_venc <= 2 and objetivo == "":
		falas.append_array(narracao.narrar("escaramuca", valores))
	elif mortes_perd > mortes_venc:
		if objetivo != "":
			valores["pelo_objetivo"] = "pela Hydra" if objetivo == "hydra" else "pelo Cérbero"
		falas.append_array(narracao.narrar("teamfight", valores, "narrador_objetivo" if objetivo != "" else ""))
	else:
		falas.append_array(narracao.narrar("teamfight_equilibrada", valores))
	var destaque: Participante = null
	for autor_d: Participante in abates_por:
		if destaque == null or int(abates_por[autor_d]) > int(abates_por[destaque]):
			destaque = autor_d
	if destaque != null and int(abates_por[destaque]) >= 2:
		falas.append_array(narracao.narrar("multiabate", _valores(destaque, null), "narrador_%d" % mini(5, int(abates_por[destaque]))))
	if time_de(perd).all(func(c: Participante) -> bool: return not c.vivo(t)):
		falas.append_array(narracao.narrar("ace", valores))
	var diferenca: float = ouro_antes[perd] - ouro_antes[venc]
	if diferenca >= 3000.0 and mortes_perd >= 3:
		var v: Dictionary = _valores_time(venc)
		v["ouro"] = _formatar_ouro(diferenca)
		falas.append_array(narracao.narrar("reacao", v))
	lance_luta["abates"] = [mortes_perd, mortes_venc] if venc == 0 else [mortes_venc, mortes_perd]
	lance_luta["lances"] = lances
	lance_luta["narracao"] = falas
	lance_luta["destaque"] = mortes_perd + mortes_venc >= 3 or objetivo != "" or primeiro
	return venc


## Quem ganha assistência num abate de luta: de um a três aliados que estavam na briga.
func _ajudantes(aliados: Array, autor: Participante) -> Array:
	var lista: Array = aliados.filter(func(c: Participante) -> bool: return c != autor)
	_embaralhar(lista)
	return lista.slice(0, mini(lista.size(), 1 + rng.randi() % 3))


## Onde foi a briga, em palavras: "no rio", "no meio", "no topo", "na rota de baixo" ou "na selva".
## O meio segue a diagonal x + y = 1; o rio cruza o mapa na diagonal x = y (ver data/config/mapa.json).
func _descrever_local(ponto: Vector2) -> String:
	if absf(ponto.x + ponto.y - 1.0) < 0.08:
		return mapa["nomes_rotas"]["meio"]["na"]
	if absf(ponto.x - ponto.y) < 0.08:
		return "no rio"
	if ponto.x < 0.15 or ponto.y < 0.15:
		return mapa["nomes_rotas"]["topo"]["na"]
	if ponto.x > 0.85 or ponto.y > 0.85:
		return mapa["nomes_rotas"]["baixo"]["na"]
	return "na selva"


func _converter_vantagem(venc: int) -> void:
	var perd: int = 1 - venc
	var vivos_v: Array[Participante] = time_de(venc).filter(func(c: Participante) -> bool: return c.vivo(t))
	var mortos_p: Array[Participante] = time_de(perd).filter(func(c: Participante) -> bool: return not c.vivo(t))
	if vivos_v.size() < 3 or mortos_p.size() < 2:
		return
	var restantes: Array[float] = []
	for c: Participante in mortos_p:
		restantes.append(c.morto_ate - t)
	restantes.sort()
	var janela: float = restantes[restantes.size() / 2]
	if t >= hydra_disponivel_em:
		_pegar_objetivo("hydra", venc, "pos_luta")
		janela -= 25.0
	elif t >= cerbero_disponivel_em:
		_pegar_objetivo("cerbero", venc, "pos_luta")
		janela -= 20.0
	var poder_cerco: float = vivos_v.size() * (2.0 if t < bonus_cerbero[venc] else 1.0) * _fragilidade()
	if t < bonus_hydra[venc]:
		poder_cerco *= 1.3
	while janela > 0.0 and vencedor == -1:
		var abertas: Array[String] = _rotas_abertas(perd)
		if abertas.is_empty():
			var rota: String = ROTAS[0]
			var menor: float = INF
			for r: String in ROTAS:
				var soma: float = 0.0
				for v: Variant in torres[perd][r]:
					soma += float(v)
				if soma < menor:
					menor = soma
					rota = r
			var i: int = _proxima_torre(perd, rota)
			var custo: float = float(torres[perd][rota][i]) / (poder_cerco * float(sim["cerco_torre"]))
			if custo > janela:
				torres[perd][rota][i] = float(torres[perd][rota][i]) - janela * poder_cerco * float(sim["cerco_torre"])
				break
			janela -= custo
			_derrubar_torre(venc, rota, i, vivos_v[0])
			continue
		if guardiao_vivo[perd]:
			var custo_g: float = guardiao_vida[perd] / (poder_cerco * float(sim["cerco_guardiao"]))
			if custo_g > janela:
				guardiao_vida[perd] -= janela * poder_cerco * float(sim["cerco_guardiao"])
				break
			janela -= custo_g
			guardiao_vivo[perd] = false
			guardiao_vida[perd] = 0.0
			guardiao_renasce[perd] = t + float(cfg["guardiao"]["renasce"])
			var pg: Array = mapa["bases"][LADOS[perd]]["guardiao"]
			_registrar("guardiao", {"time": venc, "x": pg[0], "y": pg[1], "narracao": narracao.narrar("guardiao", _valores_time(venc))})
			continue
		var custo_c: float = cristal[perd] / (poder_cerco * float(sim["cerco_cristal"]))
		if custo_c > janela:
			cristal[perd] -= janela * poder_cerco * float(sim["cerco_cristal"])
			break
		cristal[perd] = 0.0
		vencedor = venc
		return


## modo: "pos_luta" (depois de vencer uma luta), "sem_luta" (ninguém contestou) ou "roubo".
func _pegar_objetivo(tipo: String, time: int, modo: String, ladrao: Participante = null) -> void:
	var epicos: Dictionary = cfg["monstros_epicos"]
	if tipo == "hydra":
		bonus_hydra[time] = t + float(epicos["hydra"]["duracao_bonus"])
		hydra_disponivel_em = t + float(epicos["hydra"]["reaparece"])
	else:
		bonus_cerbero[time] = t + float(epicos["cerbero"]["duracao_bonus"])
		cerbero_disponivel_em = t + float(epicos["cerbero"]["reaparece"])
	for c: Participante in time_de(time):
		c.ouro_total += float(epicos[tipo]["ouro_time"]) / 5.0
	_contagem[tipo][time] += 1
	var ponto: Vector2 = _ponto_objetivo(tipo)
	var valores: Dictionary = _valores_time(time)
	valores["objetivo"] = "a Hydra" if tipo == "hydra" else "o Cérbero"
	var falas: Array[Dictionary]
	if modo == "roubo" and ladrao != null:
		valores["cacador"] = ladrao.apelido
		falas = narracao.narrar("roubo_objetivo", valores)
	else:
		falas = narracao.narrar(tipo, valores, "narrador_sem_luta" if modo == "sem_luta" else "", modo)
	_registrar(tipo, {"time": time, "x": ponto.x, "y": ponto.y, "roubado": modo == "roubo",
		"jogador": ladrao.jogador_id if ladrao else "", "narracao": falas})


func _objetivo_sem_luta() -> void:
	var leitura: Array[float] = [macro_do_time(0) + rng.randfn(0.0, 15.0), macro_do_time(1) + rng.randfn(0.0, 15.0)]
	var time: int = 0 if leitura[0] > leitura[1] else 1
	if t >= hydra_disponivel_em:
		_pegar_objetivo("hydra", time, "sem_luta")
	elif t >= cerbero_disponivel_em:
		_pegar_objetivo("cerbero", time, "sem_luta")


## Na disputa de um objetivo, o caçador de quem perdeu a luta pode roubar o último golpe:
## chegar a tempo é Macro do time; acertar é a diferença de Micro entre os caçadores.
func _tentar_roubo(objetivo: String, venc: int) -> bool:
	var ladrao: Participante = _da_posicao(1 - venc, "selva")
	var dono: Participante = _da_posicao(venc, "selva")
	if not ladrao.vivo(t):
		return false
	var chegou: float = _sig((macro_do_time(1 - venc) - macro_do_time(venc)) / 15.0)
	var acerto: float = float(sim["chance_roubo_base"]) * (1.0 + (ladrao.micro - (dono.micro if dono.vivo(t) else 30.0)) / 50.0)
	if rng.randf() < chegou * clampf(acerto, 0.02, 0.4):
		_pegar_objetivo(objetivo, 1 - venc, "roubo", ladrao)
		return true
	return false


func _guardioes_renascem() -> void:
	for n: int in [0, 1]:
		if not guardiao_vivo[n] and t >= guardiao_renasce[n]:
			guardiao_vivo[n] = true
			guardiao_vida[n] = 100.0
			var pg: Array = mapa["bases"][LADOS[n]]["guardiao"]
			_registrar("guardiao_renasce", {"time": n, "x": pg[0], "y": pg[1], "narracao": narracao.narrar("guardiao_renasce", _valores_time(n))})
		cristal[n] = minf(100.0, cristal[n] + 0.02 * float(sim["passo"]))


# --- Comentários de análise -----------------------------------------------------------

func _comentarios_periodicos() -> void:
	var minuto: int = int(t / 60.0)
	if int(t) % 300 == 0 and minuto >= 10 and _comentarios_ouro < 4:
		var dif: float = ouro_do_time(0) - ouro_do_time(1)
		if absf(dif) >= 2500.0:
			var lider: int = 0 if dif > 0 else 1
			var v: Dictionary = _valores_time(lider)
			v["ouro"] = _formatar_ouro(absf(dif))
			_comentarios_ouro += 1
			_registrar("analise", {"time": lider, "assunto": "ouro", "narracao": narracao.narrar("vantagem_ouro", v)})
	for marco: int in [10, 15]:
		if minuto == marco and not _comentario_farm_feito.has(marco) and int(t) % 60 == 0:
			_comentario_farm_feito[marco] = true
			var melhor: Participante = null
			var maior: float = 0.0
			for c: Participante in time_de(0):
				var o: Participante = _oponente_de_rota(c)
				if o == null or c.posicao == "suporte":
					continue
				if absf(c.cs - o.cs) > maior:
					maior = absf(c.cs - o.cs)
					melhor = c if c.cs > o.cs else o
			if melhor != null and maior >= 25.0:
				var v2: Dictionary = _valores(melhor, _oponente_de_rota(melhor))
				v2["quantidade"] = roundi(maior)
				_registrar("analise", {"time": melhor.time, "assunto": "farm", "jogador": melhor.jogador_id, "narracao": narracao.narrar("farm", v2)})


# --- Laço principal ------------------------------------------------------------------------

func _jogar() -> void:
	var limite: float = float(cfg["fim_de_jogo"]["limite_pratico_min"]) * 60.0
	var passo: float = float(sim["passo"])
	var fim_rotas: float = float(sim["fim_fase_de_rotas_min"]) * 60.0
	var proxima_luta: float = fim_rotas + rng.randf_range(0.0, 90.0)
	_registrar("inicio", _lance_inicio())
	_quadro()
	while t < limite and vencedor == -1:
		t += passo
		_renda()
		_guardioes_renascem()
		if t < fim_rotas:
			_trocas_de_rota()
		_ganks()
		_pressao_torres()
		_atualizar_foco()
		var objetivo_pronto: bool = t >= cerbero_disponivel_em or t >= hydra_disponivel_em
		var disputa: bool = objetivo_pronto and rng.randf() < passo / float(sim["espera_luta_objetivo"])
		if disputa and rng.randf() > float(sim["chance_disputar_objetivo"]):
			_objetivo_sem_luta()
		elif t >= proxima_luta or disputa:
			var objetivo: String = ""
			if disputa:
				objetivo = "hydra" if t >= hydra_disponivel_em else "cerbero"
			var venc: int = _luta(objetivo)
			if venc != -1:
				if objetivo != "" and _tentar_roubo(objetivo, venc):
					pass
				else:
					_converter_vantagem(venc)
			var intervalo: float = float(sim["intervalo_luta_meio"]) if t < 25 * 60 else float(sim["intervalo_luta_fim"])
			proxima_luta = t + rng.randf_range(intervalo * 0.6, intervalo * 1.4)
		_comentarios_periodicos()
		if int(t) % int(sim["quadro_a_cada"]) == 0:
			_quadro()
	if vencedor == -1:
		# Limite prático: vence quem tem mais estruturas e ouro (raro; a tensão final quase sempre decide antes).
		vencedor = 0 if _contagem["torres"][0] * 1000 + ouro_do_time(0) >= _contagem["torres"][1] * 1000 + ouro_do_time(1) else 1
	var pc: Array = mapa["bases"][LADOS[1 - vencedor]]["cristal"]
	var v: Dictionary = _valores_time(vencedor)
	v["minuto"] = int(t / 60.0)
	var contexto: String = ""
	if _maior_desvantagem[vencedor] >= 3000.0:
		contexto = "virada"
		v["ouro"] = _formatar_ouro(_maior_desvantagem[vencedor])
	elif _maior_desvantagem[vencedor] <= 500.0 and _contagem["torres"][vencedor] >= _contagem["torres"][1 - vencedor] + 4:
		contexto = "dominio"
	_registrar("vitoria", {"time": vencedor, "x": pc[0], "y": pc[1], "narracao": narracao.narrar("vitoria", v, "", contexto)})
	_quadro()


## Abertura: se um time montou composição claramente de começo de jogo, o comentarista fala disso.
func _lance_inicio() -> Dictionary:
	var cedo: Array[float] = [0.0, 0.0]
	for p: Participante in participantes:
		cedo[p.time] += (float(p.curva["inicio"]) - float(p.curva["fim"])) / 5.0
	var time: int = 0 if cedo[0] >= cedo[1] else 1
	var contexto: String = "comp_cedo" if cedo[time] - cedo[1 - time] >= 0.03 else ""
	return {"time": -1, "narracao": narracao.narrar("inicio", _valores_time(time), "", contexto)}


# --- Mapa e posições ---------------------------------------------------------------------

func _ponto(lista: Array) -> Vector2:
	return Vector2(float(lista[0]), float(lista[1]))


## Ponto de uma rota na posição s (0 = base azul, 1 = base vermelha).
func ponto_na_rota(rota: String, s: float) -> Vector2:
	var pontos: Array = mapa["rotas"][rota]
	var comprimentos: Array[float] = []
	var total: float = 0.0
	for i: int in range(pontos.size() - 1):
		var d: float = _ponto(pontos[i]).distance_to(_ponto(pontos[i + 1]))
		comprimentos.append(d)
		total += d
	var alvo: float = clampf(s, 0.0, 1.0) * total
	for i: int in range(comprimentos.size()):
		if alvo <= comprimentos[i] or i == comprimentos.size() - 1:
			return _ponto(pontos[i]).lerp(_ponto(pontos[i + 1]), clampf(alvo / maxf(comprimentos[i], 0.0001), 0.0, 1.0))
		alvo -= comprimentos[i]
	return _ponto(pontos[-1])


func _ponto_da_torre(dono: int, rota: String, indice: int) -> Vector2:
	var s: float = float(mapa["torres"]["posicoes"][indice])
	return ponto_na_rota(rota, s if dono == 0 else 1.0 - s)


func _ponto_objetivo(tipo: String) -> Vector2:
	return _ponto(mapa["monstros_epicos"][tipo])


## Onde a onda de minions está na rota: entre as torres externas que ainda estão de pé.
func _frente(rota: String) -> float:
	var posicoes: Array = mapa["torres"]["posicoes"]
	var i_azul: int = _proxima_torre(0, rota)
	var i_verm: int = _proxima_torre(1, rota)
	var s_azul: float = float(posicoes[i_azul]) if i_azul != -1 else 0.06
	var s_verm: float = 1.0 - (float(posicoes[i_verm]) if i_verm != -1 else 0.06)
	return (s_azul + s_verm) / 2.0 + sin(t / 47.0 + rota.length()) * 0.04


func _atualizar_foco() -> void:
	if int(t) % 30 != 0:
		return
	for n: int in [0, 1]:
		var alvo: Vector2
		if t + 60.0 >= hydra_disponivel_em and t > 14 * 60:
			alvo = _ponto_objetivo("hydra")
		elif t + 60.0 >= cerbero_disponivel_em:
			alvo = _ponto_objetivo("cerbero")
		else:
			alvo = ponto_na_rota("meio", _frente("meio") + (-0.06 if n == 0 else 0.06))
		_foco[n] = alvo + Vector2(-0.04 if n == 0 else 0.04, 0.04 if n == 0 else -0.04)


## Posição normalizada (0 a 1) de um campeão agora. Mortos ficam na fonte.
func posicao_de(p: Participante, ignorar_morte: bool = false) -> Vector2:
	var lado: String = LADOS[p.time]
	if not ignorar_morte and not p.vivo(t):
		return _ponto(mapa["bases"][lado]["fonte"])
	if not p.posicao_temporaria.is_empty() and float(p.posicao_temporaria["ate"]) > t:
		return p.posicao_temporaria["ponto"]
	var sinal: float = -1.0 if p.time == 0 else 1.0
	var desloc: float = (POSICOES.find(p.posicao) - 2) * 0.012
	if p.posicao == "selva" and t < float(sim["fim_fase_de_rotas_min"]) * 60.0:
		var ids: Array = ["passaros", "sapo", "rato", "aranhas", "polvo", "golem"]
		var acamp: Array = mapa["acampamentos"][ids[int(t / 25.0) % ids.size()]]
		var ponto: Vector2 = _ponto(acamp)
		return ponto if p.time == 0 else Vector2(1.0 - ponto.x, 1.0 - ponto.y)
	var rota: String = ROTA_DE[p.posicao]
	var em_rota: bool = t < float(sim["fim_fase_de_rotas_min"]) * 60.0 or p.posicao == "topo"
	if rota != "" and em_rota:
		var s: float = _frente(rota) + sinal * 0.035
		if t < float(cfg["ondas"]["primeira_chegada"]):
			s = lerpf(0.0 if p.time == 0 else 1.0, s, t / float(cfg["ondas"]["primeira_chegada"]))
		return ponto_na_rota(rota, s) + Vector2(desloc, -desloc)
	return _foco[p.time] + Vector2(desloc * 2.0, desloc)


# --- Registro e resultado --------------------------------------------------------------

func _registrar(tipo: String, dados: Dictionary) -> Dictionary:
	var lance: Dictionary = {"indice": eventos.size(), "t": int(t), "minuto": _relogio(t), "tipo": tipo,
		"destaque": tipo in SEMPRE_DESTAQUE}
	lance.merge(dados, true)
	if not lance.has("narracao"):
		lance["narracao"] = []
	eventos.append(lance)
	return lance


func _quadro() -> void:
	var dif: float = ouro_do_time(0) - ouro_do_time(1)
	_maior_desvantagem[0] = maxf(_maior_desvantagem[0], -dif)
	_maior_desvantagem[1] = maxf(_maior_desvantagem[1], dif)
	var campeoes: Array[Dictionary] = []
	for p: Participante in participantes:
		var ponto: Vector2 = posicao_de(p)
		campeoes.append({"jogador": p.jogador_id, "x": snappedf(ponto.x, 0.001), "y": snappedf(ponto.y, 0.001),
			"vivo": p.vivo(t), "nivel": nivel_de(p)})
	quadros.append({"t": int(t), "campeoes": campeoes,
		"ouro": [roundi(ouro_do_time(0)), roundi(ouro_do_time(1))],
		"abates": [_contagem["abates"][0], _contagem["abates"][1]],
		"torres": [_contagem["torres"][0], _contagem["torres"][1]]})


func _resultado() -> Dictionary:
	var jogadores: Array[Dictionary] = []
	for p: Participante in participantes:
		jogadores.append({"jogador": p.jogador_id, "apelido": p.apelido, "time": p.time, "posicao": p.posicao,
			"campeao": p.campeao_id, "campeao_nome": p.campeao_nome, "abates": p.abates, "mortes": p.mortes, "assistencias": p.assistencias,
			"cs": roundi(p.cs), "ouro": roundi(p.ouro_total), "nivel": nivel_de(p),
			"itens": p.build.slice(0, p.itens), "dominio": p.nivel_dominio})
	return {
		"vencedor": vencedor,
		"semente": semente,
		"duracao": int(t),
		"times": [{"nome": nomes_times[0], "lado": "azul"}, {"nome": nomes_times[1], "lado": "vermelho"}],
		"placar": {"abates": _contagem["abates"], "torres": _contagem["torres"],
			"hydra": _contagem["hydra"], "cerbero": _contagem["cerbero"],
			"ouro": [roundi(ouro_do_time(0)), roundi(ouro_do_time(1))]},
		"jogadores": jogadores,
		"eventos": eventos,
		"quadros": quadros,
	}


# --- Textos para a narração ------------------------------------------------------------

func _valores_time(time: int) -> Dictionary:
	return {"time": nomes_times[time], "rival": nomes_times[1 - time], "minuto": int(t / 60.0)}


func _valores_rota(rota: String) -> Dictionary:
	var nomes: Dictionary = mapa["nomes_rotas"].get(rota, {})
	return {"rota": nomes.get("nome", rota), "na_rota": nomes.get("na", ""), "da_rota": nomes.get("da", "")}


func _valores(autor: Participante, alvo: Participante, cacador: Participante = null) -> Dictionary:
	var v: Dictionary = _valores_time(autor.time)
	v["jogador"] = autor.apelido
	v["campeao"] = autor.campeao_nome
	if alvo != null:
		v["alvo"] = alvo.apelido
		v["alvo_campeao"] = alvo.campeao_nome
	var rota: String = ROTA_DE[(alvo if alvo else autor).posicao]
	if rota != "":
		v.merge(_valores_rota(rota))
	if cacador != null:
		v["cacador"] = cacador.apelido
		if cacador == autor:
			v.erase("jogador")   # evita "Fulano entra e Fulano finaliza"
	var frente: float = ouro_do_time(autor.time) - ouro_do_time(1 - autor.time)
	if frente >= 1000.0:
		v["ouro"] = _formatar_ouro(frente)
	return v


static func _formatar_ouro(valor: float) -> String:
	if valor < 1000.0:
		return "%d de ouro" % roundi(valor)
	var mil: float = snappedf(valor / 1000.0, 0.1)
	var texto: String = String.num(mil).replace(".", ",")
	return "%s mil" % texto


static func _relogio(segundos: float) -> String:
	return "%02d:%02d" % [int(segundos) / 60, int(segundos) % 60]


func _embaralhar(lista: Array) -> void:
	for i: int in range(lista.size() - 1, 0, -1):
		var j: int = rng.randi() % (i + 1)
		var tmp: Variant = lista[i]
		lista[i] = lista[j]
		lista[j] = tmp
