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
signal dinheiro_mudou(valor: int)
## Uma dificuldade foi desbloqueada (ex.: "pesadelo").
signal dificuldade_desbloqueada(id: String)
