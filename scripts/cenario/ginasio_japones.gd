extends RefCounted
## Ginásio de colégio japonês ao entardecer (referências: "image-gen-1" e
## "Vôlei no Ginásio ao Entardecer"): piso de madeira com manchas de sol,
## paredes com lambri e colunas de madeira, janelas grandes com o céu do fim
## de tarde, mezanino com guarda-corpo e faixas, palco com cortina vermelha
## num fundo e portas, placar de parede e relógio no outro, bancos com os
## carrinhos de bola e público no mezanino. Quadra, rede, árbitros, bancos e
## mesa do apontador são do cenário comum (cenario.gd).
##
## Tudo em formas simples (caixas, placas e alguns shaders), sem modelos
## externos. Os textos das faixas vêm de dados/estadios.json.

const Pecas := preload("res://scripts/cenario/pecas.gd")
const Polyfork := preload("res://scripts/cenario/polyfork.gd")
## Bolas do carrinho da Polyfork: os gomos pretos viram azuis e as laranjas,
## amarelas (cores de bola de vôlei). Veja assets/polyfork/manifesto.json.
const BOLAS_DE_VOLEI := {
	"ball-heap": {"080a0b": Color("#1E4FB8"), "e26202": Color("#F2C21B")},
	"ball-mesh": {"e26202": Color("#F2C21B")},
}
const SHADER_PISO := preload("res://shaders/piso_de_madeira.gdshader")
const SHADER_JANELA := preload("res://shaders/janela_entardecer.gdshader")
const SHADER_GRADE := preload("res://shaders/grade.gdshader")
const BRASAO := "res://arte/cenario/brasao_escola.svg"
const PASTA_EMBLEMAS := "res://arte/emblemas/%s.svg"

## Paredes laterais em x = ±LARGURA_INTERNA, fundos em z = ±COMPRIMENTO_INTERNO.
const LARGURA_INTERNA := 13.0
const COMPRIMENTO_INTERNO := 19.0
const ALTURA := 11.0
const ALTURA_DO_LAMBRI := 3.2
const ALTURA_DO_MEZANINO := 4.5
const FUNDO_DO_MEZANINO := 1.8
## Vãos entre as colunas das paredes laterais.
const VAO := 4.75

const MADEIRA_ESCURA := Color("#6E4428")
const MADEIRA_MEDIA := Color("#8C5A32")
const MADEIRA_CLARA := Color("#C7915A")
const PAREDE := Color("#E4CDA8")
const CORTINA := Color("#F2E8D5")


static func montar(c) -> void:
	_luz(c)
	_piso(c)
	_manchas_de_sol(c)
	_paredes(c)
	_janelas(c)
	_mezanino(c)
	_palco(c)
	_parede_das_portas(c)
	_objetos_de_quadra(c)
	_publico(c)
	_teto(c)
	_reflexos(c)


# --- Luz ---

static func _luz(c) -> void:
	var ambiente := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = c.cor("fundo", Color("#3B2A1E"))
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = c.cor("luz", Color("#FFE7C9"))
	env.ambient_light_energy = 0.8
	# Brilho leve nas janelas e luminárias (só no que é bem claro).
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.05
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	ambiente.environment = env
	c.add_child(ambiente)

	# Sol baixo do fim de tarde, entrando pelas janelas da esquerda.
	var sol := DirectionalLight3D.new()
	sol.name = "Sol"
	sol.light_color = c.cor("sol", Color("#FFC888"))
	sol.light_energy = 1.25
	sol.rotation_degrees = Vector3(-34.0, -70.0, 0.0)
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 60.0
	c.add_child(sol)


# --- Chão ---

static func _piso(c) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_PISO
	mat.set_shader_parameter("cor", c.cor("zona_livre", Color("#B9814A")))
	Pecas.no_chao(c, Vector2(LARGURA_INTERNA * 2.0, COMPRIMENTO_INTERNO * 2.0), Vector3.ZERO, mat)


