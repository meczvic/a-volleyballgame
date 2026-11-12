extends RefCounted
## Pinta o uniforme de um personagem do VRoid (.vrm) com as cores do time e põe
## o número da camisa.
##
## O VRoid exporta o uniforme todo branco (camiseta "Tops", short "Bottoms",
## tênis "Shoes"; a meia vem desenhada na pele). Aqui as texturas da camisa e do
## short ganham a cor do time, sem perder as dobras e costuras da textura
## original, e a camisa ganha:
##   - o número grande nas costas e pequeno no peito (personagens/numeros/);
##   - faixas laterais na cor de detalhe.
## O short ganha uma barra na cor de detalhe. Tênis e meia continuam brancos.
## As cores seguem a mesma regra do atleta gerado (gerador_de_atleta.gd):
## camisa e short na principal, número na cor que mais contrasta com a camisa.
##
## Uso (Dados.carregar_personagem já chama):
##   UniformeVrm.aplicar(personagem, {"cores": [principal, detalhe, terceira], "numero": 10})
##
## Onde fica cada coisa na textura (UV) foi medido no modelo do Hinata, que usa
## a camiseta e o short padrão do VRoid; outro modelo com as mesmas peças usa o
## mesmo mapa. Peça com nome diferente fica como veio do VRoid.

const GeradorDeAtleta := preload("res://scripts/visual/gerador_de_atleta.gd")
const PASTA_NUMEROS := "res://personagens/numeros"

## Resolução das texturas pintadas (a camiseta do VRoid vem em 1024x2048).
const LARGURA_CAMISA := 512
const ALTURA_CAMISA := 1024
const LADO_SHORT := 512
## Lado da imagem pequena usada pra copiar as dobras da textura original.
const DOBRAS_LARGURA := 128
## Quanto das dobras/costuras da textura original aparece por cima da cor.
const FORCA_DAS_DOBRAS := 1.6
## Sombra (MToon "_ShadeColor") multiplicada pela cor da peça.
const COR_DA_SOMBRA := Color(0.74, 0.74, 0.8)

## Mapa da camiseta: u = a*x + b, v = c*y + d (x, y em metros no modelo, olhando
## pra +z; medido em 10_hinata). Frente e costas leem certo, sem espelhar.
const CAMISA_FRENTE := {"a": 1.353, "b": 0.5, "c": -0.633, "d": 0.957}
const CAMISA_COSTAS := {"a": -1.082, "b": 0.5, "c": -0.937, "d": 1.773}
## Número: centro (y em metros) e lado do quadrado (m).
const NUMERO_COSTAS := {"y": 1.1, "lado": 0.26}
const NUMERO_PEITO := {"y": 1.155, "lado": 0.11}
## Faixas laterais da camisa: borda do tronco no mapa (u) e largura, da axila à barra (v).
const FAIXAS_CAMISA := [
	{"u": [0.235, 0.27], "v": [0.225, 0.415]}, {"u": [0.73, 0.765], "v": [0.225, 0.415]},
	{"u": [0.235, 0.27], "v": [0.725, 0.915]}, {"u": [0.73, 0.765], "v": [0.725, 0.915]},
]
## Barra do short (v), nas duas pernas.
const BARRA_SHORT := [0.285, 0.335]

static var _texturas := {}


## Pinta o uniforme do personagem. "uniforme" = {"cores": [...], "numero": n}.
static func aplicar(personagem: Node3D, uniforme: Dictionary) -> void:
	var cores: Array = uniforme.get("cores", [])
	if cores.is_empty():
		return
	var principal := Color.from_string(str(cores[0]), Color.GRAY)
	var detalhe := Color.from_string(str(cores[1]) if cores.size() > 1 else "#FFFFFF", Color.WHITE)
	var numero := int(uniforme.get("numero", 0))
	var cor_numero := GeradorDeAtleta._cor_do_numero(uniforme, cores)
	for no in personagem.find_children("*", "MeshInstance3D", true, false):
		var malha := no as MeshInstance3D
		for s in malha.mesh.get_surface_count():
			var material := malha.get_active_material(s) as ShaderMaterial
			if material == null:
				continue
			var nome := material.resource_name
			var textura: Texture2D = null
			if "_Tops_" in nome:
				textura = _textura_da_camisa(material, principal, detalhe, numero, cor_numero)
			elif "_Bottoms_" in nome:
				textura = _textura_do_short(material, principal, detalhe)
			if textura:
				malha.set_surface_override_material(s, _pintado(material, textura))


