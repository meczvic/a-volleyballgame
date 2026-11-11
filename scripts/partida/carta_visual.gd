extends Control
## Uma carta do Modo Caos, desenhada em código (sem ilustração pintada): moldura
## chanfrada, aba da raridade em cima, uma "arte" com o ícone do conjunto e um
## fundo próprio da raridade, um hexágono com o ícone, o nome, o conjunto e o efeito.
##
## Raridades (as de dados/cartas.json):
## - prata: moldura prateada fina, fundo de aço com reflexos inclinados;
## - ouro: moldura dourada mais grossa que brilha, raios saindo do ícone e um
##   reflexo que passa de tempos em tempos;
## - prismatica: moldura arco-íris que gira as cores, facetas coloridas que
##   cintilam no fundo e brilho que pulsa.
## Estados (definir_estado): escolhida (o cursor do jogador está nela: contorno
## na cor dele), confirmada (selo ESCOLHIDA) e apagada (as outras, depois
## que o jogador escolheu). Subir e crescer fica por conta de quem usa a carta.

const Estilo := preload("res://scripts/menus/estilo.gd")

const TAMANHO := Vector2(236.0, 336.0)
const CHANFRO := 18.0
## Área da "arte" (fundo + ícone grande).
const ARTE := Rect2(14.0, 30.0, 208.0, 138.0)
const RAIO_DO_HEXAGONO := 27.0
const FUNDO_DA_CARTA := Color("#151920")

const COR_DA_RARIDADE := {
	"prata": Color("#C9D1DD"),
	"ouro": Color("#F2C14E"),
	"prismatica": Color("#C08CFF"),
}
const NOME_DA_RARIDADE := { "prata": "PRATA", "ouro": "OURO", "prismatica": "PRISMÁTICA" }
## Fundo da arte: [cor de cima, cor de baixo].
const FUNDO_DA_RARIDADE := {
	"prata": [Color("#3A4250"), Color("#181C24")],
	"ouro": [Color("#6B4A12"), Color("#221704")],
	"prismatica": [Color("#43207E"), Color("#120926")],
}
## Cor do ícone grande no meio da arte.
const COR_DO_ICONE := {
	"prata": Color("#E8EDF4"),
	"ouro": Color("#FFE7A3"),
	"prismatica": Color("#FFFFFF"),
}
const ESPESSURA_DA_MOLDURA := { "prata": 4.0, "ouro": 6.0, "prismatica": 6.0 }
const CORES_PRISMATICAS := [
	Color("#FF5FA2"), Color("#FFB35F"), Color("#FFE15F"), Color("#7CFFB2"), Color("#5FD3FF"), Color("#B98CFF"),
]
## Conjunto (dados/cartas.json) -> [ícone em arte/icones/, nome na carta].
const CONJUNTOS := {
	"ataque": ["ataque", "ATAQUE"],
	"defesa": ["defesa", "DEFESA"],
	"saque": ["saque", "SAQUE"],
	"rede": ["bloqueio", "REDE"],
	"velocidade": ["velocidade", "VELOCIDADE"],
	"coringa": ["coringa", "CORINGA"],
}
const PASTA_ICONES := "res://arte/icones/%s.svg"

var carta: Dictionary = {}
var raridade := "prata"
var cor_do_jogador := Color.WHITE
var escolhida := false
var confirmada := false
var apagada := false

var _tempo := 0.0
## Facetas da carta prismática: [triângulo, cor, fase do brilho].
var _facetas: Array = []
var _selo: Label


## Monta a carta. Chame antes de pôr na tela.
func configurar(dados: Dictionary, cor: Color) -> void:
	carta = dados
	cor_do_jogador = cor
	raridade = str(dados.get("raridade", "prata"))
	if not COR_DA_RARIDADE.has(raridade):
		raridade = "prata"
	size = TAMANHO
	pivot_offset = TAMANHO / 2.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tempo = randf() * 3.0
	_criar_textos()
	if raridade == "prismatica":
		_criar_facetas()


func definir_estado(esta_escolhida: bool, esta_confirmada: bool, esta_apagada: bool) -> void:
	escolhida = esta_escolhida
	confirmada = esta_confirmada
	apagada = esta_apagada
	_selo.visible = confirmada
	modulate = Color(0.55, 0.55, 0.6, 0.55) if apagada else Color.WHITE
	queue_redraw()


