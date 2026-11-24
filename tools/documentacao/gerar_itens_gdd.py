#!/usr/bin/env python3
"""Gera a seção '7.2 Itens' do docs/GDD.md a partir de data/itens/itens.json.

Uso: python3 tools/documentacao/gerar_itens_gdd.py
Rode sempre que os itens mudarem, para o GDD não ficar diferente dos dados.
"""
import json
import os

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DADOS = json.load(open(os.path.join(RAIZ, "data", "itens", "itens.json"), encoding="utf-8"))
GDD = os.path.join(RAIZ, "docs", "GDD.md")

ABREV = {"dano_fisico": "DF", "poder_magico": "PM", "vida": "Vida", "armadura": "Armadura", "resistencia_magica": "RM",
         "velocidade_ataque": "Vel. ataque", "critico": "Crítico", "aceleracao": "Aceleração", "roubo_vida": "Roubo de vida",
         "letalidade": "Letalidade", "penetracao_armadura_pct": "Letalidade", "penetracao_magica": "Pen. mágica",
         "penetracao_magica_pct": "Pen. mágica", "velocidade_movimento": "Vel. movimento", "tenacidade": "Tenacidade"}
PCT = {"velocidade_ataque", "critico", "roubo_vida", "penetracao_armadura_pct", "penetracao_magica_pct", "tenacidade"}
CLASSE = {"assassino": "Assassino", "atirador": "Atirador", "mago": "Mago", "lutador": "Lutador", "tanque": "Tanque",
          "suporte": "Suporte", "todas": "Todas"}
CATEGORIA = {"fisico": "Dano físico", "hibrido": "Híbrido (físico + mágico)", "magico": "Dano mágico",
             "defesa": "Defesa", "suporte": "Suporte"}


def estatisticas(e):
    return ", ".join(("%d%% %s" if k in PCT else "%d %s") % (v, ABREV[k]) for k, v in e.items())


def passiva(p):
    return "**%s:** %s" % (p["nome"], p["descricao"]) if p else "—"


def linha(i):
    return "| **%s** — %s | %d | %s | %s | %s |" % (i["nome"], i["ideia"], i["preco"], estatisticas(i["estatisticas"]),
                                                 passiva(i.get("passiva")), ", ".join(CLASSE[c] for c in i["classes"]))


REGRAS = """### Regras

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
"""

RESULTADOS = """### Resultados dos testes de equilíbrio

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
"""


def gerar():
    partes = ["## 7.2 Itens\n",
              "Catálogo completo em `data/itens/itens.json`; modelo de combate em `data/config/combate.json`. "
              "Testado no laboratório de itens (`tools/prototipos/laboratorio_itens.py`); relatório em `tools/relatorios/laboratorio_itens.md`. "
              "Esta seção é gerada por `tools/documentacao/gerar_itens_gdd.py`.\n", REGRAS]
    s = DADOS["item_inicial_suporte"]
    partes.append("### Item inicial do suporte\n\n| Item | Preço | Atributos | Passiva |\n|---|---|---|---|\n"
                  "| **%s** — %s | %d | %s | %s |\n" % (s["nome"], s["ideia"], s["preco"], estatisticas(s["estatisticas"]), passiva(s["passiva"])))
    cabecalho = "| %s | Preço | Atributos | Passiva | Classes |\n|---|---|---|---|---|"
    partes.append("### Botas (escolha 1)\n\n" + cabecalho % "Bota" + "\n" + "\n".join(linha(b) for b in DADOS["botas"]) + "\n")
    for cat, nome in CATEGORIA.items():
        itens = [i for i in DADOS["itens"] if i["categoria"] == cat]
        partes.append("### %s\n\n" % nome + cabecalho % "Item" + "\n" + "\n".join(linha(i) for i in itens) + "\n")
    partes.append(RESULTADOS)
    return "\n".join(partes)


def main():
    texto = open(GDD, encoding="utf-8").read()
    secao = gerar()
    if "## 7.2 Itens" in texto:
        ini = texto.index("## 7.2 Itens")
        fim = texto.index("\n## ", ini + 5) + 1
        texto = texto[:ini] + secao + "\n" + texto[fim:]
    else:
        ancora = texto.index("## 8. Draft")
        texto = texto[:ancora] + secao + "\n" + texto[ancora:]
    texto = texto.replace("- Nomes dos campeões e dos itens\n", "- Nomes e habilidades dos campeões\n")
    open(GDD, "w", encoding="utf-8").write(texto)
    print("Seção 7.2 Itens atualizada em docs/GDD.md")


if __name__ == "__main__":
    main()
