class_name SistemaMercado
extends RefCounted
## Mercado de agentes livres: geração inicial, renovação mensal e busca.


## Cria o mercado inicial da carreira, com o mesmo número de jogadores por posição.
static func gerar_inicial(carreira: Carreira) -> void:
	var regra: Dictionary = Dados.mercado()
	var gerador: GeradorJogadores = _gerador(carreira, 1)
	carreira.mercado.clear()
	for posicao: String in Jogador.POSICOES:
		for indice: int in range(int(regra["jogadores_por_posicao"])):
			carreira.mercado.append(gerador.gerar({"posicao": posicao, "qualidade": _qualidade(carreira, gerador)}))
	carreira.contador_jogadores = gerador.contador()


## Troca parte dos agentes livres por jogadores novos (chamado todo mês).
## Jogadores em negociação bloqueada continuam no mercado.
static func renovar(carreira: Carreira) -> void:
	var regra: Dictionary = Dados.mercado()
	var gerador: GeradorJogadores = _gerador(carreira, carreira.dia)
	var quantidade: int = roundi(carreira.mercado.size() * float(regra["fracao_renovada"]))
	for vez: int in range(quantidade):
		if carreira.mercado.is_empty():
			break
		var indice: int = gerador_indice(carreira, vez)
		var saindo: Jogador = carreira.mercado[indice]
		carreira.negociacoes.erase(saindo.id)
		carreira.mercado[indice] = gerador.gerar({"posicao": saindo.posicao_principal, "qualidade": _qualidade(carreira, gerador)})
	carreira.contador_jogadores = gerador.contador()


## Lista o mercado com filtros simples. Devolve resumos públicos.
## filtros: {"posicao": String (opcional), "ordenar": "nivel" | "salario" | "idade" (opcional)}
static func listar(carreira: Carreira, filtros: Dictionary = {}) -> Array[Dictionary]:
	var lista: Array[Jogador] = []
	var posicao: String = str(filtros.get("posicao", ""))
	for jogador: Jogador in carreira.mercado:
		if posicao.is_empty() or jogador.posicao_principal == posicao:
			lista.append(jogador)
	match str(filtros.get("ordenar", "nivel")):
		"salario":
			lista.sort_custom(func(a: Jogador, b: Jogador) -> bool: return a.salario_pedido < b.salario_pedido)
		"idade":
			lista.sort_custom(func(a: Jogador, b: Jogador) -> bool: return a.idade < b.idade)
		_:
			lista.sort_custom(func(a: Jogador, b: Jogador) -> bool: return a.nivel_geral() > b.nivel_geral())
	var resumos: Array[Dictionary] = []
	for jogador: Jogador in lista:
		var resumo: Dictionary = jogador.resumo_publico(carreira.dia)
		resumo["negociacao"] = estado_negociacao(carreira, jogador)
		resumos.append(resumo)
	return resumos


## Estado da negociação com um jogador, para a interface.
static func estado_negociacao(carreira: Carreira, jogador: Jogador) -> Dictionary:
	var estado: Dictionary = carreira.negociacoes.get(jogador.id, {})
	var paciencia: int = int(estado.get("paciencia", Negociacao.paciencia_inicial(jogador)))
	var bloqueado_ate: int = int(estado.get("bloqueado_ate", 0))
	return {
		"paciencia": paciencia,
		"bloqueado": bloqueado_ate >= carreira.dia,
		"bloqueado_ate": bloqueado_ate,
	}


## Índice determinístico para a renovação (varia com o dia e a vez).
static func gerador_indice(carreira: Carreira, vez: int) -> int:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash([carreira.semente, carreira.dia, vez, "indice"])
	return rng.randi_range(0, carreira.mercado.size() - 1)


static func _gerador(carreira: Carreira, momento: int) -> GeradorJogadores:
	return GeradorJogadores.new(hash([carreira.semente, momento, "mercado"]), carreira.contador_jogadores)


static func _qualidade(carreira: Carreira, gerador: GeradorJogadores) -> float:
	var faixa: Dictionary = Dados.mercado()["qualidade_por_liga"][carreira.nivel_liga]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash([carreira.semente, gerador.contador(), "qualidade"])
	return float(faixa["media"]) + rng.randf_range(-float(faixa["variacao"]), float(faixa["variacao"]))
