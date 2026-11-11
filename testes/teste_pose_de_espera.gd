extends SceneTree
## Pose de espera (Fase 06): a animação "espera" existe e repete, é a que o
## atleta toca parado em quadra, dobra os joelhos (quadril mais baixo) e deixa
## os pés no chão, em atletas baixos e altos.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_pose_de_espera.gd

const Dados := preload("res://scripts/comum/dados.gd")
const Animador := preload("res://scripts/visual/animador.gd")

var falhas := 0


func _initialize() -> void:
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	var biblioteca := Animador.biblioteca()
	_verificar(biblioteca.has_animation("espera"), "a animação espera existe")
	_verificar(biblioteca.get_animation("espera").loop_mode == Animation.LOOP_LINEAR, "a espera repete")
	_verificar(Animador.PARADO_NO_JOGO == "espera", "parado em quadra, o atleta toca a espera")

	# [time, número]: do mais baixo (1,63 m) ao mais alto (1,94 m).
	for chave in [["karasuno", 10], ["karasuno", 3], ["shiratorizawa", 1], ["nekoma", 11]]:
		await _teste_pes_no_chao(chave[0], chave[1])

	# O animador de verdade começa na espera.
	var time := Dados.por_id(Dados.times(), "karasuno")
	var personagem := Dados.carregar_personagem(time, Dados.atleta_destaque(time))
	var atleta := Node3D.new()
	root.add_child(atleta)
	atleta.add_child(personagem)
	var animador = Animador.new()
	atleta.add_child(animador)
	animador.preparar(personagem, 0.0)
	var player := personagem.get_node("AnimationPlayer") as AnimationPlayer
	_verificar(str(player.current_animation).ends_with("espera"), "o animador começa na espera (%s)" % player.current_animation)
	atleta.free()

	if falhas == 0:
		print("OK: todos os testes da pose de espera passaram.")
	else:
		print("FALHOU: %d verificação(ões) da pose de espera." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _teste_pes_no_chao(id_time: String, numero: int) -> void:
	var time := Dados.por_id(Dados.times(), id_time)
	var dados := {}
	for a in Dados.elenco(id_time):
		if int(a["numero"]) == numero:
			dados = a
	var p := Dados.carregar_personagem(time, dados)
	root.add_child(p)
	var player := p.get_node("AnimationPlayer") as AnimationPlayer
	player.add_animation_library(Animador.BIBLIOTECA, Animador.biblioteca())
	var e := p.get_node("GeneralSkeleton") as Skeleton3D
	var medidas := {}
	for nome in ["parado", "espera"]:
		player.play(Animador.BIBLIOTECA + "/" + nome)
		player.seek(0.5, true)
		player.advance(0.0)
		await process_frame
		medidas[nome] = {
			"pe": e.get_bone_global_pose(e.find_bone("LeftFoot")).origin.y,
			"dedo": e.get_bone_global_pose(e.find_bone("LeftToes")).origin.y,
			"quadril": e.get_bone_global_pose(e.find_bone("Hips")).origin.y,
		}
	var nome_do_atleta := "%s %d" % [id_time, numero]
	_verificar(absf(medidas["espera"]["pe"] - medidas["parado"]["pe"]) < 0.01, "%s: tornozelo na mesma altura" % nome_do_atleta)
	_verificar(absf(medidas["espera"]["dedo"] - medidas["parado"]["dedo"]) < 0.01, "%s: ponta do pé no chão" % nome_do_atleta)
	_verificar(medidas["espera"]["quadril"] < medidas["parado"]["quadril"] - 0.08, "%s: joelhos dobrados (quadril mais baixo)" % nome_do_atleta)
	p.free()
