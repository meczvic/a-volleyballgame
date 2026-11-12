extends Control
## Seleção de times: cada jogador escolhe o seu time, depois o estádio.
##
## Jogador 1: A/D escolhe, J confirma, Espaço volta (ou o 1º controle: direcional, A, B).
## Jogador 2: setas escolhem, 1 confirma, 0 volta no numérico (ou o 2º controle).
## Esc volta pro menu principal.
##
## Contra o computador (1 jogador): o Jogador 1 escolhe o próprio time e depois
## o do computador, com as mesmas teclas.
##
## As regras (quem confirmou, em que fase está) ficam em selecao.gd.
## Este arquivo só desenha a tela e lê os botões.
##
## Visual (tela de 1600 x 900, a referência é "Seleção de Times no Ginásio
## Japonês"): cada metade tem a etiqueta do jogador, o emblema e o nome do time,
## os atributos com ícone e barra, e o atleta destaque em 3D (retrato_do_atleta.gd).
## No meio, o VS com um raio nas cores dos dois times. Embaixo, os 7 cartões
## com emblema, a faixa do estádio e os botões.

const Estilo := preload("res://scripts/menus/estilo.gd")
const Dados := preload("res://scripts/comum/dados.gd")
const Selecao := preload("res://scripts/menus/selecao.gd")
const RetratoDoAtleta := preload("res://scripts/menus/retrato_do_atleta.gd")
const EntradaDoComputador := preload("res://scripts/entrada/entrada_do_computador.gd")

const CENA_MENU := "res://cenas/menu_principal.tscn"
const CENA_PARTIDA := "res://cenas/partida.tscn"

## [chave no times.json, nome na tela, ícone em arte/icones/]
const ATRIBUTOS := [
	["ataque", "ATAQUE", "ataque"], ["defesa", "DEFESA", "defesa"], ["saque", "SAQUE", "saque"],
	["bloqueio", "BLOQUEIO", "bloqueio"], ["velocidade", "VELOCIDADE", "velocidade"],
]
const MAXIMO_DO_ATRIBUTO := 5

## Medidas na tela de 1600 x 900.
const LARGURA := 1600.0
const MARGEM := 40.0
const LARGURA_DO_PAINEL := 450.0
const TAMANHO_DO_EMBLEMA := 120.0
const TOPO_DOS_ATRIBUTOS := 292.0
const ALTURA_DA_LINHA := 40.0
const TAMANHO_DO_RETRATO := Vector2(400.0, 560.0)
const TAMANHO_DO_CARTAO := Vector2(190.0, 132.0)
const ESPACO_ENTRE_CARTOES := 14.0
const ALTURA_DOS_CARTOES := 608.0
const CENTRO_DO_VS := Vector2(800.0, 300.0)

const DICA_DO_COMPUTADOR := "O Jogador 1 escolhe o time do computador
depois de confirmar o dele"

const DICAS := [
	"Teclado: A/D escolhe  ·  J confirma  ·  Espaço desfaz\nControle 1: direcional  ·  A confirma  ·  B desfaz",
	"Teclado: setas escolhem  ·  1 confirma  ·  0 desfaz (numérico)\nControle 2: direcional  ·  A confirma  ·  B desfaz",
]

## Imagens. Retrato 2D e prévia do estádio são opcionais: se o arquivo existir,
## aparece no lugar do retrato 3D / do desenho da quadra.
const PASTA_RETRATOS := "res://arte/times/%s.png"
const PASTA_ESTADIOS := "res://arte/estadios/%s.png"
const PASTA_EMBLEMAS := "res://arte/emblemas/%s.svg"
const PASTA_ICONES := "res://arte/icones/%s.svg"


## Peças da metade da tela de um jogador.
class PainelDoJogador:
	var tinta: TextureRect
	var retrato_3d: RetratoDoAtleta
	var retrato: TextureRect
	var emblema: TextureRect
	var inicial: Label
	var nome: Label
	var estilo: Label
	var jogada: Label
	var status: Label
	var sublinhado: Panel
	## [atributo] -> Array com os 5 pedaços da barra.
	var segmentos: Array = []
	## [atributo] -> Label "4/5".
	var valores: Array = []
	## [atributo] -> ícone.
	var icones: Array = []
	## Posição de descanso do nome (ele desliza a partir dela).
	var nome_x := 0.0


var times: Array = []
var estadios: Array = []
var selecao

var _paineis: Array = []
var _cartoes: Array[Panel] = []
## [jogador][time] -> etiqueta "J1"/"J2" em cima do cartão.
var _fichas: Array = [[], []]
var _fundo: Control
## Foto do estádio escolhido, desfocada e escura, atrás de tudo (como na referência).
var _foto_do_fundo: TextureRect
var _fotos_desfocadas := {}
var _raio: Control
var _vs: Label
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
## Cor do time de cada lado, pro fundo e pro raio do VS.
var _cores_dos_lados: Array[Color] = [Estilo.DESTAQUE, Estilo.DESTAQUE]


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
	for jogador in 2:
		_paineis.append(_criar_painel_do_jogador(jogador))
	_criar_vs()
	_criar_cabecalho()
	_criar_cartoes()
	_criar_faixa_do_estadio()
	_criar_rodape()
	_atualizar_tudo(false)
	Estilo.aparecer(self)


func _process(_delta: float) -> void:
	if selecao == null or _saindo:
		return
	if Input.is_action_just_pressed("voltar"):
		_trocar_de_cena(CENA_MENU)
		return
	if Configuracao.contra_computador:
		_ler_botoes_de_um_jogador()
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


