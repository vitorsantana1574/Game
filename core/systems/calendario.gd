class_name Calendario
extends RefCounted
## Datas e fases do ano. Ver data/config/calendario.json e docs/GDD.md (calendário).
## O "dia" da carreira começa em 1 (1º de janeiro do ano 1) e nunca reinicia.


static func dados() -> Dictionary:
	return Dados.carregar("res://data/config/calendario.json")


## Dia dentro do ano (1 a 360).
static func dia_do_ano(dia: int) -> int:
	return ((dia - 1) % int(dados()["dias_por_ano"])) + 1


static func ano(dia: int) -> int:
	return int((dia - 1) / int(dados()["dias_por_ano"])) + 1


## Data legível e fase atual.
## Retorno: {"ano", "mes", "dia_do_mes", "nome_mes", "texto", "fase", "fase_nome", "janela_transferencias"}
static func data(dia: int) -> Dictionary:
	var no_ano: int = dia_do_ano(dia)
	var mes: int = int((no_ano - 1) / Dados.dias_por_mes()) + 1
	var dia_do_mes: int = ((no_ano - 1) % Dados.dias_por_mes()) + 1
	var nome_mes: String = dados()["meses"][mes - 1]
	var fase: Dictionary = fase_do_dia(dia)
	return {
		"ano": ano(dia),
		"mes": mes,
		"dia_do_mes": dia_do_mes,
		"nome_mes": nome_mes,
		"texto": "%d de %s, ano %d" % [dia_do_mes, nome_mes, ano(dia)],
		"fase": fase["id"],
		"fase_nome": fase["nome"],
		"janela_transferencias": bool(fase.get("janela_transferencias", false)),
	}


static func fase_do_dia(dia: int) -> Dictionary:
	var no_ano: int = dia_do_ano(dia)
	for fase: Dictionary in dados()["fases"]:
		if no_ano >= int(fase["inicio"]) and no_ano <= int(fase["fim"]):
			return fase
	return dados()["fases"][0]


## Dias (dentro do ano) com jogos da liga de uma etapa: 14 rodadas, semifinal e final.
static func dias_de_jogo_da_etapa(etapa: int) -> Array[int]:
	var liga: Dictionary = dados()["liga"]
	var primeira: int = int(liga["primeira_rodada_etapa_%d" % etapa])
	var dias: Array[int] = []
	for rodada: int in range(int(liga["rodadas"])):
		dias.append(primeira + rodada * int(liga["dias_entre_rodadas"]))
	var semifinal: int = dias[-1] + int(liga["dias_ate_semifinal"])
	dias.append(semifinal)
	dias.append(semifinal + int(liga["dias_semifinal_ate_final"]))
	return dias


## Dias (dentro do ano) com jogos do mundial, em ordem.
static func dias_de_jogo_do_mundial() -> Array[int]:
	var m: Dictionary = dados()["mundial"]
	var dias: Array[int] = []
	for dia: Variant in m["play_in"]:
		dias.append(int(dia))
	for dia: Variant in m["fase_suica"]:
		dias.append(int(dia))
	for chave: String in ["quartas", "semifinal", "final"]:
		dias.append(int(m[chave]))
	return dias


## Todos os dias de jogo do ano, em ordem (para quem disputa tudo, inclusive o mundial).
static func todos_os_dias_de_jogo() -> Array[int]:
	var dias: Array[int] = dias_de_jogo_da_etapa(1)
	dias.append_array(dias_de_jogo_da_etapa(2))
	dias.append_array(dias_de_jogo_do_mundial())
	return dias
