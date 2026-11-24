# MOBA Manager — Documento de Design do Jogo (GDD)

> Documento vivo: registra tudo o que já foi decidido sobre o jogo e o que ainda está em aberto.
> Itens marcados com **[A DEFINIR]** ainda não foram decididos.

Última atualização: 22/11/2026

---

## 1. Visão geral

- **Gênero:** gerenciamento de equipe de e-sports (manager), com foco em administração e estratégia.
- **Referências:** CS Manager, Teamfight Manager, Football Manager (gestão de time); Big Ambitions e Supermarket Simulator (gestão de negócio, como inspiração temática — não em 3D).
- **Nome do jogo:** **MOBA Manager**.
- **Nome do MOBA fictício:** **Crystal Legends**.
- **Premissa:** o jogador é dono e gestor de uma organização de e-sports que disputa ligas de **Crystal Legends**, um MOBA fictício inspirado em League of Legends.
- **Pilar do design:** um jogo de **pura administração de pessoas e números**. Toda mecânica nova deve gerar decisões de gestão.
- **Estrutura em duas camadas:**
  1. **Núcleo (Fase 1):** gerenciar o time — elenco, treinos, draft, partidas simuladas, liga, transferências.
  2. **Negócio (Fase 2):** gerenciar a organização como empresa — gaming house, patrocinadores, loja, staff, finanças.

## 2. Plataforma e tecnologia

- **Motor:** Godot 4.7.2 (versão padrão, GDScript), 2D, renderizador **Compatibility** (necessário para a versão de navegador).
- **Divisão do trabalho:** Claude cuida da lógica; GPT cuida da interface, arte, animações e sons. Detalhes em [ARQUITETURA.md](ARQUITETURA.md).
- **Publicação:** itch.io (gratuito), com versão jogável no navegador. Game Jolt como opção secundária. Steam e Epic descartadas por enquanto (taxa de US$ 100).
- **Repositório:** `vitorsantana1574/Game`.

## 3. Restrições importantes

- **Nada de propriedade intelectual real:** não usar League of Legends, campeões, times, jogadores ou ligas reais. O jogo fictício, os campeões e os times são todos inventados.
- **IA:** código feito com IA não precisa ser declarado nas plataformas. Arte, textos, música ou vozes gerados por IA precisam ser declarados (Steam) e podem ser filtrados por quem usa o filtro "No AI" do itch.io. Preferência: arte de pacotes gratuitos/comprados ou feita à mão.

## 4. Início de jogo (configuração)

Ao começar uma carreira, o jogador escolhe, na tela **Criar Equipe**:

- **Nome da organização:** digitado pelo jogador.
- **Dinheiro inicial:** três opções de capital.
- **Dificuldade dos times rivais:** três opções (iniciantes, equilibrados, experientes).
- **Predefinições prontas:** **Fácil**, **Normal** e **Difícil**, que ajustam dinheiro e rivais de uma vez.
- **Personalizado:** o jogador escolhe o capital e os rivais separadamente.
- **Pesadelo:** predefinição extra, **bloqueada no início**. É desbloqueada quando o jogador **vence o mundial (fica em 1º lugar no mundial) jogando no Difícil**. O desbloqueio vale para todas as carreiras futuras.
- **Moeda:** real brasileiro, no formato **R$ 80.000**.
- **Saves:** 4 espaços para carreiras, com as opções Continuar (último save jogado) e Carregar.

Valores de capital e força dos rivais de cada predefinição estão em `data/config/dificuldades.json`. São provisórios e serão calibrados junto com a economia: **[A DEFINIR — balanceamento]**

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
- **Ego:** o quanto o jogador aceita ficar no banco de reservas. Jogadores com ego alto ficam insatisfeitos quando vão para o banco.
  - Principal função: dar um **custo ao rodízio** de reservas (sistema de energia). Descansar o craque tem um preço.
  - Jogadores com ego alto podem exigir no contrato uma **cláusula de titular**: se forem para o banco, ficam insatisfeitos ou pedem para sair.
  - O ego **sobe e desce** ao longo da carreira (ver 6.5).
- **Salário pedido:** quanto o jogador exige para assinar ou renovar contrato.

### 6.5 Ego, satisfação e lealdade

> **Regra de design:** as ferramentas abaixo **atenuam o problema, mas nunca o eliminam**. O ego deve continuar dando trabalho. Em algum momento ele vai obrigar o jogador a escolher entre manter um craque ou gastar muito dinheiro, e uma decisão ruim pode levar a organização à falência.

**O que faz o ego subir**
- Títulos e prêmios individuais (MVP, seleção do mundial).
- Ser o destaque do time, com os melhores números do elenco.
- Receber propostas de outros times.
- Receber um salário muito acima do resto do elenco.

**O que faz o ego descer**
- Sequências de derrotas e atuações ruins.
- Ser superado por um companheiro da mesma posição (perder a titularidade "no campo").
- Idade e maturidade: jogadores mais velhos tendem a se acalmar.
- **Psicólogo** (staff da Fase 2): reduz o ego aos poucos.

