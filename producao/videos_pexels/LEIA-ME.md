# Vídeos do Pexels para captura de movimento

Vídeos de vôlei com **licença livre do Pexels** (pode baixar, cortar e usar, inclusive em projeto comercial, sem pagar; dar crédito é opcional: https://www.pexels.com/license/). Servem de entrada para a captura de movimento por vídeo (DeepMotion, Rokoko Vision etc.), como foi feito com a cortada do Victor.

Os `.mp4` **não vão pro Git** (estão no `.gitignore`; são ~49 MB). Este LEIA-ME vai, com o link de cada um pra baixar de novo. O `.gdignore` faz o Godot ignorar a pasta.

Escolhidos em 12/11/2026 olhando 8 a 12 quadros de cada vídeo (uns 40 vídeos vistos). O que a captura precisa: **uma pessoa só, corpo inteiro (com os pés), câmera parada**.

## Os que servem

| Arquivo | Pra qual animação | Situação | Link |
| --- | --- | --- | --- |
| `toque_6217270.mp4` | **Levantamento (toque)** | ✅ **Já está no jogo** (12/11/2026). Homem sozinho, de frente, câmera parada, 22 s fazendo toque pra si mesmo: espera com os braços baixos, sobe as mãos até a testa quando a bola chega (contatos em 2,0 s, 7,8 s, 13,4 s e 19,3 s) e estica os braços. **Não tem manchete** (a primeira olhada, com poucos quadros, enganou). Foi usado o trecho de 1 a 4 s. Vertical 1080x1920, 30 fps | [Pexels](https://www.pexels.com/video/man-playing-volleyball-by-himself-6217270/) |
| `saque_por_cima_6217332.mp4` | **Saque em pé (flutuante)** | ✅ **No jogo desde 13/11/2026** (trecho 3 a 10,3 s, 8 créditos; é câmera lenta: lança aos 3 s e bate aos 8 s). De lado, corpo inteiro, câmera parada: lança, braço por cima da cabeça, bate e acompanha. Gente ao fundo, longe. Vertical 1080x1920, 16 s | [Pexels](https://www.pexels.com/video/volleyball-player-serving-ball-6217332/) |
| `saque_viagem_6217265.mp4` | **Saque viagem** e referência de **corrida de ataque** | ✅ **No jogo desde 13/11/2026** (trecho 1 a 8,1 s, 8 créditos; câmera lenta; as pernas saem tortas em alguns quadros). Lança, corre, pula e bate no ar. A câmera acompanha o atleta (pode deixar a animação "andando"; o jogo trava o deslocamento de qualquer jeito). Vertical, 9 s | [Pexels](https://www.pexels.com/video/man-serve-the-ball-6217265/) |
| `cortada_com_corrida_6216857.mp4` | **Corrida de ataque + cortada** | ❌ Testado em 13/11/2026 (trecho 6 a 9 s, 4 créditos, `animacoes/deepmotion/cortada_corrida.fbx`): o DeepMotion não pegou o pulo e o peito gira de lado na batida; ficou fora do jogo. De lado, corpo inteiro: lança pra si, corre, pula e bate. A câmera acompanha um pouco e tem uma 2ª pessoa no fundo. Horizontal 1920x1080, 10 s | [Pexels](https://www.pexels.com/video/side-view-of-a-man-spiking-the-ba-6216857/) |
| `saque_feminino_6216953.mp4` | Saque (alternativa) | ⚠️ Câmera parada e corpo inteiro, mas a atleta aparece pequena, longe. 13 s | [Pexels](https://www.pexels.com/video/woman-serving-volleyball-ball-6216953/) |
| `saque_estudio_10350522.mp4` | Saque, só os braços | ⚠️ Estúdio com fundo preto (ótimo), mas a roupa escura faz **as pernas sumirem no escuro**. Serve pra conferir o braço. 2048x1080, 25 fps, 9 s | [Pexels](https://www.pexels.com/video/sportsman-serving-ball-in-volleyball-game-10350522/) |
| (não baixado) manchete 6217284 | **Manchete** | ✅ **No jogo desde 13/11/2026**: mandado direto do Pexels pro DeepMotion (trecho 3 a 7,5 s, 5 créditos). Atleta de frente em base de recepção, passada pro lado e manchete em ~5,4 s. Tem quem lança a bola ao fundo, à esquerda, e a câmera mexe um pouco. Vertical 1080x1920, 8,5 s | [Pexels](https://www.pexels.com/video/6217284/) |

Os 5 primeiros são do mesmo autor (**Pavel Danilyuk**), na mesma quadra coberta: as animações saem com o mesmo jeito de jogar.

## O que não tem (procurado e não achado com licença livre)

- **Mergulho:** 12169434 (mulher, na areia, base de defesa e mergulho de um braço) ✅ **no jogo desde 13/11/2026** como mergulho pra direita (trecho 4 a 8 s, 4 créditos; filmado de frente, vai em `SEM_MEIA_VOLTA`). Ainda não usados: 12169455 (homem) e 12169398 (mulher). A câmera acompanha um pouco.
- **Bloqueio com deslocamento na rede** e **levantamento com pulo**: os vídeos do Pexels com bloqueio mostram várias pessoas juntas na rede. Pra esses, o caminho é o Victor gravar imitando vídeos de treinador (lista em `docs/ESTUDO_DO_VOLEI.md`, seção 8) ou o pacote Animo Mocap Volleyball.

## Vistos e descartados

Não são manchete (vistos em 13/11/2026): 6217271 (quica a bola no chão), 6217339 (saque), 12169454 e 12169428 (cortada na praia), 6217342 (toque, pernas cortadas), 6217281, 6217282, 6217068 (posando). Câmera que mexe ou vira: 6216964, 6217069, 6217337, 6217330, 6217335, 6217334, 6217338, 6216961, 6217175, 6216856, 6217189, 6217276. Várias pessoas no quadro: 6216962, 6216849, 6216852, 6216863, 6216865, 6216963, 6216861, 6217340, 6217344, 6216855, 6216956, 12169709. Corpo cortado (só da cintura pra cima): 6217115, 6217341, 10350515, 10350516, 10350517, 10350518, 10350520, 10350524. Pessoa muito pequena: 6217269.

## Como usar no DeepMotion (do jeito que foi feito com o toque)

1. Animate 3D → enviar o vídeo, modo "Single person", boneco padrão (Adult Female, o mesmo da cortada). Plano grátis: até 20 s por clipe e **1 crédito por segundo** (o mês tinha 58). Cortar no site ("Trim & Crop", em segundos inteiros) só o trecho de um lance, com folga antes e depois: o toque usou 00:01 a 00:04 = 3 créditos.
2. Ligar só o **Physics Filter**. MP4 Output desligado.
3. Biblioteca → ⋮ → Download → trocar BVH por **FBX**. Vem um `.zip` com dois FBX: usar o **sem** "(includeTPose)".
4. Copiar pra `animacoes/deepmotion/<nome>.fbx`, com o mesmo `.fbx.import` da cortada (mapa de ossos `deepmotion_bone_map.tres`), e incluir em `CONVERSOES` no `ferramentas/converte_deepmotion.gd`. **Vídeo filmado de frente vai em `SEM_MEIA_VOLTA`** (senão o atleta fica de costas).
5. Rodar o conversor, medir onde as mãos ficam na hora do contato (como em `testes/teste_sincronia_dos_toques.gd`) e ajustar `TRECHOS` e `PREPARO` no `animador.gd`.