## Contra o computador: os botões do Jogador 1 escolhem o time dele e, depois
## de confirmado, o do computador. Desfazer volta na ordem contrária.
func _ler_botoes_de_um_jogador() -> void:
	var lado := 0 if not selecao.confirmado[0] else 1
	if _apertou(1, "esquerda"):
		_mover(lado, -1)
	elif _apertou(1, "direita"):
		_mover(lado, 1)
	if _apertou(1, "passe"):
		_confirmar(lado)
	elif _apertou(1, "mergulho"):
		if selecao.fase == Selecao.Fase.TIMES and not selecao.confirmado[1] and selecao.confirmado[0]:
			_desfazer(0)
		else:
			_desfazer(lado)


func _apertou(numero: int, acao: String) -> bool:
	return Input.is_action_just_pressed("p%d_%s" % [numero, acao])


# --- O que cada botão faz ---

func _mover(jogador: int, passo: int) -> void:
	if not selecao.mover(jogador, passo):
		return
	if selecao.fase == Selecao.Fase.ESTADIO:
		_atualizar_estadio()
		_deslizar(_previa_do_estadio, passo)
		_deslizar(_imagem_do_estadio, passo)
	else:
		_atualizar_painel(jogador, true, passo)
		# O outro lado também pode mudar (uniforme reserva com o mesmo time).
		_atualizar_painel(1 - jogador, false)
		_atualizar_cartoes()


func _confirmar(jogador: int) -> void:
	if not selecao.confirmar(jogador):
		return
	if selecao.fase == Selecao.Fase.COMECANDO:
		_comecar_partida()
		return
	_piscar(jogador)
	_atualizar_tudo(false)


func _desfazer(jogador: int) -> void:
	if selecao.desfazer(jogador):
		_atualizar_tudo(false)
	else:
		_trocar_de_cena(CENA_MENU)


func _comecar_partida() -> void:
	Configuracao.definir_partida(
		str(times[selecao.cursor[0]]["id"]),
		str(times[selecao.cursor[1]]["id"]),
		str(estadios[selecao.estadio]["id"])
	)
	_atualizar_tudo(false)
	_trocar_de_cena(CENA_PARTIDA)


func _trocar_de_cena(caminho: String) -> void:
	if _saindo:
		return
	_saindo = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file(caminho))


# --- Atualizar a tela ---

func _atualizar_tudo(animar: bool) -> void:
	for jogador in 2:
		_atualizar_painel(jogador, animar)
	_atualizar_cartoes()
	_atualizar_estadio()
	_atualizar_instrucao()


## Time como ele vai entrar em quadra: o Jogador 2 com o mesmo time usa o reserva.
func _time_em_jogo(jogador: int) -> Dictionary:
	var time: Dictionary = times[selecao.cursor[jogador]]
	if jogador == 1 and selecao.cursor[0] == selecao.cursor[1]:
		return Dados.com_uniforme_reserva(time)
	return time


func _atualizar_painel(jogador: int, animar: bool, passo := 0) -> void:
	var painel: PainelDoJogador = _paineis[jogador]
	var time: Dictionary = times[selecao.cursor[jogador]]
	var cor := _cor_do_menu(time)

	painel.nome.text = str(time.get("nome", "?")).to_upper()
	painel.estilo.text = str(time.get("estilo", ""))
	painel.jogada.text = "Jogada especial: %s" % time.get("jogada", "-")

	var emblema := _emblema(time)
	painel.emblema.texture = emblema
	painel.inicial.visible = emblema == null
	painel.inicial.text = painel.nome.text.left(1)
	painel.inicial.add_theme_stylebox_override("normal", Estilo.caixa(cor.darkened(0.3), Estilo.INCLINACAO))

	var atributos: Dictionary = time.get("atributos", {})
	for a in ATRIBUTOS.size():
		var rotulo_valor: Label = painel.valores[a]
		rotulo_valor.text = "%d/%d" % [int(atributos.get(ATRIBUTOS[a][0], 0)), MAXIMO_DO_ATRIBUTO]
		(painel.icones[a] as TextureRect).self_modulate = cor
	if animar:
		_animar_metodo("barras%d" % jogador, func(p: float) -> void: _pintar_barras(jogador, p), 0.0, 1.0, 0.3)
	else:
		_parar_animacao("barras%d" % jogador)
		_pintar_barras(jogador, 1.0)

	var pronto: bool = selecao.confirmado[jogador]
	painel.status.text = "PRONTO!" if pronto else "ESCOLHENDO..."
	painel.status.add_theme_color_override("font_color", Estilo.PRONTO if pronto else Estilo.TEXTO_SUAVE)
	painel.sublinhado.self_modulate = cor

	_cores_dos_lados[jogador] = cor
	_animar("tinta%d" % jogador, painel.tinta, "self_modulate", cor, 0.2)
	_fundo.queue_redraw()
	_raio.queue_redraw()

	# Retrato: arte 2D se existir, senão o atleta destaque em 3D.
	var arte := _imagem_opcional(PASTA_RETRATOS % time.get("id", ""))
	painel.retrato.texture = arte
	painel.retrato.visible = arte != null
	painel.retrato_3d.visible = arte == null
	if arte == null:
		painel.retrato_3d.mostrar(_time_em_jogo(jogador), cor.lightened(0.2))
		painel.retrato_3d.comemorar(pronto)

	if animar:
		# Emblema dá um pulinho e o nome entra deslizando do lado do movimento.
		painel.emblema.scale = Vector2.ONE * 0.75
		_animar("emblema%d" % jogador, painel.emblema, "scale", Vector2.ONE, 0.25, Tween.TRANS_BACK)
		painel.nome.position.x = painel.nome_x + 36.0 * signf(passo if passo != 0 else 1)
		painel.nome.modulate.a = 0.0
		_animar("nome%d" % jogador, painel.nome, "position:x", painel.nome_x, 0.18)
		_animar("nome_alfa%d" % jogador, painel.nome, "modulate:a", 1.0, 0.18)


