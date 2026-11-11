# Jogo de Vôlei

Vôlei de quadra 6 contra 6 em 3D, estilo anime cel-shaded, para 2 jogadores (no mesmo PC ou online). Feito em Godot 4.

Por enquanto o projeto tem: menu principal, seleção de times e estádio, a partida com 3 toques, bloqueio, rodízio, tela dividida e visual anime, pausa e tela de fim de jogo, com câmera que acompanha a bola, botão guardado quando você aperta um pouco cedo e toque no bloqueio. Os 42 atletas (6 por time, sem líbero) são personagens gerados pelo próprio jogo a partir de `dados/aparencia.json`, já animados: correm, param e fazem cada lance (veja `animacoes/LEIA-ME.md`). Quando o `.vrm` de um atleta existir em `personagens/`, o jogo usa ele no lugar do gerado (veja `producao/LEIA-ME.md`).

**Estado do projeto** (o que foi feito, o que falta e próximos passos): [docs/ESTADO_DO_PROJETO.md](docs/ESTADO_DO_PROJETO.md)

## Como abrir

1. Instale o **Godot 4.7.2 ou mais novo**, versão padrão (não a ".NET"): https://godotengine.org/download
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
| Mergulho | Espaço | 0 (numérico) | B |
| Largada | J no pulo da cortada | 1 (numérico) no pulo | A no pulo |
| Pausa | Esc | Esc | Start |

O 1º controle conectado é do Jogador 1, o 2º do Jogador 2. O direcional do controle também move.

Nos menus: setas, WASD ou direcional navegam; **Enter, J ou A** escolhem; **Esc ou B** voltam.

### Menus

1. **Menu principal:** Partida rápida, Modo Caos, Controles e Sair. Online aparece como "em breve".
   - **Modo Caos:** igual à partida rápida, mas antes do 1º saque e a cada 3 pontos cada jogador escolhe 1 de 3 cartas na metade dele (esquerda/direita escolhe, Passe confirma; 60 s, depois sorteia). Cada carta mostra a raridade (**prata**, **ouro** ou **prismática**, cada uma com moldura e fundo próprios), o atleta destaque do seu time fazendo a jogada da carta, o ícone do conjunto, o nome e o efeito. **Bloqueio** (L, 3 numérico ou Y) troca as 3 cartas por outras 3, uma vez por partida (`trocas_por_partida` em `dados/cartas.json`). Só 8 cartas já têm efeito (veja `docs/ESTADO_DO_PROJETO.md`).
2. **Seleção de times:** cada jogador move o próprio cursor (Jogador 1: A/D, Jogador 2: setas, ou o direcional do seu controle) e confirma com **Passe** (J, 1 numérico ou A). Na metade de cada um aparecem o emblema e o nome do time, os atributos com ícone e barra, e o atleta destaque em 3D (o mesmo personagem da partida), que comemora quando você confirma. **Mergulho** (Espaço, 0 numérico ou B) desfaz.
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
7. **Bloqueio:** quando o adversário levanta, os 3 atletas da rede sobem sozinhos e acompanham a bola. Aperte **Bloqueio** pra eles pularem; segurar esquerda ou direita desloca o bloqueio. No alto do pulo e bem na frente da bola, o bloqueio **devolve** a cortada. Cedo ou tarde demais, ou só com a ponta da mão, a bola **raspa no bloqueio** e segue pro seu lado, mais devagar: aí a sua defesa tem que pegar (o toque no bloqueio não conta como toque).

**Apertou cedo?** Se você aperta Passe ou Cortada com a bola ainda longe, o jogo guarda o botão por um instante e toca assim que der. Se a bola não chega, o anel embaixo do seu atleta pisca pra avisar que não deu.
8. Bola no chão dentro da quadra: ponto pra quem mandou a bola. Fora: ponto pra quem não tocou por último. As outras faltas estão em **Regras do vôlei**, logo abaixo.

