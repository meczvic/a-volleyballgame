"""Gera os números das camisas e uma prévia dos uniformes de cada time.

Uso (na pasta do projeto):  python3 ferramentas/uniformes.py [id_do_time ...]

Saída em producao/uniformes/<time>/:
  numeros/<nn>.png  número do atleta (fundo transparente, 1024x1024), pra
                    importar como camada nova na textura da camisa no VRoid
                    (vroid_import_layer) ou colar num editor de imagem.
  previa.png        os 6 uniformes do time, frente e costas, em desenho chapado.
                    É só pra conferir cores e números: não é a textura do VRoid
                    (essa depende do mapa UV que sai do próprio VRoid).

Cores e elenco vêm de dados/times.json e dados/elenco.json.
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

RAIZ = Path(__file__).resolve().parent.parent
FONTE = RAIZ / "fontes" / "BarlowCondensed-SemiBold.ttf"
SAIDA = RAIZ / "producao" / "uniformes"


def cor(hexa):
    hexa = hexa.lstrip("#")
    return tuple(int(hexa[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def contraste(c):
    """Contorno escuro em número claro e vice-versa, pra ler de longe."""
    luz = 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]
    return (20, 20, 24, 255) if luz > 140 else (245, 245, 245, 255)


def numero_png(numero, cor_numero, cor_camisa, tamanho=1024):
    img = Image.new("RGBA", (tamanho, tamanho), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    fonte = ImageFont.truetype(str(FONTE), int(tamanho * 0.9))
    texto = str(numero)
    borda = int(tamanho * 0.025)
    caixa = d.textbbox((0, 0), texto, font=fonte, stroke_width=borda)
    x = (tamanho - (caixa[2] - caixa[0])) / 2 - caixa[0]
    y = (tamanho - (caixa[3] - caixa[1])) / 2 - caixa[1]
    contorno = contraste(cor_numero)
    # Contorno só quando o número tem pouco contraste com a camisa.
    if abs(sum(cor_numero[:3]) - sum(cor_camisa[:3])) > 300:
        contorno = cor_numero
    d.text((x, y), texto, font=fonte, fill=cor_numero, stroke_width=borda, stroke_fill=contorno)
    return img


def camisa(d, x, y, l, a, principal, detalhe, numero, costas, fonte):
    """Camisa chapada: corpo, mangas, gola, faixa nas mangas e número."""
    manga = l * 0.28
    d.polygon([(x, y + a * 0.08), (x - manga, y + a * 0.28), (x - manga * 0.6, y + a * 0.42),
               (x, y + a * 0.3)], fill=principal, outline=(0, 0, 0, 255))
    d.polygon([(x + l, y + a * 0.08), (x + l + manga, y + a * 0.28), (x + l + manga * 0.6, y + a * 0.42),
               (x + l, y + a * 0.3)], fill=principal, outline=(0, 0, 0, 255))
    d.line([(x - manga, y + a * 0.28), (x - manga * 0.6, y + a * 0.42)], fill=detalhe, width=10)
    d.line([(x + l + manga, y + a * 0.28), (x + l + manga * 0.6, y + a * 0.42)], fill=detalhe, width=10)
    d.rectangle([x, y + a * 0.05, x + l, y + a], fill=principal, outline=(0, 0, 0, 255))
    d.rectangle([x, y + a * 0.86, x + l, y + a * 0.9], fill=detalhe)
    if costas:
        d.arc([x + l * 0.3, y - a * 0.02, x + l * 0.7, y + a * 0.1], 0, 180, fill=detalhe, width=8)
    else:
        d.polygon([(x + l * 0.32, y + a * 0.05), (x + l * 0.5, y + a * 0.2), (x + l * 0.68, y + a * 0.05)],
                  fill=detalhe)
    texto = str(numero)
    tam = int(a * (0.55 if costas else 0.3))
    f = fonte.font_variant(size=tam)
    caixa = d.textbbox((0, 0), texto, font=f)
    cx = x + (l - (caixa[2] - caixa[0])) / 2 - caixa[0]
    cy = y + a * (0.25 if costas else 0.3) - caixa[1]
    d.text((cx, cy), texto, font=f, fill=detalhe, stroke_width=3, stroke_fill=contraste(detalhe))


def previa(time, elenco, fonte):
    l, a, passo = 150, 190, 260
    img = Image.new("RGBA", (passo * 6 + 40, 2 * (a + 110) + 90), (236, 233, 226, 255))
    d = ImageDraw.Draw(img)
    titulo = fonte.font_variant(size=40)
    rotulo = fonte.font_variant(size=24)
    d.text((24, 16), f"{time['nome']}: uniformes (frente em cima, costas embaixo)", font=titulo, fill=(30, 30, 30, 255))
    for i, atleta in enumerate(elenco):
        cores = time["cores"][:2]
        principal, detalhe = cor(cores[0]), cor(cores[1])
        x = 40 + 55 + i * passo
        for linha, costas in enumerate((False, True)):
            y = 90 + linha * (a + 110)
            camisa(d, x, y, l, a, principal, detalhe, atleta["numero"], costas, fonte)
        nome = atleta["nome"].split()[-1]
        d.text((x - 30, 90 + 2 * (a + 110) - 40), nome, font=rotulo, fill=(30, 30, 30, 255))
    return img


def main():
    times = json.loads((RAIZ / "dados" / "times.json").read_text(encoding="utf-8"))["times"]
    elencos = json.loads((RAIZ / "dados" / "elenco.json").read_text(encoding="utf-8"))["times"]
    fonte = ImageFont.truetype(str(FONTE), 40)
    so = set(sys.argv[1:])
    for time in times:
        if so and time["id"] not in so:
            continue
        elenco = elencos.get(time["id"], [])
        pasta = SAIDA / time["id"]
        (pasta / "numeros").mkdir(parents=True, exist_ok=True)
        for atleta in elenco:
            cores = time["cores"][:2]
            img = numero_png(atleta["numero"], cor(cores[1]), cor(cores[0]))
            img.save(pasta / "numeros" / f"{atleta['numero']:02d}.png", optimize=True)
        previa(time, elenco, fonte).convert("RGB").save(pasta / "previa.png", optimize=True)
        print(f"{time['id']}: {len(elenco)} números + prévia")


def numeros_brancos(tamanho=512):
    """Números brancos com fundo transparente, pintados pelo jogo com a cor do
    uniforme (scripts/visual/gerador_de_atleta.gd). Um por número usado no elenco,
    em personagens/numeros/<nn>.png (essa pasta o Godot importa; producao/ não)."""
    elencos = json.loads((RAIZ / "dados" / "elenco.json").read_text(encoding="utf-8"))["times"]
    numeros = sorted({a["numero"] for time in elencos.values() for a in time})
    pasta = RAIZ / "personagens" / "numeros"
    pasta.mkdir(parents=True, exist_ok=True)
    fonte = ImageFont.truetype(str(FONTE), int(tamanho * 0.95))
    for numero in numeros:
        img = Image.new("RGBA", (tamanho, tamanho), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        texto = str(numero)
        caixa = d.textbbox((0, 0), texto, font=fonte)
        x = (tamanho - (caixa[2] - caixa[0])) / 2 - caixa[0]
        y = (tamanho - (caixa[3] - caixa[1])) / 2 - caixa[1]
        d.text((x, y), texto, font=fonte, fill=(255, 255, 255, 255))
        img.save(pasta / f"{numero:02d}.png")
    print(f"{len(numeros)} números brancos em {pasta}")


if __name__ == "__main__":
    main()
    numeros_brancos()
