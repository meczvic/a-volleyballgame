# Auditoria de jogabilidade (13/11/2026)

Feita pelo Claude depois de o Victor jogar e listar o que incomoda. Juntei as
observações dele com medições (8 partidas do robô sem janela, 5 min cada, nos
três níveis) e com a leitura do código. Cada item tem **o problema**, **o número
ou a evidência** e **a proposta**. A ordem é do que mais pesa na diversão pro
que menos pesa.

Respostas do Victor antes da auditoria:
- câmera: **atrás do meu time** (estilo jogo de vôlei de console);
- jogadas: **segurar o botão** escolhe a altura do levantamento;
- movimentação: **posições automáticas** e um **treino**;
- Normal difícil porque **o computador defende tudo**.

## Números medidos

| Partida (5 min, sementes 1 e 2) | Bolas por rally (saque + toques) | Cortadas por rally | Maior rally |
| --- | --- | --- | --- |
| Computador x computador, Fácil | 2,1 a 2,6 | — | — |
| Computador x computador, Normal | 6,3 a 6,5 | — | — |
| Computador x computador, Difícil | 10,0 a 14,2 | — | — |
| Robô x computador Normal | 7,2 a 7,6 | **1,9 a 2,3** | 24 e 35 toques |

Vôlei de verdade: **1,3 a 1,6 ataques por rally** e uns 4 a 6 toques de bola
(estudo em `docs/ESTUDO_DO_VOLEI.md`). Contra o Normal o jogo tem quase **o
dobro de ataques por rally**: o ataque não termina o ponto, o computador
devolve. Bate com o que o Victor sentiu. O Difícil passa do triplo. O Fácil é o
contrário: o rally quase não existe (mais saque errado e ace que jogo).

## Lista, do mais importante pro menos

### 1. O computador defende demais (Normal)
- **Evidência:** 1,9 a 2,3 cortadas por rally contra 1,3 a 1,6 no real;
  rallies de 24 e 35 toques. Em `dados/dificuldades.json`, o Normal erra o
  tempo com desvio de 0,08 s e a janela "Bom" vai até 0,15 s: quando ele chega
  na bola, falha só ~6% por tempo, mais 7% de "chance_de_errar". O gargalo é
  que ele **chega em quase tudo**, inclusive na cortada reta de 18 a 22 m/s.
- **Proposta:** (a) uma cortada **Perfeita mirada longe do defensor** vira
  ponto (o defensor só toca se estiver a menos de ~1,5 m da linha da bola);
  (b) no Normal, reação 0,2 → 0,3 s, erro de tempo 0,08 → 0,11 s, mergulho
  0,6 → 0,4. Meta: robô x Normal com **1,4 a 1,6 cortadas por rally**, medido
  pelo robô antes de entregar.

### 2. Câmera atrás do time, mais perto
- **Evidência:** a câmera já fica atrás do time, mas longe: 24 m do centro
  (15 m atrás da linha de fundo), 10,5 m de altura, abertura de 37°. Os atletas
  saem pequenos e a quadra parece vista "de cima".
- **Proposta:** câmera de console: uns 6 a 7 m atrás da linha de fundo, 5 a 6 m
  de altura, abertura de 50 a 55°, acompanhando mais a bola pro lado. A atual
  vira a opção "TV" no menu de configuração. Na tela dividida continua a de hoje
  (não cabe a perto).

### 3. Levantamento com altura escolhida (segurar o botão)
- **Evidência:** hoje a altura **não é do jogador**: sai da qualidade
  (`TempoDoToque.altura_do_levantamento`). E ao contrário do esperado: passe
  Perfeito + levantamento Perfeito dá a bola **rápida e baixa** (3,4 m); o resto
  dá a normal (4,4 m). Por isso parece sempre a mesma bola.
- **Proposta:** segurar o botão de passe no levantamento: toque curto =
  **rápida** (3,4 m), meio = **normal** (4,4 m), longo = **alta** (5,4 m). Um
  medidor fino aparece perto do levantador só enquanto segura. A qualidade passa
  a mudar só a precisão. A direção continua escolhendo quem ataca.

### 4. As jogadas já existem, mas estão escondidas
- **Evidência:** o jogo já tem rápida do meio, **pipe** ("Fundo"), diagonal e
  paralela (`jeitos_de_atacar.gd`). Ninguém descobre: a rápida é segurar o
  botão do flutuante (I) e o pipe é apertar "pra trás" na hora do levantamento.
- **Proposta:** junto com o item 3, a rápida passa a ser o "toque curto" (sem
  botão extra). O pipe continua na direção "pra trás", ensinado no treino (item
  6), com uma seta discreta perto do atacante escolhido.

### 5. Tela mais limpa
- **Evidência:** o anel de tempo começa com 3 m de raio, branco e muda pra
  amarelo e verde (`anel_de_tempo.gd`); "Perfeito!/Bom/Ruim" em fonte 30 sobe
  em cima do atleta; a linha de ajuda dos botões fica sempre embaixo.