func cor_da_raridade() -> Color:
	return COR_DA_RARIDADE[raridade]


func _process(delta: float) -> void:
	_tempo += delta
	# Só as cartas que se mexem são redesenhadas.
	if raridade != "prata" or escolhida:
		queue_redraw()


# --- Desenho ---

func _draw() -> void:
	var espessura: float = ESPESSURA_DA_MOLDURA[raridade]
	var cor := cor_da_raridade()

	if escolhida and not apagada:
		# Contorno na cor do jogador, com um brilho que pulsa em volta.
		var pulso := 0.5 + 0.5 * sin(_tempo * 5.0)
		draw_colored_polygon(_chanfrado(Rect2(Vector2.ZERO, TAMANHO).grow(14.0), CHANFRO + 10.0), Color(cor_do_jogador, 0.18 + 0.1 * pulso))
		draw_colored_polygon(_chanfrado(Rect2(Vector2.ZERO, TAMANHO).grow(7.0), CHANFRO + 5.0), Color(cor_do_jogador, 0.85))
	elif raridade != "prata":
		# Ouro e prismática têm um brilho fraco em volta, que pulsa.
		var brilho := 0.16 + 0.1 * sin(_tempo * 2.4)
		draw_colored_polygon(_chanfrado(Rect2(Vector2.ZERO, TAMANHO).grow(8.0), CHANFRO + 6.0), Color(cor, brilho))

	# Moldura.
	var externo := _chanfrado(Rect2(Vector2.ZERO, TAMANHO), CHANFRO)
	if raridade == "prismatica":
		draw_polygon(externo, _cores_prismaticas(externo.size(), _tempo * 0.35))
	else:
		draw_colored_polygon(externo, cor)
	draw_colored_polygon(_chanfrado(Rect2(Vector2.ZERO, TAMANHO).grow(-espessura), CHANFRO - espessura * 0.4), FUNDO_DA_CARTA)

	_desenhar_arte()
	_desenhar_aba()
	_desenhar_hexagono()


func _desenhar_arte() -> void:
	var cores: Array = FUNDO_DA_RARIDADE[raridade]
	var cima: Color = cores[0]
	var baixo: Color = cores[1]
	var r := ARTE
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([cima, cima, baixo, baixo]))
	var area := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var centro := r.get_center() + Vector2(0.0, -6.0)

	match raridade:
		"prata":
			# Três reflexos inclinados, parados.
			for k in 3:
				var x := r.position.x + 30.0 + k * 62.0
				var largura := 16.0 - k * 4.0
				_poligono_recortado(PackedVector2Array([
					Vector2(x + 40.0, r.position.y), Vector2(x + 40.0 + largura, r.position.y),
					Vector2(x + largura - 10.0, r.end.y), Vector2(x - 10.0, r.end.y),
				]), area, Color(1.0, 1.0, 1.0, 0.07))
		"ouro":
			# Raios saindo do ícone, girando devagar.
			var quantos := 16
			for k in quantos:
				if k % 2 == 1:
					continue
				var a0 := TAU * k / quantos + _tempo * 0.15
				var a1 := TAU * (k + 1) / quantos + _tempo * 0.15
				draw_colored_polygon(PackedVector2Array([
					centro, _na_borda(centro, Vector2.from_angle(a0), r), _na_borda(centro, Vector2.from_angle(a1), r),
				]), Color(1.0, 0.85, 0.4, 0.13))
			# Reflexo que passa a cada 2,6 s.
			var fase := fmod(_tempo, 2.6) / 0.7
			if fase < 1.0:
				var x := lerpf(r.position.x - 60.0, r.end.x + 20.0, fase)
				_poligono_recortado(PackedVector2Array([
					Vector2(x + 40.0, r.position.y), Vector2(x + 64.0, r.position.y),
					Vector2(x + 24.0, r.end.y), Vector2(x, r.end.y),
				]), area, Color(1.0, 0.97, 0.85, 0.35))
		"prismatica":
			for faceta in _facetas:
				var fase: float = faceta[2]
				var cor_da_faceta: Color = faceta[1]
				cor_da_faceta.a = 0.18 + 0.2 * (0.5 + 0.5 * sin(_tempo * 2.2 + fase))
				draw_colored_polygon(faceta[0], cor_da_faceta)

	# Brilho atrás do ícone.
	var cor := cor_da_raridade()
	for k in 4:
		draw_circle(centro, 46.0 - k * 9.0, Color(cor, 0.06 + k * 0.03))
	draw_rect(r, Color(cor, 0.55), false, 1.5)


