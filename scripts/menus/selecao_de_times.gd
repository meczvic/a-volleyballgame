extends Control
## Seleção de times: cada jogador escolhe o seu time, depois o estádio.
##
## Jogador 1: A/D escolhe, J confirma, Espaço volta (ou o 1º controle: direcional, A, B).
## Jogador 2: setas escolhem, 1 confirma, 0 volta no numérico (ou o 2º controle).
## Esc volta pro menu principal.
##
## As regras (quem confirmou, em que fase está) ficam em selecao.gd.
## Este arquivo só desenha a tela e lê os botões.

const Estilo := preload("res://scripts/menus/estilo.gd")
const Dados := preload("res://scripts/comum/dados.gd")
const Selecao := preload("res://scripts/menus/selecao.gd")

const CENA_MENU := "res://cenas/menu_principal.tscn"
const CENA_PARTIDA := "res://cenas/partida.tscn"

## [chave no times.json, nome na tela]
const ATRIBUTOS := [
	["ataque", "ATAQUE"], ["defesa", "DEFESA"], ["saque", "SAQUE"],
	["bloqueio", "BLOQUEIO"], ["velocidade", "VELOCIDADE"],
]
const MAXIMO_DO_ATRIBUTO := 5

## Medidas na tela de 1600 x 900.
const LARGURA_DO_PAINEL := 520.0
const MARGEM := 48.0
const TAMANHO_DO_CARTAO := Vector2(196.0, 116.0)
const ESPACO_ENTRE_CARTOES := 12.0
const ALTURA_DOS_CARTOES := 612.0

const DICAS := [
	"Teclado: A/D escolhe  ·  J confirma  ·  Espaço volta\nControle 1: direcional  ·  A confirma  ·  B volta",
	"Teclado: setas escolhem  ·  1 confirma  ·  0 volta (numérico)\nControle 2: direcional  ·  A confirma  ·  B volta",
]

## Imagens opcionais. Se o arquivo existir, aparece na tela.
const PASTA_RETRATOS := "res://arte/times/%s.png"
const PASTA_ESTADIOS := "res://arte/estadios/%s.png"


## Peças da metade da tela de um jogador.
class PainelDoJogador:
	var tinta: TextureRect
	var retrato: TextureRect
	var nome: Label
	var estilo: Label
	var jogada: Label
	var status: Label
	## [atributo] -> Array com os 5 pedaços da barra.
	var segmentos: Array = []
	## [atributo] -> Label "4/5".
	var valores: Array = []


var times: Array = []
var estadios: Array = []
var selecao

var _paineis: Array = []
var _cartoes: Array[Panel] = []
## [jogador][time] -> etiqueta "J1"/"J2" em cima do cartão.
var _fichas: Array = [[], []]
var _faixa_do_estadio: Panel
var _nome_do_estadio: Label
var _descricao_do_estadio: Label
var _dica_do_estadio: Label
var _previa_do_estadio: Control
var _imagem_do_estadio: TextureRect
var _instrucao: Label
var _animacoes := {}
var _imagens := {}
var _saindo := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = Estilo.tema()
	times = Dados.times()
	estadios = Dados.estadios()
	if times.is_empty() or estadios.is_empty():
		push_error("Faltam times ou estádios em dados/times.json ou dados/estadios.json.")
		return

	# Volta com o cursor onde estava (por exemplo, depois de "Trocar times").
	selecao = Selecao.new(times.size(), estadios.size())
	for jogador in 2:
		selecao.posicionar(jogador, Dados.indice_de(times, str(Configuracao.times[jogador])))
	selecao.posicionar_estadio(Dados.indice_de(estadios, Configuracao.estadio))

	_criar_fundo()
	_criar_cabecalho()
	for jogador in 2:
		_paineis.append(_criar_painel_do_jogador(jogador))
	_criar_vs()
	_criar_cartoes()
	_criar_faixa_do_estadio()
	_criar_rodape()
	_atualizar_tudo()
	Estilo.aparecer(self)


func _process(_delta: float) -> void:
	if selecao == null or _saindo:
		return
	if Input.is_action_just_pressed("voltar"):
		_trocar_de_cena(CENA_MENU)
		return
	for jogador in 2:
		var numero := jogador + 1
		if _apertou(numero, "esquerda"):
			_mover(jogador, -1)
		elif _apertou(numero, "direita"):
			_mover(jogador, 1)
		if _apertou(numero, "passe"):
			_confirmar(jogador)
		elif _apertou(numero, "mergulho"):
			_desfazer(jogador)
		if _saindo:
			return


