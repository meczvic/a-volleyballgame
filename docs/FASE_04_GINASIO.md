# Fase 04 — Ginásio japonês low-poly (e base dos outros estádios)

Data: 11/11/2026. Referências: `image-gen-1(1).png`, `Vôlei no Ginásio ao Entardecer.png` e as imagens de partida (do pacote; não vão pro repositório).

## Resumo
- **Branch:** `claude/fase-04-ginasio`, a partir de `claude/fidelidade-referencias`.
- **Ambiente:** Windows 11, Godot 4.7.2, Vulkan Forward+, RTX 3060 Ti.
- **Testes:** 29 de 29 com `OK:`, sem `ERROR` nos logs `[TESTADO]`; teste novo `teste_cenario.gd`.
- **Partida completa do robô:** terminou sozinha em 292 s de jogo no Ginásio Japonês, Nekoma venceu por 2 sets a 0; 18 rallies, o maior com 110 toques; nenhuma linha de erro.
- **Física e regras sem mudança:** o cenário não tem colisão; quadra, rede e bola continuam com as medidas de `partida.gd` e `bola.gd` (o teste confere a altura da rede).

## O que foi feito
O cenário saiu de `partida.gd` (chão, mureta e uma faixa branca de rede) e foi pra `scripts/cenario/`, montado em código com formas simples e quatro shaders pequenos. Nada de modelos externos.

### Quadra e rede (todos os estádios)
- Quadra com a **zona de ataque mais escura**, linhas brancas nítidas, **linha dos 3 m tracejada pra fora** da quadra e marcas da zona de saque.
- **Rede de malha escura e vazada** (antes era uma faixa branca semitransparente que desbotava quem estava atrás), fita branca em cima e embaixo, faixas laterais, **antenas listradas** de vermelho e branco, **postes com proteção azul** e cabo.
- **Cadeira do juiz** azul com escada vermelha e o **1º árbitro** em cima; **2º árbitro** em pé do outro lado.
- **Bancos** dos dois times com **2 reservas e o técnico** (personagens do jogo, com o uniforme do time e números que o time não usa) e **mesa do apontador** com **2 mesários**.

### Ginásio japonês (`ginasio_japones.gd`)
- **Piso de madeira em tábuas** (shader: tom de cada tábua, emendas desencontradas, veio, brilho de encerado) e **reflexo** das janelas e paredes (uma captura só no começo).
- **Manchas de sol compridas e inclinadas** no chão, vindas das janelas da esquerda; **sol baixo e quente** com sombras longas.
- **Paredes**: lambri de madeira escura, friso claro, parede creme quente e **colunas de madeira** entre as janelas.
- **Janelas grandes ao entardecer** (céu rosa e dourado com árvores e caixilhos, num shader só) com **cortinas** abertas.
- **Mezanino** nas duas laterais com **guarda-corpo** e **faixas**: GARRA, CLUBE DE VÔLEI, RUMO À VITÓRIA!, a bola dourada, e as **faixas dos dois times** que estão jogando (cor, emblema e nome). **Público** em pé no mezanino, com camisas do colégio e dos times.
- **Palco** com **cortina vermelha** em dobras, bambolina com franja dourada, moldura de madeira, caixas de som, **brasão da escola** (desenho original), **placa com o nome** e **faixas verticais** DESAFIO e UNIÃO.
- **Portas** com placa verde de saída, **quadro branco** com a quadra desenhada, **carrinhos de bolas**, **mesa de água**, **cadeiras dobráveis azuis**, **portão de correr**, **placar de parede** com as cores e os nomes dos times, **relógio** e faixa FORÇA, EQUIPE!.
- **Teto** com tesouras de madeira, forro e **luminárias** penduradas.
- Textos das faixas e da placa em `dados/estadios.json` (dá pra trocar sem mexer em código). Nada em japonês.

### Outros três estádios (`arena.gd`)
Estrutura reaproveitável pra Arena Nacional, Arena Brasileira e Arena Neon: piso escuro brilhante, **placas de LED** com o letreiro do estádio, **arquibancadas** em degraus nos quatro lados com **público instanciado** nas cores do estádio e dos times, **telões** com o letreiro e refletores; a Neon tem faixas de neon. Letreiro e cores do público em `dados/estadios.json`.

### Câmera
A câmera de jogo ficava alta e longe, com lente fechada (só a quadra e um pedaço do chão apareciam). Agora fica **mais baixa e mais perto, com a lente um pouco mais aberta**: mostra o palco, as paredes, as faixas e o mezanino, deixa os atletas maiores e mantém **os quatro cantos da quadra na tela** (inclusive quando a câmera acompanha a bola no saque). Valores: altura **10,5**, distância **24**, foco **0**, abertura **37°** (antes 14,5 / 29,5 / 1,5 / 27°). Continua ajustável no Inspetor do nó `Partida`.

