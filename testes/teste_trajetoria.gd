extends SceneTree
## Testes da matemática da bola.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_trajetoria.gd

const Trajetoria := preload("res://scripts/regras/trajetoria.gd")

var falhas := 0


func _init() -> void:
	_teste_cai_no_destino()
	_teste_chega_na_altura_maxima()
	_teste_passa_por_cima_da_rede()
	_teste_nao_cruza_a_rede()

	if falhas == 0:
		print("OK: todos os testes da trajetória passaram.")
	else:
		print("FALHOU: %d verificação(ões) da trajetória." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _teste_cai_no_destino() -> void:
	var origem := Vector3(1.0, 1.0, 6.0)
	var destino := Vector3(-2.0, 0.18, -5.0)
	var velocidade := Trajetoria.velocidade_para(origem, destino, 5.0)
	var queda := Trajetoria.ponto_de_queda(origem, velocidade, destino.y)
	_verificar(queda.distance_to(destino) < 0.01, "a bola deve cair no destino (caiu em %s)" % queda)


func _teste_chega_na_altura_maxima() -> void:
	var origem := Vector3(0.0, 1.0, 3.0)
	var velocidade := Trajetoria.velocidade_para(origem, Vector3(0.0, 0.18, -4.0), 4.5)
	var tempo_do_topo := velocidade.y / Trajetoria.GRAVIDADE
	var topo := Trajetoria.posicao_em(origem, velocidade, tempo_do_topo)
	_verificar(absf(topo.y - 4.5) < 0.01, "o topo deve ser 4.5 m (foi %.2f)" % topo.y)


func _teste_passa_por_cima_da_rede() -> void:
	# Saque baixo do fundo da quadra: o topo pedido (2.5 m) não passaria a rede.
	var origem := Vector3(0.0, 2.2, 10.0)
	var destino := Vector3(0.0, 0.18, -5.0)
	var velocidade := Trajetoria.velocidade_passando_rede(origem, destino, 2.5, 2.83)
	var na_rede := Trajetoria.altura_na_rede(origem, velocidade)
	_verificar(na_rede >= 2.83, "deve passar a rede com folga (passou a %.2f m)" % na_rede)
	var queda := Trajetoria.ponto_de_queda(origem, velocidade, destino.y)
	_verificar(queda.distance_to(destino) < 0.01, "mesmo subindo, cai no destino")


func _teste_nao_cruza_a_rede() -> void:
	var origem := Vector3(0.0, 1.0, 6.0)
	var velocidade := Trajetoria.velocidade_para(origem, Vector3(1.0, 0.18, 2.0), 4.0)
	_verificar(Trajetoria.altura_na_rede(origem, velocidade) == INF, "passe do mesmo lado não cruza a rede")
