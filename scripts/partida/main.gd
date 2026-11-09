extends Node3D
## Cena de teste da fase 2: saque, passe, cortada e pontos de verdade.
##
## Como jogar:
## - Quem saca aperta Ataque (K / 2 numérico / X no controle).
## - A bola vai pro outro lado e um anel amarelo mostra onde ela vai cair.
## - O jogo troca sozinho o atleta controlado pro mais perto do anel.
## - Chegue perto da bola e aperte Passe pra devolver,
##   ou Ataque com a bola alta pra cortar.
## - Bola no chão dentro da quadra: ponto de quem atacou.
##   Bola fora: ponto de quem não tocou por último.
##
## Ainda não tem 3 toques, levantador nem IA: isso vem nas próximas fases.
## Os atletas são cápsulas provisórias.

const Placar := preload("res://scripts/regras/placar.gd")
const EntradaLocal := preload("res://scripts/entrada/entrada_local.gd")
const Bola := preload("res://scripts/partida/bola.gd")
const MarcadorQueda := preload("res://scripts/partida/marcador_queda.gd")

enum Estado { SAQUE, RALLY, PONTO, FIM }

## Medidas oficiais da quadra, em metros.
const COMPRIMENTO := 18.0
const LARGURA := 9.0
const ALTURA_REDE := 2.43

## Velocidade do atleta controlado (m/s).
const VELOCIDADE := 6.0
## Distância (no chão) em que o atleta alcança a bola.
const ALCANCE := 1.8
## Altura máxima da bola pra dar um passe.
const ALTURA_MAXIMA_PASSE := 3.0
## Faixa de altura da bola pra cortar (o atleta pula).
const ALTURA_MINIMA_CORTADA := 1.6
const ALTURA_MAXIMA_CORTADA := 3.5
## Tempo mostrando "Ponto!" antes do próximo saque.
const PAUSA_DEPOIS_DO_PONTO := 1.5

## Ajuste aqui (ou no Inspetor) até achar o ângulo que você gosta.
@export var altura_camera := 17.0
@export var distancia_camera := 15.0

var placar = Placar.new()
var estado := Estado.SAQUE
var ultimo_toque := -1

var times_em_jogo: Array = []
## atletas[0] = time do Jogador 1, atletas[1] = time do Jogador 2.
var atletas: Array = [[], []]
var controlados: Array[Node3D] = [null, null]
var aneis: Array[Node3D] = [null, null]
var entradas: Array = []

var bola
var marcador
var rotulo_placar: Label
var rotulo_mensagem: Label


func _ready() -> void:
	var times := _carregar_times()
	times_em_jogo = [times[0], times[3]]  # Karasuno x Nekoma

	_criar_ambiente()
	_criar_quadra()
	_criar_rede()
	_criar_atletas(0)
	_criar_atletas(1)
	_criar_camera()
	_criar_interface()

	bola = Bola.new()
	bola.name = "Bola"
	add_child(bola)
	bola.tocou_chao.connect(_ao_bola_tocar_chao)

	marcador = MarcadorQueda.new()
	marcador.name = "MarcadorQueda"
	add_child(marcador)
	# Bateu na rede: a bola muda de rumo, então o anel muda de lugar.
	bola.tocou_rede.connect(func() -> void: marcador.mostrar_em(bola.ponto_previsto))

	for jogador in [1, 2]:
		var entrada = EntradaLocal.new()
		entrada.jogador = jogador
		entrada.name = "EntradaJogador%d" % jogador
		entrada.comando.connect(_ao_receber_comando)
		add_child(entrada)
		entradas.append(entrada)

	_conectar_placar()
	_preparar_saque()


func _physics_process(delta: float) -> void:
	for time in 2:
		var atleta := controlados[time]
		var sacando := estado == Estado.SAQUE and time == placar.quem_saca
		if not sacando:
			_mover(atleta, time, entradas[time].direcao, delta)
		aneis[time].position = Vector3(atleta.position.x, 0.03, atleta.position.z)

	# Antes do saque, a bola fica na mão de quem saca.
	if estado == Estado.SAQUE:
		var sacador := controlados[placar.quem_saca]
		var frente := -_lado(placar.quem_saca) * 0.5
		bola.segurar_em(sacador.position + Vector3(0.0, 2.2, frente))


