"""Ferramentas comuns para gerar as animações da Caldeira Glacial em quadros.

As animações são desenhadas quadro a quadro a partir da arte aprovada do mapa:
- deformação "rígida por mínimos quadrados" (MLS) para mexer patas, cabeças e corpo
  sem redesenhar o bicho;
- partículas (brasas, poeira, respingos, lascas), luz, tremor e onda de choque;
- empacotamento no mesmo formato de atlas que ui/partida/animacao_atlas.gd lê.

Tudo em float premultiplicado (RGBA de 0 a 1). Mesma semente, mesmos quadros.
"""
from __future__ import annotations

import math
import os

import numpy as np
from PIL import Image
from scipy import ndimage as nd

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


# --- Curvas de tempo --------------------------------------------------------------

def limitar(x, a=0.0, b=1.0):
    return max(a, min(b, x))


def suave(x):
    x = limitar(x)
    return x * x * (3 - 2 * x)


def mais_suave(x):
    x = limitar(x)
    return x * x * x * (x * (x * 6 - 15) + 10)


def sair(x, p=3.0):
    x = limitar(x)
    return 1 - (1 - x) ** p


def entrar(x, p=3.0):
    return limitar(x) ** p


def faixa(t, a, b):
    """0 antes de a, 1 depois de b, linear entre."""
    if b <= a:
        return 1.0 if t >= b else 0.0
    return limitar((t - a) / (b - a))


def mola(x, amortecimento=6.0, frequencia=2.2):
    """Vai de 0 a 1 passando um pouco do ponto e voltando (assentar com peso)."""
    x = limitar(x)
    return 1 - math.exp(-amortecimento * x) * math.cos(frequencia * math.pi * x)


def pulso(t, centro, largura):
    """Sino de 0 a 1 a 0 em torno de centro."""
    d = (t - centro) / max(largura, 1e-6)
    return math.exp(-d * d * 4)


# --- Imagens ------------------------------------------------------------------------

def carregar(caminho):
    return Image.open(os.path.join(RAIZ, caminho)).convert("RGBA")


def para_float(img: Image.Image) -> np.ndarray:
    a = np.asarray(img.convert("RGBA")).astype(np.float32) / 255.0
    a[..., :3] *= a[..., 3:4]
    return a


def para_imagem(a: np.ndarray) -> Image.Image:
    a = np.clip(a, 0, 1)
    alfa = a[..., 3:4]
    # Luz somada não pode passar do alfa (senão a cor estoura ao desfazer o premultiplicado).
    a = np.concatenate([np.minimum(a[..., :3], alfa), alfa], -1)
    rgb = np.where(alfa > 1e-4, a[..., :3] / np.maximum(alfa, 1e-4), 0)
    saida = np.concatenate([rgb, alfa], -1)
    return Image.fromarray((saida * 255 + 0.5).astype(np.uint8), "RGBA")


def sobre(fundo, frente):
    """Composição 'over' premultiplicada."""
    return frente + fundo * (1 - frente[..., 3:4])


def com_alfa(camada, mascara):
    return camada * mascara[..., None]


def deslocar(a, dx, dy, ordem=1):
    if abs(dx) < 1e-3 and abs(dy) < 1e-3:
        return a
    return nd.shift(a, (dy, dx, 0), order=ordem, mode="constant", cval=0.0)


def desfocar(a, sigma):
    if sigma <= 0:
        return a
    if a.ndim == 3:
        return nd.gaussian_filter(a, (sigma, sigma, 0))
    return nd.gaussian_filter(a, sigma)


def luz(a, rgb, mapa):
    """Soma luz emissiva (premultiplicada) onde mapa > 0, sem mexer no alfa além do necessário."""
    cor = np.asarray(rgb, np.float32)[None, None, :] * mapa[..., None]
    saida = a.copy()
    saida[..., :3] = saida[..., :3] + cor * saida[..., 3:4]
    return saida


def brilho_somado(a, rgb, mapa):
    """Luz que também cria alfa (halo fora do objeto)."""
    m = np.clip(mapa, 0, None)
    cor = np.asarray(rgb, np.float32)[None, None, :] * m[..., None]
    saida = a.copy()
    saida[..., :3] += cor
    saida[..., 3] = np.clip(saida[..., 3] + np.clip(m, 0, 1) * (1 - saida[..., 3]), 0, 1)
    return saida


