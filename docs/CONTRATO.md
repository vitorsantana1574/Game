# Contrato entre lógica e interface

Este documento é a **ponte entre a lógica (Claude) e a interface (GPT)**.
A interface só pode usar o que está escrito aqui. Se precisar de algo que não existe, peça por mensagem em [comunicacao/](comunicacao/README.md).

> **Status: v7.** Etapas 1 (tela inicial), 2 (mercado, elenco, contratos, técnico), economia/calendário, catálogo de campeões e itens os acréscimos pedidos pela sede (seção 2.5) domínio de campeões, patch e draft (seção 2.6) e partida simulada (seção 2.7) **[PRONTOS]**. Os nomes abaixo são a proposta inicial. A cada etapa de construção, o Claude atualiza este documento **antes** de o GPT começar a tela correspondente. Itens marcados **[PLANEJADO]** ainda não existem no código.

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

## 2.4 Catálogo de campeões e itens de Crystal Legends — **[PRONTO]**

Leitura pura, com ou sem carreira ativa. Os IDs são **estáveis** (minúsculos, sem acento): use-os em arquivos de arte (`assets/sprites/campeoes/<id>.webp`, por exemplo) e para guardar escolhas.
A interface **não recebe** a força no patch (meta), a mecânica interna da simulação nem os registros de calibração.

### Leitura

| Função | Retorno |
|---|---|
| `Jogo.listar_campeoes(filtros = {})` | `Array[Dictionary]` de resumos, em ordem alfabética. Filtros opcionais: `{"classe": "mago", "posicao": "meio", "curva": "fim"}` (a posição pode ser principal ou secundária) |
| `Jogo.detalhe_campeao(id)` | Ficha completa (abaixo). `{}` se o ID não existir |
| `Jogo.atributos_campeao(id, nivel)` | Atributos num nível de 1 a 16, sem itens: `{nivel, vida, armadura, resistencia_magica, dano_fisico, velocidade_ataque, alcance, velocidade_movimento}` |
| `Jogo.listar_itens(filtros = {})` | Botas primeiro, depois os 27 itens. Filtro opcional: `{"classe": "suporte"}` |
| `Jogo.detalhe_item(id)` | Ficha do item (abaixo). `{}` se o ID não existir |

### Resumo de campeão (`listar_campeoes`)

```gdscript
{
    "id": "veluria", "nome": "Velúria", "titulo": "a arquivista dos ventos",
    "classe": "mago", "classe_nome": "Mago",
    "posicoes": ["meio"], "posicoes_nomes": ["Meio"], "posicao_principal": "meio",
    "curva": "fim", "curva_nome": "Forte no fim",      # "inicio" | "constante" | "fim"
    "dificuldade": 3,            # 1 a 3: quanto o Micro do jogador pesa
    "dependencia_macro": 2,      # 1 a 3: quanto o Macro do jogador pesa
    "recurso": "mana", "recurso_nome": "Mana",          # "mana" | "energia" | "furia" | "vida" | "nenhum"
}
```

### Ficha completa (`detalhe_campeao`)

Tudo do resumo, mais:

```gdscript
{
    "tema": "...", "forte_contra": "...", "fraco_contra": "...",
    "recurso_detalhe": {"tipo": "mana", "nome": "Mana", "maximo_nivel_1": 420, "maximo_por_nivel": 28,
                        "regeneracao_5s_nivel_1": 25, "regeneracao_5s_por_nivel": 1.7},   # só os campos do recurso
    "atributos": { ...nível 1, mesmo formato de atributos_campeao... },
    "crescimento": {"vida": 107.56, "armadura": 4.48, "resistencia_magica": 1.45, "dano_fisico": 3.37, "velocidade_ataque_pct": 2.7},
    "passiva": {"nome": "...", "descricao": "...", "efeito": "..."},
    "habilidades": [               # sempre 3; a 3ª é a especial
        {
            "posicao": 1, "nome": "...", "descricao": "...",
            "narracao": "{campeao} dispara o primeiro estalo sobre {alvo}!",   # modelo para a narração
            "tipo_dano": "magico", "alvo": "linha",      # alvo: "linha" | "cone" | "area" | "unico" | "si_mesmo" | "aliado"
            "efeitos": ["Alcance 885, largura 66", "..."], "tags": ["desgaste", "..."],
            "especial": false, "nivel_minimo": 1,         # especial: true e nivel_minimo: 6 na 3ª
            "recarga": 6.5, "custo": 36, "custo_texto": "36 de mana",
            "dano_texto": "11,21 (+22,92 por nível) + 172,46% do poder mágico, dano mágico",   # "" se não causa dano
        },
    ],
    "build": [ {resumo de item}, ... ],      # bota + 4 itens, na ordem de compra
    "itens_alternativos": [
        {"item": {resumo}, "substitui": {resumo}, "quando": "contra explosão física...", "condicao": "fisico"},
    ],
}
```

