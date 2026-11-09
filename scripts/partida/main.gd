extends Node3D
## Cena de teste: saque, 3 toques, bloqueio, rodízio, IA dos atletas e tela dividida.
##
## Como jogar:
## - Quem saca (o atleta na posição 1 do rodízio) aperta Ataque.
## - Um anel amarelo mostra onde a bola vai cair, e o jogo troca sozinho
##   pro atleta mais perto dele. Os outros 5 se posicionam sozinhos.
## - 1º toque: Passe manda a bola pro levantador.
## - 2º toque: Passe levanta. Segure uma direção pra escolher o atacante
##   (as setas aparecem no chão). Sem direção, vai pro meio.
## - 3º toque: Ataque com a bola alta corta (a direção mira).
##   Passe só devolve de graça.
## - Ataque em qualquer toque, com a bola alta, já manda pro outro lado.
## - Bloqueio: os 3 da rede pulam. A direção desloca o bloqueio.
##   Acertar o tempo do pulo devolve a cortada.
## - 4 toques seguidos do mesmo time é falta.
##
## Os atletas são cápsulas provisórias.

const Placar := preload("res://scripts/regras/placar.gd")
const Toques := preload("res://scripts/regras/toques.gd")
const Rodizio := preload("res://scripts/regras/rodizio.gd")
const EscolhaAtaque := preload("res://scripts/regras/escolha_ataque.gd")
const EntradaLocal := preload("res://scripts/entrada/entrada_local.gd")
const Bola := preload("res://scripts/partida/bola.gd")
const MarcadorQueda := preload("res://scripts/partida/marcador_queda.gd")

enum Estado { SAQUE, RALLY, PONTO, FIM }

## Medidas oficiais da quadra, em metros.
const COMPRIMENTO := 18.0
const LARGURA := 9.0
const ALTURA_REDE := 2.43

## Velocidade do atleta controlado e dos outros (m/s).
const VELOCIDADE := 6.0
const VELOCIDADE_IA := 5.0
## Distância (no chão) em que o atleta alcança a bola.
const ALCANCE := 1.8
## Altura máxima da bola pra passar ou levantar.
const ALTURA_MAXIMA_PASSE := 3.0
## Faixa de altura da bola pra cortar (o atleta pula).
const ALTURA_MINIMA_CORTADA := 1.6
const ALTURA_MAXIMA_CORTADA := 3.5
## Tempo mostrando "Ponto!" antes do próximo saque.
const PAUSA_DEPOIS_DO_PONTO := 1.5

## Pulo: duração (s) e altura máxima (m).
const DURACAO_DO_PULO := 0.6
const ALTURA_DO_PULO := 0.95
## Altura das mãos de um atleta em pé com os braços pra cima.
const ALTURA_DAS_MAOS := 2.35
## Até quantos metros pro lado da mão o bloqueio alcança a bola.
const LARGURA_DO_BLOQUEIO := 0.6
## Só bloqueia quem está até essa distância da rede.
const DISTANCIA_MAXIMA_DO_BLOQUEIO := 1.2
## Quanto a direção desloca o bloqueio na hora do pulo (m).
const DESLOCAMENTO_DO_BLOQUEIO := 0.7

## Coordenadas "do time": x = lado (negativo = esquerda de quem olha pra rede),
## y = distância da rede.
## Onde fica cada posição do rodízio na formação básica.
const FORMACAO := {
	1: Vector2(3.0, 7.0), 2: Vector2(3.0, 2.0), 3: Vector2(0.0, 2.0),
	4: Vector2(-3.0, 2.0), 5: Vector2(-3.0, 7.0), 6: Vector2(0.0, 7.0),
}
## Onde quem saca fica (atrás da linha de fundo).
const POSICAO_DO_SACADOR := Vector2(2.5, 10.0)
## Onde o passe deve chegar: perto da rede, um pouco à direita.
const PONTO_DO_LEVANTADOR := Vector2(1.0, 1.0)
## Erro máximo do passe, em metros.
const ERRO_DO_PASSE := 0.6