Como as câmeras ficam do lado de fora do ginásio, o que está no fundo atrás de cada time vai pra uma camada que a câmera daquele time não desenha (13 e 14), senão tamparia a quadra.

### Tela de seleção
As capturas do ginásio e das arenas viraram a **prévia de cada estádio** (`arte/estadios/<id>.png`) e o **fundo desfocado** da seleção, como na referência da Fase 01.

## Capturas `[VALIDADO VISUALMENTE]`
Em `producao/fase04/`:

| Arquivo | O que mostra |
|---|---|
| `comparacao_partida.png` | Partida esperando o saque: Fase 00 à esquerda, agora à direita |
| `comparacao_selecao.png` | Seleção: Fase 01 à esquerda, agora à direita (prévia e fundo do estádio) |
| `partida_saque_*.png` | Visão de jogo com os 12 atletas (1600×900 e 1280×720) |
| `ginasio_vazio_*.png` | Visão de jogo sem atletas nem bola |
| `ginasio_geral_*.png`, `ginasio_geral_vazio_*.png` | Visão do alto, de um canto, com e sem atletas |
| `ginasio_frente_vazio_*.png` | Na altura dos olhos, do fundo (mesmo enquadramento da `image-gen-1`) |
| `arena_*_geral_1600x900.png`, `arena_*_partida_1600x900.png` | As três arenas, visão do alto e visão de jogo |
| `selecao_*.png` | Seleção com a foto do estádio |

```
godot --path . --resolution 1600x900 --position -30000,-30000 --script res://ferramentas/capturas_de_tela.gd -- saida=producao/fase04 telas=ginasio,partida
godot --path . --resolution 1600x900 --position -30000,-30000 --script res://ferramentas/capturas_de_tela.gd -- saida=<pasta> telas=ginasio estadio=arena_neon
```

## Desempenho `[TESTADO]`
Robô jogando 40 s, 12 atletas + 2 árbitros + 8 pessoas em volta, tela dividida, `--print-fps`:

| Estádio | Resolução | FPS médio | Pior 10% | Mínimo |
|---|---|---|---|---|
| Ginásio Japonês | 1600×900 | 113 | 107 | 106 |
| Ginásio Japonês | 1280×720 | 114 | 109 | 104 |
| Arena Nacional | 1600×900 | 114 | 109 | 105 |
| Antes (Fase 00, sem cenário) | 1600×900 | 118 | 81 | 64 |

A média caiu ~4%, e o mínimo subiu (o engasgo isolado da Fase 00 não apareceu). Num PC mais fraco, os primeiros candidatos a desligar são o brilho (`glow`) e o reflexo (`ReflectionProbe`) em `ginasio_japones.gd`.

## Testes `[TESTADO]`
`testes/teste_cenario.gd` abre a partida nos 4 estádios e confere: estilo certo, rede presente e na mesma altura da física da bola, 2 árbitros, 8 pessoas em volta, uma luz e um ambiente, fundo dos dois lados, cada objeto do fundo na camada do seu lado, e que a câmera de cada time não desenha o fundo atrás dele (e desenha o do outro); também sem tela dividida.

## Arquivos
- `scripts/cenario/cenario.gd`, `ginasio_japones.gd`, `arena.gd`, `pecas.gd` — novos.
- `shaders/piso_de_madeira.gdshader`, `rede.gdshader`, `janela_entardecer.gdshader`, `grade.gdshader` — novos.
- `arte/cenario/brasao_escola.svg` — novo (desenho original).
- `arte/estadios/*.png` — prévias dos 4 estádios (capturas do jogo).
- `scripts/partida/partida.gd` — as funções antigas de chão, placas, rede e luz saíram; entrou `_criar_cenario()`, a camada escondida em cada câmera e a câmera nova.
- `scripts/menus/selecao_de_times.gd` — fundo com a foto do estádio, desfocada.
- `scripts/partida/placar_visual.gd` — correção: o efeito de ponto não desenha mais formas achatadas no último instante (gerava erro no log).
- `dados/estadios.json` — estilo, textos, letreiros e cores do público.
- `testes/teste_cenario.gd`, `ferramentas/capturas_de_tela.gd` (telas do ginásio).

## Polyfork
Não usei nenhum asset do Polyfork nesta fase: tudo foi feito em código. A escolha de 1 a 3 objetos do Polyfork é a Fase 05.

## Como testar no seu PC
1. **F5** → Partida rápida → escolham os times → no estádio, passe pelos 4 e veja a prévia mudar (e o fundo da tela junto).
2. Escolha o **Ginásio Japonês**: jogue e repare na rede (dá pra ver os atletas atrás), nas antenas, no palco e nas faixas lá no fundo, e no chão de madeira com as manchas de sol.
3. Teste as outras arenas.
4. Se achar a câmera nova perto ou aberta demais: `cenas/partida.tscn` → nó `Partida` → Inspetor → altura, distância, foco e abertura.