## Pinta as barras de atributo; "progresso" de 0 a 1 enche da esquerda pra direita.
func _pintar_barras(jogador: int, progresso: float) -> void:
	var painel: PainelDoJogador = _paineis[jogador]
	var time: Dictionary = times[selecao.cursor[jogador]]
	var cor := _cor_do_menu(time)
	var atributos: Dictionary = time.get("atributos", {})
	for a in ATRIBUTOS.size():
		var valor := int(atributos.get(ATRIBUTOS[a][0], 0))
		var acesos := int(ceil(valor * progresso))
		for s in MAXIMO_DO_ATRIBUTO:
			var segmento: Panel = painel.segmentos[a][s]
			segmento.self_modulate = cor if s < acesos else Estilo.PAINEL_CLARO


func _atualizar_cartoes() -> void:
	for i in _cartoes.size():
		var cartao: Panel = _cartoes[i]
		var cor := _cor_do_menu(times[i])
		var no_cartao: Array[bool] = [selecao.cursor[0] == i, selecao.cursor[1] == i]
		var algum := no_cartao[0] or no_cartao[1]
		var travado: bool = (no_cartao[0] and selecao.confirmado[0]) or (no_cartao[1] and selecao.confirmado[1])

		var estilo := Estilo.caixa(cor.darkened(0.2 if travado else (0.45 if algum else 0.62)), Estilo.INCLINACAO)
		estilo.border_width_bottom = 6
		estilo.border_color = cor
		if algum:
			var cor_da_borda: Color = Estilo.TEXTO if no_cartao[0] and no_cartao[1] else Estilo.COR_DO_JOGADOR[0 if no_cartao[0] else 1]
			estilo.set_border_width_all(4)
			estilo.border_width_bottom = 6
			estilo.border_color = cor_da_borda
			estilo.shadow_color = Color(cor_da_borda, 0.55)
			estilo.shadow_size = 14
		cartao.add_theme_stylebox_override("panel", estilo)
		_animar("cartao%d" % i, cartao, "scale", Vector2.ONE * (1.07 if algum else 1.0), 0.12)
		cartao.modulate = Color.WHITE if algum else Color(0.82, 0.82, 0.86)

		for jogador in 2:
			var ficha: Label = _fichas[jogador][i]
			ficha.visible = no_cartao[jogador]


func _atualizar_estadio() -> void:
	var estadio: Dictionary = estadios[selecao.estadio]
	_nome_do_estadio.text = str(estadio.get("nome", "?")).to_upper()
	_descricao_do_estadio.text = str(estadio.get("descricao", ""))

	var imagem := _imagem_opcional(PASTA_ESTADIOS % estadio.get("id", ""))
	_foto_do_fundo.texture = _desfocada(str(estadio.get("id", "")), imagem)
	_fundo.queue_redraw()
	_imagem_do_estadio.texture = imagem
	_imagem_do_estadio.visible = imagem != null
	_previa_do_estadio.visible = imagem == null
	_previa_do_estadio.queue_redraw()

	var ativo: bool = selecao.fase == Selecao.Fase.ESTADIO
	var borda := Estilo.DESTAQUE if ativo else Estilo.PAINEL_CLARO
	var estilo := Estilo.caixa(Color(Estilo.PAINEL, 0.92), Estilo.INCLINACAO * 0.5, 0.0, 0.0, 3, borda)
	if ativo:
		estilo.shadow_color = Color(Estilo.DESTAQUE, 0.35)
		estilo.shadow_size = 12
	_faixa_do_estadio.add_theme_stylebox_override("panel", estilo)
	if ativo:
		_dica_do_estadio.text = "Esquerda / direita troca o estádio"
		_dica_do_estadio.add_theme_color_override("font_color", Estilo.DESTAQUE)
	else:
		_dica_do_estadio.text = "Depois dos times, escolham o estádio"
		_dica_do_estadio.add_theme_color_override("font_color", Estilo.TEXTO_APAGADO)


func _atualizar_instrucao() -> void:
	if selecao.fase == Selecao.Fase.COMECANDO:
		_instrucao.text = "BOA PARTIDA!"
	elif selecao.fase == Selecao.Fase.ESTADIO and Configuracao.contra_computador:
		_instrucao.text = "ESCOLHA O ESTÁDIO E CONFIRME PRA COMEÇAR"
	elif selecao.fase == Selecao.Fase.ESTADIO:
		_instrucao.text = "ESCOLHAM O ESTÁDIO E CONFIRMEM PRA COMEÇAR"
	elif Configuracao.contra_computador:
		_instrucao.text = "ESCOLHA O TIME DO COMPUTADOR" if selecao.confirmado[0] else "ESCOLHA O SEU TIME"
	elif selecao.confirmado[0] != selecao.confirmado[1]:
		var falta := 2 if selecao.confirmado[0] else 1
		_instrucao.text = "ESPERANDO O JOGADOR %d CONFIRMAR" % falta
	else:
		_instrucao.text = "ESCOLHAM SEUS TIMES"


# --- Desenhos feitos em código ---

