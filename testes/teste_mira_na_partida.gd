extends SceneTree
## Testes da mira dentro da partida: saque carregado e cortada mirada.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_mira_na_partida.gd

const Mira := preload("res://scripts/regras/mira.gd")

var falhas := 0
var cena: PackedScene


func _initialize() -> void:
	cena = load("res://cenas/partida.tscn")
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	_teste_saque_sai_quando_solta()
	_teste_saque_vai_pro_alvo()
	_teste_saque_no_talo_vem_baixo()
	_teste_cortada_vai_pra_direcao()

	if falhas == 0:
		print("OK: todos os testes da mira na partida passaram.")
	else:
		print("FALHOU: %d verificação(ões) da mira na partida." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _nova_partida() -> Node:
	var partida = cena.instantiate()
	root.add_child(partida)
	partida.placar.quem_saca = 0
	partida._preparar_saque()
	return partida


func _fechar(partida: Node) -> void:
	Engine.time_scale = 1.0
	root.remove_child(partida)
	partida.free()


func _teste_saque_sai_quando_solta() -> void:
	var partida = _nova_partida()
	partida._ao_receber_comando(1, "ataque")
	_verificar(partida.estado == partida.Estado.SAQUE, "apertar só começa a carregar")
	_verificar(partida.carga_do_saque >= 0.0, "está carregando")
	partida._atualizar_mira(0, 0.3)
	_verificar(partida.miras[0].visible, "a mira aparece enquanto carrega")
	_verificar(not partida.miras[1].visible, "o outro time não tem mira")
	partida._ao_soltar_botao(1, "ataque")
	_verificar(partida.estado == partida.Estado.RALLY, "soltar saca")
	_verificar(not partida.miras[0].visible, "a mira some depois do saque")
	_fechar(partida)


func _teste_saque_vai_pro_alvo() -> void:
	var partida = _nova_partida()
	var alvo := Vector2(-3.0, 7.5)
	partida._sacar(0, false, 0.0, alvo)
	var queda: Vector3 = partida.bola.ponto_previsto
	var no_alvo := Vector2(queda.x, -queda.z)
	_verificar(no_alvo.distance_to(alvo) <= Mira.erro_do_saque(0.0) + 0.05,
		"saque fraco cai perto do alvo (%s, alvo %s)" % [no_alvo, alvo])
	_fechar(partida)


func _teste_saque_no_talo_vem_baixo() -> void:
	var fraco = _nova_partida()
	fraco._sacar(0, false, 0.1, Mira.ALVO_INICIAL)
	var subida_fraca: float = fraco.bola.velocidade_atual().y
	_fechar(fraco)
	var forte = _nova_partida()
	forte._sacar(0, false, 1.0, Mira.ALVO_INICIAL)
	var subida_forte: float = forte.bola.velocidade_atual().y
	_fechar(forte)
	_verificar(subida_forte < subida_fraca, "saque forte sobe menos (%.1f < %.1f)" % [subida_forte, subida_fraca])


func _teste_cortada_vai_pra_direcao() -> void:
	var partida = _nova_partida()
	partida.entradas[0].direcao = Vector2(-1.0, 0.0)
	var esquerda: Vector2 = partida._alvo_da_cortada(0)
	partida.entradas[0].direcao = Vector2(1.0, 0.0)
	var direita: Vector2 = partida._alvo_da_cortada(0)
	partida.entradas[0].direcao = Vector2(0.0, -1.0)
	var funda: Vector2 = partida._alvo_da_cortada(0)
	partida.entradas[0].direcao = Vector2(0.0, 1.0)
	var curta: Vector2 = partida._alvo_da_cortada(0)
	partida.entradas[0].direcao = Vector2.ZERO
	# x do alvo é no mundo; pro Jogador 1 (câmera no z positivo), esquerda da tela é x negativo.
	_verificar(esquerda.x < direita.x, "esquerda e direita da tela")
	_verificar(funda.y > curta.y, "cima na tela é bola funda, baixo é curta")
	_fechar(partida)
