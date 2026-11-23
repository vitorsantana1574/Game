class_name Carreira
extends RefCounted
## Uma carreira inteira: é o que vai para o save.

## Aumente quando o formato do save mudar, para converter saves antigos.
const VERSAO_SAVE: int = 1

var config: Dictionary = {}
var organizacao: Organizacao = Organizacao.new()
var dia: int = 1
var nivel_liga: String = "regional"
## Semente dos sorteios desta carreira (gerador de jogadores, simulação etc.).
var semente: int = 0
## Quantos jogadores já foram gerados (garante ids únicos).
var contador_jogadores: int = 0


## Texto curto da fase atual, usado no resumo dos saves.
func descricao_fase() -> String:
	var nomes_liga: Dictionary = {"regional": "Regional", "nacional": "Nacional", "mundial": "Mundial"}
	return "%s · Dia %d" % [nomes_liga.get(nivel_liga, nivel_liga), dia]


func para_dicionario() -> Dictionary:
	return {
		"versao": VERSAO_SAVE,
		"config": config,
		"organizacao": organizacao.para_dicionario(),
		"dia": dia,
		"nivel_liga": nivel_liga,
		"semente": semente,
		"contador_jogadores": contador_jogadores,
	}


static func de_dicionario(dados: Dictionary) -> Carreira:
	var carreira: Carreira = Carreira.new()
	carreira.config = dados["config"].duplicate(true)
	# O JSON devolve todo número como decimal: os campos inteiros da configuração voltam a ser int.
	for campo: String in ["capital_valor", "qualidade_rivais"]:
		if carreira.config.has(campo):
			carreira.config[campo] = int(carreira.config[campo])
	carreira.organizacao = Organizacao.de_dicionario(dados["organizacao"])
	carreira.dia = int(dados["dia"])
	carreira.nivel_liga = str(dados["nivel_liga"])
	carreira.semente = int(dados["semente"])
	carreira.contador_jogadores = int(dados.get("contador_jogadores", 0))
	return carreira
