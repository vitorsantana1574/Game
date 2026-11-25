class_name Patch
extends RefCounted
## Patches de Crystal Legends: a cada 180 dias, cada campeão ganha uma força escondida (GDD 7, "patches e meta").
## A força é um multiplicador perto de 1 (0,9 a 1,1). A interface NUNCA recebe esses valores:
## o meta precisa ser descoberto (treinos e técnico).


static func regras() -> Dictionary:
	return Dados.draft()["patch"]


## Número do patch em vigor num dia da carreira (o primeiro é o 1).
static func numero_no_dia(dia: int) -> int:
	return int((dia - 1) / int(regras()["dias_por_patch"])) + 1


## Dia em que começa o próximo patch.
static func proximo_dia(dia: int) -> int:
	return numero_no_dia(dia) * int(regras()["dias_por_patch"]) + 1


## Sorteia as forças de um patch. Determinístico pela semente da carreira e pelo número do patch.
static func gerar_forcas(semente_carreira: int, numero: int) -> Dictionary:
	var r: Dictionary = regras()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("%d:patch:%d" % [semente_carreira, numero])
	var forcas: Dictionary = {}
	var ids: Array = []
	for campeao: Dictionary in Dados.campeoes()["campeoes"]:
		ids.append(campeao["id"])
	ids.sort()
	for id: String in ids:
		forcas[id] = snappedf(clampf(rng.randfn(1.0, float(r["desvio"])), float(r["forca_minima"]), float(r["forca_maxima"])), 0.001)
	return forcas
