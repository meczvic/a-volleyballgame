extends RefCounted

## Monta um atleta 3D por código: esqueleto humanoide comum (GeneralSkeleton),
## malha com pesos, rosto, cabelo e uniforme com número.
##
## Todos os 42 atletas saem da mesma base corporal. O que muda vem de
## dados/aparencia.json (altura, porte, pele, cabelo, olhos, extras) e do
## uniforme do time (dados/times.json). Assim dá pra editar um atleta só
## mexendo no JSON, sem programa de modelagem.
##
## Uso:
##   var personagem := GeradorDeAtleta.criar(aparencia, uniforme)
##   # aparencia: entrada de dados/aparencia.json
##   # uniforme: {"cores": [principal, detalhe, terceira], "numero": 10}
##
## O personagem devolvido tem a mesma forma de um .vrm importado:
##   Personagem (Node3D, olha pra +z)
##     %GeneralSkeleton (Skeleton3D, ossos com nome humanoide)
##       Corpo, Cabeca, Cabelo... (MeshInstance3D com pesos)
##     AnimationPlayer
## e funciona com scripts/visual/animador.gd sem nenhuma mudança.

const SHADER_ANIME := preload("res://shaders/anime.gdshader")
const SHADER_CONTORNO := preload("res://shaders/contorno.gdshader")
const PASTA_NUMEROS := "res://personagens/numeros"

## Altura do modelo que serviu de referência pras proporções (animações do Mixamo).
const ALTURA_BASE := 1.85
## Ossos principais, na ordem em que entram no esqueleto (pai sempre antes do filho).
const OSSOS := [
	"Hips", "Spine", "Chest", "UpperChest", "Neck", "Head",
	"LeftShoulder", "LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightShoulder", "RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "LeftToes",
	"RightUpperLeg", "RightLowerLeg", "RightFoot", "RightToes",
]
## Dedos: copiam o deslocamento do perfil humanoide do Godot (escalado).
const DEDOS := [
	"ThumbMetacarpal", "ThumbProximal", "ThumbDistal",
	"IndexProximal", "IndexIntermediate", "IndexDistal",
	"MiddleProximal", "MiddleIntermediate", "MiddleDistal",
	"RingProximal", "RingIntermediate", "RingDistal",
	"LittleProximal", "LittleIntermediate", "LittleDistal",
]

## Porte: [largura do tronco, grossura dos membros, ombros].
const PORTES := {
	"magro": [0.90, 0.88, 0.94],
	"esguio": [0.93, 0.88, 1.0],
	"atletico": [1.0, 1.0, 1.0],
	"forte": [1.10, 1.14, 1.10],
	"grande": [1.16, 1.2, 1.14],
}
const PELES := {
	"clara": "#F3DCC8", "clara_quente": "#F6E1CF", "bem_clara": "#F8E8DC",
	"bronzeada": "#E5BE9A", "morena_clara": "#D9AE88", "morena": "#B98262",
	"parda": "#9C6B4E", "negra": "#6E4A33",
}
const COR_CONTORNO := Color(0.08, 0.07, 0.1)

static var _perfil: SkeletonProfileHumanoid


# --- Entrada principal -------------------------------------------------------

## Cria o personagem. "aparencia" vem de dados/aparencia.json e "uniforme" tem
## "cores" ([principal, detalhe, terceira]) e "numero".
static func criar(aparencia: Dictionary, uniforme: Dictionary) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Personagem"
	var medidas := _medidas(aparencia)
	var esqueleto := _criar_esqueleto(medidas)
	esqueleto.name = "GeneralSkeleton"
	raiz.add_child(esqueleto)
	esqueleto.owner = raiz
	esqueleto.unique_name_in_owner = true

	var malhas := _construir_malhas(aparencia, uniforme, medidas)
	for nome in malhas:
		var instancia: MeshInstance3D = malhas[nome]
		instancia.name = nome
		esqueleto.add_child(instancia)
		instancia.owner = raiz
		instancia.skeleton = NodePath("..")
		instancia.skin = esqueleto.create_skin_from_rest_transforms()

	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	raiz.add_child(player)
	player.owner = raiz
	raiz.set_meta("altura", medidas["altura"])
	raiz.set_meta("gerado", true)
	return raiz


## Aparência padrão quando o atleta não tem entrada no JSON: só o uniforme muda.
static func aparencia_padrao() -> Dictionary:
	return {
		"altura": 1.80, "porte": "atletico", "pele": "clara",
		"cabelo": {"cor": "#2A2320", "estilo": "curto"},
		"olhos": "#4A3222", "sobrancelha": "normal", "extras": [],
	}


# --- Medidas --------------------------------------------------------------------

## Converte altura e porte em todas as medidas do corpo (metros, mundo, pose T).
static func _medidas(ap: Dictionary) -> Dictionary:
	var altura: float = float(ap.get("altura", 1.80))
	var porte: Array = PORTES.get(str(ap.get("porte", "atletico")), PORTES["atletico"])
	var h := altura
	var m := {
		"altura": altura,
		"largura": float(porte[0]),
		"membros": float(porte[1]),
		"ombros": float(porte[2]),
		"cabeca": float(ap.get("cabeca", 1.0)),
	}
	# Juntas (mundo). O personagem olha pra +z e o lado esquerdo dele é +x.
	var quadril := Vector3(0, 0.565 * h, 0)
	m["Hips"] = quadril
	m["Spine"] = quadril + Vector3(0, 0.055 * h, 0)
	m["Chest"] = m["Spine"] + Vector3(0, 0.0535 * h, -0.006 * h)
	m["UpperChest"] = m["Chest"] + Vector3(0, 0.05 * h, -0.006 * h)
	m["Neck"] = m["UpperChest"] + Vector3(0, 0.09 * h, -0.004 * h)
	m["Head"] = m["Neck"] + Vector3(0, 0.052 * h, 0.008 * h)
	var raio_cabeca: float = 0.067 * h * float(m["cabeca"])
	m["raio_cabeca"] = raio_cabeca
	m["centro_cabeca"] = m["Head"] + Vector3(0, raio_cabeca * 0.95, 0.01 * h)
	for lado: float in [1.0, -1.0]:
		var p := "Left" if lado > 0 else "Right"
		m[p + "Shoulder"] = m["UpperChest"] + Vector3(lado * 0.0247 * h, 0.0595 * h, -0.0117 * h)
		m[p + "UpperArm"] = m[p + "Shoulder"] + Vector3(lado * 0.0573 * h * m["ombros"], 0, 0)
		m[p + "LowerArm"] = m[p + "UpperArm"] + Vector3(lado * 0.1505 * h, 0, 0)
		m[p + "Hand"] = m[p + "LowerArm"] + Vector3(lado * 0.153 * h, 0, 0)
		m[p + "UpperLeg"] = quadril + Vector3(lado * 0.0444 * h * m["largura"], -0.0365 * h, -0.0086 * h)
		m[p + "LowerLeg"] = m[p + "UpperLeg"] + Vector3(0, -0.24 * h, 0.002 * h)
		m[p + "Foot"] = m[p + "LowerLeg"] + Vector3(0, -0.24 * h, 0.016 * h)
		m[p + "Toes"] = m[p + "Foot"] + Vector3(0, -0.035 * h, 0.075 * h)
	return m


static func perfil() -> SkeletonProfileHumanoid:
	if _perfil == null:
		_perfil = SkeletonProfileHumanoid.new()
	return _perfil


# --- Esqueleto ---------------------------------------------------------------

