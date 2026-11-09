extends Node
## Lê o teclado ou controle de UM jogador e transforma em comandos.
##
## A lógica do jogo só escuta os sinais "comando" e "soltou" e lê "direcao".
## Ela não sabe de onde o comando veio. No online, basta criar uma
## "entrada pela rede" com o mesmo sinal e a mesma variável.

signal comando(jogador: int, tipo: String)
## Botão solto (o saque carregado sai quando solta).
signal soltou(jogador: int, tipo: String)

const BOTOES := ["passe", "ataque", "saque_flutuante", "bloqueio", "mergulho"]

@export var jogador := 1

## Direção do movimento, de -1 a 1 em cada eixo (y negativo = para cima).
var direcao := Vector2.ZERO


func _physics_process(_delta: float) -> void:
	var prefixo := "p%d_" % jogador
	direcao = Input.get_vector(
		prefixo + "esquerda", prefixo + "direita",
		prefixo + "cima", prefixo + "baixo"
	)
	for botao in BOTOES:
		if Input.is_action_just_pressed(prefixo + botao):
			comando.emit(jogador, botao)
		if Input.is_action_just_released(prefixo + botao):
			soltou.emit(jogador, botao)