## Fundo: carvão, luz diagonal nas cores dos times, piso de madeira embaixo e
## a sombra do atleta de cada lado.
func _desenhar_fundo() -> void:
	# Com a foto do estádio atrás, o carvão fica translúcido.
	var com_foto := _foto_do_fundo != null and _foto_do_fundo.texture != null
	_fundo.draw_rect(Rect2(0.0, 0.0, LARGURA, 900.0), Color(Estilo.FUNDO, 0.55 if com_foto else 1.0))
	for jogador in 2:
		var cor: Color = _cores_dos_lados[jogador]
		var lado := -1.0 if jogador == 0 else 1.0
		# Faixas de luz inclinadas atrás do atleta.
		for k in 4:
			var x := 800.0 + lado * (140.0 + k * 120.0)
			var largura := 70.0 - k * 10.0
			var topo := Vector2(x + lado * 160.0, 0.0)
			var pontos := PackedVector2Array([
				topo, topo + Vector2(largura, 0.0),
				Vector2(x + largura, 600.0), Vector2(x, 600.0),
			])
			_fundo.draw_colored_polygon(pontos, Color(cor, 0.07 - k * 0.012))
	# Piso de madeira em perspectiva atrás dos cartões e do estádio.
	var horizonte := 586.0
	_fundo.draw_rect(Rect2(0.0, horizonte, LARGURA, 900.0 - horizonte), Color("#3A2416", 0.6 if com_foto else 1.0))
	for t in 9:
		var y := horizonte + pow(t / 8.0, 1.6) * (900.0 - horizonte)
		_fundo.draw_line(Vector2(0.0, y), Vector2(LARGURA, y), Color("#2A190F"), 2.0)
	for k in range(-12, 13):
		var base := 800.0 + k * 150.0
		_fundo.draw_line(Vector2(800.0 + k * 40.0, horizonte), Vector2(base, 900.0), Color("#2A190F", 0.7), 2.0)
	_fundo.draw_rect(Rect2(0.0, horizonte, LARGURA, 900.0 - horizonte), Color(0.0, 0.0, 0.0, 0.35))
	# Sombra no chão embaixo dos atletas.
	for jogador in 2:
		var centro := Vector2(588.0 if jogador == 0 else 1012.0, 520.0)
		_desenhar_elipse(_fundo, centro, Vector2(120.0, 16.0), Color(0.0, 0.0, 0.0, 0.45))
		_desenhar_elipse(_fundo, centro, Vector2(170.0, 26.0), Color(_cores_dos_lados[jogador], 0.18))


## Raio atrás do "VS": vai da cor do Jogador 1 (baixo) pra cor do Jogador 2 (cima).
func _desenhar_raio() -> void:
	var c := CENTRO_DO_VS - _raio.position
	var pontos := PackedVector2Array([
		c + Vector2(-150.0, 190.0), c + Vector2(-8.0, 10.0), c + Vector2(-34.0, 2.0),
		c + Vector2(150.0, -190.0), c + Vector2(10.0, -8.0), c + Vector2(36.0, 0.0),
	])
	var cor_1: Color = _cores_dos_lados[0]
	var cor_2: Color = _cores_dos_lados[1]
	var cores := PackedColorArray([cor_1, cor_1.lerp(Color.WHITE, 0.6), cor_1.lerp(Color.WHITE, 0.6),
		cor_2, cor_2.lerp(Color.WHITE, 0.6), cor_2.lerp(Color.WHITE, 0.6)])
	_raio.draw_polygon(pontos, cores)


## Mini desenho da quadra visto de cima, com as cores do estádio.
func _desenhar_previa() -> void:
	var cores: Dictionary = estadios[selecao.estadio].get("cores", {})
	var area := Rect2(Vector2.ZERO, _previa_do_estadio.size)
	var linhas := Dados.cor(cores, "linhas", Color.WHITE)
	_previa_do_estadio.draw_rect(area, Dados.cor(cores, "fundo", Estilo.FUNDO))

	# Zona livre (28 x 17 m) com as placas em volta.
	var zona := area.grow(-6.0)
	_previa_do_estadio.draw_rect(zona, Dados.cor(cores, "zona_livre", Color.DIM_GRAY))
	_previa_do_estadio.draw_rect(zona, Dados.cor(cores, "placas", Color.GRAY), false, 4.0)

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
	_previa_do_estadio.draw_line(Vector2(meio, quadra.position.y - 5.0), Vector2(meio, quadra.end.y + 5.0), linhas, 3.0)
	_previa_do_estadio.draw_rect(area, Color(1.0, 1.0, 1.0, 0.25), false, 2.0)


func _desenhar_elipse(no: CanvasItem, centro: Vector2, raios: Vector2, cor: Color) -> void:
	var pontos := PackedVector2Array()
	for i in 32:
		var angulo := TAU * i / 32.0
		pontos.append(centro + Vector2(cos(angulo) * raios.x, sin(angulo) * raios.y))
	no.draw_colored_polygon(pontos, cor)


# --- Construção da tela ---

func _criar_fundo() -> void:
	var base := ColorRect.new()
	base.color = Estilo.FUNDO
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	_foto_do_fundo = TextureRect.new()
	_foto_do_fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_foto_do_fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_foto_do_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_foto_do_fundo.modulate = Color(0.55, 0.52, 0.52)
	_foto_do_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_foto_do_fundo)
	_fundo = Control.new()
	_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fundo.draw.connect(_desenhar_fundo)
	add_child(_fundo)


func _criar_cabecalho() -> void:
	var barra := Estilo.painel(Estilo.DESTAQUE, Estilo.INCLINACAO)
	barra.position = Vector2(MARGEM, 24.0)
	barra.size = Vector2(12.0, 58.0)
	add_child(barra)

	var bola := _icone("saque", 50.0, Estilo.TEXTO)
	bola.position = Vector2(66.0, 28.0)
	add_child(bola)

	var modo := "MODO CAOS" if Configuracao.modo == "caos" else "PARTIDA RÁPIDA"
	var titulo := Estilo.rotulo(modo, 38, Estilo.TEXTO, true)
	titulo.position = Vector2(128.0, 14.0)
	add_child(titulo)
	var subtitulo := Estilo.rotulo("SELEÇÃO DE TIMES", 22, Estilo.TEXTO_SUAVE, true)
	subtitulo.position = Vector2(130.0, 58.0)
	add_child(subtitulo)

	var caixa := Estilo.painel(Color(Estilo.PAINEL, 0.9), Estilo.INCLINACAO, 2, Estilo.DESTAQUE)
	caixa.position = Vector2(LARGURA - MARGEM - 270.0, 28.0)
	caixa.size = Vector2(270.0, 46.0)
	add_child(caixa)
	var pessoas := _icone("jogadores", 28.0, Estilo.TEXTO)
	pessoas.position = Vector2(22.0, 9.0)
	caixa.add_child(pessoas)
	var texto := Estilo.rotulo(_texto_do_modo(), 22, Estilo.TEXTO, true)
	texto.position = Vector2(60.0, 8.0)
	caixa.add_child(texto)


