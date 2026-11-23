extends RefCounted
## Testes do modelo de jogador e do gerador.

var executor: Object


func teste_atributos_dentro_dos_limites() -> void:
	var gerador: GeradorJogadores = GeradorJogadores.new(42)
	for jogador: Jogador in gerador.gerar_varios(300, 50.0, 45.0):
		for atributo: String in Jogador.ATRIBUTOS:
			var valor: int = jogador.atributos[atributo]
			if valor < 1 or valor > 100:
				executor.verificar(false, "%s fora do limite: %d" % [atributo, valor])
				return
	executor.verificar(true, "todos os atributos entre 1 e 100")


func teste_mesma_semente_gera_mesmos_jogadores() -> void:
	var a: Array[Jogador] = GeradorJogadores.new(7).gerar_varios(20, 50.0)
	var b: Array[Jogador] = GeradorJogadores.new(7).gerar_varios(20, 50.0)
	var iguais: bool = true
	for i: int in range(20):
		iguais = iguais and var_to_str(a[i].para_dicionario()) == var_to_str(b[i].para_dicionario())
	executor.verificar(iguais, "geração determinística com a mesma semente")


func teste_ids_unicos_e_contador() -> void:
	var gerador: GeradorJogadores = GeradorJogadores.new(1, 100)
	var jogador: Jogador = gerador.gerar()
	executor.igual(jogador.id, "j000101", "id continua a partir do contador")
	executor.igual(gerador.contador(), 101, "contador avança")


func teste_qualidade_influencia_o_nivel() -> void:
	var gerador: GeradorJogadores = GeradorJogadores.new(3)
	var fracos: float = _media_geral(gerador.gerar_varios(100, 30.0, 0.0))
	var fortes: float = _media_geral(gerador.gerar_varios(100, 80.0, 0.0))
	executor.verificar(fortes > fracos + 30.0, "qualidade 80 gera jogadores bem melhores que qualidade 30 (%.1f x %.1f)" % [fortes, fracos])


func teste_potencial_nunca_abaixo_do_nivel() -> void:
	var gerador: GeradorJogadores = GeradorJogadores.new(5)
	var ok: bool = true
	for jogador: Jogador in gerador.gerar_varios(200, 60.0, 30.0):
		ok = ok and jogador.potencial >= roundi(jogador.nivel_geral()) and jogador.potencial <= 100
	executor.verificar(ok, "potencial entre o nível atual e 100")


func teste_posicao_principal_tem_maior_afinidade() -> void:
	var gerador: GeradorJogadores = GeradorJogadores.new(9)
	var ok: bool = true
	for jogador: Jogador in gerador.gerar_varios(100, 50.0):
		for posicao: String in Jogador.POSICOES:
			if jogador.afinidade_posicao[posicao] > jogador.afinidade_posicao[jogador.posicao_principal]:
				ok = false
	executor.verificar(ok, "a posição principal é sempre a de maior afinidade")


func teste_especialista_rende_mais_na_principal() -> void:
	var gerador: GeradorJogadores = GeradorJogadores.new(11)
	var especialista: Jogador = null
	var versatil: Jogador = null
	for jogador: Jogador in gerador.gerar_varios(200, 50.0):
		if jogador.versatilidade < 0.1 and especialista == null:
			especialista = jogador
		if jogador.versatilidade > 0.9 and versatil == null:
			versatil = jogador
	executor.verificar(especialista != null and versatil != null, "encontrou especialista e versátil")
	if especialista and versatil:
		var principal_e: float = especialista.afinidade_posicao[especialista.posicao_principal]
		var principal_v: float = versatil.afinidade_posicao[versatil.posicao_principal]
		executor.verificar(principal_e > principal_v, "especialista rende mais na posição principal")


func teste_salario_cresce_com_o_nivel() -> void:
	var gerador: GeradorJogadores = GeradorJogadores.new(13)
	var fraco: Jogador = gerador.gerar({"qualidade": 30, "idade": 18, "posicao": "meio"})
	var forte: Jogador = gerador.gerar({"qualidade": 85, "idade": 18, "posicao": "meio"})
	executor.verificar(forte.salario_pedido > fraco.salario_pedido * 3, "craque pede bem mais (%d x %d)" % [forte.salario_pedido, fraco.salario_pedido])
	executor.igual(fraco.salario_pedido % 100, 0, "salário arredondado para centenas")


func teste_tracos_ocultos_nao_vazam() -> void:
	var jogador: Jogador = GeradorJogadores.new(17).gerar()
	var resumo: Dictionary = jogador.resumo_publico()
	executor.verificar(not resumo.has("potencial") and not resumo.has("ego"), "potencial e ego escondidos")
	jogador.tracos_revelados.append("ego")
	executor.verificar(jogador.resumo_publico().has("ego"), "ego aparece depois de revelado")


func teste_serializacao_ida_e_volta() -> void:
	var original: Jogador = GeradorJogadores.new(19).gerar()
	var texto: String = JSON.stringify(original.para_dicionario())
	var copia: Jogador = Jogador.de_dicionario(JSON.parse_string(texto))
	executor.mesmo_conteudo(copia.para_dicionario(), original.para_dicionario(), "jogador volta igual depois do JSON")


func _media_geral(lista: Array[Jogador]) -> float:
	var soma: float = 0.0
	for jogador: Jogador in lista:
		soma += jogador.nivel_geral()
	return soma / lista.size()
