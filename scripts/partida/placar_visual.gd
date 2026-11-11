extends PanelContainer
## Placar da partida, no estilo de transmissão (referência: "Placar Anime
## Karasuno vs Nekoma"): dois blocos inclinados com emblema e nome, a caixa de
## pontos de cada time com a borda na cor dele, e no meio o set atual com uma
## bolinha por set (pintada na cor de quem ganhou). A bola pequena mostra quem
## saca. Embaixo aparece SET POINT / MATCH POINT / PONTO DECISIVO.
##
## No ponto (como na referência): um corte de luz dourado atravessa a caixa de
## quem pontuou, saem faíscas, um brilho dourado se abre em volta, o número
## salta e fica amarelo um instante, e o placar treme de leve.
##
## Só desenha: a conta dos pontos é de scripts/regras/placar.gd.
## Uso: configurar(nomes, cores, ids) uma vez; atualizar(...) a cada mudança;
## comemorar(time) no ponto.

const Estilo := preload("res://scripts/menus/estilo.gd")

const SETS_PARA_VENCER := 2
const TOTAL_DE_SETS := SETS_PARA_VENCER * 2 - 1
const PASTA_EMBLEMAS := "res://arte/emblemas/%s.svg"
const ICONE_DO_SAQUE := "res://arte/icones/saque.svg"

## Medidas (px na tela de 1600 x 900).
const LARGURA_DO_BLOCO := 300.0
const LARGURA_DOS_PONTOS := 112.0
const LARGURA_DO_MEIO := 116.0
const ALTURA := 70.0
const LARGURA := LARGURA_DO_BLOCO * 2.0 + LARGURA_DOS_PONTOS * 2.0 + LARGURA_DO_MEIO
const TAMANHO_DO_EMBLEMA := 60.0

## Ponto: quanto o número cresce, quanto tempo leva pra voltar e quanto fica amarelo (s).
const PULO_DO_NUMERO := 1.6
const DURACAO_DO_PULO := 0.45
const TEMPO_AMARELO := 1.1
## Duração do corte de luz e das faíscas (s).
const DURACAO_DO_EFEITO := 0.65
const DOURADO := Color("#FFB23A")
const QUANTAS_FAISCAS := 12
const AMARELO := Color("#FFD84A")
const FUNDO_DO_BLOCO := Color(0.07, 0.08, 0.1, 0.94)
const FUNDO_DOS_PONTOS := Color(0.04, 0.045, 0.06, 0.96)

var _conteudo: Control
var _nomes: Array[Label] = []
## Efeito do ponto, desenhado por cima de tudo: progresso de 0 a 1 por time
## (-1 = parado) e [ângulo, força] de cada faísca.
var _efeito: Control
var _progresso_do_efeito: Array[float] = [-1.0, -1.0]
var _faiscas: Array = [[], []]
var _pontos: Array[Label] = []
var _caixas: Array[Panel] = []
var _claroes: Array[ColorRect] = []
var _emblemas: Array[TextureRect] = []
var _riscos: Array = [[], []]
var _blocos: Array[Panel] = []
var _saque: Array[TextureRect] = []
## Uma bolinha por set da partida (no meio).
var _bolinhas: Array[Panel] = []
var _rotulo_do_set: Label
var _aviso: Label
var _cores: Array[Color] = [Color.WHITE, Color.WHITE]
var _tweens: Array = [null, null]
var _tremor: Tween
## Quem ganhou cada set já jogado, na ordem.
var _vencedores_dos_sets: Array[int] = []
var _ultimos_sets: Array[int] = [0, 0]
var _vencedor := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var base := Control.new()
	base.custom_minimum_size = Vector2(LARGURA, ALTURA + 34.0)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	_conteudo = Control.new()
	_conteudo.size = base.custom_minimum_size
	_conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(_conteudo)

	for time in 2:
		_criar_bloco(time)
		_criar_caixa_de_pontos(time)
	_criar_meio()

	_efeito = Control.new()
	_efeito.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_efeito.size = _conteudo.size
	_efeito.draw.connect(_desenhar_efeito)
	_conteudo.add_child(_efeito)


