extends CanvasLayer
## Tela do Modo Caos: cada jogador escolhe uma carta, na metade dele.
##
## Esquerda/direita move o cursor, Passe (ou Ataque) confirma. Quando os dois
## confirmam, ou o tempo acaba (aí a carta é sorteada), o sinal "terminou"
## avisa a partida com o id da carta de cada jogador.
##
## Não usa a pausa do jogo: a partida só ignora os botões enquanto esta tela
## existe. Se alguém pausar de verdade, a contagem para junto.

## [id da carta do Jogador 1, id da carta do Jogador 2].
signal terminou(escolhas: Array)

const Estilo := preload("res://scripts/menus/estilo.gd")

const COR_DA_RARIDADE := {
	"prata": Color("#C3CAD6"),
	"ouro": Color("#F2C14E"),
	"prismatica": Color("#B98CFF"),
}
const NOME_DA_RARIDADE := { "prata": "PRATA", "ouro": "OURO", "prismatica": "PRISMÁTICA" }

const LARGURA_DA_CARTA := 236.0
const ALTURA_DA_CARTA := 320.0
const ESPACO := 18.0
const METADE := 800.0
## Botões apertados nos primeiros instantes (do ponto) não contam.
const ATRASO_DAS_TECLAS := 0.5
## Depois que os dois confirmam, espera um pouco pra ver a escolha.
const PAUSA_DO_FIM := 0.5

var _opcoes: Array = []
var _indice := [0, 0]
var _pronto := [false, false]
var _quadros: Array = [[], []]
var _avisos: Array = [null, null]
var _cores: Array = []
var _relogio: Label
var _tempo := 60.0
var _atraso := ATRASO_DAS_TECLAS
var _fechando := -1.0
var _terminada := false


## "opcoes": para cada jogador, a lista de cartas (dicionários de dados/cartas.json).
## "maos": ids que cada time já tem (só pra mostrar). "cores": cor de cada time.
func configurar(opcoes: Array, nomes: Array, cores: Array, maos: Array, nomes_das_maos: Array,
		tempo_limite: float) -> void:
	layer = 9
	_opcoes = opcoes
	_cores = cores
	_tempo = tempo_limite

	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.theme = Estilo.tema()
	add_child(raiz)

	var escurecer := ColorRect.new()
	escurecer.color = Color(0.0, 0.0, 0.0, 0.72)
	escurecer.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_child(escurecer)

	var titulo := Estilo.rotulo("ESCOLHA SUA CARTA", 60, Estilo.TEXTO, true)
	titulo.position = Vector2(0.0, 40.0)
	titulo.size = Vector2(METADE * 2.0, 70.0)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(titulo)

	_relogio = Estilo.rotulo("", 40, Estilo.DESTAQUE, true)
	_relogio.position = Vector2(0.0, 112.0)
	_relogio.size = Vector2(METADE * 2.0, 50.0)
	_relogio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(_relogio)

	for jogador in 2:
		var x0 := METADE * jogador
		var etiqueta := Estilo.etiqueta("JOGADOR %d  ·  %s" % [jogador + 1, str(nomes[jogador]).to_upper()],
			_cores[jogador], 30)
		etiqueta.position = Vector2(x0 + 28.0, 190.0)
		etiqueta.size = Vector2(LARGURA_DA_CARTA * 3.0 + ESPACO * 2.0, 44.0)
		raiz.add_child(etiqueta)

		for i in (_opcoes[jogador] as Array).size():
			var quadro := _criar_carta(_opcoes[jogador][i])
			quadro.position = Vector2(x0 + 28.0 + i * (LARGURA_DA_CARTA + ESPACO), 260.0)
			raiz.add_child(quadro)
			_quadros[jogador].append(quadro)

		var aviso := Estilo.rotulo("", 34, Estilo.PRONTO, true)
		aviso.position = Vector2(x0 + 28.0, 596.0)
		aviso.size = Vector2(LARGURA_DA_CARTA * 3.0 + ESPACO * 2.0, 44.0)
		aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		raiz.add_child(aviso)
		_avisos[jogador] = aviso

		var dica := Estilo.rotulo("Esquerda/direita escolhe  ·  Passe confirma", 22, Estilo.TEXTO_SUAVE)
		dica.position = Vector2(x0 + 28.0, 646.0)
		dica.size = Vector2(LARGURA_DA_CARTA * 3.0 + ESPACO * 2.0, 30.0)
		dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		raiz.add_child(dica)

		var nomes_da_mao := PackedStringArray(nomes_das_maos[jogador])
		var mao := Estilo.rotulo("Suas cartas: %s" % (
			", ".join(nomes_da_mao) if not nomes_da_mao.is_empty() else "nenhuma"
		), 22, Estilo.TEXTO_APAGADO)
		mao.position = Vector2(x0 + 28.0, 690.0)
		mao.size = Vector2(LARGURA_DA_CARTA * 3.0 + ESPACO * 2.0, 90.0)
		mao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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

	if _tempo <= 0.0:
		# Acabou o tempo: quem não escolheu ganha uma carta sorteada.
		for jogador in 2:
			if not _pronto[jogador]:
				_indice[jogador] = randi() % (_opcoes[jogador] as Array).size()
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


