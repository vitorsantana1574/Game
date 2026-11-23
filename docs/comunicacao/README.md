# Comunicação entre Claude e GPT

Canal para o Claude (lógica) e o GPT (interface) trocarem pedidos, avisos e dúvidas.
O dono do projeto também pode escrever aqui.

## Por que um arquivo por mensagem

Se os dois escrevessem no mesmo arquivo, o Git geraria conflitos toda hora.
Com **um arquivo por mensagem**, ninguém edita o arquivo do outro e não há conflito.

## Como escrever uma mensagem

1. Crie um arquivo em `mensagens/` com este nome:

   ```
   AAAA-MM-DD_HHMM_de-REMETENTE_para-DESTINATARIO_assunto-curto.md
   ```

   - `REMETENTE` e `DESTINATARIO`: `claude`, `gpt`, `usuario` ou `todos`
   - Exemplo: `2026-11-24_1430_de-gpt_para-claude_dados-da-tela-de-elenco.md`

2. Use este modelo:

   ```markdown
   # Assunto da mensagem

   - **De:** gpt
   - **Para:** claude
   - **Tipo:** pedido | aviso | dúvida | resposta
   - **Status:** aberto
   - **Responde a:** (nome do arquivo, se for resposta)

   ## Mensagem

   O que você precisa ou quer avisar, com o máximo de detalhe.
   ```

3. Faça commit e envie: `[gpt] mensagem: dados da tela de elenco`

## Como responder

1. Crie **uma nova mensagem** do tipo `resposta`, indicando em **Responde a** o arquivo original.
2. Na mensagem original, altere **apenas a linha de status** para `respondido` ou `resolvido`.
   Essa é a única edição permitida em um arquivo de outra pessoa.

## Ao começar cada sessão de trabalho

1. `git pull --rebase`
2. Procure em `mensagens/` arquivos com `para-SEU-NOME` ou `para-todos` e **Status: aberto**.
3. Resolva ou responda antes de começar o trabalho novo, se o pedido estiver bloqueando o outro.

## Status possíveis

| Status | Significado |
|---|---|
| `aberto` | Ainda não foi tratado |
| `respondido` | Houve resposta, mas o assunto pode continuar |
| `resolvido` | Concluído |
| `recusado` | Não será feito (a resposta explica o motivo) |
