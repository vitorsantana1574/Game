#!/usr/bin/env python3
"""
Laboratório de itens de Crystal Legends.

Testa o equilíbrio dos itens (data/itens/itens.json) com o modelo de combate (data/config/combate.json):

  1. Eficiência em ouro de cada item (valor dos atributos ÷ preço).
  2. Letalidade e penetração mágica: valor fixo × porcentagem, por armadura/resistência do alvo.
  3. Valor de cada item para cada classe (ninguém pode ser obrigatório nem inútil).
  4. Melhores builds de cada classe contra composições diferentes (frágeis, equilibrada, tanques).
  5. Testes de estresse: passivas sob controle, acúmulos proibidos, limites de dano e resistência.

Uso:
    python3 tools/prototipos/laboratorio_itens.py                     # relatório
    python3 tools/prototipos/laboratorio_itens.py --atualizar-precos  # recalcula preços no JSON
"""

import argparse
import itertools
import json
import math
import os
import statistics
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CAMINHO_ITENS = os.path.join(RAIZ, "data", "itens", "itens.json")
CAMINHO_COMBATE = os.path.join(RAIZ, "data", "config", "combate.json")

COMBATE = json.load(open(CAMINHO_COMBATE, encoding="utf-8"))
DADOS_ITENS = json.load(open(CAMINHO_ITENS, encoding="utf-8"))
ITENS = {i["id"]: i for i in DADOS_ITENS["itens"]}
BOTAS = {b["id"]: b for b in DADOS_ITENS["botas"]}
TODOS = {**ITENS, **BOTAS}
REGRAS = COMBATE["regras"]
CLASSES = ["assassino", "atirador", "mago", "lutador", "tanque", "suporte"]


# ---------------------------------------------------------------------------
# Preços e eficiência
# ---------------------------------------------------------------------------

def valor_atributos(item):
    return sum(qtd * COMBATE["atributos"][atr]["ouro_por_ponto"] for atr, qtd in item["estatisticas"].items())


def preco_calculado(item):
    return int(round(valor_atributos(item) / item.get("eficiencia_alvo", 1.0) / 25.0) * 25)


def preco(item):
    return item.get("preco", preco_calculado(item))


def atualizar_precos():
    for lista in ("itens", "botas"):
        for item in DADOS_ITENS[lista]:
            item["preco"] = preco_calculado(item)
    with open(CAMINHO_ITENS, "w", encoding="utf-8") as arquivo:
        json.dump(DADOS_ITENS, arquivo, ensure_ascii=False, indent="\t")
        arquivo.write("\n")


# ---------------------------------------------------------------------------
# Campeão com itens
# ---------------------------------------------------------------------------

class Campeao:
    def __init__(self, classe, nivel, ids):
        self.classe = classe
        self.nivel = nivel
        self.ids = list(ids)
        base = COMBATE["classes"][classe]
        cresce = lambda par: par[0] + par[1] * (nivel - 1)
        e = {atr: 0.0 for atr in COMBATE["atributos"]}
        for item_id in self.ids:
            for atr, qtd in TODOS[item_id]["estatisticas"].items():
                e[atr] += qtd
        # Passivas: mesmo grupo não acumula (vale a primeira, que é a de maior valor na lista de compra).
        self.passivas = {}
        for item_id in self.ids:
            p = TODOS[item_id].get("passiva")
            if p:
                grupo = p.get("grupo", p["tipo"])
                if grupo not in self.passivas:
                    self.passivas[grupo] = p
        # % de penetração não acumula: vale a maior.
        self.pen_arm_pct = max([TODOS[i]["estatisticas"].get("penetracao_armadura_pct", 0) for i in self.ids] + [0]) / 100.0
        self.pen_mag_pct = max([TODOS[i]["estatisticas"].get("penetracao_magica_pct", 0) for i in self.ids] + [0]) / 100.0
        self.letalidade = e["letalidade"]
        self.pen_mag = e["penetracao_magica"]

        self.vida_base = cresce(base["vida"])
        self.vida_bonus = e["vida"]
        self.vida = self.vida_base + self.vida_bonus
        col = self.p("colosso")
        if col:
            self.vida *= 1 + col["vida_pct"]
            self.vida_bonus = self.vida - self.vida_base
        self.armadura = cresce(base["armadura"]) + e["armadura"]
        self.rm = cresce(base["resistencia_magica"]) + e["resistencia_magica"]
        self.df_base = cresce(base["dano_fisico"])
        self.df_bonus = e["dano_fisico"]
        self.df = self.df_base + self.df_bonus
        self.pm = e["poder_magico"] * (1 + (self.p("multiplicador_pm") or {}).get("pct", 0))
        self.va = min(REGRAS["velocidade_ataque_maxima"], base["velocidade_ataque"] * (1 + base.get("crescimento_velocidade_ataque", 0.025) * (nivel - 1)) * (1 + e["velocidade_ataque"] / 100))
        self.critico = min(1.0, e["critico"] / 100)
        self.dano_critico = (self.p("critico_aprimorado") or {}).get("dano_critico", REGRAS["dano_critico"])
        self.aceleracao = e["aceleracao"]
        self.roubo_vida = e["roubo_vida"] / 100
        self.hab = base["habilidades"]

    def p(self, grupo_ou_tipo):
        for grupo, p in self.passivas.items():
            if grupo == grupo_ou_tipo or p["tipo"] == grupo_ou_tipo:
                return p
        return None

    def ouro(self):
        return sum(preco(TODOS[i]) for i in self.ids)

    def recarga(self):
        return self.hab["recarga"] * 100 / (100 + self.aceleracao)

    def dano_habilidade(self):
        h = self.hab
        dano = h["base"][0] + h["base"][1] * (self.nivel - 1)
        dano += h.get("proporcao_df_bonus", 0) * self.df_bonus
        dano += h.get("proporcao_pm", 0) * self.pm
        dano += h.get("proporcao_vida_bonus", 0) * self.vida_bonus
        return dano, h["tipo"]


