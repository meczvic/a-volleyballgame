extends RefCounted
## Carrega os modelos gratuitos da Polyfork (assets/polyfork/, GLB, CC BY 4.0;
## veja assets/polyfork/manifesto.json) prontos pro cenário.
##
## Os GLBs da Polyfork guardam as cores nos vértices (COLOR_0) e vêm com um
## material branco: aqui cada malha ganha um material que usa a cor do vértice.
## "trocar_cores" muda cores de vértice de uma malha pelo nome dela, por exemplo
## pra pintar as bolas do carrinho como bolas de vôlei. O resultado fica
## guardado: a segunda cópia do mesmo modelo não refaz nada.
##
## O modelo volta apoiado no chão (a parte de baixo em y = 0).

const PASTA := "res://assets/polyfork/cenario/%s.glb"

## "<id>|<trocas>" -> {nome da malha: ArrayMesh pronto}
static var _malhas_prontas := {}
static var _material: StandardMaterial3D


## Uma cópia do modelo "id". "trocar_cores": {nome da malha: {"rrggbb": Color}}.
## Devolve null se o arquivo não existir.
static func modelo(id: String, trocar_cores: Dictionary = {}, sombra := true) -> Node3D:
	var caminho := PASTA % id
	if not ResourceLoader.exists(caminho):
		return null
	var cena := load(caminho) as PackedScene
	if cena == null:
		return null
	var raiz := cena.instantiate() as Node3D
	var chave := "%s|%s" % [id, str(trocar_cores)]
	if not _malhas_prontas.has(chave):
		_malhas_prontas[chave] = _preparar(raiz, trocar_cores)
	var prontas: Dictionary = _malhas_prontas[chave]
	var caixa := AABB()
	var primeira := true
	for no in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi := no as MeshInstance3D
		if prontas.has(mi.name):
			mi.mesh = prontas[mi.name]
		mi.material_override = material()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var transformada := _transformacao_ate(raiz, mi) * mi.get_aabb()
		caixa = transformada if primeira else caixa.merge(transformada)
		primeira = false
	# Apoia no chão.
	var base := Node3D.new()
	base.name = id
	base.add_child(raiz)
	raiz.position.y = -caixa.position.y
	base.set_meta("tamanho", caixa.size)
	return base


## Material que pinta com a cor de cada vértice (igual pra todos os modelos).
static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
		_material.roughness = 0.8
	return _material


## Copia as malhas com as cores trocadas (só as que têm troca).
static func _preparar(raiz: Node3D, trocar_cores: Dictionary) -> Dictionary:
	var prontas := {}
	for no in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi := no as MeshInstance3D
		if not trocar_cores.has(mi.name):
			continue
		var trocas: Dictionary = trocar_cores[mi.name]
		var nova := ArrayMesh.new()
		for s in mi.mesh.get_surface_count():
			var arrays := mi.mesh.surface_get_arrays(s)
			var cores = arrays[Mesh.ARRAY_COLOR]
			if cores != null:
				var novas := PackedColorArray(cores)
				for k in novas.size():
					var hexa := novas[k].to_html(false)
					if trocas.has(hexa):
						novas[k] = trocas[hexa]
				arrays[Mesh.ARRAY_COLOR] = novas
			nova.add_surface_from_arrays(mi.mesh.surface_get_primitive_type(s), arrays)
		prontas[mi.name] = nova
	return prontas


static func _transformacao_ate(raiz: Node3D, no: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var atual: Node = no
	while atual != null and atual != raiz:
		if atual is Node3D:
			t = (atual as Node3D).transform * t
		atual = atual.get_parent()
	return t
