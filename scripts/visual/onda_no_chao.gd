extends MeshInstance3D
## Onda que se abre no chão onde a bola caiu, na cor de quem fez o ponto.
## Some sozinha.

const DURACAO := 0.55
const RAIO_INICIAL := 0.25
const RAIO_FINAL := 2.6

var _tempo := 0.0
var _material: StandardMaterial3D
var _cor := Color.WHITE


static func mostrar(pai: Node, ponto: Vector3, cor: Color) -> MeshInstance3D:
	var onda := new()
	onda._cor = cor
	pai.add_child(onda)
	onda.position = Vector3(ponto.x, 0.04, ponto.z)
	return onda


func _ready() -> void:
	var toro := TorusMesh.new()
	toro.inner_radius = 0.82
	toro.outer_radius = 1.0
	toro.rings = 48
	mesh = toro
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = _cor
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_aplicar(0.0)


func _process(delta: float) -> void:
	_tempo += delta
	_aplicar(_tempo / DURACAO)
	if _tempo >= DURACAO:
		queue_free()


func _aplicar(t: float) -> void:
	t = clampf(t, 0.0, 1.0)
	var raio := lerpf(RAIO_INICIAL, RAIO_FINAL, 1.0 - pow(1.0 - t, 3.0))
	scale = Vector3(raio, 0.08, raio)
	_material.albedo_color.a = 0.9 * (1.0 - t)