def resistencia_efetiva(valor, pct, fixo):
    return max(0.0, valor * (1 - pct) - fixo)


def mitigar(dano, resistencia):
    return dano * 100 / (100 + resistencia)


# ---------------------------------------------------------------------------
# Combate (duelo de mão dupla, passos de 0,05 s)
# ---------------------------------------------------------------------------

class Lutador:
    def __init__(self, c):
        self.c = c
        self.vida = c.vida
        self.escudo_magico = (c.p("escudo_magico") or {}).get("valor", 0)
        self.escudo = 0.0
        self.escudo_vida_baixa_usado = False
        self.proximo_ataque = 0.0
        self.proxima_habilidade = 0.0
        self.ataques = 0
        self.primeiro_golpe_pendente = False
        self.primeiro_golpe_usado = False
        self.queimando_ate = -1.0
        self.anti_cura_ate = -1.0
        self.proxima_regeneracao = 5.0
        self.dano_causado = 0.0

    def vivo(self):
        return self.vida > 0


def aplicar_dano(alvo, dano, tipo, t):
    if dano <= 0:
        return
    if tipo == "magico" and alvo.escudo_magico > 0:
        absorvido = min(alvo.escudo_magico, dano)
        alvo.escudo_magico -= absorvido
        dano -= absorvido
    if alvo.escudo > 0:
        absorvido = min(alvo.escudo, dano)
        alvo.escudo -= absorvido
        dano -= absorvido
    alvo.vida -= dano
    p = alvo.c.p("escudo_vida_baixa")
    if p and not alvo.escudo_vida_baixa_usado and 0 < alvo.vida < alvo.c.vida * p["limite"]:
        alvo.escudo_vida_baixa_usado = True
        alvo.escudo += p["escudo"] + p["proporcao_vida_bonus"] * alvo.c.vida_bonus


def curar(quem, valor, t):
    if quem.anti_cura_ate > t:
        valor *= REGRAS["cura_anti_cura"]
    falta = quem.c.vida - quem.vida
    quem.vida += min(valor, falta)
    excesso = valor - min(valor, falta)
    p = quem.c.p("escudo_excesso_cura")
    if p and excesso > 0:
        quem.escudo = min(p["maximo"], quem.escudo + excesso)


def multiplicador_ofensivo(atq, alvo):
    m = 1.0
    p = atq.c.p("dano_extra_vida_baixa")
    if p and alvo.vida < alvo.c.vida * p["limite"]:
        m *= 1 + p["bonus"]
    p = atq.c.p("furia")
    if p:
        perdida = 1 - atq.vida / atq.c.vida
        m *= 1 + min(p["maximo"], p["por_10pct"] * perdida * 10)
    return m


