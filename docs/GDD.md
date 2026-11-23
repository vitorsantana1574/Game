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

### 6.3 Domínio de campeões

Cada jogador tem um nível de domínio para cada campeão:

| Nível | Significado |
|---|---|
| **Favorito** | Os campeões com que ele joga melhor. |
| **Conhece bem** | Joga com segurança. |
| **Já jogou** | Conhece o básico, com desempenho reduzido. |
| **Não conhece** | Penalidade forte de desempenho. |

**Tamanho da lista × maestria:**

- **Lista pequena:** mais maestria nos campeões que ele mais joga. É especialista.
- **Lista vasta:** razoável com quase tudo, mas não é especialista em nenhum.
- O mesmo vale para as **posições**: um jogador especialista na posição principal rende mais nela, enquanto um jogador flexível rende de forma mais equilibrada entre a principal e as secundárias.

Isso dá peso ao **pick & ban** e ao **meta** de cada patch. Tamanho exato das penalidades e bônus: **[A DEFINIR]**

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

**Exibição da partida:** visão **2D de cima**, com os campeões se movendo e lutando sozinhos pelo mapa, e um **painel de narração ao lado** descrevendo o que está acontecendo (abates, ganks, objetivos, torres, roubos etc.).

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
  - **Proximidade:** campeões, minions e torres aliados revelam os inimigos que estão por perto.
  - **Torres de visão:** pequenas torres que revelam uma área por **1 minuto** e levam **1min30 para recarregar**.
- **Limite de torres de visão carregadas:**
  - **Cada jogador carrega no máximo 2** ao mesmo tempo.
  - **O Suporte carrega até 3** e pode **comprar mais na base por um preço barato** (só na base).
- **Destruir uma torre de visão inimiga** dá um pouco de ouro e uma quantidade quase nula de experiência.
- Gank, invasão e roubo de objetivos dependem de visão: sem visão, o time pode ser pego de surpresa.

### Recompensa por jogador em destaque

- Um jogador com vários abates seguidos sem morrer passa a valer mais ouro para quem derrotá-lo.
- Ajuda o time que está atrás e conversa com o atributo Mental.
- Valores: **[A DEFINIR]**

## 8. Draft (pick & ban)

Fase de banimentos e escolhas antes de cada partida.

### 8.1 Ordem (padrão do LoL profissional)

1. **1ª rodada de bans:** 3 por time, alternando.
2. **1ª rodada de picks:** 3 por time, na ordem A, B, B, A, A, B.
3. **2ª rodada de bans:** 2 por time, alternando (já sabendo o que o rival escolheu).
4. **2ª rodada de picks:** os 2 últimos de cada time, na ordem B, A, A, B.

### 8.2 Quem escolhe primeiro

- **Liga:** o time melhor colocado na tabela decide.
- **Séries:** alterna a cada jogo.

### 8.3 Formato das séries

- **MD1** na fase de pontos corridos.
- **MD3/MD5** nos playoffs. Séries longas cansam mais (sistema de energia).

### 8.4 Draft "fearless" nos playoffs

- Numa série de playoff, o campeão que um time já usou não pode ser usado de novo **por esse time** nos jogos seguintes.
- Valoriza jogadores com lista de campeões grande.

### 8.5 Campeões no jogo

- Começar com **cerca de 30 campeões** (uns 6 por posição) e ampliar com o tempo.

### 8.6 Quem faz o draft

- **Fase 1:** o jogador faz o draft manualmente.
- **Depois:** opção de **delegar ao técnico**, e a qualidade dele define as escolhas.

### 8.7 Informações na tela durante o draft

- O domínio de campeões dos seus jogadores (ver 6.3).
- Campeões favoritos do adversário, revelados por olheiro ou analista.
- **A força de cada campeão no patch NÃO é mostrada.** O meta precisa ser descoberto e aprendido:
  - com **treinos**, numa fase de treinamento; e/ou
  - pelo **técnico, que precisa estudar e treinar o meta**. Um técnico atualizado com o meta orienta melhor o draft.
- Detalhes de como o conhecimento do meta é exibido e evolui: **[A DEFINIR]**

## 8.8 Técnico

- Ele estuda o meta, orienta o draft e pode receber o draft delegado.
- Como o conhecimento do meta depende dele, o técnico entra já na **Fase 1**, e não só com o restante do staff na Fase 2.

### Contratação

- O jogador publica um **anúncio**, em três tamanhos:

| Anúncio | Candidatos |
|---|---|
| Pequeno | 1 técnico |
| Médio | até 3 técnicos |
| Grande | até 5 técnicos |

- **Os candidatos não aparecem na hora:** chegam depois de um tempo.
- O anúncio pode ter uma **oferta mínima**: oferecer mais garante que os candidatos apareçam mais rápido.
- Custo de cada anúncio e tempos de espera: **[A DEFINIR]**
- **Formas extras de conseguir técnicos melhores:**
  - **Reputação da organização:** títulos e bons resultados atraem candidatos melhores nos anúncios.
  - **Tirar técnico de outro time:** pagar uma multa para levar o técnico de um rival. É caro, mas você escolhe exatamente quem quer.

### Salário

- **Salário mensal.** O jogador precisa planejar as finanças para sempre conseguir pagar.
- **Salário atrasado:**
  - o técnico fica insatisfeito e rende menos;
  - se o atraso continuar, ele pede demissão;
  - **a reputação da organização cai**;
  - as mesmas regras valem para os jogadores.

### Atributos

| Atributo | O que faz |
|---|---|
| **Macro** | O Macro do técnico dá um **pequeno bônus de Macro** aos jogadores do time. |
| **Conhecimento** | O quanto ele sabe do **patch atual** e dos **confrontos campeão contra campeão** (matchups). |
| **Olheiro** | Habilidade de avaliar jogadores: encontrar **novos jogadores** para contratar e revelar os **campeões principais dos jogadores do time inimigo**. |

- Os atributos podem ser **treinados**.
- **Conhecimento cai a cada patch novo:** parte dele fica desatualizada e o técnico precisa estudar de novo. Quanto maior o Conhecimento, mais rápido ele se atualiza.
- Na Fase 2, o **Analista** é o especialista em estudar os rivais: revela mais e mais rápido do que o Olheiro do técnico, sem substituí-lo.

### Cansaço

- O técnico tem **cansaço**, que **não pode ser treinado**.
- O cansaço **só se recupera com férias**.
- **Durante as férias o time fica sem o técnico:** sem o bônus de Macro e sem o Conhecimento dele. Tirar férias entre temporadas é seguro; no meio dos playoffs, é um risco.
- Efeitos exatos do cansaço e duração das férias: **[A DEFINIR]**

## 8.9 Reputação da organização

- A organização tem uma **reputação**.
- **Sobe** com títulos e bons resultados; **cai** com salários atrasados.
- Reputação alta atrai **técnicos melhores** nos anúncios.
- Outros efeitos (jogadores, patrocinadores, fãs) e como é exibida: **[A DEFINIR]**

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
- Balanceamento de torres, Guardião, monstros épicos e acampamentos
- Curva de experiência (define os tempos de aparição da Hydra e do Cérbero)
- Detalhes dos acampamentos da selva (posição, reaparição, bônus)
- Técnico: custos e tempos dos anúncios, efeitos do cansaço e duração das férias
- Reputação: outros efeitos e exibição
- Como o conhecimento do meta é exibido e evolui
- Nome do jogo, do MOBA fictício e dos campeões
- Estrutura da liga (quantos times, formato, playoffs, mundial)
- Transferências, contratos e janela de mercado
