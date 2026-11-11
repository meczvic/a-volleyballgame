# Fase 01 — Tela de seleção de times

Data: 10/11/2026. Referência: `Seleção de Times no Ginásio Japonês.png` (do pacote; não vai pro repositório).

## Resumo
- **Branch:** `claude/fase-01-selecao`, a partir de `claude/fase-00-diagnostico` (que vem do `claude/project-thread-o4s5hf` @ `12314fd`).
- **Ambiente:** Windows 11, Godot 4.7.2, Vulkan Forward+, RTX 3060 Ti.
- **Testes:** 27 de 27 com `OK:` `[TESTADO]`. Um teste novo, `teste_tela_de_selecao.gd`.
- **Capturas:** reais, do Godot `[VALIDADO VISUALMENTE]`.

## O que mudou na tela
| Antes | Agora |
|---|---|
| Nome do time e 2 quadradinhos de cor | **Emblema** de cada time (desenho original, animais facetados no estilo low-poly) no painel e nos 7 cartões |
| Metade da tela vazia entre os atributos e o VS | **Atleta destaque em 3D** de cada time (o mesmo personagem da partida), parado na pose de espera. **Comemora** quando o jogador confirma |
| Atributos só com texto | **Ícones** (chama, escudo, bola, rede, velocidade) na cor do time, numa caixa escura; as barras **enchem** ao trocar de time |
| VS solto | VS com **raio** que vai da cor de um time à do outro e pulsa de leve |
| Fundo em degradê liso | Faixas de luz na cor de cada time, **piso de madeira** atrás dos cartões e sombra no chão embaixo dos atletas |
| Cartões só com nome | Cartões com emblema, nome e brilho na cor do jogador que está nele |
| Rodapé "Esc: voltar ao menu" | Botões **B VOLTAR** e **A CONFIRMAR** (com as teclas), como na referência |
| — | Etiquetas JOGADOR 1/2 com ícone de controle; "2 JOGADORES · LOCAL" com ícone; ao confirmar, o "PRONTO!" salta; ao trocar de estádio, a prévia desliza |
| — | O título diz **MODO CAOS** quando a seleção vem do Modo Caos |

**O que NÃO mudou:** a lógica (`selecao.gd`), os botões de cada jogador, o desfazer, a escolha de estádio, a ida pra partida e o uniforme reserva. O retrato 2D opcional (`arte/times/<id>.png`) ainda funciona: se existir, aparece no lugar do atleta 3D.

## Capturas `[VALIDADO VISUALMENTE]`
Em `producao/fase01/`:
- `comparacao_selecao_inicio.png` e `comparacao_selecao_estadio.png`: antes (Fase 00) à esquerda, agora à direita.
- `selecao_inicio_1600x900.png`, `selecao_inicio_1280x720.png`: ninguém confirmou.
- `selecao_estadio_1600x900.png`, `selecao_estadio_1280x720.png`: os dois confirmaram (atletas comemorando), escolhendo o estádio.

Em 1600×900 e 1280×720 não há texto cortado. Em 1280×720 as dicas de teclado de cada jogador ficam pequenas (já era assim antes).

## Testes `[TESTADO]`
`testes/teste_tela_de_selecao.gd` abre a cena de verdade e aperta as ações dos dois jogadores (`p1_*`, `p2_*`), como uma pessoa no teclado ou no controle:
- emblemas, ícones e atleta destaque existem pros 7 times;
- J1 e J2 movem só o próprio cursor, com volta no fim da lista;
- os dois no mesmo time: o retrato do J2 usa o uniforme reserva (mesma regra da partida);
- confirmar: PRONTO!, atleta comemora, instrução espera o outro; quem confirmou não mexe o cursor; desfazer volta tudo;
- os dois confirmam → estádio; os dois trocam o estádio; confirmar → partida com os times e o estádio escolhidos.

Suíte completa: `for t in testes/teste_*.gd; do godot --headless --path . --script res://$t; done` → 27/27 `OK:`, sem `ERROR` nos logs.

Um vazamento de memória achado pelo teste foi corrigido: os atletas guardados pelo retrato (pra trocar de time sem montar de novo) agora são liberados quando a tela fecha.

## Desempenho `[TESTADO]`
Tela de seleção parada, `--print-fps`: **~108 FPS em 1600×900** e **~99 em 1280×720** (mínimo 77). Os dois atletas 3D custam pouco; a tela ficou acima de 60 FPS com folga.

## Arquivos
- `scripts/menus/selecao_de_times.gd` — tela redesenhada (mesma lógica).
- `scripts/menus/retrato_do_atleta.gd` — novo: atleta em 3D com fundo transparente, luz de contorno na cor do time.
- `scripts/comum/dados.gd` — `com_uniforme_reserva` (a regra saiu de `partida.gd`, que agora chama daqui; mesmo resultado) e `atleta_destaque`.
- `dados/times.json` — campo `destaque` (número da camisa do atleta do retrato).
- `arte/emblemas/*.svg` (7) e `arte/icones/*.svg` (8) — desenhos originais, feitos pra este jogo.
- `testes/teste_tela_de_selecao.gd` — novo.
- `ferramentas/lado_a_lado.gd` — novo: junta imagens pra comparar.
- README e `docs/ESTADO_DO_PROJETO.md` atualizados.

## Diferenças que ainda faltam em relação à referência
- **Atleta:** é o personagem low-poly do jogo, ainda simples (corpo de tubos, pele chapada). Isso melhora sozinho quando a Fase 06 melhorar o gerador, porque o retrato usa o mesmo personagem.
- **Prévia do estádio:** ainda é o desenho da quadra. Depois da Fase 04 (ginásio), dá pra salvar uma captura de cada estádio em `arte/estadios/<id>.png` e ela aparece sozinha.
- **Nome em japonês** embaixo do nome do time: precisaria de uma fonte com kanji (~5 MB). Ficou o estilo do time no lugar.
- **Fundo com o ginásio desfocado:** depende do ginásio da Fase 04.
- **Emblemas:** são originais e simples; se você quiser outros bichos ou outro traço, é só trocar o SVG em `arte/emblemas/`.

## Como testar no seu PC
1. Abra o projeto no Godot e aperte **F5**.
2. Escolha **Partida rápida**.
3. Jogador 1: **A/D** troca o time, **J** confirma, **Espaço** desfaz. Jogador 2: **setas**, **1** e **0** do numérico (ou dois controles).
4. Confira: emblema e atleta mudam ao trocar de time; ao confirmar, o atleta comemora; com os dois no mesmo time, o atleta do Jogador 2 aparece com o uniforme reserva.
5. Com os dois confirmados, esquerda/direita troca o estádio; confirmar começa a partida.
