extends RefCounted
## Arena de campeonato (Arena Nacional, Arena Brasileira, Arena Neon): piso
## escuro brilhante, placas de LED com o letreiro em volta da área livre,
## arquibancadas em degraus dos quatro lados com público instanciado, telões
## nos fundos e luz de ginásio. Cores, letreiro e cores do público vêm de
## dados/estadios.json, então o mesmo código serve pros três.

const Pecas := preload("res://scripts/cenario/pecas.gd")

const FILAS := 6
const PROFUNDIDADE_DA_FILA := 0.95
const ALTURA_DA_FILA := 0.5
## Onde começam as arquibancadas (distância do meio).
const COMECO_LATERAL := 10.6
const COMECO_DO_FUNDO := 16.2


static func montar(c) -> void:
	var neon := bool(c.estadio.get("neon", false))
	_luz(c, neon)
	_piso(c)
	_placas(c, neon)
	_arquibancadas(c)
	_teloes(c, neon)


static func _luz(c, neon: bool) -> void:
	var ambiente := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = c.cor("fundo", Color("#0C1230"))
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = c.cor("luz", Color("#DCE6FF"))
	env.ambient_light_energy = 0.62 if neon else 0.8
	ambiente.environment = env
	c.add_child(ambiente)
	var luz := DirectionalLight3D.new()
	luz.name = "Refletores"
	luz.light_color = c.cor("luz", Color.WHITE)
	luz.light_energy = 0.85 if neon else 1.0
	luz.rotation_degrees = Vector3(-62.0, 25.0, 0.0)
	luz.shadow_enabled = true
	luz.directional_shadow_max_distance = 60.0
	c.add_child(luz)


static func _piso(c) -> void:
	Pecas.no_chao(c, Vector2(44.0, 56.0), Vector3.ZERO, Pecas.material(c.cor("zona_livre", Color("#1D2A5E")), 0.35))


## Placas de LED em volta da área livre, com o letreiro repetido.
static func _placas(c, neon: bool) -> void:
	var cor_da_placa: Color = c.cor("placas", Color("#2A50C8"))
	var fundo := Pecas.material(Color("#0E1220"), 0.4)
	var tela := Pecas.material_aceso(cor_da_placa, 1.1 if neon else 0.85)
	var letreiro: String = c.texto("letreiro", "CAMPEONATO")
	var meia_x := float(c.medidas.get("zona_livre", Vector2(17, 28)).x) / 2.0 + 0.2
	var meio_z := float(c.medidas.get("zona_livre", Vector2(17, 28)).y) / 2.0 + 0.2
	# [centro, comprimento, giro (de frente pra dentro)]
	for lado in [[Vector3(-meia_x, 0, 0), meio_z * 2.0, PI / 2.0], [Vector3(meia_x, 0, 0), meio_z * 2.0, -PI / 2.0],
			[Vector3(0, 0, -meio_z), meia_x * 2.0, 0.0], [Vector3(0, 0, meio_z), meia_x * 2.0, PI]]:
		var centro: Vector3 = lado[0]
		var comprimento: float = lado[1]
		var giro: float = lado[2]
		var frente := Vector3(sin(giro), 0.0, cos(giro))
		var caixa := Pecas.caixa(c, Vector3(comprimento, 0.95, 0.25), centro + Vector3(0, 0.475, 0) - frente * 0.1, fundo)
		caixa.rotation.y = giro
		Pecas.placa(c, Vector2(comprimento - 0.2, 0.75), centro + Vector3(0, 0.5, 0) + frente * 0.04, giro, tela)
		var direita := Vector3(cos(giro), 0.0, -sin(giro))
		var quantos := maxi(int(comprimento / 9.0), 1)
		for k in quantos:
			var desloca := (k - (quantos - 1) / 2.0) * (comprimento / quantos)
			Pecas.texto(c, letreiro, 0.42, Color("#FFFFFF"), centro + Vector3(0, 0.5, 0) + frente * 0.06 + direita * desloca, giro)


