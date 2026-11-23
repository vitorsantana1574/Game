class_name Organizacao
extends RefCounted
## A organização de e-sports do jogador (ou de um rival).

const MAXIMO_ELENCO: int = 10

var nome: String = ""
var dinheiro: int = 0
## Reputação de 0 a 100. Ver docs/GDD.md, seção 8.9.
var reputacao: float = 10.0
var elenco: Array[Jogador] = []


func para_dicionario() -> Dictionary:
	var jogadores: Array[Dictionary] = []
	for jogador: Jogador in elenco:
		jogadores.append(jogador.para_dicionario())
	return {
		"nome": nome,
		"dinheiro": dinheiro,
		"reputacao": reputacao,
		"elenco": jogadores,
	}


static func de_dicionario(dados: Dictionary) -> Organizacao:
	var organizacao: Organizacao = Organizacao.new()
	organizacao.nome = str(dados["nome"])
	organizacao.dinheiro = int(dados["dinheiro"])
	organizacao.reputacao = float(dados["reputacao"])
	for jogador: Dictionary in dados["elenco"]:
		organizacao.elenco.append(Jogador.de_dicionario(jogador))
	return organizacao
