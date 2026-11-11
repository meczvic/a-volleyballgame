extends SceneTree
## Tira prints das telas do jogo, sempre no mesmo estado, pra comparar o
## visual antes e depois de uma mudança. Precisa de janela (não use --headless).
##
##   godot --path . --resolution 1600x900 --script res://ferramentas/capturas_de_tela.gd -- saida=producao/baseline
##   godot --path . --resolution 1280x720 --script res://ferramentas/capturas_de_tela.gd -- saida=producao/baseline telas=selecao
##
## Opções:
##   saida=<pasta>      onde salvar (padrão producao/telas)
##   telas=<lista>      menu, selecao, partida, cartas, placar, ginasio (padrão: todas)
##   times=<id1>,<id2>  padrão karasuno,nekoma
##   estadio=<id>       padrão ginasio_japones
##
## Cada arquivo sai como <tela>_<largura>x<altura>.png. Telas salvas:
##   menu             menu principal
##   selecao_inicio   seleção com os cursores nos dois times, ninguém confirmou
##   selecao_estadio  os dois confirmaram, escolhendo o estádio
##   partida_saque    partida parada esperando o saque (placar zerado)
##   cartas           Modo Caos: escolha de cartas do começo da partida, sempre
##                    com as mesmas cartas (uma de cada raridade) pra comparar
##   cartas_estados   o mesmo, com o J1 confirmado na 3ª carta e o J2 na 2ª
##   cartas_troca     depois disso, o J2 usa o TROCAR (cartas novas, sorteadas)
##   ginasio_vazio    câmeras de jogo sem atletas nem bola (só o cenário)
##   ginasio_geral    visão do alto, de um canto, com os 12 atletas (sem placar)
##   ginasio_geral_vazio  a mesma visão, sem atletas
##   ginasio_frente_vazio na altura dos olhos, do fundo (como a referência image-gen-1)
##   detalhe_banco, detalhe_palco  closes do banco de um time e do canto do palco
##   placar_*         pontos marcados pela regra de verdade (_encerrar_rally):
##                    jogo (4 x 3), ponto (no meio da animação, 6 x 3), set_point,
##                    set (faixa SET!), match_point e fim. Cada um sai também
##                    recortado no placar (placar_*_recorte_...).
##
## Pra partida em movimento, use o robô: ferramentas/robo.gd com prints=<pasta>.

const CENA_MENU := "res://cenas/menu_principal.tscn"
const CENA_SELECAO := "res://cenas/selecao_de_times.tscn"
const CENA_PARTIDA := "res://cenas/partida.tscn"
const TODAS := ["menu", "selecao", "partida", "cartas", "placar", "ginasio"]
## Tempo pras animações de entrada (cortina, aparecer) terminarem.
const ESPERA := 1.5

var _saida := "res://producao/telas"
var _telas: Array = TODAS
var _times := ["karasuno", "nekoma"]
var _estadio := "ginasio_japones"
var _atual: Node


func _initialize() -> void:
	var opcoes := {}
	for arg in OS.get_cmdline_user_args():
		var partes := arg.split("=")
		opcoes[partes[0]] = partes[1] if partes.size() > 1 else ""
	if opcoes.has("saida"):
		var pasta := str(opcoes["saida"])
		_saida = pasta if pasta.begins_with("res://") or pasta.is_absolute_path() else "res://" + pasta
	if opcoes.has("telas"):
		_telas = Array(str(opcoes["telas"]).split(","))
	if opcoes.has("times"):
		_times = Array(str(opcoes["times"]).split(","))
	_estadio = str(opcoes.get("estadio", _estadio))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_saida))
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	for tela in _telas:
		await _capturar(str(tela))
	_fechar_atual()
	print("Capturas de tela: fim. Pasta %s" % ProjectSettings.globalize_path(_saida))
	quit()


