extends SceneTree
## Testes do cenário (scripts/cenario/): abre a partida em cada estádio e
## confere o que tem que estar lá e o que cada câmera desenha.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_cenario.gd

const Cenario := preload("res://scripts/cenario/cenario.gd")
const Bola := preload("res://scripts/partida/bola.gd")
const Dados := preload("res://scripts/comum/dados.gd")

var falhas := 0


func _initialize() -> void:
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	for estadio in Dados.estadios():
		await _teste_estadio(str(estadio["id"]), str(estadio.get("estilo", "ginasio")))
	await _teste_camera_sem_tela_dividida()
	root.get_node("Configuracao").estadio = "ginasio_japones"

	if falhas == 0:
		print("OK: todos os testes do cenário passaram.")
	else:
		print("FALHOU: %d verificação(ões) do cenário." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _nova_partida(id_do_estadio: String) -> Node:
	var configuracao := root.get_node("Configuracao")
	configuracao.estadio = id_do_estadio
	configuracao.times = ["karasuno", "nekoma"]
	configuracao.modo = "rapida"
	var partida = load("res://cenas/partida.tscn").instantiate()
	root.add_child(partida)
	return partida


func _fechar(partida: Node) -> void:
	partida.temporizador_do_ponto.stop()
	root.remove_child(partida)
	partida.free()


func _teste_estadio(id: String, estilo: String) -> void:
	var partida = _nova_partida(id)
	await process_frame
	var cenario = partida.cenario
	_verificar(cenario != null, "%s: tem cenário" % id)
	if cenario == null:
		_fechar(partida)
		return
	_verificar(cenario.estilo() == estilo, "%s: estilo %s" % [id, estilo])
	_verificar(cenario.get_node_or_null("Rede") != null, "%s: tem rede" % id)
	_verificar(is_equal_approx(cenario.altura_da_rede, Bola.ALTURA_REDE), "%s: rede na mesma altura da física da bola" % id)
	_verificar(cenario.arbitros.size() == 2, "%s: dois árbitros" % id)
	_verificar(cenario.pessoas.size() == 8, "%s: 2 reservas e 1 técnico por time + 2 mesários (%d)" % [id, cenario.pessoas.size()])
	_verificar(cenario.find_children("*", "WorldEnvironment", true, false).size() == 1, "%s: um ambiente de luz" % id)
	_verificar(cenario.find_children("*", "DirectionalLight3D", true, false).size() == 1, "%s: uma luz principal" % id)

	# Camadas: o que está atrás de cada time só aparece pra câmera do outro.
	var camada_0: int = Cenario.CAMADA_ATRAS_DO_TIME[0]
	var camada_1: int = Cenario.CAMADA_ATRAS_DO_TIME[1]
	_verificar(cenario.objetos_na_camada(camada_0) > 0 and cenario.objetos_na_camada(camada_1) > 0, "%s: tem fundo dos dois lados" % id)
	var errados := 0
	for no in cenario.find_children("*", "VisualInstance3D", true, false):
		var visual := no as VisualInstance3D
		var z := (visual.global_transform * visual.get_aabb()).get_center().z
		if visual.get_layer_mask_value(camada_0) and z < 0.0:
			errados += 1
		if visual.get_layer_mask_value(camada_1) and z > 0.0:
			errados += 1
	_verificar(errados == 0, "%s: cada fundo na camada do seu lado (%d errados)" % [id, errados])
	for time in 2:
		var camera: Camera3D = partida.cameras[time]
		var propria: int = Cenario.CAMADA_ATRAS_DO_TIME[time]
		var do_outro: int = Cenario.CAMADA_ATRAS_DO_TIME[1 - time]
		_verificar(not camera.get_cull_mask_value(propria), "%s: câmera do time %d não desenha o fundo atrás dele" % [id, time])
		_verificar(camera.get_cull_mask_value(do_outro), "%s: câmera do time %d desenha o fundo do outro lado" % [id, time])
	_fechar(partida)


func _teste_camera_sem_tela_dividida() -> void:
	var configuracao := root.get_node("Configuracao")
	configuracao.estadio = "ginasio_japones"
	var partida = load("res://cenas/partida.tscn").instantiate()
	partida.tela_dividida = false
	root.add_child(partida)
	await process_frame
	var camera: Camera3D = partida.cameras[0]
	_verificar(partida.cameras.size() == 1, "sem tela dividida: uma câmera")
	_verificar(not camera.get_cull_mask_value(Cenario.CAMADA_ATRAS_DO_TIME[0]), "sem tela dividida: câmera atrás do time 0 esconde o fundo dele")
	_fechar(partida)
