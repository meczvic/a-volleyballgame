extends SceneTree
## Confere os 42 atletas do jeito que a partida os usa: resolve o personagem
## de cada registro de dados/elenco.json (VRM ou gerado), instancia, e exige
## malha visível com pesos, esqueleto humanoide animável e trilhas das
## animações ligadas a ossos que existem. Cápsula, caminho inválido ou
## personagem parado em T (pose estática) fazem o teste falhar.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_elenco_em_quadra.gd

const Dados := preload("res://scripts/comum/dados.gd")
const Animador := preload("res://scripts/visual/animador.gd")

const OSSOS_OBRIGATORIOS := [
	"Hips", "Spine", "Chest", "Neck", "Head",
	"LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot",
]

var falhas := 0
var contagem := {"vrm": 0, "gerado": 0, "capsula": 0}


func _initialize() -> void:
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	var times := Dados.times()
	var total := 0
	for time in times:
		var elenco := Dados.elenco(str(time["id"]))
		_verificar(elenco.size() == 6, "%s tem %d atletas no elenco (precisa de 6)." % [time["id"], elenco.size()])
		for atleta in elenco:
			total += 1
			_conferir_atleta(time, atleta)
	_verificar(total == 42, "São %d registros no elenco, esperava 42." % total)
	_teste_uniforme_reserva()

	print("Personagens: %d VRM, %d gerados, %d cápsulas." % [contagem["vrm"], contagem["gerado"], contagem["capsula"]])
	if falhas == 0:
		print("OK: os 42 atletas têm personagem com malha, esqueleto e animações ligadas.")
	else:
		print("FALHOU: %d verificação(ões) do elenco em quadra." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _conferir_atleta(time: Dictionary, atleta: Dictionary) -> void:
	var id_time := str(time["id"])
	var nome := "%s/%s" % [id_time, Dados.chave_do_atleta(atleta)]
	var fonte := Dados.fonte_do_personagem(id_time, atleta)
	contagem[fonte] += 1
	if fonte == "capsula":
		_verificar(false, "%s não tem personagem (nem .vrm nem entrada em dados/aparencia.json)." % nome)
		return
	var personagem := Dados.carregar_personagem(time, atleta)
	if personagem == null:
		_verificar(false, "%s: o personagem (%s) não carregou." % [nome, fonte])
		return
	var atleta_no := Node3D.new()
	root.add_child(atleta_no)
	atleta_no.add_child(personagem)

	# Malha visível, com pesos de osso, do tamanho de uma pessoa.
	var caixa := AABB()
	var com_pesos := 0
	var malhas := personagem.find_children("*", "MeshInstance3D", true, false)
	for malha in malhas:
		var m: MeshInstance3D = malha
		if m.mesh == null or m.mesh.get_surface_count() == 0:
			continue
		var aabb := m.global_transform * m.mesh.get_aabb()
		caixa = aabb if caixa.size == Vector3.ZERO else caixa.merge(aabb)
		var arrays := m.mesh.surface_get_arrays(0)
		if arrays[Mesh.ARRAY_BONES] != null and arrays[Mesh.ARRAY_BONES].size() > 0:
			com_pesos += 1
	_verificar(malhas.size() > 0 and caixa.size.y > 1.4 and caixa.size.y < 2.3,
		"%s: malha com altura %.2f m (esperava entre 1,4 e 2,3)." % [nome, caixa.size.y])
	_verificar(com_pesos > 0, "%s: nenhuma malha tem pesos de osso (não vai animar)." % nome)
	_verificar(caixa.position.y > -0.1 and caixa.position.y < 0.15, "%s: os pés não estão no chão (y mínimo %.2f)." % [nome, caixa.position.y])

	# Esqueleto humanoide com os ossos que as animações usam.
	var esqueleto := personagem.get_node_or_null("%GeneralSkeleton") as Skeleton3D
	if esqueleto == null:
		_verificar(false, "%s: não tem o esqueleto %%GeneralSkeleton." % nome)
		_fechar(atleta_no)
		return
	for osso in OSSOS_OBRIGATORIOS:
		_verificar(esqueleto.find_bone(osso) >= 0, "%s: falta o osso %s." % [nome, osso])

	# Animador liga, e cada trilha das animações aponta pra um osso real.
	var animador = Animador.new()
	atleta_no.add_child(animador)
	_verificar(animador.preparar(personagem, PI), "%s: o animador não achou o AnimationPlayer." % nome)
	var player := personagem.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player:
		var sem_osso := {}
		for nome_animacao in player.get_animation_list():
			var animacao := player.get_animation(nome_animacao)
			for t in animacao.get_track_count():
				var caminho := animacao.track_get_path(t)
				var osso := caminho.get_concatenated_subnames()
				if not caminho.get_concatenated_names().ends_with("GeneralSkeleton"):
					continue
				if esqueleto.find_bone(osso) < 0:
					sem_osso[osso] = true
		_verificar(sem_osso.is_empty(), "%s: trilhas sem osso no esqueleto: %s." % [nome, sem_osso.keys()])

		# Pose estática falha: a corrida tem que mexer as pernas.
		var perna := esqueleto.find_bone("LeftUpperLeg")
		var repouso := esqueleto.get_bone_rest(perna).basis.get_rotation_quaternion()
		player.play(Animador.BIBLIOTECA + "/correr")
		player.seek(0.3, true)
		player.advance(0.0)
		var pose := esqueleto.get_bone_pose_rotation(perna)
		_verificar(pose.angle_to(repouso) > 0.05, "%s: a corrida não mexe a perna (pose estática)." % nome)
		# E a mão da cortada precisa subir acima da cabeça.
		var altura: float = caixa.size.y
		var mao: float = animador.altura_da_mao_na_batida()
		_verificar(mao > altura * 0.85, "%s: a mão da cortada fica em %.2f m, baixo pra %.2f m de altura." % [nome, mao, altura])
	_fechar(atleta_no)


## Mesmo time dos dois lados: o segundo usa a camisa na terceira cor.
func _teste_uniforme_reserva() -> void:
	var time := Dados.por_id(Dados.times(), "karasuno")
	var reserva := time.duplicate(true)
	var cores: Array = reserva["cores"]
	reserva["cores"] = [cores[2], cores[0], cores[1]]
	var atleta: Dictionary = Dados.elenco("karasuno")[0]
	if Dados.fonte_do_personagem("karasuno", atleta) != "gerado":
		return
	var personagem := Dados.carregar_personagem(reserva, atleta)
	var camisa := personagem.find_child("camisa", true, false) as MeshInstance3D
	_verificar(camisa != null, "uniforme reserva: não achei a malha da camisa.")
	if camisa:
		var material := camisa.mesh.surface_get_material(0) as ShaderMaterial
		var cor: Color = material.get_shader_parameter("cor")
		_verificar(cor.is_equal_approx(Color.from_string(str(cores[2]), Color.BLACK)),
			"uniforme reserva: a camisa ficou %s em vez de %s." % [cor.to_html(false), cores[2]])
	personagem.free()


func _fechar(no: Node) -> void:
	root.remove_child(no)
	no.free()