- **Proposta:** anel fino, de no máximo 1,2 m, só branco, que fecha no pé e dá
  um brilho rápido na hora certa (sem trocar de cor). Qualidade sem palavra: um
  ponto colorido pequeno no rastro da bola + o som (o Perfeito com um "ting").
  A ajuda dos botões só no treino e na pausa.

### 6. Posições automáticas e um treino
- **Evidência:** os companheiros recalculam o lugar **todo quadro**
  (`ia_dos_atletas.gd`: cobertura, defesa pelo lado do atacante, abrir espaço),
  então andam o tempo todo, um pouco pra cá e pra lá. E o atleta controlado troca
  sozinho a cada bola lançada (`_ao_lancar_bola` escolhe quem vai na bola), então
  o "eu" muda várias vezes por rally.
- **Proposta:** (a) os companheiros só mudam de lugar em 4 momentos (saque,
  recepção, nosso ataque, ataque deles) e vão direto, sem ficar ajustando;
  (b) uma marca discreta no chão mostra onde o controlado deve ir; (c) **Treino**
  no menu: 4 lições curtas (recepção, levantamento com altura, cortada e
  jogadas, defesa), uma de cada vez, com a ajuda dos botões que sai da partida.

### 7. Bola sem detalhe
- **Evidência:** é uma esfera de uma cor só (`bola.gd`), e não gira.
- **Proposta:** bola com os gomos em curva (dois tons, tipo a oficial azul e
  amarela, sem copiar marca) e girando conforme a velocidade. O giro também
  ajuda a ver o saque flutuante (quase sem giro) contra o viagem (girando).

### 8. Estádios "arena" difíceis de ler
- **Evidência:** os três "arena" usam o mesmo `arena.gd` com outras cores; o
  Victor achou feios e difícil de ver o jogo. O Ginásio Japonês é o melhor.
- **Proposta:** usar o ginásio como régua: quadra clara com linha branca
  grossa, fundo mais escuro e sem brilho atrás da quadra, luz de frente. Rever um
  por um, com prints (precisa abrir a janela uma vez, com o Victor de acordo).

### 9. Ritmo do Fácil e do Difícil
- **Evidência:** Fácil com 2,1 a 2,6 bolas por rally (quase só saque); Difícil
  com 10 a 14.
- **Proposta:** acertar depois do item 1, pelo mesmo robô: Fácil errando menos
  saque e mais na defesa; Difícil defendendo menos que hoje (ainda bem mais que
  o Normal).

### 10. Animações (pendente da rodada anterior)
- Saque viagem com pernas tortas em alguns quadros. Manchete com os braços perto
  do corpo. Bloqueio com deslocamento e mergulho ainda do Mixamo (achados 3
  vídeos de mergulho, ver `producao/videos_pexels/LEIA-ME.md`).

## Arenas, olhando os prints (13/11/2026, câmera nova)
- **Torcida:** centenas de bonecos de cores fortes e misturadas (confete) tomam
  metade da tela e chamam mais atenção que o jogo. No ginásio a torcida é pouca,
  de tons quentes e apagados.
- **Faixa do campeonato** atrás da rede fica escondida pelo placar.
- **Quadra x fundo:** na Neon, quadra azul em fundo roxo e linhas que se perdem;
  na Nacional, azul claro em azul escuro (dá pra ler, mas cansa).
- **Proposta:** torcida em 2 ou 3 tons apagados da cor do estádio, mais escura e
  menor; faixa do campeonato mais baixa; quadra com contorno claro em volta
  (como a linha de madeira do ginásio).
- **Feito (13/11/2026):** em `scripts/cenario/arena.gd`, só 40% da torcida usa
  as cores do estádio e dos times (misturadas com cinza); o resto veste roupa
  comum apagada, e tudo fica mais escuro (penumbra). Cada torcedor tem um
  tremidinho de lugar, de giro e de tamanho. O chão de fora das placas ficou
  escuro, e a área livre (dentro das placas) tem a cor do estádio, como um
  palco aceso. Quadras novas em `dados/estadios.json`: Nacional laranja em
  azul, Brasileira verde em azul (placas amarelas), Neon turquesa em roxo, com
  placas menos ofuscantes. O telão continua atrás do placar na tela dividida
  (na câmera nova de uma tela ele aparece inteiro).

## O que foi feito nesta rodada (13/11/2026)
Escolhidos pelo Victor: defesa do computador, câmera, levantamento com altura,
tela limpa e companheiros parados por momento.

1. **Defesa:** cortada Perfeita só é defendida a até 0,9 m da bola (Boa, 1,3 m);
   antes era 1,8 m pra tudo (`JeitosDeDefender.segura_cortada`, números em
   `dados/ajustes.json`). Normal: reação 0,2 → 0,25 s e mergulho 60% → 45%.
   Medido (robô x Normal, 3 sementes, 5 min): **1,74 → 1,54 cortadas por
   rally**; cortada Perfeita defendida pelo computador 37% → 31%.