## Esqueleto com os ossos do perfil humanoide do Godot: as rotações de repouso
## são as do perfil (iguais às das animações retargetadas) e as posições vêm
## das medidas. Assim qualquer animação do jogo serve pra qualquer atleta.
static func _criar_esqueleto(m: Dictionary) -> Skeleton3D:
	var esqueleto := Skeleton3D.new()
	var p := perfil()
	var rot_global := {}
	for nome in OSSOS:
		var idx := esqueleto.add_bone(nome)
		var i_perfil := p.find_bone(nome)
		var rot_local: Basis = p.get_reference_pose(i_perfil).basis
		var pai_nome := String(p.get_bone_parent(i_perfil))
		var pos_mundo: Vector3 = m[nome]
		if pai_nome == "Root" or pai_nome == "":
			rot_global[nome] = rot_local
			esqueleto.set_bone_rest(idx, Transform3D(rot_local, pos_mundo))
		else:
			var pai_idx := esqueleto.find_bone(pai_nome)
			esqueleto.set_bone_parent(idx, pai_idx)
			var rot_pai: Basis = rot_global[pai_nome]
			rot_global[nome] = rot_pai * rot_local
			var origem_local: Vector3 = rot_pai.inverse() * (pos_mundo - m[pai_nome])
			esqueleto.set_bone_rest(idx, Transform3D(rot_local, origem_local))
	# Dedos: deslocamento do perfil, escalado pela altura.
	var escala: float = m["altura"] / ALTURA_BASE
	for lado: String in ["Left", "Right"]:
		for dedo in DEDOS:
			var nome: String = lado + str(dedo)
			var i_perfil := p.find_bone(nome)
			var ref := p.get_reference_pose(i_perfil)
			var idx := esqueleto.add_bone(nome)
			esqueleto.set_bone_parent(idx, esqueleto.find_bone(String(p.get_bone_parent(i_perfil))))
			esqueleto.set_bone_rest(idx, Transform3D(ref.basis, ref.origin * escala))
	esqueleto.reset_bone_poses()
	esqueleto.motion_scale = m["Hips"].y
	return esqueleto


# --- Malhas ---------------------------------------------------------------------

## Acumula triângulos de várias superfícies (uma por material) com pesos de osso.
class Malha:
	var superficies := {}

	func _superficie(material: String) -> Dictionary:
		if not superficies.has(material):
			superficies[material] = {
				"v": PackedVector3Array(), "n": PackedVector3Array(), "uv": PackedVector2Array(),
				"pesos": [], "i": PackedInt32Array(),
			}
		return superficies[material]

	## Acrescenta um vértice e devolve o índice dele.
	func vertice(material: String, pos: Vector3, pesos: Dictionary, uv := Vector2.ZERO, normal := Vector3.ZERO) -> int:
		var s := _superficie(material)
		s["v"].append(pos)
		s["n"].append(normal)
		s["uv"].append(uv)
		s["pesos"].append(pesos)
		return s["v"].size() - 1

	func triangulo(material: String, a: int, b: int, c: int) -> void:
		var s := _superficie(material)
		s["i"].append(a)
		s["i"].append(b)
		s["i"].append(c)

	## Pontos de uma elipse: centro + u*cos + v*sin.
	static func anel(centro: Vector3, u: Vector3, v: Vector3, n: int) -> PackedVector3Array:
		var pontos := PackedVector3Array()
		for k in n:
			var t := TAU * k / n
			pontos.append(centro + u * cos(t) + v * sin(t))
		return pontos

	## Liga anéis em sequência (todos com o mesmo número de pontos). Cada anel
	## tem "p" (pontos) e "pesos". "inicio"/"fim" fecham as pontas com um leque.
	func tubo(material: String, aneis: Array, fechar_inicio := false, fechar_fim := false) -> void:
		var n: int = aneis[0]["p"].size()
		var indices := []
		for anel in aneis:
			var linha := []
			for k in n:
				linha.append(vertice(material, anel["p"][k], anel["pesos"], Vector2(float(k) / n, 0)))
			indices.append(linha)
		# Descobre se a ordem dos pontos deixa as faces viradas pra fora; senão inverte.
		var invertido := false
		for a in aneis.size() - 1:
			var p0: Vector3 = aneis[a]["p"][0]
			var p1: Vector3 = aneis[a + 1]["p"][0]
			var p2: Vector3 = aneis[a + 1]["p"][1 % n]
			var normal := (p1 - p0).cross(p2 - p0)
			var centro := Vector3.ZERO
			for ponto in aneis[a]["p"]:
				centro += ponto
			centro /= n
			var fora := p0 - centro
			if normal.length_squared() > 1e-12 and fora.length_squared() > 1e-8:
				invertido = normal.dot(fora) > 0.0
				break
		for a in aneis.size() - 1:
			for k in n:
				var k2 := (k + 1) % n
				if invertido:
					triangulo(material, indices[a][k], indices[a + 1][k2], indices[a + 1][k])
					triangulo(material, indices[a][k], indices[a][k2], indices[a + 1][k2])
				else:
					triangulo(material, indices[a][k], indices[a + 1][k], indices[a + 1][k2])
					triangulo(material, indices[a][k], indices[a + 1][k2], indices[a][k2])
		if fechar_inicio:
			_leque(material, aneis[0], indices[0], not invertido)
		if fechar_fim:
			_leque(material, aneis[-1], indices[-1], invertido)

	func _leque(material: String, anel: Dictionary, linha: Array, invertido: bool) -> void:
		var centro := Vector3.ZERO
		for ponto in anel["p"]:
			centro += ponto
		centro /= anel["p"].size()
		var c := vertice(material, centro, anel["pesos"])
		var n: int = linha.size()
		for k in n:
			var k2 := (k + 1) % n
			if invertido:
				triangulo(material, c, linha[k2], linha[k])
			else:
				triangulo(material, c, linha[k], linha[k2])

	## Liga uma grade de linhas (anéis de cima pra baixo) em triângulos, com as
	## faces viradas pra fora do "centro". "fechado" liga o último ponto ao primeiro.
	func _grade(material: String, linhas: Array, centro: Vector3, fechado: bool) -> void:
		var s := _superficie(material)
		var seg: int = linhas[0].size()
		var invertido := false
		var meio: int = linhas.size() / 2
		if linhas.size() > 2:
			var p0: Vector3 = s["v"][linhas[meio][0]]
			var p1: Vector3 = s["v"][linhas[meio + 1][0]]
			var p2: Vector3 = s["v"][linhas[meio + 1][1 % seg]]
			invertido = (p1 - p0).cross(p2 - p0).dot(p0 - centro) > 0.0
		var colunas := seg if fechado else seg - 1
		for a in linhas.size() - 1:
			for k in colunas:
				var k2 := (k + 1) % seg
				if invertido:
					triangulo(material, linhas[a][k], linhas[a + 1][k2], linhas[a + 1][k])
					triangulo(material, linhas[a][k], linhas[a][k2], linhas[a + 1][k2])
				else:
					triangulo(material, linhas[a][k], linhas[a + 1][k], linhas[a + 1][k2])
					triangulo(material, linhas[a][k], linhas[a + 1][k2], linhas[a][k2])

	## Elipsoide. "deformar" (opcional) recebe o ponto unitário e devolve o fator de raio.
	func esfera(material: String, centro: Vector3, raios: Vector3, pesos: Dictionary, deformar: Callable = Callable(), seg := 16, aneis := 12) -> void:
		var linhas := []
		for a in aneis + 1:
			var fi := PI * a / aneis
			var linha := []
			for k in seg:
				var t := TAU * k / seg
				var unit := Vector3(sin(fi) * cos(t), cos(fi), sin(fi) * sin(t))
				var fator := 1.0
				if deformar.is_valid():
					fator = deformar.call(unit)
				linha.append(vertice(material, centro + unit * raios * fator, pesos, Vector2(float(k) / seg, float(a) / aneis)))
			linhas.append(linha)
		_grade(material, linhas, centro, true)

	## Casca esférica parcial (cabelo): do topo até a latitude "ate(azimute)".
	## "raio(unit)" dá o raio em cada ponto. Aberta embaixo, com a borda recortada.
	func casca(material: String, centro: Vector3, raio: Callable, ate: Callable, pesos: Dictionary, seg := 24, aneis := 10) -> void:
		var linhas := []
		for a in aneis + 1:
			var linha := []
			for k in seg:
				var t := TAU * k / seg
				var fi: float = ate.call(t) * a / aneis
				var unit := Vector3(sin(fi) * cos(t), cos(fi), sin(fi) * sin(t))
				linha.append(vertice(material, centro + unit * raio.call(unit, float(a) / aneis), pesos, Vector2(float(k) / seg, float(a) / aneis)))
			linhas.append(linha)
		_grade(material, linhas, centro, true)

	## Mecha de cabelo: cone achatado da base até a ponta, com uma curva no meio.
	func mecha(material: String, base: Vector3, direcao: Vector3, comprimento: float, raio: float, pesos: Dictionary, curva := Vector3.ZERO, achatar := 0.55, seg := 6) -> void:
		var d := direcao.normalized()
		var lateral := d.cross(Vector3.UP)
		if lateral.length() < 0.01:
			lateral = d.cross(Vector3.FORWARD)
		lateral = lateral.normalized()
		var normal := lateral.cross(d).normalized()
		var meio := base + d * comprimento * 0.5 + curva * 0.5
		var ponta := base + d * comprimento + curva
		var aneis := [
			{"p": anel(base, lateral * raio, normal * raio * achatar, seg), "pesos": pesos},
			{"p": anel(meio, lateral * raio * 0.75, normal * raio * achatar * 0.75, seg), "pesos": pesos},
			{"p": anel(ponta, lateral * 0.004, normal * 0.004, seg), "pesos": pesos},
		]
		tubo(material, aneis, true, true)

	## Caixa alinhada à base dada (colunas = eixos), centro e meios-tamanhos.
	func caixa(material: String, centro: Vector3, meios: Vector3, pesos: Dictionary, base := Basis.IDENTITY) -> void:
		var faces := [
			[Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1)],
			[Vector3(1, -1, -1), Vector3(-1, -1, -1), Vector3(-1, 1, -1), Vector3(1, 1, -1)],
			[Vector3(1, -1, 1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1)],
			[Vector3(-1, -1, -1), Vector3(-1, -1, 1), Vector3(-1, 1, 1), Vector3(-1, 1, -1)],
			[Vector3(-1, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, -1), Vector3(-1, 1, -1)],
			[Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, -1, 1), Vector3(-1, -1, 1)],
		]
		for face in faces:
			var ids := []
			for canto in face:
				ids.append(vertice(material, centro + base * (canto * meios), pesos))
			triangulo(material, ids[0], ids[1], ids[2])
			triangulo(material, ids[0], ids[2], ids[3])

	## Disco achatado (olho, íris): "normal" aponta pra fora do rosto.
	func disco(material: String, centro: Vector3, normal: Vector3, meios: Vector2, pesos: Dictionary, seg := 12, giro := 0.0) -> void:
		var n := normal.normalized()
		var u := n.cross(Vector3.UP)
		if u.length() < 0.01:
			u = n.cross(Vector3.RIGHT)
		u = u.normalized()
		var v := u.cross(n).normalized()
		var u2 := u.rotated(n, giro)
		var v2 := v.rotated(n, giro)
		var c := vertice(material, centro, pesos, Vector2(0.5, 0.5), n)
		var borda := []
		for k in seg:
			var t := TAU * k / seg
			borda.append(vertice(material, centro + u2 * meios.x * cos(t) + v2 * meios.y * sin(t), pesos, Vector2(0.5 + 0.5 * cos(t), 0.5 - 0.5 * sin(t)), n))
		for k in seg:
			triangulo(material, c, borda[k], borda[(k + 1) % seg])

	## Faixa curva em volta de uma elipse (número da camisa): "angulo0..1" em
	## radianos a partir de +z, "y0..1" alturas, com UV completo.
	func placa(material: String, meio_x: Callable, meio_z: Callable, centro_x: float, y0: float, y1: float, ang0: float, ang1: float, folga: float, pesos: Dictionary, colunas := 8, linhas := 4) -> void:
		var ids := []
		for l in linhas + 1:
			var y: float = lerpf(y0, y1, float(l) / linhas)
			var fila := []
			var rx: float = meio_x.call(y) + folga
			var rz: float = meio_z.call(y) + folga
			for c in colunas + 1:
				var t: float = lerpf(ang0, ang1, float(c) / colunas)
				var pos := Vector3(centro_x + rx * sin(t), y, rz * cos(t))
				var normal := Vector3(sin(t) / rx, 0, cos(t) / rz).normalized()
				fila.append(vertice(material, pos, pesos, Vector2(float(c) / colunas, 1.0 - float(l) / linhas), normal))
			ids.append(fila)
		for l in linhas:
			for c in colunas:
				triangulo(material, ids[l][c], ids[l + 1][c], ids[l + 1][c + 1])
				triangulo(material, ids[l][c], ids[l + 1][c + 1], ids[l][c + 1])

	## Vira cada superfície num MeshInstance3D com normais suaves e pesos.
	func instancias(esqueleto_nomes: Callable, materiais: Dictionary) -> Dictionary:
		var saida := {}
		for nome in superficies:
			var s: Dictionary = superficies[nome]
			var v: PackedVector3Array = s["v"]
			var indices: PackedInt32Array = s["i"]
			var normais: PackedVector3Array = s["n"]
			var contadas := PackedVector3Array()
			contadas.resize(v.size())
			for t in range(0, indices.size(), 3):
				var a := v[indices[t]]
				var b := v[indices[t + 1]]
				var c := v[indices[t + 2]]
				var n := (b - a).cross(c - a)
				contadas[indices[t]] += n
				contadas[indices[t + 1]] += n
				contadas[indices[t + 2]] += n
			for k in v.size():
				if normais[k].length_squared() < 0.0001:
					normais[k] = contadas[k].normalized() if contadas[k].length_squared() > 0.0 else Vector3.UP
			var ossos := PackedInt32Array()
			var pesos := PackedFloat32Array()
			for p in s["pesos"]:
				var pares := []
				for osso in p:
					pares.append([int(esqueleto_nomes.call(osso)), float(p[osso])])
				pares.sort_custom(func(x, y): return x[1] > y[1])
				var soma := 0.0
				for q in mini(4, pares.size()):
					soma += pares[q][1]
				for q in 4:
					if q < pares.size():
						ossos.append(pares[q][0])
						pesos.append(pares[q][1] / soma)
					else:
						ossos.append(0)
						pesos.append(0.0)
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = v
			arrays[Mesh.ARRAY_NORMAL] = normais
			arrays[Mesh.ARRAY_TEX_UV] = s["uv"]
			arrays[Mesh.ARRAY_BONES] = ossos
			arrays[Mesh.ARRAY_WEIGHTS] = pesos
			arrays[Mesh.ARRAY_INDEX] = indices
			var malha := ArrayMesh.new()
			malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			malha.surface_set_material(0, materiais[nome])
			var instancia := MeshInstance3D.new()
			instancia.mesh = malha
			saida[nome] = instancia
		return saida


