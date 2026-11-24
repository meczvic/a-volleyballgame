# Auditoria de QA (24/11/2026)

Primeira auditoria completa do estado do jogo, feita pelo Claude no papel de QA, depois do feedback de um amigo do Victor que testou o jogo. **Não houve refatoração**: só um ajuste de legibilidade (QA-01) e a ferramenta nova `ferramentas/fuzz_de_entradas.gd`. Evidências em `docs/qa_2026-11-24/`.

## Limites desta auditoria (leia primeiro)

O Claude **não joga com as mãos**. Tudo abaixo vem de: testes automáticos, robôs (partidas jogadas por script), um teste adversarial por script, capturas de tela (Godot 4.7.2 num servidor Linux sem GPU, renderizando por software) e leitura do código.

- **"Sensação de jogo" não foi avaliada.** Resposta do controle, peso dos toques e fluidez das animações em movimento só se avaliam com gente jogando. Onde falo disso, é do feedback do amigo ou suspeita, e está marcado.
- **Tempo por quadro não vale.** Sem GPU o jogo roda a ~580 ms por quadro com janela e ~11 ms sem janela (headless). Nenhum dos dois diz como roda no PC do Victor.
- **Só 16:9.** Mesmo pedindo 800x600 e 2560x1080, o Godot manteve a proporção 16:9 (as capturas saíram 800x450 e 1920x1080). Telas 4:3, 21:9 e verticais **não foram testadas**.
- **Não testados:** controle (gamepad), online entre dois PCs, som (sem placa de áudio), menus e seleção de times, os outros 3 estádios, os outros 5 times, Modo Caos jogado de verdade (só os testes automáticos).

## Estado geral

| Item | Situação |
| --- | --- |
| Build | Abre e roda. 49 de 49 testes automáticos passam (Godot 4.7.2). Nenhum erro de script em nenhuma execução desta auditoria. |
| Avaliado | Partida contra o computador (Fácil, Normal, Difícil) e computador x computador; tela dividida; câmeras alta e perto no Ginásio Japonês; interface durante a partida; entradas abusivas. |
| Executado | 6 partidas do robô de 300 s (headless); 1 partida de 45 s com janela (45 prints); 5 execuções do teste adversarial (de 60 a 200 s cada); capturas em 4 tamanhos. |

## O que existe, o que é parcial, o que parece funcionar

1. **Implementado e conferido por teste ou robô:** saque (com força e mira), recepção, levantamento (ponta, meio, oposto, fundo), cortada, bloqueio, mergulho, rodízio, placar, falta de posição, fim de set e de jogo, pausa, recomeço, computador em 3 níveis, tela dividida, 4 estádios.
2. **Parcial:** Modo Caos (21 cartas com efeito, mas nunca jogado por gente); online por IP (testado só com 127.0.0.1, sem prever atraso); animações (várias do Mixamo adaptadas de goleiro; manchete "passável", saque viagem com pernas tortas, segundo o estado do projeto).
3. **Quebrado:** nada que impeça jogar foi achado.
4. **Funciona só aparentemente:** a troca do atleta controlado. Não dá erro e os testes passam, mas é o centro da confusão relatada (veja "Experiência").
5. **Não existe:** tutorial ou treino (confirmei por busca no código e no menu); indicação de para onde vai o passe entre jogadores.

## Problemas encontrados

Tipo: **C** = confirmado (visto ou medido), **S** = suspeita, **F** = vem do feedback do amigo e não foi reproduzido por mim.

