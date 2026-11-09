extends SceneTree
## Testes das regras da tela de seleção de times.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_selecao.gd

const Selecao := preload("res://scripts/menus/selecao.gd")

var falhas := 0


func _init() -> void:
	_teste_cursor_da_a_volta()
	_teste_quem_confirmou_nao_mexe()
	_teste_dois_confirmados_vao_pro_estadio()
	_teste_estadio_da_a_volta_e_comeca()
	_teste_desfazer()
	_teste_posicionar_fora_da_lista()

	if falhas == 0:
		print("OK: todos os testes da seleção de times passaram.")
	else:
		print("FALHOU: %d verificação(ões) da seleção de times." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _teste_cursor_da_a_volta() -> void:
	var selecao = Selecao.new(7, 4)
	selecao.mover(0, -1)
	_verificar(selecao.cursor[0] == 6, "esquerda no primeiro time vai pro último")
	selecao.mover(0, 1)
	_verificar(selecao.cursor[0] == 0, "direita no último time volta pro primeiro")
	_verificar(selecao.cursor[1] == 0, "o cursor do outro jogador não mexe")


func _teste_quem_confirmou_nao_mexe() -> void:
	var selecao = Selecao.new(7, 4)
	_verificar(selecao.confirmar(0), "Jogador 1 confirma")
	_verificar(not selecao.mover(0, 1), "quem confirmou não move o cursor")
	_verificar(selecao.cursor[0] == 0, "o cursor ficou no mesmo time")
	_verificar(not selecao.confirmar(0), "confirmar de novo não muda nada")
	_verificar(selecao.mover(1, 1), "o Jogador 2 ainda escolhe")
	_verificar(selecao.fase == Selecao.Fase.TIMES, "com um só confirmado, continua nos times")


func _teste_dois_confirmados_vao_pro_estadio() -> void:
	var selecao = Selecao.new(7, 4)
	selecao.confirmar(1)
	selecao.confirmar(0)
	_verificar(selecao.fase == Selecao.Fase.ESTADIO, "os dois confirmaram: vai pro estádio")


func _teste_estadio_da_a_volta_e_comeca() -> void:
	var selecao = Selecao.new(7, 4)
	selecao.posicionar(0, 2)
	selecao.posicionar(1, 5)
	selecao.confirmar(0)
	selecao.confirmar(1)
	selecao.mover(1, -1)
	_verificar(selecao.estadio == 3, "esquerda no primeiro estádio vai pro último")
	_verificar(selecao.cursor[0] == 2 and selecao.cursor[1] == 5, "trocar o estádio não mexe nos times")
	_verificar(selecao.confirmar(0), "qualquer jogador confirma o estádio")
	_verificar(selecao.fase == Selecao.Fase.COMECANDO, "confirmou o estádio: começa")
	_verificar(not selecao.mover(0, 1), "começando, nada mais mexe")
	_verificar(not selecao.confirmar(1), "começando, confirmar não faz nada")


func _teste_desfazer() -> void:
	var selecao = Selecao.new(7, 4)
	_verificar(not selecao.desfazer(0), "escolhendo, desfazer avisa pra voltar pro menu")
	selecao.confirmar(0)
	_verificar(selecao.desfazer(0), "desfazer tira a confirmação")
	_verificar(not selecao.confirmado[0], "Jogador 1 não está mais confirmado")

	selecao.confirmar(0)
	selecao.confirmar(1)
	_verificar(selecao.desfazer(1), "no estádio, desfazer volta pros times")
	_verificar(selecao.fase == Selecao.Fase.TIMES, "voltou pra fase dos times")
	_verificar(selecao.confirmado[0] and not selecao.confirmado[1], "só quem desfez perdeu a confirmação")


func _teste_posicionar_fora_da_lista() -> void:
	var selecao = Selecao.new(7, 4)
	selecao.posicionar(0, 99)
	selecao.posicionar(1, -3)
	selecao.posicionar_estadio(10)
	_verificar(selecao.cursor[0] == 6 and selecao.cursor[1] == 0, "posição fora da lista fica no limite")
	_verificar(selecao.estadio == 3, "estádio fora da lista fica no limite")
