#!/usr/bin/env python3
"""
Laboratório de campeões de Crystal Legends.

Simula lutas com os 30 campeões reais (data/campeoes/campeoes.json), com os itens da build recomendada,
em três momentos da partida (início, meio e fim), e mede a taxa de vitória de cada campeão.

Uso:
    python3 tools/prototipos/laboratorio_campeoes.py                 # relatório completo
    python3 tools/prototipos/laboratorio_campeoes.py --lutas 600     # menos lutas (mais rápido, mais ruído)
    python3 tools/prototipos/laboratorio_campeoes.py --calibrar 4    # 4 rodadas de calibração automática
    python3 tools/prototipos/laboratorio_campeoes.py --semente 7

Modelo (resumo; detalhes em tools/relatorios/laboratorio_campeoes.md):
- Plano 2D abstrato, passos de 0,1 s. Cada campeão anda até o alcance, ataca e usa habilidades quando há alvo.
- Habilidades: linha, cone, área ou alvo único, com dano por nível, proporções, % de vida, divisão mista,
  lentidão, atordoamento, escudos, curas, avanços, marcas e custos de mana, energia, fúria ou vida.
- Habilidades com projétil ou aviso podem errar (chance fixa aqui; na partida real depende do Micro).
- As 30 passivas são executadas pelos gatilhos da ficha (distância real para isolamento, combos, acúmulos…).
- Itens: atributos e passivas do data/itens/itens.json (mesmo modelo do laboratorio_itens.py).
- Cenários: luta 5x5 (metade perto de objetivo épico), duelo de rota (topo, meio, selva) e rota dupla (atirador + suporte).
"""
import argparse
import json
import math
import os
import random
import statistics
import sys
from collections import defaultdict
from multiprocessing import Pool

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import laboratorio_itens as LI  # noqa: E402

RAIZ = LI.RAIZ
CAMINHO_CAMPEOES = os.path.join(RAIZ, "data", "campeoes", "campeoes.json")
CAMINHO_AJUSTES = os.path.join(RAIZ, "tools", "conversao", "ajustes_laboratorio.json")
REGRAS = LI.REGRAS
TODOS = LI.TODOS

DT = 0.1
TEMPO_MAXIMO = 30.0
POSICOES = ["topo", "selva", "meio", "atirador", "suporte"]

# Momentos da partida: nível e quantos itens da build (além da bota) cada campeão tem.
# Início = primeiras lutas de time (nível 6, especial liberada, só a bota). Meio = nível 10 com 2 itens. Fim = nível 16 com 4.
MOMENTOS = {
    "inicio": {"nivel": 6, "itens": 0, "bota": True, "acumulos": 0},
    "meio": {"nivel": 10, "itens": 2, "bota": True, "acumulos": 2},
    "fim": {"nivel": 16, "itens": 4, "bota": True, "acumulos": 5},
}
# Taxa de vitória alvo por curva de força (início, meio, fim).
ALVO_CURVA = {
    "inicio": {"inicio": 0.55, "meio": 0.51, "fim": 0.45},
    "constante": {"inicio": 0.50, "meio": 0.50, "fim": 0.50},
    "fim": {"inicio": 0.45, "meio": 0.49, "fim": 0.55},
    "pico_nivel_6": {"inicio": 0.47, "meio": 0.54, "fim": 0.49},
}
# Peso de cada cenário na nota do campeão. A luta 5x5 decide; a rota dupla (atirador + suporte) entra para quem joga nela.
# O duelo 1x1 até a morte é só informativo: é binário demais (um confronto de classes decide tudo) e a fase de rotas
# real é de farm e trocas curtas, não de duelos até a morte.
PESO_CENARIO = {"luta": 0.85, "dupla": 0.15}

# Chance de acerto de habilidades esquiváveis (Micro médio). Aviso longo dá tempo de desviar.
ACERTO_PROJETIL = 0.80
def chance_acerto(mec):
    if not mec.get("esquivavel"):
        return 1.0
    aviso = mec.get("aviso", 0) + mec.get("preparacao", 0)
    return max(0.55, ACERTO_PROJETIL + 0.08 - 0.25 * aviso) if aviso else ACERTO_PROJETIL


def carregar_campeoes():
    return json.load(open(CAMINHO_CAMPEOES, encoding="utf-8"))["campeoes"]


def no_nivel(par, nivel):
    return par[0] + par[1] * (nivel - 1)


# ---------------------------------------------------------------------------
# Ficha do campeão num nível, com itens
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Itens adaptados ao rival (Macro médio): troca o item da build pelo alternativo quando a condição vale.
# ---------------------------------------------------------------------------

def perfil_do_rival(rivais):
    """Resumo do time rival usado pelas condições dos itens alternativos."""
    magia = 0.0
    for c in rivais:
        tipos = [h["tipo_dano"] for h in c["habilidades"]]
        if c["classe"] == "mago":
            magia += 1
        elif tipos.count("magico") + 0.5 * tipos.count("misto") >= 2 and c["classe"] not in ("tanque", "suporte"):
            magia += 0.5
    critico = sum(1 for c in rivais if any(TODOS[i]["estatisticas"].get("critico") for i in c["build_ids"][1:5]))
    cura = sum(1 for c in rivais if c["passiva"]["mecanica"]["tipo"] in ("cura_propria", "cura_aliado")
               or any(TODOS[i]["estatisticas"].get("roubo_vida") for i in c["build_ids"][1:5])
               or any("cura" in h["mecanica"] for h in c["habilidades"]))
    frente = sum(1 for c in rivais if c["classe"] in ("tanque", "lutador"))
    fisico = sum(1 for c in rivais if c["classe"] in ("atirador", "assassino", "lutador"))
    rm = sum(1 for c in rivais if any(TODOS[i]["estatisticas"].get("resistencia_magica", 0) >= 40 for i in c["build_ids"][1:5]))
    frageis = sum(1 for c in rivais if c["classe"] in ("atirador", "mago", "suporte"))
    n = len(rivais)
    escala = n / 5
    return {
        "pouca_magia": magia <= 1 * escala,
        "muita_magia": magia >= 2 * escala,
        "critico": critico >= 2 * escala,
        "cura": cura >= 2 * escala,
        "armadura": frente >= 3 * escala,
        "fisico": fisico >= 3 * escala,
        "resistencia_magica": rm >= 3 * escala,
        "frageis": frageis >= 3 * escala,
        "misto": magia >= 1 * escala and fisico >= 2 * escala,
        "vida_alta": frente >= 3 * escala,
        "situacional": False,
    }


def build_adaptada(dados, rivais):
    ids = list(dados["build_ids"])
    if rivais is None:
        return ids
    perfil = perfil_do_rival(rivais)
    for alt in dados["itens_alternativos"]:
        if perfil.get(alt["condicao"]) and alt["substitui_id"] in ids and alt["item_id"] not in ids:
            ids[ids.index(alt["substitui_id"])] = alt["item_id"]
    return ids