`condicao` é a leitura da lógica para a troca (`pouca_magia`, `muita_magia`, `critico`, `cura`, `armadura`, `fisico`, `misto`, `resistencia_magica`, `frageis`, `vida_alta`, `situacional`). Para o jogador, mostre o texto `quando`.

Os números de atributos e dano podem mudar a cada calibração; leia sempre da função, nunca fixe na tela.

Sobre o custo de fúria: as habilidades **não exigem** fúria. Com a barra cheia (100), a próxima habilidade sai fortalecida e gasta o custo indicado.

### Item

```gdscript
# resumo (em builds e listas):
{"id": "orbe_da_tempestade", "nome": "Orbe da Tempestade", "preco": 2600, "categoria": "magico"}   # "fisico" | "magico" | "hibrido" | "defesa" | "suporte" | "bota"
# ficha (detalhe_item e listar_itens):
{ ...resumo..., "ideia": "...", "atributos": [{"id": "poder_magico", "nome": "Poder mágico", "valor": 65}, ...],
  "classes": ["mago"], "passiva": {"nome": "...", "descricao": "..."} }   # "passiva" só se o item tiver
```

O item inicial do suporte (`medalhao_do_tributo`) também pode ser lido com `detalhe_item`.

### Ainda não existe

Draft (estado, disponibilidade de cada campeão, domínio dos jogadores, escolha e banimento) entra na etapa do draft. Este contrato será atualizado **antes** de o GPT precisar dessas funções.

## 2.5 Acréscimos pedidos pela sede — **[PRONTO]** (25/11)

Respostas ao pedido do GPT de 25/11. Tudo é acréscimo: nada do que já existia mudou de nome nem de formato.

### Bandeira dentro do save

- `Jogo.nova_carreira(escolhas)` aceita `"bandeira_png"`: PNG de **240×208** em base64, até 256 KB. É opcional: `""` ou ausente = arte padrão. Se for inválida, a carreira não é criada e volta `{"ok": false, "erros": {"bandeira": "mensagem pronta"}}`.
- `Jogo.resumo_carreira()["bandeira_png"]` e `Jogo.listar_saves()[slot]["bandeira_png"]` devolvem a imagem (`""` em saves antigos ou sem bandeira). Saves antigos continuam abrindo.
- `Jogo.definir_bandeira(png_base64)` troca a bandeira de uma carreira ativa (`""` volta à arte padrão). Retorna `{"ok": true}` ou o erro em `"bandeira"`. A troca vai para o save no próximo `Jogo.salvar()`. Emite `Eventos.bandeira_mudou(png_base64)`.
- Com isso, o arquivo auxiliar `user://bandeiras_apresentacao.cfg` pode virar só leitura de compatibilidade: na primeira vez que um save antigo abrir com bandeira no arquivo auxiliar, chame `definir_bandeira` e salve.

### Livro de lançamentos (fica no save)

`Jogo.listar_lancamentos(limite = 50)` devolve, do mais novo para o mais antigo:

```gdscript
{"dia": 31, "data_texto": "1 de fevereiro, ano 1", "descricao": "Verba da liga", "valor": 12000, "categoria": "verba"}
# valor > 0 = entrada; < 0 = saída
# categoria: "capital" | "verba" | "salarios" | "luvas" | "rescisao" | "tecnico" | "emprestimo"
```

