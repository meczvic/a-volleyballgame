extends RefCounted
## Quão rápida a bola sai em cada lance. Todo voo é uma parábola; uma
## gravidade maior (um múltiplo da normal) deixa o voo mais rápido e reto,
## sem mudar nada no resto da conta. Passe e levantamento ficam com a
## gravidade normal (1,0) pra dar tempo de ler; saque e cortada são mais secos.
##
## Os números ficam em dados/ajustes.json, grupo "velocidade" (os valores
## abaixo valem se faltar a chave).

const Ajustes := preload("res://scripts/comum/ajustes.gd")
const Qualidade := preload("res://scripts/regras/tempo_do_toque.gd").Qualidade

## Saque forte (força 1): múltiplo da gravidade. Força baixa chega perto do SAQUE_FRACO.
const SAQUE_FORTE := 1.5
const SAQUE_FRACO := 1.1
## Saque flutuante: só um pouco mais seco que o normal.
const SAQUE_FLUTUANTE := 1.15
## Cortada perfeita, boa e a super cortada. Cortada ruim fica normal (1,0).
const CORTADA_PERFEITA := 1.6
const CORTADA_BOA := 1.4
const SUPER_CORTADA := 2.0


static func valor(chave: String, padrao: float) -> float:
	return Ajustes.pegar("velocidade", chave, padrao)


## Múltiplo da gravidade do saque ("forca" de 0 a 1).
static func do_saque(forca: float, flutuante: bool) -> float:
	if flutuante:
		return valor("saque_flutuante", SAQUE_FLUTUANTE)
	return lerpf(valor("saque_fraco", SAQUE_FRACO), valor("saque_forte", SAQUE_FORTE), clampf(forca, 0.0, 1.0))


## Múltiplo da gravidade da cortada pela qualidade (ou da super cortada).
static func da_cortada(qualidade: int, super_cortada: bool) -> float:
	if super_cortada:
		return valor("super_cortada", SUPER_CORTADA)
	if qualidade == Qualidade.PERFEITO:
		return valor("cortada_perfeita", CORTADA_PERFEITA)
	if qualidade == Qualidade.BOM:
		return valor("cortada_boa", CORTADA_BOA)
	return 1.0
