extends Node
## Guarda o que foi escolhido nos menus pra cena da partida usar.
##
## Fica sempre carregado (autoload "Configuracao"). Os valores padrão
## deixam rodar a cena da partida direto (F6), sem passar pelos menus.

## Id do time de cada jogador: [Jogador 1, Jogador 2] (veja dados/times.json).
var times := ["karasuno", "nekoma"]
## Id do estádio (veja dados/estadios.json).
var estadio := "ginasio_japones"
## "rapida" (partida normal) ou "caos" (com cartas, veja scripts/regras/cartas.gd).
var modo := "rapida"
## Semente do sorteio da partida (erro do saque, quem saca primeiro, cartas...).
## -1: cada partida sai diferente. 0 ou mais: com as mesmas teclas nos mesmos
## quadros, a partida se repete igual (o robô e os testes usam isso).
var semente := -1
## Modo 1 jogador: o time do Jogador 2 é jogado pelo computador
## (scripts/entrada/entrada_do_computador.gd) e a tela não se divide.
var contra_computador := false
## Dificuldade do computador: id de dados/dificuldades.json ("facil", "normal", "dificil").
var dificuldade := "normal"
## Os dois times jogados pelo computador (o robô e os testes usam pra assistir).
var computador_nos_dois := false
## Arquivo com os comandos gravados de uma partida (veja
## scripts/entrada/entrada_gravada.gd). Vazio = jogo normal. O robô usa com repetir=.
var repeticao := ""


func definir_partida(time_jogador_1: String, time_jogador_2: String, id_do_estadio: String) -> void:
	times = [time_jogador_1, time_jogador_2]
	estadio = id_do_estadio
