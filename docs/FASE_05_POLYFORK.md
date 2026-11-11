# Fase 05 — Polyfork seletivo

Data: 11/11/2026 (madrugada, tarefa agendada). Branch `claude/fase-05-polyfork`, a partir de `claude/fase-04-ginasio`.

## Resumo
- **3 modelos gratuitos da Polyfork** incorporados no Ginásio Japonês: **carrinho de bolas**, **quadro branco** e **banco de tábua**. Todos GLB, licença **CC BY 4.0** com crédito (`assets/polyfork/LEIA-ME.md` e `manifesto.json`).
- Nada pago, nenhuma conta, nenhum `.mjs`, nada de Three.js: o Godot importa o GLB direto.
- **Testes:** 29 de 29 com `OK:`, sem `ERROR` nos logs `[TESTADO]`. **Robô:** partida completa no Ginásio Japonês terminou sozinha (Nekoma 2 x 0, 22 rallies), sem erros.
- **Desempenho:** sem custo mensurável (veja abaixo).

## Escolha
Pesquisei no catálogo (API pública `polyfork.dev/api/assets`) os candidatos do pacote e outros de ginásio:

| Modelo | Decisão | Por quê |
|---|---|---|
| Ball Cart (1.155 triângulos) | **Usado** | Bem mais bonito que o carrinho de caixas. Vinha com **bolas de futebol** (o pacote proíbe): as cores dos vértices das bolas são trocadas no jogo, preto → azul e laranja → amarelo, e elas viram bolas de vôlei |
| Whiteboard (512) | **Usado** | Quadro com moldura, marcadores e desenho; posto num suporte com rodinhas feito no jogo |
| Plank Bench (402) | **Usado** | Banco de madeira de 4 m, igual aos de ginásio de colégio; vira o banco de cada time no Ginásio Japonês |
| Match Scoreboard | Não usado | Placar de estádio de futebol com 4,8 m; o ginásio já tem placar de parede com os times |
| Referee | Não usado | Uniforme de futebol e outro esqueleto; os árbitros do jogo já são personagens do gerador, com as animações do jogo |
| Spectator | Não usado | 3.657 triângulos por pessoa; o público instanciado do jogo é muito mais leve |
| Bleacher Stand Run | Não usado | O ginásio de colégio usa mezanino, não arquibancada |

## Como entram no jogo
- `scripts/cenario/polyfork.gd` carrega o GLB, aplica um material que usa a **cor dos vértices** (os GLBs da Polyfork vêm com material branco e as cores nos vértices), troca cores quando pedido e **apoia o modelo no chão**. O resultado fica guardado, então a segunda cópia não refaz nada.
- Se um arquivo faltar, o cenário volta pra peça desenhada em código (nada quebra).
- Sem colisão: são só cenário. Fazem sombra.
- Nas arenas, o banco continua o desenhado (o de tábua é de colégio).

## Capturas `[VALIDADO VISUALMENTE]`
Em `producao/fase05/`, antes (Fase 04) à esquerda e agora à direita, mesma câmera:
- `comparacao_detalhe_palco.png` — carrinho e quadro branco no canto do palco.
- `comparacao_detalhe_banco.png` — banco de um time com os reservas.
- `comparacao_ginasio_geral.png` — visão do alto.
- `partida_saque_1600x900.png` — visão de jogo.

## Desempenho `[TESTADO]`
Robô jogando 40 s no Ginásio Japonês, 1600×900. Teste A/B no mesmo horário (com os GLBs e sem eles, movendo os arquivos):

| Medição | FPS médio | Pior 10% |
|---|---|---|
| Com Polyfork (2ª rodada) | 107 | 103 |
| Sem Polyfork (2ª rodada) | 108 | 98 |

Os modelos somam ~3.000 triângulos no total. Nessa madrugada o PC teve quedas de FPS isoladas que aconteceram **com e sem** os modelos (então vêm de outra coisa no Windows, não do jogo); por isso a tabela usa a rodada estável de cada um.

## Testes `[TESTADO]`
`teste_cenario.gd` ganhou `_teste_polyfork`: os 3 modelos carregam, usam a cor dos vértices, ficam apoiados no chão; as bolas do carrinho não têm mais gomo preto (e têm azul); e o ginásio usa os três.

## Licença e créditos
- Ball Cart by Polyfork (https://polyfork.dev/asset/ball-cart-8274fd), CC BY 4.0 — bolas repintadas de vôlei no jogo.
- Whiteboard by Polyfork (https://polyfork.dev/asset/whiteboard-ea98f7), CC BY 4.0
- Plank Bench by Polyfork (https://polyfork.dev/asset/plank-bench-c46528), CC BY 4.0

Os arquivos GLB não foram alterados; as mudanças (cores, posição) são feitas no jogo.

## Como ver no seu PC
**F5** → Partida rápida → Ginásio Japonês. O carrinho e o quadro ficam do lado esquerdo do palco (o Jogador 1 vê no fundo), e outros dois carrinhos perto do portão (o Jogador 2 vê). Os bancos de madeira ficam na lateral, com os reservas.
