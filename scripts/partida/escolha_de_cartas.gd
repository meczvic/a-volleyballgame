extends CanvasLayer
## Tela do Modo Caos: cada jogador escolhe uma carta, na metade dele.
##
## Esquerda/direita move o cursor, Passe (ou Ataque) confirma. Quando os dois
## confirmam, ou o tempo acaba (aí a carta é sorteada), o sinal "terminou"
## avisa a partida com o id da carta de cada jogador.
##
## Não usa a pausa do jogo: a partida só ignora os botões enquanto esta tela
## existe. Se alguém pausar de verdade, a contagem para junto.
##
## Bloqueio troca as 3 cartas oferecidas por outras 3 (botão TROCAR, o "Reroll"
## da referência), enquanto o jogador ainda tiver trocas na partida.
##
## Visual (referência "Escolha Sua Carta de Vôlei"): cronômetro em cima, título,
## a etiqueta de cada jogador com o emblema do time, as 3 cartas dele
## (carta_visual.gd desenha cada uma, com a raridade e o atleta do time na
## jogada) e o botão TROCAR. A carta do cursor sobe; a confirmada ganha o selo
## ESCOLHIDA e as outras apagam.

## [id da carta do Jogador 1, id da carta do Jogador 2].
signal terminou(escolhas: Array)

const Estilo := preload("res://scripts/menus/estilo.gd")
const CartaVisual := preload("res://scripts/partida/carta_visual.gd")

const LARGURA_DA_CARTA := 236.0
const ESPACO := 18.0
const METADE := 800.0
const MARGEM := 28.0
const TOPO_DAS_CARTAS := 290.0
const LARGURA_DO_BOTAO := 300.0
## A carta do cursor sobe e cresce um pouco.
const SUBIDA := 14.0
const CRESCIMENTO := 1.04
## Botões apertados nos primeiros instantes (do ponto) não contam.
const ATRASO_DAS_TECLAS := 0.5
## Depois que os dois confirmam, espera um pouco pra ver a escolha.
const PAUSA_DO_FIM := 0.5
## Abaixo disso o cronômetro fica vermelho e pulsa (s).
const POUCO_TEMPO := 10.0
const PASTA_EMBLEMAS := "res://arte/emblemas/%s.svg"

var _opcoes: Array = []
var _indice := [0, 0]
var _pronto := [false, false]
var _quadros: Array = [[], []]
var _avisos: Array = [null, null]
var _cores: Array = []
var _relogio: Label
var _caixa_do_relogio: Control
var _tempo := 60.0
var _segundo_mostrado := -1
var _atraso := ATRASO_DAS_TECLAS
var _fechando := -1.0
var _terminada := false
var _tweens := {}
var _raiz: Control
var _times: Array = []
## Trocas que cada jogador ainda tem, e quem sorteia as cartas novas.
var _trocas: Array = [0, 0]
var _sortear_troca: Callable
var _botoes: Array = [null, null]
var _textos_dos_botoes: Array = [null, null]
## Sorteio da partida (com a semente dela), pra carta de quem não escolheu a
## tempo. Sem ele, usa um sorteio próprio.
var sorteio: RandomNumberGenerator = null


