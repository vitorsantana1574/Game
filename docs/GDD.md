# MOBA Manager — Documento de Design do Jogo (GDD)

> Documento vivo: registra tudo o que já foi decidido sobre o jogo e o que ainda está em aberto.
> Itens marcados com **[A DEFINIR]** ainda não foram decididos.

Última atualização: 22/11/2026

---

## 1. Visão geral

- **Gênero:** gerenciamento de equipe de e-sports (manager), com foco em administração e estratégia.
- **Referências:** CS Manager, Teamfight Manager, Football Manager (gestão de time); Big Ambitions e Supermarket Simulator (gestão de negócio, como inspiração temática — não em 3D).
- **Premissa:** o jogador é dono e gestor de uma organização de e-sports que disputa ligas de um **MOBA fictício**, inspirado em League of Legends.
- **Estrutura em duas camadas:**
  1. **Núcleo (Fase 1):** gerenciar o time — elenco, treinos, draft, partidas simuladas, liga, transferências.
  2. **Negócio (Fase 2):** gerenciar a organização como empresa — gaming house, patrocinadores, loja, staff, finanças.

## 2. Plataforma e tecnologia

- **Motor:** Godot 4.7.2 (versão padrão, GDScript), 2D.
- **Publicação:** itch.io (gratuito), com versão jogável no navegador. Game Jolt como opção secundária. Steam e Epic descartadas por enquanto (taxa de US$ 100).
- **Repositório:** `vitorsantana1574/Game`.

## 3. Restrições importantes

- **Nada de propriedade intelectual real:** não usar League of Legends, campeões, times, jogadores ou ligas reais. O jogo fictício, os campeões e os times são todos inventados.
- **IA:** código feito com IA não precisa ser declarado nas plataformas. Arte, textos, música ou vozes gerados por IA precisam ser declarados (Steam) e podem ser filtrados por quem usa o filtro "No AI" do itch.io. Preferência: arte de pacotes gratuitos/comprados ou feita à mão.

## 4. Início de jogo (configuração)

Ao começar uma carreira, o jogador escolhe:

- **Dinheiro inicial:** várias opções de valor.
- **Dificuldade dos times rivais:** várias opções.
- **Predefinições prontas:** Fácil, Normal, Difícil — que ajustam dinheiro e dificuldade de uma vez.
- **Personalizado:** o jogador ajusta cada opção manualmente.

Valores exatos de cada nível: **[A DEFINIR]**

## 5. Elenco

- O jogador deve contratar **10 jogadores**: **5 titulares** e **5 reservas**.
- Os reservas existem para rodízio: cobrir cansaço (ver Resistência), lesões de desempenho, estratégia contra adversários específicos e flexibilidade de posição.

### 5.1 Posições

Cinco posições: **Topo, Selva, Meio, Atirador, Suporte**.

- Cada jogador tem uma **posição principal** e pode jogar em **outras posições com desempenho reduzido**.
- Tamanho da penalidade fora da posição principal (e se existem posições secundárias com penalidade menor): **[A DEFINIR]**
- Cada posição dá **peso diferente aos atributos**. Exemplos:
  - Suporte quase não farma → Farm pesa pouco.
  - Selva → "farm" significa limpar os monstros da selva, não minions de rota.

## 6. Atributos dos jogadores

| Atributo | O que representa |
|---|---|
| **Resistência** | Quantas partidas o jogador aguenta antes de perder eficiência e a velocidade com que recupera energia. |
| **Mental** | Capacidade de manter o nível e seguir o plano do time quando a partida está ruim — não "tiltar", manter o jogo sob controle mesmo perdendo. |
| **Farm** | Quantos minions (ou monstros, no caso da Selva) o jogador consegue abater **sem pressão** — técnica de último golpe. |
| **Micro** | Desempenho nas **disputas diretas** na rota: trocas de dano, duelos, sobreviver, não morrer à toa, não perder farm para o oponente. |
| **Macro** | **Decisões no mapa:** hora certa de sair da rota, de ajudar o time, de abandonar um objetivo que não vale a pena. |

