# Relatório: laboratório de itens

Gerado por `tools/prototipos/laboratorio_itens.py` (dados em `data/itens/itens.json` e `data/config/combate.json`).
Para gerar de novo: `python3 tools/prototipos/laboratorio_itens.py`. O laboratório é um modelo simplificado, não a simulação final da partida.

```

==============================================================================
1. Eficiência em ouro (valor dos atributos ÷ preço; o resto é a passiva)
==============================================================================
  Presa da Serpente                   3050 de ouro | atributos valem  2750 ( 90%)
  Lâmina do Eclipse                   2975 de ouro | atributos valem  2617 ( 88%)
  Manto da Noite Eterna               2925 de ouro | atributos valem  2681 ( 92%)
  Lança Quebra-Escudos                2675 de ouro | atributos valem  2534 ( 95%)
  Arco do Juízo Final                 3550 de ouro | atributos valem  3125 ( 88%)
  Lâmina Cristalina                   3450 de ouro | atributos valem  3100 ( 90%)
  Asas do Vento Veloz                 2425 de ouro | atributos valem  2240 ( 92%)
  Sanguessuga Rubra                   3000 de ouro | atributos valem  2700 ( 90%)
  Cetro-Lâmina do Crepúsculo          3075 de ouro | atributos valem  2762 ( 90%)
  Machado do Gigante                  3300 de ouro | atributos valem  2910 ( 88%)
  Lâmina Sanguinária do Guerreiro     2800 de ouro | atributos valem  2521 ( 90%)
  Martelo das Montanhas               2900 de ouro | atributos valem  2618 ( 90%)
  Grimório Cristalino                 2525 de ouro | atributos valem  2224 ( 88%)
  Cajado do Abismo                    2325 de ouro | atributos valem  2055 ( 88%)
  Foice da Lua Negra                  2775 de ouro | atributos valem  2464 ( 89%)
  Orbe da Tempestade                  2600 de ouro | atributos valem  2280 ( 88%)
  Coroa da Hydra                      2350 de ouro | atributos valem  2106 ( 90%)
  Véu Celestial                       2175 de ouro | atributos valem  2006 ( 92%)
  Tocha do Tormento                   2575 de ouro | atributos valem  2190 ( 85%)
  Égide de Aço                        2225 de ouro | atributos valem  2001 ( 90%)
  Couraça do Gigante de Pedra         2450 de ouro | atributos valem  2068 ( 84%)
  Manto dos Ventos Gélidos            1775 de ouro | atributos valem  1520 ( 86%)
  Escudo do Guardião                  2175 de ouro | atributos valem  1968 ( 90%)
  Coração do Titã                     2425 de ouro | atributos valem  2136 ( 88%)
  Armadura Viva de Cristal            2300 de ouro | atributos valem  2074 ( 90%)
  Lanterna do Vigia                   2400 de ouro | atributos valem  2046 ( 85%)
  Medalhão dos Eternos                1800 de ouro | atributos valem  1540 ( 86%)
  Botas do Andarilho                   725 de ouro | atributos valem   720 ( 99%)
  Grevas de Ferro                     1050 de ouro | atributos valem   940 ( 90%)
  Sandálias da Sabedoria              1300 de ouro | atributos valem  1290 ( 99%)
  Botas do Caçador                     900 de ouro | atributos valem   900 (100%)
  Botas Arcanas                       1025 de ouro | atributos valem  1020 (100%)
  Botas da Fúria                      1425 de ouro | atributos valem  1415 ( 99%)

==============================================================================
2. Letalidade e penetração: valor fixo × porcentagem
==============================================================================
  Multiplicador de dano (quanto do dano passa) contra armadura crescente:
  armadura   sem nada   20 letalidade    20% letalidade   os dois (ordem)   
  30         0.77       0.91             0.81             0.96               melhor isolado: fixo
  60         0.62       0.71             0.68             0.78               melhor isolado: fixo
  90         0.53       0.59             0.58             0.66               melhor isolado: fixo
  120        0.45       0.50             0.51             0.57               melhor isolado: %
  180        0.36       0.38             0.41             0.45               melhor isolado: %
  240        0.29       0.31             0.34             0.37               melhor isolado: %
  300        0.25       0.26             0.29             0.31               melhor isolado: %

  Ponto de virada (fixo × porcentagem) = valor fixo ÷ porcentagem:
    20 de letalidade (Presa) × 20% (Lança): 100 de armadura
    20 de letalidade × 25% (Arco): 80 de armadura
    15 de penetração mágica (Orbe) × 25% (Cajado): 60 de resistência mágica
    15 de penetração mágica × 20% (Foice): 75 de resistência mágica

  Armadura/resistência típicas no fim de jogo (nível 15, build de referência):
    assassino  armadura    89 | resistência mágica    98 | vida  2700
    atirador   armadura    82 | resistência mágica    48 | vida  1890
    mago       armadura    82 | resistência mágica    48 | vida  2190
    lutador    armadura   172 | resistência mágica    57 | vida  3560
    tanque     armadura   218 | resistência mágica   140 | vida  4049
    suporte    armadura   119 | resistência mágica   148 | vida  2460

  Regra: % de itens diferentes não se soma (vale a maior). Exemplo com os 2 itens de letalidade %:
    Lança (20%) + Arco (25%) = 30% efetivo (sem a regra seriam 40% ou 45%)

==============================================================================
3. Valor de cada item por classe (build base: bota + 2 itens; mede o 3º item)
==============================================================================
  100% = média dos itens da MESMA categoria (dano ou defesa) para a classe.
  Acima de 125%: candidato a obrigatório. Abaixo de 70%: fraco para essa classe.
  Tanque e suporte usam duas bases (uma com armadura, outra com resistência mágica) e tiram a média,
  para não confundir 'complementa o que falta' com 'item forte demais'.

  ASSASSINO (bases: Botas do Caçador, Presa da Serpente, Lâmina do Eclipse)
    Lança Quebra-Escudos                129%  <-- forte demais?
    Manto da Noite Eterna               123%
    Machado do Gigante                  106%
    Sanguessuga Rubra                    42%  (fraco para esta classe)

  ATIRADOR (bases: Botas da Fúria, Lâmina Cristalina, Asas do Vento Veloz)
    Arco do Juízo Final                 116%
    Lança Quebra-Escudos                107%
    Cetro-Lâmina do Crepúsculo           96%
    Sanguessuga Rubra                    81%

  MAGO (bases: Botas Arcanas, Orbe da Tempestade, Grimório Cristalino)
    Cajado do Abismo                    139%  <-- forte demais?
    Tocha do Tormento                   113%
    Foice da Lua Negra                  105%
    Coroa da Hydra                       74%
    Véu Celestial                        69%  (fraco para esta classe)

  LUTADOR (bases: Botas do Caçador, Machado do Gigante, Lâmina Sanguinária do Guerreiro)
    Presa da Serpente                   123%
    Lança Quebra-Escudos                111%
    Manto da Noite Eterna               109%
    Cetro-Lâmina do Crepúsculo           96%
    Martelo das Montanhas                90%
    Sanguessuga Rubra                    70%  (fraco para esta classe)
    Coração do Titã                     129%  <-- forte demais?
    Armadura Viva de Cristal            106%
    Escudo do Guardião                   94%
    Égide de Aço                         94%
    Couraça do Gigante de Pedra          93%
    Manto dos Ventos Gélidos             83%

  TANQUE (bases: Grevas de Ferro, Coração do Titã, Égide de Aço | Sandálias da Sabedoria, Coração do Titã, Escudo do Guardião)
    Couraça do Gigante de Pedra         115%
    Manto dos Ventos Gélidos            110%
    Medalhão dos Eternos                 91%
    Armadura Viva de Cristal             84%

  SUPORTE (bases: Sandálias da Sabedoria, Medalhão dos Eternos, Lanterna do Vigia | Grevas de Ferro, Medalhão dos Eternos, Lanterna do Vigia)
    Coroa da Hydra                      151%  <-- forte demais?
    Véu Celestial                        84%
    Tocha do Tormento                    65%  (fraco para esta classe)
    Escudo do Guardião                  106%
    Égide de Aço                        100%
    Manto dos Ventos Gélidos             94%

==============================================================================
4. Melhores builds por classe contra cada composição inimiga
==============================================================================

  ASSASSINO
    contra frageis:    Botas do Caçador, Presa da Serpente, Lâmina do Eclipse, Manto da Noite Eterna, Lança Quebra-Escudos  (melhor/mediana = 1.54)
    contra equilibrada: Botas do Caçador, Presa da Serpente, Lâmina do Eclipse, Manto da Noite Eterna, Lança Quebra-Escudos  (melhor/mediana = 1.56)
    contra tanques:    Botas do Caçador, Presa da Serpente, Lâmina do Eclipse, Manto da Noite Eterna, Lança Quebra-Escudos  (melhor/mediana = 1.34)
    itens mais presentes nas 10 melhores builds (3 composições, 30 builds):
      Lâmina do Eclipse (29), Presa da Serpente (28), Lança Quebra-Escudos (24), Manto da Noite Eterna (20), Machado do Gigante (12), Sanguessuga Rubra (7)

  ATIRADOR
    contra frageis:    Botas da Fúria, Arco do Juízo Final, Lâmina Cristalina, Asas do Vento Veloz, Cetro-Lâmina do Crepúsculo  (melhor/mediana = 1.40)
    contra equilibrada: Botas da Fúria, Arco do Juízo Final, Lâmina Cristalina, Asas do Vento Veloz, Cetro-Lâmina do Crepúsculo  (melhor/mediana = 1.46)
    contra tanques:    Botas da Fúria, Arco do Juízo Final, Lâmina Cristalina, Asas do Vento Veloz, Cetro-Lâmina do Crepúsculo  (melhor/mediana = 1.41)
    itens mais presentes nas 10 melhores builds (3 composições, 30 builds):
      Lâmina Cristalina (29), Asas do Vento Veloz (27), Arco do Juízo Final (22), Cetro-Lâmina do Crepúsculo (17), Sanguessuga Rubra (12), Lança Quebra-Escudos (10)

  MAGO
    contra frageis:    Botas Arcanas, Grimório Cristalino, Foice da Lua Negra, Orbe da Tempestade, Tocha do Tormento  (melhor/mediana = 1.31)
    contra equilibrada: Botas Arcanas, Grimório Cristalino, Foice da Lua Negra, Orbe da Tempestade, Coroa da Hydra  (melhor/mediana = 1.28)
    contra tanques:    Botas Arcanas, Grimório Cristalino, Foice da Lua Negra, Orbe da Tempestade, Escudo do Guardião  (melhor/mediana = 1.06)
    itens mais presentes nas 10 melhores builds (3 composições, 30 builds):
      Orbe da Tempestade (30), Grimório Cristalino (29), Tocha do Tormento (15), Coroa da Hydra (14), Foice da Lua Negra (12), Cajado do Abismo (11)

  LUTADOR
    contra frageis:    Botas da Fúria, Presa da Serpente, Manto da Noite Eterna, Martelo das Montanhas, Coração do Titã  (melhor/mediana = 1.33)
    contra equilibrada: Botas da Fúria, Presa da Serpente, Manto da Noite Eterna, Lança Quebra-Escudos, Machado do Gigante  (melhor/mediana = 1.35)
    contra tanques:    Botas da Fúria, Presa da Serpente, Manto da Noite Eterna, Lança Quebra-Escudos, Martelo das Montanhas  (melhor/mediana = 1.22)
    itens mais presentes nas 10 melhores builds (3 composições, 30 builds):
      Presa da Serpente (29), Manto da Noite Eterna (22), Lança Quebra-Escudos (20), Martelo das Montanhas (19), Machado do Gigante (11), Cetro-Lâmina do Crepúsculo (8)

  TANQUE
    contra frageis:    Grevas de Ferro, Martelo das Montanhas, Couraça do Gigante de Pedra, Coração do Titã, Armadura Viva de Cristal  (melhor/mediana = 1.14)
    contra equilibrada: Grevas de Ferro, Martelo das Montanhas, Couraça do Gigante de Pedra, Escudo do Guardião, Coração do Titã  (melhor/mediana = 1.06)
    contra tanques:    Botas do Andarilho, Martelo das Montanhas, Égide de Aço, Couraça do Gigante de Pedra, Manto dos Ventos Gélidos  (melhor/mediana = 1.00)
    itens mais presentes nas 10 melhores builds (3 composições, 30 builds):
      Martelo das Montanhas (27), Couraça do Gigante de Pedra (22), Coração do Titã (21), Égide de Aço (19), Escudo do Guardião (12), Manto dos Ventos Gélidos (9)

  SUPORTE
    contra frageis:    Grevas de Ferro, Coroa da Hydra, Égide de Aço, Escudo do Guardião, Medalhão dos Eternos  (melhor/mediana = 1.25)
    contra equilibrada: Grevas de Ferro, Coroa da Hydra, Égide de Aço, Escudo do Guardião, Medalhão dos Eternos  (melhor/mediana = 1.17)
    contra tanques:    Grevas de Ferro, Coroa da Hydra, Égide de Aço, Lanterna do Vigia, Medalhão dos Eternos  (melhor/mediana = 1.14)
    itens mais presentes nas 10 melhores builds (3 composições, 30 builds):
      Medalhão dos Eternos (29), Égide de Aço (25), Escudo do Guardião (21), Coroa da Hydra (16), Lanterna do Vigia (14), Manto dos Ventos Gélidos (12)

==============================================================================
5. Testes de estresse e limites
==============================================================================
  [ok] Assassino (bota + 3 dano + 1 vida) em 3 s tira 75–115% da vida de um atirador: 79%
  [ok] ... e de um mago com item defensivo (Coroa da Hydra): 65–115%: 68%
  [ok] ... mas não mais que 40% de um tanque: 18%
  [ok] Atirador completo derruba um tanque completo em 6–14 s: 12.1 s
  [ok] Atirador completo derruba um mago em 1,8–4,5 s: 3.3 s
  [ok] Mago em 3 s tira 55–105% da vida de um atirador: 56%
  [ok] Tanque aguenta pelo menos 2,2× mais que um frágil: 3.2x
      (duelo atirador × lutador, sem distância: atirador matou em 10.5s, lutador em -)
  [ok] Lutador e atirador equilibrados no duelo (razão dos tempos 0,5–2,0): 1.01
  [ok] Penetração mágica %% não acumula (Cajado 25%% + Foice 20%% = 25%%)
  [ok] Dois escudos de vida baixa não acumulam (mesmo grupo)

  Interações entre itens:
  [ok] Anticura (Égide de Aço) corta a cura do roubo de vida do atirador: 240 → 168 em 6 s
  [ok] Couraça (contra crítico) segura o atirador de crítico tão bem quanto a Égide: 12.1 s × 14.3 s
  [ok] Escudo do Guardião + Sandálias protegem o atirador da explosão do mago: 56% → 33%
  [ok] Letalidade % rende mais contra tanque do que contra frágil (ganho com a Lança: frágil +0%, tanque +12%)

  Peso da passiva no valor do item (passiva desligada → quanto o item perde):
    Presa da Serpente                  (assassino)   2%
    Lâmina do Eclipse                  (assassino)  29%
    Manto da Noite Eterna              (assassino)   9%
    Lâmina Cristalina                  (atirador)  10%
    Asas do Vento Veloz                (atirador)  24%
    Sanguessuga Rubra                  (assassino)   0%
    Cetro-Lâmina do Crepúsculo         (atirador)  30%
    Machado do Gigante                 (assassino)   1%
    Lâmina Sanguinária do Guerreiro    (lutador)  11%
    Martelo das Montanhas              (lutador)  14%
    Grimório Cristalino                (mago)  25%
    Orbe da Tempestade                 (mago)  24%
    Coroa da Hydra                     (mago)  28%
    Véu Celestial                      (mago)  21%
    Tocha do Tormento                  (mago)  33%
    Égide de Aço                       (lutador)   0%
    Couraça do Gigante de Pedra        (lutador)   8%
    Manto dos Ventos Gélidos           (lutador)  32%
    Escudo do Guardião                 (assassino)  24%
    Coração do Titã                    (lutador)  44%
    Armadura Viva de Cristal           (lutador)   0%
    Lanterna do Vigia                  (suporte)  40%
    Medalhão dos Eternos               (tanque)   0%

==============================================================================
Resumo
==============================================================================
  2 ponto(s) de atenção:
   - suporte/Coroa da Hydra
   - mago: Orbe da Tempestade em todas as melhores builds
```
