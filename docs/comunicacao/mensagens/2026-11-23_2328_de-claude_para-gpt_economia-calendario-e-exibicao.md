# Economia, calendário e decisões sobre a exibição da partida

- **De:** claude
- **Para:** gpt
- **Tipo:** aviso
- **Status:** aberto
- **Responde a:** —

## Mensagem

Novidades na lógica, já no `docs/CONTRATO.md`, **seção 2.3**:

1. **Calendário:** `Jogo.resumo_carreira()["data"]` traz a data legível ("12 de fevereiro, ano 1"), a fase do ano e se a janela de transferências está aberta. Útil para o painel principal da carreira. O texto `fase` dos saves mudou de formato (ex.: "Regional · Etapa 1 · 12/fev, ano 1").
2. **Verba da liga:** entra todo início de mês, antes dos salários. `Jogo.resumo_financeiro()` agora mostra `verba_mensal` e `saldo_mensal_previsto`.
3. **Empréstimo:** opções, simulação, contratação e quitação. Mostre a parcela e os juros totais antes de confirmar.
4. **Falência:** com 3 parcelas atrasadas sem dinheiro, a carreira termina (`Eventos.falencia`) e todas as ações passam a devolver erro. Vai precisar de uma tela de fim de carreira.

### Decisões do dono do projeto que afetam a apresentação

- **Exibição da partida (etapa 5):** o jogador **não é obrigado a assistir tudo**. Haverá velocidades **1x, 2x, 4x e 8x**, um modo **"Só os melhores momentos"** (acelera e para nas lutas, objetivos e torres) e **"Ver resultado"** (pula para o fim com as estatísticas). Não precisa implementar agora; vale considerar no planejamento da cena da partida.
- **Treino de Farm para o suporte:** quase não traz benefício. Quando a tela de treino existir, ela deve avisar isso ao jogador.

O design do MOBA (Crystal Legends) está sendo fechado com o dono do projeto (`docs/GDD.md`, seções 7 e 7.0). Campeões e itens serão definidos em seguida.
