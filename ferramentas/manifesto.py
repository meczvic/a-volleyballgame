"""Gera producao/MANIFESTO.md: o estado real de cada um dos 42 atletas.

Uso (na pasta do projeto):  python3 ferramentas/manifesto.py

O que o script confere sozinho, olhando os arquivos do repositório:
  - ficha visual:   producao/fichas/<time>/<nn>_<nome>.md
  - formato em jogo: VRM em personagens/<time>/<nn>_<nome>.vrm (vale primeiro),
                     senão "gerado" se tem entrada em dados/aparencia.json,
                     senão "cápsula" (sem personagem).
  - capturas:       producao/capturas/<time>/<nn>_<nome>_<vista>.png
O que não dá pra ver daqui fica em producao/status.json, preenchido só depois
de conferir de verdade. Status separados (cada um "ok", "pendente" ou frase):
  gerado      -> o personagem gerado por código existe e passa no teste do elenco
  importado   -> VRM importado no Godot (só pra quem tem VRM)
  animado     -> as animações rodam nele sem pose T (teste do elenco)
  em_partida  -> foi visto numa partida de verdade (robô ou pessoa)
"""
import json
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
VISTAS = ["frente", "perfil", "tres_quartos", "costas", "correr", "cortada", "godot"]


def ok(condicao):
    return "sim" if condicao else "não"


def formato(id_time, base, aparencia):
    if (RAIZ / "personagens" / id_time / f"{base}.vrm").exists():
        return "vrm"
    if base in aparencia.get("times", {}).get(id_time, {}):
        return "gerado"
    return "cápsula"


def main():
    times = json.loads((RAIZ / "dados" / "times.json").read_text(encoding="utf-8"))["times"]
    elencos = json.loads((RAIZ / "dados" / "elenco.json").read_text(encoding="utf-8"))["times"]
    arquivo_aparencia = RAIZ / "dados" / "aparencia.json"
    aparencia = json.loads(arquivo_aparencia.read_text(encoding="utf-8")) if arquivo_aparencia.exists() else {}
    arquivo_status = RAIZ / "producao" / "status.json"
    status = json.loads(arquivo_status.read_text(encoding="utf-8")) if arquivo_status.exists() else {}
    status = status.get("atletas", {})

    linhas = [
        "# Manifesto de produção dos personagens",
        "",
        "Gerado por `python3 ferramentas/manifesto.py`. Não edite à mão: as colunas de arquivo vêm do que existe no repositório,",
        "e as de status vêm de `producao/status.json`, preenchido só depois de conferir de verdade.",
        "",
        "Formato em jogo: **vrm** (modelo VRoid importado), **gerado** (malha, esqueleto e pesos feitos por código a partir de",
        "`dados/aparencia.json`) ou **cápsula** (sem personagem). O VRM vale primeiro quando os dois existem.",
        "",
    ]
    formatos = {"vrm": 0, "gerado": 0, "cápsula": 0}
    etapas = {"gerado": 0, "importado": 0, "animado": 0, "em_partida": 0}
    for time in times:
        linhas += [f"## {time['nome']}", "",
                   "| Nº | Atleta | Ficha | Formato | Capturas | Gerado | Importado | Animado | Em partida | Pendências |",
                   "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"]
        for a in elencos.get(time["id"], []):
            base = f"{a['numero']:02d}_{a['arquivo']}"
            chave = f"{time['id']}/{base}"
            s = status.get(chave, {})
            ficha = RAIZ / "producao" / "fichas" / time["id"] / f"{base}.md"
            fmt = formato(time["id"], base, aparencia)
            vrm = RAIZ / "personagens" / time["id"] / f"{base}.vrm"
            tamanho = f" ({vrm.stat().st_size / 1e6:.1f} MB)" if vrm.exists() else ""
            capturas = [v for v in VISTAS
                        if (RAIZ / "producao" / "capturas" / time["id"] / f"{base}_{v}.png").exists()]
            ficha_txt = f"[sim](fichas/{time['id']}/{base}.md)" if ficha.exists() else "não"
            importado = s.get("importado", "pendente" if fmt == "vrm" else "—")
            linhas.append(
                f"| {a['numero']} | {a['nome']} | {ficha_txt} | {fmt}{tamanho} | "
                f"{', '.join(capturas) if capturas else 'nenhuma'} | {s.get('gerado', 'pendente')} | {importado} | "
                f"{s.get('animado', 'pendente')} | {s.get('em_partida', 'pendente')} | {s.get('pendencias', '')} |")
            formatos[fmt] += 1
            for etapa in etapas:
                etapas[etapa] += s.get(etapa) == "ok"
        linhas.append("")
    linhas[8:8] = [
        f"**Resumo:** {formatos['vrm']} VRM, {formatos['gerado']} gerados, {formatos['cápsula']} cápsulas (de 42). "
        f"Status conferido: {etapas['gerado']} gerados, {etapas['importado']} importados, "
        f"{etapas['animado']} animados, {etapas['em_partida']} vistos em partida.", ""]
    (RAIZ / "producao" / "MANIFESTO.md").write_text("\n".join(linhas), encoding="utf-8")
    print("producao/MANIFESTO.md:", formatos, etapas)


if __name__ == "__main__":
    main()
