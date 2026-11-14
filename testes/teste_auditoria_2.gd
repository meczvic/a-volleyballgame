extends SceneTree
## Mudanças da auditoria 2 (docs/AUDITORIA_JOGABILIDADE_2.md):
## - saque viagem sempre mais rápido que o flutuante;
## - o flutuante balança no ar (a queda muda e o anel anda junto).
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --path . --script res://testes/teste_auditoria_2.gd

const Trajetoria := preload("res://scripts/regras/trajetoria.gd")
const Mira := preload("res://scripts/regras/mira.gd")
const PASSO := 1.0 / 60.0

var falhas := 0
var cena: PackedScene


func _initialize() -> void:
	cena = load("res://cenas/partida.tscn")
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _rodar() -> void:
	_teste_viagem_mais_rapido_que_flutuante()
	_teste_flutuante_balanca()
	_teste_forca_da_cortada()
	_teste_troca_de_camera()
	await _teste_saque_viagem_atras_da_linha_e_de_frente()
	if falhas == 0:
		print("OK: as mudanças da auditoria 2 funcionam.")
	else:
		print("FALHOU: %d verificação(ões) da auditoria 2." % falhas)
	quit(1 if falhas > 0 else 0)


func _nova_partida() -> Node:
	var partida = cena.instantiate()
	root.add_child(partida)
	partida.placar.quem_saca = 0
	partida._preparar_saque()
	return partida


## Tempo de voo do saque (s), do jeito que a partida lança.
func _voo_do_saque(flutuante: bool, forca: float) -> float:
	var partida = _nova_partida()
	# Mesmo sorteio nos dois saques: o erro da mira manda os dois pro mesmo lugar.
	partida.sorteio.seed = 7
	var sacador: Node3D = partida.controlados[0]
	# Bola onde ela estaria na batida: em pé (flutuante) ou no alto do pulo (viagem).
	var altura: float = partida.ALTURA_DA_BATIDA_DO_FLUTUANTE if flutuante else partida.ALTURA_DA_BATIDA_DO_VIAGEM
	partida.bola.segurar_em(Vector3(sacador.position.x, altura, sacador.position.z))
	partida._sacar(0, flutuante, forca, Mira.ALVO_INICIAL, not flutuante)
	var bola = partida.bola
	var voo := Trajetoria.tempo_ate_altura(bola.position, bola.velocidade_atual(), bola.RAIO, bola.gravidade)
	partida.queue_free()
	return voo


func _teste_viagem_mais_rapido_que_flutuante() -> void:
	for forca in [0.0, 0.5, 1.0]:
		var viagem := _voo_do_saque(false, forca)
		var flutuante := _voo_do_saque(true, forca)
		_verificar(viagem < flutuante * 0.85, "força %.1f: viagem (%.2f s) bem mais rápido que flutuante (%.2f s)" % [forca, viagem, flutuante])


func _teste_flutuante_balanca() -> void:
	var mudou := 0
	for k in 6:
		var partida = _nova_partida()
		partida.sorteio.seed = 100 + k
		var sacador: Node3D = partida.controlados[0]
		partida.bola.segurar_em(Vector3(sacador.position.x, partida.ALTURA_DA_BATIDA_DO_FLUTUANTE, sacador.position.z))
		partida._sacar(0, true, 0.5, Mira.ALVO_INICIAL)
		var primeira: Vector3 = partida.bola.ponto_previsto
		var lancamentos: int = partida.bola.lancamentos
		var marcas := [0]
		partida.bola.balancou.connect(func() -> void: marcas[0] += 1)
		for i in 120:
			if not partida.bola.em_voo:
				break
			partida.bola._physics_process(PASSO)
		_verificar(marcas[0] == 2, "o flutuante balança duas vezes (balançou %d)" % marcas[0])
		_verificar(partida.bola.lancamentos == lancamentos, "balançar não conta como toque novo")
		if partida.bola.position.distance_to(primeira) > 0.2:
			mudou += 1
		_verificar(absf(partida.bola.position.x) <= partida.LARGURA / 2.0, "o balanço não joga pra fora pela lateral")
		partida.queue_free()
	_verificar(mudou >= 4, "o balanço muda onde a bola cai (%d de 6)" % mudou)


