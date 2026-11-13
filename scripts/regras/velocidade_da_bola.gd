extends RefCounted
## Quão rápida a bola sai em cada lance. Todo voo é uma parábola; uma
## gravidade maior (um múltiplo da normal) deixa o voo mais rápido e reto,
## sem mudar nada no resto da conta.
##
## ATENÇÃO: os números daqui são MÚLTIPLOS da gravidade (1,0 = 9,8 m/s²).
## Quem lança a bola passa por `gravidade()` pra virar m/s². (Até 12/11/2026
## os múltiplos iam crus pra bola e saque e cortada voavam com ~1,5 m/s²:
## o saque levava 4 s. Veja teste_velocidade_da_bola.gd.)
##
## Tempo de voo de referência (saque 15 m, cortada 6 m, passe 4,5 m):
## saque forte ~0,85 s, fraco ~1,3 s; cortada perfeita ~0,6 s; passe ~1,1 s.
##
## Os números ficam em dados/ajustes.json, grupo "velocidade" (os valores
## abaixo valem se faltar a chave).

const Ajustes := preload("res://scripts/comum/ajustes.gd")
const Trajetoria := preload("res://scripts/regras/trajetoria.gd")
const Qualidade := preload("res://scripts/regras/tempo_do_toque.gd").Qualidade

## Saque forte (força 1): múltiplo da gravidade. Força baixa chega perto do SAQUE_FRACO.
const SAQUE_FORTE := 3.0
const SAQUE_FRACO := 2.0
## Saque flutuante: meio-termo.
const SAQUE_FLUTUANTE := 2.5
## Cortada perfeita, boa, ruim e a super cortada.
const CORTADA_PERFEITA := 3.5
const CORTADA_BOA := 3.0
const CORTADA_RUIM := 2.0
const SUPER_CORTADA := 5.0
## Passe (recepção) e levantamento.
const PASSE := 1.8
const LEVANTAMENTO := 2.2
## Cortada em LINHA RETA: velocidade da bola em m/s (não é múltiplo de nada).
## Cortada ruim não tem (sai em arco, fraca): 0.
const RETA_PERFEITA := 22.0
const RETA_BOA := 18.0
const RETA_SUPER := 28.0


static func valor(chave: String, padrao: float) -> float:
	return Ajustes.pegar("velocidade", chave, padrao)


## Converte um múltiplo da gravidade em gravidade de verdade (m/s²),
## que é o que `Bola.lancar` espera.
static func gravidade(multiplo: float) -> float:
	return multiplo * Trajetoria.GRAVIDADE


static func do_passe() -> float:
	return valor("passe", PASSE)


static func do_levantamento() -> float:
	return valor("levantamento", LEVANTAMENTO)


## Múltiplo da gravidade do saque ("forca" de 0 a 1).
static func do_saque(forca: float, flutuante: bool) -> float:
	if flutuante:
		return valor("saque_flutuante", SAQUE_FLUTUANTE)
	return lerpf(valor("saque_fraco", SAQUE_FRACO), valor("saque_forte", SAQUE_FORTE), clampf(forca, 0.0, 1.0))


## Velocidade (m/s) da cortada em linha reta, ou 0 se ela sai em arco
## (cortada ruim). Se a linha reta bateria na rede, a bola usa o arco de
## `da_cortada` (veja Bola.lancar_reto).
static func da_cortada_reta(qualidade: int, super_cortada: bool) -> float:
	if super_cortada:
		return valor("reta_super", RETA_SUPER)
	if qualidade == Qualidade.PERFEITO:
		return valor("reta_perfeita", RETA_PERFEITA)
	if qualidade == Qualidade.BOM:
		return valor("reta_boa", RETA_BOA)
	return 0.0


## Múltiplo da gravidade da cortada pela qualidade (ou da super cortada).
static func da_cortada(qualidade: int, super_cortada: bool) -> float:
	if super_cortada:
		return valor("super_cortada", SUPER_CORTADA)
	if qualidade == Qualidade.PERFEITO:
		return valor("cortada_perfeita", CORTADA_PERFEITA)
	if qualidade == Qualidade.BOM:
		return valor("cortada_boa", CORTADA_BOA)
	return valor("cortada_ruim", CORTADA_RUIM)
