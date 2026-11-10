extends MeshInstance3D
## Anel no chão embaixo do atleta que o jogador está controlando, na cor de
## detalhe do time. Quando um botão não pode ser usado (bola longe ou alta
## demais), o anel pisca pra mostrar que o jogo ouviu o botão.

const RAIO_INTERNO := 0.5
const RAIO_EXTERNO := 0.65
## Quanto o anel cresce ao piscar e quanto tempo leva pra voltar (s).
const CRESCIMENTO := 1.6
const DURACAO_DA_PISCADA := 0.22
const COR_DA_PISCADA := Color(1.0, 1.0, 1.0)

var cor := Color.WHITE
var _material: StandardMaterial3D
var _tween: Tween


func _ready() -> void:
	var toro := TorusMesh.new()
	toro.inner_radius = RAIO_INTERNO
	toro.outer_radius = RAIO_EXTERNO
	mesh = toro
	_material = StandardMaterial3D.new()
	_material.albedo_color = cor
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scale = Vector3(1.0, 0.1, 1.0)


## Põe o anel no chão embaixo do "atleta".
func seguir(atleta: Node3D) -> void:
	if atleta == null:
		return
	position = Vector3(atleta.position.x, 0.03, atleta.position.z)


## Pisca: cresce e fica branco, e volta ao normal.
func piscar() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	scale = Vector3(CRESCIMENTO, 0.1, CRESCIMENTO)
	_material.albedo_color = COR_DA_PISCADA
	_tween = create_tween().set_parallel()
	_tween.tween_property(self, "scale", Vector3(1.0, 0.1, 1.0), DURACAO_DA_PISCADA) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_material, "albedo_color", cor, DURACAO_DA_PISCADA)


## Pra testes: se o anel está no meio de uma piscada.
func piscando() -> bool:
	return scale.x > 1.01