A soma de todos os lançamentos fecha com o dinheiro atual. O histórico que hoje vive só na sessão da sede (`_historico`) pode ser trocado por esta função: ele sobrevive ao salvar e carregar.

### Totais das finanças

`Jogo.resumo_financeiro()` ganhou:
- `"gastos_previstos"`: tudo o que vence no próximo dia 1 (folha + parcela + salários atrasados + parcelas atrasadas);
- `"divida_atrasada"`: parcelas do empréstimo em atraso.

Use esses campos em vez de somar na tela.

### Regras de contrato prontas na ficha

Em `Jogo.detalhe_jogador(id)`, para jogadores do elenco:
- `contrato.pode_renovar` (bool) e `contrato.dias_para_poder_renovar` (int). Use em vez do 90 fixo na tela: o prazo está em `data/config/contratos.json` e pode mudar.
- `exige_titularidade` (bool) **só aparece quando o ego está revelado**. Use em vez de comparar o ego com `ego_exige_titular`. Sem o ego revelado, a lógica continua aplicando a exigência na negociação, e a resposta da proposta explica o motivo.

### Campeões mais jogados

Em `detalhe_jogador(id)`:

```gdscript
"historico_campeoes": {
    "disponivel": false,          # false até a simulação de partidas existir; depois, true mesmo sem partidas
    "mais_jogados": [{"id": "veluria", "partidas": 18}, ...],   # até 3, do mais jogado (empate: ordem do id)
}
```

Mostre "Histórico indisponível" com `disponivel == false`, e "Nenhuma partida" com `disponivel == true` e lista vazia.

### Avançar até algo acontecer

`Jogo.avancar_ate_evento(maximo = 30)` avança dia a dia e para no primeiro dia com algo relevante: aviso de contrato, candidatos a técnico, saída de jogador ou técnico, verba, salários (pagos ou atrasados), parcela (paga ou atrasada), quitação ou falência. Para também ao chegar a `maximo` dias. Retorno:

```gdscript
{"ok": true, "dias_avancados": 30, "eventos": ["verba_recebida", "salarios_pagos"], "resumo": {...}}
```

Os sinais de cada dia são emitidos normalmente, então os avisos da sede continuam funcionando. Sugestão: um botão sempre visível no rodapé ("Avançar dia" e "Avançar até o próximo evento"), já que é a ação mais usada do jogo.

### Aparência (para os personagens animados, se forem aprovados)

`detalhe_jogador`, `listar_elenco`, `listar_mercado` e as fichas de técnico trazem `"aparencia"`: um inteiro de 0 a 19, estável por pessoa e guardado no save. A quantidade fica em `data/config/balanceamento.json` (`"aparencias": 20`). A lógica só guarda o índice; qual arte corresponde a cada índice é decisão da apresentação. As **atividades** na sede (computadores, reunião, intervalo) dependem da agenda de treino, que entra na etapa 3. Este contrato será atualizado antes.

## 2.6 Domínio de campeões, patch e draft — **[PRONTO]** (25/11)

### Domínio de campeões (GDD 6.3)

`detalhe_jogador`, `listar_elenco` e `listar_mercado` trazem:

```gdscript
"dominio_campeoes": [   # só os que o jogador conhece (Conhecido ou mais), do mais para o menos dominado
    {"id": "veluria", "nivel": "mono", "nivel_nome": "Mono", "conhecimento": 97},
    {"id": "prismora", "nivel": "main", "nivel_nome": "Main", "conhecimento": 84},
    {"id": "cintarro", "nivel": "conhecido", "nivel_nome": "Conhecido", "conhecimento": 62},
]
# nivel: "mono" (95-100) | "main" (80-94) | "conhecido" (41-79). Fora da lista = "desconhecido" (0-40).
```

`conhecimento` é inteiro de 0 a 100 (faixas aprovadas pelo Matheus em 25/11). Especialistas têm lista curta e conhecimento alto; versáteis, lista longa sem pico. Bom lugar para mostrar: a aba **Campeões** da ficha, ao lado do histórico.

### Patch