**Mira:** no saque, **segure** Ataque (ou Flutuante) pra encher a força e **solte** pra sacar. Enquanto segura, a direção move o X vermelho na quadra do outro lado; o círculo mostra onde a bola pode cair. Mais força: bola mais baixa e rápida, mas o círculo cresce, e no máximo (vermelho forte) o risco de sair é grande. A força enche e esvazia, então o tempo de soltar importa. Na cortada, a direção na hora da batida escolhe o lugar: esquerda ou direita, e pra frente (bola funda) ou pra trás (bola curta). A mira aparece quando o levantamento está no ar.

**Toque no tempo certo:** quando a bola vem pro seu atleta, um anel branco fecha em volta dele. Aperte quando o anel encostar no anel do atleta: amarelo é **Bom**, verde é **Perfeito!**. O texto aparece em cima do atleta.
- Passe perfeito cai na mão do levantador; passe ruim espirra e só deixa levantar alto, na ponta ou no fundo.
- Passe e levantamento perfeitos dão o **levantamento rápido** (bola baixa, que chega antes do bloqueio).
- Na cortada, aperte um pouco antes: o atleta pula e bate no alto do pulo. Cortada perfeita é forte e funda (a tela congela por um instante e treme); ruim sai fraca e torta.

**Placar e efeitos:** o placar fica em cima, no meio, como numa transmissão: o emblema e o nome de cada time num bloco inclinado, os pontos numa caixa com a borda na cor do time e, no meio, o set atual com uma bolinha por set (pintada na cor de quem ganhou). Uma bola pequena mostra quem saca. Quando sai ponto, um corte de luz dourado atravessa a caixa de quem pontuou, saem faíscas, o número salta e fica amarelo um instante. Embaixo aparece **SET POINT**, **MATCH POINT** ou **PONTO DECISIVO** (quando os dois fecham o set com o próximo ponto); no fim do jogo o meio mostra **FIM** e a caixa do vencedor brilha. Uma faixa escura com a ponta na cor do time e o emblema de quem pontuou atravessa a tela: **PONTO!** (com o motivo, se foi falta), **ACE!** (saque que cai sem ninguém tocar), **BLOQUEIO!**, **SET!** e **JOGO!**. A bola que cai dentro abre uma onda no chão e treme a tela. O bloqueio congela o jogo por um instante, treme a tela e mostra "Bloqueio!" em cima da bola.

**Largada:** depois de apertar Ataque, aperte **Passe** enquanto o atleta está no ar. Em vez de bater, ele empurra a bola devagar **por cima do bloqueio**, e ela cai curta, entre 1 e 3 m da rede. A direção escolhe o lado. Funciona bem quando o bloqueio está fechado e a defesa está lá atrás. Contra uma defesa que espera perto da rede, é bola fácil.

**Leitura do bloqueio:** quando o adversário levanta, os bloqueadores levam um instante (0,4 s) pra ler o levantamento. Depois correm pra onde a bola vai ser atacada. O central vai sempre, e o da ponta só ajuda se a bola vai pro lado dele. No levantamento alto dá tempo de montar o bloqueio. No **levantamento rápido** sobra pouco tempo pra correr e acertar o pulo, então ele é a melhor arma contra um bloqueio forte.

**Mergulho:** aperte **Mergulho** quando a bola estiver baixa (até 1,4 m) e longe demais pro passe normal. O atleta se joga e alcança até uns 3,2 m, bem mais que o passe (1,8 m). Mas a bola sai pior: no máximo **Bom**, e **Ruim** quando ela estava fora do alcance normal. Depois ele fica **no chão** por 0,8 s, sem andar. Mergulhar sem bola por perto também derruba o atleta, então não mergulhe à toa.

**Atributos dos times** (1 a 5, em `dados/times.json`; 3 é o normal):
- **Ataque:** janela de tempo da cortada maior e cortada mais forte.
- **Defesa:** janela de tempo do passe maior e mergulho mais longo.
- **Saque:** o saque erra menos (círculo da mira menor).
- **Bloqueio:** o bloqueio cobre mais rede.
- **Velocidade:** os atletas correm mais rápido.

