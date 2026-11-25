#!/usr/bin/env python3
"""
Converte a proposta de campeões (docs/propostas/campeoes.md) em data/campeoes/campeoes.json.

Uso: python3 tools/conversao/converter_campeoes.py

O que faz:
1. Lê as fichas JSON da proposta. Os textos públicos (nome, título, tema, descrições, efeitos) não mudam.
2. Acrescenta a cada habilidade e passiva um bloco "mecanica", com os números que a simulação usa.
   - Habilidades: extraídos dos textos de efeito por expressões regulares, com correções manuais onde o texto é
     particular (curas, escudos com PM, condições).
   - Passivas: escritas à mão a partir do texto (gatilho, recarga, valores).
3. Aplica os AJUSTES de calibração (laboratório de campeões) e registra cada um no campo "ajustes".

A proposta é a fonte dos textos. Depois desta conversão, o data/campeoes/campeoes.json passa a ser a referência:
mudanças de equilíbrio entram no AJUSTES abaixo e o arquivo é gerado de novo.
"""
import copy
import json
import math
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PROPOSTA = os.path.join(RAIZ, "docs", "propostas", "campeoes.md")
SAIDA = os.path.join(RAIZ, "data", "campeoes", "campeoes.json")
ITENS = json.load(open(os.path.join(RAIZ, "data", "itens", "itens.json"), encoding="utf-8"))
ID_ITEM = {i["nome"]: i["id"] for i in ITENS["itens"] + ITENS["botas"]}


def numero(texto):
    return float(texto.replace(",", "."))


# ---------------------------------------------------------------------------
# Habilidades: leitura dos textos de efeito
# ---------------------------------------------------------------------------

def ler_habilidade(h):
    texto = " | ".join(h["efeitos"])
    m = {}
    if re.search(r"[Aa]lcance global", texto):
        m["alcance"] = 99999
        m["global"] = True
    else:
        r = re.search(r"[Aa]lcance (?:fixo )?(\d+)|a até (\d+)", texto)
        if r:
            m["alcance"] = int(r.group(1) or r.group(2))
    r = re.search(r"[Rr]aio (\d+)", texto)
    if r:
        m["raio"] = int(r.group(1))
    r = re.search(r"largura (\d+)", texto)
    if r and h["alvo"] in ("linha", "area"):
        m["largura"] = int(r.group(1))
    r = re.search(r"abertura (\d+)°", texto)
    if r:
        m["abertura"] = int(r.group(1))
    r = re.search(r"retângulo (\d+) × (\d+)", texto)
    if r:
        m["raio"] = int(r.group(2))
    r = re.search(r"[Ll]entidão de (\d+)% por ([\d,]+) s", texto)
    if r:
        m["lentidao"] = {"forca": int(r.group(1)) / 100, "duracao": numero(r.group(2))}
    r = re.search(r"Atordoa(?:mento em área de| inimigos por| por) ([\d,]+) s", texto)
    if r:
        m["atordoamento"] = numero(r.group(1))
    r = re.search(r"(?:Avanço|Salto|avançar) (?:de )?até (\d+)", texto)
    if r:
        m["avanco"] = int(r.group(1))
    r = re.search(r"[Aa]viso de ([\d,]+) s", texto)
    if r:
        m["aviso"] = numero(r.group(1))
    r = re.search(r"[Pp]reparação(?: fixa)?(?: de)? ([\d,]+) s", texto)
    if r:
        m["preparacao"] = numero(r.group(1))
    r = re.search(r"(\d+)% físico e (\d+)% mágico", texto)
    if r:
        m["divisao_mista"] = {"fisico": int(r.group(1)) / 100, "magico": int(r.group(2)) / 100}
    r = re.search(r"(?:Os demais recebem|Os demais|aos posteriores|recebe dano integral\. Os demais recebem) ?(\d+)%", texto)
    if not r:
        r = re.search(r"(\d+)% aos posteriores", texto)
    if r:
        m["dano_secundario"] = int(r.group(1)) / 100
    if re.search(r"[Ss]ó (?:atinge|acerta|marca|o primeiro|causa dano ao campeão marcado)|[Pp]ara no primeiro|[Aa]tinge (?:só |apenas )?o primeiro|[Pp]rimeiro campeão na linha|no primeiro campeão|Só o primeiro campeão", texto):
        m.setdefault("primeiro_alvo", True)
    if "dano_secundario" in m:
        m.pop("primeiro_alvo", None)
    # Quantos inimigos a habilidade pode atingir.
    if h["alvo"] in ("si_mesmo", "aliado"):
        m["alvos"] = "nenhum" if all(v == 0 for v in h["dano"]["base"]) else "proprio_alcance"
    elif h["alvo"] == "unico" or m.get("primeiro_alvo"):
        m["alvos"] = "um"
    else:
        m["alvos"] = "area"
    # Habilidade com projétil ou aviso pode ser esquivada (o Micro decide quanto).
    m["esquivavel"] = h["alvo"] in ("linha", "area", "cone") and ("aviso" in m or h["alvo"] == "linha")
    if h.get("especial") or h["posicao"] == 3:
        m["nivel_minimo"] = 6
    return m


