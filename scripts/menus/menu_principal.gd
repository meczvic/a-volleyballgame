extends Control
## Menu principal: partida rápida, modos que ainda vão chegar, controles e sair.
##
## Navega com setas, WASD ou direcional. Escolhe com Enter, J ou A.
## Volta com Esc ou B.

const Estilo := preload("res://scripts/menus/estilo.gd")
const Dados := preload("res://scripts/comum/dados.gd")

const CENA_SELECAO := "res://cenas/selecao_de_times.tscn"

## [ação, Jogador 1, Jogador 2, controle]. Igual ao README e a scripts/entrada/teclas.gd.
const CONTROLES := [
	["Mover", "W A S D", "Setas", "Analógico ou direcional"],
	["Passe / levantar", "J", "1 (numérico)", "A"],
	["Saque / cortada", "K", "2 (numérico)", "X"],
	["Saque flutuante", "I", "5 (numérico)", "RB"],
	["Bloqueio", "L", "3 (numérico)", "Y"],
	["Mergulho (em breve)", "Espaço", "0 (numérico)", "B"],
	["Pausa", "Esc", "Esc", "Start"],
]

var _botoes: Array[Button] = []
var _botao_controles: Button
var _tela_de_controles: Control
var _botao_voltar: Button
var _saindo := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = Estilo.tema()
	_criar_fundo()
	_criar_titulo()
	_criar_botoes()
	_criar_tela_de_controles()
	Estilo.aparecer(self)
	_botoes[0].grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if _tela_de_controles.visible and event.is_action_pressed("ui_cancel"):
		_fechar_controles()
		get_viewport().set_input_as_handled()


# --- Ações dos botões ---

func _partida_rapida() -> void:
	Configuracao.modo = "rapida"
	_trocar_de_cena(CENA_SELECAO)


func _mostrar_controles() -> void:
	_tela_de_controles.visible = true
	_botao_voltar.grab_focus()


func _fechar_controles() -> void:
	_tela_de_controles.visible = false
	_botao_controles.grab_focus()


func _sair() -> void:
	get_tree().quit()


func _trocar_de_cena(caminho: String) -> void:
	if _saindo:
		return
	_saindo = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file(caminho))


# --- Construção da tela ---

func _criar_fundo() -> void:
	var fundo := ColorRect.new()
	fundo.color = Estilo.FUNDO
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)

	# Faixa inclinada atrás do título e dos botões.
	var faixa := Estilo.painel(Color("#181B23"), 0.35)
	faixa.position = Vector2(-260.0, 0.0)
	faixa.size = Vector2(1020.0, 900.0)
	add_child(faixa)
	var risco := Estilo.painel(Estilo.DESTAQUE, 0.35)
	risco.position = Vector2(754.0, 0.0)
	risco.size = Vector2(10.0, 900.0)
	add_child(risco)

	# Uma barra inclinada por time, na cor do time, balançando devagar.
	var times := Dados.times()
	for i in times.size():
		var barra := Estilo.painel(Dados.cor(times[i], "cor_do_menu", Estilo.DESTAQUE), 0.35)
		var altura := 560.0 - (i % 3) * 70.0
		barra.position = Vector2(880.0 + i * 92.0, 170.0 + (i % 2) * 50.0)
		barra.size = Vector2(64.0, altura)
		barra.modulate.a = 0.9
		add_child(barra)
		var balanco := barra.create_tween().set_loops()
		balanco.set_trans(Tween.TRANS_SINE)
		balanco.tween_property(barra, "position:y", barra.position.y - 14.0, 1.4 + i * 0.15)
		balanco.tween_property(barra, "position:y", barra.position.y, 1.4 + i * 0.15)


func _criar_titulo() -> void:
	var titulo := Estilo.rotulo("JOGO DE VÔLEI", 96, Estilo.TEXTO, true)
	titulo.position = Vector2(110.0, 128.0)
	add_child(titulo)
	var subtitulo := Estilo.rotulo("6 contra 6  ·  2 jogadores  ·  anime", 30, Estilo.TEXTO_SUAVE)
	subtitulo.position = Vector2(116.0, 248.0)
	add_child(subtitulo)

	# Duas linhas curtas, pra não cruzar o risco laranja inclinado.
	var dica := Estilo.rotulo(
		"Navegar: setas, WASD ou direcional\nEscolher: Enter, J ou A   ·   Voltar: Esc ou B",
		19, Estilo.TEXTO_APAGADO
	)
	dica.position = Vector2(110.0, 820.0)
	add_child(dica)


