extends RefCounted
## Testes da etapa 2: mercado, negociação, contratação, renovação, rescisão e titulares.

const PASTA_TESTE: String = "user://testes_saves"

var executor: Object


func antes_de_cada() -> void:
	Jogo.saves.pasta = PASTA_TESTE
	for slot: int in range(SistemaSaves.TOTAL_SLOTS):
		Jogo.saves.excluir(slot)
	Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "normal"})


func teste_mercado_inicial() -> void:
	var lista: Array[Dictionary] = Jogo.listar_mercado()
	executor.igual(lista.size(), 40, "40 agentes livres (8 por posição)")
	executor.igual(Jogo.listar_mercado({"posicao": "selva"}).size(), 8, "filtro por posição")
	executor.verificar(lista[0]["nivel_geral"] >= lista[-1]["nivel_geral"], "ordenado por nível, do melhor para o pior")
	var por_salario: Array[Dictionary] = Jogo.listar_mercado({"ordenar": "salario"})
	executor.verificar(por_salario[0]["salario_pedido"] <= por_salario[-1]["salario_pedido"], "ordenar por salário")
	executor.verificar(lista[0].has("negociacao") and lista[0]["contrato"].is_empty(), "agente livre sem contrato, com estado de negociação")


func teste_proposta_justa_e_aceita() -> void:
	var jogador: Jogador = _mais_barato()
	var r: Dictionary = Jogo.fazer_proposta(jogador.id, {"salario": jogador.salario_pedido * 2, "duracao_meses": 12})
	executor.verificar(r["ok"] and r["aceita"], "proposta generosa é aceita")
	executor.igual(Jogo.listar_elenco().size(), 1, "jogador entrou no elenco")
	executor.verificar(Jogo.carreira.jogador_do_mercado(jogador.id) == null, "saiu do mercado")
	var contrato: Dictionary = Jogo.listar_elenco()[0]["contrato"]
	executor.igual(contrato["duracao_meses"], 12, "duração gravada")
	executor.igual(contrato["dias_restantes"], 359, "12 meses = 360 dias (vale até o fim do último dia)")


func teste_proposta_baixa_consome_paciencia_e_bloqueia() -> void:
	var jogador: Jogador = _mais_barato()
	var paciencia: int = Negociacao.paciencia_inicial(jogador)
	var r: Dictionary = Jogo.fazer_proposta(jogador.id, {"salario": int(jogador.salario_pedido * 0.7)})
	executor.verificar(r["ok"] and not r["aceita"], "proposta 30% abaixo é recusada")
	executor.verificar(r["dica_salario"] >= jogador.salario_pedido * 0.9, "dá uma dica do salário esperado")
	executor.igual(r["paciencia"], paciencia - 1, "perdeu 1 de paciência")
	var ultima: Dictionary = {}
	for vez: int in range(paciencia):
		ultima = Jogo.fazer_proposta(jogador.id, {"salario": int(jogador.salario_pedido * 0.7)})
		if ultima.get("bloqueado", false):
			break
	executor.verificar(ultima.get("bloqueado", false), "encerra a negociação quando a paciência acaba")
	var depois: Dictionary = Jogo.fazer_proposta(jogador.id, {"salario": jogador.salario_pedido * 3})
	executor.verificar(not depois["ok"] and depois["erros"].has("jogador"), "bloqueado não aceita nem proposta ótima")
	Jogo.avancar_dia(15)
	executor.verificar(Jogo.fazer_proposta(jogador.id, {"salario": jogador.salario_pedido * 3})["aceita"], "volta a negociar depois de 15 dias")


func teste_proposta_ofensiva_custa_dois() -> void:
	var jogador: Jogador = _mais_barato()
	var paciencia: int = Negociacao.paciencia_inicial(jogador)
	var r: Dictionary = Jogo.fazer_proposta(jogador.id, {"salario": int(jogador.salario_pedido * 0.4)})
	executor.verificar(r["paciencia"] == paciencia - 2 or r["bloqueado"], "oferta ofensiva tira 2 de paciência")


