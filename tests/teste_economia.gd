extends RefCounted
## Testes da economia: verba da liga, empréstimo, atraso e falência.

const PASTA_TESTE: String = "user://testes_saves"

var executor: Object
var _faliu: bool = false


func antes_de_cada() -> void:
	Jogo.saves.pasta = PASTA_TESTE
	for slot: int in range(SistemaSaves.TOTAL_SLOTS):
		Jogo.saves.excluir(slot)
	Jogo.nova_carreira({"nome": "Vale Rift", "dificuldade": "normal"})
	_faliu = false
	if not Eventos.falencia.is_connected(_ao_falir):
		Eventos.falencia.connect(_ao_falir)


func teste_verba_por_desempenho() -> void:
	executor.igual(Financas.verba_mensal("regional", 0), 12000, "sem histórico: verba base")
	executor.igual(Financas.verba_mensal("regional", 1), 18000, "1º lugar: 1,5x")
	executor.igual(Financas.verba_mensal("regional", 8), 9000, "último: 0,75x")
	executor.verificar(Financas.verba_mensal("nacional", 4) > Financas.verba_mensal("regional", 1), "nacional paga mais que a regional")


func teste_verba_entra_todo_mes() -> void:
	var antes: int = Jogo.carreira.organizacao.dinheiro
	Jogo.avancar_dia(30)
	executor.igual(Jogo.carreira.organizacao.dinheiro, antes + 12000, "verba no dia 31")


func teste_capital_inicial_monta_um_time() -> void:
	# Normal: 5 titulares medianos + técnico de referência (~R$ 16.800/mês) precisam caber por bastante tempo.
	var custo_mensal: int = 12800 + 4000
	var saldo: int = 80000
	var meses: int = 0
	while saldo > 0 and meses < 60:
		saldo += Financas.verba_mensal("regional", 0) - custo_mensal
		meses += 1
	executor.verificar(meses >= 12, "Normal sustenta 5 titulares + técnico por pelo menos 1 ano (%d meses)" % meses)
	saldo = 40000
	meses = 0
	while saldo > 0 and meses < 60:
		saldo += Financas.verba_mensal("regional", 0) - custo_mensal
		meses += 1
	executor.verificar(meses >= 6, "Difícil sustenta o time mínimo por pelo menos 6 meses (%d meses)" % meses)


func teste_parcela_tabela_price() -> void:
	var p: int = Financas.parcela(50000, 12)
	executor.verificar(p >= 5641 and p <= 5642, "R$ 50.000 em 12x a 5%% = ~R$ 5.641 (obtido %d)" % p)
	var simulacao: Dictionary = Jogo.simular_emprestimo(50000, 12)
	executor.igual(simulacao["juros_total"], simulacao["total"] - 50000, "juros totais")


func teste_contratar_e_pagar_emprestimo() -> void:
	var antes: int = Jogo.carreira.organizacao.dinheiro
	var r: Dictionary = Jogo.contratar_emprestimo(30000, 3)
	executor.verificar(r["ok"], "empréstimo contratado")
	executor.igual(Jogo.carreira.organizacao.dinheiro, antes + 30000, "dinheiro entrou")
	executor.verificar(not Jogo.contratar_emprestimo(10000, 3)["ok"], "só um empréstimo por vez")
	var parcela: int = Jogo.estado_emprestimo()["parcela"]
	Jogo.avancar_dia(30)
	executor.igual(Jogo.estado_emprestimo()["parcelas_restantes"], 2, "1ª parcela paga")
	Jogo.avancar_dia(60)
	executor.verificar(Jogo.estado_emprestimo().is_empty(), "quitado após 3 parcelas")
	executor.igual(Jogo.carreira.organizacao.dinheiro, antes + 30000 + 12000 * 3 - parcela * 3, "pagou as 3 parcelas")


func teste_limites_do_emprestimo() -> void:
	var opcoes: Dictionary = Jogo.opcoes_emprestimo()
	executor.igual(opcoes["limite"], 72000, "limite = 6 verbas da regional")
	executor.verificar(not Jogo.contratar_emprestimo(80000, 12)["ok"], "acima do limite")
	executor.verificar(not Jogo.contratar_emprestimo(1000, 12)["ok"], "abaixo do mínimo")
	executor.verificar(not Jogo.contratar_emprestimo(10000, 5)["ok"], "prazo inválido")


func teste_quitar_antes_custa_menos() -> void:
	Jogo.contratar_emprestimo(50000, 12)
	var saldo: int = Jogo.estado_emprestimo()["saldo_para_quitar"]
	executor.verificar(saldo >= 50000 and saldo <= 50012, "quitar na hora custa o valor emprestado (com arredondamento de centavos: %d)" % saldo)
	Jogo.avancar_dia(30)
	var depois: Dictionary = Jogo.estado_emprestimo()
	executor.verificar(depois["saldo_para_quitar"] < depois["parcela"] * depois["parcelas_restantes"], "quitar antes economiza juros futuros")
	executor.verificar(Jogo.quitar_emprestimo()["ok"], "quitou")
	executor.verificar(Jogo.estado_emprestimo().is_empty(), "sem empréstimo")


func teste_atraso_e_falencia() -> void:
	Jogo.contratar_emprestimo(72000, 3)
	Jogo.carreira.organizacao.dinheiro = -10_000_000
	var reputacao: float = Jogo.carreira.organizacao.reputacao
	Jogo.avancar_dia(30)
	executor.igual(Jogo.estado_emprestimo()["parcelas_atrasadas"], 1, "1 parcela atrasada")
	executor.verificar(Jogo.estado_emprestimo()["divida_atrasada"] > Jogo.estado_emprestimo()["parcela"], "dívida atrasada inclui multa")
	executor.verificar(Jogo.carreira.organizacao.reputacao < reputacao, "reputação caiu")
	executor.verificar(not _faliu, "ainda não faliu")
	Jogo.avancar_dia(60)
	executor.verificar(_faliu, "3 parcelas atrasadas sem dinheiro: falência")
	executor.verificar(Jogo.resumo_carreira()["encerrada"], "carreira encerrada")
	executor.verificar(not Jogo.avancar_dia()["ok"], "não avança mais")
	executor.verificar(not Jogo.contratar_emprestimo(10000, 3)["ok"], "nenhuma ação depois da falência")


func teste_save_preserva_emprestimo() -> void:
	Jogo.contratar_emprestimo(20000, 6)
	Jogo.salvar()
	Jogo.carreira = null
	Jogo.carregar(0)
	executor.igual(Jogo.estado_emprestimo()["parcelas_restantes"], 6, "empréstimo preservado no save")


func _ao_falir(_resumo: Dictionary) -> void:
	_faliu = true