def golpear(atq, alvo, dano, tipo, t, ataque_basico=False):
    c, a = atq.c, alvo.c
    if tipo == "fisico":
        res = resistencia_efetiva(a.armadura, c.pen_arm_pct, c.letalidade)
    elif tipo == "magico":
        res = resistencia_efetiva(a.rm, c.pen_mag_pct, c.pen_mag)
    else:
        res = 0
    final = mitigar(dano, res) * multiplicador_ofensivo(atq, alvo)
    if ataque_basico:
        p = a.p("reducao_dano_ataques")
        if p:
            final *= 1 - p["valor"]
    aplicar_dano(alvo, final, tipo, t)
    atq.dano_causado += final
    return final


def passo_ofensivo(atq, alvo, t, dt):
    c = atq.c
    # Habilidades
    if t >= atq.proxima_habilidade:
        dano, tipo = c.dano_habilidade()
        golpear(atq, alvo, dano, tipo, t)
        p = c.p("pct_vida_maxima")
        if p:
            golpear(atq, alvo, p["pct"] * alvo.c.vida, p["dano_tipo"], t)
        p = c.p("queimadura")
        if p:
            alvo.queimando_ate = t + p["duracao"]
            if p.get("anti_cura"):
                alvo.anti_cura_ate = t + p["duracao"] + 1
        p = c.p("primeiro_golpe")
        if p and not atq.primeiro_golpe_usado:
            if p["dano_tipo"] == "magico":
                golpear(atq, alvo, p["dano"] + p.get("proporcao_pm", 0) * c.pm, "magico", t)
                atq.primeiro_golpe_usado = True
            else:
                atq.primeiro_golpe_pendente = True
        atq.proxima_habilidade = t + c.recarga()
    # Queimadura (dano por segundo)
    if atq.c.p("queimadura") and alvo.queimando_ate > t:
        golpear(atq, alvo, atq.c.p("queimadura")["pct_por_segundo"] * alvo.c.vida * dt, "magico", t)
    # Ataques básicos
    if t >= atq.proximo_ataque:
        va = c.va
        if alvo.c.p("frio"):
            va *= 1 - alvo.c.p("frio")["pct"]
        atq.proximo_ataque = t + 1 / va
        atq.ataques += 1
        critico = c.critico
        dano = c.df * (1 + critico * (c.dano_critico - 1))
        p = alvo.c.p("reducao_critico")
        if p and critico > 0:
            parte_critica = c.df * critico * c.dano_critico
            dano -= parte_critica * p["pct"]
        causado = golpear(atq, alvo, dano, "fisico", t, ataque_basico=True)
        if c.roubo_vida:
            curar(atq, causado * c.roubo_vida, t)
        p = c.p("ao_acertar")
        if p:
            golpear(atq, alvo, p["dano"] + p.get("proporcao_pm", 0) * c.pm, "magico", t)
        p = c.p("colosso")
        if p:
            golpear(atq, alvo, p["dano_ataque_pct_vida"] * c.vida, "fisico", t)
        p = c.p("rajada")
        if p and atq.ataques % 3 == 0:
            golpear(atq, alvo, p["dano"] + p.get("proporcao_df_bonus", 0) * c.df_bonus, "magico", t)
        if atq.primeiro_golpe_pendente and not atq.primeiro_golpe_usado:
            p = c.p("primeiro_golpe")
            golpear(atq, alvo, p["dano"] + p.get("proporcao_df_bonus", 0) * c.df_bonus, "fisico", t)
            atq.primeiro_golpe_usado = True
            atq.primeiro_golpe_pendente = False
        # Espinhos do alvo
        p = alvo.c.p("espinhos")
        if p:
            golpear(alvo, atq, causado * p["reflexo"] * (100 + resistencia_efetiva(alvo.c.armadura, 0, 0)) / 100, "magico", t)
            if p.get("anti_cura"):
                atq.anti_cura_ate = t + 3
    # Regeneração do próprio atacante
    p = c.p("regeneracao")
    if p and t >= atq.proxima_regeneracao:
        curar(atq, p["pct_vida"] * c.vida, t)
        atq.proxima_regeneracao = t + p["a_cada"]


