# Laboratório de campeões (24–25/11)

Script: `tools/prototipos/laboratorio_campeoes.py`. Conversão e ajustes: `tools/conversao/converter_campeoes.py`.
Dados gerados: `data/campeoes/campeoes.json`. Ajustes individuais: `tools/conversao/ajustes_laboratorio.json`.

Para refazer: `python3 tools/conversao/converter_campeoes.py` e `python3 tools/prototipos/laboratorio_campeoes.py --lutas 1500`.
Para recalibrar: `--calibrar N` (N rodadas; cada rodada leva cerca de 1 minuto e meio).

## 1. O que o laboratório simula

- **Plano 2D abstrato**, passos de 0,1 s, lutas de até 30 s. Cada campeão anda até o alcance, ataca e usa as habilidades quando tem alvo.
- **Escolha de alvo por função** (como um time médio): assassinos procuram os frágeis; tanques e suportes protegem os próprios carregadores e, com controle forte, abrem a luta nos carregadores rivais; atiradores e magos batem no alvo mais fácil ao alcance.
- **Habilidades** com geometria real (linha, cone, área, alvo único), dano por nível e proporções, % de vida, divisão mista, lentidão, atordoamento, escudos, curas, avanços, marcas e custos de mana, energia, fúria ou vida. Projéteis e áreas com aviso podem errar (80% de acerto, menos com aviso longo; na partida real, o Micro decide).
- **Itens** da build recomendada, com atributos e passivas (mesmo modelo do `laboratorio_itens.py`). O Medalhão dos Eternos não acumula entre aliados (vale o maior).
- **Troca de itens pelo rival (Macro médio):** cada item alternativo da ficha ganhou uma condição (`pouca_magia`, `muita_magia`, `critico`, `cura`, `armadura`, `fisico`…). Se o time rival cumpre a condição, a simulação troca o item.
- **Momentos da partida:** início (nível 6, só a bota), meio (nível 10, bota + 2 itens) e fim (nível 16, bota + 4 itens).
- **Cenários:** luta 5x5 (metade perto de Hydra ou Cérbero), peso 85%; rota dupla atirador + suporte, peso 15%. O duelo 1x1 até a morte ficou só como informação: ele é binário demais e a fase de rotas real é de farm e trocas curtas.

## 2. Passivas: o que a simulação executa

| Campeão | Passiva | Na simulação |
|---|---|---|
| Orvante | Parede de lastro | Completa: escudo de 8% ao receber dano parado há 0,7 s |
| Bruméria | Círculos de abrigo | Escudo da especial completo. Os anéis vêm do momento da partida (0, 2, 5) em vez de serem contados luta a luta |
| Dorsálio | Chão de volta | Completa |
| Calzugo | Debandada presa | Completa: fúria, perda fora de combate, redução de dano e os três efeitos de barra cheia |
| Vedrassa | Batente de emergência | Completa, com a distância de 360 |
| Ravíneo | Ponto cego | Completa, com isolamento por distância real (425). Dispara pouco na luta 5x5, como esperado |
| Téssari | Corda sob tensão | Completa: combo e marca exigida pela especial |
| Nalcora | Solda de entrada | Completa: 3 s sem combate antes do lançamento |
| Iscavro | Calor de retorno | Completa: cura ao encher e execução da especial só com barra cheia |
| Mirfuso | Cobrança por isolamento | Completa, com distância real (440). Quase nunca dispara na luta 5x5: é uma passiva de rota lateral |
| Kordume | Quilha na espuma | Completa |
| Marulva | Ponto de restituição | Completa |
| Trisquilo | Contraponto das ferramentas | Completa. A simulação segura a 2ª habilidade até a 1ª acertar |
| Vardilha | Primeira estaca | O escudo dispara nas lutas perto de objetivo épico. A revelação da entrada (visão) fica para a partida real |
| Eirafim | Enxerto de duelo | Cura completa. Os brotos vêm do momento da partida (0, 2, 5) |
| Velúria | Arquivo de rajadas | Completa. As fichas acumuladas antes da luta vêm do momento da partida |
| Cintarro | Piso interditado | Aproximada: a erupção sai se o alvo ainda estiver a menos de 110 do ponto do acerto após 0,8 s |
| Perlívia | Rachadura devolvida | Completa |
| Prismora | Sobreposição de lentes | Completa |
| Fulgavéu | Passagem sinalizada | Escudos completos ao usar a especial no começo da luta. A visão fica para a partida real |
| Sutéria | Ponto de urgência | Completa |
| Alvenora | Emenda partilhada | Escudo secundário completo. As emendas vêm do momento da partida |
| Luminela | Linha de retransmissão | Completa |
| Clavento | Chave de escolta | Completa |
| Ocravia | Retícula de guarda | Aproximada: o reforço vale nos 3 s após a Baliza de Cal, sem conferir a posição do aliado na área |
| Terralume | Clarão de amostra | Completa |
| Zarcavil | Pressão de roldana | Completa |
| Riscavela | Camadas de verniz | Descarga completa. As camadas vêm do momento da partida |
| Fulcrim | Câmara seca | Completa |
| Treválio | Risco de esquadro | Completa |

