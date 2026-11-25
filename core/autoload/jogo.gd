extends Node
## Estado da carreira e todas as ações que a interface pode chamar.
## A interface nunca altera o estado diretamente: usa as funções públicas daqui.
## Documentação para a interface: docs/CONTRATO.md.

const ERRO_SEM_SLOT: String = "sem_slot"
const ERRO_SLOT_INVALIDO: String = "slot_invalido"
const ERRO_SLOT_VAZIO: String = "slot_vazio"
const ERRO_FALHA_GRAVACAO: String = "falha_gravacao"
const ERRO_SEM_CARREIRA: String = "sem_carreira"

## Carreira ativa, ou null antes de começar/carregar.
var carreira: Carreira = null
## Espaço de save da carreira ativa (0 a 3), ou -1.
var slot_atual: int = -1

var saves: SistemaSaves = SistemaSaves.new()


# --- Leitura -----------------------------------------------------------------

func tem_carreira() -> bool:
	return carreira != null


## Resumo da carreira ativa para a interface. {} se não houver carreira.
func resumo_carreira() -> Dictionary:
	if carreira == null:
		return {}
	return {
		"nome": carreira.organizacao.nome,
		"dinheiro": carreira.organizacao.dinheiro,
		"reputacao": roundi(carreira.organizacao.reputacao),
		"dificuldade": carreira.config.get("dificuldade", ""),
		"nivel_liga": carreira.nivel_liga,
		"dia": carreira.dia,
		"fase": carreira.descricao_fase(),
		"mes": carreira.mes(),
		"data": Calendario.data(carreira.dia),
		"slot": slot_atual,
		"folha_mensal": carreira.organizacao.folha_mensal(),
		"salarios_atrasados": carreira.organizacao.salarios_atrasados,
		"meses_em_atraso": carreira.organizacao.meses_em_atraso,
		"tamanho_elenco": carreira.organizacao.elenco.size(),
		"tem_tecnico": carreira.organizacao.tecnico != null,
		"verba_mensal": Financas.verba_mensal(carreira.nivel_liga, carreira.organizacao.ultima_posicao),
		"tem_emprestimo": not carreira.organizacao.emprestimo.is_empty(),
		"encerrada": carreira.encerrada,
		"motivo_encerramento": carreira.motivo_encerramento,
		"bandeira_png": carreira.organizacao.bandeira_png,
	}


## Dificuldades para a tela Criar Equipe, com o estado de bloqueio.
func listar_dificuldades() -> Array[Dictionary]:
	return ConfiguracaoCarreira.listar_dificuldades(pesadelo_desbloqueado())


## Opções de capital e rivais do modo Personalizado.
func opcoes_personalizado() -> Dictionary:
	return ConfiguracaoCarreira.opcoes_personalizado()


## Resumos dos 4 espaços de save. Espaço vazio = {}.
func listar_saves() -> Array[Dictionary]:
	return saves.listar_resumos()


## Último espaço jogado (para o botão Continuar), ou -1.
func ultimo_slot() -> int:
	return saves.ultimo_slot()


func pesadelo_desbloqueado() -> bool:
	return bool(saves.ler_progresso().get("pesadelo_desbloqueado", false))


## Valida só o nome, para a tela avisar enquanto o jogador digita.
## Devolve "" se estiver certo, ou a mensagem de erro pronta para exibir.
func validar_nome_organizacao(nome: String) -> String:
	var codigo: String = ConfiguracaoCarreira.validar_nome(nome)
	return "" if codigo.is_empty() else ConfiguracaoCarreira.mensagem_erro(codigo)


# --- Ações -------------------------------------------------------------------

## Cria uma carreira nova e grava no espaço de save.
## escolhas: {"nome", "dificuldade", "capital" e "rivais" (só no Personalizado), "slot" (opcional)}
## Sem "slot" (ou -1), usa o primeiro espaço vazio.
## Retorno: {"ok": true, "slot": int, "resumo": {...}}
##       ou {"ok": false, "erros": {"campo": "mensagem"}}
func nova_carreira(escolhas: Dictionary) -> Dictionary:
	var resolucao: Dictionary = ConfiguracaoCarreira.resolver(escolhas, pesadelo_desbloqueado())
	if not resolucao["ok"]:
		var mensagens: Dictionary = {}
		for campo: String in resolucao["erros"]:
			mensagens[campo] = ConfiguracaoCarreira.mensagem_erro(resolucao["erros"][campo])
		return {"ok": false, "erros": mensagens}

	var slot: int = int(escolhas.get("slot", -1))
	if slot == -1:
		slot = saves.primeiro_slot_vazio()
		if slot == -1:
			return _erro("slot", ERRO_SEM_SLOT, "Todos os espaços estão ocupados. Escolha um para substituir.")
	elif not SistemaSaves.slot_valido(slot):
		return _erro("slot", ERRO_SLOT_INVALIDO, "Espaço de save inválido.")

	var bandeira: String = str(escolhas.get("bandeira_png", ""))
	var erro_bandeira: String = Bandeira.validar(bandeira)
	if not erro_bandeira.is_empty():
		return {"ok": false, "erros": {"bandeira": Bandeira.mensagem_erro(erro_bandeira)}}

	var config: Dictionary = resolucao["config"]
	var nova: Carreira = Carreira.new()
	nova.config = config
	nova.semente = randi() & 0x7fffffff
	nova.organizacao.nome = config["nome"]
	nova.organizacao.dinheiro = int(config["capital_valor"])
	nova.organizacao.bandeira_png = bandeira
	nova.forcas_patch = Patch.gerar_forcas(nova.semente, 1)
	nova.registrar_lancamento("Capital inicial", nova.organizacao.dinheiro, "capital")
	SistemaMercado.gerar_inicial(nova)

	if not saves.salvar(slot, nova):
		return _erro("slot", ERRO_FALHA_GRAVACAO, "Não foi possível gravar o save.")

	carreira = nova
	slot_atual = slot
	var resumo: Dictionary = resumo_carreira()
	Eventos.carreira_iniciada.emit(resumo)
	_avisar_saves()
	return {"ok": true, "slot": slot, "resumo": resumo}


## Carrega a carreira de um espaço (0 a 3) e a torna ativa.
## Retorno: {"ok": true, "resumo": {...}} ou {"ok": false, "erros": {"slot": "mensagem"}}
func carregar(slot: int) -> Dictionary:
	if not SistemaSaves.slot_valido(slot):
		return _erro("slot", ERRO_SLOT_INVALIDO, "Espaço de save inválido.")
	var carregada: Carreira = saves.carregar(slot)
	if carregada == null:
		return _erro("slot", ERRO_SLOT_VAZIO, "Este espaço está vazio.")
	carreira = carregada
	slot_atual = slot
	saves.marcar_ultimo(slot)
	var resumo: Dictionary = resumo_carreira()
	Eventos.carreira_carregada.emit(resumo)
	_avisar_saves()
	return {"ok": true, "resumo": resumo}


## Carrega o último save jogado (botão Continuar).
func continuar() -> Dictionary:
	var slot: int = saves.ultimo_slot()
	if slot == -1:
		return _erro("slot", ERRO_SLOT_VAZIO, "Não há carreira para continuar.")
	return carregar(slot)