## "2 JOGADORES · LOCAL" ou, contra o computador, "1 JOGADOR · NORMAL".
func _texto_do_modo() -> String:
	if not Configuracao.contra_computador:
		return "2 JOGADORES  ·  LOCAL"
	var nivel := EntradaDoComputador.ajustes_do_nivel(str(Configuracao.dificuldade))
	return "1 JOGADOR  ·  %s" % str(nivel.get("nome", "")).to_upper()


## Nome do lado: "JOGADOR 1", "JOGADOR 2" ou "COMPUTADOR".
func _nome_do_lado(jogador: int) -> String:
	if jogador == 1 and Configuracao.contra_computador:
		return "COMPUTADOR"
	return "JOGADOR %d" % (jogador + 1)


func _criar_painel_do_jogador(jogador: int) -> PainelDoJogador:
	var painel := PainelDoJogador.new()
	var direita := jogador == 1
	var x := MARGEM if not direita else LARGURA - MARGEM - LARGURA_DO_PAINEL
	var alinhamento := HORIZONTAL_ALIGNMENT_RIGHT if direita else HORIZONTAL_ALIGNMENT_LEFT

	# Cor do time pintando a metade da tela (fica atrás de tudo).
	painel.tinta = TextureRect.new()
	painel.tinta.texture = Estilo.degrade(not direita, 0.42)
	painel.tinta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	painel.tinta.stretch_mode = TextureRect.STRETCH_SCALE
	painel.tinta.position = Vector2(800.0 * jogador, 0.0)
	painel.tinta.size = Vector2(800.0, 590.0)
	painel.tinta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(painel.tinta)

	# Atleta destaque em 3D, entre os atributos e o "VS".
	var posicao_do_retrato := Vector2(810.0 if direita else 390.0, 40.0)
	painel.retrato_3d = RetratoDoAtleta.new()
	painel.retrato_3d.position = posicao_do_retrato
	painel.retrato_3d.size = TAMANHO_DO_RETRATO
	painel.retrato_3d.configurar(not direita)
	add_child(painel.retrato_3d)

	# Retrato 2D opcional (arte/times/<id>.png), no mesmo lugar.
	painel.retrato = TextureRect.new()
	painel.retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	painel.retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	painel.retrato.position = posicao_do_retrato
	painel.retrato.size = TAMANHO_DO_RETRATO
	painel.retrato.flip_h = direita
	painel.retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.retrato.visible = false
	add_child(painel.retrato)

	# Etiqueta do jogador com o ícone do controle.
	var cor_do_jogador: Color = Estilo.COR_DO_JOGADOR[jogador]
	var ficha := Estilo.etiqueta(_nome_do_lado(jogador), cor_do_jogador, 26)
	ficha.position = Vector2(x + LARGURA_DO_PAINEL - 232.0 if direita else x, 98.0)
	ficha.size = Vector2(232.0, 42.0)
	ficha.add_theme_constant_override("line_spacing", 0)
	add_child(ficha)
	var controle := _icone("controle", 28.0, Estilo.FUNDO)
	controle.position = Vector2(20.0, 7.0)
	ficha.add_child(controle)

	painel.status = Estilo.rotulo("", 22, Estilo.TEXTO_SUAVE, true)
	painel.status.position = Vector2(x + LARGURA_DO_PAINEL - 232.0 - 16.0 - 200.0 if direita else x + 248.0, 106.0)
	painel.status.size = Vector2(200.0, 32.0)
	painel.status.horizontal_alignment = alinhamento
	painel.status.pivot_offset = Vector2(0.0 if not direita else 200.0, 16.0)
	add_child(painel.status)

	# Emblema e nome do time.
	var emblema_x := x if not direita else x + LARGURA_DO_PAINEL - TAMANHO_DO_EMBLEMA
	painel.emblema = TextureRect.new()
	painel.emblema.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	painel.emblema.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	painel.emblema.position = Vector2(emblema_x, 148.0)
	painel.emblema.size = Vector2.ONE * TAMANHO_DO_EMBLEMA
	painel.emblema.pivot_offset = Vector2.ONE * TAMANHO_DO_EMBLEMA / 2.0
	painel.emblema.flip_h = direita
	painel.emblema.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(painel.emblema)
	# Sem emblema: a inicial do time num quadrado da cor dele.
	painel.inicial = Estilo.rotulo("", 72, Estilo.TEXTO, true)
	painel.inicial.position = painel.emblema.position + Vector2(10.0, 10.0)
	painel.inicial.size = Vector2.ONE * (TAMANHO_DO_EMBLEMA - 20.0)
	painel.inicial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	painel.inicial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(painel.inicial)

	var texto_x := x + TAMANHO_DO_EMBLEMA + 18.0 if not direita else x
	var largura_do_texto := LARGURA_DO_PAINEL - TAMANHO_DO_EMBLEMA - 18.0
	painel.nome = _rotulo_do_painel(66, Estilo.TEXTO, true, Vector2(texto_x, 150.0), largura_do_texto, 80.0, alinhamento)
	painel.nome.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	painel.nome.clip_text = true
	painel.nome_x = texto_x
	painel.estilo = _rotulo_do_painel(23, Estilo.TEXTO_SUAVE, false, Vector2(texto_x, 224.0), largura_do_texto, 30.0, alinhamento)

	# Sublinhado na cor do time com três riscos no fim.
	painel.sublinhado = Estilo.painel(Color.WHITE)
	painel.sublinhado.position = Vector2(x, 270.0)
	painel.sublinhado.size = Vector2(LARGURA_DO_PAINEL - 70.0, 4.0)
	if direita:
		painel.sublinhado.position.x = x + 70.0
	add_child(painel.sublinhado)
	for k in 3:
		var risco := Estilo.painel(Color.WHITE, Estilo.INCLINACAO * 3.0)
		risco.size = Vector2(12.0, 12.0)
		risco.position = Vector2(x + LARGURA_DO_PAINEL - 58.0 + k * 20.0 if not direita else x + k * 20.0, 266.0)
		risco.self_modulate = Color(1.0, 1.0, 1.0, 0.85)
		add_child(risco)

	# Caixa escura dos atributos: ícone, nome, 5 pedaços e o número.
	var caixa := Estilo.painel(Color(0.04, 0.05, 0.07, 0.62), Estilo.INCLINACAO * 0.6)
	caixa.position = Vector2(x - 6.0, TOPO_DOS_ATRIBUTOS - 8.0)
	caixa.size = Vector2(LARGURA_DO_PAINEL + 12.0, ATRIBUTOS.size() * ALTURA_DA_LINHA + 12.0)
	add_child(caixa)
	var largura_do_bloco := 36.0 + 140.0 + MAXIMO_DO_ATRIBUTO * 46.0 + 12.0 + 44.0
	var bloco_x := x + LARGURA_DO_PAINEL - largura_do_bloco - 6.0 if direita else x + 10.0
	for a in ATRIBUTOS.size():
		var y := TOPO_DOS_ATRIBUTOS + a * ALTURA_DA_LINHA
		var icone := _icone(ATRIBUTOS[a][2], 26.0, Color.WHITE)
		icone.position = Vector2(bloco_x, y + 4.0)
		add_child(icone)
		painel.icones.append(icone)

		var nome_do_atributo := Estilo.rotulo(ATRIBUTOS[a][1], 22, Estilo.TEXTO, true)
		nome_do_atributo.position = Vector2(bloco_x + 36.0, y)
		add_child(nome_do_atributo)

		var pedacos: Array = []
		for s in MAXIMO_DO_ATRIBUTO:
			var pedaco := Estilo.painel(Color.WHITE, Estilo.INCLINACAO)
			pedaco.position = Vector2(bloco_x + 176.0 + s * 46.0, y + 9.0)
			pedaco.size = Vector2(38.0, 16.0)
			add_child(pedaco)
			pedacos.append(pedaco)
		painel.segmentos.append(pedacos)

		var valor := Estilo.rotulo("", 22, Estilo.TEXTO, true)
		valor.position = Vector2(bloco_x + 176.0 + MAXIMO_DO_ATRIBUTO * 46.0 + 10.0, y)
		add_child(valor)
		painel.valores.append(valor)

	var abaixo := TOPO_DOS_ATRIBUTOS + ATRIBUTOS.size() * ALTURA_DA_LINHA + 8.0
	painel.jogada = _rotulo_do_painel(20, Estilo.TEXTO_SUAVE, false, Vector2(x, abaixo), LARGURA_DO_PAINEL, 28.0, alinhamento)
	var dica := _rotulo_do_painel(15, Estilo.TEXTO_APAGADO, false, Vector2(x, abaixo + 28.0), LARGURA_DO_PAINEL, 40.0, alinhamento)
	dica.text = DICA_DO_COMPUTADOR if jogador == 1 and Configuracao.contra_computador else DICAS[jogador]
	return painel


