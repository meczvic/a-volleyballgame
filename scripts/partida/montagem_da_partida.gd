extends RefCounted
## Monta a cena da partida: cenário, atletas (personagem, animador, anel e seta), marcas dos ataques e câmeras.
##
## Saiu do partida.gd (Fase C do plano de melhorias). "p" é a partida:
## tudo que é dela aparece como p.algo.

const AnelDoControlado := preload("res://scripts/partida/anel_do_controlado.gd")
const Animador := preload("res://scripts/visual/animador.gd")
const CameraDaPartida := preload("res://scripts/partida/camera_da_partida.gd")
const Cenario := preload("res://scripts/cenario/cenario.gd")
const Dados := preload("res://scripts/comum/dados.gd")
const Escalacao := preload("res://scripts/regras/escalacao.gd")
const EscolhaAtaque := preload("res://scripts/regras/escolha_ataque.gd")
const Formacao := preload("res://scripts/regras/formacao.gd")
const SetaDoControlado := preload("res://scripts/partida/seta_do_controlado.gd")
const VisualAnime := preload("res://scripts/visual/visual_anime.gd")

## A partida (partida.gd).
var p


func _init(partida) -> void:
	p = partida


## Quadra, rede, árbitros e o ginásio ou arena em volta (scripts/cenario/).
func _criar_cenario() -> void:
	p.cenario = Cenario.new()
	p.cenario.name = "Cenario"
	p.add_child(p.cenario)
	p.cenario.montar(p.estadio, p.times_em_jogo, {
		"largura": p.LARGURA, "comprimento": p.COMPRIMENTO, "altura_da_rede": p.ALTURA_REDE,
		"zona_livre": Vector2(p.LARGURA_ZONA_LIVRE, p.COMPRIMENTO_ZONA_LIVRE),
	})


func _criar_atletas(time: int) -> void:
	var dados_time: Dictionary = p.times_em_jogo[time]
	var id_time := str(dados_time["id"])
	var elenco := Dados.elenco(id_time)
	var cor_detalhe := Color.from_string(str(dados_time["cores"][1]), Color.WHITE)
	# Escalação pela função de cada um (levantador oposto ao oposto, etc.).
	var ordem := Escalacao.ordem_inicial(elenco)
	p.rodizios[time].comecar_com(ordem)
	p.funcoes[time] = Escalacao.funcoes_por_atleta(ordem)
	p.levantadores[time] = ordem[0]

	for i in 6:
		var atleta := Node3D.new()
		atleta.name = "Time%d_%s_%d" % [time + 1, id_time, i + 1]
		atleta.position = p._no_mundo(time, Formacao.lugar_no_saque(p.rodizios[time].posicao_de(i), false, false))
		atleta.set_meta("tempo_do_pulo", -1.0)
		var dados_atleta: Dictionary = elenco[i] if i < elenco.size() else {}
		atleta.set_meta("dados", dados_atleta)

		var personagem := Dados.carregar_personagem(dados_time, dados_atleta)
		if personagem:
			atleta.add_child(personagem)
			var animador := Animador.new()
			animador.name = "Animador"
			atleta.add_child(animador)
			if animador.preparar(personagem, p.GIRO_DO_PERSONAGEM if time == 0 else p.GIRO_DO_PERSONAGEM + PI):
				atleta.set_meta("animador", animador)
		else:
			_criar_capsula(atleta, _cores_do_atleta(dados_time, dados_atleta))
		p.add_child(atleta)
		p.atletas[time].append(atleta)

	# Anel no chão que mostra quem está sendo controlado.
	var anel := AnelDoControlado.new()
	anel.name = "AnelDoControlado%d" % time
	anel.cor = cor_detalhe
	p.add_child(anel)
	p.aneis_do_controlado[time] = anel
	# Seta em cima da cabeça, na cor forte do time (a do menu). Com os dois
	# jogadores no mesmo time, o Jogador 2 usa a cor de detalhe do uniforme
	# reserva, pra uma seta não ser igual à outra.
	var seta := SetaDoControlado.new()
	seta.name = "SetaDoControlado%d" % time
	var mesmo_time: bool = time == 1 and str(p.times_em_jogo[0]["id"]) == id_time
	seta.cor = cor_detalhe if mesmo_time \
		else Color.from_string(str(dados_time.get("cor_do_menu", dados_time["cores"][1])), cor_detalhe)
	p.add_child(seta)
	p.setas_do_controlado[time] = seta
	p.controlados[time] = p.atletas[time][p.rodizios[time].atleta_na(6)]


## Cores [camisa, detalhe] do atleta: o uniforme do time (não tem líbero).
func _cores_do_atleta(dados_time: Dictionary, _dados_atleta: Dictionary) -> Array:
	var cores: Array = dados_time["cores"]
	return [
		Color.from_string(str(cores[0]), Color.GRAY),
		Color.from_string(str(cores[1]), Color.WHITE),
	]


