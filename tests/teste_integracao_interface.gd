extends RefCounted
## Testes do que a lógica passou a oferecer para a sede do GPT:
## bandeira no save, livro de lançamentos, totais das finanças, regras de renovação, aparência e histórico.

const PASTA_TESTE: String = "user://testes_saves"

var executor: Object


func antes_de_cada() -> void:
	Jogo.saves.pasta = PASTA_TESTE
	for slot: int in range(SistemaSaves.TOTAL_SLOTS):
		Jogo.saves.excluir(slot)


func _png_base64(largura: int = Bandeira.LARGURA, altura: int = Bandeira.ALTURA) -> String:
	var imagem: Image = Image.create(largura, altura, false, Image.FORMAT_RGBA8)
	imagem.fill(Color(0.1, 0.5, 0.3))
	return Marshalls.raw_to_base64(imagem.save_png_to_buffer())


func _contratar_um() -> Jogador:
	var barato: Jogador = Jogo.carreira.mercado[0]
	for jogador: Jogador in Jogo.carreira.mercado:
		if jogador.salario_pedido < barato.salario_pedido:
			barato = jogador
	Jogo.fazer_proposta(barato.id, {"salario": barato.salario_pedido * 2, "duracao_meses": 6, "luvas": 1000})
	return barato


func teste_bandeira_na_criacao_e_no_save() -> void:
	var png: String = _png_base64()
	var r: Dictionary = Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "normal", "bandeira_png": png})
	executor.verificar(r["ok"], "carreira criada com bandeira")
	executor.igual(Jogo.resumo_carreira()["bandeira_png"], png, "resumo traz a bandeira")
	executor.igual(Jogo.listar_saves()[r["slot"]]["bandeira_png"], png, "resumo do save traz a bandeira")
	Jogo.carregar(r["slot"])
	executor.igual(Jogo.resumo_carreira()["bandeira_png"], png, "bandeira sobrevive ao carregar")


func teste_bandeira_invalida_recusada() -> void:
	var r: Dictionary = Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "normal", "bandeira_png": "não é base64"})
	executor.verificar(not r["ok"] and r["erros"].has("bandeira"), "texto inválido é recusado")
	r = Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "normal", "bandeira_png": _png_base64(100, 100)})
	executor.verificar(not r["ok"] and r["erros"].has("bandeira"), "tamanho errado é recusado")
	executor.igual(Jogo.listar_saves()[0], {}, "nada foi gravado")
	r = Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "normal"})
	executor.igual(Jogo.resumo_carreira()["bandeira_png"], "", "sem bandeira = arte padrão")


func teste_trocar_bandeira() -> void:
	Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "normal"})
	var png: String = _png_base64()
	executor.verificar(Jogo.definir_bandeira(png)["ok"], "bandeira trocada")
	executor.verificar(not Jogo.definir_bandeira("xyz")["ok"], "troca inválida recusada")
	Jogo.salvar()
	Jogo.carregar(Jogo.slot_atual)
	executor.igual(Jogo.resumo_carreira()["bandeira_png"], png, "troca vai para o save")


func teste_livro_de_lancamentos() -> void:
	Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "normal"})
	var inicial: Array[Dictionary] = Jogo.listar_lancamentos()
	executor.igual(inicial.size(), 1, "começa com o capital inicial")
	executor.igual(inicial[0]["categoria"], "capital", "categoria do capital")
	var jogador: Jogador = _contratar_um()
	Jogo.avancar_dia(30)
	var lista: Array[Dictionary] = Jogo.listar_lancamentos()
	executor.igual(lista[0]["dia"], 31, "mais novo primeiro: dia de pagamento")
	executor.igual(lista[1]["categoria"], "verba", "no dia de pagamento a verba entra antes dos salários")
	var categorias: Array = lista.map(func(item: Dictionary) -> String: return item["categoria"])
	executor.verificar(categorias.has("luvas") and categorias.has("salarios"), "luvas e salários registrados")
	var soma: int = 0
	for item: Dictionary in lista:
		soma += int(item["valor"])
	executor.igual(soma, Jogo.carreira.organizacao.dinheiro, "a soma dos lançamentos fecha com o dinheiro")
	executor.verificar(not String(lista[0]["data_texto"]).is_empty(), "lançamento traz a data em texto")
	Jogo.salvar()
	Jogo.carregar(Jogo.slot_atual)
	executor.igual(Jogo.listar_lancamentos().size(), lista.size(), "livro sobrevive ao carregar")
	executor.igual(Jogo.listar_lancamentos(2).size(), 2, "limite respeitado")
	executor.verificar(jogador != null, "contratou")


