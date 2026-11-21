# MOBA Manager — Documento de Design do Jogo (GDD)

> Documento vivo: registra tudo o que já foi decidido sobre o jogo e o que ainda está em aberto.
> Itens marcados com **[A DEFINIR]** ainda não foram decididos.

Última atualização: 21/11/2026

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
- **Objetivos de mapa** que podem ser disputados ou abandonados (decisão de Macro). Lista de objetivos: **[A DEFINIR]**
- **Campeões** fictícios, com características próprias.
- **Patches:** mudam a força dos campeões e o meta ao longo da temporada.

Como a partida é exibida (visão 2D de cima com bonecos lutando sozinhos, ou narração com estatísticas): **[A DEFINIR]**

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
- Objetivos de mapa do MOBA fictício
- Regras do draft
- Nome do jogo, do MOBA fictício e dos campeões
- Estrutura da liga (quantos times, formato, playoffs, mundial)
- Transferências, contratos e janela de mercado
