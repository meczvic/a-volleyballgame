extends RefCounted
## Mira do saque e da cortada, sem nada de gráfico.
##
## Saque: segurar o botão enche a força (0 a 1, enchendo e esvaziando, pra
## o tempo de soltar importar). Enquanto segura, a direção move um alvo na
## quadra do outro lado. Mais força = bola mais baixa e rápida, mas erra
## mais; no máximo da barra, o erro dá um salto (risco de bola fora).
##
## Cortada: a direção na hora da batida escolhe o lugar: esquerda/direita
## (paralela ou diagonal) e frente/trás (bola funda ou curta).
##
## Coordenadas "da quadra do alvo": x = lado no mundo, y = distância da rede
## (positiva). Quem chama converte pro mundo com o lado certo.

const LARGURA := 9.0
const FUNDO := 9.0

## Tempo pra barra de força ir de 0 a 1 (depois ela volta).
const TEMPO_DA_CARGA := 0.9
## Velocidade do alvo do saque (m/s).
const VELOCIDADE_DO_ALVO := 6.0
## Alvo do saque começa no meio da quadra do outro lado.
const ALVO_INICIAL := Vector2(0.0, 5.5)
## Limites do alvo: um pouco pra dentro das linhas.
const MARGEM := 0.3
const DISTANCIA_MINIMA_DA_REDE := 1.0

## Força acima disso é "no talo": erro bem maior.
const FORCA_ARRISCADA := 0.92

## Cortada: quanto a direção desloca o alvo (m) a partir do centro da mira.
const CORTADA_LADO := 3.2
const CORTADA_FUNDO_MEIO := 6.0
const CORTADA_FUNDO_VARIACAO := 2.5


## Força pelo tempo segurando: sobe até 1 em TEMPO_DA_CARGA e desce de volta.
static func forca(segundos: float) -> float:
	var ciclo := fposmod(maxf(segundos, 0.0), TEMPO_DA_CARGA * 2.0)
	if ciclo <= TEMPO_DA_CARGA:
		return ciclo / TEMPO_DA_CARGA
	return 2.0 - ciclo / TEMPO_DA_CARGA


## Move o alvo do saque pela direção (já na orientação do mundo, x e z) e
## mantém dentro da quadra do alvo. "lado_do_alvo": sinal do z da quadra do alvo.
static func mover_alvo(alvo: Vector2, direcao_no_mundo: Vector2, lado_do_alvo: float, delta: float) -> Vector2:
	# Direção em z do mundo vira distância da rede na quadra do alvo.
	var movimento := Vector2(direcao_no_mundo.x, direcao_no_mundo.y * lado_do_alvo) * VELOCIDADE_DO_ALVO * delta
	return limitar(alvo + movimento)


static func limitar(alvo: Vector2) -> Vector2:
	return Vector2(
		clampf(alvo.x, -LARGURA / 2.0 + MARGEM, LARGURA / 2.0 - MARGEM),
		clampf(alvo.y, DISTANCIA_MINIMA_DA_REDE, FUNDO - MARGEM)
	)


## Altura máxima do saque: fraco sobe bastante (fácil de receber), forte
## vem baixo e rápido. O flutuante é sempre um pouco mais baixo.
static func altura_do_saque(f: float, flutuante: bool) -> float:
	if flutuante:
		# O flutuante não fica muito mais rápido com força: o que dificulta é o
		# balanço (auditoria 2). Assim o viagem é sempre o saque mais rápido.
		return lerpf(5.3, 4.3, clampf(f, 0.0, 1.0))
	return lerpf(5.6, 3.2, clampf(f, 0.0, 1.0))


## Erro do saque (m, raio): cresce com a força e salta no talo. Com força
## alta, mesmo mirando no meio a bola pode sair.
static func erro_do_saque(f: float) -> float:
	var erro := lerpf(0.3, 1.5, clampf(f, 0.0, 1.0))
	if f >= FORCA_ARRISCADA:
		# Grande o bastante pra bola poder sair mesmo mirando no meio da quadra.
		erro += 2.2
	return erro


## Alvo da cortada pela direção na hora da batida (orientação do mundo).
## "lado_do_alvo": sinal do z da quadra do outro time.
static func alvo_da_cortada(direcao_no_mundo: Vector2, lado_do_alvo: float) -> Vector2:
	# Pra frente (rumo à quadra do outro) = mais fundo; pra trás = mais curta.
	var pra_frente := direcao_no_mundo.y * lado_do_alvo
	return limitar(Vector2(
		direcao_no_mundo.x * CORTADA_LADO,
		CORTADA_FUNDO_MEIO + pra_frente * CORTADA_FUNDO_VARIACAO
	))


## Ponto com erro aleatório em volta do alvo (pode cair fora: é o risco).
static func com_erro(alvo: Vector2, raio: float, sorteio: Vector2) -> Vector2:
	# sorteio: dois números de 0 a 1 (ângulo e distância), pros testes fixarem.
	return alvo + Vector2.from_angle(sorteio.x * TAU) * raio * sqrt(sorteio.y)