# Correções e acréscimos manuais por habilidade: (id do campeão, posição) -> dicionário mesclado.
# Usado onde o texto descreve curas, escudos, condições ou efeitos que as expressões não leem.
MANUAL_HABILIDADES = {
    ("orvante", 2): {"reduz_deslocamento": {"pct": 0.25, "duracao": 1.6}},
    ("brumeria", 2): {"escudo": {"alvo": "si", "pct_vida": 0.04, "duracao": 3}},
    ("brumeria", 3): {"alvos": "area", "centro": "si"},
    ("dorsalio", 2): {"escudo": {"alvo": "si", "pct_vida": 0.02, "duracao": 2}},
    ("calzugo", 1): {"furia_cheia": {"lentidao_duracao_extra": 0.4}},
    ("calzugo", 2): {"escudo": {"alvo": "si", "pct_vida": 0.03, "duracao": 2}, "furia_cheia": {"escudo_pct_vida": 0.04}},
    ("calzugo", 3): {"furia_cheia": {"atordoamento": 0.85}},
    ("orvante", 3): {},
    ("vedrassa", 2): {"escudo": {"alvo": "aliado", "pct_vida": 0.03, "duracao": 2.5}},
    ("vedrassa", 3): {"alvo_centro": "aliado"},
    ("tessari", 1): {"marca": {"duracao": 4}, "primeiro_alvo": True, "alvos": "um"},
    ("tessari", 3): {"vida_perdida_exige_marca": True},
    ("iscavro", 3): {"vida_perdida_exige_furia_cheia": True},
    ("mirfuso", 2): {"primeiro_alvo": True, "alvos": "um"},
    ("kordume", 1): {"vida_propria_sem_furia": 0.006},
    ("kordume", 2): {"escudo": {"alvo": "si", "pct_vida": 0.025, "duracao": 2}},
    ("kordume", 3): {"furia_cheia": {"preparacao": 0.25}, "preparacao": 0.4},
    ("marulva", 1): {"custo_vida": 0.025},
    ("marulva", 2): {"custo_vida": 0.02, "proximo_ataque": {"janela": 3, "roubo_do_extra": 0.10}, "alvos": "um"},
    ("marulva", 3): {"custo_vida": 0.04},
    ("eirafim", 1): {"alvos": "area"},
    ("eirafim", 2): {"proximo_ataque": {"janela": 3, "roubo_do_extra": 0.08}, "alvos": "um"},
    ("veluria", 1): {"primeiro_alvo": True, "alvos": "um"},
    ("cintarro", 2): {"escudo": {"alvo": "si", "pct_vida": 0.03, "duracao": 2}},
    ("perlivia", 1): {"custo_vida": 0.025},
    ("perlivia", 2): {"custo_vida": 0.02},
    ("perlivia", 3): {"custo_vida": 0.04},
    ("fulgaveu", 3): {"alvos": "nenhum", "visao": {"raio": 240, "duracao": 2.5}},
    ("suteria", 2): {"cura": {"alvo": "aliado", "pct_vida": 0.035, "pm": 0.12, "teto_pct": 0.06}},
    ("suteria", 3): {"cura": {"alvo": "aliado", "pct_vida": 0.06, "pm": 0.15, "teto_pct": 0.09, "pulsos": 2, "intervalo": 1.1}},
    ("alvenora", 2): {"escudo": {"alvo": "aliado", "pct_vida": 0.035, "pm": 0.18, "teto_pct": 0.07, "duracao": 2.5}},
    ("alvenora", 3): {"escudo": {"alvo": "aliado", "pct_vida": 0.07, "pm": 0.16, "teto_pct": 0.09, "duracao": 2.5}},
    ("luminela", 2): {"escudo": {"alvo": "aliado", "pct_vida": 0.035, "pm": 0.13, "teto_pct": 0.06, "duracao": 2}},
    ("luminela", 3): {"cura": {"alvo": "aliado", "pct_vida": 0.045, "pm": 0.12, "teto_pct": 0.06}, "preparacao": 0.7},
    ("clavento", 3): {"raio": 92},
    ("ocravia", 2): {"escudo": {"alvo": "aliado", "pct_vida": 0.04, "pm": 0.17, "teto_pct": 0.07, "duracao": 2.4}},
    ("ocravia", 3): {"alvos": "nenhum", "zona": {"duracao": 3}, "visao": {"raio": 225, "duracao": 3}},
    ("terralume", 2): {"reduz_lentidao": {"pct": 0.2, "duracao": 2}},
    ("riscavela", 3): {"exige_ataque_recente": 3},
    ("fulcrim", 3): {"velocidade_movimento": {"pct": 0.04, "duracao": 1.2}},
    ("trevalio", 1): {"marca": {"duracao": 4}},
    ("trevalio", 2): {"exige_marca": True, "consome_marca": True},
    ("zarcavil", 1): {"vida_maxima_alvo_uma_vez": True},
}


