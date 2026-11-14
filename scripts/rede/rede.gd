extends Node
## Online por IP, primeira versão (Fase E do plano de melhorias).
##
## Um computador é o "dono" da partida: só ele simula (bola, regras, IA). O
## outro é o "convidado": manda os botões e a direção do jogador dele e
## mostra o que o dono manda (posição dos atletas e da bola, placar, lances,
## sons e mensagens). O convidado joga com o time 2.
##
## Fica sempre carregado (autoload "Rede"). Uso:
##   Rede.hospedar()            # dono: espera alguém conectar na PORTA
##   Rede.conectar("192.168.0.10")  # convidado
## Quando os dois se acham, o dono manda a configuração (times, estádio,
## semente) e os dois abrem a partida.

signal estado_mudou(texto: String)
## Alguém entrou na partida que este computador hospeda. Só no dono.
signal convidado_entrou
## Convidado apertou (apertou = true) ou soltou um botão. Só no dono.
signal botao_do_convidado(tipo: String, apertou: bool)
## Foto da partida chegou do dono. Só no convidado.
signal foto_chegou(foto: Dictionary)
## Lance, som ou mensagem chegou do dono. Só no convidado.
signal evento_chegou(tipo: String, dados: Array)

const PORTA := 7777
const CENA_DA_PARTIDA := "res://cenas/partida.tscn"

## "" (fora do online), "dono" ou "convidado".
var papel := ""
## Direção do jogador do convidado (o dono lê, a cada quadro).
var direcao_do_convidado := Vector2.ZERO
## Quantas fotos o convidado já recebeu (pros testes).
var fotos_recebidas := 0
## Abre a partida sozinho quando conecta (os testes desligam).
var abrir_partida := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(_ao_conectar_alguem)
	multiplayer.peer_disconnected.connect(func(_id: int) -> void: _caiu("O outro jogador saiu."))
	multiplayer.connected_to_server.connect(func() -> void: estado_mudou.emit("Conectado! O dono está escolhendo o modo, os times e o estádio..."))
	multiplayer.connection_failed.connect(func() -> void: _caiu("Não deu pra conectar."))
	multiplayer.server_disconnected.connect(func() -> void: _caiu("O dono da partida saiu."))


func online() -> bool:
	return papel != ""


func e_dono() -> bool:
	return papel == "dono"


func e_convidado() -> bool:
	return papel == "convidado"


## Abre a partida pra um convidado entrar. Devolve OK ou o erro.
func hospedar(porta := PORTA) -> Error:
	sair()
	var par := ENetMultiplayerPeer.new()
	var erro := par.create_server(porta, 1)
	if erro != OK:
		estado_mudou.emit("Não deu pra abrir a porta %d (erro %d)." % [porta, erro])
		return erro
	multiplayer.multiplayer_peer = par
	papel = "dono"
	estado_mudou.emit("Esperando o outro jogador na porta %d..." % porta)
	return OK


## Conecta no dono da partida.
func conectar(ip: String, porta := PORTA) -> Error:
	sair()
	var par := ENetMultiplayerPeer.new()
	var erro := par.create_client(ip, porta)
	if erro != OK:
		estado_mudou.emit("Endereço inválido (erro %d)." % erro)
		return erro
	multiplayer.multiplayer_peer = par
	papel = "convidado"
	fotos_recebidas = 0
	estado_mudou.emit("Conectando em %s..." % ip)
	return OK


## Fecha a conexão e volta pro jogo local.
func sair() -> void:
	if multiplayer.multiplayer_peer != null and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	papel = ""
	direcao_do_convidado = Vector2.ZERO
	# A semente do online não pode ficar valendo nas partidas locais.
	var configuracao := get_node_or_null("/root/Configuracao")
	if configuracao:
		configuracao.semente = -1


func _caiu(motivo: String) -> void:
	estado_mudou.emit(motivo)


# --- Dono ---

func _ao_conectar_alguem(_id: int) -> void:
	if not e_dono():
		return
	estado_mudou.emit("O outro jogador entrou! Escolha o modo, os times e o estádio.")
	convidado_entrou.emit()


## O dono já escolheu modo, times e estádio: manda pro convidado e abre a partida
## nos dois computadores. Devolve false se não tem ninguém conectado.
func comecar_partida() -> bool:
	if not e_dono() or multiplayer.get_peers().is_empty():
		return false
	var configuracao := get_node("/root/Configuracao")
	# Cada partida online tem a sua semente (senão todas saem iguais).
	configuracao.semente = randi() % 100000
	var dados := {
		"times": configuracao.times, "estadio": configuracao.estadio,
		"modo": configuracao.modo, "semente": configuracao.semente,
	}
	for id in multiplayer.get_peers():
		_comecar.rpc_id(id, dados)
	if abrir_partida:
		_abrir_partida()
	return true


## Manda a foto da partida (posições, placar...) pro convidado.
func enviar_foto(foto: Dictionary) -> void:
	if e_dono() and multiplayer.get_peers().size() > 0:
		_receber_foto.rpc(foto)


## Manda um lance, som ou mensagem pro convidado.
func enviar_evento(tipo: String, dados: Array) -> void:
	if e_dono() and multiplayer.get_peers().size() > 0:
		_receber_evento.rpc(tipo, dados)


@rpc("any_peer", "unreliable_ordered")
func _receber_direcao(direcao: Vector2) -> void:
	if e_dono():
		direcao_do_convidado = direcao.limit_length(1.0)


@rpc("any_peer", "reliable")
func _receber_botao(tipo: String, apertou: bool) -> void:
	if e_dono():
		botao_do_convidado.emit(tipo, apertou)


# --- Convidado ---

## Manda a direção e os botões do jogador do convidado pro dono.
func enviar_direcao(direcao: Vector2) -> void:
	if e_convidado():
		_receber_direcao.rpc_id(1, direcao)


func enviar_botao(tipo: String, apertou: bool) -> void:
	if e_convidado():
		_receber_botao.rpc_id(1, tipo, apertou)


@rpc("authority", "reliable")
func _comecar(dados: Dictionary) -> void:
	var configuracao := get_node("/root/Configuracao")
	configuracao.times = dados["times"]
	configuracao.estadio = dados["estadio"]
	configuracao.modo = str(dados.get("modo", "rapida"))
	configuracao.semente = int(dados["semente"])
	estado_mudou.emit("Começando!")
	if abrir_partida:
		_abrir_partida()


@rpc("authority", "unreliable_ordered")
func _receber_foto(foto: Dictionary) -> void:
	fotos_recebidas += 1
	foto_chegou.emit(foto)


@rpc("authority", "reliable")
func _receber_evento(tipo: String, dados: Array) -> void:
	evento_chegou.emit(tipo, dados)


func _abrir_partida() -> void:
	var configuracao := get_node("/root/Configuracao")
	configuracao.contra_computador = false
	configuracao.computador_nos_dois = false
	get_tree().change_scene_to_file(CENA_DA_PARTIDA)