## "opcoes": para cada jogador, a lista de cartas (dicionários de dados/cartas.json).
## "maos": ids que cada time já tem (só pra mostrar). "cores": cor de cada time.
## "ids": id de cada time (pro emblema). "times": dados de cada time como estão
## em quadra (pro atleta nas cartas). "trocas": quantas trocas cada um tem.
## "sortear_troca": func(jogador, ids_atuais) -> novas cartas ([] = não deu).
## Os quatro últimos são opcionais.
func configurar(opcoes: Array, nomes: Array, cores: Array, maos: Array, nomes_das_maos: Array,
		tempo_limite: float, ids: Array = [], times: Array = [], trocas: Array = [0, 0],
		sortear_troca: Callable = Callable()) -> void:
	layer = 9
	_opcoes = opcoes
	_cores = cores
	_tempo = tempo_limite
	_times = times
	_trocas = trocas.duplicate()
	_sortear_troca = sortear_troca

	var raiz := Control.new()
	_raiz = raiz
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.theme = Estilo.tema()
	add_child(raiz)

	var escurecer := ColorRect.new()
	escurecer.color = Color(0.02, 0.02, 0.04, 0.74)
	escurecer.set_anchors_preset(Control.PRESET_FULL_RECT)
	escurecer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(escurecer)

	_criar_relogio(raiz)
	_criar_titulo(raiz)

	for jogador in 2:
		var x0 := METADE * jogador + MARGEM
		var largura := LARGURA_DA_CARTA * 3.0 + ESPACO * 2.0
		_criar_etiqueta_do_jogador(raiz, jogador, str(nomes[jogador]), ids[jogador] if jogador < ids.size() else "", Vector2(x0, 226.0), largura)

		_criar_cartas(jogador, 0.06 * jogador * 3)
		_criar_botao_de_troca(raiz, jogador, Vector2(x0 + (largura - LARGURA_DO_BOTAO) / 2.0, 668.0))

		var aviso := Estilo.rotulo("", 34, Estilo.PRONTO, true)
		aviso.position = Vector2(x0, 664.0)
		aviso.size = Vector2(largura, 44.0)
		aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		aviso.pivot_offset = aviso.size / 2.0
		raiz.add_child(aviso)
		_avisos[jogador] = aviso

		var dica := Estilo.rotulo("Esquerda/direita escolhe  ·  Passe confirma  ·  Bloqueio troca", 20, Estilo.TEXTO_SUAVE)
		dica.position = Vector2(x0, 716.0)
		dica.size = Vector2(largura, 30.0)
		dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		raiz.add_child(dica)

		var nomes_da_mao := PackedStringArray(nomes_das_maos[jogador])
		var mao := Estilo.rotulo("Suas cartas: %s" % (
			", ".join(nomes_da_mao) if not nomes_da_mao.is_empty() else "nenhuma"
		), 20, Estilo.TEXTO_APAGADO)
		mao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mao.position = Vector2(x0, 746.0)
		mao.size = Vector2(largura, 80.0)
		mao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		raiz.add_child(mao)

	_atualizar_quadros()
	_atualizar_relogio()


func _process(delta: float) -> void:
	if _terminada:
		return
	if _fechando >= 0.0:
		_fechando -= delta
		if _fechando < 0.0:
			_terminar()
		return
	_tempo -= delta
	_atraso = maxf(_atraso - delta, 0.0)
	_atualizar_relogio()

	if _atraso <= 0.0:
		for jogador in 2:
			if _pronto[jogador]:
				continue
			var prefixo := "p%d_" % (jogador + 1)
			if Input.is_action_just_pressed(prefixo + "esquerda"):
				_mover(jogador, -1)
			elif Input.is_action_just_pressed(prefixo + "direita"):
				_mover(jogador, 1)
			elif Input.is_action_just_pressed(prefixo + "passe") \
					or Input.is_action_just_pressed(prefixo + "ataque"):
				_confirmar(jogador)
			elif Input.is_action_just_pressed(prefixo + "bloqueio"):
				_trocar(jogador)

	if _tempo <= 0.0:
		# Acabou o tempo: quem não escolheu ganha uma carta sorteada.
		for jogador in 2:
			if not _pronto[jogador]:
				if sorteio == null:
					sorteio = RandomNumberGenerator.new()
				_indice[jogador] = sorteio.randi_range(0, (_opcoes[jogador] as Array).size() - 1)
				_confirmar(jogador)
	if _pronto[0] and _pronto[1] and _fechando < 0.0:
		_fechando = PAUSA_DO_FIM