func teste_iniciante_aceita_um_pouco_abaixo_e_estrela_nao() -> void:
	var gerador: GeradorJogadores = GeradorJogadores.new(99)
	var iniciante: Jogador = gerador.gerar({"qualidade": 30, "idade": 17})
	var estrela: Jogador = gerador.gerar({"qualidade": 92, "idade": 26})
	estrela.ego = 10
	iniciante.ego = 10
	var proposta_iniciante: Dictionary = {"salario": int(iniciante.salario_pedido * 0.9)}
	var proposta_estrela: Dictionary = {"salario": int(estrela.salario_pedido * 0.9)}
	executor.verificar(Negociacao.avaliar(iniciante, proposta_iniciante, 100.0)["aceita"], "iniciante aceita 10% abaixo")
	executor.verificar(not Negociacao.avaliar(estrela, proposta_estrela, 100.0)["aceita"], "estrela recusa 10% abaixo")
	executor.verificar(Negociacao.paciencia_inicial(iniciante) > Negociacao.paciencia_inicial(estrela), "estrela tem menos paciência")


func teste_luvas_ajudam_a_convencer() -> void:
	var estrela: Jogador = GeradorJogadores.new(5).gerar({"qualidade": 90, "idade": 25})
	estrela.ego = 10
	var sem_luvas: Dictionary = {"salario": int(estrela.salario_pedido * 0.85), "duracao_meses": 12}
	var com_luvas: Dictionary = sem_luvas.duplicate()
	com_luvas["luvas"] = estrela.salario_pedido * 3
	executor.verificar(not Negociacao.avaliar(estrela, sem_luvas, 100.0)["aceita"], "sem luvas, recusa")
	executor.verificar(Negociacao.avaliar(estrela, com_luvas, 100.0)["aceita"], "com luvas, aceita")


func teste_multa_alta_e_reputacao_baixa_encarecem() -> void:
	var jogador: Jogador = GeradorJogadores.new(8).gerar({"qualidade": 80, "idade": 24})
	var normal: Dictionary = Negociacao.normalizar({}, jogador)
	var multa_alta: Dictionary = Negociacao.normalizar({"multa_rescisoria": jogador.salario_pedido * 48}, jogador)
	executor.verificar(Negociacao.exigencia_mensal(jogador, multa_alta, 100.0, false) > Negociacao.exigencia_mensal(jogador, normal, 100.0, false),
		"multa de 4 anos de salário aumenta a exigência")
	executor.verificar(Negociacao.exigencia_mensal(jogador, normal, 5.0, false) > Negociacao.exigencia_mensal(jogador, normal, 100.0, false),
		"organização com pouca reputação paga mais")


func teste_ego_alto_exige_titular() -> void:
	var jogador: Jogador = GeradorJogadores.new(4).gerar({"qualidade": 50})
	jogador.ego = 90
	var sem: Dictionary = Negociacao.avaliar(jogador, {"salario": jogador.salario_pedido * 2}, 100.0)
	executor.igual(sem["motivo"], Negociacao.MOTIVO_EXIGE_TITULAR, "recusa sem cláusula de titular")
	var com: Dictionary = Negociacao.avaliar(jogador, {"salario": jogador.salario_pedido * 2, "clausula_titular": true}, 100.0)
	executor.verificar(com["aceita"], "aceita com a cláusula")


func teste_luvas_sem_dinheiro_nao_consomem_paciencia() -> void:
	var jogador: Jogador = _mais_barato()
	var r: Dictionary = Jogo.fazer_proposta(jogador.id, {"salario": jogador.salario_pedido, "luvas": 10_000_000})
	executor.verificar(not r["ok"] and r["erros"].has("dinheiro"), "recusa por falta de dinheiro")
	executor.verificar(not Jogo.carreira.negociacoes.has(jogador.id), "não abriu negociação nem gastou paciência")


func teste_luvas_sao_cobradas() -> void:
	var jogador: Jogador = _mais_barato()
	var antes: int = Jogo.carreira.organizacao.dinheiro
	Jogo.fazer_proposta(jogador.id, {"salario": jogador.salario_pedido * 2, "luvas": 5000})
	executor.igual(Jogo.carreira.organizacao.dinheiro, antes - 5000, "luvas descontadas do caixa")


