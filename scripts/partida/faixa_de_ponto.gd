extends Control
## Faixa que atravessa a tela quando sai um ponto ("PONTO!", "ACE!",
## "BLOQUEIO!", "SET!", "JOGO!"): fundo escuro, ponta grossa na cor do time e o
## emblema de quem pontuou. Entra pela esquerda, para no meio um instante e sai
## pela direita. Uma faixa nova substitui a anterior.
##
## É mais baixa e estreita que a antiga pra cobrir menos a quadra.

const Estilo := preload("res://scripts/menus/estilo.gd")

const ENTRADA := 0.22
const PARADA := 0.9
const SAIDA := 0.25
const LARGURA := 680.0
const ALTURA := 104.0
const TAMANHO_DO_EMBLEMA := 80.0
const PASTA_EMBLEMAS := "res://arte/emblemas/%s.svg"

var _caixa: PanelContainer
var _emblema: TextureRect
var _titulo: Label
var _subtitulo: Label
var _tween: Tween
var _emblemas: Array = [null, null]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_caixa = PanelContainer.new()
	_caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caixa.custom_minimum_size = Vector2(LARGURA, ALTURA)
	add_child(_caixa)
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 18)
	_caixa.add_child(linha)
	_emblema = TextureRect.new()
	_emblema.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_emblema.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_emblema.custom_minimum_size = Vector2.ONE * TAMANHO_DO_EMBLEMA
	_emblema.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_emblema.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_child(_emblema)
	var coluna := VBoxContainer.new()
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", -12)
	linha.add_child(coluna)
	_titulo = Estilo.rotulo("", 72, Estilo.TEXTO, true)
	_titulo.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.07))
	_titulo.add_theme_constant_override("outline_size", 12)
	coluna.add_child(_titulo)
	_subtitulo = Estilo.rotulo("", 26, Estilo.TEXTO, false)
	_subtitulo.add_theme_font_override("font", Estilo.FONTE_TEXTO)
	_subtitulo.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.07))
	_subtitulo.add_theme_constant_override("outline_size", 6)
	coluna.add_child(_subtitulo)
	visible = false


## Ids dos times ([time 0, time 1]) pra achar os emblemas.
func configurar(ids: Array) -> void:
	for time in 2:
		var caminho := PASTA_EMBLEMAS % (ids[time] if time < ids.size() else "")
		_emblemas[time] = load(caminho) if ResourceLoader.exists(caminho) else null


## "time" (0 ou 1) escolhe o emblema; -1 = sem emblema.
func mostrar(titulo: String, subtitulo: String, cor: Color, time := -1) -> void:
	_titulo.text = titulo
	_subtitulo.text = subtitulo
	_subtitulo.add_theme_color_override("font_color", cor.lightened(0.45))
	_emblema.texture = _emblemas[time] if time >= 0 and time < 2 else null
	_emblema.visible = _emblema.texture != null
	var estilo := Estilo.caixa(Color(0.06, 0.07, 0.09, 0.95), Estilo.INCLINACAO, 28.0, 4.0)
	estilo.border_width_left = 18
	estilo.border_width_bottom = 5
	estilo.border_width_top = 2
	estilo.border_color = cor
	estilo.shadow_color = Color(cor, 0.35)
	estilo.shadow_size = 10
	_caixa.add_theme_stylebox_override("panel", estilo)
	visible = true
	var tela := get_viewport_rect().size
	var y := tela.y * 0.36 - ALTURA / 2.0
	var meio := (tela.x - LARGURA) / 2.0
	_caixa.position = Vector2(-LARGURA - 40.0, y)
	_caixa.modulate.a = 1.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_caixa, "position:x", meio, ENTRADA).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(PARADA)
	_tween.tween_property(_caixa, "position:x", tela.x + 40.0, SAIDA).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func() -> void: visible = false)


func texto() -> String:
	return _titulo.text if visible else ""


func tem_emblema() -> bool:
	return visible and _emblema.visible
