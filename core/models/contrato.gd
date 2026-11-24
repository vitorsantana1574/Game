class_name Contrato
extends RefCounted
## Contrato de um jogador ou técnico com a organização. Ver docs/GDD.md, seção 8.11.

## Salário mensal, em reais.
var salario: int = 0
## Pagamento único na assinatura (luvas), em reais.
var luvas: int = 0
## Valor que outro time (ou o próprio jogador) paga para encerrar o contrato antes do fim.
var multa_rescisoria: int = 0
## Prêmios por desempenho, pagos quando a conquista acontece.
var bonus_titulo: int = 0
var bonus_mundial: int = 0
## O jogador exige ser titular.
var clausula_titular: bool = false

var duracao_meses: int = 12
## Dia da carreira em que começou e em que termina (o contrato vale até o fim deste dia).
var dia_inicio: int = 1
var dia_fim: int = 360


func dias_restantes(dia_atual: int) -> int:
	return maxi(0, dia_fim - dia_atual)


## Salário que ainda seria pago até o fim do contrato.
func salario_restante(dia_atual: int) -> int:
	var meses: float = float(dias_restantes(dia_atual)) / float(Dados.dias_por_mes())
	return int(round(float(salario) * meses))


func resumo(dia_atual: int) -> Dictionary:
	return {
		"salario": salario,
		"luvas": luvas,
		"multa_rescisoria": multa_rescisoria,
		"bonus_titulo": bonus_titulo,
		"bonus_mundial": bonus_mundial,
		"clausula_titular": clausula_titular,
		"duracao_meses": duracao_meses,
		"dia_inicio": dia_inicio,
		"dia_fim": dia_fim,
		"dias_restantes": dias_restantes(dia_atual),
	}


func para_dicionario() -> Dictionary:
	return {
		"salario": salario,
		"luvas": luvas,
		"multa_rescisoria": multa_rescisoria,
		"bonus_titulo": bonus_titulo,
		"bonus_mundial": bonus_mundial,
		"clausula_titular": clausula_titular,
		"duracao_meses": duracao_meses,
		"dia_inicio": dia_inicio,
		"dia_fim": dia_fim,
	}


static func de_dicionario(dados: Dictionary) -> Contrato:
	var contrato: Contrato = Contrato.new()
	contrato.salario = int(dados["salario"])
	contrato.luvas = int(dados["luvas"])
	contrato.multa_rescisoria = int(dados["multa_rescisoria"])
	contrato.bonus_titulo = int(dados["bonus_titulo"])
	contrato.bonus_mundial = int(dados["bonus_mundial"])
	contrato.clausula_titular = bool(dados["clausula_titular"])
	contrato.duracao_meses = int(dados["duracao_meses"])
	contrato.dia_inicio = int(dados["dia_inicio"])
	contrato.dia_fim = int(dados["dia_fim"])
	return contrato
