class_name Jogador
extends RefCounted
## Um jogador profissional. Ver docs/GDD.md, seções 5 e 6.
## Todos os atributos vão de 1 a 100.

const ATRIBUTOS: Array[String] = ["resistencia", "mental", "farm", "micro", "macro"]
const POSICOES: Array[String] = ["topo", "selva", "meio", "atirador", "suporte"]

var id: String = ""
var apelido: String = ""
var nome_real: String = ""
var idade: int = 18

## Posição principal e afinidade (0 a 1) com cada posição. 1.0 = rendimento total.
var posicao_principal: String = "meio"
var afinidade_posicao: Dictionary = {}
## 0 = especialista (lista pequena, muita maestria); 1 = versátil (bom em tudo, especialista em nada).
## Vale para posições e, quando existirem, para campeões.
var versatilidade: float = 0.5

## Atributos principais: resistencia, mental, farm, micro, macro.
var atributos: Dictionary = {}

## Estados do dia a dia (0 a 100).
var energia: float = 100.0
var satisfacao: float = 70.0
var lealdade: float = 20.0
var experiencia: int = 0

## Traços ocultos: só aparecem para o jogador quando revelados.
var potencial: int = 50
var ego: int = 50
var tracos_revelados: Array[String] = []

## Salário mensal que ele pede, em reais.
var salario_pedido: int = 0

## Domínio de campeões (id do campeão -> nível). Preenchido na etapa dos campeões.
var dominio_campeoes: Dictionary = {}

## Partidas oficiais por campeão (id do campeão -> partidas). Preenchido pela simulação de partidas.
var partidas_por_campeao: Dictionary = {}

## Aparência visual (0 a N-1, ver "aparencias" em data/config/balanceamento.json). Só apresentação.
var aparencia: int = 0

## Contrato atual, ou null para agentes livres.
var contrato: Contrato = null


## Aparência estável derivada do id (usada em saves antigos, que não tinham o campo).
static func aparencia_do_id(id_jogador: String) -> int:
	return absi(hash(id_jogador)) % maxi(1, int(Dados.balanceamento().get("aparencias", 20)))


## Até `limite` campeões mais jogados: [{"id", "partidas"}], do mais para o menos jogado.
func campeoes_mais_jogados(limite: int = 3) -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	for id_campeao: String in partidas_por_campeao:
		lista.append({"id": id_campeao, "partidas": int(partidas_por_campeao[id_campeao])})
	lista.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["partidas"] > b["partidas"] or (a["partidas"] == b["partidas"] and String(a["id"]) < String(b["id"])))
	return lista.slice(0, limite)


## Nível geral do jogador numa posição (1 a 100), ponderando os atributos pelos pesos da posição.
func nivel_geral(posicao: String = "") -> float:
	var alvo: String = posicao if not posicao.is_empty() else posicao_principal
	var pesos: Dictionary = Dados.balanceamento()["pesos_por_posicao"][alvo]
	var soma: float = 0.0
	for atributo: String in ATRIBUTOS:
		soma += float(atributos.get(atributo, 1)) * float(pesos[atributo])
	return soma * float(afinidade_posicao.get(alvo, 1.0))


func traco_revelado(traco: String) -> bool:
	return traco in tracos_revelados


## Fama de 0 a 1: quão bom e conhecido o jogador é. Quanto maior, mais difícil negociar.
func fama() -> float:
	var regra: Dictionary = Dados.contratos()["fama"]
	var parte_nivel: float = inverse_lerp(float(regra["nivel_minimo"]), float(regra["nivel_maximo"]), nivel_geral())
	var parte_experiencia: float = float(experiencia) / float(regra["experiencia_maxima"])
	var valor: float = clampf(parte_nivel, 0.0, 1.0) * float(regra["peso_nivel"])
	valor += clampf(parte_experiencia, 0.0, 1.0) * float(regra["peso_experiencia"])
	return clampf(valor, 0.0, 1.0)


