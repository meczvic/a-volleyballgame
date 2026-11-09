# Jogo de Vôlei

Vôlei de quadra 6 contra 6 em 3D, estilo anime cel-shaded, para 2 jogadores (no mesmo PC ou online). Feito em Godot 4.

Por enquanto o projeto tem a base: uma quadra de teste com cápsulas no lugar dos atletas, controles dos 2 jogadores, regras do placar e a bola com física, rede e marcador de queda.

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

O 1º controle conectado é do Jogador 1, o 2º do Jogador 2.

### Como jogar a cena de teste

1. Quem saca aperta **Ataque**. A bola vai pro outro lado.
2. Um **anel amarelo** no chão mostra onde a bola vai cair, e o jogo passa o controle pro atleta mais perto dele (o atleta controlado tem um anel da cor do time).
3. Corra até a bola e aperte **Passe** pra devolver, ou **Ataque** com a bola alta pra cortar.
4. Bola no chão dentro da quadra: ponto pra quem mandou a bola. Fora: ponto pra quem não tocou por último.

Ainda não tem 3 toques, levantador nem IA dos outros atletas: isso vem nas próximas fases. Por enquanto a câmera é só do lado do Jogador 1; a tela dividida vem depois.

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
godot --headless --script res://testes/teste_trajetoria.gd
```

Cada um deve terminar com uma linha começando com `OK:`.

## Próximos passos

Seguindo as fases do documento de design:

1. Aprender Godot (trilha de tutoriais no documento).
2. ~~Bola e quadra: física da bola, marcador de queda.~~ Feito.
3. Um time controlado: troca automática de atleta, passe, levantamento, cortada.
4. IA de posicionamento dos 5 atletas sem controle.
5. Partida completa local (MVP).

Os nomes e times inspirados em Haikyuu são só pra jogar entre amigos. Se um dia o jogo for publicado, eles precisam virar times próprios, por isso ficam todos em `dados/times.json`.
