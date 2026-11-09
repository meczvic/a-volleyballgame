extends RefCounted
## Regras de pontuação da partida.
##
## Sets até 7 pontos, com 2 de diferença e limite em 10.
## Quem ganhar 2 sets vence a partida.
## Não sabe nada de bola, câmera ou controle: só recebe "o time X fez ponto".

signal ponto_marcado(time: int)
signal rodizio(time: int)
signal set_encerrado(vencedor: int)
signal partida_encerrada(vencedor: int)

const PONTOS_PARA_VENCER_SET := 7
const DIFERENCA_MINIMA := 2
const LIMITE_DE_PONTOS := 10
const SETS_PARA_VENCER := 2

## Pontos do set atual: [time 0, time 1].
var pontos: Array[int] = [0, 0]
## Sets ganhos: [time 0, time 1].
var sets: Array[int] = [0, 0]
var set_atual := 1
var quem_saca := 0
var encerrada := false
var vencedor := -1


func marcar_ponto(time: int) -> void:
	if encerrada:
		return
	assert(time == 0 or time == 1, "time deve ser 0 ou 1")

	pontos[time] += 1
	# Quem recebia e fez o ponto ganha o saque e roda as posições.
	if time != quem_saca:
		quem_saca = time
		rodizio.emit(time)
	ponto_marcado.emit(time)

	if _set_acabou(time):
		_encerrar_set(time)


func _set_acabou(time: int) -> bool:
	var outro := 1 - time
	if pontos[time] >= LIMITE_DE_PONTOS:
		return true
	return pontos[time] >= PONTOS_PARA_VENCER_SET \
		and pontos[time] - pontos[outro] >= DIFERENCA_MINIMA


func _encerrar_set(time: int) -> void:
	sets[time] += 1
	set_encerrado.emit(time)

	if sets[time] >= SETS_PARA_VENCER:
		encerrada = true
		vencedor = time
		partida_encerrada.emit(time)
		return

	set_atual += 1
	pontos = [0, 0]
	# Quem perdeu o set começa sacando o próximo.
	quem_saca = 1 - time