**Ferramentas do gestor**
- **Conversa individual:** elogiar, cobrar ou prometer tempo de jogo.
  - Elogiar acalma, mas elogio exagerado infla o ego.
  - **Promessas precisam ser cumpridas:** promessa quebrada derruba a satisfação com muito mais força.
- **Capitão:** um jogador de ego baixo e Mental alto como capitão ajuda a segurar a satisfação do elenco.

**Retenção de jogadores em nível mundial**
- **Lealdade (indicador por jogador):** sobe com tempo de casa, títulos conquistados juntos, salário em dia e promessas cumpridas. Lealdade alta reduz a chance de aceitar propostas de rivais e deixa as renegociações mais moderadas. Jogadores formados desde iniciantes tendem a ser mais fiéis.
- **Reputação a favor:** quando o time está no topo, os jogadores querem ficar, e os rivais precisam oferecer muito mais.
- **Direito de preferência:** quando um rival faz proposta, você pode igualar antes de o jogador decidir.
- **Rivais com orçamento limitado:** os times do computador também têm caixa; só os ricos conseguem levar os seus astros.
- **Multa rescisória alta** e **contratos longos assinados cedo** (ver 8.11).

Valores, velocidade de mudança do ego e da lealdade: **[A DEFINIR — balanceamento]**

### 6.6 Treino

O treino tem várias modalidades, cada uma voltada para atributos diferentes.

| Modalidade | Atributos treinados | Observações |
|---|---|---|
| **Acompanhamento psicológico / dia de relaxar** | **Mental** e **Resistência** | Evolução **lenta**. Não é treino de partida: é treino de mente, fora do computador. |
| **X1 entre os jogadores** | **Farm** e **Micro** + **domínio de campeão** | Escolhe até **2 campeões**: um principal e um secundário. **O principal sempre é o mais treinado.** |
| **Treino puro de farm** | **Farm** (foco principal) | Um bot fica usando habilidades no jogador sem parar; ele precisa farmar sem perder minions e sem matar o bot. |
| **Partidas internas, simulações e análise de partidas** | **Macro** | Inclui exercícios por posição, por exemplo: o caçador treina o roubo de objetivo; o jogador de rota treina a hora certa de sair sem perder muito farm. |

**Regras gerais do treino**
- **Treino gasta energia:** X1, treino de farm e partidas internas consomem energia. O gestor precisa escolher entre treinar e descansar, principalmente antes de jogos importantes.
- **Exceções:** o dia de relaxar e o acompanhamento psicológico **recuperam** energia.
- **Agenda semanal:** uma grade com os dias da semana, em que o gestor distribui treinos, descanso e partidas para cada jogador.
- **Partida interna titulares × reservas:** com 10 jogadores, o time joga um 5v5 completo entre si. É o treino de Macro mais forte, mas cansa os 10 ao mesmo tempo, e dá aos reservas experiência e chance de mostrar serviço.
- **Ganhos dependem de idade, potencial e nível atual:** jovens com potencial alto evoluem rápido; veteranos evoluem pouco; atributos já altos sobem devagar.
- **Treinar demais derruba a satisfação:** agenda pesada por muitas semanas irrita os jogadores, principalmente os de ego alto.
- O **treino puro de farm não treina domínio de campeão**, para o X1 continuar valendo a pena.
- **Treinar Farm com o suporte quase não traz benefício** (o suporte não farma; o Farm pesa só 5% no nível dele). A tela deve avisar isso. Escolher esse treino para o suporte é um erro de gestão possível.
- **Cuidado de balanceamento:** o ganho de cada modalidade em cada atributo precisa ser calibrado com atenção (no simulador de temporadas), para nenhuma modalidade ser sempre a melhor escolha.

**Treino do técnico**
- Sempre **fora das partidas**.
- Durante o período de treino, o técnico **fica indisponível**, dedicado ao atributo escolhido na aba de treino. Como nas férias, o time fica sem ele nesse período.

**Ainda a definir:** duração de cada treino, custos em dinheiro e o quanto cada modalidade melhora os atributos.

**Futuro:** contratar um **treinador auxiliar** que aumenta a eficiência dos treinos.

## 7. O MOBA fictício: Crystal Legends

Baseado em League of Legends, mas não idêntico:

- Duas equipes de 5, cada uma com uma posição por jogador.
- **Minions** nas rotas: abatê-los dá **experiência** (nível do personagem) e **ouro** (para comprar **itens**).
- Quem farma pouco chega às lutas e aos duelos de rota com **nível mais baixo e menos itens**.
- **Objetivos de mapa** que podem ser disputados ou abandonados (decisão de Macro) — ver 7.1.
- **Campeões** fictícios, com características próprias, divididos em **6 classes**: **tanques, assassinos, lutadores, magos, suportes e atiradores**.
- **Itens:** criados como os campeões, com identidade própria. **Cada campeão carrega no máximo 5 itens por partida, sendo um deles uma bota** (movimentação).
- **Renascimento:** o tempo para renascer depois de morrer **aumenta com o nível** do campeão (como no LoL).
- **Patches:** mudam a força dos campeões e o meta **a cada 6 meses**.

