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
| 2. IA e modo contra o computador | Dificuldades, menu de 1 jogador, IA dos companheiros, robô medindo o rally | Não começada |
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
