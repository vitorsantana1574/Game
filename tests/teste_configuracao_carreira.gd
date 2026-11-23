extends RefCounted
## Testes da validação da tela Criar Equipe.

var executor: Object


func teste_nome_valido() -> void:
	executor.igual(ConfiguracaoCarreira.validar_nome("Aurora Esports"), "", "nome comum é válido")
	executor.igual(ConfiguracaoCarreira.validar_nome("Ação & Cia."), "", "acentos e & são aceitos")
	executor.igual(ConfiguracaoCarreira.validar_nome("Time-01"), "", "números e hífen são aceitos")


func teste_nome_invalido() -> void:
	executor.igual(ConfiguracaoCarreira.validar_nome("   "), ConfiguracaoCarreira.ERRO_NOME_VAZIO, "só espaços")
	executor.igual(ConfiguracaoCarreira.validar_nome("AB"), ConfiguracaoCarreira.ERRO_NOME_CURTO, "curto demais")
	executor.igual(ConfiguracaoCarreira.validar_nome("A".repeat(25)), ConfiguracaoCarreira.ERRO_NOME_LONGO, "longo demais")
	executor.igual(ConfiguracaoCarreira.validar_nome("Time <3"), ConfiguracaoCarreira.ERRO_NOME_CARACTERES, "caractere proibido")


func teste_limpeza_do_nome() -> void:
	executor.igual(ConfiguracaoCarreira.limpar_nome("  Vale    Rift  "), "Vale Rift", "espaços extras removidos")


func teste_predefinicao_normal() -> void:
	var r: Dictionary = ConfiguracaoCarreira.resolver({"nome": "Vale Rift", "dificuldade": "normal"}, false)
	executor.verificar(r["ok"], "normal é aceito")
	executor.igual(r["config"]["capital"], "medio", "normal usa capital médio")
	executor.igual(r["config"]["rivais"], "equilibrados", "normal usa rivais equilibrados")
	executor.igual(r["config"]["capital_valor"], 80000, "valor do capital médio")


func teste_pesadelo_bloqueado_e_desbloqueado() -> void:
	var bloqueado: Dictionary = ConfiguracaoCarreira.resolver({"nome": "Vale Rift", "dificuldade": "pesadelo"}, false)
	executor.verificar(not bloqueado["ok"], "pesadelo bloqueado no início")
	executor.igual(bloqueado.get("erros", {}).get("dificuldade", ""), ConfiguracaoCarreira.ERRO_DIFICULDADE_BLOQUEADA, "erro de bloqueio")
	var liberado: Dictionary = ConfiguracaoCarreira.resolver({"nome": "Vale Rift", "dificuldade": "pesadelo"}, true)
	executor.verificar(liberado["ok"], "pesadelo liberado após desbloqueio")


func teste_personalizado() -> void:
	var certo: Dictionary = ConfiguracaoCarreira.resolver(
		{"nome": "Vale Rift", "dificuldade": "personalizado", "capital": "alto", "rivais": "experientes"}, false)
	executor.verificar(certo["ok"], "personalizado completo é aceito")
	executor.igual(certo["config"]["capital_valor"], 120000, "capital alto")
	var incompleto: Dictionary = ConfiguracaoCarreira.resolver({"nome": "Vale Rift", "dificuldade": "personalizado"}, false)
	executor.verificar(not incompleto["ok"], "personalizado sem capital e rivais é recusado")
	executor.verificar(incompleto["erros"].has("capital") and incompleto["erros"].has("rivais"), "aponta os dois campos")
	var brutal: Dictionary = ConfiguracaoCarreira.resolver(
		{"nome": "Vale Rift", "dificuldade": "personalizado", "capital": "baixo", "rivais": "brutais"}, false)
	executor.verificar(not brutal["ok"], "rivais do Pesadelo não aparecem no personalizado")


func teste_lista_de_dificuldades() -> void:
	var lista: Array[Dictionary] = ConfiguracaoCarreira.listar_dificuldades(false)
	var ids: Array[String] = []
	for item: Dictionary in lista:
		ids.append(item["id"])
	executor.igual(ids, ["facil", "normal", "dificil", "pesadelo", "personalizado"] as Array[String], "ordem das dificuldades")
	executor.verificar(lista[3]["bloqueada"], "pesadelo aparece bloqueado")
	executor.verificar(not ConfiguracaoCarreira.listar_dificuldades(true)[3]["bloqueada"], "pesadelo liberado")