# ---------------------------------------------------------------------------
# Passivas: mecânica escrita à mão a partir do texto da ficha
# ---------------------------------------------------------------------------
# Tipos executados pela simulação:
#   dano_extra      dano adicional quando o gatilho acontece
#   escudo_proprio  escudo em si quando o gatilho acontece
#   cura_propria    cura em si quando o gatilho acontece
#   escudo_aliado   escudo num aliado quando o gatilho acontece
#   cura_aliado     cura num aliado quando o gatilho acontece
#   velocidade_ataque, reducao_dano, furia (barra própria com efeitos de barra cheia)
# Gatilhos e campos: veja como cada um é executado em tools/prototipos/laboratorio_campeoes.py (ao_acertar_habilidade,
# ao_atacar, antes_de_receber, depois_de_receber) e a tabela de passivas em tools/relatorios/laboratorio_campeoes.md.

MANUAL_PASSIVAS = {
    "orvante": {"tipo": "escudo_proprio", "gatilho": "receber_dano_parado", "parado": 0.7, "pct_vida": 0.08, "duracao": 2, "recarga": 18},
    "brumeria": {"tipo": "escudo_aliado", "gatilho": "especial_com_acumulos", "acumulo": {"fonte": "escudo_absorve", "minimo_absorvido": 45, "intervalo": 35, "teto": 5},
                 "acumulos_minimos": 3, "pct_vida": 0.04, "pct_por_acumulo_extra": 0.005, "teto_pct": 0.05, "duracao": 2, "alvo": "menor_vida_pct"},
    "dorsalio": {"tipo": "cura_propria", "gatilho": "duas_habilidades_mesmo_alvo", "janela": 10, "pct_vida": 0.05, "duracao": 3, "recarga": 16},
    "calzugo": {"tipo": "furia", "ganho_ataque": 12, "ganho_recebido": 8, "perda_fora_combate": 10, "fora_combate": 4,
                "barra_cheia": {"reducao_dano": 0.09, "duracao": 1.6, "recarga": 16, "exige_acerto": True}},
    "vedrassa": {"tipo": "escudo_aliado", "gatilho": "aliado_vida_baixa", "limite": 0.4, "raio": 360, "pct_vida": 0.06, "duracao": 2, "recarga": 20},
    "ravineo": {"tipo": "dano_extra", "gatilho": "isolado", "habilidade": 1, "distancia": 425, "recarga": 12,
                "dano": {"tipo": "fisico", "base": [25.09, 1.18], "dano_fisico_bonus": 0.20244}},
    "tessari": {"tipo": "dano_extra", "gatilho": "combo", "sequencia": [1, 2], "janela": 4, "recarga": 12,
                "dano": {"tipo": "fisico", "base": [7.05, 3.27], "dano_fisico_bonus": 0.13677}},
    "nalcora": {"tipo": "dano_extra", "gatilho": "abertura", "habilidade": 1, "fora_combate": 3, "recarga": 13,
                "dano": {"tipo": "magico", "base": [20.93, 1.91], "dano_fisico_bonus": 0.20286}},
    "iscavro": {"tipo": "furia", "ganho_ataque": 13, "ganho_recebido": 7, "perda_fora_combate": 10, "fora_combate": 4,
                "barra_cheia": {"cura_pct_vida": 0.04, "duracao": 2, "recarga": 17}},
    "mirfuso": {"tipo": "dano_extra", "gatilho": "isolado_marca_ataque", "habilidade": 1, "distancia": 440, "janela": 3, "recarga": 13,
                "dano": {"tipo": "fisico", "base": [15.46, 3.08], "dano_fisico_bonus": 0.20336}},
    "kordume": {"tipo": "furia", "ganho_ataque": 15, "ganho_recebido": 7, "perda_fora_combate": 10, "fora_combate": 4,
                "barra_cheia": {"escudo_pct_vida": 0.06, "duracao": 2, "recarga": 18}},
    "marulva": {"tipo": "cura_propria", "gatilho": "custo_vida_e_ataques", "ataques": 2, "janela": 4, "pct_vida": 0.06, "duracao": 2, "recarga": 13},
    "trisquilo": {"tipo": "dano_extra", "gatilho": "combo", "sequencia": [1, 2], "janela": 2.2, "recarga": 12, "devolve_recurso": 12,
                  "dano": {"tipo": "magico", "base": [10.62, 2.09], "dano_fisico_bonus": 0.10241, "poder_magico": 0.05243}},
    "vardilha": {"tipo": "escudo_proprio", "gatilho": "perto_de_objetivo", "pct_vida": 0.06, "duracao": 2, "recarga": 40},
    "eirafim": {"tipo": "cura_propria", "gatilho": "ataques_com_acumulo", "ataques": 3, "janela": 5, "pct_vida": 0.02, "pct_por_acumulo": 0.0065,
                "teto_pct": 0.0525, "recarga": 13, "acumulo": {"fonte": "sobreviver_combate", "duracao_minima": 6, "intervalo": 45, "teto": 5}},
    "veluria": {"tipo": "dano_extra", "gatilho": "acumulo_de_acertos", "habilidade": 1, "acertos_por_ficha": 2, "fichas": 3, "intervalo_ficha": 12, "recarga": 16,
                "dano": {"tipo": "magico", "base": [9.28, 3.37], "poder_magico": 0.176}},
    "cintarro": {"tipo": "dano_extra", "gatilho": "zona_apos_habilidade", "habilidade": 1, "permanencia": 0.8, "recarga": 15,
                 "dano": {"tipo": "magico", "base": [26.32, 1.67], "poder_magico": 0.0845}},
    "perlivia": {"tipo": "cura_propria", "gatilho": "duas_habilidades_mesmo_alvo", "janela": 4, "pct_vida": 0.06, "duracao": 2, "recarga": 14},
    "prismora": {"tipo": "dano_extra", "gatilho": "combo", "sequencia": [1, 2], "janela": 3, "recarga": 13,
                 "dano": {"tipo": "magico", "base": [4.8, 3.54], "poder_magico": 0.0764}},
    "fulgaveu": {"tipo": "escudo_aliado", "gatilho": "especial_revela", "aliados": 2, "pct_vida": 0.05, "duracao": 2, "recarga": 0},
    "suteria": {"tipo": "cura_aliado", "gatilho": "curativo_preparado", "limite": 0.4, "pct_vida": 0.045, "janela": 2, "recarga": 18},
    "alvenora": {"tipo": "escudo_aliado", "gatilho": "escudo_secundario", "acumulo": {"fonte": "escudo_absorve", "minimo_absorvido": 45, "intervalo": 40, "teto": 5},
                 "acumulos_minimos": 3, "pct_vida": 0.025, "pct_por_acumulo_extra": 0.0075, "teto_pct": 0.04, "duracao": 2, "raio": 250, "recarga": 18},
    "luminela": {"tipo": "escudo_aliado", "gatilho": "especial_cura_vida_baixa", "limite": 0.4, "pct_vida": 0.04, "duracao": 2},
    "clavento": {"tipo": "escudo_aliado", "gatilho": "ao_controlar", "habilidades": [1, 3], "raio": 280, "pct_vida": 0.05, "duracao": 1.8, "recarga": 16},
    "ocravia": {"tipo": "escudo_aliado", "gatilho": "reforco_na_zona", "habilidade": 2, "pct_extra": 0.03, "teto_pct": 0.09, "recarga": 17},
    "terralume": {"tipo": "dano_extra", "gatilho": "parado_marca_ataque", "habilidade": 1, "parado": 1.1, "janela": 2.2, "recarga": 12, "bonus_por_critico": 0.12,
                  "dano": {"tipo": "fisico", "base": [4.62, 1.93], "dano_fisico_bonus": 0.17052}},
    "zarcavil": {"tipo": "velocidade_ataque", "gatilho": "ataques_mesmo_alvo", "ataques": 3, "janela": 3, "pct": 0.14, "duracao": 2, "recarga": 10},
    "riscavela": {"tipo": "dano_extra", "gatilho": "ataques_com_acumulo", "ataques": 3, "janela": 4, "acumulos_minimos": 2, "recarga": 13,
                  "bonus_por_acumulo": {"3": 0.10, "4": 0.20, "5": 0.30},
                  "acumulo": {"fonte": "sequencia_de_ataques", "intervalo": 35, "teto": 5},
                  "dano": {"tipo": "magico", "base": [2.65, 2.06], "dano_fisico_bonus": 0.08957, "poder_magico": 0.06678}},
    "fulcrim": {"tipo": "dano_extra", "gatilho": "ataques_com_habilidade_em_recarga", "ataques": 2, "janela": 2.5, "recarga": 11,
                "dano": {"tipo": "fisico", "base": [6.56, 1.08], "dano_fisico_bonus": 0.05104}},
    "trevalio": {"tipo": "escudo_proprio", "gatilho": "combo", "sequencia": [1, 2], "janela": 4, "pct_vida": 0.06, "duracao": 1.7, "recarga": 15},
}


