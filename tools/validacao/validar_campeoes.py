#!/usr/bin/env python3
"""
Valida a proposta de campeões (docs/propostas/campeoes.md) contra as regras do docs/GUIA_CAMPEOES.md.

Uso: python3 tools/validacao/validar_campeoes.py [caminho_da_proposta]

Confere: formato, distribuição (classes, posições, curvas, recursos), faixas de atributos por classe,
mana (custo da rotação), limites de dano por vida e dano verdadeiro, itens existentes e permitidos,
arquétipos mínimos, alcance e nomes.
"""
import json
import os
import re
import sys
from collections import Counter

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
COMBATE = json.load(open(os.path.join(RAIZ, "data", "config", "combate.json"), encoding="utf-8"))
ITENS = json.load(open(os.path.join(RAIZ, "data", "itens", "itens.json"), encoding="utf-8"))
NOME_ITEM = {i["nome"]: i for i in ITENS["itens"]}
NOME_BOTA = {b["nome"]: b for b in ITENS["botas"]}

CLASSES = ["tanque", "assassino", "lutador", "mago", "suporte", "atirador"]
POSICOES = ["topo", "selva", "meio", "atirador", "suporte"]
MANA_GUIA = {"mago": (420, 28), "suporte": (400, 25), "atirador": (320, 22), "tanque": (330, 24), "lutador": (300, 20), "assassino": (280, 20)}
TOLERANCIA = 0.15
# Nomes de campeões de League of Legends (amostra) para evitar cópia.
NOMES_LOL = {"ahri", "akali", "ashe", "darius", "garen", "jinx", "lux", "yasuo", "zed", "thresh", "leona", "malphite",
             "vayne", "katarina", "annie", "teemo", "riven", "fiora", "ezreal", "caitlyn", "morgana", "soraka", "janna",
             "nami", "lulu", "braum", "alistar", "sion", "ornn", "sejuani", "zac", "amumu", "nunu", "vi", "jax", "irelia"}

problemas = []
avisos = []


def falha(texto):
    problemas.append(texto)


def aviso(texto):
    avisos.append(texto)


def carregar(caminho):
    texto = open(caminho, encoding="utf-8").read()
    campeoes = []
    for bloco in re.findall(r"```json\n(.*?)\n```", texto, re.S):
        try:
            campeoes.append(json.loads(bloco))
        except json.JSONDecodeError as erro:
            falha("JSON inválido: %s" % erro)
    return campeoes


def no_nivel(par, nivel):
    return par[0] + par[1] * (nivel - 1)


def verificar_distribuicao(cs):
    print("\n== Distribuição")
    classes = Counter(c["classe"] for c in cs)
    principais = Counter(c["posicoes"][0] for c in cs)
    curvas = Counter(c["curva_de_forca"] for c in cs)
    recursos = Counter(c["recurso"]["tipo"] for c in cs)
    print("  campeões:", len(cs))
    print("  classes:", dict(classes))
    print("  posição principal:", dict(principais))
    print("  curvas:", dict(curvas))
    print("  recursos:", dict(recursos))
    print("  dificuldade:", dict(Counter(c["dificuldade"] for c in cs)), "| dependência de Macro:", dict(Counter(c["dependencia_macro"] for c in cs)))
    if len(cs) < 28 or len(cs) > 32:
        falha("número de campeões fora de ~30: %d" % len(cs))
    for k in CLASSES:
        if not 4 <= classes.get(k, 0) <= 6:
            falha("classe %s com %d campeões (esperado ~5)" % (k, classes.get(k, 0)))
    for p in POSICOES:
        if not 5 <= principais.get(p, 0) <= 7:
            falha("posição %s com %d campeões principais (esperado ~6)" % (p, principais.get(p, 0)))
    if not 18 <= recursos.get("mana", 0) <= 20:
        falha("campeões com mana: %d (esperado 18–20)" % recursos.get("mana", 0))
    for nome, qtd in curvas.items():
        if not 8 <= qtd <= 12 and nome != "pico_nivel_6":
            aviso("curva %s com %d campeões (pedido ~1/3)" % (nome, qtd))
    for c in cs:
        if not (1 <= c["dificuldade"] <= 3 and 1 <= c["dependencia_macro"] <= 3):
            falha("%s: dificuldade/dependência de Macro fora de 1–3" % c["nome"])


