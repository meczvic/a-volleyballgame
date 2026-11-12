# Handoff: plano de melhorias da arquitetura

Escrito em **12/11/2026**. Resultado de uma análise da arquitetura feita sem mexer em código. Serve de ponto de partida para quem for executar as melhorias, pessoa ou agente de IA. O guia geral continua em [ESTADO_DO_PROJETO.md](ESTADO_DO_PROJETO.md) (leia a seção 6 antes de mexer no código) e o handoff do jogo em [HANDOFF.md](HANDOFF.md).

Os testes não foram rodados nesta análise (o Godot não estava instalado no ambiente). Os números abaixo vêm de leitura e busca no código.

## Andamento

| Fase | Situação |
| --- | --- |
| **A. Rede de segurança** | **Feita em 12/11/2026** (branch `claude/fases-a-b-seguranca`). `ferramentas/rodar_testes.sh` e `.github/workflows/testes.yml`. Contagem de testes corrigida (33). |
| **B. Aleatório controlado** | **Feita em 12/11/2026** (mesmo branch). `partida.sorteio` com `Configuracao.semente`, robô com `semente=`, impacto contando quadros de física, `teste_partida_com_semente.gd`. |
| **C. Quebrar `partida.gd`** | **Feita em 12/11/2026** (branch `claude/fase-c-interface`). `partida.gd` foi de 2.464 pra ~1.270 linhas e virou coordenadora. Saíram, em `scripts/partida/`: `interface_da_partida.gd` (placar, mensagens, barras, comandos, cortina; `partida.interface`), `montagem_da_partida.gd` (cenário, atletas, marcas, câmeras; `partida.montagem`), `cartas_da_partida.gd` (Modo Caos; `partida.caos`), `ia_dos_atletas.gd` (movimento e IA; `partida.ia`), `bloqueio_na_partida.gd` (pulo e bloqueio; `partida.bloqueios`) e `lances_da_partida.gd` (passe, levantamento, cortada, largada, mergulho; `partida.lances`). Cada módulo guarda a partida em `p` e mexe nela por `p.algo`. Testes ajustados; os 40 passam e a partida com semente não mudou. |
| D, E, F | Não começadas. |

Correções ao que está abaixo, achadas ao executar a Fase A:
- O código de saída **funciona** nos testes (eles chamam `quit(1)` quando falham). O problema real é outro: um **erro de script trava o Godot sem fechar**, e o laço `for` fica parado para sempre. O script novo usa limite de tempo por teste.
- Além do `randf()` da lista do item 3, o sorteio das cartas criava um `RandomNumberGenerator.new()` sem semente, a carta sorteada quando o tempo acaba usava `randi()`, e o congelamento do impacto media tempo de verdade (`Time.get_ticks_msec`), o que fazia a partida durar quadros diferentes a cada vez. Os três foram corrigidos.
- A partida só se repete igual com `--fixed-fps 60`. Sem ele, as animações e os temporizadores andam no ritmo da tela e mudam um pouco de uma vez pra outra. Pro online com um computador "dono" da partida isso não importa: só o dono simula.

## Resumo

A base é boa: regras puras em `scripts/regras/`, entrada separada em comandos, dados em JSON, visual e cenário organizados. Os problemas se concentram em poucos pontos, sobretudo no `scripts/partida/partida.gd`.

## Problemas encontrados

1. **`partida.gd` faz tudo.** 1.995 linhas, 105 funções, 53 variáveis, 82 constantes. Mistura regras de lance (toque, cortada, bloqueio, mergulho), IA dos atletas, fluxo das cartas do Modo Caos, montagem de cena e montagem de interface (`_criar_interface`, `_criar_*`). Quase tudo só roda dentro da cena inteira.
2. **Testes presos a nomes internos.** Os 9 testes `*_na_partida.gd` chamam 42 funções privadas diferentes (`partida._x`). Refatorar quebra testes que estão corretos.
3. **Online ainda inviável.**
   - Não há simulação separada da parte visual: posições e estado vivem em `Node3D`, dentro do `_physics_process`.
   - O `randf()` global decide lances: `partida.gd` linhas ~747 (saque), ~999 (destino), ~1008 (erro aleatório), ~1585 (ponto aleatório no lado) e `placar.gd:121` (quem saca primeiro). Dois computadores não chegariam ao mesmo resultado.
   - Os comandos são só `(jogador, "passe")`, sem número de quadro nem tempo. A direção é lida por polling na variável `direcao`.
