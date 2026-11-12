# Handoff do projeto

Atualizado em **11/11/2026** (noite). Ponto de partida para quem pegar o projeto agora, pessoa ou agente de IA. O guia completo continua em [ESTADO_DO_PROJETO.md](ESTADO_DO_PROJETO.md) (leia a seção 6 antes de mexer no código).

## Onde está tudo

| Item | Onde |
| --- | --- |
| Repositório | `github.com/meczvic/a-volleyballgame` |
| Branch principal | `claude/project-thread-o4s5hf` (não existe `main`). Trabalho novo: branch próprio + PR contra ela |
| Último trabalho | `claude/hinata-vroid`, já mesclado na principal (commit `d14e4a5`) |
| Pasta no PC de casa | `C:\Users\lukew\a-volleyballgame` |
| Godot | 4.7.2, `C:\Users\lukew\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` |
| VRoid Studio | 2.16.0 (Steam) |
| Projetos editáveis do VRoid (`.vroid`) | `C:\Users\lukew\Documents\VRoid\<time>_<nn>_<nome>.vroid` (fora do Git) |

## Estado em 11/11/2026

- **Jogo:** partida rápida local completa (menus, seleção, 4 estádios, regras FIVB, tempo, mira, bloqueio, mergulho, placar de transmissão). Modo Caos com 8 das 21 cartas valendo. Online não começou.
- **Personagens: os 42 atletas têm `.vrm` do VRoid** em `personagens/<time>/<nn>_<arquivo>.vrm`. O jogo pinta o uniforme com as cores do time e o número (`scripts/visual/uniforme_vrm.gd`) e troca o MToon pelo shader anime do jogo (`scripts/visual/visual_vrm.gd`, `shaders/atleta_vrm_*`). O personagem gerado por código (`dados/aparencia.json`) só entra se faltar o `.vrm`.
- **Testes:** os 32 de `testes/` passam no Godot 4.7.2. Robô jogou 60 s de Brasil x Karasuno sem erro (só um aviso de 7 texturas não liberadas ao fechar).
- **Alturas conferidas** com `ferramentas/medir_personagem.gd` (ex.: Paim 2,02 m, Barreto 2,01 m, Takahashi 1,76 m, Hinata 1,63 m).

## Aproximações nos personagens (ainda diferentes da referência)

- **Tsukishima:** sem óculos (o VRoid não tem óculos pronto).
- **Nishinoya, Tanaka, Kuroo, Bokuto:** cabelo aproximado com os presets do VRoid.
- **Kai, Watari, Ohira, Aran (raspados) e Yamamoto (moicano):** sem malha de cabelo no VRM. O teste aceita isso só para os estilos `raspado`/`moicano`. Ninguém olhou no jogo se o moicano do Yamamoto aparece.
- **Paim:** deveria ter tranças; ficou com cabelo curto escuro.
- **Barreto:** deveria ter undercut de duas cores; ficou curto, loiro, uma cor.
- **Azevedo:** sem braçadeira de capitão e sem expressão sorrindo.
- **Rocha:** a faixa na cabeça não foi conferida de perto.
- **Hinata e os demais:** sem joelheiras (o VRoid não tem pronta).
- **Cores dos uniformes:** só Karasuno e Brasil foram vistos no jogo; faltam os outros 4 times.
- `brasil_04_azevedo.vroid` ficou salvo antes das mudanças de cabelo, olhos e altura. O `.vrm` está certo; se for editar o Azevedo, refaça cabelo (castanho `#5A3E2B`, longo), olhos (verde `#3FA66B`), pele (`#D2A07E`) e Masc Height `0,325` (1,94 m).

## Como fazer ou refazer um atleta no VRoid

1. Abrir o `.vroid` mais parecido e usar **Salvar como** com o nome novo (`<time>_<nn>_<nome>.vroid`).
2. Ajustar cabelo (preset + cor em hex), olhos (Face → Irises), pele e altura (Body → Masc Height; o campo usa **vírgula**: `0,3`, não `0.3`). Body Size também muda a altura.
3. Roupa sempre branca, sem número (o jogo pinta). Não reduzir materiais na exportação.
4. Exportar em **VRM 1.0** direto para `personagens/<time>/<nn>_<arquivo>.vrm`.
5. No Godot: `--headless --path . --import`, depois rodar os testes e `medir_personagem.gd -- atleta=<time>/<nn>_<arquivo>`.

Dicas de automação (Computer Use no Windows): com a janela maximizada, o ícone de exportar fica colado na barra de título e o Windows abre o menu de encaixe. Restaure a janela (duplo clique no título), aperte o ícone com botão pressionado e solto separadamente (às vezes precisa de duas tentativas), escolha "Export as VRM" e maximize de novo para o botão Export do diálogo aparecer.

## Comandos úteis

```bash
G="/c/Users/lukew/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
cd /c/Users/lukew/a-volleyballgame
"$G" --headless --path . --import
for t in testes/teste_*.gd; do "$G" --headless --path . --script "$t"; done
"$G" --headless --path . --script res://ferramentas/medir_personagem.gd -- atleta=brasil/13_paim
"$G" --position -30000,-30000 --path . --script res://ferramentas/robo.gd -- times=brasil,karasuno segundos=60 prints=<pasta>
```

Cada teste precisa terminar com uma linha `OK:`. Desde 12/11/2026 há `ferramentas/rodar_testes.sh`, que roda todos e sai com erro se algum falhar (`GODOT="$G" ferramentas/rodar_testes.sh`). O laço acima não pega um teste travado: um erro de script deixa o Godot aberto para sempre.

## Próximos passos sugeridos

1. Jogar com os amigos e ajustar números (janelas de tempo, força do saque, largura do bloqueio).
2. Conferir no jogo os uniformes dos outros 4 times e o moicano do Yamamoto.
3. Corrigir as aproximações acima que mais incomodarem (óculos do Tsukishima via item custom, tranças do Paim, joelheiras).
4. Modo Caos: efeito das 13 cartas que faltam e balanceamento.
5. Online: primeiro por IP.
6. Arrumação: criar um `main`, considerar Git LFS para os `.vrm` (~14 MB cada, ~580 MB no total), atualizar o README.
