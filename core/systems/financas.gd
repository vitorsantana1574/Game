class_name Financas
extends RefCounted
## Verba da liga e empréstimos. Ver docs/GDD.md, seção 8.12, e data/config/economia.json.


static func regras() -> Dictionary:
	return Dados.carregar("res://data/config/economia.json")


## Verba mensal da liga para a organização, conforme o nível e a posição na última etapa.
## posicao: 1 a 8, ou 0 se ainda não houver histórico (multiplicador 1).
static func verba_mensal(nivel_liga: String, posicao: int) -> int:
	var regra: Dictionary = regras()["verba_liga"]
	var base: float = float(regra.get(nivel_liga, regra["regional"]))
	return int(round(base * multiplicador_desempenho(posicao) / 100.0) * 100.0)


static func multiplicador_desempenho(posicao: int) -> float:
	if posicao <= 0:
		return 1.0
	var regra: Dictionary = regras()["verba_liga"]
	var times: int = int(regra["times_na_liga"])
	var progresso: float = float(clampi(posicao, 1, times) - 1) / float(times - 1)
	return lerpf(float(regra["multiplicador_primeiro"]), float(regra["multiplicador_ultimo"]), progresso)


## Parcela fixa (tabela Price) de um empréstimo.
static func parcela(valor: int, meses: int) -> int:
	var juros: float = float(regras()["emprestimo"]["juros_mensais"])
	var fator: float = juros / (1.0 - pow(1.0 + juros, -float(meses)))
	return int(ceil(float(valor) * fator))


## Saldo para quitar um empréstimo hoje (valor presente das parcelas restantes).
static func saldo_devedor(valor_parcela: int, parcelas_restantes: int) -> int:
	if parcelas_restantes <= 0:
		return 0
	var juros: float = float(regras()["emprestimo"]["juros_mensais"])
	return int(ceil(float(valor_parcela) * (1.0 - pow(1.0 + juros, -float(parcelas_restantes))) / juros))


## Limite de empréstimo: algumas verbas mensais da liga atual.
static func limite_emprestimo(nivel_liga: String) -> int:
	var regra: Dictionary = regras()
	return int(regra["verba_liga"].get(nivel_liga, regra["verba_liga"]["regional"])) * int(regra["emprestimo"]["limite_em_verbas_mensais"])


## Prévia de um empréstimo para a interface.
static func simular(valor: int, meses: int) -> Dictionary:
	var p: int = parcela(valor, meses)
	return {"valor": valor, "meses": meses, "parcela": p, "total": p * meses, "juros_total": p * meses - valor}
