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
## - Esc ou Start pausa (continuar, recomeçar, trocar times, menu).
##
## Regras oficiais (FIVB) que o jogo cobra (o placar segue o formato do jogo:
## sets até 7, 2 de diferença, limite 10):
## - Escalação 5-1 pela função de cada atleta (scripts/regras/escalacao.gd)
##   e formação na ordem do rodízio no saque (scripts/regras/formacao.gd).
##   Fora de posição na hora do saque é ponto do outro time.
## - Gira no sentido horário quando ganha o saque de volta. Cada set começa
##   com a escalação do começo. 1º saque: sorteio no 1º set, o outro time no
##   2º, sorteio no desempate.
## - 8 segundos pra sacar. Quem sacou não toca no próprio saque.
## - 3 toques por time; o bloqueio não conta e quem bloqueou pode tocar de novo.
##   O mesmo atleta não toca duas vezes seguidas (dois toques).
## - Só os 3 da rede bloqueiam. Atleta do fundo só ataca com a bola acima da
##   rede se estiver atrás da linha de 3 m. Não pode bloquear nem atacar o saque
##   (com a bola acima da rede, perto dela).
## - Pular colado na rede é toque na rede. A bola tem que passar entre as antenas.
## - Sem líbero: 6 atletas por time.
##
## Os times e o estádio vêm da seleção de times (autoload Configuracao).
## Rodando esta cena direto (F6), vale o padrão: Karasuno x Nekoma no Ginásio Japonês.
## Atleta sem personagem do VRoid aparece como cápsula. Com personagem, ele
## corre, para e faz cada lance (scripts/visual/animador.gd).

const Placar := preload("res://scripts/regras/placar.gd")
const Toques := preload("res://scripts/regras/toques.gd")
const Rodizio := preload("res://scripts/regras/rodizio.gd")
const Escalacao := preload("res://scripts/regras/escalacao.gd")
const Formacao := preload("res://scripts/regras/formacao.gd")
const EscolhaAtaque := preload("res://scripts/regras/escolha_ataque.gd")
const EntradaLocal := preload("res://scripts/entrada/entrada_local.gd")
const Bola := preload("res://scripts/partida/bola.gd")
const MarcadorQueda := preload("res://scripts/partida/marcador_queda.gd")
const VisualAnime := preload("res://scripts/visual/visual_anime.gd")
const Dados := preload("res://scripts/comum/dados.gd")
const MenuDePausa := preload("res://scripts/menus/menu_de_pausa.gd")
const Estilo := preload("res://scripts/menus/estilo.gd")
const Animador := preload("res://scripts/visual/animador.gd")

enum Estado { SAQUE, RALLY, PONTO, FIM }

## Medidas oficiais da quadra, em metros.
const COMPRIMENTO := 18.0
const LARGURA := 9.0
const ALTURA_REDE := 2.43
## Chão em volta da quadra, até as placas.
const COMPRIMENTO_ZONA_LIVRE := COMPRIMENTO + 10.0
const LARGURA_ZONA_LIVRE := LARGURA + 8.0

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
## Tempo pra sacar depois que o saque é liberado (regra: 8 s).
const TEMPO_PARA_SACAR := 8.0
## Linha de ataque, a 3 m da rede. Atleta do fundo só ataca com a bola
## acima da rede se pular de trás dela.
const LINHA_DE_ATAQUE := 3.0
## Pular (bloqueio ou cortada) mais perto da rede que isso é encostar nela.
const DISTANCIA_MINIMA_DA_REDE := 0.5
## O levantador só deixa outro passar se estiver bem mais perto da bola (m).
const VANTAGEM_PRO_PASSE_DO_LEVANTADOR := 2.5

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
## y = distância da rede. A formação de cada posição do rodízio está em
## scripts/regras/formacao.gd.
## Onde quem saca fica (atrás da linha de fundo).
const POSICAO_DO_SACADOR := Vector2(2.5, 10.0)
## Onde o passe deve chegar: perto da rede, um pouco à direita.
const PONTO_DO_LEVANTADOR := Vector2(1.0, 1.0)
## Giro do personagem .vrm pro time do Jogador 1 olhar pra rede (-z).
## VRM 1.0 olha pra +z, por isso meia volta. Conferir com o primeiro personagem (Hinata).
const GIRO_DO_PERSONAGEM := PI
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

## Câmera atrás do próprio time, baixa e de longe, como numa transmissão de TV
## (referência: Spike Volleyball). Ajuste aqui ou no Inspetor.
## Altura e distância da rede, em metros.
@export var altura_camera := 14.5
@export var distancia_camera := 29.5
## Pra onde a câmera aponta: metros antes da rede, do lado do próprio time.
## Mais alto mostra mais o fundo da sua quadra (onde fica quem saca).
@export var foco_da_camera := 1.5
## Abertura vertical da câmera, em graus. Menor = mais "zoom" e menos distorção.
@export var abertura_da_camera := 27.0
## Tela dividida: cada jogador vê de trás do próprio time.
## Desligado: uma câmera só, do lado do Jogador 1.
@export var tela_dividida := true
## Visual anime (sombra "chapada" e contorno escuro) nos atletas e na bola.
@export var visual_anime := true