func configurar(nomes: Array, cores: Array, ids: Array = []) -> void:
	for time in 2:
		_cores[time] = cores[time]
		_nomes[time].text = str(nomes[time]).to_upper()
		var caminho := PASTA_EMBLEMAS % (ids[time] if time < ids.size() else "")
		_emblemas[time].texture = load(caminho) if ResourceLoader.exists(caminho) else null
		_saque[time].self_modulate = cores[time].lightened(0.35)
		for risco in _riscos[time]:
			(risco as Panel).self_modulate = cores[time]
		_pintar_caixa(time, false)
		var estilo := Estilo.caixa(FUNDO_DO_BLOCO, Estilo.INCLINACAO)
		estilo.border_width_bottom = 4
		estilo.border_color = cores[time]
		_blocos[time].add_theme_stylebox_override("panel", estilo)


## "aviso": { "texto", "quem" } (veja Placar.aviso()).
func atualizar(pontos: Array, sets: Array, set_atual: int, quem_saca: int, aviso: Dictionary) -> void:
	_lembrar_sets(sets)
	_vencedor = -1
	for time in 2:
		if int(sets[time]) >= SETS_PARA_VENCER:
			_vencedor = time
	for time in 2:
		_pontos[time].text = str(pontos[time])
		_saque[time].visible = time == quem_saca and _vencedor < 0
		_pintar_caixa(time, time == _vencedor)

	for i in TOTAL_DE_SETS:
		var bolinha := _bolinhas[i]
		if i < _vencedores_dos_sets.size():
			var dono := _vencedores_dos_sets[i]
			_pintar_bolinha(bolinha, _cores[dono], _cores[dono].lightened(0.4), 2)
			bolinha.set_meta("dono", dono)
		elif i == set_atual - 1 and _vencedor < 0:
			_pintar_bolinha(bolinha, Color(1, 1, 1, 0.15), Estilo.TEXTO, 2)
			bolinha.set_meta("dono", -1)
		else:
			_pintar_bolinha(bolinha, Color(0, 0, 0, 0), Estilo.TEXTO_APAGADO, 2)
			bolinha.set_meta("dono", -1)
	_rotulo_do_set.text = "FIM" if _vencedor >= 0 else "SET %d" % set_atual

	var texto: String = aviso.get("texto", "")
	_aviso.visible = texto != ""
	if texto != "":
		var quem: int = aviso.get("quem", -1)
		_aviso.text = texto
		var cor: Color = _cores[quem] if quem >= 0 else Estilo.DESTAQUE
		_aviso.add_theme_stylebox_override("normal", Estilo.caixa(cor, Estilo.INCLINACAO, 14.0, 1.0, 2, Color(1, 1, 1, 0.8)))
		_aviso.add_theme_color_override("font_color", Estilo.FUNDO if cor.get_luminance() > 0.45 else Estilo.TEXTO)


