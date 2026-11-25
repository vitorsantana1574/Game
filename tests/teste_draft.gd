extends RefCounted
## Testes do domínio de campeões, do patch e do draft.

const PASTA_TESTE: String = "user://testes_saves"

var executor: Object
var _concluidos: int = 0


func antes_de_cada() -> void:
	Jogo.saves.pasta = PASTA_TESTE
	for slot: int in range(SistemaSaves.TOTAL_SLOTS):
		Jogo.saves.excluir(slot)
	Jogo.encerrar_draft()
	Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "facil"})


func _montar_titulares() -> void:
	var titulares: Dictionary = {}
	for posicao: String in Draft.POSICOES:
		var escolhido: Jogador = null
		for jogador: Jogador in Jogo.carreira.mercado:
			if jogador.posicao_principal == posicao and (escolhido == null or jogador.salario_pedido < escolhido.salario_pedido):
				escolhido = jogador
		Jogo.fazer_proposta(escolhido.id, {"salario": escolhido.salario_pedido * 2, "duracao_meses": 6})
		titulares[posicao] = escolhido.id
	Jogo.definir_titulares(titulares)


func _primeiro_livre(estado: Dictionary) -> String:
	for campeao: Dictionary in estado["campeoes"]:
		if campeao["estado"] == "livre":
			return campeao["id"]
	return ""


# --- Domínio -------------------------------------------------------------------

func teste_dominio_gerado_para_todos() -> void:
	var total: int = Dados.campeoes()["campeoes"].size()
	var ok: bool = true
	for jogador: Jogador in Jogo.carreira.mercado:
		ok = ok and jogador.dominio_campeoes.size() == total
		for valor: Variant in jogador.dominio_campeoes.values():
			ok = ok and int(valor) >= 0 and int(valor) <= 100
	executor.verificar(ok, "maestria de 0 a 100 para os 30 campeões de cada jogador")


func teste_especialista_x_versatil() -> void:
	var gerador: GeradorJogadores = GeradorJogadores.new(42)
	var especialistas: Array[float] = []
	var versateis: Array[float] = []
	var topo_esp: Array[float] = []
	var topo_ver: Array[float] = []
	for vez: int in range(200):
		var jogador: Jogador = gerador.gerar()
		var conhecidos: int = DominioCampeoes.lista_publica(jogador).size()
		var topo: float = float(jogador.dominio_campeoes.values().max())
		if jogador.versatilidade < 0.3:
			especialistas.append(conhecidos)
			topo_esp.append(topo)
		elif jogador.versatilidade > 0.7:
			versateis.append(conhecidos)
			topo_ver.append(topo)
	var media: Callable = func(lista: Array[float]) -> float:
		var soma: float = 0.0
		for v: float in lista:
			soma += v
		return soma / maxf(1.0, lista.size())
	executor.verificar(media.call(versateis) > media.call(especialistas) + 4.0,
		"versátil conhece mais campeões (%.1f × %.1f)" % [media.call(versateis), media.call(especialistas)])
	executor.verificar(media.call(topo_esp) > media.call(topo_ver) + 6.0,
		"especialista tem maestria maior no favorito (%.0f × %.0f)" % [media.call(topo_esp), media.call(topo_ver)])


func teste_dominio_publico_sem_numeros() -> void:
	var jogador: Jogador = Jogo.carreira.mercado[0]
	var lista: Array = Jogo.detalhe_jogador(jogador.id)["dominio_campeoes"]
	executor.verificar(not lista.is_empty(), "ficha traz o domínio")
	var ok: bool = true
	for item: Dictionary in lista:
		ok = ok and item.keys().size() == 3 and item["nivel"] != "nao_conhece"
	executor.verificar(ok, "só id, nível e nome do nível; sem 'Não conhece' e sem maestria numérica")
	executor.igual(lista[0]["nivel"], DominioCampeoes.nivel(int(jogador.dominio_campeoes.values().max()))["id"], "do mais para o menos dominado")


