"""Surgimento da Hydra: a água borbulha e acende por baixo, estoura num jorro, as cabeças
sobem escorrendo água, ela ruge (cabeças recuam e avançam, névoa gelada pelas bocas, onda
na água) e assenta na pose do mapa.

Uso (na raiz do projeto):  python3 tools/arte/animar_hydra.py [--previa] [--salvar]
Gera assets/animacoes/caldeira/hydra_*.webp.
"""
from __future__ import annotations

import math
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as nd

import animacao_comum as ac

UNIDADE = 1.45
ORIGEM = (186, 194)
TAMANHO = (245, 212)
ESCALA = 2
FPS = 30
DURACAO = 4.6
LINHA_DAGUA = 240          # abaixo disto (na pose final) está tudo fora d'água
SUBIDA = 200.0             # quanto ela sobe desde o fundo
BASE = (188, 222)          # onde o corpo encontra a água

CORPO = {"base": (190, 218), "centro": (175, 196), "cauda_base": (140, 214), "cauda_meio": (96, 196),
         "cauda_curva": (70, 168), "cauda_ponta": (58, 146)}
CABECAS = {
    "centro": {"pescoco_baixo": (166, 176), "pescoco": (150, 134), "cabeca": (176, 90), "crista": (164, 60),
               "focinho": (204, 97), "mandibula": (190, 121)},
    "direita": {"pescoco_baixo": (214, 186), "pescoco": (226, 140), "cabeca": (268, 140), "crista": (262, 104),
                "focinho": (300, 158), "mandibula": (285, 176)},
}
DIRECAO_FOCINHO = {"centro": np.array([0.85, 0.25]), "direita": np.array([0.75, 0.55])}


def recortes():
    mapa = ac.carregar("assets/sprites/mapa/caldeira_glacial.webp")
    x, y = ORIGEM
    caixa = (round(x * UNIDADE), round(y * UNIDADE), round((x + TAMANHO[0]) * UNIDADE), round((y + TAMANHO[1]) * UNIDADE))
    final = mapa.crop(caixa)
    placa = ac.carregar("assets/sprites/mapa/arena_hydra.webp").resize((round(247 * UNIDADE), round(203 * UNIDADE)), Image.LANCZOS)
    vazio = Image.new("RGBA", final.size, (0, 0, 0, 0))
    vazio.alpha_composite(placa, (round((184.5 - x) * UNIDADE), round((200.5 - y) * UNIDADE)))
    return final, vazio


def agua(hsv):
    return (hsv[..., 0] > 108) & (hsv[..., 0] < 145) & (hsv[..., 1] > 100) & (hsv[..., 2] > 60)


def mascaras(final, vazio):
    hc = np.asarray(final.convert("RGB").convert("HSV")).astype(np.float32)
    he = np.asarray(vazio.convert("RGB").convert("HSV")).astype(np.float32)
    ea = np.asarray(vazio)[..., 3]
    poca = nd.binary_closing(agua(he) & (ea > 200), iterations=4)
    c = np.asarray(final.convert("RGB")).astype(np.float32)
    e = np.asarray(vazio).astype(np.float32)[..., :3]
    m = poca & ~agua(hc) & (np.abs(c - e).sum(-1) > 40)
    m = nd.binary_closing(nd.binary_opening(m, iterations=1), iterations=2)
    rot, n = nd.label(m)
    tam = nd.sum(m, rot, range(1, n + 1))
    m = np.isin(rot, [i + 1 for i, v in enumerate(tam) if v > 500])
    furos = nd.binary_fill_holes(m) & ~m
    rf, nf = nd.label(furos)
    for i, v in enumerate(nd.sum(furos, rf, range(1, nf + 1)), 1):
        if v < 250:
            m |= rf == i
    # A borda de pedra lá em cima não é bicho: só a crista da cabeça passa da linha 72.
    xs = np.arange(m.shape[1])[None, :]
    ys = np.arange(m.shape[0])[:, None]
    m &= ~((ys < 72) & ((xs < 140) | (xs > 215)))
    # Perto da borda de cima, só os espinhos claros da crista (a pedra da borda é mais escura).
    # A borda de gelo atrás da cabeça tem a mesma cor do bicho, mas é mais apagada que os espinhos.
    claro = hc[..., 2] > 212
    m &= ~((ys < 74) & ~claro)
    m = nd.binary_opening(m, iterations=1) | (m & (ys >= 74))
    return np.clip(ac.desfocar(m.astype(np.float32), 0.7) * 1.15, 0, 1), poca.astype(np.float32)


