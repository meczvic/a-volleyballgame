extends SceneTree
## Testes do rodízio.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_rodizio.gd

const Rodizio := preload("res://scripts/regras/rodizio.gd")

var falhas := 0


func _init() -> void:
	_teste_comeco()
	_teste_girar_uma_vez()
	_teste_seis_giros_voltam_ao_comeco()
	_teste_quem_e_da_rede()
	_teste_comecar_com_escalacao()
	_teste_reiniciar_volta_pra_escalacao()

	if falhas == 0:
		print("OK: todos os testes do rodízio passaram.")
	else:
		print("FALHOU: %d verificação(ões) do rodízio." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _teste_comeco() -> void:
	var rodizio = Rodizio.new()
	_verificar(rodizio.atleta_na(1) == 0, "atleta 0 começa sacando (posição 1)")
	_verificar(rodizio.posicao_de(3) == 4, "atleta 3 começa na posição 4")


func _teste_girar_uma_vez() -> void:
	var rodizio = Rodizio.new()
	rodizio.girar()
	_verificar(rodizio.atleta_na(1) == 1, "quem estava na 2 passa a sacar")
	_verificar(rodizio.posicao_de(0) == 6, "quem sacava vai pra 6")
	_verificar(rodizio.posicao_de(2) == 2, "quem estava na 3 vai pra 2")


func _teste_seis_giros_voltam_ao_comeco() -> void:
	var rodizio = Rodizio.new()
	for _i in 6:
		rodizio.girar()
	_verificar(rodizio.posicoes == [1, 2, 3, 4, 5, 6], "6 giros voltam ao começo")


func _teste_quem_e_da_rede() -> void:
	var da_rede := []
	for posicao in range(1, 7):
		if Rodizio.e_da_rede(posicao):
			da_rede.append(posicao)
	_verificar(da_rede == [2, 3, 4], "rede são as posições 2, 3 e 4")


func _teste_comecar_com_escalacao() -> void:
	var rodizio = Rodizio.new()
	rodizio.comecar_com([3, 0, 5, 1, 4, 2])
	_verificar(rodizio.atleta_na(1) == 3, "ordem[0] começa sacando")
	_verificar(rodizio.atleta_na(4) == 1, "ordem[3] começa na posição 4")
	_verificar(rodizio.posicao_de(2) == 6, "o atleta 2 começa na posição 6")
	rodizio.girar()
	_verificar(rodizio.atleta_na(1) == 0, "girando, quem estava na 2 saca")


func _teste_reiniciar_volta_pra_escalacao() -> void:
	var rodizio = Rodizio.new()
	rodizio.comecar_com([5, 4, 3, 2, 1, 0])
	rodizio.girar()
	rodizio.girar()
	rodizio.reiniciar()
	_verificar(rodizio.atleta_na(1) == 5, "novo set volta pra escalação do começo")