func _apertou(numero: int, acao: String) -> bool:
	return Input.is_action_just_pressed("p%d_%s" % [numero, acao])


# --- O que cada botão faz ---

func _mover(jogador: int, passo: int) -> void:
	if not selecao.mover(jogador, passo):
		return
	if selecao.fase == Selecao.Fase.ESTADIO:
		_atualizar_estadio()
	else:
		_atualizar_painel(jogador)
		_atualizar_cartoes()


func _confirmar(jogador: int) -> void:
	if not selecao.confirmar(jogador):
		return
	if selecao.fase == Selecao.Fase.COMECANDO:
		_comecar_partida()
		return
	_piscar(jogador)
	_atualizar_tudo()


func _desfazer(jogador: int) -> void:
	if selecao.desfazer(jogador):
		_atualizar_tudo()
	else:
		_trocar_de_cena(CENA_MENU)


func _comecar_partida() -> void:
	Configuracao.definir_partida(
		str(times[selecao.cursor[0]]["id"]),
		str(times[selecao.cursor[1]]["id"]),
		str(estadios[selecao.estadio]["id"])
	)
	_atualizar_tudo()
	_trocar_de_cena(CENA_PARTIDA)


func _trocar_de_cena(caminho: String) -> void:
	if _saindo:
		return
	_saindo = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file(caminho))


# --- Atualizar a tela ---

func _atualizar_tudo() -> void:
	for jogador in 2:
		_atualizar_painel(jogador)
	_atualizar_cartoes()
	_atualizar_estadio()
	_atualizar_instrucao()


func _atualizar_painel(jogador: int) -> void:
	var painel: PainelDoJogador = _paineis[jogador]
	var time: Dictionary = times[selecao.cursor[jogador]]
	var cor := _cor_do_menu(time)

	painel.nome.text = str(time.get("nome", "?")).to_upper()
	painel.estilo.text = str(time.get("estilo", ""))
	painel.jogada.text = "Jogada especial: %s" % time.get("jogada", "-")

	var atributos: Dictionary = time.get("atributos", {})
	for a in ATRIBUTOS.size():
		var valor := int(atributos.get(ATRIBUTOS[a][0], 0))
		for s in MAXIMO_DO_ATRIBUTO:
			var segmento: Panel = painel.segmentos[a][s]
			segmento.self_modulate = cor if s < valor else Estilo.PAINEL_CLARO
		var rotulo_valor: Label = painel.valores[a]
		rotulo_valor.text = "%d/%d" % [valor, MAXIMO_DO_ATRIBUTO]

	var pronto: bool = selecao.confirmado[jogador]
	painel.status.text = "PRONTO!" if pronto else "ESCOLHENDO..."
	painel.status.add_theme_color_override("font_color", Estilo.PRONTO if pronto else Estilo.TEXTO_SUAVE)

	_animar("tinta%d" % jogador, painel.tinta, "self_modulate", cor, 0.2)
	painel.retrato.texture = _imagem_opcional(PASTA_RETRATOS % time.get("id", ""))
	painel.retrato.visible = painel.retrato.texture != null


func _atualizar_cartoes() -> void:
	for i in _cartoes.size():
		var cartao: Panel = _cartoes[i]
		var cor := _cor_do_menu(times[i])
		var no_cartao: Array[bool] = [selecao.cursor[0] == i, selecao.cursor[1] == i]
		var algum := no_cartao[0] or no_cartao[1]
		var travado: bool = (no_cartao[0] and selecao.confirmado[0]) or (no_cartao[1] and selecao.confirmado[1])

		var estilo := Estilo.caixa(cor.darkened(0.25 if travado else 0.55), Estilo.INCLINACAO)
		if no_cartao[0] and no_cartao[1]:
			estilo.set_border_width_all(4)
			estilo.border_color = Estilo.TEXTO
		elif algum:
			estilo.set_border_width_all(4)
			estilo.border_color = Estilo.COR_DO_JOGADOR[0 if no_cartao[0] else 1]
		else:
			estilo.border_width_bottom = 6
			estilo.border_color = cor
		cartao.add_theme_stylebox_override("panel", estilo)
		_animar("cartao%d" % i, cartao, "scale", Vector2.ONE * (1.05 if algum else 1.0), 0.12)

		for jogador in 2:
			var ficha: Label = _fichas[jogador][i]
			ficha.visible = no_cartao[jogador]


