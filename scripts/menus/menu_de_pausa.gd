extends CanvasLayer
## Menu de pausa (Esc ou Start) e tela de fim de jogo, por cima da partida.
##
## Pausar congela a partida inteira (get_tree().paused). Este menu continua
## funcionando porque roda com process_mode = ALWAYS.

## O jogador pediu pausa. A partida responde chamando abrir_pausa(resumo).
signal pausa_pedida

const Estilo := preload("res://scripts/menus/estilo.gd")

const CENA_MENU := "res://cenas/menu_principal.tscn"
const CENA_SELECAO := "res://cenas/selecao_de_times.tscn"

var _fim_de_jogo := false
var _raiz: Control
var _painel: Panel
var _titulo: Label
var _detalhe: Label
var _lista: VBoxContainer


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.theme = Estilo.tema()
	_raiz.visible = false
	add_child(_raiz)

	var escurecer := ColorRect.new()
	escurecer.color = Color(0.0, 0.0, 0.0, 0.6)
	escurecer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(escurecer)

	# O tamanho do painel acompanha o número de botões (veja _mostrar).
	var painel := Estilo.painel(Estilo.PAINEL, 0.0, 2, Estilo.PAINEL_CLARO)
	_painel = painel
	_raiz.add_child(painel)

	var barra := Estilo.painel(Estilo.DESTAQUE, Estilo.INCLINACAO)
	barra.position = Vector2(40.0, 34.0)
	barra.size = Vector2(10.0, 60.0)
	painel.add_child(barra)

	_titulo = Estilo.rotulo("", 56, Estilo.TEXTO, true)
	_titulo.position = Vector2(64.0, 22.0)
	painel.add_child(_titulo)
	_detalhe = Estilo.rotulo("", 24, Estilo.TEXTO_SUAVE)
	_detalhe.position = Vector2(66.0, 96.0)
	_detalhe.size = Vector2(500.0, 64.0)
	_detalhe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	painel.add_child(_detalhe)

	_lista = VBoxContainer.new()
	_lista.position = Vector2(64.0, 172.0)
	_lista.custom_minimum_size = Vector2(472.0, 0.0)
	_lista.add_theme_constant_override("separation", 12)
	painel.add_child(_lista)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausa"):
		if _raiz.visible:
			fechar()
		elif not _fim_de_jogo:
			pausa_pedida.emit()
		get_viewport().set_input_as_handled()
	elif _raiz.visible and event.is_action_pressed("ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()


func esta_aberto() -> bool:
	return _raiz.visible


func abrir_pausa(resumo: String) -> void:
	if _fim_de_jogo or _raiz.visible:
		return
	_mostrar("PAUSA", resumo, [
		["CONTINUAR", fechar],
		["RECOMEÇAR PARTIDA", _recomecar],
		["TROCAR TIMES", _ir_para.bind(CENA_SELECAO)],
		["MENU PRINCIPAL", _ir_para.bind(CENA_MENU)],
	])


func abrir_fim_de_jogo(titulo: String, resumo: String) -> void:
	_fim_de_jogo = true
	_mostrar(titulo, resumo, [
		["JOGAR DE NOVO", _recomecar],
		["TROCAR TIMES", _ir_para.bind(CENA_SELECAO)],
		["MENU PRINCIPAL", _ir_para.bind(CENA_MENU)],
	])


## Fecha a pausa e a partida continua. No fim de jogo não fecha.
func fechar() -> void:
	if _fim_de_jogo:
		return
	_raiz.visible = false
	# Despausa só no fim do quadro, pra a tecla que fechou o menu
	# não virar um toque na bola.
	get_tree().set_deferred("paused", false)


func _mostrar(titulo: String, resumo: String, opcoes: Array) -> void:
	_titulo.text = titulo
	_detalhe.text = resumo
	for antigo in _lista.get_children():
		_lista.remove_child(antigo)
		antigo.queue_free()

	var botoes: Array[Button] = []
	for opcao in opcoes:
		var botao := Estilo.botao(opcao[0], 28)
		botao.custom_minimum_size = Vector2(472.0, 58.0)
		botao.pressed.connect(opcao[1])
		_lista.add_child(botao)
		botoes.append(botao)
	# Do último, "baixo" volta pro primeiro (e vice-versa).
	botoes[0].focus_neighbor_top = botoes[0].get_path_to(botoes[-1])
	botoes[-1].focus_neighbor_bottom = botoes[-1].get_path_to(botoes[0])

	# Painel na altura certa pros botões e no meio da tela.
	var altura := _lista.position.y + opcoes.size() * (58.0 + 12.0) - 12.0 + 48.0
	_painel.size = Vector2(600.0, altura)
	_painel.position = Vector2(500.0, (900.0 - altura) / 2.0)

	_raiz.visible = true
	get_tree().paused = true
	botoes[0].grab_focus.call_deferred()


func _recomecar() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _ir_para(caminho: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(caminho)