def duelo(a, b, tempo_max=30.0, dt=0.05, mao_dupla=True):
    """Retorna (tempo para A matar B, tempo para B matar A). None = não matou dentro do tempo."""
    la, lb = Lutador(a), Lutador(b)
    t = 0.0
    morte_b = morte_a = None
    while t <= tempo_max and (morte_a is None or morte_b is None):
        if la.vivo() and morte_b is None:
            passo_ofensivo(la, lb, t, dt)
            if not lb.vivo():
                morte_b = t
        if mao_dupla and lb.vivo() and morte_a is None:
            passo_ofensivo(lb, la, t, dt)
            if not la.vivo():
                morte_a = t
        if morte_b is not None and not mao_dupla:
            break
        if morte_a is not None or morte_b is not None:
            if mao_dupla:
                break
        t += dt
    return morte_b, morte_a


def tempo_para_matar(atacante, alvo):
    t, _ = duelo(atacante, alvo, mao_dupla=False)
    return t if t is not None else 30.0


def explosao(atacante, alvo, janela=3.0):
    """Fração da vida do alvo tirada em `janela` segundos (sem o alvo reagir)."""
    la, lb = Lutador(atacante), Lutador(alvo)
    t, dt = 0.0, 0.05
    vida_total = alvo.vida + lb.escudo_magico
    while t <= janela and lb.vivo():
        passo_ofensivo(la, lb, t, dt)
        t += dt
    return min(1.5, la.dano_causado / alvo.vida)


# ---------------------------------------------------------------------------
# Builds de referência e pontuação
# ---------------------------------------------------------------------------

REFERENCIA = {
    "assassino": ["botas_do_cacador", "presa_da_serpente", "lamina_do_eclipse", "manto_da_noite_eterna", "escudo_do_guardiao"],
    "atirador": ["botas_da_furia", "lamina_cristalina", "asas_do_vento_veloz", "sanguessuga_rubra", "arco_do_juizo_final"],
    "mago": ["botas_arcanas", "orbe_da_tempestade", "grimorio_cristalino", "cajado_do_abismo", "coroa_da_hydra"],
    "lutador": ["botas_do_cacador", "machado_do_gigante", "lamina_do_guerreiro", "martelo_das_montanhas", "couraca_de_pedra"],
    "tanque": ["grevas_de_ferro", "coracao_do_tita", "egide_de_aco", "escudo_do_guardiao", "armadura_viva_de_cristal"],
    "suporte": ["sandalias_da_sabedoria", "medalhao_dos_eternos", "lanterna_do_vigia", "coroa_da_hydra", "veu_celestial"],
}

BASES_ALTERNATIVAS = {
    "tanque": [["sandalias_da_sabedoria", "coracao_do_tita", "escudo_do_guardiao"]],
    "suporte": [["grevas_de_ferro", "medalhao_dos_eternos", "lanterna_do_vigia"]],
}

COMPOSICOES = {
    "frageis": ["mago", "atirador", "assassino"],
    "equilibrada": ["mago", "atirador", "lutador", "tanque"],
    "tanques": ["tanque", "lutador", "tanque"],
}

PESO_OFENSA = {"assassino": 0.8, "atirador": 0.75, "mago": 0.75, "lutador": 0.55, "tanque": 0.2, "suporte": 0.3}


def referencia(classe, nivel=15, itens=4):
    ids = REFERENCIA[classe]
    return Campeao(classe, nivel, ids[: 1 + itens])


def pontuar(c, composicao="equilibrada", nivel=15):
    alvos = [referencia(k, nivel) for k in COMPOSICOES[composicao]]
    # Ofensa: inverso do tempo para matar cada alvo. Defesa: tempo que cada alvo leva para matar este campeão.
    ofensa = statistics.mean(1.0 / tempo_para_matar(c, a) for a in alvos)
    defesa = statistics.mean(tempo_para_matar(a, c) for a in alvos)
    w = PESO_OFENSA[c.classe]
    valor = (ofensa ** w) * (defesa ** (1 - w))
    if c.classe == "suporte":
        valor *= 1 + valor_de_time(c)
    return valor


def valor_de_time(c):
    """Efeito de suporte em aliados, convertido em ganho relativo para o time (aproximação)."""
    ganho = 0.0
    p = c.p("bencao")
    if p:
        ganho += p["va_aliado"] * 0.5      # aliado atirador com +12% VA em metade da luta
    p = c.p("escudo_aliados")
    if p:
        escudo = p["escudo"] + p["proporcao_vida_bonus"] * c.vida_bonus
        ganho += escudo * p["alvos"] / (5 * 2000.0)   # escudo relativo à vida média dos aliados
    return ganho


