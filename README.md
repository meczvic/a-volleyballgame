# Jogo de Vôlei

Vôlei de quadra 6 contra 6 em 3D, estilo anime cel-shaded, para 2 jogadores (no mesmo PC ou online). Feito em Godot 4.

Por enquanto o projeto tem: menu principal, seleção de times e estádio, a partida com 3 toques, bloqueio, rodízio, tela dividida e visual anime, pausa e tela de fim de jogo. Os atletas ainda são cápsulas no lugar dos personagens.

## Como abrir

1. Instale o **Godot 4.3 ou mais novo**, versão padrão (não a ".NET"): https://godotengine.org/download
2. Clone este repositório.
3. Abra o Godot, clique em **Importar**, escolha o arquivo `project.godot` desta pasta.
4. Aperte **F5** (ou o botão de play no canto superior direito) pra rodar. O jogo abre no menu principal.

Na primeira vez o Godot cria a pasta `.godot/`. Ela é interna e não vai pro Git.

## Controles

| Ação | Jogador 1 | Jogador 2 | Controle |
| --- | --- | --- | --- |
| Mover | WASD | Setas | Analógico esquerdo |
| Passe | J | 1 (numérico) | A |
| Ataque (cortada / saque forte) | K | 2 (numérico) | X |
| Bloqueio | L | 3 (numérico) | Y |
| Saque flutuante | I | 5 (numérico) | RB |
| Mergulho (ainda sem efeito) | Espaço | 0 (numérico) | B |
| Pausa | Esc | Esc | Start |

O 1º controle conectado é do Jogador 1, o 2º do Jogador 2. O direcional do controle também move.

Nos menus: setas, WASD ou direcional navegam; **Enter, J ou A** escolhem; **Esc ou B** voltam.

### Menus

1. **Menu principal:** Partida rápida, Controles e Sair. Modo Caos e Online aparecem como "em breve".
2. **Seleção de times:** cada jogador move o próprio cursor (Jogador 1: A/D, Jogador 2: setas, ou o direcional do seu controle) e confirma com **Passe** (J, 1 numérico ou A). Os atributos do time aparecem na metade de cada um. **Mergulho** (Espaço, 0 numérico ou B) desfaz.
3. Com os dois confirmados, qualquer um escolhe o **estádio** (esquerda/direita) e confirma pra começar.
4. Na partida, **Esc ou Start** pausa: continuar, recomeçar, trocar times ou voltar ao menu. No fim, aparece quem venceu, com as mesmas opções.

Se os dois escolherem o mesmo time, o Jogador 2 joga com o uniforme reserva.

### Como jogar

1. Quem saca (o atleta na posição 1 do rodízio, atrás da linha de fundo) aperta **Ataque**. A bola vai pro outro lado.
2. Um **anel amarelo** no chão mostra onde a bola vai cair, e o jogo passa o controle pro atleta mais perto dele (o atleta controlado tem um anel da cor do time).
3. **1º toque:** corra até o anel e aperte **Passe**. A bola vai pro levantador, perto da rede.
4. **2º toque:** com o levantador, aperte **Passe** segurando uma direção pra escolher o atacante. As setas aparecem no chão (`< Ponta`, `^ Meio`, `> Oposto`, `v Fundo`). Sem direção, vai pro meio.
5. **3º toque:** com o atacante, aperte **Ataque** com a bola alta pra cortar. Segurar esquerda ou direita mira a cortada. **Passe** no 3º toque só devolve a bola de graça.
6. **Ataque** com a bola alta funciona em qualquer toque (por exemplo, o levantador pode atacar de surpresa).
7. **Bloqueio:** quando o adversário levanta, os 3 atletas da rede sobem sozinhos e acompanham a bola. Aperte **Bloqueio** pra eles pularem; segurar esquerda ou direita desloca o bloqueio. Acertar o tempo do pulo devolve a cortada.
8. Bola no chão dentro da quadra: ponto pra quem mandou a bola. Fora: ponto pra quem não tocou por último. 4 toques seguidos do mesmo time é falta.