Os atletas que você não controla se posicionam sozinhos, e o time gira o **rodízio** quando recupera o saque. A tela é **dividida**: o Jogador 1 vê de trás do time dele na metade esquerda, o Jogador 2 na metade direita. "Cima" é sempre na direção da rede pra cada um. A câmera fica parada atrás do time, mas vira de leve pra acompanhar a bola, como numa transmissão. As mensagens de cada time (saque, recepção, levantamento) aparecem na metade dele; as do ponto, no meio. Pra voltar pra uma câmera só, abra `cenas/partida.tscn`, selecione o nó `Partida` e desmarque **Tela Dividida** no Inspetor (lá também dá pra ajustar a altura, a distância e o foco da câmera, e ligar ou desligar o **Visual Anime**: sombra "chapada" e contorno escuro nos atletas e na bola).

### Regras do vôlei

O jogo segue as regras oficiais (FIVB). Só o placar é do jogo: sets até 7, com 2 de diferença e limite em 10, melhor de 3. Quando sai uma falta, a mensagem do ponto diz qual foi.

- **Escalação:** 6 atletas por time, sem líbero, no sistema 5-1 (um levantador). Na ordem de saque: levantador, ponteiro, central, oposto, ponteiro, central. O levantador fica sempre do lado oposto do oposto, e sempre tem 1 ponteiro e 1 central na rede. A função de cada atleta vem do campo `posicao` em `dados/elenco.json`.
- **Rodízio:** posições 1 a 6 (2, 3 e 4 na rede; 1, 6 e 5 no fundo). Quem ganha o saque de volta gira no sentido horário, e quem vai pra posição 1 saca. Cada set começa com a escalação do começo.
- **Posição no saque:** na hora em que a bola é sacada, cada time tem que estar na ordem do rodízio (cada um da rede na frente do colega de fundo da mesma coluna; da esquerda pra direita, 4-3-2 na rede e 5-6-1 no fundo). Fora de ordem: **posição errada no saque**. O atleta que você controla antes do saque não consegue sair da ordem. Depois do saque, cada um vai pro lado da sua função e o levantador do fundo infiltra pra levantar.
- **Saque:** 8 segundos pra sacar (**demorou pra sacar**; os 3 últimos aparecem na tela). Quem sacou não toca no próprio saque. Quem saca primeiro: sorteio no 1º set, o outro time no 2º, sorteio de novo no 3º.
- **Toques:** até 3 por time (**4 toques**). O mesmo atleta não toca duas vezes seguidas (**dois toques**). O bloqueio não conta como toque, e quem bloqueou pode tocar de novo.
- **Ataque e bloqueio:** só os 3 da rede bloqueiam. Atleta do fundo só ataca com a bola acima da rede se pular de trás da linha de 3 m (**ataque do fundo**). Não pode bloquear o saque (**bloqueio no saque**) nem atacá-lo com a bola acima da rede, perto dela (**ataque no saque**).
- **Rede:** pular colado na rede é **toque na rede**. A bola tem que passar entre as antenas, que ficam em cima das linhas laterais (**fora da antena**).
- **Quem vai na bola:** o jogo passa o controle pro atleta certo: o 1º toque é de quem estiver mais perto (o levantador evita, pra poder levantar), o 2º é do levantador e o 3º é de quem pode atacar dali (da rede na frente da linha de 3 m, do fundo atrás dela).

## Pastas