## Fator pra elipse do tronco em cada altura (interpola as medidas das seções).
static func _interp(tabela: Array, y: float) -> float:
	# tabela: [[y, valor], ...] em ordem crescente de y.
	if y <= tabela[0][0]:
		return tabela[0][1]
	for k in tabela.size() - 1:
		if y <= tabela[k + 1][0]:
			var t: float = (y - tabela[k][0]) / (tabela[k + 1][0] - tabela[k][0])
			return lerpf(tabela[k][1], tabela[k + 1][1], t)
	return tabela[-1][1]


## Pesos do tronco em cada altura: mistura dos ossos vizinhos.
static func _pesos_do_tronco(m: Dictionary, y: float) -> Dictionary:
	var juntas := [["Hips", m["Hips"].y - 0.06], ["Spine", m["Spine"].y], ["Chest", m["Chest"].y], ["UpperChest", m["UpperChest"].y], ["Neck", m["Neck"].y]]
	if y <= juntas[0][1]:
		return {"Hips": 1.0}
	for k in juntas.size() - 1:
		if y <= juntas[k + 1][1]:
			var t: float = (y - juntas[k][1]) / (juntas[k + 1][1] - juntas[k][1])
			t = smoothstep(0.0, 1.0, t)
			return {juntas[k][0]: 1.0 - t, juntas[k + 1][0]: t}
	return {"Neck": 1.0}