def categoria_ampla(item):
    return "dano" if item["categoria"] in ("fisico", "magico", "hibrido") else "defesa"


def elegivel(item, classe):
    return "todas" in item["classes"] or classe in item["classes"]


# ---------------------------------------------------------------------------
# Testes
# ---------------------------------------------------------------------------

def secao(titulo):
    print("\n" + "=" * 78 + "\n" + titulo + "\n" + "=" * 78)


def teste_eficiencia():
    secao("1. Eficiência em ouro (valor dos atributos ÷ preço; o resto é a passiva)")
    problemas = []
    for item in list(ITENS.values()) + list(BOTAS.values()):
        ef = valor_atributos(item) / preco(item)
        nome = item["nome"]
        marca = "" if 0.84 <= ef <= 1.02 else "  <-- fora da faixa 84–102%"
        if marca:
            problemas.append(nome)
        print("  %-34s %5d de ouro | atributos valem %5.0f (%3.0f%%)%s" % (nome, preco(item), valor_atributos(item), ef * 100, marca))
    return problemas


def teste_penetracao():
    secao("2. Letalidade e penetração: valor fixo × porcentagem")
    fixo_item = ITENS["presa_da_serpente"]["estatisticas"]["letalidade"]
    pct_item = ITENS["lanca_quebra_escudos"]["estatisticas"]["penetracao_armadura_pct"] / 100
    print("  Multiplicador de dano (quanto do dano passa) contra armadura crescente:")
    print("  %-10s %-10s %-16s %-16s %-18s" % ("armadura", "sem nada", "%d letalidade" % fixo_item, "%d%% letalidade" % (pct_item * 100), "os dois (ordem)"))
    for armadura in (30, 60, 90, 120, 180, 240, 300):
        sem = mitigar(1, armadura)
        fixo = mitigar(1, resistencia_efetiva(armadura, 0, fixo_item))
        pct = mitigar(1, resistencia_efetiva(armadura, pct_item, 0))
        ambos = mitigar(1, resistencia_efetiva(armadura, pct_item, fixo_item))
        melhor = "fixo" if fixo > pct else "%"
        print("  %-10d %-10.2f %-16.2f %-16.2f %-18.2f melhor isolado: %s" % (armadura, sem, fixo, pct, ambos, melhor))
    fixo_mag = ITENS["orbe_da_tempestade"]["estatisticas"]["penetracao_magica"]
    print("\n  Ponto de virada (fixo × porcentagem) = valor fixo ÷ porcentagem:")
    print("    %d de letalidade (Presa) × 20%% (Lança): %.0f de armadura" % (fixo_item, fixo_item / 0.20))
    print("    %d de letalidade × 25%% (Arco): %.0f de armadura" % (fixo_item, fixo_item / 0.25))
    print("    %d de penetração mágica (Orbe) × 25%% (Cajado): %.0f de resistência mágica" % (fixo_mag, fixo_mag / 0.25))
    print("    %d de penetração mágica × 20%% (Foice): %.0f de resistência mágica" % (fixo_mag, fixo_mag / 0.20))
    print("\n  Armadura/resistência típicas no fim de jogo (nível 15, build de referência):")
    for k in CLASSES:
        c = referencia(k)
        print("    %-10s armadura %5.0f | resistência mágica %5.0f | vida %5.0f" % (k, c.armadura, c.rm, c.vida))
    print("\n  Regra: % de itens diferentes não se soma (vale a maior). Exemplo com os 2 itens de letalidade %:")
    c = Campeao("atirador", 15, ["botas_da_furia", "lanca_quebra_escudos", "arco_do_juizo_final"])
    print("    Lança (20%%) + Arco (25%%) = %.0f%% efetivo (sem a regra seriam 40%% ou 45%%)" % (c.pen_arm_pct * 100))
    return []