## Degraus dos quatro lados, com gente sentada.
static func _arquibancadas(c) -> void:
	var degrau := Pecas.material(c.cor("fundo", Color("#0C1230")).lightened(0.18), 0.8)
	var cores_do_publico: Array = []
	for texto in c.estadio.get("publico", ["#2A50C8", "#F2F2F2", "#E8C547"]):
		cores_do_publico.append(Color.from_string(str(texto), Color.GRAY))
	cores_do_publico.append(c.cor_do_menu_do_time(0))
	cores_do_publico.append(c.cor_do_menu_do_time(1))
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 777

	# Laterais (de frente pro meio) e fundos.
	for lado in [-1.0, 1.0]:
		var pessoas := []
		for fila in FILAS:
			var x: float = lado * (COMECO_LATERAL + fila * PROFUNDIDADE_DA_FILA + PROFUNDIDADE_DA_FILA / 2.0)
			var altura := (fila + 1) * ALTURA_DA_FILA
			Pecas.caixa(c, Vector3(PROFUNDIDADE_DA_FILA, altura, COMECO_DO_FUNDO * 2.0), Vector3(x, altura / 2.0, 0.0), degrau)
			var z := -COMECO_DO_FUNDO + 0.4
			while z < COMECO_DO_FUNDO - 0.4:
				if sorteio.randf() > 0.12:
					pessoas.append([Vector3(x, altura, z), cores_do_publico[sorteio.randi() % cores_do_publico.size()], -lado * PI / 2.0])
				z += 0.58
		Pecas.publico(c, pessoas, true)
	for lado in [-1.0, 1.0]:
		var pessoas := []
		for fila in FILAS:
			var z: float = lado * (COMECO_DO_FUNDO + fila * PROFUNDIDADE_DA_FILA + PROFUNDIDADE_DA_FILA / 2.0)
			var altura := (fila + 1) * ALTURA_DA_FILA
			var largura := COMECO_LATERAL * 2.0 + FILAS * PROFUNDIDADE_DA_FILA * 2.0
			Pecas.caixa(c, Vector3(largura, altura, PROFUNDIDADE_DA_FILA), Vector3(0.0, altura / 2.0, z), degrau)
			var x := -largura / 2.0 + 0.4
			while x < largura / 2.0 - 0.4:
				if sorteio.randf() > 0.12:
					pessoas.append([Vector3(x, altura, z), cores_do_publico[sorteio.randi() % cores_do_publico.size()], 0.0 if lado < 0.0 else PI])
				x += 0.58
		Pecas.publico(c, pessoas, true)


## Telão no alto de cada fundo, com o letreiro, e faixas laterais.
static func _teloes(c, neon: bool) -> void:
	var cor_da_placa: Color = c.cor("placas", Color("#2A50C8"))
	var letreiro: String = c.texto("letreiro", "CAMPEONATO")
	var z := COMECO_DO_FUNDO + FILAS * PROFUNDIDADE_DA_FILA + 0.6
	for lado in [-1.0, 1.0]:
		var giro: float = 0.0 if lado < 0.0 else PI
		var centro := Vector3(0.0, 6.6, lado * z)
		Pecas.placa(c, Vector2(13.0, 4.6), centro, giro, Pecas.material(Color("#0B0D14"), 0.4))
		var frente := Vector3(sin(giro), 0.0, cos(giro))
		Pecas.placa(c, Vector2(12.4, 4.0), centro + frente * 0.02, giro, Pecas.material_aceso(cor_da_placa.darkened(0.35), 1.0))
		Pecas.texto(c, letreiro, 0.85, Color.WHITE, centro + frente * 0.05, giro, Color(0, 0, 0, 0.6))
		# Fileira de refletores acesos em cima do telão.
		for k in 8:
			var holofote := Pecas.caixa(c, Vector3(0.5, 0.35, 0.3), centro + Vector3(-5.6 + k * 1.6, 3.0, 0.0), Pecas.material_aceso(Color("#FFF6E0"), 1.3))
			holofote.rotation.y = giro
	if neon:
		# Faixas de neon nas bordas das arquibancadas.
		for lado in [-1.0, 1.0]:
			Pecas.caixa(c, Vector3(0.08, 0.08, COMECO_DO_FUNDO * 2.0), Vector3(lado * COMECO_LATERAL, ALTURA_DA_FILA + 0.05, 0.0),
				Pecas.material_aceso(Color("#3AE0FF"), 1.4))
