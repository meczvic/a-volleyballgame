# Auditoria de jogabilidade 2 (13/11/2026)

Feita depois de o Victor jogar com a câmera nova, o levantamento segurado, as
arenas e os níveis novos. Cada item tem o que ele sentiu, o que o código e as
medições mostram, e a proposta. Respostas dele antes da auditoria: câmera
**escolhida no menu**; cortada **toque curto = largada, segurar = forte**; toque
na rede **tirar**; animações que incomodam: **todas** (levantamento, saque
viagem, cortada e bloqueio, correr e defender).

## 1. As animações quase não mudaram (a causa principal)
- **Sentiu:** parecem as mesmas de antes, quase sem mudança.
- **Achado:** as animações novas do DeepMotion **estão** no jogo, mas tocam
  aceleradas e cortadas. A tabela `TRECHOS` (`scripts/visual/animador.gd`)
  mostra só um pedaço de cada vídeo, e muito rápido:

  | Lance | Pedaço usado | Velocidade | Dura na tela |
  | --- | --- | --- | --- |
  | Saque em pé | 5,1 a 6,6 s | **3,0x** | 0,5 s |
  | Saque viagem | 3,6 a 6,25 s | **4,4x** | 0,6 s |
  | Cortada | 1,25 a 2,0 s | 1,2x | 0,6 s (só o pulo) |
  | Manchete | 2,2 a 3,0 s | 1x | 0,8 s |
  | Levantamento | 1,25 a 2,3 s | 1x | 1,0 s |

  Um saque viagem de verdade leva uns 2 s (corrida, lançamento, pulo, batida);
  aqui a animação inteira passa em 0,6 s, quatro vezes mais rápido que a
  pessoa do vídeo. Com a câmera a 17 m, isso vira um borrão. Bloqueio,
  mergulho, corrida e espera ainda são do Mixamo.
- **Proposta:** o jogo esperar a animação, e não o contrário: o tempo do saque
  e da cortada passa a seguir o tempo real do movimento (corrida de 2 a 3
  passos na cortada, lançamento e pulo no saque viagem), com velocidade perto
  de 1x. Pra bloqueio, mergulho e corrida: animações novas do DeepMotion
  (sobram 36 créditos; cada uma gasta de 5 a 8).

## 2. O levantamento parece manchete
- **Achado:** o levantamento do DeepMotion começa com os braços esticados pra
  frente e os joelhos dobrados (igual à manchete), e é justo esse pedaço que o
  jogo usa no preparo, enquanto a bola chega (`PREPARO`, 0,6 a 1,25 s). As mãos
  só passam da cabeça depois que a bola já saiu.
- **Proposta:** preparo com as mãos já em cima da testa (pegar outro pedaço do
  vídeo ou ajustar os braços por código). Se o vídeo não tiver essa pose, fazer
  um levantamento novo no DeepMotion com outro vídeo do Pexels, de frente.

## 3. O saque viagem tem menos força que o flutuante
- **Achado (medido com as regras do jogo, 14 m até o meio da outra quadra):**

  | Força | Flutuante | Viagem |
  | --- | --- | --- |
  | 0 | 1,15 s, 62 km/h | **1,22 s, 53 km/h** |
  | 0,5 | 0,96 s, 63 km/h | 0,87 s, 63 km/h |
  | 1 | 0,83 s, 67 km/h | 0,63 s, 81 km/h |

  Com pouca força, o viagem é **mais lento** que o flutuante. Na força máxima,
  é só 20% mais rápido. No vôlei, o viagem passa de 90 km/h e o flutuante fica
  entre 60 e 75 km/h, e o que torna o flutuante difícil é o balanço da bola.
  No jogo, o flutuante ainda não balança (está escrito "o balanço vem depois"
  em `partida.gd`), e a animação do viagem dura só 0,6 s (item 1).
- **Proposta:** viagem sempre mais rápido que o flutuante (de 80 a 110 km/h na
  tela), com mais risco de sair. Flutuante mais lento, mas balançando no ar
  (muda um pouco de lado no meio do voo, e o anel de queda treme).

## 4. Cortada sem força
- **Hoje:** apertar o ataque = pular e cortar; a força sai só do tempo do
  botão (Perfeito, Bom, Ruim). A largada é outro botão (passe) no ar.
- **Proposta (escolha do Victor):** apertar = pular. **Soltar rápido** = largada.
  **Segurar até a batida** = cortada forte; quanto mais tempo segurando, mais
  forte, com mais risco de bater na rede ou sair. Igual ao levantamento: dá pra
  ver o braço armando enquanto segura. O computador e o robô fazem igual.

## 5. Toque na rede
- **Hoje:** só existe no bloqueio. Quem pula a menos de `DISTANCIA_MINIMA_DA_REDE`
  da rede perde o ponto (`bloqueio_na_partida.gd`). Não há aviso antes, e
  quem joga não tem como medir essa distância na tela.
- **Proposta (escolha do Victor):** tirar a falta. O bloqueador colado na rede
  só é empurrado pra trás, sem perder ponto.

## 6. A bola é um globo branco gigante
- **Achado:** é uma esfera lisa cor de creme, sem gomos e sem girar, com raio
  de 0,22 m, mais que o dobro da bola de verdade (0,105 m). O tamanho grande
  era pra câmera de TV, de longe; na câmera perto, ela ocupa muito espaço.
- **Proposta:** bola com gomos (painéis curvos em 3 cores, desenhados por
  código, sem marca), girando no voo (gira mais rápido na cortada, e o
  flutuante quase não gira), com contorno fino e menor na câmera perto (uns
  0,15 m). Na câmera de TV, ela continua maior.

