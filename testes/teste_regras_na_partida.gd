extends SceneTree
## Testes das regras dentro da partida de verdade (cena partida.tscn):
## escalação, posição no saque, tempo de saque, faltas de toque, rede e antena.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_regras_na_partida.gd
##
## Usa _initialize e espera o 1º quadro (e não _init) porque a partida
## precisa dos autoloads e da árvore pronta.

const Formacao := preload("res://scripts/regras/formacao.gd")
const Escalacao := preload("res://scripts/regras/escalacao.gd")
const Dados := preload("res://scripts/comum/dados.gd")

var falhas := 0
## Carregada só no _initialize: a cena usa autoloads, que não existem antes.
var cena: PackedScene


func _initialize() -> void:
	cena = load("res://cenas/partida.tscn")
	# Roda no 1º quadro, quando a árvore já está pronta (_ready funciona).
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	_teste_escalacao_e_formacao_no_saque()
	_teste_fora_de_posicao_no_saque()
	_teste_oito_segundos_pra_sacar()
	_teste_quem_sacou_nao_toca_no_saque()
	_teste_bloqueio_no_saque()
	_teste_ataque_no_saque()
	_teste_dois_toques()
	_teste_ataque_do_fundo()
	_teste_ataque_do_fundo_atras_da_linha_vale()
	_teste_toque_na_rede_no_bloqueio()
	_teste_fora_da_antena()
	_teste_bloqueio_nao_conta_como_toque()
	_teste_quem_vai_na_bola()
	_teste_bola_que_volta_da_rede_vai_pra_outro()
	_teste_novo_set_volta_a_escalacao()

	if falhas == 0:
		print("OK: todos os testes das regras na partida passaram.")
	else:
		print("FALHOU: %d verificação(ões) das regras na partida." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


## Partida nova, com o time 0 sacando.
func _nova_partida() -> Node:
	var partida = cena.instantiate()
	root.add_child(partida)
	partida.placar.quem_saca = 0
	partida._preparar_saque()
	return partida


func _fechar(partida: Node) -> void:
	root.remove_child(partida)
	partida.free()


func _ponto_por(partida: Node, motivo: String) -> bool:
	return partida.estado == partida.Estado.PONTO \
		and partida.rotulo_mensagem.text.contains("(%s)" % motivo)


func _pontos(partida: Node) -> Array:
	return [partida.placar.pontos[0], partida.placar.pontos[1]]


## Começa um rally com a bola em jogo, sem saque no ar.
func _rally(partida: Node) -> void:
	partida.estado = partida.Estado.RALLY
	partida.saque_em_jogo = false
	partida.toques.reiniciar()
	partida.bola.em_voo = true


## Atleta do "time" na "posicao" do rodízio.
func _na_posicao(partida: Node, time: int, posicao: int) -> Node3D:
	return partida.atletas[time][partida.rodizios[time].atleta_na(posicao)]


## Põe o atleta e a bola num lugar (coordenadas do time) e dá o controle pra ele.
func _preparar_toque(partida: Node, time: int, atleta: Node3D, lugar: Vector2, altura_da_bola: float) -> void:
	atleta.position = partida._no_mundo(time, lugar)
	partida.controlados[time] = atleta
	partida.bola.position = atleta.position + Vector3(0.0, altura_da_bola, 0.0)


func _teste_escalacao_e_formacao_no_saque() -> void:
	var partida = _nova_partida()
	for time in 2:
		var elenco := Dados.elenco(partida.times_em_jogo[time]["id"])
		var levantador: int = partida.levantadores[time]
		if elenco.size() >= 6:
			_verificar(Escalacao.funcao_de(elenco[levantador]) == "levantador",
				"time %d: o levantador da escalação é o do elenco" % time)
		_verificar(partida.rodizios[time].posicao_de(levantador) == 1, "time %d: levantador começa na 1" % time)
		var ignorar := 1 if time == partida.placar.quem_saca else 0
		var faltas: Array = Formacao.faltas(partida._lugares_do_time(time), ignorar)
		_verificar(faltas.is_empty(), "time %d começa na ordem do rodízio: %s" % [time, faltas])
	_fechar(partida)


func _teste_fora_de_posicao_no_saque() -> void:
	var partida = _nova_partida()
	# O do meio da rede (3) de quem recebe vai pra trás do meio do fundo (6).
	var meio_da_rede := _na_posicao(partida, 1, 3)
	meio_da_rede.position = partida._no_mundo(1, Vector2(0.0, 8.0))
	partida._sacar(0, false)
	_verificar(_ponto_por(partida, "posição errada no saque"), "fora de posição no saque é falta")
	_verificar(_pontos(partida) == [1, 0], "o ponto é de quem sacou")
	_fechar(partida)


func _teste_oito_segundos_pra_sacar() -> void:
	var partida = _nova_partida()
	partida._contar_tempo_do_saque(7.5)
	_verificar(partida.estado == partida.Estado.SAQUE, "com 7,5 s ainda pode sacar")
	partida._contar_tempo_do_saque(0.6)
	_verificar(_ponto_por(partida, "demorou pra sacar"), "passou de 8 s é falta")
	_verificar(_pontos(partida) == [0, 1], "o ponto é de quem recebe")
	_fechar(partida)


func _teste_quem_sacou_nao_toca_no_saque() -> void:
	var partida = _nova_partida()
	partida._sacar(0, false)
	var sacador: Node3D = partida.controlados[0]
	partida.bola.position = sacador.position + Vector3(0.0, 1.0, 0.0)
	partida._tentar_tocar(0, false)
	_verificar(partida.estado == partida.Estado.RALLY, "o toque de quem sacou é ignorado")
	_verificar(partida.toques.toques == 1 and partida.toques.time_com_a_bola == 0, "não contou toque")
	_fechar(partida)


func _teste_bloqueio_no_saque() -> void:
	var partida = _nova_partida()
	partida._sacar(0, false)
	partida._ao_bola_ser_bloqueada()
	_verificar(_ponto_por(partida, "bloqueio no saque"), "bloquear o saque é falta")
	_verificar(_pontos(partida) == [1, 0], "o ponto é de quem sacou")
	_fechar(partida)


func _teste_ataque_no_saque() -> void:
	var partida = _nova_partida()
	partida._sacar(0, false)
	# Quem recebe ataca o saque com a bola acima da rede, perto dela.
	_preparar_toque(partida, 1, _na_posicao(partida, 1, 3), Vector2(0.0, 1.5), 3.0)
	partida._tentar_tocar(1, true)
	_verificar(_ponto_por(partida, "ataque no saque"), "atacar o saque acima da rede é falta")
	_fechar(partida)


func _teste_dois_toques() -> void:
	var partida = _nova_partida()
	_rally(partida)
	partida.ultimo_toque = 0
	var atleta := _na_posicao(partida, 0, 6)
	partida.toques.registrar(0, partida.atletas[0].find(atleta))
	_preparar_toque(partida, 0, atleta, Vector2(0.0, 5.0), 1.0)
	partida._tentar_tocar(0, false)
	_verificar(_ponto_por(partida, "dois toques"), "o mesmo atleta tocar duas vezes seguidas é falta")
	_verificar(_pontos(partida) == [0, 1], "o ponto é do outro time")
	_fechar(partida)


func _teste_ataque_do_fundo() -> void:
	var partida = _nova_partida()
	_rally(partida)
	_preparar_toque(partida, 0, _na_posicao(partida, 0, 6), Vector2(0.0, 1.5), 3.0)
	partida._tentar_tocar(0, true)
	_verificar(_ponto_por(partida, "ataque do fundo"), "do fundo, atacar na frente da linha de 3 m é falta")
	_fechar(partida)


func _teste_ataque_do_fundo_atras_da_linha_vale() -> void:
	var partida = _nova_partida()
	_rally(partida)
	_preparar_toque(partida, 0, _na_posicao(partida, 0, 6), Vector2(0.0, 4.0), 3.0)
	partida._tentar_tocar(0, true)
	_verificar(partida.estado == partida.Estado.RALLY, "do fundo, atacar atrás da linha de 3 m vale")
	_verificar(partida.toques.time_com_a_bola == 0 and partida.toques.toques == 1, "contou o toque")
	_fechar(partida)


func _teste_toque_na_rede_no_bloqueio() -> void:
	var partida = _nova_partida()
	_rally(partida)
	var atleta := _na_posicao(partida, 0, 3)
	atleta.position = partida._no_mundo(0, Vector2(0.0, 0.45))
	partida._bloquear(0)
	_verificar(_ponto_por(partida, "toque na rede"), "pular colado na rede é toque na rede")
	_verificar(_pontos(partida) == [0, 1], "o ponto é do outro time")
	_fechar(partida)


func _teste_fora_da_antena() -> void:
	var partida = _nova_partida()
	_rally(partida)
	partida.ultimo_toque = 0
	partida._ao_bola_cruzar_a_rede(Vector3(0.0, 3.0, 0.0))
	_verificar(partida.estado == partida.Estado.RALLY, "entre as antenas vale")
	partida._ao_bola_cruzar_a_rede(Vector3(5.0, 3.0, 0.0))
	_verificar(_ponto_por(partida, "fora da antena"), "por fora da antena é falta")
	_verificar(_pontos(partida) == [0, 1], "o ponto é de quem não tocou por último")
	_fechar(partida)


func _teste_bloqueio_nao_conta_como_toque() -> void:
	var partida = _nova_partida()
	_rally(partida)
	partida.ultimo_toque = 1
	for atleta in [0, 1, 2]:
		partida.toques.registrar(1, atleta)
	partida._ao_bola_ser_bloqueada()
	_verificar(partida.estado == partida.Estado.RALLY, "bloqueio normal não encerra o rally")
	_verificar(partida.toques.time_com_a_bola == 0 and partida.toques.toques == 0,
		"depois do bloqueio, o time 0 ainda tem 3 toques")
	_fechar(partida)


func _teste_quem_vai_na_bola() -> void:
	var partida = _nova_partida()
	_rally(partida)
	var levantador: Node3D = partida.atletas[0][partida.levantadores[0]]
	var passador := _na_posicao(partida, 0, 6)
	if passador == levantador:
		passador = _na_posicao(partida, 0, 5)

	# 1º toque: o passe vai pro levantador.
	partida.ultimo_toque = 0
	partida.controlados[0] = passador
	partida.toques.registrar(0, partida.atletas[0].find(passador))
	var escolhido: Node3D = partida._quem_vai_na_bola(0, partida._no_mundo(0, Vector2(1.0, 1.0)))
	_verificar(escolhido == levantador, "o 2º toque é do levantador")

	# 2º toque: levantamento na ponta vai pra alguém da rede; no fundo, pra alguém do fundo.
	partida.controlados[0] = levantador
	partida.toques.registrar(0, partida.levantadores[0])
	var na_ponta: Node3D = partida._quem_vai_na_bola(0, partida._no_mundo(0, Vector2(-3.5, 1.2)))
	_verificar(partida._e_da_rede(0, na_ponta) and na_ponta != levantador, "ataque na ponta é de quem está na rede")
	var no_fundo: Node3D = partida._quem_vai_na_bola(0, partida._no_mundo(0, Vector2(0.0, 4.0)))
	_verificar(not partida._e_da_rede(0, no_fundo) and no_fundo != levantador, "ataque de fundo é de quem está no fundo")
	_fechar(partida)


func _teste_bola_que_volta_da_rede_vai_pra_outro() -> void:
	var partida = _nova_partida()
	_rally(partida)
	# O atacante do time 0 bate na rede e a bola volta pro lado dele.
	var atacante := _na_posicao(partida, 0, 4)
	partida.ultimo_toque = 0
	partida.controlados[0] = atacante
	partida.toques.registrar(0, partida.atletas[0].find(atacante))
	partida.bola.ponto_previsto = partida._no_mundo(0, Vector2(-3.0, 0.5))
	partida.bola.tocou_rede.emit()
	_verificar(partida.controlados[0] != atacante, "depois da rede, o controle vai pra outro atleta")
	_fechar(partida)


func _teste_novo_set_volta_a_escalacao() -> void:
	var partida = _nova_partida()
	var comeco: Array = partida.rodizios[0].posicoes.duplicate()
	partida.rodizios[0].girar()
	partida.rodizios[0].girar()
	partida._ao_encerrar_set(0)
	_verificar(partida.rodizios[0].posicoes == comeco, "cada set começa com a escalação do começo")
	_fechar(partida)
