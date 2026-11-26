"""Surgimento do Cérbero: o chão treme, a lava corre nas rachaduras, o chão se abre e o
Cérbero sai se arrastando com as patas da frente, ruge com as três cabeças e assenta na pose
do mapa.

Uso (na raiz do projeto):  python3 tools/arte/animar_cerbero.py [--previa]
Gera assets/animacoes/caldeira/cerbero_*.webp. Com --previa, também salva GIF e folha em /tmp.
"""
from __future__ import annotations

import math
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as nd

import animacao_comum as ac

UNIDADE = 1.45            # pixels da arte do mapa por unidade do tabuleiro
ORIGEM = (598, 546)       # canto da célula no tabuleiro (unidades), igual ao atlas antigo
TAMANHO = (206, 198)      # tamanho exibido (unidades)
ESCALA = 2                # renderiza em 2x e reduz no fim
FPS = 30
DURACAO = 5.0

# Pose de descanso (pixels da arte recortada, 299 x 287).
CORPO = {"costas": (160, 52), "quadril": (205, 72), "ombro": (128, 92), "centro": (155, 115),
         "flanco": (188, 104), "pata_tras": (222, 150), "joelho_tras": (212, 118)}
CABECAS = {
    "esq": {"pescoco": (102, 108), "cabeca": (72, 124), "focinho": (50, 140), "mandibula": (60, 160)},
    "meio": {"pescoco": (128, 125), "cabeca": (112, 146), "focinho": (90, 162), "mandibula": (97, 176)},
    "frente": {"pescoco": (162, 140), "cabeca": (170, 166), "focinho": (176, 186), "mandibula": (166, 201)},
}
PATAS = {"pata_esq": (86, 194), "pata_dir": (158, 213)}
BURACO = (158, 110)       # centro da fenda (sob o corpo na pose final)
RAIOS_BURACO = (84, 34)   # fenda comprida, deitada na direção em que ele anda
DIRECAO = np.array([-0.76, 0.65], np.float32)   # para onde ele se arrasta (frente, embaixo à esquerda)
ANGULO_FENDA = math.atan2(0.65, -0.76)
DISTANCIA = 105.0          # quanto ele anda desde dentro da fenda
PASSOS = [(1.25, 1.62), (1.70, 2.07), (2.15, 2.52), (2.60, 2.97)]   # empurrões do corpo


def recortes():
    mapa = ac.carregar("assets/sprites/mapa/caldeira_glacial.webp")
    x, y = ORIGEM
    caixa = (round(x * UNIDADE), round(y * UNIDADE), round((x + TAMANHO[0]) * UNIDADE), round((y + TAMANHO[1]) * UNIDADE))
    final = mapa.crop(caixa)
    w, h = final.size
    placa = ac.carregar("assets/sprites/mapa/arena_cerbero.webp").resize((round(196 * UNIDADE), round(174 * UNIDADE)), Image.LANCZOS)
    vazio = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    vazio.alpha_composite(placa, (round(5 * UNIDADE), round(9 * UNIDADE)))
    return final, vazio


