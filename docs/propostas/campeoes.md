# Proposta de campeões de Crystal Legends

## Elenco aprovado

São 30 campeões, cinco por classe e seis por posição principal. As curvas se dividem em dez campeões de início, dez de fim e dez constantes. Há 19 campeões com mana, quatro com energia, três com fúria, dois com vida e dois sem recurso. A primeira posição de cada ficha indica a principal.

A proposta usa a versão do [guia de campeões](../GUIA_CAMPEOES.md) do commit `33e7921` e os nomes do [catálogo de itens](../../data/itens/itens.json). Os números são ponto de partida para a conversão em dados. O laboratório original mediu campeões genéricos e uma habilidade combinada por ciclo. Alcance, mana, cura de aliados e efeitos separados ainda precisam passar pelo laboratório com estes kits.

## Convenções para leitura das fichas

- **Níveis e recargas.** As duplas de números em atributos, dano e recurso indicam o valor de nível 1 e o ganho por nível acima dele, até o nível 16. Na velocidade de ataque, o segundo número é o crescimento percentual aditivo sobre o valor de nível 1. As recargas estão em segundos antes da aceleração. A cadência da seção 3.2 orienta as duas básicas. A terceira habilidade é a especial, entra no nível 6 e tem seu próprio intervalo mais longo. A checagem de rotação avalia um uso de cada habilidade quando a especial está disponível.
- **Recursos.** Em kits de mana, `custo` indica o valor inicial. Multiplique pela razão entre a mana máxima natural do nível atual e a do nível 1, e arredonde cada habilidade para o inteiro mais próximo, com meio ponto para cima. A rotação fica em 25–35% da barra em todos os níveis. A regeneração do guia foi preservada. Por decisão aprovada, recuperar uma rotação em 20–30 s fica para o balanceamento, pois entra em conflito com as faixas de mana e custo vigentes. Energia fica em 200 e volta a 10 por segundo. Fúria tem barra de 100, inicia vazia e segue a regra de cada passiva. O efeito de barra cheia usa o valor antes do gasto. Em kits de vida, `custo` é o percentual da vida máxima atual, incluindo itens. O recurso acompanha a própria vida e a habilidade exige vida suficiente para pagar o custo e continuar vivo. Em kits sem recurso, as recargas já incluem os 15% adicionais.
- **Dano, cura e proteção.** Nas proporções de dano, `0.02` equivale a 2%, `1.10` a 110%. Os efeitos listam as condições de cada parcela. Quando um efeito dá a versão normal e a fortalecida, o campo de dano registra o teto daquela parcela. Em dano misto, a divisão descrita no efeito se aplica ao dano bruto total da habilidade. Cada parcela é mitigada pela resistência correspondente. A parcela de vida perdida é avaliada imediatamente antes do acerto. Parcelas baseadas na vida do alvo usam a vida de campeões, uma vez por alvo por lançamento. Nenhuma delas aumenta dano a estruturas ou objetivos épicos. Dano extra acoplado a um ataque continua no orçamento da habilidade e não repete o efeito de item ou o crítico do ataque básico. Curas seguem a regra de anticura do [modelo de combate](../../data/config/combate.json).
- **Poder de jogador.** Dificuldade é a sensibilidade ao Micro, de 1 a 3. Dependência de Macro mede decisões de chegada, leitura de mapa e preparação das lutas. O crescimento da ficha expressa a curva sobre os atributos da classe. O peso por nível já pertence ao modelo de partida. Convém revisar a aplicação conjunta para evitar cobrar duas vezes a mesma vantagem de nível.
- **Compra.** Cada lista tem uma bota e quatro itens em ordem. Cada alternativa é uma troca individual para a situação descrita. Essa comparação preserva os limites de classe e os grupos de passivas dos itens existentes.

## Conferência de rotação

O orçamento é a fração planejada da referência de dano da classe antes do ajuste de curva. Controles, mobilidade, cura, escudos e visão consomem parte desse orçamento, conforme a seção 3.3. Os números abaixo são dano bruto por alvo, com a bota e dois itens no nível 9 e a bota e quatro no nível 15. Usam a build recomendada. Os valores entre parênteses são as metas que orientaram a calibração.

Para parcela de vida máxima inimiga, usei a vida do lutador de referência do próprio laboratório. Para execução, usei um atirador de referência com 60% de vida perdida e o requisito do kit atendido. Para vida própria, usei os atributos da ficha com a build do nível. O cálculo soma as parcelas de dano das habilidades. Ataques normais e ativações de itens ficam fora dessa soma. O alvo único serve para comparar o orçamento da ficha. Impacto em múltiplos alvos deve ser verificado à parte.

| Campeão | Orçamento | Nível 9 | Nível 15 |
|---|---:|---:|---:|
| Orvante | 65% | 135 (135) | 182 (181) |
| Bruméria | 71% | 142 (135) | 223 (234) |
| Dorsálio | 78% | 168 (156) | 256 (234) |
| Calzugo | 65% | 131 (135) | 185 (181) |
| Vedrassa | 64% | 129 (128) | 192 (192) |
| Ravíneo | 85% | 485 (495) | 652 (640) |
| Téssari | 90% | 496 (479) | 775 (802) |
| Nalcora | 88% | 501 (513) | 675 (663) |
| Iscavro | 92% | 510 (489) | 787 (820) |
| Mirfuso | 85% | 475 (476) | 690 (688) |
| Kordume | 87% | 253 (262) | 350 (340) |
| Marulva | 82% | 234 (226) | 365 (379) |
| Trisquilo | 90% | 261 (261) | 378 (378) |
| Vardilha | 91% | 265 (274) | 368 (355) |
| Eirafim | 84% | 240 (231) | 374 (388) |
| Velúria | 86% | 477 (462) | 803 (832) |
| Cintarro | 62% | 353 (364) | 521 (507) |
| Perlívia | 80% | 450 (452) | 707 (704) |
| Prismora | 88% | 504 (472) | 790 (852) |
| Fulgavéu | 73% | 413 (412) | 643 (642) |
| Sutéria | 73% | 134 (133) | 197 (197) |
| Alvenora | 71% | 128 (118) | 205 (226) |
| Luminela | 66% | 115 (116) | 193 (191) |
| Clavento | 60% | 110 (109) | 161 (162) |
| Ocravia | 65% | 114 (114) | 187 (188) |
| Terralume | 91% | 139 (134) | 266 (275) |
| Zarcavil | 92% | 143 (143) | 253 (253) |
| Riscavela | 90% | 139 (133) | 255 (272) |
| Fulcrim | 92% | 153 (148) | 228 (235) |
| Treválio | 91% | 153 (141) | 227 (250) |

Foram conferidos 300 valores de atributos base e crescimento, as 91 substituições de itens e os limites de mana e dano percentual. O maior desvio observado entre dano da ficha e meta de orçamento foi de 9,6%. As duas habilidades com dano verdadeiro também foram verificadas nos 16 níveis com as builds recomendadas e cada troca individual.

## Pontos para a próxima simulação

- Medir a diferença entre ter e perder a especial. Sutéria, Alvenora e Luminela trocam dano por janelas de proteção, e Fulgavéu troca dano por visão. A frequência real de cura, escudo e visão deve pesar na avaliação dessas builds.
- Verificar se ordens de compra divergem na prática. Terralume favorece crítico, Zarcavil valoriza permanência no alvo com ataques rápidos e Riscavela aproveita os efeitos ao acertar de dano misto. Para magos, comparar desgaste com Tocha do Tormento, escalamento com Grimório Cristalino e a primeira troca com Orbe da Tempestade.
- Medir sustento com e sem anticura em Marulva e Perlívia, com atenção à vida gasta quando a habilidade erra. Testar entrada de luta com barra de fúria vazia em Calzugo, Iscavro e Kordume, além das janelas que energia impede usar as três habilidades imediatamente.
- Medir dano por vida em alvos frágeis, lutadores e tanques. A comparação com habilidades separadas deve observar a frequência das passivas de itens. O laboratório aplicava o Martelo das Montanhas uma vez por ciclo combinado. Na ficha, evitei recomendá-lo para os kits com dano próprio pela vida máxima inimiga.
- Comparar os campeões de início e de fim no nível 6 e no 16, em vez de avaliar só a foto de quatro itens. Medir taxa de acerto por Micro e qualidade de rotação por Macro. Em dano verdadeiro, checar também o resultado depois das resistências. A faixa de 20% foi conferida sobre a rotação bruta.

## Fichas

### Orvante, o mestre das comportas

```json
{
  "id": "orvante",
  "nome": "Orvante",
  "titulo": "o mestre das comportas",
  "classe": "tanque",
  "posicoes": ["topo"],
  "tema": "Mestre das comportas de um porto elevado, Orvante carrega duas folhas de bronze unidas por cabos. A silhueta larga e os contrapesos alaranjados denunciam quando ele vai fechar uma passagem.",
  "curva_de_forca": "inicio",
  "dificuldade": 2,
  "dependencia_macro": 2,
  "recurso": {
    "tipo": "mana",
    "maximo": [330, 24],
    "regeneracao_5s": [7, 0.5]
  },
  "atributos": {
    "vida": [706, 96.19],
    "armadura": [41, 4.35],
    "resistencia_magica": [30, 1.8],
    "dano_fisico": [58, 3.15],
    "velocidade_ataque": [0.645, 2.3],
    "alcance": 125,
    "velocidade_movimento": 335
  },
  "passiva": {
    "nome": "Lastro cravado",
    "descricao": "Orvante firma os pés antes de segurar uma entrada.",
    "efeito": "Ao permanecer 1,2 s sem se deslocar, ganha 8% de resistência a deslocamentos por 2 s. O efeito só rearma após andar 200 unidades. Não reduz atordoamentos."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Cunha de bronze",
      "descricao": "Bate com a placa de lado e reduz o passo de quem acertar.",
      "narracao": "{campeao} fecha o passo com uma cunha de bronze!",
      "tipo_dano": "magico",
      "alvo": "cone",
      "dano": {
        "base": [25, 2.53],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.01207
        }
      },
      "custo": 26,
      "recarga": 8,
      "efeitos": ["Cone de alcance 310 e abertura 65°", "Lentidão de 25% por 1,5 s"],
      "tags": ["controle"]
    },
    {
      "posicao": 2,
      "nome": "Contrapeso de ombro",
      "descricao": "Prende uma placa junto ao peito para absorver o primeiro impacto.",
      "narracao": "{campeao} encaixa o contrapeso e fecha a guarda!",
      "tipo_dano": "magico",
      "alvo": "si_mesmo",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 25,
      "recarga": 9,
      "efeitos": [
        "Escudo em si de 5% da própria vida máxima por 2 s",
        "Não acumula com outro escudo de Contrapeso de Ombro"
      ],
      "tags": ["escudo"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Fechar a eclusa",
      "descricao": "Fecha duas folhas de bronze sobre um ponto do terreno.",
      "narracao": "{campeao} fecha a eclusa e segura os adversários!",
      "tipo_dano": "magico",
      "alvo": "area",
      "dano": {
        "base": [19, 1.99],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.00949
        }
      },
      "custo": 48,
      "recarga": 68,
      "efeitos": [
        "Área de raio 185 a até 475 de alcance",
        "Aviso de 0,65 s antes de atingir",
        "Atordoa por 0,85 s",
        "Disponível a partir do nível 6."
      ],
      "tags": [
        "controle",
        "area",
        "engaje"
      ]
    }
  ],
  "build_recomendada": [
    "Grevas de Ferro",
    "Égide de Aço",
    "Coração do Titã",
    "Medalhão dos Eternos",
    "Armadura Viva de Cristal"
  ],
  "itens_alternativos": [
    {
      "item": "Escudo do Guardião",
      "quando": "contra explosão mágica antes de conseguir abrir a luta",
      "substitui": "Armadura Viva de Cristal"
    },
    {
      "item": "Couraça do Gigante de Pedra",
      "quando": "contra dois carregadores de crítico, priorizando sobreviver na frente",
      "substitui": "Medalhão dos Eternos"
    },
    {
      "item": "Botas do Andarilho",
      "quando": "contra equipes que cedem entradas quando você chega primeiro",
      "substitui": "Grevas de Ferro"
    }
  ],
  "forte_contra": "Adversários de alcance curto que precisam atravessar uma entrada estreita.",
  "fraco_contra": "Desgaste de longo alcance e equipes que espalham a luta por duas entradas."
}
```

### Bruméria, a guardiã do abrigo móvel

```json
{
  "id": "brumeria",
  "nome": "Bruméria",
  "titulo": "a guardiã do abrigo móvel",
  "classe": "tanque",
  "posicoes": ["selva", "topo"],
  "tema": "Uma cartógrafa de correntezas conduz um abrigo de cerâmica montado sobre seis patas de latão. Ela leva na carapaça anéis dos lugares que protegeu.",
  "curva_de_forca": "fim",
  "dificuldade": 2,
  "dependencia_macro": 3,
  "recurso": {
    "tipo": "mana",
    "maximo": [330, 24],
    "regeneracao_5s": [7, 0.5]
  },
  "atributos": {
    "vida": [607, 124.54],
    "armadura": [36, 5.61],
    "resistencia_magica": [34, 2.18],
    "dano_fisico": [56, 3.94],
    "velocidade_ataque": [0.595, 2.7],
    "alcance": 125,
    "velocidade_movimento": 330
  },
  "passiva": {
    "nome": "Anéis de abrigo",
    "descricao": "Bruméria reforça o abrigo ao segurar a linha de frente.",
    "efeito": "Quando Vedação de Campo absorve pelo menos 60 de dano de campeão, ganha um anel. Intervalo de 40 s entre anéis, até 5. Cada anel adiciona 0,2 ponto percentual da vida máxima àquele escudo. Sem ganho de atributos base."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Pó de cerâmica",
      "descricao": "Semeia pó áspero para afastar rivais de um ponto.",
      "narracao": "{campeao} cobre a passagem de pó de cerâmica!",
      "tipo_dano": "magico",
      "alvo": "area",
      "dano": {
        "base": [10, 4.54],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.01279
        }
      },
      "custo": 31,
      "recarga": 8,
      "efeitos": [
        "Alcance 420, raio 150",
        "Lentidão de 25% por 1,8 s",
        "Atinge uma vez e não interrompe habilidades"
      ],
      "tags": ["controle"]
    },
    {
      "posicao": 2,
      "nome": "Vedação de campo",
      "descricao": "A vedação do casco segura o dano enquanto ela permanece na linha de frente.",
      "narracao": "{campeao} sela o abrigo e aguenta o impacto!",
      "tipo_dano": "magico",
      "alvo": "si_mesmo",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 23,
      "recarga": 9,
      "efeitos": ["Escudo em si de 4% da própria vida máxima por 3 s", "Os anéis aumentam este valor até 5%"],
      "tags": [
        "escudo",
        "vida_propria",
        "acumulo_limitado"
      ]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Abrigo de maré",
      "descricao": "Apoia todo o casco no chão e empurra a briga para longe dos aliados.",
      "narracao": "{campeao} finca o abrigo e cobre a retirada!",
      "tipo_dano": "magico",
      "alvo": "area",
      "dano": {
        "base": [7, 3.43],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.00965
        }
      },
      "custo": 45,
      "recarga": 78,
      "efeitos": [
        "Raio 235 ao redor de Bruméria",
        "Causa dano uma vez na abertura",
        "Aliados no raio recebem 8% de redução de dano por 1,6 s. A proteção termina ao saírem",
        "Disponível a partir do nível 6."
      ],
      "tags": ["protecao", "zona"]
    }
  ],
  "build_recomendada": [
    "Grevas de Ferro",
    "Coração do Titã",
    "Armadura Viva de Cristal",
    "Égide de Aço",
    "Escudo do Guardião"
  ],
  "itens_alternativos": [
    {
      "item": "Medalhão dos Eternos",
      "quando": "contra abertura em área que ameaça vários aliados juntos",
      "substitui": "Égide de Aço"
    },
    {
      "item": "Manto dos Ventos Gélidos",
      "quando": "contra dano dividido entre físico e mágico e rivais de ataques rápidos",
      "substitui": "Armadura Viva de Cristal"
    },
    {
      "item": "Couraça do Gigante de Pedra",
      "quando": "contra crítico concentrado e pouco dano mágico",
      "substitui": "Escudo do Guardião"
    }
  ],
  "forte_contra": "Equipes que precisam gastar uma primeira rotação para desalojar a linha de frente.",
  "fraco_contra": "Equipes que queimam proteção e recuam, ou que finalizam objetivos antes de ela chegar."
}
```

### Dorsálio, o demolidor de costelas

