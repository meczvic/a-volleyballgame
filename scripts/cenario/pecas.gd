extends RefCounted
## Peças simples pra montar os cenários em código: caixas, cilindros, placas
## (um lado só), textos e imagens em 3D, e público instanciado (muita gente
## barata: um MultiMesh pros corpos e outro pras cabeças).
##
## Convenção das placas, textos e imagens: de frente pra +z quando o giro é 0.
## Giro PI/2 = de frente pra +x; -PI/2 = pra -x; PI = pra -z.

const Estilo := preload("res://scripts/menus/estilo.gd")

## Material fosco (ou brilhante, com aspereza baixa).
static func material(cor: Color, aspereza := 0.85, metal := 0.0) -> StandardMaterial3D:
	var novo := StandardMaterial3D.new()
	novo.albedo_color = cor
	novo.roughness = aspereza
	novo.metallic = metal
	if cor.a < 1.0:
		novo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return novo


## Material que brilha sozinho (não recebe luz): letreiros, lâmpadas, telões.
static func material_aceso(cor: Color, forca := 1.0) -> StandardMaterial3D:
	var novo := StandardMaterial3D.new()
	novo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	novo.albedo_color = Color(cor.r * forca, cor.g * forca, cor.b * forca, cor.a)
	if cor.a < 1.0:
		novo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return novo


## Luz que soma por cima do que está embaixo (manchas de sol no chão).
static func material_de_luz(cor: Color, forca: float) -> StandardMaterial3D:
	var novo := StandardMaterial3D.new()
	novo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	novo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	novo.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	novo.albedo_color = Color(cor.r, cor.g, cor.b, forca)
	novo.no_depth_test = false
	return novo


static func caixa(pai: Node3D, tamanho: Vector3, posicao: Vector3, mat: Material, sombra := false) -> MeshInstance3D:
	var malha := BoxMesh.new()
	malha.size = tamanho
	return _instancia(pai, malha, posicao, mat, sombra)


static func cilindro(pai: Node3D, raio: float, altura: float, posicao: Vector3, mat: Material,
		lados := 12, sombra := false) -> MeshInstance3D:
	var malha := CylinderMesh.new()
	malha.top_radius = raio
	malha.bottom_radius = raio
	malha.height = altura
	malha.radial_segments = lados
	malha.rings = 1
	return _instancia(pai, malha, posicao, mat, sombra)


static func esfera(pai: Node3D, raio: float, posicao: Vector3, mat: Material) -> MeshInstance3D:
	var malha := SphereMesh.new()
	malha.radius = raio
	malha.height = raio * 2.0
	malha.radial_segments = 10
	malha.rings = 6
	return _instancia(pai, malha, posicao, mat, false)


## Retângulo de um lado só, de frente pra "giro" (veja a convenção no topo).
static func placa(pai: Node3D, tamanho: Vector2, posicao: Vector3, giro: float, mat: Material) -> MeshInstance3D:
	var malha := QuadMesh.new()
	malha.size = tamanho
	var no := _instancia(pai, malha, posicao, mat, false)
	no.rotation.y = giro
	return no


## Retângulo deitado no chão (de frente pra cima).
static func no_chao(pai: Node3D, tamanho: Vector2, posicao: Vector3, mat: Material, giro := 0.0) -> MeshInstance3D:
	var malha := PlaneMesh.new()
	malha.size = tamanho
	var no := _instancia(pai, malha, posicao, mat, false)
	no.rotation.y = giro
	return no


## Texto em 3D (fonte do jogo). "altura_da_letra" em metros.
static func texto(pai: Node3D, conteudo: String, altura_da_letra: float, cor: Color, posicao: Vector3,
		giro: float, contorno := Color(0, 0, 0, 0)) -> Label3D:
	var rotulo := Label3D.new()
	rotulo.text = conteudo
	rotulo.font = Estilo.FONTE_TITULO
	rotulo.font_size = 96
	rotulo.pixel_size = altura_da_letra / 96.0
	rotulo.modulate = cor
	rotulo.double_sided = false
	rotulo.position = posicao
	rotulo.rotation.y = giro
	rotulo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if contorno.a > 0.0:
		rotulo.outline_modulate = contorno
		rotulo.outline_size = 10
	else:
		rotulo.outline_size = 0
	pai.add_child(rotulo)
	return rotulo


## Imagem (emblema, brasão) em pé, com "largura" em metros.
static func imagem(pai: Node3D, textura: Texture2D, largura: float, posicao: Vector3, giro: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = textura
	sprite.pixel_size = largura / float(maxi(textura.get_width(), 1)) if textura != null else 0.01
	sprite.double_sided = false
	sprite.shaded = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.position = posicao
	sprite.rotation.y = giro
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(sprite)
	return sprite


## Público barato: cada pessoa é um corpo (cápsula) e uma cabeça (esfera).
## "pessoas": [posição do quadril, cor da roupa, giro]. Sentada = o quadril é a
## altura do banco; em pé = o chão.
static func publico(pai: Node3D, pessoas: Array, sentadas := true) -> void:
	if pessoas.is_empty():
		return
	var corpo := CapsuleMesh.new()
	corpo.radius = 0.2
	corpo.height = 0.78 if sentadas else 1.4
	corpo.radial_segments = 8
	corpo.rings = 2
	var cabeca := SphereMesh.new()
	cabeca.radius = 0.12
	cabeca.height = 0.24
	cabeca.radial_segments = 8
	cabeca.rings = 4
	var altura_do_corpo := corpo.height / 2.0
	var altura_da_cabeca := corpo.height + 0.1
	var peles := [Color("#F1C9A5"), Color("#E0AC80"), Color("#C68B5E"), Color("#8D5A3B"), Color("#F6D7BC")]
	var cabelos := [Color("#1B1E26"), Color("#2A2320"), Color("#4A3222"), Color("#7A5A3A"), Color("#1A1A1A")]

	var corpos := _multimesh(corpo, pessoas.size())
	var cabecas := _multimesh(cabeca, pessoas.size())
	for i in pessoas.size():
		var pessoa: Array = pessoas[i]
		var base: Vector3 = pessoa[0]
		var giro: float = pessoa[2] if pessoa.size() > 2 else 0.0
		var torcao := Basis(Vector3.UP, giro)
		corpos.set_instance_transform(i, Transform3D(torcao, base + Vector3(0.0, altura_do_corpo, 0.0)))
		corpos.set_instance_color(i, pessoa[1])
		cabecas.set_instance_transform(i, Transform3D(torcao, base + Vector3(0.0, altura_da_cabeca, 0.0)))
		# Metade das cabeças "de costas" mostra o cabelo; a outra, o rosto.
		cabecas.set_instance_color(i, cabelos[i % cabelos.size()] if i % 3 == 0 else peles[i % peles.size()])

	for multimesh in [corpos, cabecas]:
		var no := MultiMeshInstance3D.new()
		no.multimesh = multimesh
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.roughness = 0.9
		no.material_override = mat
		no.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pai.add_child(no)


static func _multimesh(malha: Mesh, quantidade: int) -> MultiMesh:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = malha
	multimesh.instance_count = quantidade
	return multimesh


static func _instancia(pai: Node3D, malha: Mesh, posicao: Vector3, mat: Material, sombra: bool) -> MeshInstance3D:
	var no := MeshInstance3D.new()
	no.mesh = malha
	no.material_override = mat
	no.position = posicao
	no.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(no)
	return no