func _mover(atleta: Node3D, time: int, direcao: Vector2, delta: float) -> void:
	atleta.position += Vector3(direcao.x, 0.0, direcao.y) * VELOCIDADE * delta
	# Cada time fica no próprio lado da rede (com um pouco de área livre).
	var limite_x := LARGURA / 2.0 + 2.0
	atleta.position.x = clampf(atleta.position.x, -limite_x, limite_x)
	var fundo := COMPRIMENTO / 2.0 + 2.0
	if time == 0:
		atleta.position.z = clampf(atleta.position.z, 0.4, fundo)
	else:
		atleta.position.z = clampf(atleta.position.z, -fundo, -0.4)


# --- Regras do rally ---

func _ao_receber_comando(jogador: int, tipo: String) -> void:
	var time := jogador - 1
	match estado:
		Estado.FIM:
			if tipo == "passe" or tipo == "ataque":
				_reiniciar_partida()
		Estado.SAQUE:
			if time == placar.quem_saca and (tipo == "ataque" or tipo == "saque_flutuante"):
				_sacar(time, tipo == "saque_flutuante")
		Estado.RALLY:
			if tipo == "passe":
				_tentar_passe(time)
			elif tipo == "ataque":
				_tentar_cortada(time)


func _sacar(time: int, flutuante: bool) -> void:
	var destino := _ponto_aleatorio_no_lado(1 - time, 2.0, 8.0)
	# Provisório: o flutuante só sai mais baixo. O balanço vem depois.
	var altura := 3.4 if flutuante else 4.2
	bola.lancar(destino, altura)
	ultimo_toque = time
	estado = Estado.RALLY
	_ao_lancar_bola()


func _tentar_passe(time: int) -> void:
	if not _alcanca_bola(time, 0.0, ALTURA_MAXIMA_PASSE):
		return
	bola.lancar(_ponto_aleatorio_no_lado(1 - time, 1.5, 8.0), 5.0)
	ultimo_toque = time
	_ao_lancar_bola()


func _tentar_cortada(time: int) -> void:
	if not _alcanca_bola(time, ALTURA_MINIMA_CORTADA, ALTURA_MAXIMA_CORTADA):
		return
	# Cortada: forte, pro fundo, quase sem subir.
	bola.lancar(_ponto_aleatorio_no_lado(1 - time, 4.0, 8.5), bola.position.y + 0.3)
	ultimo_toque = time
	_ao_lancar_bola()


func _alcanca_bola(time: int, altura_minima: float, altura_maxima: float) -> bool:
	if not bola.em_voo:
		return false
	var atleta := controlados[time]
	var no_chao := Vector2(bola.position.x - atleta.position.x, bola.position.z - atleta.position.z)
	var altura: float = bola.position.y
	return no_chao.length() <= ALCANCE and altura >= altura_minima and altura <= altura_maxima


## Mostra o anel e passa o controle pro atleta mais perto de onde a bola vai cair.
func _ao_lancar_bola() -> void:
	var queda: Vector3 = bola.ponto_previsto
	marcador.mostrar_em(queda)
	var time_que_recebe := 0 if queda.z > 0.0 else 1
	_controlar(time_que_recebe, _mais_perto(time_que_recebe, queda))


func _ao_bola_tocar_chao(posicao: Vector3) -> void:
	if estado != Estado.RALLY:
		return
	marcador.esconder()

	var dentro := absf(posicao.x) <= LARGURA / 2.0 + Bola.RAIO \
		and absf(posicao.z) <= COMPRIMENTO / 2.0 + Bola.RAIO
	var vencedor: int
	if dentro:
		# Caiu do lado do time 0 (z positivo): ponto do time 1, e vice-versa.
		vencedor = 1 if posicao.z > 0.0 else 0
	else:
		vencedor = 1 - ultimo_toque

	estado = Estado.PONTO
	rotulo_mensagem.text = "Ponto %s! (%s)" % [
		times_em_jogo[vencedor]["nome"], "dentro" if dentro else "fora"
	]
	placar.marcar_ponto(vencedor)

	if placar.encerrada:
		return
	await get_tree().create_timer(PAUSA_DEPOIS_DO_PONTO).timeout
	if estado == Estado.PONTO:
		_preparar_saque()


func _preparar_saque() -> void:
	estado = Estado.SAQUE
	ultimo_toque = -1
	marcador.esconder()
	_voltar_atletas_pra_base()

	var time: int = placar.quem_saca
	var lado := _lado(time)
	# Quem saca vai pra trás da linha de fundo; o outro time controla o do meio no fundo.
	var sacador: Node3D = atletas[time][5]
	sacador.position = Vector3(2.5 * lado, 0.0, (COMPRIMENTO / 2.0 + 1.0) * lado)
	_controlar(time, sacador)
	_controlar(1 - time, atletas[1 - time][4])

	rotulo_mensagem.text = "%s saca: aperte Ataque" % times_em_jogo[time]["nome"]


