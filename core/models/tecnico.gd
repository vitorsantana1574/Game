class_name Tecnico
extends RefCounted
## Técnico do time. Ver docs/GDD.md, seção 8.8.
## Atributos de 1 a 100.

const ATRIBUTOS: Array[String] = ["macro", "conhecimento", "olheiro"]

var id: String = ""
var nome: String = ""
var idade: int = 40
## macro, conhecimento, olheiro
var atributos: Dictionary = {}
## Cansaço de 0 a 100. Só se recupera com férias (etapa 3).
var cansaco: float = 0.0
## Salário mensal que ele pede, em reais.
var salario_pedido: int = 0
var contrato: Contrato = null


func nivel_geral() -> float:
	var soma: float = 0.0
	for atributo: String in ATRIBUTOS:
		soma += float(atributos.get(atributo, 1))
	return soma / ATRIBUTOS.size()


func resumo(dia_atual: int) -> Dictionary:
	return {
		"id": id,
		"nome": nome,
		"idade": idade,
		"atributos": atributos.duplicate(),
		"nivel_geral": roundi(nivel_geral()),
		"cansaco": roundi(cansaco),
		"salario_pedido": salario_pedido,
		"contrato": contrato.resumo(dia_atual) if contrato else {},
	}


func para_dicionario() -> Dictionary:
	return {
		"id": id,
		"nome": nome,
		"idade": idade,
		"atributos": atributos,
		"cansaco": cansaco,
		"salario_pedido": salario_pedido,
		"contrato": contrato.para_dicionario() if contrato else {},
	}


static func de_dicionario(dados: Dictionary) -> Tecnico:
	var tecnico: Tecnico = Tecnico.new()
	tecnico.id = str(dados["id"])
	tecnico.nome = str(dados["nome"])
	tecnico.idade = int(dados["idade"])
	for atributo: String in dados["atributos"]:
		tecnico.atributos[atributo] = int(dados["atributos"][atributo])
	tecnico.cansaco = float(dados["cansaco"])
	tecnico.salario_pedido = int(dados["salario_pedido"])
	if not dados["contrato"].is_empty():
		tecnico.contrato = Contrato.de_dicionario(dados["contrato"])
	return tecnico