var placar = Placar.new()
var toques = Toques.new()
var rodizios: Array = [Rodizio.new(), Rodizio.new()]
var estado := Estado.SAQUE
var ultimo_toque := -1
## Função de cada atleta: funcoes[time][índice] = "levantador", "ponteiro",
## "central" ou "oposto" (veja escalacao.gd).
var funcoes: Array = [{}, {}]
## Índice do levantador de cada time.
var levantadores: Array[int] = [0, 0]
## O saque está no ar e o time que recebe ainda não tocou na bola.
var saque_em_jogo := false
## Segundos desde que o saque foi liberado (limite: TEMPO_PARA_SACAR).
var tempo_no_saque := 0.0
var _segundos_mostrados := -1

var times_em_jogo: Array = []
## Estádio escolhido (cores da quadra, do fundo e da luz). Veja dados/estadios.json.
var estadio: Dictionary = {}
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
var menu
var rotulo_placar: Label
var rotulo_mensagem: Label
## Caixa escura atrás da mensagem; some quando não tem mensagem.
var caixa_da_mensagem: PanelContainer
## Espera depois de cada ponto. É um nó (e não um "await") pra parar junto
## quando o jogo pausa e sumir junto quando a cena fecha.
var temporizador_do_ponto: Timer


func _ready() -> void:
	_carregar_escolhas()

	_criar_ambiente()
	_criar_quadra()
	_criar_placas()
	_criar_rede()
	for time in 2:
		_criar_atletas(time)
		_criar_marcas_de_ataque(time)
	_criar_camera()
	_criar_interface()

	bola = Bola.new()
	bola.name = "Bola"
	bola.usar_visual_anime = visual_anime
	add_child(bola)
	bola.verificar_bloqueio = _tem_bloqueio
	bola.tocou_chao.connect(_ao_bola_tocar_chao)
	bola.bloqueada.connect(_ao_bola_ser_bloqueada)
	bola.cruzou_a_rede.connect(_ao_bola_cruzar_a_rede)

	marcador = MarcadorQueda.new()
	marcador.name = "MarcadorQueda"
	add_child(marcador)
	# Bateu na rede: a bola muda de rumo, então o anel muda de lugar e o
	# controle passa pra quem vai nela agora (se ela voltar pro lado de quem
	# tocou, não é ele de novo: seriam dois toques).
	bola.tocou_rede.connect(_ao_lancar_bola)

	for jogador in [1, 2]:
		var entrada = EntradaLocal.new()
		entrada.jogador = jogador
		entrada.name = "EntradaJogador%d" % jogador
		entrada.comando.connect(_ao_receber_comando)
		add_child(entrada)
		entradas.append(entrada)

	temporizador_do_ponto = Timer.new()
	temporizador_do_ponto.name = "TemporizadorDoPonto"
	temporizador_do_ponto.one_shot = true
	temporizador_do_ponto.wait_time = PAUSA_DEPOIS_DO_PONTO
	temporizador_do_ponto.timeout.connect(_depois_do_ponto)
	add_child(temporizador_do_ponto)

	menu = MenuDePausa.new()
	menu.name = "MenuDePausa"
	add_child(menu)
	menu.pausa_pedida.connect(func() -> void: menu.abrir_pausa(_resumo_do_placar()))

	_conectar_placar()
	_preparar_saque()


func _physics_process(delta: float) -> void:
	for time in 2:
		var controlado := controlados[time]
		var sacando: bool = estado == Estado.SAQUE and time == placar.quem_saca
		if not sacando:
			_mover(controlado, time, _direcao_no_mundo(time), delta)
			if estado == Estado.SAQUE:
				_manter_na_ordem(time, controlado)

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
		_contar_tempo_do_saque(delta)


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
##
## No saque: a formação na ordem do rodízio (regra). Depois do saque, cada
## um vai pro lado da sua função (ponteiro na esquerda, central no meio,
## oposto e levantador na direita) e o levantador do fundo infiltra pra
## levantar quando a bola vem pro nosso lado.
func _alvo_da_ia(time: int, indice: int) -> Vector3:
	var posicao: int = rodizios[time].posicao_de(indice)
	var da_rede := Rodizio.e_da_rede(posicao)
	var e_levantador := indice == levantadores[time]
	if estado != Estado.RALLY:
		var recebendo: bool = time != placar.quem_saca
		return _no_mundo(time, Formacao.lugar_no_saque(posicao, e_levantador, recebendo))

	var outro := 1 - time
	var funcao: String = funcoes[time].get(indice, "")
	var x_da_funcao := Formacao.x_da_funcao(funcao, da_rede)
	var bola_vem_pra_ca: bool = bola.em_voo and _lado_da_queda() == time
	# O adversário levantou ou atacou: a rede fica pro bloqueio até a gente tocar.
	var adversario_vai_atacar: bool = toques.time_com_a_bola == outro and toques.toques >= 2
	var montando_o_ataque: bool = (toques.time_com_a_bola == time and toques.toques < 3) \
		or (bola_vem_pra_ca and not adversario_vai_atacar)
	var lugar: Vector2

	if da_rede and adversario_vai_atacar:
		# Sobe pra rede e acompanha a bola pra bloquear.
		var bola_x_do_time: float = bola.position.x * _lado(time)
		lugar = Vector2(lerpf(x_da_funcao, bola_x_do_time, 0.5), 0.7)
	elif e_levantador and montando_o_ataque:
		# Infiltração: o levantador vai pro lugar do levantamento.
		lugar = PONTO_DO_LEVANTADOR
	elif da_rede and montando_o_ataque:
		# Recua pra ter espaço de correr pro ataque.
		lugar = Vector2(x_da_funcao, LINHA_DE_ATAQUE)
	elif da_rede:
		lugar = Vector2(x_da_funcao, 1.5)
	else:
		lugar = Vector2(x_da_funcao, Formacao.Y_FUNDO)
	return _no_mundo(time, lugar)