```json
{
  "id": "dorsalio",
  "nome": "Dorsálio",
  "titulo": "o demolidor de costelas",
  "classe": "tanque",
  "posicoes": ["topo"],
  "tema": "Um trabalhador de mina costeira maneja um aríete com costelas de cerâmica articuladas. Ele abre fendas estreitas para ninguém precisar escavar parede inteira.",
  "curva_de_forca": "constante",
  "dificuldade": 1,
  "dependencia_macro": 1,
  "recurso": {
    "tipo": "nenhum",
    "maximo": [0, 0],
    "regeneracao_5s": [0, 0]
  },
  "atributos": {
    "vida": [680, 109.18],
    "armadura": [40, 4.95],
    "resistencia_magica": [31, 2.02],
    "dano_fisico": [58, 3.54],
    "velocidade_ataque": [0.62, 2.5],
    "alcance": 125,
    "velocidade_movimento": 335
  },
  "passiva": {
    "nome": "Pé de mina",
    "descricao": "Dorsálio se recompõe quando resiste à primeira investida.",
    "efeito": "Após 3 s consecutivos em combate contra campeão, recupera 20 + 2 por nível além do primeiro ao longo de 3 s. Intervalo de 18 s desde o início da recuperação. Cura afetada por anticura."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Fenda estreita",
      "descricao": "Enfia a cabeça do aríete numa linha curta.",
      "narracao": "{campeao} abre uma fenda na linha de frente!",
      "tipo_dano": "magico",
      "alvo": "linha",
      "dano": {
        "base": [10, 1.08],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0.018,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.00782
        }
      },
      "custo": 0,
      "recarga": 9.2,
      "efeitos": [
        "Alcance 360, largura 75",
        "Atinge só o primeiro campeão na linha",
        "O dano percentual se aplica a campeões. Em monstros, vale apenas o dano base e suas proporções de atributos"
      ],
      "tags": ["antitanque"]
    },
    {
      "posicao": 2,
      "nome": "Trava de pedreira",
      "descricao": "Abre as costelas do aríete para amortecer o próximo impacto.",
      "narracao": "{campeao} ancora o aríete e absorve o impacto!",
      "tipo_dano": "magico",
      "alvo": "si_mesmo",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 0,
      "recarga": 9.2,
      "efeitos": ["Escudo em si de 4% da própria vida máxima por 2 s"],
      "tags": ["escudo", "vida_propria"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Quebra da galeria",
      "descricao": "Quebra a escora à frente do rival e abre espaço para dar mais um passo.",
      "narracao": "{campeao} derruba a escora diante de {alvo}!",
      "tipo_dano": "magico",
      "alvo": "unico",
      "dano": {
        "base": [11, 1.26],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0.021,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.00918
        }
      },
      "custo": 0,
      "recarga": 80.5,
      "efeitos": [
        "Alcance 285",
        "Lentidão de 30% por 2 s",
        "O dano percentual se aplica a campeões",
        "Disponível a partir do nível 6."
      ],
      "tags": ["antitanque", "controle"]
    }
  ],
  "build_recomendada": [
    "Grevas de Ferro",
    "Coração do Titã",
    "Armadura Viva de Cristal",
    "Escudo do Guardião",
    "Manto dos Ventos Gélidos"
  ],
  "itens_alternativos": [
    {
      "item": "Égide de Aço",
      "quando": "contra cura sustentada de rivais que atacam a linha de frente",
      "substitui": "Manto dos Ventos Gélidos"
    },
    {
      "item": "Couraça do Gigante de Pedra",
      "quando": "contra crítico sem ameaça mágica relevante",
      "substitui": "Escudo do Guardião"
    },
    {
      "item": "Medalhão dos Eternos",
      "quando": "quando é mais importante proteger o time da abertura",
      "substitui": "Armadura Viva de Cristal"
    }
  ],
  "forte_contra": "Linha de frente de vida alta que aceita trocas prolongadas no corpo a corpo.",
  "fraco_contra": "Atiradores de alcance longo e equipes que recusam contato direto."
}
```

### Calzugo, o rancheiro do estuário

```json
{
  "id": "calzugo",
  "nome": "Calzugo",
  "titulo": "o rancheiro do estuário",
  "classe": "tanque",
  "posicoes": ["selva"],
  "tema": "Criador de animais dunares, Calzugo traz um arreio de ombro com sinos de barro. Os sinos batem conforme a pressão da disputa aumenta.",
  "curva_de_forca": "inicio",
  "dificuldade": 2,
  "dependencia_macro": 3,
  "recurso": {
    "tipo": "furia",
    "maximo": [100, 0],
    "regeneracao_5s": [0, 0]
  },
  "atributos": {
    "vida": [700, 96.43],
    "armadura": [40, 4.41],
    "resistencia_magica": [30, 1.8],
    "dano_fisico": [58, 3.14],
    "velocidade_ataque": [0.645, 2.3],
    "alcance": 125,
    "velocidade_movimento": 340
  },
  "passiva": {
    "nome": "Guizo de desafio",
    "descricao": "Atacar e apanhar carrega o arreio de Calzugo.",
    "efeito": "Ganha 12 de fúria no ataque básico e 8 ao receber um acerto de campeão ou monstro. Até um ganho por categoria por 1 s. Após 4 s sem combate, perde 10 por segundo. Com 100 de fúria antes do gasto, a próxima habilidade recebe o efeito indicado."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Puxão de rédea",
      "descricao": "Joga as rédeas à frente e dificulta a travessia.",
      "narracao": "{campeao} lança as rédeas sobre a passagem!",
      "tipo_dano": "magico",
      "alvo": "cone",
      "dano": {
        "base": [35, 2.85],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.01153
        }
      },
      "custo": 25,
      "recarga": 8,
      "efeitos": [
        "Alcance 305 e abertura 60°",
        "Lentidão de 25% por 1,5 s",
        "Com fúria cheia, a lentidão dura 0,4 s a mais"
      ],
      "tags": ["controle"]
    },
    {
      "posicao": 2,
      "nome": "Poste de parada",
      "descricao": "Crava o poste para absorver o dano de quem chegar primeiro.",
      "narracao": "{campeao} finca o poste no chão!",
      "tipo_dano": "magico",
      "alvo": "si_mesmo",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 20,
      "recarga": 8,
      "efeitos": ["Escudo em si de 4% da própria vida máxima por 2 s", "Com fúria cheia, o escudo sobe a 5%"],
      "tags": ["escudo"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Estouro de guizos",
      "descricao": "Sacode o arreio e desequilibra os rivais que tentam passar.",
      "narracao": "{campeao} bate os guizos e trava a entrada do rio!",
      "tipo_dano": "magico",
      "alvo": "area",
      "dano": {
        "base": [24, 1.9],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.00769
        }
      },
      "custo": 45,
      "recarga": 72,
      "efeitos": [
        "Raio 190, alcance 450, aviso de 0,7 s",
        "Atordoamento de 0,65 s. Com fúria cheia, 0,85 s",
        "Disponível a partir do nível 6."
      ],
      "tags": [
        "controle",
        "area",
        "engaje",
        "rotacao"
      ]
    }
  ],
  "build_recomendada": [
    "Botas do Andarilho",
    "Égide de Aço",
    "Medalhão dos Eternos",
    "Escudo do Guardião",
    "Armadura Viva de Cristal"
  ],
  "itens_alternativos": [
    {
      "item": "Grevas de Ferro",
      "quando": "contra invasões de caçador físico que obrigam a duelar cedo",
      "substitui": "Botas do Andarilho"
    },
    {
      "item": "Coração do Titã",
      "quando": "contra dano misto que favorece mais vida e frequência do escudo",
      "substitui": "Armadura Viva de Cristal"
    },
    {
      "item": "Couraça do Gigante de Pedra",
      "quando": "contra composição de crítico com pouco dano mágico",
      "substitui": "Escudo do Guardião"
    }
  ],
  "forte_contra": "Times sem linha alternativa para entrar no rio quando o arreio está carregado.",
  "fraco_contra": "Caçadores que fingem disputar o objetivo, deixam a fúria acabar e voltam depois."
}
```

### Vedrassa, a porteira de vidro

```json
{
  "id": "vedrassa",
  "nome": "Vedrassa",
  "titulo": "a porteira de vidro",
  "classe": "tanque",
  "posicoes": ["suporte"],
  "tema": "Vedrassa conduz uma porta de vidro fumê apoiada num quadro de madeira. Da fechadura teatral saem linhas claras que o público enxerga de cima.",
  "curva_de_forca": "constante",
  "dificuldade": 1,
  "dependencia_macro": 2,
  "recurso": {
    "tipo": "mana",
    "maximo": [330, 24],
    "regeneracao_5s": [7, 0.5]
  },
  "atributos": {
    "vida": [667, 109.73],
    "armadura": [40, 4.94],
    "resistencia_magica": [33, 1.98],
    "dano_fisico": [56, 3.55],
    "velocidade_ataque": [0.62, 2.5],
    "alcance": 125,
    "velocidade_movimento": 325
  },
  "passiva": {
    "nome": "Um pé na soleira",
    "descricao": "Vedrassa resiste melhor ao primeiro impacto perto do aliado que protege.",
    "efeito": "Ao permanecer até 280 de um aliado por 1 s, amortece em 30 o próximo dano de campeão contra si. Uma vez a cada 18 s. O efeito termina ao se afastar por mais de 1 s."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Soleira de raspão",
      "descricao": "Raspa a moldura no chão para segurar quem se aproxima.",
      "narracao": "{campeao} força o rival a pisar na soleira!",
      "tipo_dano": "magico",
      "alvo": "cone",
      "dano": {
        "base": [22, 4.2],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.01306
        }
      },
      "custo": 25,
      "recarga": 8,
      "efeitos": ["Alcance 315 e abertura 70°", "Lentidão de 25% por 1,5 s"],
      "tags": ["controle"]
    },
    {
      "posicao": 2,
      "nome": "Batente emprestado",
      "descricao": "Reforça a guarda de um aliado exposto.",
      "narracao": "{campeao} põe um batente na frente de {alvo}!",
      "tipo_dano": "magico",
      "alvo": "aliado",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 28,
      "recarga": 8,
      "efeitos": ["Alcance 500", "Escudo de 5% da vida máxima do aliado por 2,5 s"],
      "tags": ["escudo", "aliado"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Última saída",
      "descricao": "Fecha o batente diante do aliado para quebrar a perseguição.",
      "narracao": "{campeao} fecha a passagem na frente de {alvo}!",
      "tipo_dano": "magico",
      "alvo": "area",
      "dano": {
        "base": [14, 2.57],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.008
        }
      },
      "custo": 46,
      "recarga": 74,
      "efeitos": [
        "Escolhe um aliado a até 575 e acerta a área de raio 170 ao redor dele",
        "Aviso de 0,45 s",
        "Atordoa inimigos por 0,7 s. O aliado não se desloca",
        "Disponível a partir do nível 6."
      ],
      "tags": [
        "controle",
        "area",
        "contraengaje"
      ]
    }
  ],
  "build_recomendada": [
    "Sandálias da Sabedoria",
    "Medalhão dos Eternos",
    "Égide de Aço",
    "Escudo do Guardião",
    "Manto dos Ventos Gélidos"
  ],
  "itens_alternativos": [
    {
      "item": "Grevas de Ferro",
      "quando": "contra atirador de ataques básicos e pouco controle",
      "substitui": "Sandálias da Sabedoria"
    },
    {
      "item": "Armadura Viva de Cristal",
      "quando": "contra desgaste misto sem cura relevante, para segurar a frente",
      "substitui": "Égide de Aço"
    },
    {
      "item": "Coração do Titã",
      "quando": "contra rajadas de dano misto que tornam a vida bruta mais útil",
      "substitui": "Manto dos Ventos Gélidos"
    }
  ],
  "forte_contra": "Mergulhos previsíveis sobre um carregador e inimigos que se agrupam para persegui-lo.",
  "fraco_contra": "Ataques alternados em dois aliados distantes e desgaste que força o escudo antes da entrada."
}
```

### Ravíneo, o mestre dos ecos de cobre

```json
{
  "id": "ravineo",
  "nome": "Ravíneo",
  "titulo": "o mestre dos ecos de cobre",
  "classe": "assassino",
  "posicoes": ["selva"],
  "tema": "Um topógrafo de passagens subterrâneas caça pelo eco de uma forquilha de cobre. O traço de sua lâmina desenha uma quebra branca que dura só um instante.",
  "curva_de_forca": "inicio",
  "dificuldade": 3,
  "dependencia_macro": 3,
  "recurso": {
    "tipo": "energia",
    "maximo": [200, 0],
    "regeneracao_5s": [50, 0]
  },
  "atributos": {
    "vida": [564, 90.33],
    "armadura": [29, 3.78],
    "resistencia_magica": [28, 1.17],
    "dano_fisico": [68, 2.87],
    "velocidade_ataque": [0.676, 2.3],
    "alcance": 125,
    "velocidade_movimento": 345
  },
  "passiva": {
    "nome": "Eco solitário",
    "descricao": "Ravíneo localiza rivais longe dos companheiros.",
    "efeito": "Se o alvo de Primeiro Estalo estiver a mais de 425 de qualquer outro campeão de sua equipe, o projétil dessa habilidade viaja 35% mais depressa. Checagem no lançamento. Sem alteração de dano ou alcance."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Primeiro estalo",
      "descricao": "Dispara a forquilha numa linha estreita; acertar cedo abre o abate.",
      "narracao": "{campeao} dispara o primeiro estalo sobre {alvo}!",
      "tipo_dano": "fisico",
      "alvo": "linha",
      "dano": {
        "base": [94, 8.34],
        "proporcoes": {
          "dano_fisico_bonus": 0.964,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 80,
      "recarga": 6.5,
      "efeitos": [
        "Alcance 480, largura 62",
        "Só atinge o primeiro campeão",
        "Concentra a maior fração de dano do kit"
      ],
      "tags": ["explosao", "isolamento"]
    },
    {
      "posicao": 2,
      "nome": "Quina falsa",
      "descricao": "Dá um passo curto na diagonal sem cruzar paredes.",
      "narracao": "{campeao} troca de ângulo com um passo rasante!",
      "tipo_dano": "fisico",
      "alvo": "si_mesmo",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 55,
      "recarga": 7.5,
      "efeitos": ["Avanço de até 285 unidades", "Sem intangibilidade e sem reiniciar ataques"],
      "tags": ["mobilidade"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Câmara de eco",
      "descricao": "Entra no ângulo aberto pelo primeiro golpe e corta o alvo.",
      "narracao": "{campeao} fecha a câmara de eco em {alvo}!",
      "tipo_dano": "fisico",
      "alvo": "unico",
      "dano": {
        "base": [83, 7.39],
        "proporcoes": {
          "dano_fisico_bonus": 0.855,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 80,
      "recarga": 61,
      "efeitos": [
        "Alcance 275, sem avanço embutido",
        "Preparação de 0,35 s. Atinge uma vez",
        "Disponível a partir do nível 6."
      ],
      "tags": ["explosao"]
    }
  ],
  "build_recomendada": [
    "Botas do Caçador",
    "Lâmina do Eclipse",
    "Presa da Serpente",
    "Manto da Noite Eterna",
    "Escudo do Guardião"
  ],
  "itens_alternativos": [
    {
      "item": "Lança Quebra-Escudos",
      "quando": "contra alvos que compram armadura suficiente para reduzir o primeiro golpe",
      "substitui": "Manto da Noite Eterna"
    },
    {
      "item": "Sandálias da Sabedoria",
      "quando": "contra controle e dano mágico que impedem aproximações",
      "substitui": "Botas do Caçador"
    },
    {
      "item": "Sanguessuga Rubra",
      "quando": "contra desgaste físico entre invasões, quando a proteção mágica rende pouco",
      "substitui": "Escudo do Guardião"
    }
  ],
  "forte_contra": "Alvos frágeis separados do time e entradas pela lateral sem visão.",
  "fraco_contra": "Torres de visão, duplas que se protegem e lutadores com armadura."
}
```

### Téssari, a afinadora de tendões

