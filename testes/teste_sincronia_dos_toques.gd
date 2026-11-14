extends SceneTree
## A manchete e o levantamento têm que estar na pose de contato na hora em
## que a bola sai (antes de 12/11/2026 a pose chegava 0,3 a 0,4 s depois).
## Confere:
## - o trecho do toque (Animador.TRECHOS) começa na pose de contato: mãos
##   juntas na manchete, mãos no alto no levantamento;
## - o preparo (preparar_toque) chega nessa pose no tempo pedido.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_sincronia_dos_toques.gd

const Dados := preload("res://scripts/comum/dados.gd")
const Animador := preload("res://scripts/visual/animador.gd")

var falhas := 0


func _initialize() -> void:
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _mao(esqueleto: Skeleton3D, nome: String) -> Vector3:
	return esqueleto.get_bone_global_pose(esqueleto.find_bone(nome)).origin


## Pose da animação "lance" no segundo "t": [distância entre as mãos, altura média das mãos].
func _pose(player: AnimationPlayer, esqueleto: Skeleton3D, lance: String, t: float) -> Vector2:
	player.play(Animador.BIBLIOTECA + "/" + lance)
	player.seek(t, true)
	player.advance(0.0)
	var e := _mao(esqueleto, "LeftHand")
	var d := _mao(esqueleto, "RightHand")
	return Vector2(e.distance_to(d), (e.y + d.y) / 2.0)


## Pra onde o peito aponta (no chão) na animação "lance" no segundo "t".
func _frente_do_peito(player: AnimationPlayer, esqueleto: Skeleton3D, lance: String, t: float) -> Vector3:
	player.play(Animador.BIBLIOTECA + "/" + lance)
	player.seek(t, true)
	player.advance(0.0)
	var lado := _mao(esqueleto, "LeftUpperArm") - _mao(esqueleto, "RightUpperArm")
	return Vector3(lado.z, 0.0, -lado.x).normalized()