## Cápsula de teste (1,8 m) com uma faixa no peito na cor de detalhe.
func _criar_capsula(atleta: Node3D, cores: Array) -> void:
	var corpo := MeshInstance3D.new()
	var capsula := CapsuleMesh.new()
	capsula.radius = 0.35
	capsula.height = 1.8
	corpo.mesh = capsula
	corpo.material_override = _material_do_atleta(cores[0], 0.03)
	corpo.position.y = 0.9
	atleta.add_child(corpo)

	var faixa := MeshInstance3D.new()
	var anel_do_peito := CylinderMesh.new()
	anel_do_peito.top_radius = 0.36
	anel_do_peito.bottom_radius = 0.36
	anel_do_peito.height = 0.12
	faixa.mesh = anel_do_peito
	faixa.material_override = _material_do_atleta(cores[1], 0.0)
	faixa.position.y = 1.15
	atleta.add_child(faixa)


## Cria as marcas no chão (círculo + seta + nome) dos 4 ataques do time.
func _criar_marcas_de_ataque(time: int) -> void:
	var grupo := Node3D.new()
	grupo.name = "MarcasDeAtaque%d" % time
	grupo.visible = false
	p.add_child(grupo)
	p.marcas_de_ataque[time] = grupo

	for ataque in p.ATAQUES:
		p.alvos_de_ataque[time].append(p._no_mundo(time, ataque["posicao"]))
	var centro = EscolhaAtaque.centro_de(p.alvos_de_ataque[time])

	for i in p.ATAQUES.size():
		var alvo: Vector3 = p.alvos_de_ataque[time][i]

		var circulo := MeshInstance3D.new()
		var disco := CylinderMesh.new()
		disco.top_radius = 0.55
		disco.bottom_radius = 0.55
		disco.height = 0.01
		circulo.mesh = disco
		var material := _material(Color(1, 1, 1, 0.35))
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		circulo.material_override = material
		circulo.position = Vector3(alvo.x, 0.025, alvo.z)
		grupo.add_child(circulo)

		var texto := Label3D.new()
		texto.text = "%s %s" % [EscolhaAtaque.seta_de(alvo, centro, p._lado_da_camera(time)), p.ATAQUES[i]["nome"]]
		texto.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		texto.no_depth_test = true
		# Discreto: o nome ajuda, mas não pode tapar a quadra.
		texto.font_size = 30
		texto.outline_size = 8
		texto.modulate = Color(1, 1, 1, 0.85)
		texto.pixel_size = 0.01
		texto.position = Vector3(alvo.x, 0.6, alvo.z)
		grupo.add_child(texto)


func _criar_camera() -> void:
	if not p.tela_dividida:
		_adicionar_camera(p, p.time_da_camera)
		return

	# Duas metades da tela, cada uma com a própria câmera olhando o mesmo mundo.
	# Fica numa camada atrás da interface (placar e mensagens).
	var camada := CanvasLayer.new()
	camada.name = "TelaDividida"
	camada.layer = -1
	p.add_child(camada)
	for time in 2:
		var moldura := SubViewportContainer.new()
		moldura.name = "TelaJogador%d" % (time + 1)
		moldura.stretch = true
		moldura.anchor_left = 0.5 * time
		moldura.anchor_right = 0.5 * (time + 1)
		moldura.anchor_top = 0.0
		moldura.anchor_bottom = 1.0
		camada.add_child(moldura)

		var tela := SubViewport.new()
		tela.world_3d = p.get_viewport().find_world_3d()
		tela.msaa_3d = Viewport.MSAA_2X
		moldura.add_child(tela)
		_adicionar_camera(tela, time)


## Câmera alta atrás do time, olhando pra rede (e acompanhando a bola de leve).
func _adicionar_camera(onde: Node, time: int) -> void:
	var lado = p._lado(time)
	var camera := CameraDaPartida.new()
	camera.name = "Camera%d" % time
	onde.add_child(camera)
	camera.preparar(
		Vector3(0.0, p.altura_camera, p.distancia_camera * lado),
		Vector3(0.0, 0.0, p.foco_da_camera * lado),
		p.abertura_da_camera
	)
	camera.acompanhamento_lateral = p.acompanhamento_da_camera
	camera.current = true
	# O fundo atrás do próprio time fica entre a câmera e a quadra: não desenha.
	camera.set_cull_mask_value(Cenario.CAMADA_ATRAS_DO_TIME[0 if lado > 0.0 else 1], false)
	if p.tela_dividida:
		# Esconde o anel de tempo do outro jogador.
		camera.set_cull_mask_value(p.CAMADA_DO_ANEL_DE_TEMPO[1 - time], false)
	elif p._jogador_e_o_computador(2) and not p._jogador_e_o_computador(1):
		# Contra o computador: o anel de tempo e a mira dele não aparecem.
		camera.set_cull_mask_value(p.CAMADA_DO_ANEL_DE_TEMPO[1], false)
	p.cameras.append(camera)


func _caixa(tamanho: Vector3, posicao: Vector3, cor: Color) -> MeshInstance3D:
	var caixa := MeshInstance3D.new()
	var malha := BoxMesh.new()
	malha.size = tamanho
	caixa.mesh = malha
	caixa.material_override = _material(cor)
	caixa.position = posicao
	p.add_child(caixa)
	return caixa


## Material dos atletas: anime (com contorno) ou comum, conforme "visual_anime".
func _material_do_atleta(cor: Color, contorno: float) -> Material:
	if p.visual_anime:
		return VisualAnime.material(cor, contorno)
	return _material(cor)


func _material(cor: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = cor
	return material
