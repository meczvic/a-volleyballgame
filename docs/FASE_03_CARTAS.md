# Fase 03 — Cartas do Modo Caos

Data: 10/11/2026. Referências: `Escolha Sua Carta de Vôlei.png` e `b4258bb2…png` (praticamente iguais; do pacote, não vão pro repositório).

## Resumo
- **Branch:** `claude/fase-03-cartas`, a partir de `claude/fase-02-placar`.
- **Ambiente:** Windows 11, Godot 4.7.2, Vulkan Forward+, RTX 3060 Ti.
- **Testes:** 28 de 28 com `OK:` `[TESTADO]`; teste novo `teste_tela_de_cartas.gd`.
- **Modo Caos acessível e funcional** `[TESTADO]`: menu → MODO CAOS → seleção (título "MODO CAOS") → partida → a escolha de cartas abre. Conferido com um script que aperta os botões do começo ao fim. Os efeitos das cartas ainda não foram jogados por pessoas.
- **Regras das cartas:** não mudaram (`scripts/regras/cartas.gd`, `dados/cartas.json`). As raridades continuam as dos dados: prata, ouro e prismática.

## O que mudou
| Antes | Agora |
|---|---|
| Retângulo cinza; só a faixa de cima mudava de cor | Moldura chanfrada na cor da raridade, aba com o nome da raridade, "arte" com ícone grande, hexágono com o ícone do conjunto, nome, conjunto e efeito |
| Raridades quase iguais | **Prata:** moldura prateada fina, fundo de aço com reflexos. **Ouro:** moldura dourada mais grossa que brilha, raios girando atrás do ícone e um reflexo que passa. **Prismática:** moldura e aba arco-íris que giram as cores, facetas coloridas que cintilam, brilho pulsando |
| Cursor = borda mais grossa | A carta do cursor **sobe**, cresce um pouco e ganha **contorno na cor do jogador** que pulsa |
| Confirmada = borda verde | A carta dá um **pulo**, ganha o selo **ESCOLHIDA**, as outras **apagam** e o **PRONTO!** salta |
| "59" solto | **Cronômetro** "0:59" numa caixa com ícone; nos últimos 10 s fica vermelho e pulsa |
| Título simples | Título com traços e riscos laranja dos lados; etiqueta de cada jogador com o **emblema** do time |
| — | As cartas entram uma depois da outra quando a tela abre |

Ícones novos: `arte/icones/coringa.svg` (conjunto da Troca de Lugar) e `arte/icones/relogio.svg`. Os outros conjuntos usam os ícones da Fase 01 (ataque, defesa, saque, rede = bloqueio, velocidade).

## Capturas `[VALIDADO VISUALMENTE]`
Em `producao/fase03/`. Pra comparar, a ferramenta de capturas agora troca a mão sorteada por uma fixa (uma carta de cada raridade):

| Arquivo | O que mostra |
|---|---|
| `comparacao_cartas.png` | Antes (Fase 02) à esquerda, agora à direita, com as mesmas cartas |
| `comparacao_cartas_estados.png` | J1 confirmou a 3ª carta, J2 com o cursor na 2ª |
| `cartas_1600x900.png`, `cartas_1280x720.png` | Tela nova nas duas resoluções |
| `cartas_estados_1600x900.png`, `cartas_estados_1280x720.png` | Estados nas duas resoluções |

Sem texto cortado nas duas resoluções; nomes longos ("Levantador Preciso") diminuem a letra pra caber.

```
godot --path . --resolution 1600x900 --position -30000,-30000 --script res://ferramentas/capturas_de_tela.gd -- saida=producao/fase03 telas=cartas
```

## Testes `[TESTADO]`
`testes/teste_tela_de_cartas.gd` abre a tela sozinha com cartas fixas e aperta os botões:
- 3 cartas por jogador; raridades vêm dos dados; cada uma com cor própria; moldura de ouro mais grossa que a de prata; só a prismática tem facetas;
- cronômetro começa em 1:00;
- botão apertado logo que a tela abre não conta (é do ponto que acabou);
- J1 move e confirma com Passe: selo ESCOLHIDA, as outras apagam, PRONTO!, cursor travado;
- J2 dá a volta e confirma com Ataque; depois da pausa a tela devolve as duas cartas certas;
- tempo acabando: cronômetro 0:10 muda de cor; no fim os dois ganham carta sorteada das próprias opções.

`teste_cartas.gd` e `teste_cartas_na_partida.gd` (regras e fluxo na partida) continuam passando sem mudança.

## Desempenho `[TESTADO]`
Partida no Modo Caos parada na escolha de cartas, 1600×900, `--print-fps`: **~97 FPS** (mínimo 94). As cartas de ouro e prismáticas se redesenham a cada quadro; as de prata, só quando o cursor está nelas.

## Arquivos
- `scripts/partida/carta_visual.gd` — novo: desenha uma carta (raridade, estados, animações).
- `scripts/partida/escolha_de_cartas.gd` — tela refeita (mesma lógica, mesmo sinal `terminou`; `configurar` aceita os ids dos times no fim, opcional).
- `scripts/partida/partida.gd` — passa os ids dos times pra tela de cartas (1 linha).
- `arte/icones/coringa.svg`, `arte/icones/relogio.svg` — novos.
- `testes/teste_tela_de_cartas.gd` — novo.
- `ferramentas/capturas_de_tela.gd` — cartas fixas e tela `cartas_estados`.
- README (Modo Caos saiu de "em breve" no texto do menu, que já estava ativo) e `docs/ESTADO_DO_PROJETO.md`.

## Ajustes depois da entrega (ver `docs/AJUSTES_FIDELIDADE.md`)
- **Ilustração:** cada carta mostra o atleta destaque do time do jogador fazendo a jogada do conjunto, como as ilustrações da referência.
- **TROCAR (o "Reroll" da referência):** Bloqueio troca as 3 cartas por outras 3, uma vez por partida (ajustável em `dados/cartas.json`).
- As cartas ficam na metade de cada jogador porque os dois escolhem ao mesmo tempo (a referência mostra um jogador só).

## Como testar no seu PC
1. **F5** → **MODO CAOS** → escolham os times e o estádio.
2. A tela de cartas abre antes do 1º saque. Jogador 1: **A/D** e **J**. Jogador 2: **setas** e **1** (ou os controles: direcional e A).
3. Confira: a carta do cursor sobe; ao confirmar, ela ganha o selo ESCOLHIDA e as outras apagam.
4. Espere sem escolher: nos últimos 10 s o cronômetro fica vermelho; no fim, a carta é sorteada.
5. A cada 3 pontos a escolha abre de novo; "Suas cartas" mostra as que você já tem.
