extends ColorRect
## Cortina preta que cobre a tela nas trocas de cena: abre (some) quando a
## cena começa e fecha (aparece) antes de trocar de cena.
##
## Funciona com o jogo pausado. Uso:
##   var cortina := Cortina.nova(camada)   # já começa fechada
##   cortina.abrir()                       # na entrada da cena
##   cortina.fechar(func(): get_tree().change_scene_to_file(...))

const DURACAO := 0.3

var _tween: Tween


## Cria a cortina dentro de "pai" (de preferência um CanvasLayer alto), fechada.
static func nova(pai: Node) -> ColorRect:
	var cortina := new()
	cortina.name = "Cortina"
	pai.add_child(cortina)
	return cortina


func _ready() -> void:
	color = Color.BLACK
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


## A tela aparece aos poucos (a cortina some).
func abrir(duracao := DURACAO) -> void:
	_animar(0.0, duracao, Callable())


## A tela escurece e, no fim, chama "depois" (por exemplo, trocar de cena).
func fechar(depois: Callable = Callable(), duracao := DURACAO) -> void:
	visible = true
	_animar(1.0, duracao, depois)


func _animar(alfa: float, duracao: float, depois: Callable) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	# Continua rodando com o jogo pausado (menu de pausa).
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(self, "color:a", alfa, duracao)
	if alfa == 0.0:
		_tween.tween_callback(func() -> void: visible = false)
	if depois.is_valid():
		_tween.tween_callback(depois)