func _terminar() -> void:
	_terminada = true
	var escolhas: Array = []
	for jogador in 2:
		escolhas.append(str(_opcoes[jogador][_indice[jogador]].get("id", "")))
	terminou.emit(escolhas)
	queue_free()


func _atualizar_relogio() -> void:
	_relogio.text = str(ceili(maxf(_tempo, 0.0)))


func _atualizar_quadros() -> void:
	for jogador in 2:
		for i in (_quadros[jogador] as Array).size():
			var escolhida: bool = i == int(_indice[jogador])
			var quadro: Panel = _quadros[jogador][i]
			var cor_da_borda: Color = Estilo.PRONTO if (escolhida and _pronto[jogador]) \
				else (_cores[jogador] if escolhida else Estilo.PAINEL_CLARO)
			var largura := 6 if escolhida else 2
			quadro.add_theme_stylebox_override("panel",
				Estilo.caixa(Estilo.PAINEL, 0.0, 0.0, 0.0, largura, cor_da_borda))
			quadro.modulate = Color.WHITE if (escolhida or not _pronto[jogador]) else Color(1, 1, 1, 0.45)
		(_avisos[jogador] as Label).text = "PRONTO!" if _pronto[jogador] else ""


## Uma carta: faixa da raridade em cima, nome, conjunto e efeito.
func _criar_carta(carta: Dictionary) -> Panel:
	var raridade := str(carta.get("raridade", "prata"))
	var cor: Color = COR_DA_RARIDADE.get(raridade, Estilo.TEXTO_SUAVE)
	var quadro := Estilo.painel(Estilo.PAINEL, 0.0, 2, Estilo.PAINEL_CLARO)
	quadro.size = Vector2(LARGURA_DA_CARTA, ALTURA_DA_CARTA)

	var faixa := Estilo.painel(cor)
	faixa.size = Vector2(LARGURA_DA_CARTA, 44.0)
	quadro.add_child(faixa)
	var nome_da_raridade := Estilo.rotulo(NOME_DA_RARIDADE.get(raridade, raridade.to_upper()), 26, Estilo.FUNDO, true)
	nome_da_raridade.position = Vector2(14.0, 4.0)
	faixa.add_child(nome_da_raridade)

	var nome := Estilo.rotulo(str(carta.get("nome", "?")), 36, Estilo.TEXTO, true)
	nome.position = Vector2(14.0, 58.0)
	nome.size = Vector2(LARGURA_DA_CARTA - 28.0, 90.0)
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quadro.add_child(nome)

	var conjunto := Estilo.rotulo("Conjunto: %s" % str(carta.get("conjunto", "")).capitalize(), 20, cor)
	conjunto.position = Vector2(14.0, 150.0)
	quadro.add_child(conjunto)

	var efeito := Estilo.rotulo(str(carta.get("efeito", "")), 24, Estilo.TEXTO_SUAVE)
	efeito.position = Vector2(14.0, 188.0)
	efeito.size = Vector2(LARGURA_DA_CARTA - 28.0, 120.0)
	efeito.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quadro.add_child(efeito)
	return quadro
