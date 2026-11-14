extends SceneTree
## Robô que joga a partida sozinho, apertando as mesmas teclas que uma pessoa
## (ações p1_*/p2_*). Serve pra ver o jogo rodando sem ninguém no teclado,
## gravar vídeo e achar erros numa partida inteira.
##
##   godot --path . --script res://ferramentas/robo.gd -- times=karasuno,nekoma estadio=ginasio_japones segundos=120
##
## Gravar vídeo (Godot grava em AVI; converta com ffmpeg depois):
##   godot --path . --write-movie saida.avi --fixed-fps 30 --script res://ferramentas/robo.gd -- times=brasil,brasil segundos=90
##
## Opções: times=<id1>,<id2>  estadio=<id>  segundos=<limite>  prints=<pasta>
## (salva um PNG por segundo em <pasta>)  saque=<0|1> (quem saca primeiro)
## ROBO_PONTOS=1 (variável de ambiente): uma linha por ponto, dizendo como acabou.
## semente=<número> (repete a mesma partida; veja abaixo).
## gravar=<arquivo.json>: salva os comandos com o número do quadro no fim.
## repetir=<arquivo.json>: joga só com a gravação (use a mesma semente e o mesmo
## computador=; o robô não aperta nada). Sai igual à partida gravada.
## computador=<facil|normal|dificil>: o time 2 é jogado pelo computador de
## verdade (modo 1 jogador) e o robô joga só o time 1. Com dois=1, o
## computador joga os dois times e o robô só assiste.
## Termina sozinho no fim da partida ou do tempo, e imprime um resumo.
##
## Partida repetível: com semente= e --fixed-fps 60, o robô e a partida sorteiam
## sempre os mesmos números e cada quadro tem o mesmo tempo, então a partida
## sai igual toda vez (testes/teste_partida_com_semente.gd usa isso):
##   godot --headless --fixed-fps 60 --path . --script res://ferramentas/robo.gd -- semente=42 segundos=40

const Dados := preload("res://scripts/comum/dados.gd")

var partida: Node
var _relogio := 0.0
var _limite := 120.0
var _prints := ""
var _closeup := ""
var _closeups := 0
var _ultimo_print := -1
var _gravar := ""
var _carga := [-1.0, -1.0]
## Até quando o robô segura o ataque na cortada (relógio do robô).
var _ataque_ate := [-1.0, -1.0]
var _duracao_da_carga := 0.4
var _apertados := {}
var _desejados := {}
var _soltos := {}
var _pontos_vistos := [0, 0]
var _quadros := 0
var _tempo_de_quadro := 0.0
var _pior_quadro := 0.0
var _lances := {"saques": 0, "passes": 0, "levantamentos": 0, "cortadas": 0, "bloqueios": 0}
var _rallies := 0
var _toques_no_rally := 0
var _maior_rally := 0
## Chance de "errar" um lance (deixar a bola cair) pra partida ter pontos.
var _chance_de_erro := 0.12
var _dormindo := [false, false]
## Levantamento que o robô está fazendo em cada time (veja _levantar).
var _levantamento := [{}, {}]
var _ultimo_sorteio := ["", ""]
## Sorteios do robô (força do saque, mira, erros). Com semente=, repete.
var _sorteio := RandomNumberGenerator.new()
var _semente := -1
## Onde a bola caiu em cada rally (x, z, em cm), pra comparar partidas.
var _quedas: Array[String] = []
## Times que o robô joga (com computador=, só o time 1, ou nenhum com dois=1).
var _times_do_robo: Array[int] = [0, 1]
## Bolas lançadas (saque, toques, rede) em todos os rallies e no começo do atual.
var _lancamentos_nos_rallies := 0
var _lancamentos_no_comeco := 0
## Pontos ganhos por cada time na partida toda e tamanho de cada ponto (bolas:
## saque e toques), pra medir as dificuldades.
var _pontos_ganhos := [0, 0]
var _bolas_no_ponto := {"1-2": [0, 0], "3-5": [0, 0], "6-9": [0, 0], "10+": [0, 0]}
var _lancamentos_no_ponto := 0
var _dormiu := false


