extends RefCounted
## Troca o sombreamento MToon dos personagens do VRoid pelo sombreamento anime
## do jogo (shaders/atleta_vrm_*.gdshader, o mesmo de atleta.gdshader).
##
## O MToon soma a luz ambiente do estádio com o sol inteiro: com a luz forte do
## ginásio a pele clara do VRoid estourava pro branco (braços, pernas e uma
## mancha no rosto). O sombreamento do jogo tem duas faixas e não estoura, e
## deixa o VRM igual aos outros atletas em qualquer estádio.
##
## Mantém a textura, a cor e a transparência de cada peça do VRoid e o contorno
## do MToon (next_pass). O nome do material continua o mesmo do VRoid
## ("..._Tops_...", "..._SKIN"), que é como UniformeVrm acha cada peça.
##
## Uso (Dados.carregar_personagem já chama): VisualVrm.aplicar(personagem)

const SHADER_RECORTE := preload("res://shaders/atleta_vrm_recorte.gdshader")
const SHADER_TRANSPARENTE := preload("res://shaders/atleta_vrm_transparente.gdshader")
const SHADER_ROSTO := preload("res://shaders/atleta_vrm_rosto.gdshader")

## Tom da sombra por tipo de peça (os mesmos do atleta gerado).
const TOM_DA_PELE := Color(0.96, 0.8, 0.8)
const TOM_DO_CABELO := Color(0.86, 0.78, 0.9)

static var _materiais := {}


static func aplicar(personagem: Node3D) -> void:
	var topo := 0.0
	for no in personagem.find_children("*", "MeshInstance3D", true, false):
		var malha := no as MeshInstance3D
		topo = maxf(topo, malha.get_aabb().end.y)
		# O rosto não projeta sombra (nem no próprio rosto), como no atleta gerado.
		if malha.name == "Face":
			malha.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for s in malha.mesh.get_surface_count():
			var original := malha.get_active_material(s) as ShaderMaterial
			if original == null or original.shader == null or not "mtoon" in original.shader.resource_path:
				continue
			malha.set_surface_override_material(s, _convertido(original))
	# Altura do topo da cabeça, em pé (a seleção, as cartas e as capturas
	# enquadram por ela; o atleta gerado também guarda essa meta).
	if topo > 0.5:
		personagem.set_meta("altura", topo)


## Material do jogo equivalente a um MToon (guardado: os atletas do mesmo
## arquivo dividem os materiais que não mudam por time).
static func _convertido(original: ShaderMaterial) -> ShaderMaterial:
	if _materiais.has(original):
		return _materiais[original]
	var transparente := "trans" in original.shader.resource_path
	var novo := ShaderMaterial.new()
	novo.shader = SHADER_TRANSPARENTE if transparente else SHADER_RECORTE
	if original.resource_name.begins_with("N00_000_00_Face_") and "_SKIN" in original.resource_name:
		novo.shader = SHADER_ROSTO
	novo.resource_name = original.resource_name
	novo.render_priority = original.render_priority
	var cor = original.get_shader_parameter("_Color")
	novo.set_shader_parameter("cor", cor if cor is Color else Color.WHITE)
	novo.set_shader_parameter("textura", original.get_shader_parameter("_MainTex"))
	var corte = original.get_shader_parameter("_Cutoff")
	var recortado := "cutout" in original.shader.resource_path
	novo.set_shader_parameter("corte", float(corte) if recortado and corte != null else 0.02)
	var nome := original.resource_name
	if "_SKIN" in nome:
		novo.set_shader_parameter("tom_da_sombra", TOM_DA_PELE)
		# Pele quase toda no claro (como o gerado); o rosto fica liso, sem a
		# faixa de sombra que as normais do rosto do VRoid fazem na boca.
		novo.set_shader_parameter("limiar", -0.25)
		if novo.shader == SHADER_ROSTO:
			novo.set_shader_parameter("limiar", -1.0)
	elif "_HAIR" in nome:
		novo.set_shader_parameter("tom_da_sombra", TOM_DO_CABELO)
	# Olhos, boca e sobrancelha: sem sombra, como o rosto do atleta gerado.
	if "_EYE" in nome or "_FACE" in nome:
		novo.set_shader_parameter("luz_da_sombra", 1.0)
		novo.set_shader_parameter("brilho_de_borda", 0.0)
	novo.next_pass = original.next_pass
	_materiais[original] = novo
	return novo