| ID | Grav. | Tipo | Problema | Como reproduzir | Evidência | Status |
| --- | --- | --- | --- | --- | --- | --- |
| QA-01 | P2 | C | Depois do 1º saque a linha de controles ficava quase ilegível (cinza sobre piso laranja). Era um defeito da minha correção anterior (opacidade 0,55). | Partida 1 jogador, olhar a linha de baixo depois do saque. | `ajuda_055_ilegivel.png` e `ajuda_090_legivel.png` | **Corrigido** (opacidade 0,9) |
| QA-02 | P2 | F+C | O controle muda de atleta sozinho (a cada bola lançada, `_ao_lancar_bola` escolhe quem vai na bola) e às vezes escolhe quem não é o mais perto. Há 35 pontos de código da partida que mexem nisso. | Jogar um rally; no saque o amigo viu o controle trocar. Não reproduzi o "não é o mais perto". | Código (`partida.gd`, `controlados[...]`), `docs/AUDITORIA_JOGABILIDADE.md` item 6 | Aberto, **depende de decisão de design** |
| QA-03 | P2 | C | O destino do passe entre jogadores não tem indicação. O que existe: anel no chão onde a bola cai, e rótulos "Ponta / Meio / Oposto / Fundo" no levantamento, pequenos. | Receber um saque e olhar a tela antes do toque. | `partida_9_quadros.png`, 1º quadro (rótulos pequenos) | Aberto |
| QA-04 | P2 | F | Não há tutorial. A primeira partida só tem frases curtas por fase ("Saque: segure e solte") e a linha de comandos. | Abrir o jogo pela primeira vez. | Menu principal (só Controles) | Aberto |
| QA-05 | P3 | C | Em 800x450 a linha de comandos fica minúscula e ilegível (fonte fixa em 16 px). | Capturar em janela pequena. | `res_800x450.png` | Aberto |
| QA-06 | P3 | C | Em telas largas, a faixa "COLÉGIO VÔLEI" da parede de fundo aparece por trás dos números do placar e vaza entre eles. | Câmera perto ou alta no Ginásio Japonês, olhar o centro do placar. | `res_1920x1080.png` (topo, entre os dois números) | Aberto |
| QA-07 | P3 | C | As barras de baixo (energia) começam sem nome; só aparece "SUPER PRONTA!" mais tarde. Iniciante não sabe o que são. | Primeiros segundos da partida. | `partida_9_quadros.png` | Aberto |
| QA-08 | P3 | F | Animações "travadas" e trocas "rápidas demais". A seta de troca já foi desacelerada no PR #10. O resto **não foi avaliado**: não vi as animações em movimento, só quadros parados. | — | — | Aberto, precisa de teste com gente |
| QA-09 | P3 | S | Os níveis de dificuldade podem não estar bem ordenados. O robô (que aperta ao acaso) perdeu 0x2 do Normal, mas ganhou 2x1 do Difícil e 2x0 do Fácil. É **uma partida por nível**: pode ser sorte. Computador x computador está na ordem certa (bolas por rally: Fácil 3,5, Normal 5,4, Difícil 8,3). | `robo.gd ... computador=<nível> semente=7` | `/tmp` (logs não versionados) | Precisa de mais partidas |
| QA-10 | P4 | C | Duração: Difícil contra Difícil não terminou em 300 s (1 set a 1, 27 rallies, 8,3 bolas por rally). Uma partida entre dois bons passa de uns 8 min. | `computador=dificil dois=1 segundos=300` | log do robô | Informativo |
| QA-11 | P4 | S | Picos de até 131 ms num quadro (headless). Pode ser só carga de recursos no começo; não investiguei. | Ver "desempenho" no fim do robô. | log do robô | Precisa de teste na máquina real |

Ainda sobre QA-02: a câmera da partida e o resto continuam bons nas capturas. A bola é bem visível (rastro, anel de queda e seta), mas **em fundo claro** (a tela branca do palco) ela some um pouco; é um risco, não um problema confirmado.

### Teste adversarial (o que foi feito e deu certo)

`ferramentas/fuzz_de_entradas.gd` (nova): com o computador como adversário, aperta e solta ao acaso os 9 botões do J1 (e do J2 no modo "tudo"), faz Esc várias vezes e recarrega a partida no meio. Confere a cada quadro: bola ou atleta com valor inválido (NaN), fora da quadra, e jogo parado no mesmo estado por mais de 25 s (só tempo sem pausa).

| Modo | Duração | Pausas / recarregamentos | Resultado |
| --- | --- | --- | --- |
| caos, semente 1 | 60 s | 37 / 4 | 0 problemas |
| caos, semente 3 | 150 s | 84 / 10 | 0 problemas |
| tudo (J1 e J2), semente 2 | 150 s | 80 / 6 | 0 problemas |
| segurar todos os botões, semente 1 | 200 s | 115 / 15 | 0 problemas |

Na primeira rodada do modo "segurar" o teste acusou um estado de saque parado por 28 s. Era um **falso alarme do meu script** (contava o tempo pausado); corrigi o script e a rodada seguinte ficou limpa. Não considero isso um bug do jogo.