func _capturar(tela: String) -> void:
	var configuracao := root.get_node("Configuracao")
	configuracao.times = [_times[0], _times[1] if _times.size() > 1 else _times[0]]
	configuracao.estadio = _estadio
	configuracao.modo = "rapida"
	match tela:
		"menu":
			_abrir(CENA_MENU)
			await _esperar(ESPERA)
			_salvar("menu")
		"selecao":
			var selecao := _abrir(CENA_SELECAO)
			await _esperar(ESPERA)
			_salvar("selecao_inicio")
			selecao._confirmar(0)
			selecao._confirmar(1)
			await _esperar(0.8)
			_salvar("selecao_estadio")
		"partida":
			_abrir(CENA_PARTIDA)
			await _esperar(3.0)
			_salvar("partida_saque")
		"placar":
			await _capturar_placar()
		"ginasio":
			await _capturar_ginasio()
		"cartas":
			configuracao.modo = "caos"
			var partida := _abrir(CENA_PARTIDA)
			await _esperar(0.3)
			var escolha := _cartas_fixas(partida)
			await _esperar(ESPERA)
			_salvar("cartas")
			escolha._mover(0, 2)
			escolha._confirmar(0)
			escolha._mover(1, 1)
			await _esperar(0.4)
			_salvar("cartas_estados")
			if escolha.has_method("_trocar"):
				escolha._trocar(1)
				await _esperar(0.8)
				_salvar("cartas_troca")
			configuracao.modo = "rapida"
		_:
			print("Tela desconhecida: %s (use %s)" % [tela, ", ".join(TODAS)])


## Marca pontos pelo caminho de verdade da partida (_encerrar_rally), que
## mexe na regra, no placar e na faixa de ponto.
func _capturar_placar() -> void:
	var partida := _abrir(CENA_PARTIDA)
	await _esperar(ESPERA)
	_pontos(partida, 4, 3)
	await _esperar(0.3)
	_salvar("placar_jogo", true)
	_pontos(partida, 5, 3)
	_ponto(partida, 0)
	await create_timer(0.12).timeout
	await process_frame
	_salvar("placar_ponto", true)
	await _esperar(1.8)
	_salvar("placar_set_point", true)
	_ponto(partida, 0)
	await _esperar(0.35)
	_salvar("placar_set", true)
	await _esperar(1.8)
	_pontos(partida, 2, 6)
	_ponto(partida, 1)
	await _esperar(1.8)
	_pontos(partida, 6, 5)
	await _esperar(0.3)
	_salvar("placar_match_point", true)
	_ponto(partida, 0)
	await _esperar(0.4)
	_salvar("placar_fim", true)


## Troca a escolha sorteada por uma fixa: prata, ouro e prismática pros dois.
func _cartas_fixas(partida: Node) -> Node:
	var Cartas = load("res://scripts/regras/cartas.gd")
	var dados: Dictionary = partida.dados_das_cartas
	var ids := [["maos_firmes", "muro", "troca_de_lugar"], ["saque_firme", "ataque_rapido", "troca_de_lugar"]]
	var opcoes := []
	for lista in ids:
		var cartas := []
		for id in lista:
			cartas.append(Cartas.por_id(dados, id))
		opcoes.append(cartas)
	if partida.escolha_de_cartas != null and is_instance_valid(partida.escolha_de_cartas):
		partida.escolha_de_cartas.free()
	var escolha = load("res://scripts/partida/escolha_de_cartas.gd").new()
	partida.add_child(escolha)
	var argumentos := [opcoes, [partida.times_em_jogo[0]["nome"], partida.times_em_jogo[1]["nome"]],
		[partida._cor_do_time(0), partida._cor_do_time(1)], [[], []], [[], []], 60.0]
	# A versão nova também recebe os ids dos times (pros emblemas).
	if escolha.get_method_argument_count("configurar") >= 7:
		argumentos.append([str(partida.times_em_jogo[0]["id"]), str(partida.times_em_jogo[1]["id"])])
	# A versão com atleta nas cartas e botão TROCAR recebe os times e as trocas.
	if escolha.get_method_argument_count("configurar") >= 10:
		argumentos.append(partida.times_em_jogo)
		argumentos.append([1, 1])
		argumentos.append(partida._trocar_cartas)
	escolha.callv("configurar", argumentos)
	partida.escolha_de_cartas = escolha
	return escolha