| Pasta | O que tem |
| --- | --- |
| `cenas/` | Cenas do Godot (`.tscn`): `menu_principal.tscn` (abre primeiro), `selecao_de_times.tscn` e `partida.tscn`. Com a partida aberta no editor, **F6** roda só ela (Karasuno x Nekoma no Ginásio Japonês). |
| `scripts/regras/` | Regras puras, sem gráfico: placar, sets, rodízio, escalação (`escalacao.gd`), formação no saque (`formacao.gd`), toques, trajetória da bola, escolha do atacante. |
| `scripts/entrada/` | Teclado e controle viram "comandos". A lógica do jogo não sabe se o comando veio do teclado ou da internet, o que facilita o online depois. |
| `scripts/partida/` | O que acontece na quadra. |
| `scripts/menus/` | Menu principal, seleção de times (`selecao.gd` tem as regras, `selecao_de_times.gd` desenha a tela, `retrato_do_atleta.gd` mostra o atleta em 3D), pausa e fim de jogo. `estilo.gd` guarda as cores e fontes de todos os menus. `configuracao.gd` guarda os times e o estádio escolhidos. |
| `scripts/comum/` | `dados.gd` lê os arquivos da pasta `dados/`. |
| `fontes/` | Fonte Barlow Condensed (licença livre OFL, em `LICENCA_OFL.txt`). |
| `shaders/` | Efeito anime: `anime.gdshader` (luz e sombra em faixas) e `contorno.gdshader` (contorno escuro). Cenário: `piso_de_madeira.gdshader`, `rede.gdshader` (malha vazada), `janela_entardecer.gdshader` e `grade.gdshader`. |
| `assets/polyfork/` | Três modelos gratuitos da [Polyfork](https://polyfork.dev) usados no Ginásio Japonês (carrinho de bolas, quadro branco, banco de tábua), licença CC BY 4.0. Créditos em `assets/polyfork/LEIA-ME.md`, detalhes em `manifesto.json`. |
| `scripts/cenario/` | O lugar da partida, montado em código: `cenario.gd` (quadra, linhas, rede com antenas, cadeira do juiz, árbitros, bancos com reservas e técnico, mesa do apontador), `ginasio_japones.gd` (ginásio de colégio ao entardecer) e `arena.gd` (arquibancadas, público, placas de LED e telão, pros outros três estádios). `pecas.gd` tem as peças simples (caixas, placas, textos, público instanciado). |
| `scripts/visual/` | `visual_anime.gd` cria materiais anime prontos: `VisualAnime.material(cor)`. |
| `dados/` | Times (atributos e cores), estádios (cores da quadra, do fundo, das placas e da luz) e cartas do Modo Caos, em JSON. Mudar um número aqui muda o jogo sem mexer em código. |
| `arte/` | `arte/emblemas/<id>.svg`: emblema de cada time (desenhos originais do jogo). `arte/icones/`: ícones dos menus (brancos; o jogo pinta na cor certa). Opcional: se você criar `arte/times/<id>.png` (um personagem com fundo transparente, ex.: `arte/times/karasuno.png`), ele aparece grande na seleção de times no lugar do atleta 3D. O atleta 3D é o do campo `destaque` em `dados/times.json`. `arte/estadios/<id>.png` vira a prévia do estádio. Os ids estão nos arquivos de `dados/`. |
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
godot --headless --script res://testes/teste_escalacao.gd
godot --headless --script res://testes/teste_formacao.gd
godot --headless --script res://testes/teste_regras_na_partida.gd
godot --headless --script res://testes/teste_selecao.gd
godot --headless --script res://testes/teste_dados.gd
godot --headless --script res://testes/teste_animacoes.gd
godot --headless --script res://testes/teste_animador.gd
```

Ou todos de uma vez (29 arquivos, incluindo tempo do toque, mira, cortada, atributos, mergulho, jogadas e placar):

```
for t in testes/teste_*.gd; do godot --headless --script res://$t; done
```

Cada um deve terminar com uma linha começando com `OK:`.

Todos os testes passam no Godot 4.7.2 (antes, 4.3), e a partida, os menus e a seleção de times rodam sem erros (testado em 09/11/2026). Com as regras oficiais, um robô jogou partidas inteiras dos dois lados (3 sets) sem erro.

## Próximos passos

Seguindo as fases do documento de design:

1. Aprender Godot (trilha de tutoriais no documento).
2. ~~Bola e quadra: física da bola, marcador de queda.~~ Feito.
3. ~~Um time controlado: troca automática de atleta, passe, levantamento, cortada.~~ Feito.
4. ~~IA de posicionamento dos 5 atletas sem controle.~~ Feito (com bloqueio e rodízio).
5. Partida completa local (MVP): ~~menus, seleção de times e estádios~~ feito. Personagens gerados por código já em quadra; modelos VRoid são opcionais (passo a passo no [guia](https://claude.ai/artifact/NitRJ4DP8oGWkKQJLS1k6A)).

Os nomes e times inspirados em Haikyuu são só pra jogar entre amigos. Se um dia o jogo for publicado, eles precisam virar times próprios, por isso ficam todos em `dados/times.json`.
