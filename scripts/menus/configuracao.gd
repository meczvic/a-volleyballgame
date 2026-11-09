extends Node
## Guarda o que foi escolhido nos menus pra cena da partida usar.
##
## Fica sempre carregado (autoload "Configuracao"). Os valores padrão
## deixam rodar a cena da partida direto (F6), sem passar pelos menus.

## Id do time de cada jogador: [Jogador 1, Jogador 2] (veja dados/times.json).
var times := ["karasuno", "nekoma"]
## Id do estádio (veja dados/estadios.json).
var estadio := "ginasio_japones"
## "rapida" por enquanto. O Modo Caos vem depois.
var modo := "rapida"


func definir_partida(time_jogador_1: String, time_jogador_2: String, id_do_estadio: String) -> void:
	times = [time_jogador_1, time_jogador_2]
	estadio = id_do_estadio