def elipse(forma, centro, raios, borda=1.5, angulo=0.0):
    h, w = forma
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    x = xx - centro[0]
    y = yy - centro[1]
    if angulo:
        c, s = math.cos(angulo), math.sin(angulo)
        x, y = c * x + s * y, -s * x + c * y
    r = np.sqrt((x / max(raios[0], 1e-3)) ** 2 + (y / max(raios[1], 1e-3)) ** 2)
    escala = min(raios) if min(raios) > 0 else 1
    return np.clip((1 - r) * escala / borda, 0, 1)


def distancia_eliptica(forma, centro, raios):
    h, w = forma
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    return np.sqrt(((xx - centro[0]) / raios[0]) ** 2 + ((yy - centro[1]) / raios[1]) ** 2)


# --- Deformação rígida por mínimos quadrados (Schaefer et al., 2006) -----------

class Deformador:
    """Leva uma camada da pose de descanso para uma pose nova.

    alcas_descanso: pontos de controle na arte original.
    A cada quadro, passe as mesmas alças nas posições novas; devolve a camada deformada.
    O cálculo é inverso (de cada pixel de saída para a arte de origem), sem buracos.
    """

    def __init__(self, camada: np.ndarray, alcas_descanso, alfa=1.6, passo=2):
        self.camada = camada
        self.p = np.asarray(alcas_descanso, np.float32)
        self.alfa = alfa
        h, w = camada.shape[:2]
        self.forma = (h, w)
        self.passo = passo
        ys = np.arange(0, h + passo, passo, dtype=np.float32)
        xs = np.arange(0, w + passo, passo, dtype=np.float32)
        self.gx, self.gy = np.meshgrid(xs, ys)

    def _mapa(self, q):
        # Inverso: controle nas posições novas (q) leva às posições de descanso (p).
        controle = np.asarray(q, np.float32)
        alvo = self.p
        v = np.stack([self.gx.ravel(), self.gy.ravel()], -1)  # (N, 2)
        d = v[:, None, :] - controle[None, :, :]
        w = 1.0 / np.maximum((d ** 2).sum(-1), 1e-2) ** self.alfa  # (N, K)
        sw = w.sum(1, keepdims=True)
        p_est = (w[..., None] * controle[None]).sum(1) / sw
        q_est = (w[..., None] * alvo[None]).sum(1) / sw
        ph = controle[None] - p_est[:, None, :]
        qh = alvo[None] - q_est[:, None, :]
        vp = v - p_est
        # fr = sum w * [qh . (ph, -ph_perp)] aplicado a (vp, -vp_perp)
        ph_perp = np.stack([-ph[..., 1], ph[..., 0]], -1)
        vp_perp = np.stack([-vp[:, 1], vp[:, 0]], -1)
        a = (ph * vp[:, None, :]).sum(-1)
        b = (ph * (-vp_perp)[:, None, :]).sum(-1)
        c = ((-ph_perp) * vp[:, None, :]).sum(-1)
        d2 = ((-ph_perp) * (-vp_perp)[:, None, :]).sum(-1)
        fx = (w * (qh[..., 0] * a + qh[..., 1] * c)).sum(1)
        fy = (w * (qh[..., 0] * b + qh[..., 1] * d2)).sum(1)
        norma = np.sqrt(fx * fx + fy * fy) + 1e-6
        lv = np.sqrt((vp ** 2).sum(-1))
        sx = lv * fx / norma + q_est[:, 0]
        sy = lv * fy / norma + q_est[:, 1]
        h, w_ = self.gx.shape
        return sx.reshape(h, w_), sy.reshape(h, w_)

    def deformar(self, q, extras=()):
        """Deforma a camada; 'extras' são mapas 2D (ex.: brilho dos veios) que seguem o mesmo movimento."""
        sx, sy = self._mapa(q)
        h, w = self.forma
        # Amplia a grade grossa para cada pixel.
        yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
        gy = yy / self.passo
        gx = xx / self.passo
        mx = nd.map_coordinates(sx, [gy, gx], order=1, mode="nearest")
        my = nd.map_coordinates(sy, [gy, gx], order=1, mode="nearest")
        saida = np.empty_like(self.camada)
        for canal in range(4):
            saida[..., canal] = nd.map_coordinates(self.camada[..., canal], [my, mx], order=1, mode="constant", cval=0.0)
        if not extras:
            return saida
        return saida, [nd.map_coordinates(e, [my, mx], order=1, mode="constant", cval=0.0) for e in extras]


