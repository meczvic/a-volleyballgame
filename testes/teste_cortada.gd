extends SceneTree
## Testes da cortada na partida: o atleta sai do chão no botão e bate na bola
## no alto do pulo (TEMPO_ATE_A_BATIDA depois), quando valem as regras.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_cortada.gd

const PASSO := 1.0 / 60.0

var falhas := 0
var cena: PackedScene


func _initialize() -> void:
	cena = load("res://cenas/partida.tscn")
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	_teste_bate_no_alto_do_pulo()
	_teste_bola_longe_nao_pula()
	_teste_ataque_do_fundo_vale_de_onde_saiu()
	_teste_rally_acaba_antes_da_batida()

	if falhas == 0:
		print("OK: todos os testes da cortada passaram.")
	else:
		print("FALHOU: %d verificação(ões) da cortada." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


## Partida em rally, com a bola parada no ar acima do "lugar" (coordenadas do
## time 0) e o atleta da "posicao" do rodízio no "de" (também do time 0).
func _montar(posicao: int, de: Vector2, lugar_da_bola: Vector2, altura: float) -> Node:
	var partida = cena.instantiate()
	root.add_child(partida)
	partida.placar.quem_saca = 0
	partida._preparar_saque()
	partida.estado = partida.Estado.RALLY
	partida.saque_em_jogo = false
	partida.toques.reiniciar()
	var atleta: Node3D = partida.atletas[0][partida.rodizios[0].atleta_na(posicao)]
	atleta.position = partida._no_mundo(0, de)
	partida.controlados[0] = atleta
	var ponto: Vector3 = partida._no_mundo(0, lugar_da_bola)
	ponto.y = altura
	partida.bola.position = ponto
	partida.bola._comecar_voo(ponto, Vector3.ZERO)
	return partida


func _passar(partida: Node, segundos: float) -> void:
	var passos := int(ceil(segundos / PASSO))
	for i in passos:
		partida._physics_process(PASSO)
		partida.bola._physics_process(PASSO)


func _fechar(partida: Node) -> void:
	root.remove_child(partida)
	partida.free()


func _teste_bate_no_alto_do_pulo() -> void:
	var partida := _montar(4, Vector2(-3.0, 1.5), Vector2(-2.6, 1.3), 3.3)
	var atleta: Node3D = partida.controlados[0]
	var lancamentos: int = partida.bola.lancamentos
	partida.lances._comecar_cortada(0)
	_verificar(partida.bloqueios._esta_pulando(atleta), "apertou Ataque com a bola ao alcance: sai do chão")
	_verificar(partida.toques.toques == 0, "a bola ainda não foi tocada no botão")
	_passar(partida, partida.TEMPO_ATE_A_BATIDA * 0.5)
	_verificar(partida.bola.lancamentos == lancamentos, "na metade da subida ainda não bateu")
	_passar(partida, partida.TEMPO_ATE_A_BATIDA * 0.5 + PASSO)
	_verificar(partida.bola.lancamentos == lancamentos + 1, "bateu no alto do pulo")
	_verificar(partida.toques.time_com_a_bola == 0 and partida.toques.toques == 1, "contou o toque na batida")
	_verificar(partida.bola.ponto_previsto.z < 0.0, "a cortada vai pro outro lado")
	_verificar(partida.estado == partida.Estado.RALLY, "a cortada vale")
	_fechar(partida)


func _teste_bola_longe_nao_pula() -> void:
	var partida := _montar(4, Vector2(-3.0, 1.5), Vector2(3.0, 1.5), 3.3)
	var atleta: Node3D = partida.controlados[0]
	partida.lances._comecar_cortada(0)
	_verificar(not partida.bloqueios._esta_pulando(atleta), "bola longe: não pula")
	_verificar(partida.cortadas[0].is_empty(), "bola longe: não tem cortada")
	_fechar(partida)


## Do fundo, o atleta sai do chão atrás da linha de 3 m e cai na frente dela
## pra encontrar a bola: vale, porque a regra olha de onde ele saiu.
func _teste_ataque_do_fundo_vale_de_onde_saiu() -> void:
	var partida := _montar(6, Vector2(0.0, 3.4), Vector2(0.0, 2.0), 3.3)
	partida.lances._comecar_cortada(0)
	_passar(partida, partida.TEMPO_ATE_A_BATIDA + PASSO)
	_verificar(partida.estado == partida.Estado.RALLY, "saiu de trás da linha: o ataque do fundo vale")
	_verificar(partida.toques.toques == 1, "contou o toque")
	_fechar(partida)


func _teste_rally_acaba_antes_da_batida() -> void:
	var partida := _montar(4, Vector2(-3.0, 1.5), Vector2(-2.6, 1.3), 3.3)
	partida.lances._comecar_cortada(0)
	partida._encerrar_rally(1, "teste")
	var lancamentos: int = partida.bola.lancamentos
	_passar(partida, partida.TEMPO_ATE_A_BATIDA + PASSO)
	_verificar(partida.bola.lancamentos == lancamentos, "rally acabou no ar: não bate")
	_verificar(partida.cortadas[0].is_empty(), "a cortada foi cancelada")
	_fechar(partida)