func _mover(jogador: int, passo: int) -> void:
	var total: int = (_opcoes[jogador] as Array).size()
	_indice[jogador] = (int(_indice[jogador]) + passo + total) % total
	_atualizar_quadros()


func _confirmar(jogador: int) -> void:
	_pronto[jogador] = true
	_atualizar_quadros()
	_atualizar_botao(jogador)
	# A carta escolhida dá um pulo e o PRONTO! salta.
	var carta: Control = _quadros[jogador][_indice[jogador]]
	carta.scale = Vector2.ONE * 1.14
	_animar("pulo%d" % jogador, carta, "scale", Vector2.ONE * CRESCIMENTO, 0.3, Tween.TRANS_BACK)
	var aviso: Label = _avisos[jogador]
	aviso.scale = Vector2.ONE * 1.5
	_animar("aviso%d" % jogador, aviso, "scale", Vector2.ONE, 0.3, Tween.TRANS_BACK)


## TROCAR: as cartas da tela saem e entram 3 novas (se ainda tiver troca).
func _trocar(jogador: int) -> void:
	if _pronto[jogador] or int(_trocas[jogador]) <= 0 or not _sortear_troca.is_valid():
		_balancar_botao(jogador)
		return
	var atuais: Array = []
	for carta in _opcoes[jogador]:
		atuais.append(str(carta.get("id", "")))
	var novas: Array = _sortear_troca.call(jogador, atuais)
	if novas.is_empty():
		_balancar_botao(jogador)
		return
	_trocas[jogador] = int(_trocas[jogador]) - 1
	for carta in _quadros[jogador]:
		var saida := (carta as Control).create_tween().set_parallel()
		saida.tween_property(carta, "position:y", TOPO_DAS_CARTAS + 60.0, 0.18)
		saida.tween_property(carta, "modulate:a", 0.0, 0.18)
		saida.chain().tween_callback(carta.queue_free)
	_quadros[jogador] = []
	_opcoes[jogador] = novas
	_indice[jogador] = 0
	_criar_cartas(jogador, 0.12)
	_atualizar_quadros()
	_atualizar_botao(jogador)


func trocas_restantes(jogador: int) -> int:
	return int(_trocas[jogador])


func _terminar() -> void:
	_terminada = true
	var escolhas: Array = []
	for jogador in 2:
		escolhas.append(str(_opcoes[jogador][_indice[jogador]].get("id", "")))
	terminou.emit(escolhas)
	queue_free()


## Cronômetro "0:42"; nos últimos segundos fica vermelho e pulsa a cada segundo.
func _atualizar_relogio() -> void:
	var segundos := ceili(maxf(_tempo, 0.0))
	_relogio.text = "%d:%02d" % [floori(segundos / 60.0), segundos % 60]
	var acabando := _tempo <= POUCO_TEMPO
	_relogio.add_theme_color_override("font_color", Color("#FF5A4E") if acabando else Estilo.TEXTO)
	if acabando and segundos != _segundo_mostrado and _segundo_mostrado >= 0:
		_caixa_do_relogio.scale = Vector2.ONE * 1.12
		_animar("relogio", _caixa_do_relogio, "scale", Vector2.ONE, 0.3)
	_segundo_mostrado = segundos


func _atualizar_quadros() -> void:
	for jogador in 2:
		for i in (_quadros[jogador] as Array).size():
			var escolhida: bool = i == int(_indice[jogador])
			var carta = _quadros[jogador][i]
			var pronto: bool = _pronto[jogador]
			carta.definir_estado(escolhida, escolhida and pronto, pronto and not escolhida)
			var alvo_y := TOPO_DAS_CARTAS - (SUBIDA if escolhida else 0.0)
			_animar("sobe%d_%d" % [jogador, i], carta, "position:y", alvo_y, 0.14)
			if not (escolhida and pronto):
				_animar("pulo%d_%d" % [jogador, i], carta, "scale", Vector2.ONE * (CRESCIMENTO if escolhida else 1.0), 0.14)
		(_avisos[jogador] as Label).text = "PRONTO!" if _pronto[jogador] else ""


