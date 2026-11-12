extends SceneTree
## Testes da sensação de jogo dentro da partida: botão guardado (apertou um
## pouco cedo), anel piscando quando não dá pra tocar, toque no bloqueio,
## atletas andando pra formação depois do ponto e câmera acompanhando a bola.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_sensacao_na_partida.gd
##
## Usa _initialize e espera o 1º quadro porque a partida precisa dos
## autoloads e da árvore pronta.

const Rodizio := preload("res://scripts/regras/rodizio.gd")
const CameraDaPartida := preload("res://scripts/partida/camera_da_partida.gd")
const PASSO := 1.0 / 60.0

var falhas := 0
var cena: PackedScene


func _initialize() -> void:
	cena = load("res://cenas/partida.tscn")
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	_teste_botao_cedo_vale_quando_a_bola_chega()
	_teste_botao_sem_bola_faz_o_anel_piscar()
	_teste_pedido_some_no_fim_do_rally()
	_teste_bloqueio_no_alto_devolve()
	_teste_bloqueio_baixo_so_toca()
	_teste_bloqueio_na_ponta_da_mao_so_toca()
	_teste_toque_no_bloqueio_nao_conta_toque()
	_teste_atletas_andam_depois_do_ponto()
	_teste_camera_acompanha_a_bola()

	if falhas == 0:
		print("OK: todos os testes da sensação de jogo passaram.")
	else:
		print("FALHOU: %d verificação(ões) da sensação de jogo." % falhas)
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
	root.remove_child(partida)
	partida.free()


func _passar(partida: Node, segundos: float) -> void:
	for i in int(ceil(segundos / PASSO)):
		partida._physics_process(PASSO)
		partida.bola._physics_process(PASSO)


## Rally em andamento, com o time 1 tendo mandado a bola pro lado do time 0.
func _rally(partida: Node) -> void:
	partida.estado = partida.Estado.RALLY
	partida.saque_em_jogo = false
	partida.toques.reiniciar()
	partida.toques.registrar(1, 0)
	partida.ultimo_toque = 1


## Bola caindo reto em cima do atleta, a "altura" metros e descendo a
## "velocidade" m/s, com o atleta controlado.
func _bola_caindo_em(partida: Node, atleta: Node3D, altura: float, velocidade := 0.0) -> void:
	partida.controlados[0] = atleta
	var ponto: Vector3 = atleta.position + Vector3(0.0, altura, 0.0)
	partida.bola.position = ponto
	partida.bola._comecar_voo(ponto, Vector3(0.0, -velocidade, 0.0))


func _teste_botao_cedo_vale_quando_a_bola_chega() -> void:
	var partida = _nova_partida()
	_rally(partida)
	var atleta: Node3D = partida.atletas[0][partida.rodizios[0].atleta_na(6)]
	# A bola ainda está alta demais pro passe (acima de ALTURA_MAXIMA_PASSE),
	# mas chega ao alcance em menos de TEMPO_DO_PEDIDO.
	_bola_caindo_em(partida, atleta, partida.ALTURA_MAXIMA_PASSE + 0.3, 3.0)
	partida._ao_receber_comando(1, "passe")
	_verificar(partida.toques.time_com_a_bola == 1, "cedo demais: o toque ainda não saiu")
	_verificar(not partida.pedidos[0].is_empty(), "o botão ficou guardado")
	_passar(partida, partida.TEMPO_DO_PEDIDO)
	_verificar(partida.toques.time_com_a_bola == 0 and partida.toques.toques == 1,
		"quando a bola chegou ao alcance, o passe saiu sozinho")
	_verificar(partida.pedidos[0].is_empty(), "o pedido foi atendido e sumiu")
	_fechar(partida)


