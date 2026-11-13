extends SceneTree
## Testes da velocidade da bola por lance (gravidade maior = bola mais rápida):
## - a bola cai no mesmo lugar, só que mais cedo;
## - saque forte e cortada são mais secos que passe e levantamento;
## - o anel de tempo acompanha a gravidade da bola.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_velocidade_da_bola.gd

const Bola := preload("res://scripts/partida/bola.gd")
const Trajetoria := preload("res://scripts/regras/trajetoria.gd")
const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")
const Velocidade := preload("res://scripts/regras/velocidade_da_bola.gd")
const Ajustes := preload("res://scripts/comum/ajustes.gd")
const Q := TempoDoToque.Qualidade

var falhas := 0


func _initialize() -> void:
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	_teste_valores()
	_teste_tempo_de_voo_de_volei()
	_teste_cai_no_mesmo_lugar_mais_cedo()
	_teste_tempo_do_toque_com_gravidade()
	_teste_json_muda_a_velocidade()

	if falhas == 0:
		print("OK: todos os testes da velocidade da bola passaram.")
	else:
		print("FALHOU: %d verificação(ões) da velocidade da bola." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _teste_valores() -> void:
	Ajustes.usar_dados({})
	_verificar(Velocidade.do_saque(1.0, false) > Velocidade.do_saque(0.0, false), "saque mais forte é mais rápido")
	_verificar(Velocidade.do_saque(1.0, false) > Velocidade.do_saque(1.0, true), "saque forte é mais rápido que o flutuante")
	_verificar(Velocidade.do_saque(0.0, true) > 1.0, "até o flutuante é um pouco mais seco que o normal")
	_verificar(Velocidade.da_cortada(Q.PERFEITO, false) > Velocidade.da_cortada(Q.BOM, false), "cortada perfeita é mais rápida que a boa")
	_verificar(Velocidade.da_cortada(Q.BOM, false) > 1.0, "cortada boa é mais rápida que um arco normal")
	_verificar(Velocidade.da_cortada(Q.RUIM, false) > 1.0, "até a cortada ruim é mais seca que um arco normal")
	_verificar(Velocidade.da_cortada(Q.BOM, false) > Velocidade.da_cortada(Q.RUIM, false), "cortada boa é mais rápida que a ruim")
	_verificar(Velocidade.do_passe() > 1.0 and Velocidade.do_levantamento() > 1.0, "passe e levantamento não são câmera lenta")


## Pegava o bug de 12/11/2026: os múltiplos da gravidade iam crus pra bola
## (saque com ~1,5 m/s² levava 4 s pra cruzar a quadra). Aqui o tempo de voo
## de cada lance é medido com a conversão que a partida usa e tem que ser de
## vôlei de verdade.
func _teste_tempo_de_voo_de_volei() -> void:
	Ajustes.usar_dados({})
	var saque_forte := _tempo_de_voo(Vector3(0, 2.6, -10), Vector3(0, 0, 5), 3.2, Velocidade.gravidade(Velocidade.do_saque(1.0, false)))
	var saque_fraco := _tempo_de_voo(Vector3(0, 2.2, -10), Vector3(0, 0, 5), 5.6, Velocidade.gravidade(Velocidade.do_saque(0.0, false)))
	var cortada := _tempo_de_voo(Vector3(0, 3.2, -1), Vector3(0, 0, 5), 3.5, Velocidade.gravidade(Velocidade.da_cortada(Q.PERFEITO, false)))
	var passe := _tempo_de_voo(Vector3(0, 1.0, 5), Vector3(2, 0, 1), 3.8, Velocidade.gravidade(Velocidade.do_passe()))
	var levantamento := _tempo_de_voo(Vector3(2, 1.8, 1), Vector3(4, 0, 0.5), 4.4, Velocidade.gravidade(Velocidade.do_levantamento()))
	_verificar(saque_forte < 1.1, "saque forte cruza a quadra em menos de 1,1 s (deu %.2f s)" % saque_forte)
	_verificar(saque_fraco < 1.6, "saque fraco em menos de 1,6 s (deu %.2f s)" % saque_fraco)
	_verificar(cortada < 0.8, "cortada perfeita em menos de 0,8 s (deu %.2f s)" % cortada)
	_verificar(passe < 1.4, "passe em menos de 1,4 s (deu %.2f s)" % passe)
	_verificar(levantamento < 1.3, "levantamento em menos de 1,3 s (deu %.2f s)" % levantamento)
	_verificar(saque_forte < saque_fraco and cortada < saque_forte, "saque forte é mais rápido que o fraco e a cortada mais que o saque")
	print("  voo: saque forte %.2f s, fraco %.2f s, cortada %.2f s, passe %.2f s, levantamento %.2f s" % [saque_forte, saque_fraco, cortada, passe, levantamento])


func _tempo_de_voo(de: Vector3, para: Vector3, topo: float, gravidade: float) -> float:
	var bola = Bola.new()
	root.add_child(bola)
	bola.position = de
	bola.lancar(para, topo, gravidade)
	var t: float = Trajetoria.tempo_ate_altura(bola.position, bola.velocidade_atual(), Bola.RAIO, bola.gravidade)
	bola.queue_free()
	return t
	_verificar(Velocidade.da_cortada(Q.RUIM, true) > Velocidade.da_cortada(Q.PERFEITO, false), "a super cortada é a mais rápida")


func _teste_cai_no_mesmo_lugar_mais_cedo() -> void:
	var bola = Bola.new()
	root.add_child(bola)
	bola.position = Vector3(-2.0, 2.0, -3.0)
	var destino := Vector3(3.0, 0.0, 6.0)
	bola.lancar(destino, 4.0)
	var queda_normal: Vector3 = bola.ponto_previsto
	var voo_normal := Trajetoria.tempo_ate_altura(bola.position, bola.velocidade_atual(), Bola.RAIO)
	_verificar(is_equal_approx(bola.gravidade, Trajetoria.GRAVIDADE), "lance normal usa a gravidade normal")

	bola.position = Vector3(-2.0, 2.0, -3.0)
	bola.lancar(destino, 4.0, Trajetoria.GRAVIDADE * 1.6)
	var voo_rapido := Trajetoria.tempo_ate_altura(bola.position, bola.velocidade_atual(), Bola.RAIO, bola.gravidade)
	_verificar(bola.gravidade > Trajetoria.GRAVIDADE, "lance rápido guarda a gravidade dele")
	_verificar(bola.ponto_previsto.distance_to(queda_normal) < 0.01, "cai no mesmo lugar (%s x %s)" % [bola.ponto_previsto, queda_normal])
	_verificar(voo_rapido < voo_normal * 0.9, "e chega mais cedo (%.2f s x %.2f s)" % [voo_rapido, voo_normal])
	# A previsão acompanha a bola de verdade.
	var previsto: Vector3 = bola.posicao_daqui_a(0.3)
	var antes_y: float = bola.position.y
	for i in 18:
		bola._physics_process(1.0 / 60.0)
	_verificar(bola.position.distance_to(previsto) < 0.02, "posicao_daqui_a bate com o voo (%s x %s)" % [bola.position, previsto])
	_verificar(antes_y != bola.position.y, "a bola andou")
	# Depois de um desvio (rebote) a gravidade volta ao normal.
	bola._desviar(Vector3(0, 2, 0), Vector3(0, 1, 1))
	_verificar(is_equal_approx(bola.gravidade, Trajetoria.GRAVIDADE), "rebote volta à gravidade normal")
	bola.queue_free()


func _teste_tempo_do_toque_com_gravidade() -> void:
	var posicao := Vector3(0, 4.0, 0)
	var normal := TempoDoToque.tempo_ate_altura(posicao, Vector3.ZERO, 2.0)
	var rapida := TempoDoToque.tempo_ate_altura(posicao, Vector3.ZERO, 2.0, Trajetoria.GRAVIDADE * 2.0)
	_verificar(rapida < normal, "com gravidade maior a bola desce antes (%.2f x %.2f)" % [rapida, normal])
	_verificar(absf(rapida * sqrt(2.0) - normal) < 0.001, "o tempo cai com a raiz da gravidade")


func _teste_json_muda_a_velocidade() -> void:
	Ajustes.usar_dados({ "velocidade": { "saque_forte": 2.5 } })
	_verificar(is_equal_approx(Velocidade.do_saque(1.0, false), 2.5), "o JSON muda o saque forte")
	Ajustes.usar_dados({})
	_verificar(is_equal_approx(Velocidade.do_saque(1.0, false), Velocidade.SAQUE_FORTE), "sem a chave vale o padrão")
	Ajustes.recarregar()