**Exibição da partida:** visão **2D de cima**, com os campeões se movendo e lutando sozinhos pelo mapa, e um **painel de narração ao lado** descrevendo o que está acontecendo (abates, ganks, objetivos, torres, roubos etc.).

**O jogador não é obrigado a assistir tudo.** Opções:
- velocidades **1x, 2x, 4x e 8x**;
- **"Só os melhores momentos"**: acelera e para nas lutas, objetivos e torres;
- **"Ver resultado"**: pula direto para o fim, com as estatísticas.

## 7.0 Ritmo da partida (proposto e testado)

Valores calibrados com 2.000 partidas simuladas no protótipo de ritmo. Relatório: `tools/relatorios/ritmo_partida.md`. Números em `data/config/partida.json`.

**Metas atingidas:** duração mediana de **32 min** (80% entre 25 e 39 min), cerca de **33 abates** por partida, **1 em cada 3 partidas** com virada de um time que estava bem atrás aos 15 min, e o time mais forte vencendo na medida certa (5 pontos melhor: 62%; 20 pontos: 92%).

| Item | Valor proposto |
|---|---|
| **Duração** | Sem limite rígido. A partir dos **35 min** entra a **tensão final**: torres, Guardião e Cristal ficam 8% mais frágeis a cada minuto. Na prática, nenhuma partida passa de ~50 min |
| **Nível máximo** | **16** |
| **XP por nível** | 280 para o nível 2, e +100 a cada nível seguinte |
| **Ondas de minions** | Primeira chega a **1:30**, depois a cada **30 s**: 3 corpo a corpo + 3 à distância, e 1 de cerco a cada 3 ondas |
| **XP dos minions** | Corpo a corpo **60**, à distância **30**, cerco **90**, fortalecido **100**. A XP é dividida entre os aliados próximos; a rota dupla recebe 50% a mais no total, para não ficar muito atrás |
| **Ouro dos minions** | Corpo a corpo 21, à distância 14, cerco 60, fortalecido 45. Ouro só para quem dá o último golpe (Farm) |
| **Ouro passivo** | 2,4 por segundo a partir de 1:30 |
| **Renascimento** | 6 s + 2,6 s por nível (nível 1: 9 s; nível 16: 48 s). Depois dos 25 min, +2% por minuto, até +50% |
| **Itens (atirador típico)** | Bota aos ~5 min, 2º item aos ~13, 3º aos ~21, 4º aos ~29, 5º aos ~37 (partidas longas). Bota custa 1.000 de ouro; itens, ~2.700 |
| **Item de suporte** | O suporte começa com um item que gera ouro: 35% do ouro dos minions que o atirador abate por perto + 60 por participação em abate. **Não depende do Farm do suporte** — o suporte ajuda o atirador a farmar, não farma. Resultado: suporte com ~73% do ouro do atirador |
| **Ordem dos itens** | Segue a recomendação de cada campeão. **Macro alto adapta a ordem à partida** (ex.: atrasar a bota para fechar antes um item decisivo, item contra cura). **Micro alto faz compras arriscadas renderem mais** (itens só de dano) |
| **Reaparecimento dos monstros épicos** | **6 minutos** (Cérbero e Hydra). Bônus continua durando 2 minutos. Resultado: ~3,5 de cada por partida |
| **Cérbero** | Aparece aos **4:22** (nível 5 teórico); na prática o 1º é abatido por volta dos 6 min |
| **Hydra** | Aparece aos **9:54** (nível 9 teórico); na prática a 1ª é abatida por volta dos 11 min |

**Progressão com farm perfeito** (rota solo / rota dupla / selva): nível 5 em 4:22 / 5:19 / 5:41; nível 9 em 9:54 / 12:42 / 13:48; nível 16 em 26:00 / 34:10 / 37:23.

**Acampamentos da selva** (por time; XP +10% após o primeiro teste, para o caçador não ficar atrás demais):

| Acampamento | XP | Ouro | Reaparece |
|---|---|---|---|
| Pássaro grande + 4 pássaros pequenos | 230 | 110 | 2 min |
| Sapo vermelho enorme (bônus) | 330 | 100 | 5 min |
| Rato médio | 165 | 70 | 2 min |
| 3 aranhas | 210 | 90 | 2 min |
| Polvo enorme (bônus) | 330 | 100 | 5 min |
| Pequeno Golem de pedra | 265 | 100 | 2 min |

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

## 7.2 Itens

Catálogo completo em `data/itens/itens.json`; modelo de combate em `data/config/combate.json`. Testado no laboratório de itens (`tools/prototipos/laboratorio_itens.py`); relatório em `tools/relatorios/laboratorio_itens.md`. Esta seção é gerada por `tools/documentacao/gerar_itens_gdd.py`.

### Regras

