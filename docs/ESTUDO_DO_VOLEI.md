# Estudo do vôlei (12/11/2026)

O Victor pediu um estudo de "tudo sobre vôlei" (partidas, regras, jogos, anime) porque muita coisa no jogo não está boa. Este documento junta o que o vôlei de verdade é, o que outros jogos de vôlei acertam e erram, o que o anime faz pra parecer forte, e compara com o **nosso jogo medido** (não "achado"). No fim tem a lista do que mudar, em ordem.

**Como foi feito, sem enrolar:** eu (Claude) não consigo assistir vídeo. Li regras oficiais, estudos científicos (velocidade de saque e cortada, duração de rally), material de treinadores (sistemas, recepção, defesa, tempos de ataque), críticas de outros jogos de vôlei e textos sobre a produção do anime Haikyuu. No jogo, medi tudo pelo Godot sem abrir janela (tempos de voo, rallies do computador contra ele mesmo, em que instante cada animação chega na pose de tocar a bola). Onde a fonte é fraca (blog, wiki de fã), está dito.

---

## 1. Números do vôlei de verdade x o nosso jogo

| O quê | Vôlei de verdade | Nosso jogo (medido) | Situação |
| --- | --- | --- | --- |
| Saque viagem (forte) | 83 a 91 km/h em média; os mais fortes passam de 100 km/h. Quem recebe tem **0,52 a 0,74 s** | ~68 km/h, ~0,8 s | Bom pra jogar (um pouco mais lento que o real, de propósito) |
| Saque flutuante | 41 a 48 km/h, ~1 a 1,3 s. Sem giro: **balança de lado** e cai de repente | Mais rápido que o real e **não balança** (o código diz "provisório") | Falta o principal do flutuante |
| Cortada | Homens ~90 a 100+ km/h; mulheres ~70 km/h | 79 km/h (perfeita), 65 (boa), 100 (super). Sai reta pra baixo | Bom |
| Duração do rally | ~5 s em média | — | — |
| Ataques por ponto | **1,25 a 1,6** | Computador **Normal**: ~7 bolas por rally (perto). **Difícil**: ~21 bolas por rally. Robô: 40+ | Difícil defende demais |
| Corrida da cortada | 3 ou 4 passos, ~3,4 a 4 m/s, pulo com os dois pés; o atacante começa a correr no 2º toque | Pula parado e "desliza" no ar até a bola | Falta a corrida |
| Ataque rápido (1º tempo) | O atacante **já está no ar** quando o levantador toca | O atacante só pula depois que a bola chega | Diferente do real |