## Luz do sol que passa pelas janelas e bate no chão de madeira (só fora da
## quadra, pra não atrapalhar a leitura da bola e das linhas).
static func _manchas_de_sol(c) -> void:
	# Cada janela vira um feixe de vidros compridos e inclinados (o sol está
	# baixo), como na referência.
	var luz := Pecas.material_de_luz(Color("#FFBF6E"), 0.24)
	var giro := deg_to_rad(-28.0)
	var vaos := int(COMPRIMENTO_INTERNO * 2.0 / VAO)
	for v in vaos:
		var z := -COMPRIMENTO_INTERNO + VAO * (v + 0.5)
		for coluna in 3:
			for linha in 2:
				var centro := Vector3(-11.4 + coluna * 1.0 + linha * 1.45, 0.013, z - 0.9 + coluna * 0.55 + linha * 0.75)
				Pecas.no_chao(c, Vector2(0.85, 1.9), centro, luz, giro)
	# Do lado do palco, a luz chega até a frente dele.
	for k in 6:
		Pecas.no_chao(c, Vector2(1.0, 2.2), Vector3(-8.6 + k * 1.6, 0.013, -15.9), luz, giro)


# --- Paredes ---

static func _paredes(c) -> void:
	var lambri := Pecas.material(MADEIRA_ESCURA, 0.7)
	var parede := Pecas.material(PAREDE, 0.95)
	var friso := Pecas.material(MADEIRA_CLARA, 0.6)
	var x := LARGURA_INTERNA
	var z := COMPRIMENTO_INTERNO
	var alto := ALTURA - ALTURA_DO_LAMBRI
	# [centro, largura, giro]: laterais de frente pra dentro, fundos idem.
	for lado in [[Vector3(-x, 0, 0), z * 2.0, PI / 2.0], [Vector3(x, 0, 0), z * 2.0, -PI / 2.0],
			[Vector3(0, 0, -z), x * 2.0, 0.0], [Vector3(0, 0, z), x * 2.0, PI]]:
		var centro: Vector3 = lado[0]
		var largura: float = lado[1]
		var giro: float = lado[2]
		Pecas.placa(c, Vector2(largura, ALTURA_DO_LAMBRI), centro + Vector3(0, ALTURA_DO_LAMBRI / 2.0, 0), giro, lambri)
		Pecas.placa(c, Vector2(largura, alto), centro + Vector3(0, ALTURA_DO_LAMBRI + alto / 2.0, 0), giro, parede)
		# Friso de madeira clara em cima do lambri.
		var para_dentro := Vector3(sin(giro), 0.0, cos(giro))
		var friso_no := Pecas.placa(c, Vector2(largura, 0.14), centro + Vector3(0, ALTURA_DO_LAMBRI, 0) + para_dentro * 0.02, giro, friso)
		friso_no.name = "Friso"

	# Colunas de madeira nas paredes laterais, entre as janelas.
	var coluna := Pecas.material(MADEIRA_MEDIA, 0.7)
	var vaos := int(z * 2.0 / VAO)
	for lado in [-1.0, 1.0]:
		for k in vaos + 1:
			var cz := -z + k * VAO
			Pecas.caixa(c, Vector3(0.45, ALTURA, 0.4), Vector3(lado * (x - 0.22), ALTURA / 2.0, cz), coluna)


static func _janelas(c) -> void:
	var x := LARGURA_INTERNA
	var z := COMPRIMENTO_INTERNO
	var cortina := Pecas.material(CORTINA, 0.95)
	var vaos := int(z * 2.0 / VAO)
	var y := ALTURA_DO_MEZANINO + 3.0
	for lado in [-1.0, 1.0]:
		var giro: float = PI / 2.0 if lado < 0.0 else -PI / 2.0
		for k in vaos:
			var cz := -z + VAO * (k + 0.5)
			var posicao := Vector3(lado * (x - 0.03), y, cz)
			_janela(c, Vector2(3.5, 3.8), posicao, giro, float(k) * 1.7 + (lado + 1.0) * 5.0)
			# Cortinas abertas dos dois lados da janela.
			for borda in [-1.0, 1.0]:
				Pecas.caixa(c, Vector3(0.12, 4.1, 0.38), Vector3(lado * (x - 0.1), y - 0.05, cz + borda * 1.9), cortina)
	# Três janelas altas no fundo das portas.
	for k in 3:
		_janela(c, Vector2(3.2, 2.6), Vector3(-7.5 + k * 7.5, 8.6, z - 0.03), PI, 30.0 + k)


static func _janela(c, tamanho: Vector2, posicao: Vector3, giro: float, semente: float) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_JANELA
	mat.set_shader_parameter("semente", semente)
	mat.set_shader_parameter("colunas", 4.0 if tamanho.x > 3.3 else 3.0)
	mat.set_shader_parameter("linhas", 3.0)
	Pecas.placa(c, tamanho, posicao, giro, mat)


