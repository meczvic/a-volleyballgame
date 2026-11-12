# Plano de jogabilidade

Escrito em **12/11/2026**, a partir das respostas do Victor. Objetivo: deixar a partida mais gostosa de jogar antes de seguir com o online e a arrumação do código ([HANDOFF_MELHORIAS.md](HANDOFF_MELHORIAS.md)).

## O que o Victor decidiu

- **O que está fraco:** falta de sensação (impacto), controle confuso, rally curto e sem estratégia, IA fraca. Os quatro.
- **Estilo:** **arcade exagerado** (cortadas espetaculares, bola rápida, muito impacto, estilo anime de esporte).
- **Controle:** manter a **troca automática** de atleta.
- **Modo contra o computador:** sim, com Fácil, Normal e Difícil.
- **Som:** sim, efeitos agora; música depois.
- **Estratégia:** mais tipos de ataque, defesa mais difícil e divertida, medidor de energia com super golpe e escolhas táticas do time.
- **Como trabalhar:** Claude propõe e o Victor aprova; o Victor testa jogando no PC de casa.

## Etapas

| Etapa | O que faz | Situação |
| --- | --- | --- |
| **1. Sensação e controle** | Sons, seta no atleta controlado, impacto da cortada (zoom, faíscas, rastro), destaque do Perfeito, som quando o botão não dá | **Feita no código em 12/11/2026**, falta testar no Godot |
| **2. IA e modo contra o computador** | Dificuldades, menu de 1 jogador, IA dos companheiros, robô medindo o rally | **Feita em 12/11/2026**, testada no Godot; falta você jogar |
| 3. Estratégia no rally | Mais ataques (de meio, bola de segunda, finta), defesa com leitura, jogadas do levantador, bloqueio duplo/triplo | Não começada |
| 4. Super golpe | Medidor que enche com toques bons e libera uma jogada especial | Não começada |
| 5. Ajuste e arrumação | Números de equilíbrio em `dados/ajustes.json`, quebrar o `partida.gd` onde as etapas mexerem | Não começada |

## Etapa 1: o que mudou

Tudo é **só som e visual**: nenhuma regra, número de equilíbrio ou sorteio da partida mudou. Por isso a partida com semente (`teste_partida_com_semente.gd`) deve continuar dando o mesmo resultado.

- **Sons** (`scripts/audio/sons.gd`): saque, passe, levantamento, cortada, bloqueio, toque no bloqueio, bola na rede, bola no chão, mergulho, apito, torcida, sininho do Perfeito, som de erro (Ruim) e um "tic" quando o botão não deu. Os sons são **feitos pelo próprio jogo** (ondas e ruído), sem arquivo de áudio, então não há licença pra conferir. O volume e o tom de cada um ficam na tabela `AJUSTES`. Pra trocar por um arquivo de verdade, ponha o caminho em `SONS_DE_ARQUIVO`. A batida é mais forte quanto melhor o toque. Prévia em `producao/previa_sons/` (feita por um script Python com as mesmas fórmulas; o Godot ignora a pasta).
- **Seta do atleta controlado** (`scripts/partida/seta_do_controlado.gd`): triângulo na cor do time em cima da cabeça, sempre virado pra câmera. Quando o controle troca de atleta, ela **pula** pra você ver na hora com quem está. Com os dois no mesmo time, a do Jogador 2 usa a cor do uniforme reserva.
- **Impacto da cortada** (`scripts/visual/impacto.gd`, `scripts/visual/estouro.gd`, `scripts/visual/rastro.gd`): soco de zoom na câmera (5° na perfeita, 1,5° na normal, 3° no bloqueio), faíscas onde a mão bateu (douradas na perfeita), rastro da bola dourado e maior na perfeita. Faíscas na cor do time no bloqueio e na bola que cai dentro.
- **Perfeito!** maior (44 em vez de 30) e com sininho.
- Teste novo: `testes/teste_sons_e_impacto.gd`.

### O que conferir jogando (Etapa 1)

1. O volume de cada som está bom? Algum irrita (o apito, a torcida)?
2. A seta ajuda a saber quem você controla? Atrapalha a visão da bola?
3. A cortada perfeita parece forte? O zoom incomoda ou enjoa?
4. Ainda parece que o botão "não responde" em algum lance? Qual?

Ficou pra depois (precisa de você jogando): **aumentar o tempo do botão guardado** (`TEMPO_DO_PEDIDO`, hoje 0,15 s) e **animações com mais peso** (antecipação antes da batida). As duas mudam a partida com semente, então o teste dela precisa ser regravado junto.

## Etapa 2: plano (aprovado e feito em 12/11/2026)

### O que o Victor decidiu

- **Tela:** no modo contra o computador, tela cheia só pro Jogador 1 (sem dividir).
- **Dificuldade muda tudo:** quanto erra, quão rápido reage, quão esperto ataca e quão forte saca.
- **Companheiros mais espertos já nesta etapa**, mesmo mudando a partida com semente (o teste será regravado no Godot).
- **Menu:** botões "1 JOGADOR" e "2 JOGADORES" no menu principal.

### Partes

