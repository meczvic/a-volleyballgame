extends RefCounted
## Conta os toques de cada lado da rede.
##
## Cada time pode tocar até 3 vezes antes de mandar a bola pro outro lado.
## O saque conta como o primeiro toque de quem saca; quando o outro time
## toca, a contagem recomeça pra ele.

const MAXIMO_DE_TOQUES := 3

## Time que tocou por último (-1 = ninguém ainda).
var time_com_a_bola := -1
## Quantos toques seguidos esse time já deu.
var toques := 0


## Registra um toque do "time". Devolve false se for falta (4º toque).
func registrar(time: int) -> bool:
	if time != time_com_a_bola:
		time_com_a_bola = time
		toques = 1
		return true
	toques += 1
	return toques <= MAXIMO_DE_TOQUES


func reiniciar() -> void:
	time_com_a_bola = -1
	toques = 0
