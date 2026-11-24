class_name Organizacao
extends RefCounted
## A organização de e-sports do jogador (ou de um rival).

const MAXIMO_ELENCO: int = 10

var nome: String = ""
var dinheiro: int = 0
## Reputação de 0 a 100. Ver docs/GDD.md, seção 8.9.
var reputacao: float = 10.0
var elenco: Array[Jogador] = []
var tecnico: Tecnico = null
## Titulares: posição -> id do jogador. Posições sem titular ficam de fora.
var titulares: Dictionary = {}
## Salários que deveriam ter sido pagos e não foram (reais) e há quantos meses.
var salarios_atrasados: int = 0
var meses_em_atraso: int = 0
## Posição na última etapa disputada (1 a 8), ou 0 sem histórico. Define a verba da liga.
var ultima_posicao: int = 0
## Empréstimo ativo: {} ou {"valor", "meses", "parcela", "parcelas_restantes", "parcelas_atrasadas", "divida_atrasada"}
var emprestimo: Dictionary = {}


func jogador_por_id(id: String) -> Jogador:
	for jogador: Jogador in elenco:
		if jogador.id == id:
			return jogador
	return null


func eh_titular(id: String) -> bool:
	return titulares.values().has(id)


## Soma dos salários mensais de jogadores e técnico.
func folha_mensal() -> int:
	var total: int = 0
	for jogador: Jogador in elenco:
		if jogador.contrato:
			total += jogador.contrato.salario
	if tecnico and tecnico.contrato:
		total += tecnico.contrato.salario
	return total


func para_dicionario() -> Dictionary:
	var jogadores: Array[Dictionary] = []
	for jogador: Jogador in elenco:
		jogadores.append(jogador.para_dicionario())
	return {
		"nome": nome,
		"dinheiro": dinheiro,
		"reputacao": reputacao,
		"elenco": jogadores,
		"tecnico": tecnico.para_dicionario() if tecnico else {},
		"titulares": titulares,
		"salarios_atrasados": salarios_atrasados,
		"meses_em_atraso": meses_em_atraso,
		"ultima_posicao": ultima_posicao,
		"emprestimo": emprestimo,
	}


static func de_dicionario(dados: Dictionary) -> Organizacao:
	var organizacao: Organizacao = Organizacao.new()
	organizacao.nome = str(dados["nome"])
	organizacao.dinheiro = int(dados["dinheiro"])
	organizacao.reputacao = float(dados["reputacao"])
	for jogador: Dictionary in dados["elenco"]:
		organizacao.elenco.append(Jogador.de_dicionario(jogador))
	var tecnico_dados: Dictionary = dados.get("tecnico", {})
	if not tecnico_dados.is_empty():
		organizacao.tecnico = Tecnico.de_dicionario(tecnico_dados)
	for posicao: String in dados.get("titulares", {}):
		organizacao.titulares[posicao] = str(dados["titulares"][posicao])
	organizacao.salarios_atrasados = int(dados.get("salarios_atrasados", 0))
	organizacao.meses_em_atraso = int(dados.get("meses_em_atraso", 0))
	organizacao.ultima_posicao = int(dados.get("ultima_posicao", 0))
	var emprestimo_dados: Dictionary = dados.get("emprestimo", {})
	for chave: String in emprestimo_dados:
		organizacao.emprestimo[chave] = int(emprestimo_dados[chave])
	return organizacao
