extends SceneTree
## Testes do computador adversário (modo 1 jogador, Etapa 2 do plano de
## jogabilidade):
## - dados/dificuldades.json tem Fácil, Normal e Difícil com todos os números;
## - contra o computador a tela não se divide e o Jogador 2 é o computador;
## - o computador joga partidas de verdade nos três níveis (computador contra
##   computador, num Godot separado com o robô só assistindo), sem erro de
##   script, e no Difícil o rally é mais longo que no Fácil.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_computador.gd

const EntradaDoComputador := preload("res://scripts/entrada/entrada_do_computador.gd")
const NIVEIS := ["facil", "normal", "dificil"]
## Cada partida de teste: times, semente e tempo (s) de jogo.
const ARGUMENTOS_DO_ROBO := ["times=brasil,karasuno", "estadio=ginasio_japones", "segundos=90", "dois=1"]
## Sementes de cada nível. Uma semente só dá uns 5 rallies e o resultado balança;
## o Fácil e o Difícil são comparados pela média de três.
const SEMENTES := {"facil": [7, 11, 22], "normal": [7], "dificil": [7, 11, 22]}

var falhas := 0


func _initialize() -> void:
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	_teste_niveis_no_arquivo()
	await _teste_partida_contra_o_computador()
	_teste_partidas_nos_tres_niveis()

	if falhas == 0:
		print("OK: todos os testes do computador passaram.")
	else:
		print("FALHOU: %d verificação(ões) do computador." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _teste_niveis_no_arquivo() -> void:
	var niveis := EntradaDoComputador.niveis()
	var ids: Array = []
	for nivel in niveis:
		ids.append(str(nivel.get("id", "")))
		for chave in EntradaDoComputador.PADRAO:
			_verificar(nivel.has(chave), "o nível %s tem \"%s\"" % [nivel.get("id", "?"), chave])
		for chave in nivel:
			if str(chave).begins_with("chance_") or chave == "esperteza":
				var valor := float(nivel[chave])
				_verificar(valor >= 0.0 and valor <= 1.0, "%s.%s fica entre 0 e 1 (%s)" % [nivel.get("id", "?"), chave, valor])
	_verificar(ids == NIVEIS, "os níveis são Fácil, Normal e Difícil, nessa ordem (%s)" % [ids])
	# Do Fácil pro Difícil: erra menos, reage mais rápido, acerta mais o tempo.
	var facil := EntradaDoComputador.ajustes_do_nivel("facil")
	var dificil := EntradaDoComputador.ajustes_do_nivel("dificil")
	_verificar(float(dificil["chance_de_errar"]) < float(facil["chance_de_errar"]), "o Difícil erra menos que o Fácil")
	_verificar(float(dificil["reacao"]) < float(facil["reacao"]), "o Difícil reage mais rápido que o Fácil")
	_verificar(float(dificil["erro_do_tempo"]) < float(facil["erro_do_tempo"]), "o Difícil acerta mais o tempo do botão")
	_verificar(float(dificil["esperteza"]) > float(facil["esperteza"]), "o Difícil mira mais no buraco")
	# Nível que não existe: usa o Normal (PADRAO), sem quebrar.
	var outro := EntradaDoComputador.ajustes_do_nivel("nao_existe")
	_verificar(str(outro["id"]) == "normal", "nível desconhecido vira o Normal")


func _teste_partida_contra_o_computador() -> void:
	var configuracao := root.get_node("Configuracao")
	configuracao.contra_computador = true
	configuracao.dificuldade = "dificil"
	var partida = load("res://cenas/partida.tscn").instantiate()
	root.add_child(partida)
	await process_frame
	_verificar(not partida.tela_dividida, "contra o computador a tela não se divide")
	_verificar(partida.cameras.size() == 1, "uma câmera só (%d)" % partida.cameras.size())
	_verificar(partida.entradas[1] is EntradaDoComputador, "o Jogador 2 é o computador")
	_verificar(not (partida.entradas[0] is EntradaDoComputador), "o Jogador 1 continua sendo gente")
	_verificar(str(partida.entradas[1].ajustes["id"]) == "dificil", "o computador usa a dificuldade escolhida")
	# O computador saca sozinho: com ele sacando, em poucos segundos a bola está em jogo.
	partida.placar.quem_saca = 1
	partida._preparar_saque()
	var sacou := false
	for i in 60 * 5:
		await physics_frame
		if partida.estado != partida.Estado.SAQUE:
			sacou = true
			break
	_verificar(sacou, "o computador sacou sozinho")
	root.remove_child(partida)
	partida.free()
	configuracao.contra_computador = false
	configuracao.dificuldade = "normal"


## Computador contra computador nos três níveis (num Godot separado, com
## --fixed-fps 60 e semente fixa: sai igual toda vez).
func _teste_partidas_nos_tres_niveis() -> void:
	var medias := {}
	for nivel in NIVEIS:
		var soma := 0.0
		var partidas := 0
		for semente in SEMENTES[nivel]:
			var resumo := _rodar_o_robo(nivel, int(semente))
			_verificar(resumo.has("rallies"), "%s (semente %d): o robô terminou e imprimiu o resumo" % [nivel, semente])
			if not resumo.has("rallies"):
				continue
			print("  %s (semente %d): %d rallies, média de %.1f bolas por rally" % [nivel, semente, resumo["rallies"], resumo.get("media", 0.0)])
			_verificar(int(resumo["rallies"]) >= 2, "%s (semente %d): teve pontos (%d rallies)" % [nivel, semente, resumo["rallies"]])
			soma += float(resumo.get("media", 0.0))
			partidas += 1
		if partidas > 0:
			medias[nivel] = soma / partidas
	if medias.has("facil") and medias.has("dificil"):
		_verificar(medias["dificil"] > medias["facil"],
			"no Difícil o rally é mais longo que no Fácil (%.1f x %.1f)" % [medias["dificil"], medias["facil"]])


## Roda o robô com o computador nos dois times e lê o resumo.
func _rodar_o_robo(nivel: String, semente: int) -> Dictionary:
	var argumentos: Array[String] = ["--headless", "--fixed-fps", "60",
		"--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://ferramentas/robo.gd", "--", "computador=" + nivel]
	argumentos.append_array(ARGUMENTOS_DO_ROBO)
	argumentos.append("semente=%d" % semente)
	var saida: Array = []
	var codigo := OS.execute(OS.get_executable_path(), argumentos, saida, true)
	_verificar(codigo == 0, "%s (semente %d): o robô saiu com código %d" % [nivel, semente, codigo])
	var resumo := {}
	for linha in "\n".join(saida).split("\n"):
		var limpa := linha.strip_edges()
		if limpa.contains("SCRIPT ERROR"):
			_verificar(false, "%s: erro de script: %s" % [nivel, limpa])
		var rallies := limpa.find(" rallies (maior")
		if rallies > 0:
			resumo["rallies"] = int(limpa.substr(limpa.rfind(" ", rallies - 1) + 1, rallies - limpa.rfind(" ", rallies - 1) - 1))
		if limpa.contains("media de bolas por rally"):
			resumo["media"] = float(limpa.substr(limpa.rfind(" ") + 1))
	return resumo