func _rodar() -> void:
	var time: Dictionary = Dados.times()[0]
	var atleta := Node3D.new()
	root.add_child(atleta)
	var personagem := Dados.carregar_personagem(time, Dados.elenco(time["id"])[0])
	atleta.add_child(personagem)
	var animador := Animador.new()
	atleta.add_child(animador)
	_verificar(animador.preparar(personagem, 0.0), "o personagem tem animador")
	var esqueleto: Skeleton3D = animador._esqueleto()
	var player: AnimationPlayer = personagem.get_node("AnimationPlayer")

	# O toque começa na pose de contato.
	var contato_manchete: float = Animador.TRECHOS["manchete"][0]
	var pose := _pose(player, esqueleto, "manchete", contato_manchete)
	var pose_no_comeco := _pose(player, esqueleto, "manchete", 0.2)
	print("  manchete: mãos a %.2f m uma da outra no contato (no começo da animação, %.2f m)" % [pose.x, pose_no_comeco.x])
	# Na manchete do DeepMotion (13/11/2026) os pulsos ficam a ~0,19 m na
	# plataforma (a do Mixamo chegava a 0,10 m).
	_verificar(pose.x < 0.22 and pose.x < pose_no_comeco.x - 0.08, "na manchete o toque começa com as mãos juntas (%.2f m)" % pose.x)
	# Levantamento (toque do DeepMotion): no contato as mãos estão na altura da
	# testa, acima de onde estavam no preparo, e depois sobem empurrando a bola.
	var contato_levantamento: float = Animador.TRECHOS["levantamento"][0]
	var no_contato := _pose(player, esqueleto, "levantamento", contato_levantamento).y
	var no_preparo := _pose(player, esqueleto, "levantamento", float(Animador.PREPARO["levantamento"][0])).y
	var depois := _pose(player, esqueleto, "levantamento", contato_levantamento + 0.5).y
	var cabeca := esqueleto.get_bone_global_pose(esqueleto.find_bone("Head")).origin.y
	print("  levantamento: mãos a %.2f m no preparo, %.2f m no contato (cabeça a %.2f m), %.2f m 0,5 s depois" % [no_preparo, no_contato, cabeca, depois])
	_verificar(no_contato > no_preparo + 0.1, "no levantamento as mãos sobem do preparo até o contato")
	_verificar(absf(no_contato - cabeca) < 0.15, "no contato do levantamento as mãos estão na altura da testa")
	# Este vídeo estica pouco os braços depois do contato (de 1,58 a 1,68 m):
	# um levantamento novo do DeepMotion está na lista (AUDITORIA_JOGABILIDADE_2).
	_verificar(depois > no_contato + 0.08, "depois do contato as mãos sobem empurrando a bola")

	# Animação do DeepMotion vira de costas se o vídeo foi filmado de frente e
	# o conversor gira meia volta (aconteceu com o levantamento em 12/11/2026).
	# O peito tem que apontar pro mesmo lado que no "parado".
	var frente_parado := _frente_do_peito(player, esqueleto, "parado", 0.5)
	# Nos saques, vale a hora da batida (o saque em pé foi filmado de lado e
	# precisou da meia volta; o viagem, não).
	var batidas := {"saque": 5.3, "saque_viagem": 4.9}
	for lance in ["manchete", "levantamento", "saque", "saque_viagem"]:
		var t: float = batidas.get(lance, float(Animador.TRECHOS[lance][0]))
		var frente := _frente_do_peito(player, esqueleto, lance, t)
		_verificar(frente.dot(frente_parado) > 0.5, "%s: o atleta olha pro mesmo lado que parado (não de costas, %.2f)" % [lance, frente.dot(frente_parado)])

	# Saque viagem: a batida (mão esquerda no alto) cai na batida da partida
	# (corrida + metade do pulo depois de soltar), e o trecho dura corrida + pulo.
	var Partida = load("res://scripts/partida/partida.gd")
	var viagem: Array = Animador.TRECHOS["saque_viagem"]
	var batida_no_jogo: float = (batidas["saque_viagem"] - viagem[0]) / viagem[2]
	var duracao_no_jogo: float = (viagem[1] - viagem[0]) / viagem[2]
	var batida_da_partida: float = Partida.CORRIDA_DO_SAQUE_VIAGEM + Partida.PULO_DO_SAQUE_VIAGEM / 2.0
	print("  saque viagem: batida %.2f s depois de soltar (partida %.2f s), animação de %.2f s" % [batida_no_jogo, batida_da_partida, duracao_no_jogo])
	_verificar(absf(batida_no_jogo - batida_da_partida) < 0.04, "saque viagem: a batida da animação cai na batida da partida")
	_verificar(absf(duracao_no_jogo - (Partida.CORRIDA_DO_SAQUE_VIAGEM + Partida.PULO_DO_SAQUE_VIAGEM)) < 0.08, "saque viagem: a animação dura a corrida e o pulo")
	_verificar(duracao_no_jogo > 1.2, "saque viagem: o movimento todo aparece (mais de 1,2 s)")
	var em_pe: Array = Animador.TRECHOS["saque"]
	var batida_em_pe: float = (batidas["saque"] - em_pe[0]) / em_pe[2]
	_verificar(absf(batida_em_pe - Partida.BATIDA_DO_FLUTUANTE) < 0.04, "saque em pé: a batida da animação (%.2f s) cai na da partida" % batida_em_pe)
	player.play(Animador.BIBLIOTECA + "/saque_viagem")
	player.seek(batidas["saque_viagem"], true)
	player.advance(0.0)
	var mao_na_batida := _mao(esqueleto, "LeftHand").y
	var cabeca_na_batida := _mao(esqueleto, "Head").y
	print("  saque viagem: mão a %.2f m na batida (cabeça a %.2f m)" % [mao_na_batida, cabeca_na_batida])
	_verificar(mao_na_batida > cabeca_na_batida + 0.25, "saque viagem: a mão bate acima da cabeça")

	# O preparo termina onde o toque começa e chega lá no tempo pedido.
	for lance in ["manchete", "levantamento"]:
		_verificar(is_equal_approx(Animador.PREPARO[lance][1], Animador.TRECHOS[lance][0]), "%s: o preparo termina onde o toque começa" % lance)
		animador.soltar()
		var segundos := 0.3
		_verificar(animador.preparar_toque(lance, segundos), "%s: o preparo começa" % lance)
		await create_timer(segundos).timeout
		var onde := player.current_animation_position
		print("  %s: depois de %.2f s o preparo está em %.2f s da animação (contato em %.2f s)" % [lance, segundos, onde, Animador.TRECHOS[lance][0]])
		_verificar(absf(onde - float(Animador.TRECHOS[lance][0])) < 0.08, "%s: o preparo chega na pose de contato junto com a bola" % lance)
		animador.tocar(lance)
		_verificar(absf(player.current_animation_position - float(Animador.TRECHOS[lance][0])) < 0.02, "%s: o toque continua da pose de contato" % lance)
		await create_timer(0.6).timeout

	if falhas == 0:
		print("OK: a manchete e o levantamento estão no tempo da bola.")
	else:
		print("FALHOU: %d verificação(ões) da sincronia dos toques." % falhas)
	quit(1 if falhas > 0 else 0)
