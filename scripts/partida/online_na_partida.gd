extends RefCounted
## O que a partida faz de diferente no online (Fase E do plano de melhorias).
##
## Dono: simula tudo como sempre; o time 2 é jogado pela EntradaPelaRede, e a
## cada 2 quadros manda uma "foto" (posições, placar, estado) pro convidado,
## além dos lances, sons e mensagens na hora que acontecem.
## Convidado: não simula nada (física da partida e da bola desligadas). Lê o
## teclado/controle do jogador dele e manda pro dono; mostra o que chega.
##
## "p" é a partida. Fora do online este módulo não faz nada.

const EntradaLocal := preload("res://scripts/entrada/entrada_local.gd")

## A cada quantos quadros o dono manda a foto (2 = 30 por segundo).
const QUADROS_POR_FOTO := 2

var p
var rede: Node
var _quadros := 0


func _init(partida) -> void:
	p = partida


func dono() -> bool:
	return rede != null and rede.e_dono()


func convidado() -> bool:
	return rede != null and rede.e_convidado()


## Chamado no _ready da partida, depois de tudo montado.
func preparar() -> void:
	rede = p.get_node_or_null("/root/Rede")
	if rede == null or not rede.online():
		rede = null
		return
	if dono():
		p.sons.tocou.connect(func(nome: String, intensidade: float) -> void:
			rede.enviar_evento("som", [nome, intensidade]))
		p.interface.mensagem_mostrada.connect(func(texto: String, time: int, fixa: bool) -> void:
			rede.enviar_evento("mensagem", [texto, time, fixa]))
		p.interface.faixa.mostrou.connect(func(titulo: String, subtitulo: String, _cor: Color, time: int) -> void:
			rede.enviar_evento("faixa", [titulo, subtitulo, time]))
		p.placar.ponto_marcado.connect(func(time: int) -> void: rede.enviar_evento("ponto", [time]))
		p.placar.partida_encerrada.connect(func(time: int) -> void: rede.enviar_evento("fim", [time]))
	else:
		# O convidado só mostra: quem simula é o dono.
		p.set_physics_process(false)
		p.bola.set_physics_process(false)
		for entrada in p.entradas:
			entrada.set_physics_process(false)
		var envio := Envio.new()
		envio.name = "EnvioDoConvidado"
		envio.rede = rede
		p.add_child(envio)
		rede.foto_chegou.connect(aplicar_foto)
		rede.evento_chegou.connect(aplicar_evento)


## No fim de cada quadro do dono.
func depois_do_quadro() -> void:
	if not dono():
		return
	_quadros += 1
	if _quadros % QUADROS_POR_FOTO == 0:
		rede.enviar_foto(foto())


## Lance de um atleta (o dono avisa o convidado).
func ao_animar(atleta: Node3D, lance: String) -> void:
	if dono():
		var lugar := _lugar_do_atleta(atleta)
		if lugar.x >= 0:
			rede.enviar_evento("animar", [lugar.x, lugar.y, lance])


func ao_mergulhar(atleta: Node3D, rumo: Vector2) -> void:
	if dono():
		var lugar := _lugar_do_atleta(atleta)
		if lugar.x >= 0:
			rede.enviar_evento("mergulho", [lugar.x, lugar.y, rumo])


## Time e índice do atleta (-1 se não achou).
func _lugar_do_atleta(atleta: Node3D) -> Vector2i:
	for time in 2:
		var i: int = p.atletas[time].find(atleta)
		if i >= 0:
			return Vector2i(time, i)
	return Vector2i(-1, -1)


## Tudo que o convidado precisa pra desenhar a partida neste quadro.
func foto() -> Dictionary:
	var posicoes := PackedVector3Array()
	for time in 2:
		for atleta in p.atletas[time]:
			posicoes.append(atleta.position)
	var controlados := PackedInt32Array()
	for time in 2:
		controlados.append(p.atletas[time].find(p.controlados[time]))
	return {
		"q": Engine.get_physics_frames(),
		"b": p.bola.position,
		"a": posicoes,
		"c": controlados,
		"m": p.marcador.position if p.marcador.visible else null,
		"e": int(p.estado),
		"pt": p.placar.pontos.duplicate(),
		"st": p.placar.sets.duplicate(),
		"sa": p.placar.set_atual,
		"qs": p.placar.quem_saca,
	}


## Convidado: põe a partida do jeito que o dono mandou.
func aplicar_foto(foto: Dictionary) -> void:
	var posicoes: PackedVector3Array = foto["a"]
	var k := 0
	for time in 2:
		for atleta in p.atletas[time]:
			if k < posicoes.size():
				atleta.position = posicoes[k]
			k += 1
	p.bola.position = foto["b"]
	var controlados: PackedInt32Array = foto["c"]
	for time in 2:
		var i := controlados[time]
		if i >= 0 and i < p.atletas[time].size():
			p.controlados[time] = p.atletas[time][i]
		p.aneis_do_controlado[time].seguir(p.controlados[time])
		p.setas_do_controlado[time].seguir(p.controlados[time], 1.0 / 30.0)
	if foto["m"] == null:
		p.marcador.esconder()
	else:
		p.marcador.mostrar_em(foto["m"])
	p.estado = int(foto["e"])
	var mudou_o_placar: bool = foto["pt"] != p.placar.pontos or foto["st"] != p.placar.sets \
		or int(foto["qs"]) != p.placar.quem_saca
	if mudou_o_placar:
		# Elemento por elemento: as listas do placar têm tipo e a da rede não.
		for time in 2:
			p.placar.pontos[time] = int(foto["pt"][time])
			p.placar.sets[time] = int(foto["st"][time])
		p.placar.set_atual = int(foto["sa"])
		p.placar.quem_saca = int(foto["qs"])
		p._atualizar_placar()
	p._atualizar_poses_de_espera()


## Convidado: lance, som, mensagem ou faixa que o dono mandou.
func aplicar_evento(tipo: String, dados: Array) -> void:
	match tipo:
		"animar":
			p._animar(p.atletas[int(dados[0])][int(dados[1])], str(dados[2]))
		"mergulho":
			p.lances._animar_mergulho(p.atletas[int(dados[0])][int(dados[1])], dados[2])
		"som":
			p.sons.tocar(str(dados[0]), float(dados[1]))
		"mensagem":
			p.interface.mostrar_mensagem(str(dados[0]), int(dados[1]), bool(dados[2]))
		"faixa":
			var time := int(dados[2])
			p.interface.faixa.mostrar(str(dados[0]), str(dados[1]), p._cor_do_time(maxi(time, 0)), time)
		"ponto":
			p.interface.placar_visual.comemorar(int(dados[0]))
		"fim":
			# O fim de jogo (faixa, comemoração e tela de fim) roda aqui também.
			p.placar.partida_encerrada.emit(int(dados[0]))


## Lê o teclado/controle do convidado (como o Jogador 1) e manda pro dono.
class Envio extends Node:
	var rede: Node
	var _entrada: Node

	func _ready() -> void:
		_entrada = EntradaLocal.new()
		_entrada.jogador = 1
		_entrada.comando.connect(func(_j: int, tipo: String) -> void: rede.enviar_botao(tipo, true))
		_entrada.soltou.connect(func(_j: int, tipo: String) -> void: rede.enviar_botao(tipo, false))
		add_child(_entrada)

	func _physics_process(_delta: float) -> void:
		rede.enviar_direcao(_entrada.direcao)