## Pra onde o levantador pode mandar a bola.
const ATAQUES := [
	{ "nome": "Ponta", "posicao": Vector2(-3.5, 1.2) },
	{ "nome": "Meio", "posicao": Vector2(0.0, 1.2) },
	{ "nome": "Oposto", "posicao": Vector2(3.5, 1.2) },
	{ "nome": "Fundo", "posicao": Vector2(0.0, 4.0) },
]
## Sem direção apertada, o levantamento vai pro meio.
const ATAQUE_PADRAO := 1

## Ajuste aqui (ou no Inspetor) até achar o ângulo que você gosta.
@export var altura_camera := 17.0
@export var distancia_camera := 15.0
## Tela dividida: cada jogador vê de trás do próprio time.
## Desligado: uma câmera só, do lado do Jogador 1.
@export var tela_dividida := true

var placar = Placar.new()
var toques = Toques.new()
var rodizios: Array = [Rodizio.new(), Rodizio.new()]
var estado := Estado.SAQUE
var ultimo_toque := -1

var times_em_jogo: Array = []
## atletas[0] = time do Jogador 1, atletas[1] = time do Jogador 2.
var atletas: Array = [[], []]
var controlados: Array[Node3D] = [null, null]
var aneis: Array[Node3D] = [null, null]
var entradas: Array = []
## Posições de ataque no mundo, por time (calculadas de ATAQUES).
var alvos_de_ataque: Array = [[], []]
## Marcas no chão com as setas de cada ataque, por time.
var marcas_de_ataque: Array[Node3D] = [null, null]

var bola
var marcador
var rotulo_placar: Label
var rotulo_mensagem: Label


func _ready() -> void:
	var times := _carregar_times()
	times_em_jogo = [times[0], times[3]]  # Karasuno x Nekoma

	_criar_ambiente()
	_criar_quadra()
	_criar_rede()
	for time in 2:
		_criar_atletas(time)
		_criar_marcas_de_ataque(time)
	_criar_camera()
	_criar_interface()

	bola = Bola.new()
	bola.name = "Bola"
	add_child(bola)
	bola.verificar_bloqueio = _tem_bloqueio
	bola.tocou_chao.connect(_ao_bola_tocar_chao)
	bola.bloqueada.connect(_ao_bola_ser_bloqueada)

	marcador = MarcadorQueda.new()
	marcador.name = "MarcadorQueda"
	add_child(marcador)
	# Bateu na rede: a bola muda de rumo, então o anel muda de lugar.
	bola.tocou_rede.connect(func() -> void: marcador.mostrar_em(bola.ponto_previsto))

	for jogador in [1, 2]:
		var entrada = EntradaLocal.new()
		entrada.jogador = jogador
		entrada.name = "EntradaJogador%d" % jogador
		entrada.comando.connect(_ao_receber_comando)
		add_child(entrada)
		entradas.append(entrada)

	_conectar_placar()
	_preparar_saque()


func _physics_process(delta: float) -> void:
	for time in 2:
		var controlado := controlados[time]
		var sacando := estado == Estado.SAQUE and time == placar.quem_saca
		if not sacando:
			_mover(controlado, time, _direcao_no_mundo(time), delta)

		# Os outros 5 vão sozinhos pro lugar certo.
		if estado == Estado.SAQUE or estado == Estado.RALLY:
			for i in 6:
				var atleta: Node3D = atletas[time][i]
				if atleta != controlado:
					_mover_ia(atleta, _alvo_da_ia(time, i), delta)

		for atleta in atletas[time]:
			_atualizar_pulo(atleta, delta)
		aneis[time].position = Vector3(controlado.position.x, 0.03, controlado.position.z)

	# Antes do saque, a bola fica na mão de quem saca.
	if estado == Estado.SAQUE:
		var sacador := controlados[placar.quem_saca]
		var frente := -_lado(placar.quem_saca) * 0.5
		bola.segurar_em(sacador.position + Vector3(0.0, 2.2, frente))