func _teste_botao_sem_bola_faz_o_anel_piscar() -> void:
	var partida = _nova_partida()
	_rally(partida)
	var atleta: Node3D = partida.atletas[0][partida.rodizios[0].atleta_na(6)]
	partida.controlados[0] = atleta
	# Bola longe, caindo do outro lado da quadra.
	var ponto: Vector3 = atleta.position + Vector3(4.0, 1.0, 0.0)
	partida.bola.position = ponto
	partida.bola._comecar_voo(ponto, Vector3.ZERO)
	partida._ao_receber_comando(1, "passe")
	_verificar(not partida.aneis_do_controlado[0].piscando(), "o anel ainda não pisca: o jogo espera a bola chegar")
	_passar(partida, partida.TEMPO_DO_PEDIDO + 2.0 * PASSO)
	_verificar(partida.pedidos[0].is_empty(), "o pedido venceu")
	_verificar(partida.aneis_do_controlado[0].piscando(), "o anel do atleta piscou pra avisar que não deu")
	_verificar(partida.toques.time_com_a_bola == 1, "e nenhum toque saiu")
	_fechar(partida)


func _teste_pedido_some_no_fim_do_rally() -> void:
	var partida = _nova_partida()
	_rally(partida)
	partida.pedidos[0] = { "tipo": "ataque", "ate": partida._relogio + 10.0 }
	partida._encerrar_rally(1, "fora")
	partida._physics_process(PASSO)
	_verificar(partida.pedidos[0].is_empty(), "o pedido some quando o rally acaba")
	_fechar(partida)


## Deixa os 3 da rede do time 1 pulando a "altura" metros, com "desvio" metros
## pro lado do ponto da bola, e devolve o que o bloqueio faz com ela.
func _bloqueio_com(partida: Node, altura: float, desvio: float) -> int:
	var ponto := Vector3(0.0, 2.9, 0.0)
	for i in 6:
		if Rodizio.e_da_rede(partida.rodizios[1].posicao_de(i)):
			var atleta: Node3D = partida.atletas[1][i]
			var lugar: Vector3 = partida._no_mundo(1, Vector2(0.0, 0.6))
			atleta.position = Vector3(ponto.x + desvio, altura, lugar.z)
			atleta.set_meta("tempo_do_pulo", partida.DURACAO_DO_PULO / 2.0)
	return partida.bloqueios._tipo_do_bloqueio(ponto, signf(partida._no_mundo(1, Vector2(0.0, 1.0)).z))


func _teste_bloqueio_no_alto_devolve() -> void:
	var partida = _nova_partida()
	_verificar(_bloqueio_com(partida, partida.ALTURA_DO_PULO, 0.0) == partida.Bloqueio.DEVOLVE,
		"no alto do pulo e na frente da bola, o bloqueio devolve")
	_verificar(_bloqueio_com(partida, partida.ALTURA_DO_PULO, 3.0) == partida.Bloqueio.NENHUM,
		"longe da bola, ninguém encosta")
	_fechar(partida)


func _teste_bloqueio_baixo_so_toca() -> void:
	var partida = _nova_partida()
	# Bem no começo do pulo: as mãos alcançam a bola, mas sem força pra devolver.
	var resultado: int = _bloqueio_com(partida, partida.ALTURA_DO_PULO * 0.4, 0.0)
	_verificar(resultado == partida.Bloqueio.TOQUE, "pulo baixo só toca na bola (deu %d)" % resultado)
	_fechar(partida)


func _teste_bloqueio_na_ponta_da_mao_so_toca() -> void:
	var partida = _nova_partida()
	var desvio: float = partida.LARGURA_DO_BLOQUEIO + partida.FOLGA_DO_TOQUE_NO_BLOQUEIO * 0.5
	var resultado: int = _bloqueio_com(partida, partida.ALTURA_DO_PULO, desvio)
	_verificar(resultado == partida.Bloqueio.TOQUE, "na ponta da mão só toca na bola (deu %d)" % resultado)
	_fechar(partida)