- **Até 5 itens por campeão: 1 bota + 4 itens.** A compra segue a ordem recomendada do campeão; o Macro adapta a ordem e o Micro faz compras arriscadas renderem mais (seção 7.0).
- **Dano recebido** = dano × 100 / (100 + resistência efetiva). A resistência efetiva nunca fica abaixo de 0.
- **Letalidade e penetração mágica:**
  - **Valor fixo** tira um número da armadura/resistência: 30 de letalidade contra 300 de armadura = o alvo fica com 270.
  - **Porcentagem** tira uma parte: 30% contra 300 = 90 a menos, o alvo fica com 210.
  - **Com os dois, primeiro a porcentagem e depois o fixo:** 300 × 0,7 = 210; 210 − 30 = 180.
  - **Ponto de virada** = valor fixo ÷ porcentagem. Abaixo dele, o fixo rende mais (alvos frágeis); acima, a porcentagem (lutadores e tanques). Calibrado para: 20 de letalidade × 20% (Lança) = **100 de armadura**; 15 de penetração mágica × 25% (Cajado) = **60 de resistência mágica**. No fim de jogo, frágeis têm ~85 de armadura e ~48 de RM; lutadores ~170 de armadura; tanques ~220 de armadura e ~140 de RM.
  - **Só 2 itens têm letalidade %** (Lança Quebra-Escudos 20%, Arco do Juízo Final 30%) e **só 2 têm penetração mágica %** (Cajado do Abismo 25%, Foice da Lua Negra 20%).
  - **Porcentagens não se somam:** com dois itens de %, vale a maior. Valores fixos se somam.
- **Passivas do mesmo grupo não se acumulam** (ex.: dois escudos de vida baixa): vale a primeira.
- **Anticura:** reduz as curas do alvo em 40% (Égide de Aço contra quem bate; Tocha do Tormento contra quem é queimado).
- **Crítico** causa 175% de dano (195% com a Lâmina Cristalina).

### Item inicial do suporte

| Item | Preço | Atributos | Passiva |
|---|---|---|---|
| **Medalhão do Tributo** — Moeda antiga que os guardiões davam aos escudeiros. O suporte ganha ouro ajudando o atirador a farmar. | 400 | 50 Vida | **Tributo:** Recebe 35% do ouro dos minions abatidos pelo atirador por perto e 60 de ouro por participação em abate. |

### Botas (escolha 1)

| Bota | Preço | Atributos | Passiva | Classes |
|---|---|---|---|---|
| **Botas do Andarilho** — Botas leves de mensageiro. Para quem precisa chegar primeiro. | 725 | 60 Vel. movimento | — | Todas |
| **Grevas de Ferro** — Placas de ferro forjadas nas minas do Golem. Contra times de ataque físico. | 1050 | 45 Vel. movimento, 20 Armadura | **Aparar:** Reduz em 10% o dano de ataques básicos recebidos. | Tanque, Lutador, Suporte, Assassino |
| **Sandálias da Sabedoria** — Tecidas por monges do vale das névoas. Contra magia e controle. | 1300 | 45 Vel. movimento, 25 RM, 25% Tenacidade | — | Todas |
| **Botas do Caçador** — Couro silencioso para emboscadas. | 900 | 45 Vel. movimento, 12 Letalidade | — | Assassino, Lutador |
| **Botas Arcanas** — Runas costuradas na sola que abrem brechas na defesa mágica. | 1025 | 45 Vel. movimento, 12 Pen. mágica | — | Mago, Suporte |
| **Botas da Fúria** — Para quem não para de atacar. | 1425 | 45 Vel. movimento, 35% Vel. ataque | — | Atirador, Lutador |

### Dano físico

| Item | Preço | Atributos | Passiva | Classes |
|---|---|---|---|---|
| **Presa da Serpente** — Adaga com veneno de serpente das dunas. Para terminar o serviço. | 3050 | 50 DF, 20 Letalidade, 15 Aceleração | **Emboscada:** +8% de dano contra alvos com menos de 40% de vida. | Assassino, Lutador |
| **Lâmina do Eclipse** — Forjada durante um eclipse. O primeiro golpe vem da escuridão. | 2975 | 50 DF, 20 Letalidade, 10 Aceleração | **Golpe Sombrio:** O primeiro ataque após usar uma habilidade causa 90 (+30% do dano físico bônus) de dano físico extra. Uma vez por combate. | Assassino |
| **Manto da Noite Eterna** — Capa de sombra viva. Dá ao assassino fôlego para sair vivo. | 2925 | 40 DF, 16 Letalidade, 300 Vida | **Véu:** Ao ficar com menos de 30% de vida, ganha um escudo de 180 (+10% da vida bônus). Uma vez por combate. | Assassino, Lutador |
| **Lança Quebra-Escudos** — Ponta de cristal capaz de rachar armaduras de titã. | 2675 | 40 DF, 20% Letalidade, 200 Vida | — | Lutador, Assassino, Atirador |
| **Arco do Juízo Final** — Dizem que cada flecha carrega a sentença de um gigante. | 3550 | 35 DF, 25% Crítico, 30% Letalidade | — | Atirador |
| **Lâmina Cristalina** — Lapidada de um fragmento do Cristal. O fio mais perfeito já visto. | 3450 | 60 DF, 25% Crítico | **Fio Perfeito:** Acertos críticos causam 195% de dano em vez de 175%. | Atirador |
| **Asas do Vento Veloz** — Penas de um pássaro gigante da selva. Leveza e cadência. | 2425 | 40% Vel. ataque, 25% Crítico, 20 Vel. movimento | **Rajada:** A cada 3 ataques, o próximo causa 60 (+25% do dano físico bônus) de dano mágico extra. | Atirador |
| **Sanguessuga Rubra** — Espada que bebe o sangue de quem fere. | 3000 | 60 DF, 15% Roubo de vida | **Escudo de Sangue:** A cura acima da vida máxima vira escudo, até 250. | Atirador, Lutador, Assassino |
| **Machado do Gigante** — Machado de um gigante das montanhas. Quanto mais ferido, mais perigoso. | 3300 | 45 DF, 350 Vida, 15 Aceleração | **Fúria:** +2% de dano para cada 10% de vida perdida (máximo +12%). | Lutador, Assassino |
| **Lâmina Sanguinária do Guerreiro** — Arma de quem luta na linha de frente e não cai fácil. | 2800 | 40 DF, 300 Vida, 8% Roubo de vida | **Fôlego:** Ao ficar com menos de 30% de vida, ganha um escudo de 200 (+15% da vida bônus). Uma vez por combate. | Lutador |
| **Martelo das Montanhas** — Cada golpe é um tremor de terra. Feito para derrubar tanques. | 2900 | 30 DF, 400 Vida, 25 Armadura | **Tremor:** Habilidades causam dano físico extra igual a 4% da vida máxima do alvo. | Lutador, Tanque |