Não coberto pelo teste: resolução diferente, controle de verdade, menus de seleção e partidas inteiras com humano.

## Experiência do jogador

Notas são **minhas leituras**, não de quem jogou, e a nota que depende de jogar à mão ficou sem nota.

| Aspecto | Leitura | Base |
| --- | --- | --- |
| Estabilidade | Boa | Testes, robôs, adversarial |
| Clareza visual da quadra | Boa | Capturas: quadra, rede, anel de queda e atletas legíveis |
| Clareza dos comandos | Fraca para iniciante | Só uma linha de texto e frases por fase; sem tutorial |
| Feedback do destino da bola | Parcial | Anel de queda sim; destino do passe não (QA-03) |
| Quem eu controlo | Confuso (relato) | QA-02; a seta existe, mas a regra da troca é o problema |
| Ritmo | Plausível | Rallies de 4 a 8 bolas, perto do alvo de 4 a 6 do estudo |
| Game feel e animações | **Sem nota** | Precisa de gente jogando |
| Rejogabilidade | **Sem nota** | Modo Caos nunca jogado por gente |

## Melhorias propostas

| Problema | Impacto | Solução | Complexidade | Riscos |
| --- | --- | --- | --- | --- |
| QA-02 regra do controle | Muito alto (é a causa da sensação de "perdido") | Definir o que o jogador controla (ver "Decisão que preciso de você") e fazer a troca previsível: nunca no meio do toque, com aviso antes, sempre o mais perto da queda | Alta | Mexe no coração da partida: afeta online, gravação e a partida com semente (testes serão regravados) |
| QA-03 destino do passe e do saque | Alto | Linha ou arco curto da mão até o destino no passe e levantamento (mostrar para quem vai); no saque, anel do alvo na quadra do outro lado enquanto segura | Média | Pode poluir a tela; deve respeitar a regra "tela mais limpa" já adotada |
| QA-04 tutorial | Alto | "Treino" no menu com 4 lições curtas (já descritas em `AUDITORIA_JOGABILIDADE.md`, item 6) | Média a alta | Depende da decisão do controle: se o controle mudar, o tutorial muda |
| QA-05, QA-06, QA-07 interface | Baixo | Escalar a linha de comandos com a janela; esconder a faixa por trás do placar; dar nome às barras | Baixa | Quase nenhum |
| QA-09 dificuldade | Médio | Rodar 10 partidas por nível, com sementes diferentes, e conferir se a ordem se mantém | Baixa | Nenhum |
| QA-08 animações | Médio | Primeiro olhar de perto um vídeo gravado de uma partida e listar o que trava; depois tratar | Média | Pode pedir novas animações (DeepMotion) |

## Próximas prioridades (por impacto e dependência)

1. **Decisão do Victor sobre o controle** (bloqueia o 2 e o 3).
2. QA-03: indicação do destino do passe e do saque (independente, pode ir já).
3. QA-05, 06, 07: arrumar a interface (rápido, independente).
4. QA-09: rodar mais partidas por nível (rápido, independente).
5. Regra do controle (QA-02).
6. Tutorial / treino (depois do 5).
7. Teste com gente: controle de verdade, resoluções 4:3 e 21:9, online entre dois PCs, e os outros estádios e times.

## Veredito

**APROVADO COM RESSALVAS** para a estabilidade: o jogo não travou nem deu erro em nenhuma execução desta auditoria e os 49 testes passam.

**Não aprovo a experiência de primeira partida.** Isso vem do relato do amigo, de QA-02 a QA-04 e da falta de tutorial, e não de uma partida que eu tenha jogado à mão. Game feel e animações ficam como **NÃO TESTADO**.

## Decisão que preciso de você

O amigo diz que "é estranho controlar tudo". Qual é o jogo que você quer?

- **A. Um atleta por vez, com troca previsível** (o mais perto da bola, aviso antes de trocar, nunca no meio do toque). Mexe pouco nas regras atuais; é a minha recomendação.
- **B. Um atleta fixo (por posição)**, com o resto do time na IA. Muda bastante a ideia do jogo e as regras de rodízio ficam por conta da IA.
- **C. Como está hoje**, só com mais avisos.
