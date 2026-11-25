extends Node
## Barramento de sinais da lógica. A interface se conecta aqui para saber quando algo mudou.
## Lista oficial e significado de cada sinal: docs/CONTRATO.md, seção 5.

## Uma carreira nova foi criada e já está ativa. `resumo` = Jogo.resumo_carreira().
signal carreira_iniciada(resumo: Dictionary)
## Uma carreira foi carregada de um save e está ativa.
signal carreira_carregada(resumo: Dictionary)
## A carreira ativa foi gravada no espaço `slot`.
signal carreira_salva(slot: int)
## A lista de saves mudou (criação, gravação ou exclusão).
signal saves_mudaram(resumos: Array[Dictionary], ultimo_slot: int)
## O caixa da organização mudou.
## A bandeira da organização mudou (png_base64 = "" volta à arte padrão).
signal bandeira_mudou(png_base64: String)
signal dinheiro_mudou(valor: int)
## Uma dificuldade foi desbloqueada (ex.: "pesadelo").
signal dificuldade_desbloqueada(id: String)

# --- Etapa 2: tempo, elenco, mercado, técnico, finanças ---

## Um dia passou. `resumo` = Jogo.resumo_carreira().
signal dia_avancou(resumo: Dictionary)
## O elenco mudou (contratação, saída, renovação ou titulares). Releia Jogo.listar_elenco().
signal elenco_mudou()
## Um jogador entrou no elenco. `jogador` = resumo do jogador.
signal jogador_contratado(jogador: Dictionary)
## Um jogador saiu do elenco. motivo: "dispensado" | "contrato_encerrado".
signal jogador_saiu(jogador: Dictionary, motivo: String)
## Aviso de contrato perto do fim (90 e 7 dias). Vale para jogadores e técnico (`tipo`: "jogador" | "tecnico").
signal contrato_vencendo(pessoa: Dictionary, tipo: String, dias_restantes: int)
## O mercado de agentes livres foi renovado.
signal mercado_atualizado()
## Os candidatos do anúncio de técnico chegaram.
signal candidatos_chegaram(candidatos: Array[Dictionary])
## Um técnico foi contratado.
signal tecnico_contratado(tecnico: Dictionary)
## O técnico saiu. motivo: "dispensado" | "contrato_encerrado".
signal tecnico_saiu(tecnico: Dictionary, motivo: String)
## Os salários do mês foram pagos (total em reais).
signal salarios_pagos(total: int)
## Não havia dinheiro para os salários. `devido` acumula os meses em atraso.
signal salarios_atrasados(devido: int, meses: int)

# --- Economia ---

## A verba mensal da liga foi recebida.
signal verba_recebida(valor: int)
## Um empréstimo foi contratado. `emprestimo` = Jogo.estado_emprestimo().
signal emprestimo_contratado(emprestimo: Dictionary)
## Uma parcela foi paga. `restantes` = parcelas que faltam.
signal parcela_paga(valor: int, restantes: int)
## Não havia dinheiro para a parcela. `divida_atrasada` já inclui a multa.
signal parcela_atrasada(divida_atrasada: int, parcelas_atrasadas: int)
## O empréstimo terminou (última parcela paga ou quitado antes).
signal emprestimo_quitado()
## A organização faliu e a carreira terminou. `resumo` = Jogo.resumo_carreira().
## Saiu um patch novo de Crystal Legends (a cada 180 dias). A força dos campeões não é informada.
signal patch_novo(numero: int)
## O draft mudou (ação do jogador ou da IA). estado = Jogo.estado_draft().
signal draft_mudou(estado: Dictionary)
## O draft terminou: estado final com as posições de cada campeão.
signal draft_concluido(estado: Dictionary)
signal falencia(resumo: Dictionary)
