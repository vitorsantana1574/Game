extends RefCounted
## Testes das ações do Jogo: nova carreira, saves, carregar, continuar.
## Usa uma pasta de saves separada para não mexer nos saves reais.

const PASTA_TESTE: String = "user://testes_saves"

var executor: Object
var _sinais: Array[String] = []


func antes_de_cada() -> void:
	_limpar_pasta()
	Jogo.saves.pasta = PASTA_TESTE
	Jogo.carreira = null
	Jogo.slot_atual = -1
	_sinais.clear()
	if not Eventos.carreira_iniciada.is_connected(_ao_iniciar):
		Eventos.carreira_iniciada.connect(_ao_iniciar)
		Eventos.saves_mudaram.connect(_ao_mudar_saves)


func teste_nova_carreira_cria_save() -> void:
	var r: Dictionary = Jogo.nova_carreira({"nome": "  Aurora   Esports ", "dificuldade": "normal"})
	executor.verificar(r["ok"], "carreira criada")
	executor.igual(r["slot"], 0, "usa o primeiro espaço vazio")
	executor.igual(r["resumo"]["nome"], "Aurora Esports", "nome limpo")
	executor.igual(r["resumo"]["dinheiro"], 80000, "capital do Normal")
	executor.igual(r["resumo"]["fase"], "Regional · Dia 1", "começa na regional, dia 1")
	executor.verificar("iniciada" in _sinais and "saves" in _sinais, "emitiu carreira_iniciada e saves_mudaram")
	var resumos: Array[Dictionary] = Jogo.listar_saves()
	executor.igual(resumos.size(), 4, "sempre 4 espaços")
	executor.igual(resumos[0]["nome"], "Aurora Esports", "save aparece na lista")
	executor.verificar(resumos[1].is_empty(), "espaço 2 vazio")
	executor.igual(Jogo.ultimo_slot(), 0, "último jogado = 0")


func teste_erros_vem_com_mensagem_pronta() -> void:
	var r: Dictionary = Jogo.nova_carreira({"nome": "A", "dificuldade": "pesadelo"})
	executor.verificar(not r["ok"], "recusada")
	executor.verificar(r["erros"].has("nome") and r["erros"].has("dificuldade"), "aponta nome e dificuldade")
	executor.verificar(str(r["erros"]["nome"]).length() > 5, "mensagem legível para o nome")
	executor.verificar(not Jogo.tem_carreira(), "nenhuma carreira ativa após erro")


func teste_espacos_cheios() -> void:
	for i: int in range(4):
		Jogo.nova_carreira({"nome": "Time %d" % (i + 1), "dificuldade": "facil"})
	var r: Dictionary = Jogo.nova_carreira({"nome": "Time 5", "dificuldade": "facil"})
	executor.verificar(not r["ok"] and r["erros"].has("slot"), "recusa quando os 4 espaços estão ocupados")
	var substituir: Dictionary = Jogo.nova_carreira({"nome": "Time 5", "dificuldade": "facil", "slot": 2})
	executor.verificar(substituir["ok"], "aceita substituir um espaço escolhido")
	executor.igual(Jogo.listar_saves()[2]["nome"], "Time 5", "espaço 3 substituído")


func teste_carregar_e_continuar() -> void:
	Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "dificil"})
	Jogo.nova_carreira({"nome": "Aurora", "dificuldade": "facil"})
	Jogo.carreira = null
	var r: Dictionary = Jogo.carregar(0)
	executor.verificar(r["ok"], "carregou o espaço 1")
	executor.igual(r["resumo"]["nome"], "Vale Rift", "carreira certa")
	executor.igual(r["resumo"]["dinheiro"], 40000, "capital do Difícil preservado")
	executor.verificar(not Jogo.carregar(3)["ok"], "espaço vazio não carrega")
	Jogo.salvar()
	executor.igual(Jogo.continuar()["resumo"]["nome"], "Vale Rift", "continuar abre o último salvo")


func teste_carregar_atualiza_ultimo_jogado() -> void:
	# Caso relatado pelo GPT: salvar no espaço 2, carregar o 3, e Continuar deve abrir o 3.
	Jogo.nova_carreira({"nome": "Time Dois", "dificuldade": "normal", "slot": 1})
	Jogo.nova_carreira({"nome": "Time Tres", "dificuldade": "normal", "slot": 2})
	Jogo.carregar(1)
	executor.igual(Jogo.ultimo_slot(), 1, "carregar o espaço 2 o torna o último jogado")
	Jogo.carregar(2)
	executor.igual(Jogo.ultimo_slot(), 2, "carregar o espaço 3 o torna o último jogado")
	executor.igual(Jogo.continuar()["resumo"]["nome"], "Time Tres", "continuar abre o último carregado")


func teste_save_preserva_elenco() -> void:
	Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "normal"})
	var gerador: GeradorJogadores = GeradorJogadores.new(Jogo.carreira.semente)
	Jogo.carreira.organizacao.elenco.append_array(gerador.gerar_varios(3, 50.0))
	var antes: Dictionary = Jogo.carreira.para_dicionario()
	Jogo.salvar()
	Jogo.carreira = null
	Jogo.carregar(0)
	executor.mesmo_conteudo(Jogo.carreira.para_dicionario(), antes, "carreira volta igual do save, com elenco e com os mesmos tipos")


func teste_excluir_save() -> void:
	Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "normal"})
	executor.verificar(Jogo.excluir_save(0)["ok"], "excluiu")
	executor.verificar(Jogo.listar_saves()[0].is_empty(), "espaço vazio depois de excluir")
	executor.igual(Jogo.ultimo_slot(), -1, "continuar desativado")


func teste_desbloqueio_do_pesadelo() -> void:
	executor.verificar(not Jogo.pesadelo_desbloqueado(), "começa bloqueado")
	Jogo.desbloquear_pesadelo()
	executor.verificar(Jogo.pesadelo_desbloqueado(), "fica desbloqueado")
	executor.verificar(Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "pesadelo"})["ok"], "pesadelo disponível")


func _ao_iniciar(_resumo: Dictionary) -> void:
	_sinais.append("iniciada")


func _ao_mudar_saves(_resumos: Array[Dictionary], _ultimo: int) -> void:
	_sinais.append("saves")


func _limpar_pasta() -> void:
	var pasta: DirAccess = DirAccess.open(PASTA_TESTE)
	if pasta == null:
		return
	for arquivo: String in pasta.get_files():
		pasta.remove(arquivo)
