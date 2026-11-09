"""Gera producao/MANIFESTO.md: o estado real de cada um dos 42 atletas.

Uso (na pasta do projeto):  python3 ferramentas/manifesto.py

O que o script confere sozinho, olhando os arquivos do repositório:
  - ficha visual:  producao/fichas/<time>/<nn>_<nome>.md
  - VRM:           personagens/<time>/<nn>_<nome>.vrm (e o tamanho)
  - capturas:      producao/capturas/<time>/<nn>_<nome>_<vista>.png
O que não dá pra ver daqui fica em producao/status.json, preenchido só depois
de conferir de verdade (modelagem no VRoid, .vroid salvo no PC de casa,
importação no Godot, animação, pendências). Atleta sem entrada lá = "pendente".
"""
import json
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
VISTAS = ["frente", "perfil", "tres_quartos", "costas", "godot"]


def ok(condicao):
    return "sim" if condicao else "não"


def main():
    times = json.loads((RAIZ / "dados" / "times.json").read_text(encoding="utf-8"))["times"]
    elencos = json.loads((RAIZ / "dados" / "elenco.json").read_text(encoding="utf-8"))["times"]
    arquivo_status = RAIZ / "producao" / "status.json"
    status = json.loads(arquivo_status.read_text(encoding="utf-8")) if arquivo_status.exists() else {}
    status = status.get("atletas", {})

    linhas = [
        "# Manifesto de produção dos personagens",
        "",
        "Gerado por `python3 ferramentas/manifesto.py`. Não edite à mão: as colunas de arquivo vêm do que existe no repositório,",
        "e as de status vêm de `producao/status.json`, preenchido só depois de conferir de verdade.",
        "",
        "Projeto editável `.vroid`: fica fora do Git, no PC de casa, em `VoleiPersonagens/vroid/<time>/<nn>_<nome>.vroid` (depois vai pro Drive).",
        "",
    ]
    totais = {"ficha": 0, "vrm": 0, "importado": 0}
    for time in times:
        linhas += [f"## {time['nome']}", "",
                   "| Nº | Atleta | Ficha | Modelagem | .vroid | VRM | Capturas | Godot | Animação | Pendências |",
                   "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"]
        for a in elencos.get(time["id"], []):
            base = f"{a['numero']:02d}_{a['arquivo']}"
            chave = f"{time['id']}/{base}"
            s = status.get(chave, {})
            ficha = RAIZ / "producao" / "fichas" / time["id"] / f"{base}.md"
            vrm = RAIZ / "personagens" / time["id"] / f"{base}.vrm"
            capturas = [v for v in VISTAS
                        if (RAIZ / "producao" / "capturas" / time["id"] / f"{base}_{v}.png").exists()]
            tamanho = f" ({vrm.stat().st_size / 1e6:.1f} MB)" if vrm.exists() else ""
            nome = a["nome"] + (" (L)" if a.get("libero") else "")
            ficha_txt = f"[sim](fichas/{time['id']}/{base}.md)" if ficha.exists() else "não"
            linhas.append(
                f"| {a['numero']} | {nome} | {ficha_txt} | {s.get('modelagem', 'pendente')} | "
                f"{s.get('vroid', 'pendente')} | {ok(vrm.exists())}{tamanho} | "
                f"{', '.join(capturas) if capturas else 'nenhuma'} | {s.get('godot', 'pendente')} | "
                f"{s.get('animacao', 'pendente')} | {s.get('pendencias', '')} |")
            totais["ficha"] += ficha.exists()
            totais["vrm"] += vrm.exists()
            totais["importado"] += s.get("godot") == "ok"
        linhas.append("")
    linhas[7:7] = [f"**Resumo:** {totais['ficha']}/42 fichas, {totais['vrm']}/42 VRMs no repositório, "
                   f"{totais['importado']}/42 testados no Godot.", ""]
    (RAIZ / "producao" / "MANIFESTO.md").write_text("\n".join(linhas), encoding="utf-8")
    print("producao/MANIFESTO.md:", totais)


if __name__ == "__main__":
    main()
