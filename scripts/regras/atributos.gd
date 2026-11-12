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
	# Relâmpago (Modo Caos): enquanto dura, o time corre bem mais.
	var relampago := RELAMPAGO if carga(time, "relampago") > 0.0 else 1.0
	return fator(time, "velocidade", 0.08) * modificador(time, "velocidade") * relampago


## Escala da janela de tempo por tipo de toque.
static func escala_da_janela(time: Dictionary, tipo: String) -> float:
	match tipo:
		"passe":
			return fator(time, "defesa", 0.12) * modificador(time, "janela_passe")
		"cortada":
			return fator(time, "ataque", 0.12) * modificador(time, "janela_cortada")
	return 1.0


## Metros a mais (ou a menos) no alcance do mergulho.
static func alcance_extra_do_mergulho(time: Dictionary) -> float:
	return 0.25 * float(nota(time, "defesa") - 3) + soma(time, "alcance_do_mergulho")


## Força da cortada: quanto a bola sobe a menos (m). Ataque 5 = mais reta.
static func cortada_mais_forte(time: Dictionary) -> float:
	return 0.08 * float(nota(time, "ataque") - 3) + soma(time, "forca_da_cortada")


## Erro do saque multiplicado: saque 5 erra menos.
static func erro_do_saque(time: Dictionary) -> float:
	return fator(time, "saque", -0.1) * modificador(time, "erro_do_saque")


static func largura_do_bloqueio(time: Dictionary) -> float:
	return fator(time, "bloqueio", 0.1) * modificador(time, "largura_do_bloqueio")


# --- Cartas do Modo Caos (time["modificadores"], veja scripts/regras/cartas.gd) ---

## Multiplicador de uma carta (1.0 se o time não tem nenhuma que mexa nisso).
static func modificador(time: Dictionary, chave: String) -> float:
	var mods: Dictionary = time.get("modificadores", {})
	return float(mods.get(chave, 1.0))


## Valor somado das cartas (0.0 se não tem).
static func soma(time: Dictionary, chave: String) -> float:
	var mods: Dictionary = time.get("modificadores", {})
	return float(mods.get(chave, 0.0))


## Quanto o atleta fica no chão depois de um mergulho (1.0 = o normal).
static func escala_do_tempo_no_chao(time: Dictionary) -> float:
	return modificador(time, "tempo_no_chao")


## Carta (que soma) na mão do time?
static func tem(time: Dictionary, chave: String) -> bool:
	return soma(time, chave) > 0.0


## Quanto o Relâmpago acelera o time.
const RELAMPAGO := 1.5


## Cartas com carga (usos ou segundos que sobram), em time["cargas"].
static func carga(time: Dictionary, chave: String) -> float:
	var cargas: Dictionary = time.get("cargas", {})
	return float(cargas.get(chave, 0.0))


static func mudar_carga(time: Dictionary, chave: String, valor: float) -> void:
	if not time.has("cargas"):
		time["cargas"] = {}
	time["cargas"][chave] = maxf(valor, 0.0)


## Gasta um uso. Devolve false se não tinha.
static func gastar_carga(time: Dictionary, chave: String) -> bool:
	var agora := carga(time, chave)
	if agora < 1.0:
		return false
	mudar_carga(time, chave, agora - 1.0)
	return true


## Levantador Preciso: todo levantamento sai perfeito.
static func levantamento_perfeito(time: Dictionary) -> bool:
	return soma(time, "levantamento_perfeito") > 0.0


## Ataque Rápido: todo levantamento sai rápido.
static func levantamento_rapido(time: Dictionary) -> bool:
	return soma(time, "levantamento_rapido") > 0.0