func _atualizar_estadio() -> void:
	var estadio: Dictionary = estadios[selecao.estadio]
	_nome_do_estadio.text = str(estadio.get("nome", "?")).to_upper()
	_descricao_do_estadio.text = str(estadio.get("descricao", ""))

	var imagem := _imagem_opcional(PASTA_ESTADIOS % estadio.get("id", ""))
	_imagem_do_estadio.texture = imagem
	_imagem_do_estadio.visible = imagem != null
	_previa_do_estadio.visible = imagem == null
	_previa_do_estadio.queue_redraw()

	var ativo: bool = selecao.fase == Selecao.Fase.ESTADIO
	var borda := Estilo.DESTAQUE if ativo else Estilo.PAINEL_CLARO
	_faixa_do_estadio.add_theme_stylebox_override(
		"panel", Estilo.caixa(Estilo.PAINEL, Estilo.INCLINACAO * 0.5, 0.0, 0.0, 3, borda)
	)
	if ativo:
		_dica_do_estadio.text = "Esquerda / direita troca o estádio"
		_dica_do_estadio.add_theme_color_override("font_color", Estilo.DESTAQUE)
	else:
		_dica_do_estadio.text = "Depois dos times, escolham o estádio"
		_dica_do_estadio.add_theme_color_override("font_color", Estilo.TEXTO_APAGADO)


func _atualizar_instrucao() -> void:
	if selecao.fase == Selecao.Fase.COMECANDO:
		_instrucao.text = "BOA PARTIDA!"
	elif selecao.fase == Selecao.Fase.ESTADIO:
		_instrucao.text = "ESCOLHAM O ESTÁDIO E CONFIRMEM PRA COMEÇAR"
	elif selecao.confirmado[0] != selecao.confirmado[1]:
		var falta := 2 if selecao.confirmado[0] else 1
		_instrucao.text = "ESPERANDO O JOGADOR %d CONFIRMAR" % falta
	else:
		_instrucao.text = "ESCOLHAM SEUS TIMES"


## Mini desenho da quadra visto de cima, com as cores do estádio.
func _desenhar_previa() -> void:
	var cores: Dictionary = estadios[selecao.estadio].get("cores", {})
	var area := Rect2(Vector2.ZERO, _previa_do_estadio.size)
	var linhas := Dados.cor(cores, "linhas", Color.WHITE)
	_previa_do_estadio.draw_rect(area, Dados.cor(cores, "fundo", Estilo.FUNDO))

	# Zona livre (28 x 17 m) com as placas em volta.
	var zona := area.grow(-5.0)
	_previa_do_estadio.draw_rect(zona, Dados.cor(cores, "zona_livre", Color.DIM_GRAY))
	_previa_do_estadio.draw_rect(zona, Dados.cor(cores, "placas", Color.GRAY), false, 3.0)

	# Quadra (18 x 9 m), a rede no meio e as linhas de ataque a 3 m dela.
	var escala := minf(zona.size.x / 28.0, zona.size.y / 17.0)
	var tamanho := Vector2(18.0, 9.0) * escala
	var quadra := Rect2(zona.get_center() - tamanho / 2.0, tamanho)
	_previa_do_estadio.draw_rect(quadra, Dados.cor(cores, "quadra", Color.STEEL_BLUE))
	_previa_do_estadio.draw_rect(quadra, linhas, false, 2.0)
	var meio := quadra.get_center().x
	for lado in [-1.0, 1.0]:
		var x: float = meio + lado * 3.0 * escala
		_previa_do_estadio.draw_line(Vector2(x, quadra.position.y), Vector2(x, quadra.end.y), linhas, 1.0)
	_previa_do_estadio.draw_line(Vector2(meio, quadra.position.y - 4.0), Vector2(meio, quadra.end.y + 4.0), linhas, 3.0)


# --- Construção da tela ---

func _criar_fundo() -> void:
	var fundo := ColorRect.new()
	fundo.color = Estilo.FUNDO
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)


