extends Node3D
## Cena inicial de teste: quadra, rede, 12 atletas (cápsulas) e câmera
## alta atrás do time do Jogador 1.
##
## Cada jogador move um atleta (o que tem o anel no chão).
## O botão de ataque marca um ponto pro próprio time, só pra testar o placar.
## Tudo aqui é provisório: vai ser trocado por cenas e modelos de verdade.

const Placar := preload("res://scripts/regras/placar.gd")
const EntradaLocal := preload("res://scripts/entrada/entrada_local.gd")

## Medidas oficiais da quadra, em metros.
const COMPRIMENTO := 18.0
const LARGURA := 9.0
const ALTURA_REDE := 2.43
const VELOCIDADE := 6.0

## Ajuste aqui (ou no Inspetor) até achar o ângulo que você gosta.
@export var altura_camera := 17.0
@export var distancia_camera := 15.0

var placar = Placar.new()
var times: Array = []
var times_em_jogo: Array = []
var controlados: Array[Node3D] = [null, null]
var entradas: Array = []
var rotulo_placar: Label


func _ready() -> void:
	times = _carregar_times()
	times_em_jogo = [times[0], times[3]]  # Karasuno x Nekoma

	_criar_ambiente()
	_criar_quadra()
	_criar_rede()
	_criar_atletas(0)
	_criar_atletas(1)
	_criar_camera()
	_criar_interface()

	for jogador in [1, 2]:
		var entrada = EntradaLocal.new()
		entrada.jogador = jogador
		entrada.name = "EntradaJogador%d" % jogador
		entrada.comando.connect(_ao_receber_comando)
		add_child(entrada)
		entradas.append(entrada)

	placar.ponto_marcado.connect(func(_time: int) -> void: _atualizar_placar())
	placar.partida_encerrada.connect(_ao_encerrar_partida)
	_atualizar_placar()


func _physics_process(delta: float) -> void:
	for i in 2:
		var atleta := controlados[i]
		var direcao: Vector2 = entradas[i].direcao
		atleta.position += Vector3(direcao.x, 0.0, direcao.y) * VELOCIDADE * delta

		# Cada time fica no próprio lado da rede (com um pouco de área livre).
		var limite_x := LARGURA / 2.0 + 2.0
		atleta.position.x = clampf(atleta.position.x, -limite_x, limite_x)
		var fundo := COMPRIMENTO / 2.0 + 2.0
		if i == 0:
			atleta.position.z = clampf(atleta.position.z, 0.4, fundo)
		else:
			atleta.position.z = clampf(atleta.position.z, -fundo, -0.4)


func _ao_receber_comando(jogador: int, tipo: String) -> void:
	print("Jogador %d: %s" % [jogador, tipo])
	if tipo == "ataque":
		placar.marcar_ponto(jogador - 1)  # provisório, só pra testar


func _ao_encerrar_partida(vencedor: int) -> void:
	rotulo_placar.text += "\nFim de jogo! %s venceu." % times_em_jogo[vencedor]["nome"]


func _atualizar_placar() -> void:
	var a: Dictionary = times_em_jogo[0]
	var b: Dictionary = times_em_jogo[1]
	rotulo_placar.text = "%s  %d  x  %d  %s\nSet %d   (sets %d - %d)" % [
		a["nome"], placar.pontos[0], placar.pontos[1], b["nome"],
		placar.set_atual, placar.sets[0], placar.sets[1],
	]


func _carregar_times() -> Array:
	var texto := FileAccess.get_file_as_string("res://dados/times.json")
	var dados = JSON.parse_string(texto)
	return dados["times"]


# --- Construção da cena (provisória) ---

func _criar_ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#1B2A3A")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.95, 0.9)
	env.ambient_light_energy = 0.6
	var mundo := WorldEnvironment.new()
	mundo.environment = env
	add_child(mundo)

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	sol.shadow_enabled = true
	add_child(sol)


