extends Node
## Entrada que repete os comandos gravados de uma partida (Fase E).
##
## A partida anota cada botão e cada mudança de direção com o número do
## quadro (partida.registro). Com a mesma semente, esta entrada aperta tudo de
## novo nos mesmos quadros e a partida se repete igual. Serve pra achar erro
## ("grava a partida que deu problema e repete") e é a base do online.
##
## Cada item da gravação: [quadro, jogador, tipo, valor]. tipo "dir" tem valor
## [x, y]; os botões têm valor true (apertou) ou false (soltou).

signal comando(jogador: int, tipo: String)
signal soltou(jogador: int, tipo: String)

@export var jogador := 1

var direcao := Vector2.ZERO
var partida: Node
var _botoes: Array = []
var _direcoes: Array = []
var _proximo_botao := 0
var _proxima_direcao := 0


## Guarda só os itens deste jogador, em ordem.
func carregar(gravacao: Array) -> void:
	_botoes = []
	_direcoes = []
	for item in gravacao:
		if int(item[1]) != jogador:
			continue
		if str(item[2]) == "dir":
			_direcoes.append(item)
		else:
			_botoes.append(item)
	_proximo_botao = 0
	_proxima_direcao = 0
	# A direção do 1º quadro já tem que estar pronta antes da partida ler.
	_aplicar_direcoes_ate(1)


## Lê a gravação de um arquivo JSON (ver partida.salvar_registro).
static func ler(caminho: String) -> Array:
	var texto := FileAccess.get_file_as_string(caminho)
	var dados = JSON.parse_string(texto) if texto != "" else null
	return dados if dados is Array else []


func _physics_process(_delta: float) -> void:
	if partida == null:
		return
	var quadro: int = partida.quadro
	# Como a EntradaLocal: primeiro a direção (a que a partida lê no próximo
	# quadro), depois os botões deste quadro.
	_aplicar_direcoes_ate(quadro + 1)
	while _proximo_botao < _botoes.size() and int(_botoes[_proximo_botao][0]) <= quadro:
		var item: Array = _botoes[_proximo_botao]
		if bool(item[3]):
			comando.emit(jogador, str(item[2]))
		else:
			soltou.emit(jogador, str(item[2]))
		_proximo_botao += 1


func _aplicar_direcoes_ate(quadro: int) -> void:
	while _proxima_direcao < _direcoes.size() and int(_direcoes[_proxima_direcao][0]) <= quadro:
		var valor: Array = _direcoes[_proxima_direcao][3]
		direcao = Vector2(float(valor[0]), float(valor[1]))
		_proxima_direcao += 1