func _teste_toque_no_bloqueio_nao_conta_toque() -> void:
	var partida = _nova_partida()
	_rally(partida)
	# O time 1 atacou (3 toques) e o time 0 raspou no bloqueio.
	partida.toques.registrar(1, 1)
	partida.toques.registrar(1, 2)
	partida.bloqueios._ao_bola_tocar_bloqueio()
	_verificar(partida.estado == partida.Estado.RALLY, "o rally continua")
	_verificar(partida.toques.time_com_a_bola == 0 and partida.toques.toques == 0,
		"quem tocou no bloqueio ainda tem os 3 toques")
	_verificar(partida.ultimo_toque == 0, "a bola saiu de quem bloqueou (se sair, a falta é dele)")
	_verificar(partida._ponto_de_bloqueio == -1, "toque no bloqueio não vira faixa de BLOQUEIO!")
	_fechar(partida)


func _teste_atletas_andam_depois_do_ponto() -> void:
	var partida = _nova_partida()
	_rally(partida)
	var atleta: Node3D = partida.atletas[1][partida.rodizios[1].atleta_na(6)]
	var longe: Vector3 = partida._no_mundo(1, Vector2(-3.5, 8.5))
	atleta.position = longe
	partida._encerrar_rally(0, "dentro")
	_verificar(partida.estado == partida.Estado.PONTO, "o ponto está sendo mostrado")
	var alvo: Vector3 = partida.ia._alvo_depois_do_ponto(1, partida.atletas[1].find(atleta))
	var antes := atleta.position.distance_to(alvo)
	# Primeiro todo mundo fica parado comemorando (ou reagindo)...
	_passar(partida, partida.COMEMORACAO_ANTES_DE_VOLTAR - 0.2)
	var comemorando := atleta.position.distance_to(alvo)
	_verificar(is_equal_approx(comemorando, antes), "logo depois do ponto o atleta fica parado (%.1f -> %.1f m)" % [antes, comemorando])
	# ...e depois anda pro lugar do próximo saque, ainda na pausa do ponto.
	_passar(partida, 0.7)
	var depois := atleta.position.distance_to(alvo)
	_verificar(partida.estado == partida.Estado.PONTO, "ainda é a pausa do ponto")
	_verificar(depois < antes - 1.0, "o atleta anda pra formação durante a pausa do ponto (%.1f -> %.1f m)" % [antes, depois])
	# Quem vai sacar anda pra trás da linha de fundo.
	var sacador: Node3D = partida.atletas[0][partida.rodizios[0].atleta_na(1)]
	var lugar_do_sacador: Vector3 = partida._no_mundo(0, partida.POSICAO_DO_SACADOR)
	_verificar(partida.ia._alvo_depois_do_ponto(0, partida.atletas[0].find(sacador)).is_equal_approx(lugar_do_sacador),
		"quem saca vai pro lugar do saque")
	_fechar(partida)


func _teste_camera_acompanha_a_bola() -> void:
	var camera := CameraDaPartida.new()
	root.add_child(camera)
	var bola := Node3D.new()
	root.add_child(bola)
	camera.preparar(Vector3(0.0, 14.5, 29.5), Vector3(0.0, 0.0, 1.5), 27.0)
	camera.alvo = bola
	bola.position = Vector3(4.0, 2.0, -6.0)
	var desejado: Vector3 = camera.ponto_desejado()
	_verificar(desejado.x > 0.5 and desejado.x < 4.0, "a câmera vira um pouco pro lado da bola, sem ir até ela (%.2f)" % desejado.x)
	_verificar(desejado.z < 1.5, "e um pouco pra frente quando a bola vai pro outro lado")
	var antes := camera.ponto_olhado()
	for i in 30:
		camera._process(PASSO)
	var depois := camera.ponto_olhado()
	_verificar(depois.distance_to(desejado) < antes.distance_to(desejado), "a virada é suave, chegando aos poucos")
	_verificar(camera.global_position.is_equal_approx(Vector3(0.0, 14.5, 29.5)), "a câmera não sai do lugar")
	root.remove_child(camera)
	camera.free()
	root.remove_child(bola)
	bola.free()
