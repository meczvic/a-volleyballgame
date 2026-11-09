extends RefCounted
## Conta os toques de cada lado da rede.
##
## Cada time pode tocar até 3 vezes antes de mandar a bola pro outro lado.
## O saque conta como o primeiro toque de quem saca; quando o outro time
## toca, a contagem recomeça pra ele.
##
## O bloqueio não conta como toque, e quem bloqueou pode dar o toque seguinte.
## Fora isso, o mesmo atleta não pode tocar duas vezes seguidas (toque duplo).

const MAXIMO_DE_TOQUES := 3

## Time que tocou por último (-1 = ninguém ainda).
var time_com_a_bola := -1
## Quantos toques seguidos esse time já deu.
var toques := 0
## Atleta (índice no time) que deu o último toque. -1 = ninguém ou bloqueio.
var ultimo_atleta := -1


## Registra um toque do "time" (e de qual "atleta", se souber).
## Devolve false se for falta de 4 toques.
func registrar(time: int, atleta: int = -1) -> bool:
	if time != time_com_a_bola:
		time_com_a_bola = time
		toques = 1
		ultimo_atleta = atleta
		return true
	toques += 1
	ultimo_atleta = atleta
	return toques <= MAXIMO_DE_TOQUES


## O mesmo atleta tocaria de novo, logo depois do próprio toque?
func seria_toque_duplo(time: int, atleta: int) -> bool:
	return atleta >= 0 and time == time_com_a_bola and atleta == ultimo_atleta


## Bloqueio do "time": não conta como toque, então o time ainda tem os 3.
func registrar_bloqueio(time: int) -> void:
	time_com_a_bola = time
	toques = 0
	ultimo_atleta = -1


func reiniciar() -> void:
	time_com_a_bola = -1
	toques = 0
	ultimo_atleta = -1