## Antes do saque, o atleta controlado do time que recebe não pode sair da
## ordem do rodízio nem da quadra (senão é falta de posição).
func _manter_na_ordem(time: int, atleta: Node3D) -> void:
	var indice: int = atletas[time].find(atleta)
	if indice < 0:
		return
	var lugares := _lugares_do_time(time)
	var posicao: int = rodizios[time].posicao_de(indice)
	var ignorar := 1 if time == placar.quem_saca else 0
	var ajustado := Formacao.limitar(posicao, lugares[posicao], lugares, ignorar)
	var no_mundo := _no_mundo(time, ajustado)
	atleta.position.x = no_mundo.x
	atleta.position.z = no_mundo.z


## Onde está cada posição do rodízio do "time", em coordenadas do time.
func _lugares_do_time(time: int) -> Dictionary:
	var lugares := {}
	for i in 6:
		lugares[rodizios[time].posicao_de(i)] = _no_time(time, atletas[time][i].position)
	return lugares


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
		if estado == Estado.RALLY and absf(atleta.position.z) < DISTANCIA_MINIMA_DA_REDE:
			_encerrar_rally(1 - time, "toque na rede")
		_animar(atleta, "bloqueio")


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
	if saque_em_jogo:
		# Bloquear o saque é falta.
		_encerrar_rally(ultimo_toque, "bloqueio no saque")
		return
	# O bloqueio não conta como toque: quem bloqueou ainda tem 3 toques.
	toques.registrar_bloqueio(time_que_bloqueou)
	ultimo_toque = time_que_bloqueou
	_mostrar_mensagem("Bloqueio!")
	_ao_lancar_bola()


## Toca um lance no personagem do atleta (a cápsula não tem animação).
func _animar(atleta: Node3D, lance: String) -> void:
	if atleta == null:
		return
	var animador = atleta.get_meta("animador") if atleta.has_meta("animador") else null
	if animador:
		animador.tocar(lance)


# --- Comandos ---

func _ao_receber_comando(jogador: int, tipo: String) -> void:
	var time := jogador - 1
	match estado:
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
			elif tipo == "mergulho":
				# Por enquanto só a animação: o mergulho ainda não alcança mais longe.
				_animar(controlados[time], "mergulho")


func _sacar(time: int, flutuante: bool) -> void:
	_animar(controlados[time], "saque")
	# Na hora do saque, os dois times têm que estar na ordem do rodízio.
	var falta_de_posicao := _time_fora_de_posicao()
	if falta_de_posicao >= 0:
		_encerrar_rally(1 - falta_de_posicao, "posição errada no saque")
		return
	toques.reiniciar()
	toques.registrar(time, atletas[time].find(controlados[time]))
	saque_em_jogo = true
	var destino := _ponto_aleatorio_no_lado(1 - time, 2.0, 8.0)
	# Provisório: o flutuante só sai mais baixo. O balanço vem depois.
	var altura := 3.4 if flutuante else 4.2
	bola.lancar(destino, altura)
	ultimo_toque = time
	estado = Estado.RALLY
	_mostrar_mensagem("")
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
	if saque_em_jogo and time == placar.quem_saca:
		# Quem sacou não pode tocar no próprio saque: o toque é ignorado.
		# (Se a bola não passar a rede, ela cai do lado de quem sacou e é ponto do outro.)
		return

	var falta := _falta_no_toque(time, atacando)
	if falta != "":
		_encerrar_rally(1 - time, falta)
		return
	if not toques.registrar(time, atletas[time].find(controlados[time])):
		_encerrar_rally(1 - time, "4 toques")
		return
	if time != placar.quem_saca:
		saque_em_jogo = false
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
	_animar(controlados[time], "manchete")
	var erro := Vector2(randf_range(-ERRO_DO_PASSE, ERRO_DO_PASSE), randf_range(-0.3, ERRO_DO_PASSE))
	var alvo := _no_mundo(time, PONTO_DO_LEVANTADOR + erro)
	bola.lancar(alvo, 4.0)
	_ao_lancar_bola()
	_mostrar_marcas_de_ataque(time)