class Ficha:
    def __init__(self, dados, nivel, n_itens, bota, acumulos, rivais=None):
        self.d = dados
        self.id = dados["id"]
        self.classe = dados["classe"]
        self.nivel = nivel
        ids = build_adaptada(dados, rivais)
        self.ids = ([ids[0]] if bota else []) + ids[1:1 + n_itens]
        a = dados["atributos"]
        e = defaultdict(float)
        for item_id in self.ids:
            for atr, qtd in TODOS[item_id]["estatisticas"].items():
                e[atr] += qtd
        self.passivas_item = {}
        for item_id in self.ids:
            p = TODOS[item_id].get("passiva")
            if p:
                self.passivas_item.setdefault(p.get("grupo", p["tipo"]), p)
        self.pen_arm_pct = max([TODOS[i]["estatisticas"].get("penetracao_armadura_pct", 0) for i in self.ids] + [0]) / 100
        self.pen_mag_pct = max([TODOS[i]["estatisticas"].get("penetracao_magica_pct", 0) for i in self.ids] + [0]) / 100
        self.letalidade = e["letalidade"]
        self.pen_mag = e["penetracao_magica"]
        self.vida_base = no_nivel(a["vida"], nivel)
        self.vida = self.vida_base + e["vida"]
        col = self.p("colosso")
        if col:
            self.vida *= 1 + col["vida_pct"]
        self.vida_bonus = self.vida - self.vida_base
        self.armadura = no_nivel(a["armadura"], nivel) + e["armadura"]
        self.rm = no_nivel(a["resistencia_magica"], nivel) + e["resistencia_magica"]
        self.df_base = no_nivel(a["dano_fisico"], nivel)
        self.df_bonus = e["dano_fisico"]
        self.df = self.df_base + self.df_bonus
        self.pm = e["poder_magico"] * (1 + (self.p("multiplicador_pm") or {}).get("pct", 0))
        va0, cresce = a["velocidade_ataque"]
        self.va = min(REGRAS["velocidade_ataque_maxima"], va0 * (1 + cresce / 100 * (nivel - 1)) * (1 + e["velocidade_ataque"] / 100))
        self.critico = min(1.0, e["critico"] / 100)
        self.dano_critico = (self.p("critico_aprimorado") or {}).get("dano_critico", REGRAS["dano_critico"])
        self.aceleracao = e["aceleracao"]
        self.roubo_vida = e["roubo_vida"] / 100
        self.alcance = a["alcance"]
        self.vm = a["velocidade_movimento"] + e["velocidade_movimento"]
        self.tenacidade = e["tenacidade"] / 100
        self.habilidades = [h for h in dados["habilidades"] if nivel >= h["mecanica"].get("nivel_minimo", 1)]
        self.passiva = dados["passiva"]["mecanica"]
        self.acumulos = acumulos
        r = dados["recurso"]
        self.recurso_tipo = r["tipo"]
        if r["tipo"] == "mana":
            self.recurso_max = no_nivel(r["maximo"], nivel)
            self.escala_custo = self.recurso_max / r["maximo"][0]
            self.regen = no_nivel(r["regeneracao_5s"], nivel) / 5
        elif r["tipo"] == "energia":
            self.recurso_max, self.escala_custo, self.regen = 200, 1, 10
        elif r["tipo"] == "furia":
            self.recurso_max, self.escala_custo, self.regen = 100, 1, 0
        else:
            self.recurso_max, self.escala_custo, self.regen = 0, 1, 0

    def p(self, grupo_ou_tipo):
        for g, p in self.passivas_item.items():
            if g == grupo_ou_tipo or p["tipo"] == grupo_ou_tipo:
                return p
        return None

    def recarga(self, h):
        return h["recarga"] * 100 / (100 + self.aceleracao)

    def ouro(self):
        return sum(LI.preco(TODOS[i]) for i in self.ids)


# ---------------------------------------------------------------------------
# Unidade em combate
# ---------------------------------------------------------------------------

class Unidade:
    def __init__(self, ficha, time, x, y, rng):
        self.f = ficha
        self.time = time
        self.x, self.y = x, y
        self.rng = rng
        self.vida = ficha.vida
        self.escudos = []          # [valor, expira, fonte]
        self.escudo_magico = (ficha.p("escudo_magico") or {}).get("valor", 0)
        self.recurso = ficha.recurso_max if ficha.recurso_tipo in ("mana", "energia") else 0
        self.recargas = {h["posicao"]: 0.0 for h in ficha.habilidades}
        self.proximo_ataque = 0.0
        self.atordoado_ate = -1.0
        self.lentidoes = []        # [forca, ate]
        self.parado_desde = 0.0
        self.ultimo_combate = -99.0
        self.anti_cura_ate = -1.0
        self.queimando_ate = -1.0
        self.queimador = None
        self.reducao_dano = (0.0, -1.0)
        self.va_bonus = []         # [pct, ate]
        self.cura_continua = []    # [por_segundo, ate]
        self.alvo = None
        # Registros para gatilhos de passiva
        self.acertos = []          # (posicao, alvo, t)
        self.ataques = []          # (alvo, t)
        self.marca = None          # (alvo, ate) de habilidades com marca (Téssari, Treválio)
        self.marca_passiva = None  # (alvo, ate) marca da passiva (Mirfuso, Terralume)
        self.passiva_pronta = 0.0
        self.janela_custo_vida = -1.0
        # Fichas de acúmulo que persistem entre lutas (Velúria): começam pelo momento da partida.
        self.fichas = min(ficha.passiva.get("fichas", 0), ficha.acumulos) if ficha.passiva.get("gatilho") == "acumulo_de_acertos" else 0
        self.acertos_ficha = 0
        self.ultima_ficha = -99.0
        self.zona_ate = -1.0       # especial de zona ativa (Ocravia)
        self.curativo = None       # (aliado, ate) Sutéria
        self.primeiro_golpe_usado = False
        self.primeiro_golpe_pendente = False
        self.escudo_vida_baixa_usado = False
        self.proxima_regeneracao = 5.0
        self.ganho_furia = {"ataque": -1.0, "recebido": -1.0}
        self.furia_extra_pronta = 0.0
        # Estatísticas
        self.dano = 0.0
        self.dano_recebido = 0.0
        self.protecao = 0.0        # escudos e curas em aliados
        self.controle = 0.0        # segundos de atordoamento + lentidão ponderada
        self.abates = 0
        self.morte = None
        self.passiva_disparos = 0
        self.fonte = "outro"
        self.por_fonte = defaultdict(float)
        self.usos = defaultdict(int)

    def vivo(self):
        return self.vida > 0

    def dist(self, o):
        return math.hypot(self.x - o.x, self.y - o.y)

    def lento(self, t):
        self.lentidoes = [l for l in self.lentidoes if l[1] > t]
        return max([l[0] for l in self.lentidoes] + [0.0])

    def escudo_total(self, t):
        self.escudos = [s for s in self.escudos if s[1] > t and s[0] > 0]
        return sum(s[0] for s in self.escudos)


# ---------------------------------------------------------------------------
# Combate
# ---------------------------------------------------------------------------