## Cenário vazio nas câmeras de jogo e uma visão geral do alto.
func _capturar_ginasio() -> void:
	var partida := _abrir(CENA_PARTIDA)
	await _esperar(ESPERA)
	_mostrar_atletas(partida, false)
	await _esperar(0.2)
	_salvar("ginasio_vazio")

	# Visão geral: some a tela dividida e a interface, e uma câmera do alto,
	# de dentro do canto do ginásio, mostra tudo.
	for nome in ["TelaDividida", "Interface"]:
		var camada := partida.get_node_or_null(nome) as CanvasLayer
		if camada != null:
			camada.visible = false
	var camera := Camera3D.new()
	camera.fov = 46.0
	partida.add_child(camera)
	camera.look_at_from_position(Vector3(-8.5, 9.5, 17.5), Vector3(0.5, 0.0, -2.0))
	var cenario = partida.get("cenario")
	if cenario != null:
		camera.set_cull_mask_value(cenario.CAMADA_ATRAS_DO_TIME[0], false)
	camera.current = true
	_mostrar_atletas(partida, true)
	await _esperar(0.3)
	_salvar("ginasio_geral")
	_mostrar_atletas(partida, false)
	await _esperar(0.2)
	_salvar("ginasio_geral_vazio")
	# Na altura dos olhos, do fundo, como a imagem "image-gen-1" do pacote.
	camera.fov = 62.0
	camera.look_at_from_position(Vector3(0.0, 3.4, 17.8), Vector3(0.0, 3.0, -8.0))
	await _esperar(0.3)
	_salvar("ginasio_frente_vazio")
	# Closes dos objetos em volta da quadra (bancos, quadro, carrinho).
	camera.fov = 40.0
	camera.look_at_from_position(Vector3(5.2, 2.2, 3.2), Vector3(9.4, 0.5, 6.2))
	await _esperar(0.3)
	_salvar("detalhe_banco")
	camera.look_at_from_position(Vector3(-6.5, 2.4, -11.0), Vector3(-9.8, 0.7, -16.6))
	await _esperar(0.3)
	_salvar("detalhe_palco")


## Mostra ou esconde tudo o que é do jogo (atletas, bola, anéis, marcas),
## deixando só o cenário.
func _mostrar_atletas(partida: Node, sim: bool) -> void:
	for filho in partida.get_children():
		if filho is Node3D and filho.name != "Cenario" and not filho is Camera3D:
			var no := filho as Node3D
			if not sim:
				no.set_meta("estava_visivel", no.visible)
				no.visible = false
			else:
				no.visible = bool(no.get_meta("estava_visivel", true))


func _pontos(partida: Node, a: int, b: int) -> void:
	partida.placar.pontos[0] = a
	partida.placar.pontos[1] = b
	partida._atualizar_placar()


func _ponto(partida: Node, time: int) -> void:
	partida.estado = partida.Estado.RALLY
	partida._encerrar_rally(time, "dentro")


func _abrir(caminho: String) -> Node:
	_fechar_atual()
	_atual = load(caminho).instantiate()
	root.add_child(_atual)
	current_scene = _atual
	return _atual


func _fechar_atual() -> void:
	if _atual != null and is_instance_valid(_atual):
		root.remove_child(_atual)
		_atual.free()
	_atual = null


func _esperar(segundos: float) -> void:
	await create_timer(segundos).timeout
	# Mais um quadro pra garantir que a tela desenhou o estado final.
	await process_frame
	await process_frame


## "recorte" = salva também só a parte de cima do meio (onde fica o placar).
func _salvar(nome: String, recorte := false) -> void:
	var imagem := root.get_texture().get_image()
	var arquivo := "%s/%s_%dx%d.png" % [_saida, nome, imagem.get_width(), imagem.get_height()]
	imagem.save_png(ProjectSettings.globalize_path(arquivo))
	print("Salvo: %s" % arquivo)
	if recorte:
		var w := imagem.get_width()
		var h := imagem.get_height()
		var parte := imagem.get_region(Rect2i(int(w * 0.18), 0, int(w * 0.64), int(h * 0.2)))
		var arquivo_do_recorte := "%s/%s_recorte_%dx%d.png" % [_saida, nome, w, h]
		parte.save_png(ProjectSettings.globalize_path(arquivo_do_recorte))