- `Jogo.patch_atual()` devolve `{"numero": 1, "dias_ate_proximo": 180}`.
- A cada 180 dias sai um patch novo, com o sinal `Eventos.patch_novo(numero)`.
- A força dos campeões no patch **nunca** chega à interface.

### Draft (GDD seção 8)

O draft fica só na memória (não entra no save). Enquanto a liga não existe, o adversário é um **time de treino** gerado em torno do nível dos seus titulares. Quando a liga chegar, as partidas oficiais usam as mesmas funções.

| Função | O que faz |
|---|---|
| `Jogo.iniciar_draft(opcoes = {})` | Começa. `opcoes`: `"primeira_escolha"` (padrão `true`: você é o azul) e `"indisponiveis"` (`{"azul": [ids], "vermelho": [ids]}`, para o fearless de séries). Exige os 5 titulares; senão, erro em `"titulares"` |
| `Jogo.estado_draft()` | Estado completo (abaixo). `{}` sem draft |
| `Jogo.banir_no_draft(id)` / `Jogo.escolher_no_draft(id)` | Sua vez. Depois, o rival joga sozinho até a sua próxima vez |
| `Jogo.delegar_vez_ao_tecnico()` | O técnico faz a sua vez atual. Técnico melhor (Macro + Conhecimento) escolhe melhor; sem técnico, escolhe mal |
| `Jogo.escolher_automatico_no_draft(posicao = "")` | Botão **Automático**. Na escolha, com `posicao`, o titular dessa rota escolhe com o apoio do técnico (o campeão que ele melhor joga ali, pesando o meta conforme o técnico). Sem posição, ou no banimento, é igual a `delegar_vez_ao_tecnico()`. Erro `"posicao"` se a rota já tem campeão. A atribuição final das posições continua automática |
| `Jogo.definir_posicoes_draft({posicao: id})` | Depois do fim, troca quem joga com qual campeão (os 5 escolhidos, um por posição). A lógica já entrega a melhor distribuição |
| `Jogo.encerrar_draft()` | Descarta |

Todas as ações devolvem `{"ok": true, "estado": {...}}` ou `{"ok": false, "erros": {campo: mensagem}}`. Campos de erro: `"draft"` (não é sua vez, ação errada, já terminou), `"campeao"` (indisponível, desconhecido) e `"posicoes"`.

**Sinais:** `Eventos.draft_mudou(estado)` a cada mudança e `Eventos.draft_concluido(estado)` no fim.

**Estado:**

```gdscript
{
    "lado_jogador": "azul",
    "concluido": false,
    "vez": {"acao": "ban", "time": "azul", "do_jogador": true, "numero": 1, "total": 20},   # {} no fim
    "passos": [{"acao": "ban", "time": "azul", "campeao": ""}, ...],   # os 20 passos, na ordem; "" = ainda não feito
    "times": {
        "azul": {"nome": "...", "bans": [ids], "picks": [ids], "posicoes": {"topo": id, ...},   # posicoes só no fim
                 "jogadores": {"topo": {"id", "apelido"}, ...}},
        "vermelho": {...},
    },
    "campeoes": [
        {"id": "veluria", "estado": "livre", "por": "",      # estado: "livre" | "banido" | "escolhido" | "indisponivel"
         "dominio": {"meio": {"jogador_id", "apelido", "nivel", "nivel_nome", "conhecimento"}},   # os 5 titulares, sempre (conhecimento 0 a 100)
         "favorito_do_rival": ["meio"]},                     # rotas do rival em que o campeão é Main ou Mono; só com favoritos_do_rival_revelados = true
    ],
    "favoritos_do_rival_revelados": false,   # true com olheiro do técnico a partir de 60 (GDD 8.7)
}
```

Ordem (GDD 8.1): 3 bans de cada lado, alternando; picks A B B A A B; 2 bans de cada lado, com o vermelho começando; picks B A A B.

## 2.7 Partida simulada — **[PRONTO]** (25/11)

A partida é **simulada inteira de uma vez** (regras + semente, sem IA de linguagem) e devolvida como **linha do tempo**. A tela da partida (`ui/partida/`) só **reproduz** essa linha: não decide nada. O técnico não intervém durante a partida; ajustes só entre os jogos de uma série.