## Ponto de "time": a caixa pisca, o risco de luz passa, o número salta e fica
## amarelo um instante, e o placar treme de leve.
func comemorar(time: int) -> void:
	var numero := _pontos[time]
	numero.pivot_offset = numero.size / 2.0
	if _tweens[time]:
		_tweens[time].kill()
	numero.scale = Vector2.ONE * PULO_DO_NUMERO
	numero.add_theme_color_override("font_color", AMARELO)
	var faiscas: Array = []
	for i in QUANTAS_FAISCAS:
		faiscas.append([TAU * i / QUANTAS_FAISCAS + randf_range(-0.2, 0.2), randf_range(0.7, 1.3)])
	_faiscas[time] = faiscas
	var clarao := _claroes[time]
	clarao.color = Color(_cores[time].lightened(0.5), 0.75)

	var tween := create_tween().set_parallel()
	tween.tween_property(numero, "scale", Vector2.ONE, DURACAO_DO_PULO) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(clarao, "color:a", 0.0, 0.35)
	tween.tween_method(_mudar_efeito.bind(time), 0.0, 1.0, DURACAO_DO_EFEITO)
	tween.chain().tween_callback(_mudar_efeito.bind(-1.0, time))
	tween.tween_interval(TEMPO_AMARELO - DURACAO_DO_EFEITO)
	tween.chain().tween_callback(func() -> void: numero.remove_theme_color_override("font_color"))
	_tweens[time] = tween

	if _tremor:
		_tremor.kill()
	_conteudo.position = Vector2.ZERO
	_tremor = create_tween()
	for passo in [5.0, -4.0, 3.0, -2.0, 0.0]:
		_tremor.tween_property(_conteudo, "position:x", passo, 0.04)


## Pra testes e pro robô.
func texto_dos_pontos(time: int) -> String:
	return _pontos[time].text


func texto_do_aviso() -> String:
	return _aviso.text.strip_edges() if _aviso.visible else ""


## Quantos sets o time já ganhou (bolinhas pintadas com a cor dele).
func sets_acesos(time: int) -> int:
	var n := 0
	for bolinha in _bolinhas:
		if int(bolinha.get_meta("dono", -1)) == time:
			n += 1
	return n


func numero_pulando(time: int) -> bool:
	return _pontos[time].scale.x > 1.01


func efeito_ativo(time: int) -> bool:
	return _progresso_do_efeito[time] >= 0.0


func numero_amarelo(time: int) -> bool:
	return _pontos[time].has_theme_color_override("font_color")


func saque_visivel(time: int) -> bool:
	return _saque[time].visible


func texto_do_set() -> String:
	return _rotulo_do_set.text


# --- Construção ---

## Bloco do time: emblema na ponta de fora, nome, bola do saque e riscos na ponta de dentro.
func _criar_bloco(time: int) -> void:
	var direita := time == 1
	var x := 0.0 if not direita else LARGURA - LARGURA_DO_BLOCO
	var bloco := Panel.new()
	bloco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bloco.position = Vector2(x, 0.0)
	bloco.size = Vector2(LARGURA_DO_BLOCO, ALTURA)
	_conteudo.add_child(bloco)
	_blocos.append(bloco)

	var emblema := TextureRect.new()
	emblema.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblema.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblema.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emblema.flip_h = direita
	emblema.position = Vector2(x + (18.0 if not direita else LARGURA_DO_BLOCO - 18.0 - TAMANHO_DO_EMBLEMA), 5.0)
	emblema.size = Vector2.ONE * TAMANHO_DO_EMBLEMA
	_conteudo.add_child(emblema)
	_emblemas.append(emblema)

	var nome := _rotulo("", 32, true)
	nome.position = Vector2(x + (90.0 if not direita else 30.0), 0.0)
	nome.size = Vector2(LARGURA_DO_BLOCO - 120.0, ALTURA - 6.0)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if not direita else HORIZONTAL_ALIGNMENT_RIGHT
	nome.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nome.clip_text = true
	_conteudo.add_child(nome)
	_nomes.append(nome)

	# Bola pequena de quem saca, no canto de dentro, em cima.
	var saque := TextureRect.new()
	saque.texture = load(ICONE_DO_SAQUE) if ResourceLoader.exists(ICONE_DO_SAQUE) else null
	saque.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	saque.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	saque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	saque.position = Vector2(x + (LARGURA_DO_BLOCO - 34.0 if not direita else 12.0), 6.0)
	saque.size = Vector2(22.0, 22.0)
	_conteudo.add_child(saque)
	_saque.append(saque)

	# Três riscos inclinados na ponta de dentro, embaixo.
	for k in 3:
		var risco := Estilo.painel(Color.WHITE, Estilo.INCLINACAO * 3.0)
		risco.size = Vector2(9.0, 10.0)
		var inicio := x + (LARGURA_DO_BLOCO - 56.0 if not direita else 18.0)
		risco.position = Vector2(inicio + k * 14.0, ALTURA - 18.0)
		_conteudo.add_child(risco)
		_riscos[time].append(risco)