## Cópia do material com a textura nova. Serve pro material do jogo
## (VisualVrm: "cor", "textura") e pro MToon original ("_Color", "_MainTex").
static func _pintado(material: ShaderMaterial, textura: Texture2D) -> ShaderMaterial:
	var novo := material.duplicate() as ShaderMaterial
	if "mtoon" in material.shader.resource_path:
		novo.set_shader_parameter("_Color", Color.WHITE)
		novo.set_shader_parameter("_MainTex", textura)
		novo.set_shader_parameter("_ShadeTexture", textura)
		novo.set_shader_parameter("_ShadeColor", COR_DA_SOMBRA)
	else:
		novo.set_shader_parameter("cor", Color.WHITE)
		novo.set_shader_parameter("textura", textura)
	if novo.next_pass is ShaderMaterial:
		var contorno := (novo.next_pass as ShaderMaterial).duplicate() as ShaderMaterial
		contorno.set_shader_parameter("_MainTex", textura)
		novo.next_pass = contorno
	return novo


static func _textura_da_camisa(material: ShaderMaterial, principal: Color, detalhe: Color, numero: int, cor_numero: Color) -> Texture2D:
	var original := _textura_original(material)
	if original == null:
		return null
	var chave := "camisa|%s|%s|%s|%d|%s" % [original.get_rid(), principal.to_html(), detalhe.to_html(), numero, cor_numero.to_html()]
	if _texturas.has(chave):
		return _texturas[chave]
	var imagem := _base_tingida(original, principal, LARGURA_CAMISA, ALTURA_CAMISA)
	for faixa: Dictionary in FAIXAS_CAMISA:
		imagem.fill_rect(_retangulo(faixa["u"], faixa["v"], LARGURA_CAMISA, ALTURA_CAMISA), detalhe)
	var desenho := _imagem_do_numero(numero)
	if desenho:
		_carimbar(imagem, desenho, cor_numero, CAMISA_COSTAS, NUMERO_COSTAS)
		_carimbar(imagem, desenho, cor_numero, CAMISA_FRENTE, NUMERO_PEITO)
	var textura := _textura(imagem)
	_texturas[chave] = textura
	return textura


static func _textura_do_short(material: ShaderMaterial, principal: Color, detalhe: Color) -> Texture2D:
	var original := _textura_original(material)
	if original == null:
		return null
	var chave := "short|%s|%s|%s" % [original.get_rid(), principal.to_html(), detalhe.to_html()]
	if _texturas.has(chave):
		return _texturas[chave]
	var imagem := _base_tingida(original, principal, LADO_SHORT, LADO_SHORT)
	imagem.fill_rect(_retangulo([0.0, 1.0], BARRA_SHORT, LADO_SHORT, LADO_SHORT), detalhe)
	var textura := _textura(imagem)
	_texturas[chave] = textura
	return textura


static func _textura_original(material: ShaderMaterial) -> Texture2D:
	var textura = material.get_shader_parameter("textura")
	if textura == null:
		textura = material.get_shader_parameter("_MainTex")
	return textura as Texture2D


## Cor chapada da peça com as dobras da textura original por cima: as partes
## mais escuras do branco viram sombra preta transparente (fill + blend, tudo
## nativo, sem passar pixel por pixel na imagem grande).
static func _base_tingida(original: Texture2D, cor: Color, largura: int, altura: int) -> Image:
	var pintada := Image.create(largura, altura, false, Image.FORMAT_RGBA8)
	pintada.fill(Color(cor.r, cor.g, cor.b, 1.0))
	var dobras := _dobras(original)
	if dobras:
		var grande := dobras.duplicate() as Image
		grande.resize(largura, altura, Image.INTERPOLATE_BILINEAR)
		pintada.blend_rect(grande, Rect2i(Vector2i.ZERO, grande.get_size()), Vector2i.ZERO)
	# Mantém os recortes da peça (o VRoid usa transparência nas bordas e barras).
	var recorte := _recorte(original, largura, altura)
	if recorte == null:
		return pintada
	var imagem := Image.create(largura, altura, false, Image.FORMAT_RGBA8)
	imagem.blend_rect_mask(pintada, recorte, Rect2i(0, 0, largura, altura), Vector2i.ZERO)
	return imagem


