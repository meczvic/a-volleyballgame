extends Label3D
## Texto que sobe e some em cima do atleta depois de um toque
## ("Perfeito!", "Bom", "Ruim"). Some sozinho.

const FONTE := preload("res://fontes/BarlowCondensed-BoldItalic.ttf")
const DURACAO := 0.8
const SUBIDA := 0.9

var _tempo := 0.0
var _inicio := Vector3.ZERO


## Cria o aviso em "ponto" (no mundo) dentro de "pai".
static func mostrar(pai: Node, ponto: Vector3, texto: String, cor: Color) -> Label3D:
	var aviso := new()
	aviso.text = texto
	aviso.modulate = cor
	pai.add_child(aviso)
	aviso.global_position = ponto
	return aviso


func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	fixed_size = true
	pixel_size = 0.0007
	font_size = 44
	outline_size = 14
	outline_modulate = Color(0.08, 0.08, 0.1)
	font = FONTE
	_inicio = position


func _process(delta: float) -> void:
	_tempo += delta
	var t := clampf(_tempo / DURACAO, 0.0, 1.0)
	position = _inicio + Vector3(0.0, SUBIDA * (1.0 - pow(1.0 - t, 3.0)), 0.0)
	# Entra grande e assenta; some no último terço.
	var escala := 1.0 + 0.4 * maxf(0.0, 1.0 - t * 5.0)
	scale = Vector3.ONE * escala
	modulate.a = 1.0 if t < 0.66 else 1.0 - (t - 0.66) / 0.34
	outline_modulate.a = modulate.a
	if _tempo >= DURACAO:
		queue_free()