## Mezanino (galeria) ao longo das duas laterais, com guarda-corpo e faixas.
static func _mezanino(c) -> void:
	var x := LARGURA_INTERNA
	var z := COMPRIMENTO_INTERNO
	var laje := Pecas.material(PAREDE.darkened(0.08), 0.9)
	var grade := ShaderMaterial.new()
	grade.shader = SHADER_GRADE
	grade.set_shader_parameter("cor", Color("#3E2C20"))
	grade.set_shader_parameter("altura", 1.05)
	for lado in [-1.0, 1.0]:
		var borda: float = lado * (x - FUNDO_DO_MEZANINO)
		Pecas.caixa(c, Vector3(FUNDO_DO_MEZANINO, 0.28, z * 2.0), Vector3(lado * (x - FUNDO_DO_MEZANINO / 2.0), ALTURA_DO_MEZANINO, 0.0), laje)
		var giro: float = PI / 2.0 if lado < 0.0 else -PI / 2.0
		Pecas.placa(c, Vector2(z * 2.0, 1.05), Vector3(borda, ALTURA_DO_MEZANINO + 0.14 + 0.525, 0.0), giro, grade)

	# Faixas penduradas no guarda-corpo: [lado, z, tipo, texto/time, cor].
	var faixas: Array = c.estadio.get("faixas_do_mezanino", [
		{"texto": "GARRA", "cor": "#5B3A8E"},
		{"texto": "CLUBE DE VÔLEI", "cor": "#F2EEE6", "cor_do_texto": "#2A2A2A"},
		{"texto": "RUMO À VITÓRIA!", "cor": "#B32630"},
		{"emblema": "bola", "cor": "#24305E"},
	])
	var lugares := [[-1.0, -9.5], [1.0, -2.4], [-1.0, 4.75], [1.0, 9.5]]
	for i in mini(faixas.size(), lugares.size()):
		_faixa_do_mezanino(c, lugares[i][0], lugares[i][1], faixas[i])
	# As faixas dos dois times que estão jogando.
	_faixa_do_time(c, 1.0, -9.5, 1)
	_faixa_do_time(c, -1.0, -2.4, 0)
	_faixa_do_time(c, 1.0, 4.75, 0)
	_faixa_do_time(c, -1.0, 9.5, 1)


static func _posicao_no_mezanino(lado: float, z: float) -> Array:
	var x: float = lado * (LARGURA_INTERNA - FUNDO_DO_MEZANINO - 0.06)
	var giro: float = PI / 2.0 if lado < 0.0 else -PI / 2.0
	return [Vector3(x, ALTURA_DO_MEZANINO + 0.45, z), giro]


static func _faixa_do_mezanino(c, lado: float, z: float, dados: Dictionary) -> void:
	var lugar := _posicao_no_mezanino(lado, z)
	var posicao: Vector3 = lugar[0]
	var giro: float = lugar[1]
	var fundo := Color.from_string(str(dados.get("cor", "#B32630")), Color.RED)
	Pecas.placa(c, Vector2(4.2, 1.35), posicao, giro, Pecas.material(fundo, 0.95))
	var frente := Vector3(sin(giro), 0.0, cos(giro)) * 0.02
	if dados.has("texto"):
		var cor_do_texto := Color.from_string(str(dados.get("cor_do_texto", "#F5F2EB")), Color.WHITE)
		Pecas.texto(c, str(dados["texto"]), 0.62, cor_do_texto, posicao + frente, giro)
	elif ResourceLoader.exists("res://arte/icones/saque.svg"):
		var bola := Pecas.imagem(c, load("res://arte/icones/saque.svg"), 0.9, posicao + frente, giro)
		bola.modulate = Color("#E7B53C")