def mascara_do_cerbero(final: Image.Image, vazio: Image.Image) -> np.ndarray:
    c = np.asarray(final.convert("RGB")).astype(np.float32)
    e = np.asarray(vazio).astype(np.float32)
    dif = np.abs(c - e[..., :3]).sum(-1) * (e[..., 3] / 255)
    hsv = np.asarray(final.convert("RGB").convert("HSV")).astype(np.float32)
    v, s = hsv[..., 2], hsv[..., 1]
    escuro = ((v < 110) | ((s < 90) & (v < 150))) & (dif > 60)
    m = nd.binary_closing(escuro, iterations=3)
    m = nd.binary_opening(m, iterations=1)
    rotulos, n = nd.label(m)
    m = rotulos == (np.argmax(nd.sum(m, rotulos, range(1, n + 1))) + 1)
    # Fecha só os furos pequenos (veios de lava); o chão entre as patas fica de fora.
    furos = nd.binary_fill_holes(m) & ~m
    rf, nf = nd.label(furos)
    tamanhos = nd.sum(furos, rf, range(1, nf + 1))
    for i, t in enumerate(tamanhos, 1):
        if t < 160:
            m |= rf == i
    # Bocas e línguas (laranja e vermelho) coladas ao corpo.
    r, g = c[..., 0], c[..., 1]
    boca = (r > 150) & (g < 120) & (s > 140) & nd.binary_dilation(m, iterations=6)
    # Veios de lava no lombo: laranja forte e muito saturado (o piso é bege, menos saturado).
    veio = (s > 165) & (v > 140) & nd.binary_dilation(m, iterations=8)
    # Chifres e espinhos: cinza claro, quase sem saturação.
    espinho = (s < 70) & (v > 90) & nd.binary_dilation(m, iterations=4)
    m |= boca | veio | espinho
    # Fecha frestas estreitas (o veio do lombo é uma faixa vermelho-escura que encosta na borda).
    fechado = nd.binary_closing(np.pad(m, 8), iterations=5)[8:-8, 8:-8]
    m |= fechado & (r > g * 1.15)
    m = nd.binary_closing(m, iterations=1)
    suave = ac.desfocar(m.astype(np.float32), 0.7)
    return np.clip(suave * 1.15, 0, 1)


def distancia_fenda(forma, centro, raios):
    h, w = forma
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    x, y = xx - centro[0], yy - centro[1]
    c, s = math.cos(ANGULO_FENDA), math.sin(ANGULO_FENDA)
    ao_longo = x * c + y * s
    atravessado = -x * s + y * c
    # Um pouco irregular, para parecer chão rachado e não uma elipse perfeita.
    ondula = 1 + 0.08 * np.sin(ao_longo * 0.09 + 1.3) + 0.05 * np.sin(ao_longo * 0.23)
    return np.sqrt((ao_longo / raios[0]) ** 2 + (atravessado / (raios[1] * ondula)) ** 2)


def mapa_de_rachaduras(vazio: np.ndarray) -> np.ndarray:
    """Linhas escuras e finas do piso da arena (onde a lava vai correr). Parede e borda ficam de fora."""
    alfa = vazio[..., 3]
    rgb = vazio[..., :3] / np.maximum(alfa[..., None], 1e-4)
    lum = rgb.mean(-1)
    local = ac.desfocar(lum, 3.0 * ESCALA)
    linhas = np.clip((local - lum) * 7.0 - 0.1, 0, 1)
    piso = (ac.desfocar(lum, 6 * ESCALA) > 0.45) & (alfa > 0.98)
    piso = nd.binary_erosion(piso, iterations=4 * ESCALA)
    return ac.desfocar(linhas * piso, 0.6)


class Pedra:
    def __init__(self, rng, centro, raios):
        a = rng.uniform(0, 2 * math.pi)
        c, s = math.cos(ANGULO_FENDA), math.sin(ANGULO_FENDA)
        lx, ly = math.cos(a) * raios[0] * rng.uniform(0.3, 1.0), math.sin(a) * raios[1] * rng.uniform(0.6, 1.0)
        self.x = centro[0] + lx * c - ly * s
        self.y = centro[1] + lx * s + ly * c
        velocidade = rng.uniform(40, 120) * ESCALA
        self.vx = math.cos(a) * velocidade
        self.vy = math.sin(a) * velocidade * 0.6
        self.z = 0.0
        self.vz = rng.uniform(90, 230) * ESCALA
        self.tam = rng.uniform(1.6, 4.2) * ESCALA
        self.giro = rng.uniform(-9, 9)
        self.ang = rng.uniform(0, 6.28)
        n = rng.integers(5, 8)
        self.forma = [(math.cos(2 * math.pi * k / n + rng.uniform(-0.3, 0.3)) * rng.uniform(0.7, 1.15),
                       math.sin(2 * math.pi * k / n + rng.uniform(-0.3, 0.3)) * rng.uniform(0.7, 1.15)) for k in range(n)]
        self.cor = tuple(int(v) for v in (rng.uniform(70, 110), rng.uniform(45, 65), rng.uniform(35, 50)))
        self.brasa = rng.uniform() < 0.35
        self.repouso = False

    def avancar(self, dt):
        if self.repouso:
            return
        g = 520 * ESCALA
        self.vz -= g * dt
        self.x += self.vx * dt
        self.y += self.vy * dt
        self.z += self.vz * dt
        self.ang += self.giro * dt
        if self.z < 0:
            self.z = 0
            if abs(self.vz) > 60 * ESCALA:
                self.vz = -self.vz * 0.3
                self.vx *= 0.5
                self.vy *= 0.5
                self.giro *= 0.5
            else:
                self.repouso = True


