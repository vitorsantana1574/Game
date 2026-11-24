# Relatório: ritmo da partida de Crystal Legends

Gerado pelo protótipo `tools/prototipos/ritmo_partida.py`, com os números de `data/config/partida.json`.
O protótipo **não é a simulação final** (etapa 5): é um modelo simplificado para testar se os números geram partidas com boa duração e emoção.

Para gerar de novo: `python3 tools/prototipos/ritmo_partida.py --partidas 2000`

## Metas e resultado

| Métrica | Meta | Resultado |
|---|---|---|
| Duração (mediana) | 28–32 min | **32,4 min** |
| Partidas abaixo de 22 min | ≤ 10% | **3,8%** |
| Partidas acima de 40 min | ≤ 8% | **8,3%** (no limite) |
| Partidas sem fim aos 50 min | ~0% | **0,1%** |
| Abates por partida | 25–35 | **32,7** |
| Virada de quem está 2.500+ de ouro atrás aos 15 min | 20–30% | **33,2%** (um pouco acima, de propósito) |
| Time 5 / 10 / 20 pontos melhor vence | ~60 / ~70 / ~88% | **65 / 74 / 90%** |
| Ouro do suporte em relação ao atirador (25 min) | 70–75% | **73%** |
| Monstros épicos por partida (cada) | ~3 | **Hydra 3,5 / Cérbero 3,9** |
| Maior intervalo sem acontecimentos depois dos 10 min | ≤ 3 min | **3,1 min** |

## Ajustes da 2ª rodada

- Item de suporte (ouro sem depender do Farm do suporte): suporte foi de 60% para **73%** do ouro do atirador.
- XP da selva +10%: caçador subiu de 11,8 para **12,4** de nível médio aos 25 min.
- Monstros épicos reaparecendo a cada **6 min** (antes 4): de ~4,7 para ~3,7 de cada por partida.
- Ordem de itens adaptada pelo Macro e compras arriscadas pelo Micro (efeito pequeno na força).

## Comparações feitas

- **Nível máximo 14, 16 ou 18:** quase não muda o ritmo (duração de 31,7 a 32,3 min). Escolhido **16**: o laner solo chega lá por volta dos 26–30 min, quando a partida se decide.
- **Com e sem "tensão final":** a mediana quase não muda, mas a regra corta a cauda de partidas longas (acima de 40 min: 7,9% → 5,9%). Mantida como rede de segurança.

## Saída completa da última rodada

```
=== Crystal Legends — ritmo da partida (2000 partidas, nível máximo 16, tensão final ligada) ===

Progressão com farm perfeito:
  nível  2: rota solo 1:58 | rota dupla 2:07 | selva 2:07
  nível  5: rota solo 4:22 | rota dupla 5:19 | selva 5:18
  nível  6: rota solo 5:30 | rota dupla 6:50 | selva 6:49
  nível  9: rota solo 9:54 | rota dupla 12:42 | selva 12:40
  nível 11: rota solo 13:40 | rota dupla 17:43 | selva 17:41
  nível 13: rota solo 18:06 | rota dupla 23:38 | selva 23:35
  nível 16: rota solo 26:00 | rota dupla 34:10 | selva 34:06
  Cérbero aparece em 4:22 (nível 5 teórico); Hydra em 9:54 (nível 9 teórico)

Renascimento: nível 1: 9s, nível 6: 22s, nível 11: 35s, nível 16: 48s | nível máx. aos 35 min: 57s
Itens do atirador (mediana): bota 5 min, item 2 13, item 3 21, item 4 29, item 5 37

Partidas entre times iguais:
  duração: mediana 32.4 min (10% abaixo de 25.2, 10% acima de 39.6)
  terminam antes de 22 min: 3.8% | passam de 40 min: 8.3% | chegam a 50 min sem fim: 0.1%
  abates por partida: 32.7 | lutas em equipe: 10.7
  viradas na liderança de ouro (após 8 min): 0.66 por partida
  time atrás 2.500+ de ouro aos 15 min vence: 33.2%
  maior intervalo sem acontecimentos (mediana): 3.5 min no jogo todo, 3.1 min depois dos 10 min

Chance do time mais forte vencer:
   5 pontos de diferença na qualidade: 65%
  10 pontos de diferença na qualidade: 74%
  20 pontos de diferença na qualidade: 90%
```
