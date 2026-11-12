extends RefCounted
## Nomes fixos dos lances e dos botões, num lugar só (Fase D do plano de
## melhorias). Antes cada arquivo escrevia "passe", "cortada" etc. na mão, e um
## erro de digitação passava sem aviso. Os valores continuam os mesmos textos
## (as tabelas de TempoDoToque, Energia e dados/*.json usam eles como chave).

## Tipo do toque, pra medir o tempo do botão (TempoDoToque) e a energia.
const PASSE := "passe"
const LEVANTAMENTO := "levantamento"
const CORTADA := "cortada"

## Botões que as entradas mandam no sinal "comando" (teclado, controle,
## computador). Os nomes são os das ações em scripts/entrada/teclas.gd.
const BOTAO_PASSE := "passe"
const BOTAO_ATAQUE := "ataque"
const BOTAO_FLUTUANTE := "saque_flutuante"
const BOTAO_BLOQUEIO := "bloqueio"
const BOTAO_MERGULHO := "mergulho"