def teste_valor_por_classe():
    secao("3. Valor de cada item por classe (build base: bota + 2 itens; mede o 3º item)")
    print("  100% = média dos itens da MESMA categoria (dano ou defesa) para a classe.")
    print("  Acima de 125%: candidato a obrigatório. Abaixo de 70%: fraco para essa classe.")
    print("  Tanque e suporte usam duas bases (uma com armadura, outra com resistência mágica) e tiram a média,")
    print("  para não confundir 'complementa o que falta' com 'item forte demais'.")
    problemas = []
    for classe in CLASSES:
        bases = [REFERENCIA[classe][:3]] + BASES_ALTERNATIVAS.get(classe, [])
        relativos = {}
        for base_ids in bases:
            valor_sem = pontuar(Campeao(classe, 15, base_ids))
            ganhos = {}
            for item in ITENS.values():
                if elegivel(item, classe) and item["id"] not in sum(bases, []):
                    com = Campeao(classe, 15, base_ids + [item["id"]])
                    ganhos[item["id"]] = (pontuar(com) - valor_sem) / preco(item) * 1000
            # Compara dentro da mesma categoria: dano com dano, defesa com defesa.
            for item_id, g in ganhos.items():
                cat = categoria_ampla(ITENS[item_id])
                mesmos = [v for i, v in ganhos.items() if categoria_ampla(ITENS[i]) == cat]
                media_cat = statistics.mean(mesmos)
                if len(mesmos) >= 2 and media_cat > 0:
                    relativos.setdefault(item_id, []).append(g / media_cat * 100)
        ganhos = {i: statistics.mean(v) for i, v in relativos.items()}
        media = 100.0
        print("\n  %s (bases: %s)" % (classe.upper(), " | ".join(", ".join(TODOS[i]["nome"] for i in b) for b in bases)))
        for item_id, g in sorted(ganhos.items(), key=lambda x: (categoria_ampla(ITENS[x[0]]), -x[1])):
            rel = g
            marca = ""
            if rel > 125:
                marca = "  <-- forte demais?"
            elif rel < 70:
                marca = "  (fraco para esta classe)"
            print("    %-34s %4.0f%%%s" % (ITENS[item_id]["nome"], rel, marca))
            if rel > 140:
                problemas.append("%s/%s" % (classe, ITENS[item_id]["nome"]))
    return problemas


def melhores_builds(classe, composicao, n=3):
    botas = [b for b in BOTAS.values() if elegivel(b, classe)]
    pool = [i for i in ITENS.values() if elegivel(i, classe)]
    resultados = []
    for bota in botas:
        for combo in itertools.combinations(pool, 4):
            ids = [bota["id"]] + [i["id"] for i in combo]
            c = Campeao(classe, 15, ids)
            # builds com passivas repetidas perdem valor naturalmente (grupo não acumula)
            resultados.append((pontuar(c, composicao), ids, c.ouro()))
    resultados.sort(key=lambda x: -x[0])
    return resultados


def teste_builds():
    secao("4. Melhores builds por classe contra cada composição inimiga")
    problemas = []
    frequencia_global = {}
    for classe in CLASSES:
        print("\n  %s" % classe.upper())
        topo_por_comp = {}
        for comp in COMPOSICOES:
            res = melhores_builds(classe, comp)
            topo_por_comp[comp] = res
            melhor = res[0]
            mediana = statistics.median(r[0] for r in res)
            print("    contra %-11s %s  (melhor/mediana = %.2f)" % (comp + ":", ", ".join(TODOS[i]["nome"] for i in melhor[1]), melhor[0] / mediana))
            if melhor[0] / mediana > 1.6:
                problemas.append("%s contra %s: build dominante" % (classe, comp))
            for _, ids, _ in res[:10]:
                for i in ids[1:]:
                    frequencia_global.setdefault(classe, {}).setdefault(i, 0)
                    frequencia_global[classe][i] += 1
        mais = sorted(frequencia_global[classe].items(), key=lambda x: -x[1])[:6]
        print("    itens mais presentes nas 10 melhores builds (3 composições, 30 builds):")
        print("      " + ", ".join("%s (%d)" % (ITENS[i]["nome"], q) for i, q in mais))
        for i, q in mais:
            if q >= 30:
                problemas.append("%s: %s em todas as melhores builds" % (classe, ITENS[i]["nome"]))
    return problemas