## Constrói todas as malhas do atleta e devolve {nome: MeshInstance3D}.
static func _construir_malhas(ap: Dictionary, uniforme: Dictionary, m: Dictionary) -> Dictionary:
	var h: float = m["altura"]
	var e: float = h / ALTURA_BASE
	var larg: float = m["largura"]
	var memb: float = m["membros"]
	var malha := Malha.new()
	var cores: Array = uniforme.get("cores", ["#888888", "#FFFFFF", "#444444"])
	var cor_camisa := Color.from_string(str(cores[0]), Color.GRAY)
	var cor_detalhe := Color.from_string(str(cores[1]), Color.WHITE)
	var cor_pele := _cor_da_pele(ap)
	var cabelo: Dictionary = ap.get("cabelo", {})
	var cor_cabelo := Color.from_string(str(cabelo.get("cor", "#2A2320")), Color.BLACK)
	var cor_olhos := Color.from_string(str(ap.get("olhos", "#4A3222")), Color.BROWN)

	# Seções do tronco: altura -> meia largura (x) e meia profundidade (z).
	var y_virilha: float = m["Hips"].y - 0.085 * e
	var y_quadril: float = m["Hips"].y - 0.02 * e
	var y_cintura: float = m["Spine"].y + 0.04 * e
	var y_peito: float = m["Chest"].y + 0.07 * e
	var y_alto: float = m["UpperChest"].y + 0.075 * e
	var y_ombro: float = m["Neck"].y - 0.005 * e
	var y_pescoco: float = m["Neck"].y + 0.03 * e
	var larguras := [
		[y_virilha, 0.105 * e * larg], [y_quadril, 0.165 * e * larg], [y_cintura, 0.14 * e * larg],
		[y_peito, 0.165 * e * larg], [y_alto, 0.19 * e * larg * m["ombros"]], [y_ombro, 0.165 * e * m["ombros"]],
		[y_pescoco, 0.055 * e],
	]
	var profundidades := [
		[y_virilha, 0.085 * e * larg], [y_quadril, 0.108 * e * larg], [y_cintura, 0.095 * e * larg],
		[y_peito, 0.112 * e * larg], [y_alto, 0.115 * e * larg], [y_ombro, 0.1 * e],
		[y_pescoco, 0.055 * e],
	]
	var meio_x := func(y: float) -> float: return _interp(larguras, y)
	var meio_z := func(y: float) -> float: return _interp(profundidades, y)
	var anel_tronco := func(y: float, folga: float, n: int) -> Dictionary:
		var rx: float = meio_x.call(y) + folga
		var rz: float = meio_z.call(y) + folga
		return {"p": Malha.anel(Vector3(0, y, 0), Vector3(rx, 0, 0), Vector3(0, 0, rz), n), "pesos": _pesos_do_tronco(m, y)}

	var n := 20
	# Shorts: da virilha até a cintura (entra por baixo da camisa).
	var y_barra := y_cintura - 0.02 * e
	var shorts := [anel_tronco.call(y_virilha, 0.012 * e, n), anel_tronco.call(y_virilha + 0.03 * e, 0.014 * e, n), anel_tronco.call(y_quadril, 0.012 * e, n), anel_tronco.call(y_barra + 0.015 * e, 0.0, n)]
	malha.tubo("shorts", shorts, true, false)
	# Camisa: da barra até o pescoço.
	var camisa := [anel_tronco.call(y_barra - 0.015 * e, 0.013 * e, n), anel_tronco.call(y_barra, 0.015 * e, n), anel_tronco.call(y_cintura, 0.013 * e, n), anel_tronco.call(y_peito, 0.013 * e, n), anel_tronco.call(y_alto, 0.012 * e, n), anel_tronco.call(y_ombro, 0.008 * e, n), anel_tronco.call(y_pescoco, 0.012 * e, n)]
	malha.tubo("camisa", camisa, false, false)
	# Barra e gola em cor de detalhe.
	malha.tubo("detalhe", [anel_tronco.call(y_barra - 0.015 * e, 0.016 * e, n), anel_tronco.call(y_barra + 0.012 * e, 0.016 * e, n)], false, false)
	malha.tubo("detalhe", [anel_tronco.call(y_pescoco - 0.012 * e, 0.016 * e, n), anel_tronco.call(y_pescoco + 0.006 * e, 0.014 * e, n)], false, false)
	# Pescoço (pele) até dentro da cabeça.
	var centro_cabeca: Vector3 = m["centro_cabeca"]
	var raio_cabeca: float = m["raio_cabeca"]
	malha.tubo("pele", [
		{"p": Malha.anel(Vector3(0, y_pescoco - 0.005 * e, 0), Vector3(0.05 * e, 0, 0), Vector3(0, 0, 0.05 * e), 12), "pesos": {"Neck": 1.0}},
		{"p": Malha.anel(Vector3(0, m["Head"].y + 0.01 * e, 0.005 * e), Vector3(0.048 * e, 0, 0), Vector3(0, 0, 0.048 * e), 12), "pesos": {"Neck": 0.4, "Head": 0.6}},
		{"p": Malha.anel(centro_cabeca - Vector3(0, raio_cabeca * 0.5, 0), Vector3(0.05 * e, 0, 0), Vector3(0, 0, 0.05 * e), 12), "pesos": {"Head": 1.0}},
	], false, false)

	# Cabeça: elipsoide com queixo mais fino (estilo anime).
	var formato := str(ap.get("rosto", "oval"))
	var queixo: float = {"oval": 0.3, "redondo": 0.18, "fino": 0.42, "quadrado": 0.12}.get(formato, 0.3)
	var deformar_cabeca := func(unit: Vector3) -> float:
		var abaixo := maxf(0.0, -unit.y)
		var frente := maxf(0.0, unit.z)
		# Estreita o maxilar e puxa o queixo um pouco pra frente.
		return 1.0 - queixo * abaixo * abaixo * (1.0 - 0.4 * frente) + 0.05 * abaixo * frente
	malha.esfera("pele", centro_cabeca, Vector3(raio_cabeca * 0.95, raio_cabeca * 1.08, raio_cabeca), {"Head": 1.0}, deformar_cabeca, 20, 14)
	# Orelhas.
	for lado: float in [1.0, -1.0]:
		malha.esfera("pele", centro_cabeca + Vector3(lado * raio_cabeca * 0.93, -raio_cabeca * 0.05, 0), Vector3(0.012 * e, 0.03 * e, 0.02 * e), {"Head": 1.0}, Callable(), 8, 6)
	_rosto(malha, ap, m, cor_cabelo, cor_olhos)
	_cabelo(malha, ap, m)

	# Braços: manga (camisa) no começo, depois pele até a mão.
	for lado: float in [1.0, -1.0]:
		var p := "Left" if lado > 0 else "Right"
		var ombro: Vector3 = m[p + "UpperArm"]
		var cotovelo: Vector3 = m[p + "LowerArm"]
		var pulso: Vector3 = m[p + "Hand"]
		var eixo := Vector3(lado, 0, 0)
		var braco := func(pos: Vector3, r: float, pesos: Dictionary) -> Dictionary:
			return {"p": Malha.anel(pos, Vector3(0, r, 0), Vector3(0, 0, r), 12), "pesos": pesos}
		var r_ombro := 0.062 * e * memb
		var r_cotovelo := 0.045 * e * memb
		var r_pulso := 0.034 * e * memb
		var fim_manga := ombro + eixo * 0.09 * e
		malha.tubo("camisa", [
			braco.call(ombro - eixo * 0.03 * e, r_ombro * 1.05, {"UpperChest": 0.6, p + "UpperArm": 0.4}),
			braco.call(ombro + eixo * 0.02 * e, r_ombro * 1.08, {p + "UpperArm": 0.8, "UpperChest": 0.2}),
			braco.call(fim_manga, r_ombro * 1.02, {p + "UpperArm": 1.0}),
		], true, false)
		malha.tubo("detalhe", [braco.call(fim_manga - eixo * 0.008 * e, r_ombro * 1.06, {p + "UpperArm": 1.0}), braco.call(fim_manga + eixo * 0.012 * e, r_ombro * 1.04, {p + "UpperArm": 1.0})], false, false)
		malha.tubo("pele", [
			braco.call(fim_manga, r_ombro * 0.97, {p + "UpperArm": 1.0}),
			braco.call(cotovelo - eixo * 0.03 * e, r_cotovelo * 1.08, {p + "UpperArm": 0.8, p + "LowerArm": 0.2}),
			braco.call(cotovelo, r_cotovelo, {p + "UpperArm": 0.5, p + "LowerArm": 0.5}),
			braco.call(cotovelo + eixo * 0.05 * e, r_cotovelo * 1.08, {p + "LowerArm": 1.0}),
			braco.call(pulso - eixo * 0.01 * e, r_pulso, {p + "LowerArm": 0.6, p + "Hand": 0.4}),
		], false, true)
		# Mão: luva achatada (palma virada pra baixo).
		var mao := func(pos: Vector3, espessura: float, largura: float, pesos: Dictionary) -> Dictionary:
			return {"p": Malha.anel(pos, Vector3(0, espessura, 0), Vector3(0, 0, largura), 10), "pesos": pesos}
		malha.tubo("pele", [
			mao.call(pulso - eixo * 0.015 * e, r_pulso * 0.9, r_pulso * 0.95, {p + "LowerArm": 0.6, p + "Hand": 0.4}),
			mao.call(pulso + eixo * 0.005 * e, r_pulso * 0.95, r_pulso * 1.05, {p + "LowerArm": 0.4, p + "Hand": 0.6}),
			mao.call(pulso + eixo * 0.035 * e, 0.016 * e, 0.045 * e, {p + "Hand": 1.0}),
			mao.call(pulso + eixo * 0.075 * e, 0.014 * e, 0.046 * e, {p + "Hand": 0.7, p + "MiddleProximal": 0.3}),
			mao.call(pulso + eixo * 0.105 * e, 0.011 * e, 0.036 * e, {p + "Hand": 0.3, p + "MiddleProximal": 0.4, p + "MiddleIntermediate": 0.3}),
		], true, true)
		# Polegar: pra frente (+z).
		malha.mecha("pele", pulso + eixo * 0.03 * e + Vector3(0, 0, 0.03 * e), Vector3(lado * 0.4, 0, 1.0), 0.045 * e, 0.012 * e, {p + "Hand": 1.0}, Vector3.ZERO, 0.9)
		if "bracadeira" in ap.get("extras", []) and lado < 0:
			malha.tubo("detalhe", [braco.call(ombro + eixo * 0.035 * e, r_ombro * 1.12, {p + "UpperArm": 1.0}), braco.call(ombro + eixo * 0.065 * e, r_ombro * 1.1, {p + "UpperArm": 1.0})], false, false)

	# Pernas.
	for lado: float in [1.0, -1.0]:
		var p := "Left" if lado > 0 else "Right"
		var coxa: Vector3 = m[p + "UpperLeg"]
		var joelho: Vector3 = m[p + "LowerLeg"]
		var tornozelo: Vector3 = m[p + "Foot"]
		var dedos: Vector3 = m[p + "Toes"]
		var perna := func(pos: Vector3, r: float, pesos: Dictionary, rz := -1.0) -> Dictionary:
			return {"p": Malha.anel(pos, Vector3(r, 0, 0), Vector3(0, 0, r if rz < 0 else rz), 12), "pesos": pesos}
		var r_coxa := 0.088 * e * memb
		var r_joelho := 0.06 * e * memb
		var r_panturrilha := 0.068 * e * memb
		var r_tornozelo := 0.04 * e * memb
		var y_shorts := coxa.y - 0.17 * e
		var fim_shorts := Vector3(coxa.x, y_shorts, coxa.z + 0.004 * e)
		# Shorts por cima da coxa.
		malha.tubo("shorts", [
			perna.call(coxa + Vector3(0, 0.03 * e, 0), r_coxa * 1.1, {"Hips": 0.7, p + "UpperLeg": 0.3}),
			perna.call(coxa - Vector3(0, 0.06 * e, 0), r_coxa * 1.1, {"Hips": 0.2, p + "UpperLeg": 0.8}),
			perna.call(fim_shorts, r_coxa * 1.04, {p + "UpperLeg": 1.0}),
		], false, false)
		malha.tubo("detalhe", [perna.call(fim_shorts + Vector3(0, 0.012 * e, 0), r_coxa * 1.07, {p + "UpperLeg": 1.0}), perna.call(fim_shorts - Vector3(0, 0.004 * e, 0), r_coxa * 1.05, {p + "UpperLeg": 1.0})], false, false)
		# Coxa e joelho (pele), joelheira, panturrilha.
		var y_joelheira_alto := joelho.y + 0.06 * e
		var y_joelheira_baixo := joelho.y - 0.055 * e
		malha.tubo("pele", [
			perna.call(fim_shorts, r_coxa * 0.98, {p + "UpperLeg": 1.0}),
			perna.call(Vector3(joelho.x, y_joelheira_alto + 0.03 * e, joelho.z), r_joelho * 1.1, {p + "UpperLeg": 0.85, p + "LowerLeg": 0.15}),
			perna.call(Vector3(joelho.x, y_joelheira_alto, joelho.z), r_joelho * 1.05, {p + "UpperLeg": 0.7, p + "LowerLeg": 0.3}),
		], false, false)
		malha.tubo("joelheira", [
			perna.call(Vector3(joelho.x, y_joelheira_alto, joelho.z), r_joelho * 1.12, {p + "UpperLeg": 0.7, p + "LowerLeg": 0.3}),
			perna.call(joelho + Vector3(0, 0, 0.006 * e), r_joelho * 1.16, {p + "UpperLeg": 0.5, p + "LowerLeg": 0.5}),
			perna.call(Vector3(joelho.x, y_joelheira_baixo, joelho.z), r_joelho * 1.1, {p + "UpperLeg": 0.2, p + "LowerLeg": 0.8}),
		], false, false)
		var y_meia := tornozelo.y + 0.09 * e
		malha.tubo("pele", [
			perna.call(Vector3(joelho.x, y_joelheira_baixo, joelho.z), r_joelho * 1.0, {p + "UpperLeg": 0.2, p + "LowerLeg": 0.8}),
			perna.call(Vector3(joelho.x, joelho.y - 0.12 * e, joelho.z - 0.006 * e), r_panturrilha, {p + "LowerLeg": 1.0}),
			perna.call(Vector3(tornozelo.x, y_meia + 0.02 * e, tornozelo.z - 0.004 * e), r_tornozelo * 1.15, {p + "LowerLeg": 1.0}),
		], false, false)
		# Meia e tênis.
		malha.tubo("meia", [
			perna.call(Vector3(tornozelo.x, y_meia + 0.02 * e, tornozelo.z - 0.004 * e), r_tornozelo * 1.2, {p + "LowerLeg": 1.0}),
			perna.call(Vector3(tornozelo.x, tornozelo.y + 0.015 * e, tornozelo.z - 0.004 * e), r_tornozelo * 1.1, {p + "LowerLeg": 0.6, p + "Foot": 0.4}),
		], false, false)
		var sapato := func(pos: Vector3, rx: float, ry: float, pesos: Dictionary) -> Dictionary:
			return {"p": Malha.anel(pos, Vector3(rx, 0, 0), Vector3(0, ry, 0), 12), "pesos": pesos}
		var sola := 0.012 * e
		malha.tubo("tenis", [
			sapato.call(Vector3(tornozelo.x, tornozelo.y + 0.01 * e, tornozelo.z - 0.045 * e), r_tornozelo * 1.1, 0.03 * e, {p + "Foot": 1.0}),
			sapato.call(Vector3(tornozelo.x, (tornozelo.y + sola) * 0.5 + 0.005 * e, tornozelo.z - 0.02 * e), 0.05 * e * memb, (tornozelo.y - sola) * 0.5 + 0.012 * e, {p + "Foot": 1.0}),
			sapato.call(Vector3(tornozelo.x, (tornozelo.y + sola) * 0.5, tornozelo.z + 0.05 * e), 0.052 * e * memb, (tornozelo.y - sola) * 0.5, {p + "Foot": 0.8, p + "Toes": 0.2}),
			sapato.call(Vector3(dedos.x, dedos.y + 0.012 * e, dedos.z + 0.01 * e), 0.046 * e * memb, 0.022 * e, {p + "Foot": 0.4, p + "Toes": 0.6}),
			sapato.call(Vector3(dedos.x, dedos.y + 0.008 * e, dedos.z + 0.055 * e), 0.028 * e * memb, 0.012 * e, {p + "Toes": 1.0}),
		], true, true)
		# Sola escura.
		malha.tubo("sola", [
			sapato.call(Vector3(tornozelo.x, sola * 0.9, tornozelo.z - 0.045 * e), r_tornozelo * 1.1, sola * 0.9, {p + "Foot": 1.0}),
			sapato.call(Vector3(dedos.x, sola * 0.9, dedos.z + 0.04 * e), 0.03 * e * memb, sola * 0.9, {p + "Toes": 1.0}),
		], true, true)

	# Número: costas (grande) e peito (pequeno, à esquerda de quem veste).
	var numero := int(uniforme.get("numero", 0))
	var pesos_costas := {"Chest": 0.5, "UpperChest": 0.5}
	malha.placa("numero", meio_x, meio_z, 0.0, y_peito - 0.07 * e, y_alto + 0.03 * e, PI - 0.9, PI + 0.9, 0.018 * e, pesos_costas, 10, 4)
	malha.placa("numero", meio_x, meio_z, 0.0, y_peito + 0.0 * e, y_peito + 0.06 * e, 0.22, 0.62, 0.018 * e, pesos_costas, 4, 2)

	var materiais := {
		"pele": _material(cor_pele, 0.01 * e),
		"camisa": _material(cor_camisa, 0.012 * e),
		"detalhe": _material(cor_detalhe, 0.0),
		"shorts": _material(cor_camisa if cores.size() < 3 else Color.from_string(str(cores[0]), cor_camisa), 0.012 * e),
		"joelheira": _material(Color("#1A1A1E"), 0.0),
		"meia": _material(Color("#F2F2F2"), 0.0),
		"tenis": _material(Color("#F4F4F4"), 0.01 * e),
		"sola": _material(Color("#2A2A30"), 0.0),
		"cabelo": _material(cor_cabelo, 0.012 * e),
		"cabelo2": _material(Color.from_string(str(cabelo.get("cor2", "#1E1E1E")), Color.BLACK), 0.012 * e),
		"olho_branco": _material_chapado(Color.WHITE),
		"iris": _material_chapado(cor_olhos),
		"pupila": _material_chapado(Color(0.05, 0.03, 0.05)),
		"brilho": _material_chapado(Color.WHITE),
		"sobrancelha": _material_chapado(cor_cabelo.darkened(0.25)),
		"boca": _material_chapado(Color(0.45, 0.2, 0.2)),
		"oculos": _material(Color("#1E1E22"), 0.0),
		"faixa": _material(Color.from_string(str(ap.get("cor_da_faixa", cores[1])), cor_detalhe), 0.0),
		"numero": _material_do_numero(numero, cor_detalhe),
	}
	return malha.instancias(func(nome: String) -> int: return _indice_do_osso(nome), materiais)