## Grava a carreira ativa no espaço dela.
func salvar() -> Dictionary:
	if carreira == null:
		return _erro("carreira", ERRO_SEM_CARREIRA, "Não há carreira ativa.")
	if not saves.salvar(slot_atual, carreira):
		return _erro("slot", ERRO_FALHA_GRAVACAO, "Não foi possível gravar o save.")
	Eventos.carreira_salva.emit(slot_atual)
	_avisar_saves()
	return {"ok": true}


## Apaga um save. Se for o da carreira ativa, a carreira continua em memória até ser salva em outro espaço.
func excluir_save(slot: int) -> Dictionary:
	if not saves.excluir(slot):
		return _erro("slot", ERRO_SLOT_VAZIO, "Este espaço já está vazio.")
	if slot == slot_atual:
		slot_atual = -1
	_avisar_saves()
	return {"ok": true}


## Desbloqueia o Pesadelo para todas as carreiras. Chamado pela lógica do mundial.
func desbloquear_pesadelo() -> void:
	if pesadelo_desbloqueado():
		return
	var progresso: Dictionary = saves.ler_progresso()
	progresso["pesadelo_desbloqueado"] = true
	saves.gravar_progresso(progresso)
	Eventos.dificuldade_desbloqueada.emit("pesadelo")


# --- Catálogo de Crystal Legends (campeões e itens) ---------------------------
# Leitura pura: funciona com ou sem carreira. Não expõe a força no patch (meta) nem a mecânica interna da simulação.

## Campeões para listas e grades. filtros (opcionais): {"classe": "mago", "posicao": "meio", "curva": "fim"}.
func listar_campeoes(filtros: Dictionary = {}) -> Array[Dictionary]:
	return CatalogoCampeoes.listar(filtros)


## Ficha completa de um campeão pelo ID estável (ex.: "veluria"). {} se não existir.
func detalhe_campeao(id: String) -> Dictionary:
	return CatalogoCampeoes.detalhe(id)


## Atributos de um campeão num nível de 1 a 16, sem itens. {} se não existir.
func atributos_campeao(id: String, nivel: int) -> Dictionary:
	return CatalogoCampeoes.atributos(id, nivel)


## Itens e botas. filtros (opcional): {"classe": "suporte"} mostra só o que a classe pode comprar.
func listar_itens(filtros: Dictionary = {}) -> Array[Dictionary]:
	return CatalogoCampeoes.listar_itens(filtros)


## Ficha de um item pelo ID (ex.: "orbe_da_tempestade"). {} se não existir.
func detalhe_item(id: String) -> Dictionary:
	return CatalogoCampeoes.detalhe_item(id)


# --- Draft (GDD seção 8) --------------------------------------------------------
# O draft fica só na memória: não vai para o save. Enquanto a liga não existe, o adversário é um time de treino.

var draft_atual: Draft = null
var _lado_jogador: String = "azul"


## Patch em vigor: {"numero", "dias_ate_proximo"}. A força dos campeões nunca é informada.
func patch_atual() -> Dictionary:
	if carreira == null:
		return {}
	return {"numero": carreira.patch_numero, "dias_ate_proximo": Patch.proximo_dia(carreira.dia) - carreira.dia}


## Começa um draft. opcoes (todas opcionais):
##   "primeira_escolha": true (padrão) = seu time é o azul e escolhe primeiro;
##   "indisponiveis": {"azul": [ids], "vermelho": [ids]} para o "fearless" de séries.
## Exige os 5 titulares definidos. Retorno: {"ok": true, "estado": {...}} ou erro em "titulares".
func iniciar_draft(opcoes: Dictionary = {}) -> Dictionary:
	var bloqueio: Dictionary = _verificar_ativa()
	if not bloqueio.is_empty():
		return bloqueio
	var meus: Dictionary = {}
	for posicao: String in Draft.POSICOES:
		var jogador: Jogador = carreira.organizacao.jogador_por_id(str(carreira.organizacao.titulares.get(posicao, "")))
		if jogador == null:
			return _erro("titulares", "titulares_incompletos", "Defina os 5 titulares antes do draft.")
		meus[posicao] = jogador
	var regra: Dictionary = Dados.draft()
	var meu_time: Dictionary = {"id": "jogador", "nome": carreira.organizacao.nome, "jogadores": meus,
		"qualidade": _qualidade_draft(carreira.organizacao.tecnico), "controlado": true}
	var rival: Dictionary = _time_de_treino(meus)
	_lado_jogador = "azul" if bool(opcoes.get("primeira_escolha", true)) else "vermelho"
	var azul: Dictionary = meu_time if _lado_jogador == "azul" else rival
	var vermelho: Dictionary = rival if _lado_jogador == "azul" else meu_time
	draft_atual = Draft.criar(azul, vermelho, carreira.forcas_patch,
		hash("%d:draft:%d:%d" % [carreira.semente, carreira.dia, randi()]), opcoes.get("indisponiveis", {}))
	draft_atual.avancar_ia()
	var estado: Dictionary = estado_draft()
	Eventos.draft_mudou.emit(estado)
	return {"ok": true, "estado": estado}


## Estado do draft para a tela (ver docs/CONTRATO.md). {} se não houver draft.
func estado_draft() -> Dictionary:
	if draft_atual == null:
		return {}
	var d: Draft = draft_atual
	var meu: String = _lado_jogador
	var rival: String = Draft.outro(meu)
	var atual: Dictionary = d.vez()
	var passos: Array[Dictionary] = []
	var feitos: Dictionary = {"azul": {"ban": 0, "pick": 0}, "vermelho": {"ban": 0, "pick": 0}}
	for indice: int in range(d.ordem.size()):
		var item: Dictionary = d.ordem[indice]
		var lista: Array = d.bans[item["time"]] if item["acao"] == "ban" else d.picks[item["time"]]
		var n: int = feitos[item["time"]][item["acao"]]
		feitos[item["time"]][item["acao"]] = n + 1
		passos.append({"acao": item["acao"], "time": item["time"], "campeao": lista[n] if n < lista.size() else ""})
	var tecnico: Tecnico = carreira.organizacao.tecnico
	var revela: bool = tecnico != null and int(tecnico.atributos.get("olheiro", 0)) >= int(Dados.draft()["olheiro_revela_favoritos"])
	var campeoes: Array[Dictionary] = []
	for id: String in Draft.ids_campeoes():
		var uso: Dictionary = d.usado_por(id)
		var estado_campeao: String = uso.get("estado", "livre")
		if estado_campeao == "livre" and d.indisponiveis[meu].has(id):
			estado_campeao = "indisponivel"
		var dominio: Dictionary = {}
		for posicao: String in Draft.POSICOES:
			var jogador: Jogador = d.times[meu]["jogadores"][posicao]
			var nivel: Dictionary = DominioCampeoes.nivel(int(jogador.dominio_campeoes.get(id, 0)))
			if nivel["id"] != "nao_conhece":
				dominio[posicao] = {"jogador_id": jogador.id, "apelido": jogador.apelido, "nivel": nivel["id"], "nivel_nome": nivel["nome"]}
		var item_campeao: Dictionary = {"id": id, "estado": estado_campeao, "por": uso.get("por", ""), "dominio": dominio}
		if revela:
			var favoritos: Array[String] = []
			for posicao: String in Draft.POSICOES:
				var adversario: Jogador = d.times[rival]["jogadores"][posicao]
				if DominioCampeoes.nivel(int(adversario.dominio_campeoes.get(id, 0)))["id"] == "favorito":
					favoritos.append(posicao)
			item_campeao["favorito_do_rival"] = favoritos
		campeoes.append(item_campeao)
	var times_publico: Dictionary = {}
	for lado: String in Draft.LADOS:
		var jogadores: Dictionary = {}
		for posicao: String in Draft.POSICOES:
			var j: Jogador = d.times[lado]["jogadores"][posicao]
			jogadores[posicao] = {"id": j.id, "apelido": j.apelido}
		times_publico[lado] = {"nome": d.times[lado]["nome"], "bans": d.bans[lado].duplicate(),
			"picks": d.picks[lado].duplicate(), "posicoes": d.posicoes[lado].duplicate(), "jogadores": jogadores}
	return {
		"lado_jogador": meu,
		"concluido": d.concluido(),
		"vez": {} if atual.is_empty() else {"acao": atual["acao"], "time": atual["time"],
			"do_jogador": atual["time"] == meu, "numero": d.passo + 1, "total": d.ordem.size()},
		"passos": passos,
		"times": times_publico,
		"campeoes": campeoes,
		"favoritos_do_rival_revelados": revela,
	}