1. **Menu e escolhas.** No menu principal, "PARTIDA RÁPIDA" vira "2 JOGADORES" e entra "1 JOGADOR", que abre Fácil, Normal e Difícil. `Configuracao` ganha `contra_computador` e `dificuldade`. Na seleção de times, o Jogador 1 escolhe o próprio time e depois o do computador, com as mesmas teclas.
2. **Computador jogando.** Arquivo novo `scripts/entrada/entrada_do_computador.gd`: tem os mesmos sinais (`comando`, `soltou`) e a mesma `direcao` da `EntradaLocal`. A partida não sabe se quem joga é gente ou computador. Ele lê a bola e decide: andar até a queda, passar, levantar pra um lado, cortar mirando, largar, bloquear, mergulhar e sacar com força.
3. **Dificuldade nos dados.** Arquivo novo `dados/dificuldades.json`. Para cada nível: chance de errar o lance, atraso de reação, erro no tempo do botão (decide se sai Perfeito, Bom ou Ruim), chance de bloquear, força do saque, chance de mirar no buraco da sua quadra e chance de largada. Dá pra ajustar sem mexer no código.
4. **Tela cheia.** Contra o computador, a partida usa uma câmera só (já existe o jeito `tela_dividida = false`). O anel de tempo e a mira do computador ficam escondidos.
5. **Companheiros mais espertos** (`_alvo_da_ia` em `partida.gd`), pros dois times:
   - **Cobertura:** quando um atacante do time sobe pra cortar, dois companheiros chegam perto dele pra pegar a bola que voltar do bloqueio.
   - **Defesa que lê o ataque:** quando o adversário levanta, os do fundo se posicionam conforme o lado do atacante (diagonal e paralela), em vez de ficar parados no lugar da função.
   - **Sem amontoar:** dois atletas não ficam no mesmo lugar; quem está perto demais abre espaço.
6. **Robô e testes.** O robô ganha a opção `computador=<nível>`, que põe o computador de verdade jogando contra ele, e passa a mostrar a média de toques por rally. Teste novo `testes/teste_computador.gd`: computador contra computador em cada nível, sem erro de script, com rally de verdade (Difícil com rally mais longo que o Fácil). O teste da partida com semente tem que ser **regravado** (os companheiros mudaram).

### O que conferir jogando (Etapa 2)

1. O Fácil é fácil de verdade? O Difícil é desafiador sem ser injusto?
2. O computador parece "gente" ou faz algo estranho (fica parado, corre errado)?
3. Os seus companheiros cobrem e defendem melhor? Algum fica no caminho?
4. A tela cheia ficou boa? Falta alguma informação na tela?


## Etapa 3: plano (perguntas respondidas em 12/11/2026, falta aprovar)

### O que o Victor decidiu
- **Ataques novos:** ataque rápido do meio, bola de segunda, diagonal e paralela, ataque de fundo (pipe).
- **Defesa:** bloqueio duplo/triplo, bloqueio controlável, recepção com tempo, mergulho mais arriscado.
- **Tática do levantador:** direção (como hoje) + botão extra pra escolher o tipo de levantamento.
- **Ritmo:** rallies mais variados e com média mais longa (o robô mede).

### Como está hoje (pra entender o plano)
- Os 3 da rede **já pulam juntos** no bloqueio (`_bloquear`), e `_tipo_do_bloqueio` já decide DEVOLVE ou TOQUE pelo atleta mais bem posicionado. Então "duplo/triplo" vira **escolha sua**: quantos pulam.
- A cortada tem uma mira (esquerda/direita, curta/funda) e a qualidade do tempo decide força e erro (`TempoDoToque.CORTADA`).
- O levantamento tem 4 alvos (Ponta, Meio, Oposto, Fundo) e a altura vem da qualidade do passe/levantamento.

### Dividir em duas partes (recomendado)
Muita coisa muda a partida com semente, então cada parte regrava o teste uma vez.

**Parte 3A: ataque e tática**
1. **Tipo de levantamento (botão extra):** segurar **Ataque** junto com a direção do levantamento escolhe: *rápido* (bola baixa, chega antes do bloqueio, exige passe bom), *normal* ou *alto* (dá tempo de armar, mas o bloqueio fecha).
2. **Ataque rápido do meio:** o central bate numa bola baixa e veloz. Janela de tempo mais curta, mas o bloqueio só reage tarde.
3. **Diagonal e paralela:** a mira da cortada ganha dois jeitos claros: diagonal (cruza a quadra) e paralela (rente à lateral). A mira visual mostra qual é.
4. **Pipe (fundo):** cortada saindo de trás da linha de 3 m; mais forte que a normal de fundo e com bloqueio mais difícil (os da rede sobem atrasados).
5. **Bola de segunda:** apertar **Ataque** no 2º toque faz o levantador empurrar a bola pro outro lado (curta e sem força). Surpreende o bloqueio, mas a bola é fácil de pegar se ele ler.
6. **Computador** usa os novos ataques, mais no Difícil.

**Parte 3B: defesa**
1. **Quantos bloqueiam:** direção + Bloqueio escolhe **só 1**, **dupla** ou **tripla**. Quanto mais pulam, mais fechada a rede, mas sobra menos gente no fundo (a defesa fica com buraco).
2. **Bloqueio controlável:** bloqueio no tempo certo (Perfeito) devolve a bola mais forte e pro lugar que você mirar; sem tempo, só "toque" que a bola sobra.
3. **Recepção com tempo:** cortada forte (Perfeita) exige acertar o tempo do botão; senão a bola foge e vira passe ruim.
4. **Mergulho mais arriscado:** mergulhar fora do tempo deixa mais tempo no chão; no tempo, salva bola que antes era impossível.
5. **Computador** bloqueia dupla/tripla e mergulha conforme a dificuldade.

### Testes e dados
- Números novos em `dados/ajustes.json` (começa na Etapa 5, mas esta parte já cria o arquivo só com os números novos).
- Teste novo por parte (`teste_ataques.gd`, `teste_defesa.gd`) e teste com semente regravado.
- O robô passa a mostrar quantos ataques de cada tipo e a média de bolas por rally.

### Riscos
- O **rally pode ficar curto demais** se o ataque ficar forte e a defesa não acompanhar: por isso a 3B vem logo depois da 3A.
- Botões a mais: o levantamento depende de **segurar Ataque** antes do toque. Se ficar confuso jogando, vira opção no menu.
