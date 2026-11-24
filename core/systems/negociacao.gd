class_name Negociacao
extends RefCounted
## Decide se um jogador aceita uma proposta de contrato. Ver docs/GDD.md, seção 8.11.
## Regras e números em data/config/contratos.json.
##
## Ideia: o jogador tem uma EXIGÊNCIA mensal (salário pedido ajustado por multa, reputação do time
## e lealdade). A proposta vale um VALOR mensal (salário + luvas diluídas + parte dos bônus).
## Ele aceita se valor >= exigência × tolerância. Iniciantes toleram mais; estrelas, quase nada.

const MOTIVO_ACEITA: String = "aceita"
const MOTIVO_POUCO: String = "proposta_baixa"
const MOTIVO_OFENSIVA: String = "proposta_ofensiva"
const MOTIVO_EXIGE_TITULAR: String = "exige_titular"
const MOTIVO_INVALIDA: String = "proposta_invalida"


## Completa uma proposta com valores padrão e garante tipos inteiros.
static func normalizar(proposta: Dictionary, jogador: Jogador) -> Dictionary:
	var regras: Dictionary = Dados.contratos()
	var salario: int = int(proposta.get("salario", jogador.salario_pedido))
	return {
		"salario": salario,
		"duracao_meses": int(proposta.get("duracao_meses", 12)),
		"luvas": int(proposta.get("luvas", 0)),
		"multa_rescisoria": int(proposta.get("multa_rescisoria", salario * int(regras["multa_padrao_meses"]))),
		"bonus_titulo": int(proposta.get("bonus_titulo", 0)),
		"bonus_mundial": int(proposta.get("bonus_mundial", 0)),
		"clausula_titular": bool(proposta.get("clausula_titular", false)),
	}


## Valida os campos da proposta. Devolve "" se estiver certa, ou a mensagem do problema.
static func validar(proposta: Dictionary) -> String:
	var duracoes: Array = Dados.contratos()["duracoes_meses"]
	if not float(proposta["duracao_meses"]) in duracoes:
		return "Duração inválida. Opções: %s meses." % ", ".join(duracoes.map(func(d: Variant) -> String: return str(int(d))))
	if int(proposta["salario"]) <= 0:
		return "O salário precisa ser maior que zero."
	for campo: String in ["luvas", "multa_rescisoria", "bonus_titulo", "bonus_mundial"]:
		if int(proposta[campo]) < 0:
			return "Valores não podem ser negativos."
	return ""


## Exigência mensal real do jogador para esta proposta (antes da tolerância).
static func exigencia_mensal(jogador: Jogador, proposta: Dictionary, reputacao: float, renovacao: bool) -> float:
	var regra: Dictionary = Dados.contratos()["negociacao"]
	var exigencia: float = float(jogador.salario_pedido)

	# Multa alta prende o jogador: ele cobra mais por isso (acima de 1 ano de salário).
	var anos_de_multa: float = float(proposta["multa_rescisoria"]) / maxf(float(jogador.salario_pedido) * 12.0, 1.0)
	var acrescimo_multa: float = clampf((anos_de_multa - 1.0) * float(regra["multa_acrescimo_por_ano_extra"]),
		0.0, float(regra["multa_acrescimo_maximo"]))
	exigencia *= 1.0 + acrescimo_multa

	# Jogador mais famoso que a organização cobra mais para "descer de nível".
	var diferenca: float = maxf(0.0, jogador.fama() * 100.0 - reputacao)
	exigencia *= 1.0 + diferenca * float(regra["reputacao_acrescimo_por_ponto"])

	# Na renovação, a lealdade deixa o jogador mais moderado.
	if renovacao:
		exigencia *= 1.0 - (jogador.lealdade / 100.0) * float(regra["lealdade_desconto_maximo"])
	return exigencia


## Quanto a proposta vale por mês, na visão do jogador.
static func valor_mensal(proposta: Dictionary) -> float:
	var regra: Dictionary = Dados.contratos()["negociacao"]
	var valor: float = float(proposta["salario"])
	valor += float(proposta["luvas"]) * float(regra["peso_luvas"]) / maxf(float(proposta["duracao_meses"]), 1.0)
	var bonus: float = float(proposta["bonus_titulo"]) + float(proposta["bonus_mundial"])
	valor += bonus * float(regra["peso_bonus"]) / 12.0
	return valor


