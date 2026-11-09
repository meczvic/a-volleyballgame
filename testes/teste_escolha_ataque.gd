extends SceneTree
## Testes da escolha do atacante pelo levantador.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_escolha_ataque.gd

const EscolhaAtaque := preload("res://scripts/regras/escolha_ataque.gd")

## Alvos do time do lado da câmera: ponta, meio, oposto, fundo.
const ALVOS := [
	Vector3(-3.5, 0.0, 1.2), Vector3(0.0, 0.0, 1.2),
	Vector3(3.5, 0.0, 1.2), Vector3(0.0, 0.0, 4.0),
]
const MEIO := 1

var falhas := 0


func _init() -> void:
	_teste_direcoes()
	_teste_solto_usa_o_padrao()
	_teste_setas()

	if falhas == 0:
		print("OK: todos os testes da escolha de ataque passaram.")
	else:
		print("FALHOU: %d verificação(ões) da escolha de ataque." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _teste_direcoes() -> void:
	_verificar(EscolhaAtaque.escolher(ALVOS, Vector2.LEFT, MEIO) == 0, "esquerda escolhe a ponta")
	_verificar(EscolhaAtaque.escolher(ALVOS, Vector2.UP, MEIO) == 1, "cima escolhe o meio")
	_verificar(EscolhaAtaque.escolher(ALVOS, Vector2.RIGHT, MEIO) == 2, "direita escolhe o oposto")
	_verificar(EscolhaAtaque.escolher(ALVOS, Vector2.DOWN, MEIO) == 3, "baixo escolhe o fundo")
	_verificar(EscolhaAtaque.escolher(ALVOS, Vector2(-0.8, -0.3), MEIO) == 0, "esquerda meio torta ainda é a ponta")


func _teste_solto_usa_o_padrao() -> void:
	_verificar(EscolhaAtaque.escolher(ALVOS, Vector2.ZERO, MEIO) == MEIO, "sem direção usa o padrão")
	_verificar(EscolhaAtaque.escolher(ALVOS, Vector2(0.1, 0.1), MEIO) == MEIO, "analógico quase solto usa o padrão")


func _teste_setas() -> void:
	var centro := EscolhaAtaque.centro_de(ALVOS)
	var setas := []
	for alvo in ALVOS:
		setas.append(EscolhaAtaque.seta_de(alvo, centro))
	_verificar(setas == ["<", "^", ">", "v"], "setas certas (vieram %s)" % [setas])

	# Time do outro lado, com a própria câmera: tudo espelhado, mesmas setas.
	var alvos_espelhados := []
	for alvo in ALVOS:
		alvos_espelhados.append(Vector3(-alvo.x, 0.0, -alvo.z))
	var centro_espelhado := EscolhaAtaque.centro_de(alvos_espelhados)
	var setas_espelhadas := []
	for alvo in alvos_espelhados:
		setas_espelhadas.append(EscolhaAtaque.seta_de(alvo, centro_espelhado, -1.0))
	_verificar(setas_espelhadas == ["<", "^", ">", "v"], "setas do outro lado (vieram %s)" % [setas_espelhadas])
	# Esquerda na tela do outro lado é x positivo no mundo: escolhe a ponta dele.
	_verificar(EscolhaAtaque.escolher(alvos_espelhados, -Vector2.LEFT, MEIO) == 0, "esquerda do outro lado escolhe a ponta")