def verificar_estrutura(c):
    if not c.get("passiva") or not c["passiva"].get("efeito"):
        falha("%s: sem passiva com efeito" % c["nome"])
    habs = c.get("habilidades", [])
    if len(habs) != 3:
        falha("%s: tem %d habilidades (esperado 3)" % (c["nome"], len(habs)))
    elif not habs[2].get("especial"):
        falha("%s: a 3ª habilidade não está marcada como especial" % c["nome"])
    for h in habs:
        for campo in ("nome", "descricao", "narracao", "tipo_dano", "alvo", "dano", "recarga", "efeitos"):
            if campo not in h:
                falha("%s / %s: falta o campo %s" % (c["nome"], h.get("nome", "?"), campo))
    if c["nome"].lower() in NOMES_LOL:
        falha("%s: nome igual a campeão de League of Legends" % c["nome"])


def verificar_atributos(c):
    base = COMBATE["classes"][c["classe"]]
    for atr in ("vida", "armadura", "resistencia_magica", "dano_fisico"):
        ficha, ref = c["atributos"][atr], base[atr]
        for nivel in (1, 16):
            v, r = no_nivel(ficha, nivel), no_nivel(ref, nivel)
            desvio = v / r - 1
            if abs(desvio) > TOLERANCIA + 1e-9:
                falha("%s: %s no nível %d = %.0f (classe %.0f, %+.0f%%)" % (c["nome"], atr, nivel, v, r, desvio * 100))
    va, cres = c["atributos"]["velocidade_ataque"]
    ref_cres = base.get("crescimento_velocidade_ataque", 0.025) * 100
    va16, ref16 = va * (1 + cres / 100 * 15), base["velocidade_ataque"] * (1 + ref_cres / 100 * 15)
    if abs(va16 / ref16 - 1) > TOLERANCIA:
        falha("%s: velocidade de ataque no nível 16 %.2f (classe %.2f)" % (c["nome"], va16, ref16))
    alcance = c["atributos"].get("alcance", 0)
    faixas = {"atirador": (500, 650), "mago": (500, 600)}
    if c["classe"] in faixas and not faixas[c["classe"]][0] <= alcance <= faixas[c["classe"]][1]:
        aviso("%s: alcance %d fora do sugerido para %s" % (c["nome"], alcance, c["classe"]))
    if c["classe"] in ("assassino", "lutador", "tanque") and alcance > 175:
        aviso("%s: %s de alcance %d (sugerido corpo a corpo)" % (c["nome"], c["classe"], alcance))


def verificar_mana(c):
    r = c["recurso"]
    if r["tipo"] != "mana":
        return
    ref = MANA_GUIA[c["classe"]]
    for nivel in (1, 16):
        v, g = no_nivel(r["maximo"], nivel), no_nivel(ref, nivel)
        if abs(v / g - 1) > TOLERANCIA:
            falha("%s: mana máxima no nível %d = %.0f (guia %.0f)" % (c["nome"], nivel, v, g))
    custo = sum(h.get("custo", 0) for h in c["habilidades"])
    pct = custo / r["maximo"][0]
    if not 0.25 - 1e-9 <= pct <= 0.35 + 1e-9:
        falha("%s: rotação custa %.0f%% da mana no nível 1 (esperado 25–35%%)" % (c["nome"], pct * 100))


def verificar_limites(c):
    rot = {"alvo": 0.0, "propria": 0.0}
    verdadeiro = 0
    for h in c["habilidades"]:
        p = h["dano"]["proporcoes"]
        alvo = p.get("vida_maxima_alvo_pct", 0)
        perdida = p.get("vida_perdida_alvo_pct", 0)
        propria = p.get("vida_maxima_propria_pct", 0)
        if alvo > 0.06 + 1e-9:
            falha("%s / %s: %.1f%% da vida máxima do alvo (limite 6%%)" % (c["nome"], h["nome"], alvo * 100))
        if perdida > 0.15 + 1e-9:
            falha("%s / %s: %.1f%% da vida perdida (limite 15%%)" % (c["nome"], h["nome"], perdida * 100))
        if propria > 0.05 + 1e-9:
            falha("%s / %s: %.1f%% da vida máxima própria (limite 5%%)" % (c["nome"], h["nome"], propria * 100))
        rot["alvo"] += alvo
        rot["propria"] += propria
        if h["tipo_dano"] == "verdadeiro":
            verdadeiro += 1
    limite_alvo = 0.06 if c["classe"] in ("assassino", "mago") else 0.12
    if rot["alvo"] > limite_alvo + 1e-9:
        falha("%s: rotação com %.1f%% da vida máxima do alvo (limite %d%%)" % (c["nome"], rot["alvo"] * 100, limite_alvo * 100))
    if rot["propria"] > 0.10 + 1e-9:
        falha("%s: rotação com %.1f%% da vida própria (limite 10%%)" % (c["nome"], rot["propria"] * 100))
    if verdadeiro > 1:
        falha("%s: %d habilidades de dano verdadeiro (máximo 1)" % (c["nome"], verdadeiro))


