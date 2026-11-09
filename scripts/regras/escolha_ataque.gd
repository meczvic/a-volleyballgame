extends RefCounted
## Escolhe pra qual atacante o levantador manda a bola, pela direção apertada.
##
## Funciona com qualquer quantidade de alvos: pega o alvo que está mais
## "na direção" que o jogador apertou, olhando a partir do centro dos alvos.
## A direção vem da tela: x positivo = direita, y positivo = baixo
## (com a câmera atrás do time, olhando pra rede).

## Abaixo disso o analógico conta como solto.
const ZONA_MORTA := 0.3


## Devolve o índice do alvo escolhido, ou "padrao" se nada estiver apertado.
static func escolher(alvos: Array, direcao: Vector2, padrao: int) -> int:
	if direcao.length() < ZONA_MORTA or alvos.is_empty():
		return padrao
	var centro := centro_de(alvos)
	var rumo_apertado := direcao.normalized()
	var melhor := padrao
	var maior_alinhamento := -INF
	for i in alvos.size():
		var alvo: Vector3 = alvos[i]
		var rumo_do_alvo := Vector2(alvo.x - centro.x, alvo.z - centro.z).normalized()
		var alinhamento := rumo_do_alvo.dot(rumo_apertado)
		if alinhamento > maior_alinhamento:
			maior_alinhamento = alinhamento
			melhor = i
	return melhor


static func centro_de(alvos: Array) -> Vector3:
	var soma := Vector3.ZERO
	for alvo in alvos:
		soma += alvo
	return soma / float(alvos.size())


## Seta que indica qual direção apertar pra escolher esse alvo.
## Usa só caracteres simples (< ^ > v) pra funcionar com qualquer fonte.
static func seta_de(alvo: Vector3, centro: Vector3) -> String:
	var rumo := Vector2(alvo.x - centro.x, alvo.z - centro.z)
	if absf(rumo.x) >= absf(rumo.y):
		return ">" if rumo.x > 0.0 else "<"
	return "v" if rumo.y > 0.0 else "^"