Efeitos de habilidade que a luta ainda não usa: redução de empurrões (Orvante), bônus curto de movimento (Fulcrim), visão (Fulgavéu, Ocravia) e o avanço lateral do Mirfuso. Eles entram na partida real (mapa, visão e perseguições).

## 3. O que foi corrigido na conversão

1. **Correção de orçamento.** O guia mandava a rotação completa (com a especial) ficar perto do combo da classe, mas o laboratório de itens disparava esse combo a cada ~7 s. No uso contínuo, as duas básicas entregavam cerca de metade do previsto. Agora as básicas e a passiva entregam, a cada 7 s, o orçamento do campeão × o combo da classe. A especial não muda. O guia foi corrigido (seção 3.2).
2. **Correção por classe.** Mesmo assim, a luta 5x5 mostrou diferenças por classe:
   - magos venciam 52% no início e 36% no fim (o poder mágico dos itens é baixo, cerca de 300 com 4 itens);
   - atiradores passavam de 62% no fim (dano × crítico × velocidade cresce multiplicado);
   - assassinos ficavam em 39% no início.
   A correção mexe nas proporções dos magos, no crescimento de dano e velocidade dos atiradores, no dano inicial dos assassinos, nos escudos e curas dos suportes e na vida e no dano dos tanques. Os valores estão em `CORRECAO_CLASSE` no conversor.
3. **Ajuste individual em dois botões:**
   - `inicio`: dano de nível 1 e ganho por nível, ou seja, o que vale sem itens;
   - `fim`: proporções de dano físico bônus e poder mágico, ou seja, o que cresce com itens.

   Os dois botões também mexem em atributos, conforme a classe. Ficam entre 0,5 e 2,0 e foram calibrados em 14 rodadas de 1.500 lutas 5x5 por momento.
4. **Cintarro:** a base da Poeira de escória subiu (92 em vez de 74,9) e o ganho por nível caiu (3,6 em vez de 4,77), como combinado. As correções seguintes partem desses valores.
5. **Mecânica estruturada:** cada habilidade e passiva ganhou o bloco `mecanica` (alcance, área, lentidão, atordoamento, escudo, cura, gatilho da passiva…). Os textos do GPT não mudaram, e a interface não recebe esse bloco.

Fatores aplicados por campeão (correção de orçamento das básicas; botões inicio / fim):

