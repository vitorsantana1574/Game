class_name DominioCampeoes
extends RefCounted
## Domínio de campeões de cada jogador (GDD 6.3).
##
## A lógica guarda uma maestria de 0 a 100 por campeão. A interface vê só o nível:
## Favorito, Conhece bem, Já jogou, Não conhece. Os limites e o rendimento de cada nível
## ficam em data/config/draft.json ("dominio").
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
		maestria[escolhido] = clampi(roundi(valor), 26, 99)
	for id: String in restantes:
		maestria[id] = rng.randi_range(0, int(r["maestria_desconhecido_maxima"]))
	return maestria


## Nível de uma maestria: {"id", "nome", "rendimento"}.
static func nivel(maestria: int) -> Dictionary:
	for item: Dictionary in regras()["niveis"]:
		if maestria >= int(item["minimo"]):
			return {"id": item["id"], "nome": item["nome"], "rendimento": float(item["rendimento"])}
	var ultimo: Dictionary = regras()["niveis"][-1]
	return {"id": ultimo["id"], "nome": ultimo["nome"], "rendimento": float(ultimo["rendimento"])}


## Rendimento (multiplicador de desempenho) de um jogador com um campeão.
static func rendimento(jogador: Jogador, campeao_id: String) -> float:
	return float(nivel(int(jogador.dominio_campeoes.get(campeao_id, 0)))["rendimento"])


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


## Lista pública: campeões que o jogador conhece (Já jogou ou mais), do mais para o menos dominado.
## [{"id", "nivel", "nivel_nome"}]. A maestria numérica não sai.
static func lista_publica(jogador: Jogador) -> Array[Dictionary]:
	var ids: Array = jogador.dominio_campeoes.keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ma: int = int(jogador.dominio_campeoes[a])
		var mb: int = int(jogador.dominio_campeoes[b])
		return ma > mb or (ma == mb and a < b))
	var saida: Array[Dictionary] = []
	for id: String in ids:
		var n: Dictionary = nivel(int(jogador.dominio_campeoes[id]))
		if n["id"] == "nao_conhece":
			continue
		saida.append({"id": id, "nivel": n["id"], "nivel_nome": n["nome"]})
	return saida