# --- Partículas -----------------------------------------------------------------------

def mancha(tela, x, y, raio, rgb, alfa, nitidez=2.2, aditiva=False):
    """Desenha uma mancha suave (gaussiana) em tela (premultiplicada)."""
    if alfa <= 0.002 or raio <= 0.05:
        return
    h, w = tela.shape[:2]
    alcance = int(math.ceil(raio * 2.5)) + 1
    x0, x1 = max(0, int(x) - alcance), min(w, int(x) + alcance + 1)
    y0, y1 = max(0, int(y) - alcance), min(h, int(y) + alcance + 1)
    if x0 >= x1 or y0 >= y1:
        return
    yy, xx = np.mgrid[y0:y1, x0:x1].astype(np.float32)
    d2 = ((xx - x) ** 2 + (yy - y) ** 2) / max(raio * raio, 1e-4)
    m = np.exp(-d2 * nitidez) * alfa
    cor = np.asarray(rgb, np.float32)
    regiao = tela[y0:y1, x0:x1]
    if aditiva:
        regiao[..., :3] += cor * m[..., None]
        regiao[..., 3] = np.clip(regiao[..., 3] + m * 0.6 * (1 - regiao[..., 3]), 0, 1)
    else:
        frente = np.concatenate([cor * m[..., None], m[..., None]], -1)
        tela[y0:y1, x0:x1] = frente + regiao * (1 - m[..., None])


def poligono_mascara(forma, pontos):
    from PIL import ImageDraw
    h, w = forma
    img = Image.new("L", (w, h), 0)
    ImageDraw.Draw(img).polygon([tuple(p) for p in pontos], fill=255)
    return np.asarray(img).astype(np.float32) / 255.0


# --- Atlas ----------------------------------------------------------------------------

def empacotar(quadros, celula, colunas, por_pagina, prefixo, qualidade=88):
    """Salva os quadros em páginas no formato lido por animacao_atlas.gd.

    Cada célula fica em (coluna * (L + 4) + 2, linha * (A + 4) + 2), com a borda repetida
    nos 2 px de margem para o filtro linear não puxar cor da vizinha.
    """
    largura, altura = celula
    paginas = []
    for inicio in range(0, len(quadros), por_pagina):
        lote = quadros[inicio:inicio + por_pagina]
        linhas = math.ceil(len(lote) / colunas)
        pagina = np.zeros((linhas * (altura + 4), colunas * (largura + 4), 4), np.uint8)
        for i, quadro in enumerate(lote):
            arr = np.asarray(quadro.convert("RGBA"))
            com_margem = np.pad(arr, ((2, 2), (2, 2), (0, 0)), mode="edge")
            # A margem repete a cor, mas sem opacidade, para não criar contorno.
            com_margem[:2, :, 3] = 0
            com_margem[-2:, :, 3] = 0
            com_margem[:, :2, 3] = 0
            com_margem[:, -2:, 3] = 0
            c, l = i % colunas, i // colunas
            pagina[l * (altura + 4):(l + 1) * (altura + 4), c * (largura + 4):(c + 1) * (largura + 4)] = com_margem
        caminho = os.path.join(RAIZ, f"{prefixo}_{len(paginas)}.webp")
        Image.fromarray(pagina, "RGBA").save(caminho, "WEBP", quality=qualidade, method=6, alpha_quality=90)
        paginas.append(caminho)
    return paginas


def folha_de_contato(quadros, caminho, colunas=8, passo=1, fundo=(28, 40, 52, 255)):
    sel = quadros[::passo]
    w, h = sel[0].size
    linhas = math.ceil(len(sel) / colunas)
    folha = Image.new("RGBA", (colunas * w, linhas * h), fundo)
    for i, q in enumerate(sel):
        folha.alpha_composite(q, ((i % colunas) * w, (i // colunas) * h))
    folha.save(caminho)


def salvar_gif(quadros, caminho, fps, fundo=(28, 40, 52)):
    lista = []
    for q in quadros:
        base = Image.new("RGB", q.size, fundo)
        base.paste(q, (0, 0), q)
        lista.append(base)
    lista[0].save(caminho, save_all=True, append_images=lista[1:], duration=int(1000 / fps), loop=0)