# --- Construção ---

## As cartas de "jogador", entrando uma depois da outra a partir de "atraso" (s).
func _criar_cartas(jogador: int, atraso: float) -> void:
	var x0 := METADE * jogador + MARGEM
	var time: Dictionary = _times[jogador] if jogador < _times.size() else {}
	for i in (_opcoes[jogador] as Array).size():
		var carta := CartaVisual.new()
		carta.configurar(_opcoes[jogador][i], _cores[jogador], time)
		carta.position = Vector2(x0 + i * (LARGURA_DA_CARTA + ESPACO), TOPO_DAS_CARTAS)
		_raiz.add_child(carta)
		_quadros[jogador].append(carta)
		# Entrada: cada carta sobe e aparece, uma depois da outra.
		carta.modulate.a = 0.0
		carta.position.y += 40.0
		var entrada := carta.create_tween().set_parallel()
		var y_final := TOPO_DAS_CARTAS - (SUBIDA if i == int(_indice[jogador]) else 0.0)
		entrada.tween_property(carta, "position:y", y_final, 0.25).set_delay(atraso + 0.06 * i) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		entrada.tween_property(carta, "modulate:a", 1.0, 0.2).set_delay(atraso + 0.06 * i)


## Botão TROCAR (o "Reroll" da referência) embaixo das cartas do jogador.
func _criar_botao_de_troca(raiz: Control, jogador: int, posicao: Vector2) -> void:
	var botao := Estilo.painel(Color(0.08, 0.09, 0.12, 0.95), Estilo.INCLINACAO, 2, Color(1, 1, 1, 0.7))
	botao.position = posicao
	botao.size = Vector2(LARGURA_DO_BOTAO, 42.0)
	botao.pivot_offset = botao.size / 2.0
	raiz.add_child(botao)
	var icone := TextureRect.new()
	icone.texture = load("res://arte/icones/coringa.svg")
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.size = Vector2(28.0, 28.0)
	icone.position = Vector2(26.0, 7.0)
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	botao.add_child(icone)
	var texto := Estilo.rotulo("", 26, Estilo.TEXTO, true)
	texto.position = Vector2(62.0, 0.0)
	texto.size = Vector2(LARGURA_DO_BOTAO - 74.0, 42.0)
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	botao.add_child(texto)
	_botoes[jogador] = botao
	_textos_dos_botoes[jogador] = texto
	_atualizar_botao(jogador)


func _atualizar_botao(jogador: int) -> void:
	var botao: Control = _botoes[jogador]
	if botao == null:
		return
	var restantes := int(_trocas[jogador])
	(_textos_dos_botoes[jogador] as Label).text = "TROCAR (%d)   Bloqueio" % restantes
	botao.visible = not _pronto[jogador]
	botao.modulate = Color.WHITE if restantes > 0 and _sortear_troca.is_valid() else Color(1, 1, 1, 0.4)


## Sem troca: o botão balança pra avisar.
func _balancar_botao(jogador: int) -> void:
	var botao: Control = _botoes[jogador]
	if botao == null or not botao.visible:
		return
	var x := botao.position.x
	var tween := create_tween()
	for passo in [8.0, -7.0, 5.0, -3.0, 0.0]:
		tween.tween_property(botao, "position:x", x + passo, 0.04)

