class_name Carreira
extends RefCounted
## Uma carreira inteira: é o que vai para o save.

## Aumente quando o formato do save mudar, para converter saves antigos.
const VERSAO_SAVE: int = 1

var config: Dictionary = {}
var organizacao: Organizacao = Organizacao.new()
var dia: int = 1
var nivel_liga: String = "regional"
## Semente dos sorteios desta carreira (gerador de jogadores, simulação etc.).
var semente: int = 0
## Quantos jogadores e técnicos já foram gerados (garante ids únicos).
var contador_jogadores: int = 0
var contador_tecnicos: int = 0

## Agentes livres disponíveis para contratação.
var mercado: Array[Jogador] = []
## Estado das negociações: id do jogador -> {"paciencia": int, "bloqueado_ate": int}
var negociacoes: Dictionary = {}
## Anúncio de técnico em andamento: {"tamanho", "oferta_minima", "dia_chegada"} ou {}.
var anuncio_tecnico: Dictionary = {}
## Candidatos a técnico que já responderam: lista de {"tecnico": Tecnico, "expira_em": int}
var candidatos_tecnico: Array[Dictionary] = []
## Avisos de contrato já enviados, para não repetir: "id_jogador:dias".
var avisos_enviados: Array[String] = []
## Carreira encerrada (ex.: falência). Nenhuma ação é aceita depois disso.
var encerrada: bool = false
var motivo_encerramento: String = ""
## Patch de Crystal Legends em vigor e a força escondida de cada campeão (nunca vai para a interface).
var patch_numero: int = 1
var forcas_patch: Dictionary = {}

## Livro de lançamentos (entradas e saídas de dinheiro), do mais antigo para o mais novo.
## Cada item: {"dia", "descricao", "valor", "categoria"}. Guarda só os últimos MAXIMO_LANCAMENTOS.
var lancamentos: Array[Dictionary] = []
const MAXIMO_LANCAMENTOS: int = 200


func registrar_lancamento(descricao: String, valor: int, categoria: String) -> void:
	lancamentos.append({"dia": dia, "descricao": descricao, "valor": valor, "categoria": categoria})
	if lancamentos.size() > MAXIMO_LANCAMENTOS:
		lancamentos = lancamentos.slice(lancamentos.size() - MAXIMO_LANCAMENTOS)


## Mês atual da carreira (começa em 1).
func mes() -> int:
	return int((dia - 1) / Dados.dias_por_mes()) + 1


func jogador_do_mercado(id: String) -> Jogador:
	for jogador: Jogador in mercado:
		if jogador.id == id:
			return jogador
	return null


## Texto curto da fase atual, usado no resumo dos saves.
func descricao_fase() -> String:
	var nomes_liga: Dictionary = {"regional": "Regional", "nacional": "Nacional", "mundial": "Mundial"}
	var data: Dictionary = Calendario.data(dia)
	return "%s · %s · %d/%s, ano %d" % [nomes_liga.get(nivel_liga, nivel_liga), data["fase_nome"],
		data["dia_do_mes"], data["nome_mes"].substr(0, 3), data["ano"]]


func para_dicionario() -> Dictionary:
	return {
		"versao": VERSAO_SAVE,
		"config": config,
		"organizacao": organizacao.para_dicionario(),
		"dia": dia,
		"nivel_liga": nivel_liga,
		"semente": semente,
		"contador_jogadores": contador_jogadores,
		"contador_tecnicos": contador_tecnicos,
		"mercado": mercado.map(func(j: Jogador) -> Dictionary: return j.para_dicionario()),
		"negociacoes": negociacoes,
		"anuncio_tecnico": anuncio_tecnico,
		"candidatos_tecnico": candidatos_tecnico.map(func(c: Dictionary) -> Dictionary:
			return {"tecnico": (c["tecnico"] as Tecnico).para_dicionario(), "expira_em": c["expira_em"]}),
		"avisos_enviados": avisos_enviados,
		"encerrada": encerrada,
		"motivo_encerramento": motivo_encerramento,
		"lancamentos": lancamentos,
		"patch_numero": patch_numero,
		"forcas_patch": forcas_patch,
	}


static func de_dicionario(dados: Dictionary) -> Carreira:
	var carreira: Carreira = Carreira.new()
	carreira.config = dados["config"].duplicate(true)
	# O JSON devolve todo número como decimal: os campos inteiros da configuração voltam a ser int.
	for campo: String in ["capital_valor", "qualidade_rivais"]:
		if carreira.config.has(campo):
			carreira.config[campo] = int(carreira.config[campo])
	carreira.organizacao = Organizacao.de_dicionario(dados["organizacao"])
	carreira.dia = int(dados["dia"])
	carreira.nivel_liga = str(dados["nivel_liga"])
	carreira.semente = int(dados["semente"])
	carreira.contador_jogadores = int(dados.get("contador_jogadores", 0))
	carreira.contador_tecnicos = int(dados.get("contador_tecnicos", 0))
	for jogador: Dictionary in dados.get("mercado", []):
		carreira.mercado.append(Jogador.de_dicionario(jogador))
	for id: String in dados.get("negociacoes", {}):
		var estado: Dictionary = dados["negociacoes"][id]
		carreira.negociacoes[id] = {"paciencia": int(estado["paciencia"]), "bloqueado_ate": int(estado["bloqueado_ate"])}
	var anuncio: Dictionary = dados.get("anuncio_tecnico", {})
	if not anuncio.is_empty():
		carreira.anuncio_tecnico = {
			"tamanho": str(anuncio["tamanho"]),
			"oferta_minima": int(anuncio["oferta_minima"]),
			"dia_chegada": int(anuncio["dia_chegada"]),
		}
	for candidato: Dictionary in dados.get("candidatos_tecnico", []):
		carreira.candidatos_tecnico.append({
			"tecnico": Tecnico.de_dicionario(candidato["tecnico"]),
			"expira_em": int(candidato["expira_em"]),
		})
	for aviso: Variant in dados.get("avisos_enviados", []):
		carreira.avisos_enviados.append(str(aviso))
	carreira.encerrada = bool(dados.get("encerrada", false))
	carreira.motivo_encerramento = str(dados.get("motivo_encerramento", ""))
	carreira.patch_numero = int(dados.get("patch_numero", Patch.numero_no_dia(carreira.dia)))
	for id_campeao: String in dados.get("forcas_patch", {}):
		carreira.forcas_patch[id_campeao] = float(dados["forcas_patch"][id_campeao])
	if carreira.forcas_patch.is_empty():
		carreira.forcas_patch = Patch.gerar_forcas(carreira.semente, carreira.patch_numero)
	for item: Dictionary in dados.get("lancamentos", []):
		carreira.lancamentos.append({"dia": int(item["dia"]), "descricao": str(item["descricao"]),
			"valor": int(item["valor"]), "categoria": str(item["categoria"])})
	return carreira