# ---------------------------------------------------------------------------
# Ajustes de calibração (laboratório de campeões). Cada entrada vira registro no campo "ajustes" da ficha.
# Formato: id -> lista de (caminho, novo valor, motivo). Caminho com pontos, ex.: "habilidades.1.dano.base".
# ---------------------------------------------------------------------------

AJUSTES = {
    "cintarro": [
        ("habilidades.1.dano.base", [92.0, 3.6], "Forte no início: no nível 3 estava abaixo dos magos constantes porque a Porta refratária não causa dano."),
    ],
}

# Ajustes multiplicativos gerados pelo laboratório: id -> {"inicio": fator, "fim": fator}.
# "inicio" multiplica a base (nível 1) do dano das habilidades e da passiva; "fim" multiplica o ganho por nível
# e as proporções. Lidos de tools/conversao/ajustes_laboratorio.json, se existir.
ORCAMENTOS = {}
CAMINHO_AJUSTES_LAB = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ajustes_laboratorio.json")


# ---------------------------------------------------------------------------
# Correção de orçamento (24/11)
# ---------------------------------------------------------------------------
# A seção 3.2 do guia mandava a rotação completa (as 3 habilidades) ficar perto do "combo" da classe. Só que o
# laboratório de itens disparava esse combo a cada ~7 s, e a especial tem recarga de 60 a 110 s. Resultado: no uso
# contínuo, as duas básicas entregavam cerca de metade do dano previsto e magos e assassinos ficavam muito fracos
# diante dos ataques básicos dos atiradores. A correção escala as duas habilidades básicas e o dano da passiva para
# que, a cada 7 s, entreguem o orçamento do campeão (tabela da proposta) × o combo da classe. A especial não muda:
# vira o pico de dano das lutas, como deve ser.