func _mover(atleta: Node3D, time: int, direcao: Vector2, delta: float) -> void:
	atleta.position += Vector3(direcao.x, 0.0, direcao.y) * VELOCIDADE * delta
	# Cada time fica no próprio lado da rede (com um pouco de área livre).
	var limite_x := LARGURA / 2.0 + 2.0
	atleta.position.x = clampf(atleta.position.x, -limite_x, limite_x)
	var fundo := COMPRIMENTO / 2.0 + 2.0
	if time == 0:
		atleta.position.z = clampf(atleta.position.z, 0.4, fundo)
	else:
		atleta.position.z = clampf(atleta.position.z, -fundo, -0.4)


# --- IA dos atletas sem controle ---

## Lugar (no mundo) pra onde o atleta "indice" do "time" deve ir agora.
func _alvo_da_ia(time: int, indice: int) -> Vector3:
	var posicao: int = rodizios[time].posicao_de(indice)
	var lugar: Vector2 = FORMACAO[posicao]
	var da_rede := Rodizio.e_da_rede(posicao)
	var outro := 1 - time

	if estado == Estado.RALLY and da_rede:
		var adversario_vai_atacar: bool = toques.time_com_a_bola == outro and toques.toques >= 2
		var nos_com_a_bola: bool = toques.time_com_a_bola == time
		if adversario_vai_atacar:
			# Sobe pra rede e acompanha a bola pra bloquear.
			var bola_x_do_time: float = bola.position.x * _lado(time)
			lugar = Vector2(lerpf(lugar.x, bola_x_do_time, 0.5), 0.7)
		elif nos_com_a_bola:
			# Recua um pouco pra ter espaço de correr pro ataque.
			lugar.y = 3.0

	return _no_mundo(time, lugar)


func _mover_ia(atleta: Node3D, alvo: Vector3, delta: float) -> void:
	var atual := Vector2(atleta.position.x, atleta.position.z)
	var novo := atual.move_toward(Vector2(alvo.x, alvo.z), VELOCIDADE_IA * delta)
	atleta.position.x = novo.x
	atleta.position.z = novo.y


# --- Pulo e bloqueio ---

func _pular(atleta: Node3D) -> void:
	if _esta_pulando(atleta):
		return
	atleta.set_meta("tempo_do_pulo", 0.0)


func _esta_pulando(atleta: Node3D) -> bool:
	return float(atleta.get_meta("tempo_do_pulo", -1.0)) >= 0.0


func _atualizar_pulo(atleta: Node3D, delta: float) -> void:
	if not _esta_pulando(atleta):
		return
	var tempo: float = float(atleta.get_meta("tempo_do_pulo")) + delta
	if tempo >= DURACAO_DO_PULO:
		atleta.position.y = 0.0
		atleta.set_meta("tempo_do_pulo", -1.0)
		return
	var fracao := tempo / DURACAO_DO_PULO
	atleta.position.y = 4.0 * ALTURA_DO_PULO * fracao * (1.0 - fracao)
	atleta.set_meta("tempo_do_pulo", tempo)


func _bloquear(time: int) -> void:
	var deslocamento := _direcao_no_mundo(time).x * DESLOCAMENTO_DO_BLOQUEIO
	for i in 6:
		if not Rodizio.e_da_rede(rodizios[time].posicao_de(i)):
			continue
		var atleta: Node3D = atletas[time][i]
		if _esta_pulando(atleta):
			continue
		atleta.position.x += deslocamento
		_pular(atleta)


