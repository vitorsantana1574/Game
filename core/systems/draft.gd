class_name Draft
extends RefCounted
## Draft de Crystal Legends: banimentos e escolhas (GDD seção 8).
##
## Ordem padrão do profissional, lida de data/config/draft.json:
## 3 bans por time alternando, picks A B B A A B, 2 bans por time (B começa), picks B A A B.
## "azul" escolhe primeiro. O time controlado pelo jogador espera as ações dele;
## o outro (e o jogador, quando delega ao técnico) decide pela IA.

const LADOS: Array[String] = ["azul", "vermelho"]
const POSICOES: Array[String] = ["topo", "selva", "meio", "atirador", "suporte"]

const ERRO_CONCLUIDO: String = "draft_concluido"
const ERRO_NAO_E_SUA_VEZ: String = "nao_e_sua_vez"
const ERRO_ACAO_ERRADA: String = "acao_errada"
const ERRO_INDISPONIVEL: String = "campeao_indisponivel"
const ERRO_CAMPEAO: String = "campeao_inexistente"

var ordem: Array = []
var passo: int = 0
## lado -> {"id", "nome", "jogadores": {posicao: Jogador}, "qualidade": float (0 a 1), "controlado": bool}
var times: Dictionary = {}
var bans: Dictionary = {"azul": [], "vermelho": []}
var picks: Dictionary = {"azul": [], "vermelho": []}
## Campeões que cada lado não pode usar (draft "fearless" numa série de playoff).
var indisponiveis: Dictionary = {"azul": [], "vermelho": []}
## Posição final de cada campeão escolhido: lado -> {posicao: id do campeão}.
var posicoes: Dictionary = {"azul": {}, "vermelho": {}}
## Força escondida do patch (id -> multiplicador). Só a IA usa, ponderada pela qualidade.
var forcas: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


static func criar(azul: Dictionary, vermelho: Dictionary, forcas_patch: Dictionary, semente: int,
		bloqueados: Dictionary = {}) -> Draft:
	var draft: Draft = Draft.new()
	draft.ordem = Dados.draft()["ordem"].duplicate(true)
	draft.times = {"azul": azul, "vermelho": vermelho}
	draft.forcas = forcas_patch
	draft._rng.seed = semente
	for lado: String in LADOS:
		for id: Variant in bloqueados.get(lado, []):
			draft.indisponiveis[lado].append(str(id))
	return draft


static func ids_campeoes() -> Array[String]:
	var lista: Array[String] = []
	for campeao: Dictionary in Dados.campeoes()["campeoes"]:
		lista.append(String(campeao["id"]))
	lista.sort()
	return lista


static func outro(lado: String) -> String:
	return "vermelho" if lado == "azul" else "azul"


func concluido() -> bool:
	return passo >= ordem.size()


## Ação da vez: {"acao": "ban" | "pick", "time": "azul" | "vermelho"}, ou {} se o draft acabou.
func vez() -> Dictionary:
	return {} if concluido() else ordem[passo]


func usado_por(campeao_id: String) -> Dictionary:
	for lado: String in LADOS:
		if bans[lado].has(campeao_id):
			return {"estado": "banido", "por": lado}
		if picks[lado].has(campeao_id):
			return {"estado": "escolhido", "por": lado}
	return {}


func disponivel(campeao_id: String, lado: String) -> bool:
	return usado_por(campeao_id).is_empty() and not indisponiveis[lado].has(campeao_id)


## Aplica a ação da vez com o campeão. "" se deu certo, ou o código do erro.
func aplicar(campeao_id: String) -> String:
	if concluido():
		return ERRO_CONCLUIDO
	if not ids_campeoes().has(campeao_id):
		return ERRO_CAMPEAO
	var atual: Dictionary = vez()
	var lado: String = atual["time"]
	# Banir: só não pode o que já saiu. O "fearless" não impede banir.
	if atual["acao"] == "ban":
		if not usado_por(campeao_id).is_empty():
			return ERRO_INDISPONIVEL
		bans[lado].append(campeao_id)
	else:
		if not disponivel(campeao_id, lado):
			return ERRO_INDISPONIVEL
		picks[lado].append(campeao_id)
	passo += 1
	if concluido():
		for l: String in LADOS:
			if posicoes[l].is_empty():
				posicoes[l] = melhor_atribuicao(l)
	return ""


## Executa as vezes da IA até chegar a vez de um time controlado pelo jogador (ou o fim).
func avancar_ia() -> void:
	while not concluido() and not bool(times[vez()["time"]].get("controlado", false)):
		aplicar(decidir_ia())