func teste_gastos_previstos() -> void:
	Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "normal"})
	_contratar_um()
	Jogo.contratar_emprestimo(20000, 6)
	var resumo: Dictionary = Jogo.resumo_financeiro()
	executor.igual(resumo["gastos_previstos"], resumo["folha_mensal"] + resumo["parcela_emprestimo"],
		"gastos previstos = folha + parcela (sem atrasos)")


func teste_regras_de_renovacao_na_ficha() -> void:
	Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "normal"})
	var jogador: Jogador = _contratar_um()
	var ficha: Dictionary = Jogo.detalhe_jogador(jogador.id)
	var dias: int = int(Dados.contratos()["renovacao"]["dias_restantes_para_renovar"])
	var restantes: int = int(ficha["contrato"]["dias_restantes"])
	executor.igual(ficha["contrato"]["pode_renovar"], restantes <= dias, "pode_renovar segue a regra da lógica")
	executor.igual(ficha["contrato"]["dias_para_poder_renovar"], maxi(0, restantes - dias), "dias até poder renovar")
	executor.verificar(not ficha.has("exige_titularidade") or jogador.traco_revelado("ego"), "exigência só aparece com ego revelado")


func teste_aparencia_e_historico() -> void:
	Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "normal"})
	var total: int = int(Dados.balanceamento()["aparencias"])
	var ok: bool = true
	var vistas: Dictionary = {}
	for jogador: Jogador in Jogo.carreira.mercado:
		ok = ok and jogador.aparencia >= 0 and jogador.aparencia < total
		vistas[jogador.aparencia] = true
	executor.verificar(ok, "aparência dentro do intervalo")
	executor.verificar(vistas.size() >= 5, "aparências variadas no mercado (%d)" % vistas.size())
	var alvo: Jogador = Jogo.carreira.mercado[0]
	alvo.partidas_por_campeao = {"veluria": 18, "orvante": 3, "prismora": 18, "kordume": 1}
	var ficha: Dictionary = Jogo.detalhe_jogador(alvo.id)
	executor.igual(ficha["aparencia"], alvo.aparencia, "ficha traz a aparência")
	executor.igual(ficha["historico_campeoes"]["mais_jogados"],
		[{"id": "prismora", "partidas": 18}, {"id": "veluria", "partidas": 18}, {"id": "orvante", "partidas": 3}],
		"até 3 campeões, do mais jogado para o menos (empate por id)")
	executor.igual(ficha["historico_campeoes"]["disponivel"], false, "histórico indisponível até existir a simulação de partidas")
	Jogo.salvar()
	Jogo.carregar(Jogo.slot_atual)
	var recarregado: Jogador = Jogo.carreira.jogador_do_mercado(alvo.id)
	executor.igual(recarregado.aparencia, alvo.aparencia, "aparência salva")
	executor.igual(recarregado.partidas_por_campeao["veluria"], 18, "partidas por campeão salvas")


func teste_save_antigo_sem_campos_novos() -> void:
	Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "normal"})
	var dados: Dictionary = Jogo.carreira.para_dicionario()
	dados.erase("lancamentos")
	dados["organizacao"].erase("bandeira_png")
	for jogador: Dictionary in dados["mercado"]:
		jogador.erase("aparencia")
		jogador.erase("partidas_por_campeao")
	var antiga: Carreira = Carreira.de_dicionario(dados)
	executor.igual(antiga.organizacao.bandeira_png, "", "bandeira vazia em save antigo")
	executor.igual(antiga.lancamentos.size(), 0, "livro vazio em save antigo")
	executor.igual(antiga.mercado[0].aparencia, Jogador.aparencia_do_id(antiga.mercado[0].id), "aparência derivada do id")


func teste_avancar_ate_evento() -> void:
	Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "normal"})
	var r: Dictionary = Jogo.avancar_ate_evento(60)
	executor.igual(r["dias_avancados"], 30, "sem elenco, o primeiro evento é a verba do dia 31")
	executor.verificar((r["eventos"] as Array).has("verba_recebida"), "evento informado")
	executor.igual(Jogo.carreira.dia, 31, "parou no dia do evento")
	r = Jogo.avancar_ate_evento(5)
	executor.igual(r["dias_avancados"], 5, "respeita o máximo de dias")
	executor.igual(r["eventos"], [], "nenhum evento nesses dias")
