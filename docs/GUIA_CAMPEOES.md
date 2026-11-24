# Guia para criar os campeões de Crystal Legends

Este documento explica **como foram feitas as simulações** de partida e de itens, e define **as regras para criar os campeões** sem quebrar o equilíbrio já testado.

- **Quem cria a proposta dos campeões:** GPT, com aprovação do dono do projeto.
- **Quem converte para os dados do jogo e testa:** Claude (`data/campeoes/`, laboratório de itens e simulação).
- **Onde entregar:** `docs/propostas/campeoes.md` (ver seção 6).

Documentos relacionados: [GDD.md](GDD.md) (seções 7, 7.0 e 7.2), `data/config/combate.json`, `data/itens/itens.json`, `tools/relatorios/`.

---

## 1. Como foram feitas as simulações

### 1.1 Ritmo da partida (`tools/prototipos/ritmo_partida.py`)

Simula milhares de partidas inteiras, em passos de 5 segundos, para calibrar duração, níveis, ouro e emoção.

- **10 jogadores** com Farm, Micro, Macro e Mental sorteados em torno da qualidade do time.
- **Ondas de minions** dão XP por presença e ouro pelo último golpe (Farm).
- **Selva** com os acampamentos reais (pássaros, sapo, rato, aranhas, polvo, golem).
- **Força de cada campeão** = habilidade do jogador × **nível** (cerca de **+7,5% por nível**) × ouro gasto em itens.
- **Fase de rotas** com trocas (Micro) e ganks (Macro decide ir, Micro decide o resultado); depois, lutas em equipe, objetivos (Cérbero, Hydra), torres, Guardião e Cristal.
- **Resultado calibrado:** partidas de ~32 min, ~33 abates, viradas em 1 de cada 3 partidas, time mais forte vencendo na medida certa.

**Importante para os campeões:** nesse modelo, todos os campeões de uma posição eram iguais. A diferença entre eles (curva de força, alcance, controle) ainda não existe. É isso que os campeões vão trazer.

### 1.2 Laboratório de itens (`tools/prototipos/laboratorio_itens.py`)

Simula duelos em passos de 0,05 s entre campeões genéricos de cada classe, com itens, para testar o equilíbrio dos itens.

O que **foi** simulado:
- Atributos base de cada classe por nível (tabela 3.1).
- Ataques básicos com crítico, velocidade de ataque, roubo de vida e efeitos ao acertar.
- Habilidades como **um único "combo"** por ciclo de recarga (tabela 3.2), reduzido pela aceleração de habilidade.
- Armadura, resistência mágica, letalidade e penetração (fixa e %), escudos, anticura, passivas dos itens.

O que **não foi** simulado (e os campeões vão precisar trazer):
- **Mana e outros recursos:** o modelo considerava que o campeão sempre podia usar o combo.
- **Habilidades separadas**, com efeitos próprios (controle, mobilidade, cura em aliados).
- **Alcance e posicionamento:** todos lutavam "encostados".
- **Curvas de força diferentes:** todos os campeões da classe cresciam igual.
- **Curas e escudos em aliados:** por isso, para o suporte, itens de defesa rendiam mais que os de poder mágico.

---

## 2. O que cada campeão precisa ter

Todo campeão tem:

1. **1 passiva.**
2. **3 habilidades:** duas básicas e uma **especial** (a terceira), mais forte e com recarga maior, liberada no **nível 6**.
3. **Uma classe:** tanque, assassino, lutador, mago, suporte ou atirador.
4. **Posições** em que joga (principal e possíveis secundárias).
5. **Um recurso** (seção 4), com peso real na partida.
6. **Uma curva de força:** forte no início, forte no fim ou constante (seção 5.1).
7. **Dificuldade** (1 a 3) e **dependência de Macro** (1 a 3) (seção 5.2).
8. **Build recomendada** (1 bota + 4 itens) e **2 a 4 itens alternativos** para situações diferentes, usando só os itens de `data/itens/itens.json` (seção 5.4).
9. **Contra quem é forte e contra quem é fraco** (classes, estilos ou campeões).
10. **Tema e texto curto** de personagem, e frases curtas que a narração possa usar para cada habilidade.

---

## 3. Faixas testadas (não sair delas)

Cada campeão deve ficar **dentro de 10 a 15% da base da sua classe**. Fora disso, os testes de itens deixam de valer. Quem tem mais em um ponto deve ter menos em outro: um assassino com mais vida tem menos dano.

### 3.1 Atributos base por classe (nível 1, depois ganho por nível; nível máximo 16)

