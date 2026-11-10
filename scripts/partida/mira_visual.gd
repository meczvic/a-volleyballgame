extends Node3D
## Mira na quadra do outro lado: um X no alvo e um círculo do tamanho do erro
## (onde a bola pode cair). A força do saque fica numa barra na tela
## (scripts/partida/barra_de_forca.gd), perto de quem saca.
## Cada time tem a sua, numa camada que só a câmera do próprio jogador vê.

const COR := Color("#FF5A4E")
const COR_ARRISCADA := Color("#FF2D2D")

var _x: Node3D
var _circulo: MeshInstance3D
var _material_circulo: StandardMaterial3D
var _camada := 1


func _ready() -> void:
	_x = Node3D.new()
	add_child(_x)
	for angulo in [PI / 4.0, -PI / 4.0]:
		var barra := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = Vector3(1.2, 0.02, 0.2)
		barra.mesh = caixa
		barra.material_override = _material(COR, 0.95)
		barra.rotation.y = angulo
		_x.add_child(barra)

	_circulo = MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 1.0
	disco.bottom_radius = 1.0
	disco.height = 0.01
	disco.radial_segments = 48
	_circulo.mesh = disco
	_material_circulo = _material(COR, 0.35)
	_circulo.material_override = _material_circulo
	add_child(_circulo)
	usar_camada(_camada)
	visible = false


## Mostra a mira em "ponto" (no chão, mundo) com o erro "raio".
## "arriscada": saque no talo, o círculo fica vermelho forte.
func mostrar(ponto: Vector3, raio: float, arriscada: bool = false) -> void:
	visible = true
	position = Vector3(ponto.x, 0.04, ponto.z)
	_circulo.scale = Vector3(raio, 1.0, raio)
	var cor := COR_ARRISCADA if arriscada else COR
	_material_circulo.albedo_color = Color(cor, 0.5 if arriscada else 0.35)


func esconder() -> void:
	visible = false


func usar_camada(camada: int) -> void:
	_camada = camada
	if _x == null:
		return
	for no in [_circulo] + _x.get_children():
		(no as VisualInstance3D).layers = 1 << (camada - 1)


func _material(cor: Color, alfa: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(cor, alfa)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	return material