func _rotulo_do_painel(tamanho: int, cor: Color, titulo: bool, posicao: Vector2,
		largura: float, altura: float, alinhamento: HorizontalAlignment) -> Label:
	var novo := Estilo.rotulo("", tamanho, cor, titulo)
	novo.position = posicao
	novo.size = Vector2(largura, altura)
	novo.horizontal_alignment = alinhamento
	add_child(novo)
	return novo


func _criar_vs() -> void:
	_raio = Control.new()
	_raio.position = CENTRO_DO_VS - Vector2(200.0, 220.0)
	_raio.size = Vector2(400.0, 440.0)
	_raio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raio.draw.connect(_desenhar_raio)
	add_child(_raio)

	_vs = Estilo.rotulo("VS", 150, Estilo.TEXTO, true)
	_vs.position = CENTRO_DO_VS - Vector2(150.0, 92.0)
	_vs.size = Vector2(300.0, 184.0)
	_vs.pivot_offset = _vs.size / 2.0
	_vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_vs.add_theme_color_override("font_outline_color", Color("#14161C"))
	_vs.add_theme_constant_override("outline_size", 16)
	_vs.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.5))
	_vs.add_theme_constant_override("shadow_offset_x", 6)
	_vs.add_theme_constant_override("shadow_offset_y", 8)
	add_child(_vs)
	# O "VS" pulsa de leve, o tempo todo.
	var pulso := create_tween().set_loops()
	pulso.tween_property(_vs, "scale", Vector2.ONE * 1.05, 0.7).set_trans(Tween.TRANS_SINE)
	pulso.tween_property(_vs, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)


