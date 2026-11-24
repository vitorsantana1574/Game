# Contrato entre lógica e interface

Este documento é a **ponte entre a lógica (Claude) e a interface (GPT)**.
A interface só pode usar o que está escrito aqui. Se precisar de algo que não existe, peça por mensagem em [comunicacao/](comunicacao/README.md).

> **Status: v3.** Etapas 1 (tela inicial), 2 (mercado, elenco, contratos, técnico) e economia/calendário **[PRONTAS]**. Os nomes abaixo são a proposta inicial. A cada etapa de construção, o Claude atualiza este documento **antes** de o GPT começar a tela correspondente. Itens marcados **[PLANEJADO]** ainda não existem no código.

Regras do contrato: [ARQUITETURA.md](ARQUITETURA.md), seção 2.

---

## 1. Como a interface conversa com a lógica

Três formas, e só estas três:

| Forma | Direção | Para quê | Exemplo |
|---|---|---|---|
| **Ler o estado** | Interface ← lógica | Mostrar informações | `Jogo.time_do_jogador.elenco` |
| **Chamar ações** | Interface → lógica | O jogador fez algo | `Jogo.contratar_jogador(jogador, oferta)` |
| **Ouvir sinais** | Lógica → interface | Atualizar a tela quando algo muda | `Eventos.jogador_contratado` |

**A interface nunca altera o estado diretamente** (por exemplo, `jogador.salario = 500` é proibido). Toda mudança passa por uma ação.

## 2. Singletons globais (autoload) — **[PRONTO]**

| Nome | Arquivo | Papel |
|---|---|---|
| `Eventos` | `core/autoload/eventos.gd` | Barramento de sinais: a interface se conecta aqui |
| `Jogo` | `core/autoload/jogo.gd` | Estado da carreira e todas as ações que a interface pode chamar |

## 2.1 Tela inicial e Criar Equipe — **[PRONTO]**

### Leitura

| Função | Retorno |
|---|---|
| `Jogo.listar_dificuldades()` | `Array[Dictionary]`, na ordem de exibição (ver abaixo) |
| `Jogo.opcoes_personalizado()` | `{"capitais": [{id, nome, valor}], "rivais": [{id, nome}]}` |
| `Jogo.validar_nome_organizacao(nome)` | `""` se o nome é válido, ou a mensagem de erro pronta para exibir |
| `Jogo.listar_saves()` | `Array[Dictionary]` com **sempre 4 itens** (espaços 0 a 3). Espaço vazio = `{}` |
| `Jogo.ultimo_slot()` | Índice do último save jogado (0 a 3), ou `-1`. Use para habilitar **Continuar** |
| `Jogo.pesadelo_desbloqueado()` | `bool` |
| `Jogo.tem_carreira()` | `bool` |
| `Jogo.resumo_carreira()` | Resumo da carreira ativa (ver abaixo), ou `{}` |

**Item de `listar_dificuldades()`** (ordem: Fácil, Normal, Difícil, Pesadelo, Personalizado):

```gdscript
{
    "id": "normal",                     # "facil" | "normal" | "dificil" | "pesadelo" | "personalizado"
    "nome": "Normal",                   # texto para o botão
    "bloqueada": false,                 # Pesadelo começa true
    "condicao_desbloqueio": "",         # Pesadelo: "Vencer o mundial jogando no Difícil."
    # Os campos abaixo não existem no item "personalizado":
    "capital": "medio",
    "capital_valor": 80000,             # em reais
    "capital_nome": "Caixa equilibrado",
    "rivais": "equilibrados",
    "rivais_nome": "Adversários equilibrados",
}
```

**Item de `listar_saves()`** (quando o espaço está ocupado):

```gdscript
{
    "nome": "Aurora Esports",           # nome da organização
    "fase": "Regional · Dia 12",        # texto pronto para exibir
    "dificuldade": "normal",
    "salvo_em": "2026-11-23 14:05:00",
}
```

