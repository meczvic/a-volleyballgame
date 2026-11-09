extends RefCounted
## Cores, fontes e peças de interface usadas em todos os menus.
##
## Mudar uma cor aqui muda todos os menus de uma vez.

const FONTE_TITULO := preload("res://fontes/BarlowCondensed-BoldItalic.ttf")
const FONTE_TEXTO := preload("res://fontes/BarlowCondensed-SemiBold.ttf")

const FUNDO := Color("#12141A")
const PAINEL := Color("#1E222B")
const PAINEL_CLARO := Color("#2C313D")
const TEXTO := Color("#F5F2EB")
const TEXTO_SUAVE := Color("#A2A8B4")
const TEXTO_APAGADO := Color("#646A76")
const DESTAQUE := Color("#FF8A1F")
const PRONTO := Color("#4CD47A")
## Cor de cada jogador: [Jogador 1, Jogador 2].
const COR_DO_JOGADOR := [Color("#FF8A1F"), Color("#3AA0FF")]
## Inclinação dos painéis, no estilo dos jogos de esporte.
const INCLINACAO := 0.18


## Tema dos menus: fonte padrão e visual dos botões.
## Coloque no Control de cima (theme = Estilo.tema()) e os filhos herdam.
static func tema() -> Theme:
	var tema_novo := Theme.new()
	tema_novo.default_font = FONTE_TEXTO
	tema_novo.default_font_size = 24
	tema_novo.set_color("font_color", "Label", TEXTO)
	tema_novo.set_stylebox("panel", "Panel", caixa(PAINEL))

	tema_novo.set_stylebox("normal", "Button", caixa(PAINEL, INCLINACAO, 28.0, 10.0))
	tema_novo.set_stylebox("hover", "Button", caixa(PAINEL_CLARO, INCLINACAO, 28.0, 10.0))
	tema_novo.set_stylebox("pressed", "Button", caixa(DESTAQUE.darkened(0.3), INCLINACAO, 28.0, 10.0))
	tema_novo.set_stylebox("hover_pressed", "Button", caixa(DESTAQUE.darkened(0.3), INCLINACAO, 28.0, 10.0))
	tema_novo.set_stylebox("disabled", "Button", caixa(PAINEL.darkened(0.35), INCLINACAO, 28.0, 10.0))
	# O foco é desenhado por cima do fundo do botão: só uma borda laranja.
	var foco := caixa(Color.TRANSPARENT, INCLINACAO, 28.0, 10.0)
	foco.draw_center = false
	foco.border_color = DESTAQUE
	foco.set_border_width_all(3)
	foco.border_width_left = 10
	tema_novo.set_stylebox("focus", "Button", foco)
	for nome in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		tema_novo.set_color(nome, "Button", TEXTO)
	tema_novo.set_color("font_disabled_color", "Button", TEXTO_APAGADO)
	return tema_novo


## Fundo chapado (opcionalmente inclinado e com borda) pra painéis, botões e etiquetas.
## "margem_x" e "margem_y" afastam o texto da borda.
static func caixa(cor: Color, inclinacao := 0.0, margem_x := 0.0, margem_y := 0.0,
		borda := 0, cor_da_borda := Color.TRANSPARENT) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.skew = Vector2(inclinacao, 0.0)
	estilo.content_margin_left = margem_x
	estilo.content_margin_right = margem_x
	estilo.content_margin_top = margem_y
	estilo.content_margin_bottom = margem_y
	if borda > 0:
		estilo.set_border_width_all(borda)
		estilo.border_color = cor_da_borda
	return estilo


## Texto pronto. "titulo" = fonte grossa e inclinada.
static func rotulo(texto: String, tamanho: int, cor: Color = TEXTO, titulo := false) -> Label:
	var novo := Label.new()
	novo.text = texto
	novo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	novo.add_theme_font_size_override("font_size", tamanho)
	novo.add_theme_color_override("font_color", cor)
	if titulo:
		novo.add_theme_font_override("font", FONTE_TITULO)
	return novo


## Etiqueta colorida com texto centralizado (por exemplo "JOGADOR 1").
static func etiqueta(texto: String, cor: Color, tamanho: int, cor_do_texto: Color = FUNDO) -> Label:
	var nova := rotulo(texto, tamanho, cor_do_texto, true)
	nova.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nova.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nova.add_theme_stylebox_override("normal", caixa(cor, INCLINACAO, 8.0, 0.0))
	return nova


## Painel retangular colorido.
static func painel(cor: Color, inclinacao := 0.0, borda := 0, cor_da_borda := Color.TRANSPARENT) -> Panel:
	var novo := Panel.new()
	novo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	novo.add_theme_stylebox_override("panel", caixa(cor, inclinacao, 0.0, 0.0, borda, cor_da_borda))
	return novo


## Botão de menu. O mouse em cima também move o foco pra ele, assim
## teclado, controle e mouse destacam sempre o mesmo botão.
static func botao(texto: String, tamanho := 30) -> Button:
	var novo := Button.new()
	novo.text = texto
	novo.alignment = HORIZONTAL_ALIGNMENT_LEFT
	novo.add_theme_font_override("font", FONTE_TITULO)
	novo.add_theme_font_size_override("font_size", tamanho)
	novo.mouse_entered.connect(func() -> void:
		if not novo.disabled and novo.focus_mode != Control.FOCUS_NONE:
			novo.grab_focus()
	)
	return novo


## Degradê branco (use self_modulate pra dar a cor). "da_esquerda" = forte na esquerda.
static func degrade(da_esquerda: bool, forca := 0.5) -> GradientTexture2D:
	var forte := Color(1.0, 1.0, 1.0, forca)
	var fraco := Color(1.0, 1.0, 1.0, 0.0)
	var gradiente := Gradient.new()
	gradiente.offsets = PackedFloat32Array([0.0, 1.0])
	gradiente.colors = PackedColorArray([forte, fraco] if da_esquerda else [fraco, forte])
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.width = 256
	textura.height = 16
	textura.fill_from = Vector2(0.0, 0.0)
	textura.fill_to = Vector2(1.0, 0.0)
	return textura


## A tela aparece aos poucos.
static func aparecer(no: CanvasItem, duracao := 0.25) -> void:
	no.modulate.a = 0.0
	no.create_tween().tween_property(no, "modulate:a", 1.0, duracao)