func _initialize() -> void:
	var opcoes := {}
	for arg in OS.get_cmdline_user_args():
		var partes := arg.split("=")
		opcoes[partes[0]] = partes[1] if partes.size() > 1 else ""
	var times := str(opcoes.get("times", "karasuno,nekoma")).split(",")
	var configuracao := root.get_node("Configuracao")
	configuracao.times = [times[0], times[1] if times.size() > 1 else times[0]]
	if opcoes.has("estadio"):
		configuracao.estadio = str(opcoes["estadio"])
	_limite = float(opcoes.get("segundos", 120.0))
	_prints = str(opcoes.get("prints", ""))
	_chance_de_erro = float(opcoes.get("erro", 0.12))
	_closeup = str(opcoes.get("closeup", ""))
	if _closeup != "":
		DirAccess.make_dir_recursive_absolute(_closeup)
	if _prints != "":
		DirAccess.make_dir_recursive_absolute(_prints)
	_semente = int(opcoes.get("semente", -1))
	configuracao.semente = _semente
	configuracao.contra_computador = opcoes.has("computador")
	configuracao.computador_nos_dois = opcoes.has("computador") and str(opcoes.get("dois", "0")) == "1"
	if opcoes.has("computador"):
		configuracao.dificuldade = str(opcoes["computador"])
		_times_do_robo = []
		if not configuracao.computador_nos_dois:
			_times_do_robo.append(0)
	_gravar = str(opcoes.get("gravar", ""))
	configuracao.repeticao = str(opcoes.get("repetir", ""))
	if configuracao.repeticao != "":
		# Quem joga é a gravação: o robô e o computador só assistem.
		configuracao.computador_nos_dois = false
		_times_do_robo = []
	if _semente >= 0:
		_sorteio.seed = _semente
	else:
		_sorteio.randomize()
	process_frame.connect(_comecar, CONNECT_ONE_SHOT)
	set_meta("saque", int(opcoes.get("saque", -1)))


func _comecar() -> void:
	partida = load("res://cenas/partida.tscn").instantiate()
	root.add_child(partida)
	var saque: int = get_meta("saque")
	if saque >= 0:
		partida.placar.quem_saca = saque
		partida._preparar_saque()
	partida.bola.tocou_chao.connect(func(p: Vector3): _fim_do_rally(p))
	partida.placar.ponto_marcado.connect(_ponto)
	physics_frame.connect(_jogar)
	var configuracao := root.get_node("Configuracao")
	print("Robô: %s x %s, estádio %s%s%s" % [configuracao.times[0], configuracao.times[1], configuracao.estadio,
		", semente %d" % _semente if _semente >= 0 else "",
		", computador %s" % configuracao.dificuldade if configuracao.contra_computador else ""])