func _ao_encerrar_partida(vencedor: int) -> void:
	estado = Estado.FIM
	marcador.esconder()
	rotulo_mensagem.text = "Fim de jogo! %s venceu. Aperte Passe pra jogar de novo." % times_em_jogo[vencedor]["nome"]


func _reiniciar_partida() -> void:
	placar = Placar.new()
	_conectar_placar()
	_preparar_saque()


func _conectar_placar() -> void:
	placar.ponto_marcado.connect(func(_time: int) -> void: _atualizar_placar())
	placar.partida_encerrada.connect(_ao_encerrar_partida)
	_atualizar_placar()


func _atualizar_placar() -> void:
	var a: Dictionary = times_em_jogo[0]
	var b: Dictionary = times_em_jogo[1]
	rotulo_placar.text = "%s  %d  x  %d  %s\nSet %d   (sets %d - %d)" % [
		a["nome"], placar.pontos[0], placar.pontos[1], b["nome"],
		placar.set_atual, placar.sets[0], placar.sets[1],
	]


# --- Ajudantes ---

## 1 pro time do Jogador 1 (lado da câmera, z positivo), -1 pro outro.
func _lado(time: int) -> float:
	return 1.0 if time == 0 else -1.0


## Ponto aleatório dentro da quadra do "time", entre z_min e z_max metros da rede.
func _ponto_aleatorio_no_lado(time: int, z_min: float, z_max: float) -> Vector3:
	var x := randf_range(-LARGURA / 2.0 + 0.8, LARGURA / 2.0 - 0.8)
	var z := randf_range(z_min, z_max) * _lado(time)
	return Vector3(x, 0.0, z)


func _mais_perto(time: int, ponto: Vector3) -> Node3D:
	var melhor: Node3D = null
	var menor := INF
	for atleta in atletas[time]:
		var distancia: float = Vector2(atleta.position.x - ponto.x, atleta.position.z - ponto.z).length()
		if distancia < menor:
			menor = distancia
			melhor = atleta
	return melhor


func _controlar(time: int, atleta: Node3D) -> void:
	controlados[time] = atleta


func _voltar_atletas_pra_base() -> void:
	for time in 2:
		for atleta in atletas[time]:
			atleta.position = atleta.get_meta("base")


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


func _criar_atletas(time: int) -> void:
	var dados_time: Dictionary = times_em_jogo[time]
	var cor_uniforme := Color.html(str(dados_time["cores"][0]))
	var cor_detalhe := Color.html(str(dados_time["cores"][1]))
	var lado := _lado(time)
	# Posições de base: 3 na rede e 3 no fundo.
	var posicoes := [
		Vector2(-3, 2.5), Vector2(0, 2.5), Vector2(3, 2.5),
		Vector2(-3, 6.5), Vector2(0, 6.5), Vector2(3, 6.5),
	]

	for i in posicoes.size():
		var p: Vector2 = posicoes[i]
		var atleta := Node3D.new()
		atleta.name = "%s_%d" % [dados_time["id"], i + 1]
		atleta.position = Vector3(p.x * lado, 0, p.y * lado)
		atleta.set_meta("base", atleta.position)

		var corpo := MeshInstance3D.new()
		var capsula := CapsuleMesh.new()
		capsula.radius = 0.35
		capsula.height = 1.8
		corpo.mesh = capsula
		corpo.material_override = _material(cor_uniforme)
		corpo.position.y = 0.9
		atleta.add_child(corpo)
		add_child(atleta)
		atletas[time].append(atleta)

	# Anel no chão que mostra quem está sendo controlado.
	var anel := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.5
	toro.outer_radius = 0.65
	anel.mesh = toro
	var material := _material(cor_detalhe)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	anel.material_override = material
	anel.scale = Vector3(1.0, 0.1, 1.0)
	add_child(anel)
	aneis[time] = anel
	controlados[time] = atletas[time][4]


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

	rotulo_mensagem = Label.new()
	rotulo_mensagem.position = Vector2(400, 90)
	rotulo_mensagem.size = Vector2(800, 40)
	rotulo_mensagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo_mensagem.add_theme_font_size_override("font_size", 28)
	camada.add_child(rotulo_mensagem)

	var ajuda := Label.new()
	ajuda.text = "Jogador 1: WASD move, J passe, K saque/cortada  |  Jogador 2: setas move, 1 passe, 2 saque/cortada (numérico)  |  Controle: analógico, A passe, X saque/cortada"
	ajuda.position = Vector2(24, 850)
	ajuda.add_theme_font_size_override("font_size", 15)
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