## Bane um campeão na sua vez. Depois, a IA do rival joga até a sua próxima vez.
func banir_no_draft(campeao_id: String) -> Dictionary:
	return _acao_draft(campeao_id, "ban")


## Escolhe um campeão na sua vez. Depois, a IA do rival joga até a sua próxima vez.
func escolher_no_draft(campeao_id: String) -> Dictionary:
	return _acao_draft(campeao_id, "pick")


## O técnico faz a sua vez atual (com a qualidade dele; sem técnico, a escolha é fraca).
func delegar_vez_ao_tecnico() -> Dictionary:
	if draft_atual == null or draft_atual.concluido():
		return _erro("draft", Draft.ERRO_CONCLUIDO, "Não há vez para jogar.")
	return _acao_draft(draft_atual.decidir_ia(), str(draft_atual.vez()["acao"]))


## Troca a posição final dos seus campeões depois do draft. mapa: {posicao: id do campeão} com os 5 escolhidos.
func definir_posicoes_draft(mapa: Dictionary) -> Dictionary:
	if draft_atual == null:
		return _erro("draft", "sem_draft", "Não há draft em andamento.")
	var codigo: String = draft_atual.definir_posicoes(_lado_jogador, mapa)
	if not codigo.is_empty():
		return _erro("posicoes", codigo, "Distribua os seus 5 campeões, um por posição.")
	var estado: Dictionary = estado_draft()
	Eventos.draft_mudou.emit(estado)
	return {"ok": true, "estado": estado}


## Descarta o draft atual.
func encerrar_draft() -> void:
	draft_atual = null


# --- Etapa 5: partida simulada ------------------------------------------------
# A partida é simulada inteira de uma vez e devolvida como linha do tempo (docs/CONTRATO.md, seção 2.7).
# Fica só na memória. Partida de treino não conta no histórico de campeões dos jogadores.

var ultima_partida: Dictionary = {}


## Simula a partida do draft concluído. Retorno: {"ok": true, "partida": {...}} ou erro em "draft".
## opcoes: {"semente": int} para repetir uma partida (opcional).
func simular_partida_do_draft(opcoes: Dictionary = {}) -> Dictionary:
	if draft_atual == null:
		return _erro("draft", "sem_draft", "Não há draft para jogar.")
	if not draft_atual.concluido():
		return _erro("draft", "draft_em_andamento", "Termine o draft antes da partida.")
	var times: Array[Dictionary] = []
	for lado: String in Draft.LADOS:
		var time: Dictionary = draft_atual.times[lado]
		var jogadores: Array[Dictionary] = []
		for posicao: String in Draft.POSICOES:
			jogadores.append({"posicao": posicao, "jogador": time["jogadores"][posicao],
				"campeao": draft_atual.posicoes[lado][posicao]})
		times.append({"nome": time["nome"], "macro_tecnico": _macro_tecnico_de(time), "jogadores": jogadores})
	var semente: int = int(opcoes.get("semente", hash("%d:partida:%d:%d" % [carreira.semente, carreira.dia, randi()])))
	var partida: Dictionary = SimuladorPartida.simular({"times": times, "forcas_patch": carreira.forcas_patch, "semente": semente})
	partida["lado_jogador"] = _lado_jogador
	partida["venceu"] = Draft.LADOS[int(partida["vencedor"])] == _lado_jogador
	partida["treino"] = draft_atual.times[Draft.outro(_lado_jogador)].get("id", "") == "treino"
	_aplicar_partida_ao_elenco(draft_atual.times[_lado_jogador]["jogadores"], draft_atual.posicoes[_lado_jogador], not partida["treino"])
	ultima_partida = partida
	Eventos.partida_simulada.emit(partida)
	return {"ok": true, "partida": partida}


## Depois de uma partida: cada titular gasta energia (oficial = o dobro do treino) e,
## só na oficial, o campeão jogado entra no histórico.
func _aplicar_partida_ao_elenco(jogadores: Dictionary, campeoes: Dictionary, oficial: bool) -> void:
	for posicao: String in jogadores:
		var jogador: Jogador = jogadores[posicao]
		SistemaEnergia.gastar_partida(jogador, oficial)
		if oficial:
			var id: String = str(campeoes[posicao])
			jogador.partidas_por_campeao[id] = int(jogador.partidas_por_campeao.get(id, 0)) + 1
	Eventos.elenco_mudou.emit()


## Geometria do mapa para desenhar a partida (coordenadas de 0 a 1). Ver docs/CONTRATO.md, seção 2.7.
func mapa_partida() -> Dictionary:
	return Dados.mapa().duplicate(true)


## Macro do técnico (0 a 100) que entra na leitura de jogo do time; -1 quando não há técnico.
func _macro_tecnico_de(time: Dictionary) -> int:
	if time.get("id", "") == "treino":
		return roundi(float(Dados.draft()["treino"]["qualidade_tecnico"]) * 100.0)
	var tecnico: Tecnico = carreira.organizacao.tecnico
	return int(tecnico.atributos.get("macro", 50)) if tecnico != null else -1


func _acao_draft(campeao_id: String, acao: String) -> Dictionary:
	if draft_atual == null:
		return _erro("draft", "sem_draft", "Não há draft em andamento.")
	var d: Draft = draft_atual
	if d.concluido():
		return _erro("draft", Draft.ERRO_CONCLUIDO, "O draft já terminou.")
	var atual: Dictionary = d.vez()
	if atual["time"] != _lado_jogador:
		return _erro("draft", Draft.ERRO_NAO_E_SUA_VEZ, "Aguarde a vez do seu time.")
	if atual["acao"] != acao:
		return _erro("draft", Draft.ERRO_ACAO_ERRADA, "Agora é hora de %s." % ("banir" if atual["acao"] == "ban" else "escolher"))
	var codigo: String = d.aplicar(campeao_id)
	if not codigo.is_empty():
		var mensagens: Dictionary = {Draft.ERRO_INDISPONIVEL: "Este campeão não está disponível.",
			Draft.ERRO_CAMPEAO: "Campeão desconhecido."}
		return _erro("campeao", codigo, str(mensagens.get(codigo, "Ação inválida.")))
	d.avancar_ia()
	var estado: Dictionary = estado_draft()
	Eventos.draft_mudou.emit(estado)
	if d.concluido():
		Eventos.draft_concluido.emit(estado)
	return {"ok": true, "estado": estado}


