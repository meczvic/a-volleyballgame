extends SceneTree
## Confere o personagem do VRoid do Hinata (personagens/karasuno/10_hinata.vrm)
## com o uniforme pintado pelo jogo (scripts/visual/uniforme_vrm.gd):
## - carrega como VRM, com o esqueleto comum e o animador;
## - altura de 1,63 m (topo da cabeça entre 1,58 e 1,68 m) e rosto pra rede;
## - camisa e short na cor principal do time, número nas costas e no peito na
##   cor que mais contrasta, faixa lateral na cor de detalhe;
## - uniforme reserva muda a cor; tênis continuam brancos;
## - todas as peças usam o sombreamento do jogo (visual_vrm.gd), não o MToon.
##
##   godot --headless --path . --script res://testes/teste_uniforme_vrm.gd

const Dados := preload("res://scripts/comum/dados.gd")
const Animador := preload("res://scripts/visual/animador.gd")
const UniformeVrm := preload("res://scripts/visual/uniforme_vrm.gd")

var _falhas := 0


func _initialize() -> void:
	var karasuno := Dados.por_id(Dados.times(), "karasuno")
	var hinata := {}
	for atleta in Dados.elenco("karasuno"):
		if str(atleta["arquivo"]) == "hinata":
			hinata = atleta
	_conferir(Dados.fonte_do_personagem("karasuno", hinata) == "vrm", "Hinata vem do .vrm")
	var personagem := Dados.carregar_personagem(karasuno, hinata)
	_conferir(personagem != null, "Hinata carrega")
	if personagem == null:
		_fim()
		return
	root.add_child(personagem)
	await process_frame
	var esqueleto := personagem.get_node_or_null("%GeneralSkeleton") as Skeleton3D
	if esqueleto == null:
		esqueleto = personagem.get_node_or_null("GeneralSkeleton") as Skeleton3D
	_conferir(esqueleto != null, "tem GeneralSkeleton")

	# Altura e rosto (pose de descanso, giro do time 0 = PI, como na partida).
	var animador := Animador.new()
	personagem.add_child(animador)
	_conferir(animador.preparar(personagem, PI), "animador liga no VRM")
	if esqueleto:
		esqueleto.reset_bone_poses()
		var topo := 0.0
		for malha in personagem.find_children("*", "MeshInstance3D", true, false):
			var caixa: AABB = (malha as MeshInstance3D).global_transform * (malha as MeshInstance3D).get_aabb()
			topo = maxf(topo, caixa.end.y)
		_conferir(topo > 1.58 and topo < 1.68, "altura do Hinata ~1,63 m (%.3f)" % topo)
		var cabeca := esqueleto.find_bone("Head")
		var olho := esqueleto.find_bone("LeftEye")
		if cabeca >= 0 and olho >= 0:
			var para_frente := esqueleto.global_transform * esqueleto.get_bone_global_rest(olho).origin - esqueleto.global_transform * esqueleto.get_bone_global_rest(cabeca).origin
			_conferir(para_frente.z < 0.0, "time 0 olha pra rede (-z)")

	# Uniforme do Karasuno: camisa preta, número branco, faixa laranja.
	var cores: Array = karasuno["cores"]
	var principal := Color(cores[0])
	var camisa := _imagem_da_peca(personagem, "_Tops_")
	var short := _imagem_da_peca(personagem, "_Bottoms_")
	_conferir(camisa != null and short != null, "camisa e short pintados")
	if camisa:
		var w := camisa.get_width()
		var h := camisa.get_height()
		var costas_meio := _uv(UniformeVrm.CAMISA_COSTAS, 0.0, UniformeVrm.NUMERO_COSTAS["y"])
		var lado_da_camisa := _uv(UniformeVrm.CAMISA_COSTAS, 0.0, 0.95)
		var cor_da_camisa := camisa.get_pixel(int(lado_da_camisa.x * w), int(lado_da_camisa.y * h))
		_conferir(_perto(cor_da_camisa, principal, 0.12) and cor_da_camisa.a > 0.5, "camisa na cor principal (%s)" % cor_da_camisa)
		var tem_numero := false
		for dy in range(-20, 21, 4):
			for dx in range(-30, 31, 3):
				var c := camisa.get_pixel(int(costas_meio.x * w) + dx, int(costas_meio.y * h) + dy)
				if _perto(c, Color.WHITE, 0.15):
					tem_numero = true
		_conferir(tem_numero, "número branco nas costas")
		var peito := _uv(UniformeVrm.CAMISA_FRENTE, 0.0, UniformeVrm.NUMERO_PEITO["y"])
		var tem_no_peito := false
		for dx in range(-12, 13, 2):
			if _perto(camisa.get_pixel(int(peito.x * w) + dx, int(peito.y * h)), Color.WHITE, 0.15):
				tem_no_peito = true
		_conferir(tem_no_peito, "número no peito")
		var faixa: Dictionary = UniformeVrm.FAIXAS_CAMISA[0]
		var pf := Vector2((faixa["u"][0] + faixa["u"][1]) / 2.0, (faixa["v"][0] + faixa["v"][1]) / 2.0)
		_conferir(_perto(camisa.get_pixel(int(pf.x * w), int(pf.y * h)), Color(cores[1]), 0.12), "faixa lateral na cor de detalhe")
	if short:
		_conferir(_perto(short.get_pixel(short.get_width() / 4, int(0.2 * short.get_height())), principal, 0.15), "short na cor principal")

	# Tênis continuam brancos (material original do VRoid).
	for malha in personagem.find_children("*", "MeshInstance3D", true, false):
		var mi := malha as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(s)
			if "_Shoes_" in mat.resource_name:
				var tex_tenis = (mat as ShaderMaterial).get_shader_parameter("textura")
				_conferir(tex_tenis is Texture2D and (tex_tenis as Texture2D).resource_path != "", "tênis sem pintura (textura do VRoid)")

	# Sombreamento do jogo em todas as peças.
	var em_mtoon := 0
	for malha in personagem.find_children("*", "MeshInstance3D", true, false):
		var mi := malha as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var sm := mi.get_active_material(s) as ShaderMaterial
			if sm and "mtoon" in sm.shader.resource_path:
				em_mtoon += 1
	_conferir(em_mtoon == 0, "nenhuma peça ficou no MToon (%d)" % em_mtoon)

	# Reserva: a camisa muda de cor.
	var reserva := Dados.com_uniforme_reserva(karasuno)
	var outro := Dados.carregar_personagem(reserva, hinata)
	var camisa_reserva := _imagem_da_peca(outro, "_Tops_")
	if camisa_reserva:
		var p := _uv(UniformeVrm.CAMISA_COSTAS, 0.0, 0.95)
		var c := camisa_reserva.get_pixel(int(p.x * camisa_reserva.get_width()), int(p.y * camisa_reserva.get_height()))
		_conferir(_perto(c, Color(reserva["cores"][0]), 0.12), "reserva com a camisa na cor do reserva (%s)" % c)
	else:
		_conferir(false, "reserva pintado")
	outro.free()
	_fim()


func _imagem_da_peca(personagem: Node3D, parte: String) -> Image:
	for malha in personagem.find_children("*", "MeshInstance3D", true, false):
		var mi := malha as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(s) as ShaderMaterial
			if mat and parte in mat.resource_name:
				var tex: Texture2D = mat.get_shader_parameter("textura")
				return tex.get_image() if tex and tex.resource_path == "" else null
	return null


func _uv(mapa: Dictionary, x: float, y: float) -> Vector2:
	return Vector2(mapa["a"] * x + mapa["b"], mapa["c"] * y + mapa["d"])


func _perto(a: Color, b: Color, tolerancia: float) -> bool:
	return absf(a.r - b.r) < tolerancia and absf(a.g - b.g) < tolerancia and absf(a.b - b.b) < tolerancia


func _fim() -> void:
	if _falhas == 0:
		print("OK: Hinata do VRoid (altura, giro, uniforme do time, número e reserva).")
	else:
		print("FALHOU: %d verificações do Hinata do VRoid." % _falhas)
	quit()


func _conferir(condicao: bool, descricao: String) -> void:
	if not condicao:
		_falhas += 1
		print("FALHOU: ", descricao)