| Campeão | Classe | Orçamento das básicas | Botões inicio / fim |
|---|---|---|---|
| Orvante | tanque | 1,76 | 1,34 / 0,50 (limite) |
| Bruméria | tanque | 1,64 | 0,54 / 2,00 (limite) |
| Dorsálio | tanque | 2,17 | 1,05 / 2,00 (limite) |
| Calzugo | tanque | 1,49 | 2,00 / 0,55 (limite) |
| Vedrassa | tanque | 1,32 | 0,57 / 2,00 (limite) |
| Ravíneo | assassino | 1,99 | 1,19 / 0,85 |
| Téssari | assassino | 2,09 | 0,84 / 2,00 (limite) |
| Nalcora | assassino | 1,50 | 0,77 / 0,88 |
| Iscavro | assassino | 1,64 | 0,58 / 0,50 (limite) |
| Mirfuso | assassino | 1,91 | 1,39 / 2,00 (limite) |
| Kordume | lutador | 1,96 | 1,05 / 0,50 (limite) |
| Marulva | lutador | 1,94 | 0,87 / 2,00 (limite) |
| Trisquilo | lutador | 1,79 | 1,81 / 0,78 |
| Vardilha | lutador | 1,66 | 1,17 / 1,04 |
| Eirafim | lutador | 1,80 | 0,90 / 1,26 |
| Velúria | mago | 1,70 | 0,61 / 0,88 |
| Cintarro | mago | 1,91 | 1,34 / 2,00 (limite) |
| Perlívia | mago | 1,51 | 0,74 / 1,27 |
| Prismora | mago | 1,47 | 0,50 / 1,98 (limite) |
| Fulgavéu | mago | 1,07 | 0,64 / 1,56 |
| Sutéria | suporte | 1,09 | 1,31 / 0,63 |
| Alvenora | suporte | 1,05 | 1,21 / 1,34 |
| Luminela | suporte | 1,00 | 1,36 / 2,00 (limite) |
| Clavento | suporte | 1,43 | 0,95 / 0,50 (limite) |
| Ocravia | suporte | 0,97 | 2,00 / 1,86 (limite) |
| Terralume | atirador | 2,07 | 1,14 / 0,50 (limite) |
| Zarcavil | atirador | 1,17 | 0,98 / 1,12 |
| Riscavela | atirador | 1,17 | 1,02 / 1,26 |
| Fulcrim | atirador | 1,51 | 1,02 / 1,55 |
| Treválio | atirador | 1,52 | 1,17 / 0,50 (limite) |

## 4. Resultado

```
== Taxa de vitória por momento (luta 5x5 85%, rota dupla 15%) — 1500 lutas 5x5 por momento

Campeão    Classe    Curva     Início   Meio    Fim  Geral  Fora do alvo
Ravíneo    assassino inicio     53.7%  45.2%  46.0%  48.0%  meio
Nalcora    assassino inicio     55.2%  38.4%  41.9%  44.5%  meio
Fulcrim    atirador  inicio     58.2%  46.2%  46.9%  50.0%  meio
Kordume    lutador   inicio     55.2%  48.9%  51.4%  51.5%  fim
Vardilha   lutador   inicio     58.3%  44.6%  42.5%  48.1%  meio
Cintarro   mago      inicio     59.4%  50.5%  48.8%  52.7%  inicio
Sutéria    suporte   inicio     64.0%  44.2%  50.5%  52.0%  inicio, meio, fim
Clavento   suporte   inicio     48.5%  67.7%  58.9%  59.3%  inicio, meio, fim
Orvante    tanque    inicio     55.0%  51.8%  49.8%  52.2%  fim
Calzugo    tanque    inicio     55.0%  49.0%  50.2%  51.2%  fim
Mirfuso    assassino constante  46.4%  48.0%  45.6%  46.8%  fim
Zarcavil   atirador  constante  47.1%  42.8%  52.0%  46.8%  meio
Treválio   atirador  constante  51.4%  47.1%  56.7%  51.2%  fim
Trisquilo  lutador   constante  52.5%  53.3%  52.0%  52.7%  
Perlívia   mago      constante  46.3%  54.3%  49.6%  50.5%  meio
Fulgavéu   mago      constante  44.4%  56.9%  43.2%  49.0%  inicio, meio, fim
Luminela   suporte   constante  46.2%  51.0%  48.4%  48.8%  
Ocravia    suporte   constante  47.6%  50.9%  48.9%  49.3%  
Dorsálio   tanque    constante  51.8%  48.0%  46.0%  48.5%  fim
Vedrassa   tanque    constante  52.6%  45.0%  36.3%  44.7%  meio, fim
Téssari    assassino fim        41.6%  51.2%  48.1%  47.4%  fim
Iscavro    assassino fim        39.4%  58.2%  55.8%  51.8%  inicio, meio
Terralume  atirador  fim        42.9%  55.3%  55.5%  51.7%  meio
Riscavela  atirador  fim        55.7%  45.1%  54.6%  51.1%  inicio
Marulva    lutador   fim        48.0%  51.8%  52.7%  50.9%  
Eirafim    lutador   fim        43.7%  49.0%  49.9%  47.7%  fim
Velúria    mago      fim        45.0%  50.5%  52.9%  49.6%  
Prismora   mago      fim        53.2%  59.3%  50.8%  54.9%  inicio, meio, fim
Alvenora   suporte   fim        41.2%  42.5%  57.2%  46.5%  meio
Bruméria   tanque    fim        43.2%  49.3%  53.0%  48.6%  

Momentos fora do alvo (±4 pontos): 34 de 90

== Média por classe
  tanque    início  51.5%  meio  48.6%  fim  47.1%
  assassino início  47.3%  meio  48.2%  fim  47.5%
  lutador   início  51.6%  meio  49.5%  fim  49.7%
  mago      início  49.6%  meio  54.3%  fim  49.1%
  suporte   início  49.5%  meio  51.2%  fim  52.8%
  atirador  início  51.0%  meio  47.3%  fim  53.1%

== Média por curva
  inicio    início  56.2%  meio  48.6%  fim  48.7%
  constante início  48.6%  meio  49.7%  fim  47.9%
  fim       início  45.4%  meio  51.2%  fim  53.1%
```

