extends Control
## Tela do online (primeira versão, por IP).
##
## HOSPEDAR: este computador vira o dono da partida e espera alguém conectar
## (usa os times e o estádio da última partida escolhida). CONECTAR: entra na
## partida de outro computador pelo IP dele (o seu jogador é o time 2).
## Os dois precisam estar na mesma rede (ou com a porta 7777 aberta).

const Estilo := preload("res://scripts/menus/estilo.gd")
const MENU := "res://cenas/menu_principal.tscn"

var _ip: LineEdit
var _situacao: Label
var _rede: Node


func _ready() -> void:
	_rede = get_node("/root/Rede")
	_rede.estado_mudou.connect(func(texto: String) -> void: _situacao.text = texto)

	var fundo := ColorRect.new()
	fundo.color = Color("#10151D")
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var coluna := VBoxContainer.new()
	coluna.position = Vector2(110.0, 140.0)
	coluna.custom_minimum_size = Vector2(620.0, 0.0)
	coluna.add_theme_constant_override("separation", 18)
	add_child(coluna)

	var titulo := Estilo.rotulo_com_contorno(54, true)
	titulo.text = "ONLINE"
	coluna.add_child(titulo)

	var explica := Estilo.rotulo_com_contorno(20, false)
	explica.text = "Os dois computadores na mesma rede. Um hospeda, o outro conecta pelo IP.\nQuem conecta joga com o time 2."
	coluna.add_child(explica)

	var hospedar := Estilo.botao("HOSPEDAR")
	hospedar.custom_minimum_size = Vector2(440.0, 62.0)
	hospedar.pressed.connect(func() -> void: _rede.hospedar())
	coluna.add_child(hospedar)

	_ip = LineEdit.new()
	_ip.placeholder_text = "IP do dono (ex.: 192.168.0.10)"
	_ip.text = "127.0.0.1"
	_ip.custom_minimum_size = Vector2(440.0, 52.0)
	_ip.add_theme_font_size_override("font_size", 24)
	coluna.add_child(_ip)

	var conectar := Estilo.botao("CONECTAR")
	conectar.custom_minimum_size = Vector2(440.0, 62.0)
	conectar.pressed.connect(func() -> void: _rede.conectar(_ip.text.strip_edges()))
	coluna.add_child(conectar)

	var voltar := Estilo.botao("VOLTAR")
	voltar.custom_minimum_size = Vector2(440.0, 62.0)
	voltar.pressed.connect(_voltar)
	coluna.add_child(voltar)

	_situacao = Estilo.rotulo_com_contorno(22, false)
	_situacao.text = "Seu IP: " + ", ".join(_ips_locais())
	coluna.add_child(_situacao)

	hospedar.grab_focus()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		_voltar()


func _voltar() -> void:
	_rede.sair()
	get_tree().change_scene_to_file(MENU)


## IPs desta máquina na rede local (pra passar pro amigo).
func _ips_locais() -> PackedStringArray:
	var lista := PackedStringArray()
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			lista.append(ip)
	if lista.is_empty():
		lista.append("127.0.0.1")
	return lista