### Híbrido (físico + mágico)

| Item | Preço | Atributos | Passiva | Classes |
|---|---|---|---|---|
| **Cetro-Lâmina do Crepúsculo** — Metade espada, metade cajado. Para quem ataca com aço e magia. | 3075 | 30 DF, 50 PM, 25% Vel. ataque | **Duplo Golpe:** Ataques causam 15 (+15% do poder mágico) de dano mágico extra. | Atirador, Lutador |

### Dano mágico

| Item | Preço | Atributos | Passiva | Classes |
|---|---|---|---|---|
| **Grimório Cristalino** — Livro escrito com tinta de cristal. Amplifica todo o poder de quem lê. | 2525 | 90 PM, 10 Aceleração | **Sabedoria:** Aumenta o poder mágico total em 12%. | Mago |
| **Cajado do Abismo** — Cajado que suga a magia ao redor. Nenhuma barreira resiste. | 2325 | 60 PM, 25% Pen. mágica | — | Mago |
| **Foice da Lua Negra** — Colhe a vida e a resistência dos inimigos sob a lua. | 2775 | 55 PM, 20% Pen. mágica, 250 Vida | — | Mago |
| **Orbe da Tempestade** — Um raio preso numa esfera. A primeira magia vem como um trovão. | 2600 | 65 PM, 15 Pen. mágica, 10 Aceleração | **Raio:** O primeiro dano de habilidade em um combate causa 70 (+10% do poder mágico) de dano mágico extra. | Mago |
| **Coroa da Hydra** — Coroa feita de escamas da Hydra. Quem a usa demora a cair. | 2350 | 60 PM, 300 Vida | **Proteção da Hydra:** Ao ficar com menos de 35% de vida, ganha um escudo de 120 (+15% da vida bônus). Uma vez por combate. | Mago, Suporte |
| **Véu Celestial** — Tecido das estrelas. Bloqueia a primeira magia que vier. | 2175 | 55 PM, 45 RM | **Barreira:** Começa cada combate com um escudo de 300 que só absorve dano mágico. | Mago, Suporte |
| **Tocha do Tormento** — Chama que não se apaga. Queima tanques e corta a cura dos inimigos. | 2575 | 70 PM, 250 Vida | **Queimadura:** Habilidades queimam o alvo por 3 s, causando 0,6% da vida máxima dele por segundo como dano mágico, e reduzem as curas dele em 40%. | Mago, Suporte |

### Defesa

| Item | Preço | Atributos | Passiva | Classes |
|---|---|---|---|---|
| **Égide de Aço** — Escudo coberto de espinhos. Quem bate, se machuca. | 2225 | 60 Armadura, 300 Vida | **Espinhos:** Devolve 12% do dano de ataques recebidos como dano mágico e reduz as curas do atacante em 40%. | Tanque, Lutador, Suporte |
| **Couraça do Gigante de Pedra** — Placas de rocha viva. Críticos simplesmente escorregam. | 2450 | 400 Vida, 50 Armadura | **Pele de Pedra:** Recebe 20% menos dano de acertos críticos. | Tanque, Lutador |
| **Manto dos Ventos Gélidos** — O frio do norte envolve quem o veste e entorpece os atacantes. | 1775 | 40 Armadura, 40 RM | **Frio:** Inimigos que atacam o portador têm a velocidade de ataque reduzida em 8%. | Tanque, Lutador, Suporte |
| **Escudo do Guardião** — Réplica do escudo da estátua que guarda o Cristal. | 2175 | 400 Vida, 50 RM | **Bastião:** Começa cada combate com um escudo de 220 que só absorve dano mágico. | Tanque, Lutador, Suporte, Mago, Assassino, Atirador |
| **Coração do Titã** — O coração de pedra de um titã ainda bate. Quanto maior o portador, mais forte o golpe. | 2425 | 700 Vida, 10 Aceleração | **Colosso:** Aumenta a vida máxima em 2,5%. Ataques causam dano físico extra igual a 0,6% da vida máxima do portador. | Tanque, Lutador |
| **Armadura Viva de Cristal** — Cristal que cresce sobre a pele e se regenera em combate. | 2300 | 350 Vida, 30 Armadura, 30 RM | **Regeneração Cristalina:** Em combate, recupera 2,5% da vida máxima a cada 5 segundos. | Tanque, Lutador |