func teste_elenco_maximo_de_dez() -> void:
	for vez: int in range(10):
		var jogador: Jogador = _mais_barato()
		jogador.ego = 0
		Jogo.fazer_proposta(jogador.id, {"salario": jogador.salario_pedido * 2})
	executor.igual(Jogo.listar_elenco().size(), 10, "10 contratados")
	var outro: Jogador = _mais_barato()
	var r: Dictionary = Jogo.fazer_proposta(outro.id, {"salario": outro.salario_pedido * 2})
	executor.verificar(not r["ok"] and r["erros"].has("elenco"), "não passa de 10")


func teste_titulares() -> void:
	var ids: Array[String] = _contratar(3)
	var certo: Dictionary = Jogo.definir_titulares({"topo": ids[0], "meio": ids[1]})
	executor.verificar(certo["ok"], "define titulares")
	executor.verificar(Jogo.detalhe_jogador(ids[0])["titular"], "jogador marcado como titular")
	executor.igual(Jogo.detalhe_jogador(ids[0])["posicao_titular"], "topo", "posição do titular")
	executor.verificar(not Jogo.definir_titulares({"topo": ids[0], "meio": ids[0]})["ok"], "não repete jogador")
	executor.verificar(not Jogo.definir_titulares({"lateral": ids[2]})["ok"], "posição inválida")


func teste_dispensa_cobra_rescisao_e_devolve_ao_mercado() -> void:
	var id: String = _contratar(1)[0]
	Jogo.definir_titulares({"topo": id})
	var custo: int = Jogo.custo_rescisao(id)
	var salario: int = Jogo.detalhe_jogador(id)["contrato"]["salario"]
	executor.verificar(custo > salario * 5 and custo < salario * 6.1, "rescisão ≈ metade dos 12 salários restantes")
	var antes: int = Jogo.carreira.organizacao.dinheiro
	executor.verificar(Jogo.dispensar_jogador(id)["ok"], "dispensou")
	executor.igual(Jogo.carreira.organizacao.dinheiro, antes - custo, "pagou a rescisão")
	executor.verificar(Jogo.listar_elenco().is_empty(), "saiu do elenco")
	executor.verificar(Jogo.titulares().is_empty(), "saiu dos titulares")
	executor.verificar(Jogo.carreira.jogador_do_mercado(id) != null, "voltou ao mercado")


func teste_renovacao_so_perto_do_fim() -> void:
	var id: String = _contratar(1, 6)[0]
	var cedo: Dictionary = Jogo.renovar_contrato(id, {"salario": 99999})
	executor.verificar(not cedo["ok"] and cedo["erros"].has("jogador"), "não renova faltando mais de 90 dias")
	Jogo.avancar_dia(100)
	var salario: int = Jogo.detalhe_jogador(id)["salario_pedido"]
	var r: Dictionary = Jogo.renovar_contrato(id, {"salario": salario * 2, "duracao_meses": 24})
	executor.verificar(r["ok"] and r["aceita"], "renova perto do fim")
	executor.igual(Jogo.detalhe_jogador(id)["contrato"]["duracao_meses"], 24, "novo contrato de 24 meses")


func teste_save_preserva_contratos_e_mercado() -> void:
	var id: String = _contratar(1)[0]
	Jogo.definir_titulares({"selva": id})
	var mercado_antes: int = Jogo.listar_mercado().size()
	Jogo.salvar()
	Jogo.carreira = null
	Jogo.carregar(0)
	executor.igual(Jogo.listar_mercado().size(), mercado_antes, "mercado preservado")
	executor.igual(Jogo.titulares(), {"selva": id}, "titulares preservados")
	executor.igual(Jogo.detalhe_jogador(id)["contrato"]["duracao_meses"], 12, "contrato preservado")


## Jogador mais barato do mercado, com ego baixo para não exigir cláusula de titular.
func _mais_barato() -> Jogador:
	var lista: Array[Jogador] = Jogo.carreira.mercado.duplicate()
	lista.sort_custom(func(a: Jogador, b: Jogador) -> bool: return a.salario_pedido < b.salario_pedido)
	lista[0].ego = 0
	return lista[0]


func _contratar(quantidade: int, meses: int = 12) -> Array[String]:
	var ids: Array[String] = []
	for vez: int in range(quantidade):
		var jogador: Jogador = _mais_barato()
		Jogo.fazer_proposta(jogador.id, {"salario": jogador.salario_pedido * 2, "duracao_meses": meses})
		ids.append(jogador.id)
	return ids
