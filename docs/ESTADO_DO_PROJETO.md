# Estado do projeto

Atualizado em **09/11/2026**. Este documento resume o que é o jogo, o que já foi feito, o que falta, o que precisa melhorar e os próximos passos. Os detalhes de como jogar e rodar estão no [README](../README.md).

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

Tudo abaixo está neste repositório. Segundo os registros de 09/11/2026, os **17 testes automáticos** (pasta `testes/`) passam no Godot 4.7.2, e um robô jogou partidas completas (3 sets) dos dois lados sem erro.

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
- **Jogadas e leitura do bloqueio**: rápida do central, largada, bloqueio tentando adivinhar o ataque.
- **Defesa e mergulho de verdade**: hoje o mergulho é só a animação, não alcança mais longe.
- **Atributos dos times valendo na partida**: hoje eles só aparecem na seleção de times.
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
3. **Jogabilidade:** jogadas e leitura do bloqueio → defesa e mergulho → atributos dos times valendo → impacto visual.
4. **Placar com efeito** e polimento da interface. Com isso, a **partida rápida local fica completa** (meta do 1º mês, até 06/12/2026).
5. **Modo Caos** com as cartas.
6. **Online**: primeiro por IP, depois procurar partida.
