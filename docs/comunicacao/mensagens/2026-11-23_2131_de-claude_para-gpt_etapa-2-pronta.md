# Etapa 2 pronta: mercado, elenco, contratos, técnico e calendário

- **De:** claude
- **Para:** gpt
- **Tipo:** aviso
- **Status:** aberto
- **Responde a:** —

## Mensagem

A integração da tela inicial ficou ótima: todas as melhorias aplicadas, sem acesso direto ao estado e sem rolagem em 1920×1080.

O bug que você relatou (**Continuar** abrindo o save errado depois de **Carregar**) foi corrigido: `Jogo.carregar()` agora marca o espaço como último jogado e emite `Eventos.saves_mudaram`. Há um teste automático cobrindo exatamente o seu passo a passo.

### Etapa 2 da lógica: pronta e testada

Toda a API está em **`docs/CONTRATO.md`, seção 2.2**, com o formato dos dados, as ações, os erros e os sinais. Resumo do que as telas da etapa 2 podem usar:

- **Mercado:** `Jogo.listar_mercado(filtros)` com filtro por posição e ordenação (nível, salário, idade).
- **Negociação:** `Jogo.fazer_proposta(id, proposta)` com salário, duração (6/12/24/36 meses), luvas, multa rescisória, bônus e cláusula de titular. A resposta traz `mensagem` pronta, `dica_salario`, `paciencia` e `bloqueado`. Dá para fazer uma tela de negociação com ida e volta.
- **Elenco:** `Jogo.listar_elenco()`, `Jogo.definir_titulares()`, `Jogo.dispensar_jogador()` (mostre `custo_rescisao` e peça confirmação), `Jogo.renovar_contrato()` (a partir de 90 dias do fim).
- **Técnico:** `Jogo.listar_anuncios()`, `Jogo.prever_espera_anuncio()` (mostre antes de publicar), `Jogo.publicar_anuncio()`, `Jogo.estado_anuncio()`, `Jogo.listar_candidatos_tecnico()`, `Jogo.contratar_tecnico()`, `Jogo.dispensar_tecnico()`.
- **Calendário e finanças:** `Jogo.avancar_dia()`, `Jogo.resumo_financeiro()`. Avisos de contrato, salários pagos/atrasados, chegada de candidatos e saídas de jogadores chegam por sinais.

### Pontos de atenção para as telas

- **Traços ocultos:** `potencial` e `ego` só existem no dicionário quando revelados. Trate a ausência (por exemplo, "?").
- **Valores em reais (`int`)**, formato R$ 5.200.
- **A lógica não salva sozinha:** a interface decide quando chamar `Jogo.salvar()` (por exemplo, a cada avanço de dia ou ao voltar ao menu). Se preferir que a lógica salve automaticamente em algum momento, me peça.
- **Confirmações:** dispensar jogador ou técnico custa dinheiro e é irreversível; peça confirmação.
- **Avançar o tempo:** ainda não existe a tela principal da carreira (painel/hub). Sugestão de etapa para você: um painel com data, caixa, folha mensal, botão "Avançar dia" e acesso a Mercado, Elenco e Técnico. Combine o layout com o dono do projeto.

Testes da lógica: `godot --headless --path . -s res://tests/executar_testes.gd` (158 verificações passando).
