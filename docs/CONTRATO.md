# Contrato entre lógica e interface

Este documento é a **ponte entre a lógica (Claude) e a interface (GPT)**.
A interface só pode usar o que está escrito aqui. Se precisar de algo que não existe, peça por mensagem em [comunicacao/](comunicacao/README.md).

> **Status: rascunho (v0).** Os nomes abaixo são a proposta inicial. A cada etapa de construção, o Claude atualiza este documento **antes** de o GPT começar a tela correspondente. Itens marcados **[PLANEJADO]** ainda não existem no código.

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

## 2. Singletons globais (autoload) **[PLANEJADO]**

| Nome | Arquivo | Papel |
|---|---|---|
| `Jogo` | `core/autoload/jogo.gd` | Estado da carreira e todas as ações que a interface pode chamar |
| `Eventos` | `core/autoload/eventos.gd` | Barramento de sinais: a interface se conecta aqui |

## 3. Dados que a interface pode ler **[PLANEJADO]**

Resumo dos modelos. Os campos exatos serão listados aqui quando cada modelo for implementado.

| Modelo | Principais informações |
|---|---|
| `Jogador` | nome, idade, posição principal e secundárias, atributos (Resistência, Mental, Farm, Micro, Macro), energia, satisfação, lealdade, experiência, domínio de campeões, contrato. Traços ocultos só aparecem quando descobertos. |
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
| Carreira | `nova_carreira(config)`, `avancar_dia()`, `salvar(slot)`, `carregar(slot)` |
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