func _levantar(time: int) -> void:
	_animar(controlados[time], "levantamento")
	var direcao := _direcao_no_mundo(time)
	var escolhido := EscolhaAtaque.escolher(alvos_de_ataque[time], direcao, ATAQUE_PADRAO)
	var alvo: Vector3 = alvos_de_ataque[time][escolhido]
	bola.lancar(alvo, 4.4)
	_ao_lancar_bola()
	_mostrar_mensagem("Levantamento: %s" % ATAQUES[escolhido]["nome"])


func _cortar(time: int) -> void:
	_pular(controlados[time])
	_animar(controlados[time], "cortada")
	# A direção mira pra esquerda ou direita da quadra adversária.
	var direcao := _direcao_no_mundo(time)
	var mira_x := clampf(direcao.x * 3.0 + randf_range(-0.8, 0.8), -LARGURA / 2.0 + 0.5, LARGURA / 2.0 - 0.5)
	var profundidade := randf_range(4.0, 8.5)
	var destino := Vector3(mira_x, 0.0, profundidade * _lado(1 - time))
	# Cortada: forte, quase sem subir.
	bola.lancar(destino, bola.position.y + 0.3)
	_ao_lancar_bola()


func _devolver_de_graca(time: int) -> void:
	_animar(controlados[time], "manchete")
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
	var time_que_recebe := _lado_da_queda()
	controlados[time_que_recebe] = _quem_vai_na_bola(time_que_recebe, queda)


## Quem do "time" vai na bola que cai em "queda", respeitando as funções:
## - 1º toque (bola que vem do outro lado ou que voltou do nosso bloqueio):
##   quem estiver mais perto (o levantador evita, pra poder levantar);
## - 2º toque: o levantador (se não foi ele que passou);
## - 3º toque: quem pode atacar dali (da rede na frente da linha de 3 m,
##   do fundo atrás dela). Ninguém toca duas vezes seguidas.
func _quem_vai_na_bola(time: int, queda: Vector3) -> Node3D:
	var levantador: Node3D = atletas[time][levantadores[time]]
	var bola_nossa: bool = time == ultimo_toque and toques.time_com_a_bola == time
	if not bola_nossa or toques.toques == 0:
		var outro_perto := _mais_perto(time, queda, levantador)
		if _distancia_no_chao(levantador, queda) + VANTAGEM_PRO_PASSE_DO_LEVANTADOR \
				< _distancia_no_chao(outro_perto, queda):
			return levantador
		return outro_perto

	var quem_tocou: Node3D = controlados[time]
	if toques.toques == 1:
		if levantador != quem_tocou:
			return levantador
		return _mais_perto(time, queda, quem_tocou)

	var do_fundo := absf(queda.z) >= LINHA_DE_ATAQUE
	var quem_ataca := _mais_perto(time, queda, quem_tocou, func(atleta: Node3D) -> bool:
		return _e_da_rede(time, atleta) != do_fundo)
	if quem_ataca:
		return quem_ataca
	return _mais_perto(time, queda, quem_tocou)


# --- Regras (faltas) ---

## Falta no toque do atleta controlado do "time"? Devolve o motivo, ou "".
func _falta_no_toque(time: int, atacando: bool) -> String:
	var atleta := controlados[time]
	var indice: int = atletas[time].find(atleta)
	if toques.seria_toque_duplo(time, indice):
		return "dois toques"
	if not atacando:
		return ""
	if absf(atleta.position.z) < DISTANCIA_MINIMA_DA_REDE:
		return "toque na rede"
	# Ataque com a bola inteira acima da rede, de dentro da zona de ataque:
	var acima_da_rede: bool = bola.position.y - Bola.RAIO > ALTURA_REDE
	var na_zona_de_ataque := absf(atleta.position.z) < LINHA_DE_ATAQUE
	if acima_da_rede and na_zona_de_ataque:
		if saque_em_jogo:
			return "ataque no saque"
		if not _e_da_rede(time, atleta):
			return "ataque do fundo"
	return ""


## A bola cruzou a linha da rede: tem que passar entre as antenas
## (que ficam em cima das linhas laterais).
func _ao_bola_cruzar_a_rede(ponto: Vector3) -> void:
	if estado != Estado.RALLY:
		return
	if absf(ponto.x) > LARGURA / 2.0:
		_encerrar_rally(1 - ultimo_toque, "fora da antena")