| Função | O que faz |
|---|---|
| `Jogo.simular_partida_do_draft(opcoes = {})` | Simula a partida do draft concluído. `opcoes`: `"semente"` (repete uma partida). Devolve `{"ok": true, "partida": {...}}` ou erro em `"draft"` (sem draft / draft em andamento) |
| `Jogo.ultima_partida` | A última partida simulada (só na memória) |
| | **Cada draft vale uma partida:** chamar de novo devolve a mesma partida, sem gastar energia outra vez. Criar ou carregar outra carreira descarta draft e partida |
| `Jogo.mapa_partida()` | Geometria do mapa (abaixo) |

**Sinal:** `Eventos.partida_simulada(partida)`.

Depois da partida, cada titular seu **gasta energia**: a de treino gasta como uma partida interna; a oficial, o dobro (GDD 6.1). Só a **oficial** conta no histórico de campeões (`campeoes_mais_jogados` na ficha). O sinal `Eventos.elenco_mudou` avisa para atualizar as fichas.

Enquanto a agenda não existe, **cada dia avançado recupera energia** de todo o elenco (o campo `energia` da ficha, de 0 a 100). Energia só pesa no jogo abaixo de 70.

### Partida

```gdscript
{
    "vencedor": 0,              # 0 = azul, 1 = vermelho (em toda a partida, time 0 é o azul)
    "lado_jogador": "azul",     # de que lado está o seu time
    "venceu": true,
    "treino": true,
    "semente": 123456,
    "duracao": 1932,            # segundos
    "times": [{"nome": "Vale Rift", "lado": "azul"}, {"nome": "Time de Treino", "lado": "vermelho"}],
    "placar": {"abates": [21, 9], "torres": [8, 2], "hydra": [2, 1], "cerbero": [3, 0], "ouro": [61200, 50400]},
    "jogadores": [   # estatística final, 10 entradas (5 de cada time, na ordem topo, selva, meio, atirador, suporte)
        {"jogador": "j000012", "apelido": "Kyxis", "time": 0, "posicao": "topo",
         "campeao": "eirafim", "campeao_nome": "Eirafim", "abates": 3, "mortes": 1, "assistencias": 6,
         "cs": 238, "ouro": 12087, "nivel": 15, "itens": [ids na ordem de compra], "dominio": "main"},
    ],
    "eventos": [ ... ],   # lances, em ordem de tempo (abaixo)
    "quadros": [ ... ],   # posição de todos, a cada 5 s (abaixo)
}
```

### Lances (`eventos`)

Campos de todo lance:

```gdscript
{
    "indice": 14,            # posição na lista (outros lances apontam para ele)
    "t": 845,                # segundos desde o início
    "minuto": "14:05",       # relógio pronto para a tela
    "tipo": "abate",
    "time": 0,               # time que fez o lance (-1 no início)
    "destaque": true,        # entra no modo "melhores momentos"
    "narracao": [            # 0, 1 ou 2 falas, na ordem: primeiro o narrador, depois o comentarista
        {"voz": "narrador", "nome": "Narrador", "texto": "Solo kill no topo! Eirafim passa por cima de Marulva."},
        {"voz": "comentarista", "nome": "Comentarista", "texto": "Duelo assim é Micro."},
    ],
    "x": 0.12, "y": 0.40,    # onde aconteceu (quando faz sentido), no mesmo sistema do mapa
}
```

