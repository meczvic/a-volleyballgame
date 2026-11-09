extends PanelContainer
## Placar da partida: nome e cor de cada time, pontos grandes, bolinhas dos
## sets, quem saca, o número do set e o aviso de SET POINT / MATCH POINT.
## Quando sai um ponto, o número de quem pontuou pula e pisca na cor do time.
##
## Uso: configurar(nomes, cores) uma vez; atualizar(...) a cada mudança;
## comemorar(time) no ponto.

const Estilo := preload("res://scripts/menus/estilo.gd")

## Quanto o número cresce no ponto e quanto tempo leva pra voltar (s).
const PULO_DO_NUMERO := 1.7
const DURACAO_DO_PULO := 0.45
const SETS_PARA_VENCER := 2

var _faixas: Array[ColorRect] = []
var _nomes: Array[Label] = []
var _pontos: Array[Label] = []
## Bolinhas dos sets de cada time (desenhadas, não texto: a fonte não tem
## "●" e no navegador não há fonte reserva).
var _sets: Array = [[], []]
var _saque: Array[Panel] = []
var _rotulo_do_set: Label
var _aviso: Label
var _cores: Array[Color] = [Color.WHITE, Color.WHITE]
var _tweens: Array = [null, null]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel",
		Estilo.caixa(Color(0.06, 0.07, 0.09, 0.96), Estilo.INCLINACAO, 26.0, 6.0))
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 0)
	add_child(coluna)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 12)
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_child(linha)
	for time in 2:
		var faixa := ColorRect.new()
		faixa.custom_minimum_size = Vector2(8.0, 44.0)
		var saque := _bolinha(12.0)
		var nome := _rotulo("", 30, true)
		nome.custom_minimum_size.x = 170.0
		nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if time == 0 else HORIZONTAL_ALIGNMENT_LEFT
		var sets := HBoxContainer.new()
		sets.add_theme_constant_override("separation", 5)
		sets.alignment = BoxContainer.ALIGNMENT_CENTER
		for i in SETS_PARA_VENCER:
			var bolinha := _bolinha(11.0)
			sets.add_child(bolinha)
			_sets[time].append(bolinha)
		var pontos := _rotulo("0", 48, true)
		pontos.custom_minimum_size.x = 48.0
		pontos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var ordem: Array = [faixa, saque, nome, sets, pontos]
		if time == 1:
			ordem.reverse()
			linha.add_child(_rotulo("-", 36, true))
		for no in ordem:
			linha.add_child(no)
		_faixas.append(faixa)
		_saque.append(saque)
		_nomes.append(nome)
		_pontos.append(pontos)
	var embaixo := HBoxContainer.new()
	embaixo.alignment = BoxContainer.ALIGNMENT_CENTER
	embaixo.add_theme_constant_override("separation", 14)
	coluna.add_child(embaixo)
	_rotulo_do_set = _rotulo("SET 1", 20, true)
	_rotulo_do_set.add_theme_color_override("font_color", Estilo.TEXTO_SUAVE)
	embaixo.add_child(_rotulo_do_set)
	_aviso = Estilo.etiqueta("", Estilo.DESTAQUE, 20)
	_aviso.visible = false
	embaixo.add_child(_aviso)


func configurar(nomes: Array, cores: Array) -> void:
	for time in 2:
		_cores[time] = cores[time]
		_nomes[time].text = str(nomes[time]).to_upper()
		_faixas[time].color = cores[time]
		_pintar(_saque[time], cores[time], cores[time])


## "aviso": { "texto", "quem" } (veja Placar.aviso()).
func atualizar(pontos: Array, sets: Array, set_atual: int, quem_saca: int, aviso: Dictionary) -> void:
	for time in 2:
		_pontos[time].text = str(pontos[time])
		for i in SETS_PARA_VENCER:
			var ganho := i < int(sets[time])
			_pintar(_sets[time][i], _cores[time] if ganho else Color(0, 0, 0, 0), Estilo.TEXTO)
		_saque[time].modulate.a = 1.0 if time == quem_saca else 0.0
	_rotulo_do_set.text = "SET %d" % set_atual
	var texto: String = aviso.get("texto", "")
	_aviso.visible = texto != ""
	if texto != "":
		var quem: int = aviso.get("quem", -1)
		_aviso.text = " %s " % texto
		var cor: Color = _cores[quem] if quem >= 0 else Estilo.DESTAQUE
		_aviso.add_theme_stylebox_override("normal", Estilo.caixa(cor, Estilo.INCLINACAO, 10.0, 2.0))
		_aviso.add_theme_color_override("font_color", Estilo.FUNDO if cor.get_luminance() > 0.45 else Estilo.TEXTO)


## O número de quem pontuou pula e pisca na cor do time.
func comemorar(time: int) -> void:
	var numero := _pontos[time]
	numero.pivot_offset = numero.size / 2.0
	if _tweens[time]:
		_tweens[time].kill()
	numero.scale = Vector2.ONE * PULO_DO_NUMERO
	numero.modulate = _cores[time].lightened(0.35)
	var tween := create_tween().set_parallel()
	tween.tween_property(numero, "scale", Vector2.ONE, DURACAO_DO_PULO) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(numero, "modulate", Color.WHITE, DURACAO_DO_PULO * 1.4)
	_tweens[time] = tween


## Pra testes e pro robô.
func texto_dos_pontos(time: int) -> String:
	return _pontos[time].text


func texto_do_aviso() -> String:
	return _aviso.text.strip_edges() if _aviso.visible else ""


func sets_acesos(time: int) -> int:
	var n := 0
	for bolinha in _sets[time]:
		if bolinha.get_meta("acesa", false):
			n += 1
	return n


func numero_pulando(time: int) -> bool:
	return _pontos[time].scale.x > 1.01


func _bolinha(tamanho: float) -> Panel:
	var bolinha := Panel.new()
	bolinha.custom_minimum_size = Vector2(tamanho, tamanho)
	bolinha.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bolinha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pintar(bolinha, Color(0, 0, 0, 0), Estilo.TEXTO)
	return bolinha


## Bolinha cheia (cor com alfa) ou vazia (só a borda).
func _pintar(bolinha: Panel, cor: Color, borda: Color) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.set_corner_radius_all(int(bolinha.custom_minimum_size.x))
	estilo.set_border_width_all(2)
	estilo.border_color = borda
	bolinha.add_theme_stylebox_override("panel", estilo)
	bolinha.set_meta("acesa", cor.a > 0.0)


func _rotulo(texto: String, tamanho: int, titulo: bool) -> Label:
	var rotulo := Estilo.rotulo_com_contorno(tamanho, titulo, texto)
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return rotulo