| Classe | Vida | Armadura | Resist. mágica | Dano físico | Vel. de ataque | Alcance sugerido |
|---|---|---|---|---|---|---|
| Assassino | 600 (+100) | 30 (+4,2) | 30 (+1,3) | 62 (+3,3) | 0,65 (+2,5%/nível) | corpo a corpo (125) |
| Atirador | 560 (+95) | 26 (+4,0) | 30 (+1,3) | 60 (+4,0) | 0,70 (+3,5%/nível) | 525 a 650 |
| Mago | 560 (+95) | 26 (+4,0) | 30 (+1,3) | 52 (+3,0) | 0,63 (+2,5%/nível) | 525 a 575 |
| Lutador | 640 (+105) | 34 (+4,5) | 32 (+1,8) | 64 (+3,5) | 0,65 (+2,5%/nível) | corpo a corpo |
| Tanque | 660 (+110) | 38 (+5,0) | 32 (+2,0) | 60 (+3,5) | 0,62 (+2,5%/nível) | corpo a corpo |
| Suporte | 580 (+95) | 30 (+4,2) | 30 (+1,3) | 50 (+3,0) | 0,62 (+2,5%/nível) | 500 a 550 ou corpo a corpo |

### 3.2 Dano total das 3 habilidades (uma rotação completa)

A soma do dano das 3 habilidades (mais o dano extra da passiva, se houver) deve ficar perto do "combo" testado:

| Classe | Fórmula testada do combo | Nível 9 (2 itens) | Nível 15 (4 itens) | Recarga média |
|---|---|---|---|---|
| Assassino | 150 + 30/nível + 170% do dano físico bônus (físico) | ~560 | ~810 | 7 s |
| Mago | 150 + 28/nível + 110% do poder mágico (mágico) | ~565 | ~880 | 7 s |
| Lutador | 80 + 16/nível + 100% do dano físico bônus (físico) | ~290 | ~420 | 6 s |
| Atirador | 40 + 10/nível + 60% do dano físico bônus (o dano vem dos ataques) | ~155 | ~275 | 8 s |
| Tanque | 60 + 12/nível + 4% da vida bônus (mágico) | ~200 | ~300 | 8 s |
| Suporte | 60 + 12/nível + 40% do poder mágico (mágico) | ~175 | ~290 | 8 s |

### 3.3 "Orçamento" de poder: dano × utilidade

Controle, mobilidade, cura e escudos **custam dano**. Use como guia (valores por rotação completa):

| Efeito | Custa aproximadamente |
|---|---|
| 1 s de atordoamento em um alvo | 15% do dano da rotação |
| Atordoamento em área (vários alvos) | 25% a 35% |
| Lentidão de 30% por 2 s | 8% |
| Um avanço/salto (mobilidade) | 10% |
| Ficar invulnerável ou intocável por ~1 s | 20% |
| Escudo ou cura em si de ~10% da vida máxima | 10% |
| Escudo ou cura em aliado de ~10% da vida dele | 12% |
| Habilidade global (alcança o mapa inteiro) | 15% a 20% |

Exemplo: um mago com atordoamento em área e um salto deve causar uns 60 a 65% do dano de um mago "só dano".

### 3.4 Limites para dano por vida (evitam campeões quebrados)

| Mecânica | Limite por habilidade | Limite por rotação |
|---|---|---|
| % da **vida máxima do alvo** | até 6% | até 12% (anti-tanque); assassinos e magos de explosão: até 6% |
| % da **vida perdida do alvo** (execução) | até 15% da vida perdida | ou bônus de dano de até +30% contra alvos com pouca vida |
| % da **vida máxima própria** (tanques e lutadores) | até 5% | até 10% |
| **Dano verdadeiro** (ignora armadura e resistência) | só em 1 habilidade ou na passiva | no máximo 20% do dano da rotação |
| Acúmulos infinitos (cresce a cada abate ou ação) | sempre com **teto** | o teto precisa caber na faixa da classe no nível 16 |

---

## 4. Recursos: mana com peso real

**Nem todo campeão usa mana.** Distribuição pedida para cerca de 30 campeões: **18 a 20 com mana** e **10 a 12 com outros recursos**.

| Recurso | Como funciona | Para quem combina |
|---|---|---|
| **Mana** | Barra que gasta com habilidades e volta devagar. Acabou, só ataques básicos até recuperar. | Magos, suportes, maioria dos atiradores e tanques |
| **Energia** | Barra pequena e fixa (200, não cresce) que volta rápido (~10 por segundo). Limita a sequência, não a luta inteira. | Assassinos e lutadores ágeis |
| **Fúria** | Começa vazia, enche atacando e recebendo dano, esvazia fora de combate. Com a barra cheia, as habilidades ficam mais fortes. | Lutadores |
| **Vida** | Habilidades custam vida. Precisa de algum jeito de recuperar (roubo de vida, passiva). | Lutadores e magos de risco |
| **Sem recurso** | Só recarga, mas recargas um pouco maiores (+15%). | Alguns tanques e atiradores |