static var _indices_dos_ossos := {}
static func _indice_do_osso(nome: String) -> int:
	if _indices_dos_ossos.is_empty():
		var k := 0
		for osso in OSSOS:
			_indices_dos_ossos[osso] = k
			k += 1
		for lado: String in ["Left", "Right"]:
			for dedo in DEDOS:
				_indices_dos_ossos[lado + dedo] = k
				k += 1
	return _indices_dos_ossos.get(nome, 0)


# --- Rosto -----------------------------------------------------------------------

static func _rosto(malha: Malha, ap: Dictionary, m: Dictionary, cor_cabelo: Color, _cor_olhos: Color) -> void:
	var e: float = m["altura"] / ALTURA_BASE
	var c: Vector3 = m["centro_cabeca"]
	var r: float = m["raio_cabeca"]
	var pesos := {"Head": 1.0}
	var olhos: Dictionary = ap.get("formato_dos_olhos", {}) if ap.get("formato_dos_olhos") is Dictionary else {}
	var tamanho_olho: float = float(olhos.get("tamanho", {"grandes": 1.25, "pequenos": 0.8}.get(str(ap.get("formato_dos_olhos", "")), 1.0)))
	var fechados: float = {"caidos": 0.7, "estreitos": 0.55, "normais": 1.0}.get(str(ap.get("palpebras", "normais")), 1.0)
	var inclinacao: float = {"caidos": -0.25, "bravos": 0.3}.get(str(ap.get("palpebras", "normais")), 0.0)
	for lado: float in [1.0, -1.0]:
		var x := lado * r * 0.36
		var y := c.y + r * 0.02
		# Ponto na superfície da cabeça virado pra frente.
		var unit := Vector3(x / (r * 0.95), (y - c.y) / (r * 1.08), 0)
		unit.z = sqrt(maxf(0.0, 1.0 - unit.x * unit.x - unit.y * unit.y))
		var pos := c + unit * Vector3(r * 0.95, r * 1.08, r)
		var normal := Vector3(unit.x * 0.6, unit.y * 0.3, 1.0).normalized()
		var larg := r * 0.17 * tamanho_olho
		var alt := r * 0.13 * tamanho_olho * fechados
		var giro := inclinacao * lado
		malha.disco("olho_branco", pos + normal * 0.004 * e, normal, Vector2(larg, alt), pesos, 14, giro)
		malha.disco("iris", pos + normal * 0.006 * e, normal, Vector2(larg * 0.55, alt * 0.85), pesos, 12, giro)
		malha.disco("pupila", pos + normal * 0.0075 * e, normal, Vector2(larg * 0.25, alt * 0.5), pesos, 8, giro)
		malha.disco("brilho", pos + normal * 0.009 * e + Vector3(-lado * larg * 0.2, alt * 0.35, 0), normal, Vector2(larg * 0.14, alt * 0.2), pesos, 6)
		# Sobrancelha: caixa fina acima do olho, seguindo a curva da cabeça.
		var grossura: float = {"fina": 0.5, "normal": 0.8, "grossa": 1.3}.get(str(ap.get("sobrancelha", "normal")), 0.8)
		var pos_s := pos + Vector3(0, alt + r * 0.11, 0) + normal * 0.005 * e
		var base_s := Basis(Vector3(0, 0, 1), -inclinacao * lado * 0.8)
		malha.caixa("sobrancelha", pos_s, Vector3(larg * 1.05, r * 0.025 * grossura, 0.004 * e), pesos, base_s)
		if "oculos" in ap.get("extras", []):
			var aro := Basis(Vector3(1, 0, 0), PI / 2)
			for k in 12:
				var t0 := TAU * k / 12
				var t1 := TAU * (k + 1) / 12
				var p0 := pos + normal * 0.012 * e + Vector3(cos(t0) * larg * 1.25, sin(t0) * alt * 1.6, 0)
				var p1 := pos + normal * 0.012 * e + Vector3(cos(t1) * larg * 1.25, sin(t1) * alt * 1.6, 0)
				malha.caixa("oculos", (p0 + p1) * 0.5, Vector3((p1 - p0).length() * 0.55, 0.0025 * e, 0.0025 * e), pesos, Basis(Vector3(0, 0, 1), (p1 - p0).angle_to(Vector3.RIGHT) * signf((p1 - p0).y)))
			if lado > 0:
				malha.caixa("oculos", c + Vector3(0, r * 0.03, r * 0.99 + 0.012 * e), Vector3(r * 0.1, 0.0025 * e, 0.0025 * e), pesos)
			malha.caixa("oculos", c + Vector3(lado * r * 0.8, r * 0.04, r * 0.35), Vector3(0.0025 * e, 0.0025 * e, r * 0.6), pesos)
	# Boca: linha curta.
	var boca_unit := Vector3(0, -0.5, 0)
	boca_unit.z = sqrt(1.0 - 0.25)
	var boca := c + boca_unit * Vector3(r * 0.95, r * 1.08, r) * (1.0 - 0.3 * 0.25 * 0.6 + 0.05 * 0.5 * boca_unit.z)
	var sorriso: float = {"sorrindo": 1.0, "serio": 0.0, "neutro": 0.4}.get(str(ap.get("expressao", "neutro")), 0.4)
	malha.caixa("boca", boca + Vector3(0, 0, 0.004 * e), Vector3(r * (0.12 + 0.05 * sorriso), r * 0.012, 0.003 * e), pesos)
	if "barbicha" in ap.get("extras", []):
		malha.caixa("sobrancelha", boca + Vector3(0, -r * 0.3, -0.01 * e), Vector3(r * 0.08, r * 0.06, 0.012 * e), pesos)
	if "faixa" in ap.get("extras", []):
		# Faixa esportiva na testa.
		var aneis := []
		for dy: float in [0.0, 0.05 * e]:
			var y := c.y + r * 0.45 + dy
			var fator := sqrt(maxf(0.1, 1.0 - pow((y - c.y) / (r * 1.08), 2)))
			aneis.append({"p": Malha.anel(Vector3(c.x, y, c.z), Vector3(r * 0.95 * fator + 0.012 * e, 0, 0), Vector3(0, 0, r * fator + 0.012 * e), 20), "pesos": pesos})
		malha.tubo("faixa", aneis, false, false)