## Chamado pela bola quando ela cruza a rede por cima da fita.
## Bloqueia se um atleta da rede do lado de destino está no ar, perto da
## bola e com as mãos alto o bastante.
func _tem_bloqueio(ponto_na_rede: Vector3, lado_destino: float) -> bool:
	var time := 0 if lado_destino > 0.0 else 1
	for i in 6:
		if not Rodizio.e_da_rede(rodizios[time].posicao_de(i)):
			continue
		var atleta: Node3D = atletas[time][i]
		if not _esta_pulando(atleta):
			continue
		if absf(atleta.position.z) > DISTANCIA_MAXIMA_DO_BLOQUEIO:
			continue
		if absf(atleta.position.x - ponto_na_rede.x) > LARGURA_DO_BLOQUEIO:
			continue
		if ponto_na_rede.y <= ALTURA_DAS_MAOS + atleta.position.y + Bola.RAIO:
			return true
	return false


func _ao_bola_ser_bloqueada() -> void:
	if estado != Estado.RALLY:
		return
	# Quem bloqueou é o time do lado pra onde a bola ia.
	var time_que_bloqueou := 1 - ultimo_toque
	# O bloqueio não conta como toque: quem bloqueou ainda tem 3 toques.
	toques.registrar(time_que_bloqueou)
	toques.toques = 0
	ultimo_toque = time_que_bloqueou
	rotulo_mensagem.text = "Bloqueio!"
	_ao_lancar_bola()


# --- Comandos ---

func _ao_receber_comando(jogador: int, tipo: String) -> void:
	var time := jogador - 1
	match estado:
		Estado.FIM:
			if tipo == "passe" or tipo == "ataque":
				_reiniciar_partida()
		Estado.SAQUE:
			if time == placar.quem_saca and (tipo == "ataque" or tipo == "saque_flutuante"):
				_sacar(time, tipo == "saque_flutuante")
		Estado.RALLY:
			if tipo == "passe":
				_tentar_tocar(time, false)
			elif tipo == "ataque":
				_tentar_tocar(time, true)
			elif tipo == "bloqueio":
				_bloquear(time)


func _sacar(time: int, flutuante: bool) -> void:
	toques.reiniciar()
	toques.registrar(time)
	var destino := _ponto_aleatorio_no_lado(1 - time, 2.0, 8.0)
	# Provisório: o flutuante só sai mais baixo. O balanço vem depois.
	var altura := 3.4 if flutuante else 4.2
	bola.lancar(destino, altura)
	ultimo_toque = time
	estado = Estado.RALLY
	rotulo_mensagem.text = ""
	_ao_lancar_bola()


## Passe (atacando = false) ou ataque (atacando = true) do atleta controlado.
func _tentar_tocar(time: int, atacando: bool) -> void:
	var alcancou: bool
	if atacando:
		alcancou = _alcanca_bola(time, ALTURA_MINIMA_CORTADA, ALTURA_MAXIMA_CORTADA)
	else:
		alcancou = _alcanca_bola(time, 0.0, ALTURA_MAXIMA_PASSE)
	if not alcancou:
		return

	if not toques.registrar(time):
		_encerrar_rally(1 - time, "4 toques")
		return
	ultimo_toque = time
	_mostrar_marcas_de_ataque(-1)

	var numero: int = toques.toques
	if atacando:
		_cortar(time)
	elif numero == 1:
		_passar_pro_levantador(time)
	elif numero == 2:
		_levantar(time)
	else:
		_devolver_de_graca(time)


func _passar_pro_levantador(time: int) -> void:
	var erro := Vector2(randf_range(-ERRO_DO_PASSE, ERRO_DO_PASSE), randf_range(-0.3, ERRO_DO_PASSE))
	var alvo := _no_mundo(time, PONTO_DO_LEVANTADOR + erro)
	bola.lancar(alvo, 4.0)
	_ao_lancar_bola()
	_mostrar_marcas_de_ataque(time)


func _levantar(time: int) -> void:
	var direcao := _direcao_no_mundo(time)
	var escolhido := EscolhaAtaque.escolher(alvos_de_ataque[time], direcao, ATAQUE_PADRAO)
	var alvo: Vector3 = alvos_de_ataque[time][escolhido]
	bola.lancar(alvo, 4.4)
	_ao_lancar_bola()
	rotulo_mensagem.text = "Levantamento: %s" % ATAQUES[escolhido]["nome"]