class Luta:
    def __init__(self, time_a, time_b, rng, objetivo=False):
        self.unidades = time_a + time_b
        self.rng = rng
        self.objetivo = objetivo
        self.t = 0.0
        self.bencao = {}
        for u in self.unidades:
            u.luta = self
        # Escudo de início de luta (Medalhão dos Eternos). Efeito de time: não acumula, vale o maior de cada time.
        for time in (0, 1):
            portadores = [u for u in self.unidades if u.time == time and u.f.p("escudo_aliados")]
            if portadores:
                valor_de = lambda u: u.f.p("escudo_aliados")["escudo"] + u.f.p("escudo_aliados")["proporcao_vida_bonus"] * u.f.vida_bonus
                u = max(portadores, key=valor_de)
                for a in self.aliados(u, incluir=True):
                    self.dar_escudo(u, a, valor_de(u), 4.0)

    def aliados(self, u, incluir=False):
        return [o for o in self.unidades if o.time == u.time and o.vivo() and (incluir or o is not u)]

    def inimigos(self, u):
        return [o for o in self.unidades if o.time != u.time and o.vivo()]

    # --- efeitos básicos -----------------------------------------------------

    def dar_escudo(self, fonte, alvo, valor, duracao):
        if valor <= 0 or not alvo.vivo():
            return
        alvo.escudos.append([valor, self.t + duracao, fonte])
        if alvo is not fonte:
            fonte.protecao += valor
            self.aplicar_bencao(fonte, alvo)

    def curar(self, fonte, alvo, valor):
        if valor <= 0 or not alvo.vivo():
            return 0
        if alvo.anti_cura_ate > self.t:
            valor *= REGRAS["cura_anti_cura"]
        efetivo = min(valor, alvo.f.vida - alvo.vida)
        alvo.vida += efetivo
        excesso = valor - efetivo
        p = alvo.f.p("escudo_excesso_cura")
        if p and excesso > 0:
            atual = sum(s[0] for s in alvo.escudos if s[2] == "excesso")
            if atual < p["maximo"]:
                alvo.escudos.append([min(excesso, p["maximo"] - atual), self.t + 3, "excesso"])
        if alvo is not fonte:
            fonte.protecao += efetivo
            self.aplicar_bencao(fonte, alvo)
        return efetivo

    def aplicar_bencao(self, fonte, alvo):
        p = fonte.f.p("bencao")
        if p:
            alvo.va_bonus.append([p["va_aliado"], self.t + 4])

    def mitigar(self, atq, alvo, dano, tipo):
        if tipo == "fisico":
            res = LI.resistencia_efetiva(alvo.f.armadura, atq.f.pen_arm_pct, atq.f.letalidade)
        elif tipo == "magico":
            res = LI.resistencia_efetiva(alvo.f.rm, atq.f.pen_mag_pct, atq.f.pen_mag)
        else:
            res = 0
        return LI.mitigar(dano, res)

    def multiplicador(self, atq, alvo):
        m = 1.0
        p = atq.f.p("dano_extra_vida_baixa")
        if p and alvo.vida < alvo.f.vida * p["limite"]:
            m *= 1 + p["bonus"]
        p = atq.f.p("furia")
        if p:
            m *= 1 + min(p["maximo"], p["por_10pct"] * (1 - atq.vida / atq.f.vida) * 10)
        red, ate = alvo.reducao_dano
        if ate > self.t and atq in getattr(alvo, "reducao_contra", ()):
            m *= 1 - red
        return m

    def golpear(self, atq, alvo, dano, tipo, ataque_basico=False):
        """Aplica dano já com a parcela crua; devolve o dano efetivo."""
        if dano <= 0 or not alvo.vivo():
            return 0.0
        final = self.mitigar(atq, alvo, dano, tipo) * self.multiplicador(atq, alvo)
        if ataque_basico:
            p = alvo.f.p("reducao_dano_ataques")
            if p:
                final *= 1 - p["valor"]
        self.antes_de_receber(alvo, atq)
        restante = final
        if tipo == "magico" and alvo.escudo_magico > 0:
            absorvido = min(alvo.escudo_magico, restante)
            alvo.escudo_magico -= absorvido
            restante -= absorvido
        alvo.escudo_total(self.t)
        for s in sorted(alvo.escudos, key=lambda s: s[1]):
            if restante <= 0:
                break
            absorvido = min(s[0], restante)
            s[0] -= absorvido
            restante -= absorvido
        vida_antes = alvo.vida
        alvo.vida -= restante
        atq.dano += final
        atq.por_fonte[atq.fonte] += final
        alvo.dano_recebido += final
        atq.ultimo_combate = alvo.ultimo_combate = self.t
        self.depois_de_receber(alvo, atq, vida_antes)
        if not alvo.vivo() and alvo.morte is None:
            alvo.morte = self.t
            atq.abates += 1
        return final

    def dano_cru(self, atq, alvo, dano_def, mec, secundario=False):
        f = atq.f
        b = dano_def["base"]
        p = dano_def.get("proporcoes", dano_def)
        valor = no_nivel(b, f.nivel)
        valor += p.get("dano_fisico_bonus", 0) * f.df_bonus + p.get("poder_magico", 0) * f.pm
        valor += p.get("vida_maxima_propria_pct", 0) * f.vida
        if p.get("vida_maxima_alvo_pct"):
            valor += p["vida_maxima_alvo_pct"] * alvo.f.vida
        if p.get("vida_perdida_alvo_pct"):
            valor += p["vida_perdida_alvo_pct"] * (alvo.f.vida - alvo.vida)
        if secundario:
            valor *= mec.get("dano_secundario", 1.0)
        return valor

    def causar(self, atq, alvo, valor, tipo_dano, mec=None):
        if mec and mec.get("divisao_mista"):
            d = mec["divisao_mista"]
            return self.golpear(atq, alvo, valor * d["fisico"], "fisico") + self.golpear(atq, alvo, valor * d["magico"], "magico")
        if tipo_dano == "misto":
            return self.golpear(atq, alvo, valor * 0.5, "fisico") + self.golpear(atq, alvo, valor * 0.5, "magico")
        return self.golpear(atq, alvo, valor, tipo_dano)

    def desacelerar(self, fonte, alvo, forca, duracao):
        duracao *= 1 - alvo.f.tenacidade
        if getattr(alvo, "reduz_lentidao", (0, -1))[1] > self.t:
            forca *= 1 - alvo.reduz_lentidao[0]
        alvo.lentidoes.append([forca, self.t + duracao])
        fonte.controle += forca * duracao

    def atordoar(self, fonte, alvo, duracao):
        duracao *= 1 - alvo.f.tenacidade
        alvo.atordoado_ate = max(alvo.atordoado_ate, self.t + duracao)
        fonte.controle += duracao

    # --- gatilhos de passiva -------------------------------------------------

    def antes_de_receber(self, alvo, atq):
        pas = alvo.f.passiva
        g = pas.get("gatilho")
        if g == "receber_dano_parado" and self.t >= alvo.passiva_pronta and self.t - alvo.parado_desde >= pas["parado"]:
            self.dar_escudo(alvo, alvo, pas["pct_vida"] * alvo.f.vida, pas["duracao"])
            alvo.passiva_pronta = self.t + pas["recarga"]
            alvo.passiva_disparos += 1
        elif g == "perto_de_objetivo" and self.objetivo and self.t >= alvo.passiva_pronta:
            self.dar_escudo(alvo, alvo, pas["pct_vida"] * alvo.f.vida, pas["duracao"])
            alvo.passiva_pronta = self.t + pas["recarga"]
            alvo.passiva_disparos += 1
        # Fúria ao receber acerto
        if pas.get("tipo") == "furia" and self.t - alvo.ganho_furia["recebido"] >= 1.0:
            alvo.ganho_furia["recebido"] = self.t
            self.ganhar_furia(alvo, pas["ganho_recebido"])

    def depois_de_receber(self, alvo, atq, vida_antes):
        if not alvo.vivo():
            return
        # Escudo de emergência de item (uma vez por luta)
        p = alvo.f.p("escudo_vida_baixa")
        if p and not alvo.escudo_vida_baixa_usado and alvo.vida < alvo.f.vida * p["limite"]:
            alvo.escudo_vida_baixa_usado = True
            self.dar_escudo(alvo, alvo, p["escudo"] + p["proporcao_vida_bonus"] * alvo.f.vida_bonus, 4)
        for v in self.aliados(alvo, incluir=True):
            pas = v.f.passiva
            g = pas.get("gatilho")
            if g == "aliado_vida_baixa" and self.t >= v.passiva_pronta and alvo.vida < alvo.f.vida * pas["limite"] <= vida_antes and v.dist(alvo) <= pas["raio"]:
                self.dar_escudo(v, alvo, pas["pct_vida"] * alvo.f.vida, pas["duracao"])
                v.passiva_pronta = self.t + pas["recarga"]
                v.passiva_disparos += 1
            if g == "curativo_preparado" and v.curativo and v.curativo[0] is alvo and v.curativo[1] >= self.t:
                v.curativo = None
                self.curar(v, alvo, pas["pct_vida"] * alvo.f.vida)
                v.passiva_disparos += 1

    def ganhar_furia(self, u, qtd):
        antes = u.recurso
        u.recurso = min(100, u.recurso + qtd)
        bc = u.f.passiva.get("barra_cheia", {})
        if antes < 100 <= u.recurso and "cura_pct_vida" in bc and self.t >= u.furia_extra_pronta:
            u.cura_continua.append([bc["cura_pct_vida"] * u.f.vida / bc["duracao"], self.t + bc["duracao"]])
            u.furia_extra_pronta = self.t + bc["recarga"]
            u.passiva_disparos += 1

    def dano_passiva(self, u, alvo, multiplicador=1.0):
        anterior, u.fonte = u.fonte, "passiva"
        self._dano_passiva(u, alvo, multiplicador)
        u.fonte = anterior

    def _dano_passiva(self, u, alvo, multiplicador=1.0):
        pas = u.f.passiva
        d = pas["dano"]
        valor = no_nivel(d["base"], u.f.nivel) + d.get("dano_fisico_bonus", 0) * u.f.df_bonus + d.get("poder_magico", 0) * u.f.pm
        self.golpear(u, alvo, valor * multiplicador, d["tipo"])
        u.passiva_disparos += 1

    def ao_acertar_habilidade(self, u, h, alvo, principal):
        """Gatilhos de passiva quando uma habilidade atinge um campeão."""
        pas = u.f.passiva
        g = pas.get("gatilho")
        pos = h["posicao"]
        t = self.t
        pronto = t >= u.passiva_pronta
        if g == "isolado" and principal and pos == pas["habilidade"] and pronto:
            if all(o.dist(alvo) > pas["distancia"] for o in self.aliados(alvo)):
                self.dano_passiva(u, alvo)
                u.passiva_pronta = t + pas["recarga"]
        elif g == "isolado_marca_ataque" and principal and pos == pas["habilidade"] and pronto:
            outros = [o for o in self.unidades if o.vivo() and o is not u and o is not alvo]
            if all(o.dist(alvo) > pas["distancia"] for o in outros):
                u.marca_passiva = (alvo, t + pas["janela"])
        elif g == "combo" and pos == pas["sequencia"][1] and pronto:
            if any(p == pas["sequencia"][0] and a is alvo and t - tt <= pas["janela"] for p, a, tt in u.acertos):
                if pas["tipo"] == "dano_extra":
                    self.dano_passiva(u, alvo)
                    if pas.get("devolve_recurso"):
                        u.recurso = min(u.f.recurso_max, u.recurso + pas["devolve_recurso"])
                else:  # escudo_proprio (Treválio)
                    self.dar_escudo(u, u, pas["pct_vida"] * u.f.vida, pas["duracao"])
                    u.passiva_disparos += 1
                u.passiva_pronta = t + pas["recarga"]
        elif g == "abertura" and principal and pos == pas["habilidade"] and pronto and t - u.combate_antes_do_lancamento >= pas["fora_combate"]:
            self.dano_passiva(u, alvo)
            u.passiva_pronta = t + pas["recarga"]
        elif g == "acumulo_de_acertos" and principal and pos == pas["habilidade"]:
            if u.fichas >= pas["fichas"] and pronto:
                self.dano_passiva(u, alvo)
                u.fichas = 0
                u.passiva_pronta = t + pas["recarga"]
            else:
                u.acertos_ficha += 1
                if u.acertos_ficha >= pas["acertos_por_ficha"] and t - u.ultima_ficha >= pas["intervalo_ficha"]:
                    u.acertos_ficha = 0
                    u.fichas = min(pas["fichas"], u.fichas + 1)
                    u.ultima_ficha = t
        elif g == "zona_apos_habilidade" and principal and pos == pas["habilidade"] and pronto:
            u.zona_pendente = (alvo, alvo.x, alvo.y, t + pas["permanencia"])
        elif g == "parado_marca_ataque" and principal and pos == pas["habilidade"] and pronto and t - u.parado_desde >= pas["parado"]:
            u.marca_passiva = (alvo, t + pas["janela"])
        elif g == "duas_habilidades_mesmo_alvo" and pronto:
            if any(p != pos and a is alvo and t - tt <= pas["janela"] for p, a, tt in u.acertos):
                u.cura_continua.append([pas["pct_vida"] * u.f.vida / pas["duracao"], t + pas["duracao"]])
                u.passiva_pronta = t + pas["recarga"]
                u.passiva_disparos += 1
        elif g == "ao_controlar" and pos in pas["habilidades"] and pronto and ("lentidao" in h["mecanica"] or "atordoamento" in h["mecanica"]):
            perto = [a for a in self.aliados(u) if a.dist(u) <= pas["raio"]]
            if perto:
                a = min(perto, key=lambda a: a.dist(u))
                self.dar_escudo(u, a, pas["pct_vida"] * a.f.vida, pas["duracao"])
                u.passiva_pronta = t + pas["recarga"]
                u.passiva_disparos += 1
        u.acertos.append((pos, alvo, t))
        if len(u.acertos) > 12:
            u.acertos = u.acertos[-12:]

    def ao_atacar(self, u, alvo, causado):
        """Gatilhos de passiva e de item no ataque básico."""
        pas = u.f.passiva
        g = pas.get("gatilho")
        t = self.t
        u.ataques.append((alvo, t))
        if len(u.ataques) > 6:
            u.ataques = u.ataques[-6:]
        if pas.get("tipo") == "furia" and t - u.ganho_furia["ataque"] >= 1.0:
            u.ganho_furia["ataque"] = t
            self.ganhar_furia(u, pas["ganho_ataque"])
        seguidos = 0
        for a, tt in reversed(u.ataques):
            if a is alvo and t - tt <= pas.get("janela", 3):
                seguidos += 1
            else:
                break
        pronto = t >= u.passiva_pronta
        if g in ("isolado_marca_ataque", "parado_marca_ataque") and u.marca_passiva and u.marca_passiva[0] is alvo and u.marca_passiva[1] >= t:
            mult = 1 + pas.get("bonus_por_critico", 0) * u.f.critico
            self.dano_passiva(u, alvo, mult)
            u.marca_passiva = None
            u.passiva_pronta = t + pas["recarga"]
        elif g == "ataques_com_acumulo" and seguidos >= pas["ataques"] and pronto:
            if pas["tipo"] == "dano_extra":
                if u.f.acumulos >= pas["acumulos_minimos"]:
                    mult = 1 + pas["bonus_por_acumulo"].get(str(u.f.acumulos), 0)
                    self.dano_passiva(u, alvo, mult)
                    u.passiva_pronta = t + pas["recarga"]
            else:  # Eirafim
                pct = min(pas["teto_pct"], pas["pct_vida"] + pas["pct_por_acumulo"] * u.f.acumulos)
                self.curar(u, u, pct * u.f.vida)
                u.passiva_pronta = t + pas["recarga"]
                u.passiva_disparos += 1
            u.ataques = []
        elif g == "ataques_com_habilidade_em_recarga" and seguidos >= pas["ataques"] and pronto:
            if any(u.recargas.get(p, 0) > t for p in (1, 2)):
                self.dano_passiva(u, alvo)
                u.passiva_pronta = t + pas["recarga"]
                u.ataques = []
        elif g == "custo_vida_e_ataques" and u.janela_custo_vida >= t and seguidos >= pas["ataques"] and pronto:
            u.cura_continua.append([pas["pct_vida"] * u.f.vida / pas["duracao"], t + pas["duracao"]])
            u.passiva_pronta = t + pas["recarga"]
            u.janela_custo_vida = -1
            u.passiva_disparos += 1
        elif g == "ataques_mesmo_alvo" and seguidos >= pas["ataques"] and pronto:
            u.va_bonus.append([pas["pct"], t + pas["duracao"]])
            u.passiva_pronta = t + pas["recarga"]
            u.passiva_disparos += 1

    # --- ações ---------------------------------------------------------------

    def escolher_alvo(self, u):
        """Escolha de alvo por função, como um time médio faria (o Macro do jogador muda isso na partida real)."""
        inimigos = self.inimigos(u)
        if not inimigos:
            return None
        classe = u.f.classe
        carregadores = [o for o in inimigos if o.f.classe in ("atirador", "mago")]
        frageis = [o for o in inimigos if o.f.classe in ("atirador", "mago", "suporte")]
        perto = lambda o: o.dist(u) + (o.vida / o.f.vida) * 150
        if classe == "assassino" and frageis:
            return min(frageis, key=lambda o: (o.vida / o.f.vida) + o.dist(u) / 2000)
        if classe in ("tanque", "suporte"):
            # Proteger os próprios carregadores de quem os ataca de perto.
            meus = [a for a in self.aliados(u) if a.f.classe in ("atirador", "mago")]
            ameacas = [o for o in inimigos if any(o.dist(a) <= 250 for a in meus)]
            if ameacas:
                return min(ameacas, key=lambda o: o.dist(u))
            engaje = any("atordoamento" in h["mecanica"] for h in u.f.habilidades)
            if classe == "tanque" and engaje and carregadores:
                c = min(carregadores, key=lambda o: o.dist(u))
                if c.dist(u) <= 650:
                    return c
        if classe == "lutador" and carregadores:
            c = min(carregadores, key=lambda o: o.dist(u))
            if c.dist(u) <= 420:
                return c
        if classe in ("atirador", "mago"):
            alcance = max([h["mecanica"].get("alcance", 0) for h in u.f.habilidades if h["mecanica"]["alvos"] != "nenhum"] + [u.f.alcance])
            alcance = min(alcance, u.f.alcance + 150)
            ao_alcance = [o for o in inimigos if o.dist(u) <= alcance]
            if ao_alcance:
                return min(ao_alcance, key=lambda o: (o.vida + o.escudo_total(self.t)) / (1.6 if o.f.classe in ("atirador", "mago", "suporte") else 1.0))
        if u.alvo and u.alvo.vivo() and u.dist(u.alvo) <= max(u.f.alcance, 450) + 100:
            return u.alvo
        return min(inimigos, key=perto)

    def distancia_desejada(self, u):
        """Chega perto o bastante para a habilidade de dano pronta de menor alcance, ou para o ataque básico."""
        t = self.t
        alcances = [u.f.alcance]
        for h in u.f.habilidades:
            mec = h["mecanica"]
            if mec["alvos"] in ("um", "area") and "alcance" in mec and u.recargas[h["posicao"]] <= t and self.pode_pagar(u, h):
                alcances.append(mec["alcance"])
        return min(alcances) * 0.85

    def pode_pagar(self, u, h):
        tipo = u.f.recurso_tipo
        custo = h["custo"]
        if tipo in ("mana", "energia"):
            return u.recurso >= round(custo * u.f.escala_custo)
        if tipo == "vida":
            return u.vida > h["mecanica"].get("custo_vida", custo / 100) * u.f.vida + 1
        return True

    def pagar(self, u, h):
        tipo = u.f.recurso_tipo
        cheia = False
        if tipo in ("mana", "energia"):
            u.recurso -= round(h["custo"] * u.f.escala_custo)
        elif tipo == "vida":
            u.vida -= h["mecanica"].get("custo_vida", h["custo"] / 100) * u.f.vida
            u.janela_custo_vida = self.t + u.f.passiva.get("janela", 4)
        elif tipo == "furia":
            # Regra: habilidades não exigem fúria. Lançar com a barra cheia fortalece e gasta o custo.
            if u.recurso >= 100:
                cheia = True
                u.recurso -= h["custo"]
        return cheia

    def alvos_da_habilidade(self, u, h, alvo):
        mec = h["mecanica"]
        tipo = h["alvo"]
        inimigos = self.inimigos(u)
        if mec["alvos"] == "um":
            return [alvo]
        if mec.get("centro") == "si":
            r = mec.get("raio", 200)
            return [o for o in inimigos if o.dist(u) <= r]
        if tipo == "cone":
            alc = mec.get("alcance", 300)
            meia = math.radians(mec.get("abertura", 60)) / 2
            ang = math.atan2(alvo.y - u.y, alvo.x - u.x)
            res = []
            for o in inimigos:
                if o.dist(u) <= alc + 30:
                    da = abs((math.atan2(o.y - u.y, o.x - u.x) - ang + math.pi) % (2 * math.pi) - math.pi)
                    if da <= meia or o is alvo:
                        res.append(o)
            return res
        if tipo == "linha":
            alc = mec.get("alcance", 600)
            larg = mec.get("largura", 70) / 2 + 35
            dx, dy = alvo.x - u.x, alvo.y - u.y
            n = math.hypot(dx, dy) or 1
            dx, dy = dx / n, dy / n
            res = []
            for o in inimigos:
                px, py = o.x - u.x, o.y - u.y
                proj = px * dx + py * dy
                if 0 <= proj <= alc and abs(px * dy - py * dx) <= larg:
                    res.append(o)
            if alvo not in res:
                res.append(alvo)
            return res
        # área centrada no alvo (ou num aliado, como a Última saída)
        r = mec.get("raio", 150)
        centro = alvo
        if mec.get("alvo_centro") == "aliado":
            aliados = self.aliados(u, incluir=True)
            centro = min(aliados, key=lambda a: a.dist(alvo))
        return [o for o in inimigos if o.dist(centro) <= r + 30]

    def usar_dano(self, u, h, alvo):
        mec = h["mecanica"]
        u.combate_antes_do_lancamento = u.ultimo_combate
        u.fonte = "hab%d" % h["posicao"]
        u.usos[u.fonte] += 1
        cheia = self.pagar(u, h)
        u.recargas[h["posicao"]] = self.t + u.f.recarga(h)
        if cheia:
            self.efeito_furia_cheia(u, h)
        if mec.get("avanco"):
            self.mover_para(u, alvo, mec["avanco"], ignorar_lentidao=True)
        if self.rng.random() > chance_acerto(mec):
            return
        alvos = self.alvos_da_habilidade(u, h, alvo)
        if mec.get("primeiro_alvo") or mec["alvos"] == "um":
            alvos = [alvo]
        dano_def = h["dano"]
        tem_dano = no_nivel(dano_def["base"], u.f.nivel) > 0 or any(v for v in dano_def["proporcoes"].values())
        acertados = []
        for i, o in enumerate(alvos):
            principal = o is alvo or (i == 0 and alvo not in alvos)
            if tem_dano:
                d = dict(dano_def)
                prop = dict(dano_def["proporcoes"])
                if prop.get("vida_perdida_alvo_pct"):
                    if mec.get("vida_perdida_exige_marca") and not (u.marca and u.marca[0] is o and u.marca[1] >= self.t):
                        prop["vida_perdida_alvo_pct"] = 0
                    if mec.get("vida_perdida_exige_furia_cheia") and not cheia:
                        prop["vida_perdida_alvo_pct"] = 0
                if u.f.recurso_tipo == "furia" and "vida_propria_sem_furia" in mec and not cheia:
                    prop["vida_maxima_propria_pct"] = mec["vida_propria_sem_furia"]
                d["proporcoes"] = prop
                valor = self.dano_cru(u, o, d, mec, secundario=not principal)
                self.causar(u, o, valor, h["tipo_dano"], mec)
                # Itens que reagem a habilidades
                p = u.f.p("pct_vida_maxima")
                if p:
                    self.golpear(u, o, p["pct"] * o.f.vida, p["dano_tipo"])
                p = u.f.p("queimadura")
                if p:
                    o.queimando_ate = self.t + p["duracao"]
                    o.queimador = u
                    if p.get("anti_cura"):
                        o.anti_cura_ate = max(o.anti_cura_ate, self.t + p["duracao"] + 1)
                p = u.f.p("primeiro_golpe")
                if p and not u.primeiro_golpe_usado:
                    if p["dano_tipo"] == "magico":
                        self.golpear(u, o, p["dano"] + p.get("proporcao_pm", 0) * u.f.pm, "magico")
                        u.primeiro_golpe_usado = True
                    else:
                        u.primeiro_golpe_pendente = True
            if "lentidao" in mec:
                extra = mec.get("furia_cheia", {}).get("lentidao_duracao_extra", 0) if cheia else 0
                self.desacelerar(u, o, mec["lentidao"]["forca"], mec["lentidao"]["duracao"] + extra)
            if "atordoamento" in mec:
                dur = mec.get("furia_cheia", {}).get("atordoamento", mec["atordoamento"]) if cheia else mec["atordoamento"]
                self.atordoar(u, o, dur)
            acertados.append(o)
            self.ao_acertar_habilidade(u, h, o, principal)
        if mec.get("marca") and acertados:
            u.marca = (acertados[0], self.t + mec["marca"]["duracao"])
        if mec.get("consome_marca"):
            u.marca = None
        if cheia and acertados and u.f.passiva.get("barra_cheia", {}).get("reducao_dano"):
            bc = u.f.passiva["barra_cheia"]
            if self.t >= u.furia_extra_pronta:
                u.reducao_dano = (bc["reducao_dano"], self.t + bc["duracao"])
                u.reducao_contra = set(acertados)
                u.furia_extra_pronta = self.t + bc["recarga"]
                u.passiva_disparos += 1
        if mec.get("velocidade_movimento"):
            pass  # bônus de movimento curto: efeito desprezível na luta
        # Especial de suporte com escudo em área (Bruméria)
        pas = u.f.passiva
        if pas.get("gatilho") == "especial_com_acumulos" and h["posicao"] == 3 and u.f.acumulos >= pas["acumulos_minimos"]:
            perto = [a for a in self.aliados(u, incluir=True) if a.dist(u) <= mec.get("raio", 235)]
            if perto:
                a = min(perto, key=lambda a: a.vida / a.f.vida)
                pct = min(pas["teto_pct"], pas["pct_vida"] + pas["pct_por_acumulo_extra"] * (u.f.acumulos - pas["acumulos_minimos"]))
                self.dar_escudo(u, a, pct * a.f.vida, pas["duracao"])
                u.passiva_disparos += 1

    def efeito_furia_cheia(self, u, h):
        bc = u.f.passiva.get("barra_cheia", {})
        if "escudo_pct_vida" in bc and self.t >= u.furia_extra_pronta:
            self.dar_escudo(u, u, bc["escudo_pct_vida"] * u.f.vida, bc["duracao"])
            u.furia_extra_pronta = self.t + bc["recarga"]
            u.passiva_disparos += 1

    def valor_protecao(self, u, alvo, d):
        valor = d["pct_vida"] * alvo.f.vida + d.get("pm", 0) * u.f.pm
        if "teto_pct" in d:
            valor = min(valor, d["teto_pct"] * alvo.f.vida)
        return valor

    def usar_protecao(self, u, h, alvo):
        mec = h["mecanica"]
        pas = u.f.passiva
        cheia = self.pagar(u, h)
        u.recargas[h["posicao"]] = self.t + u.f.recarga(h)
        if cheia:
            self.efeito_furia_cheia(u, h)
        if "escudo" in mec:
            d = dict(mec["escudo"])
            if cheia and "escudo_pct_vida" in mec.get("furia_cheia", {}):
                d["pct_vida"] = mec["furia_cheia"]["escudo_pct_vida"]
            if pas.get("gatilho") == "reforco_na_zona" and h["posicao"] == pas["habilidade"] and u.zona_ate >= self.t and self.t >= u.passiva_pronta:
                d["pct_vida"] += pas["pct_extra"]
                d["teto_pct"] = pas["teto_pct"]
                u.passiva_pronta = self.t + pas["recarga"]
                u.passiva_disparos += 1
            self.dar_escudo(u, alvo, self.valor_protecao(u, alvo, d), d["duracao"])
            if pas.get("gatilho") == "escudo_secundario" and h["posicao"] == 2 and u.f.acumulos >= pas["acumulos_minimos"] and self.t >= u.passiva_pronta:
                outros = [a for a in self.aliados(u, incluir=True) if a is not alvo and a.dist(alvo) <= pas["raio"]]
                if outros:
                    b = min(outros, key=lambda a: a.vida / a.f.vida)
                    pct = min(pas["teto_pct"], pas["pct_vida"] + pas["pct_por_acumulo_extra"] * (u.f.acumulos - pas["acumulos_minimos"]))
                    self.dar_escudo(u, b, pct * b.f.vida, pas["duracao"])
                    u.passiva_pronta = self.t + pas["recarga"]
                    u.passiva_disparos += 1
        if "cura" in mec:
            d = mec["cura"]
            estava_baixo = alvo.vida < alvo.f.vida * 0.4
            valor = self.valor_protecao(u, alvo, d)
            pulsos = d.get("pulsos", 1)
            self.curar(u, alvo, valor / pulsos)
            if pulsos > 1:
                u.cura_pendente = (alvo, valor / pulsos, self.t + d.get("intervalo", 1))
            if estava_baixo:
                if pas.get("gatilho") == "curativo_preparado" and self.t >= u.passiva_pronta:
                    u.curativo = (alvo, self.t + pas["janela"])
                    u.passiva_pronta = self.t + pas["recarga"]
                if pas.get("gatilho") == "especial_cura_vida_baixa" and h["posicao"] == 3:
                    self.dar_escudo(u, alvo, pas["pct_vida"] * alvo.f.vida, pas["duracao"])
                    u.passiva_disparos += 1
        if "reduz_lentidao" in mec:
            u.reduz_lentidao = (mec["reduz_lentidao"]["pct"], self.t + mec["reduz_lentidao"]["duracao"])
        if "zona" in mec:
            u.zona_ate = self.t + mec["zona"]["duracao"]
        if pas.get("gatilho") == "especial_revela" and h["posicao"] == 3:
            aliados = sorted(self.aliados(u, incluir=True), key=lambda a: min([a.dist(o) for o in self.inimigos(u)] + [9999]))
            for a in aliados[:pas["aliados"]]:
                self.dar_escudo(u, a, pas["pct_vida"] * a.f.vida, pas["duracao"])
            u.passiva_disparos += 1
        if mec.get("proximo_ataque"):
            u.ataque_fortalecido = (h, self.t + mec["proximo_ataque"]["janela"])

    def mover_para(self, u, alvo, distancia, ignorar_lentidao=False, manter=0):
        dx, dy = alvo.x - u.x, alvo.y - u.y
        n = math.hypot(dx, dy)
        if n <= manter or n == 0:
            return
        passo = min(distancia, n - manter)
        u.x += dx / n * passo
        u.y += dy / n * passo
        u.parado_desde = self.t

    def agir(self, u):
        t = self.t
        f = u.f
        # Regeneração de recurso e efeitos contínuos
        if f.recurso_tipo in ("mana", "energia"):
            u.recurso = min(f.recurso_max, u.recurso + f.regen * DT)
        elif f.recurso_tipo == "furia" and t - u.ultimo_combate > f.passiva.get("fora_combate", 4):
            u.recurso = max(0, u.recurso - f.passiva.get("perda_fora_combate", 10) * DT)
        for c in u.cura_continua:
            if c[1] > t:
                self.curar(u, u, c[0] * DT)
        u.cura_continua = [c for c in u.cura_continua if c[1] > t]
        cp = getattr(u, "cura_pendente", None)
        if cp and cp[2] <= t:
            if cp[0].vivo():
                self.curar(u, cp[0], cp[1])
            u.cura_pendente = None
        zp = getattr(u, "zona_pendente", None)
        if zp and zp[3] <= t:
            alvo = zp[0]
            if alvo.vivo() and math.hypot(alvo.x - zp[1], alvo.y - zp[2]) < 110:
                self.dano_passiva(u, alvo)
                u.passiva_pronta = t + f.passiva["recarga"]
            u.zona_pendente = None
        if u.queimando_ate > t and u.queimador is not None:
            p = u.queimador.f.p("queimadura")
            self.golpear(u.queimador, u, p["pct_por_segundo"] * u.f.vida * DT, "magico")
        p = f.p("regeneracao")
        if p and t >= u.proxima_regeneracao:
            self.curar(u, u, p["pct_vida"] * f.vida)
            u.proxima_regeneracao = t + p["a_cada"]
        if not u.vivo() or u.atordoado_ate > t:
            return
        # Proteções em aliados e em si
        for h in f.habilidades:
            mec = h["mecanica"]
            if u.recargas[h["posicao"]] > t or not self.pode_pagar(u, h):
                continue
            if "escudo" in mec or "cura" in mec:
                alvo = self.alvo_de_protecao(u, h)
                if alvo:
                    self.usar_protecao(u, h, alvo)
                    return
            elif mec["alvos"] == "nenhum" and ("visao" in mec or "zona" in mec):
                if any(min(a.dist(o) for a in self.aliados(u, incluir=True)) < 650 for o in self.inimigos(u)):
                    self.usar_protecao(u, h, u)
                    return
            elif mec["alvos"] == "nenhum" and "reduz_lentidao" in mec:
                if u.lento(t) > 0:
                    self.usar_protecao(u, h, u)
                    return
            elif mec.get("proximo_ataque"):
                alvo = u.alvo
                if alvo and alvo.vivo() and u.dist(alvo) <= f.alcance + 40:
                    self.usar_protecao(u, h, u)
                    return
        alvo = self.escolher_alvo(u)
        if alvo is None:
            return
        u.alvo = alvo
        d = u.dist(alvo)
        # Habilidades de dano / controle
        # Ordem: controle forte (atordoamento) primeiro para abrir a luta; depois 1, 2, 3 (combos da passiva usam 1 → 2).
        for h in sorted(f.habilidades, key=lambda h: (0 if "atordoamento" in h["mecanica"] else 1, h["posicao"])):
            mec = h["mecanica"]
            if mec["alvos"] in ("nenhum",) and not mec.get("avanco"):
                continue
            if "escudo" in mec or "cura" in mec or mec.get("proximo_ataque"):
                continue
            if u.recargas[h["posicao"]] > t or not self.pode_pagar(u, h):
                continue
            if mec.get("exige_marca") and not (u.marca and u.marca[1] >= t):
                continue
            pas = f.passiva
            if pas.get("gatilho") == "combo" and h["posicao"] == pas["sequencia"][1] and t >= u.passiva_pronta:
                primeira = next((x for x in f.habilidades if x["posicao"] == pas["sequencia"][0]), None)
                if primeira and u.recargas[primeira["posicao"]] <= t and self.pode_pagar(u, primeira):
                    continue  # segura a 2ª habilidade do combo até a 1ª acertar
            if mec.get("exige_ataque_recente") and not any(a is alvo and t - tt <= mec["exige_ataque_recente"] for a, tt in u.ataques):
                continue
            alcance = mec.get("alcance", f.alcance) + (mec.get("avanco", 0) if mec["alvos"] != "nenhum" else 0)
            if mec["alvos"] == "nenhum" and mec.get("avanco"):
                # avanço puro: usar para encurtar distância
                if f.alcance + 40 < d <= f.alcance + mec["avanco"] + 60:
                    self.pagar(u, h)
                    u.recargas[h["posicao"]] = t + f.recarga(h)
                    self.mover_para(u, alvo, mec["avanco"], ignorar_lentidao=True, manter=f.alcance * 0.8)
                    return
                continue
            if mec.get("centro") == "si":
                if any(o.dist(u) <= mec.get("raio", 200) for o in self.inimigos(u)):
                    self.usar_dano(u, h, alvo)
                    return
                continue
            if d <= alcance:
                self.usar_dano(u, h, alvo)
                return
        # Ataque básico
        if d <= f.alcance + 20:
            if t >= u.proximo_ataque:
                va = f.va * (1 + sum(b[0] for b in u.va_bonus if b[1] > t))
                frio = alvo.f.p("reducao_va_inimigos")
                if frio:
                    va *= 1 - frio["pct"]
                va = min(REGRAS["velocidade_ataque_maxima"], va)
                u.proximo_ataque = t + 1 / va
                self.ataque_basico(u, alvo)
            return
        # Movimento
        vm = f.vm * (1 - u.lento(t))
        self.mover_para(u, alvo, vm * DT, manter=self.distancia_desejada(u))

    def ataque_basico(self, u, alvo):
        f = u.f
        u.fonte = "ataque"
        dano = f.df * (1 + f.critico * (f.dano_critico - 1))
        p = alvo.f.p("reducao_critico")
        if p and f.critico > 0:
            dano -= f.df * f.critico * f.dano_critico * p["pct"]
        causado = self.golpear(u, alvo, dano, "fisico", ataque_basico=True)
        if f.roubo_vida:
            self.curar(u, u, causado * f.roubo_vida)
        af = getattr(u, "ataque_fortalecido", None)
        if af and af[1] >= self.t:
            h = af[0]
            extra = self.dano_cru(u, alvo, h["dano"], h["mecanica"])
            efetivo = self.causar(u, alvo, extra, h["tipo_dano"], h["mecanica"])
            self.curar(u, u, efetivo * h["mecanica"]["proximo_ataque"]["roubo_do_extra"])
            u.ataque_fortalecido = None
        p = f.p("ao_acertar")
        if p:
            self.golpear(u, alvo, p["dano"] + p.get("proporcao_pm", 0) * f.pm, "magico")
        p = f.p("colosso")
        if p:
            self.golpear(u, alvo, p["dano_ataque_pct_vida"] * f.vida, "fisico")
        p = f.p("rajada")
        if p and len(u.ataques) % 3 == 2:
            self.golpear(u, alvo, p["dano"] + p.get("proporcao_df_bonus", 0) * f.df_bonus, "magico")
        if u.primeiro_golpe_pendente and not u.primeiro_golpe_usado:
            p = f.p("primeiro_golpe")
            self.golpear(u, alvo, p["dano"] + p.get("proporcao_df_bonus", 0) * f.df_bonus, "fisico")
            u.primeiro_golpe_usado = True
            u.primeiro_golpe_pendente = False
        p = alvo.f.p("espinhos")
        if p and alvo.vivo():
            self.golpear(alvo, u, causado * p["reflexo"] * (100 + alvo.f.armadura) / 100, "magico")
            if p.get("anti_cura"):
                u.anti_cura_ate = self.t + 3
        self.ao_atacar(u, alvo, causado)

    def alvo_de_protecao(self, u, h):
        mec = h["mecanica"]
        if mec.get("escudo", mec.get("cura", {})).get("alvo") == "si":
            recente = u.dano_recebido > 0 and self.t - u.ultimo_combate < 0.6
            return u if recente and u.vida < u.f.vida * 0.95 else None
        alcance = mec.get("alcance", 600)
        candidatos = [a for a in self.aliados(u, incluir=True) if a.dist(u) <= alcance]
        if "cura" in mec:
            valor = mec["cura"]["pct_vida"]
            candidatos = [a for a in candidatos if a.f.vida - a.vida >= a.f.vida * valor * 0.8]
            limite = 0.45 if h["posicao"] == 3 else 0.75
            candidatos = [a for a in candidatos if a.vida < a.f.vida * limite]
        else:
            candidatos = [a for a in candidatos if self.t - a.ultimo_combate < 0.6 and a.vida < a.f.vida * 0.9]
        if not candidatos:
            return None
        return min(candidatos, key=lambda a: a.vida / a.f.vida - (0.1 if a.f.classe in ("atirador", "mago") else 0))

    def rodar(self, tempo_maximo=TEMPO_MAXIMO):
        ordem = list(self.unidades)
        while self.t < tempo_maximo:
            self.rng.shuffle(ordem)
            for u in ordem:
                self.agir(u)
            vivos = {u.time for u in self.unidades if u.vivo()}
            if len(vivos) < 2:
                break
            self.t += DT
        return self.resultado()

    def resultado(self):
        frac = defaultdict(float)
        for u in self.unidades:
            frac[u.time] += max(0, u.vida) / u.f.vida
        return 0 if frac[0] > frac[1] else 1 if frac[1] > frac[0] else self.rng.randint(0, 1)


