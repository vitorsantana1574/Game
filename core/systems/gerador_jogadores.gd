class_name GeradorJogadores
extends RefCounted
## Cria jogadores fictícios. Com a mesma semente, gera sempre os mesmos jogadores.

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _contador: int = 0


func _init(semente: int = 0, contador_inicial: int = 0) -> void:
	_rng.seed = semente
	_contador = contador_inicial


## Quantos jogadores já foram gerados (guardar na carreira para manter ids únicos).
func contador() -> int:
	return _contador


## Gera um jogador.
## Opções (todas opcionais):
##   "qualidade": média desejada dos atributos (1 a 100). Padrão: 50.
##   "posicao": posição principal. Padrão: sorteada.
##   "idade": idade fixa. Padrão: sorteada.
func gerar(opcoes: Dictionary = {}) -> Jogador:
	var balanco: Dictionary = Dados.balanceamento()
	var geracao: Dictionary = balanco["geracao"]
	var jogador: Jogador = Jogador.new()

	_contador += 1
	jogador.id = "j%06d" % _contador
	_gerar_nomes(jogador)

	var idade_padrao: int = _rng.randi_range(int(geracao["idade_minima"]), int(geracao["idade_maxima"]))
	jogador.idade = int(opcoes.get("idade", idade_padrao))

	var posicao: String = str(opcoes.get("posicao", Jogador.POSICOES[_rng.randi() % Jogador.POSICOES.size()]))
	jogador.posicao_principal = posicao
	jogador.versatilidade = snappedf(_rng.randf(), 0.001)
	_gerar_afinidades(jogador, balanco["afinidade_posicao"])

	var qualidade: float = clampf(float(opcoes.get("qualidade", 50)), 1.0, 100.0)
	_gerar_atributos(jogador, qualidade, float(geracao["desvio_atributos"]), balanco["atributos"])

	_gerar_tracos(jogador, qualidade)
	jogador.energia = float(geracao["energia_inicial"])
	jogador.satisfacao = float(geracao["satisfacao_inicial"])
	jogador.lealdade = float(geracao["lealdade_inicial"])
	jogador.salario_pedido = calcular_salario_pedido(jogador)
	return jogador


## Gera vários jogadores de uma vez, com qualidade variando em torno da média.
func gerar_varios(quantidade: int, qualidade_media: float, variacao: float = 10.0) -> Array[Jogador]:
	var lista: Array[Jogador] = []
	for indice: int in range(quantidade):
		var qualidade: float = qualidade_media + _rng.randf_range(-variacao, variacao)
		lista.append(gerar({"qualidade": qualidade}))
	return lista


## Salário mensal pedido, em reais. Ver data/config/balanceamento.json ("salario").
static func calcular_salario_pedido(jogador: Jogador) -> int:
	var regra: Dictionary = Dados.balanceamento()["salario"]
	var geral: float = maxf(jogador.nivel_geral(), 1.0)
	var valor: float = float(regra["base"]) * pow(geral / float(regra["referencia"]), float(regra["expoente"]))
	valor *= 1.0 + float(jogador.experiencia) * float(regra["bonus_por_experiencia"])
	valor = maxf(valor, float(regra["minimo"]))
	return int(round(valor / 100.0) * 100.0)


func _gerar_nomes(jogador: Jogador) -> void:
	var nomes: Dictionary = Dados.nomes_jogadores()
	jogador.nome_real = "%s %s" % [_sortear(nomes["primeiros_nomes"]), _sortear(nomes["sobrenomes"])]
	jogador.apelido = _sortear(nomes["apelido_inicio"]) + _sortear(nomes["apelido_fim"])


## Especialista: muito bom na principal, fraco nas outras.
## Versátil: um pouco menos na principal, bom em uma ou duas secundárias.
func _gerar_afinidades(jogador: Jogador, regra: Dictionary) -> void:
	var v: float = jogador.versatilidade
	var principal: float = lerpf(float(regra["principal_especialista"]), float(regra["principal_versatil"]), v)
	var secundaria: float = lerpf(float(regra["secundaria_especialista"]), float(regra["secundaria_versatil"]), v)
	var outras: Array[String] = []
	for posicao: String in Jogador.POSICOES:
		if posicao != jogador.posicao_principal:
			outras.append(posicao)
	_embaralhar(outras)
	var quantidade_secundarias: int = 1 if v < 0.5 else 2
	for posicao: String in Jogador.POSICOES:
		jogador.afinidade_posicao[posicao] = float(regra["sem_afinidade"])
	for indice: int in range(quantidade_secundarias):
		var variacao: float = _rng.randf_range(-0.05, 0.05)
		jogador.afinidade_posicao[outras[indice]] = snappedf(clampf(secundaria + variacao, 0.0, 1.0), 0.01)
	jogador.afinidade_posicao[jogador.posicao_principal] = snappedf(principal, 0.01)


## Atributos em torno da qualidade, com os mais importantes da posição um pouco mais altos.
func _gerar_atributos(jogador: Jogador, qualidade: float, desvio: float, limites: Dictionary) -> void:
	var pesos: Dictionary = Dados.balanceamento()["pesos_por_posicao"][jogador.posicao_principal]
	for atributo: String in Jogador.ATRIBUTOS:
		# Peso médio é 0.2: atributos com peso maior puxam para cima, com peso menor puxam para baixo.
		var inclinacao: float = (float(pesos[atributo]) - 0.2) * 40.0
		var valor: float = _rng.randfn(qualidade + inclinacao, desvio)
		jogador.atributos[atributo] = clampi(roundi(valor), int(limites["minimo"]), int(limites["maximo"]))


func _gerar_tracos(jogador: Jogador, qualidade: float) -> void:
	var geracao: Dictionary = Dados.balanceamento()["geracao"]
	var idade_min: int = int(geracao["idade_minima"])
	var idade_max: int = int(geracao["idade_maxima"])
	var juventude: float = 1.0 - inverse_lerp(float(idade_min), float(idade_max), float(jogador.idade))

	# Potencial: teto de evolução. Jovens têm mais margem para crescer.
	var geral: float = jogador.nivel_geral()
	var margem: float = _rng.randf_range(0.0, 30.0) * juventude
	jogador.potencial = clampi(roundi(geral + margem), roundi(geral), 100)

	# Experiência: cresce com a idade e com a qualidade. Iniciantes podem não ter nenhuma.
	var anos_de_carreira: float = maxf(0.0, float(jogador.idade - idade_min) - _rng.randf_range(0.0, 3.0))
	jogador.experiencia = maxi(0, roundi(anos_de_carreira * _rng.randf_range(5.0, 15.0) * (qualidade / 50.0)))

	# Ego: aleatório, um pouco maior em jogadores melhores.
	var tendencia: float = 35.0 + (qualidade - 50.0) * 0.5
	jogador.ego = clampi(roundi(_rng.randfn(tendencia, 15.0)), 1, 100)


func _sortear(lista: Array) -> String:
	return str(lista[_rng.randi() % lista.size()])


func _embaralhar(lista: Array) -> void:
	for i: int in range(lista.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var temporario: Variant = lista[i]
		lista[i] = lista[j]
		lista[j] = temporario
