# Fase 02 — Placar e feedback de ponto

Data: 10/11/2026. Referência: `Placar Anime Karasuno vs Nekoma.png` (do pacote; não vai pro repositório).

## Resumo
- **Branch:** `claude/fase-02-placar`, a partir de `claude/fase-01-selecao`.
- **Ambiente:** Windows 11, Godot 4.7.2, Vulkan Forward+, RTX 3060 Ti.
- **Testes:** 27 de 27 com `OK:` `[TESTADO]`; `teste_placar_na_partida.gd` ganhou verificações do visual novo.
- **Partida completa pelo robô:** terminou sem erros.
- **Regras do placar** (`scripts/regras/placar.gd`): **não mudaram**. Set de 7 com 2 de diferença e limite em 10, melhor de 3: já cobertos por `teste_placar.gd` (`_teste_set_de_7_a_0`, `_teste_precisa_de_2_de_diferenca`, `_teste_limite_em_10`, `_teste_partida_acaba_com_2_sets`), que continua passando.

## O que mudou
| Antes | Agora |
|---|---|
| Faixa única: nome, bolinhas, número, "-", número, nome | Dois **blocos inclinados** com **emblema** e nome; os pontos em **caixas com a borda na cor do time**; no meio, o **set** |
| 2 bolinhas pequenas por time ao lado do nome | **Uma bolinha por set da partida** no meio (3), pintada na cor de **quem ganhou aquele set**, na ordem; o set atual fica contornado |
| Ponto colorido de quem saca | **Bola pequena** (ícone de vôlei) no canto do bloco de quem saca |
| Número pula e pisca | **Clarão** na caixa, **risco de luz** atravessando, número **salta e fica amarelo** ~1 s, placar **treme de leve** |
| SET POINT / MATCH POINT ao lado de "SET n" | Etiqueta embaixo do meio, na cor do time que pode fechar |
| Fim de jogo igual ao resto | Meio mostra **FIM**, a caixa do vencedor **brilha** e a bola do saque some |
| Faixa de ponto 900 x 128, fundo na cor do time | **680 x 104** (cerca de 40% menos área), fundo escuro, ponta grossa na cor do time e **emblema de quem pontuou** |

A conta dos pontos continua só em `placar.gd`; o placar visual só desenha o que recebe. A ordem de quem ganhou cada set é lembrada pelo próprio placar visual (comparando os sets entre uma atualização e outra), sem mexer na regra.

## Capturas `[VALIDADO VISUALMENTE]`
Em `producao/fase02/`, todas marcadas pelo caminho de verdade da partida (`_encerrar_rally`), Karasuno x Nekoma, 1600×900:

| Arquivo | Estado |
|---|---|
| `comparacao_placar_jogo.png` | 4 x 3 no meio do set (antes à esquerda, agora à direita) |
| `comparacao_placar_ponto.png` | 0,12 s depois do ponto: 6 x 3, efeito no meio, SET POINT |
| `comparacao_placar_set_point.png` | 6 x 3 parado, SET POINT |
| `comparacao_placar_set.png` | Karasuno fecha o set 1 (7 x 3), faixa SET! |
| `comparacao_placar_match_point.png` | Set 3, 6 x 5, MATCH POINT, bolinhas dos sets 1 e 2 pintadas |
| `comparacao_placar_fim.png` | Karasuno vence: FIM, brilho no vencedor |
| `placar_*_1600x900.png` | As mesmas cenas, tela inteira (dá pra ver a faixa de ponto e a tela dividida) |

O "antes" foi tirado do código da Fase 00 com a mesma ferramenta e os mesmos pontos.

A nova tela `placar` em `ferramentas/capturas_de_tela.gd` refaz tudo:

```
godot --path . --resolution 1600x900 --position -30000,-30000 --script res://ferramentas/capturas_de_tela.gd -- saida=producao/fase02 telas=placar
```

## Testes `[TESTADO]`
Novo em `teste_placar_na_partida.gd` (`_teste_visual_do_placar`):
- a bola do saque aparece no time que saca e passa pra quem ganha o ponto;
- o número de quem pontuou fica amarelo, o do outro não;
- a faixa de ponto mostra o emblema;
- set 1 do Nekoma e set 2 do Karasuno: as bolinhas guardam essa ordem;
- o set novo (SET 3, 0 x 0) aparece no saque seguinte (no fim do set o placar ainda mostra o resultado, como já era);
- fim de jogo: FIM, vencedor com 2 bolinhas, sem bola de saque.

Os testes que já existiam (pontos, pulo do número, SET POINT / MATCH POINT / sem aviso, faixa de ACE!/BLOQUEIO!/PONTO!/SET!/JOGO!, motivo da falta) continuam passando sem mudança.

## Partida pelo robô `[TESTADO]`
Partida completa sem janela (`--headless`), Karasuno x Nekoma: terminou sozinha em 267 s de jogo, Nekoma venceu por 2 sets a 0 (último set 7 x 0). 19 rallies, o maior com 34 toques; 112 passes, 108 levantamentos, 94 cortadas. Nenhuma linha de erro no log.

## Encaixe na tela dividida
O placar continua em cima, no meio, sobre a linha que divide as metades. Tem 940 px de largura e ~75 px de altura (o antigo tinha ~730 x 95), então ocupa a faixa de cima das duas metades sem chegar na quadra. O aviso de SET POINT fica logo embaixo do meio, sem cobrir a quadra.

## Arquivos
- `scripts/partida/placar_visual.gd` — refeito (mesmas funções públicas: `configurar`, `atualizar`, `comemorar`, `texto_dos_pontos`, `texto_do_aviso`, `sets_acesos`, `numero_pulando`; `configurar` aceita os ids dos times pros emblemas).
- `scripts/partida/faixa_de_ponto.gd` — menor, escura, com emblema (`configurar(ids)` e `mostrar(..., time)`).
- `scripts/partida/partida.gd` — só passa os ids dos times e quem pontuou pra faixa (9 linhas).
- `testes/teste_placar_na_partida.gd` — verificações novas.
- `ferramentas/capturas_de_tela.gd` — tela `placar`, com recorte.

## O que ainda falta em relação à referência
- O nome em japonês embaixo do nome do time (precisa de fonte com kanji).
- O efeito de ponto da referência tem um corte de luz grande e faíscas; aqui é um risco fino e um clarão, pra não chamar atenção demais durante o jogo. Fácil de aumentar se você preferir.
- A mensagem "Ponto Karasuno!" no meio da tela continua aparecendo junto com a faixa PONTO! (já era assim). Fica pra fase de game feel decidir se uma das duas sai.

## Como testar no seu PC
1. Abra o projeto e aperte **F5** → Partida rápida → escolham os times → começa.
2. Jogue alguns pontos: a caixa de quem pontua pisca e o número fica amarelo; a bola pequena mostra quem saca.
3. Chegue a 6 pontos: aparece SET POINT embaixo do placar.
4. Feche um set: a primeira bolinha do meio fica na cor de quem ganhou.
5. No fim do jogo: FIM no meio e a caixa do vencedor brilha.
