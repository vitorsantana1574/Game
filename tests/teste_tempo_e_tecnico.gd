extends RefCounted
## Testes da etapa 2: passagem do tempo, salários, avisos, fim de contrato e técnico.

const PASTA_TESTE: String = "user://testes_saves"

var executor: Object
var _eventos: Array[String] = []


func antes_de_cada() -> void:
	Jogo.saves.pasta = PASTA_TESTE
	for slot: int in range(SistemaSaves.TOTAL_SLOTS):
		Jogo.saves.excluir(slot)
	Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "normal"})
	_eventos.clear()
	if not Eventos.contrato_vencendo.is_connected(_ao_vencer):
		Eventos.contrato_vencendo.connect(_ao_vencer)
		Eventos.salarios_pagos.connect(func(_t: int) -> void: _eventos.append("pagos"))
		Eventos.salarios_atrasados.connect(func(_d: int, _m: int) -> void: _eventos.append("atrasados"))
		Eventos.jogador_saiu.connect(func(_j: Dictionary, motivo: String) -> void: _eventos.append("saiu:" + motivo))
		Eventos.candidatos_chegaram.connect(func(c: Array[Dictionary]) -> void: _eventos.append("candidatos:%d" % c.size()))


func teste_salario_pago_no_inicio_do_mes() -> void:
	var id: String = _contratar_barato(12)
	var salario: int = Jogo.detalhe_jogador(id)["contrato"]["salario"]
	var verba: int = Jogo.resumo_financeiro()["verba_mensal"]
	var antes: int = Jogo.carreira.organizacao.dinheiro
	Jogo.avancar_dia(29)
	executor.igual(Jogo.carreira.organizacao.dinheiro, antes, "nada pago antes do mês virar")
	Jogo.avancar_dia(1)
	executor.igual(Jogo.carreira.dia, 31, "dia 31 = início do mês 2")
	executor.igual(Jogo.carreira.organizacao.dinheiro, antes + verba - salario, "verba recebida e salário pago")
	executor.verificar("pagos" in _eventos, "emitiu salarios_pagos")


func teste_salario_atrasado_derruba_satisfacao_e_reputacao() -> void:
	var id: String = _contratar_barato(12)
	# Salário maior que a verba da liga, sem dinheiro em caixa: não há como pagar.
	Jogo.carreira.organizacao.jogador_por_id(id).contrato.salario = 50000
	Jogo.carreira.organizacao.dinheiro = 0
	var reputacao: float = Jogo.carreira.organizacao.reputacao
	var satisfacao: float = Jogo.carreira.organizacao.jogador_por_id(id).satisfacao
	Jogo.avancar_dia(30)
	executor.verificar("atrasados" in _eventos, "emitiu salarios_atrasados")
	executor.igual(Jogo.resumo_financeiro()["meses_em_atraso"], 1, "1 mês em atraso")
	executor.verificar(Jogo.carreira.organizacao.reputacao < reputacao, "reputação caiu")
	executor.verificar(Jogo.carreira.organizacao.jogador_por_id(id).satisfacao < satisfacao, "satisfação caiu")
	var devido: int = Jogo.resumo_financeiro()["salarios_atrasados"]
	Jogo.carreira.organizacao.dinheiro = devido * 10
	Jogo.avancar_dia(30)
	executor.igual(Jogo.resumo_financeiro()["salarios_atrasados"], 0, "atraso quitado no mês seguinte")


func teste_avisos_de_contrato_e_fim() -> void:
	# Contrato de 6 meses assinado no dia 1 vale até o dia 180.
	_contratar_barato(6)
	Jogo.avancar_dia(88)
	executor.verificar(not _eventos.has("aviso:90"), "dia 89 (faltam 91): ainda sem aviso")
	Jogo.avancar_dia(1)
	executor.verificar(_eventos.has("aviso:90"), "dia 90 (faltam 90): aviso de 90 dias")
	Jogo.avancar_dia(82)
	executor.verificar(not _eventos.has("aviso:7"), "dia 172 (faltam 8): ainda sem aviso de 7 dias")
	Jogo.avancar_dia(1)
	executor.verificar(_eventos.has("aviso:7"), "dia 173 (faltam 7): aviso de 7 dias")
	executor.igual(_eventos.count("aviso:90"), 1, "aviso de 90 dias não se repete")
	Jogo.avancar_dia(7)
	executor.verificar(not "saiu:contrato_encerrado" in _eventos, "dia 180: contrato ainda vale")
	Jogo.avancar_dia(1)
	executor.verificar("saiu:contrato_encerrado" in _eventos, "jogador sai quando o contrato acaba")
	executor.verificar(Jogo.listar_elenco().is_empty(), "elenco vazio")


func teste_mercado_renova_todo_mes() -> void:
	var ids_antes: Array = Jogo.listar_mercado().map(func(j: Dictionary) -> String: return j["id"])
	Jogo.avancar_dia(30)
	var ids_depois: Array = Jogo.listar_mercado().map(func(j: Dictionary) -> String: return j["id"])
	var novos: int = ids_depois.filter(func(id: String) -> bool: return not id in ids_antes).size()
	executor.igual(ids_depois.size(), 40, "tamanho do mercado mantido")
	executor.verificar(novos >= 5 and novos <= 10, "cerca de 25%% renovado (%d novos)" % novos)


