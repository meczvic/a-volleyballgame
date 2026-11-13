extends SceneTree
## Testes da cortada em linha reta (Trajetoria.voo_reto e Bola.lancar_reto).
## A cortada tem que sair reta ou pra baixo (sem o arco que sobe antes de
## descer), passar por cima da rede, cair onde foi mirada e chegar rápido.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_cortada_reta.gd

const Trajetoria := preload("res://scripts/regras/trajetoria.gd")
const Bola := preload("res://scripts/partida/bola.gd")
const Velocidade := preload("res://scripts/regras/velocidade_da_bola.gd")
const Qualidade := preload("res://scripts/regras/tempo_do_toque.gd").Qualidade

const RAIO := 0.18
const REDE_COM_FOLGA := 2.43 + 0.25

var falhas := 0


func _initialize() -> void:
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _rodar() -> void:
	_teste_cortadas_tipicas()
	_teste_nos_dois_lados_da_rede()
	_teste_ataque_curto_fica_no_arco()
	_teste_mais_reta_que_o_arco()
	_teste_na_bola_de_verdade()

	if falhas == 0:
		print("OK: todos os testes da cortada reta passaram.")
	else:
		print("FALHOU: %d verificação(ões) da cortada reta." % falhas)
	quit(1 if falhas > 0 else 0)


## Confere um voo reto: cai no destino, passa da rede, não sobe antes de descer.
func _conferir(nome: String, origem: Vector3, destino: Vector3, velocidade: float) -> void:
	var alvo := Vector3(destino.x, RAIO, destino.z)
	var voo := Trajetoria.voo_reto(origem, alvo, velocidade, REDE_COM_FOLGA)
	_verificar(not voo.is_empty(), "%s: tem voo reto" % nome)
	if voo.is_empty():
		return
	var v: Vector3 = voo["velocidade"]
	var g: float = voo["gravidade"]
	var queda := Trajetoria.ponto_de_queda(origem, v, RAIO, g)
	_verificar(queda.distance_to(alvo) < 0.05, "%s: cai no destino (%s x %s)" % [nome, queda, alvo])
	var na_rede := Trajetoria.altura_na_rede(origem, v, g)
	_verificar(na_rede >= REDE_COM_FOLGA - 0.01, "%s: passa por cima da rede (%.2f m)" % [nome, na_rede])
	var subida := v.y * v.y / (2.0 * g) if v.y > 0.0 else 0.0
	_verificar(subida < 0.35, "%s: não sobe antes de descer (sobe %.2f m)" % [nome, subida])
	var horizontal := Vector2(v.x, v.z).length()
	_verificar(absf(horizontal - velocidade) < 0.01, "%s: sai na velocidade pedida" % nome)
	var tempo := Trajetoria.tempo_ate_altura(origem, v, RAIO, g)
	_verificar(tempo < 0.7, "%s: chega rápido (%.2f s)" % [nome, tempo])


func _teste_cortadas_tipicas() -> void:
	# Time 0 ataca pra z negativo (a rede fica em z = 0).
	_conferir("ponta, diagonal funda", Vector3(-3.0, 3.2, 2.5), Vector3(3.0, 0.0, -7.0), Velocidade.RETA_PERFEITA)
	_conferir("meio, perto da rede", Vector3(0.0, 3.3, 1.0), Vector3(0.5, 0.0, -5.0), Velocidade.RETA_PERFEITA)
	_conferir("oposto, paralela", Vector3(3.5, 3.0, 2.0), Vector3(3.5, 0.0, -8.0), Velocidade.RETA_BOA)
	_conferir("pipe do fundo", Vector3(0.0, 3.1, 3.5), Vector3(0.0, 0.0, -8.0), Velocidade.RETA_BOA)
	_conferir("super cortada", Vector3(-2.0, 3.4, 1.5), Vector3(1.0, 0.0, -6.0), Velocidade.RETA_SUPER)