def desenhar_pedras(forma, pedras, opacidade, calor):
    h, w = forma
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for p in pedras:
        sx, sy = p.x, p.y - p.z
        ca, sa = math.cos(p.ang), math.sin(p.ang)
        pts = [(sx + (fx * ca - fy * sa) * p.tam, sy + (fx * sa + fy * ca) * p.tam * 0.8) for fx, fy in p.forma]
        if p.z > 0.5:
            sombra = [(x + 0.0, y + p.z) for x, y in pts]
            d.polygon(sombra, fill=(10, 6, 4, int(70 * opacidade)))
        cor = p.cor
        if p.brasa:
            q = calor
            cor = tuple(int(c * (1 - q) + b * q) for c, b in zip(cor, (255, 120, 40)))
        d.polygon(pts, fill=cor + (int(255 * opacidade),))
        topo = pts[: max(2, len(pts) // 2)]
        if len(topo) >= 2:
            d.line(topo, fill=(min(255, cor[0] + 60), min(255, cor[1] + 45), min(255, cor[2] + 35), int(200 * opacidade)), width=1)
    return ac.para_float(img)


def posar(t, ruido):
    """Posição de cada alça no tempo t (pixels da arte em escala 1)."""
    # Progresso do corpo: empurrões com pausa entre eles.
    andado = 0.0
    for i, (a, b) in enumerate(PASSOS):
        andado += ac.mais_suave(ac.faixa(t, a, b)) / len(PASSOS)
    deslocamento = -DIRECAO * DISTANCIA * (1 - andado)
    # Levantar no rugido e assentar com peso.
    ergue = ac.sair(ac.faixa(t, 3.0, 3.35)) * (1 - ac.mola(ac.faixa(t, 3.75, 4.45)))
    escala = 1 + 0.045 * ergue
    sobe = np.array([0, -5.0 * ergue])
    # Respiração ofegante durante o arrasto.
    arfar = math.sin(t * 9.0) * 1.2 * ac.faixa(t, 1.1, 1.4) * (1 - ac.faixa(t, 2.95, 3.2))
    centro = np.array(CORPO["centro"], np.float32)

    def corpo(p, extra=(0, 0)):
        p = np.array(p, np.float32)
        p = centro + (p - centro) * escala
        return p + deslocamento + sobe + np.array(extra, np.float32) + np.array([0, arfar * 0.4])

    alcas, nomes = [], []
    for nome, p in CORPO.items():
        extra = (0, 0)
        if nome in ("ombro", "centro"):
            # O ombro afunda a cada empurrão, como quem puxa o peso.
            empurra = sum(ac.pulso(t, (a + b) / 2, (b - a)) for a, b in PASSOS)
            extra = (0, 2.5 * empurra)
        alcas.append(corpo(p, extra))
        nomes.append(nome)

    # Patas: a da frente do passo estica e sobe antes do empurrão; durante o empurrão fica cravada.
    passo_len = DISTANCIA / len(PASSOS)
    for nome, p in PATAS.items():
        rel = np.zeros(2, np.float32)
        for i, (a, b) in enumerate(PASSOS):
            vez = "pata_esq" if i % 2 == 0 else "pata_dir"
            if nome != vez:
                continue
            alcance = ac.suave(ac.faixa(t, a - 0.24, a + 0.02))       # estica
            cravada = ac.mais_suave(ac.faixa(t, a, b))                 # corpo alcança a pata
            frente = 0.55 * passo_len * alcance * (1 - cravada)
            levanta = math.sin(math.pi * ac.faixa(t, a - 0.24, a + 0.04)) * 9.0
            rel += DIRECAO * frente + np.array([0, -levanta])
        # Patada no chão durante o rugido (as duas pisam forte).
        pisa = ac.pulso(t, 3.2, 0.25) * 4.0
        rel += np.array([0, -pisa]) * (1 if nome == "pata_esq" else 0.6)
        alcas.append(corpo(p) + rel)
        nomes.append(nome)

    # Cabeças: baixas e inquietas no arrasto; recuam, sobem e avançam no rugido; boca abre.
    preparo = ac.suave(ac.faixa(t, 2.95, 3.2)) * (1 - ac.faixa(t, 3.2, 3.32))
    rugido = ac.sair(ac.faixa(t, 3.18, 3.34)) * (1 - ac.suave(ac.faixa(t, 3.8, 4.35)))
    arrasto = ac.faixa(t, 1.0, 1.3) * (1 - ac.faixa(t, 2.9, 3.2))
    for k, (nome, cab) in enumerate(CABECAS.items()):
        fase = k * 2.1
        pivo = corpo(cab["pescoco"])
        angulo = (0.10 * math.sin(t * 5.3 + fase) + 0.06) * arrasto        # balança e olha para baixo
        angulo += -0.30 * preparo + 0.10 * rugido                           # joga para trás, depois para frente
        atraso = (0.0, 0.03, 0.06)[k]
        tremor = ruido[k] * 1.6 * ac.pulso(t, 3.5 + atraso, 0.45)
        translado = DIRECAO * (8.0 * rugido - 8.0 * preparo) + np.array([tremor, -15.0 * preparo - 4.0 * rugido])
        translado += np.array([0, 5.0 * arrasto])
        boca = rugido * (7.0 if nome != "frente" else 4.5) + preparo * 1.5
        ca, sa = math.cos(angulo), math.sin(angulo)
        for parte, p in cab.items():
            if parte == "pescoco":
                alcas.append(pivo)
                nomes.append(f"{nome}_{parte}")
                continue
            q = corpo(p) - pivo
            q = np.array([q[0] * ca - q[1] * sa, q[0] * sa + q[1] * ca])
            q = pivo + q + translado
            if parte == "mandibula":
                direcao_boca = np.array([0.35, 1.0])
                q = q + direcao_boca / np.linalg.norm(direcao_boca) * boca
            alcas.append(q)
            nomes.append(f"{nome}_{parte}")
    return np.array(alcas, np.float32), nomes, deslocamento, andado


def descanso():
    alcas = [CORPO[n] for n in CORPO] + [PATAS[n] for n in PATAS]
    for cab in CABECAS.values():
        alcas += [cab[p] for p in cab]
    return np.array(alcas, np.float32)


def tremor_da_tela(t, rng_quadro):
    forca = 0.6 * ac.faixa(t, 0.3, 0.9) * (1 - ac.faixa(t, 0.9, 1.0))
    forca += 2.4 * math.exp(-max(0, t - 0.9) * 7) * (t >= 0.9)
    for a, b in PASSOS:
        forca += 1.0 * math.exp(-max(0, t - b) * 12) * (t >= b - 0.02)
    forca += 3.0 * math.exp(-max(0, t - 3.22) * 4.5) * (t >= 3.2)
    return rng_quadro.normal(0, 1, 2) * forca * ESCALA


def gerar(previa=False):
    final_img, vazio_img = recortes()
    w0, h0 = final_img.size
    W, H = w0 * ESCALA, h0 * ESCALA
    final = ac.para_float(final_img.resize((W, H), Image.LANCZOS))
    vazio = ac.para_float(vazio_img.resize((W, H), Image.LANCZOS))
    mascara = mascara_do_cerbero(final_img, vazio_img)
    mascara = np.clip(np.asarray(Image.fromarray((mascara * 255).astype(np.uint8)).resize((W, H), Image.LANCZOS)) / 255.0, 0, 1).astype(np.float32)
    bicho = ac.com_alfa(final, mascara)
    oval = vazio[..., 3].copy()
    # Cena opaca o tempo todo; o oval só recorta no fim (sem bordas coloridas).
    opaco = vazio[..., :3] / np.maximum(vazio[..., 3:4], 1e-4)
    media = (opaco * (oval[..., None] > 0.99)).sum((0, 1)) / max(1, (oval > 0.99).sum())
    preenchido = np.where(oval[..., None] > 0.02, opaco, media[None, None, :])
    vazio = np.concatenate([preenchido, np.ones_like(oval)[..., None]], -1).astype(np.float32)
    final = np.concatenate([final[..., :3] / np.maximum(final[..., 3:4], 1e-4), np.ones_like(oval)[..., None]], -1).astype(np.float32)
    rachaduras = mapa_de_rachaduras(vazio)
    deformador = ac.Deformador(bicho, descanso() * ESCALA, alfa=1.5, passo=2)
    # Veios de lava do próprio desenho (laranja forte), para acender no rugido.
    hsv = np.asarray(Image.fromarray((final[..., :3] * 255).astype(np.uint8)).convert("HSV")).astype(np.float32)
    veios_base = np.clip((hsv[..., 1] - 150) / 60, 0, 1) * np.clip((hsv[..., 2] - 140) / 60, 0, 1) * mascara
    veios_base = ac.desfocar(veios_base, 0.8)

    rng = np.random.default_rng(7)
    pedras = [Pedra(rng, (BURACO[0] * ESCALA, BURACO[1] * ESCALA), (RAIOS_BURACO[0] * ESCALA, RAIOS_BURACO[1] * ESCALA)) for _ in range(30)]
    pedras_soltas = False
    poeira = []    # [x, y, nasce, vida, raio0, raio1, alfa, vx, vy]
    brasas = []    # [x, y, nasce, vida, vx, vy, tam]

    def soltar_poeira(cx, cy, n, espalha, raio, alfa, t, vida=1.2, sobe=0.0):
        for _ in range(n):
            a = rng.uniform(0, 2 * math.pi)
            d = rng.uniform(0.3, 1.0) * espalha
            poeira.append([cx + math.cos(a) * d * ESCALA, cy + math.sin(a) * d * 0.6 * ESCALA, t, vida * rng.uniform(0.7, 1.3),
                           raio * 0.5 * ESCALA, raio * rng.uniform(1.0, 1.8) * ESCALA, alfa * rng.uniform(0.6, 1.0),
                           math.cos(a) * 14 * ESCALA, math.sin(a) * 8 * ESCALA - sobe * ESCALA])

    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    quadros = []
    n_quadros = int(DURACAO * FPS)
    ruido_cabecas = rng.normal(0, 1, (n_quadros + 2, 3))
    passos_feitos = set()
    dt = 1.0 / FPS
    for i in range(n_quadros):
        t = i / FPS
        rq = np.random.default_rng(1000 + i)
        # --- tempo das peças -------------------------------------------------------------
        abertura = ac.sair(ac.faixa(t, 0.86, 1.18), 2.4) * (1 - ac.mais_suave(ac.faixa(t, 3.55, 4.4)))
        raios = (RAIOS_BURACO[0] * ESCALA * abertura, RAIOS_BURACO[1] * ESCALA * abertura)
        centro_b = (BURACO[0] * ESCALA, BURACO[1] * ESCALA)
        calor = ac.faixa(t, 0.25, 0.9) * (1 - 0.45 * ac.faixa(t, 2.9, 3.6)) * (1 - ac.faixa(t, 3.9, 4.6))
        frente_lava = ac.sair(ac.faixa(t, 0.25, 1.05)) * 120 * ESCALA
        mistura_final = ac.mais_suave(ac.faixa(t, 4.25, 4.95))

        # --- chão: rachaduras acesas e buraco ---------------------------------------------
        fundo = vazio.copy()
        dist = np.sqrt(((xx - centro_b[0])) ** 2 + ((yy - centro_b[1]) / 0.6) ** 2)
        onda = np.clip((frente_lava - dist) / (30 * ESCALA), 0, 1)
        pulso_lava = 0.75 + 0.25 * math.sin(t * 13)
        brilho_rachadura = rachaduras * onda * calor * pulso_lava * 0.75
        fundo = ac.luz(fundo, (1.4, 0.55, 0.12), brilho_rachadura)
        fundo = ac.luz(fundo, (0.7, 0.26, 0.04), ac.desfocar(brilho_rachadura, 2.5 * ESCALA) * 0.4)
        if abertura > 0.01:
            d = distancia_fenda((H, W), centro_b, (max(raios[0], 1), max(raios[1], 1)))
            dentro = np.clip((1 - d) * min(raios) / 1.5, 0, 1)
            borda = np.exp(-((d - 1.0) / 0.06) ** 2) * (d < 1.25)
            esfria = ac.faixa(t, 3.5, 4.3)
            poco = np.zeros_like(fundo)
            fundo_poco = np.array([0.07, 0.025, 0.015]) * (1 - esfria) + np.array([0.20, 0.13, 0.10]) * esfria
            luz_fundo = np.clip(1 - d * 1.15, 0, 1) ** 1.4 * (1 - esfria)
            cor = fundo_poco[None, None, :] + np.array([0.75, 0.22, 0.03])[None, None, :] * (luz_fundo[..., None] * 0.45)
            poco[..., :3] = cor * dentro[..., None]
            poco[..., 3] = dentro
            fundo = ac.sobre(fundo, poco)
            fundo = ac.luz(fundo, (1.2, 0.5, 0.1), borda * (1 - esfria) * 0.8)
            fundo = ac.luz(fundo, (0.8, 0.30, 0.04), ac.desfocar(borda, 3 * ESCALA) * (1 - esfria) * 0.35 * abertura)

        # --- Cérbero ----------------------------------------------------------------------
        alcas, nomes, desloc, andado = posar(t, ruido_cabecas[i])
        camada, (veios,) = deformador.deformar(alcas * ESCALA, extras=(veios_base,))
        # Acima do chão: à frente da borda do buraco, ou já fora dele.
        s = (xx - centro_b[0]) * DIRECAO[0] + (yy - centro_b[1]) * DIRECAO[1]
        if abertura > 0.01:
            d = distancia_fenda((H, W), centro_b, (max(raios[0], 1), max(raios[1], 1)))
            no_poco = np.clip((1 - d) * 25, 0, 1)
        else:
            no_poco = np.zeros((H, W), np.float32)
        # Quem ainda está atrás da borda vai aparecendo aos poucos, escuro, como quem sai da terra.
        acima = np.clip(1 + s / (26 * ESCALA), 0, 1) * (abertura > 0.01)
        saiu = ac.suave(ac.faixa(t, 2.85, 3.25))
        visivel = np.clip(np.maximum(acima, no_poco), 0, 1) * ac.faixa(t, 0.95, 1.05)
        visivel = visivel * (1 - saiu) + saiu
        profundidade = np.clip(-s / (30 * ESCALA), 0, 1) * (1 - saiu)
        camada = ac.com_alfa(camada, visivel)
        # Dentro do poço: escuro, com luz de lava vindo de baixo.
        camada[..., :3] *= (1 - 0.7 * profundidade)[..., None]
        camada = ac.luz(camada, (0.8, 0.30, 0.05), profundidade * 0.45 + np.clip(1 - np.abs(s) / (8 * ESCALA), 0, 1) * (1 - saiu) * 0.18 * (abertura > 0.01))
        # Brasa nos veios quando ruge.
        rugido = ac.pulso(t, 3.4, 0.6)
        camada = ac.luz(camada, (1.0, 0.45, 0.10), veios * visivel * (0.2 + 0.7 * rugido))
        camada = ac.luz(camada, (0.6, 0.22, 0.03), ac.desfocar(veios, 2 * ESCALA) * visivel * 0.5 * rugido)
        # Sombra no chão.
        sombra_alfa = ac.desfocar(deslocar_alfa(camada[..., 3], 3 * ESCALA, 5 * ESCALA), 3 * ESCALA) * 0.32 * (1 - mistura_final)
        fundo[..., :3] *= (1 - sombra_alfa * (1 - no_poco))[..., None]
        cena = ac.sobre(fundo, camada)

        # Luz das bocas no rugido.
        bocas = [n for n in nomes if n.endswith("_mandibula")]
        for nb in bocas:
            j = nomes.index(nb)
            fx, fy = alcas[j] * ESCALA
            ac.mancha(cena, fx, fy - 6 * ESCALA, 4 * ESCALA, (0.9, 0.45, 0.12), 0.25 * rugido, nitidez=2.0, aditiva=True)

        # --- partículas -------------------------------------------------------------------
        if t >= 0.9 and not pedras_soltas:
            pedras_soltas = True
            soltar_poeira(BURACO[0], BURACO[1], 26, 40, 13, 0.55, t, vida=1.6, sobe=10)
        if pedras_soltas:
            for p in pedras:
                p.avancar(dt)
            some = 1 - ac.faixa(t, 2.6, 3.6)
            cena = ac.sobre(cena, ac.com_alfa(desenhar_pedras((H, W), pedras, 1.0, calor), np.ones((H, W), np.float32) * some))
        for k, (a, b) in enumerate(PASSOS):
            if t >= b - 0.03 and k not in passos_feitos:
                passos_feitos.add(k)
                nome = "pata_esq" if k % 2 == 0 else "pata_dir"
                j = nomes.index(nome)
                soltar_poeira(alcas[j][0], alcas[j][1], 7, 9, 7, 0.45, t, vida=0.9, sobe=6)
        if 3.2 <= t < 3.2 + dt:
            for nome in ("pata_esq", "pata_dir"):
                j = nomes.index(nome)
                soltar_poeira(alcas[j][0], alcas[j][1], 10, 14, 9, 0.5, t, vida=1.1, sobe=8)
        if 3.95 <= t < 3.95 + dt:
            soltar_poeira(CORPO["centro"][0], CORPO["centro"][1] + 30, 16, 60, 12, 0.35, t, vida=1.3, sobe=4)
        # Brasas: saem das rachaduras e do buraco; jorro das bocas no rugido.
        taxa = 3 * calor + 10 * ac.pulso(t, 1.0, 0.3) + 14 * ac.pulso(t, 3.35, 0.35)
        for _ in range(rq.poisson(taxa)):
            if t > 3.15 and rq.uniform() < 0.7:
                j = nomes.index(rq.choice(bocas))
                bx, by = alcas[j]
                ang = rq.uniform(-2.6, -0.5)
                vel = rq.uniform(30, 90)
                brasas.append([bx * ESCALA, by * ESCALA, t, rq.uniform(0.5, 1.1), math.cos(ang) * vel * ESCALA, math.sin(ang) * vel * ESCALA, rq.uniform(0.8, 1.6) * ESCALA])
            else:
                a = rq.uniform(0, 2 * math.pi)
                r = rq.uniform(0, 1)
                bx = BURACO[0] + math.cos(a) * RAIOS_BURACO[0] * r * max(abertura, 0.6)
                by = BURACO[1] + math.sin(a) * RAIOS_BURACO[1] * r * max(abertura, 0.6)
                brasas.append([bx * ESCALA, by * ESCALA, t, rq.uniform(0.7, 1.5), rq.uniform(-8, 8) * ESCALA, rq.uniform(-45, -20) * ESCALA, rq.uniform(0.7, 1.4) * ESCALA])
        vivas = []
        for b in brasas:
            idade = (t - b[2]) / b[3]
            if idade >= 1:
                continue
            vivas.append(b)
            x = b[0] + b[4] * (t - b[2])
            y = b[1] + b[5] * (t - b[2]) + 30 * ESCALA * (t - b[2]) ** 2 * 0.3
            cintila = 0.6 + 0.4 * math.sin(t * 40 + b[0])
            ac.mancha(cena, x, y, b[6] * 1.6, (1.0, 0.55, 0.15), (1 - idade) * cintila * 0.9, nitidez=2.0, aditiva=True)
            ac.mancha(cena, x, y, b[6] * 0.6, (1.0, 0.9, 0.6), (1 - idade) * cintila, nitidez=2.5, aditiva=True)
        brasas = vivas
        vivas = []
        for p in poeira:
            idade = (t - p[2]) / p[3]
            if idade < 0 or idade >= 1:
                if idade < 1:
                    vivas.append(p)
                continue
            vivas.append(p)
            x = p[0] + p[7] * (t - p[2]) * (1 - idade * 0.5)
            y = p[1] + p[8] * (t - p[2]) * (1 - idade * 0.5)
            r = p[4] + (p[5] - p[4]) * ac.sair(idade, 2)
            a = p[6] * (1 - idade) ** 1.6 * min(1, idade * 6)
            ac.mancha(cena, x, y, r, (0.62, 0.50, 0.42), a, nitidez=1.1)
        poeira = vivas

        # --- onda de choque do rugido -------------------------------------------------------
        if 3.2 <= t <= 3.95:
            k = (t - 3.2) / 0.75
            j = nomes.index("frente_mandibula")
            cx, cy = alcas[j] * ESCALA
            raio = ac.sair(k, 2) * 175 * ESCALA
            d = np.sqrt((xx - cx) ** 2 + ((yy - cy) / 0.62) ** 2)
            anel = np.exp(-((d - raio) / (7 * ESCALA)) ** 2) * (1 - k)
            # Refração: empurra o que está atrás do anel.
            desloca = anel * 2.2 * ESCALA
            ang_x = (xx - cx) / np.maximum(d, 1)
            ang_y = (yy - cy) / np.maximum(d, 1) * 0.62
            refratada = np.empty_like(cena)
            for canal in range(4):
                refratada[..., canal] = nd.map_coordinates(cena[..., canal], [yy - ang_y * desloca, xx - ang_x * desloca], order=1, mode="nearest")
            cena = refratada
            cena = ac.luz(cena, (1.0, 0.8, 0.55), anel * 0.22)

        # --- tremor e acabamento ------------------------------------------------------------
        dx, dy = tremor_da_tela(t, rq)
        cena = nd.shift(cena, (dy, dx, 0), order=1, mode="nearest")
        if mistura_final > 0:
            cena = cena * (1 - mistura_final) + final * mistura_final
        cena = np.clip(cena, 0, 1)
        cena[..., 3] = 1.0
        cena = ac.com_alfa(cena, oval)
        quadro = ac.para_imagem(cena).resize((w0, h0), Image.LANCZOS)
        quadros.append(quadro)
        if i % 15 == 0:
            print(f"  quadro {i}/{n_quadros}", flush=True)
    # Último quadro exatamente igual à arte do mapa recortada no oval.
    ultimo = ac.para_float(final_img)
    ultimo = ac.com_alfa(ultimo, np.asarray(vazio_img)[..., 3].astype(np.float32) / 255)
    quadros.append(ac.para_imagem(ultimo))
    return quadros


def deslocar_alfa(a, dx, dy):
    return nd.shift(a, (dy, dx), order=1, mode="constant", cval=0.0)


if __name__ == "__main__":
    previa = "--previa" in sys.argv
    quadros = gerar(previa)
    if previa:
        ac.salvar_gif(quadros, "/tmp/anim/cerbero_novo.gif", FPS)
        ac.folha_de_contato(quadros, "/tmp/anim/cerbero_novo_folha.png", colunas=8, passo=4)
        for i, q in enumerate(quadros):
            q.save(f"/tmp/anim/cerbero_novo_{i:03d}.png")
    if "--salvar" in sys.argv:
        print(ac.empacotar(quadros, quadros[0].size, 6, 78, "assets/animacoes/caldeira/cerbero"))
    print(len(quadros), "quadros", quadros[0].size)