**Valor de nível** (mesmo campeão e mesmos itens no nível 10; sem erros de habilidade; força = raiz da razão dos tempos para matar):
- 1 nível a mais dá cerca de **+6 a +8% de força**;
- 2 níveis a mais dão cerca de **+12 a +23%**.

É o mesmo valor que o protótipo de ritmo usava (7,5% por nível). **Decisão para a etapa 5:** quando a partida usar os atributos dos campeões por nível, ela **não** soma o bônus genérico de 7,5% por nível, porque isso contaria o nível duas vezes.

## 5. Pontos pendentes do laboratório de itens

- **Orbe da Tempestade:** trocar a Orbe entra ou sai da build dos 5 magos muda a taxa de vitória em ±2 a 4 pontos, dentro do ruído. **Não é mais item obrigatório.**
- **Itens de poder mágico do suporte:** trocar Lanterna, Coroa, Véu e Tocha por itens de defesa dá resultado misto (de −3 a +8 pontos por campeão, média perto de zero). Com escudos e curas que crescem com o PM, os itens de PM do suporte **passaram a valer o mesmo que os de defesa**.

## 6. O que ainda está fora do alvo

O erro médio parou em ~4 pontos por momento (o ruído da medição é de ~2). A maioria dos campeões fica entre 46% e 53% no geral, e as médias por curva vão na direção certa. Fora disso:

| Campeão | Situação | Por que o ajuste de números não resolve |
|---|---|---|
| **Clavento** | Forte (~59%; 66 a 69% no meio) | A força vem do controle em área e do avanço, não do dano. O botão de dano já está no mínimo |
| **Prismora** | Forte no início e no meio (~55%) | Alcance longo (850 e 1080) e área. O botão `inicio` já está no mínimo |
| **Vedrassa** | Fraca no fim (36%) | Tanque de suporte com pouco dano e escudo pequeno no fim |
| **Nalcora** | Fraca no meio e no fim (~44%) | Assassina de dano misto que morre cedo na luta 5x5 |

Para esses quatro, a correção precisa mexer no kit: duração de controle, alcance ou tamanho de escudo. Isso muda o texto das fichas, então depende do dono do projeto e do GPT.

Campeões com botão no limite (0,5 ou 2,0) são candidatos a revisão de kit no primeiro patch.

## 7. Atualização de 25/11: proposta de kits nº 1 aprovada