### Suporte

| Item | Preço | Atributos | Passiva | Classes |
|---|---|---|---|---|
| **Lanterna do Vigia** — Luz que guia e fortalece os aliados. | 2400 | 45 PM, 250 Vida, 15 Aceleração | **Bênção:** Curas e escudos do portador em aliados também dão 10% de velocidade de ataque ao aliado por 4 s. | Suporte |
| **Medalhão dos Eternos** — Relíquia dos primeiros defensores do Cristal. Protege todo o time de uma vez. | 1800 | 30 Armadura, 30 RM, 15 Aceleração | **Égide Coletiva:** No início de cada luta, dá um escudo de 140 (+8% da vida bônus do portador) a todo o time. | Suporte, Tanque |

### Resultados dos testes de equilíbrio

- **Assassino com bota + 3 itens de dano + 1 item de vida** (Botas do Caçador, Presa da Serpente, Lâmina do Eclipse, Lança Quebra-Escudos, Escudo do Guardião): em 3 s tira ~**79%** da vida de um atirador, ~**68%** de um mago com item defensivo e só ~**18%** de um tanque.
- **Atirador completo** derruba um mago em ~**3,3 s** e um tanque completo em ~**12 s**.
- **Tanque** aguenta ~**3,2×** mais que um frágil contra o mesmo time.
- **Lutador × atirador** no duelo corpo a corpo: equilibrado.
- **Interações:** anticura corta ~30% da cura do roubo de vida; a Couraça segura atiradores de crítico; Escudo do Guardião + Sandálias reduzem a explosão do mago de ~56% para ~33% da vida; a letalidade % não rende contra frágeis e dá +12% de dano contra tanques.
- **Nenhuma passiva carrega o item sozinha** (peso máximo ~44% do valor).
- **Eficiência em ouro** de todos os itens entre 84% e 101% (o resto do valor está na passiva).

**Pontos a revisar quando os campeões existirem:**
- A **Orbe da Tempestade** apareceu em todas as melhores builds do mago (item central). Com habilidades diferentes por campeão, outras opções devem competir.
- Para o **suporte**, itens de vida e defesa rendem mais que os de poder mágico, porque as curas e escudos em aliados ainda não estão no modelo (dependem dos kits dos campeões).

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

## 8.10 Competições

Três níveis: **regional**, **nacional** e **mundial**.

### Calendário do ano

O ano tem 12 meses de 30 dias. Uma rodada da liga por semana.

| Período | Dias | O que acontece |
|---|---|---|
| Janeiro | 1–34 | **Pré-temporada**: janela de transferências aberta, **patch novo** |
| Fevereiro a maio | 35–150 | **Etapa 1**: 14 rodadas (1 por semana) + semifinal e final |
| Junho | 151–184 | **Pausa do meio do ano**: janela de transferências aberta, bootcamp. **Patch novo** no dia 181 |
| Julho a outubro | 185–300 | **Etapa 2**: 14 rodadas + semifinal e final |
| Novembro | 301–330 | **Mundial** (para quem se classificou) |
| Dezembro | 331–360 | **Fim de temporada**: janela de transferências aberta |

- **Até três competições por ano:** etapa 1, etapa 2 e mundial. Os dois patches anuais caem no início de cada etapa.
- **Acesso e rebaixamento ao fim de cada etapa** (2 sobem, 2 caem). Assim dá para subir para a nacional já no meio do ano.

**Tempo mínimo para respirar e treinar** (verificado por testes automáticos):
- **Liga:** 6 dias livres entre um jogo e outro (rodadas semanais); 9 dias entre a última rodada e a semifinal.
- **Preparação:** 34 dias antes do 1º jogo do ano; 41 dias entre a final da etapa 1 e a etapa 2; mais de 2 meses entre o mundial e a temporada seguinte.
- **Mundial:** mais apertado de propósito, com pelo menos 1 dia livre entre jogos na fase suíça e 3 dias no mata-mata. É onde a Resistência e o rodízio de reservas mais pesam. Há 9 dias entre a final da etapa 2 e o mundial.

### Ligas regional e nacional (mesmo formato)

**Fase de pontos**
- **8 equipes.**
- **Vitória: 5 pontos. Derrota: 0 pontos.**
- Partidas em **MD1** (ver 8.3).
- **Turno e returno: 14 jogos por equipe** (cada time enfrenta os outros 7 duas vezes).
- **Critérios de desempate**, nesta ordem:
  1. confronto direto;
  2. saldo de abates;
  3. tempo médio das vitórias (quem vence mais rápido fica na frente).