```json
{
  "id": "tessari",
  "nome": "Téssari",
  "titulo": "a afinadora de tendões",
  "classe": "assassino",
  "posicoes": ["meio"],
  "tema": "Téssari percorre cidades de palco em palco regulando cordas cerimoniais. Dois dedais de ferro viram ganchos curtos quando ela muda de ofício.",
  "curva_de_forca": "fim",
  "dificuldade": 3,
  "dependencia_macro": 2,
  "recurso": {
    "tipo": "energia",
    "maximo": [200, 0],
    "regeneracao_5s": [50, 0]
  },
  "atributos": {
    "vida": [552, 113.22],
    "armadura": [28, 4.73],
    "resistencia_magica": [31, 1.44],
    "dano_fisico": [59, 3.71],
    "velocidade_ataque": [0.624, 2.7],
    "alcance": 125,
    "velocidade_movimento": 340
  },
  "passiva": {
    "nome": "Corda de verificação",
    "descricao": "Uma nota bem acertada prepara o corte final.",
    "efeito": "Acertar Tom de Prova põe uma marca visível no campeão por 4 s. A marca só existe em um alvo por vez e é consumida por Corda Rompida. Sem dano próprio ou amplificação."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Tom de prova",
      "descricao": "Lança o primeiro gancho para marcar um rival.",
      "narracao": "{campeao} mede a distância e marca {alvo}!",
      "tipo_dano": "fisico",
      "alvo": "linha",
      "dano": {
        "base": [23, 10.1],
        "proporcoes": {
          "dano_fisico_bonus": 0.423,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 65,
      "recarga": 6.5,
      "efeitos": ["Alcance 455, largura 66", "Marca apenas o primeiro campeão inimigo acertado"],
      "tags": ["precisao", "marca"]
    },
    {
      "posicao": 2,
      "nome": "Mudança de afinação",
      "descricao": "Gira o segundo gancho para abrir caminho sem sair do lugar.",
      "narracao": "{campeao} gira a corda e corta a passagem!",
      "tipo_dano": "fisico",
      "alvo": "cone",
      "dano": {
        "base": [15, 6.95],
        "proporcoes": {
          "dano_fisico_bonus": 0.291,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 65,
      "recarga": 7.5,
      "efeitos": ["Alcance 295 e abertura 55°", "Lentidão de 25% por 1,2 s"],
      "tags": ["controle"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Corda rompida",
      "descricao": "Arranca o gancho do rival marcado. Quanto mais ferido ele estiver, maior o dano.",
      "narracao": "{campeao} rompe a corda presa em {alvo}!",
      "tipo_dano": "fisico",
      "alvo": "unico",
      "dano": {
        "base": [33, 14.52],
        "proporcoes": {
          "dano_fisico_bonus": 0.608,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0.068,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 85,
      "recarga": 74,
      "efeitos": [
        "Alcance 340",
        "A parcela de vida perdida exige a marca de Tom de Prova e só vale contra campeões",
        "A marca é consumida mesmo quando o alvo tem pouca vida perdida",
        "Disponível a partir do nível 6."
      ],
      "tags": ["execucao", "precisao"]
    }
  ],
  "build_recomendada": [
    "Botas do Caçador",
    "Presa da Serpente",
    "Lança Quebra-Escudos",
    "Lâmina do Eclipse",
    "Escudo do Guardião"
  ],
  "itens_alternativos": [
    {
      "item": "Manto da Noite Eterna",
      "quando": "contra explosão física que ameaça antes da finalização",
      "substitui": "Lâmina do Eclipse"
    },
    {
      "item": "Sanguessuga Rubra",
      "quando": "para se recuperar entre duelos quando há pouca magia do outro lado",
      "substitui": "Escudo do Guardião"
    },
    {
      "item": "Sandálias da Sabedoria",
      "quando": "contra controle mágico que faz a marca expirar",
      "substitui": "Botas do Caçador"
    }
  ],
  "forte_contra": "Alvos feridos por um aliado e equipes que lutam sem uma segunda linha de proteção.",
  "fraco_contra": "Escudos que compram tempo, curas fortes e rivais que bloqueiam o gancho inicial."
}
```

### Nalcora, a lapidadora de faíscas

```json
{
  "id": "nalcora",
  "nome": "Nalcora",
  "titulo": "a lapidadora de faíscas",
  "classe": "assassino",
  "posicoes": ["meio"],
  "tema": "Nalcora corta placas de relógio com gelo de solda e um estilete condutor. A primeira batida solta metal de um lado e vapor de sal do outro.",
  "curva_de_forca": "inicio",
  "dificuldade": 3,
  "dependencia_macro": 2,
  "recurso": {
    "tipo": "mana",
    "maximo": [280, 20],
    "regeneracao_5s": [7, 0.5]
  },
  "atributos": {
    "vida": [558, 90.56],
    "armadura": [29, 3.78],
    "resistencia_magica": [31, 1.15],
    "dano_fisico": [67, 2.88],
    "velocidade_ataque": [0.676, 2.3],
    "alcance": 125,
    "velocidade_movimento": 340
  },
  "passiva": {
    "nome": "Ângulo assentado",
    "descricao": "Nalcora ajusta a lâmina ao entrar pelo lado menos vigiado.",
    "efeito": "Após 2 s fora de combate contra campeões, a primeira abertura de Estilete de Solda perde 0,1 s de preparação. Rearma somente após sair de combate. Sem dano adicional."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Estilete de solda",
      "descricao": "Raspa a placa condutora num corte que alterna calor e aço.",
      "narracao": "{campeao} abre a troca com um estilete de solda!",
      "tipo_dano": "misto",
      "alvo": "linha",
      "dano": {
        "base": [91, 8.32],
        "proporcoes": {
          "dano_fisico_bonus": 0.882,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 24,
      "recarga": 6.5,
      "efeitos": [
        "Alcance 380, largura 70",
        "Preparação de 0,35 s antes da passiva",
        "Para no primeiro campeão",
        "Divisão do dano final bruto: 69% físico e 31% mágico, com mitigação separada."
      ],
      "tags": ["dano_misto", "explosao"]
    },
    {
      "posicao": 2,
      "nome": "Fio de retorno",
      "descricao": "Recolhe o fio pelo chão e enrosca quem a perseguiu.",
      "narracao": "{campeao} recolhe o fio aos pés dos rivais!",
      "tipo_dano": "misto",
      "alvo": "cone",
      "dano": {
        "base": [42, 3.9],
        "proporcoes": {
          "dano_fisico_bonus": 0.414,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 23,
      "recarga": 7.5,
      "efeitos": [
        "Alcance 290 e abertura 65°",
        "Lentidão de 30% por 1,4 s",
        "Divisão do dano final bruto: 57% físico e 43% mágico, com mitigação separada."
      ],
      "tags": ["dano_misto", "controle"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Vidragem súbita",
      "descricao": "Estoura a solda já fria sobre o alvo que permaneceu perto.",
      "narracao": "{campeao} estoura a vidragem perto de {alvo}!",
      "tipo_dano": "misto",
      "alvo": "unico",
      "dano": {
        "base": [52, 4.75],
        "proporcoes": {
          "dano_fisico_bonus": 0.504,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 37,
      "recarga": 65,
      "efeitos": [
        "Alcance 285",
        "Preparação de 0,4 s e um único acerto",
        "Divisão do dano final bruto: 60% físico e 40% mágico, com mitigação separada.",
        "Disponível a partir do nível 6."
      ],
      "tags": ["dano_misto", "explosao"]
    }
  ],
  "build_recomendada": [
    "Botas do Caçador",
    "Lâmina do Eclipse",
    "Presa da Serpente",
    "Manto da Noite Eterna",
    "Escudo do Guardião"
  ],
  "itens_alternativos": [
    {
      "item": "Lança Quebra-Escudos",
      "quando": "contra armadura alta quando a parcela física ainda domina sua rotação",
      "substitui": "Manto da Noite Eterna"
    },
    {
      "item": "Grevas de Ferro",
      "quando": "contra pressão física no meio, para continuar ganhando a primeira troca",
      "substitui": "Botas do Caçador"
    },
    {
      "item": "Machado do Gigante",
      "quando": "contra lutas de contato prolongado com pouco dano mágico",
      "substitui": "Escudo do Guardião"
    }
  ],
  "forte_contra": "Frágeis que compram uma única resistência e cedem o primeiro ângulo.",
  "fraco_contra": "Rivais de zona que negam o alcance curto e alvos com resistências mistas."
}
```

### Iscavro, o vigia das fornalhas

```json
{
  "id": "iscavro",
  "nome": "Iscavro",
  "titulo": "o vigia das fornalhas",
  "classe": "assassino",
  "posicoes": ["selva"],
  "tema": "Vigia de uma fornalha desativada, Iscavro conserva o calor numa manivela junto ao pulso. O metal muda do cinza ao vermelho antes do golpe final.",
  "curva_de_forca": "fim",
  "dificuldade": 3,
  "dependencia_macro": 3,
  "recurso": {
    "tipo": "furia",
    "maximo": [100, 0],
    "regeneracao_5s": [0, 0]
  },
  "atributos": {
    "vida": [552, 113.22],
    "armadura": [29, 4.71],
    "resistencia_magica": [28, 1.46],
    "dano_fisico": [60, 3.69],
    "velocidade_ataque": [0.624, 2.7],
    "alcance": 125,
    "velocidade_movimento": 345
  },
  "passiva": {
    "nome": "Calor de retorno",
    "descricao": "A fornalha de Iscavro precisa esquentar antes da finalização.",
    "efeito": "Ganha 13 de fúria ao acertar ataque básico e 7 ao receber acerto de campeão ou monstro, no máximo um ganho por categoria por segundo. Após 4 s sem combate, perde 10 por segundo. A especial com fúria cheia recebe a parcela de execução."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Manivela curta",
      "descricao": "Vira a manivela de uma vez e fere quem estiver no arco.",
      "narracao": "{campeao} gira a manivela e abre a roda de briga!",
      "tipo_dano": "fisico",
      "alvo": "cone",
      "dano": {
        "base": [25, 12.87],
        "proporcoes": {
          "dano_fisico_bonus": 0.465,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 22,
      "recarga": 6.5,
      "efeitos": ["Alcance 265 e abertura 80°", "A habilidade não gera fúria ao acertar"],
      "tags": ["briga"]
    },
    {
      "posicao": 2,
      "nome": "Sombra da chaminé",
      "descricao": "Lança um pino diante do alvo e atrasa sua fuga.",
      "narracao": "{campeao} finca um pino na rota de fuga!",
      "tipo_dano": "fisico",
      "alvo": "linha",
      "dano": {
        "base": [16, 8.47],
        "proporcoes": {
          "dano_fisico_bonus": 0.306,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 24,
      "recarga": 7.5,
      "efeitos": ["Alcance 415, largura 58 e lentidão de 25% por 1,2 s"],
      "tags": ["precisao", "controle"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Forja da última brasa",
      "descricao": "Golpeia com a manivela quente. O efeito final cresce com os ferimentos do alvo.",
      "narracao": "{campeao} descarrega a última brasa sobre {alvo}!",
      "tipo_dano": "fisico",
      "alvo": "unico",
      "dano": {
        "base": [24, 12.53],
        "proporcoes": {
          "dano_fisico_bonus": 0.453,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0.073,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 46,
      "recarga": 81,
      "efeitos": [
        "Alcance 265",
        "Com 100 de fúria antes do gasto, aplica a parcela pela vida perdida a campeões",
        "Sem fúria cheia, só aplica o dano regular",
        "Disponível a partir do nível 6."
      ],
      "tags": ["execucao", "furia"]
    }
  ],
  "build_recomendada": [
    "Botas do Caçador",
    "Presa da Serpente",
    "Machado do Gigante",
    "Lança Quebra-Escudos",
    "Escudo do Guardião"
  ],
  "itens_alternativos": [
    {
      "item": "Manto da Noite Eterna",
      "quando": "contra rajadas físicas que interrompem o preparo da fúria",
      "substitui": "Machado do Gigante"
    },
    {
      "item": "Sanguessuga Rubra",
      "quando": "contra desgaste longo e pouca ameaça mágica",
      "substitui": "Escudo do Guardião"
    },
    {
      "item": "Lâmina do Eclipse",
      "quando": "contra retaguarda frágil que sangra no primeiro contato, com pouca armadura",
      "substitui": "Lança Quebra-Escudos"
    }
  ],
  "forte_contra": "Brigas de rio com tempo para preparar fúria antes de perseguir um inimigo já ferido.",
  "fraco_contra": "Lutas breves, curas entre trocas e adversários que fazem o caçador perder fúria antes do objetivo."
}
```

### Mirfuso, o cobrador de caminhos

```json
{
  "id": "mirfuso",
  "nome": "Mirfuso",
  "titulo": "o cobrador de caminhos",
  "classe": "assassino",
  "posicoes": ["topo", "meio"],
  "tema": "Mirfuso anota pedágios com um perfurador de cobre triangular. Usa um rolo de fita diagonal nas costas que sacode quando ele muda de rota.",
  "curva_de_forca": "constante",
  "dificuldade": 3,
  "dependencia_macro": 3,
  "recurso": {
    "tipo": "energia",
    "maximo": [200, 0],
    "regeneracao_5s": [50, 0]
  },
  "atributos": {
    "vida": [582, 100.75],
    "armadura": [29, 4.22],
    "resistencia_magica": [31, 1.29],
    "dano_fisico": [64, 3.28],
    "velocidade_ataque": [0.65, 2.5],
    "alcance": 125,
    "velocidade_movimento": 345
  },
  "passiva": {
    "nome": "Recibo aberto",
    "descricao": "Mirfuso se reposiciona melhor depois de trabalhar sozinho na rota.",
    "efeito": "Após derrotar um minion sem outro campeão aliado a até 600, ganha 8 unidades de movimento por 3 s. Intervalo de 9 s, sem acúmulo. Não vale em monstros ou estruturas."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Fita de cobrança",
      "descricao": "Lança fita rasgante pela rota para cortar a aproximação.",
      "narracao": "{campeao} estica a fita na direção de {alvo}!",
      "tipo_dano": "fisico",
      "alvo": "linha",
      "dano": {
        "base": [57, 11.05],
        "proporcoes": {
          "dano_fisico_bonus": 0.656,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 70,
      "recarga": 6.5,
      "efeitos": ["Alcance 418, largura 72", "Só o primeiro campeão recebe dano completo. Minions recebem 65%"],
      "tags": ["pressao_lateral", "precisao"]
    },
    {
      "posicao": 2,
      "nome": "Furo de selo",
      "descricao": "Perfura a ponta da fita num golpe curto e muito estreito.",
      "narracao": "{campeao} perfura o selo sobre {alvo}!",
      "tipo_dano": "verdadeiro",
      "alvo": "linha",
      "dano": {
        "base": [17, 3.34],
        "proporcoes": {
          "dano_fisico_bonus": 0.198,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 65,
      "recarga": 7.5,
      "efeitos": [
        "Alcance 257, largura 38",
        "Só o primeiro campeão recebe dano verdadeiro. Em monstros e estruturas não causa dano"
      ],
      "tags": ["dano_verdadeiro", "precisao"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Trecho interditado",
      "descricao": "Fecha a passagem com o perfurador antes de mudar de ângulo.",
      "narracao": "{campeao} fecha o trecho diante de {alvo}!",
      "tipo_dano": "fisico",
      "alvo": "unico",
      "dano": {
        "base": [58, 11.31],
        "proporcoes": {
          "dano_fisico_bonus": 0.671,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 80,
      "recarga": 67,
      "efeitos": [
        "Atinge um campeão a até 310",
        "Após acertar, pode avançar até 235 em direção perpendicular à linha entre os dois. Não cruza terreno",
        "Disponível a partir do nível 6."
      ],
      "tags": ["mobilidade", "pressao_lateral"]
    }
  ],
  "build_recomendada": [
    "Botas do Andarilho",
    "Presa da Serpente",
    "Lança Quebra-Escudos",
    "Manto da Noite Eterna",
    "Escudo do Guardião"
  ],
  "itens_alternativos": [
    {
      "item": "Botas do Caçador",
      "quando": "contra frágeis que defendem sozinhos e têm pouca armadura",
      "substitui": "Botas do Andarilho"
    },
    {
      "item": "Sanguessuga Rubra",
      "quando": "contra longos duelos físicos na rota lateral",
      "substitui": "Escudo do Guardião"
    },
    {
      "item": "Lâmina do Eclipse",
      "quando": "contra frágeis que se afastam logo depois da primeira troca",
      "substitui": "Lança Quebra-Escudos"
    }
  ],
  "forte_contra": "Defesas de rota isoladas, principalmente quando a equipe sabe quando pressionar o outro lado.",
  "fraco_contra": "Times que cortam a saída com visão e obrigam a defender com o time em vez de abrir rota."
}
```

### Kordume, o carregador de quilhas

