extends Node
## Entrada do jogador que está do outro lado da rede (online, no dono).
##
## Mesmos sinais e a mesma "direcao" da EntradaLocal: a partida não sabe que
## o jogador está em outro computador. Os botões e a direção chegam pelo
## autoload "Rede" (scripts/rede/rede.gd).

signal comando(jogador: int, tipo: String)
signal soltou(jogador: int, tipo: String)

@export var jogador := 2

var direcao := Vector2.ZERO
var _rede: Node


func _ready() -> void:
	_rede = get_node_or_null("/root/Rede")
	if _rede:
		_rede.botao_do_convidado.connect(_ao_receber_botao)


func _physics_process(_delta: float) -> void:
	if _rede:
		direcao = _rede.direcao_do_convidado


func _ao_receber_botao(tipo: String, apertou: bool) -> void:
	if apertou:
		comando.emit(jogador, tipo)
	else:
		soltou.emit(jogador, tipo)
