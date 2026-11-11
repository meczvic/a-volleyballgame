# Estado do projeto

Atualizado em **09/11/2026** (à noite, depois do polimento da partida). Este documento resume o que é o jogo, o que já foi feito, o que falta, o que precisa melhorar e os próximos passos. Os detalhes de como jogar e rodar estão no [README](../README.md). A [seção 6](#6-para-devs-e-agentes-de-ia) é o guia técnico para quem for mexer no código (pessoa ou agente de IA).

---

## 1. O que é o projeto

Um jogo de **vôlei de quadra 6 contra 6 em 3D**, para PC, feito para jogar com amigos.

| Item | Decisão |
| --- | --- |
| Engine | **Godot 4.7.2** (versão padrão, não a .NET), em GDScript |
| Visual | Anime **cel-shaded**, personagens com corpo normal, vários estádios |
| Câmera | Baixa, atrás do próprio time (~27°, estilo transmissão de TV). No PC, **tela dividida lado a lado** |
| Jogadores | **2 humanos**, cada um com um time de 6. O jogo passa o controle pro atleta que vai na bola; a IA posiciona os outros |
| Rede | Multiplayer **local** (feito) e **online** (planejado) |
| Controles | Teclado e controle |
| Estilo de jogo | Meio-termo entre arcade e simulação |
| Regras | Regras oficiais do vôlei (FIVB): rodízio, posição no saque, ataque e bloqueio do fundo etc. **6 atletas por time, sem líbero** |
| Placar | Melhor de 3 sets; set até **7**, com 2 de diferença e limite em **10** |
| Modos | **Partida rápida** (normal) e **Modo Caos** com cartas (prata, ouro e prismática), inspirado no ARAM Mayhem |
| Público | Amigos. Sem progressão, sem som/música por enquanto |

Material de apoio (privado, no Claude): [documento de design](https://claude.ai/artifact/8wLMvqE4SpXA52gxGTi6Qt), [apresentação do jogo](https://claude.ai/artifact/6CPMDNbUbxsLh42fkANrPc), [guia do VRoid](https://claude.ai/artifact/NitRJ4DP8oGWkKQJLS1k6A) e [plano semanal](https://claude.ai/artifact/8QXRa1ZrCFDYubEuys7BAr).

---

## 2. O que já foi feito

Tudo abaixo está neste repositório. Em 09/11/2026, os **23 testes automáticos** (pasta `testes/`) passam no Godot 4.7.2, e um robô jogou partidas completas (3 sets) dos dois lados, passando pelos menus, pausa e fim de jogo, sem erro.

### Menus e telas
- Menu principal (Partida rápida, Modo Caos, Controles, Sair; Online aparece como "em breve").
- Seleção de times com cursor de cada jogador, emblema de cada time, atributos com ícone e o atleta destaque em 3D que comemora ao confirmar (Fase 01, 10/11/2026); escolha entre **4 estádios** (Ginásio Japonês, Arena Nacional, Arena Brasileira, Arena Neon).
- Pausa (continuar, recomeçar, trocar times, menu) e tela de fim de jogo.
- Uniforme reserva quando os dois escolhem o mesmo time.

### Partida
- Bola com trajetória calculada e **anel amarelo** marcando onde ela vai cair.
- **3 toques**: passe, levantamento (escolhendo ponta, meio, oposto ou fundo) e cortada.
- **Bloqueio** com os 3 da rede, que podem ser deslocados e acertar o tempo do pulo.
- **Troca automática** do atleta controlado e IA que posiciona os demais.
- **Tela dividida**, com câmera baixa atrás de cada time.
- **Visual anime**: sombra em faixas e contorno escuro (`shaders/`).

### Regras oficiais (FIVB)
- Escalação 5-1 a partir da posição de cada atleta em `dados/elenco.json`.
- Rodízio, ordem de saque por set, e falta de **posição errada no saque**.
- Faltas: 4 toques, dois toques, ataque do fundo, bloqueio e ataque no saque, toque na rede, fora da antena, 8 segundos pra sacar.
- A mensagem do ponto diz qual falta aconteceu.

### Jogabilidade com tempo e mira
- **Toque no tempo certo**: um anel branco fecha em volta do atleta; o resultado é **Bom** ou **Perfeito!**. Passe perfeito vai na mão do levantador; passe e levantamento perfeitos liberam o **levantamento rápido**; cortada perfeita congela a tela por um instante e treme.
- **Mira no saque**: segurar enche a força, soltar saca; a direção move o alvo; mais força = bola mais rápida, mas mais risco de sair.
- **Mira na cortada**: a direção escolhe paralela, diagonal, funda ou curta.
- Na cortada, o atleta pula no botão e **a mão bate na bola no alto do pulo** (0,3 s depois).

### Placar e impacto visual
- **Placar de transmissão** (`scripts/partida/placar_visual.gd`, Fase 02, 10/11/2026), em cima e no meio: emblema e nome em blocos inclinados, caixas de pontos com a borda na cor do time, set atual com uma bolinha por set na cor de quem ganhou, bola de quem saca, efeito de ponto (corte de luz dourado, faíscas, brilho, número amarelo, tremor), FIM e brilho do vencedor, e aviso de SET POINT / MATCH POINT / PONTO DECISIVO (regra em `placar.gd`: `ponto_de_set`, `ponto_de_partida`, `aviso`).
- **Faixa do ponto** (`faixa_de_ponto.gd`): PONTO!, ACE!, BLOQUEIO!, SET! e JOGO!, escura com a ponta na cor do time e o emblema de quem pontuou; menor que a antiga (680 x 104) pra cobrir menos a quadra.
- **Efeitos**: onda no chão onde a bola cai (`scripts/visual/onda_no_chao.gd`) com tremor; bloqueio congela, treme e mostra "Bloqueio!".

### Jogadas e leitura do bloqueio
- **Largada**: Passe no ar durante a cortada. A bola sai devagar e alta, passa por cima do bloqueio e cai curta (1 a 3 m da rede).
- **Leitura do bloqueio**: depois do levantamento, o bloqueio espera 0,4 s (reação) e corre pra onde a bola vai estar na hora da cortada. O central vai sempre, e os da ponta só se a bola vai pro lado deles. No levantamento rápido sobra pouco tempo pra fechar.

### Defesa, mergulho e atributos
- **Mergulho**: alcança bola baixa (até 1,4 m) a até 3,2 m do atleta (o passe normal alcança 1,8 m). A bola sai no máximo **Bom**, e **Ruim** se estava fora do alcance normal. O atleta fica 0,8 s no chão sem andar (mergulho no vazio também).
- **Atributos dos times valendo** (`scripts/regras/atributos.gd`, 3 = normal): ataque (janela e força da cortada), defesa (janela do passe e alcance do mergulho), saque (erro do saque), bloqueio (largura do bloqueio) e velocidade (corrida dos atletas).

### Polimento da partida (09/11/2026)
Feito depois de um robô jogar partidas inteiras e listar o que parecia estranho:
- **Botão guardado**: Passe ou Cortada apertados um pouco cedo (bola fora do alcance) valem por 0,15 s e saem assim que a bola chega. Se não dá, o **anel do atleta pisca** (`scripts/partida/anel_do_controlado.gd`), pra nenhum botão ficar "sem resposta".
- **Toque no bloqueio**: só o bloqueio no alto do pulo e bem na frente da bola devolve a cortada. Cedo, tarde ou na ponta da mão, a bola **raspa e segue** pro lado de quem bloqueou, mais devagar (não conta toque; se sair, a falta é do bloqueio). O bloqueio ficou menos "muro" (largura 0,5 m).
- **Cortada mais decisiva**: a cortada perfeita sai mais rápida e pode cair mais curta (4,5 m), em vez de sempre em cima da defesa.
- **Saque com risco de verdade**: o erro cresce mais com a força e, no talo, a bola pode sair mesmo mirando no meio. O saque fraco sobe um pouco mais (mais fácil de receber).
- **Câmera viva** (`scripts/partida/camera_da_partida.gd`): fica no lugar, mas vira de leve pra acompanhar a bola, com suavização.
- **Depois do ponto, os atletas andam** até a formação do saque (1,8 s) em vez de teleportar.
- **Transições**: cortina preta na entrada da partida e nas saídas pelo menu de pausa (`scripts/menus/cortina.gd`); o painel da pausa e do fim de jogo entra crescendo.
- **Bola mais visível**: desenho maior que o raio das regras e rastro mais forte.
- **Mensagens por metade da tela**: saque, recepção, levantamento e largada aparecem na metade do time; só o ponto fica no meio. "(dentro)" sumiu do texto do ponto e "fora" virou "bola fora".
- **Barra de força do saque** na tela (`scripts/partida/barra_de_forca.gd`), no lugar do texto 3D na quadra do outro lado.
- Avisos "Perfeito!"/"Bloqueio!" no mesmo lugar **empilham** em vez de se sobrepor. A ajuda embaixo cita mergulho e largada; a tela de Controles também.

### Personagens e animações
- O jogo carrega um personagem do VRoid (`.vrm`) quando o arquivo existe em `personagens/<time>/<número>_<nome>.vrm`. Sem o arquivo, usa o **personagem gerado por código** (`scripts/visual/gerador_de_atleta.gd`, 10/11/2026): malha, esqueleto humanoide e pesos feitos no próprio Godot a partir de `dados/aparencia.json` (altura, porte, pele, cabelo, uniforme com número). Só vira cápsula se não houver nem `.vrm` nem entrada em `aparencia.json`. Os 42 atletas do elenco têm entrada e passam no `teste_elenco_em_quadra.gd`.
- Ferramentas: `ferramentas/capturas.gd` (folhas de contato e vistas de cada atleta, renderizadas pelo jogo) e `ferramentas/robo.gd` (robô que joga a partida sozinho, grava vídeo, prints e mede o tempo por quadro).
- Plugin VRM para Godot já incluído em `addons/`.
- **Animações** no esqueleto comum dos personagens (`animacoes/`): parado, correr, deslocamento lateral, defesa lateral, manchete, bloqueio, saque, mergulho e 3 comemorações, vindas do **Mixamo**; levantamento e cortada montados à mão; e a **cortada gravada pelo Victor no DeepMotion**, que é a cortada usada no jogo.
- `scripts/visual/animador.gd` escolhe a animação pelo movimento e toca a de cada lance.
- Ferramentas de produção: uniformes com número (`ferramentas/uniformes.py`), manifesto do que falta (`producao/MANIFESTO.md`) e conversor do DeepMotion (`ferramentas/converte_deepmotion.gd`).

### Dados editáveis (sem mexer em código)
- `dados/times.json`: times, atributos (1 a 5, somando 17) e cores.
- `dados/elenco.json`: atletas de cada time (nome, número, posição).
- `dados/estadios.json`: estilo (ginásio ou arena), cores (piso, quadra, linhas, placas, proteção dos postes, luz, sol), textos das faixas (ginásio), letreiro e cores do público (arena).
- `dados/cartas.json`: cartas do Modo Caos (usadas no Modo Caos, só as de `IMPLEMENTADAS` em `scripts/regras/cartas.gd`).

---

## 3. O que falta fazer

### Personagens (Victor e amigo)
- Desde 10/11/2026 os 42 atletas aparecem como **personagens gerados por código** (humanoides estilizados, cel-shaded, diferenciados por altura, porte, pele, cabelo e uniforme). Não são retratos: a aparência vem de `dados/aparencia.json`, que o Victor pode editar.
- Quem quiser um modelo mais detalhado exporta o `.vrm` do VRoid para `personagens/<time>/` com o nome certo: o jogo passa a usar o VRM no lugar do gerado, sem mexer em código.
- Falta o Victor **avaliar a aparência** dos gerados em partida e dizer o que ajustar (cores, cabelos, porte) em `dados/aparencia.json`.

### Jogabilidade e interface
- A base está feita. Falta testar com gente de verdade e ajustar números (janelas de tempo, alcance, força).

### Modos
- **Modo Caos (primeira versão, 10/11/2026):** menu → seleção → partida com cartas. Testado no Godot 4.7.2 em 10/11/2026: o caminho todo abre e a tela de cartas funciona com os dois jogadores (`teste_tela_de_cartas.gd`); os efeitos ainda não foram jogados por gente. Tela refeita na Fase 03: cartas desenhadas em `scripts/partida/carta_visual.gd` (prata, ouro e prismática com moldura, fundo e brilho próprios; ícone do conjunto em `arte/icones/`; foto do atleta destaque do time na jogada do conjunto, tirada uma vez e guardada), cronômetro, emblema do time e botão TROCAR (Bloqueio; `trocas_por_partida` em `dados/cartas.json`, regra em `partida._trocar_cartas`). Os dois jogadores escolhem 1 de 3 cartas antes do 1º saque e a cada 3 pontos (`pontos_por_escolha` em `dados/cartas.json`), com limite de 60 s (depois sorteia). Regras em `scripts/regras/cartas.gd`, tela em `scripts/partida/escolha_de_cartas.gd`, efeitos em `scripts/regras/atributos.gd` (`time["modificadores"]`). Só 8 das 21 cartas têm efeito e entram no sorteio (lista `IMPLEMENTADAS`): Mãos Firmes, Pés Leves, Tapete Vermelho, Saque Firme, Levantador Preciso, Muro, Ataque Rápido e Troca de Lugar; os bônus de conjunto de 2 cartas (ataque, defesa, saque, velocidade) e o de 3 de velocidade também valem. Falta o efeito das outras 13, balancear e testar com gente. Testes novos: `teste_cartas.gd` e `teste_cartas_na_partida.gd`.
- **Online**: ainda não foi construído. O código já separa a entrada (teclado/controle) da lógica do jogo pra facilitar isso. Plano: um computador é o "dono" da partida, primeiro conexão por IP, depois procurar partida.

### Arte e som
- Estádios com cenário de verdade (hoje são cores por estádio).
- Prévias dos estádios na seleção: capturas do próprio jogo em `arte/estadios/<id>.png` (Fase 04), também usadas desfocadas no fundo da seleção. Retrato 2D opcional dos times em `arte/times/` (sem ele aparece o atleta 3D).
- Som e música, quando for decidido.

---

## 4. O que precisa melhorar

- **Times e nomes**: os dados ainda usam os times inspirados em Haikyuu (Karasuno, Nekoma etc.). Isso serve só para jogar entre amigos; se o jogo for publicado, precisam virar times próprios. Todos ficam em `dados/times.json` e `dados/elenco.json` para facilitar a troca.
- **Escala dos personagens**: os modelos de exemplo do VRoid são pequenos (~1,25 m) e não alcançam a bola; nos vídeos foram aumentados pra 1,75 m. Com os personagens de verdade, conferir altura e o giro (`GIRO_DO_PERSONAGEM`).
- **Animações**: o Mixamo não tem animações de vôlei, então várias são adaptadas (de goleiro, por exemplo). Vale gravar mais lances no DeepMotion, como foi feito com a cortada.
- **Ajuste fino**: velocidade da bola, janelas do tempo certo, força do saque, largura do bloqueio e o quanto a câmera acompanha a bola ainda são valores iniciais e precisam ser testados jogando. O robô (que acerta o tempo do bloqueio quase sempre) ainda bloqueia ou toca em quase metade das cortadas: vale olhar isso com gente de verdade.
- **Cenas e menus** ainda são montados por código (`_criar_*`), sem `.tscn` com nós. Funciona, mas dificulta mexer no visual pelo editor.
- **README**: a lista de testes e a seção "Próximos passos" do README estão um pouco desatualizadas; este documento é a referência atual.
- **Organização dos branches**: o repositório não tem um branch `main`. O trabalho principal está em `claude/project-thread-o4s5hf`. Vale criar um `main` quando o jogo estiver estável.

---

## 5. Próximos passos

Em ordem sugerida:

1. **Hoje à noite (PC de casa):** instalar o Godot 4.7.2 e o VRoid Studio, abrir o projeto e fazer um **personagem piloto** (um atleta do time Brasil) para conferir o caminho completo VRoid → jogo.
2. **Personagens:** Victor e o amigo modelam os atletas no VRoid e colocam os `.vrm` em `personagens/<time>/`.
3. **Jogabilidade:** feita a base (tempo, mira, jogadas, leitura do bloqueio, defesa, mergulho, atributos, placar e impacto visual). Falta jogar com os amigos e ajustar.
4. **Polimento da interface** (placar com efeito, mensagens por metade, barra de força e transições já feitos). Com isso, a **partida rápida local fica completa** (meta do 1º mês, até 06/12/2026).
5. **Modo Caos** com as cartas.
6. **Online**: primeiro por IP, depois procurar partida.

---

## 6. Para devs e agentes de IA

Leia esta seção inteira antes de mexer no código.

### Como trabalhar neste projeto
- **Idioma:** tudo em **português (BR)**: textos do jogo, nomes de arquivos, variáveis, funções, comentários, commits e PRs. Siga o padrão que já existe (`placar`, `rodizio`, `toques`...).
- **Quem é o dono:** o Victor nunca tinha usado uma engine antes deste projeto. Explique as coisas em linguagem simples, sem jargão, e diga o que ele precisa fazer no Godot passo a passo.
- **Tempo:** ~3h por dia, à noite e no fim de semana. O PC do **trabalho** dele não pode receber instalações; Godot e VRoid ficam no **PC de casa**.
- **Peça ok antes** de qualquer coisa difícil de desfazer: instalar programas no PC dele (por exemplo o VRoid MCP Bridge, um projeto não oficial que mexe no VRoid e na configuração do Claude), apagar arquivos, mudar o histórico do Git, publicar algo.
- **Limite de conteúdo (atualizado em 10/11/2026 a pedido do Victor):** os 42 atletas dos dados são feitos pelo gerador de personagens do jogo, a partir das fichas (altura, porte, cores, estilo de cabelo); são humanoides estilizados, não retratos. Modelos detalhados (VRoid) continuam por conta do Victor e do amigo. Não apague o que já existe nos dados.
- **Seja preciso:** só diga que algo funciona depois de rodar os testes ou o jogo.

### Branches e PRs
- O repositório **não tem `main`**. O branch principal é **`claude/project-thread-o4s5hf`**.
- Trabalho novo vai num branch próprio, com PR (em rascunho) **contra o `claude/project-thread-o4s5hf`**.
- Histórico: PR #1 (personagens VRoid e animações) e PR #2 (cortada do DeepMotion) já foram mesclados nele.
- Arquivos pesados (`.vrm`, `.fbx`, `.png`...) estão marcados como binários no `.gitattributes`. Os `.vroid` (projeto editável do VRoid) **não vão pro Git**; ficam no PC de casa e no Drive.

### Como o código está organizado
- **Fluxo das cenas:** `cenas/menu_principal.tscn` → `cenas/selecao_de_times.tscn` → `cenas/partida.tscn`. Com a partida aberta, **F6** roda só ela (Karasuno x Nekoma no Ginásio Japonês).
- **Autoloads** (em `project.godot`): `Teclas` (`scripts/entrada/teclas.gd`, cria as ações `p1_passe`, `p2_ataque` etc. de teclado e controle) e `Configuracao` (`scripts/menus/configuracao.gd`, guarda os times e o estádio escolhidos).
- **`scripts/regras/`:** regras **puras**, sem nós nem gráfico, fáceis de testar: `placar`, `rodizio`, `escalacao`, `formacao`, `toques`, `trajetoria`, `escolha_ataque`, `tempo_do_toque`, `mira`, `atributos`. Regra nova vai aqui, com teste.
- **`scripts/entrada/`:** teclado e controle viram **comandos**. A partida não sabe de onde o comando veio. É isso que vai permitir o online: basta criar outra fonte de comandos que venha da rede.
- **`scripts/partida/partida.gd`:** o centro da partida (~1.900 linhas): monta quadra, times e câmeras, liga regras, IA, bloqueio, rodízio, faltas, placar e animações. É o arquivo mais arriscado de mexer; separe partes novas em scripts próprios (como foi feito com `bola.gd`, `anel_de_tempo.gd`, `mira_visual.gd`, `anel_do_controlado.gd`, `camera_da_partida.gd`, `barra_de_forca.gd`). Pedaços que se repetem já têm ajudantes: `_distancia_no_chao`, `_animador_de`, `_erro_aleatorio`, `_destino_na_quadra_do_outro`, `_mostrar_mensagem(texto, time)`.
- **Bloqueio:** `_tipo_do_bloqueio` devolve `Bloqueio.NENHUM`, `DEVOLVE` ou `TOQUE`; a bola (`bola.gd`) usa isso pra voltar ou raspar e seguir. Botões apertados cedo ficam em `pedidos[time]` por `TEMPO_DO_PEDIDO`.
- **Polyfork** (Fase 05): 3 GLBs gratuitos em `assets/polyfork/cenario/` (CC BY 4.0, créditos em `assets/polyfork/LEIA-ME.md`), carregados por `scripts/cenario/polyfork.gd` (cor dos vértices, troca de cores, apoio no chão; sem o arquivo, volta a peça desenhada). Antes de acrescentar outro, registre em `assets/polyfork/manifesto.json`.
- **`scripts/cenario/`** (Fase 04): `cenario.gd` monta quadra, rede, árbitros, bancos e mesa e chama o estilo do estádio (`ginasio_japones.gd` ou `arena.gd`); `pecas.gd` tem as peças. A partida só chama `_criar_cenario()`. As câmeras ficam do lado de fora do ginásio, atrás de cada time: o que está no fundo atrás de um time vai pra camada 13 (atrás do time 0, z positivo) ou 14 (atrás do time 1), e a câmera daquele time não desenha essa camada (`Cenario.CAMADA_ATRAS_DO_TIME`). Use as camadas 11–14 só pra isso. O cenário não tem física: medidas da quadra e da rede continuam em `partida.gd` e `bola.gd`.
- **`scripts/visual/`:** `visual_anime.gd` (materiais anime), `animador.gd` (animações dos personagens), `impacto.gd` (congelar e tremer a tela), `rastro.gd` (rastro da bola).
- **`scripts/menus/`:** `estilo.gd` guarda cores, fontes e peças de interface de todos os menus (inclusive `rotulo_com_contorno`, usado na partida); `selecao.gd` tem a lógica da seleção e `selecao_de_times.gd` desenha a tela (emblemas em `arte/emblemas/`, ícones em `arte/icones/`, atleta 3D em `retrato_do_atleta.gd`, que guarda os atletas já montados e libera ao sair); `cortina.gd` é a cortina preta das trocas de cena.
- **`dados/*.json`:** tudo que é ajustável sem código (times, elenco, estádios, cartas), lido por `scripts/comum/dados.gd`. A escalação depende do campo `posicao` em `dados/elenco.json` (levantador, ponteiro, central, oposto): mantenha 1 levantador, 2 ponteiros, 2 centrais e 1 oposto por time.
- **Câmera e visual:** ajustáveis no Inspetor do nó `Partida` em `cenas/partida.tscn` (tela dividida, altura, distância, foco, visual anime). Valores atuais (Fase 04): altura 10,5, distância 24, foco 0, abertura 37° (antes: 14,5, 29,5, 1,5 e 27°; a câmera nova mostra o ginásio e deixa os atletas maiores, com os quatro cantos da quadra na tela). O quanto a câmera acompanha a bola fica nas constantes de `scripts/partida/camera_da_partida.gd`.

### Personagens (`.vrm` ou gerados)
- Ordem que a partida usa (`Dados.carregar_personagem`): `.vrm` se existir → gerado por código se tiver entrada em `dados/aparencia.json` → cápsula.
- Caminho do VRM: `personagens/<id do time>/<número com 2 dígitos>_<nome>.vrm`, tudo minúsculo, sem acento nem espaço (ex.: `personagens/brasil/01_nome.vrm`).
- **Gerador** (`scripts/visual/gerador_de_atleta.gd`): monta no Godot a malha (tubos, esfera da cabeça, cabelo por estilo, uniforme, joelheiras, tênis e número na camisa), o esqueleto `GeneralSkeleton` com as rotações do `SkeletonProfileHumanoid` (as mesmas que o Mixamo e o DeepMotion usam) e os pesos. Cada atleta leva ~20 ms pra gerar e tem ~2,7 mil vértices. Os ajustes por atleta ficam em `dados/aparencia.json` (campo `_sobre` explica cada chave); os números são texturas em `personagens/numeros/` (saem de `ferramentas/uniformes.py`).
- Capturas renderizadas pelo jogo: `godot --path . --script res://ferramentas/capturas.gd -- folha=karasuno` (ou `atleta=karasuno/10_hinata`, ou `todos`); precisa de tela (ou xvfb, veja abaixo). Saída em `producao/capturas/<time>/`.
- Plugin VRM **2.6.1** (AzPepoze) em `addons/vrm` e `addons/mtoon`. Ele **não funciona no Godot 4.3**; por isso o projeto usa o 4.7.2.
- Importação: Bone Rename Humanoid e esqueleto `GeneralSkeleton` (já configurado em `project.godot`), pra que todas as animações sirvam em todos os atletas.
- `GIRO_DO_PERSONAGEM = PI` em `partida.gd` faz o modelo olhar pra rede. Conferir com o primeiro personagem real.
- **Altura:** os modelos de exemplo do VRoid têm ~1,25 m e não alcançam a bola; nos vídeos de teste foram aumentados pra 1,75 m. Com os personagens reais, conferir a altura.
- Produção: fichas em `producao/fichas/`, números das camisas e prévias de uniforme com `python3 ferramentas/uniformes.py` (precisa do Pillow), e o estado de cada atleta em `producao/MANIFESTO.md`, gerado por `python3 ferramentas/manifesto.py` a partir de `producao/status.json`. Detalhes em `producao/LEIA-ME.md` e `personagens/LEIA-ME.md`. Alturas das fichas foram escritas de memória e precisam ser conferidas.

### Animações
- Do **Mixamo**: baixar em **FBX Binary, With Skin, 30 fps**, "In Place" nas de correr. O Mixamo não tem nada de vôlei, então as animações são adaptadas (goleiro, arremesso etc.).
- O retarget pro esqueleto comum usa `animacoes/mixamo_bone_map.tres`, configurado no bloco `_subresources` de cada `.fbx.import`.
- **Cuidado:** deixe **Remove Tracks desligado** na importação. No Godot 4.7.2 ele apaga as trilhas da animação.
- **DeepMotion** (vídeo → animação): ossos com nomes `*_JNT`, vem de costas e o quadril sobe com o tempo. Fica em `animacoes/deepmotion/` com `deepmotion_bone_map.tres`; rode `godot --headless --script res://ferramentas/converte_deepmotion.gd` pra gerar o `.tres` do jogo.
- Levantamento e cortada montada saem de `ferramentas/animacoes_combinadas.gd`.
- **Pose de espera** (Fase 06): parado em quadra o atleta toca "espera", criada em `animador.gd` a partir da "parado" (`POSE_DE_ESPERA`, `DESCIDA_DO_QUADRIL`, `PARADO_NO_JOGO`). Mexendo nos ângulos, rode `teste_pose_de_espera.gd` (confere os pés no chão).
- `scripts/visual/animador.gd`: a tabela `TRECHOS` diz qual pedaço de cada animação toca em cada lance. A cortada usa `TEMPO_ATE_A_BATIDA` (0,3 s) e puxa a bola até a mão (ímã de 0,15 s).
- Passo a passo completo em `animacoes/LEIA-ME.md`.

### Testes
- São 30 arquivos em `testes/` (`teste_pose_de_espera.gd` confere a pose de espera com os pés no chão; `teste_cenario.gd` abre a partida nos 4 estádios e confere rede, árbitros, pessoas e as camadas de cada câmera; `teste_tela_de_selecao.gd` e `teste_tela_de_cartas.gd` abrem a tela e apertam os botões dos dois jogadores; `teste_elenco_em_quadra.gd` confere os 42 atletas: malha com pesos, esqueleto, trilhas das animações e pose que se mexe). Rode todos, dentro da pasta do projeto:

```
for t in testes/teste_*.gd; do godot --headless --script res://$t; done
```

  Cada um precisa terminar com uma linha começando com `OK:`.
- Teste de regra pura: script que estende `SceneTree` e roda no `_init`.
- Teste que abre a partida (`teste_regras_na_partida.gd`, `teste_tempo_na_partida.gd`, `teste_mira_na_partida.gd`, `teste_sensacao_na_partida.gd`, `teste_interface_na_partida.gd`...): use `_initialize` e espere o **1º quadro**, porque a partida precisa dos autoloads. **Não** use `preload` da cena nesses testes; carregue com `load` dentro do `_initialize`.
- Depois de mexer em código: rode **todos** os testes e jogue (ou rode o robô) uma partida antes de subir. Atualize o README e este documento se algo mudar.

### Rodar o Godot num servidor Linux sem tela (agentes)
1. Baixe `Godot_v4.7.2-stable_linux.x86_64` (releases de `godotengine/godot-builds`).
2. `apt-get install mesa-vulkan-drivers xvfb`.
3. Rode com tela virtual:

```
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver vulkan --path .
```

- Os testes rodam com `--headless`, sem precisar disso.
- **Robô:** `ferramentas/robo.gd` joga a partida sozinho apertando as ações `p1_*`/`p2_*` (saque, passe, levantamento, cortada, bloqueio, erro sorteado). Exemplos:

```
godot --headless --path . --script res://ferramentas/robo.gd -- times=karasuno,nekoma segundos=300
VK_ICD_FILENAMES=... xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver vulkan --path . --write-movie partida.avi --fixed-fps 30 --script res://ferramentas/robo.gd -- times=brasil,brasil estadio=arena_brasileira segundos=60 prints=/tmp/prints
```

  Opções: `estadio=`, `saque=0|1`, `erro=0..1`, `prints=<pasta>` (um PNG por segundo), `closeup=<pasta>` (recortes ampliados do atleta do J1 nos lances). No fim imprime placar, lances e o **tempo médio por quadro**. Detalhe que custou tempo: soltar e apertar a mesma ação no mesmo quadro não conta como `is_action_just_pressed`; o robô aperta num quadro e solta no seguinte. Pra menus e pausa (`ui_accept`, `pausa`) use `InputEventAction` com `Input.parse_input_event`.
- A mensagem `ERR_CANT_OPEN ... audio_driver_alsa` só quer dizer que não há placa de som. Pode ignorar.
- Na primeira abertura o Godot cria `.godot/`, que fica fora do Git. A importação dos `.fbx` e `.vrm` demora na primeira vez.

### Pendências de dados que ninguém conferiu ainda
- Números dos atletas do Inarizaki em `dados/elenco.json`.
- Alturas nas fichas de `producao/fichas/`.
- `defesa_lateral` e `comemoracao_vitoria` existem mas ainda não são usadas.