func _criar_cartoes() -> void:
	# Faixa escura atrás dos cartões.
	var faixa := Estilo.painel(Color(0.04, 0.05, 0.07, 0.82))
	faixa.position = Vector2(0.0, ALTURA_DOS_CARTOES - 26.0)
	faixa.size = Vector2(LARGURA, TAMANHO_DO_CARTAO.y + 48.0)
	add_child(faixa)
	var filete := Estilo.painel(Color(1.0, 1.0, 1.0, 0.08))
	filete.position = faixa.position
	filete.size = Vector2(LARGURA, 2.0)
	add_child(filete)

	var quantidade := times.size()
	var largura_total := quantidade * TAMANHO_DO_CARTAO.x + (quantidade - 1) * ESPACO_ENTRE_CARTOES
	var inicio := (LARGURA - largura_total) / 2.0
	for seta in [["<", inicio - 52.0], [">", inicio + largura_total + 22.0]]:
		var rotulo := Estilo.rotulo(seta[0], 48, Estilo.TEXTO_SUAVE, true)
		rotulo.position = Vector2(seta[1], ALTURA_DOS_CARTOES + 30.0)
		add_child(rotulo)

	for i in quantidade:
		var time: Dictionary = times[i]
		var cartao := Panel.new()
		cartao.position = Vector2(inicio + i * (TAMANHO_DO_CARTAO.x + ESPACO_ENTRE_CARTOES), ALTURA_DOS_CARTOES)
		cartao.size = TAMANHO_DO_CARTAO
		cartao.pivot_offset = TAMANHO_DO_CARTAO / 2.0
		cartao.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cartao)
		_cartoes.append(cartao)

		var emblema := TextureRect.new()
		emblema.texture = _emblema(time)
		emblema.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		emblema.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		emblema.position = Vector2(TAMANHO_DO_CARTAO.x / 2.0 - 34.0, 8.0)
		emblema.size = Vector2(68.0, 68.0)
		emblema.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cartao.add_child(emblema)

		var nome := Estilo.rotulo(str(time.get("nome", "?")).to_upper(), 25, Estilo.TEXTO, true)
		nome.position = Vector2(4.0, 80.0)
		nome.size = Vector2(TAMANHO_DO_CARTAO.x - 8.0, 36.0)
		nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nome.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.6))
		nome.add_theme_constant_override("outline_size", 4)
		cartao.add_child(nome)

		for jogador in 2:
			var texto_da_ficha := "CPU" if jogador == 1 and Configuracao.contra_computador else "J%d" % (jogador + 1)
			var ficha := Estilo.etiqueta(texto_da_ficha, Estilo.COR_DO_JOGADOR[jogador], 18)
			var deslocamento := 6.0 if jogador == 0 else TAMANHO_DO_CARTAO.x - 6.0 - 48.0
			ficha.position = cartao.position + Vector2(deslocamento, -30.0)
			ficha.size = Vector2(48.0, 26.0)
			ficha.visible = false
			add_child(ficha)
			_fichas[jogador].append(ficha)


func _criar_faixa_do_estadio() -> void:
	_faixa_do_estadio = Panel.new()
	_faixa_do_estadio.position = Vector2(230.0, 770.0)
	_faixa_do_estadio.size = Vector2(1140.0, 84.0)
	_faixa_do_estadio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_faixa_do_estadio)

	var icone := _icone("estadio", 34.0, Estilo.TEXTO)
	icone.position = Vector2(34.0, 25.0)
	_faixa_do_estadio.add_child(icone)
	var rotulo := Estilo.rotulo("ESTÁDIO", 28, Estilo.TEXTO, true)
	rotulo.position = Vector2(80.0, 22.0)
	_faixa_do_estadio.add_child(rotulo)

	var seta_esquerda := Estilo.rotulo("<", 44, Estilo.TEXTO_SUAVE, true)
	seta_esquerda.position = Vector2(222.0, 12.0)
	_faixa_do_estadio.add_child(seta_esquerda)

	# A prévia fica num recorte, pra deslizar sem vazar pros lados.
	var recorte := Control.new()
	recorte.position = Vector2(256.0, 6.0)
	recorte.size = Vector2(190.0, 72.0)
	recorte.clip_contents = true
	recorte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_faixa_do_estadio.add_child(recorte)

	_previa_do_estadio = Control.new()
	_previa_do_estadio.size = recorte.size
	_previa_do_estadio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_previa_do_estadio.draw.connect(_desenhar_previa)
	recorte.add_child(_previa_do_estadio)

	_imagem_do_estadio = TextureRect.new()
	_imagem_do_estadio.size = recorte.size
	_imagem_do_estadio.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_imagem_do_estadio.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_imagem_do_estadio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_imagem_do_estadio.visible = false
	recorte.add_child(_imagem_do_estadio)

	var seta_direita := Estilo.rotulo(">", 44, Estilo.TEXTO_SUAVE, true)
	seta_direita.position = Vector2(458.0, 12.0)
	_faixa_do_estadio.add_child(seta_direita)

	_nome_do_estadio = Estilo.rotulo("", 34, Estilo.TEXTO, true)
	_nome_do_estadio.position = Vector2(510.0, 4.0)
	_faixa_do_estadio.add_child(_nome_do_estadio)
	_descricao_do_estadio = Estilo.rotulo("", 20, Estilo.TEXTO_SUAVE)
	_descricao_do_estadio.position = Vector2(512.0, 44.0)
	_faixa_do_estadio.add_child(_descricao_do_estadio)
	var sublinhado := Estilo.painel(Estilo.DESTAQUE)
	sublinhado.position = Vector2(512.0, 72.0)
	sublinhado.size = Vector2(230.0, 3.0)
	_faixa_do_estadio.add_child(sublinhado)

	_dica_do_estadio = Estilo.rotulo("", 20, Estilo.TEXTO_APAGADO, true)
	_dica_do_estadio.position = Vector2(760.0, 28.0)
	_dica_do_estadio.size = Vector2(350.0, 30.0)
	_dica_do_estadio.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_faixa_do_estadio.add_child(_dica_do_estadio)