COMBATE = json.load(open(os.path.join(RAIZ, "data", "config", "combate.json"), encoding="utf-8"))
TODOS_ITENS = {i["id"]: i for i in ITENS["itens"] + ITENS["botas"]}


def bonus_da_build(c, n_itens):
    e = {"dano_fisico": 0.0, "poder_magico": 0.0, "vida": 0.0, "aceleracao": 0.0}
    for item_id in c["build_ids"][: 1 + n_itens]:
        for k in e:
            e[k] += TODOS_ITENS[item_id]["estatisticas"].get(k, 0)
    return e


# Alvos de referência para as parcelas por vida do alvo (mesmos da conferência da proposta):
# vida máxima de um lutador de referência; vida perdida de um atirador com 60% de vida perdida.
ALVO_VIDA = {9: 640 + 105 * 8 + 650, 15: 640 + 105 * 14 + 1300}
ALVO_PERDIDA = {9: (560 + 95 * 8 + 300) * 0.6, 15: (560 + 95 * 14 + 400) * 0.6}


def dano_habilidade(d, nivel, e, vida_total):
    p = d.get("proporcoes", d)
    v = d["base"][0] + d["base"][1] * (nivel - 1)
    v += p.get("dano_fisico_bonus", 0) * e["dano_fisico"] + p.get("poder_magico", 0) * e["poder_magico"]
    v += p.get("vida_maxima_propria_pct", 0) * vida_total
    v += p.get("vida_maxima_alvo_pct", 0) * ALVO_VIDA[nivel] + p.get("vida_perdida_alvo_pct", 0) * ALVO_PERDIDA[nivel]
    return v


def combo_da_classe(classe, nivel, e):
    h = COMBATE["classes"][classe]["habilidades"]
    v = h["base"][0] + h["base"][1] * (nivel - 1)
    v += h.get("proporcao_df_bonus", 0) * e["dano_fisico"] + h.get("proporcao_pm", 0) * e["poder_magico"] + h.get("proporcao_vida_bonus", 0) * e["vida"]
    return v * 7 / h["recarga"]


def dano_continuo(c, nivel, e):
    """Dano bruto a cada 7 s das duas básicas e da passiva (um disparo por recarga da passiva)."""
    vida_total = c["atributos"]["vida"][0] + c["atributos"]["vida"][1] * (nivel - 1) + e["vida"]
    total = 0.0
    for h in c["habilidades"]:
        if h["posicao"] in (1, 2) and h["recarga"]:
            total += dano_habilidade(h["dano"], nivel, e, vida_total) * 7 / h["recarga"]
    pm = c["passiva"]["mecanica"]
    if pm.get("dano"):
        total += dano_habilidade(pm["dano"], nivel, e, vida_total) * min(1.0, 7 / max(pm.get("recarga", 12), 7))
    return total