func _desenhar_aba() -> void:
	var meio := TAMANHO.x / 2.0
	var pontos := PackedVector2Array([
		Vector2(meio - 72.0, -6.0), Vector2(meio + 72.0, -6.0), Vector2(meio + 60.0, 22.0), Vector2(meio - 60.0, 22.0),
	])
	if raridade == "prismatica":
		draw_polygon(pontos, _cores_prismaticas(4, _tempo * 0.35 + 0.3))
	else:
		draw_colored_polygon(pontos, cor_da_raridade())
	draw_polyline(_fechado(pontos), Color(0.05, 0.05, 0.07, 0.8), 2.0)


func _desenhar_hexagono() -> void:
	var centro := Vector2(TAMANHO.x / 2.0, ARTE.end.y)
	var pontos := PackedVector2Array()
	for k in 6:
		pontos.append(centro + Vector2.from_angle(TAU * k / 6.0) * RAIO_DO_HEXAGONO)
	draw_colored_polygon(pontos, Color("#0E1117"))
	var cor := cor_da_raridade()
	if raridade == "prismatica":
		cor = Color.from_hsv(fmod(_tempo * 0.35, 1.0), 0.55, 1.0)
	draw_polyline(_fechado(pontos), cor, 3.0)


# --- Textos e ícones (nós filhos) ---

func _criar_textos() -> void:
	var cor := cor_da_raridade()
	var aba := Estilo.rotulo(NOME_DA_RARIDADE.get(raridade, raridade.to_upper()), 17, Color("#14161C"), true)
	aba.position = Vector2(0.0, -6.0)
	aba.size = Vector2(TAMANHO.x, 28.0)
	aba.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aba.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(aba)

	var conjunto := str(carta.get("conjunto", ""))
	var dados_do_conjunto: Array = CONJUNTOS.get(conjunto, [conjunto, conjunto.to_upper()])
	var caminho := PASTA_ICONES % dados_do_conjunto[0]
	var textura: Texture2D = load(caminho) if ResourceLoader.exists(caminho) else null

	var grande := _icone(textura, 78.0, COR_DO_ICONE[raridade])
	grande.position = ARTE.get_center() + Vector2(-39.0, -45.0)
	add_child(grande)
	var pequeno := _icone(textura, 28.0, cor)
	pequeno.position = Vector2(TAMANHO.x / 2.0 - 14.0, ARTE.end.y - 14.0)
	add_child(pequeno)

	var nome_texto := str(carta.get("nome", "?"))
	var tamanho_do_nome := 28
	while tamanho_do_nome > 18 and Estilo.FONTE_TITULO.get_string_size(nome_texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho_do_nome).x > TAMANHO.x - 24.0:
		tamanho_do_nome -= 1
	var nome := Estilo.rotulo(nome_texto, tamanho_do_nome, Estilo.TEXTO, true)
	nome.position = Vector2(8.0, ARTE.end.y + 28.0)
	nome.size = Vector2(TAMANHO.x - 16.0, 34.0)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(nome)

	var rotulo_do_conjunto := Estilo.rotulo("CONJUNTO  ·  %s" % dados_do_conjunto[1], 15, cor, true)
	rotulo_do_conjunto.position = Vector2(8.0, ARTE.end.y + 62.0)
	rotulo_do_conjunto.size = Vector2(TAMANHO.x - 16.0, 20.0)
	rotulo_do_conjunto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(rotulo_do_conjunto)

	var efeito := Estilo.rotulo(str(carta.get("efeito", "")), 18, Estilo.TEXTO_SUAVE)
	# A quebra de linha vem antes do tamanho, senão o texto estica a caixa.
	efeito.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	efeito.position = Vector2(16.0, ARTE.end.y + 86.0)
	efeito.size = Vector2(TAMANHO.x - 32.0, TAMANHO.y - ARTE.end.y - 96.0)
	efeito.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(efeito)

	_selo = Estilo.etiqueta("ESCOLHIDA", Estilo.PRONTO, 22)
	_selo.position = Vector2(TAMANHO.x / 2.0 - 70.0, TAMANHO.y - 24.0)
	_selo.size = Vector2(140.0, 32.0)
	_selo.visible = false
	add_child(_selo)