## Faixa do time: na cor dele, com o emblema e o nome.
static func _faixa_do_time(c, lado: float, z: float, time: int) -> void:
	var lugar := _posicao_no_mezanino(lado, z)
	var posicao: Vector3 = lugar[0]
	var giro: float = lugar[1]
	var cores: Array = c.cores_do_time(time)
	var fundo: Color = cores[0]
	var detalhe: Color = cores[1]
	Pecas.placa(c, Vector2(4.2, 1.35), posicao, giro, Pecas.material(fundo, 0.95))
	var frente := Vector3(sin(giro), 0.0, cos(giro))
	var direita := Vector3(cos(giro), 0.0, -sin(giro))
	Pecas.placa(c, Vector2(4.2, 0.12), posicao + Vector3(0, -0.6, 0) + frente * 0.01, giro, Pecas.material(detalhe, 0.9))
	var caminho := PASTA_EMBLEMAS % c.id_do_time(time)
	if ResourceLoader.exists(caminho):
		Pecas.imagem(c, load(caminho), 1.1, posicao - direita * 1.35 + frente * 0.02, giro)
	var nome := str(c.times[time].get("nome", "")).to_upper() if time < c.times.size() else ""
	var cor_do_texto := Color("#14161C") if fundo.get_luminance() > 0.55 else Color("#F5F2EB")
	Pecas.texto(c, nome, 0.5, cor_do_texto, posicao + direita * 0.55 + frente * 0.02, giro)


# --- Fundo do palco (z negativo) ---

static func _palco(c) -> void:
	var z := -COMPRIMENTO_INTERNO
	var madeira := Pecas.material(MADEIRA_MEDIA, 0.6)
	var madeira_escura := Pecas.material(MADEIRA_ESCURA, 0.7)
	var largura := 13.0
	var fundo := 3.4
	var altura := 1.15
	# Plataforma e frente do palco.
	Pecas.caixa(c, Vector3(largura, altura, fundo), Vector3(0, altura / 2.0, z + fundo / 2.0), madeira_escura)
	Pecas.caixa(c, Vector3(largura + 0.1, 0.08, fundo + 0.1), Vector3(0, altura, z + fundo / 2.0), madeira)
	# Escadinhas dos lados.
	for lado in [-1.0, 1.0]:
		for k in 3:
			var degrau := Vector3(1.0, altura * (k + 1) / 4.0, 0.35)
			Pecas.caixa(c, degrau, Vector3(lado * (largura / 2.0 + 0.6), degrau.y / 2.0, z + fundo - 0.2 - k * 0.35), madeira)

	# Boca de cena: fundo claro, cortinas vermelhas, bambolina e moldura.
	var boca := 11.0
	var alto := 5.6
	Pecas.placa(c, Vector2(boca, alto), Vector3(0, altura + alto / 2.0, z + 0.05), 0.0, Pecas.material(Color("#D8D2C8"), 0.95))
	var vermelho := Pecas.material(Color("#A81E24"), 0.85)
	var vermelho_escuro := Pecas.material(Color("#7E1519"), 0.85)
	for lado in [-1.0, 1.0]:
		for k in 7:
			var dobra: float = lado * (boca / 2.0 - 0.18 - k * 0.32)
			Pecas.caixa(c, Vector3(0.34, alto - 0.3, 0.2), Vector3(dobra, altura + (alto - 0.3) / 2.0, z + 0.3 + (k % 2) * 0.08),
				vermelho if k % 2 == 0 else vermelho_escuro)
	Pecas.caixa(c, Vector3(boca + 0.4, 0.85, 0.25), Vector3(0, altura + alto - 0.42, z + 0.42), vermelho)
	Pecas.caixa(c, Vector3(boca + 0.4, 0.1, 0.27), Vector3(0, altura + alto - 0.86, z + 0.42), Pecas.material(Color("#D9A93A"), 0.5))
	# Moldura de madeira em volta da boca.
	Pecas.caixa(c, Vector3(boca + 1.6, 0.7, 0.3), Vector3(0, altura + alto + 0.35, z + 0.15), madeira)
	for lado in [-1.0, 1.0]:
		Pecas.caixa(c, Vector3(0.8, alto + 0.7, 0.3), Vector3(lado * (boca / 2.0 + 0.4), altura + (alto + 0.7) / 2.0, z + 0.15), madeira)

	# Caixas de som e o brasão da escola com a placa do nome em cima.
	var preto := Pecas.material(Color("#1E1E22"), 0.6)
	for lado in [-1.0, 1.0]:
		Pecas.caixa(c, Vector3(0.6, 0.9, 0.45), Vector3(lado * (boca / 2.0 + 1.4), 6.6, z + 0.3), preto)
	if ResourceLoader.exists(BRASAO):
		Pecas.imagem(c, load(BRASAO), 1.3, Vector3(0, altura + alto + 1.35, z + 0.32), 0.0)
	var placa_y := altura + alto + 2.5
	Pecas.caixa(c, Vector3(6.4, 1.0, 0.12), Vector3(0, placa_y, z + 0.08), madeira_escura)
	Pecas.caixa(c, Vector3(6.1, 0.78, 0.13), Vector3(0, placa_y, z + 0.09), Pecas.material(Color("#F1E7D3"), 0.9))
	Pecas.texto(c, c.texto("placa_da_escola", "COLÉGIO VOLEIBOL"), 0.5, Color("#2B211A"), Vector3(0, placa_y, z + 0.17), 0.0)

	# Faixas verticais dos dois lados do palco (letras empilhadas).
	var verticais: Array = c.estadio.get("faixas_do_palco", [
		{"texto": "DESAFIO", "cor": "#A82828"}, {"texto": "UNIÃO", "cor": "#26408A"},
	])
	for i in mini(verticais.size(), 2):
		var lado := -1.0 if i == 0 else 1.0
		var dados: Dictionary = verticais[i]
		var posicao := Vector3(lado * (boca / 2.0 + 2.6), 5.3, z + 0.06)
		Pecas.placa(c, Vector2(1.25, 3.7), posicao, 0.0, Pecas.material(Color.from_string(str(dados.get("cor", "#A82828")), Color.RED), 0.95))
		var letras := "\n".join(Array(str(dados.get("texto", "")).split("")))
		var rotulo := Pecas.texto(c, letras, 0.42, Color("#F5F2EB"), posicao + Vector3(0, 0, 0.02), 0.0)
		rotulo.line_spacing = -18.0

	# Portas dos lados do palco, com placa de saída verde.
	_porta(c, Vector3(-10.6, 0.0, z + 0.04), 0.0)
	_porta(c, Vector3(10.6, 0.0, z + 0.04), 0.0)

	# Quadro branco e carrinho de bolas na frente da porta da esquerda.
	_quadro_branco(c, Vector3(-8.3, 0.0, z + 2.2), 0.25)
	_carrinho_de_bolas(c, Vector3(-11.2, 0.0, z + 2.6), 0.5)
	_mesa_de_agua(c, Vector3(11.2, 0.0, z + 2.2))