func _teste_forca_da_cortada() -> void:
	var Lances = load("res://scripts/partida/lances_da_partida.gd")
	_verificar(Lances.forca_pelo_tempo_segurado(-1.0, 0.3, 0.12) == 1.0, "segurando até a batida = força cheia")
	_verificar(Lances.forca_pelo_tempo_segurado(0.12, 0.3, 0.12) == 0.0, "soltar logo depois da largada = força mínima")
	var meio: float = Lances.forca_pelo_tempo_segurado(0.21, 0.3, 0.12)
	_verificar(meio > 0.4 and meio < 0.6, "soltar no meio = força média (%.2f)" % meio)
	# Na partida: soltar o ataque logo depois de pular vira largada.
	var partida = _nova_partida()
	partida.estado = partida.Estado.RALLY
	var atleta: Node3D = partida.controlados[0]
	partida.cortadas[0] = {"atleta": atleta, "tempo": 0.05, "de": Vector2.ZERO, "soltou_em": -1.0}
	partida.lances._soltar_cortada(0)
	_verificar(atleta.get_meta("largada", false), "soltar o ataque cedo = largada")
	partida.cortadas[0] = {"atleta": atleta, "tempo": 0.25, "de": Vector2.ZERO, "soltou_em": -1.0}
	atleta.remove_meta("largada")
	partida.lances._soltar_cortada(0)
	_verificar(not atleta.get_meta("largada", false), "soltar depois = cortada, não largada")
	_verificar(is_equal_approx(float(partida.cortadas[0]["soltou_em"]), 0.25), "guarda quando soltou")
	partida.queue_free()


func _teste_troca_de_camera() -> void:
	var configuracao = root.get_node("Configuracao")
	var antes: String = configuracao.camera
	var medidas := {}
	for estilo in configuracao.CAMERAS:
		configuracao.camera = estilo
		var partida = cena.instantiate()
		partida.tela_dividida = false
		partida._escolher_camera()
		medidas[estilo] = [partida.distancia_camera, partida.altura_camera, partida.tamanho_da_bola]
		partida.free()
	_verificar(medidas["perto"][1] < medidas["tv"][1] and medidas["tv"][1] < medidas["alta"][1], "perto mais baixa que TV, TV mais baixa que alta (%s)" % medidas)
	_verificar(medidas["perto"][2] < medidas["tv"][2], "bola menor na câmera perto")
	configuracao.camera = antes


func _osso(esqueleto: Skeleton3D, nome: String) -> Vector3:
	return esqueleto.global_transform * esqueleto.get_bone_global_pose(esqueleto.find_bone(nome)).origin


## Para que lado o peito aponta (no chão), pela linha entre os ombros.
func _frente_do_peito(esqueleto: Skeleton3D) -> Vector3:
	var ombros := _osso(esqueleto, "LeftUpperArm") - _osso(esqueleto, "RightUpperArm")
	return Vector3(ombros.z, 0.0, -ombros.x).normalized()


## Saque viagem de verdade, com a animação rodando: até sair do chão nenhum pé
## passa da linha de fundo, e o peito fica virado pra rede (até uns 30°) em
## toda a corrida e no pulo.
func _teste_saque_viagem_atras_da_linha_e_de_frente() -> void:
	var partida = _nova_partida()
	var sacador: Node3D = partida.controlados[0]
	var animador = partida._animador_de(sacador)
	if animador == null or animador._esqueleto() == null:
		print("  (sem personagem, pulei o teste do saque viagem)")
		partida.queue_free()
		return
	var esqueleto: Skeleton3D = animador._esqueleto()
	for k in 20:
		await process_frame
	# Rumo da rede, visto do sacador. (Pela conta dos ombros, a frente do
	# esqueleto sai invertida: parado, ela dá -0,94 com a rede. Por isso o "-".)
	var pra_rede := Vector3(0.0, 0.0, -signf(sacador.position.z))
	partida._ao_receber_comando(1, "ataque")
	await create_timer(0.4).timeout
	partida._ao_soltar_botao(1, "ataque")
	var linha: float = partida.COMPRIMENTO / 2.0
	var pe_mais_perto := INF
	var pior_giro := 1.0
	var corpo_longe := 0.0
	var tempo := 0.0
	while tempo < 1.4:
		await process_frame
		tempo += get_root().get_process_delta_time()
		var giro_agora := -_frente_do_peito(esqueleto).dot(pra_rede)
		pior_giro = minf(pior_giro, giro_agora)
		var quadril := _osso(esqueleto, "Hips")
		corpo_longe = maxf(corpo_longe, Vector2(quadril.x - sacador.position.x, quadril.z - sacador.position.z).length())
		if not partida.bloqueios._esta_pulando(sacador):
			pe_mais_perto = minf(pe_mais_perto, minf(absf(_osso(esqueleto, "LeftFoot").z), absf(_osso(esqueleto, "RightFoot").z)))
		elif sacador.position.y > 0.1:
			break
	_verificar(pe_mais_perto > linha, "saque viagem: a corrida não pisa na linha (pé chegou a %.2f m; linha em %.2f m)" % [pe_mais_perto, linha])
	_verificar(corpo_longe < 0.5, "saque viagem: o corpo fica em cima do atleta, não metros à frente (afastou %.2f m)" % corpo_longe)
	_verificar(pior_giro > 0.85, "saque viagem: o atleta corre e pula de frente pra rede (pior: %.2f)" % pior_giro)
	partida.queue_free()
