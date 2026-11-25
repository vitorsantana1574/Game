extends RefCounted
## Testes do simulador de partidas, da narração e da partida depois do draft.

const PASTA_TESTE: String = "user://testes_saves"

var executor: Object
var _sinais: int = 0


func antes_de_cada() -> void:
	Jogo.saves.pasta = PASTA_TESTE
	for slot: int in range(SistemaSaves.TOTAL_SLOTS):
		Jogo.saves.excluir(slot)
	Jogo.encerrar_draft()
	Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "facil"})


## Dois times gerados com a qualidade pedida; cada jogador joga o campeão principal da posição que mais domina.
func _entrada(qualidade_azul: float, qualidade_vermelho: float, semente: int) -> Dictionary:
	var gerador: GeradorJogadores = GeradorJogadores.new(semente)
	var por_posicao: Dictionary = {}
	for campeao: Dictionary in Dados.campeoes()["campeoes"]:
		var principal: String = str(campeao["posicoes"][0])
		if not por_posicao.has(principal):
			por_posicao[principal] = []
		por_posicao[principal].append(campeao["id"])
	var times: Array[Dictionary] = []
	for indice: int in range(2):
		var jogadores: Array[Dictionary] = []
		for posicao: String in SimuladorPartida.POSICOES:
			var j: Jogador = gerador.gerar({"qualidade": [qualidade_azul, qualidade_vermelho][indice], "posicao": posicao})
			var melhor: String = ""
			for id: String in por_posicao[posicao]:
				if melhor == "" or int(j.dominio_campeoes.get(id, 0)) > int(j.dominio_campeoes.get(melhor, 0)):
					melhor = id
			jogadores.append({"posicao": posicao, "jogador": j, "campeao": melhor})
		times.append({"nome": ["Azul FC", "Rubro EC"][indice], "jogadores": jogadores})
	return {"times": times, "forcas_patch": {}, "semente": semente}


func _concluir_draft() -> void:
	var titulares: Dictionary = {}
	for posicao: String in Draft.POSICOES:
		var escolhido: Jogador = null
		for jogador: Jogador in Jogo.carreira.mercado:
			if jogador.posicao_principal == posicao and (escolhido == null or jogador.salario_pedido < escolhido.salario_pedido):
				escolhido = jogador
		Jogo.fazer_proposta(escolhido.id, {"salario": escolhido.salario_pedido * 2, "duracao_meses": 6})
		titulares[posicao] = escolhido.id
	Jogo.definir_titulares(titulares)
	Jogo.iniciar_draft()
	var vezes: int = 0
	while not Jogo.estado_draft()["concluido"] and vezes < 30:
		Jogo.delegar_vez_ao_tecnico()
		vezes += 1


# --- Simulador ----------------------------------------------------------------------

func teste_mesma_semente_mesma_partida() -> void:
	var a: Dictionary = SimuladorPartida.simular(_entrada(50, 50, 77))
	var b: Dictionary = SimuladorPartida.simular(_entrada(50, 50, 77))
	executor.igual([a["vencedor"], a["duracao"], a["eventos"].size()], [b["vencedor"], b["duracao"], b["eventos"].size()], "mesma semente, mesma partida")
	executor.verificar(JSON.stringify(a["eventos"]) == JSON.stringify(b["eventos"]), "mesmos lances e mesmas falas")
	var c: Dictionary = SimuladorPartida.simular(_entrada(50, 50, 78))
	executor.verificar(JSON.stringify(a["eventos"]) != JSON.stringify(c["eventos"]), "outra semente, outra partida")