# ---------------------------------------------------------------------------
# Cenários
# ---------------------------------------------------------------------------

POSICAO_INICIAL = {"tanque": 300, "lutador": 330, "assassino": 430, "mago": 620, "atirador": 660, "suporte": 560}


def montar(campeoes_time, time, momento, rng, cenario, rivais=None):
    m = MOMENTOS[momento]
    sinal = -1 if time == 0 else 1
    unidades = []
    for c in campeoes_time:
        f = Ficha(c, m["nivel"], m["itens"], m["bota"], m["acumulos"], rivais)
        if cenario == "luta":
            x = sinal * POSICAO_INICIAL[c["classe"]]
            y = rng.uniform(-140, 140)
            if c["classe"] == "assassino":
                y = rng.choice([-1, 1]) * rng.uniform(150, 280)
        else:
            x = sinal * 420
            y = rng.uniform(-60, 60)
        unidades.append(Unidade(f, time, x, y, rng))
    return unidades


def sortear_por_posicao(campeoes, rng, posicoes):
    usados = set()
    escolha = []
    for pos in posicoes:
        opcoes = [(c, 1.0 if c["posicoes"][0] == pos else 0.5) for c in campeoes if pos in c["posicoes"] and c["id"] not in usados]
        total = sum(w for _, w in opcoes)
        r = rng.uniform(0, total)
        for c, w in opcoes:
            r -= w
            if r <= 0:
                break
        usados.add(c["id"])
        escolha.append(c)
    return escolha