## Escolha automática para a vez atual, com a qualidade do time da vez (técnico).
func decidir_ia() -> String:
	var atual: Dictionary = vez()
	var lado: String = atual["time"]
	var ia: Dictionary = Dados.draft()["ia"]
	var q: float = float(times[lado].get("qualidade", ia["qualidade_sem_tecnico"]))
	var ruido: float = lerpf(float(ia["ruido_qualidade_baixa"]), float(ia["ruido_qualidade_alta"]), q)
	var abertas_meu: Array[String] = posicoes_abertas(lado)
	var abertas_rival: Array[String] = posicoes_abertas(outro(lado))
	var melhor: String = ""
	var melhor_nota: float = -INF
	for id: String in ids_campeoes():
		var nota: float
		if atual["acao"] == "ban":
			if not usado_por(id).is_empty():
				continue
			nota = valor_para(outro(lado), id, q, abertas_rival)
		else:
			if not disponivel(id, lado):
				continue
			nota = valor_para(lado, id, q, abertas_meu) + float(ia["peso_negar_rival"]) * valor_para(outro(lado), id, q, abertas_rival) * 0.5
		nota *= 1.0 + _rng.randfn(0.0, ruido)
		if nota > melhor_nota:
			melhor_nota = nota
			melhor = id
	return melhor


## Quanto um campeão vale para um lado agora: melhor encaixe numa posição ainda aberta
## (domínio do jogador × adequação do campeão à posição), mais o meta percebido.
func valor_para(lado: String, campeao_id: String, qualidade: float, abertas: Array[String] = []) -> float:
	if indisponiveis[lado].has(campeao_id):
		return 0.0  # o lado não pode usar (fearless): não vale nada para ele
	var ia: Dictionary = Dados.draft()["ia"]
	if abertas.is_empty():
		abertas = posicoes_abertas(lado)
	var melhor: float = 0.0
	var jogadores: Dictionary = times[lado]["jogadores"]
	for posicao: String in abertas:
		var jogador: Jogador = jogadores.get(posicao)
		if jogador == null:
			continue
		melhor = maxf(melhor, DominioCampeoes.rendimento(jogador, campeao_id) * DominioCampeoes.adequacao(campeao_id, posicao))
	var peso_meta: float = lerpf(float(ia["peso_meta_qualidade_baixa"]), float(ia["peso_meta_qualidade_alta"]), qualidade)
	return melhor + peso_meta * (float(forcas.get(campeao_id, 1.0)) - 1.0) * 3.0


## Posições que ainda não têm campeão, pela melhor atribuição provisória dos picks feitos.
func posicoes_abertas(lado: String) -> Array[String]:
	var ocupadas: Dictionary = melhor_atribuicao(lado)
	var abertas: Array[String] = []
	for posicao: String in POSICOES:
		if not ocupadas.has(posicao):
			abertas.append(posicao)
	return abertas


## Melhor distribuição dos campeões escolhidos pelas posições (maximiza domínio × adequação).
## Testa todas as combinações: com até 5 campeões são no máximo 120.
func melhor_atribuicao(lado: String) -> Dictionary:
	var escolhidos: Array = picks[lado]
	if escolhidos.is_empty():
		return {}
	var jogadores: Dictionary = times[lado]["jogadores"]
	var melhor: Dictionary = {}
	var melhor_nota: float = -1.0
	for combinacao: Array in _arranjos(POSICOES, escolhidos.size()):
		var nota: float = 0.0
		var mapa: Dictionary = {}
		for indice: int in range(escolhidos.size()):
			var posicao: String = combinacao[indice]
			var jogador: Jogador = jogadores.get(posicao)
			var rend: float = DominioCampeoes.rendimento(jogador, escolhidos[indice]) if jogador else 0.8
			nota += rend * DominioCampeoes.adequacao(escolhidos[indice], posicao)
			mapa[posicao] = escolhidos[indice]
		if nota > melhor_nota + 1e-9:
			melhor_nota = nota
			melhor = mapa
	return melhor


## Troca a posição final dos campeões de um lado. mapa: {posicao: id}, com os 5 campeões escolhidos.
func definir_posicoes(lado: String, mapa: Dictionary) -> String:
	if not concluido():
		return "draft_em_andamento"
	var esperado: Array = picks[lado].duplicate()
	var recebido: Array = []
	for posicao: String in POSICOES:
		if not mapa.has(posicao):
			return "posicao_faltando"
		recebido.append(str(mapa[posicao]))
	esperado.sort()
	recebido.sort()
	if esperado != recebido:
		return "campeoes_diferentes"
	posicoes[lado] = {}
	for posicao: String in POSICOES:
		posicoes[lado][posicao] = str(mapa[posicao])
	return ""


static func _arranjos(itens: Array, tamanho: int) -> Array:
	if tamanho == 0:
		return [[]]
	var saida: Array = []
	for indice: int in range(itens.size()):
		var resto: Array = itens.duplicate()
		resto.remove_at(indice)
		for cauda: Array in _arranjos(resto, tamanho - 1):
			saida.append([itens[indice]] + cauda)
	return saida