**`resumo_carreira()`**:

```gdscript
{
    "nome": "Aurora Esports",
    "dinheiro": 80000,                  # em reais
    "reputacao": 10,                    # 0 a 100
    "dificuldade": "normal",
    "nivel_liga": "regional",           # "regional" | "nacional" | "mundial"
    "dia": 1,
    "fase": "Regional · Dia 1",
    "slot": 0,
}
```

### Ações

Todas devolvem um dicionário com `"ok"`. Em caso de erro, `"erros"` traz **mensagens prontas para exibir**, por campo.

| Ação | Parâmetros | Sucesso |
|---|---|---|
| `Jogo.nova_carreira(escolhas)` | ver abaixo | `{"ok": true, "slot": int, "resumo": {...}}` |
| `Jogo.carregar(slot)` | `slot`: 0 a 3 | `{"ok": true, "resumo": {...}}` |
| `Jogo.continuar()` | — | igual a `carregar(ultimo_slot())` |
| `Jogo.salvar()` | — | `{"ok": true}` |
| `Jogo.excluir_save(slot)` | `slot`: 0 a 3 | `{"ok": true}` |

**Parâmetro `escolhas` de `nova_carreira`:**

```gdscript
{
    "nome": "Aurora Esports",           # obrigatório; a lógica tira espaços extras
    "dificuldade": "normal",            # id vindo de listar_dificuldades()
    "capital": "alto",                  # só no "personalizado": id vindo de opcoes_personalizado()
    "rivais": "experientes",            # só no "personalizado"
    "slot": -1,                         # opcional: -1 (ou ausente) = primeiro espaço vazio;
                                        # 0 a 3 = grava nesse espaço, SUBSTITUINDO o save que estiver lá
}
```

**Erro:** `{"ok": false, "erros": {"nome": "O nome precisa ter pelo menos 3 caracteres."}}`
Campos possíveis em `erros`: `nome`, `dificuldade`, `capital`, `rivais`, `slot`.

- Se os 4 espaços estiverem ocupados e `slot` for -1, vem `erros["slot"]`. A tela deve perguntar ao jogador qual save substituir e chamar de novo com o `slot` escolhido.
- **Peça confirmação ao jogador antes de substituir um save.** A lógica substitui sem perguntar.

**Regras do nome da organização:** de 3 a 24 caracteres (após tirar espaços extras), com letras (acentos aceitos), números, espaço e `. - & '`.

### Sinais desta etapa

| Sinal | Quando |
|---|---|
| `Eventos.carreira_iniciada(resumo)` | Depois de `nova_carreira` com sucesso |
| `Eventos.carreira_carregada(resumo)` | Depois de `carregar`/`continuar` com sucesso |
| `Eventos.carreira_salva(slot)` | Depois de `salvar` |
| `Eventos.saves_mudaram(resumos, ultimo_slot)` | Sempre que a lista de saves muda. Os parâmetros têm o mesmo formato de `listar_saves()` e `ultimo_slot()` |
| `Eventos.dificuldade_desbloqueada(id)` | Quando o Pesadelo é desbloqueado |
| `Eventos.dinheiro_mudou(valor)` | Quando o caixa mudar (ver 2.2) |

### Formato de dinheiro

Real brasileiro, com ponto nos milhares: **R$ 80.000**. Os valores chegam como `int` em reais.

## 2.2 Mercado, elenco, contratos, técnico e calendário — **[PRONTO]**

Todas as funções abaixo exigem uma carreira ativa (depois de `nova_carreira`, `carregar` ou `continuar`).

### Formato de um jogador (resumo)

Usado por `listar_mercado()`, `listar_elenco()`, `detalhe_jogador()` e pelos sinais.

