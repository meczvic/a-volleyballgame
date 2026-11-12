extends PanelContainer
## Medidor de energia do time, na metade da tela dele: enche com toques bons
## e pisca "SUPER PRONTA!" quando está cheio (a próxima cortada boa é super).

const Estilo := preload("res://scripts/menus/estilo.gd")

const LARGURA := 220.0
const ALTURA := 12.0
const COR := Color("#4FC3F7")
const COR_CHEIA := Color("#FFD23F")

var _fundo: Control
var _cheio: ColorRect
var _rotulo: Label
var _cheia := false
var _relogio := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel",
		Estilo.caixa(Color(0.06, 0.07, 0.09, 0.6), Estilo.INCLINACAO, 14.0, 6.0))
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 3)
	add_child(coluna)
	_rotulo = Label.new()
	_rotulo.text = "ENERGIA"
	_rotulo.add_theme_font_override("font", Estilo.FONTE_TITULO)
	_rotulo.add_theme_font_size_override("font_size", 14)
	_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(_rotulo)
	_fundo = Panel.new()
	_fundo.custom_minimum_size = Vector2(LARGURA, ALTURA)
	_fundo.add_theme_stylebox_override("panel", Estilo.caixa(Color(1, 1, 1, 0.15), Estilo.INCLINACAO))
	coluna.add_child(_fundo)
	_cheio = ColorRect.new()
	_cheio.color = COR
	_cheio.size = Vector2(0.0, ALTURA)
	_cheio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fundo.add_child(_cheio)


func _process(delta: float) -> void:
	if not _cheia:
		return
	_relogio += delta
	_rotulo.modulate.a = 0.65 + 0.35 * sin(_relogio * 9.0)


## "valor" de 0 a 1; "cheia" quando a super cortada está pronta.
func mostrar(valor: float, cheia: bool) -> void:
	_cheia = cheia
	_cheio.size.x = LARGURA * clampf(valor, 0.0, 1.0)
	_cheio.color = COR_CHEIA if cheia else COR
	_rotulo.text = "SUPER PRONTA!" if cheia else "ENERGIA"
	_rotulo.add_theme_color_override("font_color", COR_CHEIA if cheia else Estilo.TEXTO)
	if not cheia:
		_rotulo.modulate.a = 1.0


## Pra testes: fração cheia da barra (0 a 1).
func fracao() -> float:
	return _cheio.size.x / LARGURA