## Caixa do número de pontos, colada no bloco, do lado do meio.
func _criar_caixa_de_pontos(time: int) -> void:
	var x := LARGURA_DO_BLOCO if time == 0 else LARGURA - LARGURA_DO_BLOCO - LARGURA_DOS_PONTOS
	var caixa := Panel.new()
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.position = Vector2(x, -4.0)
	caixa.size = Vector2(LARGURA_DOS_PONTOS, ALTURA + 8.0)
	caixa.clip_contents = true
	_conteudo.add_child(caixa)
	_caixas.append(caixa)

	var clarao := ColorRect.new()
	clarao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clarao.color = Color(1, 1, 1, 0)
	clarao.position = Vector2.ZERO
	clarao.size = caixa.size
	caixa.add_child(clarao)
	_claroes.append(clarao)

	var numero := _rotulo("0", 60, true)
	numero.position = Vector2(0.0, 0.0)
	numero.size = caixa.size
	numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caixa.add_child(numero)
	_pontos.append(numero)



## Meio: "SET n" em cima, uma bolinha por set embaixo; aviso por baixo do placar.
func _criar_meio() -> void:
	var x := LARGURA_DO_BLOCO + LARGURA_DOS_PONTOS
	var meio := Estilo.painel(Color(0.03, 0.035, 0.05, 0.96), Estilo.INCLINACAO, 2, Color(1, 1, 1, 0.18))
	meio.position = Vector2(x, 6.0)
	meio.size = Vector2(LARGURA_DO_MEIO, ALTURA - 12.0)
	_conteudo.add_child(meio)

	_rotulo_do_set = _rotulo("SET 1", 22, true)
	_rotulo_do_set.position = Vector2(x, 6.0)
	_rotulo_do_set.size = Vector2(LARGURA_DO_MEIO, 30.0)
	_rotulo_do_set.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_conteudo.add_child(_rotulo_do_set)

	var tamanho := 14.0
	var espaco := 10.0
	var largura_das_bolinhas := TOTAL_DE_SETS * tamanho + (TOTAL_DE_SETS - 1) * espaco
	for i in TOTAL_DE_SETS:
		var bolinha := Panel.new()
		bolinha.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bolinha.size = Vector2(tamanho, tamanho)
		bolinha.position = Vector2(x + (LARGURA_DO_MEIO - largura_das_bolinhas) / 2.0 + i * (tamanho + espaco), 40.0)
		_conteudo.add_child(bolinha)
		_bolinhas.append(bolinha)
		_pintar_bolinha(bolinha, Color(0, 0, 0, 0), Estilo.TEXTO_APAGADO, 2)

	var centro := CenterContainer.new()
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.position = Vector2(0.0, ALTURA + 4.0)
	centro.size = Vector2(LARGURA, 30.0)
	_conteudo.add_child(centro)
	_aviso = Estilo.etiqueta("", Estilo.DESTAQUE, 22)
	_aviso.visible = false
	centro.add_child(_aviso)


# --- Efeito do ponto ---

func _mudar_efeito(progresso: float, time: int) -> void:
	_progresso_do_efeito[time] = progresso
	_efeito.queue_redraw()