```gdscript
{
    "id": "j000123",
    "apelido": "Kazen",
    "nome_real": "Lucas Almeida",
    "idade": 19,
    "posicao_principal": "meio",            # "topo" | "selva" | "meio" | "atirador" | "suporte"
    "afinidade_posicao": {"topo": 0.4, "meio": 0.97, ...},   # 0 a 1: rendimento em cada posição
    "atributos": {"resistencia": 55, "mental": 61, "farm": 70, "micro": 66, "macro": 52},  # 1 a 100
    "nivel_geral": 63,                       # 1 a 100, na posição principal
    "energia": 100, "satisfacao": 70, "lealdade": 20,       # 0 a 100
    "experiencia": 40,
    "salario_pedido": 5200,                  # reais por mês
    "fama": 0.42,                            # 0 a 1: quanto maior, mais difícil negociar
    "contrato": {},                          # {} para agente livre; ver formato abaixo
    # Só aparecem quando revelados (traços ocultos):
    "potencial": 78, "ego": 55,

    # Só em jogadores do MERCADO:
    "negociacao": {"paciencia": 3, "bloqueado": false, "bloqueado_ate": 0},
    # Só em jogadores do ELENCO:
    "no_elenco": true, "titular": true, "posicao_titular": "meio", "custo_rescisao": 31200,
}
```

**Contrato:**

```gdscript
{
    "salario": 5200, "luvas": 0, "multa_rescisoria": 62400,
    "bonus_titulo": 0, "bonus_mundial": 0, "clausula_titular": false,
    "duracao_meses": 12, "dia_inicio": 1, "dia_fim": 360, "dias_restantes": 359,
}
```

**Técnico (resumo):**

```gdscript
{
    "id": "t00004", "nome": "Paula Rocha", "idade": 41,
    "atributos": {"macro": 55, "conhecimento": 48, "olheiro": 60},
    "nivel_geral": 54, "cansaco": 0, "salario_pedido": 4300,
    "contrato": {...},                       # {} para candidatos
    # Só em candidatos:
    "expira_em": 26, "dias_para_expirar": 12,
}
```

### Leitura

| Função | Retorno |
|---|---|
| `Jogo.listar_mercado(filtros)` | Agentes livres. `filtros` opcional: `{"posicao": "meio", "ordenar": "nivel" \| "salario" \| "idade"}` (padrão: nível, do melhor para o pior) |
| `Jogo.listar_elenco()` | Jogadores do elenco (até 10) |
| `Jogo.detalhe_jogador(id)` | Resumo de um jogador do elenco ou do mercado, ou `{}` |
| `Jogo.titulares()` | `{"topo": id, "meio": id, ...}` (posições sem titular ficam de fora) |
| `Jogo.opcoes_contrato()` | `{"duracoes_meses": [6, 12, 24, 36], "multa_padrao_meses": 12, "ego_exige_titular": 75}` |
| `Jogo.custo_rescisao(id)` | Custo para dispensar o jogador agora, ou `-1` |
| `Jogo.resumo_financeiro()` | `{dinheiro, folha_mensal, salarios_atrasados, meses_em_atraso, proximo_pagamento_dia, dias_ate_pagamento}` |
| `Jogo.listar_anuncios()` | `[{id: "pequeno" \| "medio" \| "grande", nome, candidatos, custo, dias_espera}]` |
| `Jogo.prever_espera_anuncio(tamanho, oferta_minima)` | Dias até os candidatos chegarem, para mostrar antes de publicar |
| `Jogo.estado_anuncio()` | `{}` ou `{tamanho, oferta_minima, dia_chegada, dias_restantes}` |
| `Jogo.listar_candidatos_tecnico()` | Candidatos que já responderam |
| `Jogo.tecnico_atual()` | Técnico contratado, ou `{}` |

`Jogo.resumo_carreira()` agora também traz: `mes`, `folha_mensal`, `salarios_atrasados`, `meses_em_atraso`, `tamanho_elenco`, `tem_tecnico`.

### Ações

