extends SceneTree
## Convidado de mentira pro testes/teste_online_rede.gd: conecta em
## 127.0.0.1, manda direção pra direita e aperta/solta "passe", conta as fotos
## que chegam e escreve "fotos N" em user://teste_online_resultado.txt.
##   godot --headless --path . --script res://ferramentas/convidado_de_teste.gd -- porta=7791

const RESULTADO := "user://teste_online_resultado.txt"


func _initialize() -> void:
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	var porta := 7777
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("porta="):
			porta = int(arg.substr(6))
	var rede = root.get_node("Rede")
	rede.abrir_partida = false
	rede.conectar("127.0.0.1", porta)
	var tempo := 0.0
	while tempo < 8.0 and root.multiplayer.get_peers().size() == 0:
		await create_timer(0.1).timeout
		tempo += 0.1
	var apertou := false
	tempo = 0.0
	while tempo < 3.0:
		rede.enviar_direcao(Vector2(1.0, 0.0))
		if not apertou and tempo > 0.5:
			rede.enviar_botao("passe", true)
			rede.enviar_botao("passe", false)
			apertou = true
		await create_timer(0.1).timeout
		tempo += 0.1
	var arquivo := FileAccess.open(RESULTADO, FileAccess.WRITE)
	arquivo.store_string("fotos %d" % rede.fotos_recebidas)
	arquivo.close()
	rede.sair()
	quit()
