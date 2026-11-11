extends SceneTree
## Testes da TELA de escolha de cartas do Modo Caos (a regra fica em
## teste_cartas.gd e o fluxo na partida em teste_cartas_na_partida.gd).
## Abre a tela sozinha e aperta os botões dos dois jogadores: raridades
## diferentes, cursor, confirmar, botões cedo demais, tempo acabando.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_tela_de_cartas.gd

const EscolhaDeCartas := preload("res://scripts/partida/escolha_de_cartas.gd")
const Cartas := preload("res://scripts/regras/cartas.gd")
const Dados := preload("res://scripts/comum/dados.gd")

var falhas := 0
var _resultado: Array = []


func _initialize() -> void:
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	await _teste_raridades_e_escolha()
	await _teste_tempo_acaba()

	if falhas == 0:
		print("OK: todos os testes da tela de cartas passaram.")
	else:
		print("FALHOU: %d verificação(ões) da tela de cartas." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _apertar(acao: String) -> void:
	Input.action_press(acao)
	await process_frame
	Input.action_release(acao)
	await process_frame


func _esperar(segundos: float) -> void:
	await create_timer(segundos).timeout
	await process_frame


func _nova_tela(tempo: float) -> Node:
	var dados := Dados.cartas()
	var opcoes := []
	for lista in [["maos_firmes", "muro", "troca_de_lugar"], ["saque_firme", "ataque_rapido", "troca_de_lugar"]]:
		var cartas := []
		for id in lista:
			cartas.append(Cartas.por_id(dados, id))
		opcoes.append(cartas)
	var tela = EscolhaDeCartas.new()
	root.add_child(tela)
	tela.configurar(opcoes, ["Karasuno", "Nekoma"], [Color("#F28C28"), Color("#D3343B")],
		[[], []], [[], []], tempo, ["karasuno", "nekoma"])
	_resultado = []
	tela.terminou.connect(func(escolhas: Array) -> void: _resultado = escolhas)
	return tela


func _teste_raridades_e_escolha() -> void:
	var tela = _nova_tela(60.0)
	var cartas: Array = tela._quadros[0]
	_verificar(cartas.size() == 3 and tela._quadros[1].size() == 3, "3 cartas pra cada jogador")
	_verificar(cartas[0].raridade == "prata" and cartas[1].raridade == "ouro" and cartas[2].raridade == "prismatica",
		"raridades vêm dos dados (prata, ouro, prismatica)")
	var cores := [cartas[0].cor_da_raridade(), cartas[1].cor_da_raridade(), cartas[2].cor_da_raridade()]
	_verificar(cores[0] != cores[1] and cores[1] != cores[2] and cores[0] != cores[2], "cada raridade tem uma cor")
	_verificar(cartas[0].ESPESSURA_DA_MOLDURA["prata"] < cartas[1].ESPESSURA_DA_MOLDURA["ouro"], "moldura de ouro é mais grossa que a de prata")
	_verificar(not cartas[2]._facetas.is_empty() and cartas[0]._facetas.is_empty(), "só a prismática tem facetas")
	_verificar(tela._relogio.text == "1:00", "cronômetro começa em 1:00 (%s)" % tela._relogio.text)
	_verificar(cartas[0].escolhida and not cartas[1].escolhida, "cursor começa na 1ª carta")

	# Botão apertado logo que a tela abre não conta (é do ponto que acabou).
	await _apertar("p1_direita")
	_verificar(tela._indice[0] == 0, "botão cedo demais não move o cursor")
	await _esperar(EscolhaDeCartas.ATRASO_DAS_TECLAS)

	await _apertar("p1_direita")
	_verificar(tela._indice[0] == 1 and cartas[1].escolhida and not cartas[0].escolhida, "J1 move pra 2ª carta")
	_verificar(tela._indice[1] == 0, "J2 não mexeu")
	await _apertar("p1_passe")
	_verificar(tela._pronto[0], "J1 confirmou com Passe")
	_verificar(cartas[1].confirmada and cartas[1]._selo.visible, "carta do J1 com selo ESCOLHIDA")
	_verificar(cartas[0].apagada and cartas[2].apagada, "as outras cartas do J1 apagam")
	_verificar(tela._avisos[0].text == "PRONTO!", "PRONTO! do J1")
	await _apertar("p1_direita")
	_verificar(tela._indice[0] == 1, "depois de confirmar, o cursor do J1 não mexe")
	_verificar(_resultado.is_empty(), "ainda espera o J2")

	await _apertar("p2_esquerda")
	_verificar(tela._indice[1] == 2, "J2 dá a volta pra última carta")
	await _apertar("p2_ataque")
	_verificar(tela._pronto[1], "J2 confirmou com Ataque")
	await _esperar(EscolhaDeCartas.PAUSA_DO_FIM + 0.1)
	_verificar(_resultado == ["muro", "troca_de_lugar"], "terminou com as cartas escolhidas (%s)" % [_resultado])


func _teste_tempo_acaba() -> void:
	var tela = _nova_tela(11.0)
	await _esperar(1.2)
	_verificar(tela._relogio.text == "0:10", "cronômetro em 0:10 (%s)" % tela._relogio.text)
	_verificar(tela._relogio.get_theme_color("font_color") != EscolhaDeCartas.Estilo.TEXTO, "nos últimos segundos o cronômetro muda de cor")
	tela._tempo = 0.05
	await _esperar(EscolhaDeCartas.PAUSA_DO_FIM + 0.2)
	_verificar(_resultado.size() == 2, "tempo acabou: os dois ganham carta sorteada")
	if _resultado.size() == 2:
		var ids_j1 := ["maos_firmes", "muro", "troca_de_lugar"]
		var ids_j2 := ["saque_firme", "ataque_rapido", "troca_de_lugar"]
		_verificar(ids_j1.has(_resultado[0]) and ids_j2.has(_resultado[1]), "cartas sorteadas são das opções de cada um")