def uma_luta(args):
    semente, momento, cenario = args
    rng = random.Random(semente)
    campeoes = CAMPEOES_GLOBAL
    if cenario == "luta":
        a_b = sortear_por_posicao(campeoes, rng, POSICOES * 2)
        a, b = a_b[0::2], a_b[1::2]
        objetivo = rng.random() < 0.5
    elif cenario == "dupla":
        a_b = sortear_por_posicao(campeoes, rng, ["atirador", "atirador", "suporte", "suporte"])
        a, b = [a_b[0], a_b[2]], [a_b[1], a_b[3]]
        objetivo = False
    else:  # duelo
        pos = rng.choice(["topo", "meio", "selva"])
        a_b = sortear_por_posicao(campeoes, rng, [pos, pos])
        a, b = [a_b[0]], [a_b[1]]
        objetivo = False
    ua, ub = montar(a, 0, momento, rng, cenario, b), montar(b, 1, momento, rng, cenario, a)
    luta = Luta(ua, ub, rng, objetivo)
    vencedor = luta.rodar()
    linhas = []
    for u in luta.unidades:
        linhas.append((u.f.id, momento, cenario, 1 if u.time == vencedor else 0,
                       u.dano, u.protecao, u.controle, u.passiva_disparos, 1 if u.morte is not None else 0))
    return linhas


