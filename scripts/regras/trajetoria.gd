extends RefCounted
## Matemática da trajetória da bola, sem nada de gráfico.
##
## A bola faz uma parábola: anda reto na horizontal e cai com a gravidade.
## Como a conta é exata, dá pra saber ANTES onde ela vai cair
## (é isso que o marcador de queda mostra).

const GRAVIDADE := 9.8


## Velocidade inicial pra sair de "origem", subir até "altura_maxima"
## e cair exatamente em "destino".
static func velocidade_para(origem: Vector3, destino: Vector3, altura_maxima: float, gravidade: float = GRAVIDADE) -> Vector3:
	# O topo precisa ficar acima da saída e da chegada.
	var topo := maxf(altura_maxima, maxf(origem.y, destino.y) + 0.01)
	var vy := sqrt(2.0 * gravidade * (topo - origem.y))
	var tempo_subida := vy / gravidade
	var tempo_descida := sqrt(2.0 * (topo - destino.y) / gravidade)
	var tempo_total := tempo_subida + tempo_descida
	return Vector3(
		(destino.x - origem.x) / tempo_total,
		vy,
		(destino.z - origem.z) / tempo_total
	)


## Igual a velocidade_para, mas sobe o topo da parábola até a bola
## passar por cima da rede com folga.
static func velocidade_passando_rede(origem: Vector3, destino: Vector3, altura_maxima: float, altura_minima_na_rede: float, gravidade: float = GRAVIDADE) -> Vector3:
	var topo := altura_maxima
	var velocidade := velocidade_para(origem, destino, topo, gravidade)
	for _i in 12:
		if altura_na_rede(origem, velocidade, gravidade) >= altura_minima_na_rede:
			break
		topo += 0.5
		velocidade = velocidade_para(origem, destino, topo, gravidade)
	return velocidade


## Onde a bola está depois de "tempo" segundos de voo.
static func posicao_em(origem: Vector3, velocidade: Vector3, tempo: float, gravidade: float = GRAVIDADE) -> Vector3:
	return origem + velocidade * tempo + Vector3(0.0, -0.5 * gravidade * tempo * tempo, 0.0)


## Segundos até a bola descer até "altura". Devolve -1 se nunca chegar.
static func tempo_ate_altura(origem: Vector3, velocidade: Vector3, altura: float, gravidade: float = GRAVIDADE) -> float:
	# origem.y + vy*t - (g/2)*t² = altura  ->  resolve a equação do 2º grau.
	var a := 0.5 * gravidade
	var delta := velocidade.y * velocidade.y + 4.0 * a * (origem.y - altura)
	if delta < 0.0:
		return -1.0
	return (velocidade.y + sqrt(delta)) / (2.0 * a)


## Ponto onde a bola vai tocar o chão (na altura "altura_chao").
static func ponto_de_queda(origem: Vector3, velocidade: Vector3, altura_chao: float, gravidade: float = GRAVIDADE) -> Vector3:
	var tempo := tempo_ate_altura(origem, velocidade, altura_chao, gravidade)
	if tempo < 0.0:
		return origem
	return posicao_em(origem, velocidade, tempo, gravidade)


## Voo da cortada: a trajetória MAIS RETA possível que sai de "origem", passa
## por cima da rede (z = 0) na altura "altura_na_rede" ou mais e cai em "destino",
## na velocidade horizontal dada (m/s). Não sobe antes de descer: sai reto ou
## pra baixo e só vai entortando (a gravidade dá o resto).
##
## A conta é feita no perfil do voo: y(s) = y0 + m*s - k*s², com s = distância
## horizontal andada. Dá pra voltar pra velocidade e gravidade: o ângulo inicial
## é m, e a gravidade é g = 2*k*v². Devolve { "velocidade": Vector3,
## "gravidade": float } ou {} se não dá (não cruza a rede, sobe demais ou a curva
## seria forte demais: aí quem chamou usa o arco de velocidade_passando_rede).
const K_MINIMO := 0.002
const SUBIDA_MAXIMA_DO_RETO := 0.3
const GRAVIDADE_MAXIMA_DO_RETO := 70.0


static func voo_reto(origem: Vector3, destino: Vector3, velocidade_horizontal: float, altura_na_rede: float) -> Dictionary:
	var dz := destino.z - origem.z
	var horizontal := Vector2(destino.x - origem.x, dz)
	var total := horizontal.length()
	if total < 0.5 or velocidade_horizontal <= 0.1 or is_zero_approx(dz):
		return {}
	var fracao_da_rede := -origem.z / dz
	if fracao_da_rede <= 0.0 or fracao_da_rede >= 1.0:
		return {}
	var s_rede := fracao_da_rede * total
	# Primeiro a reta (quase sem curva): se passa da rede com folga, é ela.
	var k := K_MINIMO
	var m := (destino.y - origem.y + k * total * total) / total
	if origem.y + m * s_rede - k * s_rede * s_rede < altura_na_rede:
		# Não passa: curva mais fraca que passa rente por cima da rede e cai no destino.
		var c_rede := altura_na_rede - origem.y
		var c_destino := destino.y - origem.y
		var det := s_rede * (-total * total) - total * (-s_rede * s_rede)
		if absf(det) < 0.0001:
			return {}
		m = (c_rede * (-total * total) - c_destino * (-s_rede * s_rede)) / det
		k = (s_rede * c_destino - total * c_rede) / det
		if k < K_MINIMO or m > SUBIDA_MAXIMA_DO_RETO:
			return {}
	var gravidade_do_voo := 2.0 * k * velocidade_horizontal * velocidade_horizontal
	if gravidade_do_voo > GRAVIDADE_MAXIMA_DO_RETO:
		return {}
	var direcao := horizontal / total
	return {
		"velocidade": Vector3(direcao.x * velocidade_horizontal, m * velocidade_horizontal, direcao.y * velocidade_horizontal),
		"gravidade": gravidade_do_voo,
	}


## Altura da bola quando ela cruza a linha da rede (z = 0).
## Devolve INF se ela não vai cruzar a rede.
static func altura_na_rede(origem: Vector3, velocidade: Vector3, gravidade: float = GRAVIDADE) -> float:
	if is_zero_approx(velocidade.z):
		return INF
	var tempo := -origem.z / velocidade.z
	if tempo <= 0.0:
		return INF
	# Se a bola cai no chão antes de chegar na rede, ela não cruza.
	if tempo > tempo_ate_altura(origem, velocidade, 0.0, gravidade):
		return INF
	return posicao_em(origem, velocidade, tempo, gravidade).y
