extends RefCounted
## Regras da tela de seleção de times, sem nada de desenho.
##
## 1. Cada jogador move o próprio cursor e confirma um time.
## 2. Com os dois confirmados, qualquer um troca o estádio e confirma.
## 3. Aí a partida começa.
## Desfazer volta um passo. Se não tem nada pra desfazer, a tela volta pro menu.

enum Fase { TIMES, ESTADIO, COMECANDO }

var quantidade_de_times := 1
var quantidade_de_estadios := 1
## Time embaixo do cursor de cada jogador: [Jogador 1, Jogador 2].
var cursor: Array[int] = [0, 0]
var confirmado: Array[bool] = [false, false]
## Estádio escolhido (posição na lista).
var estadio := 0
var fase := Fase.TIMES


func _init(times := 1, estadios := 1) -> void:
	quantidade_de_times = maxi(times, 1)
	quantidade_de_estadios = maxi(estadios, 1)


## Coloca o cursor do jogador (0 ou 1) num time. Usado ao voltar pra essa tela.
func posicionar(jogador: int, indice: int) -> void:
	cursor[jogador] = clampi(indice, 0, quantidade_de_times - 1)


func posicionar_estadio(indice: int) -> void:
	estadio = clampi(indice, 0, quantidade_de_estadios - 1)


## Anda "passo" casas (-1 ou 1), dando a volta no fim da lista.
## Devolve true se algo mudou.
func mover(jogador: int, passo: int) -> bool:
	match fase:
		Fase.TIMES:
			if confirmado[jogador]:
				return false
			cursor[jogador] = posmod(cursor[jogador] + passo, quantidade_de_times)
			return true
		Fase.ESTADIO:
			estadio = posmod(estadio + passo, quantidade_de_estadios)
			return true
	return false


## Devolve true se algo mudou.
func confirmar(jogador: int) -> bool:
	match fase:
		Fase.TIMES:
			if confirmado[jogador]:
				return false
			confirmado[jogador] = true
			if confirmado[0] and confirmado[1]:
				fase = Fase.ESTADIO
			return true
		Fase.ESTADIO:
			fase = Fase.COMECANDO
			return true
	return false


## Desfaz o último passo do jogador. Devolve false quando não tinha nada
## pra desfazer (ele ainda estava escolhendo): a tela então volta pro menu.
func desfazer(jogador: int) -> bool:
	match fase:
		Fase.ESTADIO:
			fase = Fase.TIMES
			confirmado[jogador] = false
			return true
		Fase.TIMES:
			if confirmado[jogador]:
				confirmado[jogador] = false
				return true
			return false
	# Fase.COMECANDO: a partida já está abrindo, ignora.
	return true
