#!/usr/bin/env python3
"""
Protótipo de RITMO da partida de Crystal Legends.

Não é a simulação final (que será em GDScript, etapa 5). Serve para testar, com milhares de partidas,
se os números de data/config/partida.json geram partidas com boa duração e emoção:
duração, níveis, itens, abates, viradas, tempo sem acontecimentos, chance do time mais forte.

Uso:
    python3 tools/prototipos/ritmo_partida.py                 # relatório padrão
    python3 tools/prototipos/ritmo_partida.py --partidas 4000 --nivel-maximo 18
    python3 tools/prototipos/ritmo_partida.py --sem-tensao-final

Modelo (simplificado de propósito):
- Passos de 5 segundos. 10 jogadores com habilidade (Farm, Micro, Macro, Mental) em torno da qualidade do time.
- Ondas de minions dão XP (por presença) e ouro (por último golpe, conforme o Farm).
- Caçador limpa os acampamentos da selva conforme o Farm e o tempo de reaparecimento.
- Força de cada campeão = habilidade × nível × ouro gasto em itens (até 5 itens) × bônus.
- Fase de rotas (até ~14 min): trocas na rota (Micro), ganks do caçador (Macro decide ir, Micro decide o resultado).
- Depois: lutas em equipe nos objetivos (Cérbero, Hydra) e em momentos aleatórios. O vencedor converte
  a vantagem em objetivos, torres, Guardião e Cristal enquanto os inimigos renascem.
- Renascimento cresce com o nível e no fim de jogo. "Tensão final" fragiliza estruturas a partir do minuto 35.
"""

import argparse
import json
import math
import os
import random
import statistics
from dataclasses import dataclass, field

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CAMINHO_CONFIG = os.path.join(RAIZ, "data", "config", "partida.json")

POSICOES = ["topo", "selva", "meio", "atirador", "suporte"]
ROTA_DE = {"topo": "topo", "meio": "meio", "atirador": "baixo", "suporte": "baixo", "selva": None}
ROTAS = ["topo", "meio", "baixo"]
PASSO = 5  # segundos

# Constantes internas do protótipo (como a "física" do modelo responde). Não são regras do jogo.
AJUSTE = {
    "troca_rota_a_cada": 520,      # segundos médios entre trocas que geram abate, por rota
    "gank_base": 330,              # quanto maior, menos ganks (Macro do caçador reduz)
    "luta_sensibilidade": 3.2,     # quão decisiva é a diferença de força numa luta
    "habilidade_base": 0.75,       # peso fixo da habilidade no poder
    "habilidade_peso": 0.35,        # peso dos atributos no poder
    "defesa_base": 1.15,           # bônus de quem luta perto da própria base
    "dano_torre_rota": 0.075,       # ritmo de dano em torres pelas rotas
    "cerco_torre": 1.0, "cerco_guardiao": 0.45, "cerco_cristal": 0.75,
    "intervalo_luta_meio": 165, "intervalo_luta_fim": 140,
    "espera_luta_objetivo": 120,   # segundos médios até alguém disputar um objetivo disponível
    "ganks_ate_min": 20,           # depois disso o caçador anda com o time
    "chance_disputar_objetivo": 0.5,  # senão, um time pega o objetivo sem luta
    "renda_super_minions": 1.0,    # ouro/s extra por jogador para quem tem a base exposta
}


def carregar_config():
    with open(CAMINHO_CONFIG, encoding="utf-8") as arquivo:
        return json.load(arquivo)


def sig(x):
    return 1.0 / (1.0 + math.exp(-x))


# ---------------------------------------------------------------------------
# Progressão teórica (farm perfeito): níveis, objetivos e itens
# ---------------------------------------------------------------------------

def xp_para_nivel(cfg, nivel):
    """XP acumulada necessária para chegar ao nível (nível 1 = 0)."""
    n = cfg["niveis"]
    total = 0
    for alvo in range(2, nivel + 1):
        total += n["xp_para_nivel_2"] + n["xp_incremento_por_nivel"] * (alvo - 2)
    return total


def nivel_por_xp(cfg, xp):
    nivel = 1
    while nivel < cfg["niveis"]["maximo"] and xp >= xp_para_nivel(cfg, nivel + 1):
        nivel += 1
    return nivel