```json
{
  "id": "kordume",
  "nome": "Kordume",
  "titulo": "o carregador de quilhas",
  "classe": "lutador",
  "posicoes": ["topo"],
  "tema": "Kordume manteve docas abertas a marretadas quando as marés soterraram o cais. Empunha uma quilha curta, presa ao braço com uma tira vermelha grossa.",
  "curva_de_forca": "inicio",
  "dificuldade": 2,
  "dependencia_macro": 1,
  "recurso": {
    "tipo": "furia",
    "maximo": [100, 0],
    "regeneracao_5s": [0, 0]
  },
  "atributos": {
    "vida": [698, 91.35],
    "armadura": [35, 3.96],
    "resistencia_magica": [31, 1.62],
    "dano_fisico": [66, 3.09],
    "velocidade_ataque": [0.676, 2.3],
    "alcance": 125,
    "velocidade_movimento": 335
  },
  "passiva": {
    "nome": "Peso de carga",
    "descricao": "Atacar e suportar a pancada enche a barra de fúria.",
    "efeito": "Recebe 15 de fúria por ataque básico acertado e 7 ao receber um acerto de campeão ou monstro, uma vez por categoria a cada 1 s. Fora de combate por 4 s, perde 10 por segundo. A quilha fica mais pesada com a barra cheia."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Quilha atravessada",
      "descricao": "Varre o espaço curto com o peso do corpo.",
      "narracao": "{campeao} vira a quilha e abre espaço!",
      "tipo_dano": "fisico",
      "alvo": "cone",
      "dano": {
        "base": [52, 3.44],
        "proporcoes": {
          "dano_fisico_bonus": 0.315,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.009
        }
      },
      "custo": 23,
      "recarga": 6,
      "efeitos": [
        "Alcance 260 e abertura 75°",
        "Com fúria cheia antes do gasto, a parcela de vida máxima própria sobe de 0,6% para 0,9%"
      ],
      "tags": ["vida_propria", "briga"]
    },
    {
      "posicao": 2,
      "nome": "Fivela presa",
      "descricao": "Aperta as tiras da quilha e se protege por um instante.",
      "narracao": "{campeao} aperta a fivela e segura a pancada!",
      "tipo_dano": "fisico",
      "alvo": "si_mesmo",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 22,
      "recarga": 6,
      "efeitos": ["Escudo em si de 4% da própria vida máxima por 2 s. Com fúria cheia, 5%"],
      "tags": ["escudo", "vida_propria"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Peso morto",
      "descricao": "Crava a quilha acima da guarda do oponente.",
      "narracao": "{campeao} deixa a quilha cair sobre {alvo}!",
      "tipo_dano": "fisico",
      "alvo": "unico",
      "dano": {
        "base": [59, 3.88],
        "proporcoes": {
          "dano_fisico_bonus": 0.355,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.012
        }
      },
      "custo": 43,
      "recarga": 61,
      "efeitos": [
        "Alcance 245",
        "A parcela de vida própria só é aplicada a campeões",
        "Com fúria cheia antes do gasto, a lenta preparação cai de 0,40 s para 0,25 s",
        "Disponível a partir do nível 6."
      ],
      "tags": ["vida_propria"]
    }
  ],
  "build_recomendada": [
    "Grevas de Ferro",
    "Coração do Titã",
    "Machado do Gigante",
    "Lâmina Sanguinária do Guerreiro",
    "Armadura Viva de Cristal"
  ],
  "itens_alternativos": [
    {
      "item": "Égide de Aço",
      "quando": "contra roubo de vida em lutas no corpo a corpo",
      "substitui": "Armadura Viva de Cristal"
    },
    {
      "item": "Escudo do Guardião",
      "quando": "contra explosão mágica que atravessa a sustentação inicial",
      "substitui": "Lâmina Sanguinária do Guerreiro"
    },
    {
      "item": "Couraça do Gigante de Pedra",
      "quando": "quando a ameaça é crítico e ele precisa segurar a linha de frente",
      "substitui": "Machado do Gigante"
    },
    {
      "item": "Martelo das Montanhas",
      "quando": "contra muita vida inimiga em troca de parte da aceleração e do dano físico",
      "substitui": "Machado do Gigante"
    }
  ],
  "forte_contra": "Duelistas que entram no alcance curto e trocam antes de fechar o primeiro item.",
  "fraco_contra": "Rivais que lutam de longe, somem da rota e deixam a fúria cair."
}
```

### Marulva, a fiandeira do sal rubro

```json
{
  "id": "marulva",
  "nome": "Marulva",
  "titulo": "a fiandeira do sal rubro",
  "classe": "lutador",
  "posicoes": ["topo"],
  "tema": "Marulva fia cabos de sal com uma manivela de osso. As tiras vermelhas do uniforme escurecem a cada feitiço, e voltam a clarear quando ela acerta o ritmo.",
  "curva_de_forca": "fim",
  "dificuldade": 3,
  "dependencia_macro": 2,
  "recurso": {
    "tipo": "vida",
    "maximo": [589, 118.88],
    "regeneracao_5s": [0, 0]
  },
  "atributos": {
    "vida": [589, 118.88],
    "armadura": [33, 5.04],
    "resistencia_magica": [33, 1.98],
    "dano_fisico": [60, 3.94],
    "velocidade_ataque": [0.624, 2.7],
    "alcance": 125,
    "velocidade_movimento": 335
  },
  "passiva": {
    "nome": "Ponto de restituição",
    "descricao": "A fiandeira recupera vida se encadear ataques depois de gastar a própria.",
    "efeito": "Ao acertar 2 ataques básicos contra campeões em até 4 s depois de pagar um custo de vida, cura 3% da própria vida máxima. Uma vez a cada 9 s. A cura sofre anticura e não reembolsa a habilidade perdida."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Linha lancetada",
      "descricao": "Passa o cabo rente ao solo e corta quem não abre espaço.",
      "narracao": "{campeao} estica uma linha de sal sob {alvo}!",
      "tipo_dano": "fisico",
      "alvo": "linha",
      "dano": {
        "base": [12, 5.88],
        "proporcoes": {
          "dano_fisico_bonus": 0.233,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 2.5,
      "recarga": 6,
      "efeitos": ["Alcance 355, largura 62", "Custa 2,5% da vida máxima própria"],
      "tags": ["custo_vida", "precisao"]
    },
    {
      "posicao": 2,
      "nome": "Ponto de retorno",
      "descricao": "O próximo ataque puxa o fio de volta enquanto recupera fôlego.",
      "narracao": "{campeao} recolhe o cabo e recupera fôlego!",
      "tipo_dano": "fisico",
      "alvo": "si_mesmo",
      "dano": {
        "base": [7, 3.53],
        "proporcoes": {
          "dano_fisico_bonus": 0.14,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 2,
      "recarga": 7,
      "efeitos": [
        "Custa 2,0% da vida máxima própria",
        "Em 3 s, o primeiro ataque contra campeão causa a parcela de dano extra da habilidade e cura 25% do dano extra efetivamente causado",
        "O dano extra não é crítico e não aplica roubo de vida. O ataque normal mantém seu cálculo"
      ],
      "tags": ["cura", "roubo_vida"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Bobina de ressaca",
      "descricao": "Desenrola toda a bobina. Depois disso, precisa continuar batendo para recuperar o que gastou.",
      "narracao": "{campeao} vira a bobina de sal sobre os rivais!",
      "tipo_dano": "fisico",
      "alvo": "cone",
      "dano": {
        "base": [14, 7.4],
        "proporcoes": {
          "dano_fisico_bonus": 0.293,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 4,
      "recarga": 75,
      "efeitos": [
        "Custa 4,0% da vida máxima própria",
        "Alcance 335 e abertura 70°",
        "Lentidão de 25% por 1,3 s",
        "Disponível a partir do nível 6."
      ],
      "tags": [
        "custo_vida",
        "controle",
        "sustentacao"
      ]
    }
  ],
  "build_recomendada": [
    "Botas da Fúria",
    "Lâmina Sanguinária do Guerreiro",
    "Sanguessuga Rubra",
    "Machado do Gigante",
    "Armadura Viva de Cristal"
  ],
  "itens_alternativos": [
    {
      "item": "Escudo do Guardião",
      "quando": "contra magia de execução, para sobreviver antes de recuperar vida",
      "substitui": "Armadura Viva de Cristal"
    },
    {
      "item": "Couraça do Gigante de Pedra",
      "quando": "contra críticos que derrubam antes dos ataques de restituição",
      "substitui": "Machado do Gigante"
    },
    {
      "item": "Lança Quebra-Escudos",
      "quando": "contra acúmulo de armadura quando o dano físico perde força contra armadura",
      "substitui": "Machado do Gigante"
    }
  ],
  "forte_contra": "Desgaste físico que permite devolver ataques e recuperar vida em trocas sucessivas.",
  "fraco_contra": "Anticura, desarme de oportunidades de ataque e explosão antes da restituição."
}
```

### Trisquilo, o afinador de maquinário

```json
{
  "id": "trisquilo",
  "nome": "Trisquilo",
  "titulo": "o afinador de maquinário",
  "classe": "lutador",
  "posicoes": ["selva", "topo"],
  "tema": "Um consertador de caixas de música usa um martelo mecânico numa mão e uma chave ressonante na outra. O som muda conforme ele troca a ordem das ferramentas.",
  "curva_de_forca": "constante",
  "dificuldade": 3,
  "dependencia_macro": 2,
  "recurso": {
    "tipo": "energia",
    "maximo": [200, 0],
    "regeneracao_5s": [50, 0]
  },
  "atributos": {
    "vida": [627, 105.52],
    "armadura": [33, 4.53],
    "resistencia_magica": [33, 1.79],
    "dano_fisico": [67, 3.46],
    "velocidade_ataque": [0.65, 2.5],
    "alcance": 125,
    "velocidade_movimento": 345
  },
  "passiva": {
    "nome": "Par distinto",
    "descricao": "Trisquilo repõe um pouco de energia quando alterna bem as ferramentas.",
    "efeito": "Se acertar Choque de Chave em até 2,2 s após acertar Dente de Roda, devolve 15 de energia depois do segundo impacto. Intervalo de 8 s. Só vale em campeões."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Dente de roda",
      "descricao": "Bate no arco da frente com o martelo dentado.",
      "narracao": "{campeao} pega o rival no dente da roda!",
      "tipo_dano": "fisico",
      "alvo": "cone",
      "dano": {
        "base": [24, 4.96],
        "proporcoes": {
          "dano_fisico_bonus": 0.222,
          "poder_magico": 0.114,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 76,
      "recarga": 6,
      "efeitos": ["Alcance 240 e abertura 59°", "Aviso de 0,24 s"],
      "tags": ["dano_misto", "combo"]
    },
    {
      "posicao": 2,
      "nome": "Choque de chave",
      "descricao": "Manda uma vibração estreita pela chave de afinação.",
      "narracao": "{campeao} solta uma vibração de chave em {alvo}!",
      "tipo_dano": "magico",
      "alvo": "linha",
      "dano": {
        "base": [23, 4.66],
        "proporcoes": {
          "dano_fisico_bonus": 0.209,
          "poder_magico": 0.107,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 62,
      "recarga": 6,
      "efeitos": ["Alcance 390, largura 62", "Atinge só o primeiro campeão na linha"],
      "tags": ["dano_misto", "precisao"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Engrenagem em falso",
      "descricao": "Passa por dentro da guarda e bate com as duas ferramentas.",
      "narracao": "{campeao} encontra a engrenagem em falso de {alvo}!",
      "tipo_dano": "misto",
      "alvo": "unico",
      "dano": {
        "base": [26, 5.42],
        "proporcoes": {
          "dano_fisico_bonus": 0.242,
          "poder_magico": 0.125,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 77,
      "recarga": 65,
      "efeitos": [
        "Salto de até 255 em direção a um campeão, sem cruzar paredes",
        "O dano só sai se terminar ao alcance do alvo",
        "Divisão do dano final bruto: 52% físico e 48% mágico, com mitigação separada.",
        "Disponível a partir do nível 6."
      ],
      "tags": ["dano_misto", "mobilidade"]
    }
  ],
  "build_recomendada": [
    "Botas da Fúria",
    "Cetro-Lâmina do Crepúsculo",
    "Machado do Gigante",
    "Lâmina Sanguinária do Guerreiro",
    "Escudo do Guardião"
  ],
  "itens_alternativos": [
    {
      "item": "Lança Quebra-Escudos",
      "quando": "contra armadura elevada, se o time precisa manter a parcela física relevante",
      "substitui": "Lâmina Sanguinária do Guerreiro"
    },
    {
      "item": "Manto dos Ventos Gélidos",
      "quando": "contra dano misto com vários atacantes rápidos",
      "substitui": "Escudo do Guardião"
    },
    {
      "item": "Couraça do Gigante de Pedra",
      "quando": "contra crítico que força trocar dano por resistência",
      "substitui": "Machado do Gigante"
    }
  ],
  "forte_contra": "Escaramuças em terreno aberto e rivais que compram só armadura ou só resistência mágica.",
  "fraco_contra": "Controle que separa as duas partes do combo e perseguições que custam mais energia que o previsto."
}
```

### Vardilha, a marcadora de estacas

```json
{
  "id": "vardilha",
  "nome": "Vardilha",
  "titulo": "a marcadora de estacas",
  "classe": "lutador",
  "posicoes": ["selva"],
  "tema": "Vardilha cerca poças de mineração com estacas de sinalização. Em luta, planta marcas no terreno para indicar onde cairá a corrente sob medida.",
  "curva_de_forca": "inicio",
  "dificuldade": 2,
  "dependencia_macro": 3,
  "recurso": {
    "tipo": "mana",
    "maximo": [300, 20],
    "regeneracao_5s": [7, 0.5]
  },
  "atributos": {
    "vida": [678, 92.05],
    "armadura": [35, 3.96],
    "resistencia_magica": [31, 1.61],
    "dano_fisico": [66, 3.09],
    "velocidade_ataque": [0.676, 2.3],
    "alcance": 125,
    "velocidade_movimento": 340
  },
  "passiva": {
    "nome": "Medida de vazão",
    "descricao": "Vardilha prepara a disputa de monstros quando chega antes.",
    "efeito": "Entrar voluntariamente num raio de 325 de Hydra ou Cérbero e permanecer 2 s concede visão própria da entrada mais próxima por 2 s, num raio de 120. Uma vez por monstro a cada 60 s. Não revela campeões fora da área nem causa dano."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Estaca niveladora",
      "descricao": "Acerta a superfície e prende o primeiro rival no caminho.",
      "narracao": "{campeao} finca a estaca diante de {alvo}!",
      "tipo_dano": "fisico",
      "alvo": "linha",
      "dano": {
        "base": [52, 1.65],
        "proporcoes": {
          "dano_fisico_bonus": 0.279,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0.022,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 26,
      "recarga": 6,
      "efeitos": ["Alcance 380, largura 70", "Parcela por vida máxima só contra campeões"],
      "tags": ["antitanque", "objetivo"]
    },
    {
      "posicao": 2,
      "nome": "Marco de percurso",
      "descricao": "Planta uma estaca baixa para atrasar a entrada da outra equipe.",
      "narracao": "{campeao} marca o chão na entrada do objetivo!",
      "tipo_dano": "fisico",
      "alvo": "area",
      "dano": {
        "base": [20, 0.63],
        "proporcoes": {
          "dano_fisico_bonus": 0.107,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 23,
      "recarga": 6.5,
      "efeitos": ["Alcance 370, raio 125", "Lentidão de 20% por 1,5 s"],
      "tags": ["controle", "zona"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Aferição final",
      "descricao": "Fecha a corrente sobre o ponto mais pesado do alvo.",
      "narracao": "{campeao} aperta a corrente de aferição em {alvo}!",
      "tipo_dano": "fisico",
      "alvo": "unico",
      "dano": {
        "base": [28, 0.89],
        "proporcoes": {
          "dano_fisico_bonus": 0.15,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0.022,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 41,
      "recarga": 64,
      "efeitos": [
        "Alcance 280",
        "Parcela por vida máxima só contra campeões",
        "Em monstros épicos só vale dano base mais o escalamento por DF bônus",
        "Disponível a partir do nível 6."
      ],
      "tags": ["antitanque", "objetivo"]
    }
  ],
  "build_recomendada": [
    "Botas do Caçador",
    "Machado do Gigante",
    "Lâmina Sanguinária do Guerreiro",
    "Lança Quebra-Escudos",
    "Escudo do Guardião"
  ],
  "itens_alternativos": [
    {
      "item": "Égide de Aço",
      "quando": "contra cura e ataques físicos de quem contesta o rio",
      "substitui": "Escudo do Guardião"
    },
    {
      "item": "Grevas de Ferro",
      "quando": "quando invasores físicos conseguem forçar o duelo cedo",
      "substitui": "Botas do Caçador"
    },
    {
      "item": "Armadura Viva de Cristal",
      "quando": "contra desgaste misto que atrapalha entrar no objetivo com vida",
      "substitui": "Lâmina Sanguinária do Guerreiro"
    }
  ],
  "forte_contra": "Tanques na entrada do objetivo e times que avisam o caçador cedo para chegar ao rio.",
  "fraco_contra": "Artilharia fora do alcance e equipes que invertem o lado do mapa depois de mostrar presença."
}
```

### Eirafim, o cultivador de órbitas