func _jogar() -> void:
	var delta := 1.0 / Engine.physics_ticks_per_second
	_relogio += delta
	if partida.estado == partida.Estado.FIM or _relogio > _limite:
		_terminar()
		return
	for time in _times_do_robo:
		_jogar_time(time, delta)
	_aplicar_teclas()
	# Desempenho: tempo gasto por quadro (processo + física), em ms.
	if _relogio > 2.0:
		var gasto: float = (Performance.get_monitor(Performance.TIME_PROCESS) + Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0
		_quadros += 1
		_tempo_de_quadro += gasto
		_pior_quadro = maxf(_pior_quadro, gasto)
	if OS.has_environment("ROBO_DEBUG") and partida.estado == partida.Estado.RALLY and Engine.get_physics_frames() % 20 == 0:
		var a: Node3D = partida.controlados[0]
		print("t=%.1f bola=%s queda=%s ctrl0=%s dir0=%s" % [_relogio, partida.bola.position, partida.bola.ponto_previsto, a.position, partida.entradas[0].direcao])
	if _closeup != "" and _closeups < 400 and Engine.get_physics_frames() % 2 == 0:
		_capturar_closeup()
	if _prints != "" and int(_relogio) != _ultimo_print:
		_ultimo_print = int(_relogio)
		root.get_texture().get_image().save_png("%s/%04d.png" % [_prints, _ultimo_print])


## Decide o que o jogador "time" faz neste quadro.
func _jogar_time(time: int, delta: float) -> void:
	var p := "p%d_" % (time + 1)
	var estado = partida.estado
	var atleta: Node3D = partida.controlados[time]
	if estado == partida.Estado.SAQUE:
		if time != partida.placar.quem_saca:
			return
		# Já soltou: o atleta está no movimento do saque (corrida, lançamento).
		if not partida.saque_viagem.is_empty():
			return
		# Segura Ataque por um tempo variável e solta: saque com força variada.
		if _carga[time] < 0.0:
			if partida.tempo_no_saque > 0.6:
				_carga[time] = 0.0
				_duracao_da_carga = _sorteio.randf_range(0.25, 0.7)
				_segurar(p + "ataque")
		elif _carga[time] < _duracao_da_carga:
			_carga[time] += delta
			_segurar(p + "ataque")
		else:
			# Parou de segurar: o saque sai quando o botão solta.
			_carga[time] = -1.0
			_lances["saques"] += 1
		return
	if estado != partida.Estado.RALLY:
		_carga[time] = -1.0
		return
	# Cortada segurada: continua apertando até a hora sorteada (pouco = largada).
	if _relogio < _ataque_ate[time]:
		_segurar(p + "ataque")
	var bola = partida.bola
	if not bola.em_voo or not partida.cortadas[time].is_empty() or _dormindo[time]:
		return
	var lado: float = partida._lado(time)
	var queda: Vector3 = bola.ponto_previsto
	var bola_vem_pra_ca: bool = queda.z * lado > 0.0
	var nossa: bool = partida.toques.time_com_a_bola == time and partida.ultimo_toque == time
	var toques: int = partida.toques.toques if nossa else 0

	if not bola_vem_pra_ca:
		# Bola indo pro outro lado: se sou da rede e ela está vindo alta, bloqueio.
		if partida.ultimo_toque != time and partida._e_da_rede(time, atleta) \
				and absf(bola.position.z) < 2.5 and bola.position.y > 2.3 and bola.velocidade_atual().z * lado > 0.0:
			if _sorteio.randf() < 0.3:
				_apertar(p + "bloqueio")
				_lances["bloqueios"] += 1
		return

	# Vai até onde a bola vai cair (um pouco atrás dela, pro lado da própria quadra).
	var alvo := Vector3(queda.x, 0.0, queda.z + lado * 0.25)
	if toques == 2:
		# Terceiro toque: fica embaixo de onde a bola vai estar na batida.
		var prevista: Vector3 = bola.posicao_daqui_a(partida.TEMPO_ATE_A_BATIDA)
		alvo = Vector3(prevista.x, 0.0, prevista.z + lado * 0.3)
	var dif := Vector2(alvo.x - atleta.position.x, alvo.z - atleta.position.z)
	if dif.length() > 0.15:
		var dir: Vector2 = dif.normalized() * float(partida._lado_da_camera(time))
		_segurar(p + ("direita" if dir.x > 0.0 else "esquerda"), absf(dir.x))
		_segurar(p + ("baixo" if dir.y > 0.0 else "cima"), absf(dir.y))

	var dist := Vector2(bola.position.x - atleta.position.x, bola.position.z - atleta.position.z).length()
	var descendo: bool = bola.velocidade_atual().y < 0.0
	if toques == 1:
		_levantar(time, p, dist < 1.4 and descendo and bola.position.y < 2.6, descendo)
	elif toques < 2:
		# Passe: quando a bola chega perto e baixa.
		if dist < 1.4 and descendo and bola.position.y < 2.6:
			if _errou(time):
				return
			_apertar(p + "passe")
			_lances["passes" if toques == 0 else "levantamentos"] += 1
			_toques_no_rally += 1
			# No levantamento, escolhe pra onde (direção segurada).
			if toques == 1:
				var escolha := _sorteio.randi_range(0, 2)
				if escolha == 0:
					_segurar(p + "esquerda")
				elif escolha == 1:
					_segurar(p + "direita")
	else:
		var prevista: Vector3 = bola.posicao_daqui_a(partida.TEMPO_ATE_A_BATIDA)
		var no_chao := Vector2(prevista.x - atleta.position.x, prevista.z - atleta.position.z).length()
		if no_chao < 1.2 and prevista.y > 1.9 and prevista.y < 3.3 and descendo:
			if _errou(time):
				return
			_apertar(p + "ataque")
			# Segura um tempo sorteado: às vezes larga (solta logo), quase sempre corta.
			_ataque_ate[time] = _relogio + (0.05 if _sorteio.randf() < 0.12 else _sorteio.randf_range(0.2, 0.5))
			_lances["cortadas"] += 1
			_toques_no_rally += 1
			# Mira variada.
			var escolha := _sorteio.randi_range(0, 2)
			if escolha == 0:
				_segurar(p + "esquerda")
			elif escolha == 1:
				_segurar(p + "direita")
		elif dist < 1.5 and descendo and bola.position.y < 1.6:
			# Não deu pra cortar: devolve de graça.
			_apertar(p + "passe")


## Levantamento (13/11/2026): segura o passe e solta na hora do toque; o tempo
## segurando escolhe a altura. Sorteia uma vez por levantamento: rápida (aperta
## e solta na hora), normal (segura desde o alto do passe) ou alta (segura desde
## o passe), e pra onde (direção segurada até soltar).
func _levantar(time: int, p: String, na_hora: bool, descendo: bool) -> void:
	var chave := "%d_%d" % [_rallies, partida.bola.lancamentos]
	if _levantamento[time].get("chave", "") != chave:
		if _errou(time):
			return
		var modos := ["rapida", "normal", "alta"]
		var direcoes := ["", p + "esquerda", p + "direita"]
		_levantamento[time] = { "chave": chave, "modo": modos[_sorteio.randi_range(0, 2)],
			"dir": direcoes[_sorteio.randi_range(0, 2)], "feito": false }
	var plano: Dictionary = _levantamento[time]
	if plano["feito"]:
		return
	if plano["dir"] != "":
		_segurar(plano["dir"])
	if na_hora:
		plano["feito"] = true
		_lances["levantamentos"] += 1
		_toques_no_rally += 1
		# Rápida, ou não deu tempo de começar a segurar (passe baixo): aperta agora.
		if plano["modo"] == "rapida" or not _apertados.has(p + "passe"):
			_apertar(p + "passe")
		# Nos outros, não pedir o passe neste quadro = soltar = levantar.
		return
	# A alta começa depois de a bola subir (senão o botão do passe ainda está
	# apertado e o levantamento não começa).
	var subiu: bool = partida.bola.position.y > 2.8 or descendo
	if (plano["modo"] == "alta" and subiu) or (plano["modo"] == "normal" and descendo):
		_segurar(p + "passe")


## Sorteia um erro: o jogador "congela" até o fim do rally e a bola cai.
## Sorteia uma vez por toque (não a cada quadro).
func _errou(time: int) -> bool:
	var chave := "%d_%d" % [_rallies, partida.toques.toques]
	if _ultimo_sorteio[time] == chave:
		return false
	_ultimo_sorteio[time] = chave
	if _sorteio.randf() < _chance_de_erro:
		_dormindo[time] = true
		return true
	return false


func _fim_do_rally(queda: Vector3) -> void:
	_quedas.append("%d,%d" % [roundi(queda.x * 100.0), roundi(queda.z * 100.0)])
	_dormiu = _dormindo[0]
	if OS.has_environment("ROBO_DEBUG"):
		print("fim do rally: bola em %s, dormindo=%s, toques=%d, último toque=%d" % [partida.bola.position, _dormindo, _toques_no_rally, partida.ultimo_toque])
	_dormindo = [false, false]
	_lancamentos_nos_rallies += partida.bola.lancamentos - _lancamentos_no_comeco
	_lancamentos_no_comeco = partida.bola.lancamentos
	_rallies += 1
	_maior_rally = maxi(_maior_rally, _toques_no_rally)
	_toques_no_rally = 0



func _ponto(time: int) -> void:
	var bolas: int = partida.bola.lancamentos - _lancamentos_no_ponto
	_lancamentos_no_ponto = partida.bola.lancamentos
	_pontos_ganhos[time] += 1
	var faixa := "1-2" if bolas <= 2 else ("3-5" if bolas <= 5 else ("6-9" if bolas <= 9 else "10+"))
	_bolas_no_ponto[faixa][time] += 1
	if OS.has_environment("ROBO_PONTOS"):
		var b: Vector3 = partida.bola.position
		var quadra: int = 0 if signf(b.z) == signf(partida._lado(0)) else 1
		var dentro: bool = absf(b.x) <= partida.LARGURA / 2.0 + 0.1 and absf(b.z) <= partida.COMPRIMENTO / 2.0 + 0.1
		print("Robô: ponto do time %d em %d bolas; último toque do time %d; caiu %s da quadra do time %d; robô errou de propósito: %s" % [
			time, bolas, partida.ultimo_toque, "dentro" if dentro else "fora", quadra, "sim" if _dormindo[0] or _dormiu else "não"])
	_dormiu = false


## Toque: aperta neste quadro e solta no próximo. (Soltar e apertar de novo no
## mesmo quadro não conta como "acabou de apertar" pro Godot.)
func _apertar(acao: String) -> void:
	if _soltos.has(acao):
		return
	_desejados[acao] = 1.0


## Segura (movimento, carga do saque): fica apertado enquanto for pedido.
func _segurar(acao: String, forca := 1.0) -> void:
	_desejados[acao] = forca


## Aplica no Input o que foi pedido neste quadro: solta o que não foi mais
## pedido e aperta o que é novo. Chamado no fim de cada quadro do robô.
func _aplicar_teclas() -> void:
	_soltos = {}
	for acao in _apertados.keys():
		if not _desejados.has(acao):
			Input.action_release(acao)
			_apertados.erase(acao)
			_soltos[acao] = true
	for acao in _desejados:
		Input.action_press(acao, _desejados[acao])
		_apertados[acao] = true
	_desejados = {}


## Recorte ampliado do atleta controlado do time 0 quando a bola está perto
## dele (pra conferir a animação do lance quadro a quadro).
func _capturar_closeup() -> void:
	var atleta: Node3D = partida.controlados[0]
	var bola = partida.bola
	# ROBO_FILME=1: recorta sempre (um quadro a cada 3), pra ver o saque e a corrida.
	var filme := OS.has_environment("ROBO_FILME")
	if filme:
		if Engine.get_physics_frames() % 3 != 0:
			return
	elif not bola.em_voo or atleta.position.distance_to(bola.position) > 3.0:
		return
	var camera: Camera3D = partida.cameras[0]
	var viewport := camera.get_viewport()
	var imagem: Image = viewport.get_texture().get_image()
	var centro := camera.unproject_position(atleta.position + Vector3(0, 1.0, 0))
	var lado := 220
	var recorte := Rect2i(int(centro.x) - lado / 2, int(centro.y) - lado / 2, lado, lado)
	recorte = recorte.intersection(Rect2i(Vector2i.ZERO, imagem.get_size()))
	if recorte.size.x < 10 or recorte.size.y < 10:
		return
	var saida := imagem.get_region(recorte)
	saida.resize(saida.get_width() * 3, saida.get_height() * 3, Image.INTERPOLATE_NEAREST)
	_closeups += 1
	saida.save_png("%s/%04d_t%05.1f.png" % [_closeup, _closeups, _relogio])


func _terminar() -> void:
	physics_frame.disconnect(_jogar)
	if _gravar != "":
		partida.salvar_registro(_gravar)
	var placar = partida.placar
	print("Robô: fim depois de %.0f s de jogo. Sets %d x %d, pontos %d x %d, estado %s." % [
		_relogio, placar.sets[0], placar.sets[1], placar.pontos[0], placar.pontos[1], partida.Estado.keys()[partida.estado]])
	print("Robô: %d rallies (maior com %d toques), lances: %s" % [_rallies, _maior_rally, _lances])
	print("Robô: cortadas em linha reta: %d de %d" % [partida.bola.retos, int(_lances.get("cortadas", 0))])
	print("Robô: quedas (cm): %s" % " ".join(_quedas))
	print("Robô: pontos na partida toda: %d x %d; por tamanho do ponto (bolas: time 0/time 1): %s" % [
		_pontos_ganhos[0], _pontos_ganhos[1], _bolas_no_ponto])
	if _rallies > 0:
		print("Robô: media de bolas por rally (saque e toques): %.1f" % (float(_lancamentos_nos_rallies) / _rallies))
	if _quadros > 0:
		print("Robô: desempenho: %.1f ms por quadro em média (pior %.1f ms), %d quadros medidos, %s, placa: %s" % [
			_tempo_de_quadro / _quadros, _pior_quadro, _quadros,
			"sem janela (headless)" if DisplayServer.get_name() == "headless" else "%dx%d" % [root.size.x, root.size.y],
			RenderingServer.get_video_adapter_name()])
	quit()