### 6.1 Resistência e energia

A Resistência funciona em duas partes:

- **Atributo Resistência:** capacidade máxima (quantas partidas aguenta) e velocidade de recuperação. Ex.: alguém com Resistência alta joga 10 partidas ou mais tranquilamente.
- **Barra de energia atual:** cai a cada partida jogada e sobe com descanso.
- **Energia baixa reduz a eficiência de todos os outros atributos.**
- A Resistência pode ser **treinada**; a energia é **recuperada com descanso**.

### 6.2 Como os atributos interagem na partida

- **Farm vs. Micro:** o farm de cada jogador na fase de rotas = seu atributo Farm, **ajustado pela diferença de Micro** contra o oponente direto. Um jogador com Farm ótimo e Micro fraco perde farm para um rival agressivo.
- **Lutas em equipe:** não há atributo próprio de Teamfight. O desempenho nas lutas é calculado a partir de **Micro + Macro** (e do nível e itens de cada personagem). Fórmula exata: **[A DEFINIR]**
- **Mental:** quando o time está atrás no placar/ouro, o desempenho de cada jogador cai — e quanto maior o Mental, menor essa queda.

### 6.3 Lista de campeões

- Cada jogador tem uma **lista de campeões que domina**.
- Jogar com um campeão fora da lista gera **penalidade** de desempenho.
- Isso dá peso ao **pick & ban** e ao **meta** de cada patch.

### 6.4 Traços ocultos

Descobertos aos poucos pelo jogador (por exemplo, com o tempo de convivência ou com um olheiro):

- **Idade e potencial:** quanto o jogador ainda pode evoluir.
- **Ego:** aceita ou não ficar no banco de reservas; jogadores com ego alto podem ficar insatisfeitos.
- **Salário pedido:** quanto o jogador exige para assinar ou renovar contrato.

## 7. O MOBA fictício

Baseado em League of Legends, mas não idêntico:

- Duas equipes de 5, cada uma com uma posição por jogador.
- **Minions** nas rotas: abatê-los dá **experiência** (nível do personagem) e **ouro** (para comprar **itens**).
- Quem farma pouco chega às lutas e aos duelos de rota com **nível mais baixo e menos itens**.
- **Objetivos de mapa** que podem ser disputados ou abandonados (decisão de Macro) — ver 7.1.
- **Campeões** fictícios, com características próprias.
- **Patches:** mudam a força dos campeões e o meta ao longo da temporada.

Como a partida é exibida (visão 2D de cima com bonecos lutando sozinhos, ou narração com estatísticas): **[A DEFINIR]**. Observação: as regras de prioridade das torres e as mecânicas de área dos monstros e do Guardião aparecem muito melhor numa visão 2D de cima.

## 7.1 Mapa

### Rotas e torres

- **3 rotas, com 3 torres cada: 9 torres por time.**
- As torres atacam tudo o que entra no seu alcance, com esta prioridade (como no LoL):
  1. Se um campeão inimigo atacar um campeão aliado dentro do alcance da torre, ela foca nesse inimigo.
  2. Caso contrário, se minions entraram primeiro no alcance, ela foca neles e depois nos campeões.
- **Cada torre destruída dá uma quantidade considerável de ouro** ao time que a destruiu.
- **Minions fortalecidos:** quando a terceira torre de uma rota cai, os minions do time atacante naquela rota ficam mais fortes. Esses minions **dão mais ouro ao serem abatidos**, o que dá ao time que perdeu mais torres uma chance de se recuperar.
- Vida, dano e alcance das torres: **[A DEFINIR — balanceamento]**

### Cristal e Guardião

