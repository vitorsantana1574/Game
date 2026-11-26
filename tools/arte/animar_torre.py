"""Queda da torre: rachaduras acendem, o cristal estoura, a torre tomba e se quebra em
pedaços irregulares (fratura de Voronoi) que caem com peso, quicam e somem na poeira,
deixando a ruína do mapa.

Uso (na raiz do projeto):  python3 tools/arte/animar_torre.py [--previa] [--salvar]
Gera assets/animacoes/caldeira/torre_azul_*.webp e torre_coral_*.webp.
"""
from __future__ import annotations

import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage as nd
from scipy.spatial import cKDTree

import animacao_comum as ac

PX = 2                        # pixels por unidade do tabuleiro (as placas de torre são 2x)
CAIXA = (-90, -105, 180, 160)  # célula em unidades, relativa ao ponto da torre
PLACA = (-62, -72)             # onde a placa da torre fica, relativa ao ponto
FPS = 30
DURACAO = 2.6
CORES = {"azul": (0.45, 0.88, 1.0), "coral": (1.0, 0.56, 0.46)}
CHAO_Y = 150                   # linha do chão na placa (pixels), onde os pedaços param


def fratura(alfa, n, rng):
    """Divide a silhueta em n pedaços irregulares (células de Voronoi, mais miúdas no topo)."""
    ys, xs = np.nonzero(alfa > 0.5)
    pontos = []
    while len(pontos) < n:
        k = rng.integers(len(xs))
        # Mais pedaços pequenos perto do topo (onde o cristal e as ameias quebram fino).
        if rng.uniform() < 0.5 + 0.5 * (1 - (ys[k] - ys.min()) / max(1, np.ptp(ys))):
            pontos.append((xs[k] + rng.uniform(-1, 1), ys[k] + rng.uniform(-1, 1)))
    pontos = np.array(pontos)
    h, w = alfa.shape
    yy, xx = np.mgrid[0:h, 0:w]
    _, rotulo = cKDTree(pontos).query(np.stack([xx.ravel(), yy.ravel()], -1))
    rotulo = rotulo.reshape(h, w)
    # Borda irregular: desloca o rótulo com ruído para não ficar com cortes retos.
    ruido_x = ac.desfocar(rng.normal(0, 1, (h, w)).astype(np.float32), 2.5) * 9
    ruido_y = ac.desfocar(rng.normal(0, 1, (h, w)).astype(np.float32), 2.5) * 9
    rx = np.clip(xx + ruido_x, 0, w - 1).astype(int)
    ry = np.clip(yy + ruido_y, 0, h - 1).astype(int)
    return rotulo[ry, rx], pontos


class Pedaco:
    def __init__(self, img, caixa, centro, rng, base_x, topo_y, altura):
        self.img = img            # PIL RGBA do pedaço
        self.caixa = caixa        # (x0, y0) na placa
        self.c = np.array(centro, np.float32)
        frac = (centro[1] - topo_y) / max(1, altura)      # 0 no topo, 1 embaixo
        lado = np.sign(centro[0] - base_x) or (1 if rng.uniform() < 0.5 else -1)
        self.atraso = 0.42 + 0.10 * frac + rng.uniform(0, 0.08)
        self.vx = lado * rng.uniform(6, 26) + 10 * (1 - frac)   # o topo tomba um pouco para a direita
        self.vy = rng.uniform(-25, 5) - 25 * (1 - frac)
        self.giro = rng.uniform(-200, 200) * (1.2 - frac)  # graus por segundo
        self.chao = CHAO_Y + rng.uniform(-14, 18)
        self.ang = 0.0
        self.pos = self.c.copy()
        self.parado = False
        self.quicou = False
        self.pousou_em = None

    def avancar(self, t, dt):
        if t < self.atraso or self.parado:
            return
        g = 900.0
        self.vy += g * dt
        self.pos += np.array([self.vx, self.vy]) * dt
        self.ang += self.giro * dt
        if self.pos[1] >= self.chao:
            self.pos[1] = self.chao
            if self.pousou_em is None:
                self.pousou_em = t
            if not self.quicou and self.vy > 120:
                self.vy = -self.vy * 0.22
                self.vx *= 0.45
                self.giro *= 0.4
                self.quicou = True
            else:
                self.parado = True