# --- Cabelo ---------------------------------------------------------------------

## Estilos: cada um combina casca (volume), mechas (franja/espetado) e extras.
static func _cabelo(malha: Malha, ap: Dictionary, m: Dictionary) -> void:
	var e: float = m["altura"] / ALTURA_BASE
	var c: Vector3 = m["centro_cabeca"]
	var r: float = m["raio_cabeca"]
	var cabelo: Dictionary = ap.get("cabelo", {})
	var estilo := str(cabelo.get("estilo", "curto"))
	var pesos := {"Head": 1.0}
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(ap.get("semente", estilo + str(cabelo.get("cor", "")))) + str(m["altura"]))
	var raios := Vector3(r * 0.95, r * 1.08, r)

	# Volume da casca por estilo (metros acima da pele, em proporção ao raio).
	var volume: float = float(cabelo.get("volume", {
		"raspado": 0.04, "curto": 0.1, "liso": 0.13, "franja": 0.14, "espetado": 0.16, "ondulado": 0.2,
		"cacheado": 0.22, "topete": 0.1, "moicano": 0.03, "coque": 0.12, "black_power": 0.42, "trancas": 0.1,
		"undercut": 0.12, "repartido": 0.13, "bagunçado": 0.2, "comprido": 0.16, "tigela": 0.15, "para_tras": 0.14,
	}.get(estilo, 0.12)))
	# Até onde a casca desce: ângulo do topo (rad) na frente, lado e atrás.
	var frente_deg: float = float(cabelo.get("testa", {"franja": 95, "tigela": 98, "liso": 80, "repartido": 72, "comprido": 85, "bagunçado": 85, "para_tras": 60}.get(estilo, 68)))
	var lado_deg: float = float(cabelo.get("lados", {"comprido": 135, "black_power": 110, "undercut": 70, "moicano": 45, "coque": 100}.get(estilo, 95)))
	var atras_deg: float = float(cabelo.get("nuca", {"comprido": 140, "black_power": 125, "undercut": 85, "moicano": 70, "coque": 110, "trancas": 120}.get(estilo, 118)))
	var ate := func(azimute: float) -> float:
		# azimute 0 = +x (lado esquerdo), PI/2 = +z (frente), 3PI/2 = -z (atrás).
		var frente := maxf(0.0, sin(azimute))
		var atras := maxf(0.0, -sin(azimute))
		var lados := 1.0 - frente - atras
		return deg_to_rad(frente * frente_deg + atras * atras_deg + lados * lado_deg)
	var ondulado := estilo in ["ondulado", "cacheado", "bagunçado", "black_power", "trancas"]
	var raio_casca := func(unit: Vector3, t: float) -> Vector3:
		var extra := volume * (1.0 - 0.35 * t * t)
		if ondulado:
			extra *= 1.0 + 0.25 * sin(unit.x * 37.0 + unit.y * 23.0) * sin(unit.z * 41.0 + 1.3)
		if estilo == "trancas":
			extra *= 1.0 + 0.3 * sin(atan2(unit.z, unit.x) * 12.0)
		var borda := 1.0 + 0.03 * sin(t * 40.0 + unit.x * 30.0) * t
		return raios * (1.0 + extra * borda)
	if estilo == "undercut":
		# Lados raspados em cor mais escura, topo com volume.
		malha.casca("cabelo2", c, func(unit: Vector3, _t: float) -> Vector3: return raios * 1.03, func(a: float) -> float: return deg_to_rad(95.0 if cos(a) * cos(a) > 0.3 else 75.0), pesos)
	if estilo != "moicano":
		malha.casca("cabelo", c, raio_casca, ate, pesos, 28, 10)
	else:
		malha.casca("cabelo2", c, func(unit: Vector3, _t: float) -> Vector3: return raios * 1.02, func(_a: float) -> float: return deg_to_rad(100.0), pesos)

	var topo := c + Vector3(0, raios.y * (1.0 + volume), 0)
	match estilo:
		"espetado", "bagunçado":
			var qtd := int(cabelo.get("mechas", 16))
			var compr := float(cabelo.get("comprimento", 0.075)) * e
			for k in qtd:
				var az := rng.randf_range(0.0, TAU)
				var polar := rng.randf_range(0.05, deg_to_rad(80.0))
				var unit := Vector3(sin(polar) * cos(az), cos(polar), sin(polar) * sin(az))
				var base := c + unit * raios * (1.0 + volume * 0.7)
				var dir := (unit + Vector3(0, 0.6, 0) + Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3))).normalized()
				var cor := "cabelo"
				if cabelo.get("pontas", "") != "":
					cor = "cabelo2"
				malha.mecha("cabelo", base, dir, compr * rng.randf_range(0.7, 1.3), 0.022 * e, pesos, Vector3(0, 0, 0), 0.6)
				if cor == "cabelo2":
					malha.mecha("cabelo2", base + dir * compr * 0.55, dir, compr * 0.5, 0.013 * e, pesos, Vector3.ZERO, 0.6)
			if estilo == "bagunçado":
				# Franja caindo sobre um lado do rosto.
				var lado_f := float(cabelo.get("lado_da_franja", 1.0))
				for k in 4:
					var base := c + Vector3(lado_f * r * (0.1 + 0.15 * k), r * 0.75, r * 0.6)
					malha.mecha("cabelo", base, Vector3(lado_f * 0.15, -1.0, 0.25), r * (0.75 + 0.1 * k), 0.025 * e, pesos, Vector3(0, 0, r * 0.1), 0.45)
			_franja(malha, c, raios, e, pesos, rng, 5, 0.3, cabelo, "cabelo")
		"franja", "liso", "tigela", "repartido", "comprido":
			var compr: float = {"franja": 0.42, "tigela": 0.45, "liso": 0.33, "repartido": 0.3, "comprido": 0.5}.get(estilo, 0.35)
			var reta := estilo in ["tigela", "franja"]
			var lado_f := float(cabelo.get("lado_da_franja", 0.0))
			var qtd := 7 if estilo != "repartido" else 6
			for k in qtd:
				var frac := (float(k) + 0.5) / qtd
				var az := lerpf(deg_to_rad(40.0), deg_to_rad(140.0), frac)
				var unit := Vector3(cos(az), 0.72, sin(az)).normalized()
				var base := c + unit * raios * (1.0 + volume * 0.8)
				var dir := Vector3(lado_f * 0.3 + (unit.x if not reta else unit.x * 0.2), -1.0, 0.1).normalized()
				var l := r * compr * (1.0 if reta else rng.randf_range(0.85, 1.15))
				if estilo == "repartido":
					# Risca: as mechas abrem do meio pros lados.
					var sinal := -1.0 if frac < 0.5 + lado_f * 0.3 else 1.0
					dir = Vector3(sinal * 0.5, -1.0, 0.15).normalized()
				malha.mecha("cabelo", base, dir, l, 0.028 * e, pesos, Vector3(0, 0, 0.012 * e), 0.4)
			if cabelo.get("pontas", "") != "" and estilo != "comprido":
				for k in 4:
					var frac := (float(k) + 0.5) / 4.0
					var az := lerpf(deg_to_rad(50.0), deg_to_rad(130.0), frac)
					var unit := Vector3(cos(az), 0.4, sin(az)).normalized()
					var base := c + unit * raios * (1.0 + volume * 0.9)
					malha.mecha("cabelo2", base, Vector3(unit.x * 0.2, -1.0, 0.25), r * 0.2, 0.018 * e, pesos, Vector3.ZERO, 0.4)
			if cabelo.get("raizes", "") != "":
				# Raiz escura no topo.
				malha.casca("cabelo2", c, func(unit: Vector3, _t: float) -> Vector3: return raios * (1.0 + volume * 1.06), func(_a: float) -> float: return deg_to_rad(40.0), pesos, 20, 5)
			if estilo == "comprido":
				# Mechas longas dos lados até o queixo.
				for lado: float in [1.0, -1.0]:
					for k in 3:
						var base := c + Vector3(lado * r * 0.8, r * 0.5, r * (0.3 - 0.3 * k))
						malha.mecha("cabelo", base, Vector3(lado * 0.1, -1.0, 0.05), r * 1.3, 0.03 * e, pesos, Vector3(0, 0, 0), 0.5)
		"topete":
			var alt := float(cabelo.get("comprimento", 0.11)) * e
			for k in 7:
				var az := rng.randf_range(0.0, TAU)
				var dist := rng.randf_range(0.0, r * 0.35)
				var base := topo + Vector3(cos(az) * dist, -0.01 * e, sin(az) * dist * 0.7)
				malha.mecha("cabelo", base, Vector3(cos(az) * 0.15, 1.0, sin(az) * 0.1 + 0.1), alt * rng.randf_range(0.8, 1.15), 0.028 * e, pesos, Vector3(0, 0, -0.01 * e), 0.8)
			if cabelo.get("pontas", "") != "":
				# Mecha clara bem na frente (ex.: franja descolorida).
				malha.mecha("cabelo2", c + Vector3(0, raios.y * 0.95, r * 0.55), Vector3(0, 1.0, 0.35), alt * 0.9, 0.03 * e, pesos, Vector3.ZERO, 0.7)
			_franja(malha, c, raios, e, pesos, rng, 4, 0.28, cabelo, "cabelo")
		"moicano":
			for k in 9:
				var z := lerpf(r * 0.8, -r * 0.8, float(k) / 8.0)
				var unit := Vector3(0, sqrt(maxf(0.05, 1.0 - z * z / (r * r))), z / r).normalized()
				var base := c + unit * raios * 1.02
				malha.mecha("cabelo", base, (unit + Vector3(0, 0.6, 0.15)).normalized(), 0.07 * e, 0.024 * e, pesos, Vector3.ZERO, 0.6)
		"coque":
			var coque := c + Vector3(0, -r * 0.05, -raios.z * 1.05)
			malha.esfera("cabelo", coque, Vector3(0.045, 0.045, 0.04) * e, pesos, Callable(), 10, 8)
			for lado: float in [1.0, -1.0]:
				malha.mecha("cabelo", c + Vector3(lado * r * 0.55, r * 0.55, r * 0.75), Vector3(lado * 0.1, -1.0, 0.1), r * 0.9, 0.022 * e, pesos, Vector3.ZERO, 0.45)
			_franja(malha, c, raios, e, pesos, rng, 4, 0.3, cabelo, "cabelo")
		"black_power":
			pass
		"trancas":
			# Rabo de tranças atrás.
			for k in 5:
				var az := rng.randf_range(-0.5, 0.5)
				malha.mecha("cabelo", c + Vector3(az * r * 0.5, -r * 0.1, -raios.z * 1.05), Vector3(az * 0.3, -1.0, -0.2), r * 1.1 * rng.randf_range(0.8, 1.1), 0.014 * e, pesos, Vector3(0, 0, -0.02 * e), 0.9)
		"ondulado", "cacheado":
			# Cachos: bolinhas em volta do topo.
			var qtd := 14 if estilo == "cacheado" else 8
			for k in qtd:
				var az := rng.randf_range(0.0, TAU)
				var polar := rng.randf_range(0.1, deg_to_rad(85.0))
				var unit := Vector3(sin(polar) * cos(az), cos(polar), sin(polar) * sin(az))
				malha.esfera("cabelo", c + unit * raios * (1.0 + volume * 0.9), Vector3(1, 1, 1) * r * rng.randf_range(0.14, 0.22), pesos, Callable(), 8, 6)
			_franja(malha, c, raios, e, pesos, rng, 5, 0.32 if estilo == "ondulado" else 0.22, cabelo, "cabelo")
		"para_tras":
			for k in 8:
				var az := rng.randf_range(deg_to_rad(20.0), deg_to_rad(160.0))
				var unit := Vector3(cos(az) * 0.6, 0.85, sin(az) * 0.5).normalized()
				var base := c + unit * raios * (1.0 + volume * 0.8)
				malha.mecha("cabelo", base, Vector3(unit.x * 0.2, 0.35, -1.0).normalized(), r * 0.5, 0.026 * e, pesos, Vector3(0, -0.02 * e, 0), 0.5)
		"undercut":
			for k in 9:
				var az := rng.randf_range(0.0, TAU)
				var dist := rng.randf_range(0.0, r * 0.45)
				var base := topo + Vector3(cos(az) * dist, -0.015 * e, sin(az) * dist)
				malha.mecha("cabelo", base, Vector3(0.1, 0.5, 1.0).normalized(), r * 0.5, 0.028 * e, pesos, Vector3(0, -0.02 * e, 0), 0.5)
		"curto", "raspado":
			if estilo == "curto":
				_franja(malha, c, raios, e, pesos, rng, 4, 0.14, cabelo, "cabelo")
		_:
			pass


