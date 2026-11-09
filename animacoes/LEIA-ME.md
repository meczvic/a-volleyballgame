# Animações

Animações do [Mixamo](https://www.mixamo.com), convertidas pro mesmo esqueleto dos
personagens do VRoid (`GeneralSkeleton`, ossos com nome humanoide). Assim uma animação
serve pros 42 atletas.

| Arquivo | Original no Mixamo | Uso |
| --- | --- | --- |
| `parado.fbx` | Idle | Atleta parado esperando |
| `correr.fbx` | Running | Correr (ainda anda pra frente sozinha, ver abaixo) |
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

| `cortada.tres` | (montada) | Pulo do bloqueio + braço do saque batendo no alto do pulo |
| `levantamento.tres` | (montada) | Pernas paradas + tronco e braços do bloqueio subindo acima da cabeça |

As duas montadas saem de `ferramentas/animacoes_combinadas.gd` (rodar de novo se mudar
`bloqueio.fbx`, `saque.fbx` ou `parado.fbx`). O Mixamo não tem nada de vôlei, então todas
essas são adaptadas de outros esportes. Vão precisar de corte (usar só o trecho certo)
e ajuste à mão no Godot quando entrarem no jogo.

## Como adicionar uma animação nova

1. No Mixamo: FBX Binary, With Skin, 30 fps. Nas de deslocamento, marque **In Place**.
2. Coloque o `.fbx` aqui com nome em português, sem acento.
3. Copie o bloco `_subresources` de `parado.fbx.import` pro `.import` do arquivo novo
   (ou, no editor: dois cliques no `.fbx` → Skeleton3D → Retarget → Bone Map =
   `mixamo_bone_map.tres`, Rename Bones e Unique Node ligados, nome `GeneralSkeleton`,
   Rest Fixer → Overwrite Axis ligado) e reimporte.
4. Rode `godot --headless --script res://testes/teste_animacoes.gd`.

**Importante:** deixe as opções de **Remove Tracks** desligadas. No Godot 4.7.2 elas
apagam quase todas as trilhas dessas animações (só sobra o quadril).

## Testado

Prova feita num personagem de exemplo do VRoid: o parado e a corrida tocam certo
(imagem em `/mnt/project-files/personagens/prova-animacao-mixamo.png` no projeto).
A corrida foi baixada sem "In Place", então o personagem anda pra frente sozinho;
quando ela entrar no jogo, o código zera esse avanço (ou baixe de novo com In Place).