func _teste_nos_dois_lados_da_rede() -> void:
	# O time 1 ataca pra z positivo.
	_conferir("time 1, diagonal", Vector3(3.0, 3.2, -2.5), Vector3(-3.0, 0.0, 7.0), Velocidade.RETA_PERFEITA)
	_conferir("time 1, meio", Vector3(0.0, 3.3, -1.0), Vector3(-0.5, 0.0, 5.0), Velocidade.RETA_BOA)


func _teste_ataque_curto_fica_no_arco() -> void:
	# Cai quase colada na rede: não dá pra ser reta (precisa de arco, é a largada).
	var voo := Trajetoria.voo_reto(Vector3(0, 3.2, 2.0), Vector3(0, RAIO, -0.8), 22.0, REDE_COM_FOLGA)
	_verificar(voo.is_empty(), "ataque curto não vira reta (cai no arco)")
	# Bola do mesmo lado da rede: não cruza.
	_verificar(Trajetoria.voo_reto(Vector3(0, 3.2, 2.0), Vector3(0, RAIO, 6.0), 22.0, REDE_COM_FOLGA).is_empty(), "sem cruzar a rede não é reta")


## O arco de antes subia antes de descer; o reto não. Mede a diferença.
func _teste_mais_reta_que_o_arco() -> void:
	var origem := Vector3(-3.0, 3.2, 2.5)
	var alvo := Vector3(3.0, RAIO, -7.0)
	var g_antigo: float = Trajetoria.GRAVIDADE * 3.5
	var arco := Trajetoria.velocidade_passando_rede(origem, alvo, origem.y + 0.3, REDE_COM_FOLGA, g_antigo)
	var subida_do_arco: float = arco.y * arco.y / (2.0 * g_antigo) if arco.y > 0.0 else 0.0
	var reto := Trajetoria.voo_reto(origem, alvo, 22.0, REDE_COM_FOLGA)
	var v: Vector3 = reto["velocidade"]
	var g_reto: float = reto["gravidade"]
	var subida_do_reto: float = v.y * v.y / (2.0 * g_reto) if v.y > 0.0 else 0.0
	print("  cortada típica: o arco antigo sobe %.2f m antes de descer, o reto sobe %.2f m (sai a %.0f graus pra baixo)" % [
		subida_do_arco, subida_do_reto, rad_to_deg(atan2(-v.y, Vector2(v.x, v.z).length()))])
	_verificar(subida_do_reto < subida_do_arco or subida_do_arco < 0.01, "o reto sobe menos que o arco")


func _teste_na_bola_de_verdade() -> void:
	var bola = Bola.new()
	root.add_child(bola)
	bola.position = Vector3(-2.0, 3.2, 2.5)
	var destino := Vector3(2.0, 0.0, -6.5)
	_verificar(bola.lancar_reto(destino, Velocidade.da_cortada_reta(Qualidade.PERFEITO, false)), "a bola aceita o lance reto")
	_verificar(bola.retos == 1, "a bola conta o lance reto")
	_verificar(bola.ponto_previsto.distance_to(Vector3(destino.x, RAIO, destino.z)) < 0.05, "a bola prevê a queda no destino (%s)" % bola.ponto_previsto)
	# A bola anda de verdade e passa por cima da rede.
	var altura_na_rede := -1.0
	var antes_z: float = bola.position.z
	for i in 60:
		bola._physics_process(1.0 / 60.0)
		if antes_z > 0.0 and bola.position.z <= 0.0:
			altura_na_rede = bola.position.y
		antes_z = bola.position.z
	_verificar(altura_na_rede >= REDE_COM_FOLGA - 0.05, "passou por cima da rede andando (%.2f m)" % altura_na_rede)
	_verificar(Velocidade.da_cortada_reta(Qualidade.RUIM, false) == 0.0, "cortada ruim não é reta")
	_verificar(Velocidade.da_cortada_reta(Qualidade.PERFEITO, false) > Velocidade.da_cortada_reta(Qualidade.BOM, false), "perfeita é mais rápida que a boa")
	_verificar(Velocidade.da_cortada_reta(Qualidade.BOM, true) > Velocidade.da_cortada_reta(Qualidade.PERFEITO, false), "super é a mais rápida")
	bola.queue_free()