func _icone(textura: Texture2D, tamanho: float, cor: Color) -> TextureRect:
	var icone := TextureRect.new()
	icone.texture = textura
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.size = Vector2.ONE * tamanho
	icone.self_modulate = cor
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icone


## Triângulos tortos cobrindo a arte, com cores do arco-íris. A mesma carta
## sempre sai com as mesmas facetas.
func _criar_facetas() -> void:
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = hash(str(carta.get("id", "")))
	var colunas := 5
	var linhas := 3
	var pontos := []
	for l in linhas + 1:
		var linha := []
		for c in colunas + 1:
			var p := ARTE.position + Vector2(ARTE.size.x * c / colunas, ARTE.size.y * l / linhas)
			if c > 0 and c < colunas and l > 0 and l < linhas:
				p += Vector2(sorteio.randf_range(-14.0, 14.0), sorteio.randf_range(-10.0, 10.0))
			linha.append(p)
		pontos.append(linha)
	for l in linhas:
		for c in colunas:
			var a: Vector2 = pontos[l][c]
			var b: Vector2 = pontos[l][c + 1]
			var d: Vector2 = pontos[l + 1][c]
			var e: Vector2 = pontos[l + 1][c + 1]
			for tri in [[a, b, e], [a, e, d]]:
				var cor: Color = CORES_PRISMATICAS[sorteio.randi() % CORES_PRISMATICAS.size()]
				_facetas.append([PackedVector2Array(tri), cor, sorteio.randf() * TAU])


# --- Ajudantes de geometria ---

## Retângulo com os cantos cortados.
func _chanfrado(r: Rect2, chanfro: float) -> PackedVector2Array:
	var c := maxf(chanfro, 0.0)
	return PackedVector2Array([
		r.position + Vector2(c, 0.0), Vector2(r.end.x - c, r.position.y), Vector2(r.end.x, r.position.y + c),
		Vector2(r.end.x, r.end.y - c), Vector2(r.end.x - c, r.end.y), Vector2(r.position.x + c, r.end.y),
		Vector2(r.position.x, r.end.y - c), r.position + Vector2(0.0, c),
	])


func _fechado(pontos: PackedVector2Array) -> PackedVector2Array:
	var novo := pontos.duplicate()
	novo.append(pontos[0])
	return novo


## Cores do arco-íris em volta de um polígono, girando com "deslocamento".
func _cores_prismaticas(quantas: int, deslocamento: float) -> PackedColorArray:
	var cores := PackedColorArray()
	for i in quantas:
		cores.append(Color.from_hsv(fmod(deslocamento + float(i) / quantas, 1.0), 0.5, 1.0))
	return cores


## Onde a reta que sai de "centro" na direção "direcao" encontra a borda de "r".
func _na_borda(centro: Vector2, direcao: Vector2, r: Rect2) -> Vector2:
	var t := INF
	if direcao.x > 0.001:
		t = minf(t, (r.end.x - centro.x) / direcao.x)
	elif direcao.x < -0.001:
		t = minf(t, (r.position.x - centro.x) / direcao.x)
	if direcao.y > 0.001:
		t = minf(t, (r.end.y - centro.y) / direcao.y)
	elif direcao.y < -0.001:
		t = minf(t, (r.position.y - centro.y) / direcao.y)
	return centro + direcao * t


## Desenha só a parte de "poligono" que fica dentro de "area".
func _poligono_recortado(poligono: PackedVector2Array, area: PackedVector2Array, cor: Color) -> void:
	for parte in Geometry2D.intersect_polygons(poligono, area):
		if parte.size() >= 3:
			draw_colored_polygon(parte, cor)
