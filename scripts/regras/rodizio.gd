extends RefCounted
## Rodízio: em que posição da quadra (1 a 6) cada atleta do time está.
##
## Posições, olhando pra rede:
##   4 (rede esquerda)   3 (rede meio)    2 (rede direita)
##   5 (fundo esquerda)  6 (fundo meio)   1 (fundo direita, quem saca)
##
## Quando o time ganha o saque de volta, todo mundo gira no sentido horário:
## 2 vai pra 1, 1 vai pra 6, 6 pra 5, 5 pra 4, 4 pra 3 e 3 pra 2.

## posicoes[i] = posição do atleta i. Sem escalação, o atleta i começa na posição i + 1.
var posicoes: Array[int] = [1, 2, 3, 4, 5, 6]
## Posições do começo do set, pra voltar a elas no set seguinte.
var _inicio: Array[int] = [1, 2, 3, 4, 5, 6]


## Começa com o atleta ordem[0] na posição 1, ordem[1] na posição 2, etc.
## (veja escalacao.gd). "ordem" precisa ter os índices 0 a 5, sem repetir.
func comecar_com(ordem: Array) -> void:
	var novas: Array[int] = [0, 0, 0, 0, 0, 0]
	for vaga in 6:
		var atleta: int = ordem[vaga]
		if atleta < 0 or atleta > 5 or novas[atleta] != 0:
			push_error("Escalação inválida: %s" % [ordem])
			return
		novas[atleta] = vaga + 1
	posicoes = novas
	_inicio = novas.duplicate()


## Volta pra escalação do começo (no início de cada set).
func reiniciar() -> void:
	posicoes = _inicio.duplicate()


func girar() -> void:
	for i in posicoes.size():
		posicoes[i] = 6 if posicoes[i] == 1 else posicoes[i] - 1


func posicao_de(atleta: int) -> int:
	return posicoes[atleta]


## Índice do atleta que está na "posicao" (1 a 6).
func atleta_na(posicao: int) -> int:
	return posicoes.find(posicao)


## Posições 2, 3 e 4 ficam na rede (podem bloquear e atacar de frente).
static func e_da_rede(posicao: int) -> bool:
	return posicao >= 2 and posicao <= 4