static func _porta(c, base: Vector3, giro: float) -> void:
	var frente := Vector3(sin(giro), 0.0, cos(giro))
	Pecas.placa(c, Vector2(2.3, 2.6), base + Vector3(0, 1.3, 0), giro, Pecas.material(Color("#3A2A1E"), 0.8))
	for lado in [-1.0, 1.0]:
		var direita := Vector3(cos(giro), 0.0, -sin(giro))
		Pecas.placa(c, Vector2(0.98, 2.4), base + Vector3(0, 1.22, 0) + direita * lado * 0.52 + frente * 0.01, giro, Pecas.material(Color("#7D8A84"), 0.6))
	Pecas.caixa(c, Vector3(0.6, 0.22, 0.06), base + Vector3(0, 2.85, 0) + frente * 0.05, Pecas.material_aceso(Color("#3DDC84"), 1.1))


static func _quadro_branco(c, base: Vector3, giro: float) -> void:
	# Quadro da Polyfork num suporte com rodinhas; sem o arquivo, o desenhado.
	var modelo := Polyfork.modelo("whiteboard-ea98f7")
	if modelo != null:
		var suporte := Node3D.new()
		suporte.position = base
		suporte.rotation.y = giro
		c.add_child(suporte)
		var metal := Pecas.material(Color("#9AA0A8"), 0.4, 0.5)
		for lado in [-0.85, 0.85]:
			Pecas.caixa(suporte, Vector3(0.05, 1.9, 0.05), Vector3(lado, 0.95, -0.08), metal)
			Pecas.caixa(suporte, Vector3(0.05, 0.05, 0.55), Vector3(lado, 0.05, -0.08), metal)
		# O quadro vem pendurado (a parte de baixo a 0,9 m); fica na mesma altura.
		modelo.position = Vector3(0.0, 0.8, 0.0)
		suporte.add_child(modelo)
		return
	var quadro := Node3D.new()
	quadro.position = base
	quadro.rotation.y = giro
	c.add_child(quadro)
	var metal := Pecas.material(Color("#9AA0A8"), 0.4, 0.5)
	for lado in [-0.85, 0.85]:
		Pecas.caixa(quadro, Vector3(0.05, 1.9, 0.05), Vector3(lado, 0.95, 0.0), metal)
		Pecas.caixa(quadro, Vector3(0.05, 0.05, 0.55), Vector3(lado, 0.05, 0.0), metal)
	Pecas.caixa(quadro, Vector3(1.8, 1.05, 0.04), Vector3(0, 1.35, 0.0), Pecas.material(Color("#F4F6F7"), 0.3))
	# Desenho da quadra no quadro.
	var azul := Pecas.material(Color("#2E5FA8"), 0.8)
	Pecas.caixa(quadro, Vector3(1.1, 0.02, 0.045), Vector3(0, 1.1, 0.0), azul)
	Pecas.caixa(quadro, Vector3(1.1, 0.02, 0.045), Vector3(0, 1.6, 0.0), azul)
	for x in [-0.55, 0.0, 0.55]:
		Pecas.caixa(quadro, Vector3(0.02, 0.5, 0.045), Vector3(x, 1.35, 0.0), azul)


