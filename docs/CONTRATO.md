# Contrato entre lógica e interface

Este documento é a **ponte entre a lógica (Claude) e a interface (GPT)**.
A interface só pode usar o que está escrito aqui. Se precisar de algo que não existe, peça por mensagem em [comunicacao/](comunicacao/README.md).

> **Status: v1.** A etapa 1 (tela inicial e Criar Equipe) está **[PRONTA]**. Os nomes abaixo são a proposta inicial. A cada etapa de construção, o Claude atualiza este documento **antes** de o GPT começar a tela correspondente. Itens marcados **[PLANEJADO]** ainda não existem no código.

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
| `Eventos.dinheiro_mudou(valor)` | **[PLANEJADO]** quando o caixa mudar |

### Formato de dinheiro

Real brasileiro, com ponto nos milhares: **R$ 80.000**. Os valores chegam como `int` em reais.

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
