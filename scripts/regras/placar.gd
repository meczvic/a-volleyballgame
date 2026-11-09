extends RefCounted
## Regras de pontuação da partida.
##
## Sets até 7 pontos, com 2 de diferença e limite em 10.
## Quem ganhar 2 sets vence a partida.
##
## Quem saca primeiro (regra da FIVB): no 1º set, sorteio. No 2º, o time que
## não sacou primeiro no 1º. No set de desempate (3º), sorteio de novo.
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
## Quem sacou primeiro no set atual (decide quem começa o próximo).
var primeiro_saque_do_set := 0
var encerrada := false
var vencedor := -1
## Sorteio (cara ou coroa): função que devolve 0 ou 1. Vazio = aleatório.
## Os testes trocam por uma função fixa.
var sorteio := Callable()


## Sorteia quem saca primeiro na partida (antes do 1º ponto).
func sortear_primeiro_saque() -> void:
	quem_saca = _sortear()
	primeiro_saque_do_set = quem_saca


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


## Se o "time" fecha o set fazendo o próximo ponto (set point).
func ponto_de_set(time: int) -> bool:
	# No fim do set o placar ainda mostra o resultado: aí não tem aviso.
	if encerrada or _set_acabou(0) or _set_acabou(1):
		return false
	var depois := pontos[time] + 1
	if depois >= LIMITE_DE_PONTOS:
		return true
	return depois >= PONTOS_PARA_VENCER_SET and depois - pontos[1 - time] >= DIFERENCA_MINIMA


## Se o "time" ganha a partida fazendo o próximo ponto (match point).
func ponto_de_partida(time: int) -> bool:
	return ponto_de_set(time) and sets[time] == SETS_PARA_VENCER - 1


## Aviso do placar agora: "MATCH POINT", "SET POINT", "PONTO DECISIVO" (os dois
## fecham com o próximo ponto) ou "" (nada). "quem" recebe o time do aviso
## (-1 quando vale pros dois ou não tem aviso).
func aviso() -> Dictionary:
	var de_set := [ponto_de_set(0), ponto_de_set(1)]
	if de_set[0] and de_set[1]:
		return { "texto": "PONTO DECISIVO", "quem": -1 }
	for time in 2:
		if ponto_de_partida(time):
			return { "texto": "MATCH POINT", "quem": time }
		if de_set[time]:
			return { "texto": "SET POINT", "quem": time }
	return { "texto": "", "quem": -1 }


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
	if set_atual == SETS_PARA_VENCER * 2 - 1:
		# Set de desempate: sorteio de novo.
		quem_saca = _sortear()
	else:
		# Começa sacando quem não sacou primeiro no set anterior.
		quem_saca = 1 - primeiro_saque_do_set
	primeiro_saque_do_set = quem_saca


func _sortear() -> int:
	if sorteio.is_valid():
		return 1 if int(sorteio.call()) == 1 else 0
	return randi() % 2
