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

const SHADER_ATLETA := preload("res://shaders/atleta.gdshader")
const SHADER_ROSTO := preload("res://shaders/rosto.gdshader")
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
	"clara": "#EDC4A2", "clara_quente": "#F0C39C", "bem_clara": "#F3D3B8",
	"bronzeada": "#D9A57A", "morena_clara": "#C9946C", "morena": "#A8714F",
	"parda": "#8C5C40", "negra": "#5E3D2A",
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

	## Mecha larga de anime: faixa achatada que segue "caminho" (pontos), larga
	## na raiz e afinando até a ponta. "centro" é o centro da cabeça (pra saber
	## qual lado é "fora"). Com "material2", a ponta (de "inicio_cor2" em
	## diante, 0..1) sai na segunda cor.
	func mecha_larga(material: String, caminho: Array, centro: Vector3, largura: float, espessura: float, pesos: Dictionary, material2 := "", inicio_cor2 := 1.0, seg := 4) -> void:
		var n := caminho.size()
		var aneis := []
		var lado_anterior := Vector3.ZERO
		for i in n:
			var t := float(i) / (n - 1)
			var ponto: Vector3 = caminho[i]
			var tang: Vector3 = (caminho[mini(i + 1, n - 1)] - caminho[maxi(i - 1, 0)]).normalized()
			var fora: Vector3 = ponto - centro
			fora -= tang * fora.dot(tang)
			if fora.length() < 0.004:
				fora = Vector3.UP - tang * tang.y
			if fora.length() < 0.004:
				fora = Vector3.FORWARD
			fora = fora.normalized()
			var lado := tang.cross(fora).normalized()
			# Mantém o mesmo lado em todos os anéis (sem torcer a mecha).
			if i > 0 and lado.dot(lado_anterior) < 0.0:
				lado = -lado
			fora = lado.cross(tang).normalized()
			lado_anterior = lado
			# Mais larga logo depois da raiz e afinando em ponta.
			var w := largura * (0.75 + 0.25 * sin(minf(t * 3.0, 1.0) * PI * 0.5)) * pow(1.0 - t, 0.9) + 0.0015
			var th := espessura * (1.0 - 0.6 * t) + 0.001
			aneis.append({"p": anel(ponto, lado * w, fora * th, seg), "pesos": pesos})
		if material2 == "" or inicio_cor2 >= 1.0:
			tubo(material, aneis, true, true)
		else:
			var corte := clampi(int(round(inicio_cor2 * (n - 1))), 1, n - 2)
			tubo(material, aneis.slice(0, corte + 1), true, false)
			tubo(material2, aneis.slice(corte), false, true)

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
	func placa(material: String, meio_x: Callable, meio_z: Callable, centro_x: float, y0: float, y1: float, ang0: float, ang1: float, folga: float, pesos: Dictionary, colunas := 8, linhas := 4, folga_por_y: Callable = Callable(), pesos_por_y: Callable = Callable()) -> void:
		var ids := []
		for l in linhas + 1:
			var y: float = lerpf(y0, y1, float(l) / linhas)
			var fila := []
			var f: float = folga_por_y.call(y) if folga_por_y.is_valid() else folga
			var pesos_y: Dictionary = pesos_por_y.call(y) if pesos_por_y.is_valid() else pesos
			var rx: float = meio_x.call(y) + f
			var rz: float = meio_z.call(y) + f
			for c in colunas + 1:
				var t: float = lerpf(ang0, ang1, float(c) / colunas)
				var pos := Vector3(centro_x + rx * sin(t), y, rz * cos(t))
				var normal := Vector3(sin(t) / rx, 0, cos(t) / rz).normalized()
				fila.append(vertice(material, pos, pesos_y, Vector2(float(c) / colunas, 1.0 - float(l) / linhas), normal))
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
			# Os triângulos estão na ordem do Godot (horário visto de fora), então
			# (b - a) x (c - a) aponta pra dentro: a normal é o oposto.
			for k in v.size():
				if normais[k].length_squared() < 0.0001:
					normais[k] = -contadas[k].normalized() if contadas[k].length_squared() > 0.0 else Vector3.UP
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
		[y_peito, 0.172 * e * larg], [y_alto, 0.205 * e * larg * m["ombros"]], [y_ombro, 0.178 * e * m["ombros"]],
		[y_pescoco, 0.055 * e],
	]
	var profundidades := [
		[y_virilha, 0.085 * e * larg], [y_quadril, 0.108 * e * larg], [y_cintura, 0.095 * e * larg],
		[y_peito, 0.118 * e * larg], [y_alto, 0.118 * e * larg], [y_ombro, 0.1 * e],
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
	# Folga da camisa em cada altura: solta embaixo, justa no peito.
	var folgas_camisa := [
		[y_barra - 0.04 * e, 0.026 * e], [y_barra - 0.01 * e, 0.022 * e], [y_cintura, 0.016 * e],
		[y_peito, 0.013 * e], [y_alto, 0.012 * e], [y_ombro, 0.008 * e], [y_pescoco, 0.012 * e],
	]
	var folga_camisa := func(y: float) -> float: return _interp(folgas_camisa, y)
	var shorts := [anel_tronco.call(y_virilha, 0.012 * e, n), anel_tronco.call(y_virilha + 0.03 * e, 0.014 * e, n), anel_tronco.call(y_quadril, 0.012 * e, n), anel_tronco.call(y_barra + 0.015 * e, 0.0, n)]
	malha.tubo("shorts", shorts, true, false)
	# Camisa: da barra até o pescoço.
	# Camisa: solta por cima do short (barra mais larga), justa no peito.
	var camisa := []
	for y: float in [y_barra - 0.04 * e, y_barra - 0.01 * e, y_cintura, y_peito, y_alto, y_ombro, y_pescoco]:
		camisa.append(anel_tronco.call(y, folga_camisa.call(y), n))
	malha.tubo("camisa", camisa, false, false)
	# Gola: aro na cor de detalhe.
	malha.tubo("detalhe", [anel_tronco.call(y_pescoco - 0.007 * e, 0.016 * e, n), anel_tronco.call(y_pescoco + 0.005 * e, 0.014 * e, n)], false, false)
	# Pescoço (pele) até dentro da cabeça.
	var centro_cabeca: Vector3 = m["centro_cabeca"]
	var raio_cabeca: float = m["raio_cabeca"]
	malha.tubo("pele", [
		{"p": Malha.anel(Vector3(0, y_pescoco - 0.005 * e, 0), Vector3(0.057 * e, 0, 0), Vector3(0, 0, 0.055 * e), 12), "pesos": {"Neck": 1.0}},
		{"p": Malha.anel(Vector3(0, m["Head"].y + 0.01 * e, 0.003 * e), Vector3(0.052 * e, 0, 0), Vector3(0, 0, 0.051 * e), 12), "pesos": {"Neck": 0.4, "Head": 0.6}},
		{"p": Malha.anel(centro_cabeca - Vector3(0, raio_cabeca * 0.5, 0), Vector3(0.052 * e, 0, 0), Vector3(0, 0, 0.052 * e), 12), "pesos": {"Head": 1.0}},
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
	_rosto(malha, ap, m, deformar_cabeca)
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
		var r_ombro := 0.066 * e * memb
		var r_cotovelo := 0.044 * e * memb
		var r_pulso := 0.032 * e * memb
		var fim_manga := ombro + eixo * 0.12 * e
		malha.tubo("camisa", [
			braco.call(ombro - eixo * 0.03 * e, r_ombro * 1.05, {"UpperChest": 0.6, p + "UpperArm": 0.4}),
			braco.call(ombro + eixo * 0.02 * e, r_ombro * 1.14, {p + "UpperArm": 0.8, "UpperChest": 0.2}),
			braco.call(ombro + eixo * 0.07 * e, r_ombro * 1.1, {p + "UpperArm": 1.0}),
			braco.call(fim_manga, r_ombro * 1.06, {p + "UpperArm": 1.0}),
		], true, false)
		malha.tubo("detalhe", [braco.call(fim_manga - eixo * 0.012 * e, r_ombro * 1.1, {p + "UpperArm": 1.0}), braco.call(fim_manga + eixo * 0.01 * e, r_ombro * 1.08, {p + "UpperArm": 1.0})], false, false)
		malha.tubo("pele", [
			braco.call(fim_manga, r_ombro * 0.9, {p + "UpperArm": 1.0}),
			braco.call(lerp(fim_manga, cotovelo, 0.45), r_cotovelo * 1.2, {p + "UpperArm": 1.0}),
			braco.call(cotovelo - eixo * 0.03 * e, r_cotovelo * 1.05, {p + "UpperArm": 0.8, p + "LowerArm": 0.2}),
			braco.call(cotovelo, r_cotovelo, {p + "UpperArm": 0.5, p + "LowerArm": 0.5}),
			braco.call(cotovelo + eixo * 0.05 * e, r_cotovelo * 1.15, {p + "LowerArm": 1.0}),
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
		var r_coxa := 0.094 * e * memb
		var r_joelho := 0.06 * e * memb
		var r_panturrilha := 0.074 * e * memb
		var r_tornozelo := 0.038 * e * memb
		var y_shorts := coxa.y - 0.205 * e
		var fim_shorts := Vector3(coxa.x + lado * 0.006 * e, y_shorts, coxa.z + 0.004 * e)
		# Shorts por cima da coxa: folgado, abrindo um pouco na barra.
		var aneis_short := [
			[coxa + Vector3(0, 0.03 * e, 0), r_coxa * 1.16, {"Hips": 0.7, p + "UpperLeg": 0.3}],
			[coxa - Vector3(-lado * 0.003 * e, 0.07 * e, 0), r_coxa * 1.25, {"Hips": 0.2, p + "UpperLeg": 0.8}],
			[fim_shorts, r_coxa * 1.3, {p + "UpperLeg": 1.0}],
		]
		var tubo_short := []
		for a: Array in aneis_short:
			tubo_short.append(perna.call(a[0], a[1], a[2]))
		malha.tubo("shorts", tubo_short, false, false)
		# Faixa larga na lateral do short, na cor de detalhe.
		var faixa := []
		for a: Array in aneis_short:
			var linha := []
			for k in 5:
				var ang := lerpf(-0.42, 0.42, float(k) / 4.0)
				var dir := Vector3(lado * cos(ang), 0, sin(ang))
				linha.append(malha.vertice("detalhe", a[0] + dir * (a[1] + 0.003 * e), a[2]))
			faixa.append(linha)
		for l in faixa.size() - 1:
			for k in 4:
				if lado > 0:
					malha.triangulo("detalhe", faixa[l][k], faixa[l + 1][k], faixa[l][k + 1])
					malha.triangulo("detalhe", faixa[l][k + 1], faixa[l + 1][k], faixa[l + 1][k + 1])
				else:
					malha.triangulo("detalhe", faixa[l][k], faixa[l][k + 1], faixa[l + 1][k])
					malha.triangulo("detalhe", faixa[l][k + 1], faixa[l + 1][k + 1], faixa[l + 1][k])
		# Coxa e joelho (pele), joelheira, panturrilha.
		var y_joelheira_alto := joelho.y + 0.06 * e
		var y_joelheira_baixo := joelho.y - 0.055 * e
		malha.tubo("pele", [
			perna.call(fim_shorts, r_coxa * 0.96, {p + "UpperLeg": 1.0}),
			perna.call(Vector3(joelho.x, y_joelheira_alto + 0.03 * e, joelho.z), r_joelho * 1.1, {p + "UpperLeg": 0.85, p + "LowerLeg": 0.15}),
			perna.call(Vector3(joelho.x, y_joelheira_alto, joelho.z), r_joelho * 1.05, {p + "UpperLeg": 0.7, p + "LowerLeg": 0.3}),
		], false, false)
		malha.tubo("joelheira", [
			perna.call(Vector3(joelho.x, y_joelheira_alto, joelho.z), r_joelho * 1.12, {p + "UpperLeg": 0.7, p + "LowerLeg": 0.3}),
			perna.call(joelho + Vector3(0, 0, 0.006 * e), r_joelho * 1.16, {p + "UpperLeg": 0.5, p + "LowerLeg": 0.5}),
			perna.call(Vector3(joelho.x, y_joelheira_baixo, joelho.z), r_joelho * 1.1, {p + "UpperLeg": 0.2, p + "LowerLeg": 0.8}),
		], false, false)
		var y_meia := tornozelo.y + 0.055 * e
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
		var sola := 0.016 * e
		var lg := 1.12 * memb
		var pe := {p + "Foot": 1.0}
		# Cano do tênis (gola acolchoada em volta do tornozelo).
		malha.tubo("tenis", [
			perna.call(Vector3(tornozelo.x, tornozelo.y + 0.04 * e, tornozelo.z - 0.006 * e), r_tornozelo * 1.32, {p + "LowerLeg": 0.5, p + "Foot": 0.5}),
			perna.call(Vector3(tornozelo.x, tornozelo.y + 0.01 * e, tornozelo.z - 0.004 * e), r_tornozelo * 1.42, pe),
		], false, false)
		# Corpo do tênis, do calcanhar à ponta.
		var corpo_tenis := [
			sapato.call(Vector3(tornozelo.x, tornozelo.y * 0.62 + 0.004 * e, tornozelo.z - 0.05 * e), r_tornozelo * 1.25, tornozelo.y * 0.42, pe),
			sapato.call(Vector3(tornozelo.x, (tornozelo.y + sola) * 0.5 + 0.008 * e, tornozelo.z - 0.02 * e), 0.05 * e * lg, (tornozelo.y - sola) * 0.5 + 0.016 * e, pe),
			sapato.call(Vector3(tornozelo.x, (tornozelo.y + sola) * 0.5 + 0.002 * e, tornozelo.z + 0.05 * e), 0.053 * e * lg, (tornozelo.y - sola) * 0.5 + 0.004 * e, {p + "Foot": 0.8, p + "Toes": 0.2}),
			sapato.call(Vector3(dedos.x, dedos.y + 0.016 * e, dedos.z + 0.012 * e), 0.048 * e * lg, 0.026 * e, {p + "Foot": 0.4, p + "Toes": 0.6}),
			sapato.call(Vector3(dedos.x, dedos.y + 0.012 * e, dedos.z + 0.06 * e), 0.03 * e * lg, 0.016 * e, {p + "Toes": 1.0}),
		]
		malha.tubo("tenis", corpo_tenis, true, true)
		# Bico e calcanhar na cor de detalhe do time.
		malha.tubo("detalhe", [
			sapato.call(Vector3(dedos.x, dedos.y + 0.013 * e, dedos.z + 0.03 * e), 0.046 * e * lg, 0.024 * e, {p + "Foot": 0.3, p + "Toes": 0.7}),
			sapato.call(Vector3(dedos.x, dedos.y + 0.012 * e, dedos.z + 0.064 * e), 0.028 * e * lg, 0.015 * e, {p + "Toes": 1.0}),
		], false, true)
		malha.tubo("detalhe", [
			sapato.call(Vector3(tornozelo.x, tornozelo.y * 0.5 + 0.004 * e, tornozelo.z - 0.058 * e), r_tornozelo * 1.15, tornozelo.y * 0.36, pe),
			sapato.call(Vector3(tornozelo.x, tornozelo.y * 0.55 + 0.004 * e, tornozelo.z - 0.04 * e), r_tornozelo * 1.32, tornozelo.y * 0.45, pe),
		], true, false)
		# Faixa larga na lateral do tênis.
		malha.tubo("detalhe", [
			sapato.call(Vector3(tornozelo.x, tornozelo.y * 0.5 + 0.004 * e, tornozelo.z - 0.015 * e), 0.054 * e * lg, 0.017 * e, pe),
			sapato.call(Vector3(tornozelo.x, tornozelo.y * 0.45 + 0.004 * e, tornozelo.z + 0.04 * e), 0.057 * e * lg, 0.015 * e, {p + "Foot": 0.9, p + "Toes": 0.1}),
		], false, false)
		# Sola grossa e escura.
		malha.tubo("sola", [
			sapato.call(Vector3(tornozelo.x, sola * 0.9, tornozelo.z - 0.055 * e), r_tornozelo * 1.32, sola, pe),
			sapato.call(Vector3(tornozelo.x, sola * 0.9, tornozelo.z + 0.03 * e), 0.058 * e * lg, sola, pe),
			sapato.call(Vector3(dedos.x, sola * 0.9, dedos.z + 0.05 * e), 0.036 * e * lg, sola, {p + "Toes": 1.0}),
		], true, true)

	# Número: costas (grande) e peito (pequeno, à esquerda de quem veste).
	var numero := int(uniforme.get("numero", 0))
	var pesos_costas := {"Chest": 0.5, "UpperChest": 0.5}
	var sobre_camisa := func(y: float) -> float: return folga_camisa.call(y) + 0.005 * e
	var pesos_na_altura := func(y: float) -> Dictionary: return _pesos_do_tronco(m, y)
	malha.placa("numero", meio_x, meio_z, 0.0, y_peito - 0.1 * e, y_alto + 0.04 * e, PI - 1.0, PI + 1.0, 0.0, pesos_costas, 10, 8, sobre_camisa, pesos_na_altura)
	malha.placa("numero", meio_x, meio_z, 0.0, y_peito - 0.095 * e, y_alto - 0.005 * e, -0.74, 0.74, 0.0, pesos_costas, 8, 8, sobre_camisa, pesos_na_altura)
	# Recortes laterais da camisa e faixa lateral do short, na cor de detalhe.
	for lado: float in [1.0, -1.0]:
		var centro := PI / 2.0 * lado
		var mais := func(y: float) -> float: return folga_camisa.call(y) + 0.0025 * e
		malha.placa("detalhe", meio_x, meio_z, 0.0, y_barra - 0.04 * e, y_alto + 0.01 * e, centro - 0.5, centro + 0.5, 0.0, {"Spine": 0.5, "Chest": 0.5}, 8, 6, mais, pesos_na_altura)
		malha.placa("detalhe", meio_x, meio_z, 0.0, y_virilha + 0.03 * e, y_barra - 0.03 * e, centro - 0.3, centro + 0.3, 0.017 * e, {"Hips": 1.0}, 4, 2)

	# Faixa de brilho só em cabelo claro e com volume (no escuro vira mancha cinza).
	var brilho_do_cabelo := 0.0 if str(cabelo.get("estilo", "")) in ["raspado", "moicano", "undercut", "black_power", "cacheado"] else clampf(cor_cabelo.get_luminance() * 0.5, 0.0, 0.22)
	var materiais := {
		"pele": _material(cor_pele, 0.01 * e, Color(0.96, 0.8, 0.8)),
		"camisa": _material(cor_camisa, 0.012 * e),
		"detalhe": _material(cor_detalhe, 0.0),
		"rosto": _material_do_rosto(ap, cor_pele, cor_cabelo, cor_olhos),
		"shorts": _material(cor_camisa if cores.size() < 3 else Color.from_string(str(cores[0]), cor_camisa), 0.012 * e),
		"joelheira": _material(Color("#1A1A1E"), 0.0),
		"meia": _material(Color("#F2F2F2"), 0.0),
		"tenis": _material(Color("#F4F4F4"), 0.01 * e),
		"sola": _material(Color("#2A2A30"), 0.0),
		"cabelo": _material(cor_cabelo, 0.012 * e, Color(0.8, 0.74, 0.9), brilho_do_cabelo),
		"cacho": _material(cor_cabelo, 0.0, Color(0.8, 0.74, 0.9), 0.0),
		"cabelo2": _material(Color.from_string(str(cabelo.get("cor2", "#1E1E1E")), Color.BLACK), 0.012 * e, Color(0.8, 0.74, 0.9), brilho_do_cabelo),
		"olho_branco": _material_chapado(Color.WHITE),
		"iris": _material_chapado(cor_olhos),
		"pupila": _material_chapado(Color(0.05, 0.03, 0.05)),
		"brilho": _material_chapado(Color.WHITE),
		"sobrancelha": _material_chapado(cor_cabelo.darkened(0.25)),
		"boca": _material_chapado(Color(0.45, 0.2, 0.2)),
		"oculos": _material(Color("#1E1E22"), 0.0),
		"faixa": _material(Color.from_string(str(ap.get("cor_da_faixa", cores[1])), cor_detalhe), 0.0),
		"numero": _material_do_numero(numero, _cor_do_numero(uniforme, cores)),
	}
	materiais["pele"].set_shader_parameter("limiar", -0.25)
	materiais["meia"].set_shader_parameter("limiar", -0.2)
	var instancias := malha.instancias(func(nome: String) -> int: return _indice_do_osso(nome), materiais)
	for nome in ["rosto", "cabelo", "cabelo2", "cacho"]:
		if instancias.has(nome):
			instancias[nome].cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instancias


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

## Parâmetros do rosto (shaders/rosto.gdshader) a partir do aparencia.json.
static func _parametros_do_rosto(ap: Dictionary) -> Dictionary:
	var olhos: Dictionary = ap.get("formato_dos_olhos", {}) if ap.get("formato_dos_olhos") is Dictionary else {}
	var tamanho: float = float(olhos.get("tamanho", {"grandes": 1.2, "pequenos": 0.82}.get(str(ap.get("formato_dos_olhos", "")), 1.0)))
	var palpebras := str(ap.get("palpebras", "normais"))
	return {
		"olho_x": 0.37 + 0.02 * (tamanho - 1.0),
		"olho_y": -0.06,
		"olho_largura": 0.185 * tamanho,
		"olho_altura": 0.165 * tamanho,
		"abertura": {"caidos": 0.72, "estreitos": 0.55}.get(palpebras, 1.0),
		"inclinacao": {"caidos": -0.35, "bravos": 0.4, "estreitos": 0.15}.get(palpebras, 0.0),
		"sobrancelha_grossura": {"fina": 0.65, "normal": 1.0, "grossa": 1.5}.get(str(ap.get("sobrancelha", "normal")), 1.0),
		"sorriso": {"sorrindo": 1.0, "serio": 0.0, "neutro": 0.4}.get(str(ap.get("expressao", "neutro")), 0.4),
		"corado": float(ap.get("corado", 0.0)),
	}


## Máscara do rosto: uma grade colada na frente da cabeça (UV = posição em
## raios da cabeça) onde o shader do rosto desenha olhos, sobrancelhas e boca.
## Também monta óculos, barbicha e faixa de testa (extras).
static func _rosto(malha: Malha, ap: Dictionary, m: Dictionary, deformar: Callable) -> void:
	var e: float = m["altura"] / ALTURA_BASE
	var c: Vector3 = m["centro_cabeca"]
	var r: float = m["raio_cabeca"]
	var pesos := {"Head": 1.0}
	var raios := Vector3(r * 0.95, r * 1.08, r)
	# Ponto da superfície da cabeça na posição (x, y) do rosto (em raios).
	var no_rosto := func(x: float, y: float, acima: float) -> Array:
		var ux := x / 0.95
		var uy := y / 1.08
		var unit := Vector3(ux, uy, sqrt(maxf(0.0, 1.0 - ux * ux - uy * uy))).normalized()
		var f: float = deformar.call(unit)
		var normal := Vector3(unit.x / raios.x, unit.y / raios.y, unit.z / raios.z).normalized()
		return [c + unit * raios * f + normal * acima, normal]
	var nx := 18
	var ny := 20
	var linhas := []
	for a in ny + 1:
		var y := lerpf(0.8, -1.02, float(a) / ny)
		var linha := []
		for k in nx + 1:
			var x := lerpf(-0.84, 0.84, float(k) / nx)
			var ponto: Array = no_rosto.call(x, y, 0.0012 * e)
			linha.append(malha.vertice("rosto", ponto[0], pesos, Vector2(x, y), ponto[1]))
		linhas.append(linha)
	for a in ny:
		for k in nx:
			malha.triangulo("rosto", linhas[a][k], linhas[a][k + 1], linhas[a + 1][k])
			malha.triangulo("rosto", linhas[a][k + 1], linhas[a + 1][k + 1], linhas[a + 1][k])
	var p := _parametros_do_rosto(ap)
	var extras: Array = ap.get("extras", [])
	if "oculos" in extras:
		var larg: float = p["olho_largura"] * r
		var alt: float = p["olho_altura"] * r
		for lado: float in [1.0, -1.0]:
			var ponto: Array = no_rosto.call(lado * p["olho_x"], p["olho_y"], 0.0)
			var pos: Vector3 = ponto[0]
			var normal: Vector3 = ponto[1]
			for k in 12:
				var t0 := TAU * k / 12
				var t1 := TAU * (k + 1) / 12
				var p0 := pos + normal * 0.012 * e + Vector3(cos(t0) * larg * 1.3, sin(t0) * alt * 1.4, 0)
				var p1 := pos + normal * 0.012 * e + Vector3(cos(t1) * larg * 1.3, sin(t1) * alt * 1.4, 0)
				malha.caixa("oculos", (p0 + p1) * 0.5, Vector3((p1 - p0).length() * 0.55, 0.0025 * e, 0.0025 * e), pesos, Basis(Vector3(0, 0, 1), (p1 - p0).angle_to(Vector3.RIGHT) * signf((p1 - p0).y)))
			if lado > 0:
				malha.caixa("oculos", c + Vector3(0, r * p["olho_y"], r * 0.99 + 0.012 * e), Vector3(r * 0.1, 0.0025 * e, 0.0025 * e), pesos)
			malha.caixa("oculos", c + Vector3(lado * r * 0.8, r * (p["olho_y"] + 0.02), r * 0.35), Vector3(0.0025 * e, 0.0025 * e, r * 0.6), pesos)
	if "barbicha" in extras:
		var queixo: Array = no_rosto.call(0.0, -0.85, 0.0)
		malha.caixa("sobrancelha", queixo[0], Vector3(r * 0.08, r * 0.06, 0.008 * e), pesos)
	if "faixa" in extras:
		# Faixa esportiva na testa.
		var aneis := []
		for dy: float in [0.0, 0.05 * e]:
			var y := c.y + r * 0.45 + dy
			var fator := sqrt(maxf(0.1, 1.0 - pow((y - c.y) / (r * 1.08), 2)))
			aneis.append({"p": Malha.anel(Vector3(c.x, y, c.z), Vector3(r * 0.95 * fator + 0.012 * e, 0, 0), Vector3(0, 0, r * fator + 0.012 * e), 20), "pesos": pesos})
		malha.tubo("faixa", aneis, false, false)


# --- Cabelo ---------------------------------------------------------------------

## Direção a partir do centro da cabeça: "polar" em graus a partir do topo e
## "azimute" em graus (0 = esquerda do atleta, 90 = frente, 180 = direita, 270 = nuca).
static func _direcao(polar: float, azimute: float) -> Vector3:
	var t := deg_to_rad(polar)
	var f := deg_to_rad(azimute)
	return Vector3(sin(t) * cos(f), cos(t), sin(t) * sin(f))


## Cada estilo: volume da base (casca), até onde ela desce (testa, lados, nuca,
## em graus a partir do topo) e os grupos de mechas largas. Grupo:
##   tipo: "cai" (desce rente à cabeça), "espeta" (sai pra fora) ou "tras" (penteado pra trás)
##   qtd, az [de, até] (azimute), de [a, b] (onde nasce), ate [a, b] (onde termina)
##   larg, esp (em raios da cabeça), solta (ponta saindo da cabeça), desvio (graus pro lado)
##   compr [a, b] e sobe (espetos), reto (desce reto depois, em raios), espelhar (os dois lados)
##   ponta (a ponta usa a segunda cor quando o atleta tem "pontas")
static func _estilo_de_cabelo(estilo: String) -> Dictionary:
	var franja_curta := {"tipo": "cai", "qtd": 6, "az": [58, 122], "de": [30, 36], "ate": [66, 74], "larg": 0.3, "esp": 0.09, "solta": 0.08, "desvio": 8}
	var lados_curtos := {"tipo": "cai", "qtd": 3, "az": [8, 42], "de": [45, 50], "ate": [90, 98], "larg": 0.32, "esp": 0.08, "solta": 0.04, "desvio": 6, "espelhar": true}
	var nuca_curta := {"tipo": "cai", "qtd": 5, "az": [205, 335], "de": [55, 65], "ate": [108, 114], "larg": 0.36, "esp": 0.08, "solta": 0.05, "desvio": 6}
	var topo := {"tipo": "cai", "qtd": 7, "az": [0, 360], "de": [4, 9], "ate": [42, 55], "larg": 0.42, "esp": 0.07, "solta": 0.0, "desvio": 10}
	match estilo:
		"espetado":
			return {"volume": 0.15, "testa": 72, "lados": 100, "nuca": 118, "grupos": [
				{"tipo": "espeta", "qtd": 18, "az": [0, 360], "de": [4, 78], "compr": [0.5, 0.8], "larg": 0.3, "esp": 0.17, "sobe": 0.22, "ponta": true},
				{"tipo": "cai", "qtd": 6, "az": [58, 122], "de": [24, 30], "ate": [64, 74], "larg": 0.38, "esp": 0.15, "solta": 0.24, "desvio": 16},
				{"tipo": "cai", "qtd": 2, "az": [10, 38], "de": [40, 46], "ate": [84, 92], "larg": 0.36, "esp": 0.14, "solta": 0.3, "desvio": 14, "espelhar": true},
				{"tipo": "cai", "qtd": 6, "az": [200, 340], "de": [55, 70], "ate": [108, 116], "larg": 0.36, "esp": 0.15, "solta": 0.32, "desvio": 12},
			]}
		"bagunçado":
			return {"volume": 0.17, "testa": 74, "lados": 102, "nuca": 120, "grupos": [
				{"tipo": "espeta", "qtd": 11, "az": [0, 360], "de": [8, 65], "compr": [0.4, 0.6], "larg": 0.28, "esp": 0.14, "sobe": 0.15, "ponta": true},
				{"tipo": "cai", "qtd": 5, "az": [70, 125], "de": [28, 34], "ate": [82, 94], "larg": 0.32, "esp": 0.11, "solta": 0.1, "desvio": 16, "lado_da_franja": true},
				{"tipo": "cai", "qtd": 3, "az": [5, 42], "de": [42, 48], "ate": [100, 110], "larg": 0.34, "esp": 0.1, "solta": 0.18, "desvio": 10, "espelhar": true},
				{"tipo": "cai", "qtd": 6, "az": [200, 340], "de": [55, 68], "ate": [118, 126], "larg": 0.36, "esp": 0.11, "solta": 0.22, "desvio": 10},
			]}
		"curto":
			return {"volume": 0.1, "testa": 66, "lados": 96, "nuca": 116, "grupos": [
				topo, franja_curta, lados_curtos, nuca_curta,
				{"tipo": "espeta", "qtd": 6, "az": [0, 360], "de": [10, 45], "compr": [0.2, 0.3], "larg": 0.28, "esp": 0.12, "sobe": 0.2, "ponta": true},
			]}
		"raspado":
			return {"volume": 0.04, "testa": 62, "lados": 92, "nuca": 112, "grupos": []}
		"liso", "franja", "tigela":
			var reta := estilo != "liso"
			var ate_franja: Array = [76, 84] if estilo == "liso" else ([80, 85] if estilo == "franja" else [80, 82])
			return {"volume": 0.13 if estilo == "liso" else 0.15, "testa": 80, "lados": 100, "nuca": 125, "grupos": [
				topo,
				{"tipo": "cai", "qtd": 8, "az": [52, 128], "de": [28, 34], "ate": ate_franja, "larg": 0.3, "esp": 0.09, "solta": 0.04, "desvio": 0 if reta else 5, "ponta": true},
				{"tipo": "cai", "qtd": 3, "az": [5, 45], "de": [40, 45], "ate": [106, 114] if estilo != "tigela" else [102, 106], "larg": 0.34, "esp": 0.09, "solta": 0.05, "desvio": 3, "espelhar": true},
				{"tipo": "cai", "qtd": 6, "az": [200, 340], "de": [50, 60], "ate": [126, 132] if estilo != "tigela" else [118, 122], "larg": 0.36, "esp": 0.09, "solta": 0.06, "desvio": 3},
			]}
		"repartido":
			return {"volume": 0.13, "testa": 72, "lados": 100, "nuca": 122, "grupos": [
				topo,
				{"tipo": "cai", "qtd": 4, "az": [62, 88], "de": [24, 30], "ate": [74, 82], "larg": 0.32, "esp": 0.09, "solta": 0.05, "desvio": -20, "ponta": true, "aleatorio": false},
				{"tipo": "cai", "qtd": 4, "az": [92, 118], "de": [24, 30], "ate": [74, 82], "larg": 0.32, "esp": 0.09, "solta": 0.05, "desvio": 20, "ponta": true, "aleatorio": false},
				{"tipo": "cai", "qtd": 3, "az": [5, 45], "de": [40, 45], "ate": [102, 108], "larg": 0.34, "esp": 0.09, "solta": 0.05, "desvio": 3, "espelhar": true},
				{"tipo": "cai", "qtd": 6, "az": [200, 340], "de": [50, 60], "ate": [120, 126], "larg": 0.36, "esp": 0.09, "solta": 0.06, "desvio": 3},
			]}
		"comprido":
			return {"volume": 0.16, "testa": 85, "lados": 125, "nuca": 135, "grupos": [
				topo,
				{"tipo": "cai", "qtd": 8, "az": [50, 130], "de": [28, 34], "ate": [84, 90], "larg": 0.3, "esp": 0.09, "solta": 0.05, "desvio": 6, "ponta": true},
				{"tipo": "cai", "qtd": 4, "az": [0, 48], "de": [40, 46], "ate": [104, 110], "larg": 0.34, "esp": 0.1, "solta": 0.08, "desvio": 2, "reto": 0.55, "espelhar": true},
				{"tipo": "cai", "qtd": 7, "az": [195, 345], "de": [50, 58], "ate": [112, 118], "larg": 0.38, "esp": 0.1, "solta": 0.08, "desvio": 2, "reto": 0.45},
			]}
		"topete":
			return {"volume": 0.1, "testa": 64, "lados": 96, "nuca": 116, "grupos": [
				{"tipo": "espeta", "qtd": 7, "az": [55, 125], "de": [8, 34], "compr": [0.75, 1.0], "larg": 0.28, "esp": 0.14, "sobe": 0.9, "ponta": true},
				{"tipo": "espeta", "qtd": 6, "az": [180, 360], "de": [15, 50], "compr": [0.3, 0.45], "larg": 0.28, "esp": 0.12, "sobe": 0.4},
				lados_curtos, nuca_curta,
			]}
		"para_tras":
			return {"volume": 0.14, "testa": 55, "lados": 96, "nuca": 120, "grupos": [
				{"tipo": "tras", "qtd": 9, "az": [40, 140], "de": [45, 52], "ate": [118, 126], "larg": 0.36, "esp": 0.1, "solta": 0.08, "desvio": 0},
				{"tipo": "cai", "qtd": 3, "az": [10, 40], "de": [48, 52], "ate": [100, 106], "larg": 0.32, "esp": 0.08, "solta": 0.04, "desvio": -35, "espelhar": true},
			]}
		"undercut":
			return {"volume": 0.12, "testa": 66, "lados": 70, "nuca": 85, "grupos": [
				topo,
				{"tipo": "cai", "qtd": 5, "az": [65, 120], "de": [24, 30], "ate": [66, 76], "larg": 0.32, "esp": 0.11, "solta": 0.16, "desvio": 18, "ponta": true},
			]}
		"moicano":
			return {"volume": 0.03, "testa": 62, "lados": 100, "nuca": 112, "grupos": []}
		"coque":
			return {"volume": 0.12, "testa": 70, "lados": 100, "nuca": 110, "grupos": [
				topo, franja_curta,
				{"tipo": "cai", "qtd": 3, "az": [8, 42], "de": [45, 50], "ate": [100, 106], "larg": 0.32, "esp": 0.08, "solta": 0.04, "desvio": -20, "espelhar": true},
			]}
		"ondulado":
			return {"volume": 0.2, "testa": 76, "lados": 104, "nuca": 122, "grupos": [
				{"tipo": "cai", "qtd": 6, "az": [55, 125], "de": [28, 34], "ate": [74, 82], "larg": 0.34, "esp": 0.12, "solta": 0.1, "desvio": 18, "ponta": true, "lado_da_franja": true},
				{"tipo": "cai", "qtd": 3, "az": [5, 42], "de": [42, 48], "ate": [104, 110], "larg": 0.36, "esp": 0.12, "solta": 0.12, "desvio": 12, "espelhar": true},
				{"tipo": "cai", "qtd": 6, "az": [200, 340], "de": [55, 65], "ate": [118, 124], "larg": 0.38, "esp": 0.12, "solta": 0.12, "desvio": 12},
			]}
		"cacheado", "black_power", "trancas":
			return {"volume": {"cacheado": 0.22, "black_power": 0.42, "trancas": 0.1}[estilo], "testa": 68, "lados": {"black_power": 110}.get(estilo, 96), "nuca": {"black_power": 125, "trancas": 120}.get(estilo, 118), "grupos": [franja_curta] if estilo == "cacheado" else []}
		_:
			return {"volume": 0.12, "testa": 68, "lados": 95, "nuca": 118, "grupos": [topo, franja_curta, lados_curtos, nuca_curta]}


## Monta o cabelo: casca (volume) + mechas largas do estilo + extras
## (raízes, pontas e mecha da frente em outra cor, coque, tranças, cachos).
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
	var def := _estilo_de_cabelo(estilo)
	var volume: float = float(cabelo.get("volume", def["volume"]))
	var frente_deg: float = float(cabelo.get("testa", def["testa"]))
	var lado_deg: float = float(cabelo.get("lados", def["lados"]))
	var atras_deg: float = float(cabelo.get("nuca", def["nuca"]))
	var ate := func(azimute: float) -> float:
		# azimute 0 = +x (lado esquerdo), PI/2 = +z (frente), 3PI/2 = -z (atrás).
		var frente := maxf(0.0, sin(azimute))
		var atras := maxf(0.0, -sin(azimute))
		var lados := 1.0 - frente - atras
		return deg_to_rad(frente * frente_deg + atras * atras_deg + lados * lado_deg)
	var ondulado := estilo in ["ondulado", "cacheado", "black_power", "trancas"]
	var raio_casca := func(unit: Vector3, t: float) -> Vector3:
		var extra := volume * (1.0 - 0.35 * t * t)
		if ondulado:
			extra *= 1.0 + 0.25 * sin(unit.x * 37.0 + unit.y * 23.0) * sin(unit.z * 41.0 + 1.3)
		if estilo == "trancas":
			extra *= 1.0 + 0.3 * sin(atan2(unit.z, unit.x) * 12.0)
		return raios * (1.0 + extra)
	if estilo == "undercut":
		# Lados raspados em cor mais escura, topo com volume.
		malha.casca("cabelo2", c, func(_unit: Vector3, _t: float) -> Vector3: return raios * 1.03, func(a: float) -> float: return deg_to_rad(95.0 if cos(a) * cos(a) > 0.3 else 75.0), pesos)
	if estilo != "moicano":
		malha.casca("cabelo", c, raio_casca, ate, pesos, 28, 10)
	else:
		malha.casca("cabelo2", c, func(_unit: Vector3, _t: float) -> Vector3: return raios * 1.02, func(_a: float) -> float: return deg_to_rad(100.0), pesos)

	var tem_pontas: bool = str(cabelo.get("pontas", "")) != ""
	var escala_espeto: float = float(cabelo.get("comprimento", 0.0)) / {"espetado": 0.08, "bagunçado": 0.09, "topete": 0.11}.get(estilo, 0.08) if cabelo.has("comprimento") else 1.0
	var lado_da_franja: float = float(cabelo.get("lado_da_franja", 0.0))
	var primeiro_espeto := true
	for grupo: Dictionary in def["grupos"]:
		var lados_do_grupo: Array = [1.0, -1.0] if grupo.get("espelhar", false) else [1.0]
		var material2 := "cabelo2" if tem_pontas and grupo.get("ponta", false) else ""
		var qtd: int = int(grupo["qtd"])
		if grupo["tipo"] == "espeta" and primeiro_espeto and cabelo.has("mechas"):
			qtd = int(cabelo["mechas"]) * 2 / 3
		if grupo["tipo"] == "espeta":
			primeiro_espeto = false
		for espelho: float in lados_do_grupo:
			for k in qtd:
				var frac := (float(k) + 0.5) / qtd
				var az: float = lerpf(float(grupo["az"][0]), float(grupo["az"][1]), frac) + rng.randf_range(-4.0, 4.0)
				if grupo.get("lado_da_franja", false):
					az -= lado_da_franja * 18.0
				if espelho < 0.0:
					az = 180.0 - az
				var larg: float = float(grupo["larg"]) * r * rng.randf_range(0.85, 1.15)
				var esp: float = float(grupo["esp"]) * r
				match str(grupo["tipo"]):
					"espeta":
						var polar: float = rng.randf_range(float(grupo["de"][0]), float(grupo["de"][1]))
						var u0 := _direcao(polar, az)
						var dir := (u0 + Vector3.UP * float(grupo["sobe"]) + Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))).normalized()
						var compr: float = rng.randf_range(float(grupo["compr"][0]), float(grupo["compr"][1])) * r * escala_espeto
						var base := c + u0 * raios * (1.0 + volume * 0.35)
						var cai := Vector3(0, -0.18 * compr * (1.0 - float(grupo["sobe"]) * 0.5), 0)
						var caminho := [base, base + dir * compr * 0.3, base + dir * compr * 0.6 + cai * 0.3, base + dir * compr * 0.85 + cai * 0.7, base + dir * compr + cai]
						malha.mecha_larga("cabelo", caminho, c, larg, esp, pesos, material2, 0.6)
					"cai", "tras":
						var de: float = rng.randf_range(float(grupo["de"][0]), float(grupo["de"][1]))
						var para: float = rng.randf_range(float(grupo["ate"][0]), float(grupo["ate"][1]))
						var desvio: float = float(grupo.get("desvio", 0.0))
						if grupo.get("lado_da_franja", false) and lado_da_franja != 0.0:
							desvio = absf(desvio) * -signf(lado_da_franja)
						else:
							if not grupo.get("espelhar", false) and grupo.get("aleatorio", true):
								desvio *= rng.randf_range(-1.0, 1.0)
						if espelho < 0.0:
							desvio = -desvio
						var u0 := _direcao(de, az)
						var az1 := az + desvio
						if grupo["tipo"] == "tras":
							az1 = az + 180.0
						var u1 := _direcao(para, az1)
						var solta: float = float(grupo.get("solta", 0.05))
						var caminho := []
						for i in 6:
							var t := float(i) / 5.0
							var u: Vector3 = u0.slerp(u1, t).normalized()
							# A raiz nasce dentro da base e sai dela; a ponta descola da cabeça.
							var raio := 1.0 + volume * (0.55 + 0.45 * smoothstep(0.0, 0.35, t) - 0.4 * t) + 0.02 + solta * t * t
							caminho.append(c + u * raios * raio)
						var reto: float = float(grupo.get("reto", 0.0)) * r
						if reto > 0.0:
							var ultimo: Vector3 = caminho[-1]
							var fora := Vector3(ultimo.x - c.x, 0, ultimo.z - c.z).normalized() * 0.01 * e
							caminho.append(ultimo + Vector3(0, -reto * 0.5, 0) + fora)
							caminho.append(ultimo + Vector3(0, -reto, 0) + fora * 2.0)
						malha.mecha_larga("cabelo", caminho, c, larg, esp, pesos, material2, 0.65)

	match estilo:
		"moicano":
			for k in 9:
				var z := lerpf(r * 0.85, -r * 0.85, float(k) / 8.0)
				var unit := Vector3(0, sqrt(maxf(0.05, 1.0 - z * z / (r * r))), z / r).normalized()
				var base := c + unit * raios * 1.0
				var dir := (unit + Vector3(0, 0.7, -0.1)).normalized()
				var compr := r * (0.55 if absf(z) < r * 0.6 else 0.4)
				malha.mecha_larga("cabelo", [base, base + dir * compr * 0.4, base + dir * compr * 0.75, base + dir * compr], c, r * 0.3, r * 0.1, pesos)
		"coque":
			var coque := c + Vector3(0, r * 0.15, -raios.z * 1.05)
			malha.esfera("cabelo", coque, Vector3(0.045, 0.045, 0.04) * e, pesos, Callable(), 10, 8)
		"trancas":
			# Rabo de tranças atrás.
			for k in 5:
				var az := rng.randf_range(-0.5, 0.5)
				var base := c + Vector3(az * r * 0.5, -r * 0.1, -raios.z * 1.05)
				var caminho := [base, base + Vector3(az * 0.1 * r, -r * 0.4, -r * 0.12), base + Vector3(az * 0.2 * r, -r * 0.8, -r * 0.18), base + Vector3(az * 0.3 * r, -r * 1.15, -r * 0.2)]
				malha.mecha_larga("cabelo", caminho, c, r * 0.11, r * 0.09, pesos)
		"ondulado", "cacheado", "black_power":
			# Cachos: calombos facetados meio enterrados no volume (sem contorno
			# próprio, pra não parecer bolha), fora da frente do rosto.
			var qtd: int = {"ondulado": 10, "cacheado": 22, "black_power": 30}[estilo]
			var tamanho: float = {"ondulado": 0.2, "cacheado": 0.24, "black_power": 0.3}[estilo]
			var feitos := 0
			var tentativas := 0
			while feitos < qtd and tentativas < qtd * 4:
				tentativas += 1
				var az := rng.randf_range(0.0, TAU)
				var polar := rng.randf_range(0.1, deg_to_rad(88.0 if estilo != "black_power" else 105.0))
				var unit := Vector3(sin(polar) * cos(az), cos(polar), sin(polar) * sin(az))
				# Não cobre o rosto: na frente, só no alto da testa.
				if unit.z > 0.45 and unit.y < 0.55:
					continue
				malha.esfera("cacho", c + unit * raios * (1.0 + volume * 0.8), Vector3(1, 0.85, 1) * r * tamanho * rng.randf_range(0.8, 1.2), pesos, Callable(), 6, 4)
				feitos += 1
	if cabelo.get("raizes", "") != "":
		# Raiz escura no topo.
		malha.casca("cabelo2", c, func(_unit: Vector3, _t: float) -> Vector3: return raios * (1.0 + volume * 1.06 + 0.012), func(_a: float) -> float: return deg_to_rad(40.0), pesos, 20, 5)
	if cabelo.get("mecha_frente", "") != "":
		# Uma mecha de cor diferente bem no meio da franja.
		var u0 := _direcao(25.0, 90.0)
		var u1 := _direcao(85.0, 95.0)
		var caminho := []
		for i in 5:
			var t := float(i) / 4.0
			caminho.append(c + u0.slerp(u1, t).normalized() * raios * (1.0 + volume * (1.0 - 0.4 * t) + 0.05 + 0.1 * t * t))
		malha.mecha_larga("cabelo2", caminho, c, r * 0.22, r * 0.1, pesos)


# --- Materiais -------------------------------------------------------------------

static func _cor_da_pele(ap: Dictionary) -> Color:
	var pele := str(ap.get("pele", "clara"))
	if PELES.has(pele):
		return Color(PELES[pele])
	return Color.from_string(pele, Color(PELES["clara"]))


## Material anime (luz e sombra em faixas, shaders/atleta.gdshader) com contorno opcional.
static func _material(cor: Color, contorno: float, tom_da_sombra := Color(0.84, 0.8, 0.94), brilho := 0.0) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_ATLETA
	mat.set_shader_parameter("cor", cor)
	mat.set_shader_parameter("tom_da_sombra", tom_da_sombra)
	mat.set_shader_parameter("faixa_de_brilho", brilho)
	if contorno > 0.0:
		var borda := ShaderMaterial.new()
		borda.shader = SHADER_CONTORNO
		borda.set_shader_parameter("espessura", contorno * 0.42)
		borda.set_shader_parameter("cor_do_contorno", COR_CONTORNO)
		borda.set_shader_parameter("largura_minima_px", 1.5)
		mat.next_pass = borda
	return mat


## Rosto desenhado pelo shader (olhos, cílios, sobrancelhas, nariz e boca).
static func _material_do_rosto(ap: Dictionary, cor_pele: Color, cor_cabelo: Color, cor_olhos: Color) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_ROSTO
	var p := _parametros_do_rosto(ap)
	for chave in p:
		mat.set_shader_parameter(chave, p[chave])
	mat.set_shader_parameter("cor_da_iris", cor_olhos)
	mat.set_shader_parameter("cor_da_pele", cor_pele)
	mat.set_shader_parameter("cor_do_cilio", Color(0.11, 0.07, 0.08).lerp(cor_cabelo.darkened(0.6), 0.25))
	mat.set_shader_parameter("cor_da_sobrancelha", cor_cabelo.darkened(0.3) if cor_cabelo.get_luminance() > 0.25 else cor_cabelo.lightened(0.05))
	mat.render_priority = 1
	return mat


## Cor do número: a do uniforme ("cor_numero") ou, entre as cores de
## detalhe, a que mais contrasta com a camisa.
static func _cor_do_numero(uniforme: Dictionary, cores: Array) -> Color:
	if uniforme.has("cor_numero"):
		return Color.from_string(str(uniforme["cor_numero"]), Color.WHITE)
	var camisa := Color.from_string(str(cores[0]), Color.GRAY)
	var melhor := Color.WHITE
	var maior := -1.0
	for k in range(1, cores.size()):
		var cor := Color.from_string(str(cores[k]), Color.WHITE)
		var diferenca := absf(cor.get_luminance() - camisa.get_luminance())
		if diferenca > maior:
			maior = diferenca
			melhor = cor
	return melhor


## Cor chapada, sem sombra.
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
	# Sem mipmap: com ele os traços finos (1, 7) somem de longe.
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var caminho := "%s/%02d.png" % [PASTA_NUMEROS, numero]
	if ResourceLoader.exists(caminho):
		mat.albedo_texture = load(caminho)
	else:
		mat.albedo_color.a = 0.0
	return mat