func _criar_quadra() -> void:
	# Zona livre (azul) e quadra (madeira).
	_caixa(Vector3(LARGURA + 8.0, 0.1, COMPRIMENTO + 10.0), Vector3(0, -0.05, 0), Color("#2D6A9A"))
	_caixa(Vector3(LARGURA, 0.1, COMPRIMENTO), Vector3(0, -0.04, 0), Color("#E39A55"))

	# Linhas: laterais, fundos, centro e linhas de ataque (3 m da rede).
	var branco := Color.WHITE
	var y := 0.015
	for x in [-LARGURA / 2.0, LARGURA / 2.0]:
		_caixa(Vector3(0.05, 0.01, COMPRIMENTO), Vector3(x, y, 0), branco)
	for z in [-COMPRIMENTO / 2.0, -3.0, 0.0, 3.0, COMPRIMENTO / 2.0]:
		_caixa(Vector3(LARGURA, 0.01, 0.05), Vector3(0, y, z), branco)


func _criar_rede() -> void:
	var rede := _caixa(Vector3(LARGURA + 1.0, 1.0, 0.03), Vector3(0, ALTURA_REDE - 0.5, 0), Color(1, 1, 1, 0.45))
	var material := rede.material_override as StandardMaterial3D
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	for x in [-(LARGURA / 2.0 + 0.5), LARGURA / 2.0 + 0.5]:
		var poste := MeshInstance3D.new()
		var cilindro := CylinderMesh.new()
		cilindro.top_radius = 0.05
		cilindro.bottom_radius = 0.05
		cilindro.height = ALTURA_REDE + 0.1
		poste.mesh = cilindro
		poste.material_override = _material(Color("#D8D8D8"))
		poste.position = Vector3(x, cilindro.height / 2.0, 0)
		add_child(poste)


func _criar_atletas(indice_time: int) -> void:
	var time: Dictionary = times_em_jogo[indice_time]
	var cor_uniforme := Color.html(str(time["cores"][0]))
	var cor_detalhe := Color.html(str(time["cores"][1]))
	# Time 0 fica do lado da câmera (z positivo), time 1 do outro lado.
	var lado := 1.0 if indice_time == 0 else -1.0
	var posicoes := [
		Vector2(-3, 2.5), Vector2(0, 2.5), Vector2(3, 2.5),
		Vector2(-3, 6.5), Vector2(0, 6.5), Vector2(3, 6.5),
	]

	for i in posicoes.size():
		var p: Vector2 = posicoes[i]
		var atleta := Node3D.new()
		atleta.name = "%s_%d" % [time["id"], i + 1]
		atleta.position = Vector3(p.x * lado, 0, p.y * lado)

		var corpo := MeshInstance3D.new()
		var capsula := CapsuleMesh.new()
		capsula.radius = 0.35
		capsula.height = 1.8
		corpo.mesh = capsula
		corpo.material_override = _material(cor_uniforme)
		corpo.position.y = 0.9
		atleta.add_child(corpo)
		add_child(atleta)

		if i == 4:  # o do meio, no fundo, começa controlado
			controlados[indice_time] = atleta
			_adicionar_anel(atleta, cor_detalhe)


func _adicionar_anel(atleta: Node3D, cor: Color) -> void:
	var anel := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.5
	toro.outer_radius = 0.65
	anel.mesh = toro
	var material := _material(cor)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	anel.material_override = material
	anel.scale = Vector3(1.0, 0.1, 1.0)
	anel.position.y = 0.03
	atleta.add_child(anel)


func _criar_camera() -> void:
	var camera := Camera3D.new()
	camera.fov = 50.0
	add_child(camera)
	camera.look_at_from_position(
		Vector3(0, altura_camera, distancia_camera),
		Vector3(0, 0, -1.0)
	)
	camera.make_current()


func _criar_interface() -> void:
	var camada := CanvasLayer.new()
	add_child(camada)

	rotulo_placar = Label.new()
	rotulo_placar.position = Vector2(24, 20)
	rotulo_placar.add_theme_font_size_override("font_size", 26)
	camada.add_child(rotulo_placar)

	var ajuda := Label.new()
	ajuda.text = "Jogador 1: WASD move, K marca ponto  |  Jogador 2: setas move, 2 (numérico) marca ponto  |  Controles também funcionam"
	ajuda.position = Vector2(24, 850)
	ajuda.add_theme_font_size_override("font_size", 16)
	camada.add_child(ajuda)


func _caixa(tamanho: Vector3, posicao: Vector3, cor: Color) -> MeshInstance3D:
	var caixa := MeshInstance3D.new()
	var malha := BoxMesh.new()
	malha.size = tamanho
	caixa.mesh = malha
	caixa.material_override = _material(cor)
	caixa.position = posicao
	add_child(caixa)
	return caixa


func _material(cor: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = cor
	return material
