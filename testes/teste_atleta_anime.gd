extends SceneTree
## Confere o atleta no estilo anime (gerador_de_atleta.gd):
## - normais da malha viradas pra fora (senão a luz inverte e o contorno some);
## - rosto desenhado pelo shader do rosto, sem projetar sombra;
## - cabelo em mechas largas, sem sombra no rosto;
## - número na cor que mais contrasta com a camisa;
## - todos os 42 atletas montam sem erro e com cabelo.
##
##   godot --headless --path . --script res://testes/teste_atleta_anime.gd

const Gerador := preload("res://scripts/visual/gerador_de_atleta.gd")
const Dados := preload("res://scripts/comum/dados.gd")

var _falhas := 0


func _initialize() -> void:
	var ap := {"altura": 1.63, "porte": "magro", "pele": "clara_quente", "formato_dos_olhos": "grandes", "expressao": "sorrindo", "cabelo": {"cor": "#F07E2A", "estilo": "espetado"}}
	var atleta := Gerador.criar(ap, {"cores": ["#1F1F24", "#F28C28", "#FFFFFF"], "numero": 10})
	var esqueleto: Skeleton3D = atleta.get_node("GeneralSkeleton")
	var malhas := {}
	for filho in esqueleto.get_children():
		if filho is MeshInstance3D:
			malhas[str(filho.name)] = filho

	# Normais pra fora: na camisa, a normal aponta pra longe do eixo do corpo.
	var camisa: MeshInstance3D = malhas.get("camisa")
	_conferir(camisa != null, "tem camisa")
	if camisa:
		var arr := camisa.mesh.surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var fora := 0
		for k in v.size():
			if n[k].dot(Vector3(v[k].x, 0, v[k].z)) > 0.0:
				fora += 1
		_conferir(fora > v.size() * 0.9, "normais da camisa pra fora (%d de %d)" % [fora, v.size()])

	# Rosto desenhado pelo shader.
	var rosto: MeshInstance3D = malhas.get("rosto")
	_conferir(rosto != null, "tem máscara do rosto")
	if rosto:
		var mat := rosto.mesh.surface_get_material(0) as ShaderMaterial
		_conferir(mat != null and mat.shader.resource_path.ends_with("rosto.gdshader"), "rosto usa shaders/rosto.gdshader")
		_conferir(mat != null and float(mat.get_shader_parameter("sorriso")) > 0.7, "expressão sorrindo vira sorriso aberto")
		_conferir(rosto.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "rosto não projeta sombra")
	_conferir(not malhas.has("olho_branco"), "olhos antigos (discos) não existem mais")

	# Cabelo: mechas e sem sombra no rosto.
	var cabelo: MeshInstance3D = malhas.get("cabelo")
	_conferir(cabelo != null and cabelo.mesh.surface_get_array_len(0) > 800, "cabelo espetado tem as mechas")
	_conferir(cabelo != null and cabelo.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "cabelo não projeta sombra no rosto")

	# Contorno com largura mínima em pixels (aparece de longe).
	var pele_mat := (malhas["pele"] as MeshInstance3D).mesh.surface_get_material(0) as ShaderMaterial
	_conferir(pele_mat.shader.resource_path.ends_with("atleta.gdshader"), "pele usa shaders/atleta.gdshader")
	_conferir(pele_mat.next_pass != null and float(pele_mat.next_pass.get_shader_parameter("largura_minima_px")) >= 1.0, "contorno com largura mínima em pixels")

	# Número: branco na camisa preta (Karasuno), azul-marinho na branca (Aoba Johsai).
	var num := (malhas["numero"] as MeshInstance3D).mesh.surface_get_material(0) as StandardMaterial3D
	_conferir(num.albedo_color.is_equal_approx(Color("#FFFFFF")), "número branco na camisa preta")
	_conferir(Gerador._cor_do_numero({}, ["#F2F4F3", "#2E9E93", "#1E3A5C"]).is_equal_approx(Color("#1E3A5C")), "número escuro na camisa branca")
	atleta.free()

	# Os 42: todos montam, com cabelo (menos o raspado, que é só a base) e rosto.
	var total := 0
	for time in Dados.times():
		for dados_atleta in Dados.elenco(str(time["id"])):
			var p := Dados.carregar_personagem(time, dados_atleta)
			if p == null:
				_conferir(false, "atleta %s/%s monta" % [time["id"], dados_atleta["arquivo"]])
				continue
			var esq := p.get_node_or_null("GeneralSkeleton")
			# Quem já tem .vrm do VRoid usa as malhas do VRoid (Face, Hair).
			var nomes := ["Face", "Hair", "Hair"] if Dados.fonte_do_personagem(str(time["id"]), dados_atleta) == "vrm" else ["rosto", "cabelo", "cabelo2"]
			var tem_rosto := esq != null and esq.get_node_or_null(nomes[0]) != null
			var tem_cabelo := esq != null and (esq.get_node_or_null(nomes[1]) != null or esq.get_node_or_null(nomes[2]) != null)
			# Cabeça raspada no VRoid não gera malha de cabelo: o cabelo vai pintado no couro.
			if not tem_cabelo and nomes[0] == "Face" and _cabelo_raspado(str(time["id"]), dados_atleta):
				tem_cabelo = true
			_conferir(tem_rosto and tem_cabelo, "atleta %s/%s tem rosto e cabelo" % [time["id"], dados_atleta["arquivo"]])
			total += 1
			p.free()
	_conferir(total == 42, "42 atletas montados (%d)" % total)

	if _falhas == 0:
		print("OK: atleta anime (normais, rosto, cabelo, contorno, número e os 42).")
	else:
		print("FALHOU: %d verificações do atleta anime." % _falhas)
	quit()


func _conferir(condicao: bool, descricao: String) -> void:
	if not condicao:
		_falhas += 1
		print("FALHOU: ", descricao)


func _cabelo_raspado(time_id: String, atleta: Dictionary) -> bool:
	var f := FileAccess.open("res://dados/aparencia.json", FileAccess.READ)
	if f == null:
		return false
	var dados: Variant = JSON.parse_string(f.get_as_text())
	if not (dados is Dictionary):
		return false
	var chave := "%02d_%s" % [int(atleta["numero"]), str(atleta["arquivo"])]
	var ap: Variant = dados.get("times", {}).get(time_id, {}).get(chave, {})
	if not (ap is Dictionary):
		return false
	return str(ap.get("cabelo", {}).get("estilo", "")) in ["raspado", "moicano"]