- Depois das 9 torres, cada time tem um **Cristal** para proteger. **Destruir o Cristal inimigo vence a partida.**
- Na frente de cada Cristal fica o **Guardião** do time: uma estátua enorme com uma lança numa mão e um escudo na outra.
  - Ataca os inimigos e aguenta muito dano. **É o ser com mais vida no jogo.**
  - **A cada 5 ataques, bate o escudo no chão**, causando dano em área nos inimigos próximos. Quem se posiciona bem (Macro) recua a tempo.
  - **Renasce 5 minutos depois de ser derrotado**, se o Cristal ainda não tiver sido destruído. Isso cria chances de virada no fim de jogo.
- O time atacante precisa derrotar o Guardião e destruir o Cristal; o defensor precisa impedir.

### Monstros épicos

Ficam na selva: a **Hydra** na metade de cima do mapa e o **Cérbero** na metade de baixo. Um tem foco em lutar, o outro em destruir torres.

| | Hydra (cima) | Cérbero (baixo) |
|---|---|---|
| **Foco** | Lutas | Torres |
| **Bônus** | Ouro + 10% de dano, vida máxima e mana máxima | Ouro + dobro de dano em torres |
| **Primeira aparição** | Quando todos chegariam ao **nível 9** pegando todos os minions de cada onda | Quando todos chegariam ao **nível 5** pegando todos os minions de cada onda |

Os tempos exatos de primeira aparição serão calculados quando a curva de experiência estiver definida.

Regras comuns aos dois:

- O bônus é **temporário: dura 2 minutos**.
- O monstro **reaparece 4 minutos** depois de ser derrotado.
- **Se um campeão com o bônus morrer, ele perde o bônus**; o resto do time continua com ele.

**Fases da Hydra** (fica mais perigosa conforme apanha):

1. **1 cabeça:** morde os inimigos.
2. **2 cabeças:** surge a segunda cabeça; elas cospem bolas de água nos inimigos.
3. **3 cabeças:** começa a invocar redemoinhos com dano em área.

**Fases do Cérbero** (cada terço da vida é uma fase):

1. **Garras:** ataca com as garras.
2. **Ao perder um terço da vida, uma das cabeças cai.** As duas restantes mordem até 2 campeões diferentes, ou mordem 2 vezes o mesmo campeão (dobro de dano).
3. **Resta uma cabeça,** que ataca com fogo em área de cone.

**Roubo de objetivo:** quando os dois times disputam um monstro épico, o caçador adversário pode "roubar" o último golpe.

- **Estar lá na hora certa é Macro:** decidir disputar o objetivo e chegar a tempo.
- **Acertar o último golpe é Micro:** a execução mecânica.
- Na simulação, o Macro do time define se existe chance de roubo (se o caçador chegou a tempo), e a diferença de Micro entre os dois caçadores define a chance de sucesso.

### Acampamentos da selva

**Cada time tem sua própria selva com o mesmo conjunto de acampamentos** (espelhada), dividida em duas metades:

| Metade | Acampamento | Tipo | Recompensa |
|---|---|---|---|
| 1 | **Pássaro grande + 4 pássaros pequenos** | Pequeno | Ouro e experiência; dá **mais ouro** que os outros pequenos |
| 1 | **Sapo vermelho enorme** | Médio (bônus) | Ouro, experiência + **regeneração de vida e dano físico extra** |
| 1 | **Rato médio** | Pequeno | Ouro e experiência |
| 2 | **3 aranhas** | Pequeno | Ouro e experiência |
| 2 | **Polvo enorme** | Médio (bônus) | Ouro, experiência + **regeneração de mana e poder mágico extra** |
| 2 | **Pequeno Golem de pedra** | Pequeno | Ouro e experiência |

- Todos reaparecem depois de um tempo.
- **Os acampamentos são o farm do caçador**, já que minions não chegam à selva (como no LoL). Por isso **todos são obrigatórios na rotina normal da selva**.
- **Pular um acampamento é decisão de Macro:** um caçador com Macro alto pode deixar um acampamento para trás quando enxerga uma oportunidade melhor (um gank, um objetivo, uma invasão).
- **Bônus herdado:** se o portador do bônus do Sapo ou do Polvo morrer, **quem deu o abate herda o bônus** pelo tempo que restava.
- Posição exata no mapa, tempos de reaparição, duração e valores dos bônus: **[A DEFINIR]**