CAMPEOES_GLOBAL = None


def iniciar(campeoes):
    global CAMPEOES_GLOBAL
    CAMPEOES_GLOBAL = campeoes


def medir(campeoes, lutas, semente, processos=2, duelos=False):
    tarefas = []
    for i, momento in enumerate(MOMENTOS):
        for j in range(lutas):
            base = semente * 1000003 + i * 100003 + j * 3
            tarefas.append((base, momento, "luta"))
            if j % 2 == 0:
                tarefas.append((base + 2, momento, "dupla"))
            if duelos and j % 2 == 1:
                tarefas.append((base + 1, momento, "duelo"))
    with Pool(processos, initializer=iniciar, initargs=(campeoes,)) as pool:
        resultados = pool.map(uma_luta, tarefas, chunksize=40)
    tab = defaultdict(lambda: defaultdict(list))
    for linhas in resultados:
        for cid, momento, cen, venceu, dano, prot, ctrl, pas, morreu in linhas:
            tab[cid][(momento, cen)].append((venceu, dano, prot, ctrl, pas, morreu))
    return tab


def taxa(tab, cid, momento):
    """Taxa de vitória ponderada pelos cenários."""
    total = peso = 0.0
    for cen, w in PESO_CENARIO.items():
        lst = tab[cid].get((momento, cen), [])
        if lst:
            total += w * statistics.mean(x[0] for x in lst)
            peso += w
    return total / peso if peso else 0.5