## Dados que a interface pode exibir. Traços ocultos só aparecem se revelados.
## `dia_atual` é usado para calcular os dias restantes do contrato.
func resumo_publico(dia_atual: int = 1) -> Dictionary:
	var resumo: Dictionary = {
		"id": id,
		"apelido": apelido,
		"nome_real": nome_real,
		"idade": idade,
		"posicao_principal": posicao_principal,
		"afinidade_posicao": afinidade_posicao.duplicate(),
		"atributos": atributos.duplicate(),
		"nivel_geral": roundi(nivel_geral()),
		"energia": roundi(energia),
		"satisfacao": roundi(satisfacao),
		"lealdade": roundi(lealdade),
		"experiencia": experiencia,
		"salario_pedido": salario_pedido,
		"fama": snappedf(fama(), 0.01),
		"contrato": contrato.resumo(dia_atual) if contrato else {},
		"aparencia": aparencia,
		"historico_campeoes": {
			# false até a simulação de partidas existir; depois, true mesmo sem partidas.
			"disponivel": bool(Dados.balanceamento().get("historico_de_partidas_ativo", false)),
			"mais_jogados": campeoes_mais_jogados(),
		},
	}
	if traco_revelado("potencial"):
		resumo["potencial"] = potencial
	if traco_revelado("ego"):
		resumo["ego"] = ego
	return resumo


func para_dicionario() -> Dictionary:
	return {
		"id": id,
		"apelido": apelido,
		"nome_real": nome_real,
		"idade": idade,
		"posicao_principal": posicao_principal,
		"afinidade_posicao": afinidade_posicao,
		"versatilidade": versatilidade,
		"atributos": atributos,
		"energia": energia,
		"satisfacao": satisfacao,
		"lealdade": lealdade,
		"experiencia": experiencia,
		"potencial": potencial,
		"ego": ego,
		"tracos_revelados": tracos_revelados,
		"salario_pedido": salario_pedido,
		"dominio_campeoes": dominio_campeoes,
		"partidas_por_campeao": partidas_por_campeao,
		"aparencia": aparencia,
		"contrato": contrato.para_dicionario() if contrato else {},
	}


static func de_dicionario(dados: Dictionary) -> Jogador:
	var jogador: Jogador = Jogador.new()
	jogador.id = str(dados["id"])
	jogador.apelido = str(dados["apelido"])
	jogador.nome_real = str(dados["nome_real"])
	jogador.idade = int(dados["idade"])
	jogador.posicao_principal = str(dados["posicao_principal"])
	for posicao: String in dados["afinidade_posicao"]:
		jogador.afinidade_posicao[posicao] = float(dados["afinidade_posicao"][posicao])
	jogador.versatilidade = float(dados["versatilidade"])
	for atributo: String in dados["atributos"]:
		jogador.atributos[atributo] = int(dados["atributos"][atributo])
	jogador.energia = float(dados["energia"])
	jogador.satisfacao = float(dados["satisfacao"])
	jogador.lealdade = float(dados["lealdade"])
	jogador.experiencia = int(dados["experiencia"])
	jogador.potencial = int(dados["potencial"])
	jogador.ego = int(dados["ego"])
	for traco: Variant in dados["tracos_revelados"]:
		jogador.tracos_revelados.append(str(traco))
	jogador.salario_pedido = int(dados["salario_pedido"])
	jogador.dominio_campeoes = dados.get("dominio_campeoes", {}).duplicate()
	for id_campeao: String in dados.get("partidas_por_campeao", {}):
		jogador.partidas_por_campeao[id_campeao] = int(dados["partidas_por_campeao"][id_campeao])
	jogador.aparencia = int(dados["aparencia"]) if dados.has("aparencia") else aparencia_do_id(jogador.id)
	var contrato_dados: Dictionary = dados.get("contrato", {})
	if not contrato_dados.is_empty():
		jogador.contrato = Contrato.de_dicionario(contrato_dados)
	return jogador
