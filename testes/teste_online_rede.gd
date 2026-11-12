extends SceneTree
## Online (Fase E) com rede de verdade: este Godot hospeda e abre um segundo
## Godot (ferramentas/convidado_de_teste.gd) que conecta em 127.0.0.1.
## Confere que a direção e os botões do convidado chegam no dono e que as
## fotos do dono chegam no convidado.
##   godot --headless --path . --script res://testes/teste_online_rede.gd

const PORTA := 7791
const RESULTADO := "user://teste_online_resultado.txt"
const LIMITE := 20.0

var falhas := 0


func _initialize() -> void:
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	var rede = root.get_node("Rede")
	rede.abrir_partida = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RESULTADO))
	_verificar(rede.hospedar(PORTA) == OK, "abre a porta %d" % PORTA)
	var botoes := []
	rede.botao_do_convidado.connect(func(tipo: String, apertou: bool) -> void: botoes.append([tipo, apertou]))
	var pid := OS.create_process(OS.get_executable_path(), [
		"--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://ferramentas/convidado_de_teste.gd", "--", "porta=%d" % PORTA,
	])
	_verificar(pid > 0, "abre o segundo Godot")
	var tempo := 0.0
	var conectou := false
	while tempo < LIMITE and not FileAccess.file_exists(RESULTADO):
		if root.multiplayer.get_peers().size() > 0:
			conectou = true
			rede.enviar_foto({ "q": 1, "teste": true })
		await create_timer(0.1).timeout
		tempo += 0.1
	_verificar(conectou, "o convidado conectou")
	_verificar(rede.direcao_do_convidado.x > 0.5, "a direção do convidado chegou (%s)" % rede.direcao_do_convidado)
	_verificar(botoes.has(["passe", true]) and botoes.has(["passe", false]), "o botão do convidado chegou (%s)" % [botoes])
	var resultado := FileAccess.get_file_as_string(RESULTADO)
	_verificar(resultado.begins_with("fotos "), "o convidado escreveu o resultado (%s)" % resultado)
	_verificar(resultado.begins_with("fotos ") and int(resultado.split(" ")[1]) > 0, "as fotos do dono chegaram no convidado (%s)" % resultado)
	if OS.is_process_running(pid):
		OS.kill(pid)
	rede.sair()
	if falhas == 0:
		print("OK: todos os testes do online pela rede passaram.")
	else:
		print("FALHOU: %d verificação(ões) do online pela rede." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)
