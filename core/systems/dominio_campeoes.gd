class_name DominioCampeoes
extends RefCounted
## Domínio de campeões de cada jogador (GDD 6.3).
##
## A lógica guarda uma maestria de 0 a 100 por campeão; a interface mostra o número e a faixa
## (aprovadas pelo dono em 25/11): 95-100 Mono, 80-94 Main, 41-79 Conhecido, 0-40 Desconhecido.
## O rendimento cresce dentro da faixa e salta ao mudar de faixa. Limites e valores em
## data/config/draft.json ("dominio").
##
## Especialista (versatilidade baixa): lista pequena, maestria alta nos primeiros.
## Versátil (versatilidade alta): lista grande, maestria razoável em todos, sem pico.


static func regras() -> Dictionary:
	return Dados.draft()["dominio"]


## Gera a maestria de um jogador para todos os campeões. Determinístico pela semente.
static func gerar(jogador: Jogador, semente: int) -> Dictionary:
	var r: Dictionary = regras()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = semente
	var v: float = jogador.versatilidade
	var conhecidos: int = roundi(lerpf(float(r["campeoes_conhecidos_especialista"]), float(r["campeoes_conhecidos_versatil"]), v))
	var topo: float = lerpf(float(r["maestria_topo_especialista"]), float(r["maestria_topo_versatil"]), v)
	var queda: float = lerpf(float(r["queda_por_campeao_especialista"]), float(r["queda_por_campeao_versatil"]), v)

	# Peso de sorteio de cada campeão: quanto ele combina com as posições do jogador.
	var pesos: Dictionary = {}
	for campeao: Dictionary in Dados.campeoes()["campeoes"]:
		var peso: float = 0.0
		var posicoes: Array = campeao["posicoes"]
		for indice: int in range(posicoes.size()):
			var afinidade: float = float(jogador.afinidade_posicao.get(posicoes[indice], 0.0))
			var fator: float = float(r["peso_posicao_principal_do_campeao"]) if indice == 0 else float(r["peso_posicao_secundaria_do_campeao"])
			peso = maxf(peso, afinidade * afinidade * fator)
		pesos[campeao["id"]] = maxf(peso, float(r["peso_fora_da_posicao"]))

	var maestria: Dictionary = {}
	var restantes: Array = pesos.keys()
	restantes.sort()
	for ordem: int in range(mini(conhecidos, restantes.size())):
		var total: float = 0.0
		for id: String in restantes:
			total += float(pesos[id])
		var sorteio: float = rng.randf() * total
		var escolhido: String = restantes[-1]
		for id: String in restantes:
			sorteio -= float(pesos[id])
			if sorteio <= 0.0:
				escolhido = id
				break
		restantes.erase(escolhido)
		var valor: float = topo - queda * ordem + rng.randf_range(-float(r["ruido"]), float(r["ruido"]))
		# Campeão da lista do jogador é pelo menos Conhecido.
		maestria[escolhido] = clampi(roundi(valor), int(regras()["niveis"][-2]["minimo"]), 100)
	for id: String in restantes:
		maestria[id] = rng.randi_range(0, int(r["maestria_desconhecido_maxima"]))
	return maestria


## Faixa de uma maestria: {"id", "nome", "rendimento"}. O rendimento já considera o ponto dentro da faixa.
static func nivel(maestria: int) -> Dictionary:
	var niveis: Array = regras()["niveis"]
	var teto: int = 100
	for item: Dictionary in niveis:
		var minimo: int = int(item["minimo"])
		if maestria >= minimo:
			var progresso: float = clampf(float(maestria - minimo) / maxf(1.0, float(teto - minimo)), 0.0, 1.0)
			var valor: float = lerpf(float(item["rendimento"]), float(item.get("rendimento_no_topo", item["rendimento"])), progresso)
			return {"id": item["id"], "nome": item["nome"], "rendimento": valor}
		teto = minimo - 1
	var ultimo: Dictionary = niveis[-1]
	return {"id": ultimo["id"], "nome": ultimo["nome"], "rendimento": float(ultimo["rendimento"])}


## Rendimento (multiplicador de desempenho) de um jogador com um campeão.
static func rendimento(jogador: Jogador, campeao_id: String) -> float:
	return float(nivel(int(jogador.dominio_campeoes.get(campeao_id, 0)))["rendimento"])


## Campeão principal: Main ou Mono (80 ou mais).
static func e_principal(maestria: int) -> bool:
	return nivel(maestria)["id"] in ["main", "mono"]


## Rendimento de um campeão numa posição (principal, secundária ou fora das posições dele).
static func adequacao(campeao_id: String, posicao: String) -> float:
	var regra: Dictionary = Dados.draft()["adequacao_posicao"]
	var campeao: Dictionary = Dados.por_id(Dados.campeoes()["campeoes"], campeao_id)
	if campeao.is_empty():
		return float(regra["fora"])
	var posicoes: Array = campeao["posicoes"]
	if not posicoes.is_empty() and posicoes[0] == posicao:
		return float(regra["principal"])
	if posicoes.has(posicao):
		return float(regra["secundaria"])
	return float(regra["fora"])


## Lista pública: campeões que o jogador conhece (Conhecido ou mais), do mais para o menos dominado.
## [{"id", "nivel", "nivel_nome", "conhecimento"}].
static func lista_publica(jogador: Jogador) -> Array[Dictionary]:
	var ids: Array = jogador.dominio_campeoes.keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ma: int = int(jogador.dominio_campeoes[a])
		var mb: int = int(jogador.dominio_campeoes[b])
		return ma > mb or (ma == mb and a < b))
	var saida: Array[Dictionary] = []
	for id: String in ids:
		var maestria: int = int(jogador.dominio_campeoes[id])
		var n: Dictionary = nivel(maestria)
		if n["id"] == "desconhecido":
			continue
		saida.append({"id": id, "nivel": n["id"], "nivel_nome": n["nome"], "conhecimento": maestria})
	return saida