static func _carrinho_de_bolas(c, base: Vector3, giro := 0.0) -> void:
	# Carrinho da Polyfork com as bolas pintadas de vôlei; sem o arquivo, o desenhado.
	var modelo := Polyfork.modelo("ball-cart-8274fd", BOLAS_DE_VOLEI)
	if modelo != null:
		modelo.position = base
		modelo.rotation.y = giro
		c.add_child(modelo)
		return
	var metal := Pecas.material(Color("#2F5DB8"), 0.5, 0.3)
	Pecas.caixa(c, Vector3(0.9, 0.05, 0.6), base + Vector3(0, 0.25, 0), metal)
	for dx in [-0.43, 0.43]:
		for dz in [-0.28, 0.28]:
			Pecas.caixa(c, Vector3(0.04, 0.95, 0.04), base + Vector3(dx, 0.47, dz), metal)
	Pecas.caixa(c, Vector3(0.9, 0.04, 0.04), base + Vector3(0, 0.95, -0.28), metal)
	Pecas.caixa(c, Vector3(0.9, 0.04, 0.04), base + Vector3(0, 0.95, 0.28), metal)
	var amarelo := Pecas.material(Color("#F2C230"), 0.6)
	var azul := Pecas.material(Color("#2B5CC7"), 0.6)
	for i in 10:
		var px := -0.3 + (i % 4) * 0.2
		var pz := -0.15 + (i / 4 % 2) * 0.3
		var py := 0.4 + (i / 8) * 0.2 + (i % 2) * 0.12
		Pecas.esfera(c, 0.105, base + Vector3(px, py + 0.25, pz), amarelo if i % 3 != 0 else azul)


static func _mesa_de_agua(c, base: Vector3) -> void:
	var madeira := Pecas.material(MADEIRA_MEDIA, 0.6)
	Pecas.caixa(c, Vector3(1.6, 0.06, 0.6), base + Vector3(0, 0.75, 0), madeira)
	for dx in [-0.75, 0.75]:
		Pecas.caixa(c, Vector3(0.05, 0.75, 0.55), base + Vector3(dx, 0.375, 0), madeira)
	Pecas.cilindro(c, 0.16, 0.42, base + Vector3(-0.4, 0.99, 0), Pecas.material(Color("#2F7FD8"), 0.4), 12)
	Pecas.caixa(c, Vector3(0.45, 0.14, 0.3), base + Vector3(0.35, 0.85, 0), Pecas.material(Color("#F5F5F2"), 0.95))


# --- Fundo das portas (z positivo) ---

