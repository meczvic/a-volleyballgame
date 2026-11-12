# Animações

Animações do [Mixamo](https://www.mixamo.com), convertidas pro mesmo esqueleto dos
personagens do VRoid (`GeneralSkeleton`, ossos com nome humanoide). Assim uma animação
serve pros 42 atletas.

| Arquivo | Original no Mixamo | Uso |
| --- | --- | --- |
| `parado.fbx` | Idle | Atleta parado esperando |
| `correr.fbx` | Running | Correr (o animador trava o avanço) |
| `lateral_esquerda.fbx` | Left Strafe | Passo lateral |
| `lateral_direita.fbx` | Right Strafe | Passo lateral |
| `defesa_lateral.fbx` | Goalkeeper Sidestep | Deslocamento de defesa |
| `manchete.fbx` | Goalkeeper Catch 1 | Abaixa e pega a bola baixa |
| `bloqueio.fbx` | Goalkeeper Catch | Tem um pulo com os braços pra cima |
| `saque.fbx` | Goalie Throw | Arremesso com o braço por cima |
| `mergulho.fbx` | Goalkeeper Diving Save | Mergulho de lado |
| `comemoracao_torcida.fbx` | Rallying | Comemoração, em loop |
| `comemoracao_palmas.fbx` | Clapping | Palmas, em loop |
| `comemoracao_vitoria.fbx` | Victory | Fim de jogo (mexe pouco) |
| `bloqueio_tapa.fbx` | Defender (Jumping And Swatting At A Ball) | Pula e bate na bola com o braço; candidata a bloqueio |
| `bloqueio_erro.fbx` | Goalkeeper Miss | Pula e a bola passa |
| `mergulho_direita.fbx` | Goalkeeper Diving Save (Right) | Mergulho pro outro lado (o `mergulho.fbx` é o Left) |
| `levantar_do_chao.fbx` | Getting Up (From Stomach) | Levantar depois do mergulho |
| `espera_defesa.fbx` | Goalkeeper Idle (Without Ball) | Agachado esperando a bola, em loop |
| `pulo_parado.fbx` | Unarmed Jump | Pulo no lugar |
| `pulo_correndo.fbx` | Jump (Forward Running Jump) | Pulo depois de correr; candidata à corrida de ataque |
| `aterrissagem.fbx` | Landing | Queda depois do pulo |
| `comemoracao_punho.fbx` | Fist Pump | Ponto ganho |
| `comemoracao_pulo.fbx` | Joyful Jump | Ponto ganho, mais animado |
| `ponto_perdido_frustrado.fbx` | Defeated | Ponto perdido |
| `ponto_perdido_desanimado.fbx` | Disappointed | Ponto perdido |

| `cortada.tres` | (montada) | Pulo do bloqueio + braço do saque batendo no alto do pulo |
| `levantamento.tres` | (montada) | Pernas paradas + tronco e braços do bloqueio subindo acima da cabeça |
| `cortada_deepmotion.tres` | (DeepMotion, gravada pelo Victor) | **Cortada usada no jogo.** Sai de `deepmotion/cortada.fbx` |

A `cortada.tres` montada ficou guardada, mas o jogo usa a do DeepMotion.
As duas montadas saem de `ferramentas/animacoes_combinadas.gd` (rodar de novo se mudar
`bloqueio.fbx`, `saque.fbx` ou `parado.fbx`). O Mixamo não tem nada de vôlei, então todas
essas são adaptadas de outros esportes.

## Na partida

`scripts/visual/animador.gd` liga essas animações a cada atleta que tem personagem:

- **Movimento, sozinho:** parado quando o atleta não anda; passo lateral quando anda
  de lado olhando pra rede; corrida (virado pra onde vai) no resto. A velocidade da
  animação acompanha a do atleta.
- **Lances:** saque, manchete (1º toque e bola devolvida de graça), levantamento,
  cortada, bloqueio (os da rede) e mergulho (botão Mergulho). O mergulho vai pro
  lado da bola: `mergulho` pra esquerda do atleta, `mergulho_direita` pra direita.
- **Ponto:** quem fez o ponto comemora (palmas, punho ou pulo, cada atleta uma) e
  quem perdeu reage (desanimado ou frustrado). A comemoração e a reação param assim
  que o atleta anda pro lugar do próximo saque. No fim da partida, quem venceu
  comemora com a torcida e quem perdeu fica frustrado.
- **Defesa:** parado em quadra, o time que espera o saque ou o ataque do outro fica
  agachado (`espera_defesa`); o time com a bola fica na pose de espera normal.
- Cada lance toca só o trecho que importa (tabela `TRECHOS` no começo do arquivo).
  Na cortada e no bloqueio o alto do pulo da animação cai junto com o alto do pulo do jogo.
- O quadril fica travado no lugar em todas (até na corrida, que veio sem In Place):
  quem anda é o atleta. Na cortada e no bloqueio o quadril também não sobe, porque
  o jogo já faz o pulo.

Pra ajustar um lance (ex.: a cortada começa cedo demais), mude os números em `TRECHOS`.
Ainda sem uso: `defesa_lateral`, `comemoracao_vitoria`, `bloqueio_tapa`, `bloqueio_erro`,
`pulo_parado`, `pulo_correndo`, `aterrissagem` e `levantar_do_chao`. Os pulos e o bloqueio
com tapa trazem corrida ou queda própria e não casam com o pulo do jogo (0,6 s, feito pela
partida); o mergulho já levanta sozinho no fim, então o `levantar_do_chao` sobrou. As
baixadas em 12/11/2026 vieram sem In Place (o animador trava o quadril).

## Animações do DeepMotion

O DeepMotion transforma um vídeo em animação. O `.fbx` dele usa outros nomes de osso
(`hips_JNT`, `l_arm_JNT`...), então fica em `animacoes/deepmotion/` com o próprio
`deepmotion_bone_map.tres` (mesmos passos do Mixamo abaixo, trocando o Bone Map, o nome
da animação no `.import` e com Embedded Image Handling = Discard, pra não extrair a
textura do boneco do DeepMotion). Depois, `ferramentas/converte_deepmotion.gd` gira
meia volta (o DeepMotion entrega o atleta de costas) e salva o `.tres` usado no jogo:

    godot --headless --script res://ferramentas/converte_deepmotion.gd

Na partida, o atleta sai do chão no botão Ataque e bate no alto do pulo
(`TEMPO_ATE_A_BATIDA`), na pose de `BATIDA_DA_CORTADA` (1,62 s). O pulo tem a altura
que a mão daquele personagem precisa pra chegar na bola, o atleta vai pra baixo dela
no ar e, no fim, a bola encosta na mão (`IMA_DA_MAO`) e sai de lá.

O quadril da cortada sobe ~1,4 m no vídeo e não volta (erro comum de captura por
vídeo); como na cortada o pulo é do jogo, o animador trava essa altura e não aparece.

## Como adicionar uma animação nova

1. No Mixamo: FBX Binary, With Skin, 30 fps. Nas de deslocamento, marque **In Place**.
2. Coloque o `.fbx` aqui com nome em português, sem acento.
3. Copie o bloco `_subresources` de `parado.fbx.import` pro `.import` do arquivo novo
   (ou, no editor: dois cliques no `.fbx` → Skeleton3D → Retarget → Bone Map =
   `mixamo_bone_map.tres`, Rename Bones e Unique Node ligados, nome `GeneralSkeleton`,
   Rest Fixer → Overwrite Axis ligado) e reimporte.
4. Rode `godot --headless --script res://testes/teste_animacoes.gd`.
5. Pra usar na partida, coloque em `ARQUIVOS` no `scripts/visual/animador.gd`.

**Importante:** deixe as opções de **Remove Tracks** desligadas. No Godot 4.7.2 elas
apagam quase todas as trilhas dessas animações (só sobra o quadril).

## Testado

Prova feita num personagem de exemplo do VRoid: o parado e a corrida tocam certo
(imagem em `/mnt/project-files/personagens/prova-animacao-mixamo.png` no projeto).
A corrida foi baixada sem "In Place"; o animador zera esse avanço.
Depois, uma partida inteira jogada por um robô com modelos de exemplo (12 em quadra)
rodou sem erros, com cada lance e a corrida aparecendo nos personagens.
