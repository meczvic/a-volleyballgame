extends SceneTree
## Online (Fase E), sem rede de verdade: o convidado copia a foto do dono e a
## entrada pela rede vira comandos. O teste com dois Godot conectados é o
## testes/teste_online_rede.gd.
##   godot --headless --path . --script res://testes/teste_online.gd

const EntradaPelaRede := preload("res://scripts/entrada/entrada_pela_rede.gd")

var falhas := 0
var cena: PackedScene


func _initialize() -> void:
	cena = load("res://cenas/partida.tscn")
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	await _teste_convidado_copia_a_foto()
	_teste_dono_so_comeca_com_convidado()
	_teste_entrada_pela_rede()
	_teste_dono_usa_a_entrada_pela_rede()
	var rede = root.get_node("Rede")
	rede.papel = ""
	if falhas == 0:
		print("OK: todos os testes do online passaram.")
	else:
		print("FALHOU: %d verificação(ões) do online." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _nova_partida() -> Node:
	root.get_node("Configuracao").modo = "rapida"
	root.get_node("Configuracao").semente = 5
	var partida = cena.instantiate()
	root.add_child(partida)
	return partida


func _fechar(partida: Node) -> void:
	root.remove_child(partida)
	partida.free()


func _teste_convidado_copia_a_foto() -> void:
	var rede = root.get_node("Rede")
	# O "dono" aqui é uma partida comum: só serve pra tirar a foto.
	rede.papel = ""
	var dono = _nova_partida()
	dono.atletas[0][2].position = Vector3(2.0, 0.0, 5.0)
	dono.bola.position = Vector3(-1.0, 3.0, -2.0)
	dono.placar.pontos[0] = 4
	dono.placar.pontos[1] = 7
	# Saque do time 2 carregando: mira e barra de força que o convidado precisa ver.
	dono.hud["mira"][1] = [Vector3(1.0, 0.0, 6.0), 0.8, true]
	dono.hud["forca"][1] = [0.9, true]
	dono.hud["anel"][0] = [Vector3(0.0, 0.0, 4.0), 0.2]
	var foto: Dictionary = dono.online.foto()
	_fechar(dono)

	rede.papel = "convidado"
	var convidado = _nova_partida()
	_verificar(not convidado.is_physics_processing(), "o convidado não simula a partida")
	_verificar(not convidado.bola.is_physics_processing(), "o convidado não simula a bola")
	_verificar(convidado.get_node_or_null("EnvioDoConvidado") != null, "o convidado manda os botões pro dono")
	_verificar(convidado.time_da_camera == 1, "o convidado vê pelo lado do time 2")
	convidado.online.aplicar_foto(foto)
	_verificar(convidado.miras[1].visible and convidado.miras[1].position.is_equal_approx(Vector3(1.0, 0.04, 6.0)), "o convidado vê a mira do saque")
	_verificar(convidado.interface.barras_de_forca[1].visible, "o convidado vê a barra de força")
	_verificar(convidado.aneis_de_tempo[0].visible, "o convidado vê o anel de tempo")
	_verificar(not convidado.miras[0].visible and not convidado.interface.barras_de_forca[0].visible, "o que o dono escondeu fica escondido")
	_verificar(convidado.atletas[0][2].position.is_equal_approx(Vector3(2.0, 0.0, 5.0)), "o atleta vai pra onde o dono mandou")
	_verificar(convidado.bola.position.is_equal_approx(Vector3(-1.0, 3.0, -2.0)), "a bola vai pra onde o dono mandou")
	_verificar(convidado.placar.pontos == [4, 7], "o placar copia o do dono (%s)" % [convidado.placar.pontos])
	convidado.online.aplicar_evento("mensagem", ["Teste!", 0, true])
	_verificar(convidado.interface.rotulos_do_time[0].text == "Teste!", "a mensagem do dono aparece")
	convidado.online.aplicar_evento("som", ["cortada", 1.0])
	_verificar(convidado.sons.historico.has("cortada"), "o som do dono toca")
	await process_frame
	_fechar(convidado)
	rede.papel = ""


## O dono só começa a partida (modo, times e estádio escolhidos) se tem alguém conectado.
func _teste_dono_so_comeca_com_convidado() -> void:
	var rede = root.get_node("Rede")
	rede.papel = "dono"
	_verificar(not rede.comecar_partida(), "sem convidado conectado, a partida online não começa")
	rede.papel = ""

func _teste_entrada_pela_rede() -> void:
	var rede = root.get_node("Rede")
	rede.papel = "dono"
	var entrada = EntradaPelaRede.new()
	root.add_child(entrada)
	var recebidos := []
	entrada.comando.connect(func(j: int, tipo: String) -> void: recebidos.append(["aperta", j, tipo]))
	entrada.soltou.connect(func(j: int, tipo: String) -> void: recebidos.append(["solta", j, tipo]))
	rede.botao_do_convidado.emit("passe", true)
	rede.botao_do_convidado.emit("ataque", false)
	_verificar(recebidos == [["aperta", 2, "passe"], ["solta", 2, "ataque"]], "os botões do convidado viram comandos do jogador 2 (%s)" % [recebidos])
	rede.direcao_do_convidado = Vector2(1.0, 0.0)
	entrada._physics_process(0.016)
	_verificar(entrada.direcao == Vector2(1.0, 0.0), "a direção do convidado chega")
	rede.direcao_do_convidado = Vector2.ZERO
	root.remove_child(entrada)
	entrada.free()
	rede.papel = ""


func _teste_dono_usa_a_entrada_pela_rede() -> void:
	var rede = root.get_node("Rede")
	rede.papel = "dono"
	var dono = _nova_partida()
	_verificar(dono.entradas[1].get_script() == EntradaPelaRede, "no dono, o time 2 é jogado pela rede")
	_verificar(not dono.tela_dividida, "no online a tela não divide")
	_verificar(dono.time_da_camera == 0, "o dono vê pelo lado do time 1")
	_fechar(dono)
	rede.papel = ""