func teste_dominio_deterministico_e_save_antigo() -> void:
	var a: Jogador = GeradorJogadores.new(7).gerar()
	var b: Jogador = GeradorJogadores.new(7).gerar()
	executor.igual(a.dominio_campeoes, b.dominio_campeoes, "mesma semente, mesmo domínio")
	var dados: Dictionary = a.para_dicionario()
	dados.erase("dominio_campeoes")
	var antigo: Jogador = Jogador.de_dicionario(dados)
	executor.igual(antigo.dominio_campeoes.size(), Dados.campeoes()["campeoes"].size(), "save antigo ganha domínio ao carregar")


# --- Patch -----------------------------------------------------------------------

func teste_patch_escondido_e_periodico() -> void:
	var forcas: Dictionary = Jogo.carreira.forcas_patch
	var ok: bool = forcas.size() == Dados.campeoes()["campeoes"].size()
	for valor: Variant in forcas.values():
		ok = ok and float(valor) >= 0.9 and float(valor) <= 1.1
	executor.verificar(ok, "força de patch entre 0,9 e 1,1 para todos")
	executor.igual(Jogo.patch_atual(), {"numero": 1, "dias_ate_proximo": 180}, "patch 1 no início, sem forças")
	Jogo.avancar_dia(180)
	executor.igual(Jogo.carreira.patch_numero, 2, "patch 2 no dia 181")
	executor.verificar(Jogo.carreira.forcas_patch != forcas, "forças mudam no patch novo")
	executor.igual(Patch.gerar_forcas(123, 2), Patch.gerar_forcas(123, 2), "forças determinísticas")


# --- Draft -------------------------------------------------------------------------

func teste_ordem_do_draft() -> void:
	var ordem: Array = Dados.draft()["ordem"]
	executor.igual(ordem.size(), 20, "20 passos")
	var texto: String = ""
	for item: Dictionary in ordem:
		texto += ("b" if item["acao"] == "ban" else "p") + ("A" if item["time"] == "azul" else "B")
	executor.igual(texto, "bAbBbAbBbAbBpApBpBpApApBbBbAbBbApBpApApB", "ordem do profissional (GDD 8.1)")


func teste_draft_exige_titulares() -> void:
	var r: Dictionary = Jogo.iniciar_draft()
	executor.verificar(not r["ok"] and r["erros"].has("titulares"), "sem 5 titulares não há draft")


func teste_draft_completo() -> void:
	_montar_titulares()
	_concluidos = 0
	var ao_concluir: Callable = func(_estado: Dictionary) -> void: _concluidos += 1
	Eventos.draft_concluido.connect(ao_concluir)
	var estado: Dictionary = Jogo.iniciar_draft()["estado"]
	executor.verificar(estado["vez"]["do_jogador"] and estado["vez"]["acao"] == "ban", "azul começa banindo")
	var r: Dictionary = Jogo.escolher_no_draft(_primeiro_livre(estado))
	executor.verificar(not r["ok"] and r["erros"].has("draft"), "não pode escolher na hora de banir")
	var vezes: int = 0
	while not estado["concluido"] and vezes < 30:
		var id: String = _primeiro_livre(estado)
		r = Jogo.banir_no_draft(id) if estado["vez"]["acao"] == "ban" else Jogo.escolher_no_draft(id)
		if not r["ok"]:
			executor.verificar(false, "ação %d recusada: %s" % [vezes, str(r)])
			break
		estado = r["estado"]
		vezes += 1
	Eventos.draft_concluido.disconnect(ao_concluir)
	executor.verificar(estado["concluido"], "draft terminou")
	executor.igual(_concluidos, 1, "sinal de conclusão emitido uma vez")
	var usados: Dictionary = {}
	var repetido: bool = false
	for lado: String in Draft.LADOS:
		var t: Dictionary = estado["times"][lado]
		executor.igual([t["bans"].size(), t["picks"].size(), t["posicoes"].size()], [5, 5, 5], "%s: 5 bans, 5 picks, 5 posições" % lado)
		for id: Variant in t["bans"] + t["picks"]:
			repetido = repetido or usados.has(id)
			usados[id] = true
	executor.verificar(not repetido, "nenhum campeão banido ou escolhido duas vezes")
	executor.verificar(not JSON.stringify(estado).contains("forca"), "o estado do draft não traz força de patch")


