extends SceneTree
## Testes das regras de pontuação.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_placar.gd

const Placar := preload("res://scripts/regras/placar.gd")

var falhas := 0


func _init() -> void:
	_teste_set_de_7_a_0()
	_teste_precisa_de_2_de_diferenca()
	_teste_limite_em_10()
	_teste_partida_acaba_com_2_sets()
	_teste_rodizio_so_quando_recebe_e_pontua()
	_teste_ordem_de_saque_por_set()

	if falhas == 0:
		print("OK: todos os testes do placar passaram.")
	else:
		print("FALHOU: %d verificação(ões) do placar." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _pontos(placar, time: int, quantidade: int) -> void:
	for _i in quantidade:
		placar.marcar_ponto(time)


func _teste_set_de_7_a_0() -> void:
	var placar = Placar.new()
	_pontos(placar, 0, 7)
	_verificar(placar.sets == [1, 0], "7x0 deve dar o set ao time 0")
	_verificar(placar.pontos == [0, 0], "pontos zeram depois do set")
	_verificar(placar.set_atual == 2, "deve estar no set 2")


func _teste_precisa_de_2_de_diferenca() -> void:
	var placar = Placar.new()
	_pontos(placar, 1, 6)
	_pontos(placar, 0, 6)
	placar.marcar_ponto(0)
	_verificar(placar.sets == [0, 0], "7x6 ainda não fecha o set")
	placar.marcar_ponto(0)
	_verificar(placar.sets == [1, 0], "8x6 fecha o set")


func _teste_limite_em_10() -> void:
	var placar = Placar.new()
	for _i in 9:
		placar.marcar_ponto(0)
		placar.marcar_ponto(1)
	_verificar(placar.pontos == [9, 9], "deve estar 9x9")
	placar.marcar_ponto(1)
	_verificar(placar.sets == [0, 1], "10x9 fecha o set pelo limite")


func _teste_partida_acaba_com_2_sets() -> void:
	var placar = Placar.new()
	_pontos(placar, 1, 7)
	_pontos(placar, 1, 7)
	_verificar(placar.encerrada, "2 sets seguidos encerram a partida")
	_verificar(placar.vencedor == 1, "time 1 é o vencedor")
	# No fim, o placar guarda os pontos do último set (0 x 7) pra mostrar na tela.
	_verificar(placar.pontos == [0, 7], "o fim guarda os pontos do último set")
	placar.marcar_ponto(0)
	_verificar(placar.pontos == [0, 7], "ponto depois do fim é ignorado")
	_verificar(placar.sets == [0, 2], "set depois do fim não muda")


func _teste_rodizio_so_quando_recebe_e_pontua() -> void:
	var placar = Placar.new()
	var rodizios: Array[int] = []
	placar.rodizio.connect(func(time: int) -> void: rodizios.append(time))
	placar.marcar_ponto(0)  # time 0 já sacava: sem rodízio
	placar.marcar_ponto(1)  # time 1 recebia e pontuou: roda
	placar.marcar_ponto(1)  # time 1 agora saca: sem rodízio
	_verificar(rodizios == [1], "só um rodízio, do time 1")
	_verificar(placar.quem_saca == 1, "time 1 passa a sacar")


func _teste_ordem_de_saque_por_set() -> void:
	var placar = Placar.new()
	var resultados := [1, 0]
	placar.sorteio = func() -> int: return resultados.pop_front()
	placar.sortear_primeiro_saque()
	_verificar(placar.quem_saca == 1, "o sorteio decide quem saca no 1º set")
	_pontos(placar, 1, 7)
	_verificar(placar.quem_saca == 0, "no 2º set saca quem não sacou primeiro no 1º")
	_pontos(placar, 0, 7)
	_verificar(placar.set_atual == 3, "foi pro desempate")
	_verificar(placar.quem_saca == 0, "no desempate vale o novo sorteio")

	# Mesmo que o time 0 perca o 1º set, se ele sacou primeiro, o 2º começa com o 1.
	var outro = Placar.new()
	outro.sorteio = func() -> int: return 0
	outro.sortear_primeiro_saque()
	_pontos(outro, 1, 7)
	_verificar(outro.quem_saca == 1, "2º set: saca o time que recebeu primeiro no 1º")
