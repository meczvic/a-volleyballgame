extends RefCounted
## Formação no saque e lugares de cada função durante o rally.
##
## Coordenadas "do time": x = lado (negativo = esquerda de quem olha pra rede),
## y = distância da rede, em metros.
##
## Regra da ordem no saque (FIVB 7.4): na hora em que quem saca bate na bola,
## cada time tem que estar dentro da própria quadra e na ordem do rodízio:
## - cada um da rede mais perto da rede que o do fundo da mesma coluna
##   (4 na frente do 5, 3 na frente do 6, 2 na frente do 1);
## - em cada fila, da esquerda pra direita: 4, 3, 2 (rede) e 5, 6, 1 (fundo).
## Quem saca não conta. Depois do saque, cada um vai pra onde quiser
## (é aí que o levantador "infiltra" e cada um vai pro lado da sua função).

## [rede, fundo] de cada coluna, da esquerda pra direita.
const COLUNAS := [[4, 5], [3, 6], [2, 1]]
## Filas da esquerda pra direita.
const FILA_DA_REDE := [4, 3, 2]
const FILA_DO_FUNDO := [5, 6, 1]
## Lado (x) de cada posição na formação do saque.
const X_DA_POSICAO := {4: -3.0, 3: 0.0, 2: 3.0, 5: -3.0, 6: 0.0, 1: 3.0}

## Metade da largura e o comprimento de cada lado da quadra (m).
const MEIA_LARGURA := 4.5
const FUNDO := 9.0
## Folga que o atleta controlado mantém dos vizinhos antes do saque.
const FOLGA := 0.3

## Profundidades (distância da rede) na formação do saque.
const Y_REDE_SACANDO := 1.2
const Y_REDE_RECEBENDO := 2.5
const Y_LEVANTADOR_NA_REDE := 1.0
const Y_FUNDO := 6.5
## Levantador do fundo, no time que recebe: escondido logo atrás do colega
## da rede, pronto pra infiltrar até o ponto do levantamento.
const Y_LEVANTADOR_ESCONDIDO := 3.4


static func e_da_rede(posicao: int) -> bool:
	return posicao >= 2 and posicao <= 4


## Lugar do atleta na "posicao" do rodízio na hora do saque.
## Sempre respeita a regra da ordem (veja o teste teste_formacao.gd).
static func lugar_no_saque(posicao: int, e_levantador: bool, recebendo: bool) -> Vector2:
	var x: float = X_DA_POSICAO[posicao]
	if e_da_rede(posicao):
		if e_levantador and recebendo:
			return Vector2(x, Y_LEVANTADOR_NA_REDE)
		return Vector2(x, Y_REDE_RECEBENDO if recebendo else Y_REDE_SACANDO)
	if e_levantador and recebendo:
		return Vector2(x, Y_LEVANTADOR_ESCONDIDO)
	return Vector2(x, Y_FUNDO)


## Faltas de posição: lista vazia = formação certa.
## "lugares": posição (1 a 6) -> Vector2. "ignorar": posição de quem saca (0 = nenhuma).
static func faltas(lugares: Dictionary, ignorar: int = 0) -> Array[String]:
	var encontradas: Array[String] = []
	for coluna in COLUNAS:
		var rede: int = coluna[0]
		var fundo: int = coluna[1]
		if rede == ignorar or fundo == ignorar:
			continue
		if not (lugares[rede].y < lugares[fundo].y):
			encontradas.append("posição %d não está na frente da %d" % [rede, fundo])
	for fila in [FILA_DA_REDE, FILA_DO_FUNDO]:
		for i in 2:
			var esquerda: int = fila[i]
			var direita: int = fila[i + 1]
			if esquerda == ignorar or direita == ignorar:
				continue
			if not (lugares[esquerda].x < lugares[direita].x):
				encontradas.append("posição %d não está à esquerda da %d" % [esquerda, direita])
	for posicao in lugares:
		if posicao == ignorar:
			continue
		var lugar: Vector2 = lugares[posicao]
		if absf(lugar.x) > MEIA_LARGURA or lugar.y < 0.0 or lugar.y > FUNDO:
			encontradas.append("posição %d fora da quadra" % posicao)
	return encontradas


## Ajusta "ponto" (onde o atleta da "posicao" quer ir antes do saque) pra
## ele continuar na ordem em relação aos outros e dentro da quadra.
static func limitar(posicao: int, ponto: Vector2, lugares: Dictionary, ignorar: int = 0) -> Vector2:
	var minimo_x := -MEIA_LARGURA + FOLGA
	var maximo_x := MEIA_LARGURA - FOLGA
	var minimo_y := 0.4
	var maximo_y := FUNDO - FOLGA

	var fila: Array = FILA_DA_REDE if e_da_rede(posicao) else FILA_DO_FUNDO
	var i := fila.find(posicao)
	if i > 0 and fila[i - 1] != ignorar:
		minimo_x = maxf(minimo_x, lugares[fila[i - 1]].x + FOLGA)
	if i < 2 and fila[i + 1] != ignorar:
		maximo_x = minf(maximo_x, lugares[fila[i + 1]].x - FOLGA)

	for coluna in COLUNAS:
		if coluna[0] == posicao and coluna[1] != ignorar:
			maximo_y = minf(maximo_y, lugares[coluna[1]].y - FOLGA)
		elif coluna[1] == posicao and coluna[0] != ignorar:
			minimo_y = maxf(minimo_y, lugares[coluna[0]].y + FOLGA)

	# Se os vizinhos estiverem colados, fica no meio do espaço que sobrou.
	var x := clampf(ponto.x, minimo_x, maximo_x) if minimo_x <= maximo_x else (minimo_x + maximo_x) / 2.0
	var y := clampf(ponto.y, minimo_y, maximo_y) if minimo_y <= maximo_y else (minimo_y + maximo_y) / 2.0
	return Vector2(x, y)


## Lado (x) de cada função depois do saque, quando o time está montando o
## ataque. Na rede: ponteiro na esquerda, central no meio, oposto (ou o
## levantador) na direita. No fundo: central na esquerda, ponteiro no meio
## (o melhor passador), oposto e levantador na direita.
static func x_da_funcao(funcao: String, na_rede: bool) -> float:
	if na_rede:
		match funcao:
			"ponteiro":
				return -3.0
			"central":
				return 0.0
			_:
				return 3.0
	match funcao:
		"central":
			return -3.0
		"ponteiro":
			return 0.0
		_:
			return 3.0