## Quanto abaixo da exigência o jogador ainda aceita (0.85 a 0.98).
static func tolerancia(jogador: Jogador) -> float:
	var regra: Dictionary = Dados.contratos()["negociacao"]
	return lerpf(float(regra["tolerancia_iniciante"]), float(regra["tolerancia_estrela"]), jogador.fama())


## Quantas propostas recusadas o jogador aguenta antes de encerrar a conversa.
static func paciencia_inicial(jogador: Jogador) -> int:
	var regra: Dictionary = Dados.contratos()["negociacao"]
	return roundi(lerpf(float(regra["paciencia_iniciante"]), float(regra["paciencia_estrela"]), jogador.fama()))


## Avalia a proposta. Não altera nada.
## Retorno: {"aceita": bool, "motivo": String, "mensagem": String, "dica_salario": int, "ofensiva": bool}
static func avaliar(jogador: Jogador, proposta_bruta: Dictionary, reputacao: float, renovacao: bool = false) -> Dictionary:
	var regra: Dictionary = Dados.contratos()["negociacao"]
	var proposta: Dictionary = normalizar(proposta_bruta, jogador)
	var erro: String = validar(proposta)
	if not erro.is_empty():
		return _resposta(false, MOTIVO_INVALIDA, erro, 0, false)

	if jogador.ego >= int(regra["ego_exige_titular"]) and not proposta["clausula_titular"]:
		return _resposta(false, MOTIVO_EXIGE_TITULAR,
			"%s só assina com cláusula de titular." % jogador.apelido, 0, false)

	var exigencia: float = exigencia_mensal(jogador, proposta, reputacao, renovacao)
	var valor: float = valor_mensal(proposta)
	var dica: int = _arredondar(exigencia, int(regra["arredondar_dica"]))

	if valor >= exigencia * tolerancia(jogador):
		return _resposta(true, MOTIVO_ACEITA, "%s aceitou a proposta!" % jogador.apelido, dica, false)
	if valor < exigencia * float(regra["oferta_ofensiva"]):
		return _resposta(false, MOTIVO_OFENSIVA,
			"%s se sentiu desrespeitado com a proposta. Ele espera algo em torno de R$ %s por mês." % [jogador.apelido, _formatar(dica)],
			dica, true)
	return _resposta(false, MOTIVO_POUCO,
		"%s recusou. Ele espera algo em torno de R$ %s por mês." % [jogador.apelido, _formatar(dica)], dica, false)


## Cria o contrato a partir de uma proposta aceita.
static func criar_contrato(jogador: Jogador, proposta_bruta: Dictionary, dia_atual: int) -> Contrato:
	var proposta: Dictionary = normalizar(proposta_bruta, jogador)
	var contrato: Contrato = Contrato.new()
	contrato.salario = proposta["salario"]
	contrato.luvas = proposta["luvas"]
	contrato.multa_rescisoria = proposta["multa_rescisoria"]
	contrato.bonus_titulo = proposta["bonus_titulo"]
	contrato.bonus_mundial = proposta["bonus_mundial"]
	contrato.clausula_titular = proposta["clausula_titular"]
	contrato.duracao_meses = proposta["duracao_meses"]
	contrato.dia_inicio = dia_atual
	contrato.dia_fim = dia_atual + contrato.duracao_meses * Dados.dias_por_mes() - 1
	return contrato


static func _resposta(aceita: bool, motivo: String, mensagem: String, dica: int, ofensiva: bool) -> Dictionary:
	return {"aceita": aceita, "motivo": motivo, "mensagem": mensagem, "dica_salario": dica, "ofensiva": ofensiva}


static func _arredondar(valor: float, passo: int) -> int:
	return int(ceil(valor / float(passo)) * passo)


## Formato brasileiro de milhar: 12500 -> "12.500".
static func _formatar(valor: int) -> String:
	var texto: String = str(absi(valor))
	var partes: Array[String] = []
	while texto.length() > 3:
		partes.push_front(texto.substr(texto.length() - 3))
		texto = texto.substr(0, texto.length() - 3)
	partes.push_front(texto)
	return ("-" if valor < 0 else "") + ".".join(partes)
