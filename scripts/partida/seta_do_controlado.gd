extends MeshInstance3D
## Seta em cima da cabeça do atleta que o jogador está controlando, na cor do
## time. Sempre virada pra câmera. Quando o controle passa pra outro atleta,
## a seta "pula" (cresce e volta), pra você ver na hora com quem está.
##
## Só visual: não muda nada no jogo.

## Altura da ponta da seta acima da cabeça (m).
const FOLGA_ACIMA_DA_CABECA := 0.45
## Altura da cabeça quando o personagem não diz a dele (cápsula).
const ALTURA_PADRAO := 1.8
## Tamanho da seta (m): largura em cima e altura.
const LARGURA := 0.5
const ALTURA := 0.42
## Pulo na troca de atleta: quanto cresce e quanto dura (s).
const CRESCIMENTO_NA_TROCA := 1.9
const DURACAO_DA_TROCA := 0.35
## Balanço pra cima e pra baixo, pra chamar atenção sem atrapalhar.
const BALANCO := 0.06
const VELOCIDADE_DO_BALANCO := 5.0

var cor := Color.WHITE
## Atleta que a seta está seguindo (pros testes).
var atleta_atual: Node3D

var _tween: Tween
var _tempo := 0.0


func _ready() -> void:
	mesh = _triangulo()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	# Sem isto a seta não cresce no pulo (o billboard ignora a escala).
	material.billboard_keep_scale = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	# A cor vem dos vértices (miolo na cor do time, borda escura).
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.no_depth_test = true
	material.render_priority = 10
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Coloca a seta em cima do "atleta". Se é outro atleta, a seta pula.
func seguir(atleta: Node3D, delta := 0.0) -> void:
	if atleta == null:
		visible = false
		return
	visible = true
	if atleta != atleta_atual:
		var trocou := atleta_atual != null
		atleta_atual = atleta
		if trocou:
			pular()
	_tempo += delta
	var y := atleta.position.y + _altura_da_cabeca(atleta) + FOLGA_ACIMA_DA_CABECA
	position = Vector3(atleta.position.x, y + BALANCO * sin(_tempo * VELOCIDADE_DO_BALANCO), atleta.position.z)


## A seta cresce e volta ao tamanho normal.
func pular() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	scale = Vector3.ONE * CRESCIMENTO_NA_TROCA
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector3.ONE, DURACAO_DA_TROCA) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Pra testes: se a seta está no meio do pulo da troca.
func pulando() -> bool:
	return scale.x > 1.01


func _altura_da_cabeca(atleta: Node3D) -> float:
	for filho in atleta.get_children():
		if filho.has_meta("altura"):
			return float(filho.get_meta("altura"))
	return ALTURA_PADRAO


## Triângulo apontando pra baixo, com a ponta na origem. O miolo tem a cor
## do time e a borda é mais escura (contorno).
func _triangulo() -> ArrayMesh:
	var escuro := Color(cor.darkened(0.6), 1.0)
	var vertices := PackedVector3Array()
	var cores := PackedColorArray()
	var ponta := Vector3.ZERO
	var esquerda := Vector3(-LARGURA / 2.0, ALTURA, 0.0)
	var direita := Vector3(LARGURA / 2.0, ALTURA, 0.0)
	# Borda (triângulo de fora, escuro) e miolo (menor, na cor do time) um
	# pouquinho na frente.
	var centro := (ponta + esquerda + direita) / 3.0
	var encolher := 0.72
	var frente := Vector3(0.0, 0.0, 0.01)
	for v in [ponta, esquerda, direita]:
		vertices.append(v)
		cores.append(escuro)
	for v in [ponta, esquerda, direita]:
		vertices.append(centro + (v - centro) * encolher + frente)
		cores.append(cor)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = cores
	var malha := ArrayMesh.new()
	malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return malha