## Algum time fora da ordem do rodízio na hora do saque? Devolve qual, ou -1.
## Quem saca erra primeiro (a falta dele vale mais, como na regra).
func _time_fora_de_posicao() -> int:
	for time in [placar.quem_saca, 1 - placar.quem_saca]:
		var ignorar := 1 if time == placar.quem_saca else 0
		if not Formacao.faltas(_lugares_do_time(time), ignorar).is_empty():
			return time
	return -1


## Conta os 8 s do saque e avisa nos 3 últimos.
func _contar_tempo_do_saque(delta: float) -> void:
	tempo_no_saque += delta
	var restam := ceili(TEMPO_PARA_SACAR - tempo_no_saque)
	if restam <= 0:
		_encerrar_rally(1 - placar.quem_saca, "demorou pra sacar")
		return
	if restam <= 3 and restam != _segundos_mostrados:
		_segundos_mostrados = restam
		_mostrar_mensagem("%s saca: aperte Ataque (%d)" % [times_em_jogo[placar.quem_saca]["nome"], restam])


func _e_da_rede(time: int, atleta: Node3D) -> bool:
	var indice: int = atletas[time].find(atleta)
	return indice >= 0 and Rodizio.e_da_rede(rodizios[time].posicao_de(indice))


## De que lado vai cair a bola: 0 = time do Jogador 1 (z positivo), 1 = o outro.
func _lado_da_queda() -> int:
	return 0 if bola.ponto_previsto.z > 0.0 else 1


func _distancia_no_chao(atleta: Node3D, ponto: Vector3) -> float:
	if atleta == null:
		return INF
	return Vector2(atleta.position.x - ponto.x, atleta.position.z - ponto.z).length()


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
	if estado != Estado.SAQUE and estado != Estado.RALLY:
		return
	estado = Estado.PONTO
	saque_em_jogo = false
	marcador.esconder()
	_mostrar_marcas_de_ataque(-1)
	_mostrar_mensagem("Ponto %s! (%s)" % [times_em_jogo[vencedor]["nome"], motivo])
	for atleta in atletas[vencedor]:
		_animar(atleta, "comemoracao_palmas")
	# Se foi o último ponto, o placar chama _ao_encerrar_partida aqui dentro.
	placar.marcar_ponto(vencedor)
	temporizador_do_ponto.start()


## Depois da pausa do ponto: próximo saque, ou a tela de fim de jogo.
func _depois_do_ponto() -> void:
	if estado == Estado.FIM:
		var vencedor: int = placar.vencedor
		menu.abrir_fim_de_jogo(
			"%s VENCEU!" % str(times_em_jogo[vencedor]["nome"]).to_upper(),
			"%d sets a %d" % [placar.sets[vencedor], placar.sets[1 - vencedor]]
		)
	elif estado == Estado.PONTO:
		_preparar_saque()


func _preparar_saque() -> void:
	estado = Estado.SAQUE
	ultimo_toque = -1
	saque_em_jogo = false
	tempo_no_saque = 0.0
	_segundos_mostrados = -1
	toques.reiniciar()
	marcador.esconder()
	_mostrar_marcas_de_ataque(-1)
	_colocar_na_formacao()
	for lado in 2:
		for atleta in atletas[lado]:
			var animador = atleta.get_meta("animador") if atleta.has_meta("animador") else null
			if animador:
				animador.soltar()
	# Depois de um set, o placar zera aqui (no fim do set ele mostra o resultado).
	_atualizar_placar()

	# Quem saca é o atleta na posição 1, atrás da linha de fundo.
	var time: int = placar.quem_saca
	var sacador: Node3D = atletas[time][rodizios[time].atleta_na(1)]
	sacador.position = _no_mundo(time, POSICAO_DO_SACADOR)
	controlados[time] = sacador
	# O outro time começa controlando quem passa: o do meio do fundo
	# (ou o da esquerda do fundo, se o do meio for o levantador).
	var outro := 1 - time
	var passador: int = rodizios[outro].atleta_na(6)
	if passador == levantadores[outro]:
		passador = rodizios[outro].atleta_na(5)
	controlados[outro] = atletas[outro][passador]

	_mostrar_mensagem("%s saca: aperte Ataque" % times_em_jogo[time]["nome"])


func _ao_encerrar_partida(vencedor: int) -> void:
	estado = Estado.FIM
	marcador.esconder()
	_mostrar_marcas_de_ataque(-1)
	_mostrar_mensagem("Fim de jogo! %s venceu." % times_em_jogo[vencedor]["nome"])
	for atleta in atletas[vencedor]:
		_animar(atleta, "comemoracao_torcida")


func _conectar_placar() -> void:
	placar.sortear_primeiro_saque()
	placar.ponto_marcado.connect(func(_time: int) -> void: _atualizar_placar())
	placar.rodizio.connect(func(time: int) -> void: rodizios[time].girar())
	placar.set_encerrado.connect(_ao_encerrar_set)
	placar.partida_encerrada.connect(_ao_encerrar_partida)
	_atualizar_placar()