2. **Levantamento segurando o passe:** no 2º toque, apertar não toca; soltar
   toca, e o tempo segurado escolhe a altura (menos de 0,2 s rápida, até 0,55 s
   normal, mais alta). Se segurar demais, levanta sozinho quando a bola ia sair
   do alcance (sai "Tarde"). O computador e o robô fazem igual. A dica está na
   linha de botões e no README.
3. **Câmera perto** (uma tela só): 17,5 m da rede, 6,5 m de altura, 52°,
   seguindo mais a bola pro lado (grupo "camera" em `dados/ajustes.json`;
   `"estilo": "tv"` volta a antiga). Tela dividida continua com a de TV.
4. **Tela limpa:** anel de tempo fino e só branco (no máximo 1,4 m); Perfeito
   sem texto (brilho verde pequeno na bola + sininho); Ruim escreve pequeno
   "Cedo!/Tarde!"; barras de energia na borda de baixo (estavam em cima da
   quadra); sem as dicas do time do computador no modo 1 jogador.
5. **Companheiros:** o lugar de cada um só muda quando muda o momento (cada bola
   lançada); vão direto, sem ficar ajustando. O bloqueio continua lendo a bola.

Teste novo: `testes/teste_auditoria_jogabilidade.gd`. Suíte: 49 de 49.

**Medição final com tudo junto** (5 min por partida):

| Partida | Antes | Depois |
| --- | --- | --- |
| Robô x Normal: cortadas do robô por rally | 1,9 a 2,3 | **1,3 a 1,6** |
| Robô x Normal: maior rally | 24 e 35 toques | 15 a 20 toques |
| Robô x Normal: bolas por rally | 7,2 a 7,6 | 5,2 a 6,1 |
| Computador x computador, Normal | 6,3 a 6,5 | 5,2 a 6,3 |
| Computador x computador, Fácil | 2,1 a 2,6 | 2,6 a 2,7 |
| Computador x computador, Difícil | 10,0 a 14,2 | **13,8 a 18,1** (piorou) |

O Normal ficou na faixa do vôlei de verdade. O Difícil ficou com rallies ainda
mais longos (o item 9 continua pendente) e o Fácil continua curto demais.

## Como medir cada mudança
O robô (`ferramentas/robo.gd`) já mostra bolas por rally e cortadas. Antes de
cada entrega: mesmas sementes, mesmo tempo, e comparar com a tabela acima. O que
é visual (câmera, anel, bola, estádios) precisa do Victor olhando.

## Ritmo do Fácil e do Difícil (item 9, feito em 13/11/2026)
O robô agora diz, no fim, quem fez quantos pontos e quantas bolas teve cada
ponto (e, com `ROBO_PONTOS=1`, como cada ponto acabou). Medido com o robô contra
o computador, 3 sementes, 5 min cada.

**O que se descobriu:**
- O Fácil era "quase só saque" por um motivo escondido: o computador sorteia se
  aperta antes ou depois da hora certa, e quando sorteia "depois" num saque
  rápido a bola bate no chão antes do toque (ace), com o atleta embaixo da bola.
  Novo número `chance_de_salvar_a_recepcao`: atrasado, ele toca no último
  instante e sai um passe ruim, não ace.
- O computador quase só ganha ponto quando o robô erra de propósito (12% por
  toque). Ou seja: quanto mais o computador segura a bola viva, mais o jogador
  erra. "Defende tudo" = jogador perde no cansaço.
- Números novos em `dados/dificuldades.json`: `chance_de_errar_na_recepcao`
  (separada da `chance_de_errar` do resto do rally) e `erro_do_tempo_na_cortada`
  (o computador pode receber bem e atacar fraco).

**Ajustes:** Fácil recebe bem (erra 4% na recepção, salva 85% das atrasadas),
mas erra 18% no meio do rally, reage devagar, quase não mergulha, ataca fraco e
larga muito. Normal igual ao de antes. Difícil defende um pouco menos (reação
0,16 s, mergulho 50%, salva 30% das recepções atrasadas).

| Robô x computador (3 partidas) | Antes | Depois |
| --- | --- | --- |
| Fácil: pontos do robô | 67% | 66% |
| Fácil: pontos em 1–2 bolas | **36%** | 16% |
| Fácil: bolas por rally | 4,1 a 4,7 | 4,5 a 5,3 |
| Normal: pontos do robô | 54% | 44% (mesmos números; só o sorteio mudou) |
| Difícil: pontos do robô | **21%** | 29% |
| Difícil: bolas por rally | 5,8 a 8,9 | 5,8 a 11,1 |
| Computador x computador, Fácil | 2,6 a 2,7 | 4,4 a 5,6 |
| Computador x computador, Difícil | **13,8 a 18,1** | 5,5 a 12,0 |

Robô "iniciante" (`erro=0.25`, erra 1 toque em 4) contra o Fácil: 47% dos
pontos. O robô erra igual em bola fácil e difícil; uma pessoa erra menos quando
a bola vem mansa, então pra gente o Fácil deve ser mais fácil que isso. Com 3
partidas a conta oscila uns 5 pontos pra cada lado (o Normal, sem mudar nada,
deu 54% e 44%).