def xp_e_ouro_por_onda(cfg):
    o = cfg["ondas"]
    xp_onda = o["corpo_a_corpo"] * o["xp"]["corpo_a_corpo"] + o["a_distancia"] * o["xp"]["a_distancia"]
    ouro_onda = o["corpo_a_corpo"] * o["ouro"]["corpo_a_corpo"] + o["a_distancia"] * o["ouro"]["a_distancia"]
    xp_cerco = o["xp"]["cerco"] / o["cerco_a_cada_ondas"]
    ouro_cerco = o["ouro"]["cerco"] / o["cerco_a_cada_ondas"]
    return xp_onda + xp_cerco, ouro_onda + ouro_cerco


def taxa_selva(cfg, farm):
    """XP e ouro por segundo de um caçador com o Farm dado (0-100), limitado pelo reaparecimento."""
    acamps = cfg["selva"]["acampamentos"]
    fator = 1.35 - 0.7 * farm / 100.0           # Farm 50 = 1.0x; Farm 100 = 0.65x do tempo
    limpeza = sum(a["limpeza"] for a in acamps) * fator + 45  # + deslocamento
    ciclo = max(limpeza, min(a["reaparece"] for a in acamps))
    # Acampamentos médios reaparecem a cada 300 s: entram na média proporcionalmente.
    xp = sum(a["xp"] * (min(1.0, ciclo / a["reaparece"])) for a in acamps)
    ouro = sum(a["ouro"] * (min(1.0, ciclo / a["reaparece"])) for a in acamps)
    return xp / ciclo, ouro / ciclo


def progressao_teorica(cfg):
    """Tempos para cada nível com farm perfeito (rota solo, rota dupla, selva)."""
    xp_onda, ouro_onda = xp_e_ouro_por_onda(cfg)
    o = cfg["ondas"]
    xp_seg_solo = xp_onda / o["intervalo"]
    xp_seg_dupla = xp_seg_solo * o["bonus_xp_rota_dupla"] / 2
    xp_seg_selva, _ = taxa_selva(cfg, 70)
    inicio = o["primeira_chegada"]
    resultado = {}
    for nome, taxa, comeco in [("solo", xp_seg_solo, inicio), ("dupla", xp_seg_dupla, inicio),
                               ("selva", xp_seg_selva, cfg["selva"]["primeira_aparicao"])]:
        tempos = {}
        for nivel in range(2, cfg["niveis"]["maximo"] + 1):
            tempos[nivel] = comeco + xp_para_nivel(cfg, nivel) / taxa
        resultado[nome] = tempos
    return resultado


def renascimento(cfg, nivel, minuto):
    r = cfg["renascimento"]
    tempo = r["base"] + r["por_nivel"] * nivel
    if minuto > r["inicio_acrescimo_tardio_min"]:
        extra = min(r["acrescimo_tardio_maximo"], (minuto - r["inicio_acrescimo_tardio_min"]) * r["acrescimo_tardio_por_min"])
        tempo *= 1 + extra
    return tempo


# ---------------------------------------------------------------------------
# Simulação de uma partida
# ---------------------------------------------------------------------------

@dataclass
class Campeao:
    time: int
    posicao: str
    farm: float
    micro: float
    macro: float
    mental: float
    xp: float = 0.0
    ouro_total: float = 500.0   # ouro inicial
    morto_ate: float = 0.0
    abates_seguidos: int = 0
    abates: int = 0
    mortes: int = 0

    def vivo(self, t):
        return t >= self.morto_ate


@dataclass
class Estado:
    torres: list = field(default_factory=lambda: [{r: [100.0, 120.0, 150.0] for r in ROTAS} for _ in range(2)])
    guardiao_vivo: list = field(default_factory=lambda: [True, True])
    guardiao_renasce: list = field(default_factory=lambda: [0.0, 0.0])
    guardiao_vida: list = field(default_factory=lambda: [100.0, 100.0])
    cristal: list = field(default_factory=lambda: [100.0, 100.0])
    bonus_hydra: list = field(default_factory=lambda: [0.0, 0.0])
    bonus_cerbero: list = field(default_factory=lambda: [0.0, 0.0])
    hydra_disponivel_em: float = 0.0
    cerbero_disponivel_em: float = 0.0
    eventos: list = field(default_factory=list)   # (tempo, tipo)
    lutas: int = 0