```json
{
  "id": "eirafim",
  "nome": "Eirafim",
  "titulo": "o cultivador de órbitas",
  "classe": "lutador",
  "posicoes": ["topo"],
  "tema": "Eirafim usa dois discos de poda pendurados por dobradiças. Ele coleciona brotos metálicos que só conseguem crescer em espiral.",
  "curva_de_forca": "fim",
  "dificuldade": 2,
  "dependencia_macro": 1,
  "recurso": {
    "tipo": "mana",
    "maximo": [300, 20],
    "regeneracao_5s": [7, 0.5]
  },
  "atributos": {
    "vida": [595, 118.59],
    "armadura": [33, 5.04],
    "resistencia_magica": [33, 1.98],
    "dano_fisico": [61, 3.93],
    "velocidade_ataque": [0.624, 2.7],
    "alcance": 125,
    "velocidade_movimento": 330
  },
  "passiva": {
    "nome": "Broto de ferro",
    "descricao": "Duelos repetidos melhoram a capacidade de Eirafim voltar para a rota.",
    "efeito": "Ao participar de uma luta com um campeão e ficar vivo por 6 s, ganha 1 broto, no máximo um a cada 45 s e até 5. Cada broto acrescenta 1 ponto percentual à parcela de roubo de vida da habilidade Espiral de Poda, sem conceder atributo permanente."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Corte de entrelinha",
      "descricao": "Abre as lâminas para bater de frente com quem disputa o mesmo espaço.",
      "narracao": "{campeao} abre os discos na entrelinha do rival!",
      "tipo_dano": "fisico",
      "alvo": "cone",
      "dano": {
        "base": [13, 6.68],
        "proporcoes": {
          "dano_fisico_bonus": 0.271,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 24,
      "recarga": 6,
      "efeitos": ["Alcance 255 e abertura 70°", "Dano integral uma vez por alvo"],
      "tags": ["duelo"]
    },
    {
      "posicao": 2,
      "nome": "Espiral de poda",
      "descricao": "Vira o próximo ataque numa poda cuidadosa que devolve parte da vida.",
      "narracao": "{campeao} encontra fôlego na espiral de poda!",
      "tipo_dano": "fisico",
      "alvo": "si_mesmo",
      "dano": {
        "base": [7, 3.25],
        "proporcoes": {
          "dano_fisico_bonus": 0.132,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 24,
      "recarga": 6.5,
      "efeitos": [
        "Em 3 s, o próximo ataque em campeão aplica o dano extra e cura 15% do dano extra efetivamente causado, até 20% com brotos",
        "O bônus de habilidade não é crítico. O ataque normal mantém seu cálculo"
      ],
      "tags": ["roubo_vida", "acumulo_limitado"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Dobra do pomar",
      "descricao": "Recolhe as dobradiças para prender o alvo um instante mais perto.",
      "narracao": "{campeao} gira a dobra do pomar diante de {alvo}!",
      "tipo_dano": "fisico",
      "alvo": "unico",
      "dano": {
        "base": [14, 7.19],
        "proporcoes": {
          "dano_fisico_bonus": 0.291,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 42,
      "recarga": 76,
      "efeitos": [
        "Alcance 280",
        "Lentidão de 30% por 1,5 s",
        "Disponível a partir do nível 6."
      ],
      "tags": ["controle", "sustentacao"]
    }
  ],
  "build_recomendada": [
    "Botas da Fúria",
    "Lâmina Sanguinária do Guerreiro",
    "Sanguessuga Rubra",
    "Machado do Gigante",
    "Manto dos Ventos Gélidos"
  ],
  "itens_alternativos": [
    {
      "item": "Lança Quebra-Escudos",
      "quando": "contra armadura alta em duelos longos",
      "substitui": "Machado do Gigante"
    },
    {
      "item": "Escudo do Guardião",
      "quando": "contra rajadas de magia concentradas que vencem a cura",
      "substitui": "Manto dos Ventos Gélidos"
    },
    {
      "item": "Égide de Aço",
      "quando": "contra rivais que também sustentam o duelo com ataques básicos",
      "substitui": "Machado do Gigante"
    }
  ],
  "forte_contra": "Duelos de longa duração e oponentes sem anticura que deixam bater depois da primeira troca.",
  "fraco_contra": "Desgaste à distância, cura reduzida e rotas adversárias que só aparecem em trocas de um golpe."
}
```

### Velúria, a arquivista dos ventos

```json
{
  "id": "veluria",
  "nome": "Velúria",
  "titulo": "a arquivista dos ventos",
  "classe": "mago",
  "posicoes": ["meio"],
  "tema": "Velúria arquiva ventos em tubos de vidro e ensina o céu a repetir o que ouviu. Seus projéteis levam fitas pálidas, como fichas de biblioteca soltas no ar.",
  "curva_de_forca": "fim",
  "dificuldade": 3,
  "dependencia_macro": 2,
  "recurso": {
    "tipo": "mana",
    "maximo": [420, 28],
    "regeneracao_5s": [8, 0.6]
  },
  "atributos": {
    "vida": [515, 107.56],
    "armadura": [25, 4.48],
    "resistencia_magica": [29, 1.45],
    "dano_fisico": [49, 3.37],
    "velocidade_ataque": [0.605, 2.7],
    "alcance": 575,
    "velocidade_movimento": 325
  },
  "passiva": {
    "nome": "Arquivo de rajadas",
    "descricao": "Acertos repetidos ajudam Velúria a furar a névoa mais de longe.",
    "efeito": "A cada 2 acertos de Escrito ao Vento em campeões, ganha 1 ficha. Intervalo de 18 s entre fichas, até 5. Cada ficha dá +18 de alcance apenas a Escrito ao Vento, até 950. Sem aumento no alcance de ataques básicos ou no dano."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Escrito ao vento",
      "descricao": "Solta uma ficha veloz que estoura no primeiro rival.",
      "narracao": "{campeao} lança um escrito ao vento contra {alvo}!",
      "tipo_dano": "magico",
      "alvo": "linha",
      "dano": {
        "base": [29, 10.52],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.55,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 36,
      "recarga": 6.5,
      "efeitos": [
        "Alcance 860 antes das fichas, largura 66",
        "Para no primeiro campeão ou monstro épico. Minions recebem 50% do dano e não interrompem"
      ],
      "tags": [
        "desgaste",
        "longo_alcance",
        "acumulo_limitado"
      ]
    },
    {
      "posicao": 2,
      "nome": "Índice aberto",
      "descricao": "Deixa uma folha suspensa que se rasga com quem chega perto.",
      "narracao": "{campeao} abre o índice no caminho inimigo!",
      "tipo_dano": "magico",
      "alvo": "area",
      "dano": {
        "base": [15, 5.38],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.281,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 35,
      "recarga": 7.5,
      "efeitos": ["Alcance 660, raio 125, aviso de 0,55 s", "Lentidão de 20% por 1,4 s"],
      "tags": ["controle", "desgaste"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Rajada catalogada",
      "descricao": "Dobra todas as folhas numa corrente estreita que anuncia por onde vai passar.",
      "narracao": "{campeao} solta a rajada catalogada pela rota!",
      "tipo_dano": "magico",
      "alvo": "linha",
      "dano": {
        "base": [23, 8.56],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.447,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 55,
      "recarga": 79,
      "efeitos": [
        "Alcance 1060, largura 82 e aviso de 0,85 s",
        "Dano integral ao primeiro campeão, 70% aos posteriores",
        "Disponível a partir do nível 6."
      ],
      "tags": ["longo_alcance", "precisao"]
    }
  ],
  "build_recomendada": [
    "Botas Arcanas",
    "Grimório Cristalino",
    "Cajado do Abismo",
    "Tocha do Tormento",
    "Véu Celestial"
  ],
  "itens_alternativos": [
    {
      "item": "Orbe da Tempestade",
      "quando": "contra frágeis com pouca resistência mágica e pouca cura",
      "substitui": "Tocha do Tormento"
    },
    {
      "item": "Foice da Lua Negra",
      "quando": "contra invasões e mergulhos que pedem vida antes da penetração máxima",
      "substitui": "Cajado do Abismo"
    },
    {
      "item": "Coroa da Hydra",
      "quando": "contra explosão física, quando o escudo só mágico tem pouco valor",
      "substitui": "Véu Celestial"
    }
  ],
  "forte_contra": "Lutas de cerco em que a equipe segura espaço e permite vários disparos de longe.",
  "fraco_contra": "Avanços repentinos por ângulos distintos e pressão cedo antes de acumular alcance."
}
```

### Cintarro, o inspetor dos fornos

```json
{
  "id": "cintarro",
  "nome": "Cintarro",
  "titulo": "o inspetor dos fornos",
  "classe": "mago",
  "posicoes": ["meio"],
  "tema": "Cintarro demarca áreas perigosas em fundições públicas. No mapa, seu cordão vermelho avisa onde o piso está para passar do morno ao branco.",
  "curva_de_forca": "inicio",
  "dificuldade": 2,
  "dependencia_macro": 3,
  "recurso": {
    "tipo": "mana",
    "maximo": [420, 28],
    "regeneracao_5s": [8, 0.6]
  },
  "atributos": {
    "vida": [594, 83.28],
    "armadura": [27, 3.53],
    "resistencia_magica": [28, 1.17],
    "dano_fisico": [49, 2.7],
    "velocidade_ataque": [0.655, 2.3],
    "alcance": 525,
    "velocidade_movimento": 330
  },
  "passiva": {
    "nome": "Interdição pronta",
    "descricao": "Cintarro fecha melhor um corredor que já conhece.",
    "efeito": "Ficar 2 s a até 475 do rio ou da entrada de um objetivo sem sofrer dano de campeão prepara uma inspeção. O próximo Cordão de Forno preparado tem 0,10 s a menos de aviso. Intervalo de 18 s após o uso; não altera dano nem área."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Poeira de escória",
      "descricao": "Espalha escória pela frente para quebrar a aproximação.",
      "narracao": "{campeao} levanta escória na direção dos rivais!",
      "tipo_dano": "magico",
      "alvo": "cone",
      "dano": {
        "base": [85, 8.97],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.325,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 35,
      "recarga": 7,
      "efeitos": ["Alcance 410 e abertura 70°", "Lentidão de 25% por 1,5 s"],
      "tags": ["controle", "zona"]
    },
    {
      "posicao": 2,
      "nome": "Porta refratária",
      "descricao": "Ergue uma placa para tomar a primeira pancada no posto de inspeção.",
      "narracao": "{campeao} apoia a porta refratária no chão!",
      "tipo_dano": "magico",
      "alvo": "si_mesmo",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 38,
      "recarga": 8,
      "efeitos": ["Escudo em si de 4% da própria vida máxima por 2,5 s"],
      "tags": ["escudo"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Cordão de forno",
      "descricao": "Interdita um corredor e aquece o piso antes de quem estiver nele poder passar.",
      "narracao": "{campeao} fecha o cordão do forno e atordoa os rivais!",
      "tipo_dano": "magico",
      "alvo": "area",
      "dano": {
        "base": [67, 7.04],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.255,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 53,
      "recarga": 70,
      "efeitos": [
        "Alcance 600, retângulo 310 × 155",
        "Aviso padrão de 0,7 s",
        "Atordoa por 0,9 s",
        "Disponível a partir do nível 6."
      ],
      "tags": [
        "controle",
        "area",
        "mapa"
      ]
    }
  ],
  "build_recomendada": [
    "Sandálias da Sabedoria",
    "Orbe da Tempestade",
    "Coroa da Hydra",
    "Tocha do Tormento",
    "Foice da Lua Negra"
  ],
  "itens_alternativos": [
    {
      "item": "Botas Arcanas",
      "quando": "contra retaguarda de resistência baixa e pouco controle",
      "substitui": "Sandálias da Sabedoria"
    },
    {
      "item": "Cajado do Abismo",
      "quando": "quando os alvos já empilham resistência mágica e a vida extra rende pouco",
      "substitui": "Foice da Lua Negra"
    },
    {
      "item": "Véu Celestial",
      "quando": "contra uma abertura quase toda mágica",
      "substitui": "Coroa da Hydra"
    }
  ],
  "forte_contra": "Engajes previsíveis em corredor, sobretudo quando pode preparar a entrada antes.",
  "fraco_contra": "Equipe que entra por vários lados, heróis de longo alcance e lutas sem tempo para preparar o cordão."
}
```

### Perlívia, a oleira de marés rasas

```json
{
  "id": "perlivia",
  "nome": "Perlívia",
  "titulo": "a oleira de marés rasas",
  "classe": "mago",
  "posicoes": ["meio"],
  "tema": "Perlívia guarda brasa em potes de porcelana filtrante. Cada feitiço que acende usa parte do seu fôlego, e acertar no tamanho certo devolve calor.",
  "curva_de_forca": "constante",
  "dificuldade": 2,
  "dependencia_macro": 2,
  "recurso": {
    "tipo": "vida",
    "maximo": [566, 94.76],
    "regeneracao_5s": [0, 0]
  },
  "atributos": {
    "vida": [566, 94.76],
    "armadura": [26, 3.99],
    "resistencia_magica": [31, 1.29],
    "dano_fisico": [49, 3.04],
    "velocidade_ataque": [0.63, 2.5],
    "alcance": 550,
    "velocidade_movimento": 325
  },
  "passiva": {
    "nome": "Pote retornável",
    "descricao": "Depois de pagar com vida, Perlívia pode recuperar parte do gasto.",
    "efeito": "Acertar um campeão inimigo com duas habilidades diferentes em até 4 s recupera 3,5% da própria vida máxima. Uma vez por 10 s. Cura própria sujeita a anticura; minions e monstros não contam."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Cacos morno-frios",
      "descricao": "Solta cacos de tamanhos diferentes na mesma direção.",
      "narracao": "{campeao} lança uma fileira de cacos contra {alvo}!",
      "tipo_dano": "magico",
      "alvo": "linha",
      "dano": {
        "base": [49, 8.09],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.37,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 2.5,
      "recarga": 7,
      "efeitos": [
        "Custa 2,5% da vida máxima própria",
        "Alcance 650, largura 78",
        "Máximo de um acerto por alvo"
      ],
      "tags": ["custo_vida", "precisao"]
    },
    {
      "posicao": 2,
      "nome": "Boca do molde",
      "descricao": "Deixa o gargalo quente no caminho e toma parte do espaço do rival.",
      "narracao": "{campeao} abre a boca do molde na rota!",
      "tipo_dano": "magico",
      "alvo": "area",
      "dano": {
        "base": [31, 5.18],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.237,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 2,
      "recarga": 7,
      "efeitos": [
        "Custa 2,0% da vida máxima própria",
        "Alcance 515 e raio 160",
        "Lentidão de 25% por 1,4 s"
      ],
      "tags": ["custo_vida", "controle"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Vaso de ressaca",
      "descricao": "Quebra de uma vez um pote que ainda guarda o calor da troca anterior.",
      "narracao": "{campeao} parte o vaso de ressaca sobre os rivais!",
      "tipo_dano": "magico",
      "alvo": "area",
      "dano": {
        "base": [45, 7.46],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.341,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 4,
      "recarga": 74,
      "efeitos": [
        "Custa 4,0% da vida máxima própria",
        "Alcance 575, raio 180 e aviso de 0,65 s",
        "Perlívia cura 2% da própria vida máxima se acertar ao menos um campeão. Uma cura por lançamento",
        "Disponível a partir do nível 6."
      ],
      "tags": ["custo_vida", "cura"]
    }
  ],
  "build_recomendada": [
    "Sandálias da Sabedoria",
    "Coroa da Hydra",
    "Grimório Cristalino",
    "Foice da Lua Negra",
    "Tocha do Tormento"
  ],
  "itens_alternativos": [
    {
      "item": "Véu Celestial",
      "quando": "contra desgaste mágico que ameaça o orçamento de vida cedo",
      "substitui": "Coroa da Hydra"
    },
    {
      "item": "Cajado do Abismo",
      "quando": "contra resistência mágica empilhada quando ainda é seguro ceder vida de item",
      "substitui": "Foice da Lua Negra"
    },
    {
      "item": "Orbe da Tempestade",
      "quando": "contra frágeis sem cura relevante e com janelas curtas de troca",
      "substitui": "Tocha do Tormento"
    }
  ],
  "forte_contra": "Trocas de ritmo médio com tempo para devolver dois acertos e recuperar a vida gasta.",
  "fraco_contra": "Anticura, alcance superior e explosão antes de devolver o segundo feitiço."
}
```

### Prismora, a calibradora de lentes

