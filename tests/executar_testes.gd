extends SceneTree
## Executa todos os testes automáticos da lógica, sem interface.
##
## Como rodar (na pasta do projeto):
##   godot --headless --path . -s res://tests/executar_testes.gd
##
## Sai com código 0 se tudo passou, ou 1 se algum teste falhou.

const ARQUIVOS_DE_TESTE: Array[String] = [
	"res://tests/teste_configuracao_carreira.gd",
	"res://tests/teste_gerador_jogadores.gd",
	"res://tests/teste_saves_e_carreira.gd",
	"res://tests/teste_contratos_e_mercado.gd",
	"res://tests/teste_tempo_e_tecnico.gd",
	"res://tests/teste_calendario.gd",
	"res://tests/teste_economia.gd",
	"res://tests/teste_campeoes.gd",
	"res://tests/teste_integracao_interface.gd",
	"res://tests/teste_draft.gd",
]

var _falhas: int = 0
var _verificacoes: int = 0
var _teste_atual: String = ""


func _initialize() -> void:
	# Espera um quadro para os autoloads (Jogo, Eventos) existirem.
	await process_frame
	for caminho: String in ARQUIVOS_DE_TESTE:
		var suite: Object = load(caminho).new()
		suite.set("executor", self)
		print("\n== %s" % caminho.get_file())
		for metodo: Dictionary in suite.get_method_list():
			var nome: String = metodo["name"]
			if nome.begins_with("teste_"):
				_teste_atual = nome
				var falhas_antes: int = _falhas
				if suite.has_method("antes_de_cada"):
					suite.call("antes_de_cada")
				await suite.call(nome)
				print("  %s %s" % ["ok  " if _falhas == falhas_antes else "FALHOU", nome])
	print("\n%d verificações, %d falha(s)." % [_verificacoes, _falhas])
	quit(1 if _falhas > 0 else 0)


func verificar(condicao: bool, descricao: String) -> void:
	_verificacoes += 1
	if not condicao:
		_falhas += 1
		printerr("    falha em %s: %s" % [_teste_atual, descricao])


func igual(obtido: Variant, esperado: Variant, descricao: String) -> void:
	verificar(obtido == esperado, "%s (esperado %s, obtido %s)" % [descricao, str(esperado), str(obtido)])


## Compara dicionários pelo conteúdo e pelos tipos, sem depender da ordem das chaves.
## Decimais são comparados com tolerância de 6 casas.
func mesmo_conteudo(obtido: Dictionary, esperado: Dictionary, descricao: String) -> void:
	var a: String = var_to_str(_ordenar(obtido))
	var b: String = var_to_str(_ordenar(esperado))
	verificar(a == b, "%s\n      esperado: %s\n      obtido:   %s" % [descricao, b, a])


func _ordenar(valor: Variant) -> Variant:
	if valor is Dictionary:
		var chaves: Array = valor.keys()
		chaves.sort()
		var ordenado: Dictionary = {}
		for chave: Variant in chaves:
			ordenado[chave] = _ordenar(valor[chave])
		return ordenado
	if valor is Array:
		var lista: Array = []
		for item: Variant in valor:
			lista.append(_ordenar(item))
		return lista
	if valor is float:
		# Decimais são comparados com 6 casas: diferenças menores vêm só da conversão para texto.
		return "%.6f" % valor
	return valor