def teste_estresse():
    secao("5. Testes de estresse e limites")
    problemas = []

    def checar(cond, texto):
        print("  [%s] %s" % ("ok" if cond else "FALHOU", texto))
        if not cond:
            problemas.append(texto)

    assassino = Campeao("assassino", 15, ["botas_do_cacador", "presa_da_serpente", "lamina_do_eclipse", "lanca_quebra_escudos", "escudo_do_guardiao"])
    atirador, mago, tanque, lutador = referencia("atirador"), referencia("mago"), referencia("tanque"), referencia("lutador")

    e = explosao(assassino, atirador)
    checar(0.75 <= e <= 1.15, "Assassino (bota + 3 dano + 1 vida) em 3 s tira 75–115%% da vida de um atirador: %.0f%%" % (e * 100))
    e = explosao(assassino, mago)
    checar(0.65 <= e <= 1.15, "... e de um mago com item defensivo (Coroa da Hydra): 65–115%%: %.0f%%" % (e * 100))
    e = explosao(assassino, tanque)
    checar(e <= 0.40, "... mas não mais que 40%% de um tanque: %.0f%%" % (e * 100))

    t = tempo_para_matar(atirador, tanque)
    checar(6 <= t <= 14, "Atirador completo derruba um tanque completo em 6–14 s: %.1f s" % t)
    t = tempo_para_matar(atirador, mago)
    checar(1.8 <= t <= 4.5, "Atirador completo derruba um mago em 1,8–4,5 s: %.1f s" % t)

    e = explosao(mago, atirador)
    checar(0.55 <= e <= 1.05, "Mago em 3 s tira 55–105%% da vida de um atirador: %.0f%%" % (e * 100))

    equipe = [assassino, atirador, mago]
    t_tanque = statistics.mean(tempo_para_matar(a, tanque) for a in equipe)
    t_fragil = statistics.mean(tempo_para_matar(a, mago) for a in equipe)
    checar(t_tanque >= 2.2 * t_fragil, "Tanque aguenta pelo menos 2,2× mais que um frágil: %.1fx" % (t_tanque / t_fragil))

    a_mata, l_mata = duelo(atirador, lutador)
    print("      (duelo atirador × lutador, sem distância: atirador matou em %s, lutador em %s)" % (
        "%.1fs" % a_mata if a_mata else "-", "%.1fs" % l_mata if l_mata else "-"))
    t1, t2 = tempo_para_matar(atirador, lutador), tempo_para_matar(lutador, atirador)
    checar(0.5 <= t1 / t2 <= 2.0, "Lutador e atirador equilibrados no duelo (razão dos tempos 0,5–2,0): %.2f" % (t1 / t2))

    # Acúmulos proibidos
    c = Campeao("mago", 15, ["botas_arcanas", "cajado_do_abismo", "foice_da_lua_negra"])
    checar(abs(c.pen_mag_pct - 0.25) < 1e-9, "Penetração mágica %% não acumula (Cajado 25%% + Foice 20%% = 25%%)")
    c = Campeao("lutador", 15, ["botas_do_cacador", "lamina_do_guerreiro", "manto_da_noite_eterna"])
    checar(len([p for p in c.passivas.values() if p["tipo"] == "escudo_vida_baixa"]) == 1, "Dois escudos de vida baixa não acumulam (mesmo grupo)")

    # Interações entre itens
    print("\n  Interações entre itens:")
    atirador_ls = Campeao("atirador", 15, ["botas_da_furia", "lamina_cristalina", "sanguessuga_rubra", "asas_do_vento_veloz", "arco_do_juizo_final"])
    lutador_sem = Campeao("lutador", 15, ["grevas_de_ferro", "machado_do_gigante", "lamina_do_guerreiro", "couraca_de_pedra", "escudo_do_guardiao"])
    lutador_egide = Campeao("lutador", 15, ["grevas_de_ferro", "machado_do_gigante", "lamina_do_guerreiro", "egide_de_aco", "escudo_do_guardiao"])
    def cura_em_duelo(atq, alvo):
        la, lb = Lutador(atq), Lutador(alvo)
        curado = [0.0]
        original = globals()["curar"]
        def contar(quem, valor, t):
            antes = quem.vida
            original(quem, valor, t)
            if quem is la:
                curado[0] += quem.vida - antes
        globals()["curar"] = contar
        try:
            t = 0.0
            while t < 6.0 and lb.vivo() and la.vivo():
                passo_ofensivo(la, lb, t, 0.05)
                passo_ofensivo(lb, la, t, 0.05)
                t += 0.05
        finally:
            globals()["curar"] = original
        return curado[0]
    c_sem, c_com = cura_em_duelo(atirador_ls, lutador_sem), cura_em_duelo(atirador_ls, lutador_egide)
    checar(c_com < c_sem * 0.75, "Anticura (Égide de Aço) corta a cura do roubo de vida do atirador: %.0f → %.0f em 6 s" % (c_sem, c_com))
    tanque_sem = Campeao("tanque", 15, ["grevas_de_ferro", "coracao_do_tita", "egide_de_aco", "escudo_do_guardiao", "armadura_viva_de_cristal"])
    tanque_cou = Campeao("tanque", 15, ["grevas_de_ferro", "coracao_do_tita", "couraca_de_pedra", "escudo_do_guardiao", "armadura_viva_de_cristal"])
    t1, t2 = tempo_para_matar(atirador, tanque_sem), tempo_para_matar(atirador, tanque_cou)
    checar(t2 > t1 * 0.95, "Couraça (contra crítico) segura o atirador de crítico tão bem quanto a Égide: %.1f s × %.1f s" % (t1, t2))
    mago_alvo_sem = Campeao("atirador", 15, ["botas_da_furia", "lamina_cristalina", "asas_do_vento_veloz", "sanguessuga_rubra", "arco_do_juizo_final"])
    mago_alvo_com = Campeao("atirador", 15, ["sandalias_da_sabedoria", "lamina_cristalina", "asas_do_vento_veloz", "sanguessuga_rubra", "escudo_do_guardiao"])
    e1, e2 = explosao(mago, mago_alvo_sem), explosao(mago, mago_alvo_com)
    checar(e2 < e1 * 0.75, "Escudo do Guardião + Sandálias protegem o atirador da explosão do mago: %.0f%% → %.0f%%" % (e1 * 100, e2 * 100))
    assassino_flat = Campeao("assassino", 15, ["botas_do_cacador", "presa_da_serpente", "lamina_do_eclipse", "manto_da_noite_eterna", "machado_do_gigante"])
    assassino_pct = Campeao("assassino", 15, ["botas_do_cacador", "presa_da_serpente", "lamina_do_eclipse", "lanca_quebra_escudos", "machado_do_gigante"])
    f1, f2 = explosao(assassino_flat, atirador), explosao(assassino_pct, atirador)
    g1, g2 = explosao(assassino_flat, tanque), explosao(assassino_pct, tanque)
    checar(g2 / g1 > f2 / f1, "Letalidade %% rende mais contra tanque do que contra frágil (ganho com a Lança: frágil %+.0f%%, tanque %+.0f%%)" % ((f2 / f1 - 1) * 100, (g2 / g1 - 1) * 100))

    # Passivas não podem carregar o item sozinhas
    print("\n  Peso da passiva no valor do item (passiva desligada → quanto o item perde):")
    for item in ITENS.values():
        if "passiva" not in item:
            continue
        classe = next(k for k in CLASSES if elegivel(item, k))
        base = [i for i in REFERENCIA[classe] if i != item["id"]][:3]
        sem = pontuar(Campeao(classe, 15, base))
        com = pontuar(Campeao(classe, 15, base + [item["id"]]))
        original = item.pop("passiva")
        try:
            sem_passiva = pontuar(Campeao(classe, 15, base + [item["id"]]))
        finally:
            item["passiva"] = original
        ganho, ganho_sem = com - sem, sem_passiva - sem
        peso = 1 - ganho_sem / ganho if ganho > 1e-9 else 0
        marca = "" if peso <= 0.45 else "  <-- passiva pesa demais"
        if peso > 0.45:
            problemas.append("passiva de %s pesa demais (%.0f%%)" % (item["nome"], peso * 100))
        print("    %-34s (%s) %3.0f%%%s" % (item["nome"], classe, peso * 100, marca))
    return problemas


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--atualizar-precos", action="store_true")
    parser.add_argument("--sem-builds", action="store_true", help="pula o teste 4 (o mais demorado)")
    args = parser.parse_args()
    if args.atualizar_precos:
        atualizar_precos()
        print("Preços atualizados em", CAMINHO_ITENS)
        return
    problemas = []
    problemas += teste_eficiencia()
    problemas += teste_penetracao()
    problemas += teste_valor_por_classe()
    if not args.sem_builds:
        problemas += teste_builds()
    problemas += teste_estresse()
    secao("Resumo")
    if problemas:
        print("  %d ponto(s) de atenção:" % len(problemas))
        for p in problemas:
            print("   - " + p)
    else:
        print("  Todos os testes dentro das metas.")


if __name__ == "__main__":
    main()