func _cortar(time: int) -> void:
	_pular(controlados[time])
	# A direção mira pra esquerda ou direita da quadra adversária.
	var direcao := _direcao_no_mundo(time)
	var mira_x := clampf(direcao.x * 3.0 + randf_range(-0.8, 0.8), -LARGURA / 2.0 + 0.5, LARGURA / 2.0 - 0.5)
	var profundidade := randf_range(4.0, 8.5)
	var destino := Vector3(mira_x, 0.0, profundidade * _lado(1 - time))
	# Cortada: forte, quase sem subir.
	bola.lancar(destino, bola.position.y + 0.3)
	_ao_lancar_bola()


func _devolver_de_graca(time: int) -> void:
	bola.lancar(_ponto_aleatorio_no_lado(1 - time, 2.0, 8.0), 5.0)
	_ao_lancar_bola()


func _alcanca_bola(time: int, altura_minima: float, altura_maxima: float) -> bool:
	if not bola.em_voo:
		return false
	var atleta := controlados[time]
	var no_chao := Vector2(bola.position.x - atleta.position.x, bola.position.z - atleta.position.z)
	var altura: float = bola.position.y
	return no_chao.length() <= ALCANCE and altura >= altura_minima and altura <= altura_maxima


## Mostra o anel e passa o controle pro atleta mais perto de onde a bola vai cair.
## Se a bola fica do mesmo lado (passe ou levantamento), quem acabou de tocar
## não é escolhido de novo.
func _ao_lancar_bola() -> void:
	var queda: Vector3 = bola.ponto_previsto
	marcador.mostrar_em(queda)
	var time_que_recebe := 0 if queda.z > 0.0 else 1
	var excluir: Node3D = null
	if time_que_recebe == ultimo_toque:
		excluir = controlados[time_que_recebe]
	controlados[time_que_recebe] = _mais_perto(time_que_recebe, queda, excluir)


# --- Fim do rally ---

func _ao_bola_tocar_chao(posicao: Vector3) -> void:
	if estado != Estado.RALLY:
		return
	var dentro := absf(posicao.x) <= LARGURA / 2.0 + Bola.RAIO \
		and absf(posicao.z) <= COMPRIMENTO / 2.0 + Bola.RAIO
	if dentro:
		# Caiu do lado do time 0 (z positivo): ponto do time 1, e vice-versa.
		_encerrar_rally(1 if posicao.z > 0.0 else 0, "dentro")
	else:
		_encerrar_rally(1 - ultimo_toque, "fora")


func _encerrar_rally(vencedor: int, motivo: String) -> void:
	estado = Estado.PONTO
	marcador.esconder()
	_mostrar_marcas_de_ataque(-1)
	rotulo_mensagem.text = "Ponto %s! (%s)" % [times_em_jogo[vencedor]["nome"], motivo]
	placar.marcar_ponto(vencedor)

	if placar.encerrada:
		return
	await get_tree().create_timer(PAUSA_DEPOIS_DO_PONTO).timeout
	if estado == Estado.PONTO:
		_preparar_saque()


func _preparar_saque() -> void:
	estado = Estado.SAQUE
	ultimo_toque = -1
	toques.reiniciar()
	marcador.esconder()
	_mostrar_marcas_de_ataque(-1)
	_colocar_na_formacao()

	# Quem saca é o atleta na posição 1, atrás da linha de fundo.
	var time: int = placar.quem_saca
	var sacador: Node3D = atletas[time][rodizios[time].atleta_na(1)]
	sacador.position = _no_mundo(time, POSICAO_DO_SACADOR)
	controlados[time] = sacador
	# O outro time começa controlando quem está no meio do fundo.
	var outro := 1 - time
	controlados[outro] = atletas[outro][rodizios[outro].atleta_na(6)]

	rotulo_mensagem.text = "%s saca: aperte Ataque" % times_em_jogo[time]["nome"]