def descanso():
    alcas = [CORPO[n] for n in CORPO]
    for cab in CABECAS.values():
        alcas += [cab[p] for p in cab]
    return np.array(alcas, np.float32)


def posar(t, ruido):
    subiu = ac.sair(ac.faixa(t, 0.72, 2.45), 2.6)
    desce = SUBIDA * (1 - subiu)
    balanca = ac.faixa(t, 0.8, 1.2) * (1 - ac.faixa(t, 2.6, 2.9))
    preparo = ac.suave(ac.faixa(t, 2.62, 2.92)) * (1 - ac.faixa(t, 2.92, 3.04))
    alcas, nomes = [], []

    def subir(p, extra=0.0):
        return np.array(p, np.float32) + np.array([0, desce * (1 + extra)])

    for k, (nome, p) in enumerate(CORPO.items()):
        onda = 0.0
        if nome.startswith("cauda"):
            peso = {"cauda_base": 0.3, "cauda_meio": 0.6, "cauda_curva": 0.9, "cauda_ponta": 1.0}[nome]
            onda = math.sin(t * 4.2 - peso * 2.4) * 4.0 * peso * (0.4 + 0.6 * balanca)
        q = subir(p, 0.05 * (k >= 2)) + np.array([onda * 0.6, onda])
        alcas.append(q)
        nomes.append(nome)
    for k, (nome, cab) in enumerate(CABECAS.items()):
        atraso = 0.09 * k
        rugido = ac.sair(ac.faixa(t, 2.98 + atraso, 3.14 + atraso)) * (1 - ac.suave(ac.faixa(t, 3.62 + atraso, 4.2)))
        direcao = DIRECAO_FOCINHO[nome] / np.linalg.norm(DIRECAO_FOCINHO[nome])
        pivo = subir(cab["pescoco_baixo"])
        # As cabeças sobem um pouco à frente do corpo (puxam a subida).
        frente = -18.0 * ac.pulso(t, 1.35 + 0.15 * k, 0.9)
        angulo = 0.12 * math.sin(t * 3.1 + k * 1.7) * balanca - 0.30 * preparo + 0.12 * rugido
        translado = direcao * (12.0 * rugido - 9.0 * preparo) + np.array([0, -10.0 * preparo + frente])
        translado += np.array([ruido[k] * 1.4 * ac.pulso(t, 3.3 + atraso, 0.4), 0])
        boca = rugido * 7.0 + preparo * 1.5
        ca, sa = math.cos(angulo), math.sin(angulo)
        for parte, p in cab.items():
            q = subir(p) - pivo
            peso = 0.0 if parte == "pescoco_baixo" else (0.5 if parte == "pescoco" else 1.0)
            ang = angulo * peso
            c2, s2 = math.cos(ang), math.sin(ang)
            q = np.array([q[0] * c2 - q[1] * s2, q[0] * s2 + q[1] * c2])
            q = pivo + q + translado * peso
            if parte == "mandibula":
                q = q + np.array([0.25, 1.0]) / math.hypot(0.25, 1.0) * boca
            alcas.append(q)
            nomes.append(f"{nome}_{parte}")
    return np.array(alcas, np.float32), nomes, desce


