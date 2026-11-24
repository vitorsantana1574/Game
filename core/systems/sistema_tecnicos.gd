class_name SistemaTecnicos
extends RefCounted
## Anúncios de vaga e geração de candidatos a técnico. Ver docs/GDD.md, seção 8.8.


## Tamanhos de anúncio disponíveis, para a interface.
static func listar_anuncios() -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	for anuncio: Dictionary in Dados.tecnicos()["anuncios"]:
		lista.append({
			"id": anuncio["id"],
			"nome": anuncio["nome"],
			"candidatos": int(anuncio["candidatos"]),
			"custo": int(anuncio["custo"]),
			"dias_espera": int(anuncio["dias_espera"]),
		})
	return lista


## Dias até os candidatos chegarem. Oferta maior que a referência acelera; menor atrasa.
static func dias_de_espera(tamanho: String, oferta_minima: int) -> int:
	var regra: Dictionary = Dados.tecnicos()
	var anuncio: Dictionary = Dados.por_id(regra["anuncios"], tamanho)
	var fator: float = float(regra["oferta"]["referencia"]) / maxf(float(oferta_minima), 1.0)
	fator = clampf(fator, float(regra["oferta"]["fator_espera_minimo"]), float(regra["oferta"]["fator_espera_maximo"]))
	return maxi(1, roundi(float(anuncio["dias_espera"]) * fator))


## Gera os candidatos que respondem ao anúncio.
## Melhor reputação e oferta maior atraem técnicos melhores. O número exato pode ser menor que o máximo.
static func gerar_candidatos(carreira: Carreira, tamanho: String, oferta_minima: int) -> Array[Tecnico]:
	var regra: Dictionary = Dados.tecnicos()
	var anuncio: Dictionary = Dados.por_id(regra["anuncios"], tamanho)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash([carreira.semente, carreira.dia, carreira.contador_tecnicos, "tecnicos"])

	var maximo: int = int(anuncio["candidatos"])
	# Anúncio pequeno traz sempre 1; os maiores trazem "até" o máximo (pelo menos metade).
	var quantidade: int = maximo if maximo == 1 else rng.randi_range(ceili(maximo / 2.0), maximo)

	var qualidade: Dictionary = regra["qualidade"]
	var dobros_de_oferta: float = log(maxf(float(oferta_minima), 1.0) / float(regra["oferta"]["referencia"])) / log(2.0)
	var media: float = float(qualidade["base"]) + carreira.organizacao.reputacao * float(qualidade["por_ponto_reputacao"])
	media += dobros_de_oferta * float(qualidade["por_dobro_da_oferta"])

	var nomes: Dictionary = Dados.nomes_jogadores()
	var candidatos: Array[Tecnico] = []
	for indice: int in range(quantidade):
		carreira.contador_tecnicos += 1
		var tecnico: Tecnico = Tecnico.new()
		tecnico.id = "t%05d" % carreira.contador_tecnicos
		tecnico.nome = "%s %s" % [
			nomes["primeiros_nomes"][rng.randi() % nomes["primeiros_nomes"].size()],
			nomes["sobrenomes"][rng.randi() % nomes["sobrenomes"].size()],
		]
		tecnico.idade = rng.randi_range(int(regra["idade_minima"]), int(regra["idade_maxima"]))
		for atributo: String in Tecnico.ATRIBUTOS:
			tecnico.atributos[atributo] = clampi(roundi(rng.randfn(media, float(qualidade["desvio"]))), 1, 100)
		tecnico.salario_pedido = maxi(oferta_minima, calcular_salario(tecnico))
		candidatos.append(tecnico)
	return candidatos


## Salário mensal que um técnico pede, em reais.
static func calcular_salario(tecnico: Tecnico) -> int:
	var regra: Dictionary = Dados.tecnicos()["salario"]
	var valor: float = float(regra["base"]) * pow(maxf(tecnico.nivel_geral(), 1.0) / float(regra["referencia"]), float(regra["expoente"]))
	valor = maxf(valor, float(regra["minimo"]))
	return int(round(valor / 100.0) * 100.0)
