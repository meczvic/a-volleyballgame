# Elenco: os 42 atletas

Os dados ficam em `dados/elenco.json` (nome, número, posição e nome do arquivo).
Cada time tem **6 jogadores de quadra, sem líbero** (decisão do Victor em 09/11/2026): 1 levantador,
2 ponteiros, 2 centrais e 1 oposto. Quem era líbero virou o que faltava no time (oposto ou central).
As fichas dos ex-líberos dos times de Haikyuu ainda dizem "líbero"; esses times vão ser trocados por originais.
A ordem da lista é a posição inicial no rodízio (1 a 6).

## Como o elenco foi escolhido

- Base: os titulares de cada time no anime/mangá, com prioridade pra quem é mais reconhecível.
- Como são só 6 vagas, um titular de quadra ficou de fora em alguns times (tabela abaixo).
  Trocar é só editar `dados/elenco.json`.
- O time **Brasil** é inventado: 6 atletas originais, sem base em pessoas reais.

| Time | Ficou de fora | Por quê |
| --- | --- | --- |
| Karasuno | Ryunosuke Tanaka (5) | Com o líbero Nishinoya, sobram 5 vagas; Daichi e Asahi ficaram pela função (capitão, ás). |
| Nekoma | Shohei Fukunaga (6) | Mesmo motivo; Kai, Yamamoto e Kuroo são mais conhecidos. |
| Aoba Johsai | Akira Kunimi (13), Kentaro Kyotani (16) | Mantidos os titulares do 3º ano + Kindaichi. |
| Shiratorizawa | Taichi Kawanishi (12), Eita Semi (3) | Semi é sacador reserva; Tendo é o central mais reconhecível. |
| Fukurodani | Wataru Onaga (12) | Washio ficou como central. |
| Inarizaki | Hitoshi Ginjima, Ren Omimi | Kita é reserva no jogo contra o Karasuno, mas é o capitão e muito reconhecível. |

## Números: o que foi conferido

| Time | Situação | Fonte |
| --- | --- | --- |
| Karasuno, Nekoma, Aoba Johsai, Shiratorizawa, Fukurodani | Todos os números conferidos | [Sportskeeda: Haikyuu jersey numbers](https://www.sportskeeda.com/anime/haikyuu-jersey-numbers) |
| Inarizaki | **A conferir:** Kita 1, Aran 4, Atsumu 7, Akagi 9, Suna 10, Osamu 11 (de memória; a fonte acima não tem Inarizaki e o wiki de fãs não abriu daqui) | Conferir no [wiki de fãs](https://haikyuu.fandom.com/wiki/Inarizaki_High) antes de fazer as camisas |
| Brasil | Inventados | — |

Cada atleta tem uma ficha visual em `producao/fichas/`. As alturas dos personagens de Haikyuu nas fichas vêm de memória do perfil oficial e estão marcadas pra conferir antes de modelar.

## Time Brasil (original)

| Nº | Nome | Posição | Visual proposto |
| --- | --- | --- | --- |
| 7 | Caio Ventura | Levantador | 1,86 m, pele morena, cabelo preto curto e cacheado com risca lateral |
| 10 | Davi Rocha | Ponteiro (ás) | 1,92 m, pele negra, black power médio com faixa na testa |
| 13 | Lucas Paim | Central | 2,04 m, pele parda, tranças nagô presas atrás |
| 4 | Rafael Azevedo | Central (capitão) | 1,94 m, pele morena clara, cabelo castanho ondulado na altura do queixo |
| 8 | Thiago Barreto | Oposto | 2,01 m, pele clara, loiro descolorido com laterais raspadas |
| 1 | Enzo Takahashi | Ponteiro | 1,76 m, nipo-brasileiro, cabelo preto liso com franja comprida |

## Direitos

Os personagens de Haikyuu são fan assets pra uso privado entre amigos: não publicar os modelos.
Pra uma versão pública, trocar nomes e aparências aqui, em `dados/elenco.json` e nas fichas.