func _ao_encerrar_partida(vencedor: int) -> void:
	estado = Estado.FIM
	marcador.esconder()
	_mostrar_marcas_de_ataque(-1)
	rotulo_mensagem.text = "Fim de jogo! %s venceu. Aperte Passe pra jogar de novo." % times_em_jogo[vencedor]["nome"]


func _reiniciar_partida() -> void:
	placar = Placar.new()
	rodizios = [Rodizio.new(), Rodizio.new()]
	_conectar_placar()
	_preparar_saque()


func _conectar_placar() -> void:
	placar.ponto_marcado.connect(func(_time: int) -> void: _atualizar_placar())
	placar.rodizio.connect(func(time: int) -> void: rodizios[time].girar())
	placar.partida_encerrada.connect(_ao_encerrar_partida)
	_atualizar_placar()


func _atualizar_placar() -> void:
	var a: Dictionary = times_em_jogo[0]
	var b: Dictionary = times_em_jogo[1]
	rotulo_placar.text = "%s  %d  x  %d  %s\nSet %d   (sets %d - %d)" % [
		a["nome"], placar.pontos[0], placar.pontos[1], b["nome"],
		placar.set_atual, placar.sets[0], placar.sets[1],
	]


# --- Ajudantes ---

## 1 pro time do Jogador 1 (lado da câmera, z positivo), -1 pro outro.
func _lado(time: int) -> float:
	return 1.0 if time == 0 else -1.0


## De que lado está a câmera que esse jogador olha: 1 = atrás do time 0,
## -1 = atrás do time 1 (só com tela dividida).
func _lado_da_camera(time: int) -> float:
	return _lado(time) if tela_dividida else 1.0


## Direção apertada pelo jogador, convertida pro mundo (x, z).
## "Cima" na tela é sempre "pra frente" na câmera daquele jogador.
func _direcao_no_mundo(time: int) -> Vector2:
	var direcao: Vector2 = entradas[time].direcao
	return direcao * _lado_da_camera(time)


## Converte coordenadas "do time" (x = lado, y = distância da rede) pro mundo.
## Os dois times olham pra rede, então o time de lá fica espelhado.
func _no_mundo(time: int, local: Vector2) -> Vector3:
	var lado := _lado(time)
	return Vector3(local.x * lado, 0.0, local.y * lado)


## Ponto aleatório dentro da quadra do "time", entre z_min e z_max metros da rede.
func _ponto_aleatorio_no_lado(time: int, z_min: float, z_max: float) -> Vector3:
	var x := randf_range(-LARGURA / 2.0 + 0.8, LARGURA / 2.0 - 0.8)
	var z := randf_range(z_min, z_max) * _lado(time)
	return Vector3(x, 0.0, z)


func _mais_perto(time: int, ponto: Vector3, excluir: Node3D = null) -> Node3D:
	var melhor: Node3D = null
	var menor := INF
	for atleta in atletas[time]:
		if atleta == excluir:
			continue
		var distancia: float = Vector2(atleta.position.x - ponto.x, atleta.position.z - ponto.z).length()
		if distancia < menor:
			menor = distancia
			melhor = atleta
	return melhor


## Coloca todo mundo na posição do rodízio, no chão.
func _colocar_na_formacao() -> void:
	for time in 2:
		for i in 6:
			var atleta: Node3D = atletas[time][i]
			atleta.position = _no_mundo(time, FORMACAO[rodizios[time].posicao_de(i)])
			atleta.set_meta("tempo_do_pulo", -1.0)


## Mostra as setas de ataque no chão do "time" (ou esconde todas com -1).
func _mostrar_marcas_de_ataque(time: int) -> void:
	for i in 2:
		marcas_de_ataque[i].visible = i == time


