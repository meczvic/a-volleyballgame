extends RefCounted
## Medidor de energia do time (Etapa 4 do plano de jogabilidade): enche com
## toques bons e jogadas bonitas. Cheio, a próxima cortada que não sair ruim
## vira a SUPER CORTADA: rápida, certeira, difícil de bloquear e de receber.
## Só regras e números (sem tela), pra testar sozinho.

const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")
const Qualidade := TempoDoToque.Qualidade

## Quanto cada toque enche (0 a 1 = barra inteira), pela qualidade do botão.
const GANHO_DO_PASSE := { Qualidade.PERFEITO: 0.10, Qualidade.BOM: 0.04, Qualidade.RUIM: 0.0 }
const GANHO_DO_LEVANTAMENTO := { Qualidade.PERFEITO: 0.08, Qualidade.BOM: 0.03, Qualidade.RUIM: 0.0 }
const GANHO_DA_CORTADA := { Qualidade.PERFEITO: 0.12, Qualidade.BOM: 0.05, Qualidade.RUIM: 0.0 }
## Outras jogadas.
const GANHO_DO_BLOQUEIO_QUE_DEVOLVE := 0.15
const GANHO_DO_TOQUE_NO_BLOQUEIO := 0.05
const GANHO_DO_MERGULHO := 0.08
const GANHO_DO_PONTO := 0.05
## O time que sofre o ponto também aprende: um tiquinho de consolo.
const GANHO_DO_PONTO_PERDIDO := 0.02

## Super cortada: erro da mira (m), quanto a bola sobe acima do contato (m,
## menos é mais forte) e quanto encolhe a largura do bloqueio.
const ERRO_DA_SUPER := 0.2
const SUBIDA_DA_SUPER := 0.05
const BLOQUEIO_DA_SUPER := 0.45

## Quanto tem agora (0 a 1).
var valor := 0.0


func cheia() -> bool:
	return valor >= 1.0 - 0.0001


## Soma "quanto" (limitado a 1). Devolve true se acabou de encher.
func encher(quanto: float) -> bool:
	var estava_cheia := cheia()
	valor = clampf(valor + quanto, 0.0, 1.0)
	return cheia() and not estava_cheia


func zerar() -> void:
	valor = 0.0


## Gasta tudo (a super cortada saiu).
func gastar() -> void:
	valor = 0.0


## Ganho de um toque do "tipo" ("passe", "levantamento" ou "cortada") com essa qualidade.
static func ganho_do_toque(tipo: String, qualidade: Qualidade) -> float:
	match tipo:
		"passe":
			return GANHO_DO_PASSE[qualidade]
		"levantamento":
			return GANHO_DO_LEVANTAMENTO[qualidade]
		"cortada":
			return GANHO_DA_CORTADA[qualidade]
	return 0.0
