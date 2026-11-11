# Atleta no estilo anime (refazendo o modelo da Fase 06)

Data: 11/11/2026. Branch `claude/atleta-v2`, a partir da principal (`claude/project-thread-o4s5hf`, Fases 00 a 06).

## Por que
O dono olhou o Hinata da Fase 06 e disse que não era o melhor que dava pra fazer. Comparando com as referências (`Partida Karasuno contra Nekoma.png` e `Seleção de Times no Ginásio Japonês.png`), faltava muito: cabelo de capacete com cones, olhos em disco, uniforme com um "cinto", short justo, tênis que parecia meia e nada de traço de anime.

## O que mudou (tudo por código, vale pros 42)
| Antes | Agora |
|---|---|
| **Normais da malha viradas pra dentro** (defeito antigo): luz invertida e contorno escondido dentro do corpo | Normais pra fora (`instancias()` em `gerador_de_atleta.gd`): luz do lado certo e **contorno preto aparecendo** |
| Contorno só em metros, sumia de longe | `shaders/contorno.gdshader` ganhou `largura_minima_px` (1,5 px): o traço aparece na partida também |
| Sombreamento que estourava pro branco com a luz do ginásio | `shaders/atleta.gdshader`: luz e sombra em duas faixas, sombra levemente lilás (pele mais quente), limite pra não estourar; igual em qualquer estádio |
| Olhos em disco, boca em caixinha | `shaders/rosto.gdshader` numa máscara colada no rosto: olho de anime (íris com degradê, pupila, dois brilhos), **cílio de cima grosso com pontinha**, sobrancelha em arco, nariz discreto, boca (séria, neutra ou sorriso aberto). Tudo vem do `aparencia.json` (olhos grandes/pequenos, pálpebras caídas/bravas, sobrancelha, expressão) |
| Cabelo: capacete + cones finos com ponta preta | **Mechas largas** que afinam em ponta, facetadas (low-poly de propósito): franja, lados, nuca e espetos. Uma tabela por estilo (`_estilo_de_cabelo`) cobre os 18 estilos; cachos viraram calombos facetados; cabelo não projeta sombra no rosto |
| Faixa laranja na barra parecendo cinto | Camisa solta por cima do short, barra sem faixa; **painéis laterais largos** na cor do time; gola na cor de detalhe |
| Short justo e curto | Short **folgado**, um pouco mais comprido, com **faixa lateral larga** |
| Número da frente pequeno e na cor de detalhe; sumia embaixo da camisa quando o atleta respirava | Número maior, na cor que **mais contrasta** com a camisa (branco na Karasuno, azul-marinho na Aoba Johsai) e acompanhando os ossos da camisa |
| Tênis branco igual à meia | Tênis com cano, sola grossa escura, **bico, calcanhar e faixa na cor do time**; meia curta branca |

Os dados dos 42 (`dados/aparencia.json`, `dados/elenco.json`) e as animações não mudaram.

## Capturas `[VALIDADO VISUALMENTE]`
- `producao/atleta_v2/comparacao_hinata_{rosto,frente,tres_quartos,costas,espera}.png`: Hinata antes (esquerda) e agora (direita).
- `producao/atleta_v2/comparacao_partida.png`: a mesma cena de jogo, Fase 06 × agora.
- `producao/atleta_v2/selecao_inicio_1600x900.png`, `cartas_1600x900.png`, `partida_saque_1600x900.png`, `ginasio_geral_1600x900.png`: o atleta novo nas telas do jogo.
- `producao/capturas/<time>/folha.png`: os 6 de cada um dos 7 times, frente e costas.
- `producao/capturas/karasuno/10_hinata_rosto.png`: vista nova de close do rosto (`ferramentas/capturas.gd`, vista `rosto`).

## Testes `[TESTADO]`
- Novo `testes/teste_atleta_anime.gd`: normais pra fora, rosto pelo shader (sem sombra), cabelo com mechas e sem sombra, contorno com largura mínima, cor do número pelo contraste, e os **42 atletas** montando com rosto e cabelo.
- **31 de 31** arquivos de `testes/` passaram.
- **Robô:** partida completa Karasuno × Nekoma no ginásio japonês, 2 × 1 em sets, 30 rallies (maior com 60 toques), 0 linhas de erro.
- **FPS de verdade** (janela 1600×900, `--print-fps`, mesma partida de 45 s, RTX 3060 Ti): **129 FPS** agora contra **102 FPS** antes. Ficou mais leve porque o cabelo não projeta mais sombra.

## Limites conhecidos
- Continua low-poly gerado por código: não é a ilustração 2D da referência (o próprio pacote diz que não precisa ser).
- De longe (na folha dos 6), números de traço fino como "1" e "7" na frente ficam finos; de perto e nas costas saem inteiros.