## Franja padrão: algumas mechas curtas caindo na testa.
static func _franja(malha: Malha, c: Vector3, raios: Vector3, e: float, pesos: Dictionary, rng: RandomNumberGenerator, qtd: int, compr: float, cabelo: Dictionary, material: String) -> void:
	var r := raios.z
	for k in qtd:
		var frac := (float(k) + 0.5) / qtd
		var az := lerpf(deg_to_rad(45.0), deg_to_rad(135.0), frac)
		var unit := Vector3(cos(az), 0.85, sin(az)).normalized()
		var base := c + unit * raios * 1.07
		var dir := Vector3(unit.x * 0.5 + rng.randf_range(-0.2, 0.2), -1.0, 0.35).normalized()
		malha.mecha(material, base, dir, r * compr * rng.randf_range(0.8, 1.2), 0.024 * e, pesos, Vector3(0, 0, 0.01 * e), 0.4)
	if cabelo.get("mecha_frente", "") != "":
		# Uma mecha de cor diferente bem no meio da franja.
		malha.mecha("cabelo2", c + Vector3(0, raios.y * 0.9, r * 0.5), Vector3(0, 0.9, 0.5), r * 0.45, 0.03 * e, pesos, Vector3.ZERO, 0.7)


# --- Materiais -------------------------------------------------------------------