static func _parede_das_portas(c) -> void:
	var z := COMPRIMENTO_INTERNO
	var giro := PI
	# Portão de correr de metal no meio.
	Pecas.placa(c, Vector2(6.4, 3.9), Vector3(0, 1.95, z - 0.04), giro, Pecas.material(Color("#5E6670"), 0.5, 0.3))
	for k in 9:
		Pecas.placa(c, Vector2(0.05, 3.6), Vector3(-2.8 + k * 0.7, 1.85, z - 0.06), giro, Pecas.material(Color("#454B53"), 0.5, 0.3))
	Pecas.caixa(c, Vector3(6.8, 0.25, 0.2), Vector3(0, 4.0, z - 0.1), Pecas.material(MADEIRA_ESCURA, 0.7))

	# Placar de parede com as cores e os nomes dos dois times.
	var placar_y := 6.4
	Pecas.caixa(c, Vector3(5.6, 1.9, 0.18), Vector3(0, placar_y, z - 0.09), Pecas.material(Color("#1A1C20"), 0.5))
	for time in 2:
		var lado := 1.0 if time == 0 else -1.0
		var cor_do_time: Color = c.cor_do_menu_do_time(time)
		Pecas.placa(c, Vector2(2.4, 0.42), Vector3(lado * 1.3, placar_y + 0.6, z - 0.19), giro, Pecas.material_aceso(cor_do_time, 1.0))
		var nome := str(c.times[time].get("nome", "")).to_upper() if time < c.times.size() else ""
		Pecas.texto(c, nome, 0.3, Color.WHITE, Vector3(lado * 1.3, placar_y + 0.6, z - 0.2), giro)
		Pecas.texto(c, "00", 0.75, Color("#FFB23A"), Vector3(lado * 1.3, placar_y - 0.25, z - 0.2), giro)
	Pecas.texto(c, "SET", 0.3, Color("#D8D8D8"), Vector3(0, placar_y + 0.05, z - 0.2), giro)

	# Relógio de parede.
	var relogio := Pecas.cilindro(c, 0.5, 0.08, Vector3(-6.2, 6.4, z - 0.06), Pecas.material(Color("#F7F5EF"), 0.5), 20)
	relogio.rotation.x = PI / 2.0
	var aro := Pecas.cilindro(c, 0.55, 0.06, Vector3(-6.2, 6.4, z - 0.03), Pecas.material(Color("#2A2A2E"), 0.5), 20)
	aro.rotation.x = PI / 2.0
	var ponteiros := Pecas.material(Color("#1A1A1A"), 0.5)
	var ponteiro := Pecas.caixa(c, Vector3(0.03, 0.36, 0.02), Vector3(-6.2, 6.52, z - 0.11), ponteiros)
	ponteiro.rotation.z = 0.5
	Pecas.caixa(c, Vector3(0.03, 0.26, 0.02), Vector3(-6.13, 6.34, z - 0.11), ponteiros).rotation.z = -1.9

	# Faixa comprida em cima do portão.
	var faixa: Dictionary = c.estadio.get("faixa_do_fundo", {"texto": "FORÇA, EQUIPE!", "cor": "#1F3A6E"})
	var fundo_da_faixa := Color.from_string(str(faixa.get("cor", "#1F3A6E")), Color.BLUE)
	Pecas.placa(c, Vector2(7.5, 1.0), Vector3(7.6, 3.4, z - 0.05), giro, Pecas.material(fundo_da_faixa, 0.95))
	Pecas.texto(c, str(faixa.get("texto", "")), 0.55, Color("#F5F2EB"), Vector3(7.6, 3.4, z - 0.07), giro)

	_porta(c, Vector3(-10.6, 0.0, z - 0.04), giro)
	_carrinho_de_bolas(c, Vector3(9.8, 0.0, z - 2.0), PI + 0.3)
	_carrinho_de_bolas(c, Vector3(11.2, 0.0, z - 2.3), PI - 0.4)
	# Cadeiras dobráveis azuis encostadas.
	var azul := Pecas.material(Color("#2E5AA8"), 0.6)
	for k in 6:
		var base := Vector3(-8.2 + k * 0.62, 0.0, z - 0.7)
		Pecas.caixa(c, Vector3(0.45, 0.04, 0.42), base + Vector3(0, 0.45, 0), azul)
		Pecas.caixa(c, Vector3(0.45, 0.45, 0.04), base + Vector3(0, 0.7, 0.2), azul)
		Pecas.caixa(c, Vector3(0.04, 0.45, 0.04), base + Vector3(-0.2, 0.22, -0.18), azul)
		Pecas.caixa(c, Vector3(0.04, 0.45, 0.04), base + Vector3(0.2, 0.22, -0.18), azul)


# --- O que fica perto da quadra ---

static func _objetos_de_quadra(c) -> void:
	# Toalhas e garrafas perto dos bancos.
	for time in 2:
		var lado := 1.0 if time == 0 else -1.0
		var base := Vector3(10.4, 0.0, lado * 9.4)
		Pecas.caixa(c, Vector3(0.5, 0.3, 0.35), base + Vector3(0, 0.15, 0), Pecas.material(Color("#2F7FD8"), 0.5))
		Pecas.cilindro(c, 0.04, 0.24, base + Vector3(-0.15, 0.42, 0.0), Pecas.material(Color("#E8EEF2", 0.9), 0.2), 8)


# --- Teto e reflexos ---