O dono aprovou a proposta (`docs/balanceamento/proposta_kits_1.md`). As mecânicas novas entraram no conversor e o laboratório recalibrou:
- os quatro campeões da proposta (5 rodadas, botões entre 0,3 e 3,0);
- Téssari, Bruméria, Marulva e Orvante, que tinham ficado mais longe do alvo (4 rodadas).

Resultado com 1.500 lutas 5x5 por momento:

```
Campeão    Classe    Curva     Início   Meio    Fim  Geral  Fora do alvo
Ravíneo    assassino inicio     54.8%  46.9%  46.8%  49.2%  meio
Nalcora    assassino inicio     56.6%  46.5%  45.1%  49.1%  meio
Fulcrim    atirador  inicio     60.2%  48.1%  47.2%  51.5%  inicio
Kordume    lutador   inicio     49.3%  51.4%  47.1%  49.5%  inicio
Vardilha   lutador   inicio     52.8%  50.1%  42.9%  48.8%  
Cintarro   mago      inicio     58.6%  52.6%  43.1%  51.6%  
Sutéria    suporte   inicio     56.0%  46.0%  48.9%  49.9%  meio
Clavento   suporte   inicio     55.1%  53.8%  51.5%  53.5%  fim
Orvante    tanque    inicio     51.8%  46.9%  48.9%  49.0%  meio
Calzugo    tanque    inicio     53.8%  48.8%  48.7%  50.3%  
Mirfuso    assassino constante  51.2%  44.6%  45.5%  46.9%  meio, fim
Zarcavil   atirador  constante  48.0%  41.7%  50.8%  46.3%  meio
Treválio   atirador  constante  51.1%  45.7%  48.4%  48.1%  meio
Trisquilo  lutador   constante  48.2%  51.0%  52.1%  50.5%  
Perlívia   mago      constante  54.3%  49.5%  49.4%  50.9%  inicio
Fulgavéu   mago      constante  46.6%  58.4%  44.0%  50.6%  meio, fim
Luminela   suporte   constante  47.1%  52.0%  44.2%  48.2%  fim
Ocravia    suporte   constante  47.0%  51.6%  51.5%  50.2%  
Dorsálio   tanque    constante  54.7%  46.8%  47.0%  49.3%  inicio
Vedrassa   tanque    constante  49.2%  51.8%  47.0%  49.6%  
Téssari    assassino fim        45.8%  48.1%  54.5%  49.3%  
Iscavro    assassino fim        41.3%  54.5%  54.1%  50.4%  meio
Terralume  atirador  fim        46.0%  53.1%  58.9%  52.7%  meio
Riscavela  atirador  fim        52.8%  47.1%  55.3%  51.3%  inicio
Marulva    lutador   fim        46.9%  58.3%  52.1%  53.0%  meio
Eirafim    lutador   fim        45.1%  51.0%  55.0%  50.4%  
Velúria    mago      fim        43.1%  51.3%  52.9%  49.3%  
Prismora   mago      fim        41.3%  56.0%  52.4%  50.5%  meio
Alvenora   suporte   fim        45.7%  45.3%  57.0%  48.9%  
Bruméria   tanque    fim        50.9%  48.9%  54.1%  51.0%  inicio

Momentos fora do alvo (±4 pontos): 22 de 90

== Média por classe
  tanque    início  52.1%  meio  48.6%  fim  49.1%
  assassino início  49.9%  meio  48.1%  fim  49.2%
  lutador   início  48.4%  meio  52.4%  fim  49.9%
  mago      início  48.8%  meio  53.6%  fim  48.4%
  suporte   início  50.2%  meio  49.7%  fim  50.6%
  atirador  início  51.6%  meio  47.1%  fim  52.1%
```

- **Fora do alvo:** 22 de 90 momentos (antes eram 26 a 34).
- **No geral:** todos os campeões entre 46% e 54% de vitória.
- **Botões no limite (0,3 ou 3,0):** o botão de dano da Vedrassa (força agora vem da divisão de dano) e o botão "fim" do Clavento (o dano dele quase não pesa). São candidatos a revisão de kit no próximo patch, se a partida real confirmar.
