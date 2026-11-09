extends Node3D
## Rastro da bola: bolinhas que ficam pra trás e somem, só quando a bola
## está rápida (cortada, saque forte). Fica no mundo (top_level), seguindo
## o nó "alvo".

const QUANTIDADE := 14
## A cada quantos segundos guarda um ponto do caminho.
const INTERVALO := 0.012
## Abaixo dessa velocidade (m/s) o rastro some.
const VELOCIDADE_MINIMA := 11.0
const COR := Color("#FFF4D6")

## Nó que o rastro segue (a bola).
var alvo: Node3D
## Raio da primeira bolinha (a mais perto da bola).
var raio := 0.16

var _multimesh: MultiMesh
var _pontos: Array[Vector3] = []
var _tempo := 0.0
var _anterior := Vector3.ZERO
var _velocidade := 0.0


func _ready() -> void:
	top_level = true
	var esfera := SphereMesh.new()
	esfera.radius = 1.0
	esfera.height = 2.0
	esfera.radial_segments = 10
	esfera.rings = 5
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	esfera.material = material

	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.mesh = esfera
	_multimesh.instance_count = QUANTIDADE
	var instancias := MultiMeshInstance3D.new()
	instancias.multimesh = _multimesh
	instancias.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instancias)
	_limpar()


func _physics_process(delta: float) -> void:
	if alvo == null or not is_instance_valid(alvo) or delta <= 0.0:
		return
	var agora := alvo.global_position
	_velocidade = agora.distance_to(_anterior) / delta
	_anterior = agora
	if _velocidade < VELOCIDADE_MINIMA:
		if not _pontos.is_empty():
			_pontos.pop_back()
			_desenhar()
		return
	_tempo += delta
	if _tempo < INTERVALO:
		return
	_tempo = 0.0
	_pontos.push_front(agora)
	if _pontos.size() > QUANTIDADE:
		_pontos.resize(QUANTIDADE)
	_desenhar()


func _desenhar() -> void:
	for i in QUANTIDADE:
		if i < _pontos.size():
			var fracao := 1.0 - float(i) / QUANTIDADE
			var tamanho := raio * (0.35 + 0.65 * fracao)
			_multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * tamanho), _pontos[i]))
			_multimesh.set_instance_color(i, Color(COR, 0.55 * fracao))
		else:
			_multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))


func _limpar() -> void:
	_pontos.clear()
	_desenhar()