func teste_estrutura_do_resultado() -> void:
	var r: Dictionary = SimuladorPartida.simular(_entrada(55, 50, 5))
	executor.verificar(r["vencedor"] in [0, 1], "tem vencedor")
	executor.igual(r["jogadores"].size(), 10, "10 jogadores na estatística final")
	executor.igual(r["eventos"][0]["tipo"], "inicio", "a linha do tempo começa no início")
	executor.igual(r["eventos"][-1]["tipo"], "vitoria", "e termina na vitória")
	var ordenado: bool = true
	for i: int in range(1, r["eventos"].size()):
		ordenado = ordenado and int(r["eventos"][i]["t"]) >= int(r["eventos"][i - 1]["t"]) and int(r["eventos"][i]["indice"]) == i
	executor.verificar(ordenado, "lances em ordem de tempo, com índice sequencial")
	var quadros_ok: bool = true
	for q: Dictionary in r["quadros"]:
		quadros_ok = quadros_ok and q["campeoes"].size() == 10
		for c: Dictionary in q["campeoes"]:
			quadros_ok = quadros_ok and float(c["x"]) >= 0.0 and float(c["x"]) <= 1.0 and float(c["y"]) >= 0.0 and float(c["y"]) <= 1.0
	executor.verificar(quadros_ok, "cada quadro tem os 10 campeões dentro do mapa")
	executor.verificar(int(r["quadros"][1]["t"]) - int(r["quadros"][0]["t"]) == 5, "um quadro a cada 5 segundos")
	var abates_eventos: Array[int] = [0, 0]
	for e: Dictionary in r["eventos"]:
		if e["tipo"] == "abate":
			abates_eventos[int(e["time"])] += 1
	var abates_jogadores: Array[int] = [0, 0]
	var mortes: int = 0
	for j: Dictionary in r["jogadores"]:
		abates_jogadores[int(j["time"])] += int(j["abates"])
		mortes += int(j["mortes"])
	executor.igual(abates_eventos, [int(r["placar"]["abates"][0]), int(r["placar"]["abates"][1])], "placar de abates bate com os lances")
	executor.igual(abates_jogadores, abates_eventos, "e com a estatística dos jogadores")
	executor.igual(mortes, abates_eventos[0] + abates_eventos[1], "cada abate é uma morte")


func teste_narracao_limpa() -> void:
	var problemas: Array[String] = []
	for semente: int in range(6):
		var r: Dictionary = SimuladorPartida.simular(_entrada(50, 50, 300 + semente))
		for e: Dictionary in r["eventos"]:
			for fala: Dictionary in e["narracao"]:
				var texto: String = fala["texto"]
				if texto.contains("{") or texto.contains("}"):
					problemas.append("marcador sobrando: " + texto)
				if texto.is_empty() or texto[0] != texto[0].to_upper():
					problemas.append("começa minúscula: " + texto)
				if fala["voz"] not in ["narrador", "comentarista"]:
					problemas.append("voz desconhecida: " + fala["voz"])
	executor.verificar(problemas.is_empty(), "narração sem marcador sobrando e com maiúscula: %s" % str(problemas.slice(0, 3)))


func teste_frases_seguem_regras_de_escrita() -> void:
	var ruins: Array[String] = []
	var marcadores_validos: Array[String] = ["jogador", "campeao", "alvo", "alvo_campeao", "time", "rival", "rota",
		"na_rota", "da_rota", "local", "minuto", "ouro", "quantidade", "abates_texto", "cacador", "objetivo", "pelo_objetivo"]
	var regex: RegEx = RegEx.create_from_string("\\{([a-z_]+)\\}")
	var artigo: RegEx = RegEx.create_from_string("(\\b[dn]?[oa]s? |\\bd)\\{(jogador|alvo|time|rival|cacador|campeao|alvo_campeao)\\}")
	for tipo: String in Narracao.dados()["eventos"]:
		var evento: Dictionary = Narracao.dados()["eventos"][tipo]
		for lista: String in evento:
			for frase: Variant in evento[lista]:
				for achado: RegExMatch in regex.search_all(str(frase)):
					if not marcadores_validos.has(achado.get_string(1)):
						ruins.append("marcador desconhecido em %s: %s" % [tipo, frase])
				if artigo.search(str(frase)) != null:
					ruins.append("artigo antes de nome em %s: %s" % [tipo, frase])
	executor.verificar(ruins.is_empty(), "frases sem artigo antes de nome e só com marcadores conhecidos: %s" % str(ruins.slice(0, 3)))


func teste_preencher_poe_maiuscula() -> void:
	executor.igual(Narracao.preencher("{objetivo} vai para {time}!", {"objetivo": "a Hydra", "time": "Vale Rift"}),
		"A Hydra vai para Vale Rift!", "maiúscula quando o marcador abre a frase")
	executor.igual(Narracao.preencher("Ninguém acredita! {objetivo} caiu.", {"objetivo": "o Cérbero"}),
		"Ninguém acredita! O Cérbero caiu.", "maiúscula depois de exclamação")
	executor.igual(Narracao.preencher("Todo mundo posicionado... e começa!", {}),
		"Todo mundo posicionado... e começa!", "reticências não pedem maiúscula")