func teste_draft_segunda_escolha_e_erros() -> void:
	_montar_titulares()
	var estado: Dictionary = Jogo.iniciar_draft({"primeira_escolha": false})["estado"]
	executor.igual(estado["lado_jogador"], "vermelho", "jogador no lado vermelho")
	executor.igual(estado["passos"][0]["campeao"] != "", true, "a IA azul já fez o primeiro ban")
	var banido: String = estado["passos"][0]["campeao"]
	var r: Dictionary = Jogo.banir_no_draft(banido)
	executor.verificar(not r["ok"] and r["erros"].has("campeao"), "não pode banir o que já foi banido")
	r = Jogo.banir_no_draft("nao_existe")
	executor.verificar(not r["ok"], "campeão desconhecido recusado")
	r = Jogo.delegar_vez_ao_tecnico()
	executor.verificar(r["ok"], "o técnico faz a vez")


func teste_fearless_e_posicoes() -> void:
	_montar_titulares()
	var proibido: String = Draft.ids_campeoes()[0]
	var estado: Dictionary = Jogo.iniciar_draft({"indisponiveis": {"azul": [proibido]}})["estado"]
	var item: Dictionary = estado["campeoes"].filter(func(c: Dictionary) -> bool: return c["id"] == proibido)[0]
	executor.igual(item["estado"], "indisponivel", "campeão já usado na série aparece indisponível")
	while not estado["concluido"]:
		var r: Dictionary = Jogo.delegar_vez_ao_tecnico()
		estado = r["estado"]
	executor.verificar(not estado["times"]["azul"]["picks"].has(proibido), "o time não escolhe o campeão bloqueado")
	var meus: Dictionary = estado["times"]["azul"]["posicoes"]
	var trocado: Dictionary = meus.duplicate()
	trocado["topo"] = meus["meio"]
	trocado["meio"] = meus["topo"]
	executor.verificar(Jogo.definir_posicoes_draft(trocado)["ok"], "troca de posições aceita")
	trocado["topo"] = trocado["meio"]
	executor.verificar(not Jogo.definir_posicoes_draft(trocado)["ok"], "campeão repetido recusado")


func teste_ia_com_tecnico_bom_escolhe_melhor() -> void:
	var gerador: GeradorJogadores = GeradorJogadores.new(99)
	var forcas: Dictionary = Patch.gerar_forcas(5, 1)
	var soma: Dictionary = {"bom": 0.0, "fraco": 0.0}
	for rodada: int in range(12):
		var jogadores_a: Dictionary = {}
		var jogadores_b: Dictionary = {}
		for posicao: String in Draft.POSICOES:
			jogadores_a[posicao] = gerador.gerar({"posicao": posicao})
			jogadores_b[posicao] = gerador.gerar({"posicao": posicao})
		var d: Draft = Draft.criar(
			{"nome": "A", "jogadores": jogadores_a, "qualidade": 0.95, "controlado": false},
			{"nome": "B", "jogadores": jogadores_b, "qualidade": 0.05, "controlado": false}, forcas, rodada)
		d.avancar_ia()
		for lado: String in Draft.LADOS:
			var total: float = 0.0
			var time: Dictionary = jogadores_a if lado == "azul" else jogadores_b
			for posicao: String in d.posicoes[lado]:
				var id: String = d.posicoes[lado][posicao]
				total += DominioCampeoes.rendimento(time[posicao], id) * DominioCampeoes.adequacao(id, posicao)
			soma["bom" if lado == "azul" else "fraco"] += total
	executor.verificar(soma["bom"] > soma["fraco"], "técnico bom monta composição mais adequada (%.1f × %.1f)" % [soma["bom"], soma["fraco"]])
