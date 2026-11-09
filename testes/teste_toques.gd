extends SceneTree
## Testes da contagem de toques.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_toques.gd

const Toques := preload("res://scripts/regras/toques.gd")

var falhas := 0


func _init() -> void:
	_teste_tres_toques_valem()
	_teste_quarto_toque_e_falta()
	_teste_outro_time_recomeca_a_contagem()
	_teste_reiniciar()
	_teste_toque_duplo()
	_teste_bloqueio_nao_conta()

	if falhas == 0:
		print("OK: todos os testes de toques passaram.")
	else:
		print("FALHOU: %d verificação(ões) de toques." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _teste_tres_toques_valem() -> void:
	var toques = Toques.new()
	_verificar(toques.registrar(0), "1º toque vale")
	_verificar(toques.registrar(0), "2º toque vale")
	_verificar(toques.registrar(0), "3º toque vale")
	_verificar(toques.toques == 3, "contou 3 toques")


func _teste_quarto_toque_e_falta() -> void:
	var toques = Toques.new()
	for _i in 3:
		toques.registrar(1)
	_verificar(not toques.registrar(1), "4º toque é falta")


func _teste_outro_time_recomeca_a_contagem() -> void:
	var toques = Toques.new()
	toques.registrar(0)
	toques.registrar(0)
	_verificar(toques.registrar(1), "toque do outro time vale")
	_verificar(toques.toques == 1, "contagem recomeça em 1")
	_verificar(toques.time_com_a_bola == 1, "a bola agora é do time 1")


func _teste_reiniciar() -> void:
	var toques = Toques.new()
	toques.registrar(0)
	toques.reiniciar()
	_verificar(toques.toques == 0 and toques.time_com_a_bola == -1, "reiniciar zera tudo")


func _teste_toque_duplo() -> void:
	var toques = Toques.new()
	toques.registrar(0, 4)
	_verificar(toques.seria_toque_duplo(0, 4), "o mesmo atleta tocar de novo é dois toques")
	_verificar(not toques.seria_toque_duplo(0, 2), "outro atleta do time pode tocar")
	_verificar(not toques.seria_toque_duplo(1, 4), "atleta do outro time não é toque duplo")
	toques.registrar(0, 2)
	_verificar(toques.ultimo_atleta == 2, "guarda quem tocou por último")


func _teste_bloqueio_nao_conta() -> void:
	var toques = Toques.new()
	toques.registrar(1, 0)
	toques.registrar(1, 3)
	toques.registrar(1, 5)
	toques.registrar_bloqueio(0)
	_verificar(toques.time_com_a_bola == 0 and toques.toques == 0, "bloqueio não conta como toque")
	for atleta in [2, 1, 2]:
		_verificar(toques.registrar(0, atleta), "depois do bloqueio ainda tem 3 toques")
	_verificar(not toques.registrar(0, 4), "o 4º toque depois do bloqueio é falta")

	var outro = Toques.new()
	outro.registrar(1, 0)
	outro.registrar_bloqueio(0)
	_verificar(not outro.seria_toque_duplo(0, 3), "quem bloqueou pode tocar logo depois")