```json
{
  "id": "prismora",
  "nome": "Prismora",
  "titulo": "a calibradora de lentes",
  "classe": "mago",
  "posicoes": ["atirador", "meio"],
  "tema": "Prismora fabrica lentes de torre para iluminar neblina marítima. No mapa, o tripé dobrado aparece de lado sempre que ela decide assumir um ângulo.",
  "curva_de_forca": "fim",
  "dificuldade": 3,
  "dependencia_macro": 2,
  "recurso": {
    "tipo": "mana",
    "maximo": [420, 28],
    "regeneracao_5s": [8, 0.6]
  },
  "atributos": {
    "vida": [515, 107.56],
    "armadura": [24, 4.51],
    "resistencia_magica": [31, 1.44],
    "dano_fisico": [49, 3.37],
    "velocidade_ataque": [0.605, 2.7],
    "alcance": 575,
    "velocidade_movimento": 325
  },
  "passiva": {
    "nome": "Nitidez de ofício",
    "descricao": "Prismora premia quem prepara a mira com antecedência.",
    "efeito": "Após 1 s sem se mover, Projeção de Prova tem +90 de alcance. O benefício é consumido no lançamento e exige ficar parada de novo antes de rearmar. Sem alteração de dano."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Projeção de prova",
      "descricao": "Projeta um feixe estreito, mais longo quando a lente está firme.",
      "narracao": "{campeao} calibra a lente e projeta um feixe em {alvo}!",
      "tipo_dano": "magico",
      "alvo": "linha",
      "dano": {
        "base": [23, 17.31],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.373,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 35,
      "recarga": 7,
      "efeitos": [
        "Alcance de 815 ou 905 com a passiva, largura 57",
        "Atinge só o primeiro campeão. Minions também são acertados e não interrompem"
      ],
      "tags": ["longo_alcance", "precisao"]
    },
    {
      "posicao": 2,
      "nome": "Íris fechada",
      "descricao": "Fecha a íris num ponto lateral para atrasar o contra-ataque.",
      "narracao": "{campeao} fecha a íris à frente dos perseguidores!",
      "tipo_dano": "magico",
      "alvo": "area",
      "dano": {
        "base": [12, 8.85],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.191,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 33,
      "recarga": 7,
      "efeitos": ["Alcance 530, raio 140, aviso de 0,45 s", "Lentidão de 25% por 1,5 s"],
      "tags": ["controle", "desgaste"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Linha de horizonte",
      "descricao": "Devolve toda a luz num risco que cruza a rota.",
      "narracao": "{campeao} traça uma linha de horizonte pelo combate!",
      "tipo_dano": "magico",
      "alvo": "linha",
      "dano": {
        "base": [17, 12.31],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.265,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 58,
      "recarga": 83,
      "efeitos": [
        "Alcance 1080, largura 78 e aviso de 0,75 s",
        "Primeiro campeão recebe 100% do dano. Os demais recebem 60%",
        "Disponível a partir do nível 6."
      ],
      "tags": ["longo_alcance", "artilharia"]
    }
  ],
  "build_recomendada": [
    "Botas Arcanas",
    "Grimório Cristalino",
    "Orbe da Tempestade",
    "Cajado do Abismo",
    "Escudo do Guardião"
  ],
  "itens_alternativos": [
    {
      "item": "Tocha do Tormento",
      "quando": "contra cura e vida alta, trocando abertura por dano de desgaste e anticura",
      "substitui": "Orbe da Tempestade"
    },
    {
      "item": "Foice da Lua Negra",
      "quando": "contra mergulhos quando a vida comprada vale mais que penetração adicional",
      "substitui": "Cajado do Abismo"
    },
    {
      "item": "Coroa da Hydra",
      "quando": "contra ameaça física com pouca magia, para manter proteção e aumentar PM",
      "substitui": "Escudo do Guardião"
    }
  ],
  "forte_contra": "Rotas duplas que conseguem segurar a frente e lhe dão tempo entre disparos.",
  "fraco_contra": "Engajes rápidos, zonas que obrigam a andar o tempo todo e dano físico que chega pela lateral."
}
```

### Fulgavéu, a sinalizadora de vigias

```json
{
  "id": "fulgaveu",
  "nome": "Fulgavéu",
  "titulo": "a sinalizadora de vigias",
  "classe": "mago",
  "posicoes": ["atirador", "meio"],
  "tema": "Fulgavéu carregava sinais dobráveis nas passagens entre portos. A arma parece um leque de mapas, com um canto refletivo que aponta para a rota vizinha.",
  "curva_de_forca": "constante",
  "dificuldade": 2,
  "dependencia_macro": 3,
  "recurso": {
    "tipo": "mana",
    "maximo": [420, 28],
    "regeneracao_5s": [8, 0.6]
  },
  "atributos": {
    "vida": [554, 95.24],
    "armadura": [25, 4.02],
    "resistencia_magica": [32, 1.28],
    "dano_fisico": [50, 3.03],
    "velocidade_ataque": [0.63, 2.5],
    "alcance": 550,
    "velocidade_movimento": 330
  },
  "passiva": {
    "nome": "Sinal de partida",
    "descricao": "Fulgavéu presta mais atenção à primeira travessia revelada.",
    "efeito": "O primeiro campeão inimigo visto pela Vigia de Travessia no segundo inicial mantém uma indicação de última posição por 1 s depois de sair da área. A indicação é estática e não atualiza movimento nem revela névoa adicional."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Papel em brasa",
      "descricao": "Lança uma tira quente contra quem dá o primeiro passo na rota.",
      "narracao": "{campeao} acende o papel na rota de {alvo}!",
      "tipo_dano": "magico",
      "alvo": "linha",
      "dano": {
        "base": [62, 10.79],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.509,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 38,
      "recarga": 7,
      "efeitos": ["Alcance 690, largura 78", "Primeiro campeão recebe 100% do dano. Os demais recebem 70%"],
      "tags": ["pressao", "rota"]
    },
    {
      "posicao": 2,
      "nome": "Dobra de recado",
      "descricao": "Deixa um recado que atrapalha a perseguição se o rival insistir no caminho.",
      "narracao": "{campeao} dobra o recado no chão e atrasa a passagem!",
      "tipo_dano": "magico",
      "alvo": "area",
      "dano": {
        "base": [45, 7.82],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.368,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 34,
      "recarga": 8,
      "efeitos": ["Alcance 540, raio 146", "Lentidão de 20% por 1,5 s"],
      "tags": ["controle", "zona"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Vigia de travessia",
      "descricao": "Abre uma vigia distante para o time decidir se pode cruzar.",
      "narracao": "{campeao} abre uma vigia na travessia!",
      "tipo_dano": "magico",
      "alvo": "area",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 54,
      "recarga": 92,
      "efeitos": [
        "Alcance 2600, raio 245 e duração de 3 s",
        "Aviso visual ao adversário antes de revelar",
        "Revela apenas campeões e monstros dentro da área. Não causa dano, não substitui as torres de visão",
        "Disponível a partir do nível 6."
      ],
      "tags": ["mapa", "visao"]
    }
  ],
  "build_recomendada": [
    "Botas do Andarilho",
    "Tocha do Tormento",
    "Grimório Cristalino",
    "Cajado do Abismo",
    "Coroa da Hydra"
  ],
  "itens_alternativos": [
    {
      "item": "Botas Arcanas",
      "quando": "quando é preciso ganhar as trocas da própria rota e há pouca resistência mágica",
      "substitui": "Botas do Andarilho"
    },
    {
      "item": "Véu Celestial",
      "quando": "contra pressão mágica inicial que ameaça impedir as rotações",
      "substitui": "Coroa da Hydra"
    },
    {
      "item": "Orbe da Tempestade",
      "quando": "contra frágeis e pouca cura, se a equipe precisa de mais explosão na rota",
      "substitui": "Tocha do Tormento"
    }
  ],
  "forte_contra": "Composições que convertem visão antecipada em uma chegada segura a objetivos.",
  "fraco_contra": "Rivais que mostram presença falsa e entram por outro lado, ou que forçam duelos sem dependência de visão."
}
```

### Sutéria, a tecelã de curativos

```json
{
  "id": "suteria",
  "nome": "Sutéria",
  "titulo": "a tecelã de curativos",
  "classe": "suporte",
  "posicoes": ["suporte"],
  "tema": "Uma artesã de barracas de atendimento, Sutéria guarda bandagens verdes em carretéis abertos. Seus desenhos têm nós grandes para o aliado reconhecer mesmo em corrida.",
  "curva_de_forca": "inicio",
  "dificuldade": 1,
  "dependencia_macro": 1,
  "recurso": {
    "tipo": "mana",
    "maximo": [400, 25],
    "regeneracao_5s": [9, 0.6]
  },
  "atributos": {
    "vida": [609, 83.49],
    "armadura": [29, 3.77],
    "resistencia_magica": [31, 1.15],
    "dano_fisico": [48, 2.7],
    "velocidade_ataque": [0.645, 2.3],
    "alcance": 525,
    "velocidade_movimento": 330
  },
  "passiva": {
    "nome": "Primeiro socorro",
    "descricao": "A primeira ajuda de Sutéria chega mais depressa em quem acabou de ser ferido.",
    "efeito": "Se Ponte de Linha for usada em aliado que recebeu dano de campeão nos últimos 1,2 s, a preparação cai de 0,35 s para 0,15 s. Não muda a cura."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Carretel arremessado",
      "descricao": "Atira um carretel por baixo do movimento do rival.",
      "narracao": "{campeao} acerta o carretel em {alvo}!",
      "tipo_dano": "magico",
      "alvo": "unico",
      "dano": {
        "base": [46, 6.95],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.306,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 34,
      "recarga": 8,
      "efeitos": ["Alcance 545", "Lentidão de 20% por 1,4 s"],
      "tags": ["controle", "troca"]
    },
    {
      "posicao": 2,
      "nome": "Ponte de linha",
      "descricao": "Estanca parte dos ferimentos de um aliado.",
      "narracao": "{campeao} passa a linha e cura {alvo}!",
      "tipo_dano": "magico",
      "alvo": "aliado",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 35,
      "recarga": 9,
      "efeitos": ["Alcance 630", "Cura 4,5% da vida máxima do aliado + 12% PM, limitada a 7% da vida dele"],
      "tags": ["cura", "aliado"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Costura de plantão",
      "descricao": "Reforça os pontos do companheiro entre o primeiro e o segundo impacto.",
      "narracao": "{campeao} costura {alvo} no meio da luta!",
      "tipo_dano": "magico",
      "alvo": "aliado",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 51,
      "recarga": 66,
      "efeitos": [
        "Alcance 600",
        "Cura em dois pulsos separados por 1,1 s. O total é 7% da vida máxima do aliado + 15% PM, limitado a 10% da vida máxima dele",
        "O segundo pulso só ocorre até 700 da posição atual de Sutéria",
        "Disponível a partir do nível 6."
      ],
      "tags": ["cura", "aliado"]
    }
  ],
  "build_recomendada": [
    "Sandálias da Sabedoria",
    "Lanterna do Vigia",
    "Coroa da Hydra",
    "Medalhão dos Eternos",
    "Tocha do Tormento"
  ],
  "itens_alternativos": [
    {
      "item": "Véu Celestial",
      "quando": "contra dano mágico concentrado em Sutéria, quando sobreviver permite a segunda cura",
      "substitui": "Medalhão dos Eternos"
    },
    {
      "item": "Égide de Aço",
      "quando": "contra atacante físico que cura ao acertar a linha de frente",
      "substitui": "Tocha do Tormento"
    },
    {
      "item": "Botas do Andarilho",
      "quando": "contra pressão em rotas diferentes que exige chegar antes da troca",
      "substitui": "Sandálias da Sabedoria"
    }
  ],
  "forte_contra": "Trocas curtas de rota dupla e aliados que ficam vivos entre os dois pulsos.",
  "fraco_contra": "Anticura, explosão que elimina um aliado antes da cura e lutas que se abrem muito longe."
}
```

### Alvenora, a construtora de vigamentos

```json
{
  "id": "alvenora",
  "nome": "Alvenora",
  "titulo": "a construtora de vigamentos",
  "classe": "suporte",
  "posicoes": ["suporte"],
  "tema": "Alvenora remenda pontes com tábuas dobráveis e estacas brancas cintilantes. Cada reforço parece um encaixe de carpintaria, com bordas claras sobre o aliado.",
  "curva_de_forca": "fim",
  "dificuldade": 2,
  "dependencia_macro": 2,
  "recurso": {
    "tipo": "mana",
    "maximo": [400, 25],
    "regeneracao_5s": [9, 0.6]
  },
  "atributos": {
    "vida": [539, 107.3],
    "armadura": [29, 4.7],
    "resistencia_magica": [31, 1.43],
    "dano_fisico": [47, 3.38],
    "velocidade_ataque": [0.595, 2.7],
    "alcance": 500,
    "velocidade_movimento": 325
  },
  "passiva": {
    "nome": "Emenda medida",
    "descricao": "Alvenora melhora o reforço único com a experiência de proteger aliados.",
    "efeito": "Quando uma Placa de Travessa absorver ao menos 45 de dano de campeão, ganha uma emenda. Máximo de 5, com intervalo de 40 s. Cada emenda acrescenta 0,35 ponto percentual da vida do alvo ao escudo, até +1,75 ponto. O limite do escudo continua valendo."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Prego atravessado",
      "descricao": "Arremessa um prego comprido para segurar quem tenta atravessar.",
      "narracao": "{campeao} atravessa um prego na entrada dos rivais!",
      "tipo_dano": "magico",
      "alvo": "linha",
      "dano": {
        "base": [17, 10.09],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.292,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 34,
      "recarga": 8,
      "efeitos": ["Alcance 560, largura 63. Só acerta o primeiro campeão", "Lentidão de 25% por 1,4 s"],
      "tags": ["controle", "precisao"]
    },
    {
      "posicao": 2,
      "nome": "Placa de travessa",
      "descricao": "Encaixa uma placa sobre a guarda do aliado.",
      "narracao": "{campeao} coloca uma travessa na frente de {alvo}!",
      "tipo_dano": "magico",
      "alvo": "aliado",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 30,
      "recarga": 8,
      "efeitos": [
        "Alcance 620",
        "Escudo de 4% da vida máxima do aliado + 18% PM por 2,8 s, limitado a 8% da vida do alvo",
        "As emendas afetam apenas a base percentual"
      ],
      "tags": [
        "escudo",
        "aliado",
        "acumulo_limitado"
      ]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Ponte provisória",
      "descricao": "Estende duas pranchas para o aliado que vai tomar a primeira pancada.",
      "narracao": "{campeao} levanta uma ponte provisória para {alvo}!",
      "tipo_dano": "magico",
      "alvo": "aliado",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 56,
      "recarga": 82,
      "efeitos": [
        "Alcance 680",
        "Escudo de 7% da vida máxima do aliado + 18% PM por 2,8 s, limitado a 10% da vida máxima do alvo",
        "Se o alvo já tem Placa de Travessa, vale apenas o maior escudo restante entre os dois",
        "Disponível a partir do nível 6."
      ],
      "tags": ["escudo", "aliado"]
    }
  ],
  "build_recomendada": [
    "Sandálias da Sabedoria",
    "Lanterna do Vigia",
    "Coroa da Hydra",
    "Medalhão dos Eternos",
    "Véu Celestial"
  ],
  "itens_alternativos": [
    {
      "item": "Tocha do Tormento",
      "quando": "contra cura inimiga frequente e uma equipe que consegue protegê-la",
      "substitui": "Véu Celestial"
    },
    {
      "item": "Égide de Aço",
      "quando": "contra mergulho físico sustentado que impede acumular emendas",
      "substitui": "Coroa da Hydra"
    },
    {
      "item": "Escudo do Guardião",
      "quando": "contra dano mágico se priorizar vida e perder pouco pela redução de PM",
      "substitui": "Véu Celestial"
    }
  ],
  "forte_contra": "Explosões anunciadas sobre um aliado com muita vida e equipes que preparam suas entradas.",
  "fraco_contra": "Trocas em vários aliados que esgotam a mana e deixam o escudo cair fora da hora."
}
```

### Luminela, a portadora de luz de socorro