def correcao_de_orcamento(c, orcamento):
    fatores = []
    for nivel, n_itens in ((9, 2), (15, 4)):
        e = bonus_da_build(c, n_itens)
        atual = dano_continuo(c, nivel, e)
        if atual > 0:
            fatores.append(orcamento * combo_da_classe(c["classe"], nivel, e) / atual)
    if not fatores:
        return 1.0
    return math.sqrt(fatores[0] * fatores[-1])


def escalar_basicas(c, fator):
    for h in c["habilidades"]:
        if h["posicao"] in (1, 2):
            d = h["dano"]
            d["base"] = [arred(d["base"][0] * fator, 2), arred(d["base"][1] * fator, 3)]
            for k, v in d["proporcoes"].items():
                if v and k in ("dano_fisico_bonus", "poder_magico", "vida_maxima_propria_pct"):
                    d["proporcoes"][k] = arred(v * fator, 5)
    pd = c["passiva"]["mecanica"].get("dano")
    if pd:
        pd["base"] = [arred(pd["base"][0] * fator, 2), arred(pd["base"][1] * fator, 3)]
        for k in ("dano_fisico_bonus", "poder_magico"):
            if pd.get(k):
                pd[k] = arred(pd[k] * fator, 5)


# ---------------------------------------------------------------------------
# Correção por classe (laboratório de campeões, 24/11)
# ---------------------------------------------------------------------------
# Depois da correção de orçamento, a luta 5x5 ainda mostrava diferenças por classe que nenhum campeão sozinho explica:
# - mago: o poder mágico dos itens é baixo (300 com 4 itens), então as proporções precisam ser maiores para o dano
#   acompanhar o fim de jogo. Sem isso, os magos venciam 52% no início e só 36% no fim;
# - atirador: o dano dos ataques cresce multiplicado (dano × crítico × velocidade) e passava de 62% no fim;
# - assassino: fraco no início (39%), antes de ter itens;
# - suporte: escudos e curas pequenos demais para mudar lutas; tanque: forte cedo e fraco no fim.
# "base" multiplica o valor de nível 1 do dano das 3 habilidades e da passiva; "cresce" multiplica o ganho por nível
# e as proporções. "dano_fisico_cresce" e "velocidade_ataque_cresce" multiplicam o ganho por nível desses atributos.
CORRECAO_CLASSE = {
    "mago": {"base": 0.55, "cresce": 3.1},
    "atirador": {"base": 1.6, "dano_fisico_base": 1.15, "dano_fisico_cresce": 0.75, "velocidade_ataque_cresce": 0.65},
    "assassino": {"base": 2.1, "cresce": 1.25},
    "lutador": {"base": 1.0, "cresce": 0.9},
    "suporte": {"base": 1.5, "cresce": 1.2, "protecao": 1.3},
    "tanque": {"base": 0.85, "cresce": 1.25},
}
# Os valores acima vieram de duas rodadas do laboratório: a primeira com só a correção de orçamento, a segunda
# recentrando cada classe pela média dos ajustes individuais (para que os ajustes por campeão fiquem perto de 1).


def corrigir_classe(c):
    k = CORRECAO_CLASSE.get(c["classe"])
    if not k:
        return
    base, cresce = k.get("base", 1.0), k.get("cresce", 1.0)
    if base != 1.0 or cresce != 1.0:
        for h in c["habilidades"]:
            d = h["dano"]
            d["base"] = [arred(d["base"][0] * base, 2), arred(d["base"][1] * cresce, 3)]
            for chave in ("dano_fisico_bonus", "poder_magico"):
                if d["proporcoes"].get(chave):
                    d["proporcoes"][chave] = arred(d["proporcoes"][chave] * cresce, 5)
        pd = c["passiva"]["mecanica"].get("dano")
        if pd:
            pd["base"] = [arred(pd["base"][0] * base, 2), arred(pd["base"][1] * cresce, 3)]
            for chave in ("dano_fisico_bonus", "poder_magico"):
                if pd.get(chave):
                    pd[chave] = arred(pd[chave] * cresce, 5)
    a = c["atributos"]
    if "dano_fisico_cresce" in k:
        a["dano_fisico"] = [a["dano_fisico"][0], arred(a["dano_fisico"][1] * k["dano_fisico_cresce"], 3)]
    if "dano_fisico_base" in k:
        a["dano_fisico"] = [arred(a["dano_fisico"][0] * k["dano_fisico_base"], 2), a["dano_fisico"][1]]
    if "protecao" in k:
        for h in c["habilidades"]:
            for chave in ("escudo", "cura"):
                if chave in h["mecanica"]:
                    d = h["mecanica"][chave]
                    d["pct_vida"] = arred(d["pct_vida"] * k["protecao"], 4)
                    if "teto_pct" in d:
                        d["teto_pct"] = arred(d["teto_pct"] * k["protecao"], 4)
                    if d.get("pm"):
                        d["pm"] = arred(d["pm"] * k["protecao"], 4)
    if "velocidade_ataque_cresce" in k:
        a["velocidade_ataque"] = [a["velocidade_ataque"][0], arred(a["velocidade_ataque"][1] * k["velocidade_ataque_cresce"], 3)]
    c["ajustes"].append({"campo": "correção da classe %s" % c["classe"], "valores": k,
                         "motivo": "Equilíbrio entre classes medido no laboratório de campeões (ver tools/relatorios/laboratorio_campeoes.md)."})


