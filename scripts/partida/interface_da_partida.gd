extends Node
## Tudo o que aparece por cima da partida: placar, mensagens, faixa do ponto,
## barras de força e de energia, comandos, lembrete da pausa, cartas do Modo
## Caos e a cortina preta das trocas de cena.
##
## A partida (partida.gd) cria um e chama montar(); depois só manda mostrar
## mensagem, esconder ajuda etc. Saiu do partida.gd na Fase C do plano de
## melhorias (docs/HANDOFF_MELHORIAS.md).

const Estilo := preload("res://scripts/menus/estilo.gd")
const PlacarVisual := preload("res://scripts/partida/placar_visual.gd")
const FaixaDePonto := preload("res://scripts/partida/faixa_de_ponto.gd")
const Cortina := preload("res://scripts/menus/cortina.gd")
const BarraDeForca := preload("res://scripts/partida/barra_de_forca.gd")
const BarraDeEnergia := preload("res://scripts/partida/barra_de_energia.gd")

## Quanto tempo os avisos rápidos ficam na tela (s).
const DURACAO_DA_MENSAGEM := 1.8

var placar_visual: PanelContainer
## Faixa grande do ponto ("PONTO!", "ACE!", "BLOQUEIO!", "SET!").
var faixa: Control
## Cortina preta das trocas de cena.
var cortina: ColorRect
var rotulo_mensagem: Label
## Caixa escura atrás da mensagem; some quando não tem mensagem.
var caixa_da_mensagem: PanelContainer
## Mensagem de cada time, na metade da tela dele (saque, levantamento, largada).
var rotulos_do_time: Array[Label] = []
var caixas_do_time: Array[PanelContainer] = []
## Barra de força do saque de cada time.
var barras_de_forca: Array = [null, null]
## Barra do medidor de energia de cada time (Etapa 4).
var barras_de_energia: Array = [null, null]
## Lembrete "Esc ou Start: pausa"; some no fim de jogo.
var caixa_da_pausa: PanelContainer
## Textos de comandos (um por jogador): somem depois do primeiro saque.
var ajudas_de_comandos: Array[Label] = []
## Texto das cartas de cada time, no canto da quadra (só no Modo Caos).
var rotulos_de_cartas: Array[Label] = []

var _ajuda_escondida := false
## Conta de mensagens por lugar (meio, time 0, time 1), pra saber se a de um
## aviso rápido ainda é a que está na tela.
var _validade_da_mensagem := [0, 0, 0]


## Monta a interface. "nomes", "cores" e "ids" têm um item por time.
func montar(tela_dividida: bool, nomes: Array, cores: Array, ids: Array, modo_caos: bool) -> void:
	var camada := CanvasLayer.new()
	camada.name = "Interface"
	camada.layer = 1
	add_child(camada)

	if tela_dividida:
		# Linha separando as duas metades.
		var divisoria := ColorRect.new()
		divisoria.color = Color("#0F1620")
		divisoria.anchor_left = 0.5
		divisoria.anchor_right = 0.5
		divisoria.anchor_top = 0.0
		divisoria.anchor_bottom = 1.0
		divisoria.offset_left = -2.0
		divisoria.offset_right = 2.0
		camada.add_child(divisoria)

	# Placar em cima, no meio (em cima da divisória na tela dividida).
	var topo := CenterContainer.new()
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topo.position = Vector2(0.0, 10.0)
	topo.size = Vector2(1600.0, 100.0)
	camada.add_child(topo)
	placar_visual = PlacarVisual.new()
	topo.add_child(placar_visual)
	placar_visual.configurar(nomes, cores, ids)

	# Mensagem no meio, em cima. O CenterContainer mantém a caixa centralizada
	# e do tamanho do texto.
	var centro := CenterContainer.new()
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.position = Vector2(0.0, 118.0)
	centro.size = Vector2(1600.0, 56.0)
	camada.add_child(centro)
	caixa_da_mensagem = _caixa_da_interface()
	centro.add_child(caixa_da_mensagem)
	rotulo_mensagem = _rotulo_da_interface(32, true)
	caixa_da_mensagem.add_child(rotulo_mensagem)

	# Mensagem de cada time, embaixo da mensagem geral, na metade dele
	# (sem tela dividida, as duas ficam lado a lado na mesma tela).
	for time in 2:
		var centro_do_time := CenterContainer.new()
		centro_do_time.mouse_filter = Control.MOUSE_FILTER_IGNORE
		centro_do_time.position = Vector2(800.0 * time, 182.0)
		centro_do_time.size = Vector2(800.0, 48.0)
		camada.add_child(centro_do_time)
		var caixa := _caixa_da_interface()
		caixa.visible = false
		centro_do_time.add_child(caixa)
		var rotulo := _rotulo_da_interface(24, true)
		caixa.add_child(rotulo)
		caixas_do_time.append(caixa)
		rotulos_do_time.append(rotulo)

		# Barra de força do saque, embaixo, na metade do time.
		var centro_da_barra := CenterContainer.new()
		centro_da_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
		centro_da_barra.position = Vector2(800.0 * time, 760.0)
		centro_da_barra.size = Vector2(800.0, 70.0)
		camada.add_child(centro_da_barra)
		var barra := BarraDeForca.new()
		barra.name = "BarraDeForca%d" % time
		centro_da_barra.add_child(barra)
		barras_de_forca[time] = barra

		# Medidor de energia (super cortada), acima da barra de força.
		var centro_da_energia := CenterContainer.new()
		centro_da_energia.mouse_filter = Control.MOUSE_FILTER_IGNORE
		centro_da_energia.position = Vector2(800.0 * time, 690.0)
		centro_da_energia.size = Vector2(800.0, 60.0)
		camada.add_child(centro_da_energia)
		var barra_de_energia := BarraDeEnergia.new()
		barra_de_energia.name = "BarraDeEnergia%d" % time
		centro_da_energia.add_child(barra_de_energia)
		barras_de_energia[time] = barra_de_energia

		# Modo Caos: as cartas do time, no canto da metade dele.
		if modo_caos:
			var cartas_do_time := _rotulo_da_interface(18, false)
			cartas_do_time.position = Vector2(20.0 + 800.0 * time, 700.0)
			cartas_do_time.size = Vector2(360.0, 50.0)
			cartas_do_time.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			camada.add_child(cartas_do_time)
			rotulos_de_cartas.append(cartas_do_time)

	faixa = FaixaDePonto.new()
	camada.add_child(faixa)
	faixa.configurar(ids)

	# Cortina preta por cima de tudo (até da pausa), fechada até a cena abrir.
	var camada_da_cortina := CanvasLayer.new()
	camada_da_cortina.name = "CamadaDaCortina"
	camada_da_cortina.layer = 20
	add_child(camada_da_cortina)
	cortina = Cortina.nova(camada_da_cortina)

	# Comandos de cada jogador embaixo da metade dele (ou só do J1, sem tela dividida).
	# Curtos: somem no primeiro saque (o resto fica por conta do jogo ensinar).
	var ajudas_teclado := [
		"Teclado: WASD move · J passe · K saque/cortada · I flutuante · L bloqueio · Espaço mergulho",
		"Teclado: setas movem · 1 passe · 2 saque/cortada · 5 flutuante · 3 bloqueio · 0 mergulho",
	]
	var ajuda_do_controle := "Controle: A passe · X saque/cortada · RB flutuante · Y bloqueio · B mergulho"
	var controles_ligados := Input.get_connected_joypads().size()
	for jogador in (2 if tela_dividida else 1):
		var ajuda := _rotulo_da_interface(16, false)
		ajuda.text = ajuda_do_controle if controles_ligados > jogador else ajudas_teclado[jogador]
		ajuda.position = Vector2(20.0 + jogador * 800.0, 860.0)
		camada.add_child(ajuda)
		ajudas_de_comandos.append(ajuda)

	# Lembrete da pausa no canto direito, crescendo pra esquerda.
	caixa_da_pausa = _caixa_da_interface()
	caixa_da_pausa.anchor_left = 1.0
	caixa_da_pausa.anchor_right = 1.0
	caixa_da_pausa.offset_left = -18.0
	caixa_da_pausa.offset_right = -18.0
	caixa_da_pausa.offset_top = 16.0
	caixa_da_pausa.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	camada.add_child(caixa_da_pausa)
	var dica_da_pausa := _rotulo_da_interface(18, true)
	dica_da_pausa.text = "Esc ou Start: pausa"
	caixa_da_pausa.add_child(dica_da_pausa)