func _criar_cabecalho() -> void:
	var barra := Estilo.painel(Estilo.DESTAQUE, Estilo.INCLINACAO)
	barra.position = Vector2(40.0, 24.0)
	barra.size = Vector2(12.0, 58.0)
	add_child(barra)

	var titulo := Estilo.rotulo("PARTIDA RÁPIDA", 40, Estilo.TEXTO, true)
	titulo.position = Vector2(66.0, 14.0)
	add_child(titulo)
	var subtitulo := Estilo.rotulo("SELEÇÃO DE TIMES", 22, Estilo.TEXTO_SUAVE, true)
	subtitulo.position = Vector2(68.0, 60.0)
	add_child(subtitulo)

	var modo := Estilo.etiqueta("2 JOGADORES  ·  LOCAL", Estilo.PAINEL_CLARO, 22, Estilo.TEXTO)
	modo.position = Vector2(1310.0, 28.0)
	modo.size = Vector2(250.0, 44.0)
	add_child(modo)


func _criar_painel_do_jogador(jogador: int) -> PainelDoJogador:
	var painel := PainelDoJogador.new()
	var direita := jogador == 1
	var x := MARGEM if not direita else 1600.0 - MARGEM - LARGURA_DO_PAINEL
	var alinhamento := HORIZONTAL_ALIGNMENT_RIGHT if direita else HORIZONTAL_ALIGNMENT_LEFT

	# Cor do time pintando a metade da tela (fica atrás de tudo).
	painel.tinta = TextureRect.new()
	painel.tinta.texture = Estilo.degrade(not direita, 0.5)
	painel.tinta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	painel.tinta.stretch_mode = TextureRect.STRETCH_SCALE
	painel.tinta.position = Vector2(800.0 * jogador, 0.0)
	painel.tinta.size = Vector2(800.0, 900.0)
	painel.tinta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(painel.tinta)
	move_child(painel.tinta, 1)

	# Retrato opcional (arte/times/<id>.png), entre o painel e o "VS".
	painel.retrato = TextureRect.new()
	painel.retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	painel.retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	painel.retrato.position = Vector2(800.0 if direita else 430.0, 40.0)
	painel.retrato.size = Vector2(370.0, 560.0)
	painel.retrato.flip_h = direita
	painel.retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.retrato.visible = false
	add_child(painel.retrato)

	var cor_do_jogador: Color = Estilo.COR_DO_JOGADOR[jogador]
	var ficha := Estilo.etiqueta("JOGADOR %d" % (jogador + 1), cor_do_jogador, 26)
	ficha.position = Vector2(x + LARGURA_DO_PAINEL - 200.0 if direita else x, 116.0)
	ficha.size = Vector2(200.0, 40.0)
	add_child(ficha)

	painel.status = Estilo.rotulo("", 22, Estilo.TEXTO_SUAVE, true)
	painel.status.position = Vector2(x + LARGURA_DO_PAINEL - 456.0 if direita else x + 216.0, 120.0)
	painel.status.size = Vector2(240.0, 32.0)
	painel.status.horizontal_alignment = alinhamento
	add_child(painel.status)

	painel.nome = _rotulo_do_painel(72, Estilo.TEXTO, true, Vector2(x, 154.0), 88.0, alinhamento)
	painel.estilo = _rotulo_do_painel(24, Estilo.TEXTO_SUAVE, false, Vector2(x, 238.0), 32.0, alinhamento)

	# Barras de atributo: nome, 5 pedaços e o número.
	var largura_do_bloco := 150.0 + 10.0 + MAXIMO_DO_ATRIBUTO * 46.0 + 12.0 + 56.0
	var bloco_x := x + LARGURA_DO_PAINEL - largura_do_bloco if direita else x + 2.0
	for a in ATRIBUTOS.size():
		var y := 284.0 + a * 42.0
		var nome_do_atributo := Estilo.rotulo(ATRIBUTOS[a][1], 22, Estilo.TEXTO, true)
		nome_do_atributo.position = Vector2(bloco_x, y)
		add_child(nome_do_atributo)

		var pedacos: Array = []
		for s in MAXIMO_DO_ATRIBUTO:
			var pedaco := Estilo.painel(Color.WHITE, Estilo.INCLINACAO)
			pedaco.position = Vector2(bloco_x + 160.0 + s * 46.0, y + 9.0)
			pedaco.size = Vector2(38.0, 16.0)
			add_child(pedaco)
			pedacos.append(pedaco)
		painel.segmentos.append(pedacos)

		var valor := Estilo.rotulo("", 22, Estilo.TEXTO, true)
		valor.position = Vector2(bloco_x + 160.0 + MAXIMO_DO_ATRIBUTO * 46.0 + 12.0, y)
		add_child(valor)
		painel.valores.append(valor)

	painel.jogada = _rotulo_do_painel(20, Estilo.TEXTO_SUAVE, false, Vector2(x, 496.0), 28.0, alinhamento)
	var dica := _rotulo_do_painel(17, Estilo.TEXTO_APAGADO, false, Vector2(x, 530.0), 50.0, alinhamento)
	dica.text = DICAS[jogador]
	return painel