4. **Estado espalhado e frágil.**
   - O enum `Estado` (SAQUE, RALLY, PONTO, FIM) convive com flags soltas: `saque_em_jogo`, `carga_do_saque`, `cortadas`, `pedidos`, `_escolhendo_cartas()`.
   - Mais de 15 arrays paralelos `[time0, time1]`.
   - Dicionários fazendo papel de struct (`cortadas`, `pedidos`, `funcoes`).
   - Textos mágicos para tipo de comando, função do atleta, lance e motivo do ponto.
5. **Sem rede de segurança automática.** Não existe script que rode todos os testes nem CI (`.github/` não existe). O "OK:" é conferido na mão. A contagem de testes está inconsistente na documentação: 23 (seção 2), 31 (seção 6), 32 (HANDOFF.md).
6. **Ajuste fino só por código.** As constantes de equilíbrio (janelas de tempo, alcance, bloqueio, pulo) ficam em `partida.gd`, e o jogo ainda precisa de muito ajuste com gente jogando.
7. **Cenas e menus montados por código.** Só existem 3 `.tscn`; o resto é `_criar_*`.
8. **Higiene do repositório.**
   - Não existe `main` (o principal é `claude/project-thread-o4s5hf`).
   - Dezenas de `.vrm` e `.fbx` direto no Git. O tamanho **não foi medido**; vale conferir e avaliar Git LFS.
   - Nomes de times e atletas vêm de Haikyuu: serve entre amigos, mas impede publicar.

## Plano por fases

Regra para todas: cada fase termina com **todos os testes de `testes/` passando** e uma partida do robô (`ferramentas/robo.gd`) sem erro, e vira um PR em rascunho contra `claude/project-thread-o4s5hf`.

| Fase | O que fazer | Risco |
| --- | --- | --- |
| **A. Rede de segurança** | Criar `ferramentas/rodar_testes.sh`, que falha se algum teste não imprimir `OK:` e devolve código de saída diferente de zero. Criar workflow de GitHub Actions com Godot 4.7.2 headless. Corrigir a contagem de testes em README e docs. | Baixo |
| **B. Aleatório controlado** | Trocar o `randf()` por um `RandomNumberGenerator` com semente na partida e no placar. Fazer o robô aceitar `semente=`. Gravar o resultado de uma partida com semente fixa como teste de regressão **antes** de mexer na estrutura. | Baixo |
| **C. Quebrar `partida.gd`** | Tirar um pedaço por vez, do mais isolado ao mais entranhado: (1) interface e mensagens, (2) montagem de cenário e atletas, (3) fluxo das cartas, (4) IA e posicionamento, (5) bloqueio, cortada e toque. A `partida.gd` fica como coordenadora (~400 linhas): sinais para cima, chamadas para baixo. Os testes `*_na_partida.gd` são ajustados no mesmo PR de cada pedaço. | Médio |
| **D. Modelo de estado limpo** | Máquina de estados explícita em `scripts/regras/`. Enums no lugar dos textos mágicos. Uma pequena classe por time no lugar dos arrays paralelos. | Médio |
| **E. Preparar o online** | Comandos com número de quadro; passo da simulação separado da parte visual. Só depois, um protótipo com um computador "dono" da partida e conexão por IP. | Alto |
| **F. Conforto** | Constantes de equilíbrio para `dados/ajustes.json`. Menus para `.tscn`, um por vez. Criar `main`, medir o peso dos binários e decidir sobre LFS. | Baixo |

## Ordem recomendada

1. **A e B juntas.** São pequenas e tornam seguras todas as outras.
2. **C** em PRs pequenos, começando pela interface.
3. **D** depois da C.
4. **E** só depois da D.
5. **F** pode ser feita a qualquer momento, em paralelo.

## Cuidados ao executar

- Tudo em português (BR), inclusive commits e PRs (veja a seção 6 do ESTADO_DO_PROJETO).
- O AGENTS.md pede ok do Victor antes de mudar organização de branches. Criar o `main` e o CI (Fases A e F) precisam desse ok.
- Nos testes que abrem a partida: use `_initialize`, espere o 1º quadro e carregue a cena com `load` (não `preload`).
- Ao tirar funções do `partida.gd`, nomes antigos usados pelos testes precisam ser atualizados junto; não deixe teste quebrado para depois.
- Depois de cada fase, atualizar o ESTADO_DO_PROJETO e o README se algo mudar.

## Decisões em aberto (do Victor)

1. Por qual fase começar (a sugestão é A + B).
2. Criar o `main` e o CI já na Fase A, ou decidir depois.
3. Usar Git LFS para `.vrm` e `.fbx`, depois de medir o tamanho do repositório.
4. Quando trocar os times e nomes de Haikyuu por times próprios, se a ideia for publicar.
