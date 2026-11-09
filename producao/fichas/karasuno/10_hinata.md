# Ficha visual: Shoyo Hinata (Karasuno, nº 10)

Piloto da produção. Tudo aqui é o alvo; o que foi realmente reproduzido no VRoid
entra na seção "Resultado" depois do piloto, com as capturas.

Referências (abrir do lado ao modelar, não copiar imagens pro repositório):
- Página oficial do anime, personagens: https://haikyu.jp/character/
- Perfil no wiki de fãs: https://haikyuu.fandom.com/wiki/Sh%C5%8Dy%C5%8D_Hinata

## Prioridade de reconhecimento (câmera alta, de longe)

1. **Cabelo laranja vivo e espetado**, com volume pra todo lado. É o que mais identifica.
2. **Baixo**: o mais baixo dos 5 de quadra do Karasuno (só o líbero Nishinoya é menor).
3. **Camisa preta com detalhe laranja, número 10.**

## Corpo

| Item | Alvo | Observação |
| --- | --- | --- |
| Altura | 1,63 m (162,8 cm no perfil do 1º ano) | Conferir na fonte. No jogo, a cápsula tem 1,80 m. |
| Proporção | Anime adulto jovem, cabeça ~1/7 da altura | Nada de chibi. Reduzir um pouco a cabeça padrão do VRoid. |
| Físico | Magro e atlético, pernas fortes (salto) | Ombros estreitos, cintura fina, panturrilha definida. |
| Postura | Neutra (T-pose no VRoid) | A animação dá a energia. |

## Rosto

| Item | Alvo |
| --- | --- |
| Formato | Rosto oval, queixo pequeno, jovem |
| Olhos | Grandes e redondos, castanho-alaranjados (âmbar), íris clara com brilho |
| Sobrancelhas | Finas, laranja como o cabelo |
| Expressão neutra | Animado: olhos bem abertos, boca levemente sorrindo |
| Pele | Clara, tom quente (`#F6E1CF` como ponto de partida) |

## Cabelo

| Item | Alvo |
| --- | --- |
| Cor | Laranja vivo (`#F07E2A` base, `#F7A54A` brilho, `#C9561A` sombra) |
| Comprimento | Curto: cobre a testa, não passa da nuca |
| Silhueta | Mechas espetadas saindo em todas as direções, topo volumoso e arredondado |
| Franja | Mechas grossas apontando pra baixo e pros lados, sem cobrir os olhos |
| Laterais | Pontas pra fora acima das orelhas |

Limite conhecido: o VRoid MCP Bridge não cria cabelo do zero. O caminho é partir do
penteado curto e espetado mais parecido entre os presets, depois alongar, clonar e
ajustar mechas com as ferramentas de pincel. Se não ficar reconhecível, o ajuste fino
fica pra edição manual no VRoid.

## Uniforme (Karasuno, de `dados/times.json`)

| Peça | Cor | Detalhe |
| --- | --- | --- |
| Camisa | Preta `#1F1F24` | Gola em V, punhos das mangas e faixa da barra em laranja `#F28C28` |
| Número | 10, laranja `#F28C28` | Frente (no peito, menor) e costas (grande). Arquivo: `producao/uniformes/karasuno/numeros/10.png` |
| Shorts | Preto `#1F1F24` | Faixa lateral laranja |
| Joelheiras | Pretas | Curtas, nos dois joelhos |
| Meias e tênis | Meia branca curta, tênis branco com detalhe laranja | |

Prévia chapada do uniforme do time: `producao/uniformes/karasuno/previa.png`.

## Checagem visual do piloto

Vistas a capturar (salvar em `producao/capturas/karasuno/10_hinata_<vista>.png`):
`frente`, `perfil`, `tres_quartos`, `costas` no VRoid, e `godot` (na câmera do jogo).

- [ ] Reconhecível de longe pelo cabelo
- [ ] Mais baixo que os colegas de quadra
- [ ] Número 10 legível na frente e nas costas
- [ ] Sem cabelo atravessando a camisa ou o rosto
- [ ] Sem peça transparente faltando depois da exportação

## Resultado

Ainda não modelado. Preencher depois do piloto: o que ficou igual, o que foi
aproximado e por quê, tamanho do VRM, avisos do exportador.