def gerar():
    final_img, vazio_img = recortes()
    w0, h0 = final_img.size
    W, H = w0 * ESCALA, h0 * ESCALA
    mascara, poca = mascaras(final_img, vazio_img)
    grande = lambda m: np.clip(np.asarray(Image.fromarray((m * 255).astype(np.uint8)).resize((W, H), Image.LANCZOS)) / 255.0, 0, 1).astype(np.float32)
    mascara, poca = grande(mascara), grande(poca)
    final = ac.para_float(final_img.resize((W, H), Image.LANCZOS))
    vazio = ac.para_float(vazio_img.resize((W, H), Image.LANCZOS))
    oval = vazio[..., 3].copy()
    opaco = vazio[..., :3] / np.maximum(vazio[..., 3:4], 1e-4)
    media = (opaco * (oval[..., None] > 0.99)).sum((0, 1)) / max(1, (oval > 0.99).sum())
    vazio = np.concatenate([np.where(oval[..., None] > 0.02, opaco, media[None, None, :]), np.ones_like(oval)[..., None]], -1).astype(np.float32)
    bicho = ac.com_alfa(final, mascara)
    deformador = ac.Deformador(bicho, descanso() * ESCALA, alfa=1.5, passo=2)
    rng = np.random.default_rng(21)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    gotas = []     # [x, y, nasce, vida, vx, vy, tam]
    neblina = []   # [x, y, nasce, vida, vx, vy, r0, r1]
    aneis = []     # [nasce, cx, cy, forca]
    quadros = []
    n = int(DURACAO * FPS)
    ruido = rng.normal(0, 1, (n + 2, 3))
    dt = 1.0 / FPS
    base = np.array(BASE, np.float32) * ESCALA
    for i in range(n):
        t = i / FPS
        rq = np.random.default_rng(3000 + i)
        mistura_final = ac.mais_suave(ac.faixa(t, 4.0, 4.55))
        # Anéis na água: borbulhar no começo, um grande no jorro, outro no rugido.
        if i % 7 == 0 and 0.1 < t < 3.2:
            aneis.append([t, base[0] + rq.normal(0, 12 * ESCALA), base[1] + rq.normal(0, 5 * ESCALA), 0.5])
        if abs(t - 0.78) < dt / 2:
            aneis.append([t, base[0], base[1], 1.6])
        if abs(t - 3.05) < dt / 2:
            aneis.append([t, base[0], base[1] - 20 * ESCALA, 1.2])
        # --- água ---------------------------------------------------------------------
        fundo = vazio.copy()
        brilho_baixo = (0.35 * ac.faixa(t, 0.0, 0.6) + 0.6 * ac.pulso(t, 0.78, 0.25)) * (1 - ac.faixa(t, 1.2, 2.2))
        if brilho_baixo > 0:
            d = np.sqrt(((xx - base[0]) / (70 * ESCALA)) ** 2 + ((yy - base[1] + 10 * ESCALA) / (42 * ESCALA)) ** 2)
            fundo = ac.luz(fundo, (0.35, 0.85, 1.0), np.exp(-d * d * 1.5) * poca * brilho_baixo * (0.8 + 0.2 * math.sin(t * 17)))
        luz_aneis = np.zeros((H, W), np.float32)
        refracao = np.zeros((H, W), np.float32)
        vivos = []
        for a in aneis:
            idade = t - a[0]
            vida = 1.6 * a[3]
            if idade > vida:
                continue
            vivos.append(a)
            raio = (10 + 120 * ac.sair(idade / vida, 1.8) * a[3]) * ESCALA
            d = np.sqrt((xx - a[1]) ** 2 + ((yy - a[2]) / 0.55) ** 2)
            anel = np.exp(-((d - raio) / (3.5 * ESCALA)) ** 2) * (1 - idade / vida) * min(1, a[3])
            luz_aneis += anel
            refracao += anel * a[3]
        aneis = vivos
        luz_aneis *= poca
        if refracao.max() > 0.01:
            desloca = refracao * poca * 2.0 * ESCALA
            nova = np.empty_like(fundo)
            for canal in range(4):
                nova[..., canal] = nd.map_coordinates(fundo[..., canal], [yy - desloca, xx], order=1, mode="nearest")
            fundo = nova
        fundo = ac.luz(fundo, (0.75, 0.95, 1.0), luz_aneis * 0.45)
        # --- Hydra ----------------------------------------------------------------------
        alcas, nomes, desce = posar(t, ruido[i])
        camada = deformador.deformar(alcas * ESCALA)
        acima = np.clip((LINHA_DAGUA * ESCALA - yy) / (12 * ESCALA) + 0.5, 0, 1)
        profundidade = np.clip((yy - LINHA_DAGUA * ESCALA) / (60 * ESCALA), 0, 1)
        submersa = (1 - acima) * 0.42 * np.exp(-profundidade * 2.2) * poca
        visivel = np.clip(acima + submersa, 0, 1) * ac.faixa(t, 0.12, 0.4)
        # Debaixo d'água: azulada, ondulando.
        onda = np.sin(yy / (6 * ESCALA) + t * 9) * 1.5 * ESCALA * (1 - acima)
        camada_ondulada = np.empty_like(camada)
        for canal in range(4):
            camada_ondulada[..., canal] = nd.map_coordinates(camada[..., canal], [yy, xx + onda], order=1, mode="constant")
        camada = ac.com_alfa(camada_ondulada, visivel)
        tinta = (1 - acima)[..., None]
        camada[..., :3] = camada[..., :3] * (1 - tinta * 0.55) + np.array([0.05, 0.35, 0.45]) * camada[..., 3:4] * tinta * 0.55
        # Molhada logo depois de sair: brilho que escorre.
        molhada = ac.faixa(t, 1.0, 1.6) * (1 - ac.faixa(t, 2.6, 3.6))
        camada = ac.luz(camada, (0.25, 0.4, 0.5), np.clip(camada[..., 2] - 0.55, 0, 1) * molhada * 1.2)
        cena = ac.sobre(fundo, camada)
        # Espuma onde o corpo corta a água.
        if t > 0.75:
            linha = LINHA_DAGUA * ESCALA - 18 * ESCALA * ac.faixa(t, 2.0, 2.6)
            contato = np.exp(-((yy - linha) / (7 * ESCALA)) ** 2)
            perto = ac.desfocar(camada[..., 3], 4 * ESCALA)
            espuma = np.clip(perto * 1.6, 0, 1) * contato * (1 - camada[..., 3]) * poca * (0.5 + 0.5 * ac.faixa(t, 0.75, 1.3)) * (1 - mistura_final)
            cena = ac.sobre(cena, np.concatenate([np.array([0.85, 0.95, 1.0])[None, None, :] * espuma[..., None] * 0.7, espuma[..., None] * 0.7], -1))
        # --- partículas -----------------------------------------------------------------------
        if abs(t - 0.78) < dt / 2:
            for _ in range(70):
                a = rq.uniform(-math.pi, 0)
                v = rq.uniform(50, 170)
                gotas.append([base[0] + rq.normal(0, 14 * ESCALA), base[1], t, rq.uniform(0.6, 1.1), math.cos(a) * v * 0.6 * ESCALA, math.sin(a) * v * ESCALA - 40 * ESCALA, rq.uniform(0.8, 1.8) * ESCALA])
            for _ in range(14):
                neblina.append([base[0] + rq.normal(0, 25 * ESCALA), base[1] - rq.uniform(0, 30) * ESCALA, t, rq.uniform(0.9, 1.4), rq.normal(0, 10) * ESCALA, -rq.uniform(10, 30) * ESCALA, 8 * ESCALA, rq.uniform(18, 30) * ESCALA])
        # Água escorrendo das cabeças enquanto sobem.
        if 1.0 < t < 2.8:
            for nome in CABECAS:
                if rq.uniform() < 0.8:
                    j = nomes.index(f"{nome}_cabeca")
                    hx, hy = alcas[j] * ESCALA
                    gotas.append([hx + rq.normal(0, 8 * ESCALA), hy + rq.normal(0, 6 * ESCALA), t, rq.uniform(0.4, 0.7), rq.normal(0, 8) * ESCALA, rq.uniform(10, 40) * ESCALA, rq.uniform(0.7, 1.3) * ESCALA])
        # Rugido: névoa gelada saindo das bocas.
        for k, nome in enumerate(CABECAS):
            if 3.0 + 0.09 * k < t < 3.55 + 0.09 * k:
                j = nomes.index(f"{nome}_mandibula")
                jx, jy = alcas[j] * ESCALA
                d = DIRECAO_FOCINHO[nome] / np.linalg.norm(DIRECAO_FOCINHO[nome])
                for _ in range(5):
                    v = rq.uniform(50, 130) * ESCALA
                    ang = rq.normal(0, 0.5)
                    vx = (d[0] * math.cos(ang) - d[1] * math.sin(ang)) * v
                    vy = (d[0] * math.sin(ang) + d[1] * math.cos(ang)) * v
                    neblina.append([jx, jy - 4 * ESCALA, t, rq.uniform(0.5, 0.9), vx, vy, 2 * ESCALA, rq.uniform(8, 15) * ESCALA])
                    gotas.append([jx, jy, t, rq.uniform(0.4, 0.8), vx * 1.2, vy * 1.2, rq.uniform(0.6, 1.2) * ESCALA])
        vivas = []
        for g in gotas:
            idade = (t - g[2]) / g[3]
            if idade >= 1:
                continue
            vivas.append(g)
            s = t - g[2]
            x = g[0] + g[4] * s
            y = g[1] + g[5] * s + 0.5 * 420 * ESCALA * s * s
            ac.mancha(cena, x, y, g[6] * 1.4, (0.75, 0.92, 1.0), 0.7 * (1 - idade), nitidez=2.2)
            ac.mancha(cena, x, y - 0.4 * g[6], g[6] * 0.5, (1, 1, 1), 0.8 * (1 - idade), nitidez=2.5, aditiva=True)
        gotas = vivas
        vivas = []
        for p in neblina:
            idade = (t - p[2]) / p[3]
            if idade >= 1:
                continue
            vivas.append(p)
            s = t - p[2]
            x = p[0] + p[4] * s * (1 - idade * 0.5)
            y = p[1] + p[5] * s * (1 - idade * 0.5)
            r = p[6] + (p[7] - p[6]) * ac.sair(idade, 2)
            ac.mancha(cena, x, y, r, (0.85, 0.95, 1.0), 0.20 * (1 - idade) ** 1.4 * min(1, idade * 6), nitidez=1.1)
        neblina = vivas
        # Tremor no jorro e no rugido.
        forca = 2.0 * math.exp(-max(0, t - 0.78) * 6) * (t >= 0.78) + 2.4 * math.exp(-max(0, t - 3.02) * 4.5) * (t >= 3.0)
        dx, dy = rq.normal(0, 1, 2) * forca * ESCALA
        cena = nd.shift(cena, (dy, dx, 0), order=1, mode="nearest")
        if mistura_final > 0:
            cena = cena * (1 - mistura_final) + final * mistura_final
        cena = np.clip(cena, 0, 1)
        cena[..., 3] = 1.0
        cena = ac.com_alfa(cena, oval)
        quadros.append(ac.para_imagem(cena).resize((w0, h0), Image.LANCZOS))
        if i % 15 == 0:
            print(f"  quadro {i}/{n}", flush=True)
    ultimo = ac.com_alfa(ac.para_float(final_img), np.asarray(vazio_img)[..., 3].astype(np.float32) / 255)
    quadros.append(ac.para_imagem(ultimo))
    return quadros


if __name__ == "__main__":
    quadros = gerar()
    if "--previa" in sys.argv:
        ac.salvar_gif(quadros, "/tmp/anim/hydra_nova.gif", FPS)
        for i, q in enumerate(quadros):
            q.save(f"/tmp/anim/hydra_nova_{i:03d}.png")
    if "--salvar" in sys.argv:
        print(ac.empacotar(quadros, quadros[0].size, 5, 55, "assets/animacoes/caldeira/hydra"))
    print(len(quadros), "quadros", quadros[0].size)