func _criar_relogio(raiz: Control) -> void:
	_caixa_do_relogio = Control.new()
	_caixa_do_relogio.position = Vector2(METADE - 110.0, 100.0)
	_caixa_do_relogio.size = Vector2(220.0, 58.0)
	_caixa_do_relogio.pivot_offset = _caixa_do_relogio.size / 2.0
	_caixa_do_relogio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(_caixa_do_relogio)
	var fundo := Estilo.painel(Color(0.06, 0.07, 0.09, 0.96), Estilo.INCLINACAO, 3, Estilo.DESTAQUE)
	fundo.size = _caixa_do_relogio.size
	_caixa_do_relogio.add_child(fundo)
	var icone := TextureRect.new()
	icone.texture = load("res://arte/icones/relogio.svg")
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.size = Vector2(34.0, 34.0)
	icone.position = Vector2(30.0, 11.0)
	icone.self_modulate = Estilo.DESTAQUE
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caixa_do_relogio.add_child(icone)
	_relogio = Estilo.rotulo("", 46, Estilo.TEXTO, true)
	_relogio.position = Vector2(72.0, 0.0)
	_relogio.size = Vector2(130.0, 58.0)
	_relogio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_relogio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caixa_do_relogio.add_child(_relogio)


func _criar_titulo(raiz: Control) -> void:
	var titulo := Estilo.rotulo("ESCOLHA SUA CARTA", 56, Estilo.TEXTO, true)
	titulo.position = Vector2(0.0, 156.0)
	titulo.size = Vector2(METADE * 2.0, 64.0)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.06))
	titulo.add_theme_constant_override("outline_size", 10)
	raiz.add_child(titulo)
	# Traço e riscos laranja dos dois lados do título, como na referência.
	var meia_largura := Estilo.FONTE_TITULO.get_string_size(titulo.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 56).x / 2.0
	for lado in [-1.0, 1.0]:
		var perto: float = METADE + lado * (meia_largura + 24.0)
		var traco := Estilo.painel(Estilo.DESTAQUE)
		traco.size = Vector2(150.0, 4.0)
		traco.position = Vector2(perto if lado > 0.0 else perto - 150.0, 190.0)
		raiz.add_child(traco)
		for k in 3:
			var risco := Estilo.painel(Estilo.DESTAQUE, Estilo.INCLINACAO * 3.0)
			risco.size = Vector2(9.0, 14.0)
			var x: float = perto + lado * (6.0 + k * 14.0) - (9.0 if lado < 0.0 else 0.0)
			risco.position = Vector2(x, 185.0)
			raiz.add_child(risco)


func _criar_etiqueta_do_jogador(raiz: Control, jogador: int, nome_do_time: String, id: String, posicao: Vector2, largura: float) -> void:
	var cor: Color = _cores[jogador]
	var faixa := Estilo.painel(Color(cor, 0.92), Estilo.INCLINACAO)
	faixa.position = posicao
	faixa.size = Vector2(largura, 46.0)
	raiz.add_child(faixa)
	var caminho := PASTA_EMBLEMAS % id
	if id != "" and ResourceLoader.exists(caminho):
		var emblema := TextureRect.new()
		emblema.texture = load(caminho)
		emblema.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		emblema.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		emblema.size = Vector2(56.0, 56.0)
		emblema.position = Vector2(posicao.x + 18.0, posicao.y - 6.0)
		emblema.mouse_filter = Control.MOUSE_FILTER_IGNORE
		raiz.add_child(emblema)
	var cor_do_texto := Estilo.FUNDO if cor.get_luminance() > 0.45 else Estilo.TEXTO
	var texto := Estilo.rotulo("JOGADOR %d  ·  %s" % [jogador + 1, nome_do_time.to_upper()], 30, cor_do_texto, true)
	texto.position = posicao
	texto.size = Vector2(largura, 46.0)
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	raiz.add_child(texto)


## Anima uma propriedade, cancelando a animação anterior com a mesma chave.
func _animar(chave: String, alvo: Object, propriedade: String, valor: Variant, duracao: float,
		transicao := Tween.TRANS_QUAD) -> void:
	var anterior = _tweens.get(chave)
	if anterior is Tween and anterior.is_valid():
		anterior.kill()
	var tween := create_tween()
	tween.tween_property(alvo, propriedade, valor, duracao).set_trans(transicao).set_ease(Tween.EASE_OUT)
	_tweens[chave] = tween
