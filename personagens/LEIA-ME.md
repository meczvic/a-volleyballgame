# Personagens

Aqui ficam os atletas feitos no VRoid Studio, um arquivo `.vrm` por atleta, e em `numeros/` as texturas dos números das camisas que o gerador de personagens usa.

**Hoje só o Hinata tem `.vrm`** (`karasuno/10_hinata.vrm`, 11/11/2026); os outros 41 são gerados por código (`scripts/visual/gerador_de_atleta.gd`) a partir de `dados/aparencia.json`. Quando um `.vrm` com o nome certo aparecer aqui, o jogo usa ele no lugar do gerado.

**Uniforme: faça no VRoid todo branco, sem cor de time e sem número** (camiseta padrão, short pelo molde "Shorts" do Custom, meia e tênis brancos). O jogo pinta a camisa e o short com as cores de cada time (titular e reserva) e põe o número (`scripts/visual/uniforme_vrm.gd`). Exporte em VRM 1.0 sem reduzir materiais. Detalhes na seção "Personagens" de `docs/ESTADO_DO_PROJETO.md`.

Padrão de nome: `personagens/<id do time>/<número com 2 dígitos>_<nome>.vrm`, tudo em minúsculas, sem acento e sem espaço.

```
personagens/karasuno/10_hinata.vrm
personagens/nekoma/05_kenma.vrm
```

Ids dos times: `karasuno`, `aoba_johsai`, `shiratorizawa`, `nekoma`, `fukurodani`, `inarizaki`, `brasil` (os mesmos de `dados/times.json`).

O passo a passo completo (criar no VRoid, cores dos uniformes, exportar, plugin VRM no Godot, animações) está no guia: https://claude.ai/artifact/NitRJ4DP8oGWkKQJLS1k6A

Quem é cada atleta (nome, número, posição, líbero) está em `dados/elenco.json`, e as fontes em `ELENCO.md`. O jogo usa o `.vrm` sozinho quando ele existe e o plugin VRM está ativo; sem ele, usa o gerado; sem os dois, cápsula. O estado da produção está em `producao/MANIFESTO.md`.

Os arquivos `.vroid` (projeto editável do VRoid) não vêm pra cá: ficam no Drive compartilhado. O do Hinata está em `Documentos\VRoid\10_hinata.vroid` no PC de casa (falta subir pro Drive).
