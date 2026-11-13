extends Node3D
## Anel de tempo: um anel que fecha em volta do atleta controlado e encosta
## no anel dele na hora certa de apertar o botão.
##
## Fino e discreto (13/11/2026): longe da hora é pequeno e quase transparente;
## fica mais forte na janela "bom" e branco cheio na "perfeito". Depois da hora, some.
## A partida chama mostrar(ponto, segundos) a cada quadro, com os segundos
## que faltam pro momento ideal (veja scripts/regras/tempo_do_toque.gd).

const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")

## Raio do anel quando chega na hora: igual ao anel do atleta controlado.
const RAIO_NA_HORA := 0.6
## Quanto o raio cresce por segundo que falta.
const RAIO_POR_SEGUNDO := 1.0
const RAIO_MAXIMO := 1.4
## Só aparece quando falta menos que isso (s).
const ANTECEDENCIA := 0.8

const COR_LONGE := Color(1.0, 1.0, 1.0, 0.35)
const COR_BOM := Color(1.0, 1.0, 1.0, 0.7)
const COR_PERFEITO := Color("#3DDC84")
## Na janela perfeita o anel só fica branco cheio (o verde ficou pro brilho
## do toque perfeito, em _avisar_qualidade). Tela limpa, 13/11/2026.
const COR_NA_HORA := Color(1.0, 1.0, 1.0, 1.0)

var _anel: MeshInstance3D
var _material: StandardMaterial3D


func _ready() -> void:
	var toro := TorusMesh.new()
	toro.inner_radius = 0.92
	toro.outer_radius = 1.0
	toro.rings = 48
	_anel = MeshInstance3D.new()
	_anel.mesh = toro
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.no_depth_test = true
	_anel.material_override = _material
	_anel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_anel)
	visible = false


## Mostra o anel no chão em "ponto", faltando "segundos" pro momento ideal
## (negativo = já passou).
func mostrar(ponto: Vector3, segundos: float) -> void:
	if segundos > ANTECEDENCIA or segundos < -TempoDoToque.JANELA_BOA * 2.0:
		visible = false
		return
	visible = true
	position = Vector3(ponto.x, 0.05, ponto.z)
	var raio := raio_para(segundos)
	var cor := cor_para(segundos)
	# Depois da hora, vai sumindo.
	if segundos < -TempoDoToque.JANELA_BOA:
		cor.a *= 1.0 - (-segundos - TempoDoToque.JANELA_BOA) / TempoDoToque.JANELA_BOA
	_material.albedo_color = cor
	_anel.scale = Vector3(raio, 0.1, raio)


func esconder() -> void:
	visible = false


## Põe o anel numa camada de desenho (1 a 20), pra só a câmera do próprio
## jogador mostrar (na tela dividida).
func usar_camada(camada: int) -> void:
	_anel.layers = 1 << (camada - 1)


static func raio_para(segundos: float) -> float:
	return clampf(RAIO_NA_HORA + RAIO_POR_SEGUNDO * maxf(segundos, 0.0), RAIO_NA_HORA, RAIO_MAXIMO)


static func cor_para(segundos: float) -> Color:
	match TempoDoToque.qualidade(segundos):
		TempoDoToque.Qualidade.PERFEITO:
			return COR_NA_HORA
		TempoDoToque.Qualidade.BOM:
			return COR_BOM
	return COR_LONGE