class Partida:
    def __init__(self, cfg, qualidade_a, qualidade_b, rng, tensao_final=True):
        self.cfg = cfg
        self.rng = rng
        self.tensao_final = tensao_final
        self.campeoes = []
        for time, qualidade in enumerate([qualidade_a, qualidade_b]):
            for pos in POSICOES:
                g = lambda: max(5.0, min(100.0, rng.gauss(qualidade, 8)))
                self.campeoes.append(Campeao(time, pos, g(), g(), g(), g()))
        self.e = Estado()
        prog = progressao_teorica(cfg)
        epic = cfg["monstros_epicos"]
        self.e.cerbero_disponivel_em = prog["solo"][epic["cerbero"]["aparece_no_nivel_teorico"]]
        self.e.hydra_disponivel_em = prog["solo"][epic["hydra"]["aparece_no_nivel_teorico"]]
        self.xp_onda, self.ouro_onda = xp_e_ouro_por_onda(cfg)
        self.historico_ouro = []
        self.vencedor = None
        self.t = 0.0

    # --- utilidades ---
    def time(self, n):
        return [c for c in self.campeoes if c.time == n]

    def nivel(self, c):
        return nivel_por_xp(self.cfg, c.xp)

    def ouro_itens(self, c):
        it = self.cfg["itens"]
        teto = it["preco_bota"] + it["preco_item_medio"] * (it["maximo_por_campeao"] - 1)
        return min(c.ouro_total - 500, teto) if c.ouro_total > 500 else 0.0

    def poder(self, c):
        nivel = self.nivel(c)
        habilidade = AJUSTE["habilidade_base"] + AJUSTE["habilidade_peso"] * (0.5 * c.micro + 0.3 * c.macro + 0.2 * c.farm) / 100.0
        p = habilidade * (1 + 0.075 * (nivel - 1)) * (1 + self.ouro_itens(c) / 5000.0)
        if self.t < self.e.bonus_hydra[c.time]:
            p *= 1.10
        return p

    def ouro_time(self, n):
        return sum(c.ouro_total for c in self.time(n))

    def fragilidade(self):
        ft = self.cfg["fim_de_jogo"]
        minuto = self.t / 60
        if not self.tensao_final or minuto < ft["inicio_tensao_final_min"]:
            return 1.0
        return 1.0 + ft["fragilidade_por_min"] * (minuto - ft["inicio_tensao_final_min"])

    def registrar(self, tipo):
        self.e.eventos.append((self.t, tipo))

    def matar(self, vitima, assassino):
        if not vitima.vivo(self.t):
            return
        ab = self.cfg["abates"]
        nivel_vitima = self.nivel(vitima)
        recompensa = min(ab["recompensa_maxima"], vitima.abates_seguidos * ab["recompensa_por_abate_seguido"])
        vitima.morto_ate = self.t + renascimento(self.cfg, nivel_vitima, self.t / 60)
        vitima.mortes += 1
        vitima.abates_seguidos = 0
        if assassino is not None:
            assassino.ouro_total += ab["ouro"] + recompensa
            assassino.xp += ab["xp_base"] + ab["xp_por_nivel_vitima"] * nivel_vitima
            assassino.abates += 1
            assassino.abates_seguidos += 1
            vivos = [c for c in self.time(assassino.time) if c is not assassino and c.vivo(self.t)]
            for c in vivos[:2]:
                c.ouro_total += ab["ouro_assistencia_total"] / 2
        self.registrar("abate")

    # --- renda contínua ---
    def renda(self):
        cfg = self.cfg
        o = cfg["ondas"]
        if self.t < o["primeira_chegada"]:
            return
        fase_rotas = self.t < 14 * 60
        for c in self.campeoes:
            if not c.vivo(self.t):
                continue
            c.ouro_total += cfg["ouro_passivo_por_segundo"] * PASSO
            # Minions fortalecidos do inimigo na base dão mais ouro a quem defende (chance de virada).
            c.ouro_total += AJUSTE["renda_super_minions"] * PASSO * len(self.rotas_abertas(c.time))
            if c.posicao == "selva":
                xp_s, ouro_s = taxa_selva(cfg, c.farm)
                fator = 1.0 if fase_rotas else 0.8
                c.xp += xp_s * PASSO * fator
                c.ouro_total += ouro_s * PASSO * fator
                continue
            # Depois da fase de rotas, o time se agrupa: farm cai para ~70%.
            presenca = 1.0 if fase_rotas else 0.7
            eficiencia = 0.45 + 0.5 * c.farm / 100.0
            oponente = self.oponente_de_rota(c)
            if oponente is not None and oponente.vivo(self.t):
                eficiencia *= 1 + 0.25 * math.tanh((c.micro - oponente.micro) / 25)
            else:
                eficiencia *= 1.1
            xp_seg = self.xp_onda / o["intervalo"]
            ouro_seg = self.ouro_onda / o["intervalo"]
            if c.posicao in ("atirador", "suporte"):
                xp_seg *= o["bonus_xp_rota_dupla"] / 2
                ouro_seg *= 0.9 if c.posicao == "atirador" else 0.1
                if c.posicao == "suporte":
                    eficiencia = 1.0
            c.xp += xp_seg * PASSO * presenca
            c.ouro_total += ouro_seg * PASSO * presenca * min(1.0, eficiencia)

    def oponente_de_rota(self, c):
        rota = ROTA_DE[c.posicao]
        if rota is None:
            return None
        for outro in self.time(1 - c.time):
            if outro.posicao == c.posicao:
                return outro
        return None

    # --- fase de rotas ---
    def trocas_de_rota(self):
        for c in self.time(0):
            if c.posicao == "selva" or c.posicao == "suporte":
                continue
            inimigo = self.oponente_de_rota(c)
            if not (c.vivo(self.t) and inimigo.vivo(self.t)):
                continue
            if self.rng.random() < PASSO / AJUSTE["troca_rota_a_cada"]:
                p_a = sig((self.poder(c) * (0.6 + c.micro / 250) - self.poder(inimigo) * (0.6 + inimigo.micro / 250)) * 6)
                if self.rng.random() < p_a:
                    self.matar(inimigo, c)
                else:
                    self.matar(c, inimigo)

    def ganks(self):
        for time in (0, 1):
            cacador = next(c for c in self.time(time) if c.posicao == "selva")
            if not cacador.vivo(self.t) or self.t < 150 or self.t > AJUSTE["ganks_ate_min"] * 60:
                continue
            # Macro alto: percebe mais oportunidades.
            if self.rng.random() > PASSO / (AJUSTE["gank_base"] - cacador.macro):
                continue
            alvos = [c for c in self.time(1 - time) if c.posicao not in ("selva",) and c.vivo(self.t)]
            if not alvos:
                continue
            alvo = self.rng.choice(alvos)
            aliado = next((c for c in self.time(time) if c.posicao == alvo.posicao), None)
            suporte_inimigo = next(c for c in self.time(1 - time) if c.posicao == "suporte")
            visao = (suporte_inimigo.macro - cacador.macro) / 100.0
            forca = self.poder(cacador) + (self.poder(aliado) if aliado and aliado.vivo(self.t) else 0)
            chance = sig(1.0 + (forca - self.poder(alvo) * 1.6) * 2.5 + (cacador.micro - alvo.micro) / 40 - visao * 2)
            if self.rng.random() < chance:
                self.matar(alvo, cacador if self.rng.random() < 0.4 else aliado)
            elif self.rng.random() < 0.35:
                self.matar(cacador, alvo)

    # --- estruturas ---
    def proxima_torre(self, defensor, rota):
        torres = self.e.torres[defensor][rota]
        for i, vida in enumerate(torres):
            if vida > 0:
                return i
        return None

    def pressao_torres(self):
        cfg = self.cfg
        if self.t < cfg["ondas"]["primeira_chegada"] + 30:
            return
        for atacante in (0, 1):
            defensor = 1 - atacante
            for rota in ROTAS:
                i = self.proxima_torre(defensor, rota)
                if i is None:
                    continue
                meus = [c for c in self.time(atacante) if ROTA_DE[c.posicao] == rota and c.vivo(self.t)]
                deles = [c for c in self.time(defensor) if ROTA_DE[c.posicao] == rota and c.vivo(self.t)]
                if self.t > 14 * 60:
                    meus, deles = meus[:1], deles[:1]  # rotas laterais com 1 jogador no meio de jogo
                vantagem = sum(self.poder(c) for c in meus) - sum(self.poder(c) for c in deles)
                dano = 0.10 + max(0.0, vantagem) * 0.9
                if not deles and meus:
                    dano += 1.0
                if self.t < cfg["torres"]["defesa_inicial_min"] * 60:
                    dano *= 0.4
                if self.t < self.e.bonus_cerbero[atacante]:
                    dano *= 2.0
                self.e.torres[defensor][rota][i] -= dano * PASSO * AJUSTE["dano_torre_rota"] * self.fragilidade()
                if self.e.torres[defensor][rota][i] <= 0:
                    self.e.torres[defensor][rota][i] = 0
                    for c in self.time(atacante):
                        c.ouro_total += cfg["torres"]["ouro_time"] / 5
                    if meus:
                        meus[0].ouro_total += cfg["torres"]["ouro_quem_destroi"]
                    self.registrar("torre")

    def rotas_abertas(self, defensor):
        return [r for r in ROTAS if self.proxima_torre(defensor, r) is None]

    # --- lutas em equipe ---
    def luta(self, motivo):
        vivos = [[c for c in self.time(n) if c.vivo(self.t)] for n in (0, 1)]
        if len(vivos[0]) < 2 or len(vivos[1]) < 2:
            return None
        self.e.lutas += 1
        forca = []
        for n in (0, 1):
            macro = statistics.mean(c.macro for c in self.time(n))
            atras = self.ouro_time(n) < self.ouro_time(1 - n) - 2000
            mental = statistics.mean(c.mental for c in self.time(n))
            f = sum(self.poder(c) for c in vivos[n]) * (1 + (macro - 50) / 400)
            if atras:
                f *= 0.94 + 0.06 * mental / 100   # Mental segura o time quando está atrás
            # Defender perto da base ajuda (Guardião e torres)
            if len(self.rotas_abertas(n)) > 0:
                f *= AJUSTE["defesa_base"]
            forca.append(f)
        p_a = sig(AJUSTE["luta_sensibilidade"] * math.log(forca[0] / forca[1]))
        vencedor = 0 if self.rng.random() < p_a else 1
        perdedor = 1 - vencedor
        margem = abs(p_a - 0.5) * 2
        mortes_perdedor = min(len(vivos[perdedor]), 1 + int(self.rng.random() * 2.0 + margem * 1.5))
        mortes_vencedor = min(len(vivos[vencedor]) - 1, int(self.rng.random() * 1.6 * (1 - margem)))
        for vitima in self.rng.sample(vivos[perdedor], mortes_perdedor):
            self.matar(vitima, self.rng.choice(vivos[vencedor]))
        for vitima in self.rng.sample(vivos[vencedor], mortes_vencedor):
            self.matar(vitima, self.rng.choice(vivos[perdedor]))
        self.registrar("luta")
        return vencedor

    def converter_vantagem(self, vencedor):
        """Depois de vencer uma luta, o time converte em objetivo/estruturas enquanto o outro renasce."""
        cfg = self.cfg
        perdedor = 1 - vencedor
        vivos_v = [c for c in self.time(vencedor) if c.vivo(self.t)]
        mortos_p = [c for c in self.time(perdedor) if not c.vivo(self.t)]
        if len(vivos_v) < 3 or len(mortos_p) < 2:
            return
        janela = sorted(c.morto_ate - self.t for c in mortos_p)[len(mortos_p) // 2]
        epic = cfg["monstros_epicos"]
        # 1) objetivo disponível
        if self.t >= self.e.hydra_disponivel_em:
            self.e.bonus_hydra[vencedor] = self.t + epic["hydra"]["duracao_bonus"]
            self.e.hydra_disponivel_em = self.t + epic["hydra"]["reaparece"]
            for c in self.time(vencedor):
                c.ouro_total += epic["hydra"]["ouro_time"] / 5
            self.registrar("hydra")
            janela -= 25
        elif self.t >= self.e.cerbero_disponivel_em:
            self.e.bonus_cerbero[vencedor] = self.t + epic["cerbero"]["duracao_bonus"]
            self.e.cerbero_disponivel_em = self.t + epic["cerbero"]["reaparece"]
            for c in self.time(vencedor):
                c.ouro_total += epic["cerbero"]["ouro_time"] / 5
            self.registrar("cerbero")
            janela -= 20
        # 2) estruturas, na ordem: torres -> Guardião -> Cristal
        poder_cerco = len(vivos_v) * (2.0 if self.t < self.e.bonus_cerbero[vencedor] else 1.0) * self.fragilidade()
        if self.t < self.e.bonus_hydra[vencedor]:
            poder_cerco *= 1.3
        while janela > 0:
            abertas = self.rotas_abertas(perdedor)
            if not abertas:
                rota = min(ROTAS, key=lambda r: sum(self.e.torres[perdedor][r]))
                i = self.proxima_torre(perdedor, rota)
                custo = self.e.torres[perdedor][rota][i] / (poder_cerco * AJUSTE["cerco_torre"])
                if custo > janela:
                    self.e.torres[perdedor][rota][i] -= janela * poder_cerco * AJUSTE["cerco_torre"]
                    break
                janela -= custo
                self.e.torres[perdedor][rota][i] = 0
                for c in self.time(vencedor):
                    c.ouro_total += cfg["torres"]["ouro_time"] / 5
                self.registrar("torre")
                continue
            if self.e.guardiao_vivo[perdedor]:
                custo = self.e.guardiao_vida[perdedor] / (poder_cerco * AJUSTE["cerco_guardiao"])
                if custo > janela:
                    self.e.guardiao_vida[perdedor] -= janela * poder_cerco * AJUSTE["cerco_guardiao"]
                    break
                janela -= custo
                self.e.guardiao_vivo[perdedor] = False
                self.e.guardiao_vida[perdedor] = 0
                self.e.guardiao_renasce[perdedor] = self.t + cfg["guardiao"]["renasce"]
                self.registrar("guardiao")
                continue
            custo = self.e.cristal[perdedor] / (poder_cerco * AJUSTE["cerco_cristal"])
            if custo > janela:
                self.e.cristal[perdedor] -= janela * poder_cerco * AJUSTE["cerco_cristal"]
                break
            self.e.cristal[perdedor] = 0
            self.vencedor = vencedor
            self.registrar("cristal")
            return

    def objetivo_sem_luta(self):
        """Um time pega o objetivo disponível sem disputa (melhor leitura de jogo e visão)."""
        epic = self.cfg["monstros_epicos"]
        leitura = [statistics.mean(c.macro for c in self.time(n)) + self.rng.gauss(0, 15) for n in (0, 1)]
        time = 0 if leitura[0] > leitura[1] else 1
        if self.t >= self.e.hydra_disponivel_em:
            self.e.bonus_hydra[time] = self.t + epic["hydra"]["duracao_bonus"]
            self.e.hydra_disponivel_em = self.t + epic["hydra"]["reaparece"]
            ouro, tipo = epic["hydra"]["ouro_time"], "hydra"
        elif self.t >= self.e.cerbero_disponivel_em:
            self.e.bonus_cerbero[time] = self.t + epic["cerbero"]["duracao_bonus"]
            self.e.cerbero_disponivel_em = self.t + epic["cerbero"]["reaparece"]
            ouro, tipo = epic["cerbero"]["ouro_time"], "cerbero"
        else:
            return
        for c in self.time(time):
            c.ouro_total += ouro / 5
        self.registrar(tipo)

    def guardioes_renascem(self):
        for n in (0, 1):
            if not self.e.guardiao_vivo[n] and self.t >= self.e.guardiao_renasce[n]:
                self.e.guardiao_vivo[n] = True
                self.e.guardiao_vida[n] = 100.0
                self.registrar("guardiao_renasce")
            # Cristal se recupera devagar quando ninguém ataca
            self.e.cristal[n] = min(100.0, self.e.cristal[n] + 0.02 * PASSO)

    # --- laço principal ---
    def jogar(self):
        limite = self.cfg["fim_de_jogo"]["limite_pratico_min"] * 60
        proxima_luta = 14 * 60 + self.rng.uniform(0, 90)
        while self.t < limite and self.vencedor is None:
            self.t += PASSO
            self.renda()
            self.guardioes_renascem()
            if self.t < 14 * 60:
                self.trocas_de_rota()
            self.ganks()
            self.pressao_torres()
            # Lutas: nos objetivos (a partir do Cérbero) e no meio/fim de jogo.
            objetivo_pronto = self.t >= self.e.cerbero_disponivel_em or self.t >= self.e.hydra_disponivel_em
            chance_objetivo = PASSO / AJUSTE["espera_luta_objetivo"] if objetivo_pronto else 0
            disputa = self.rng.random() < chance_objetivo
            if disputa and self.rng.random() > AJUSTE["chance_disputar_objetivo"]:
                self.objetivo_sem_luta()
            elif self.t >= proxima_luta or disputa:
                vencedor = self.luta("objetivo" if objetivo_pronto else "meio")
                if vencedor is not None:
                    self.converter_vantagem(vencedor)
                intervalo = AJUSTE["intervalo_luta_meio"] if self.t < 25 * 60 else AJUSTE["intervalo_luta_fim"]
                proxima_luta = self.t + self.rng.uniform(intervalo * 0.6, intervalo * 1.4)
            if int(self.t) % 30 == 0:
                self.historico_ouro.append((self.t, self.ouro_time(0) - self.ouro_time(1)))
        return self


# ---------------------------------------------------------------------------
# Métricas e relatório
# ---------------------------------------------------------------------------

def metricas(partidas):
    duracoes = [p.t / 60 for p in partidas]
    terminadas = [p for p in partidas if p.vencedor is not None]
    abates = [sum(c.abates for c in p.campeoes) + 0 for p in partidas]
    viradas, comebacks, atras_15 = [], 0, 0
    maiores_pausas = []
    pausas_meio = []
    for p in partidas:
        # viradas de liderança no ouro depois dos 8 min (com folga de 1.000)
        lider, trocas = 0, 0
        for t, dif in p.historico_ouro:
            if t < 8 * 60:
                continue
            atual = 1 if dif > 1000 else (-1 if dif < -1000 else 0)
            if atual != 0 and lider != 0 and atual != lider:
                trocas += 1
            if atual != 0:
                lider = atual
        viradas.append(trocas)
        dif15 = next((d for t, d in p.historico_ouro if t >= 15 * 60), 0)
        if abs(dif15) >= 2500 and p.vencedor is not None:
            atras_15 += 1
            time_atras = 1 if dif15 > 0 else 0
            if p.vencedor == time_atras:
                comebacks += 1
        momentos = [t for t, tipo in p.e.eventos if tipo in ("abate", "torre", "hydra", "cerbero", "guardiao", "cristal")]
        momentos = [0.0] + sorted(momentos) + [p.t]
        maiores_pausas.append(max(b - a for a, b in zip(momentos, momentos[1:])) / 60)
        depois_10 = [t for t in momentos if t >= 600]
        depois_10 = [600.0] + depois_10 if depois_10 else [600.0, p.t]
        pausas_meio.append(max(b - a for a, b in zip(depois_10, depois_10[1:])) / 60)
    return {
        "duracao_mediana": statistics.median(duracoes),
        "duracao_p10": sorted(duracoes)[len(duracoes) // 10],
        "duracao_p90": sorted(duracoes)[len(duracoes) * 9 // 10],
        "pct_menos_22": 100 * sum(d < 22 for d in duracoes) / len(duracoes),
        "pct_mais_40": 100 * sum(d > 40 for d in duracoes) / len(duracoes),
        "pct_sem_fim": 100 * (len(partidas) - len(terminadas)) / len(partidas),
        "abates_medios": statistics.mean(abates),
        "viradas_medias": statistics.mean(viradas),
        "pct_virada_15": 100 * comebacks / atras_15 if atras_15 else 0.0,
        "maior_pausa_mediana": statistics.median(maiores_pausas),
        "maior_pausa_depois_10_mediana": statistics.median(pausas_meio),
        "lutas_medias": statistics.mean(p.e.lutas for p in partidas),
    }


def vitoria_do_mais_forte(cfg, diferenca, n, rng, tensao):
    vitorias = 0
    for _ in range(n):
        p = Partida(cfg, 50 + diferenca / 2, 50 - diferenca / 2, rng, tensao).jogar()
        if p.vencedor == 0:
            vitorias += 1
        elif p.vencedor is None and p.ouro_time(0) > p.ouro_time(1):
            vitorias += 0.5
    return 100 * vitorias / n


def tempos_de_itens(cfg, partidas):
    it = cfg["itens"]
    precos = [it["preco_bota"]] + [it["preco_item_medio"]] * (it["maximo_por_campeao"] - 1)
    marcos = [sum(precos[:i + 1]) + 500 for i in range(len(precos))]
    # aproximação: ouro do atirador ao longo do tempo (taxa média da partida)
    tempos = {i: [] for i in range(len(marcos))}
    for p in partidas:
        atirador = next(c for c in p.campeoes if c.time == 0 and c.posicao == "atirador")
        taxa = atirador.ouro_total / max(p.t, 1)
        for i, marco in enumerate(marcos):
            tempos[i].append(marco / taxa / 60)
    return [statistics.median(v) for v in tempos.values()]


def formatar_tempo(segundos):
    return "%d:%02d" % (int(segundos // 60), int(segundos % 60))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--partidas", type=int, default=2000)
    parser.add_argument("--semente", type=int, default=2026)
    parser.add_argument("--nivel-maximo", type=int)
    parser.add_argument("--sem-tensao-final", action="store_true")
    parser.add_argument("--json", action="store_true", help="imprime só as métricas em JSON")
    args = parser.parse_args()

    cfg = carregar_config()
    if args.nivel_maximo:
        cfg["niveis"]["maximo"] = args.nivel_maximo
    rng = random.Random(args.semente)
    tensao = not args.sem_tensao_final

    partidas = [Partida(cfg, 50, 50, rng, tensao).jogar() for _ in range(args.partidas)]
    m = metricas(partidas)
    forte = {d: vitoria_do_mais_forte(cfg, d, max(300, args.partidas // 4), rng, tensao) for d in (5, 10, 20)}
    if args.json:
        m["vitoria_mais_forte"] = forte
        print(json.dumps(m, ensure_ascii=False, indent=2))
        return

    prog = progressao_teorica(cfg)
    epic = cfg["monstros_epicos"]
    print("=== Crystal Legends — ritmo da partida (%d partidas, nível máximo %d, tensão final %s) ===\n"
          % (args.partidas, cfg["niveis"]["maximo"], "ligada" if tensao else "desligada"))
    print("Progressão com farm perfeito:")
    for nivel in (2, 5, 6, 9, 11, 13, cfg["niveis"]["maximo"]):
        if nivel in prog["solo"]:
            print("  nível %2d: rota solo %s | rota dupla %s | selva %s" % (
                nivel, formatar_tempo(prog["solo"][nivel]), formatar_tempo(prog["dupla"][nivel]), formatar_tempo(prog["selva"][nivel])))
    print("  Cérbero aparece em %s (nível %d teórico); Hydra em %s (nível %d teórico)" % (
        formatar_tempo(prog["solo"][epic["cerbero"]["aparece_no_nivel_teorico"]]), epic["cerbero"]["aparece_no_nivel_teorico"],
        formatar_tempo(prog["solo"][epic["hydra"]["aparece_no_nivel_teorico"]]), epic["hydra"]["aparece_no_nivel_teorico"]))
    print("\nRenascimento: " + ", ".join("nível %d: %.0fs" % (n, renascimento(cfg, n, 10)) for n in (1, 6, 11, cfg["niveis"]["maximo"]))
          + " | nível máx. aos 35 min: %.0fs" % renascimento(cfg, cfg["niveis"]["maximo"], 35))
    itens = tempos_de_itens(cfg, partidas)
    print("Itens do atirador (mediana): bota %.0f min, item 2 %.0f, item 3 %.0f, item 4 %.0f, item 5 %.0f" % tuple(itens))
    print("\nPartidas entre times iguais:")
    print("  duração: mediana %.1f min (10%% abaixo de %.1f, 10%% acima de %.1f)" % (m["duracao_mediana"], m["duracao_p10"], m["duracao_p90"]))
    print("  terminam antes de 22 min: %.1f%% | passam de 40 min: %.1f%% | chegam a %d min sem fim: %.1f%%" % (
        m["pct_menos_22"], m["pct_mais_40"], cfg["fim_de_jogo"]["limite_pratico_min"], m["pct_sem_fim"]))
    print("  abates por partida: %.1f | lutas em equipe: %.1f" % (m["abates_medios"], m["lutas_medias"]))
    print("  viradas na liderança de ouro (após 8 min): %.2f por partida" % m["viradas_medias"])
    print("  time atrás 2.500+ de ouro aos 15 min vence: %.1f%%" % m["pct_virada_15"])
    print("  maior intervalo sem acontecimentos (mediana): %.1f min no jogo todo, %.1f min depois dos 10 min" % (m["maior_pausa_mediana"], m["maior_pausa_depois_10_mediana"]))
    print("\nChance do time mais forte vencer:")
    for d, v in forte.items():
        print("  %2d pontos de diferença na qualidade: %.0f%%" % (d, v))


if __name__ == "__main__":
    main()