## Corte de luz em diagonal pela caixa, faíscas saindo do centro e brilho em volta.
func _desenhar_efeito() -> void:
	for time in 2:
		var p := _progresso_do_efeito[time]
		if p < 0.0:
			continue
		var caixa := _caixas[time]
		var centro := caixa.position + caixa.size / 2.0
		var some := 1.0 - smoothstep(0.55, 1.0, p)
		# No fim o corte e as faíscas viram formas achatadas: não desenha.
		if some < 0.03:
			continue

		# Brilho dourado que se abre.
		var raio := lerpf(30.0, 120.0, ease(p, 0.4))
		for k in 5:
			_efeito.draw_circle(centro, raio * (1.0 - k * 0.16), Color(DOURADO, 0.12 * some))

		# Corte: losango comprido que cresce na diagonal, de baixo pra cima.
		var direcao := Vector2(1.0, -0.62).normalized()
		var normal := Vector2(-direcao.y, direcao.x)
		var comprimento := 175.0 * ease(minf(p / 0.35, 1.0), 0.3)
		var largura := 13.0 * some
		var ponta_a := centro - direcao * comprimento
		var ponta_b := centro + direcao * comprimento
		var miolo := Color(1.0, 0.96, 0.8, some)
		var borda := Color(DOURADO, 0.0)
		if comprimento > 2.0:
			_efeito.draw_polygon(
				PackedVector2Array([ponta_a, centro + normal * largura * 2.6, ponta_b, centro - normal * largura * 2.6]),
				PackedColorArray([borda, Color(DOURADO, 0.35 * some), borda, Color(DOURADO, 0.35 * some)]))
			_efeito.draw_polygon(
				PackedVector2Array([ponta_a, centro + normal * largura, ponta_b, centro - normal * largura]),
				PackedColorArray([borda, miolo, borda, miolo]))

		# Faíscas: triângulos finos que voam pra fora.
		for faisca in _faiscas[time]:
			var angulo: float = faisca[0]
			var forca: float = faisca[1]
			var dir := Vector2.from_angle(angulo)
			var inicio := centro + dir * lerpf(26.0, 96.0 * forca, ease(p, 0.35))
			var fim := inicio + dir * 16.0 * forca * some
			var lado := Vector2(-dir.y, dir.x) * 2.5
			_efeito.draw_colored_polygon(PackedVector2Array([inicio + lado, fim, inicio - lado]), Color(1.0, 0.85, 0.4, some))


# --- Ajudantes ---

## Borda da caixa de pontos na cor do time; o vencedor da partida ganha brilho.
func _pintar_caixa(time: int, venceu: bool) -> void:
	var estilo := Estilo.caixa(FUNDO_DOS_PONTOS, Estilo.INCLINACAO, 0.0, 0.0, 3, _cores[time])
	if venceu:
		estilo.border_color = _cores[time].lightened(0.3)
		estilo.set_border_width_all(4)
		estilo.shadow_color = Color(_cores[time], 0.7)
		estilo.shadow_size = 14
	_caixas[time].add_theme_stylebox_override("panel", estilo)


func _pintar_bolinha(bolinha: Panel, cor: Color, borda: Color, espessura: int) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.set_corner_radius_all(int(bolinha.size.x))
	estilo.set_border_width_all(espessura)
	estilo.border_color = borda
	bolinha.add_theme_stylebox_override("panel", estilo)


## Descobre quem ganhou cada set comparando com a última atualização.
func _lembrar_sets(sets: Array) -> void:
	var agora: Array[int] = [int(sets[0]), int(sets[1])]
	if agora[0] + agora[1] < _vencedores_dos_sets.size():
		# Partida recomeçou (ou o placar voltou): refaz a lista sem saber a ordem.
		_vencedores_dos_sets.clear()
		_ultimos_sets = [0, 0]
	for time in 2:
		for i in agora[time] - _ultimos_sets[time]:
			_vencedores_dos_sets.append(time)
	_ultimos_sets = agora


func _rotulo(texto: String, tamanho: int, titulo: bool) -> Label:
	var rotulo := Estilo.rotulo_com_contorno(tamanho, titulo, texto)
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return rotulo
