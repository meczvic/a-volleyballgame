extends Node3D
## Anel amarelo pulsando no chão, no lugar onde a bola vai cair.

const COR := Color("#FFD23F")

var _anel: MeshInstance3D
var _tempo := 0.0


func _ready() -> void:
	var toro := TorusMesh.new()
	toro.inner_radius = 0.45
	toro.outer_radius = 0.6
	_anel = MeshInstance3D.new()
	_anel.mesh = toro
	var material := StandardMaterial3D.new()
	material.albedo_color = COR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_anel.material_override = material
	_anel.scale = Vector3(1.0, 0.05, 1.0)
	add_child(_anel)
	visible = false


func mostrar_em(ponto: Vector3) -> void:
	position = Vector3(ponto.x, 0.03, ponto.z)
	visible = true


func esconder() -> void:
	visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	_tempo += delta
	var tamanho := 1.0 + 0.12 * sin(_tempo * 8.0)
	_anel.scale = Vector3(tamanho, 0.05, tamanho)
