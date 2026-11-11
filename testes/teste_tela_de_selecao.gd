extends SceneTree
## Testes da TELA de seleção de times (a lógica pura fica em teste_selecao.gd).
## Abre a cena de verdade e aperta os botões dos dois jogadores, como uma pessoa:
## mover, confirmar, desfazer, mesmo time (uniforme reserva), estádio e começar.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_tela_de_selecao.gd

const Dados := preload("res://scripts/comum/dados.gd")
const Selecao := preload("res://scripts/menus/selecao.gd")

var falhas := 0
var tela: Control


func _initialize() -> void:
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	var configuracao := root.get_node("Configuracao")
	configuracao.times = ["karasuno", "nekoma"]
	configuracao.estadio = "ginasio_japones"
	configuracao.modo = "rapida"
	tela = load("res://cenas/selecao_de_times.tscn").instantiate()
	root.add_child(tela)
	await process_frame

	_teste_arte_existe()
	_teste_comeco()
	await _teste_mover_os_dois()
	await _teste_mesmo_time_usa_reserva()
	await _teste_confirmar_e_desfazer()
	await _teste_estadio_e_comecar()
	root.remove_child(tela)
	tela.free()

	if falhas == 0:
		print("OK: todos os testes da tela de seleção passaram.")
	else:
		print("FALHOU: %d verificação(ões) da tela de seleção." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


## Aperta e solta uma ação (ex.: "p1_direita"), um quadro de cada vez.
func _apertar(acao: String) -> void:
	Input.action_press(acao)
	await process_frame
	Input.action_release(acao)
	await process_frame


func _painel(jogador: int):
	return tela._paineis[jogador]


func _teste_arte_existe() -> void:
	for time in Dados.times():
		var id := str(time["id"])
		_verificar(ResourceLoader.exists("res://arte/emblemas/%s.svg" % id), "emblema de %s existe" % id)
		_verificar(not Dados.atleta_destaque(time).is_empty(), "%s tem atleta destaque" % id)
	for atributo in tela.ATRIBUTOS:
		_verificar(ResourceLoader.exists("res://arte/icones/%s.svg" % atributo[2]), "ícone de %s existe" % atributo[0])
	_verificar(tela._cartoes.size() == Dados.times().size(), "um cartão por time")


func _teste_comeco() -> void:
	_verificar(tela.selecao.cursor[0] == 0 and tela.selecao.cursor[1] == 3, "começa em Karasuno x Nekoma")
	_verificar(_painel(0).nome.text == "KARASUNO", "nome do Jogador 1")
	_verificar(_painel(1).nome.text == "NEKOMA", "nome do Jogador 2")
	_verificar(_painel(0).emblema.texture != null and _painel(1).emblema.texture != null, "emblemas aparecem")
	_verificar(_painel(0).valores[0].text == "4/5", "ataque do Karasuno é 4/5")
	_verificar(_painel(0).retrato_3d.visible, "retrato 3D aparece sem arte 2D")
	_verificar(_painel(0).retrato_3d.animacao_atual() == "parado", "atleta parado enquanto escolhe")
	_verificar(_painel(1).status.text == "ESCOLHENDO...", "ninguém confirmou ainda")
	_verificar(tela._fichas[0][0].visible and tela._fichas[1][3].visible, "fichas J1 e J2 nos cartões certos")


func _teste_mover_os_dois() -> void:
	await _apertar("p1_direita")
	_verificar(tela.selecao.cursor[0] == 1, "J1 foi pro Aoba Johsai")
	_verificar(_painel(0).nome.text == "AOBA JOHSAI", "painel do J1 mudou")
	_verificar(tela.selecao.cursor[1] == 3, "J2 não mexeu")
	await _apertar("p2_direita")
	_verificar(tela.selecao.cursor[1] == 4, "J2 foi pro Fukurodani")
	await _apertar("p1_esquerda")
	await _apertar("p1_esquerda")
	_verificar(tela.selecao.cursor[0] == Dados.times().size() - 1, "J1 dá a volta pro último time")
	await _apertar("p1_direita")
	_verificar(tela.selecao.cursor[0] == 0, "J1 volta pro Karasuno")


func _teste_mesmo_time_usa_reserva() -> void:
	for i in 4:
		await _apertar("p2_esquerda")
	_verificar(tela.selecao.cursor[1] == 0, "J2 também no Karasuno")
	var karasuno := Dados.por_id(Dados.times(), "karasuno")
	var cores_do_j2: Array = tela._time_em_jogo(1)["cores"]
	_verificar(cores_do_j2[0] == karasuno["cores"][2], "J2 com o mesmo time usa o uniforme reserva no retrato")
	_verificar(tela._time_em_jogo(0)["cores"][0] == karasuno["cores"][0], "J1 continua com o uniforme titular")


func _teste_confirmar_e_desfazer() -> void:
	await _apertar("p1_passe")
	_verificar(tela.selecao.confirmado[0], "J1 confirmou")
	_verificar(_painel(0).status.text == "PRONTO!", "aparece PRONTO! pro J1")
	_verificar(_painel(0).retrato_3d.esta_comemorando(), "atleta do J1 comemora")
	_verificar(tela._instrucao.text == "ESPERANDO O JOGADOR 2 CONFIRMAR", "instrução espera o J2")
	await _apertar("p1_direita")
	_verificar(tela.selecao.cursor[0] == 0, "quem confirmou não mexe o cursor")
	await _apertar("p1_mergulho")
	_verificar(not tela.selecao.confirmado[0], "J1 desfez")
	_verificar(not _painel(0).retrato_3d.esta_comemorando(), "atleta do J1 para de comemorar")
	_verificar(_painel(0).status.text == "ESCOLHENDO...", "volta pra ESCOLHENDO...")


func _teste_estadio_e_comecar() -> void:
	await _apertar("p1_passe")
	await _apertar("p2_passe")
	_verificar(tela.selecao.fase == Selecao.Fase.ESTADIO, "os dois confirmaram: escolhe o estádio")
	_verificar(tela._dica_do_estadio.text.begins_with("Esquerda"), "faixa do estádio pede a escolha")
	await _apertar("p2_direita")
	_verificar(tela._nome_do_estadio.text == "ARENA NACIONAL", "J2 também troca o estádio")
	await _apertar("p1_passe")
	_verificar(tela.selecao.fase == Selecao.Fase.COMECANDO, "confirmou o estádio: começa")
	var configuracao := root.get_node("Configuracao")
	_verificar(configuracao.times == ["karasuno", "karasuno"], "partida com os times escolhidos")
	_verificar(configuracao.estadio == "arena_nacional", "partida no estádio escolhido")
	_verificar(tela._saindo, "a tela começa a sair pra partida")