def verificar_itens(c):
    build = c["build_recomendada"]
    if len(build) != 5:
        falha("%s: build com %d itens (esperado 5)" % (c["nome"], len(build)))
        return
    if build[0] not in NOME_BOTA:
        falha("%s: primeiro item da build não é uma bota existente (%s)" % (c["nome"], build[0]))
    nomes = build[1:] + [a["item"] for a in c.get("itens_alternativos", [])]
    for nome in nomes:
        item = NOME_ITEM.get(nome) or NOME_BOTA.get(nome)
        if item is None:
            falha("%s: item inexistente '%s'" % (c["nome"], nome))
        elif "todas" not in item["classes"] and c["classe"] not in item["classes"]:
            aviso("%s: '%s' não é listado para a classe %s" % (c["nome"], nome, c["classe"]))
    if len(set(build[1:])) != 4:
        falha("%s: itens repetidos na build" % c["nome"])
    if not 2 <= len(c.get("itens_alternativos", [])) <= 4:
        aviso("%s: %d itens alternativos (pedido 2–4)" % (c["nome"], len(c.get("itens_alternativos", []))))


def verificar_arquetipos(cs):
    print("\n== Arquétipos (mínimos do guia)")
    def tem(c, f):
        return any(f(h) for h in c["habilidades"])
    def efeitos(c):
        return " ".join(" ".join(h.get("efeitos", [])) + " " + " ".join(h.get("tags", [])) for h in c["habilidades"]).lower() + " " + c["passiva"]["efeito"].lower()
    contagem = {
        "Dano misto": (3, [c for c in cs if tem(c, lambda h: h["tipo_dano"] == "misto")]),
        "Dano por vida máxima do alvo": (3, [c for c in cs if tem(c, lambda h: h["dano"]["proporcoes"].get("vida_maxima_alvo_pct", 0) > 0)]),
        "Dano/escudo pela vida própria": (2, [c for c in cs if tem(c, lambda h: h["dano"]["proporcoes"].get("vida_maxima_propria_pct", 0) > 0) or "própria vida" in efeitos(c)]),
        "Assassinos com execução (vida perdida)": (2, [c for c in cs if c["classe"] == "assassino" and tem(c, lambda h: h["dano"]["proporcoes"].get("vida_perdida_alvo_pct", 0) > 0)]),
        "Cura/escudo em aliados": (3, [c for c in cs if re.search(r"aliad", efeitos(c)) and re.search(r"cura|escudo", efeitos(c))]),
        "Controle em área": (4, [c for c in cs if tem(c, lambda h: "controle" in h.get("tags", []) and h["alvo"] in ("area", "cone", "linha"))]),
        "Global/mapa": (2, [c for c in cs if "global" in efeitos(c)]),
        "Dano verdadeiro": (2, [c for c in cs if tem(c, lambda h: h["tipo_dano"] == "verdadeiro") or "dano verdadeiro" in efeitos(c)]),
        "Sem mana": (10, [c for c in cs if c["recurso"]["tipo"] != "mana"]),
    }
    for nome, (minimo, lista) in contagem.items():
        ok = len(lista) >= minimo
        print("  [%s] %-40s %2d (mínimo %d): %s" % ("ok" if ok else "FALTA", nome, len(lista), minimo, ", ".join(c["nome"] for c in lista)))
        if not ok:
            falha("arquétipo '%s' com %d (mínimo %d)" % (nome, len(lista), minimo))


def main():
    caminho = sys.argv[1] if len(sys.argv) > 1 else os.path.join(RAIZ, "docs", "propostas", "campeoes.md")
    cs = carregar(caminho)
    nomes = Counter(c["nome"] for c in cs)
    for nome, qtd in nomes.items():
        if qtd > 1:
            falha("nome repetido: %s" % nome)
    verificar_distribuicao(cs)
    for c in cs:
        verificar_estrutura(c)
        verificar_atributos(c)
        verificar_mana(c)
        verificar_limites(c)
        verificar_itens(c)
    verificar_arquetipos(cs)
    print("\n== Resultado")
    print("  %d problema(s), %d aviso(s)" % (len(problemas), len(avisos)))
    for p in problemas:
        print("  PROBLEMA: " + p)
    for a in avisos:
        print("  aviso: " + a)
    sys.exit(1 if problemas else 0)


if __name__ == "__main__":
    main()
