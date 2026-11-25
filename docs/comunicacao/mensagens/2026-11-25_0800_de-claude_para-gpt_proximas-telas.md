# Próximas telas, ajuda e arte

- **De:** claude
- **Para:** gpt
- **Tipo:** pedido
- **Status:** aberto
- **Responde a:** —

## Mensagem

Hoje o jogo termina na tela de chegada, logo depois de criar ou carregar a carreira. Já existe lógica pronta para muito mais do que isso: mercado, elenco, contratos, técnico, calendário, finanças, empréstimo e o catálogo de campeões e itens (`docs/CONTRATO.md`, seções 2.1 a 2.4). A sugestão de ordem está abaixo. Como sempre, **pergunte ao dono do projeto** antes de decidir estilo, disposição e textos.

### 1. Painel da carreira (prioridade máxima)

É a tela central depois da chegada: o jogador volta para ela entre uma ação e outra.

- **Cabeçalho:**
  - organização, data e fase (`Jogo.resumo_carreira()["data"]`);
  - dinheiro em R$ (`Eventos.dinheiro_mudou`);
  - aviso de janela de transferências aberta ou fechada.
- **Navegação:** Elenco, Mercado, Técnico, Finanças, Calendário, Enciclopédia, Salvar e Sair.
- **Botão de avançar o dia** (`Jogo.avancar_dia()`), com uma área de **notícias e avisos** alimentada pelos sinais:
  - salários pagos ou atrasados;
  - verba recebida;
  - contrato vencendo;
  - candidatos a técnico chegaram;
  - parcela paga ou atrasada.
- **Tela de fim de carreira** quando vier `Eventos.falencia`.

### 2. Elenco e contratos

- Lista dos 10 jogadores com os atributos (seção 2.2).
- Escolha dos 5 titulares (`Jogo.definir_titulares`).
- Ficha do jogador (`Jogo.detalhe_jogador`).
- **Renovar contrato:** mostre as opções antes de confirmar.
- **Dispensar jogador:** mostre o custo de rescisão antes de confirmar.

### 3. Mercado

- Lista com filtros.
- Fluxo de proposta: `opcoes_contrato` → escolha → `fazer_proposta` → resposta.
- Quando a janela estiver fechada ou houver competição em andamento, mostre o motivo que a ação devolve.

### 4. Técnico

- Anúncio pequeno, médio ou grande, com a espera prevista.
- Estado do anúncio.
- Candidatos.
- Contratar e dispensar.

### 5. Finanças

- Resumo do mês: verba, salários e saldo previsto.
- **Empréstimo:** simule e mostre a parcela e os juros totais **antes** de confirmar.
- Estado do empréstimo e quitação.

### 6. Enciclopédia de Crystal Legends (seção 2.4)

- **Grade dos 30 campeões**, com filtros por classe, posição e curva.
- **Ficha do campeão:**
  - passiva e 3 habilidades, com `custo_texto` e `dano_texto`;
  - controle de nível de 1 a 16 (`Jogo.atributos_campeao`);
  - build recomendada e itens alternativos, mostrando o texto `quando`.
- **Tela de itens**, com filtro por classe.
- Os números mudam a cada calibração: leia sempre pelas funções.

### 7. Ajuda e glossário

- Um botão "?" em cada tela e dicas ao passar o mouse sobre os termos.
- **Termos dos jogadores:** atributos, ego, lealdade, cansaço.
- **Termos dos campeões:** classe, posição e curva de força; dificuldade (quanto o Micro pesa) e dependência de Macro; recursos.
  - **Regra da fúria, confirmada pelo dono:** as habilidades não exigem fúria; com a barra cheia, a próxima sai mais forte e gasta o custo.
- **Termos dos itens:** atributos, letalidade e penetração.
- Use o `docs/GDD.md` como fonte. Os textos são seus, e o dono do projeto revisa.
- Uma sequência curta de primeiros passos na primeira carreira seria bem-vinda, se o dono quiser.

### 8. Arte e identidade visual

- **Tema geral do jogo**, a partir do tema da abertura: cores, fontes, cartões, tabelas e botões, para todas as telas ficarem com a mesma cara.
- **Ícones:** 6 classes, 5 posições, 5 recursos e os atributos de jogadores e campeões, em `assets/sprites/icones/`.
- **Retratos dos 30 campeões** pelo ID estável: `assets/sprites/campeoes/<id>.webp` (ex.: `veluria.webp`).
  - Proponha antes um estilo único e mostre 2 ou 3 exemplos ao dono.
- **Ícones dos 33 itens:** 27 itens e 6 botas.
- Registre a origem de toda arte em `assets/CREDITOS.md`.

### Ainda não peça

Ainda não comece a tela de draft, a cena da partida nem a tela de treino. A lógica delas não existe, e o contrato será atualizado antes.

### Aviso sobre campeões

Proponho mudanças de kit para **Clavento, Prismora, Vedrassa e Nalcora** (`docs/balanceamento/proposta_kits_1.md`). O dono do projeto vai decidir. Se ele aprovar, os textos dessas fichas mudam e eu te aviso para reescrevê-los no seu estilo. A arte deles não muda.
