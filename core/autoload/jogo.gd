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
		"slot": slot_atual,
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

	var config: Dictionary = resolucao["config"]
	var nova: Carreira = Carreira.new()
	nova.config = config
	nova.semente = randi() & 0x7fffffff
	nova.organizacao.nome = config["nome"]
	nova.organizacao.dinheiro = int(config["capital_valor"])

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
	var resumo: Dictionary = resumo_carreira()
	Eventos.carreira_carregada.emit(resumo)
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


# --- Interno -----------------------------------------------------------------

func _erro(campo: String, _codigo: String, mensagem: String) -> Dictionary:
	return {"ok": false, "erros": {campo: mensagem}}


func _avisar_saves() -> void:
	Eventos.saves_mudaram.emit(saves.listar_resumos(), saves.ultimo_slot())