func _rotulo_do_painel(tamanho: int, cor: Color, titulo: bool, posicao: Vector2,
		altura: float, alinhamento: HorizontalAlignment) -> Label:
	var novo := Estilo.rotulo("", tamanho, cor, titulo)
	novo.position = posicao
	novo.size = Vector2(LARGURA_DO_PAINEL, altura)
	novo.horizontal_alignment = alinhamento
	add_child(novo)
	return novo


func _criar_vs() -> void:
	var vs := Estilo.rotulo("VS", 140, Estilo.TEXTO, true)
	vs.position = Vector2(650.0, 210.0)
	vs.size = Vector2(300.0, 170.0)
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vs.add_theme_color_override("font_outline_color", Estilo.DESTAQUE)
	vs.add_theme_constant_override("outline_size", 10)
	add_child(vs)


func _criar_cartoes() -> void:
	# Faixa escura atrás dos cartões.
	var faixa := Estilo.painel(Color(0.04, 0.05, 0.07, 0.85))
	faixa.position = Vector2(0.0, ALTURA_DOS_CARTOES - 40.0)
	faixa.size = Vector2(1600.0, TAMANHO_DO_CARTAO.y + 66.0)
	add_child(faixa)

	var quantidade := times.size()
	var largura_total := quantidade * TAMANHO_DO_CARTAO.x + (quantidade - 1) * ESPACO_ENTRE_CARTOES
	var inicio := (1600.0 - largura_total) / 2.0
	for i in quantidade:
		var time: Dictionary = times[i]
		var cartao := Panel.new()
		cartao.position = Vector2(inicio + i * (TAMANHO_DO_CARTAO.x + ESPACO_ENTRE_CARTOES), ALTURA_DOS_CARTOES)
		cartao.size = TAMANHO_DO_CARTAO
		cartao.pivot_offset = TAMANHO_DO_CARTAO / 2.0
		cartao.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cartao)
		_cartoes.append(cartao)

		var nome := Estilo.rotulo(str(time.get("nome", "?")).to_upper(), 26, Estilo.TEXTO, true)
		nome.position = Vector2(0.0, 22.0)
		nome.size = Vector2(TAMANHO_DO_CARTAO.x, 40.0)
		nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cartao.add_child(nome)

		# As duas cores do uniforme.
		var cores: Array = time.get("cores", [])
		for k in mini(cores.size(), 2):
			var amostra := ColorRect.new()
			amostra.color = Color.from_string(str(cores[k]), Color.WHITE)
			amostra.position = Vector2(TAMANHO_DO_CARTAO.x / 2.0 - 38.0 + k * 42.0, 76.0)
			amostra.size = Vector2(34.0, 12.0)
			amostra.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cartao.add_child(amostra)

		for jogador in 2:
			var ficha := Estilo.etiqueta("J%d" % (jogador + 1), Estilo.COR_DO_JOGADOR[jogador], 18)
			var deslocamento := 6.0 if jogador == 0 else TAMANHO_DO_CARTAO.x - 6.0 - 48.0
			ficha.position = cartao.position + Vector2(deslocamento, -32.0)
			ficha.size = Vector2(48.0, 26.0)
			ficha.visible = false
			add_child(ficha)
			_fichas[jogador].append(ficha)