static func _cor_da_pele(ap: Dictionary) -> Color:
	var pele := str(ap.get("pele", "clara"))
	if PELES.has(pele):
		return Color(PELES[pele])
	return Color.from_string(pele, Color(PELES["clara"]))


## Material anime (sombra em faixas) com contorno opcional.
static func _material(cor: Color, contorno: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_ANIME
	mat.set_shader_parameter("cor", cor)
	mat.set_shader_parameter("brilho_de_borda", 0.15)
	if contorno > 0.0:
		var borda := ShaderMaterial.new()
		borda.shader = SHADER_CONTORNO
		borda.set_shader_parameter("espessura", contorno)
		borda.set_shader_parameter("cor_do_contorno", COR_CONTORNO)
		mat.next_pass = borda
	return mat


## Cor chapada, sem sombra (olhos, boca).
static func _material_chapado(cor: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cor
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


## Número da camisa: textura branca (personagens/numeros/NN.png)
## pintada com a cor de detalhe do uniforme. Sem a textura, fica sem número.
static func _material_do_numero(numero: int, cor: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cor
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.roughness = 0.9
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var caminho := "%s/%02d.png" % [PASTA_NUMEROS, numero]
	if ResourceLoader.exists(caminho):
		mat.albedo_texture = load(caminho)
	else:
		mat.albedo_color.a = 0.0
	return mat