func _qualidade_draft(tecnico: Tecnico) -> float:
	if tecnico == null:
		return float(Dados.draft()["ia"]["qualidade_sem_tecnico"])
	return clampf((float(tecnico.atributos.get("macro", 50)) + float(tecnico.atributos.get("conhecimento", 50))) / 200.0, 0.0, 1.0)


func _time_de_treino(meus: Dictionary) -> Dictionary:
	var regra: Dictionary = Dados.draft()["treino"]
	var media: float = 0.0
	for jogador: Jogador in meus.values():
		media += jogador.nivel_geral()
	media /= meus.size()
	var gerador: GeradorJogadores = GeradorJogadores.new(hash("%d:treino:%d" % [carreira.semente, carreira.dia]), 900000)
	var jogadores: Dictionary = {}
	for posicao: String in Draft.POSICOES:
		var qualidade: float = media + gerador.sortear_float(-float(regra["variacao_qualidade"]), float(regra["variacao_qualidade"]))
		jogadores[posicao] = gerador.gerar({"posicao": posicao, "qualidade": qualidade})
	return {"id": "treino", "nome": str(regra["nome"]), "jogadores": jogadores,
		"qualidade": float(regra["qualidade_tecnico"]), "controlado": false}


# --- Etapa 2: leitura de elenco, mercado e técnico ---------------------------

## Opções para montar uma proposta de contrato.
func opcoes_contrato() -> Dictionary:
	var regras: Dictionary = Dados.contratos()
	var duracoes: Array[int] = []
	for meses: Variant in regras["duracoes_meses"]:
		duracoes.append(int(meses))
	return {
		"duracoes_meses": duracoes,
		"multa_padrao_meses": int(regras["multa_padrao_meses"]),
		"ego_exige_titular": int(regras["negociacao"]["ego_exige_titular"]),
	}


## Agentes livres. filtros: {"posicao": "meio", "ordenar": "nivel" | "salario" | "idade"} (opcionais).
func listar_mercado(filtros: Dictionary = {}) -> Array[Dictionary]:
	if carreira == null:
		return []
	return SistemaMercado.listar(carreira, filtros)


## Jogadores do elenco, com contrato e indicação de titular.
func listar_elenco() -> Array[Dictionary]:
	if carreira == null:
		return []
	var lista: Array[Dictionary] = []
	for jogador: Jogador in carreira.organizacao.elenco:
		lista.append(_resumo_elenco(jogador))
	return lista


## Titulares atuais: posição -> id do jogador.
func titulares() -> Dictionary:
	return carreira.organizacao.titulares.duplicate() if carreira else {}


## Detalhe de um jogador do elenco ou do mercado. {} se não existir.
func detalhe_jogador(id: String) -> Dictionary:
	if carreira == null:
		return {}
	var jogador: Jogador = carreira.organizacao.jogador_por_id(id)
	if jogador:
		return _resumo_elenco(jogador)
	jogador = carreira.jogador_do_mercado(id)
	if jogador:
		var resumo: Dictionary = jogador.resumo_publico(carreira.dia)
		resumo["negociacao"] = SistemaMercado.estado_negociacao(carreira, jogador)
		resumo["no_elenco"] = false
		return resumo
	return {}


## Quanto custa dispensar um jogador do elenco agora. -1 se ele não estiver no elenco.
func custo_rescisao(id: String) -> int:
	if carreira == null:
		return -1
	var jogador: Jogador = carreira.organizacao.jogador_por_id(id)
	if jogador == null or jogador.contrato == null:
		return -1
	return _custo_rescisao(jogador.contrato)


## Resumo das finanças da organização.
func resumo_financeiro() -> Dictionary:
	if carreira == null:
		return {}
	var dias_por_mes: int = Dados.dias_por_mes()
	var proximo: int = carreira.mes() * dias_por_mes + 1
	return {
		"dinheiro": carreira.organizacao.dinheiro,
		"folha_mensal": carreira.organizacao.folha_mensal(),
		"salarios_atrasados": carreira.organizacao.salarios_atrasados,
		"meses_em_atraso": carreira.organizacao.meses_em_atraso,
		"proximo_pagamento_dia": proximo,
		"dias_ate_pagamento": proximo - carreira.dia,
		"verba_mensal": Financas.verba_mensal(carreira.nivel_liga, carreira.organizacao.ultima_posicao),
		"parcela_emprestimo": int(carreira.organizacao.emprestimo.get("parcela", 0)),
		"saldo_mensal_previsto": Financas.verba_mensal(carreira.nivel_liga, carreira.organizacao.ultima_posicao)
			- carreira.organizacao.folha_mensal() - int(carreira.organizacao.emprestimo.get("parcela", 0)),
		# Total a pagar no próximo dia 1: folha + parcela + tudo o que está atrasado.
		"gastos_previstos": carreira.organizacao.folha_mensal() + int(carreira.organizacao.emprestimo.get("parcela", 0))
			+ carreira.organizacao.salarios_atrasados + int(carreira.organizacao.emprestimo.get("divida_atrasada", 0)),
		"divida_atrasada": int(carreira.organizacao.emprestimo.get("divida_atrasada", 0)),
	}


## Livro de lançamentos, do mais novo para o mais antigo: [{dia, data_texto, descricao, valor, categoria}].
## valor > 0 é entrada; < 0 é saída. categoria: "capital", "verba", "salarios", "luvas", "rescisao", "tecnico", "emprestimo".
func listar_lancamentos(limite: int = 50) -> Array[Dictionary]:
	var saida: Array[Dictionary] = []
	if carreira == null:
		return saida
	for indice: int in range(carreira.lancamentos.size() - 1, -1, -1):
		if saida.size() >= limite:
			break
		var item: Dictionary = carreira.lancamentos[indice].duplicate()
		item["data_texto"] = String(Calendario.data(int(item["dia"]))["texto"])
		saida.append(item)
	return saida


## Troca a bandeira da organização (PNG 240×208 em base64; "" volta à arte padrão).
## Retorno: {"ok": true} ou {"ok": false, "erros": {"bandeira": "mensagem"}}. Vai para o save no próximo salvar().
func definir_bandeira(png_base64: String) -> Dictionary:
	var bloqueio: Dictionary = _verificar_ativa()
	if not bloqueio.is_empty():
		return bloqueio
	var codigo: String = Bandeira.validar(png_base64)
	if not codigo.is_empty():
		return _erro("bandeira", codigo, Bandeira.mensagem_erro(codigo))
	carreira.organizacao.bandeira_png = png_base64
	Eventos.bandeira_mudou.emit(png_base64)
	return {"ok": true}


## Tamanhos de anúncio para técnico: [{id, nome, candidatos, custo, dias_espera}].
func listar_anuncios() -> Array[Dictionary]:
	return SistemaTecnicos.listar_anuncios()


## Prévia de quantos dias os candidatos levariam para chegar com esta oferta.
func prever_espera_anuncio(tamanho: String, oferta_minima: int) -> int:
	return SistemaTecnicos.dias_de_espera(tamanho, oferta_minima)


## Anúncio em andamento: {} se não houver, ou {"tamanho", "oferta_minima", "dia_chegada", "dias_restantes"}.
func estado_anuncio() -> Dictionary:
	if carreira == null or carreira.anuncio_tecnico.is_empty():
		return {}
	var estado: Dictionary = carreira.anuncio_tecnico.duplicate()
	estado["dias_restantes"] = maxi(0, int(estado["dia_chegada"]) - carreira.dia)
	return estado