Fontes dos números: [velocidade do saque e tempo de quem recebe (Palao e Valadés)](https://thesportjournal.org/article/normative-profiles-for-serve-speed-for-the-training-of-the-serve-and-reception-in-volleyball/), [saque viagem a 92 km/h ou mais muda o jogo](https://ped.muni.cz/en/research/research-and-development/publications/2394657), [velocidade da cortada na liga da Estônia](https://ojs.utlib.ee/index.php/PoA/article/download/poa.2016.25.1.04/8044/10380), [cortada de mulheres na Espanha](https://lida.sport-iat.de/dvv/Record/4035589), [cortada de homens na Bélgica](https://orbi.uliege.be/bitstream/2268/107039/2/Cloes%20et%20al%2c%2004%2c%20Thessaloniki%2c%20poster.pdf), [duração do rally (Mark Lebedew)](https://marklebedew.com/2021/08/17/rally-length-in-olympic-volleyball-2004-v-2021/), [ataques por ponto](https://coachingvb.com/womens-matches-have-longer-rallies), [corrida e altura do contato](https://ojs.ub.uni-konstanz.de/cpa/article/view/2606/2454), [tempos de ataque](https://opensourcevolleyball.blogspot.com/2015/11/volleyball-basics-offensive-tempo.html), [física do flutuante](https://en.wikipedia.org/wiki/Float_serve).

---

## 2. Animações: o problema mais visível (medido)

A crítica que mais aparece em outros jogos de vôlei é **"a animação não bate com a bola"**. O Spike Volleyball (2019) foi detonado por isso: "não vi nenhuma cortada encostar no atleta" e "parece sorte se o atleta reage a tempo" ([Operation Sports](https://operationsports.com/spike-volleyball-review), [The Xbox Hub](https://www.thexboxhub.com/spike-volleyball-review/), [Push Square](https://pushsquare.com/reviews/ps4/spike_volleyball)).

No nosso jogo, medi em que instante as mãos chegam na pose de tocar a bola, contando a partir do toque:

| Lance | Quando a pose de contato acontece | O que se vê |
| --- | --- | --- |
| Cortada | **Na hora** (tem o ímã da mão, foi bem feito) | Certo |
| Bloqueio | Na hora (alto do pulo = alto da animação) | Certo |
| Manchete | **0,30 s depois** que a bola já saiu; agacha 0,5 s depois | Parece um goleiro agarrando uma bola que já foi embora |
| Levantamento | **0,40 s depois** | As mãos sobem depois da bola sair |
| Saque em pé | A mão nunca passa da cabeça (1,37 m; cabeça a 1,57 m) | Arremesso por baixo, não é saque de vôlei |

Por que acontece: as animações vêm do Mixamo, que não tem nada de vôlei. A manchete é "goleiro agarrando", o saque é "goleiro arremessando". Além disso, a animação começa **no toque**, e não antes.

**O que dá pra fazer sem animação nova:** começar a animação já na pose de contato e tocar o "preparo" (abaixar, juntar os braços) sozinho quando a bola está chegando (~0,3 s antes). É o que os jogos bons fazem: o atleta se prepara antes, e o botão só confirma.

**O que precisa de animação nova (DeepMotion, como a cortada do Victor):** manchete, levantamento com as mãos acima da testa, saque em pé com o braço por cima, corrida de ataque (3 a 4 passos e pulo) e deslocamento do bloqueio (passo lateral cruzado). Veja a lista de gravações na seção 8.

---

## 3. Regras: o que mudou e o jogo ainda não sabe

- **Desde 2025, o time que saca não comete mais falta de posição.** Só o time que recebe precisa estar na ordem do rodízio quando o sacador bate na bola. Fontes: [diretrizes de arbitragem da CEV 2025](https://inside.cev.eu/media/bm4jik3r/new-guidelines-instructions-2025.pdf), [casebook da FIVB 2025](https://volleyboll.se/download/18.298f7086197176bdb6335667/1748597507597/FIVB%20CaseBook%202025.pdf), [sportrules.org](https://sportrules.org/volleyball/rotation-and-overlap/). **O nosso jogo ainda cobra dos dois times** (`_time_fora_de_posicao` em `partida.gd`). Mudança pequena.
- **Testes de 2025 e 2026 (ainda não são regra fixa):** o time que recebe pode se mexer a partir do lançamento da bola no saque; e dois toques do mesmo atleta no levantamento valem se a bola ficar do mesmo lado ([World of Volley](https://worldofvolley.com/latest_news/fivb/329401/fivb-introduces-rule-changes-to-modernize-volleyball.html), [FIVB aprova testes de 2026](https://worldofvolley.com/latest_news/fivb/334579/fivb-approves-2026-rule-changes.html)). Dá pra deixar como opção.
- Sem líbero, sem substituição e sem pedido de tempo: foram decisões do projeto pra jogo entre amigos, e continuam fazendo sentido. Set até 7 também.

---

## 4. Tática: como os times se posicionam de verdade

- **Defesa (corrigir o que eu fiz hoje):** a defesa mais usada no alto nível é a de **perímetro**. O atleta do **meio do fundo fica fundo**, no centro, e os dois das pontas fecham as diagonais perto das laterais. Na versão de hoje eu fiz o contrário (meio pra frente e pontas fundas), que é a defesa **rotacional**, usada contra largada. Fontes: [The Art of Coaching Volleyball](https://www.theartofcoachingvolleyball.com/digging-perimeter-defense/), [Sportplan](https://www.sportplan.net/drills/Volleyball/trends/defensive-systems-rotations-2025-05.jsp), [Coaches Insider](https://coachesinsider.com/volleyball/defensive-systems-article/). O certo: perímetro como padrão e rotacional quando o atacante do outro lado costuma largar (bom pra dificuldade ou carta).
- **A defesa nasce do bloqueio:** os do fundo ficam nas "sombras" que o bloqueio deixa abertas (diagonal e paralela fora do bloqueio). O bloqueio é a base da formação.
- **Recepção:** times de verdade recebem com **3 passadores** (os 2 ponteiros e o líbero). Os outros já ficam onde vão começar a corrida de ataque, e o levantador se esconde ([Gold Medal Squared](https://goldmedalsquared.com/post/volleyball-rotations/), [Volleyball Vault](https://volleyballvault.com/volleyball-rotations/)). O nosso "W" de hoje usa 5 passadores, que é o de time iniciante: funciona e é fácil de entender, mas o real seria 3 (ou 4) passadores com os atacantes prontos pra correr.
- **Sistema 5-1** (1 levantador, 5 atacantes): o jogo já usa.
- **Tempos de ataque:** 1º tempo (rápida: o atacante pula antes do levantamento), 2º tempo (sai logo depois, pra pegar o bloqueio já comprometido) e 3º tempo (bola alta). O jogo tem "rápido" e "normal" ou "alto", mas o atacante não corre antes da bola.

---

## 5. Outros jogos de vôlei: o que copiar e o que evitar

- **Volleyball Legends (Roblox)**, o que o Victor citou ([guia](https://rblxguide.com/games/volleyball-legends/updates/beginners-guide), [Pro Game Guides](https://progameguides.com/roblox/haikyuu-legends-beginners-guide/)): 6x6 e partidas de 1x1 a 4x4. Cada pessoa joga com um atleta. Um botão faz duas coisas: no chão é manchete, no ar é cortada; o outro levanta no chão e bloqueia no ar. Tem marcador de onde a bola cai. Quando o tempo do botão erra, aparece **"TOO LOW"**: o jogo diz claramente o que deu errado. A barra de habilidade enche tocando na bola, e o levantamento vai pra direção apertada.
  - Pra copiar: **aviso claro do erro** ("cedo", "tarde", "baixo"), modos menores (2x2 e 3x3 são ótimos pra jogar entre amigos) e um botão que muda de função no ar.
  - O nosso já tem: marcador de queda, levantamento com direção, barra de energia e atributos.
- **Spike Volleyball:** animação fora de sincronia, contato que parece sorte e IA ruim. É o que temos que evitar (veja a seção 2).
- **Super Volley Blast:** elogiado por ser rápido "como o vôlei de verdade, mas não impossível". Criticado porque o marcador de queda às vezes erra, porque sozinho fica repetitivo e por causa da IA ([OpenCritic](https://opencritic.com/game/6366/view), [Nintendo World Report](https://www.nintendoworldreport.com/review/47742)). Lição: o marcador tem que ser sempre confiável, e jogar contra o computador precisa de variedade.
- **Haikyu!! Fly High (celular):** elogiado pela apresentação. Criticado porque **os clipes do anime no meio da jogada irritam** ([Final Boss](https://finalboss.io/haikyu-fly-high-launches-globally-but-is-it), [GamingonPhone](https://gamingonphone.com/reviews/haikyu-fly-high-game-review)). Lição: efeito especial curto, sem tirar o controle do jogador.

---

## 6. O anime e a TV: por que parece forte

- **Haikyuu** ([entrevista com o animador Boya Liang](https://wavemotioncannon.com/2016/12/22/interview-haikyuus-boya-liang/), [Looper](https://www.looper.com/1078640/haikyuu-animator-boya-liang-breaks-down-that-show-stopping-mad-dog-scene-in-season-2), [Kotaku](https://kotaku.com.au/?p=1358953), [/Film](https://www.slashfilm.com/571818/haikyu)):
  - o golpe principal é desenhado quadro a quadro, com traço mais duro;
  - a ação **para ou fica em câmera lenta** no momento do golpe e depois acelera;
  - dá pra **ler a força da cortada** na tela;
  - o **som** (tênis no piso, mão na bola) faz metade do impacto.
  - O jogo já tem congelar, tremer, zoom, faíscas e rastro. Falta: o **quadro de impacto** (um instante em alto contraste na batida perfeita), as linhas de velocidade e o som do tênis no piso.
- **Técnicas do anime que são de verdade** (exageradas no desenho): rápida "maluca" (o atacante pula antes do levantamento e o levantador põe a bola na mão dele), ataque sincronizado (todos correm juntos, e o bloqueio não sabe quem vai atacar), ataque de um pé correndo ao longo da rede, saque flutuante com pulo, bloqueio que lê a jogada x bloqueio que adivinha, e o isca (atacante que corre só pra enganar). Boas ideias pra cartas do Modo Caos ou jogadas especiais. Fonte fraca aqui: não achei uma fonte boa que explique cada técnica; o resumo é do conhecimento geral do vôlei e do anime.
- **Comportamento entre pontos:** no vôlei de verdade **o time se junta no meio da quadra depois de quase todo ponto** (abraço, toque de mão, conversa rápida), principalmente pra manter o ânimo ([Scroll.in](https://scroll.in/field/1049860/team-spirit-and-momentum-why-volleyball-players-celebrate-nearly-each-point-won-with-gusto), [The Art of Coaching Volleyball](https://www.theartofcoachingvolleyball.com/3-neglected-seconds/)). No nosso jogo, cada um comemora parado no lugar.
- **Câmera de TV:** a principal fica alta, atrás da linha de fundo (a FIVB marca os lugares das câmeras de TV nas linhas de fundo), e o replay usa outros ângulos ([layout da VNL 2026](https://www.fivb.com/wp-content/uploads/2024/05/Volleyball-Field-of-Play-Layout-VNL-2026.pdf), [Hudl](https://www.hudl.com/blog/power-of-the-endline-camera-view)). A nossa câmera atrás de cada time está certa. Falta o **replay em câmera lenta** dos pontos bonitos, de outro ângulo (o jogo já grava os comandos; dá pra reaproveitar).

---

## 7. O que mudar, em ordem

Ordem pelo que mais melhora a sensação de jogar com menos trabalho.

| # | O quê | Por quê | Tamanho |
| --- | --- | --- | --- |
| 1 | ✅ **Feito.** **Manchete e levantamento no tempo da bola:** a animação começa na pose de contato, e o atleta se prepara sozinho ~0,35 s antes da bola chegar | Hoje a pose vem 0,3 a 0,4 s atrasada (medido). É a crítica nº 1 de jogos de vôlei | Pequeno |
| 2 | ✅ **Feito.** **Defesa em perímetro** (meio do fundo fundo, pontas fechando as diagonais) | Corrige o que eu inverti hoje. É como os times defendem | Pequeno |
| 3 | ✅ **Feito.** **Regra de 2025:** time que saca sem falta de posição | É a regra oficial atual | Pequeno |
| 4 | ✅ **Feito.** **Aviso claro do erro de tempo** ("Cedo!" ou "Tarde!") em vez de só "Ruim" | Tira a sensação de sorte (Spike Volleyball) e é o que o Roblox faz | Pequeno |
| 5 | **Flutuante que balança** (desvio de lado e queda no fim, sem aviso, mais lento que o viagem) | É o que faz o flutuante ser difícil de receber. Hoje é só um saque mais lento | Médio |
| 6 | **Ritmo do Difícil e do bloqueio:** meta de 1,5 a 2,5 ataques por ponto | Hoje o Difícil faz ~21 bolas por rally | Médio |
| 7 | **Recepção com 3 ou 4 passadores** e atacantes já posicionados pra correr | Mais parecido com o real e prepara o item 8 | Médio |
| 8 | **Corrida de ataque:** o atacante dá 2 a 3 passos e pula de dois pés (o `pulo_correndo.fbx` do Mixamo já está na pasta e serve de base) | Hoje ele pula parado e desliza no ar | Médio |
| 9 | **Time se junta depois do ponto** + **replay em câmera lenta** dos pontos bonitos | É o que faz parecer partida de TV | Médio |
| 10 | **Efeitos de anime:** quadro de impacto na cortada perfeita, linhas de velocidade, som de tênis no piso | O anime ganha força no instante do golpe e no som | Médio |
| 11 | **Modos 2x2 e 3x3** | O Roblox mostra que é o jeito mais divertido de jogar entre amigos; menos atletas = mais bola pra cada um | Grande |
| 12 | **Animações novas** (veja abaixo) | Sem isso, manchete, levantamento e saque em pé continuam parecendo de goleiro | Depende do Victor |

---

## 8. Gravações que só o Victor pode fazer (DeepMotion, como a cortada)

Cada clipe com 3 a 5 s, corpo inteiro no vídeo, câmera parada, de lado ou na diagonal, sem ninguém passando na frente:

1. **Manchete:** parado em posição de espera, abaixa, junta os braços e toca uma bola imaginária na altura da cintura.
2. **Levantamento:** mãos acima da testa, empurra a bola pra cima com os dedos (pernas estendem junto).
3. **Saque em pé (flutuante):** joga a bola, braço por cima da cabeça, bate com a mão aberta e para o braço (sem acompanhar).
4. **Corrida de ataque:** 3 passos (esquerdo, direito, esquerdo pra destro), braços vão pra trás no penúltimo passo, pula de dois pés.
5. **Deslocamento do bloqueio:** passo lateral cruzado ao longo da rede e pulo com as mãos passando por cima da rede.
6. Extra: **mergulho de vôlei** (deslizar de barriga, "peixinho") e **comemoração em grupo** (bater na mão do colega).

O caminho é o mesmo da cortada: `animacoes/deepmotion/` e `ferramentas/converte_deepmotion.gd` (veja `animacoes/LEIA-ME.md`).
