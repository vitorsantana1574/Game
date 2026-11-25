class_name SistemaEnergia
extends RefCounted
## Energia dos jogadores (GDD 6.1): cai com partidas e sobe com descanso.
## Valores em data/config/balanceamento.json ("energia") e data/config/partida.json ("simulacao").
##
## Enquanto a agenda semanal não existe (etapa 3), todo dia conta como descanso.


static func regras() -> Dictionary:
	return Dados.balanceamento()["energia"]


## Quanto uma partida custa para o jogador. Oficial custa o dobro de uma partida interna (ou de treino).
static func custo_partida(jogador: Jogador, oficial: bool) -> float:
	var r: Dictionary = regras()
	var base: float = float(r["partida_interna"]) * (float(r["multiplicador_partida_oficial"]) if oficial else 1.0)
	var resistencia: float = float(jogador.atributos.get("resistencia", 50)) / 100.0
	return base * (float(r["custo_resistencia_base"]) - float(r["custo_resistencia_reducao"]) * resistencia)


static func gastar_partida(jogador: Jogador, oficial: bool) -> void:
	jogador.energia = maxf(0.0, jogador.energia - custo_partida(jogador, oficial))


## Recuperação de um dia de descanso.
static func recuperacao_diaria(jogador: Jogador) -> float:
	var r: Dictionary = regras()
	var resistencia: float = float(jogador.atributos.get("resistencia", 50)) / 100.0
	return float(r["recuperacao_diaria_base"]) + float(r["recuperacao_diaria_por_resistencia"]) * resistencia


static func descansar_dia(jogador: Jogador) -> void:
	jogador.energia = minf(100.0, jogador.energia + recuperacao_diaria(jogador))


## Multiplicador de Micro e Macro na partida: sem perda acima do limite; abaixo, cai até a perda máxima com energia zero.
static func fator_rendimento(energia: float) -> float:
	var sim: Dictionary = Dados.partida()["simulacao"]
	var limite: float = float(sim["energia_sem_perda"])
	var falta: float = clampf((limite - energia) / limite, 0.0, 1.0)
	return 1.0 - float(sim["energia_perda_maxima"]) * falta
