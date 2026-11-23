class_name ConfiguracaoCarreira
extends RefCounted
## Valida e resolve as escolhas da tela Criar Equipe.

const ERRO_NOME_VAZIO: String = "nome_vazio"
const ERRO_NOME_CURTO: String = "nome_curto"
const ERRO_NOME_LONGO: String = "nome_longo"
const ERRO_NOME_CARACTERES: String = "nome_caracteres"
const ERRO_DIFICULDADE_INVALIDA: String = "dificuldade_invalida"
const ERRO_DIFICULDADE_BLOQUEADA: String = "dificuldade_bloqueada"
const ERRO_CAPITAL_INVALIDO: String = "capital_invalido"
const ERRO_RIVAIS_INVALIDOS: String = "rivais_invalidos"

## Letras (com acento), números, espaço e . - & '
const _PADRAO_NOME: String = "^[\\p{L}\\p{N} .\\-&']+$"


## Limpa o nome: tira espaços nas pontas e espaços repetidos no meio.
static func limpar_nome(nome: String) -> String:
	var limpo: String = nome.strip_edges()
	var espacos: RegEx = RegEx.create_from_string("\\s+")
	return espacos.sub(limpo, " ", true)


## Valida o nome da organização. Devolve "" se estiver tudo certo, ou o código do erro.
static func validar_nome(nome: String) -> String:
	var limites: Dictionary = Dados.dificuldades()["nome_organizacao"]
	var limpo: String = limpar_nome(nome)
	if limpo.is_empty():
		return ERRO_NOME_VAZIO
	if limpo.length() < int(limites["minimo"]):
		return ERRO_NOME_CURTO
	if limpo.length() > int(limites["maximo"]):
		return ERRO_NOME_LONGO
	if RegEx.create_from_string(_PADRAO_NOME).search(limpo) == null:
		return ERRO_NOME_CARACTERES
	return ""


## Mensagem pronta para exibir ao jogador, a partir de um código de erro.
static func mensagem_erro(codigo: String) -> String:
	var limites: Dictionary = Dados.dificuldades()["nome_organizacao"]
	match codigo:
		ERRO_NOME_VAZIO: return "Digite um nome para a organização."
		ERRO_NOME_CURTO: return "O nome precisa ter pelo menos %d caracteres." % int(limites["minimo"])
		ERRO_NOME_LONGO: return "O nome pode ter no máximo %d caracteres." % int(limites["maximo"])
		ERRO_NOME_CARACTERES: return "Use apenas letras, números, espaços e . - & '"
		ERRO_DIFICULDADE_INVALIDA: return "Escolha uma dificuldade."
		ERRO_DIFICULDADE_BLOQUEADA: return "Esta dificuldade ainda está bloqueada."
		ERRO_CAPITAL_INVALIDO: return "Escolha o capital inicial."
		ERRO_RIVAIS_INVALIDOS: return "Escolha a força dos rivais."
	return "Não foi possível criar a carreira."


## Lista das dificuldades para a tela, já com o estado de bloqueio.
static func listar_dificuldades(pesadelo_desbloqueado: bool) -> Array[Dictionary]:
	var dados: Dictionary = Dados.dificuldades()
	var lista: Array[Dictionary] = []
	for predefinicao: Dictionary in dados["predefinicoes"]:
		var capital: Dictionary = Dados.por_id(dados["capitais"], predefinicao["capital"])
		var rivais: Dictionary = Dados.por_id(dados["rivais"], predefinicao["rivais"])
		var bloqueada: bool = bool(predefinicao["bloqueada_no_inicio"]) and not pesadelo_desbloqueado
		lista.append({
			"id": predefinicao["id"],
			"nome": predefinicao["nome"],
			"bloqueada": bloqueada,
			"condicao_desbloqueio": predefinicao.get("condicao_desbloqueio", ""),
			"capital": capital["id"],
			"capital_valor": int(capital["valor"]),
			"capital_nome": capital["nome"],
			"rivais": rivais["id"],
			"rivais_nome": rivais["nome"],
		})
	lista.append({
		"id": dados["personalizado"]["id"],
		"nome": dados["personalizado"]["nome"],
		"bloqueada": false,
		"condicao_desbloqueio": "",
	})
	return lista


## Opções de capital e rivais disponíveis no modo Personalizado.
static func opcoes_personalizado() -> Dictionary:
	var dados: Dictionary = Dados.dificuldades()
	var capitais: Array[Dictionary] = []
	for id: String in dados["personalizado"]["capitais_permitidos"]:
		var capital: Dictionary = Dados.por_id(dados["capitais"], id)
		capitais.append({"id": id, "nome": capital["nome"], "valor": int(capital["valor"])})
	var rivais: Array[Dictionary] = []
	for id: String in dados["personalizado"]["rivais_permitidos"]:
		var rival: Dictionary = Dados.por_id(dados["rivais"], id)
		rivais.append({"id": id, "nome": rival["nome"]})
	return {"capitais": capitais, "rivais": rivais}


## Valida as escolhas e devolve a configuração resolvida.
## Retorno: {"ok": true, "config": {...}} ou {"ok": false, "erros": {"campo": "codigo"}}
static func resolver(escolhas: Dictionary, pesadelo_desbloqueado: bool) -> Dictionary:
	var dados: Dictionary = Dados.dificuldades()
	var erros: Dictionary = {}

	var erro_nome: String = validar_nome(str(escolhas.get("nome", "")))
	if not erro_nome.is_empty():
		erros["nome"] = erro_nome

	var dificuldade: String = str(escolhas.get("dificuldade", ""))
	var capital_id: String = ""
	var rivais_id: String = ""
	if dificuldade == dados["personalizado"]["id"]:
		capital_id = str(escolhas.get("capital", ""))
		rivais_id = str(escolhas.get("rivais", ""))
		if not capital_id in dados["personalizado"]["capitais_permitidos"]:
			erros["capital"] = ERRO_CAPITAL_INVALIDO
		if not rivais_id in dados["personalizado"]["rivais_permitidos"]:
			erros["rivais"] = ERRO_RIVAIS_INVALIDOS
	else:
		var predefinicao: Dictionary = Dados.por_id(dados["predefinicoes"], dificuldade)
		if predefinicao.is_empty():
			erros["dificuldade"] = ERRO_DIFICULDADE_INVALIDA
		elif bool(predefinicao["bloqueada_no_inicio"]) and not pesadelo_desbloqueado:
			erros["dificuldade"] = ERRO_DIFICULDADE_BLOQUEADA
		else:
			capital_id = predefinicao["capital"]
			rivais_id = predefinicao["rivais"]

	if not erros.is_empty():
		return {"ok": false, "erros": erros}

	var capital: Dictionary = Dados.por_id(dados["capitais"], capital_id)
	var rivais: Dictionary = Dados.por_id(dados["rivais"], rivais_id)
	return {
		"ok": true,
		"config": {
			"nome": limpar_nome(str(escolhas["nome"])),
			"dificuldade": dificuldade,
			"capital": capital_id,
			"capital_valor": int(capital["valor"]),
			"rivais": rivais_id,
			"qualidade_rivais": int(rivais["qualidade_media"]),
		},
	}
