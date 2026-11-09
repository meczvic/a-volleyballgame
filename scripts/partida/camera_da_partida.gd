extends Camera3D
## Câmera estilo transmissão de TV: fica parada no lugar dela, atrás do time,
## mas vira devagar pra acompanhar a bola, como um cinegrafista.
##
## Uso: preparar(posicao, foco, abertura) uma vez e alvo = bola. O quanto
## ela acompanha é pouco de propósito: a quadra inteira continua na tela.

## Fração do deslocamento da bola (pro lado e em profundidade) que a câmera segue.
const ACOMPANHAMENTO_LATERAL := 0.22
const ACOMPANHAMENTO_PROFUNDIDADE := 0.10
## Quanto a altura da bola puxa o olhar pra cima (fração).
const ACOMPANHAMENTO_ALTURA := 0.15
## Velocidade da virada: maior = chega mais rápido (1/s).
const SUAVIDADE := 4.0

## Nó que a câmera acompanha (a bola). Sem alvo, fica olhando pro foco.
var alvo: Node3D
var _posicao_base := Vector3.ZERO
var _foco_base := Vector3.ZERO
var _ponto_olhado := Vector3.ZERO


## Coloca a câmera em "posicao" olhando pro "foco", com a abertura vertical em graus.
func preparar(posicao: Vector3, foco: Vector3, abertura: float) -> void:
	fov = abertura
	_posicao_base = posicao
	_foco_base = foco
	_ponto_olhado = foco
	look_at_from_position(posicao, foco)


func _process(delta: float) -> void:
	var desejado := ponto_desejado()
	# Chega perto do ponto desejado de um jeito que não depende da taxa de quadros.
	_ponto_olhado = _ponto_olhado.lerp(desejado, 1.0 - exp(-SUAVIDADE * delta))
	look_at_from_position(_posicao_base, _ponto_olhado)


## Pra onde a câmera quer olhar agora: o foco, puxado um pouco pela bola.
func ponto_desejado() -> Vector3:
	if alvo == null or not is_instance_valid(alvo):
		return _foco_base
	var bola := alvo.global_position
	return _foco_base + Vector3(
		bola.x * ACOMPANHAMENTO_LATERAL,
		bola.y * ACOMPANHAMENTO_ALTURA,
		(bola.z - _foco_base.z) * ACOMPANHAMENTO_PROFUNDIDADE
	)


## Pra testes: pra onde a câmera está olhando agora.
func ponto_olhado() -> Vector3:
	return _ponto_olhado