## Treliças de madeira, forro e luminárias penduradas. Fica acima da câmera de
## jogo (aparece nas visões do alto e na prévia do estádio).
static func _teto(c) -> void:
	var forro := Pecas.material(Color("#9B6B42"), 0.8)
	var viga := Pecas.material(MADEIRA_ESCURA, 0.7)
	var x := LARGURA_INTERNA
	var z := COMPRIMENTO_INTERNO
	# Forro (de frente pra baixo, então não aparece pra quem está acima dele).
	var teto := Pecas.no_chao(c, Vector2(x * 2.0, z * 2.0), Vector3(0, ALTURA + 0.6, 0), forro)
	teto.rotation.x = PI
	# Tesouras de madeira de parede a parede, alinhadas com as colunas.
	var vaos := int(z * 2.0 / VAO)
	for k in vaos + 1:
		var tz := -z + k * VAO
		Pecas.caixa(c, Vector3(x * 2.0, 0.35, 0.3), Vector3(0, ALTURA - 0.2, tz), viga)
		for lado in [-1.0, 1.0]:
			# Pernas inclinadas da tesoura subindo pro meio.
			var perna := Pecas.caixa(c, Vector3(x * 1.05, 0.25, 0.25), Vector3(lado * x * 0.5, ALTURA + 0.25, tz), viga)
			perna.rotation.z = lado * -0.08
		for montante in [-0.66, -0.33, 0.33, 0.66]:
			Pecas.caixa(c, Vector3(0.14, 0.75, 0.14), Vector3(montante * x, ALTURA + 0.15, tz), viga)
	# Luminárias: cúpula escura e lâmpada acesa, em duas fileiras.
	var cupula := Pecas.material(Color("#2E3036"), 0.5, 0.4)
	var lampada := Pecas.material_aceso(Color("#FFE9B8"), 1.6)
	for k in vaos:
		var lz := -z + VAO * (k + 0.5)
		for lx in [-5.5, 5.5]:
			Pecas.cilindro(c, 0.012, 1.4, Vector3(lx, ALTURA - 0.75, lz), viga, 4)
			var copa := Pecas.cilindro(c, 0.42, 0.28, Vector3(lx, ALTURA - 1.55, lz), cupula, 12)
			copa.mesh.top_radius = 0.12
			Pecas.esfera(c, 0.2, Vector3(lx, ALTURA - 1.72, lz), lampada)


## Reflexo das janelas e das paredes no piso encerado: uma captura só, no começo.
static func _reflexos(c) -> void:
	var sonda := ReflectionProbe.new()
	sonda.name = "Reflexos"
	sonda.update_mode = ReflectionProbe.UPDATE_ONCE
	sonda.size = Vector3(LARGURA_INTERNA * 2.0, ALTURA, COMPRIMENTO_INTERNO * 2.0)
	sonda.position = Vector3(0.0, ALTURA / 2.0, 0.0)
	sonda.origin_offset = Vector3(0.0, -ALTURA / 2.0 + 1.6, 0.0)
	sonda.box_projection = true
	sonda.interior = true
	sonda.intensity = 0.7
	sonda.ambient_mode = ReflectionProbe.AMBIENT_DISABLED
	c.add_child(sonda)


# --- Público ---

## Gente em pé no mezanino, atrás do guarda-corpo, com camisas do colégio e dos times.
static func _publico(c) -> void:
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 4242
	var cores_gerais := [Color("#1F2A44"), Color("#F2F2F2"), Color("#2B2B2B"), Color("#3A4E7A"), Color("#8C2D2D")]
	for lado in [-1.0, 1.0]:
		var pessoas := []
		var z := -COMPRIMENTO_INTERNO + 1.5
		while z < COMPRIMENTO_INTERNO - 1.5:
			z += sorteio.randf_range(0.45, 1.1)
			if sorteio.randf() < 0.2:
				continue
			var fila := sorteio.randi_range(0, 1)
			var x: float = lado * (LARGURA_INTERNA - 0.5 - fila * 0.6)
			var cor: Color
			var sorte := sorteio.randf()
			if sorte < 0.25:
				cor = c.cores_do_time(0)[0]
			elif sorte < 0.5:
				cor = c.cores_do_time(1)[0]
			else:
				cor = cores_gerais[sorteio.randi() % cores_gerais.size()]
			pessoas.append([Vector3(x, ALTURA_DO_MEZANINO + 0.14, z), cor, -lado * PI / 2.0])
		Pecas.publico(c, pessoas, false)