func _criar_botoes() -> void:
	var lista := VBoxContainer.new()
	lista.position = Vector2(110.0, 330.0)
	lista.custom_minimum_size = Vector2(440.0, 0.0)
	lista.add_theme_constant_override("separation", 14)
	add_child(lista)

	# [texto, ação]. Sem ação = ainda não existe (aparece apagado).
	var opcoes := [
		["PARTIDA RÁPIDA", _partida_rapida],
		["MODO CAOS  ·  EM BREVE", Callable()],
		["ONLINE  ·  EM BREVE", Callable()],
		["CONTROLES", _mostrar_controles],
		["SAIR", _sair],
	]
	for opcao in opcoes:
		var botao := Estilo.botao(opcao[0])
		botao.custom_minimum_size = Vector2(440.0, 62.0)
		var acao: Callable = opcao[1]
		if acao.is_valid():
			botao.pressed.connect(acao)
			_botoes.append(botao)
		else:
			botao.disabled = true
			botao.focus_mode = Control.FOCUS_NONE
		lista.add_child(botao)
		if opcao[0] == "CONTROLES":
			_botao_controles = botao

	# Do último botão, "baixo" volta pro primeiro (e vice-versa).
	var primeiro := _botoes[0]
	var ultimo := _botoes[_botoes.size() - 1]
	primeiro.focus_neighbor_top = primeiro.get_path_to(ultimo)
	ultimo.focus_neighbor_bottom = ultimo.get_path_to(primeiro)


func _criar_tela_de_controles() -> void:
	_tela_de_controles = Control.new()
	_tela_de_controles.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tela_de_controles.visible = false
	add_child(_tela_de_controles)

	var escurecer := ColorRect.new()
	escurecer.color = Color(0.0, 0.0, 0.0, 0.75)
	escurecer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tela_de_controles.add_child(escurecer)

	var painel := Estilo.painel(Estilo.PAINEL, 0.0, 2, Estilo.PAINEL_CLARO)
	painel.position = Vector2(230.0, 100.0)
	painel.size = Vector2(1140.0, 700.0)
	_tela_de_controles.add_child(painel)

	var titulo := Estilo.rotulo("CONTROLES", 56, Estilo.TEXTO, true)
	titulo.position = Vector2(40.0, 20.0)
	painel.add_child(titulo)

	var tabela := GridContainer.new()
	tabela.columns = 4
	tabela.position = Vector2(44.0, 110.0)
	tabela.add_theme_constant_override("h_separation", 56)
	tabela.add_theme_constant_override("v_separation", 14)
	painel.add_child(tabela)
	for cabecalho in ["AÇÃO", "JOGADOR 1", "JOGADOR 2", "CONTROLE"]:
		tabela.add_child(Estilo.rotulo(cabecalho, 24, Estilo.DESTAQUE, true))
	for linha in CONTROLES:
		for coluna in 4:
			var cor := Estilo.TEXTO if coluna == 0 else Estilo.TEXTO_SUAVE
			tabela.add_child(Estilo.rotulo(linha[coluna], 26, cor))

	var nota := Estilo.rotulo(
		"O 1º controle é do Jogador 1 e o 2º do Jogador 2. Dá pra misturar teclado e controle.",
		21, Estilo.TEXTO_SUAVE
	)
	nota.position = Vector2(44.0, 540.0)
	painel.add_child(nota)

	_botao_voltar = Estilo.botao("VOLTAR", 28)
	_botao_voltar.position = Vector2(44.0, 610.0)
	_botao_voltar.size = Vector2(240.0, 58.0)
	_botao_voltar.pressed.connect(_fechar_controles)
	painel.add_child(_botao_voltar)
	# Com a tela de controles aberta, o foco não sai do "Voltar".
	for lado in ["focus_neighbor_top", "focus_neighbor_bottom", "focus_neighbor_left", "focus_neighbor_right", "focus_next", "focus_previous"]:
		_botao_voltar.set(lado, NodePath("."))