### Gank

Gank é quando o caçador sai da selva para ajudar uma rota a abater o inimigo.

- **Perceber a oportunidade e ir é Macro:** por exemplo, notar que o inimigo de uma rota está com pouca vida.
- **O sucesso do gank depende de Micro:** comparação de Micro entre os envolvidos. O gank pode dar errado: o inimigo pode jogar tão bem que escapa ou até abate o jogador da rota e o caçador.

### Invasão de selva

- O caçador (ou o time) pode **entrar na selva inimiga e roubar acampamentos**, inclusive o Sapo e o Polvo.
- Invadir ou proteger a própria selva é decisão de **Macro**.

### Encontros entre caçadores

- Os caçadores podem se encontrar na selva e **lutar, disputar objetivos ou disputar farm**.
- O resultado depende de **Micro**.

### Visão (névoa de guerra)

- **Os times não sabem onde estão os jogadores inimigos**, a não ser que tenham visão deles.
- Formas de ter visão:
  - **Proximidade:** ver inimigos que estão perto dos seus campeões (e, presumivelmente, de minions e torres aliados — **[A DEFINIR]**).
  - **Torres de visão:** pequenas torres que revelam uma área por **1 minuto** e levam **1min30 para recarregar**.
- Quantas torres de visão cada jogador pode colocar e se o Suporte tem alguma vantagem nisso: **[A DEFINIR]**
- Gank, invasão e roubo de objetivos dependem de visão: sem visão, o time pode ser pego de surpresa.

### Recompensa por jogador em destaque

- Um jogador com vários abates seguidos sem morrer passa a valer mais ouro para quem derrotá-lo.
- Ajuda o time que está atrás e conversa com o atributo Mental.
- Valores: **[A DEFINIR]**

## 8. Draft (pick & ban)

- Fase de banimentos e escolhas antes de cada partida.
- O jogador avalia campeões, o meta atual e as listas de campeões dos seus jogadores e dos adversários.
- Ordem e quantidade de bans/picks: **[A DEFINIR]**

## 9. Camada de negócio (Fase 2)

Entra depois que o núcleo estiver divertido. Feita em menus e painéis, não em 3D.

- Gaming house
- Patrocinadores
- Loja de produtos
- Criadores de conteúdo
- Staff (técnico, analista, psicólogo etc.)
- Finanças da empresa

Detalhes: **[A DEFINIR]**

## 10. Roteiro

### Fase 1 — Núcleo
- [ ] Tela inicial com configuração de dinheiro e dificuldade (predefinições + personalizado)
- [ ] Geração de jogadores com posição, atributos, lista de campeões e traços ocultos
- [ ] Contratação do elenco (5 titulares + 5 reservas)
- [ ] Sistema de energia, descanso e treino
- [ ] Campeões fictícios e draft
- [ ] Simulação de partida
- [ ] Liga e calendário
- [ ] Salvar e carregar
- [ ] Versão de navegador publicada no itch.io

### Fase 2 — Negócio
- [ ] Itens da seção 9

## 11. Decisões em aberto

- Valores de dinheiro inicial e de cada nível de dificuldade
- Penalidade por jogar fora da posição principal
- Fórmula das lutas em equipe (Micro + Macro)
- Formato de exibição da partida
- Balanceamento de torres, Guardião, monstros épicos e acampamentos
- Curva de experiência (define os tempos de aparição da Hydra e do Cérbero)
- Detalhes dos acampamentos da selva (posição, reaparição, bônus)
- Regras do draft
- Nome do jogo, do MOBA fictício e dos campeões
- Estrutura da liga (quantos times, formato, playoffs, mundial)
- Transferências, contratos e janela de mercado