## Imagem pequena preta cuja transparência é o quanto a textura original
## escurece o branco (dobras, costuras, barra). Guardada por textura.
static func _dobras(original: Texture2D) -> Image:
	var chave := "dobras|%s" % original.get_rid()
	if _texturas.has(chave):
		return _texturas[chave]
	var fonte := original.get_image()
	if fonte == null:
		return null
	fonte = fonte.duplicate() as Image
	if fonte.is_compressed():
		fonte.decompress()
	fonte.convert(Image.FORMAT_RGBA8)
	var proporcao := float(fonte.get_height()) / float(fonte.get_width())
	fonte.resize(DOBRAS_LARGURA, int(DOBRAS_LARGURA * proporcao), Image.INTERPOLATE_BILINEAR)
	var dobras := Image.create(fonte.get_width(), fonte.get_height(), false, Image.FORMAT_RGBA8)
	for y in fonte.get_height():
		for x in fonte.get_width():
			var c := fonte.get_pixel(x, y)
			var escuro := clampf((1.0 - c.get_luminance()) * FORCA_DAS_DOBRAS, 0.0, 0.85)
			dobras.set_pixel(x, y, Color(0.0, 0.0, 0.0, escuro))
	_texturas[chave] = dobras
	return dobras


## A textura original no tamanho pedido: só a transparência dela é usada.
static func _recorte(original: Texture2D, largura: int, altura: int) -> Image:
	var chave := "recorte|%s|%d|%d" % [original.get_rid(), largura, altura]
	if _texturas.has(chave):
		return _texturas[chave]
	var imagem := original.get_image()
	if imagem == null:
		return null
	imagem = imagem.duplicate() as Image
	if imagem.is_compressed():
		imagem.decompress()
	imagem.convert(Image.FORMAT_RGBA8)
	imagem.resize(largura, altura, Image.INTERPOLATE_BILINEAR)
	_texturas[chave] = imagem
	return imagem


## Número em branco com fundo transparente (personagens/numeros/<nn>.png).
static func _imagem_do_numero(numero: int) -> Image:
	var caminho := "%s/%02d.png" % [PASTA_NUMEROS, numero]
	if numero <= 0 or not ResourceLoader.exists(caminho):
		return null
	var chave := "numero|%d" % numero
	if _texturas.has(chave):
		return _texturas[chave]
	var imagem := (load(caminho) as Texture2D).get_image().duplicate() as Image
	if imagem.is_compressed():
		imagem.decompress()
	imagem.convert(Image.FORMAT_RGBA8)
	_texturas[chave] = imagem
	return imagem


## Desenha o número na cor dada, num quadrado de "lado" metros centrado em x=0
## e na altura "y", usando o mapa (u, v) daquele lado da camisa.
static func _carimbar(imagem: Image, desenho: Image, cor: Color, mapa: Dictionary, lugar: Dictionary) -> void:
	var meio: float = lugar["lado"] / 2.0
	var u := [mapa["b"] - absf(mapa["a"]) * meio, mapa["b"] + absf(mapa["a"]) * meio]
	var v := [mapa["c"] * (lugar["y"] + meio) + mapa["d"], mapa["c"] * (lugar["y"] - meio) + mapa["d"]]
	var area := _retangulo(u, v, imagem.get_width(), imagem.get_height())
	var mascara := desenho.duplicate() as Image
	mascara.resize(area.size.x, area.size.y, Image.INTERPOLATE_BILINEAR)
	var tinta := Image.create(area.size.x, area.size.y, false, Image.FORMAT_RGBA8)
	tinta.fill(Color(cor.r, cor.g, cor.b, 1.0))
	imagem.blend_rect_mask(tinta, mascara, Rect2i(Vector2i.ZERO, area.size), area.position)


static func _retangulo(u: Array, v: Array, largura: int, altura: int) -> Rect2i:
	var x0 := int(round(minf(u[0], u[1]) * largura))
	var x1 := int(round(maxf(u[0], u[1]) * largura))
	var y0 := int(round(minf(v[0], v[1]) * altura))
	var y1 := int(round(maxf(v[0], v[1]) * altura))
	return Rect2i(x0, y0, maxi(1, x1 - x0), maxi(1, y1 - y0))


static func _textura(imagem: Image) -> ImageTexture:
	imagem.generate_mipmaps()
	return ImageTexture.create_from_image(imagem)