func teste_anuncio_e_contratacao_de_tecnico() -> void:
	var antes: int = Jogo.carreira.organizacao.dinheiro
	var r: Dictionary = Jogo.publicar_anuncio("medio", 4000)
	executor.verificar(r["ok"], "anúncio publicado")
	executor.igual(Jogo.carreira.organizacao.dinheiro, antes - 3000, "custo do anúncio médio cobrado")
	executor.igual(r["dias_espera"], 7, "oferta igual à referência: espera padrão")
	executor.verificar(not Jogo.publicar_anuncio("pequeno", 4000)["ok"], "só um anúncio por vez")
	executor.verificar(Jogo.listar_candidatos_tecnico().is_empty(), "candidatos ainda não chegaram")
	Jogo.avancar_dia(7)
	var candidatos: Array[Dictionary] = Jogo.listar_candidatos_tecnico()
	executor.verificar(candidatos.size() >= 2 and candidatos.size() <= 3, "anúncio médio traz até 3 (%d)" % candidatos.size())
	executor.verificar(_eventos.any(func(e: String) -> bool: return e.begins_with("candidatos:")), "emitiu candidatos_chegaram")
	executor.verificar(candidatos[0]["salario_pedido"] >= 4000, "candidato pede pelo menos a oferta")
	executor.verificar(Jogo.contratar_tecnico(candidatos[0]["id"], 12)["ok"], "contratou")
	executor.igual(Jogo.tecnico_atual()["id"], candidatos[0]["id"], "técnico atual")
	executor.verificar(Jogo.listar_candidatos_tecnico().is_empty(), "outros candidatos dispensados")
	executor.verificar(Jogo.resumo_financeiro()["folha_mensal"] >= 4000, "salário do técnico entra na folha")


func teste_oferta_maior_acelera_e_atrai_melhores() -> void:
	executor.verificar(Jogo.prever_espera_anuncio("grande", 12000) < Jogo.prever_espera_anuncio("grande", 4000), "oferta alta chega mais rápido")
	executor.verificar(Jogo.prever_espera_anuncio("grande", 1500) > Jogo.prever_espera_anuncio("grande", 4000), "oferta baixa demora mais")
	var carreira: Carreira = Jogo.carreira
	var baratos: float = _media(SistemaTecnicos.gerar_candidatos(carreira, "grande", 1500))
	var caros: float = _media(SistemaTecnicos.gerar_candidatos(carreira, "grande", 16000))
	executor.verificar(caros > baratos, "oferta alta atrai técnicos melhores (%.0f x %.0f)" % [caros, baratos])


func teste_candidatos_expiram() -> void:
	Jogo.publicar_anuncio("pequeno", 4000)
	Jogo.avancar_dia(5)
	executor.igual(Jogo.listar_candidatos_tecnico().size(), 1, "anúncio pequeno traz 1 candidato")
	Jogo.avancar_dia(15)
	executor.verificar(Jogo.listar_candidatos_tecnico().is_empty(), "candidato desiste depois de 14 dias")


func teste_dispensar_tecnico() -> void:
	Jogo.publicar_anuncio("pequeno", 4000)
	Jogo.avancar_dia(5)
	Jogo.contratar_tecnico(Jogo.listar_candidatos_tecnico()[0]["id"], 12)
	executor.verificar(not Jogo.publicar_anuncio("pequeno", 4000).is_empty(), "pode anunciar mesmo com técnico")
	executor.verificar(Jogo.dispensar_tecnico()["ok"], "dispensou")
	executor.verificar(Jogo.tecnico_atual().is_empty(), "sem técnico")


func teste_save_preserva_anuncio_e_tecnico() -> void:
	Jogo.publicar_anuncio("pequeno", 4000)
	Jogo.salvar()
	Jogo.carreira = null
	Jogo.carregar(0)
	executor.verificar(not Jogo.estado_anuncio().is_empty(), "anúncio preservado")
	Jogo.avancar_dia(5)
	Jogo.contratar_tecnico(Jogo.listar_candidatos_tecnico()[0]["id"], 24)
	Jogo.salvar()
	Jogo.carreira = null
	Jogo.carregar(0)
	executor.igual(Jogo.tecnico_atual()["contrato"]["duracao_meses"], 24, "técnico e contrato preservados")


func _contratar_barato(meses: int) -> String:
	var lista: Array[Jogador] = Jogo.carreira.mercado.duplicate()
	lista.sort_custom(func(a: Jogador, b: Jogador) -> bool: return a.salario_pedido < b.salario_pedido)
	var jogador: Jogador = lista[0]
	jogador.ego = 0
	Jogo.fazer_proposta(jogador.id, {"salario": jogador.salario_pedido * 2, "duracao_meses": meses})
	return jogador.id


func _media(tecnicos: Array[Tecnico]) -> float:
	var soma: float = 0.0
	for tecnico: Tecnico in tecnicos:
		soma += tecnico.nivel_geral()
	return soma / maxf(tecnicos.size(), 1.0)


func _ao_vencer(_pessoa: Dictionary, _tipo: String, dias: int) -> void:
	_eventos.append("aviso:%d" % (90 if dias > 7 else 7))