| `tipo` | Campos extras |
|---|---|
| `inicio` | — |
| `abate` | `jogador`, `campeao`, `alvo`, `alvo_campeao`, `assistencias` (ids), `contexto` (`"solo"`, `"gank"`, `"dive"`, `"luta"`). Abates de luta vêm **sem narração**: quem narra é o lance `luta` |
| `gank_falhou` | `jogador` (o caçador), `alvo` |
| `luta` | `objetivo` (`""`, `"hydra"`, `"cerbero"`), `abates` ([azul, vermelho] na luta), `lances` (índices dos abates dessa luta, que vêm logo depois, no mesmo segundo) |
| `torre` | `rota` (`"topo"`, `"meio"`, `"baixo"`), `torre` (0 = externa, 1 = interna, 2 = da base), `jogador` (pode ser vazio) |
| `cerbero` / `hydra` | `roubado` (bool), `jogador` (quem roubou, quando roubado), `renasce_em` (segundo em que volta a surgir) |
| `cerbero_surge` / `hydra_surge` | O monstro passa a poder ser atacado **neste segundo** (primeira aparição e cada volta). Sempre destaque, com narração. `x`, `y` = covil. A tela começa a animação de surgimento antes (duração × velocidade da reprodução), para ela terminar exatamente aqui |
| `guardiao` | `time` = quem derrubou o Guardião do outro |
| `guardiao_renasce` | `time` = dono do Guardião |
| `item` | `jogador`, `campeao`, `item` (id). Sem narração; serve para o painel de itens |
| `analise` | `assunto` (`"ouro"` ou `"farm"`), `jogador` (no farm). Só fala do comentarista |
| `vitoria` | `x`, `y` = Cristal destruído |

**Modos de assistir** (GDD 7.4): partida inteira em 1x, 2x ou 4x; **melhores momentos** (padrão) = mostrar os lances com `destaque: true` e acelerar entre eles; **ver resultado** = pular para a estatística final.

### Quadros (`quadros`)

Um a cada 5 segundos de partida. A tela anima cada campeão entre um quadro e o próximo.

```gdscript
{
    "t": 845,
    "campeoes": [{"jogador": "j000012", "x": 0.121, "y": 0.402, "vivo": true, "nivel": 9}, ...],   # os 10
    "ouro": [24100, 22800], "abates": [6, 4], "torres": [2, 1],   # placar até ali, [azul, vermelho]
}
```

Campeão morto fica na fonte do próprio time até renascer (`vivo: false`).

### Mapa (`Jogo.mapa_partida()`)

Coordenadas normalizadas de 0 a 1 (x para a direita, y para baixo). **Azul embaixo à esquerda, vermelho em cima à direita.** A rota do meio segue a diagonal entre as bases; o rio cruza na outra diagonal, onde ficam Hydra e Cérbero.

```gdscript
{
    "bases": {"azul": {"fonte": [x, y], "cristal": [x, y], "guardiao": [x, y]}, "vermelho": {...}},
    "rotas": {"topo": [[x, y], ...], "meio": [...], "baixo": [...]},   # da base azul até a vermelha
    "torres": {"posicoes": [0.36, 0.24, 0.12]},   # posição na rota a partir da base do dono (vermelho = 1 - valor)
    "monstros_epicos": {"hydra": [x, y], "cerbero": [x, y]},
    "acampamentos": {"passaros": [x, y], ...},    # selva azul; na vermelha, (1 - x, 1 - y)
    "nomes_rotas": {"topo": {"nome", "na", "da"}, ...},
}
```

Se a arte precisar de outra geometria, peça: os pontos mudam em `data/config/mapa.json` e a simulação acompanha.

## 3. Dados que a interface pode ler **[PLANEJADO]**

Resumo dos modelos. Os campos exatos serão listados aqui quando cada modelo for implementado.

| Modelo | Principais informações |
|---|---|
| `Jogador` | **[PRONTO na lógica, ainda sem ação para a interface]** apelido, nome real, idade, posição principal e secundárias, atributos (Resistência, Mental, Farm, Micro, Macro), energia, satisfação, lealdade, experiência, domínio de campeões, contrato. Traços ocultos só aparecem quando descobertos. |
| `Tecnico` | nome, atributos (Macro, Conhecimento, Olheiro), cansaço, salário, disponibilidade (treinando, de férias) |
| `Campeao` | **[PRONTO]** ver seção 2.4 |
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
| Partida | **Pronta:** `simular_partida_do_draft()` (seção 2.7) |

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
| `partida_simulada(partida)` | **[PRONTO]** A partida está pronta para ser exibida (seção 2.7) |
| `temporada_terminou(resumo)` | Fim de temporada, acesso e rebaixamento |

## 6. Linha do tempo da partida — **[PRONTO]**

Substituída pela seção 2.7.
