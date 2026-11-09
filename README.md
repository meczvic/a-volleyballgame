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

1. Quem saca (o atleta na posição 1 do rodízio, atrás da linha de fundo) aperta **Ataque**. A bola vai pro outro lado.
2. Um **anel amarelo** no chão mostra onde a bola vai cair, e o jogo passa o controle pro atleta mais perto dele (o atleta controlado tem um anel da cor do time).
3. **1º toque:** corra até o anel e aperte **Passe**. A bola vai pro levantador, perto da rede.
4. **2º toque:** com o levantador, aperte **Passe** segurando uma direção pra escolher o atacante. As setas aparecem no chão (`< Ponta`, `^ Meio`, `> Oposto`, `v Fundo`). Sem direção, vai pro meio.
5. **3º toque:** com o atacante, aperte **Ataque** com a bola alta pra cortar. Segurar esquerda ou direita mira a cortada. **Passe** no 3º toque só devolve a bola de graça.
6. **Ataque** com a bola alta funciona em qualquer toque (por exemplo, o levantador pode atacar de surpresa).
7. **Bloqueio:** quando o adversário levanta, os 3 atletas da rede sobem sozinhos e acompanham a bola. Aperte **Bloqueio** pra eles pularem; segurar esquerda ou direita desloca o bloqueio. Acertar o tempo do pulo devolve a cortada.
8. Bola no chão dentro da quadra: ponto pra quem mandou a bola. Fora: ponto pra quem não tocou por último. 4 toques seguidos do mesmo time é falta.

Os atletas que você não controla se posicionam sozinhos, e o time gira o **rodízio** quando recupera o saque. A tela é **dividida**: o Jogador 1 vê de trás do time dele na metade esquerda, o Jogador 2 na metade direita. "Cima" é sempre na direção da rede pra cada um. Pra voltar pra uma câmera só, selecione o nó `Main` na cena e desmarque **Tela Dividida** no Inspetor (lá também dá pra ajustar a altura e a distância da câmera).

## Pastas

| Pasta | O que tem |
| --- | --- |
| `cenas/` | Cenas do Godot (`.tscn`). `main.tscn` é a cena de teste. |
| `scripts/regras/` | Regras puras, sem gráfico: placar, sets, rodízio, toques, trajetória da bola, escolha do atacante. |
| `scripts/entrada/` | Teclado e controle viram "comandos". A lógica do jogo não sabe se o comando veio do teclado ou da internet, o que facilita o online depois. |
| `scripts/partida/` | O que acontece na quadra. |
| `dados/` | Times (atributos e cores) e cartas do Modo Caos, em JSON. Mudar um número aqui muda o jogo sem mexer em código. |
| `testes/` | Testes automáticos das regras. |

## Rodar os testes

No terminal, dentro da pasta do projeto:

```
godot --headless --script res://testes/teste_placar.gd
godot --headless --script res://testes/teste_trajetoria.gd
godot --headless --script res://testes/teste_toques.gd
godot --headless --script res://testes/teste_escolha_ataque.gd
godot --headless --script res://testes/teste_rodizio.gd
```

Cada um deve terminar com uma linha começando com `OK:`.

## Próximos passos

Seguindo as fases do documento de design:

1. Aprender Godot (trilha de tutoriais no documento).
2. ~~Bola e quadra: física da bola, marcador de queda.~~ Feito.
3. ~~Um time controlado: troca automática de atleta, passe, levantamento, cortada.~~ Feito.
4. ~~IA de posicionamento dos 5 atletas sem controle.~~ Feito (com bloqueio e rodízio).
5. Partida completa local (MVP).

Os nomes e times inspirados em Haikyuu são só pra jogar entre amigos. Se um dia o jogo for publicado, eles precisam virar times próprios, por isso ficam todos em `dados/times.json`.