### 4.1 Faixas de mana (valores iniciais, serão testados com os campeões)

| Classe | Mana máxima (nível 1, +por nível) | Regeneração a cada 5 s (nível 1, +por nível) |
|---|---|---|
| Mago | 420 (+28) | 8 (+0,6) |
| Suporte | 400 (+25) | 9 (+0,6) |
| Atirador | 320 (+22) | 7 (+0,5) |
| Tanque | 330 (+24) | 7 (+0,5) |
| Lutador | 300 (+20) | 7 (+0,5) |
| Assassino | 280 (+20) | 7 (+0,5) |

**Regras para o custo das habilidades:**
- **Uma rotação completa** (as 3 habilidades) deve custar **25% a 35% da mana máxima** em qualquer nível. Assim, com mana cheia, o campeão faz ~3 rotações numa luta longa.
- A regeneração natural deve recuperar **uma rotação em 20 a 30 segundos**. Na fase de rotas, quem gasta mana à toa fica sem poder trocar.
- A **habilidade especial** pode custar mais (até metade do custo da rotação).
- O **buff do Polvo** (recuperação de mana) passa a valer muito para quem usa mana, e não vale nada para quem não usa. É uma decisão de Macro real para o caçador.

*Observação do Claude:* hoje nenhum item dá mana. Quando os campeões chegarem, vou acrescentar mana ou regeneração de mana a alguns itens de mago e suporte e testar no laboratório.

---

## 5. Variedade com controle

### 5.1 Curva de força (peso alto no nível)

Na simulação, **cada nível de diferença vale ~7,5% de força**. A curva do campeão muda o quanto ele aproveita isso.

| Curva | Como construir | Em relação à base da classe |
|---|---|---|
| **Forte no início** | Bases altas, crescimento por nível baixo, proporções (DF/PM) baixas. Passiva que ajuda cedo. | ~**+12%** de força no nível 1–6; ~**−10%** no nível 16 |
| **Forte no fim** | Bases baixas, crescimento alto, proporções altas, passiva que acumula (com teto). | ~**−12%** no nível 1–6; ~**+10–12%** no nível 16 |
| **Constante** | Perto da base da classe o jogo todo. | ±3% |
| **Pico no nível 6** (opcional) | Especial muito forte e recarga longa; mais fraco antes do 6. | Forte entre o nível 6 e o 11 |

Distribuição pedida: cerca de **1/3 forte no início, 1/3 forte no fim e 1/3 constante**, dentro de cada classe quando possível.

A curva vira decisão de gestão: um time de campeões fortes no fim precisa sobreviver ao começo (Farm, Mental, rodízio de energia); um time forte no início precisa fechar a partida cedo (Macro, objetivos).

### 5.2 Micro, Macro e domínio de campeão

**Dificuldade (1 a 3): quanto o Micro do jogador muda o rendimento do campeão.**

| Dificuldade | Efeito proposto do Micro (de Micro 20 a Micro 100) | Exemplos de kit |
|---|---|---|
| 1 (fácil) | −5% a +5% | habilidades com alvo garantido, área grande |
| 2 (média) | −10% a +10% | habilidades de linha, combos simples |
| 3 (difícil) | −18% a +18% | combos de várias habilidades, avanços precisos, execuções |

Campeões difíceis devem ser **um pouco mais fortes no papel** (até +5%), para que valha a pena colocar um jogador de Micro alto neles. Com Micro baixo, eles rendem menos que um campeão fácil. O **domínio do campeão** (Favorito, Conhece bem, Já jogou, Não conhece) amplia ou reduz esse efeito.

**Dependência de Macro (1 a 3): quanto o campeão vive de decisões no mapa.**
- **Alta (3):** habilidades globais, muita visão, empurrar rotas sozinho, roubar objetivos, rotações. Rende muito com Macro alto e se perde com Macro baixo.
- **Baixa (1):** campeões de luta direta, que rendem bem mesmo com decisões simples.

### 5.3 Arquétipos pedidos (variedade)

Para ~30 campeões (cerca de 5 por classe e 6 por posição), garanta pelo menos:

| Arquétipo | Mínimo | Observação |
|---|---|---|
| **Dano misto** (físico + mágico) | 3 | Obriga o rival a escolher entre armadura e resistência |
| **Dano por % da vida máxima do alvo** (anti-tanque) | 3 | Dentro dos limites da seção 3.4 |
| **Dano ou escudo pela vida máxima própria** | 2 | Tanques/lutadores que crescem comprando vida |
| **Assassinos que executam pela vida perdida do alvo** | 2 | Fortes para finalizar, fracos para começar a luta |
| **Assassinos de explosão (primeiro golpe)** | 2 | O contrário: fortes no início da luta |
| **Curandeiros e escudeiros de aliados** (suportes) | 3 | Resolve o ponto em aberto dos itens de suporte |
| **Controle em área** (engajar lutas) | 4 | Tanques, suportes e alguns magos |
| **Alcance longo / desgaste à distância** | 3 | Magos e atiradores |
| **Roubo de vida / sustentação** | 3 | Fortes contra desgaste, fracos contra anticura |
| **Habilidade global ou de mapa** | 2 | Dependência de Macro alta |
| **Acúmulo com teto** (cresce na partida) | 3 | Forte no fim |
| **Sem mana** (energia, fúria, vida ou sem recurso) | 10 | Ver seção 4 |
| **Dano verdadeiro** | 2 | Dentro do limite da seção 3.4 |

Um campeão pode ocupar mais de um arquétipo.

### 5.4 Escolha certa de itens

Os kits devem tornar a escolha de itens uma decisão real:
- Campeões de **dano misto** e de **% da vida máxima** punem quem só compra um tipo de defesa.
- Campeões com **cura** perdem muito contra a anticura (Égide de Aço, Tocha do Tormento).
- **Crítico** contra **efeitos ao acertar**: atiradores de crítico querem Lâmina Cristalina e Arco do Juízo Final; atiradores de ataques rápidos querem Cetro-Lâmina e Asas do Vento Veloz.
- **Letalidade fixa** contra **%**: assassinos que caçam frágeis preferem letalidade fixa; lutadores e atiradores que enfrentam tanques preferem %.
- Cada campeão deve listar **itens alternativos** para pelo menos uma situação diferente (ex.: "contra muito dano mágico: Escudo do Guardião no lugar de X").

---

## 6. Formato da proposta

Entregue em `docs/propostas/campeoes.md`, **um bloco por campeão**, neste formato (valores numéricos dentro das faixas da seção 3):

```json
{
  "id": "nome_sem_acento",
  "nome": "Nome",
  "titulo": "o/a ... (ex.: a Lâmina do Crepúsculo)",
  "classe": "assassino | atirador | mago | lutador | tanque | suporte",
  "posicoes": ["meio", "selva"],
  "tema": "uma ou duas frases de personagem",
  "curva_de_forca": "inicio | fim | constante | pico_nivel_6",
  "dificuldade": 1,
  "dependencia_macro": 1,
  "recurso": {
    "tipo": "mana | energia | furia | vida | nenhum",
    "maximo": [base, por_nivel],
    "regeneracao_5s": [base, por_nivel]
  },
  "atributos": {
    "vida": [base, por_nivel],
    "armadura": [base, por_nivel],
    "resistencia_magica": [base, por_nivel],
    "dano_fisico": [base, por_nivel],
    "velocidade_ataque": [base, crescimento_por_nivel_em_porcentagem],
    "alcance": 125,
    "velocidade_movimento": 340
  },
  "passiva": {
    "nome": "...",
    "descricao": "texto para o jogador",
    "efeito": "descrição mecânica com números (ex.: +2% de dano por acúmulo, até 10 acúmulos)"
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "...",
      "descricao": "texto para o jogador",
      "narracao": "frase curta para o painel (ex.: '{campeao} avança e corta {alvo}!')",
      "tipo_dano": "fisico | magico | verdadeiro | misto",
      "alvo": "unico | area | linha | cone | si_mesmo | aliado",
      "dano": {
        "base": [base, por_nivel_do_campeao],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0.0,
          "vida_perdida_alvo_pct": 0.0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 60,
      "recarga": 8,
      "efeitos": ["atordoar 1,0 s", "lentidao 30% por 2 s", "avanco 400", "escudo 120 + 40% PM"],
      "tags": ["controle", "mobilidade", "execucao"]
    },
    { "posicao": 2, "...": "..." },
    { "posicao": 3, "especial": true, "...": "liberada no nível 6" }
  ],
  "build_recomendada": ["bota", "item 1", "item 2", "item 3", "item 4"],
  "itens_alternativos": [
    { "item": "Escudo do Guardião", "quando": "contra muito dano mágico", "substitui": "item 4" }
  ],
  "forte_contra": "...",
  "fraco_contra": "..."
}
```

Use os nomes de itens exatamente como em `data/itens/itens.json`.

## 7. Depois da proposta

1. O dono do projeto aprova (ou pede mudanças).
2. O Claude converte para `data/campeoes/`, roda o laboratório com os campeões reais e devolve um relatório: quem ficou forte ou fraco demais, quais arquétipos funcionam e o que ajustar.
3. Ajustes de números são combinados entre os três; nomes, temas e textos ficam com o GPT e o dono do projeto.

**Nada de League of Legends:** nomes, habilidades marcantes e visuais precisam ser originais.