func teste_time_mais_forte_vence_mais() -> void:
	var vitorias: int = 0
	var n: int = 40
	for i: int in range(n):
		var forte_azul: bool = i % 2 == 0
		var r: Dictionary = SimuladorPartida.simular(_entrada(70 if forte_azul else 45, 45 if forte_azul else 70, 900 + i))
		if (int(r["vencedor"]) == 0) == forte_azul:
			vitorias += 1
	executor.verificar(vitorias >= 30, "time 25 pontos melhor vence a maioria (%d de %d)" % [vitorias, n])


func teste_dominio_pesa_no_micro_mas_nao_vira_o_jogo() -> void:
	# Alguém de Micro 80 num campeão que não conhece ainda rende um pouco mais que alguém de Micro 55 no favorito.
	var sim: SimuladorPartida = SimuladorPartida.new()
	sim.cfg = Dados.partida()
	sim.sim = sim.cfg["simulacao"]
	var micro_alto: float = 0.0
	var micro_baixo: float = 0.0
	var farm_desconhecido: float = 0.0
	var gerador: GeradorJogadores = GeradorJogadores.new(4)
	for i: int in range(60):
		sim.rng.seed = i
		var alto: Jogador = gerador.gerar({"qualidade": 60, "posicao": "meio"})
		alto.atributos["micro"] = 80
		alto.atributos["farm"] = 70
		alto.atributos["mental"] = 70
		alto.dominio_campeoes["prismora"] = 0
		var baixo: Jogador = gerador.gerar({"qualidade": 60, "posicao": "meio"})
		baixo.atributos["micro"] = 55
		baixo.atributos["mental"] = 70
		baixo.dominio_campeoes["prismora"] = 95
		var p_alto: SimuladorPartida.Participante = sim._criar_participante(0, {"jogador": alto, "posicao": "meio", "campeao": "prismora"}, {}, {})
		var p_baixo: SimuladorPartida.Participante = sim._criar_participante(1, {"jogador": baixo, "posicao": "meio", "campeao": "prismora"}, {}, {})
		micro_alto += p_alto.micro
		micro_baixo += p_baixo.micro
		farm_desconhecido += p_alto.farm
	executor.verificar(micro_alto > micro_baixo, "habilidade alta segura uma leve vantagem (%.1f contra %.1f)" % [micro_alto / 60.0, micro_baixo / 60.0])
	executor.verificar(micro_alto / micro_baixo < 1.25, "mas a vantagem é leve")
	executor.verificar(farm_desconhecido / 60.0 > 70.0 * 0.85, "o domínio pesa menos no Farm que no Micro")


# --- Integração com o Jogo -----------------------------------------------------------

func teste_partida_depois_do_draft() -> void:
	var r: Dictionary = Jogo.simular_partida_do_draft()
	executor.verificar(not r["ok"] and r["erros"].has("draft"), "sem draft não há partida")
	_concluir_draft()
	var historico_antes: Dictionary = {}
	for jogador: Jogador in Jogo.carreira.organizacao.elenco:
		historico_antes[jogador.id] = jogador.partidas_por_campeao.duplicate()
	_sinais = 0
	var ao_simular: Callable = func(_p: Dictionary) -> void: _sinais += 1
	Eventos.partida_simulada.connect(ao_simular)
	r = Jogo.simular_partida_do_draft()
	Eventos.partida_simulada.disconnect(ao_simular)
	executor.verificar(r["ok"], "partida simulada")
	executor.igual(_sinais, 1, "sinal partida_simulada emitido")
	var p: Dictionary = r["partida"]
	executor.verificar(p["treino"] and p["lado_jogador"] == "azul", "partida de treino, jogador no azul")
	executor.igual(p["venceu"], int(p["vencedor"]) == 0, "venceu bate com o vencedor")
	executor.igual(p["times"][0]["nome"], "Vale Rift", "nome do time do jogador")
	var mudou: bool = false
	for jogador: Jogador in Jogo.carreira.organizacao.elenco:
		mudou = mudou or jogador.partidas_por_campeao != historico_antes[jogador.id]
	executor.verificar(not mudou, "treino não conta no histórico de campeões")
	var repetida: Dictionary = Jogo.simular_partida_do_draft({"semente": int(p["semente"])})["partida"]
	executor.igual(repetida["duracao"], p["duracao"], "a semente devolvida repete a partida")
	executor.verificar(not JSON.stringify(p).contains("forca"), "a partida não revela a força de patch")
