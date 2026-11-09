extends RefCounted
## Toque no tempo certo: quanto melhor o tempo do botão, melhor o toque.
##
## Cada toque tem uma altura ideal pra encostar na bola (manchete na altura
## da cintura, levantamento acima da cabeça, cortada no alto do pulo). Na
## hora do botão, o jogo vê quanto falta (ou quanto passou) pra bola chegar
## nessa altura. O erro, em segundos, vira a qualidade do toque:
##   PERFEITO: até JANELA_PERFEITA de erro;
##   BOM: até JANELA_BOA;
##   RUIM: mais que isso (o toque sai, mas torto).
## A qualidade de um toque muda o próximo: passe perfeito deixa a bola na mão
## do levantador e libera o levantamento rápido; passe ruim só deixa
## levantar alto na ponta ou no fundo.
##
## Sem nada de gráfico: a partida pergunta aqui e o anel de tempo mostra.

const Trajetoria := preload("res://scripts/regras/trajetoria.gd")

enum Qualidade { PERFEITO, BOM, RUIM }

## Erro máximo (s) de cada qualidade.
const JANELA_PERFEITA := 0.06
const JANELA_BOA := 0.15

## Altura ideal da bola (m) no contato de cada toque.
const ALTURA_IDEAL := {
	"passe": 0.9,
	"levantamento": 2.4,
	"cortada": 3.2,
}

## Quanto o passe erra o ponto do levantador (m), por qualidade.
const ERRO_DO_PASSE := {
	Qualidade.PERFEITO: 0.15,
	Qualidade.BOM: 0.8,
	Qualidade.RUIM: 2.2,
}
## Altura do passe: o ruim sobe mais (bola "espirrada", demora a cair).
const ALTURA_DO_PASSE := {
	Qualidade.PERFEITO: 3.8,
	Qualidade.BOM: 4.0,
	Qualidade.RUIM: 5.2,
}
## Quanto o levantamento erra o lugar do atacante (m).
const ERRO_DO_LEVANTAMENTO := {
	Qualidade.PERFEITO: 0.1,
	Qualidade.BOM: 0.5,
	Qualidade.RUIM: 1.4,
}
## Altura do levantamento: rápido (bola baixa, chega antes do bloqueio),
## normal e alto (o que dá pra fazer com um passe ruim).
const ALTURA_DO_LEVANTAMENTO_RAPIDO := 3.4
const ALTURA_DO_LEVANTAMENTO_NORMAL := 4.4
const ALTURA_DO_LEVANTAMENTO_ALTO := 5.4

## Ataques que cada qualidade de passe deixa o levantador escolher.
## (Os nomes são os de ATAQUES em partida.gd.)
const ATAQUES_LIBERADOS := {
	Qualidade.PERFEITO: ["Ponta", "Meio", "Oposto", "Fundo"],
	Qualidade.BOM: ["Ponta", "Meio", "Oposto", "Fundo"],
	Qualidade.RUIM: ["Ponta", "Fundo"],
}

## Cortada: força (quanto a bola sobe acima do ponto de contato, menos é
## mais forte), erro da mira (m) e profundidade mínima/máxima (m da rede).
const CORTADA := {
	Qualidade.PERFEITO: { "subida": 0.2, "erro_da_mira": 0.3, "fundo_min": 5.5, "fundo_max": 8.5 },
	Qualidade.BOM: { "subida": 0.4, "erro_da_mira": 0.8, "fundo_min": 4.0, "fundo_max": 8.5 },
	Qualidade.RUIM: { "subida": 1.6, "erro_da_mira": 2.0, "fundo_min": 2.5, "fundo_max": 7.0 },
}


## Segundos até a bola (agora em "posicao", com "velocidade") descer até
## "altura". Negativo: ela já passou dessa altura descendo (há quanto tempo).
## Se ela nem chega nessa altura, o melhor momento é o alto da subida.
static func tempo_ate_altura(posicao: Vector3, velocidade: Vector3, altura: float) -> float:
	var a := 0.5 * Trajetoria.GRAVIDADE
	var delta := velocidade.y * velocidade.y + 4.0 * a * (posicao.y - altura)
	if delta < 0.0:
		return velocidade.y / Trajetoria.GRAVIDADE
	return (velocidade.y + sqrt(delta)) / (2.0 * a)


## Erro (s) do botão apertado agora pra um toque do "tipo" ("passe",
## "levantamento" ou "cortada"). "atraso": tempo entre o botão e o contato
## (a cortada bate no alto do pulo). Positivo = cedo, negativo = tarde.
static func erro_do_botao(tipo: String, posicao: Vector3, velocidade: Vector3, atraso: float = 0.0) -> float:
	return tempo_ate_altura(posicao, velocidade, ALTURA_IDEAL[tipo]) - atraso


## Qualidade pelo erro em segundos. "escala" aumenta (> 1) ou diminui (< 1)
## as janelas, por exemplo pelos atributos do time.
static func qualidade(erro: float, escala: float = 1.0) -> Qualidade:
	var erro_absoluto := absf(erro)
	if erro_absoluto <= JANELA_PERFEITA * escala:
		return Qualidade.PERFEITO
	if erro_absoluto <= JANELA_BOA * escala:
		return Qualidade.BOM
	return Qualidade.RUIM


## Escala da janela por um atributo do time (1 a 5; 3 = normal).
static func escala_do_atributo(atributo: int) -> float:
	return 1.0 + 0.1 * float(clampi(atributo, 1, 5) - 3)


## Texto que aparece na tela.
static func nome(q: Qualidade) -> String:
	match q:
		Qualidade.PERFEITO:
			return "Perfeito!"
		Qualidade.BOM:
			return "Bom"
	return "Ruim"


## A pior das duas qualidades (o levantamento rápido precisa de passe e
## levantamento bons).
static func pior(a: Qualidade, b: Qualidade) -> Qualidade:
	return a if int(a) > int(b) else b


## Altura do levantamento pela qualidade do passe e do levantamento:
## os dois perfeitos dão o rápido; passe ruim dá o alto.
static func altura_do_levantamento(passe: Qualidade, levantamento: Qualidade) -> float:
	if passe == Qualidade.RUIM or levantamento == Qualidade.RUIM:
		return ALTURA_DO_LEVANTAMENTO_ALTO
	if passe == Qualidade.PERFEITO and levantamento == Qualidade.PERFEITO:
		return ALTURA_DO_LEVANTAMENTO_RAPIDO
	return ALTURA_DO_LEVANTAMENTO_NORMAL


## Se o ataque "nome" pode ser escolhido depois de um passe dessa qualidade.
static func ataque_liberado(passe: Qualidade, nome_do_ataque: String) -> bool:
	return ATAQUES_LIBERADOS[passe].has(nome_do_ataque)