func _criar_faixa_do_estadio() -> void:
	_faixa_do_estadio = Panel.new()
	_faixa_do_estadio.position = Vector2(200.0, 758.0)
	_faixa_do_estadio.size = Vector2(1200.0, 92.0)
	_faixa_do_estadio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_faixa_do_estadio)

	var rotulo := Estilo.rotulo("ESTÁDIO", 28, Estilo.TEXTO, true)
	rotulo.position = Vector2(40.0, 26.0)
	_faixa_do_estadio.add_child(rotulo)

	var seta_esquerda := Estilo.rotulo("<", 44, Estilo.TEXTO_SUAVE, true)
	seta_esquerda.position = Vector2(206.0, 14.0)
	_faixa_do_estadio.add_child(seta_esquerda)

	_previa_do_estadio = Control.new()
	_previa_do_estadio.position = Vector2(244.0, 6.0)
	_previa_do_estadio.size = Vector2(150.0, 80.0)
	_previa_do_estadio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_previa_do_estadio.draw.connect(_desenhar_previa)
	_faixa_do_estadio.add_child(_previa_do_estadio)

	_imagem_do_estadio = TextureRect.new()
	_imagem_do_estadio.position = _previa_do_estadio.position
	_imagem_do_estadio.size = _previa_do_estadio.size
	_imagem_do_estadio.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_imagem_do_estadio.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_imagem_do_estadio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_imagem_do_estadio.visible = false
	_faixa_do_estadio.add_child(_imagem_do_estadio)

	var seta_direita := Estilo.rotulo(">", 44, Estilo.TEXTO_SUAVE, true)
	seta_direita.position = Vector2(406.0, 14.0)
	_faixa_do_estadio.add_child(seta_direita)

	_nome_do_estadio = Estilo.rotulo("", 36, Estilo.TEXTO, true)
	_nome_do_estadio.position = Vector2(460.0, 6.0)
	_faixa_do_estadio.add_child(_nome_do_estadio)
	_descricao_do_estadio = Estilo.rotulo("", 21, Estilo.TEXTO_SUAVE)
	_descricao_do_estadio.position = Vector2(462.0, 50.0)
	_faixa_do_estadio.add_child(_descricao_do_estadio)

	_dica_do_estadio = Estilo.rotulo("", 21, Estilo.TEXTO_APAGADO, true)
	_dica_do_estadio.position = Vector2(780.0, 30.0)
	_dica_do_estadio.size = Vector2(380.0, 32.0)
	_dica_do_estadio.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_faixa_do_estadio.add_child(_dica_do_estadio)


func _criar_rodape() -> void:
	var voltar := Estilo.rotulo("Esc: voltar ao menu", 19, Estilo.TEXTO_APAGADO)
	voltar.position = Vector2(40.0, 862.0)
	add_child(voltar)

	_instrucao = Estilo.rotulo("", 24, Estilo.TEXTO, true)
	_instrucao.position = Vector2(0.0, 856.0)
	_instrucao.size = Vector2(1600.0, 36.0)
	_instrucao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_instrucao)


# --- Ajudantes ---

func _cor_do_menu(time: Dictionary) -> Color:
	return Dados.cor(time, "cor_do_menu", Estilo.DESTAQUE)


## Quando o jogador confirma, a metade dele pisca rapidinho.
func _piscar(jogador: int) -> void:
	var painel: PainelDoJogador = _paineis[jogador]
	var cor := _cor_do_menu(times[selecao.cursor[jogador]])
	_parar_animacao("tinta%d" % jogador)
	var tween := create_tween()
	tween.tween_property(painel.tinta, "self_modulate", Color.WHITE, 0.06)
	tween.tween_property(painel.tinta, "self_modulate", cor, 0.3)
	_animacoes["tinta%d" % jogador] = tween


## Anima uma propriedade, cancelando a animação anterior com a mesma chave.
func _animar(chave: String, alvo: Object, propriedade: String, valor: Variant, duracao: float) -> void:
	_parar_animacao(chave)
	var tween := create_tween()
	tween.tween_property(alvo, propriedade, valor, duracao)
	_animacoes[chave] = tween


func _parar_animacao(chave: String) -> void:
	var anterior = _animacoes.get(chave)
	if anterior is Tween and anterior.is_valid():
		anterior.kill()


## Carrega uma imagem só se o arquivo existir (guarda pra não carregar de novo).
func _imagem_opcional(caminho: String) -> Texture2D:
	if not _imagens.has(caminho):
		var imagem: Texture2D = null
		if ResourceLoader.exists(caminho):
			imagem = load(caminho) as Texture2D
		_imagens[caminho] = imagem
	return _imagens[caminho]