| Ação | Sucesso |
|---|---|
| `Jogo.fazer_proposta(jogador_id, proposta)` | `{"ok": true, "aceita": bool, "mensagem", "dica_salario", "paciencia", "bloqueado", "jogador"?}` |
| `Jogo.renovar_contrato(jogador_id, proposta)` | Igual a `fazer_proposta`. Só a partir de **90 dias** do fim do contrato; jogador insatisfeito recusa |
| `Jogo.dispensar_jogador(jogador_id)` | `{"ok": true, "custo": int}`. Paga a rescisão; o jogador volta ao mercado |
| `Jogo.definir_titulares({"topo": id, ...})` | `{"ok": true}`. Substitui todos os titulares |
| `Jogo.publicar_anuncio(tamanho, oferta_minima)` | `{"ok": true, "dias_espera": int}`. Cobra o custo na hora; um anúncio por vez |
| `Jogo.contratar_tecnico(candidato_id, duracao_meses)` | `{"ok": true}`. Pelo salário pedido; exige não ter técnico |
| `Jogo.dispensar_tecnico()` | `{"ok": true, "custo": int}` |
| `Jogo.avancar_dia(dias = 1)` | `{"ok": true, "resumo": {...}}` |

Erros seguem o padrão: `{"ok": false, "erros": {"campo": "mensagem pronta"}}`.

**Proposta** (campos ausentes usam o padrão):

```gdscript
{
    "salario": 5200,            # padrão: salário pedido
    "duracao_meses": 12,        # 6, 12, 24 ou 36 (opcoes_contrato())
    "luvas": 0,                 # pago na hora; precisa haver dinheiro em caixa
    "multa_rescisoria": 62400,  # padrão: 12 salários. Multa acima de 1 ano de salário encarece a exigência
    "bonus_titulo": 0,
    "bonus_mundial": 0,
    "clausula_titular": false,  # jogadores com ego alto só assinam com ela
}
```

**Como a negociação funciona (para a tela explicar ao jogador):**
- Recusa normal: o jogador perde **1** de paciência e a resposta traz `dica_salario` (o salário mensal que ele espera, arredondado).
- Proposta muito baixa (abaixo de 60% do esperado): perde **2** de paciência.
- Paciência zerada: ele **encerra a negociação por 15 dias** (`bloqueado: true`).
- Iniciantes têm mais paciência e aceitam um pouco abaixo do pedido; estrelas, quase nada.
- Luvas e bônus aumentam o valor da proposta. Reputação baixa da organização encarece jogadores famosos.
- `mensagem` vem pronta para exibir.

### Calendário

- **1 mês = 30 dias.** O dia 1 é o início da carreira; dia 31 começa o mês 2, e assim por diante.
- **Salários** são cobrados no primeiro dia de cada mês (dias 31, 61, 91...). Sem dinheiro, nada é pago, o valor acumula e a satisfação e a reputação caem.
- **Avisos de contrato:** 90 e 7 dias antes do fim.
- **Fim de contrato:** o jogador sai no dia seguinte ao `dia_fim`.
- **Mercado:** cerca de 25% dos agentes livres são trocados todo início de mês.
- **Candidatos a técnico** desistem 14 dias depois de chegar.
- A lógica **não salva sozinha**: a interface decide quando chamar `Jogo.salvar()`.

### Sinais desta etapa

| Sinal | Quando |
|---|---|
| `Eventos.dia_avancou(resumo)` | A cada dia que passa |
| `Eventos.elenco_mudou()` | Contratação, saída, renovação ou mudança de titulares |
| `Eventos.jogador_contratado(jogador)` | Jogador entrou no elenco |
| `Eventos.jogador_saiu(jogador, motivo)` | `motivo`: `"dispensado"` \| `"contrato_encerrado"` |
| `Eventos.contrato_vencendo(pessoa, tipo, dias_restantes)` | `tipo`: `"jogador"` \| `"tecnico"` |
| `Eventos.mercado_atualizado()` | Mercado renovado (início do mês) |
| `Eventos.candidatos_chegaram(candidatos)` | Candidatos do anúncio chegaram |
| `Eventos.tecnico_contratado(tecnico)` / `Eventos.tecnico_saiu(tecnico, motivo)` | Mudança de técnico |
| `Eventos.salarios_pagos(total)` / `Eventos.salarios_atrasados(devido, meses)` | Folha do mês |
| `Eventos.dinheiro_mudou(valor)` | Qualquer mudança no caixa (agora **[PRONTO]**) |

