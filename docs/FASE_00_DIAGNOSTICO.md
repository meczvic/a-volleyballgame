# Fase 00 — Diagnóstico e ponto de partida (baseline)

Data: 10/11/2026. Feito antes de qualquer mudança visual ou de jogo, pra servir de "antes" nas próximas fases.

## Resumo
- **Branch:** `claude/fase-00-diagnostico`, a partir de `claude/project-thread-o4s5hf` @ `12314fd` (merge do PR #8, 10/11/2026 11:10).
- **Ambiente:** Windows 11 Pro, Godot 4.7.2 stable (oficial), Vulkan / Forward+, NVIDIA GeForce RTX 3060 Ti, AMD Ryzen 5 4600G, 16 GB, monitor 1920×1080 a 165 Hz.
- **O que mudou no projeto:** nada no jogo. Entraram só este documento, a ferramenta `ferramentas/capturas_de_tela.gd` e as imagens de `producao/baseline_fase00/`.
- **Testes:** os 26 arquivos de `testes/` passaram `[TESTADO]`.
- **Capturas:** todas reais, tiradas do Godot nesta máquina `[VALIDADO VISUALMENTE]`.

## PRs e branches concorrentes
| Item | Situação | Risco pras próximas fases |
|---|---|---|
| PR #5 (rascunho), branch `ccr-a7e14e51-7da0im` | 1 commit: arquivos `.uid` e `.import` gerados pelo Godot 4.7.2 | Baixo. Não mexe em telas nem em lógica. Ao abrir o projeto, o Godot já cria `testes/teste_elenco_em_quadra.gd.uid` e muda 2 `.import` de fontes: é o mesmo assunto desse PR, por isso ficaram fora deste commit. |
| Outras 7 branches `claude/*` | Já mescladas no branch principal (0 commits à frente) | Nenhum. |

## Testes `[TESTADO]`
Comando (na pasta do projeto, sem abrir janela):

```
for t in testes/teste_*.gd; do godot --headless --path . --script res://$t; done
```

Resultado: **26 de 26 terminaram com `OK:`**, sem nenhuma linha de `ERROR` ou `SCRIPT ERROR` nos logs. (O README fala em 21 arquivos e o `ESTADO_DO_PROJETO.md` em 24; hoje são 26.)

| Teste | Tempo | Teste | Tempo |
|---|---|---|---|
| animacoes | 1 s | mira | 0 s |
| animador | 1 s | mira_na_partida | 3 s |
| atributos | 0 s | placar | 1 s |
| cartas | 1 s | placar_na_partida | 4 s |
| cartas_na_partida | 3 s | regras_na_partida | 7 s |
| cortada | 2 s | rodizio | 1 s |
| dados | 0 s | selecao | 1 s |
| elenco_em_quadra (42 atletas) | 3 s | sensacao_na_partida | 4 s |
| escalacao | 0 s | tempo_do_toque | 0 s |
| escolha_ataque | 1 s | tempo_na_partida | 3 s |
| formacao | 0 s | toques | 1 s |
| interface_na_partida | 3 s | trajetoria | 0 s |
| jogadas_na_partida | 4 s | mergulho_na_partida | 6 s |

## Partida pelo robô `[TESTADO]`
- **Com imagem (60 s, Karasuno x Nekoma, Ginásio Japonês):** 6 rallies, o maior com 26 toques. Saque, passe, levantamento, cortada e bloqueio aconteceram. Sem erros no log.
- **Partida completa sem janela (`--headless`):** terminou sozinha em 416 s de jogo, Nekoma venceu por 2 sets a 1 (último set 7 x 3). 33 rallies, o maior com 42 toques; 172 passes, 160 levantamentos, 132 cortadas. Nenhuma linha de erro no log.

## Desempenho `[TESTADO]`
Medido com `--print-fps` (FPS real que o Godot desenhou), robô jogando 45 s, 12 atletas, sem gravar imagens:

| Resolução | FPS médio | Mediana | Pior 10% | Mínimo |
|---|---|---|---|---|
| 1600×900 | 118 | 122 | 81 | 64 |
| 1280×720 | 125 | 126 | 115 | 103 |

- O mínimo de 64 FPS em 1600×900 veio de um engasgo isolado (o robô também registrou um pico de 118 ms). Pode ser shader compilando na primeira vez que algo aparece. Vale observar nas próximas fases.
- **Cuidado com o número do robô:** a linha "ms por quadro" do `robo.gd` soma o tempo de processo e de física do Godot. Com o robô salvando imagens ela marcou 70 ms (parece 14 FPS), mas o FPS real estava acima de 100. Pra medir desempenho, use `--print-fps` e não salve imagens ao mesmo tempo.
- Há folga grande pra cenário mais rico neste PC. Num PC mais fraco isso precisa ser medido de novo.

## Capturas (todas em `producao/baseline_fase00/`)
Cada tela em 1600×900 e 1280×720, sempre no mesmo estado (Karasuno x Nekoma, Ginásio Japonês):

| Arquivo | O que mostra |
|---|---|
| `menu_*.png` | menu principal |
| `selecao_inicio_*.png` | seleção, cursores em Karasuno e Nekoma, ninguém confirmou |
| `selecao_estadio_*.png` | os dois confirmaram, escolhendo o estádio |
| `partida_saque_*.png` | partida esperando o saque, placar 0 x 0 |
| `cartas_*.png` | Modo Caos, escolha de cartas do começo |
| `robo/partida_ace_1600x900.png` | faixa de ACE! durante a partida |
| `robo/partida_saque_rally_1600x900.png` | saque com a barra de força |
| `robo/closeup_rede.png` | recorte de uma disputa na rede |
| `hinata/10_hinata_*.png` | atleta exemplar: frente, perfil, três quartos, costas, correr, cortada |

As capturas do Hinata saíram iguais às que já estavam em `producao/capturas/karasuno/` (o gerador não mudou desde então). As de `producao/capturas/` não foram alteradas.

As cartas do Modo Caos são sorteadas, então a mão muda a cada captura. Pra comparar antes e depois, olhe o layout, não as cartas.

**Como repetir** (sem a janela aparecer na tela: ela abre fora da área visível):

```
godot --path . --resolution 1600x900 --position -30000,-30000 --script res://ferramentas/capturas_de_tela.gd -- saida=producao/baseline_fase00
godot --path . --resolution 1600x900 --position -30000,-30000 --script res://ferramentas/robo.gd -- times=karasuno,nekoma segundos=60 prints=<pasta>
godot --path . --position -30000,-30000 --script res://ferramentas/capturas.gd -- atleta=karasuno/10_hinata
```

## Comparação com as referências

### Seleção de times (ref.: `Seleção de Times no Ginásio Japonês.png`)
**O que já existe e está bom:** os dois lados com a cor do time, VS no meio, os 5 atributos em barras de 5 segmentos com "x/5", os 7 times numa fileira, etiquetas J1/J2 nos cartões, estados "ESCOLHENDO…" e "PRONTO!", faixa do estádio e instruções. Lê bem em 1600×900 e 1280×720; nenhum texto cortado.

**O que falta:**
- Emblemas dos times (corvo, gato, coruja…) no painel e nos cartões. Hoje os cartões têm só nome e 2 quadradinhos de cor.
- Uma figura grande de cada lado. A referência tem personagens; aqui pode ser um retrato renderizado do próprio atleta low-poly.
- Ícones nos atributos (chama, escudo, bola, rede, velocidade).
- Nome em japonês embaixo do nome do time (se quiser manter o tema).
- Prévia real do estádio. Hoje é um desenho de quadra; a referência mostra uma foto do ginásio. Dá pra usar uma captura do próprio jogo.
- Fundo com o ginásio desfocado, em vez do degradê liso.
- Botões no rodapé com o ícone do controle ("B VOLTAR", "A CONFIRMAR") e cabeçalho com ícone.

### Placar (ref.: `Placar Anime Karasuno vs Nekoma.png`)
**O que já existe:** nomes, cores, pontos grandes, bolinhas dos sets, ponto de quem saca, "SET 1", pulo e piscada do número no ponto, avisos SET POINT / MATCH POINT.

**O que falta:**
- Formato. A referência tem dois blocos inclinados, cada um com emblema, nome, caixa de pontos com borda na cor do time e o set no meio. Hoje é uma faixa só, com tudo numa linha.
- Emblemas.
- Efeito de ponto com brilho/corte na caixa do número e número novo destacado (amarelo).
- Bolinhas dos sets muito pequenas.
- Na tela dividida o placar fica bem em cima da linha que separa as metades. Funciona, mas deixa a linha atravessando o "VS".

### Cartas (ref.: `Escolha Sua Carta de Vôlei.png`; `b4258bb2…png` é praticamente a mesma imagem)
**O que já existe:** título, contador, 3 cartas por jogador na metade dele, raridade no topo (PRATA, OURO, PRISMÁTICA), nome, conjunto e descrição, cursor com a cor do jogador, lista "Suas cartas". O placar escurece atrás. Texto dentro das cartas e sem cortes.

**O que falta:**
- Cada raridade com identidade própria: hoje só a faixa do topo muda de cor. Falta moldura, brilho, ícone hexagonal e fundo por raridade.
- Uma ilustração ou ícone grande no meio da carta.
- O relógio pequeno ("59" solto) contra o cronômetro em destaque da referência.
- A referência mostra 3 cartas grandes no centro pra um jogador. O jogo tem 2 jogadores escolhendo ao mesmo tempo, então as cartas ficam menores. Manter 2 jogadores e trabalhar a moldura é o caminho mais barato.
- Botão "Reroll" não existe (é mecânica nova; não entra sem decisão sua).

### Partida e ginásio (refs.: `Partida Karasuno contra Nekoma.png`, `Partida de Vôlei…`, `Vôlei no Ginásio ao Entardecer.png`, `image-gen-1(1).png`)
**O que já existe:** quadra azul com linhas brancas, chão laranja, 12 atletas com cores dos times, anel do controlado, anel de tempo, sombras, faixa de ponto, câmera por time em tela dividida. A bola branca aparece bem contra a quadra azul.

**O que falta (o cenário é a maior distância das referências):**
- O ginásio não existe. Hoje é chão + quadra + uma mureta vermelha de 1 m e fundo de cor sólida. Faltam paredes, janelas, arquibancada/mezanino, banners, teto/luminárias, banco de reservas, cadeira do juiz, mesa, carrinho de bolas.
- A rede é uma faixa branca semitransparente sem malha, sem fita, sem antenas e com postes finos. Quem está atrás dela fica desbotado (rosado/acinzentado) e difícil de ler.
- O piso não tem textura de madeira nem a área de saque tracejada; não há reflexo nem luz quente da janela.
- Só uma luz direcional; sem luz ambiente colorida do ginásio.

### Atleta exemplar — Hinata (ref.: `producao/capturas/karasuno/10_hinata_frente.png` e os conceitos)
- Silhueta de "boneco de tubos": braços e pernas cilíndricos e retos, ombros estreitos.
- Pele quase branca e sem variação, meias brancas longas que se misturam com as pernas.
- Número da frente minúsculo; uniforme liso, sem recortes.
- Tênis são blocos brancos sem sola.
- Pose parada de pé, sem joelho flexionado (a referência pede "pose de espera" agressiva).
- Cabelo espetado legível de longe, o que é ponto forte.
- Animações funcionam (corrida e cortada com o braço alto).

## Matriz de prioridades
**P0** = bloqueia a meta do vertical slice. **P1** = atrapalha leitura, controle ou visual de forma clara. **P2** = polimento.

| # | Pri | Área | Problema | Onde mexer | Custo |
|---|---|---|---|---|---|
| 1 | P0 | Ginásio | Não há ginásio: só chão, quadra e mureta. A referência mais importante (ginásio japonês) fica muito distante. | script novo de cenário (sem inchar `partida.gd`), `dados/estadios.json` | médio |
| 2 | P0 | Seleção | Sem emblemas nem figura dos times; não chega perto do conceito. | `selecao_de_times.gd`, `estilo.gd`, emblemas originais | médio |
| 3 | P0 | Placar | Formato de faixa única, sem emblema; longe do conceito. | `placar_visual.gd` | baixo/médio |
| 4 | P1 | Leitura | Rede semitransparente desbota os atletas atrás dela e não parece rede. | `_criar_rede` (trocar por malha + fita + antenas) | baixo |
| 5 | P1 | Leitura | Faixa de ACE!/PONTO! cobre boa parte das duas metades e a quadra. | faixa de ponto em `partida.gd` | baixo |
| 6 | P1 | Leitura | Caixas de mensagem do saque/recepção ficam no meio do fundo da quadra, perto da bola sacada. | `_mostrar_mensagem` em `partida.gd` | baixo |
| 7 | P1 | Cartas | Raridades sem identidade visual além da cor do topo. | `escolha_de_cartas.gd` | baixo/médio |
| 8 | P1 | Atleta | Corpo de tubos, pele branca chapada, tênis sem sola, número pequeno, pose sem flexão. | `gerador_de_atleta.gd`, `dados/aparencia.json` | médio |
| 9 | P1 | Desempenho | Engasgo isolado (pico de 118 ms) em 1600×900, possivelmente shader compilando. | investigar depois que o cenário crescer | baixo |
| 10 | P2 | Ferramenta | O "ms por quadro" do robô não é FPS real e engana. | `ferramentas/robo.gd` | baixo |
| 11 | P2 | Seleção | Prévia do estádio é um desenho; não existe pasta `arte/`. | captura do próprio jogo em `arte/estadios/` | baixo |
| 12 | P2 | Docs | README e ESTADO falam em 21 e 24 testes; são 26. | docs | baixo |
| 13 | P2 | Cartas | Mão sorteada a cada vez dificulta comparar capturas. | semente opcional na ferramenta de captura | baixo |
| 14 | P2 | Partida | No recorte da rede, dois atletas de times diferentes se atravessam. Visto em 1 quadro; pode ser só o ângulo. | verificar na fase de gameplay | ? |

## Checklist de aceite (estado hoje, antes das mudanças)
- Seleção: 7 times sem quebrar ✔ · cursor/confirmar/desfazer por jogador ✔ (teste `selecao`) · atributos visíveis ✔ · estádio claro ✔ (prévia fraca) · pt-BR sem cortes ✔ · 1600×900 e 1280×720 ✔ · comparação com a referência: **distante** (sem emblemas/figuras).
- Placar: lê nome/pontos/sets ✔ · feedback de ponto ✔ mas a faixa cobre a quadra ✘.
- Cartas: raridades diferenciadas só pela cor do topo ✘ · seleção dos dois lados ✔.
- Ginásio: rede e linhas visíveis ✔ (rede desbota atletas) · contexto de ginásio ✘ · câmera mantém a bola legível ✔.
- Atleta: anda e anima ✔ · sem pose T ✔ · melhora de silhueta ✘ (é o "antes").
- Jogabilidade: saque, passe, levantamento, cortada, bloqueio ✔ pelo robô; mergulho ✔ pelo teste `mergulho_na_partida`.

## Decisões viáveis sem custo (sugestão de ordem)
1. **Seleção (Fase 01):** emblemas originais desenhados em código ou SVG simples; retrato do atleta low-poly renderizado pelo próprio Godot; ícones de atributo; fundo com captura do ginásio desfocada. Nada pago.
2. **Placar (Fase 02):** refazer com dois blocos inclinados, emblema, caixa de pontos com borda; efeito de ponto com brilho curto. Reduzir a faixa de ACE/PONTO pra não cobrir a quadra.
3. **Rede e mensagens (rápido, alto ganho de leitura):** rede com malha em textura, fita branca, antenas listradas, postes mais grossos e opacos; mensagens fora da área de jogo.
4. **Cartas (Fase 03):** moldura e brilho por raridade com StyleBox e shader simples; ícone por conjunto.
5. **Ginásio japonês (Fase 04):** paredes de madeira, janelas com luz quente, mezanino, banners, banco, cadeira do juiz, mesa, carrinho; tudo com formas simples e poucas luzes. Polyfork só onde ganhar de forma visível.
6. **Hinata (Fase 06):** primeiro proporção, pele, tênis com sola, número maior e pose de espera; depois replicar pros 42 pelos dados.

## O que NÃO foi feito nesta fase
- Nenhuma mudança visual, de controle ou de regra.
- Teste com controle físico (gamepad) e com duas pessoas: não dá pra fazer daqui. O teste `selecao` cobre a lógica, não o aparelho.
- Comparação de FPS em outro PC.
- Capturas das outras arenas (Nacional, Brasileira, Neon): ficam pra Fase 04.