## Mostra uma mensagem no meio da tela (time = -1) ou na metade de um time.
## Texto vazio esconde a caixa.
## "fixa" = false: a mensagem some sozinha depois de DURACAO_DA_MENSAGEM
## (avisos rápidos). Fixa: fica até outra mensagem ou o próximo lance.
func mostrar_mensagem(texto: String, time := -1, fixa := true) -> void:
	_validade_da_mensagem[time + 1] += 1
	var numero: int = _validade_da_mensagem[time + 1]
	if time < 0:
		rotulo_mensagem.text = texto
		caixa_da_mensagem.visible = texto != ""
	else:
		rotulos_do_time[time].text = texto
		caixas_do_time[time].visible = texto != ""
	if fixa or texto == "" or not is_inside_tree():
		return
	await get_tree().create_timer(DURACAO_DA_MENSAGEM, true, false, true).timeout
	# Se outra mensagem entrou nesse meio tempo, deixa ela em paz.
	if is_inside_tree() and _validade_da_mensagem[time + 1] == numero:
		mostrar_mensagem("", time)


## Esconde a mensagem do meio e as dos dois times.
func limpar_mensagens() -> void:
	mostrar_mensagem("")
	for time in 2:
		mostrar_mensagem("", time)


## Esconde só a caixa do meio (a faixa do ponto já diz o que ela diria).
## O texto continua guardado pros testes e pro robô.
func esconder_caixa_do_meio() -> void:
	caixa_da_mensagem.visible = false


## Some com os textos de comandos e o lembrete da pausa (só valem no começo).
func esconder_ajuda() -> void:
	if _ajuda_escondida:
		return
	_ajuda_escondida = true
	var alvos: Array = []
	alvos.append_array(ajudas_de_comandos)
	alvos.append(caixa_da_pausa)
	for alvo in alvos:
		if not is_instance_valid(alvo):
			continue
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(alvo, "modulate:a", 0.0, 0.8)
		tween.tween_callback(alvo.hide)


## Some com o lembrete da pausa de uma vez (fim de jogo).
func esconder_lembrete_da_pausa() -> void:
	caixa_da_pausa.visible = false


## Texto das cartas de um time, no canto da quadra (só no Modo Caos).
func mostrar_cartas(time: int, texto: String) -> void:
	if rotulos_de_cartas.size() > time:
		rotulos_de_cartas[time].text = texto


## Caixa escura e inclinada (como as dos menus) atrás dos textos da partida.
func _caixa_da_interface() -> PanelContainer:
	var caixa := PanelContainer.new()
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_theme_stylebox_override("panel",
		Estilo.caixa(Color(0.06, 0.07, 0.09, 0.72), Estilo.INCLINACAO, 22.0, 4.0))
	return caixa


## Texto da interface com contorno escuro, pra ler bem em cima da quadra.
func _rotulo_da_interface(tamanho: int, titulo: bool) -> Label:
	return Estilo.rotulo_com_contorno(tamanho, titulo)
