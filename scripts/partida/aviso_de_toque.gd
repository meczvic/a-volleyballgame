extends Label3D
## Texto que sobe e some em cima do atleta depois de um toque
## ("Perfeito!", "Bom", "Ruim"). Some sozinho.

const FONTE := preload("res://fontes/BarlowCondensed-BoldItalic.ttf")
const DURACAO := 0.8
const SUBIDA := 0.9
## Avisos a menos disso (m, no chão) de outro aviso vivo sobem um degrau,
## pra um não escrever em cima do outro.
const DISTANCIA_DE_EMPILHAR := 2.0
const DEGRAU := 0.55

var _tempo := 0.0
var _inicio := Vector3.ZERO


## Cria o aviso em "ponto" (no mundo) dentro de "pai". Se já tem outro
## aviso perto, este fica em cima dele.
static func mostrar(pai: Node, ponto: Vector3, texto: String, cor: Color) -> Label3D:
	var aviso := new()
	aviso.text = texto
	aviso.modulate = cor
	var lugar := ponto
	lugar.y += DEGRAU * degraus_ocupados(pai, ponto, aviso.get_script())
	pai.add_child(aviso)
	aviso.global_position = lugar
	return aviso


## Quantos avisos vivos (nós com este "script") já estão perto de "ponto" (no chão).
static func degraus_ocupados(pai: Node, ponto: Vector3, script: Script) -> int:
	var ocupados := 0
	for filho in pai.get_children():
		if filho is Label3D and filho.get_script() == script \
				and Vector2(filho.global_position.x - ponto.x, filho.global_position.z - ponto.z).length() < DISTANCIA_DE_EMPILHAR:
			ocupados += 1
	return ocupados


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