func _carregar_times() -> Array:
	var texto := FileAccess.get_file_as_string("res://dados/times.json")
	var dados = JSON.parse_string(texto)
	return dados["times"]


# --- Construção da cena (provisória) ---

func _criar_ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#1B2A3A")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.95, 0.9)
	env.ambient_light_energy = 0.6
	var mundo := WorldEnvironment.new()
	mundo.environment = env
	add_child(mundo)

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	sol.shadow_enabled = true
	add_child(sol)


func _criar_quadra() -> void:
	# Zona livre (azul) e quadra (madeira).
	_caixa(Vector3(LARGURA + 8.0, 0.1, COMPRIMENTO + 10.0), Vector3(0, -0.05, 0), Color("#2D6A9A"))
	_caixa(Vector3(LARGURA, 0.1, COMPRIMENTO), Vector3(0, -0.04, 0), Color("#E39A55"))

	# Linhas: laterais, fundos, centro e linhas de ataque (3 m da rede).
	var branco := Color.WHITE
	var y := 0.015
	for x in [-LARGURA / 2.0, LARGURA / 2.0]:
		_caixa(Vector3(0.05, 0.01, COMPRIMENTO), Vector3(x, y, 0), branco)
	for z in [-COMPRIMENTO / 2.0, -3.0, 0.0, 3.0, COMPRIMENTO / 2.0]:
		_caixa(Vector3(LARGURA, 0.01, 0.05), Vector3(0, y, z), branco)


func _criar_rede() -> void:
	var rede := _caixa(Vector3(LARGURA + 1.0, 1.0, 0.03), Vector3(0, ALTURA_REDE - 0.5, 0), Color(1, 1, 1, 0.45))
	var material := rede.material_override as StandardMaterial3D
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	for x in [-(LARGURA / 2.0 + 0.5), LARGURA / 2.0 + 0.5]:
		var poste := MeshInstance3D.new()
		var cilindro := CylinderMesh.new()
		cilindro.top_radius = 0.05
		cilindro.bottom_radius = 0.05
		cilindro.height = ALTURA_REDE + 0.1
		poste.mesh = cilindro
		poste.material_override = _material(Color("#D8D8D8"))
		poste.position = Vector3(x, cilindro.height / 2.0, 0)
		add_child(poste)


func _criar_atletas(time: int) -> void:
	var dados_time: Dictionary = times_em_jogo[time]
	var cor_uniforme := Color.html(str(dados_time["cores"][0]))
	var cor_detalhe := Color.html(str(dados_time["cores"][1]))

	for i in 6:
		var atleta := Node3D.new()
		atleta.name = "%s_%d" % [dados_time["id"], i + 1]
		atleta.position = _no_mundo(time, FORMACAO[rodizios[time].posicao_de(i)])
		atleta.set_meta("tempo_do_pulo", -1.0)

		var corpo := MeshInstance3D.new()
		var capsula := CapsuleMesh.new()
		capsula.radius = 0.35
		capsula.height = 1.8
		corpo.mesh = capsula
		corpo.material_override = _material(cor_uniforme)
		corpo.position.y = 0.9
		atleta.add_child(corpo)
		add_child(atleta)
		atletas[time].append(atleta)

	# Anel no chão que mostra quem está sendo controlado.
	var anel := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.5
	toro.outer_radius = 0.65
	anel.mesh = toro
	var material := _material(cor_detalhe)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	anel.material_override = material
	anel.scale = Vector3(1.0, 0.1, 1.0)
	add_child(anel)
	aneis[time] = anel
	controlados[time] = atletas[time][rodizios[time].atleta_na(6)]