## 2.3 Economia e calendário — **[PRONTO]**

### Calendário

`Jogo.resumo_carreira()["data"]`:

```gdscript
{
    "ano": 1, "mes": 2, "dia_do_mes": 12, "nome_mes": "fevereiro",
    "texto": "12 de fevereiro, ano 1",
    "fase": "etapa_1",          # "pre_temporada" | "etapa_1" | "pausa_meio_ano" | "etapa_2" | "mundial" | "fim_de_temporada"
    "fase_nome": "Etapa 1",
    "janela_transferencias": false,
}
```

O campo `fase` do resumo e dos saves agora é, por exemplo: `"Regional · Etapa 1 · 12/fev, ano 1"`.
Calendário completo do ano: `docs/GDD.md`, seção 8.10. Os jogos da liga ainda não são disputados (etapa 6).

### Verba da liga e finanças

`Jogo.resumo_financeiro()` agora também traz: `verba_mensal`, `parcela_emprestimo`, `saldo_mensal_previsto` (verba − folha − parcela).
`Jogo.resumo_carreira()` traz: `verba_mensal`, `tem_emprestimo`, `encerrada`, `motivo_encerramento` (`"falencia"`).

**Ordem do dia de pagamento** (1º dia de cada mês): verba entra → parcela do empréstimo → salários.

### Empréstimo

| Função | Retorno |
|---|---|
| `Jogo.opcoes_emprestimo()` | `{juros_mensais: 0.05, prazos_meses: [3, 6, 12], valor_minimo, limite, pode_contratar, motivo}` |
| `Jogo.simular_emprestimo(valor, meses)` | `{valor, meses, parcela, total, juros_total}`. Mostre antes de contratar |
| `Jogo.estado_emprestimo()` | `{}` ou `{valor, meses, parcela, parcelas_restantes, parcelas_atrasadas, divida_atrasada, saldo_para_quitar}` |
| `Jogo.contratar_emprestimo(valor, meses)` | `{"ok": true, "emprestimo": {...}}`. Peça confirmação mostrando parcela e juros totais |
| `Jogo.quitar_emprestimo()` | `{"ok": true, "pago": int}` |

### Carreira encerrada (falência)

Com 3 parcelas atrasadas e sem dinheiro para a dívida atrasada, a carreira termina: `Eventos.falencia(resumo)` é emitido, `resumo_carreira()["encerrada"]` fica `true` e **todas as ações passam a devolver erro** (`erros["carreira"]`). A interface deve mostrar uma tela de fim de carreira.

### Sinais

| Sinal | Quando |
|---|---|
| `Eventos.verba_recebida(valor)` | Verba mensal recebida |
| `Eventos.emprestimo_contratado(emprestimo)` | Empréstimo contratado |
| `Eventos.parcela_paga(valor, restantes)` | Parcela paga |
| `Eventos.parcela_atrasada(divida_atrasada, parcelas_atrasadas)` | Sem dinheiro para a parcela (avise o jogador com destaque) |
| `Eventos.emprestimo_quitado()` | Última parcela paga ou quitação antecipada |
| `Eventos.falencia(resumo)` | Fim da carreira |

## 3. Dados que a interface pode ler **[PLANEJADO]**

Resumo dos modelos. Os campos exatos serão listados aqui quando cada modelo for implementado.

