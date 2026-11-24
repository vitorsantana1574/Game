extends RefCounted
## Testes do calendário: datas, fases e tempo mínimo de descanso e preparação.

var executor: Object


func teste_datas() -> void:
	executor.igual(Calendario.data(1)["texto"], "1 de janeiro, ano 1", "dia 1")
	executor.igual(Calendario.data(31)["texto"], "1 de fevereiro, ano 1", "dia 31")
	executor.igual(Calendario.data(360)["texto"], "30 de dezembro, ano 1", "último dia do ano")
	executor.igual(Calendario.data(361)["texto"], "1 de janeiro, ano 2", "virada do ano")


func teste_fases_cobrem_o_ano_sem_buracos() -> void:
	var fases: Array = Calendario.dados()["fases"]
	var esperado: int = 1
	var ok: bool = true
	for fase: Dictionary in fases:
		ok = ok and int(fase["inicio"]) == esperado and int(fase["fim"]) >= int(fase["inicio"])
		esperado = int(fase["fim"]) + 1
	executor.verificar(ok and esperado == 361, "fases em sequência, do dia 1 ao 360")
	executor.igual(Calendario.data(10)["fase"], "pre_temporada", "janeiro é pré-temporada")
	executor.verificar(Calendario.data(10)["janela_transferencias"], "janela aberta na pré-temporada")
	executor.verificar(not Calendario.data(100)["janela_transferencias"], "janela fechada durante a etapa")


func teste_jogos_da_liga_dentro_da_etapa() -> void:
	for etapa: int in [1, 2]:
		var dias: Array[int] = Calendario.dias_de_jogo_da_etapa(etapa)
		executor.igual(dias.size(), 16, "etapa %d: 14 rodadas + semifinal + final" % etapa)
		var fase: Dictionary = Calendario.fase_do_dia(dias[0])
		executor.igual(fase["id"], "etapa_%d" % etapa, "primeiro jogo dentro da etapa %d" % etapa)
		executor.igual(Calendario.fase_do_dia(dias[-1])["id"], "etapa_%d" % etapa, "final dentro da etapa %d" % etapa)


func teste_descanso_minimo_na_liga() -> void:
	var minimo: int = int(Calendario.dados()["descanso_minimo"]["dias_livres_entre_jogos_liga"])
	for etapa: int in [1, 2]:
		var dias: Array[int] = Calendario.dias_de_jogo_da_etapa(etapa)
		var menor: int = 999
		for i: int in range(1, dias.size()):
			menor = mini(menor, dias[i] - dias[i - 1] - 1)
		executor.verificar(menor >= minimo, "etapa %d: pelo menos %d dias livres entre jogos (menor: %d)" % [etapa, minimo, menor])


func teste_descanso_minimo_no_mundial() -> void:
	var minimo: int = int(Calendario.dados()["descanso_minimo"]["dias_livres_entre_jogos_mundial"])
	var dias: Array[int] = Calendario.dias_de_jogo_do_mundial()
	var menor: int = 999
	for i: int in range(1, dias.size()):
		menor = mini(menor, dias[i] - dias[i - 1] - 1)
	executor.verificar(menor >= minimo, "mundial: pelo menos %d dia livre entre jogos (menor: %d)" % [minimo, menor])
	executor.verificar(dias[0] - Calendario.dias_de_jogo_da_etapa(2)[-1] - 1 >= 7, "pelo menos 1 semana entre a final da etapa 2 e o mundial")


func teste_tempo_de_preparacao() -> void:
	var minimo: int = int(Calendario.dados()["descanso_minimo"]["dias_minimos_de_preparacao"])
	var etapa1: Array[int] = Calendario.dias_de_jogo_da_etapa(1)
	var etapa2: Array[int] = Calendario.dias_de_jogo_da_etapa(2)
	executor.verificar(etapa1[0] - 1 >= minimo, "pré-temporada: %d dias antes do 1º jogo" % (etapa1[0] - 1))
	executor.verificar(etapa2[0] - etapa1[-1] - 1 >= minimo, "meio do ano: %d dias entre a final da etapa 1 e a etapa 2" % (etapa2[0] - etapa1[-1] - 1))
	var ultimo_mundial: int = Calendario.dias_de_jogo_do_mundial()[-1]
	executor.verificar(360 - ultimo_mundial + etapa1[0] - 1 >= minimo, "fim de ano: tempo livre entre o mundial e a próxima temporada")