## 7. Câmera
- **Hoje:** a câmera perto vale pra 1 jogador e online; a tela dividida usa a
  de TV. Não dá pra trocar.
- **Proposta (escolha do Victor):** escolher no menu e na pausa: **Perto**
  (atual), **TV** (lateral, alta) e **Alta** (atrás e mais de cima, pra ver as
  duas quadras). Fica salva pra próxima partida.

## Ordem sugerida
1. Toque na rede (rápido, tira frustração).
2. Saque viagem x flutuante (números) e bola nova.
3. Cortada segurada (força).
4. Câmera no menu.
5. Animações: tempo do jogo esperando a animação (saque, cortada) e preparo do
   levantamento. Depois, DeepMotion novo para bloqueio, mergulho e corrida
   (avisar antes de pôr no jogo).

## O que foi feito (13/11/2026)
Escolhido pelo Victor: tudo, com bola amarela e azul e DeepMotion só avisando
antes de pôr no jogo.

1. **Toque na rede:** a falta não existe mais; quem pula colado na rede é
   afastado até 0,5 m (`_afastar_da_rede` na partida).
2. **Saques:** o viagem sai do alto do pulo quase reto, a 19–24 m/s (68–86
   km/h), sempre mais rápido que o flutuante. Na primeira versão (21–27 m/s),
   o Normal tomava 30% dos pontos em ace; com 19–24, caiu pra 9%. O flutuante
   sai mais alto e quase não acelera com a força (de 5,3 a 4,3 m de altura) e
   **balança** duas vezes no voo: a queda muda até 1,4 m, o anel anda junto, e
   o balanço nunca joga pra fora uma bola que ia cair dentro.
3. **Saque no tempo de verdade:** soltou, o viagem corre 0,62 s lançando a bola
   (parábola de verdade, sobe a ~3,9 m), pula e bate 1,05 s depois de soltar;
   o flutuante lança e bate em 0,6 s. Antes a bola saía em 0,3 s e a animação
   passava 4,4 vezes mais rápida; agora o vídeo passa a 3x (viagem) e 2x (em
   pé), que são câmera lenta, e a corrida aparece.
4. **Levantamento:** o preparo começa com as mãos subindo do peito (0,9 s do
   vídeo) e o contato é com as mãos na testa (1,45 s). Visto no jogo: as duas
   mãos sobem acima da cabeça. O vídeo estica pouco os braços depois.
5. **Cortada:** antes de apertar, a última passada e o braço indo pra trás
   (preparo de 0,55 s). Apertar pula; **soltar em menos de 0,12 s = largada**;
   segurar mais deixa mais forte (10% a mais de velocidade no talo, 30% a mais
   de erro e, acima de 75% de força, a bola pode sair). Apertou cedo e soltou
   antes de dar? Vale o tempo que segurou. Computador e robô fazem igual.
6. **Bola:** gomos amarelos e azuis (shader `shaders/bola.gdshader`, sem
   textura), costura escura, contorno fino, girando no voo (rápida na
   cortada, quase parada no flutuante). Raio de 0,15 m na câmera perto (era
   0,22) e rastro amarelado e mais fino.
7. **Câmera:** botão no menu principal e na pausa: **Perto**, **TV**, **Alta**
   (`Configuracao.camera`, salvo em `user://opcoes.cfg`; números em
   `dados/ajustes.json`, grupos `camera` e `camera_alta`). A pausa troca na hora.

**Medido depois (robô x computador, 3 partidas de 5 min):** Fácil 72% dos
pontos pro robô, 24% dos pontos em 1–2 bolas; Normal 46% pro robô (antes
44%), aces 11%. Os pontos do computador no Normal vêm quase todos de erro do
robô (30 de 47).

**Falta:** DeepMotion (cortada com corrida, vídeo 6216857, e mergulho,
12169434). O navegador do app não abriu o site e o Chrome não estava
conectado. Bloqueio não tem vídeo bom com licença livre (todos têm várias
pessoas na rede). Corrida e espera continuam do Mixamo.

**DeepMotion (13/11/2026, mais tarde):** feitos a cortada com corrida (6216857,
4 créditos) e o mergulho (12169434, 4 créditos). O **mergulho** entrou no jogo
como mergulho pra direita (o da esquerda continua do Mixamo). A **cortada com
corrida ficou de fora**: o DeepMotion não pegou o pulo, a qualidade foi 70,5% e
o peito gira de lado na batida. O FBX fica em `animacoes/deepmotion/` caso
sirva depois. Sobram uns 28 créditos.

**Saque viagem, depois de o Victor jogar (13/11/2026):** ele viu o atleta
correndo de lado e pisando na linha. Medido na partida, quadro a quadro: o pé
passava da linha de fundo (8,48 m, linha em 9 m) aos 0,4 s, ainda no chão, e o
peito começava uns 75° virado (o vídeo foi filmado com a câmera acompanhando o
atleta de lado). Arrumado: o quadril do saque viagem fica sempre virado como
na batida (`GIRO_TRAVADO` no animador; o tronco ainda gira sobre ele), o
sacador começa 2 m atrás da linha (era 1 m) e a corrida para a 0,9 m dela.
Agora o pé mais perto fica em ~9,1 m até sair do chão e o peito fica de frente
pra rede o tempo todo. `teste_auditoria_2` confere as duas coisas com a
animação rodando (e falha com o código antigo).
