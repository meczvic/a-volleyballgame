extends RefCounted
## Rodízio: em que posição da quadra (1 a 6) cada atleta do time está.
##
## Posições, olhando pra rede:
##   4 (rede esquerda)   3 (rede meio)    2 (rede direita)
##   5 (fundo esquerda)  6 (fundo meio)   1 (fundo direita, quem saca)
##
## Quando o time ganha o saque de volta, todo mundo gira no sentido horário:
## 2 vai pra 1, 1 vai pra 6, 6 pra 5, 5 pra 4, 4 pra 3 e 3 pra 2.

## posicoes[i] = posição do atleta i. O atleta i começa na posição i + 1.
var posicoes: Array[int] = [1, 2, 3, 4, 5, 6]


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
