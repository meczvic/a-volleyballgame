extends Node3D
## Estouro de faíscas onde a bola foi batida (cortada, bloqueio) ou caiu.
## Riscos curtos que saem pra todos os lados, caem um pouco e somem. Some sozinho.
##
## Só visual: as direções são fixas (espalhadas por igual), sem sorteio,
## então não muda nada no jogo nem na partida com semente.

const DURACAO := 0.45
## Gravidade das faíscas (m/s²): caem um pouco enquanto voam.
const GRAVIDADE := 9.0

var _cor := Color.WHITE
var _quantidade := 12
var _velocidade := 7.0
var _tamanho := 0.12
var _tempo := 0.0
var _faiscas: Array[MeshInstance3D] = []
var _rumos: Array[Vector3] = []
var _material: StandardMaterial3D


## Cria o estouro em "ponto" (no mundo) dentro de "pai". "forca" (0 a 1)
## muda quantas faíscas, a velocidade e o tamanho.
static func mostrar(pai: Node, ponto: Vector3, cor: Color, forca := 1.0) -> Node3D:
	var estouro := new()
	estouro._cor = cor
	estouro._quantidade = int(lerpf(8.0, 18.0, clampf(forca, 0.0, 1.0)))
	estouro._velocidade = lerpf(4.5, 10.0, clampf(forca, 0.0, 1.0))
	estouro._tamanho = lerpf(0.08, 0.16, clampf(forca, 0.0, 1.0))
	pai.add_child(estouro)
	estouro.global_position = ponto
	return estouro


func _ready() -> void:
	var risco := BoxMesh.new()
	risco.size = Vector3(1.0, 1.0, 1.0)
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = _cor
	risco.material = _material
	# Direções espalhadas numa esfera (espiral de Fibonacci), mais pra cima e pros lados.
	var angulo_de_ouro := PI * (3.0 - sqrt(5.0))
	for i in _quantidade:
		var y := 1.0 - (float(i) + 0.5) / _quantidade * 1.6
		var raio := sqrt(maxf(1.0 - y * y, 0.0))
		var giro := angulo_de_ouro * i
		var rumo := Vector3(cos(giro) * raio, y, sin(giro) * raio).normalized()
		var faisca := MeshInstance3D.new()
		faisca.mesh = risco
		faisca.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(faisca)
		_faiscas.append(faisca)
		# Faíscas um pouco mais rápidas e mais lentas, pra não sair uma bola perfeita.
		_rumos.append(rumo * _velocidade * (0.7 + 0.3 * float(i % 3)))
	_aplicar(0.0)


func _process(delta: float) -> void:
	_tempo += delta
	_aplicar(_tempo)
	if _tempo >= DURACAO:
		queue_free()


func _aplicar(t: float) -> void:
	var fracao := clampf(t / DURACAO, 0.0, 1.0)
	for i in _faiscas.size():
		var faisca := _faiscas[i]
		var rumo := _rumos[i]
		var velocidade := rumo + Vector3.DOWN * GRAVIDADE * t
		faisca.position = rumo * t + Vector3.DOWN * 0.5 * GRAVIDADE * t * t
		# Risco comprido na direção em que voa, encolhendo até sumir.
		var comprimento := _tamanho * 3.5 * (1.0 - fracao) + 0.01
		var largura := _tamanho * (1.0 - fracao * 0.7)
		if velocidade.length() > 0.01:
			var frente := velocidade.normalized()
			var lado := frente.cross(Vector3.UP)
			if lado.length() < 0.01:
				lado = Vector3.RIGHT
			lado = lado.normalized()
			var cima := lado.cross(frente).normalized()
			faisca.basis = Basis(lado * largura, cima * largura, frente * comprimento)
	_material.albedo_color.a = 1.0 - fracao * fracao
