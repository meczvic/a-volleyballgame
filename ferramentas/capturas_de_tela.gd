extends SceneTree
## Tira prints das telas do jogo, sempre no mesmo estado, pra comparar o
## visual antes e depois de uma mudança. Precisa de janela (não use --headless).
##
##   godot --path . --resolution 1600x900 --script res://ferramentas/capturas_de_tela.gd -- saida=producao/baseline
##   godot --path . --resolution 1280x720 --script res://ferramentas/capturas_de_tela.gd -- saida=producao/baseline telas=selecao
##
## Opções:
##   saida=<pasta>      onde salvar (padrão producao/telas)
##   telas=<lista>      menu, selecao, partida, cartas (padrão: todas)
##   times=<id1>,<id2>  padrão karasuno,nekoma
##   estadio=<id>       padrão ginasio_japones
##
## Cada arquivo sai como <tela>_<largura>x<altura>.png. Telas salvas:
##   menu             menu principal
##   selecao_inicio   seleção com os cursores nos dois times, ninguém confirmou
##   selecao_estadio  os dois confirmaram, escolhendo o estádio
##   partida_saque    partida parada esperando o saque (placar zerado)
##   cartas           Modo Caos: escolha de cartas do começo da partida
##
## Pra partida em movimento, use o robô: ferramentas/robo.gd com prints=<pasta>.

const CENA_MENU := "res://cenas/menu_principal.tscn"
const CENA_SELECAO := "res://cenas/selecao_de_times.tscn"
const CENA_PARTIDA := "res://cenas/partida.tscn"
const TODAS := ["menu", "selecao", "partida", "cartas"]
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
		"cartas":
			configuracao.modo = "caos"
			_abrir(CENA_PARTIDA)
			await _esperar(ESPERA)
			_salvar("cartas")
			configuracao.modo = "rapida"
		_:
			print("Tela desconhecida: %s (use %s)" % [tela, ", ".join(TODAS)])


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


func _salvar(nome: String) -> void:
	var imagem := root.get_texture().get_image()
	var arquivo := "%s/%s_%dx%d.png" % [_saida, nome, imagem.get_width(), imagem.get_height()]
	imagem.save_png(ProjectSettings.globalize_path(arquivo))
	print("Salvo: %s" % arquivo)