def definir(ficha, caminho, valor):
    partes = caminho.split(".")
    alvo = ficha
    if partes[0] == "habilidades":
        # "habilidades.N" aponta para a habilidade de posição N (1 a 3), não para o índice da lista.
        alvo = next(h for h in ficha["habilidades"] if h["posicao"] == int(partes[1]))
        partes = partes[2:]
    for parte in partes[:-1]:
        alvo = alvo[int(parte)] if isinstance(alvo, list) else alvo[parte]
    antigo = alvo[partes[-1]]
    alvo[partes[-1]] = valor
    return antigo


def arred(v, casas=4):
    return round(v, casas)


def aplicar_fator(ficha, inicio, fim, motivo):
    """Ajuste de calibração em dois botões, medidos na luta 5x5 do laboratório.

    - "inicio" mexe no que vale sem itens: dano de nível 1 e ganho por nível das habilidades e da passiva.
    - "fim" mexe no que cresce com os itens: proporções de dano físico bônus e poder mágico.
    Por classe, os botões também movem:
    - atirador: dano físico (base × inicio; ganho × fim) e crescimento da velocidade de ataque (× fim);
    - tanque e lutador: vida (base × raiz de inicio; ganho × raiz de fim);
    - suporte: escudos e curas em aliados (% de vida × inicio; proporção de PM × fim).
    """
    def escala_dano(d, alvo_prop):
        d["base"] = [arred(d["base"][0] * inicio, 2), arred(d["base"][1] * inicio, 3)]
        for k in ("dano_fisico_bonus", "poder_magico"):
            if alvo_prop.get(k):
                alvo_prop[k] = arred(alvo_prop[k] * fim, 5)

    for h in ficha["habilidades"]:
        escala_dano(h["dano"], h["dano"]["proporcoes"])
    pd = ficha["passiva"]["mecanica"].get("dano")
    if pd:
        escala_dano(pd, pd)
    a = ficha["atributos"]
    if ficha["classe"] == "atirador":
        a["dano_fisico"] = [arred(a["dano_fisico"][0] * inicio, 2), arred(a["dano_fisico"][1] * fim, 3)]
        a["velocidade_ataque"] = [a["velocidade_ataque"][0], arred(a["velocidade_ataque"][1] * fim, 3)]
    if ficha["classe"] in ("tanque", "lutador"):
        a["vida"] = [arred(a["vida"][0] * inicio ** 0.5, 1), arred(a["vida"][1] * fim ** 0.5, 2)]
    if ficha["classe"] == "suporte":
        for h in ficha["habilidades"]:
            for chave in ("escudo", "cura"):
                if chave in h["mecanica"]:
                    d = h["mecanica"][chave]
                    d["pct_vida"] = arred(d["pct_vida"] * inicio, 4)
                    if "teto_pct" in d:
                        d["teto_pct"] = arred(d["teto_pct"] * inicio, 4)
                    if d.get("pm"):
                        d["pm"] = arred(d["pm"] * fim, 4)
    ficha["ajustes"].append({"campo": "força (botões inicio e fim, ver aplicar_fator em tools/conversao/converter_campeoes.py)", "inicio": inicio, "fim": fim, "motivo": motivo})


# Condições dos itens alternativos, lidas do texto "quando" da ficha. A simulação (e, na partida, o Macro do jogador)
# usa a condição para trocar o item da build. Ordem importa: a primeira regra que casar vale.
REGRAS_CONDICAO = [
    (r"pouc[ao] (?:dano mágico|magia|ameaça mágica)|sem ameaça mágica|proteção mágica rende pouco|escudo só mágico tem pouco valor|há pouca magia", "pouca_magia"),
    (r"resistência mágica alta|empilha\w* resistência mágica|já empilham resistência mágica|resistência mágica empilhada", "resistencia_magica"),
    (r"pouca resistência mágica|resistência baixa", "frageis"),
    (r"explosão mágica|magia de execução|dano mágico|pressão mágica|ameaça mágica dominante|quase toda mágica|desgaste mágico|magos|controle mágico|controle e dano mágico|magia e controle|magia que impede|rajadas de magia", "muita_magia"),
    (r"crítico", "critico"),
    (r"cura|roubo de vida|sustentam", "cura"),
    (r"armadura alta|armadura elevada|acúmulo de armadura|armadura suficiente|resistência física alta|defesa física|armadura$", "armadura"),
    (r"explosão física|mergulho físico|perseguidores físicos|pressão física|invas\w* físic\w*|atacante físico|atirador de ataques básicos|ataques rápidos|ataques físicos|desgaste físico|duelos físicos|rajadas físicas|ameaça física", "fisico"),
    (r"dano misto|desgaste misto", "misto"),
    (r"muita vida|vida alta", "vida_alta"),
    (r"frágeis|retaguarda", "frageis"),
]


