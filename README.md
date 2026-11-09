# Jogo de Vôlei

Vôlei de quadra 6 contra 6 em 3D, estilo anime cel-shaded, para 2 jogadores (no mesmo PC ou online). Feito em Godot 4.

Por enquanto o projeto tem só a base: uma quadra de teste com cápsulas no lugar dos atletas, controles dos 2 jogadores e as regras do placar.

## Como abrir

1. Instale o **Godot 4.3 ou mais novo**, versão padrão (não a ".NET"): https://godotengine.org/download
2. Clone este repositório.
3. Abra o Godot, clique em **Importar**, escolha o arquivo `project.godot` desta pasta.
4. Aperte **F5** (ou o botão de play no canto superior direito) pra rodar.

Na primeira vez o Godot cria a pasta `.godot/`. Ela é interna e não vai pro Git.

## Controles de teste

| Ação | Jogador 1 | Jogador 2 | Controle |
| --- | --- | --- | --- |
| Mover | WASD | Setas | Analógico esquerdo |
| Passe | J | 1 (numérico) | A |
| Ataque (cortada / saque forte) | K | 2 (numérico) | X |
| Bloqueio | L | 3 (numérico) | Y |
| Saque flutuante | I | 5 (numérico) | RB |
| Mergulho | Espaço | 0 (numérico) | B |

O 1º controle conectado é do Jogador 1, o 2º do Jogador 2. Na cena de teste, o botão de ataque marca um ponto pro seu time, só pra ver o placar funcionando.

## Pastas

| Pasta | O que tem |
| --- | --- |
| `cenas/` | Cenas do Godot (`.tscn`). `main.tscn` é a cena de teste. |
| `scripts/regras/` | Regras puras, sem gráfico: placar, sets, rodízio. |
| `scripts/entrada/` | Teclado e controle viram "comandos". A lógica do jogo não sabe se o comando veio do teclado ou da internet, o que facilita o online depois. |
| `scripts/partida/` | O que acontece na quadra. |
| `dados/` | Times (atributos e cores) e cartas do Modo Caos, em JSON. Mudar um número aqui muda o jogo sem mexer em código. |
| `testes/` | Testes automáticos das regras. |

## Rodar os testes

No terminal, dentro da pasta do projeto:

```
godot --headless --script res://testes/teste_placar.gd
```

Deve aparecer `OK: todos os testes do placar passaram.`

## Próximos passos

Seguindo as fases do documento de design:

1. Aprender Godot (trilha de tutoriais no documento).
2. Bola e quadra: física da bola, marcador de queda.
3. Um time controlado: troca automática de atleta, passe, levantamento, cortada.
4. IA de posicionamento dos 5 atletas sem controle.
5. Partida completa local (MVP).

Os nomes e times inspirados em Haikyuu são só pra jogar entre amigos. Se um dia o jogo for publicado, eles precisam virar times próprios, por isso ficam todos em `dados/times.json`.
