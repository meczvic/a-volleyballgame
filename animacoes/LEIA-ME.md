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

Faltam: manchete, levantamento, cortada, bloqueio, saque, mergulho e comemoração.
O Mixamo não tem nada de vôlei, então essas vão sair de outras animações
(pulo, arremesso, defesa de goleiro) ou ser feitas à mão no Godot.

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
