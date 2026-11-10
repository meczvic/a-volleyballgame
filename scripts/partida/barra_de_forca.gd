extends PanelContainer
## Barra de força do saque, na metade da tela de quem saca: enche enquanto
## o botão está apertado e fica vermelha no "talo" (risco de bola fora).

const Estilo := preload("res://scripts/menus/estilo.gd")

const LARGURA := 260.0
const ALTURA := 18.0
const COR := Color("#FFD23F")
const COR_ARRISCADA := Color("#FF2D2D")

var _fundo: Control
var _cheio: ColorRect
var _rotulo: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel",
		Estilo.caixa(Color(0.06, 0.07, 0.09, 0.72), Estilo.INCLINACAO, 18.0, 8.0))
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 4)
	add_child(coluna)
	_rotulo = Label.new()
	_rotulo.text = "FORÇA"
	_rotulo.add_theme_font_override("font", Estilo.FONTE_TITULO)
	_rotulo.add_theme_font_size_override("font_size", 18)
	_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(_rotulo)
	_fundo = Panel.new()
	_fundo.custom_minimum_size = Vector2(LARGURA, ALTURA)
	_fundo.add_theme_stylebox_override("panel", Estilo.caixa(Color(1, 1, 1, 0.15), Estilo.INCLINACAO))
	coluna.add_child(_fundo)
	_cheio = ColorRect.new()
	_cheio.color = COR
	_cheio.position = Vector2.ZERO
	_cheio.size = Vector2(0.0, ALTURA)
	_cheio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fundo.add_child(_cheio)
	visible = false


## "forca" de 0 a 1. "arriscada": no talo, a barra fica vermelha.
func mostrar(forca: float, arriscada: bool) -> void:
	visible = true
	_cheio.size.x = LARGURA * clampf(forca, 0.0, 1.0)
	_cheio.color = COR_ARRISCADA if arriscada else COR
	_rotulo.text = "FORÇA  ·  RISCO DE SAIR!" if arriscada else "FORÇA"
	_rotulo.add_theme_color_override("font_color", COR_ARRISCADA if arriscada else Estilo.TEXTO)


func esconder() -> void:
	visible = false


## Pra testes: fração cheia da barra (0 a 1).
func fracao() -> float:
	return _cheio.size.x / LARGURA