**Playoffs**
- As **4 primeiras colocadas** avançam.
- Os confrontos são **sorteados de forma totalmente aleatória**: quem se classificou em 4º pode enfrentar logo o 1º colocado.
- **Semifinais (MD5) → final (MD5)**, com draft fearless (ver 8.4).
- **Vantagem pela colocação:** o time melhor colocado na fase de pontos escolhe quem faz o primeiro pick no **jogo 1** da série. Nos jogos seguintes, alterna (ver 8.2).

**Conexão entre regional e nacional: acesso e rebaixamento**
- O time começa na **regional**. Os melhores sobem para a **nacional** na temporada seguinte, e os piores da nacional caem para a regional.
- **2 sobem e 2 caem** por temporada.

### Mundial

**1. Classificação**
- Campeões e mais bem colocados das ligas nacionais de várias **regiões fictícias**, cada uma com seu estilo de jogo e seus campeões favoritos.
- Quantas vagas cada região tem: **[A DEFINIR]**

**2. Play-in**
- Times de regiões mais fracas disputam as vagas restantes.

**3. Fase suíça (16 times)**
- A cada rodada, cada time enfrenta alguém com a mesma campanha.
- **3 vitórias: avança. 3 derrotas: eliminado.**

**4. Mata-mata (8 times)**
- Chave fixa, todas as séries em **MD5**, até a grande final.

**5. Extras**
- **Bootcamp antes do torneio:** gastar dinheiro para treinar fora e se adaptar ao meta do mundial.
- **Viagem e fuso horário:** cansam os jogadores e afetam a energia nos primeiros dias.
- **Meta do mundial:** costuma vir num patch especial; o Conhecimento do técnico conta muito.
- **Prêmios individuais:** MVP do torneio, melhor jogador por posição, seleção do mundial.
- **Premiação em dinheiro e grande ganho de reputação.**

Formato das séries no play-in e na fase suíça, valores de premiação: **[A DEFINIR]**

## 8.11 Contratos e transferências

### Duração

- Contratos firmados por período: **6 meses, 1 ano, 2 anos** e assim por diante.

### Modelos de contrato

**1. Clássico (salário)**
- Salário **negociável, mas sem fugir muito** do valor pedido pelo jogador.
- **Quanto melhor e mais conhecido o jogador, mais difícil a negociação.** Iniciantes são mais simples de negociar.
- O salário pedido é **fortemente ligado aos atributos** do jogador.

**2. Com pagamento na assinatura (luvas)**
- Uma **quantia alta paga só na hora da assinatura**, e depois segue o salário normal.
- Aumenta a chance de o jogador aceitar, mas **ele ainda pode recusar**, dependendo de quão bom e conhecido ele é.

### Experiência

- Cada jogador tem uma **barra de experiência**.
- Quem **já disputou a regional** antes começa com alguma experiência.
- Experiência e atributos definem o quanto o jogador é "conhecido" e quanto ele pede de salário.
- Como a experiência é ganha e quanto ela influencia: **[A DEFINIR]**

### Durante o contrato

- **Renegociação:** se um jogador evolui muito (por exemplo, um iniciante que ganhou muita experiência, mas assinou 2 anos com salário de iniciante), ele pode **pedir revisão do contrato com aumento de salário**.
- Se o pedido não for atendido, ele pode **quebrar o contrato, pagando uma multa, e sair**.
- **Demissão não é livre:** dependendo do contrato, o time não pode simplesmente demitir o jogador. Regras e custo de rescisão: **[A DEFINIR]**
- **Multa rescisória definida no contrato:** negociada na assinatura. Uma multa alta protege o jogador contra outros times, que podem levá-lo pagando esse valor; em troca, o jogador pede mais salário para aceitar uma multa alta.
- **Bônus por desempenho:** em vez de um salário alto, oferecer prêmios por título ou por classificação para o mundial. É mais barato se o time não vencer, mas mais arriscado para o jogador, então nem todos aceitam.

### Fim do contrato e renovação

- Quando o contrato acaba, é possível **renovar, se o jogador quiser**.
- O time pode fazer **ofertas enormes para segurar um jogador importante**, mesmo que nem compensem financeiramente (por exemplo, o melhor jogador da regional, às vésperas do mundial).

**Contrato que vence durante a temporada ou um evento** (responsabilidade do jogador, com redes de segurança):
1. **Dois avisos:** quando faltam **3 meses** e quando falta **1 semana** para o contrato vencer.
2. **O contrato vai até o fim do evento em andamento:** se vence no meio dos playoffs ou do mundial, o jogador fica até o fim da competição e só depois sai.
3. **Contratação emergencial:** se faltar gente, dá para contratar jogadores sem time a qualquer momento. Os disponíveis costumam ser mais fracos ou mais caros.
4. **Derrota por W.O.:** sem 5 jogadores para entrar em campo, o time perde a partida.

### Trocas e propostas

- **Trocas, compras e propostas só podem ser feitas fora de competições em andamento.**
- Quem propõe a troca pode **oferecer dinheiro junto**.
- O resultado depende do **nível do seu jogador, do nível do jogador rival e do dinheiro oferecido**. Com uma quantia absurdamente grande, é possível trocar um jogador mediano por um ótimo.
- **Os outros times também fazem propostas** pelos seus jogadores, principalmente os que se destacaram. Você pode aceitar, recusar ou fazer uma contraproposta.
- **O jogador precisa aceitar a troca:** ele pode recusar ir para um time com reputação muito menor que a do atual.