def condicao_do_texto(texto):
    for padrao, condicao in REGRAS_CONDICAO:
        if re.search(padrao, texto):
            return condicao
    return "situacional"


def converter():
    texto = open(PROPOSTA, encoding="utf-8").read()
    fichas = [json.loads(b) for b in re.findall(r"```json\n(.*?)\n```", texto, re.S)]
    global ORCAMENTOS
    ORCAMENTOS = {nome: int(pct) / 100 for nome, pct in re.findall(r"^\| (\S+) \| (\d+)% \|", texto, re.M)}
    ajustes_lab = json.load(open(CAMINHO_AJUSTES_LAB, encoding="utf-8")) if os.path.exists(CAMINHO_AJUSTES_LAB) else {}
    saida = []
    for f in fichas:
        c = copy.deepcopy(f)
        c["ajustes"] = []
        for h in c["habilidades"]:
            mec = ler_habilidade(h)
            extra = MANUAL_HABILIDADES.get((c["id"], h["posicao"]), {})
            mec.update(extra)
            if c["recurso"]["tipo"] == "vida":
                mec.setdefault("custo_vida", h["custo"] / 100)
            h["mecanica"] = mec
        if c["id"] not in MANUAL_PASSIVAS:
            sys.exit("Passiva sem mecânica: %s" % c["id"])
        c["passiva"]["mecanica"] = copy.deepcopy(MANUAL_PASSIVAS[c["id"]])
        c["build_ids"] = [ID_ITEM[n] for n in c["build_recomendada"]]
        for alt in c["itens_alternativos"]:
            alt["item_id"] = ID_ITEM[alt["item"]]
            alt["substitui_id"] = ID_ITEM[alt["substitui"]]
            alt["condicao"] = condicao_do_texto(alt["quando"])
        # Ajustes manuais primeiro, sobre os números da proposta; as correções seguintes escalam a partir deles.
        for caminho, valor, motivo in AJUSTES.get(c["id"], []):
            antigo = definir(c, caminho, valor)
            c["ajustes"].append({"campo": caminho, "antes": antigo, "depois": valor, "motivo": motivo})
        orcamento = ORCAMENTOS.get(c["nome"])
        if orcamento:
            fator = round(correcao_de_orcamento(c, orcamento), 3)
            escalar_basicas(c, fator)
            c["ajustes"].append({"campo": "habilidades 1 e 2 e dano da passiva", "fator": fator,
                                 "motivo": "Correção de orçamento: dano contínuo das básicas = %d%% do combo da classe a cada 7 s." % round(orcamento * 100)})
        corrigir_classe(c)
        if c["id"] in ajustes_lab:
            a = ajustes_lab[c["id"]]
            if abs(a["inicio"] - 1) > 1e-6 or abs(a["fim"] - 1) > 1e-6:
                aplicar_fator(c, a["inicio"], a["fim"], a.get("motivo", "Calibração do laboratório de campeões."))
        saida.append(c)
    dados = {
        "_comentario": "Catálogo de campeões de Crystal Legends. Gerado por tools/conversao/converter_campeoes.py a partir de docs/propostas/campeoes.md (textos do GPT) com a mecânica estruturada e os ajustes de calibração. A força no patch (meta) não fica aqui.",
        "versao": 1,
        "campeoes": saida,
    }
    os.makedirs(os.path.dirname(SAIDA), exist_ok=True)
    with open(SAIDA, "w", encoding="utf-8") as arquivo:
        json.dump(dados, arquivo, ensure_ascii=False, indent="\t")
        arquivo.write("\n")
    return saida


def resumo(campeoes):
    for c in campeoes:
        print("== %s (%s)" % (c["nome"], c["classe"]))
        for h in c["habilidades"]:
            print("   %d %-24s %s" % (h["posicao"], h["nome"], json.dumps(h["mecanica"], ensure_ascii=False)))
        for a in c["ajustes"]:
            print("   ajuste:", a)


if __name__ == "__main__":
    campeoes = converter()
    if "--resumo" in sys.argv:
        resumo(campeoes)
    print("Gerado %s com %d campeões." % (os.path.relpath(SAIDA, RAIZ), len(campeoes)))