## Candidatos a técnico disponíveis (já responderam ao anúncio).
func listar_candidatos_tecnico() -> Array[Dictionary]:
	if carreira == null:
		return []
	var lista: Array[Dictionary] = []
	for candidato: Dictionary in carreira.candidatos_tecnico:
		var resumo: Dictionary = (candidato["tecnico"] as Tecnico).resumo(carreira.dia)
		resumo["expira_em"] = candidato["expira_em"]
		resumo["dias_para_expirar"] = maxi(0, int(candidato["expira_em"]) - carreira.dia)
		lista.append(resumo)
	return lista


## Técnico atual, ou {} se não houver.
func tecnico_atual() -> Dictionary:
	if carreira == null or carreira.organizacao.tecnico == null:
		return {}
	return carreira.organizacao.tecnico.resumo(carreira.dia)


# --- Etapa 2: ações ----------------------------------------------------------

## Faz uma proposta de contrato a um agente livre.
## proposta: {"salario", "duracao_meses", "luvas", "multa_rescisoria", "bonus_titulo", "bonus_mundial", "clausula_titular"}
## Campos ausentes usam o padrão (salário pedido, 12 meses, sem luvas, multa de 12 salários, sem bônus).
## Retorno: {"ok": true, "aceita": bool, "mensagem": String, "dica_salario": int, "paciencia": int, "bloqueado": bool}
##       ou {"ok": false, "erros": {...}} para pedidos impossíveis (elenco cheio, sem dinheiro para as luvas...).
func fazer_proposta(jogador_id: String, proposta: Dictionary) -> Dictionary:
	var bloqueio: Dictionary = _verificar_ativa()
	if not bloqueio.is_empty():
		return bloqueio
	var jogador: Jogador = carreira.jogador_do_mercado(jogador_id)
	if jogador == null:
		return _erro("jogador", "jogador_inexistente", "Este jogador não está no mercado.")
	if carreira.organizacao.elenco.size() >= Organizacao.MAXIMO_ELENCO:
		return _erro("elenco", "elenco_cheio", "O elenco já tem %d jogadores." % Organizacao.MAXIMO_ELENCO)
	return _negociar(jogador, proposta, false)


## Propõe a renovação do contrato de um jogador do elenco (a partir de 90 dias do fim).
## Mesmo formato de proposta e de retorno de fazer_proposta().
func renovar_contrato(jogador_id: String, proposta: Dictionary) -> Dictionary:
	var bloqueio: Dictionary = _verificar_ativa()
	if not bloqueio.is_empty():
		return bloqueio
	var jogador: Jogador = carreira.organizacao.jogador_por_id(jogador_id)
	if jogador == null:
		return _erro("jogador", "jogador_inexistente", "Este jogador não está no elenco.")
	var regra: Dictionary = Dados.contratos()["renovacao"]
	var restantes: int = jogador.contrato.dias_restantes(carreira.dia) if jogador.contrato else 0
	if restantes > int(regra["dias_restantes_para_renovar"]):
		return _erro("jogador", "cedo_para_renovar",
			"A renovação só pode ser proposta a partir de %d dias do fim do contrato." % int(regra["dias_restantes_para_renovar"]))
	if jogador.satisfacao < float(regra["satisfacao_minima"]):
		return {"ok": true, "aceita": false, "mensagem": "%s está insatisfeito e não quer renovar." % jogador.apelido,
			"dica_salario": 0, "paciencia": 0, "bloqueado": false}
	return _negociar(jogador, proposta, true)


## Dispensa um jogador do elenco, pagando a rescisão (ver custo_rescisao()). Ele volta ao mercado.
func dispensar_jogador(jogador_id: String) -> Dictionary:
	var bloqueio: Dictionary = _verificar_ativa()
	if not bloqueio.is_empty():
		return bloqueio
	var jogador: Jogador = carreira.organizacao.jogador_por_id(jogador_id)
	if jogador == null:
		return _erro("jogador", "jogador_inexistente", "Este jogador não está no elenco.")
	var custo: int = _custo_rescisao(jogador.contrato) if jogador.contrato else 0
	if custo > carreira.organizacao.dinheiro:
		return _erro("dinheiro", "sem_dinheiro", "Não há dinheiro para pagar a rescisão (R$ %s)." % Negociacao._formatar(custo))
	_mudar_dinheiro(-custo, "Rescisão de %s" % jogador.apelido, "rescisao")
	_remover_do_elenco(jogador, "dispensado")
	return {"ok": true, "custo": custo}


## Define os titulares. titulares: {"topo": id, "selva": id, ...}. Posições ausentes ficam sem titular.
## Um jogador pode ser titular fora da posição principal (rende conforme a afinidade).
func definir_titulares(novos: Dictionary) -> Dictionary:
	var bloqueio: Dictionary = _verificar_ativa()
	if not bloqueio.is_empty():
		return bloqueio
	var usados: Array[String] = []
	for posicao: String in novos:
		var id: String = str(novos[posicao])
		if not posicao in Jogador.POSICOES:
			return _erro("titulares", "posicao_invalida", "Posição inválida: %s." % posicao)
		if carreira.organizacao.jogador_por_id(id) == null:
			return _erro("titulares", "jogador_inexistente", "Um dos jogadores não está no elenco.")
		if id in usados:
			return _erro("titulares", "jogador_repetido", "Um jogador não pode ocupar duas posições.")
		usados.append(id)
	carreira.organizacao.titulares.clear()
	for posicao: String in novos:
		carreira.organizacao.titulares[posicao] = str(novos[posicao])
	Eventos.elenco_mudou.emit()
	return {"ok": true}


## Publica um anúncio de vaga de técnico. Cobra o custo do anúncio na hora.
## tamanho: "pequeno" | "medio" | "grande". oferta_minima: salário mensal oferecido (reais).
func publicar_anuncio(tamanho: String, oferta_minima: int) -> Dictionary:
	var bloqueio: Dictionary = _verificar_ativa()
	if not bloqueio.is_empty():
		return bloqueio
	var regra: Dictionary = Dados.tecnicos()
	var anuncio: Dictionary = Dados.por_id(regra["anuncios"], tamanho)
	if anuncio.is_empty():
		return _erro("tamanho", "tamanho_invalido", "Escolha o tamanho do anúncio.")
	if not carreira.anuncio_tecnico.is_empty():
		return _erro("anuncio", "anuncio_ativo", "Já existe um anúncio em andamento.")
	if oferta_minima < int(regra["oferta"]["minima"]):
		return _erro("oferta_minima", "oferta_baixa", "A oferta mínima é R$ %s." % Negociacao._formatar(int(regra["oferta"]["minima"])))
	if int(anuncio["custo"]) > carreira.organizacao.dinheiro:
		return _erro("dinheiro", "sem_dinheiro", "Não há dinheiro para o anúncio.")
	_mudar_dinheiro(-int(anuncio["custo"]), "Anúncio de técnico (%s)" % str(anuncio.get("nome", tamanho)), "tecnico")
	var espera: int = SistemaTecnicos.dias_de_espera(tamanho, oferta_minima)
	carreira.anuncio_tecnico = {"tamanho": tamanho, "oferta_minima": oferta_minima, "dia_chegada": carreira.dia + espera}
	return {"ok": true, "dias_espera": espera}


