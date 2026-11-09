# Estado do projeto

Atualizado em **09/11/2026**. Este documento resume o que é o jogo, o que já foi feito, o que falta, o que precisa melhorar e os próximos passos. Os detalhes de como jogar e rodar estão no [README](../README.md). A [seção 6](#6-para-devs-e-agentes-de-ia) é o guia técnico para quem for mexer no código (pessoa ou agente de IA).

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

Tudo abaixo está neste repositório. Segundo os registros de 09/11/2026, os **20 testes automáticos** (pasta `testes/`) passam no Godot 4.7.2, e um robô jogou partidas completas (3 sets) dos dois lados sem erro.

### Menus e telas
- Menu principal (Partida rápida, Controles, Sair; Modo Caos e Online aparecem como "em breve").
- Seleção de times com cursor de cada jogador e atributos do time na tela; escolha entre **4 estádios** (Ginásio Japonês, Arena Nacional, Arena Brasileira, Arena Neon).
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

### Jogadas e leitura do bloqueio
- **Largada**: Passe no ar durante a cortada. A bola sai devagar e alta, passa por cima do bloqueio e cai curta (1 a 3 m da rede).
- **Leitura do bloqueio**: depois do levantamento, o bloqueio espera 0,4 s (reação) e corre pra onde a bola vai estar na hora da cortada. O central vai sempre, e os da ponta só se a bola vai pro lado deles. No levantamento rápido sobra pouco tempo pra fechar.

### Defesa, mergulho e atributos
- **Mergulho**: alcança bola baixa (até 1,4 m) a até 3,2 m do atleta (o passe normal alcança 1,8 m). A bola sai no máximo **Bom**, e **Ruim** se estava fora do alcance normal. O atleta fica 0,8 s no chão sem andar (mergulho no vazio também).
- **Atributos dos times valendo** (`scripts/regras/atributos.gd`, 3 = normal): ataque (janela e força da cortada), defesa (janela do passe e alcance do mergulho), saque (erro do saque), bloqueio (largura do bloqueio) e velocidade (corrida dos atletas).

### Personagens e animações
- O jogo carrega um personagem do VRoid (`.vrm`) quando o arquivo existe em `personagens/<time>/<número>_<nome>.vrm`. Sem o arquivo, o atleta continua sendo uma cápsula. Testado com modelos de exemplo do VRoid.
- Plugin VRM para Godot já incluído em `addons/`.
- **Animações** no esqueleto comum dos personagens (`animacoes/`): parado, correr, deslocamento lateral, defesa lateral, manchete, bloqueio, saque, mergulho e 3 comemorações, vindas do **Mixamo**; levantamento e cortada montados à mão; e a **cortada gravada pelo Victor no DeepMotion**, que é a cortada usada no jogo.
- `scripts/visual/animador.gd` escolhe a animação pelo movimento e toca a de cada lance.
- Ferramentas de produção: uniformes com número (`ferramentas/uniformes.py`), manifesto do que falta (`producao/MANIFESTO.md`) e conversor do DeepMotion (`ferramentas/converte_deepmotion.gd`).

### Dados editáveis (sem mexer em código)
- `dados/times.json`: times, atributos (1 a 5, somando 17) e cores.
- `dados/elenco.json`: atletas de cada time (nome, número, posição).
- `dados/estadios.json`: cores da quadra, do fundo, das placas e da luz.
- `dados/cartas.json`: cartas do Modo Caos (ainda não usadas no jogo).

---

## 3. O que falta fazer

### Personagens (Victor e amigo)
- **Nenhum personagem real foi colocado ainda.** Hoje os atletas aparecem como cápsulas.
- Os personagens dos times inspirados em Haikyuu serão **modelados pelo Victor e por um amigo no VRoid**, por conta própria. O Claude não cria nem prepara esses personagens; ele cuida do motor, do caminho VRoid → Godot (uniformes, animações, testes) e de conteúdo original, como o **time Brasil**.
- Basta exportar cada `.vrm` para `personagens/<time>/` com o nome certo que o jogo usa sozinho.

### Jogabilidade
- **Mais impacto visual**: efeitos de cortada, bloqueio e ponto.

### Interface
- **Placar com efeito** na troca de pontos (previsto no design).

### Modos
- **Modo Caos**: as cartas estão em `dados/cartas.json`, mas o modo não existe ainda. Falta a tela de escolha na pausa depois do ponto (limite de 1 minuto, senão a carta é sorteada) e o efeito de cada carta.
- **Online**: ainda não foi construído. O código já separa a entrada (teclado/controle) da lógica do jogo pra facilitar isso. Plano: um computador é o "dono" da partida, primeiro conexão por IP, depois procurar partida.

### Arte e som
- Estádios com cenário de verdade (hoje são cores por estádio).
- Imagens dos times e prévias dos estádios na seleção (`arte/times/` e `arte/estadios/`, opcionais).
- Som e música, quando for decidido.

---

## 4. O que precisa melhorar

- **Times e nomes**: os dados ainda usam os times inspirados em Haikyuu (Karasuno, Nekoma etc.). Isso serve só para jogar entre amigos; se o jogo for publicado, precisam virar times próprios. Todos ficam em `dados/times.json` e `dados/elenco.json` para facilitar a troca.
- **Escala dos personagens**: os modelos de exemplo do VRoid são pequenos (~1,25 m) e não alcançam a bola; nos vídeos foram aumentados pra 1,75 m. Com os personagens de verdade, conferir altura e o giro (`GIRO_DO_PERSONAGEM`).
- **Animações**: o Mixamo não tem animações de vôlei, então várias são adaptadas (de goleiro, por exemplo). Vale gravar mais lances no DeepMotion, como foi feito com a cortada.
- **Ajuste fino**: velocidade da bola, janelas do tempo certo, força do saque e posição da câmera ainda são valores iniciais e precisam ser testados jogando.
- **README**: a lista de testes e a seção "Próximos passos" do README estão um pouco desatualizadas; este documento é a referência atual.
- **Organização dos branches**: o repositório não tem um branch `main`. O trabalho principal está em `claude/project-thread-o4s5hf`. Vale criar um `main` quando o jogo estiver estável.

---

## 5. Próximos passos

Em ordem sugerida:

1. **Hoje à noite (PC de casa):** instalar o Godot 4.7.2 e o VRoid Studio, abrir o projeto e fazer um **personagem piloto** (um atleta do time Brasil) para conferir o caminho completo VRoid → jogo.
2. **Personagens:** Victor e o amigo modelam os atletas no VRoid e colocam os `.vrm` em `personagens/<time>/`.
3. **Jogabilidade:** impacto visual (jogadas, leitura do bloqueio, defesa, mergulho e atributos já feitos).
4. **Placar com efeito** e polimento da interface. Com isso, a **partida rápida local fica completa** (meta do 1º mês, até 06/12/2026).
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
- **Limite de conteúdo:** agentes de IA **não criam nem preparam personagens ou times de Haikyuu** (modelos, fichas, uniformes, nomes novos). O Victor e um amigo fazem esses personagens no VRoid por conta própria. Os agentes cuidam do motor, do caminho VRoid → Godot, das animações, dos testes e de conteúdo **original** (como o time Brasil, com nomes fictícios). Não apague o que já existe nos dados; só não acrescente.
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
- **`scripts/partida/partida.gd`:** o centro da partida (~1.550 linhas): monta quadra, times e câmeras, liga regras, IA, bloqueio, rodízio, faltas, placar e animações. É o arquivo mais arriscado de mexer; separe partes novas em scripts próprios (como foi feito com `bola.gd`, `anel_de_tempo.gd`, `mira_visual.gd`).
- **`scripts/visual/`:** `visual_anime.gd` (materiais anime), `animador.gd` (animações dos personagens), `impacto.gd` (congelar e tremer a tela), `rastro.gd` (rastro da bola).
- **`scripts/menus/`:** `estilo.gd` guarda cores e fontes de todos os menus; `selecao.gd` tem a lógica da seleção e `selecao_de_times.gd` desenha a tela.
- **`dados/*.json`:** tudo que é ajustável sem código (times, elenco, estádios, cartas), lido por `scripts/comum/dados.gd`. A escalação depende do campo `posicao` em `dados/elenco.json` (levantador, ponteiro, central, oposto): mantenha 1 levantador, 2 ponteiros, 2 centrais e 1 oposto por time.
- **Câmera e visual:** ajustáveis no Inspetor do nó `Partida` em `cenas/partida.tscn` (tela dividida, altura, distância, foco, visual anime). Valores atuais: altura 14,5, distância 29,5, foco 1,5, abertura 27°.

### Personagens (`.vrm`)
- Caminho: `personagens/<id do time>/<número com 2 dígitos>_<nome>.vrm`, tudo minúsculo, sem acento nem espaço (ex.: `personagens/brasil/01_nome.vrm`). Sem o arquivo, o atleta vira cápsula.
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
- `scripts/visual/animador.gd`: a tabela `TRECHOS` diz qual pedaço de cada animação toca em cada lance. A cortada usa `TEMPO_ATE_A_BATIDA` (0,3 s) e puxa a bola até a mão (ímã de 0,15 s).
- Passo a passo completo em `animacoes/LEIA-ME.md`.

### Testes
- São 20 arquivos em `testes/`. Rode todos, dentro da pasta do projeto:

```
for t in testes/teste_*.gd; do godot --headless --script res://$t; done
```

  Cada um precisa terminar com uma linha começando com `OK:`.
- Teste de regra pura: script que estende `SceneTree` e roda no `_init`.
- Teste que abre a partida (`teste_regras_na_partida.gd`, `teste_tempo_na_partida.gd`, `teste_mira_na_partida.gd`...): use `_initialize` e espere o **1º quadro**, porque a partida precisa dos autoloads. **Não** use `preload` da cena nesses testes; carregue com `load` dentro do `_initialize`.
- Depois de mexer em código: rode **todos** os testes e jogue (ou rode o robô) uma partida antes de subir. Atualize o README e este documento se algo mudar.

### Rodar o Godot num servidor Linux sem tela (agentes)
1. Baixe `Godot_v4.7.2-stable_linux.x86_64` (releases de `godotengine/godot-builds`).
2. `apt-get install mesa-vulkan-drivers xvfb`.
3. Rode com tela virtual:

```
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver vulkan --path .
```

- Os testes rodam com `--headless`, sem precisar disso.
- **Robô e prints:** copie o projeto pra uma pasta temporária, troque `run/main_scene` pra `res://cenas/partida.tscn`, registre um autoload que aperta ações (`InputEventAction`) e salva `get_viewport().get_texture().get_image()`. Não suba essas mudanças.
- A mensagem `ERR_CANT_OPEN ... audio_driver_alsa` só quer dizer que não há placa de som. Pode ignorar.
- Na primeira abertura o Godot cria `.godot/`, que fica fora do Git. A importação dos `.fbx` e `.vrm` demora na primeira vez.

### Pendências de dados que ninguém conferiu ainda
- Números dos atletas do Inarizaki em `dados/elenco.json`.
- Alturas nas fichas de `producao/fichas/`.
- `defesa_lateral` e `comemoracao_vitoria` existem mas ainda não são usadas.
