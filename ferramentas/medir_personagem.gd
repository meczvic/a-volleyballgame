extends SceneTree
## Mede um personagem como a partida usa: altura (topo da cabeça), pra onde o
## rosto aponta depois do giro, e a altura da mão na batida da cortada.
##
##   godot --headless --path . --script res://ferramentas/medir_personagem.gd -- atleta=karasuno/10_hinata

const Dados := preload("res://scripts/comum/dados.gd")
const Animador := preload("res://scripts/visual/animador.gd")
const GIRO_DO_TIME_0 := PI


func _initialize() -> void:
	var pedido := "karasuno/10_hinata"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("atleta="):
			pedido = arg.substr(7)
	var partes := pedido.split("/")
	var time := Dados.por_id(Dados.times(), partes[0])
	var atleta := {}
	for a in Dados.elenco(partes[0]):
		if "%02d_%s" % [int(a["numero"]), str(a["arquivo"])] == partes[1]:
			atleta = a
	var personagem := Dados.carregar_personagem(time, atleta)
	if personagem == null:
		print("FALHOU: personagem não carregou")
		quit(1)
		return
	var raiz := Node3D.new()
	root.add_child(raiz)
	raiz.add_child(personagem)
	var animador := Animador.new()
	raiz.add_child(animador)
	animador.preparar(personagem, GIRO_DO_TIME_0)
	await process_frame
	var esqueleto := personagem.get_node_or_null("%GeneralSkeleton") as Skeleton3D
	if esqueleto == null:
		esqueleto = personagem.find_child("GeneralSkeleton", true, false) as Skeleton3D
	print("fonte: ", Dados.fonte_do_personagem(partes[0], atleta))
	print("escala do personagem: ", personagem.scale)
	var malhas := personagem.find_children("*", "MeshInstance3D", true, false)
	var caixa := AABB()
	var primeira := true
	for m in malhas:
		var mi := m as MeshInstance3D
		var c := mi.global_transform * mi.get_aabb()
		caixa = c if primeira else caixa.merge(c)
		primeira = false
	print("caixa (pose atual): ", caixa)
	# Altura em T (pose de descanso): cabeça + topo
	esqueleto.reset_bone_poses()
	var cabeca := esqueleto.find_bone("Head")
	var pe := esqueleto.find_bone("LeftFoot")
	print("osso Head y (descanso): %.3f" % (esqueleto.global_transform * esqueleto.get_bone_global_rest(cabeca).origin).y)
	print("osso LeftFoot y (descanso): %.3f" % (esqueleto.global_transform * esqueleto.get_bone_global_rest(pe).origin).y)
	# Frente do rosto: direção do pescoço até o nariz ~ eixo +Z do osso Head no mundo.
	var base_cabeca := (esqueleto.global_transform * esqueleto.get_bone_global_rest(cabeca)).basis
	print("eixo z da cabeça no mundo (time 0): ", base_cabeca.z.normalized())
	var olho_e := esqueleto.find_bone("LeftEye")
	if olho_e >= 0:
		var olho := esqueleto.global_transform * esqueleto.get_bone_global_rest(olho_e).origin
		var cab := esqueleto.global_transform * esqueleto.get_bone_global_rest(cabeca).origin
		print("olho - cabeça (pra onde o rosto aponta, time 0 deve ser -z): ", (olho - cab))
	print("altura da mão na batida: %.3f" % animador.altura_da_mao_na_batida())
	quit()