## Contrata um candidato a técnico pelo salário que ele pede. Exige que não haja técnico atual.
func contratar_tecnico(candidato_id: String, duracao_meses: int) -> Dictionary:
	var bloqueio: Dictionary = _verificar_ativa()
	if not bloqueio.is_empty():
		return bloqueio
	if carreira.organizacao.tecnico != null:
		return _erro("tecnico", "ja_tem_tecnico", "Dispense o técnico atual antes de contratar outro.")
	if not float(duracao_meses) in Dados.contratos()["duracoes_meses"]:
		return _erro("duracao_meses", "duracao_invalida", "Duração inválida.")
	for indice: int in range(carreira.candidatos_tecnico.size()):
		var tecnico: Tecnico = carreira.candidatos_tecnico[indice]["tecnico"]
		if tecnico.id == candidato_id:
			var contrato: Contrato = Contrato.new()
			contrato.salario = tecnico.salario_pedido
			contrato.duracao_meses = duracao_meses
			contrato.dia_inicio = carreira.dia
			contrato.dia_fim = carreira.dia + duracao_meses * Dados.dias_por_mes() - 1
			contrato.multa_rescisoria = tecnico.salario_pedido * int(Dados.contratos()["multa_padrao_meses"])
			tecnico.contrato = contrato
			carreira.organizacao.tecnico = tecnico
			carreira.candidatos_tecnico.clear()
			Eventos.tecnico_contratado.emit(tecnico.resumo(carreira.dia))
			return {"ok": true}
	return _erro("candidato", "candidato_inexistente", "Este candidato não está mais disponível.")


## Dispensa o técnico atual, pagando a rescisão.
func dispensar_tecnico() -> Dictionary:
	var bloqueio: Dictionary = _verificar_ativa()
	if not bloqueio.is_empty():
		return bloqueio
	if carreira.organizacao.tecnico == null:
		return _erro("tecnico", "sem_tecnico", "Não há técnico para dispensar.")
	var tecnico: Tecnico = carreira.organizacao.tecnico
	var custo: int = _custo_rescisao(tecnico.contrato) if tecnico.contrato else 0
	if custo > carreira.organizacao.dinheiro:
		return _erro("dinheiro", "sem_dinheiro", "Não há dinheiro para pagar a rescisão (R$ %s)." % Negociacao._formatar(custo))
	_mudar_dinheiro(-custo, "Rescisão do técnico %s" % tecnico.nome, "rescisao")
	carreira.organizacao.tecnico = null
	Eventos.tecnico_saiu.emit(tecnico.resumo(carreira.dia), "dispensado")
	return {"ok": true, "custo": custo}


## Avança o calendário. Processa salários (início de cada mês), avisos e fim de contratos,
## chegada e validade dos candidatos a técnico e renovação do mercado.
func avancar_dia(dias: int = 1) -> Dictionary:
	var bloqueio: Dictionary = _verificar_ativa()
	if not bloqueio.is_empty():
		return bloqueio
	for vez: int in range(maxi(1, dias)):
		carreira.dia += 1
		_processar_dia()
		Eventos.dia_avancou.emit(resumo_carreira())
		if carreira.encerrada:
			break
	return {"ok": true, "resumo": resumo_carreira()}


## Sinais que interrompem avancar_ate_evento(): algo que o jogador provavelmente quer ver.
const EVENTOS_QUE_PARAM: Array[String] = [
	"contrato_vencendo", "candidatos_chegaram", "jogador_saiu", "tecnico_saiu",
	"salarios_pagos", "salarios_atrasados", "verba_recebida", "parcela_paga",
	"parcela_atrasada", "emprestimo_quitado", "falencia",
]
var _eventos_do_dia: Array[String] = []


## Avança dia a dia até acontecer algo relevante (aviso de contrato, candidatos, pagamentos, saída de jogador,
## falência) ou até `maximo` dias. Retorno: {"ok", "dias_avancados", "eventos": [nomes dos sinais], "resumo"}.
## Os sinais de cada dia continuam sendo emitidos normalmente.
func avancar_ate_evento(maximo: int = 30) -> Dictionary:
	var bloqueio: Dictionary = _verificar_ativa()
	if not bloqueio.is_empty():
		return bloqueio
	var observadores: Array[Callable] = []
	for nome: String in EVENTOS_QUE_PARAM:
		var observador: Callable = func(_a: Variant = null, _b: Variant = null, _c: Variant = null) -> void:
			_eventos_do_dia.append(nome)
		Eventos.connect(nome, observador)
		observadores.append(observador)
	var dias: int = 0
	_eventos_do_dia.clear()
	while dias < maxi(1, maximo) and _eventos_do_dia.is_empty() and not carreira.encerrada:
		avancar_dia(1)
		dias += 1
	for indice: int in range(EVENTOS_QUE_PARAM.size()):
		Eventos.disconnect(EVENTOS_QUE_PARAM[indice], observadores[indice])
	var eventos: Array[String] = _eventos_do_dia.duplicate()
	_eventos_do_dia.clear()
	return {"ok": true, "dias_avancados": dias, "eventos": eventos, "resumo": resumo_carreira()}


# --- Etapa 2: interno --------------------------------------------------------

func _negociar(jogador: Jogador, proposta: Dictionary, renovacao: bool) -> Dictionary:
	var estado: Dictionary = carreira.negociacoes.get(jogador.id,
		{"paciencia": Negociacao.paciencia_inicial(jogador), "bloqueado_ate": 0})
	if int(estado["bloqueado_ate"]) >= carreira.dia:
		return _erro("jogador", "negociacao_bloqueada",
			"%s não quer conversar até o dia %d." % [jogador.apelido, int(estado["bloqueado_ate"]) + 1])

	var normalizada: Dictionary = Negociacao.normalizar(proposta, jogador)
	var erro_proposta: String = Negociacao.validar(normalizada)
	if not erro_proposta.is_empty():
		return _erro("proposta", Negociacao.MOTIVO_INVALIDA, erro_proposta)
	if normalizada["luvas"] > carreira.organizacao.dinheiro:
		return _erro("dinheiro", "sem_dinheiro", "Não há dinheiro para pagar as luvas.")

	var avaliacao: Dictionary = Negociacao.avaliar(jogador, normalizada, carreira.organizacao.reputacao, renovacao)
	if avaliacao["aceita"]:
		carreira.negociacoes.erase(jogador.id)
		_mudar_dinheiro(-int(normalizada["luvas"]), "Luvas de %s" % jogador.apelido, "luvas")
		jogador.contrato = Negociacao.criar_contrato(jogador, normalizada, carreira.dia)
		_limpar_avisos(jogador.id)
		if not renovacao:
			carreira.mercado.erase(jogador)
			carreira.organizacao.elenco.append(jogador)
			Eventos.jogador_contratado.emit(_resumo_elenco(jogador))
		Eventos.elenco_mudou.emit()
		return {"ok": true, "aceita": true, "mensagem": avaliacao["mensagem"], "dica_salario": avaliacao["dica_salario"],
			"paciencia": 0, "bloqueado": false, "jogador": _resumo_elenco(jogador)}

	var custo_paciencia: int = 2 if avaliacao["ofensiva"] else 1
	estado["paciencia"] = int(estado["paciencia"]) - custo_paciencia
	var mensagem: String = avaliacao["mensagem"]
	var bloqueado: bool = false
	if int(estado["paciencia"]) <= 0:
		var dias_bloqueio: int = int(Dados.contratos()["negociacao"]["bloqueio_dias"])
		estado["bloqueado_ate"] = carreira.dia + dias_bloqueio - 1
		estado["paciencia"] = Negociacao.paciencia_inicial(jogador)
		mensagem += " Ele encerrou a negociação por %d dias." % dias_bloqueio
		bloqueado = true
	carreira.negociacoes[jogador.id] = estado
	return {"ok": true, "aceita": false, "mensagem": mensagem, "dica_salario": avaliacao["dica_salario"],
		"paciencia": 0 if bloqueado else int(estado["paciencia"]), "bloqueado": bloqueado}


