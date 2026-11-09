extends SceneTree
## Confere as animações do Mixamo em animacoes/: cada uma precisa ter sido
## convertida pro esqueleto comum (GeneralSkeleton, ossos com nome humanoide),
## que é o mesmo dos personagens do VRoid.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_animacoes.gd

const PASTA := "res://animacoes"
const OSSOS_OBRIGATORIOS := ["Hips", "Spine", "Head", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightLowerLeg"]

var falhas := 0


func _init() -> void:
	var arquivos := DirAccess.get_files_at(PASTA)
	var total := 0
	for arquivo in arquivos:
		if arquivo.get_extension() == "fbx":
			_teste_animacao(PASTA + "/" + arquivo)
			total += 1
	_verificar(total > 0, "tem pelo menos 1 animação em animacoes/")

	if falhas == 0:
		print("OK: todas as %d animações estão no esqueleto comum." % total)
	else:
		print("FALHOU: %d verificação(ões) das animações." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _teste_animacao(caminho: String) -> void:
	var cena = load(caminho)
	_verificar(cena is PackedScene, "%s importou" % caminho)
	if not cena is PackedScene:
		return
	var raiz: Node = cena.instantiate()
	var esqueleto := raiz.get_node_or_null("GeneralSkeleton") as Skeleton3D
	_verificar(esqueleto != null, "%s: esqueleto se chama GeneralSkeleton" % caminho)
	var player := raiz.get_node_or_null("AnimationPlayer") as AnimationPlayer
	_verificar(player != null and player.has_animation("mixamo_com"), "%s: tem a animação mixamo_com" % caminho)
	if player and player.has_animation("mixamo_com"):
		var animacao := player.get_animation("mixamo_com")
		var ossos := {}
		for t in animacao.get_track_count():
			ossos[animacao.track_get_path(t).get_concatenated_subnames()] = true
		for osso in OSSOS_OBRIGATORIOS:
			_verificar(ossos.has(osso), "%s: anima o osso %s" % [caminho, osso])
	raiz.free()