def amostras(tab, cid, momento):
    return sum(len(tab[cid].get((momento, c), [])) for c in PESO_CENARIO)


# ---------------------------------------------------------------------------
# Calibração automática
# ---------------------------------------------------------------------------

LIMITES = (0.5, 2.0)


def calibrar(rodadas, lutas, semente):
    ajustes = json.load(open(CAMINHO_AJUSTES, encoding="utf-8")) if os.path.exists(CAMINHO_AJUSTES) else {}
    for rodada in range(rodadas):
        os.system("python3 %s > /dev/null" % os.path.join(RAIZ, "tools", "conversao", "converter_campeoes.py"))
        campeoes = carregar_campeoes()
        tab = medir(campeoes, lutas, semente + rodada)
        erro_total = 0
        for c in campeoes:
            alvo = ALVO_CURVA[c["curva_de_forca"]]
            e_ini = alvo["inicio"] - taxa(tab, c["id"], "inicio")
            e_mei = alvo["meio"] - taxa(tab, c["id"], "meio")
            e_fim = alvo["fim"] - taxa(tab, c["id"], "fim")
            erro_total += abs(e_ini) + abs(e_mei) + abs(e_fim)
            a = ajustes.setdefault(c["id"], {"inicio": 1.0, "fim": 1.0})
            # Sensibilidade aproximada: 10% de força ≈ 3 pontos de taxa de vitória. Passos amortecidos e limitados.
            sens = 0.3
            passo_ini = max(-0.15, min(0.15, (e_ini + 0.3 * e_mei) / sens * 0.4))
            passo_fim = max(-0.15, min(0.15, (e_fim + 0.3 * e_mei) / sens * 0.4))
            a["inicio"] = round(max(LIMITES[0], min(LIMITES[1], a["inicio"] * (1 + passo_ini))), 3)
            a["fim"] = round(max(LIMITES[0], min(LIMITES[1], a["fim"] * (1 + passo_fim))), 3)
            a["motivo"] = "Calibração do laboratório de campeões (taxa de vitória por momento da partida)."
        print("Rodada %d: erro médio %.1f pontos" % (rodada + 1, erro_total / (3 * len(campeoes)) * 100))
        with open(CAMINHO_AJUSTES, "w", encoding="utf-8") as arquivo:
            json.dump(ajustes, arquivo, ensure_ascii=False, indent="\t", sort_keys=True)
            arquivo.write("\n")
    os.system("python3 %s > /dev/null" % os.path.join(RAIZ, "tools", "conversao", "converter_campeoes.py"))