def rachaduras(forma, rng, n=7, origem=(125, 95)):
    """Linhas de rachadura em ziguezague saindo do meio da torre."""
    h, w = forma
    linhas = []
    for _ in range(n):
        x, y = origem[0] + rng.uniform(-14, 14), origem[1] + rng.uniform(-30, 40)
        ang = rng.uniform(0, 2 * math.pi)
        pts = [(x, y)]
        for _ in range(rng.integers(4, 8)):
            ang += rng.uniform(-0.8, 0.8)
            passo = rng.uniform(5, 12)
            x += math.cos(ang) * passo
            y += math.sin(ang) * passo
            pts.append((x, y))
        linhas.append(pts)
    return linhas


def gerar(lado, previa=False):
    rng = np.random.default_rng(11 if lado == "azul" else 12)
    cor = CORES[lado]
    inteira = ac.carregar(f"assets/sprites/mapa/torre_{lado}_inteira.webp")
    ruina = ac.carregar(f"assets/sprites/mapa/torre_{lado}_ruina.webp")
    W, H = CAIXA[2] * PX, CAIXA[3] * PX
    ox, oy = (PLACA[0] - CAIXA[0]) * PX, (PLACA[1] - CAIXA[1]) * PX
    arr = np.asarray(inteira).astype(np.float32) / 255
    alfa = arr[..., 3]
    estrutura = alfa > 0.9
    # A sombra (semitransparente) fica no chão e some com a torre.
    sombra = inteira.copy()
    sa = np.asarray(sombra).copy()
    linha = np.arange(sa.shape[0])[:, None]
    halo_a = np.where(~estrutura & (linha < 125), sa[..., 3], 0).astype(np.uint8)
    sa[..., 3] = np.where(estrutura | (linha < 125), 0, sa[..., 3])
    sombra = Image.fromarray(sa)
    # Halo do cristal (semitransparente, acima do chão): some quando a torre quebra.
    ha = np.asarray(inteira).copy()
    ha[..., 3] = halo_a
    halo = Image.fromarray(ha)
    corpo = np.asarray(inteira).copy()
    corpo[..., 3] = np.where(estrutura, corpo[..., 3], 0)
    corpo_img = Image.fromarray(corpo)
    ys, xs = np.nonzero(estrutura)
    topo_y, base_y = ys.min(), ys.max()
    base_x = float(xs.mean())
    rotulo, pontos = fratura(estrutura.astype(np.float32), 26, rng)
    pedacos = []
    for k in range(len(pontos)):
        m = (rotulo == k) & estrutura
        if m.sum() < 12:
            continue
        yk, xk = np.nonzero(m)
        x0, x1, y0, y1 = xk.min(), xk.max() + 1, yk.min(), yk.max() + 1
        recorte = corpo[y0:y1, x0:x1].copy()
        recorte[..., 3] = np.where(m[y0:y1, x0:x1], recorte[..., 3], 0)
        # Face interna da quebra: escurece a borda do pedaço para dar volume.
        borda = nd.binary_dilation(~m[y0:y1, x0:x1], iterations=2) & m[y0:y1, x0:x1]
        recorte[..., :3] = np.where(borda[..., None], (recorte[..., :3] * 0.55).astype(np.uint8), recorte[..., :3])
        pedacos.append(Pedaco(Image.fromarray(recorte), (x0, y0), ((x0 + x1) / 2, (y0 + y1) / 2), rng, base_x, topo_y, base_y - topo_y))
    linhas = rachaduras(alfa.shape, rng, origem=(base_x, (topo_y + base_y) / 2))
    # Cristal: a parte mais brilhante e saturada do topo.
    hsv = np.asarray(inteira.convert("RGB").convert("HSV")).astype(np.float32)
    cristal = (hsv[..., 1] > 120) & (hsv[..., 2] > 170) & estrutura
    cy, cx = np.nonzero(cristal)
    centro_cristal = (cx.mean(), cy.mean()) if len(cx) else (base_x, topo_y + 30)
    lascas = []
    for _ in range(18):
        a = rng.uniform(-math.pi, 0.2)
        v = rng.uniform(60, 190)
        lascas.append([centro_cristal[0], centro_cristal[1], math.cos(a) * v, math.sin(a) * v - 40, rng.uniform(1.5, 3.5), rng.uniform(0, 6.28), rng.uniform(-12, 12)])
    poeira = []
    pedrinhas = []
    quadros = []
    n = int(DURACAO * FPS)
    dt = 1.0 / FPS
    for i in range(n):
        t = i / FPS
        rq = np.random.default_rng(500 + i)
        tela = np.zeros((H, W, 4), np.float32)
        # Ruína aparece por baixo enquanto a torre cai.
        r_alfa = ac.faixa(t, 0.7, 1.3)
        if r_alfa > 0:
            camada = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            camada.alpha_composite(ruina, (ox, oy))
            tela = ac.sobre(tela, ac.para_float(camada) * r_alfa)
        # Sombra da torre encolhe.
        s_alfa = 1 - ac.faixa(t, 0.45, 1.0)
        if s_alfa > 0:
            camada = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            camada.alpha_composite(sombra, (ox, oy))
            tela = ac.sobre(tela, ac.para_float(camada) * s_alfa)
        h_alfa = 1 - ac.faixa(t, 0.40, 0.52)
        if h_alfa > 0:
            camada = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            camada.alpha_composite(halo, (ox, oy))
            tela = ac.sobre(tela, ac.para_float(camada) * h_alfa)
        quebrou = t >= 0.42
        if not quebrou:
            # Inclina e treme antes de quebrar; rachaduras acendem.
            inclina = 4.0 * ac.entrar(ac.faixa(t, 0.15, 0.42), 2)
            treme = rq.normal(0, 1, 2) * (0.6 + 1.6 * ac.faixa(t, 0.0, 0.42)) * (t > 0.02)
            img = corpo_img.copy()
            d = ImageDraw.Draw(img)
            cresce = ac.sair(ac.faixa(t, 0.02, 0.38))
            luz_rach = tuple(int(255 * min(1, c * 1.1 + 0.2)) for c in cor)
            for pts in linhas:
                k = max(2, int(len(pts) * cresce))
                d.line(pts[:k], fill=luz_rach + (255,), width=2)
            img = Image.composite(img, Image.new("RGBA", img.size, (0, 0, 0, 0)), Image.fromarray((estrutura * 255).astype(np.uint8)))
            # Brilho das rachaduras e lampejo do impacto.
            brilho = img.filter(ImageFilter.GaussianBlur(3))
            img = img.rotate(-inclina, resample=Image.BICUBIC, center=(base_x, base_y))
            camada = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            camada.alpha_composite(img, (int(ox + treme[0]), int(oy + treme[1])))
            f = ac.para_float(camada)
            lampejo = ac.pulso(t, 0.03, 0.10) * 0.22 + ac.pulso(t, 0.38, 0.08) * 0.45
            f = ac.luz(f, (lampejo * 0.9, lampejo * 0.95, lampejo), np.ones(f.shape[:2], np.float32))
            tela = ac.sobre(tela, f)
            # Cristal pulsando antes de estourar.
            pulso_c = (0.4 + 0.6 * abs(math.sin(t * 30))) * ac.faixa(t, 0.1, 0.42)
            ac.mancha(tela, ox + centro_cristal[0] + treme[0], oy + centro_cristal[1] + treme[1], 16, cor, 0.5 * pulso_c, nitidez=1.4, aditiva=True)
        else:
            # Pedaços: desenha de trás para a frente (pela linha do chão).
            for p in pedacos:
                p.avancar(t, dt)
                if p.pousou_em is not None and not getattr(p, "poeira_feita", False):
                    p.poeira_feita = True
                    for _ in range(3):
                        poeira.append([ox + p.pos[0] + rng.uniform(-6, 6), oy + p.pos[1] + rng.uniform(-3, 3), t, rng.uniform(0.7, 1.2), rng.uniform(3, 5), rng.uniform(9, 16), rng.uniform(0.18, 0.3), rng.uniform(-20, 20), rng.uniform(-14, -4)])
                    for _ in range(2):
                        pedrinhas.append([ox + p.pos[0], oy + p.pos[1], rng.uniform(-50, 50), rng.uniform(-90, -40), t, rng.uniform(1.0, 2.0)])
            some = 1 - ac.mais_suave(ac.faixa(t, 1.55, 2.2))
            camada = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            for p in sorted(pedacos, key=lambda q: q.pos[1]):
                img = p.img.rotate(p.ang, resample=Image.BICUBIC, expand=True)
                desloc = p.pos - p.c
                x = ox + p.caixa[0] + desloc[0] - (img.width - p.img.width) / 2
                y = oy + p.caixa[1] + desloc[1] - (img.height - p.img.height) / 2
                if some < 1:
                    a = np.asarray(img).copy()
                    a[..., 3] = (a[..., 3] * some).astype(np.uint8)
                    img = Image.fromarray(a)
                camada.alpha_composite(img, (int(round(x)), int(round(y))))
            tela = ac.sobre(tela, ac.para_float(camada))
            # Explosão do cristal.
            explode = ac.pulso(t, 0.46, 0.12)
            ac.mancha(tela, ox + centro_cristal[0], oy + centro_cristal[1], 26, cor, 0.9 * explode, nitidez=1.2, aditiva=True)
            ac.mancha(tela, ox + centro_cristal[0], oy + centro_cristal[1], 9, (1, 1, 1), 0.9 * explode, nitidez=1.8, aditiva=True)
            for l in lascas:
                idade = t - 0.42
                if idade > 1.0:
                    continue
                x = ox + l[0] + l[2] * idade
                y = oy + l[1] + l[3] * idade + 0.5 * 700 * idade * idade
                y = min(y, oy + CHAO_Y + 10)
                a = (1 - idade) * (0.6 + 0.4 * math.sin(t * 35 + l[5]))
                ac.mancha(tela, x, y, l[4], cor, a, nitidez=2.0, aditiva=True)
                ac.mancha(tela, x, y, l[4] * 0.4, (1, 1, 1), a, nitidez=2.5, aditiva=True)
            if 0.42 <= t < 0.42 + dt:
                for _ in range(10):
                    a = rng.uniform(0, 2 * math.pi)
                    poeira.append([ox + base_x + math.cos(a) * 18, oy + base_y - 6 + math.sin(a) * 8, t + 0.15, rng.uniform(1.2, 1.8), 8, rng.uniform(22, 34), 0.28, math.cos(a) * 45, math.sin(a) * 16 - 8])
        # Pedrinhas e poeira.
        for pe in pedrinhas:
            idade = t - pe[4]
            if idade < 0 or idade > pe[5]:
                continue
            x = pe[0] + pe[2] * idade
            y = min(pe[1] + pe[3] * idade + 0.5 * 600 * idade * idade, pe[1] + 6)
            ac.mancha(tela, x, y, 1.6, (0.35, 0.36, 0.40), 0.9 * (1 - idade / pe[5]), nitidez=3)
        for po in poeira:
            idade = (t - po[2]) / po[3]
            if idade < 0 or idade >= 1:
                continue
            x = po[0] + po[7] * (t - po[2]) * (1 - idade * 0.6)
            y = po[1] + po[8] * (t - po[2]) * (1 - idade * 0.6)
            r = po[4] + (po[5] - po[4]) * ac.sair(idade, 2)
            a = po[6] * (1 - idade) ** 1.5 * min(1, idade * 8)
            ac.mancha(tela, x, y, r, (0.58, 0.60, 0.64), a, nitidez=1.0)
        # Fim: só a ruína, exatamente como no mapa.
        fim = ac.mais_suave(ac.faixa(t, 2.15, 2.55))
        if fim > 0:
            camada = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            camada.alpha_composite(ruina, (ox, oy))
            tela = tela * (1 - fim) + ac.para_float(camada) * fim
        quadros.append(ac.para_imagem(tela))
    camada = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    camada.alpha_composite(ruina, (ox, oy))
    quadros.append(camada)
    return quadros


if __name__ == "__main__":
    for lado in ("azul", "coral"):
        quadros = gerar(lado)
        if "--previa" in sys.argv:
            ac.salvar_gif(quadros, f"/tmp/anim/torre_{lado}_nova.gif", FPS)
            ac.folha_de_contato(quadros, f"/tmp/anim/torre_{lado}_nova_folha.png", colunas=8, passo=2)
        if "--salvar" in sys.argv:
            print(ac.empacotar(quadros, quadros[0].size, 5, 60, f"assets/animacoes/caldeira/torre_{lado}"))
        print(lado, len(quadros), "quadros", quadros[0].size)
