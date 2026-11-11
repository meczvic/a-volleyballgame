# Fase 06 — Atleta low-poly com personalidade (42 preservados)

Data: 11/11/2026 (madrugada, tarefa agendada). Branch `claude/fase-06-atleta`, a partir de `claude/fase-05-polyfork`, com a prévia aprovada (`claude/previa-atleta`).

## Resumo
- O **gerador de atletas** ficou mais atlético e com uniforme de verdade, e os atletas ganharam uma **pose de espera** em quadra. Tudo por código: as mudanças valem pros **42** de uma vez, sem obra manual em cada um.
- Os dados dos 42 (`dados/aparencia.json`, `dados/elenco.json`) **não mudaram**: altura, porte, pele, cabelo e rosto de cada um continuam os mesmos.
- **Testes:** 30 de 30 arquivos de `testes/` passaram `[TESTADO]`; teste novo `teste_pose_de_espera.gd`. **Robô:** partida completa Karasuno × Nekoma no ginásio japonês, 2 × 1 em sets, 29 rallies (maior com 44 toques), 353 s de jogo, 0 linhas de erro; 3,9 ms por quadro em média (pior 14,7 ms, sem janela).

## O que mudou no corpo e no uniforme (`scripts/visual/gerador_de_atleta.gd`)
| Antes | Agora |
|---|---|
| Pele quase branca (o shader anime clareava demais) | Tons de pele com cor, do mais claro ao mais escuro (tabela `PELES`) |
| Tronco estreito, "boneco de tubos" | Ombros e peito mais largos (silhueta em V), deltoide, bíceps, antebraço, coxa e panturrilha com volume |
| Número da frente minúsculo, no canto | **Número grande no meio do peito**; o das costas também cresceu |
| Camisa e short lisos | **Recortes laterais** na camisa e **faixa lateral** no short, na cor de detalhe do time; manga mais comprida e larga; short um pouco mais comprido |
| Meia branca até a canela, misturando com a perna e o tênis | **Meia curta** e **tênis com sola mais grossa e faixa na cor do time** |

## Pose de espera (`scripts/visual/animador.gd`)
Parado em quadra, o atleta não fica mais em pé com os braços soltos: toca a animação **"espera"**, feita a partir da "parado" (mesma respiração), com **joelhos dobrados, quadril mais baixo, tronco inclinado pra frente e braços na frente do corpo**. Os ângulos ficam em `POSE_DE_ESPERA` e a descida do quadril em `DESCIDA_DO_QUADRIL`, ajustados medindo os ossos: **tornozelo na mesma altura e ponta do pé no chão** em atletas de 1,63 m a 1,94 m (diferença de até 4 mm). Corrida, passos laterais, lances, cortada (mão da batida, `LeftHand`) e comemorações não mudaram. Os árbitros, reservas, a seleção e as cartas continuam com a "parado" (em pé).

## Capturas `[VALIDADO VISUALMENTE]`
- `producao/fase06/comparacao_hinata_*.png` — Hinata antes (esquerda) e agora (direita): frente, três quartos, perfil, costas, correr, cortada.
- `producao/fase06/comparacao_hinata_parado_x_espera.png` — antes em pé × agora na pose de espera.
- `producao/fase06/comparacao_partida.png` — a mesma cena de jogo, antes e agora (12 atletas).
- `producao/fase06/comparacao_detalhe_banco.png` — reservas no banco.
- `producao/capturas/<time>/folha.png` — os 6 de cada um dos 7 times, refeitos com o gerador novo (frente e costas).
- `producao/capturas/karasuno/10_hinata_*.png` — todas as vistas do Hinata, inclusive a nova `espera`.

## Testes `[TESTADO]`
- `teste_pose_de_espera.gd` (novo): a "espera" existe e repete, é a pose parada em quadra, e em 4 atletas de alturas diferentes o tornozelo e a ponta do pé ficam no chão com o quadril mais baixo; o animador de verdade começa nela.
- `teste_elenco_em_quadra.gd` continua confirmando os 42 atletas com malha, pesos, esqueleto e animações; `teste_animacoes`, `teste_animador` e `teste_cortada` continuam passando (rig e batida intactos).

## Como fica pros 42
Não há nada pra fazer atleta por atleta: corpo, uniforme e pose saem do gerador e do animador. Pra mudar um atleta, continua sendo só o `dados/aparencia.json` (altura, porte, pele, cabelo, rosto). Um `.vrm` em `personagens/` continua tendo prioridade sobre o gerado, e a cápsula continua como reserva.

## Polyfork humanoide
Não usado: os personagens da Polyfork têm outro esqueleto (Mixamo de 22 ossos, sem os dedos do perfil do jogo) e uniforme de outros esportes; trocar exigiria retarget e refazer roupa e cabelo pra cada um, enquanto o gerador já entrega os 42 diferentes e animados.

## Como ver no seu PC
**F5** → Partida rápida → qualquer time. Parados, os atletas esperam agachados; ao correr, voltam ao normal. Na seleção, o atleta do retrato mostra o uniforme novo.