```json
{
  "id": "luminela",
  "nome": "Luminela",
  "titulo": "a portadora de luz de socorro",
  "classe": "suporte",
  "posicoes": ["suporte"],
  "tema": "Luminela aprendeu a enviar fachos entre vilarejos cujas sirenes falhavam na chuva. Usa dois visores e uma placa de endereçamento colorida nas costas.",
  "curva_de_forca": "constante",
  "dificuldade": 2,
  "dependencia_macro": 3,
  "recurso": {
    "tipo": "mana",
    "maximo": [400, 25],
    "regeneracao_5s": [9, 0.6]
  },
  "atributos": {
    "vida": [568, 95.47],
    "armadura": [29, 4.23],
    "resistencia_magica": [31, 1.29],
    "dano_fisico": [48, 3.03],
    "velocidade_ataque": [0.62, 2.5],
    "alcance": 550,
    "velocidade_movimento": 325
  },
  "passiva": {
    "nome": "Endereço conhecido",
    "descricao": "Um aliado que ficou perto dela recebe o sinal à distância mais depressa.",
    "efeito": "Se o aliado escolhido para Sinal de Socorro esteve a até 380 de Luminela nos últimos 8 s, a preparação da especial passa de 0,7 s a 0,55 s. Essa janela não altera a cura."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Lágrima de vidro",
      "descricao": "Atira uma lente horizontal para enfraquecer o avanço.",
      "narracao": "{campeao} lança uma lente diante de {alvo}!",
      "tipo_dano": "magico",
      "alvo": "linha",
      "dano": {
        "base": [43, 7.43],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.286,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 33,
      "recarga": 8,
      "efeitos": [
        "Alcance 610, largura 73",
        "Atinge o primeiro campeão inimigo",
        "Lentidão de 20% por 1,4 s"
      ],
      "tags": ["controle"]
    },
    {
      "posicao": 2,
      "nome": "Foco de revezamento",
      "descricao": "Põe um filtro de luz entre um aliado e o próximo impacto.",
      "narracao": "{campeao} cobre {alvo} com o foco de revezamento!",
      "tipo_dano": "magico",
      "alvo": "aliado",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 34,
      "recarga": 9,
      "efeitos": [
        "Alcance 650",
        "Escudo de 4% da vida máxima do aliado + 16% PM por 2 s, limitado a 7% da vida do alvo"
      ],
      "tags": ["escudo", "aliado"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Sinal de socorro",
      "descricao": "Manda um facho de socorro para um aliado onde o time precisar.",
      "narracao": "{campeao} recebe o pedido de socorro e alcança {alvo}!",
      "tipo_dano": "magico",
      "alvo": "aliado",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 53,
      "recarga": 104,
      "efeitos": [
        "Alcance global, apenas um campeão aliado vivo, exclui Luminela",
        "Preparação de 0,7 s. Não cura se o alvo morrer antes de receber o facho",
        "Cura 5% da vida máxima do aliado + 12% PM, limitada a 7% da vida máxima do alvo",
        "Disponível a partir do nível 6."
      ],
      "tags": [
        "global",
        "mapa",
        "cura"
      ]
    }
  ],
  "build_recomendada": [
    "Botas do Andarilho",
    "Lanterna do Vigia",
    "Medalhão dos Eternos",
    "Coroa da Hydra",
    "Véu Celestial"
  ],
  "itens_alternativos": [
    {
      "item": "Sandálias da Sabedoria",
      "quando": "contra muito controle ou pressão mágica que interrompe o socorro",
      "substitui": "Botas do Andarilho"
    },
    {
      "item": "Tocha do Tormento",
      "quando": "contra composições com cura dedicada e pouca pressão mágica sobre o suporte",
      "substitui": "Véu Celestial"
    },
    {
      "item": "Égide de Aço",
      "quando": "contra perseguidores físicos que a impedem de acompanhar o mapa",
      "substitui": "Coroa da Hydra"
    }
  ],
  "forte_contra": "Times que avisam cedo sobre uma luta em outra rota e sobrevivem até a ajuda chegar.",
  "fraco_contra": "Anticura, abates instantâneos e oponentes que ameaçam uma rota para forçar o uso prematuro da especial."
}
```

### Clavento, o fechador de passagens

```json
{
  "id": "clavento",
  "nome": "Clavento",
  "titulo": "o fechador de passagens",
  "classe": "suporte",
  "posicoes": ["suporte"],
  "tema": "Clavento leva um estojo com chaves de portas demolidas. A chave comprida que usa no combate deixa um rastro curvo quando bate no chão.",
  "curva_de_forca": "inicio",
  "dificuldade": 2,
  "dependencia_macro": 3,
  "recurso": {
    "tipo": "mana",
    "maximo": [400, 25],
    "regeneracao_5s": [9, 0.6]
  },
  "atributos": {
    "vida": [621, 83.07],
    "armadura": [31, 3.7],
    "resistencia_magica": [29, 1.17],
    "dano_fisico": [46, 2.72],
    "velocidade_ataque": [0.645, 2.3],
    "alcance": 125,
    "velocidade_movimento": 335
  },
  "passiva": {
    "nome": "Chave emprestada",
    "descricao": "O primeiro aliado que acompanha o engaje recebe um curto impulso.",
    "efeito": "O primeiro campeão aliado que entra no arco de Fecho de Travessia até 2 s após o acerto da especial recebe 10% de movimento por 1,1 s. Um beneficiado por especial e sem acúmulo."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Dente de fechadura",
      "descricao": "Gira a chave para forçar o lado fraco da guarda inimiga.",
      "narracao": "{campeao} gira o dente de fechadura diante de {alvo}!",
      "tipo_dano": "magico",
      "alvo": "cone",
      "dano": {
        "base": [25, 5.24],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.122,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 32,
      "recarga": 8,
      "efeitos": ["Alcance 315 e abertura 65°", "Lentidão de 20% por 1,5 s"],
      "tags": ["controle"]
    },
    {
      "posicao": 2,
      "nome": "Passo de dobradiça",
      "descricao": "Avança meio corpo para alinhar o outro lado da passagem.",
      "narracao": "{campeao} se alinha com um passo de dobradiça!",
      "tipo_dano": "magico",
      "alvo": "si_mesmo",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 34,
      "recarga": 9,
      "efeitos": ["Avanço de até 260 unidades. Não cruza terreno e não é intocável"],
      "tags": ["mobilidade", "engaje"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Fecho de travessia",
      "descricao": "Marca um fecho curvo no chão e trava quem não sair a tempo.",
      "narracao": "{campeao} fecha a travessia sobre os rivais!",
      "tipo_dano": "magico",
      "alvo": "area",
      "dano": {
        "base": [16, 3.35],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.078,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 54,
      "recarga": 68,
      "efeitos": [
        "Alcance 420, arco com largura 185, aviso de 0,65 s",
        "Atordoamento em área de 0,75 s",
        "Disponível a partir do nível 6."
      ],
      "tags": [
        "controle",
        "area",
        "engaje"
      ]
    }
  ],
  "build_recomendada": [
    "Grevas de Ferro",
    "Medalhão dos Eternos",
    "Égide de Aço",
    "Manto dos Ventos Gélidos",
    "Escudo do Guardião"
  ],
  "itens_alternativos": [
    {
      "item": "Botas do Andarilho",
      "quando": "para rotar antes e preparar o fecho em um objetivo",
      "substitui": "Grevas de Ferro"
    },
    {
      "item": "Sandálias da Sabedoria",
      "quando": "contra magia e controle que cancelam sua chegada à primeira linha",
      "substitui": "Grevas de Ferro"
    },
    {
      "item": "Tocha do Tormento",
      "quando": "contra curas dos rivais que recuam após a primeira troca",
      "substitui": "Manto dos Ventos Gélidos"
    }
  ],
  "forte_contra": "Adversários corpo a corpo que passam juntos por entradas estreitas.",
  "fraco_contra": "Times que exploram o intervalo após errar o avanço e mantêm os carregadores separados."
}
```

### Ocravia, a cartógrafa do subsolo

```json
{
  "id": "ocravia",
  "nome": "Ocravia",
  "titulo": "a cartógrafa do subsolo",
  "classe": "suporte",
  "posicoes": ["suporte"],
  "tema": "Ocravia desenha mapas em papel azul e segura o estojo por argolas como as de um sino. Seu trabalho aparece em linhas quadriculadas nos pontos que o time precisa atravessar.",
  "curva_de_forca": "constante",
  "dificuldade": 2,
  "dependencia_macro": 3,
  "recurso": {
    "tipo": "mana",
    "maximo": [400, 25],
    "regeneracao_5s": [9, 0.6]
  },
  "atributos": {
    "vida": [580, 95.0],
    "armadura": [31, 4.18],
    "resistencia_magica": [29, 1.31],
    "dano_fisico": [48, 3.03],
    "velocidade_ataque": [0.62, 2.5],
    "alcance": 525,
    "velocidade_movimento": 330
  },
  "passiva": {
    "nome": "Retícula fiel",
    "descricao": "Ocravia consegue guiar o escudo melhor se tiver acabado de observar a entrada.",
    "efeito": "Se o alvo aliado da Guarda de Retícula estiver dentro de Baliza de Cal, o escudo dura 0,6 s a mais. Só afeta a duração e não renova o efeito."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Giz no caminho",
      "descricao": "Lança um pedaço de giz escuro que segura o primeiro rival na rota.",
      "narracao": "{campeao} deixa um traço de giz diante de {alvo}!",
      "tipo_dano": "magico",
      "alvo": "linha",
      "dano": {
        "base": [35, 7.76],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.378,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 34,
      "recarga": 8,
      "efeitos": ["Alcance 575, largura 70", "Lentidão de 25% por 1,5 s no primeiro campeão"],
      "tags": ["controle"]
    },
    {
      "posicao": 2,
      "nome": "Guarda de retícula",
      "descricao": "Abre o estojo diante do aliado para absorver o próximo golpe.",
      "narracao": "{campeao} desenha uma guarda para {alvo}!",
      "tipo_dano": "magico",
      "alvo": "aliado",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 35,
      "recarga": 9,
      "efeitos": [
        "Alcance 600",
        "Escudo de 4,5% da vida máxima do alvo + 17% PM por 2,4 s, limitado a 8% da vida do aliado"
      ],
      "tags": ["escudo", "aliado"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Baliza de cal",
      "descricao": "Estende um mapa de chão e define uma zona que o time pode observar.",
      "narracao": "{campeao} marca a passagem com uma baliza de cal!",
      "tipo_dano": "magico",
      "alvo": "area",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 51,
      "recarga": 86,
      "efeitos": [
        "Alcance 1400, raio 225 por 3 s",
        "Avisa a área após 0,5 s e revela o conteúdo enquanto estiver ativa",
        "Um aliado dentro da baliza por lançamento recebe um escudo de 4% da vida máxima por 2 s. Escolhe o de menor % de vida, sem somar a Guarda de Retícula",
        "Disponível a partir do nível 6."
      ],
      "tags": [
        "visao",
        "mapa",
        "escudo"
      ]
    }
  ],
  "build_recomendada": [
    "Botas do Andarilho",
    "Lanterna do Vigia",
    "Medalhão dos Eternos",
    "Manto dos Ventos Gélidos",
    "Tocha do Tormento"
  ],
  "itens_alternativos": [
    {
      "item": "Sandálias da Sabedoria",
      "quando": "contra controle prolongado e explosão mágica nas entradas",
      "substitui": "Botas do Andarilho"
    },
    {
      "item": "Escudo do Guardião",
      "quando": "contra uma ameaça mágica dominante e poucos atacantes rápidos",
      "substitui": "Manto dos Ventos Gélidos"
    },
    {
      "item": "Égide de Aço",
      "quando": "contra cura de atacantes que batem no próprio suporte durante a disputa",
      "substitui": "Tocha do Tormento"
    }
  ],
  "forte_contra": "Lutas por objetivo que premiam chegar primeiro e proteger um aliado já bem posicionado.",
  "fraco_contra": "Rivais que deixam a área marcada expirar e entram de lado ou que atacam antes de montar a retícula."
}
```

### Terralume, o prospector de clarões

```json
{
  "id": "terralume",
  "nome": "Terralume",
  "titulo": "o prospector de clarões",
  "classe": "atirador",
  "posicoes": ["atirador"],
  "tema": "Terralume mede a dureza de pedras raras pelo brilho deixado atrás do impacto. O cano do seu instrumento abre três abas quando ele assume uma linha de tiro.",
  "curva_de_forca": "fim",
  "dificuldade": 3,
  "dependencia_macro": 2,
  "recurso": {
    "tipo": "mana",
    "maximo": [320, 22],
    "regeneracao_5s": [7, 0.5]
  },
  "atributos": {
    "vida": [515, 107.56],
    "armadura": [24, 4.51],
    "resistencia_magica": [29, 1.45],
    "dano_fisico": [57, 4.5],
    "velocidade_ataque": [0.672, 3.78],
    "alcance": 650,
    "velocidade_movimento": 325
  },
  "passiva": {
    "nome": "Visor desdobrado",
    "descricao": "Terralume encontra o primeiro disparo de longe se teve tempo de parar.",
    "efeito": "Depois de permanecer 1,1 s sem mover-se, o primeiro ataque contra campeão tem +9 pontos percentuais de chance crítica, respeitando 100%. Intervalo de 8 s e consumo no disparo. A chance extra não se aplica a habilidades."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Impacto de amostra",
      "descricao": "Dispara uma amostra de pedra pelo visor.",
      "narracao": "{campeao} lança a amostra contra {alvo}!",
      "tipo_dano": "fisico",
      "alvo": "linha",
      "dano": {
        "base": [11, 4.6],
        "proporcoes": {
          "dano_fisico_bonus": 0.406,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 28,
      "recarga": 7.5,
      "efeitos": [
        "Alcance 780, largura 55",
        "Para no primeiro campeão. Dano da habilidade não recebe multiplicador crítico"
      ],
      "tags": ["precisao", "longo_alcance"]
    },
    {
      "posicao": 2,
      "nome": "Tripé aberto",
      "descricao": "Trava o tripé por pouco tempo para estabilizar a primeira troca.",
      "narracao": "{campeao} abre o tripé e firma a mira!",
      "tipo_dano": "fisico",
      "alvo": "si_mesmo",
      "dano": {
        "base": [0, 0.0],
        "proporcoes": {
          "dano_fisico_bonus": 0.0,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 22,
      "recarga": 8.5,
      "efeitos": [
        "Por 2 s, reduz em 20% relativos a força das lentidões que receber",
        "Não reduz atordoamento, não aumenta alcance e termina se Terralume andar mais de 150"
      ],
      "tags": ["protecao"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Teste de campo",
      "descricao": "Usa a última placa do visor para disparar numa faixa bem comprida.",
      "narracao": "{campeao} dispara o teste de campo pela rota!",
      "tipo_dano": "fisico",
      "alvo": "linha",
      "dano": {
        "base": [10, 4.24],
        "proporcoes": {
          "dano_fisico_bonus": 0.375,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 46,
      "recarga": 78,
      "efeitos": [
        "Alcance 1000, largura 72, aviso de 0,65 s",
        "Primeiro campeão recebe dano integral. Os demais recebem 65%",
        "Disponível a partir do nível 6."
      ],
      "tags": [
        "longo_alcance",
        "precisao",
        "critico"
      ]
    }
  ],
  "build_recomendada": [
    "Botas da Fúria",
    "Lâmina Cristalina",
    "Asas do Vento Veloz",
    "Arco do Juízo Final",
    "Sanguessuga Rubra"
  ],
  "itens_alternativos": [
    {
      "item": "Escudo do Guardião",
      "quando": "contra explosão mágica que mata antes dos primeiros ataques",
      "substitui": "Sanguessuga Rubra"
    },
    {
      "item": "Cetro-Lâmina do Crepúsculo",
      "quando": "quando a resistência física é alta e uma parcela mágica extra vale mais que a cura",
      "substitui": "Sanguessuga Rubra"
    },
    {
      "item": "Botas do Andarilho",
      "quando": "quando a sobrevivência depende mais de reposicionamento que de recarga de ataque",
      "substitui": "Botas da Fúria"
    }
  ],
  "forte_contra": "Frágeis expostos atrás de uma linha de frente aliada bem montada.",
  "fraco_contra": "Engajes laterais e Couraça do Gigante de Pedra em campeões que conseguem impedir a mira."
}
```

### Zarcavil, a tropeira de roldanas

