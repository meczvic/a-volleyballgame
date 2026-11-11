# Ajustes de fidelidade às referências (fases 01 a 03)

Data: 10/11/2026. Branch `claude/fidelidade-referencias`, a partir de `claude/fase-03-cartas`.

Depois das fases 01–03, algumas coisas das referências tinham ficado como "aproximação". Este ajuste faz essas partes como nas imagens. Os nomes em japonês ficaram de fora a pedido do Victor.

## O que mudou
| Tela | Antes | Agora |
|---|---|---|
| Placar (`Placar Anime Karasuno vs Nekoma.png`) | No ponto, um risco fino e um clarão | **Corte de luz dourado** atravessando a caixa de quem pontuou, **faíscas** voando e **brilho** em volta (0,65 s), além do número amarelo e do tremor que já existiam |
| Partida | A caixa "Ponto Karasuno!" aparecia junto com a faixa PONTO! | Só a faixa (ela já mostra quem pontuou e o motivo). O texto continua guardado pros testes e pro robô |
| Cartas (`Escolha Sua Carta de Vôlei.png`) | "Arte" era só o ícone do conjunto | **Ilustração:** o atleta destaque do time do jogador fazendo a jogada da carta (ataque = cortada, defesa = postura de recepção, saque, rede = bloqueio, velocidade = corrida, coringa = comemoração), com luz de contorno na cor da raridade, em cima do fundo da raridade. Carta um pouco mais alta (360 px) |
| Cartas | Sem "Reroll" | Botão **TROCAR (1)**: **Bloqueio** (L, 3 numérico ou Y) troca as 3 cartas por outras 3. Uma vez por partida por jogador (`trocas_por_partida` em `dados/cartas.json`). Sem troca, o botão fica apagado e balança se apertar |

### Como a ilustração é feita
A carta monta um "estúdio" 3D pequeno só pra ela, posa o personagem do jogo (o mesmo da partida, com o uniforme em jogo, inclusive o reserva), espera a pose entrar, mede o corpo pelos ossos, enquadra do joelho ou da cintura pra cima e tira uma foto. A foto fica guardada: a mesma carta do mesmo time não fotografa de novo. Quando a Fase 06 melhorar o personagem, as cartas melhoram juntas. Sem placa de vídeo (testes), aparece o ícone grande como antes.

### Regra da troca
`partida._trocar_cartas(time, ids_na_tela)`: se o time ainda tem troca, gasta uma e sorteia outras cartas pela mesma regra do sorteio normal (`Cartas.sortear`), tentando não repetir as que estavam na tela. A tela de cartas chama isso quando o jogador aperta Bloqueio. Nada muda nas outras regras das cartas.

## Capturas `[VALIDADO VISUALMENTE]`
Em `producao/fidelidade/`:
- `comparacao_efeito_de_ponto.png` — placar no instante do ponto: Fase 02 à esquerda, agora à direita.
- `comparacao_ponto_tela_inteira.png` — a tela inteira no ponto (sem a caixa duplicada).
- `comparacao_cartas.png` — tela de cartas: Fase 03 à esquerda, agora à direita.
- `cartas_*`, `cartas_estados_*`, `cartas_troca_*` — 1600×900 e 1280×720; `cartas_troca` é depois do Jogador 2 usar o TROCAR.
- `placar_ponto_*` — 1600×900 e 1280×720.

## Testes `[TESTADO]`
- Suíte inteira: **28 de 28 com `OK:`**, sem `ERROR` nos logs.
- `teste_tela_de_cartas.gd` ganhou o teste do TROCAR: Bloqueio troca as 3 cartas, o cursor volta pra 1ª, a troca é gasta, o botão mostra TROCAR (0), sem troca nada muda, e a carta escolhida depois da troca é a nova.
- `teste_cartas_na_partida.gd` ganhou o teste da regra: os dois times começam com as trocas dos dados, trocar gasta só do time certo e devolve cartas, sem troca não vem nada, e a tela recebe as trocas.
- `teste_placar_na_partida.gd`: o efeito de ponto solta as faíscas na caixa de quem pontuou, não na do outro.
- Partida completa do robô: terminou sozinha em 443 s de jogo, Karasuno venceu por 2 sets a 1; 32 rallies, o maior com 50 toques; nenhuma linha de erro no log.

## Desempenho `[TESTADO]`
Partida no Modo Caos parada na escolha de cartas, 1600×900: **~156 FPS** (as fotos são tiradas uma vez; depois a tela é só 2D).

## Arquivos
- `scripts/partida/placar_visual.gd` — efeito de ponto novo.
- `scripts/partida/partida.gd` — esconde a caixa duplicada; guarda as trocas e sorteia as cartas novas (`_trocar_cartas`); passa os times e as trocas pra tela de cartas.
- `scripts/partida/carta_visual.gd` — foto do atleta na arte, carta mais alta.
- `scripts/partida/escolha_de_cartas.gd` — botão TROCAR.
- `scripts/regras/cartas.gd` — `trocas_por_partida`.
- `dados/cartas.json` — `trocas_por_partida: 1`.
- Testes e `ferramentas/capturas_de_tela.gd` (tela `cartas_troca`).

## Como testar no seu PC
1. **F5** → **MODO CAOS** → times → estádio.
2. Na tela de cartas: cada carta mostra o atleta do seu time na jogada. Aperte **Bloqueio** (L / 3 / Y): as cartas trocam e o botão vira TROCAR (0).
3. Jogue um ponto: o número de quem pontuou é cortado por um risco dourado com faíscas; no meio da tela aparece só a faixa PONTO!.