Os atletas que você não controla se posicionam sozinhos, e o time gira o **rodízio** quando recupera o saque. A tela é **dividida**: o Jogador 1 vê de trás do time dele na metade esquerda, o Jogador 2 na metade direita. "Cima" é sempre na direção da rede pra cada um. Pra voltar pra uma câmera só, abra `cenas/partida.tscn`, selecione o nó `Partida` e desmarque **Tela Dividida** no Inspetor (lá também dá pra ajustar a altura, a distância e o foco da câmera, e ligar ou desligar o **Visual Anime**: sombra "chapada" e contorno escuro nos atletas e na bola).

## Pastas

| Pasta | O que tem |
| --- | --- |
| `cenas/` | Cenas do Godot (`.tscn`): `menu_principal.tscn` (abre primeiro), `selecao_de_times.tscn` e `partida.tscn`. Com a partida aberta no editor, **F6** roda só ela (Karasuno x Nekoma no Ginásio Japonês). |
| `scripts/regras/` | Regras puras, sem gráfico: placar, sets, rodízio, toques, trajetória da bola, escolha do atacante. |
| `scripts/entrada/` | Teclado e controle viram "comandos". A lógica do jogo não sabe se o comando veio do teclado ou da internet, o que facilita o online depois. |
| `scripts/partida/` | O que acontece na quadra. |
| `scripts/menus/` | Menu principal, seleção de times (`selecao.gd` tem as regras, `selecao_de_times.gd` desenha a tela), pausa e fim de jogo. `estilo.gd` guarda as cores e fontes de todos os menus. `configuracao.gd` guarda os times e o estádio escolhidos. |
| `scripts/comum/` | `dados.gd` lê os arquivos da pasta `dados/`. |
| `fontes/` | Fonte Barlow Condensed (licença livre OFL, em `LICENCA_OFL.txt`). |
| `shaders/` | Efeito anime: `anime.gdshader` (luz e sombra em faixas) e `contorno.gdshader` (contorno escuro). |
| `scripts/visual/` | `visual_anime.gd` cria materiais anime prontos: `VisualAnime.material(cor)`. |
| `dados/` | Times (atributos e cores), estádios (cores da quadra, do fundo, das placas e da luz) e cartas do Modo Caos, em JSON. Mudar um número aqui muda o jogo sem mexer em código. |
| `arte/` (opcional) | Se você criar `arte/times/<id>.png` (um personagem com fundo transparente, ex.: `arte/times/karasuno.png`), ele aparece grande na seleção de times. `arte/estadios/<id>.png` vira a prévia do estádio. Os ids estão nos arquivos de `dados/`. |
| `personagens/` | Atletas feitos no VRoid Studio (`.vrm`), um por arquivo: `personagens/<time>/<número>_<nome>.vrm`. Veja o [guia do VRoid](https://claude.ai/artifact/NitRJ4DP8oGWkKQJLS1k6A). |
| `testes/` | Testes automáticos das regras. |

## Rodar os testes

No terminal, dentro da pasta do projeto:

```
godot --headless --script res://testes/teste_placar.gd
godot --headless --script res://testes/teste_trajetoria.gd
godot --headless --script res://testes/teste_toques.gd
godot --headless --script res://testes/teste_escolha_ataque.gd
godot --headless --script res://testes/teste_rodizio.gd
godot --headless --script res://testes/teste_selecao.gd
godot --headless --script res://testes/teste_dados.gd
```

Cada um deve terminar com uma linha começando com `OK:`.

Todos os testes passam no Godot 4.3, e a partida, os menus e a seleção de times rodam sem erros (testado em 09/11/2026).

## Próximos passos

Seguindo as fases do documento de design:

1. Aprender Godot (trilha de tutoriais no documento).
2. ~~Bola e quadra: física da bola, marcador de queda.~~ Feito.
3. ~~Um time controlado: troca automática de atleta, passe, levantamento, cortada.~~ Feito.
4. ~~IA de posicionamento dos 5 atletas sem controle.~~ Feito (com bloqueio e rodízio).
5. Partida completa local (MVP): ~~menus, seleção de times e estádios~~ feito. Falta trocar as cápsulas pelos personagens (VRoid, passo a passo no [guia](https://claude.ai/artifact/NitRJ4DP8oGWkKQJLS1k6A)) e o placar com efeito.

Os nomes e times inspirados em Haikyuu são só pra jogar entre amigos. Se um dia o jogo for publicado, eles precisam virar times próprios, por isso ficam todos em `dados/times.json`.
