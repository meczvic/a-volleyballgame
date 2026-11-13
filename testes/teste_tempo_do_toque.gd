extends SceneTree
## Testes do toque no tempo certo (qualidade pelo tempo do botão).
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_tempo_do_toque.gd

const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")
const Trajetoria := preload("res://scripts/regras/trajetoria.gd")
const Q := TempoDoToque.Qualidade

var falhas := 0


func _init() -> void:
	_teste_tempo_ate_altura()
	_teste_qualidade_pelo_erro()
	_teste_aviso_de_cedo_e_tarde()
	_teste_botao_na_hora_certa_e_perfeito()
	_teste_cortada_conta_o_pulo()
	_teste_bola_que_nao_sobe_tanto()
	_teste_escala_do_atributo()
	_teste_um_toque_muda_o_proximo()

	if falhas == 0:
		print("OK: todos os testes do tempo do toque passaram.")
	else:
		print("FALHOU: %d verificação(ões) do tempo do toque." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


## Bola caindo de 4 m, parada no alto (velocidade zero).
func _bola_caindo_de(altura: float) -> Array:
	return [Vector3(0.0, altura, 3.0), Vector3.ZERO]


func _teste_tempo_ate_altura() -> void:
	# De 4 m até 0,9 m, caindo do repouso: t = sqrt(2 * 3,1 / g).
	var esperado := sqrt(2.0 * 3.1 / Trajetoria.GRAVIDADE)
	var t := TempoDoToque.tempo_ate_altura(Vector3(0, 4, 0), Vector3.ZERO, 0.9)
	_verificar(absf(t - esperado) < 0.001, "tempo até 0,9 m: %.3f (esperado %.3f)" % [t, esperado])
	# Já abaixo e descendo: negativo (passou).
	var passou := TempoDoToque.tempo_ate_altura(Vector3(0, 0.5, 0), Vector3(0, -4, 0), 0.9)
	_verificar(passou < 0.0, "bola que já passou da altura dá tempo negativo")
	# Subindo abaixo da altura: conta até descer de volta.
	var subindo := TempoDoToque.tempo_ate_altura(Vector3(0, 1.0, 0), Vector3(0, 6, 0), 2.4)
	_verificar(subindo > 6.0 / Trajetoria.GRAVIDADE, "subindo, o momento é na descida")


func _teste_qualidade_pelo_erro() -> void:
	_verificar(TempoDoToque.qualidade(0.0) == Q.PERFEITO, "erro zero é perfeito")
	_verificar(TempoDoToque.qualidade(-0.05) == Q.PERFEITO, "um pouco tarde ainda é perfeito")
	_verificar(TempoDoToque.qualidade(0.1) == Q.BOM, "0,1 s cedo é bom")
	_verificar(TempoDoToque.qualidade(-0.3) == Q.RUIM, "0,3 s tarde é ruim")


func _teste_botao_na_hora_certa_e_perfeito() -> void:
	var bola := _bola_caindo_de(4.0)
	var falta := TempoDoToque.tempo_ate_altura(bola[0], bola[1], TempoDoToque.ALTURA_IDEAL["passe"])
	# Simula a bola até o instante ideal e aperta.
	var agora := Trajetoria.posicao_em(bola[0], bola[1], falta)
	var velocidade := Vector3(0.0, -Trajetoria.GRAVIDADE * falta, 0.0)
	var erro := TempoDoToque.erro_do_botao("passe", agora, velocidade)
	_verificar(TempoDoToque.qualidade(erro) == Q.PERFEITO, "apertar na hora certa é perfeito (erro %.3f)" % erro)
	# Apertar 0,1 s antes é bom; 0,4 s antes é ruim.
	var antes := Trajetoria.posicao_em(bola[0], bola[1], falta - 0.1)
	var v_antes := Vector3(0.0, -Trajetoria.GRAVIDADE * (falta - 0.1), 0.0)
	_verificar(TempoDoToque.qualidade(TempoDoToque.erro_do_botao("passe", antes, v_antes)) == Q.BOM, "0,1 s antes é bom")
	var cedo := Trajetoria.posicao_em(bola[0], bola[1], falta - 0.4)
	var v_cedo := Vector3(0.0, -Trajetoria.GRAVIDADE * (falta - 0.4), 0.0)
	_verificar(TempoDoToque.qualidade(TempoDoToque.erro_do_botao("passe", cedo, v_cedo)) == Q.RUIM, "0,4 s antes é ruim")


func _teste_cortada_conta_o_pulo() -> void:
	# Bola a 0,3 s de chegar na altura da cortada: apertando agora com 0,3 s
	# de pulo, a mão chega junto com a bola.
	var bola := _bola_caindo_de(5.0)
	var falta := TempoDoToque.tempo_ate_altura(bola[0], bola[1], TempoDoToque.ALTURA_IDEAL["cortada"])
	var agora := Trajetoria.posicao_em(bola[0], bola[1], falta - 0.3)
	var velocidade := Vector3(0.0, -Trajetoria.GRAVIDADE * (falta - 0.3), 0.0)
	var erro := TempoDoToque.erro_do_botao("cortada", agora, velocidade, 0.3)
	_verificar(absf(erro) < 0.01, "com o pulo de 0,3 s, apertar antes é o certo (erro %.3f)" % erro)


func _teste_bola_que_nao_sobe_tanto() -> void:
	# Bola que só chega a 2 m: pro levantamento (2,4 m) o melhor é o alto dela.
	var no_alto := TempoDoToque.erro_do_botao("levantamento", Vector3(0, 2.0, 1), Vector3.ZERO)
	_verificar(TempoDoToque.qualidade(no_alto) == Q.PERFEITO, "no alto de uma bola baixa ainda dá perfeito")


func _teste_escala_do_atributo() -> void:
	_verificar(is_equal_approx(TempoDoToque.escala_do_atributo(3), 1.0), "atributo 3 é normal")
	_verificar(TempoDoToque.escala_do_atributo(5) > TempoDoToque.escala_do_atributo(1), "atributo maior dá janela maior")
	# 0,065 s: bom pra quem tem atributo 3, perfeito pra quem tem 5.
	_verificar(TempoDoToque.qualidade(0.065, TempoDoToque.escala_do_atributo(3)) == Q.BOM, "atributo 3: bom")
	_verificar(TempoDoToque.qualidade(0.065, TempoDoToque.escala_do_atributo(5)) == Q.PERFEITO, "atributo 5: perfeito")


func _teste_um_toque_muda_o_proximo() -> void:
	_verificar(TempoDoToque.ERRO_DO_PASSE[Q.PERFEITO] < TempoDoToque.ERRO_DO_PASSE[Q.BOM] \
		and TempoDoToque.ERRO_DO_PASSE[Q.BOM] < TempoDoToque.ERRO_DO_PASSE[Q.RUIM], "passe pior erra mais")
	_verificar(TempoDoToque.altura_do_levantamento(Q.PERFEITO, Q.PERFEITO) == TempoDoToque.ALTURA_DO_LEVANTAMENTO_RAPIDO,
		"passe e levantamento perfeitos dão o levantamento rápido")
	_verificar(TempoDoToque.altura_do_levantamento(Q.BOM, Q.PERFEITO) == TempoDoToque.ALTURA_DO_LEVANTAMENTO_NORMAL,
		"passe bom dá o levantamento normal")
	_verificar(TempoDoToque.altura_do_levantamento(Q.RUIM, Q.PERFEITO) == TempoDoToque.ALTURA_DO_LEVANTAMENTO_ALTO,
		"passe ruim só deixa levantar alto")
	_verificar(not TempoDoToque.ataque_liberado(Q.RUIM, "Meio"), "passe ruim não deixa levantar no meio")
	_verificar(TempoDoToque.ataque_liberado(Q.RUIM, "Ponta"), "passe ruim deixa levantar na ponta")
	_verificar(TempoDoToque.pior(Q.PERFEITO, Q.RUIM) == Q.RUIM, "a pior das duas")
	_verificar(TempoDoToque.CORTADA[Q.PERFEITO]["subida"] < TempoDoToque.CORTADA[Q.RUIM]["subida"], "cortada perfeita é mais forte")


## Toque ruim por causa do tempo diz pra que lado errou (o Volleyball Legends
## do Roblox faz isso, e tira a sensação de que foi sorte).
func _teste_aviso_de_cedo_e_tarde() -> void:
	_verificar(TempoDoToque.nome_do_ruim(0.3) == "Cedo!", "erro positivo (apertou antes) é Cedo!")
	_verificar(TempoDoToque.nome_do_ruim(-0.3) == "Tarde!", "erro negativo (apertou depois) é Tarde!")
	_verificar(TempoDoToque.nome_do_ruim(0.0) == "Ruim", "ruim por outro motivo continua Ruim")
