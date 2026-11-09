extends Control
## Faixa grande que atravessa a tela quando sai um ponto ("PONTO!", "ACE!",
## "BLOQUEIO!", "SET!"), na cor do time. Entra pela esquerda, para no meio um
## instante e sai pela direita. Uma faixa nova substitui a anterior.

const Estilo := preload("res://scripts/menus/estilo.gd")

const ENTRADA := 0.22
const PARADA := 0.9
const SAIDA := 0.25
const LARGURA := 900.0
const ALTURA := 128.0

var _caixa: PanelContainer
var _titulo: Label
var _subtitulo: Label
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_caixa = PanelContainer.new()
	_caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caixa.custom_minimum_size = Vector2(LARGURA, ALTURA)
	add_child(_caixa)
	var coluna := VBoxContainer.new()
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", -10)
	_caixa.add_child(coluna)
	_titulo = Estilo.rotulo("", 84, Estilo.TEXTO, true)
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.07))
	_titulo.add_theme_constant_override("outline_size", 12)
	coluna.add_child(_titulo)
	_subtitulo = Estilo.rotulo("", 28, Estilo.TEXTO, false)
	_subtitulo.add_theme_font_override("font", Estilo.FONTE_TEXTO)
	_subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitulo.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.07))
	_subtitulo.add_theme_constant_override("outline_size", 6)
	coluna.add_child(_subtitulo)
	visible = false


func mostrar(titulo: String, subtitulo: String, cor: Color) -> void:
	_titulo.text = titulo
	_subtitulo.text = subtitulo
	var fundo := cor
	fundo.a = 0.97
	_caixa.add_theme_stylebox_override("panel", Estilo.caixa(fundo, Estilo.INCLINACAO, 30.0, 6.0, 4, Color(1, 1, 1, 0.85)))
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