func _criar_rodape() -> void:
	_botao_do_rodape("B", Color("#E5484D"), "VOLTAR", "Esc", Vector2(MARGEM, 862.0), false)
	_botao_do_rodape("A", Color("#3FB950"), "CONFIRMAR", "J / 1", Vector2(LARGURA - MARGEM, 862.0), true)

	_instrucao = Estilo.rotulo("", 24, Estilo.TEXTO, true)
	_instrucao.position = Vector2(400.0, 862.0)
	_instrucao.size = Vector2(800.0, 34.0)
	_instrucao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_instrucao)


## Botão do rodapé: bolinha com a letra do controle, a ação e as teclas, numa linha.
## "pela_direita" = "posicao" é o canto direito.
func _botao_do_rodape(letra: String, cor: Color, acao: String, teclas: String, posicao: Vector2, pela_direita: bool) -> void:
	var largura := 230.0
	var caixa := Control.new()
	caixa.position = posicao - Vector2(largura if pela_direita else 0.0, 0.0)
	caixa.size = Vector2(largura, 34.0)
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caixa)

	var bolinha := Estilo.rotulo(letra, 20, Color.WHITE, true)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.set_corner_radius_all(15)
	bolinha.add_theme_stylebox_override("normal", estilo)
	bolinha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bolinha.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bolinha.size = Vector2(30.0, 30.0)
	bolinha.position = Vector2(largura - 30.0 - 190.0 if pela_direita else 0.0, 2.0)
	caixa.add_child(bolinha)

	var texto := Estilo.rotulo(acao, 24, Estilo.TEXTO, true)
	texto.position = Vector2(bolinha.position.x + 40.0, 0.0)
	caixa.add_child(texto)
	var dica := Estilo.rotulo(teclas, 18, Estilo.TEXTO_APAGADO)
	dica.position = Vector2(texto.position.x + texto.get_minimum_size().x + 10.0, 6.0)
	caixa.add_child(dica)


# --- Ajudantes ---

func _cor_do_menu(time: Dictionary) -> Color:
	return Dados.cor(time, "cor_do_menu", Estilo.DESTAQUE)


func _emblema(time: Dictionary) -> Texture2D:
	return _imagem_opcional(PASTA_EMBLEMAS % time.get("id", ""))


## Ícone branco de arte/icones/, pintado com "cor".
func _icone(nome: String, tamanho: float, cor: Color) -> TextureRect:
	var icone := TextureRect.new()
	icone.texture = _imagem_opcional(PASTA_ICONES % nome)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.size = Vector2.ONE * tamanho
	icone.self_modulate = cor
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icone


## Quando o jogador confirma, a metade dele pisca, o "PRONTO!" salta e o atleta comemora.
func _piscar(jogador: int) -> void:
	var painel: PainelDoJogador = _paineis[jogador]
	var cor := _cor_do_menu(times[selecao.cursor[jogador]])
	_parar_animacao("tinta%d" % jogador)
	var tween := create_tween()
	tween.tween_property(painel.tinta, "self_modulate", Color.WHITE, 0.06)
	tween.tween_property(painel.tinta, "self_modulate", cor, 0.3)
	_animacoes["tinta%d" % jogador] = tween
	painel.status.scale = Vector2.ONE * 1.5
	_animar("status%d" % jogador, painel.status, "scale", Vector2.ONE, 0.3, Tween.TRANS_BACK)


## A prévia do estádio entra deslizando do lado pra onde o jogador apertou.
func _deslizar(no: Control, passo: int) -> void:
	no.position.x = 60.0 * signf(passo)
	no.modulate.a = 0.0
	_animar("deslizar_%s" % no.get_instance_id(), no, "position:x", 0.0, 0.16)
	_animar("deslizar_alfa_%s" % no.get_instance_id(), no, "modulate:a", 1.0, 0.16)


## Anima uma propriedade, cancelando a animação anterior com a mesma chave.
func _animar(chave: String, alvo: Object, propriedade: String, valor: Variant, duracao: float,
		transicao := Tween.TRANS_QUAD) -> void:
	_parar_animacao(chave)
	var tween := create_tween()
	tween.tween_property(alvo, propriedade, valor, duracao).set_trans(transicao).set_ease(Tween.EASE_OUT)
	_animacoes[chave] = tween


## Igual a _animar, mas chamando uma função com o valor de "de" até "ate".
func _animar_metodo(chave: String, metodo: Callable, de: float, ate: float, duracao: float) -> void:
	_parar_animacao(chave)
	var tween := create_tween()
	tween.tween_method(metodo, de, ate, duracao)
	_animacoes[chave] = tween


func _parar_animacao(chave: String) -> void:
	var anterior = _animacoes.get(chave)
	if anterior is Tween and anterior.is_valid():
		anterior.kill()


## A foto do estádio bem pequena e esticada na tela inteira fica desfocada
## (guarda pra não refazer).
func _desfocada(id: String, imagem: Texture2D) -> Texture2D:
	if imagem == null:
		return null
	if not _fotos_desfocadas.has(id):
		var pequena := imagem.get_image()
		if pequena == null or pequena.is_empty():
			return imagem
		pequena = pequena.duplicate()
		if pequena.is_compressed():
			pequena.decompress()
		pequena.resize(96, 54, Image.INTERPOLATE_BILINEAR)
		pequena.resize(384, 216, Image.INTERPOLATE_BILINEAR)
		_fotos_desfocadas[id] = ImageTexture.create_from_image(pequena)
	return _fotos_desfocadas[id]


## Carrega uma imagem só se o arquivo existir (guarda pra não carregar de novo).
func _imagem_opcional(caminho: String) -> Texture2D:
	if not _imagens.has(caminho):
		var imagem: Texture2D = null
		if ResourceLoader.exists(caminho):
			imagem = load(caminho) as Texture2D
		_imagens[caminho] = imagem
	return _imagens[caminho]