## Fim de um set. Se foi o último, _ao_encerrar_partida troca a mensagem logo depois.
func _ao_encerrar_set(vencedor: int) -> void:
	# Cada set começa com a escalação do começo.
	for rodizio in rodizios:
		rodizio.reiniciar()
	_atualizar_placar()
	_mostrar_mensagem("Set %d: %s venceu! (%d x %d)" % [
		placar.set_atual, times_em_jogo[vencedor]["nome"],
		placar.pontos[vencedor], placar.pontos[1 - vencedor],
	])


func _atualizar_placar() -> void:
	var a: Dictionary = times_em_jogo[0]
	var b: Dictionary = times_em_jogo[1]
	rotulo_placar.text = "%s  %d  x  %d  %s\nSet %d   (sets %d - %d)" % [
		a["nome"], placar.pontos[0], placar.pontos[1], b["nome"],
		placar.set_atual, placar.sets[0], placar.sets[1],
	]


## Uma linha com o placar, pro menu de pausa.
func _resumo_do_placar() -> String:
	return "%s %d x %d %s  ·  Set %d  ·  Sets %d x %d" % [
		times_em_jogo[0]["nome"], placar.pontos[0], placar.pontos[1], times_em_jogo[1]["nome"],
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


## O contrário de _no_mundo: ponto do mundo em coordenadas do "time".
func _no_time(time: int, mundo: Vector3) -> Vector2:
	var lado := _lado(time)
	return Vector2(mundo.x * lado, mundo.z * lado)


## Ponto aleatório dentro da quadra do "time", entre z_min e z_max metros da rede.
func _ponto_aleatorio_no_lado(time: int, z_min: float, z_max: float) -> Vector3:
	var x := randf_range(-LARGURA / 2.0 + 0.8, LARGURA / 2.0 - 0.8)
	var z := randf_range(z_min, z_max) * _lado(time)
	return Vector3(x, 0.0, z)


## Atleta do "time" mais perto do "ponto" (no chão), menos "excluir".
## "filtro" (opcional): função(atleta) -> bool que diz quem pode ser escolhido.
func _mais_perto(time: int, ponto: Vector3, excluir: Node3D = null, filtro := Callable()) -> Node3D:
	var melhor: Node3D = null
	var menor := INF
	for atleta in atletas[time]:
		if atleta == excluir:
			continue
		if filtro.is_valid() and not filtro.call(atleta):
			continue
		var distancia: float = Vector2(atleta.position.x - ponto.x, atleta.position.z - ponto.z).length()
		if distancia < menor:
			menor = distancia
			melhor = atleta
	return melhor


## Coloca todo mundo na formação do saque (na ordem do rodízio), no chão.
func _colocar_na_formacao() -> void:
	for time in 2:
		var recebendo: bool = time != placar.quem_saca
		for i in 6:
			var atleta: Node3D = atletas[time][i]
			var posicao: int = rodizios[time].posicao_de(i)
			atleta.position = _no_mundo(time, Formacao.lugar_no_saque(posicao, i == levantadores[time], recebendo))
			atleta.set_meta("tempo_do_pulo", -1.0)


## Mostra as setas de ataque no chão do "time" (ou esconde todas com -1).
func _mostrar_marcas_de_ataque(time: int) -> void:
	for i in 2:
		marcas_de_ataque[i].visible = i == time


## Lê os times e o estádio escolhidos nos menus.
func _carregar_escolhas() -> void:
	var times := Dados.times()
	times_em_jogo = [
		Dados.por_id(times, str(Configuracao.times[0])),
		Dados.por_id(times, str(Configuracao.times[1])),
	]
	# Mesmo time dos dois lados: o Jogador 2 joga com o uniforme reserva.
	if times_em_jogo[0]["id"] == times_em_jogo[1]["id"]:
		times_em_jogo[1] = _com_uniforme_reserva(times_em_jogo[1])
	estadio = Dados.por_id(Dados.estadios(), Configuracao.estadio)


## Uniforme reserva: a 3ª cor vira a principal, e a principal vira o detalhe.
func _com_uniforme_reserva(time: Dictionary) -> Dictionary:
	var reserva := time.duplicate(true)
	var cores: Array = reserva["cores"]
	if cores.size() >= 3:
		reserva["cores"] = [cores[2], cores[0], cores[1]]
	return reserva


## Cor do estádio (veja dados/estadios.json), ou "padrao" se faltar.
func _cor_do_estadio(chave: String, padrao: Color) -> Color:
	return Dados.cor(estadio.get("cores", {}), chave, padrao)


# --- Construção da cena (provisória) ---

func _criar_ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = _cor_do_estadio("fundo", Color("#1B2A3A"))
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = _cor_do_estadio("luz", Color(1.0, 0.95, 0.9))
	# A sombra "chapada" do visual anime fica melhor com mais luz ambiente.
	env.ambient_light_energy = 0.8 if visual_anime else 0.6
	var mundo := WorldEnvironment.new()
	mundo.environment = env
	add_child(mundo)

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	sol.shadow_enabled = true
	add_child(sol)


func _criar_quadra() -> void:
	# Zona livre em volta e a quadra, nas cores do estádio.
	_caixa(Vector3(LARGURA_ZONA_LIVRE, 0.1, COMPRIMENTO_ZONA_LIVRE), Vector3(0, -0.05, 0),
		_cor_do_estadio("zona_livre", Color("#2D6A9A")))
	_caixa(Vector3(LARGURA, 0.1, COMPRIMENTO), Vector3(0, -0.04, 0),
		_cor_do_estadio("quadra", Color("#E39A55")))

	# Linhas: laterais, fundos, centro e linhas de ataque (3 m da rede).
	var cor_das_linhas := _cor_do_estadio("linhas", Color.WHITE)
	var y := 0.015
	for x in [-LARGURA / 2.0, LARGURA / 2.0]:
		_caixa(Vector3(0.05, 0.01, COMPRIMENTO), Vector3(x, y, 0), cor_das_linhas)
	for z in [-COMPRIMENTO / 2.0, -3.0, 0.0, 3.0, COMPRIMENTO / 2.0]:
		_caixa(Vector3(LARGURA, 0.01, 0.05), Vector3(0, y, z), cor_das_linhas)


## Placas de propaganda em volta da zona livre, na cor do estádio.
func _criar_placas() -> void:
	var cor := _cor_do_estadio("placas", Color("#8E2B2B"))
	var altura := 1.0
	var espessura := 0.3
	var x := LARGURA_ZONA_LIVRE / 2.0 + espessura / 2.0
	var z := COMPRIMENTO_ZONA_LIVRE / 2.0 + espessura / 2.0
	for lado in [-1.0, 1.0]:
		_caixa(Vector3(espessura, altura, COMPRIMENTO_ZONA_LIVRE), Vector3(x * lado, altura / 2.0, 0.0), cor)
		_caixa(Vector3(LARGURA_ZONA_LIVRE + espessura * 2.0, altura, espessura), Vector3(0.0, altura / 2.0, z * lado), cor)


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
	var id_time := str(dados_time["id"])
	var elenco := Dados.elenco(id_time)
	var cor_detalhe := Color.from_string(str(dados_time["cores"][1]), Color.WHITE)
	# Escalação pela função de cada um (levantador oposto ao oposto, etc.).
	var ordem := Escalacao.ordem_inicial(elenco)
	rodizios[time].comecar_com(ordem)
	funcoes[time] = Escalacao.funcoes_por_atleta(ordem)
	levantadores[time] = ordem[0]

	for i in 6:
		var atleta := Node3D.new()
		atleta.name = "Time%d_%s_%d" % [time + 1, id_time, i + 1]
		atleta.position = _no_mundo(time, Formacao.lugar_no_saque(rodizios[time].posicao_de(i), false, false))
		atleta.set_meta("tempo_do_pulo", -1.0)
		var dados_atleta: Dictionary = elenco[i] if i < elenco.size() else {}
		atleta.set_meta("dados", dados_atleta)

		var personagem := _carregar_personagem(id_time, dados_atleta)
		if personagem:
			atleta.add_child(personagem)
			var animador := Animador.new()
			animador.name = "Animador"
			atleta.add_child(animador)
			if animador.preparar(personagem, GIRO_DO_PERSONAGEM if time == 0 else GIRO_DO_PERSONAGEM + PI):
				atleta.set_meta("animador", animador)
		else:
			_criar_capsula(atleta, _cores_do_atleta(dados_time, dados_atleta))
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


## Personagem do VRoid (.vrm) do atleta, ou null se o arquivo ainda não existe
## (ou se o plugin VRM não está instalado). Aí o atleta continua sendo cápsula.
func _carregar_personagem(id_time: String, dados_atleta: Dictionary) -> Node3D:
	if dados_atleta.is_empty():
		return null
	var caminho := Dados.caminho_do_personagem(id_time, dados_atleta)
	if not ResourceLoader.exists(caminho):
		return null
	var cena = load(caminho)
	if not cena is PackedScene:
		push_warning("O arquivo %s não virou uma cena (o plugin VRM está ativo?)." % caminho)
		return null
	return cena.instantiate() as Node3D


## Cores [camisa, detalhe] do atleta: o uniforme do time (não tem líbero).
func _cores_do_atleta(dados_time: Dictionary, _dados_atleta: Dictionary) -> Array:
	var cores: Array = dados_time["cores"]
	return [
		Color.from_string(str(cores[0]), Color.GRAY),
		Color.from_string(str(cores[1]), Color.WHITE),
	]


## Cápsula de teste (1,8 m) com uma faixa no peito na cor de detalhe.
func _criar_capsula(atleta: Node3D, cores: Array) -> void:
	var corpo := MeshInstance3D.new()
	var capsula := CapsuleMesh.new()
	capsula.radius = 0.35
	capsula.height = 1.8
	corpo.mesh = capsula
	corpo.material_override = _material_do_atleta(cores[0], 0.03)
	corpo.position.y = 0.9
	atleta.add_child(corpo)

	var faixa := MeshInstance3D.new()
	var anel_do_peito := CylinderMesh.new()
	anel_do_peito.top_radius = 0.36
	anel_do_peito.bottom_radius = 0.36
	anel_do_peito.height = 0.12
	faixa.mesh = anel_do_peito
	faixa.material_override = _material_do_atleta(cores[1], 0.0)
	faixa.position.y = 1.15
	atleta.add_child(faixa)


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
	camera.fov = abertura_da_camera
	onde.add_child(camera)
	camera.look_at_from_position(
		Vector3(0.0, altura_camera, distancia_camera * lado),
		Vector3(0.0, 0.0, foco_da_camera * lado)
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

	# Placar no canto, numa caixa escura pra ler bem em qualquer estádio.
	var caixa_do_placar := _caixa_da_interface()
	caixa_do_placar.position = Vector2(18.0, 16.0)
	camada.add_child(caixa_do_placar)
	rotulo_placar = _rotulo_da_interface(28, true)
	caixa_do_placar.add_child(rotulo_placar)

	# Mensagem no meio, em cima. O CenterContainer mantém a caixa centralizada
	# e do tamanho do texto.
	var centro := CenterContainer.new()
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.position = Vector2(0.0, 86.0)
	centro.size = Vector2(1600.0, 56.0)
	camada.add_child(centro)
	caixa_da_mensagem = _caixa_da_interface()
	centro.add_child(caixa_da_mensagem)
	rotulo_mensagem = _rotulo_da_interface(32, true)
	caixa_da_mensagem.add_child(rotulo_mensagem)

	# Comandos de cada jogador embaixo da metade dele (ou só do J1, sem tela dividida).
	var ajudas := [
		"J1 (teclado): WASD move · J passe · K saque/cortada · I flutuante · L bloqueio",
		"J2 (teclado): setas move · 1 passe · 2 saque/cortada · 5 flutuante · 3 bloqueio (numérico)",
	]
	for jogador in (2 if tela_dividida else 1):
		var ajuda := _rotulo_da_interface(16, false)
		ajuda.text = ajudas[jogador] + "\nControle: A passe · X saque/cortada · RB flutuante · Y bloqueio"
		ajuda.position = Vector2(20.0 + jogador * 800.0, 848.0)
		camada.add_child(ajuda)

	# Lembrete da pausa no canto direito, crescendo pra esquerda.
	var caixa_da_pausa := _caixa_da_interface()
	caixa_da_pausa.anchor_left = 1.0
	caixa_da_pausa.anchor_right = 1.0
	caixa_da_pausa.offset_left = -18.0
	caixa_da_pausa.offset_right = -18.0
	caixa_da_pausa.offset_top = 16.0
	caixa_da_pausa.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	camada.add_child(caixa_da_pausa)
	var dica_da_pausa := _rotulo_da_interface(18, true)
	dica_da_pausa.text = "Esc ou Start: pausa"
	caixa_da_pausa.add_child(dica_da_pausa)


## Mostra uma mensagem no meio da tela. Texto vazio esconde a caixa.
func _mostrar_mensagem(texto: String) -> void:
	rotulo_mensagem.text = texto
	caixa_da_mensagem.visible = texto != ""


## Caixa escura e inclinada (como as dos menus) atrás dos textos da partida.
func _caixa_da_interface() -> PanelContainer:
	var caixa := PanelContainer.new()
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_theme_stylebox_override("panel",
		Estilo.caixa(Color(0.06, 0.07, 0.09, 0.72), Estilo.INCLINACAO, 22.0, 4.0))
	return caixa


## Texto da interface com contorno escuro, pra ler bem em cima da quadra.
func _rotulo_da_interface(tamanho: int, titulo: bool) -> Label:
	var rotulo := Label.new()
	rotulo.add_theme_font_override("font", Estilo.FONTE_TITULO if titulo else Estilo.FONTE_TEXTO)
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.07))
	rotulo.add_theme_constant_override("outline_size", 6)
	return rotulo


func _caixa(tamanho: Vector3, posicao: Vector3, cor: Color) -> MeshInstance3D:
	var caixa := MeshInstance3D.new()
	var malha := BoxMesh.new()
	malha.size = tamanho
	caixa.mesh = malha
	caixa.material_override = _material(cor)
	caixa.position = posicao
	add_child(caixa)
	return caixa


## Material dos atletas: anime (com contorno) ou comum, conforme "visual_anime".
func _material_do_atleta(cor: Color, contorno: float) -> Material:
	if visual_anime:
		return VisualAnime.material(cor, contorno)
	return _material(cor)


func _material(cor: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = cor
	return material