## Cria as marcas no chão (círculo + seta + nome) dos 4 ataques do time.
func _criar_marcas_de_ataque(time: int) -> void:
	var grupo := Node3D.new()
	grupo.name = "MarcasDeAtaque%d" % time
	grupo.visible = false
	add_child(grupo)
	marcas_de_ataque[time] = grupo

	for ataque in ATAQUES:
		alvos_de_ataque[time].append(_no_mundo(time, ataque["posicao"]))
	var centro := EscolhaAtaque.centro_de(alvos_de_ataque[time])

	for i in ATAQUES.size():
		var alvo: Vector3 = alvos_de_ataque[time][i]

		var circulo := MeshInstance3D.new()
		var disco := CylinderMesh.new()
		disco.top_radius = 0.55
		disco.bottom_radius = 0.55
		disco.height = 0.01
		circulo.mesh = disco
		var material := _material(Color(1, 1, 1, 0.35))
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		circulo.material_override = material
		circulo.position = Vector3(alvo.x, 0.025, alvo.z)
		grupo.add_child(circulo)

		var texto := Label3D.new()
		texto.text = "%s %s" % [EscolhaAtaque.seta_de(alvo, centro, _lado_da_camera(time)), ATAQUES[i]["nome"]]
		texto.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		texto.no_depth_test = true
		texto.font_size = 48
		texto.outline_size = 12
		texto.pixel_size = 0.01
		texto.position = Vector3(alvo.x, 0.6, alvo.z)
		grupo.add_child(texto)


func _criar_camera() -> void:
	if not tela_dividida:
		_adicionar_camera(self, 0)
		return

	# Duas metades da tela, cada uma com a própria câmera olhando o mesmo mundo.
	# Fica numa camada atrás da interface (placar e mensagens).
	var camada := CanvasLayer.new()
	camada.name = "TelaDividida"
	camada.layer = -1
	add_child(camada)
	for time in 2:
		var moldura := SubViewportContainer.new()
		moldura.name = "TelaJogador%d" % (time + 1)
		moldura.stretch = true
		moldura.anchor_left = 0.5 * time
		moldura.anchor_right = 0.5 * (time + 1)
		moldura.anchor_top = 0.0
		moldura.anchor_bottom = 1.0
		camada.add_child(moldura)

		var tela := SubViewport.new()
		tela.world_3d = get_viewport().find_world_3d()
		tela.msaa_3d = Viewport.MSAA_2X
		moldura.add_child(tela)
		_adicionar_camera(tela, time)


## Câmera alta atrás do time, olhando pra rede.
func _adicionar_camera(onde: Node, time: int) -> void:
	var lado := _lado(time)
	var camera := Camera3D.new()
	camera.fov = 50.0
	onde.add_child(camera)
	camera.look_at_from_position(
		Vector3(0.0, altura_camera, distancia_camera * lado),
		Vector3(0.0, 0.0, -1.0 * lado)
	)
	camera.current = true


func _criar_interface() -> void:
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

	rotulo_placar = Label.new()
	rotulo_placar.position = Vector2(24, 20)
	rotulo_placar.add_theme_font_size_override("font_size", 26)
	camada.add_child(rotulo_placar)

	rotulo_mensagem = Label.new()
	rotulo_mensagem.position = Vector2(400, 90)
	rotulo_mensagem.size = Vector2(800, 40)
	rotulo_mensagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo_mensagem.add_theme_font_size_override("font_size", 28)
	camada.add_child(rotulo_mensagem)

	var ajuda := Label.new()
	ajuda.text = "Jogador 1: WASD move, J passe, K saque/cortada, L bloqueio  |  Jogador 2: setas move, 1 passe, 2 saque/cortada, 3 bloqueio (numérico)  |  Controle: A passe, X saque/cortada, Y bloqueio"
	ajuda.position = Vector2(24, 850)
	ajuda.add_theme_font_size_override("font_size", 15)
	camada.add_child(ajuda)


func _caixa(tamanho: Vector3, posicao: Vector3, cor: Color) -> MeshInstance3D:
	var caixa := MeshInstance3D.new()
	var malha := BoxMesh.new()
	malha.size = tamanho
	caixa.mesh = malha
	caixa.material_override = _material(cor)
	caixa.position = posicao
	add_child(caixa)
	return caixa


func _material(cor: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = cor
	return material
