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
