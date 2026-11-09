extends Node3D
## A bola: voa em parábola, bate na rede e avisa quando toca o chão.
##
## Usa a conta exata da trajetória (não o motor de física do Godot).
## Assim o ponto de queda previsto é sempre o ponto real, e o jogo
## fica igual nos dois computadores quando for online.

signal tocou_chao(posicao: Vector3)
signal tocou_rede
signal bloqueada
## A bola passou pro outro lado: por cima da rede ou por fora dela.
## "ponto" é onde ela cruzou a linha da rede (veja a regra das antenas na partida).
signal cruzou_a_rede(ponto: Vector3)

const Trajetoria := preload("res://scripts/regras/trajetoria.gd")
const VisualAnime := preload("res://scripts/visual/visual_anime.gd")

## Um pouco maior que a bola real (0,105 m) pra enxergar bem de cima.
const RAIO := 0.18
const ALTURA_REDE := 2.43
## A rede passa 0,5 m pra fora de cada lateral da quadra.
const LARGURA_REDE := 10.0
## Folga mínima por cima da fita da rede nos lançamentos.
const FOLGA_REDE := 0.4

var em_voo := false
## Onde a bola vai tocar o chão (válido enquanto está em voo).
var ponto_previsto := Vector3.ZERO
## Quem cuida do bloqueio: função(ponto_na_rede: Vector3, lado_destino: float) -> bool.
## Devolve true se tem alguém pulando no lugar certo pra bloquear.
var verificar_bloqueio := Callable()
## Visual anime (contorno escuro). Defina antes de colocar a bola na cena.
var usar_visual_anime := true

var _origem := Vector3.ZERO
var _velocidade_inicial := Vector3.ZERO
var _tempo := 0.0
var _sombra: MeshInstance3D


func _ready() -> void:
	var esfera := SphereMesh.new()
	esfera.radius = RAIO
	esfera.height = RAIO * 2.0
	var visual := MeshInstance3D.new()
	visual.mesh = esfera
	var cor := Color("#F7F3E8")
	if usar_visual_anime:
		visual.material_override = VisualAnime.material(cor, 0.015)
	else:
		var material := StandardMaterial3D.new()
		material.albedo_color = cor
		visual.material_override = material
	add_child(visual)

	# Sombra redonda sempre no chão, embaixo da bola.
	var disco := CylinderMesh.new()
	disco.top_radius = RAIO
	disco.bottom_radius = RAIO
	disco.height = 0.01
	_sombra = MeshInstance3D.new()
	_sombra.mesh = disco
	var material_sombra := StandardMaterial3D.new()
	material_sombra.albedo_color = Color(0, 0, 0, 0.45)
	material_sombra.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_sombra.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_sombra.material_override = material_sombra
	_sombra.top_level = true
	add_child(_sombra)


## Lança a bola da posição atual até "destino" (no chão), subindo até
## "altura_maxima". Se precisar, sobe mais pra passar a rede.
func lancar(destino: Vector3, altura_maxima: float) -> void:
	var alvo := Vector3(destino.x, RAIO, destino.z)
	var velocidade := Trajetoria.velocidade_passando_rede(
		position, alvo, altura_maxima, ALTURA_REDE + FOLGA_REDE
	)
	_comecar_voo(position, velocidade)


## Para a bola num ponto (por exemplo, na mão de quem vai sacar).
func segurar_em(ponto: Vector3) -> void:
	em_voo = false
	position = ponto


func velocidade_atual() -> Vector3:
	return _velocidade_inicial + Vector3(0.0, -Trajetoria.GRAVIDADE * _tempo, 0.0)


## Muda o rumo da bola no meio do voo (rede ou bloqueio).
func _desviar(ponto: Vector3, nova_velocidade: Vector3) -> void:
	position = ponto
	_comecar_voo(ponto, nova_velocidade)


func _comecar_voo(de: Vector3, velocidade: Vector3) -> void:
	_origem = de
	_velocidade_inicial = velocidade
	_tempo = 0.0
	em_voo = true
	ponto_previsto = Trajetoria.ponto_de_queda(_origem, _velocidade_inicial, RAIO)


func _physics_process(delta: float) -> void:
	if em_voo:
		_voar(delta)
	_sombra.global_position = Vector3(global_position.x, 0.02, global_position.z)


func _voar(delta: float) -> void:
	var antes := position
	_tempo += delta
	var agora := Trajetoria.posicao_em(_origem, _velocidade_inicial, _tempo)

	# Cruzou a linha da rede neste quadro?
	if antes.z != 0.0 and signf(antes.z) != signf(agora.z):
		var fracao := antes.z / (antes.z - agora.z)
		var cruzamento := antes.lerp(agora, fracao)
		var na_largura_da_rede := absf(cruzamento.x) < LARGURA_REDE / 2.0
		var lado_de_onde_veio := signf(antes.z)

		# Abaixo da fita: bateu na rede.
		if na_largura_da_rede and cruzamento.y < ALTURA_REDE + RAIO:
			var v := velocidade_atual()
			# Volta devagar pro lado de quem bateu e cai perto da rede.
			var rebote := Vector3(v.x * 0.5, minf(v.y, 0.0), -v.z * 0.25)
			_desviar(Vector3(cruzamento.x, cruzamento.y, lado_de_onde_veio * (RAIO + 0.02)), rebote)
			tocou_rede.emit()
			return

		# Acima da fita, mas com alguém bloqueando ali: volta pra quem atacou.
		if na_largura_da_rede and verificar_bloqueio.is_valid() \
				and verificar_bloqueio.call(cruzamento, signf(agora.z)):
			var v := velocidade_atual()
			var rebote := Vector3(v.x * 0.3, -absf(v.y) * 0.3 - 1.5, -v.z * 0.35)
			_desviar(Vector3(cruzamento.x, cruzamento.y, lado_de_onde_veio * (RAIO + 0.3)), rebote)
			bloqueada.emit()
			return

		cruzou_a_rede.emit(cruzamento)

	if agora.y <= RAIO:
		position = ponto_previsto
		em_voo = false
		tocou_chao.emit(position)
		return

	position = agora
