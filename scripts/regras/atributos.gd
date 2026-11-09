extends RefCounted
## O que cada atributo do time (1 a 5, em dados/times.json) muda no jogo.
## 3 é o normal; cada ponto acima ou abaixo muda um pouco (uns 8 a 12%).
##
## - velocidade: corrida de todos os atletas;
## - defesa: janela de tempo do passe e alcance do mergulho;
## - ataque: janela de tempo da cortada e força dela;
## - saque: erro do saque (o círculo da mira fica menor);
## - bloqueio: largura das mãos no bloqueio.

const NOMES := ["ataque", "defesa", "saque", "bloqueio", "velocidade"]


## Nota do atributo no dicionário do time (3 se não tiver).
static func nota(time: Dictionary, nome: String) -> int:
	var atributos: Dictionary = time.get("atributos", {})
	return clampi(int(atributos.get(nome, 3)), 1, 5)


## Multiplicador simples: 1 + passo por ponto acima de 3.
static func fator(time: Dictionary, nome: String, passo: float) -> float:
	return 1.0 + passo * float(nota(time, nome) - 3)


static func velocidade(time: Dictionary) -> float:
	return fator(time, "velocidade", 0.08)


## Escala da janela de tempo por tipo de toque.
static func escala_da_janela(time: Dictionary, tipo: String) -> float:
	match tipo:
		"passe":
			return fator(time, "defesa", 0.12)
		"cortada":
			return fator(time, "ataque", 0.12)
	return 1.0


## Metros a mais (ou a menos) no alcance do mergulho.
static func alcance_extra_do_mergulho(time: Dictionary) -> float:
	return 0.25 * float(nota(time, "defesa") - 3)


## Força da cortada: quanto a bola sobe a menos (m). Ataque 5 = mais reta.
static func cortada_mais_forte(time: Dictionary) -> float:
	return 0.08 * float(nota(time, "ataque") - 3)


## Erro do saque multiplicado: saque 5 erra menos.
static func erro_do_saque(time: Dictionary) -> float:
	return fator(time, "saque", -0.1)


static func largura_do_bloqueio(time: Dictionary) -> float:
	return fator(time, "bloqueio", 0.1)
