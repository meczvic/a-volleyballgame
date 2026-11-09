extends SceneTree
## Testes da mira do saque e da cortada.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_mira.gd

const Mira := preload("res://scripts/regras/mira.gd")

var falhas := 0


func _init() -> void:
	_teste_forca_enche_e_esvazia()
	_teste_alvo_anda_e_fica_na_quadra()
	_teste_mais_forca_mais_risco()
	_teste_cortada_pela_direcao()
	_teste_erro_fica_no_raio()

	if falhas == 0:
		print("OK: todos os testes da mira passaram.")
	else:
		print("FALHOU: %d verificação(ões) da mira." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _teste_forca_enche_e_esvazia() -> void:
	var t := Mira.TEMPO_DA_CARGA
	_verificar(is_zero_approx(Mira.forca(0.0)), "começa sem força")
	_verificar(is_equal_approx(Mira.forca(t / 2.0), 0.5), "metade do tempo, metade da força")
	_verificar(is_equal_approx(Mira.forca(t), 1.0), "cheia no tempo da carga")
	_verificar(is_equal_approx(Mira.forca(t * 1.5), 0.5), "depois esvazia")
	_verificar(is_zero_approx(Mira.forca(t * 2.0)), "e volta a zero")


func _teste_alvo_anda_e_fica_na_quadra() -> void:
	# Quadra do alvo no lado z negativo: apertar "pra cima" (z negativo) leva pro fundo.
	var alvo := Mira.mover_alvo(Mira.ALVO_INICIAL, Vector2(0.0, -1.0), -1.0, 0.25)
	_verificar(alvo.y > Mira.ALVO_INICIAL.y, "pra frente, o alvo vai pro fundo")
	var longe := Mira.ALVO_INICIAL
	for _i in 100:
		longe = Mira.mover_alvo(longe, Vector2(1.0, 1.0), -1.0, 0.1)
	_verificar(longe.x <= Mira.LARGURA / 2.0 and longe.y >= Mira.DISTANCIA_MINIMA_DA_REDE, "o alvo não sai da quadra: %s" % longe)


func _teste_mais_forca_mais_risco() -> void:
	_verificar(Mira.altura_do_saque(1.0, false) < Mira.altura_do_saque(0.2, false), "saque forte vem mais baixo")
	_verificar(Mira.altura_do_saque(0.5, true) < Mira.altura_do_saque(0.5, false), "flutuante vem mais baixo")
	_verificar(Mira.erro_do_saque(0.9) > Mira.erro_do_saque(0.2), "mais força, mais erro")
	_verificar(Mira.erro_do_saque(1.0) > Mira.erro_do_saque(0.9) + 0.5, "no talo, o erro salta")


func _teste_cortada_pela_direcao() -> void:
	# Time de baixo (z positivo) atacando a quadra de z negativo.
	var meio := Mira.alvo_da_cortada(Vector2.ZERO, -1.0)
	var esquerda := Mira.alvo_da_cortada(Vector2(-1.0, 0.0), -1.0)
	var funda := Mira.alvo_da_cortada(Vector2(0.0, -1.0), -1.0)
	var curta := Mira.alvo_da_cortada(Vector2(0.0, 1.0), -1.0)
	_verificar(esquerda.x < meio.x, "esquerda mira na esquerda")
	_verificar(funda.y > meio.y and curta.y < meio.y, "pra frente é funda, pra trás é curta")
	# O outro time (atacando z positivo): pra frente dele é z positivo.
	_verificar(Mira.alvo_da_cortada(Vector2(0.0, 1.0), 1.0).y > meio.y, "vale pro outro lado também")


func _teste_erro_fica_no_raio() -> void:
	for sorteio in [Vector2(0.1, 1.0), Vector2(0.7, 0.3), Vector2(0.0, 0.0)]:
		var ponto := Mira.com_erro(Vector2(1.0, 5.0), 1.5, sorteio)
		_verificar(ponto.distance_to(Vector2(1.0, 5.0)) <= 1.5 + 0.001, "erro dentro do raio")