| Modelo | Principais informações |
|---|---|
| `Jogador` | **[PRONTO na lógica, ainda sem ação para a interface]** apelido, nome real, idade, posição principal e secundárias, atributos (Resistência, Mental, Farm, Micro, Macro), energia, satisfação, lealdade, experiência, domínio de campeões, contrato. Traços ocultos só aparecem quando descobertos. |
| `Tecnico` | nome, atributos (Macro, Conhecimento, Olheiro), cansaço, salário, disponibilidade (treinando, de férias) |
| `Campeao` | nome, posições, características |
| `Time` | nome, elenco (5 titulares + 5 reservas), técnico, dinheiro, reputação |
| `Contrato` | duração, salário, luvas, multa rescisória, bônus, cláusula de titular |
| `Liga` | nível (regional/nacional), times, tabela, rodada atual, playoffs |
| `Agenda` | atividades de cada jogador em cada dia da semana |

## 4. Ações que a interface pode chamar **[PLANEJADO]**

Lista inicial; será detalhada com parâmetros e retornos em cada etapa.

| Área | Ações previstas |
|---|---|
| Carreira | **Prontas:** ver 2.1. **Planejada:** `avancar_dia()` |
| Mercado | `buscar_jogadores(filtros)`, `fazer_proposta(...)`, `negociar(...)`, `propor_troca(...)` |
| Técnico | `publicar_anuncio(tamanho, oferta_minima)`, `contratar_tecnico(...)`, `dar_ferias()`, `treinar_tecnico(atributo)` |
| Elenco | `definir_titulares(...)`, `conversar(jogador, tipo)`, `definir_capitao(jogador)` |
| Agenda e treino | `definir_atividade(jogador, dia, atividade)` |
| Draft | `banir(campeao)`, `escolher(campeao, jogador)` |
| Partida | `simular_partida(...)` → devolve a **linha do tempo** (seção 6) |

## 5. Sinais **[PLANEJADO]**

| Sinal | Quando |
|---|---|
| `dia_avancou(data)` | Um dia passou |
| `dinheiro_mudou(valor)` | O caixa mudou |
| `jogador_contratado(jogador)` / `jogador_saiu(jogador, motivo)` | Mudança no elenco |
| `proposta_recebida(proposta)` | Outro time quer um jogador seu |
| `contrato_vencendo(jogador, dias)` | Avisos de 3 meses e 1 semana |
| `satisfacao_mudou(jogador)` | Ego, banco, salário, promessas |
| `candidatos_chegaram(anuncio)` | Técnicos responderam ao anúncio |
| `partida_simulada(linha_do_tempo)` | A partida está pronta para ser exibida |
| `temporada_terminou(resumo)` | Fim de temporada, acesso e rebaixamento |

## 6. Linha do tempo da partida **[PLANEJADO]**

A simulação devolve a partida inteira de uma vez, como uma lista de eventos em ordem de tempo. A cena visual (`ui/partida/`) **reproduz** essa lista; ela não decide nada.

Formato proposto de cada evento:

```gdscript
{
    "tempo": 312.5,                 # segundos desde o início da partida
    "tipo": "abate",                # tipo do evento (lista abaixo)
    "dados": { ... },               # informações do evento, conforme o tipo
    "narracao": "Fulano abate Sicrano na rota do meio!"   # texto para o painel (pode ser vazio)
}
```

Tipos previstos: `posicao` (posições lógicas dos 10 campeões), `ataque`, `habilidade`, `abate`, `minion_abatido`, `torre_destruida`, `monstro_abatido`, `bonus_ganho`, `bonus_perdido`, `roubo`, `torre_visao_colocada`, `guardiao_derrotado`, `guardiao_renasceu`, `cristal_destruido`, `fim_de_partida`.

- **Posições** são coordenadas lógicas do mapa (em unidades do mapa, não em pixels). A interface converte para a tela e anima o deslocamento entre um ponto e outro.
- Detalhes do mapa lógico (tamanho, rotas, posição das torres e acampamentos) serão publicados aqui na etapa 5.