func _custo_rescisao(contrato: Contrato) -> int:
	var fracao: float = float(Dados.contratos()["rescisao"]["fracao_salario_restante"])
	return int(round(float(contrato.salario_restante(carreira.dia)) * fracao / 100.0) * 100.0)


func _resumo_elenco(jogador: Jogador) -> Dictionary:
	var resumo: Dictionary = jogador.resumo_publico(carreira.dia)
	resumo["no_elenco"] = true
	resumo["titular"] = carreira.organizacao.eh_titular(jogador.id)
	resumo["posicao_titular"] = carreira.organizacao.titulares.find_key(jogador.id) if resumo["titular"] else ""
	resumo["custo_rescisao"] = _custo_rescisao(jogador.contrato) if jogador.contrato else 0
	if jogador.contrato:
		var dias_regra: int = int(Dados.contratos()["renovacao"]["dias_restantes_para_renovar"])
		var restantes: int = jogador.contrato.dias_restantes(carreira.dia)
		resumo["contrato"]["pode_renovar"] = restantes <= dias_regra
		resumo["contrato"]["dias_para_poder_renovar"] = maxi(0, restantes - dias_regra)
	# Só aparece quando o ego está revelado (senão entregaria o traço oculto).
	if jogador.traco_revelado("ego"):
		resumo["exige_titularidade"] = jogador.ego >= int(Dados.contratos()["negociacao"]["ego_exige_titular"])
	return resumo


func _remover_do_elenco(jogador: Jogador, motivo: String) -> void:
	var resumo: Dictionary = _resumo_elenco(jogador)
	carreira.organizacao.elenco.erase(jogador)
	var posicao: Variant = carreira.organizacao.titulares.find_key(jogador.id)
	if posicao != null:
		carreira.organizacao.titulares.erase(posicao)
	jogador.contrato = null
	jogador.lealdade = float(Dados.balanceamento()["geracao"]["lealdade_inicial"])
	_limpar_avisos(jogador.id)
	carreira.mercado.append(jogador)
	Eventos.jogador_saiu.emit(resumo, motivo)
	Eventos.elenco_mudou.emit()


func _mudar_dinheiro(variacao: int, descricao: String, categoria: String) -> void:
	if variacao == 0:
		return
	carreira.registrar_lancamento(descricao, variacao, categoria)
	carreira.organizacao.dinheiro += variacao
	Eventos.dinheiro_mudou.emit(carreira.organizacao.dinheiro)


func _limpar_avisos(id: String) -> void:
	carreira.avisos_enviados = carreira.avisos_enviados.filter(func(aviso: String) -> bool: return not aviso.begins_with(id + ":"))


func _processar_dia() -> void:
	var patch: int = Patch.numero_no_dia(carreira.dia)
	if patch != carreira.patch_numero:
		carreira.patch_numero = patch
		carreira.forcas_patch = Patch.gerar_forcas(carreira.semente, patch)
		Eventos.patch_novo.emit(patch)
	_processar_anuncio()
	_processar_contratos()
	# Sem agenda ainda (etapa 3): todo dia é descanso.
	for jogador: Jogador in carreira.organizacao.elenco:
		SistemaEnergia.descansar_dia(jogador)
	if (carreira.dia - 1) % Dados.dias_por_mes() == 0:
		_dia_de_pagamento()
		SistemaMercado.renovar(carreira)
		Eventos.mercado_atualizado.emit()


func _processar_anuncio() -> void:
	# Candidatos vencidos desistem.
	carreira.candidatos_tecnico = carreira.candidatos_tecnico.filter(
		func(candidato: Dictionary) -> bool: return int(candidato["expira_em"]) >= carreira.dia)
	if carreira.anuncio_tecnico.is_empty() or carreira.dia < int(carreira.anuncio_tecnico["dia_chegada"]):
		return
	var anuncio: Dictionary = carreira.anuncio_tecnico
	carreira.anuncio_tecnico = {}
	var validade: int = int(Dados.tecnicos()["validade_candidatos_dias"])
	var resumos: Array[Dictionary] = []
	for tecnico: Tecnico in SistemaTecnicos.gerar_candidatos(carreira, anuncio["tamanho"], int(anuncio["oferta_minima"])):
		carreira.candidatos_tecnico.append({"tecnico": tecnico, "expira_em": carreira.dia + validade})
		resumos.append(tecnico.resumo(carreira.dia))
	Eventos.candidatos_chegaram.emit(resumos)


func _processar_contratos() -> void:
	var avisos: Array = Dados.contratos()["avisos_dias_restantes"]
	for jogador: Jogador in carreira.organizacao.elenco.duplicate():
		if jogador.contrato == null:
			continue
		# TODO (etapa 6): se houver competição em andamento, o contrato vai até o fim dela.
		if carreira.dia > jogador.contrato.dia_fim:
			_remover_do_elenco(jogador, "contrato_encerrado")
			continue
		_avisar_contrato(jogador.id, jogador.resumo_publico(carreira.dia), "jogador", jogador.contrato, avisos)
	var tecnico: Tecnico = carreira.organizacao.tecnico
	if tecnico and tecnico.contrato:
		if carreira.dia > tecnico.contrato.dia_fim:
			carreira.organizacao.tecnico = null
			_limpar_avisos(tecnico.id)
			Eventos.tecnico_saiu.emit(tecnico.resumo(carreira.dia), "contrato_encerrado")
		else:
			_avisar_contrato(tecnico.id, tecnico.resumo(carreira.dia), "tecnico", tecnico.contrato, avisos)


func _avisar_contrato(id: String, resumo: Dictionary, tipo: String, contrato: Contrato, avisos: Array) -> void:
	var restantes: int = contrato.dias_restantes(carreira.dia)
	for limite: Variant in avisos:
		var chave: String = "%s:%d" % [id, int(limite)]
		if restantes <= int(limite) and not chave in carreira.avisos_enviados:
			carreira.avisos_enviados.append(chave)
			# Envia só o aviso mais urgente que ainda não foi dado.
			if restantes <= int(avisos.min()) and int(limite) != int(avisos.min()):
				continue
			Eventos.contrato_vencendo.emit(resumo, tipo, restantes)


func _pagar_salarios() -> void:
	var organizacao: Organizacao = carreira.organizacao
	var devido: int = organizacao.folha_mensal() + organizacao.salarios_atrasados
	if devido == 0:
		return
	if organizacao.dinheiro >= devido:
		organizacao.salarios_atrasados = 0
		organizacao.meses_em_atraso = 0
		_mudar_dinheiro(-devido, "Salários", "salarios")
		Eventos.salarios_pagos.emit(devido)
		return
	var regra: Dictionary = Dados.contratos()["atraso_salarial"]
	organizacao.salarios_atrasados = devido
	organizacao.meses_em_atraso += 1
	organizacao.reputacao = maxf(0.0, organizacao.reputacao - float(regra["queda_reputacao"]))
	for jogador: Jogador in organizacao.elenco:
		jogador.satisfacao = maxf(0.0, jogador.satisfacao - float(regra["queda_satisfacao"]))
	Eventos.salarios_atrasados.emit(organizacao.salarios_atrasados, organizacao.meses_em_atraso)