# ---------------------------------------------------------------------------
# Relatório
# ---------------------------------------------------------------------------

def tempo_para_matar(fa, fb, rng):
    """Tempo para fa matar fb sem reação (fb fica atordoado)."""
    ua, ub = Unidade(fa, 0, -150, 0, rng), Unidade(fb, 1, 150, 0, rng)
    luta = Luta([ua], [ub], rng)
    ub.atordoado_ate = 9999
    luta.rodar(tempo_maximo=300)
    return ub.morte if ub.morte is not None else 300


def valor_de_nivel(campeoes, semente):
    """Força relativa de 1 e 2 níveis a mais, no meio da partida, com o mesmo campeão e os mesmos itens.

    Força = raiz(tempo que o rival leva para me matar / tempo que eu levo para matá-lo). 1,075 = 7,5% mais forte.
    """
    rng = random.Random(semente)
    resultado = {}
    for dif in (1, 2):
        razoes = []
        for c in campeoes:
            fa = Ficha(c, 10 + dif, 2, True, 2)
            fb = Ficha(c, 10, 2, True, 2)
            razoes.append(math.sqrt(tempo_para_matar(fb, fa, rng) / tempo_para_matar(fa, fb, rng)))
        resultado[dif] = statistics.mean(razoes)
    return resultado


def relatorio(lutas, semente):
    campeoes = carregar_campeoes()
    tab = medir(campeoes, lutas, semente)
    linhas = []
    print("\n== Taxa de vitória por momento (luta 5x5 85%%, rota dupla 15%%) — %d lutas 5x5 por momento\n" % lutas)
    print("%-10s %-9s %-9s %6s %6s %6s %6s  %s" % ("Campeão", "Classe", "Curva", "Início", "Meio", "Fim", "Geral", "Fora do alvo"))
    fora = 0
    for curva in ("inicio", "constante", "fim", "pico_nivel_6"):
        for c in sorted([c for c in campeoes if c["curva_de_forca"] == curva], key=lambda c: c["classe"]):
            t = {m: taxa(tab, c["id"], m) for m in MOMENTOS}
            geral = 0.3 * t["inicio"] + 0.4 * t["meio"] + 0.3 * t["fim"]
            alvo = ALVO_CURVA[curva]
            desvios = [m for m in MOMENTOS if abs(t[m] - alvo[m]) > 0.04]
            fora += len(desvios)
            linhas.append((c, t, geral))
            print("%-10s %-9s %-9s %5.1f%% %5.1f%% %5.1f%% %5.1f%%  %s" % (c["nome"], c["classe"], curva, t["inicio"] * 100, t["meio"] * 100, t["fim"] * 100, geral * 100, ", ".join(desvios)))
    print("\nMomentos fora do alvo (±4 pontos): %d de %d" % (fora, 3 * len(campeoes)))
    print("\n== Média por classe")
    for classe in ("tanque", "assassino", "lutador", "mago", "suporte", "atirador"):
        g = [x for x in linhas if x[0]["classe"] == classe]
        print("  %-9s início %5.1f%%  meio %5.1f%%  fim %5.1f%%" % (classe, *[statistics.mean(x[1][m] for x in g) * 100 for m in MOMENTOS]))
    print("\n== Média por curva")
    for curva in ("inicio", "constante", "fim"):
        g = [x for x in linhas if x[0]["curva_de_forca"] == curva]
        print("  %-9s início %5.1f%%  meio %5.1f%%  fim %5.1f%%" % (curva, *[statistics.mean(x[1][m] for x in g) * 100 for m in MOMENTOS]))
    print("\n== Contribuição média por luta 5x5 no fim (dano, proteção a aliados, controle em s, disparos da passiva)")
    for c in campeoes:
        lst = tab[c["id"]].get(("fim", "luta"), [])
        if lst:
            print("  %-10s dano %5.0f  proteção %4.0f  controle %4.1f  passiva %4.1f  morre %3.0f%%" % (
                c["nome"], statistics.mean(x[1] for x in lst), statistics.mean(x[2] for x in lst),
                statistics.mean(x[3] for x in lst), statistics.mean(x[4] for x in lst), statistics.mean(x[5] for x in lst) * 100))
    vn = valor_de_nivel(campeoes, semente)
    print("\n== Valor de nível (duelo do mesmo campeão no meio da partida)")
    print("  1 nível a mais: %+.1f%% de força; 2 níveis a mais: %+.1f%%" % ((vn[1] - 1) * 100, (vn[2] - 1) * 100))
    return tab


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--lutas", type=int, default=900)
    ap.add_argument("--semente", type=int, default=1)
    ap.add_argument("--calibrar", type=int, default=0)
    args = ap.parse_args()
    if args.calibrar:
        calibrar(args.calibrar, args.lutas, args.semente)
    relatorio(args.lutas, args.semente)