### Regras provisórias da implementação (etapa 2)

Definidas pelo Claude para a lógica funcionar; podem ser mudadas pelo dono do projeto. Números em `data/config/contratos.json`, `mercado.json` e `tecnicos.json`.

- **Calendário:** 1 mês = 30 dias. Salários cobrados no primeiro dia de cada mês.
- **Negociação:** cada jogador tem uma **paciência** (iniciantes 4, estrelas 2). Proposta recusada tira 1; proposta muito baixa (abaixo de 60% do esperado) tira 2. Sem paciência, ele encerra a negociação por **15 dias**. Cada recusa vem com uma dica do salário esperado.
- **Tolerância:** iniciantes aceitam até ~15% abaixo do pedido; estrelas, só ~2%.
- **Valor da proposta:** luvas valem um pouco mais que salário (dinheiro na mão) e bônus valem só uma parte do valor (são incertos).
- **Reputação:** jogadores mais famosos que a organização cobram mais.
- **Ego:** a partir de ego 75, o jogador só assina com cláusula de titular.
- **Rescisão:** dispensar custa **metade do salário que ainda seria pago**.
- **Salário atrasado:** se não há dinheiro, nada é pago, o valor acumula, a satisfação de cada jogador cai 15 e a reputação cai 5 por mês.
- **Mercado:** 40 agentes livres (8 por posição); 25% são trocados todo mês.
- **Técnico:** um anúncio por vez; candidatos desistem 14 dias depois de chegar; contratado pelo salário que pede (sem negociação nesta versão).

## 8.12 Economia da organização

- **Verba mensal da liga:** recebida no primeiro dia de cada mês, antes dos salários. **Regional: R$ 12.000; nacional: R$ 30.000** (provisório), multiplicada pela posição na última etapa: **1º lugar recebe 1,5x, último 0,75x** (sem histórico: 1x).
- **Investimento inicial suficiente:** o capital inicial de cada dificuldade precisa permitir montar um time para começar (pelo menos os 5 titulares, mesmo sem reservas no início) e mantê-lo pelos primeiros meses.
  - Custo medido no mercado: 5 titulares medianos da regional ~R$ 12.800/mês; com técnico ~R$ 16.800; elenco completo ~R$ 24.000.
  - **Normal (R$ 80.000):** sustenta 5 titulares + técnico por mais de 1 ano. **Difícil (R$ 40.000):** por uns 8 meses. Com elenco completo, o time precisa vencer ou subir de liga.
- **Empréstimo bancário:** **juros de 5% ao mês**, parcelas fixas.
  - **Prazos:** 3, 6 ou 12 meses. Exemplo: R$ 50.000 em 12x = 12 parcelas de ~R$ 5.641 (~R$ 17.700 de juros). Caro de propósito: é um recurso de emergência.
  - **Limite:** 6 verbas mensais da liga atual (regional: R$ 72.000). Mínimo R$ 5.000. **Um empréstimo por vez.**
  - **Quitar antes:** possível a qualquer momento, pagando o saldo devedor (sem os juros futuros).
  - **Parcela atrasada:** multa de 10% da parcela, a dívida acumula e a reputação cai 3.
  - **Falência:** com **3 parcelas atrasadas** e sem dinheiro para pagar a dívida atrasada, a organização **vai à falência e a carreira termina**.

## 8.13 Times rivais

- **Cada rival tem sua própria gestão:** contrata, renova, dispensa e administra o dinheiro, como o jogador.
- **Quanto maior a dificuldade, melhor a administração dos rivais.**

## 8.14 Experiência e idade

- **Veteranos rendem mais**, principalmente em jogos decisivos, **mas sem tornar os jovens inúteis**:
  - A experiência dá um **bônus pequeno, de no máximo ~4%**, que aparece principalmente em **playoffs e no mundial**.
  - **A idade cobra seu preço:** a partir de ~27 anos, os atributos começam a cair devagar, com o **Micro (reflexo) caindo primeiro** e o **Macro durando mais**.
  - **Jovens** têm potencial, **evoluem mais rápido nos treinos** e pedem salários menores.
  - Resultado: o veterano é a peça segura para o jogo decisivo; o jovem é o investimento que pode virar craque.
- **Ganho de experiência:** sobe com partidas jogadas, mais em playoffs e no mundial. Valores: **[A DEFINIR — balanceamento]**

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
- Detalhes dos acampamentos da selva (posição, reaparição, bônus)
- Técnico: custos e tempos dos anúncios, efeitos do cansaço e duração das férias
- Reputação: outros efeitos e exibição
- Como o conhecimento do meta é exibido e evolui
- Nomes e habilidades dos campeões
- Mundial: vagas por região, séries do play-in e da fase suíça, premiação
- Contratos: ganho de experiência, regras de rescisão
- Ego e lealdade: valores e velocidade de mudança (balanceamento)
- Treino: duração, custos e ganhos de cada modalidade