# --- Economia: empréstimo -------------------------------------------------------

## Regras e limites para a tela de empréstimo.
## Retorno: {"juros_mensais", "prazos_meses", "valor_minimo", "limite", "pode_contratar", "motivo"}
func opcoes_emprestimo() -> Dictionary:
	if carreira == null:
		return {}
	var regra: Dictionary = Financas.regras()["emprestimo"]
	var prazos: Array[int] = []
	for meses: Variant in regra["prazos_meses"]:
		prazos.append(int(meses))
	var motivo: String = ""
	if not carreira.organizacao.emprestimo.is_empty():
		motivo = "Já existe um empréstimo ativo."
	return {
		"juros_mensais": float(regra["juros_mensais"]),
		"prazos_meses": prazos,
		"valor_minimo": int(regra["valor_minimo"]),
		"limite": Financas.limite_emprestimo(carreira.nivel_liga),
		"pode_contratar": motivo.is_empty(),
		"motivo": motivo,
	}


## Prévia de um empréstimo: {"valor", "meses", "parcela", "total", "juros_total"}.
func simular_emprestimo(valor: int, meses: int) -> Dictionary:
	return Financas.simular(valor, meses)


## Empréstimo ativo: {} ou {"valor", "meses", "parcela", "parcelas_restantes", "parcelas_atrasadas", "divida_atrasada", "saldo_para_quitar"}.
func estado_emprestimo() -> Dictionary:
	if carreira == null or carreira.organizacao.emprestimo.is_empty():
		return {}
	var estado: Dictionary = carreira.organizacao.emprestimo.duplicate()
	estado["saldo_para_quitar"] = Financas.saldo_devedor(int(estado["parcela"]), int(estado["parcelas_restantes"])) + int(estado["divida_atrasada"])
	return estado


## Contrata um empréstimo. O dinheiro entra na hora; as parcelas vencem no início de cada mês.
func contratar_emprestimo(valor: int, meses: int) -> Dictionary:
	var bloqueio: Dictionary = _verificar_ativa()
	if not bloqueio.is_empty():
		return bloqueio
	var opcoes: Dictionary = opcoes_emprestimo()
	if not opcoes["pode_contratar"]:
		return _erro("emprestimo", "emprestimo_ativo", opcoes["motivo"])
	if not meses in opcoes["prazos_meses"]:
		return _erro("meses", "prazo_invalido", "Prazo inválido.")
	if valor < int(opcoes["valor_minimo"]) or valor > int(opcoes["limite"]):
		return _erro("valor", "valor_invalido", "O valor deve ficar entre R$ %s e R$ %s." % [
			Negociacao._formatar(int(opcoes["valor_minimo"])), Negociacao._formatar(int(opcoes["limite"]))])
	carreira.organizacao.emprestimo = {
		"valor": valor,
		"meses": meses,
		"parcela": Financas.parcela(valor, meses),
		"parcelas_restantes": meses,
		"parcelas_atrasadas": 0,
		"divida_atrasada": 0,
	}
	_mudar_dinheiro(valor, "Empréstimo bancário", "emprestimo")
	Eventos.emprestimo_contratado.emit(estado_emprestimo())
	return {"ok": true, "emprestimo": estado_emprestimo()}


## Quita o empréstimo de uma vez, pagando o saldo devedor (com desconto dos juros futuros).
func quitar_emprestimo() -> Dictionary:
	var bloqueio: Dictionary = _verificar_ativa()
	if not bloqueio.is_empty():
		return bloqueio
	var estado: Dictionary = estado_emprestimo()
	if estado.is_empty():
		return _erro("emprestimo", "sem_emprestimo", "Não há empréstimo ativo.")
	var saldo: int = int(estado["saldo_para_quitar"])
	if saldo > carreira.organizacao.dinheiro:
		return _erro("dinheiro", "sem_dinheiro", "Não há dinheiro para quitar (R$ %s)." % Negociacao._formatar(saldo))
	_mudar_dinheiro(-saldo, "Quitação do empréstimo", "emprestimo")
	carreira.organizacao.emprestimo = {}
	Eventos.emprestimo_quitado.emit()
	return {"ok": true, "pago": saldo}


func _verificar_ativa() -> Dictionary:
	if carreira == null:
		return _erro("carreira", ERRO_SEM_CARREIRA, "Não há carreira ativa.")
	if carreira.encerrada:
		return _erro("carreira", "carreira_encerrada", "Esta carreira terminou.")
	return {}


## Primeiro dia do mês: verba da liga, parcela do empréstimo e salários, nesta ordem.
func _dia_de_pagamento() -> void:
	var verba: int = Financas.verba_mensal(carreira.nivel_liga, carreira.organizacao.ultima_posicao)
	if verba > 0:
		_mudar_dinheiro(verba, "Verba da liga", "verba")
		Eventos.verba_recebida.emit(verba)
	_cobrar_parcela()
	_pagar_salarios()
	_verificar_falencia()


func _cobrar_parcela() -> void:
	var emprestimo: Dictionary = carreira.organizacao.emprestimo
	if emprestimo.is_empty():
		return
	var devido: int = int(emprestimo["parcela"]) + int(emprestimo["divida_atrasada"])
	if carreira.organizacao.dinheiro >= devido:
		_mudar_dinheiro(-devido, "Parcela do empréstimo", "emprestimo")
		emprestimo["parcelas_restantes"] = int(emprestimo["parcelas_restantes"]) - 1
		emprestimo["parcelas_atrasadas"] = 0
		emprestimo["divida_atrasada"] = 0
		Eventos.parcela_paga.emit(devido, int(emprestimo["parcelas_restantes"]))
		if int(emprestimo["parcelas_restantes"]) <= 0:
			carreira.organizacao.emprestimo = {}
			Eventos.emprestimo_quitado.emit()
		return
	var regra: Dictionary = Financas.regras()["emprestimo"]
	var multa: int = int(ceil(float(emprestimo["parcela"]) * float(regra["multa_atraso"])))
	emprestimo["divida_atrasada"] = int(emprestimo["divida_atrasada"]) + int(emprestimo["parcela"]) + multa
	emprestimo["parcelas_restantes"] = int(emprestimo["parcelas_restantes"]) - 1
	emprestimo["parcelas_atrasadas"] = int(emprestimo["parcelas_atrasadas"]) + 1
	carreira.organizacao.reputacao = maxf(0.0, carreira.organizacao.reputacao - float(regra["queda_reputacao_atraso"]))
	Eventos.parcela_atrasada.emit(int(emprestimo["divida_atrasada"]), int(emprestimo["parcelas_atrasadas"]))


func _verificar_falencia() -> void:
	var emprestimo: Dictionary = carreira.organizacao.emprestimo
	if emprestimo.is_empty():
		return
	var limite: int = int(Financas.regras()["emprestimo"]["parcelas_atrasadas_para_falencia"])
	if int(emprestimo["parcelas_atrasadas"]) >= limite and carreira.organizacao.dinheiro < int(emprestimo["divida_atrasada"]):
		carreira.encerrada = true
		carreira.motivo_encerramento = "falencia"
		Eventos.falencia.emit(resumo_carreira())


# --- Interno -----------------------------------------------------------------

func _erro(campo: String, _codigo: String, mensagem: String) -> Dictionary:
	return {"ok": false, "erros": {campo: mensagem}}


func _avisar_saves() -> void:
	Eventos.saves_mudaram.emit(saves.listar_resumos(), saves.ultimo_slot())