```json
{
  "id": "zarcavil",
  "nome": "Zarcavil",
  "titulo": "a tropeira de roldanas",
  "classe": "atirador",
  "posicoes": ["atirador"],
  "tema": "Zarcavil conduzia cabos de aço entre pontes antigas. A besta de roldanas que saiu do trabalho ganha uma vibração grave quando ela mantém o mesmo alvo no fio de visão.",
  "curva_de_forca": "constante",
  "dificuldade": 2,
  "dependencia_macro": 1,
  "recurso": {
    "tipo": "mana",
    "maximo": [320, 22],
    "regeneracao_5s": [7, 0.5]
  },
  "atributos": {
    "vida": [538, 95.95],
    "armadura": [27, 3.98],
    "resistencia_magica": [29, 1.31],
    "dano_fisico": [60, 4.0],
    "velocidade_ataque": [0.7, 3.5],
    "alcance": 540,
    "velocidade_movimento": 330
  },
  "passiva": {
    "nome": "Molde repetido",
    "descricao": "Os ataques ficam mais rápidos se Zarcavil permanece no mesmo alvo.",
    "efeito": "Dois ataques básicos no mesmo campeão em até 2,5 s concedem +7% de velocidade de ataque por 2 s. Trocar de alvo desfaz o efeito. Não acumula e a velocidade final respeita o teto de 2,5 ataques/s."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Roldana marcada",
      "descricao": "Acerta a roldana no ponto que precisa de mais pressão.",
      "narracao": "{campeao} marca {alvo} com a roldana!",
      "tipo_dano": "fisico",
      "alvo": "unico",
      "dano": {
        "base": [17, 2.67],
        "proporcoes": {
          "dano_fisico_bonus": 0.225,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0.023,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 25,
      "recarga": 8,
      "efeitos": [
        "Alcance 575",
        "Parcela percentual uma única vez, apenas contra campeões",
        "O dano não ativa efeitos de ataque básico"
      ],
      "tags": ["antitanque"]
    },
    {
      "posicao": 2,
      "nome": "Cabo de reboque",
      "descricao": "Arrasta um cabo rasteiro para que o alvo não consiga sair da zona de disparo tão cedo.",
      "narracao": "{campeao} estica um cabo rente ao chão!",
      "tipo_dano": "fisico",
      "alvo": "linha",
      "dano": {
        "base": [8, 1.23],
        "proporcoes": {
          "dano_fisico_bonus": 0.103,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 26,
      "recarga": 8,
      "efeitos": ["Alcance 605, largura 67", "Lentidão de 22% por 1,4 s no primeiro campeão atingido"],
      "tags": ["controle"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Costura de aço",
      "descricao": "Pressiona a mesma falha que vinha marcando nos ataques.",
      "narracao": "{campeao} costura a guarda de {alvo} com aço!",
      "tipo_dano": "fisico",
      "alvo": "unico",
      "dano": {
        "base": [10, 1.67],
        "proporcoes": {
          "dano_fisico_bonus": 0.141,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 45,
      "recarga": 70,
      "efeitos": [
        "Alcance 590",
        "Causa dano uma vez. Este acerto não é um ataque básico nem aciona efeitos ao acertar",
        "Disponível a partir do nível 6."
      ],
      "tags": ["antitanque", "precisao"]
    }
  ],
  "build_recomendada": [
    "Botas da Fúria",
    "Cetro-Lâmina do Crepúsculo",
    "Asas do Vento Veloz",
    "Arco do Juízo Final",
    "Sanguessuga Rubra"
  ],
  "itens_alternativos": [
    {
      "item": "Escudo do Guardião",
      "quando": "contra explosão mágica que impede chegar à sequência de ataques",
      "substitui": "Sanguessuga Rubra"
    },
    {
      "item": "Lâmina Cristalina",
      "quando": "contra resistência mágica alta e linha de frente com pouca proteção a crítico",
      "substitui": "Cetro-Lâmina do Crepúsculo"
    },
    {
      "item": "Botas do Andarilho",
      "quando": "contra ameaças que exigem acompanhar o alvo trocando constantemente de ângulo",
      "substitui": "Botas da Fúria"
    }
  ],
  "forte_contra": "Tanques expostos que dão tempo para manter o mesmo alvo e capitalizar velocidade de ataque.",
  "fraco_contra": "Pressão lateral que força a mudar de alvo, pouco tempo para atirar e redução de velocidade de ataque."
}
```

### Riscavela, a pintora de mastros

```json
{
  "id": "riscavela",
  "nome": "Riscavela",
  "titulo": "a pintora de mastros",
  "classe": "atirador",
  "posicoes": ["atirador"],
  "tema": "Riscavela pendura tiras de tinta em mastros móveis e atira por entre as cores. O injetor solta uma faísca azul junto do impacto físico.",
  "curva_de_forca": "fim",
  "dificuldade": 3,
  "dependencia_macro": 2,
  "recurso": {
    "tipo": "mana",
    "maximo": [320, 22],
    "regeneracao_5s": [7, 0.5]
  },
  "atributos": {
    "vida": [515, 107.56],
    "armadura": [25, 4.5],
    "resistencia_magica": [31, 1.43],
    "dano_fisico": [58, 4.48],
    "velocidade_ataque": [0.672, 3.78],
    "alcance": 560,
    "velocidade_movimento": 330
  },
  "passiva": {
    "nome": "Camadas de verniz",
    "descricao": "Quanto mais confrontos diferentes ela atravessa, mais fácil enlata o próximo disparo.",
    "efeito": "A cada três ataques básicos no mesmo campeão ao longo de até 4 s, ganha uma camada. Uma a cada 35 s, até 5. Cada camada acrescenta 16 de alcance, até +80, a Tiro de Mistura. Camadas permanentes na partida, sem aumento de dano ou alcance básico."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Tiro de mistura",
      "descricao": "Dispara tinta pesada com duas temperaturas.",
      "narracao": "{campeao} mistura duas tintas no disparo contra {alvo}!",
      "tipo_dano": "misto",
      "alvo": "linha",
      "dano": {
        "base": [6, 5.16],
        "proporcoes": {
          "dano_fisico_bonus": 0.223,
          "poder_magico": 0.167,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 28,
      "recarga": 7.5,
      "efeitos": [
        "Alcance 610 antes das camadas, largura 65",
        "Primeiro campeão na linha. Não ativa efeitos de ataque básico",
        "Divisão do dano final bruto: 58% físico e 42% mágico, com mitigação separada."
      ],
      "tags": ["dano_misto", "acumulo_limitado"]
    },
    {
      "posicao": 2,
      "nome": "Faixa de gotejo",
      "descricao": "Deixa tinta baixa onde o alvo tem mais chance de passar.",
      "narracao": "{campeao} deixa uma faixa de tinta na passagem!",
      "tipo_dano": "magico",
      "alvo": "area",
      "dano": {
        "base": [3, 2.41],
        "proporcoes": {
          "dano_fisico_bonus": 0.104,
          "poder_magico": 0.078,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 26,
      "recarga": 8.5,
      "efeitos": ["Alcance 470 e raio 125", "Lentidão de 22% por 1,3 s"],
      "tags": ["controle"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Verniz poroso",
      "descricao": "Pressiona o alvo marcado com uma descarga curta de duas cores.",
      "narracao": "{campeao} solta o verniz poroso sobre {alvo}!",
      "tipo_dano": "misto",
      "alvo": "unico",
      "dano": {
        "base": [5, 3.89],
        "proporcoes": {
          "dano_fisico_bonus": 0.169,
          "poder_magico": 0.126,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 42,
      "recarga": 78,
      "efeitos": [
        "Alcance 575",
        "Exige que um ataque básico de Riscavela tenha acertado o alvo nos últimos 3 s",
        "Causa dano uma vez e não aciona efeitos ao acertar. Os ataques normais continuam acionando itens elegíveis",
        "Divisão do dano final bruto: 50% físico e 50% mágico, com mitigação separada.",
        "Disponível a partir do nível 6."
      ],
      "tags": ["dano_misto", "ao_acertar"]
    }
  ],
  "build_recomendada": [
    "Botas da Fúria",
    "Cetro-Lâmina do Crepúsculo",
    "Asas do Vento Veloz",
    "Sanguessuga Rubra",
    "Arco do Juízo Final"
  ],
  "itens_alternativos": [
    {
      "item": "Escudo do Guardião",
      "quando": "contra magia que impede empilhar ataques no alvo",
      "substitui": "Sanguessuga Rubra"
    },
    {
      "item": "Lâmina Cristalina",
      "quando": "contra frágeis com resistência mágica alta e pouca ameaça de desgaste",
      "substitui": "Sanguessuga Rubra"
    },
    {
      "item": "Botas do Andarilho",
      "quando": "quando o movimento deixa terminar o terceiro ataque com mais frequência",
      "substitui": "Botas da Fúria"
    }
  ],
  "forte_contra": "Equipes com uma única resistência e lutas em que pode manter o alvo à vista.",
  "fraco_contra": "Rivais que forçam trocas curtas cedo ou proteção que nega o terceiro ataque seguido."
}
```

### Fulcrim, o vigia de pulso seco

```json
{
  "id": "fulcrim",
  "nome": "Fulcrim",
  "titulo": "o vigia de pulso seco",
  "classe": "atirador",
  "posicoes": ["atirador"],
  "tema": "Fulcrim carregava um repetidor de corda nas salinas. Cada batida da arma faz um estalo curto, sem brilho, que se ouve antes do impacto.",
  "curva_de_forca": "inicio",
  "dificuldade": 1,
  "dependencia_macro": 1,
  "recurso": {
    "tipo": "nenhum",
    "maximo": [0, 0],
    "regeneracao_5s": [0, 0]
  },
  "atributos": {
    "vida": [543, 85.18],
    "armadura": [27, 3.52],
    "resistencia_magica": [29, 1.17],
    "dano_fisico": [65, 3.48],
    "velocidade_ataque": [0.728, 3.22],
    "alcance": 525,
    "velocidade_movimento": 335
  },
  "passiva": {
    "nome": "Mola em espera",
    "descricao": "Fulcrim mantém o ritmo com ataques enquanto os disparos especiais recarregam.",
    "efeito": "Enquanto as duas habilidades básicas estiverem em recarga, acertar dois ataques normais em campeões dentro de 2,5 s dá 8 unidades de movimento por 1,6 s. Intervalo de 8 s, sem acúmulo."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Disparo seco",
      "descricao": "Atira à queima-roupa para impor a primeira troca.",
      "narracao": "{campeao} abre a troca com um disparo seco em {alvo}!",
      "tipo_dano": "fisico",
      "alvo": "unico",
      "dano": {
        "base": [14, 5.5],
        "proporcoes": {
          "dano_fisico_bonus": 0.195,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 0,
      "recarga": 9.2,
      "efeitos": ["Alcance 530", "O dano não é crítico e não repete efeitos ao acertar"],
      "tags": ["troca", "pressao"]
    },
    {
      "posicao": 2,
      "nome": "Corda pelo chão",
      "descricao": "Lança a corda na frente do rival para retardar a saída.",
      "narracao": "{campeao} estica uma corda pelo chão!",
      "tipo_dano": "fisico",
      "alvo": "linha",
      "dano": {
        "base": [6, 2.38],
        "proporcoes": {
          "dano_fisico_bonus": 0.084,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 0,
      "recarga": 9.2,
      "efeitos": ["Alcance 490, largura 66", "Só acerta o primeiro campeão. Lentidão de 20% por 1,5 s"],
      "tags": ["controle"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Trava do repetidor",
      "descricao": "Solta a mola já regulada num disparo único.",
      "narracao": "{campeao} solta a trava do repetidor contra {alvo}!",
      "tipo_dano": "fisico",
      "alvo": "unico",
      "dano": {
        "base": [6, 2.49],
        "proporcoes": {
          "dano_fisico_bonus": 0.088,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 0,
      "recarga": 80.5,
      "efeitos": [
        "Alcance 570",
        "Após acertar, Fulcrim ganha 6% de movimento por 1,5 s. Se o bônus da passiva estiver ativo, usa só o maior",
        "Disponível a partir do nível 6."
      ],
      "tags": ["pressao"]
    }
  ],
  "build_recomendada": [
    "Botas da Fúria",
    "Lâmina Cristalina",
    "Sanguessuga Rubra",
    "Asas do Vento Veloz",
    "Arco do Juízo Final"
  ],
  "itens_alternativos": [
    {
      "item": "Escudo do Guardião",
      "quando": "contra magos que podem eliminá-lo antes do primeiro disparo",
      "substitui": "Sanguessuga Rubra"
    },
    {
      "item": "Cetro-Lâmina do Crepúsculo",
      "quando": "se precisar de dano mágico ao acertar contra defesa física e crítico protegido",
      "substitui": "Lâmina Cristalina"
    },
    {
      "item": "Botas do Andarilho",
      "quando": "contra rivais que recuam demais entre cada troca",
      "substitui": "Botas da Fúria"
    }
  ],
  "forte_contra": "Rivais de mana escassa no começo e rotas que aceitam trocas repetidas com alcance curto.",
  "fraco_contra": "Artilharia, linha de frente que escala melhor e ataques que chegam durante o intervalo maior entre habilidades."
}
```

### Treválio, o gravador de alvos

```json
{
  "id": "trevalio",
  "nome": "Treválio",
  "titulo": "o gravador de alvos",
  "classe": "atirador",
  "posicoes": ["meio", "atirador"],
  "tema": "Treválio gravava selos de argila com um bastão de precisão. Agora carrega os alvos riscados na manga e usa a extremidade do bastão como uma mira simples.",
  "curva_de_forca": "constante",
  "dificuldade": 3,
  "dependencia_macro": 2,
  "recurso": {
    "tipo": "mana",
    "maximo": [320, 22],
    "regeneracao_5s": [7, 0.5]
  },
  "atributos": {
    "vida": [538, 95.95],
    "armadura": [25, 4.03],
    "resistencia_magica": [30, 1.3],
    "dano_fisico": [62, 3.97],
    "velocidade_ataque": [0.7, 3.5],
    "alcance": 575,
    "velocidade_movimento": 335
  },
  "passiva": {
    "nome": "Risco persistente",
    "descricao": "Treválio prepara um único disparo verdadeiro com um acerto anterior.",
    "efeito": "Corte de Giz marca o primeiro campeão atingido por 4 s. Só um alvo marcado por vez. Ponto Perfurante exige a marca e a consome ao acertar. A passiva não causa dano."
  },
  "habilidades": [
    {
      "posicao": 1,
      "nome": "Corte de giz",
      "descricao": "Risca o primeiro rival com o bastão estendido.",
      "narracao": "{campeao} grava um risco em {alvo}!",
      "tipo_dano": "fisico",
      "alvo": "linha",
      "dano": {
        "base": [8, 6.09],
        "proporcoes": {
          "dano_fisico_bonus": 0.193,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 28,
      "recarga": 7.5,
      "efeitos": ["Alcance 680, largura 63", "Só marca e acerta o primeiro campeão"],
      "tags": ["marca", "precisao"]
    },
    {
      "posicao": 2,
      "nome": "Ponto perfurante",
      "descricao": "Atira perpendicular ao risco marcado.",
      "narracao": "{campeao} acerta o ponto perfurante em {alvo}!",
      "tipo_dano": "verdadeiro",
      "alvo": "linha",
      "dano": {
        "base": [2, 1.74],
        "proporcoes": {
          "dano_fisico_bonus": 0.055,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 23,
      "recarga": 8.5,
      "efeitos": [
        "Alcance 620 e largura 38",
        "Só causa dano ao campeão marcado. Atingir outro campeão bloqueia o projétil",
        "Sem dano em monstros e estruturas"
      ],
      "tags": ["dano_verdadeiro", "precisao"]
    },
    {
      "posicao": 3,
      "especial": true,
      "nome": "Carimbo na linha",
      "descricao": "Aponta a haste pelo corredor mais reto para abrir espaço.",
      "narracao": "{campeao} carimba a linha de fuga dos rivais!",
      "tipo_dano": "fisico",
      "alvo": "linha",
      "dano": {
        "base": [6, 4.59],
        "proporcoes": {
          "dano_fisico_bonus": 0.146,
          "poder_magico": 0.0,
          "vida_maxima_alvo_pct": 0,
          "vida_perdida_alvo_pct": 0,
          "vida_maxima_propria_pct": 0.0
        }
      },
      "custo": 45,
      "recarga": 68,
      "efeitos": [
        "Alcance 800, largura 72, aviso de 0,55 s",
        "Lentidão de 20% por 1,5 s no primeiro campeão",
        "Disponível a partir do nível 6."
      ],
      "tags": ["controle", "precisao"]
    }
  ],
  "build_recomendada": [
    "Botas da Fúria",
    "Lâmina Cristalina",
    "Arco do Juízo Final",
    "Asas do Vento Veloz",
    "Escudo do Guardião"
  ],
  "itens_alternativos": [
    {
      "item": "Sanguessuga Rubra",
      "quando": "contra desgaste sem ameaça mágica alta, para recuperar vida entre os duelos",
      "substitui": "Escudo do Guardião"
    },
    {
      "item": "Cetro-Lâmina do Crepúsculo",
      "quando": "contra armadura alta ou proteção a crítico, para variar o tipo de dano dos ataques",
      "substitui": "Asas do Vento Veloz"
    },
    {
      "item": "Botas do Andarilho",
      "quando": "para encontrar ângulos fora da linha de minions e contra muito deslocamento rival",
      "substitui": "Botas da Fúria"
    }
  ],
  "forte_contra": "Duelos em corredor claro com tempo para marcar e acertar o segundo tiro.",
  "fraco_contra": "Rivais que fazem o projétil bater numa segunda pessoa e mergulhos rápidos fora do eixo da mira."
}
```
