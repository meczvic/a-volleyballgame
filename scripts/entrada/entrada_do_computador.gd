extends Node
## O computador jogando por um time (modo 1 jogador).
##
## Tem os mesmos sinais ("comando" e "soltou") e a mesma "direcao" da
## EntradaLocal: a partida não sabe se quem aperta os botões é uma pessoa ou o
## computador. A cada quadro ele olha a bola e decide o que "apertar":
## andar até a bola, passar, levantar pra um lado, cortar mirando, largar,
## bloquear, mergulhar e sacar.
##
## O jeito de jogar de cada dificuldade (quanto erra, quão rápido reage, quão
## esperto ataca, quão forte saca) fica em dados/dificuldades.json.

signal comando(jogador: int, tipo: String)
signal soltou(jogador: int, tipo: String)

const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")
const Mira := preload("res://scripts/regras/mira.gd")
const EscolhaAtaque := preload("res://scripts/regras/escolha_ataque.gd")

const ARQUIVO := "res://dados/dificuldades.json"
const NIVEL_PADRAO := "normal"

## Usado se faltar o arquivo ou algum número nele (igual ao "normal").
const PADRAO := {
	"id": "normal", "nome": "Normal",
	"chance_de_errar": 0.07,
	"reacao": 0.2,
	"erro_do_tempo": 0.08,
	"velocidade": 0.95,
	"chance_de_bloquear": 0.5,
	"atraso_do_bloqueio": 0.12,
	"chance_de_mergulho": 0.6,
	"forca_do_saque": [0.35, 0.8],
	"chance_de_flutuante": 0.25,
	"esperteza": 0.5,
	"chance_de_largada": 0.12,
}

## Lugares (em coordenadas da quadra do alvo: x = lado, y = distância da rede)
## que o computador pensa em mirar no saque.
const ALVOS_DO_SAQUE := [
	Vector2(-3.5, 3.0), Vector2(0.0, 3.0), Vector2(3.5, 3.0),
	Vector2(-3.5, 5.5), Vector2(0.0, 5.5), Vector2(3.5, 5.5),
	Vector2(-3.5, 8.0), Vector2(0.0, 8.0), Vector2(3.5, 8.0),
]
## Antes de sacar, o computador espera um pouco (como gente se ajeitando).
const ESPERA_DO_SAQUE := [0.8, 1.6]
## Chega "perto o bastante" da bola: para de andar.
const PERTO := 0.15
## Bola na quadra curta (largada) a menos disso de qualquer defensor: coberta.
const LARGADA_COBERTA := 2.5

@export var jogador := 2

var partida: Node
var ajustes: Dictionary = PADRAO.duplicate()
## Direção "apertada", de -1 a 1 em cada eixo, como a da EntradaLocal.
var direcao := Vector2.ZERO
## Sorteios do computador, separados dos da partida (com semente, repete igual).
var sorteio := RandomNumberGenerator.new()

var _relogio := 0.0
## bola.lancamentos do lance que o computador está jogando agora.
var _lance := -1
var _lance_visto_em := 0.0
## Decisões do lance atual (sorteadas uma vez por lance).
var _plano := {}
## Já apertou o botão do toque neste lance.
var _apertou := false
## Direção segurada depois do botão (o levantamento lê a direção na hora do toque).
var _segurando := Vector2.ZERO
var _saque := {}


## Lista dos níveis (Fácil, Normal, Difícil), na ordem do arquivo.
static func niveis() -> Array:
	var arquivo := FileAccess.open(ARQUIVO, FileAccess.READ)
	if arquivo == null:
		return [PADRAO]
	var dados = JSON.parse_string(arquivo.get_as_text())
	if not dados is Dictionary or not dados.get("niveis") is Array:
		push_warning("dados/dificuldades.json sem a lista \"niveis\".")
		return [PADRAO]
	return dados["niveis"]


## Ajustes de um nível (o que faltar vem do PADRAO).
static func ajustes_do_nivel(id: String) -> Dictionary:
	for nivel in niveis():
		if str(nivel.get("id", "")) == id:
			return PADRAO.merged(nivel, true)
	return PADRAO.duplicate()


## Prepara o computador. "semente" < 0: cada partida sai diferente.
func configurar(a_partida: Node, nivel: String, semente: int = -1) -> void:
	partida = a_partida
	ajustes = ajustes_do_nivel(nivel)
	if semente >= 0:
		sorteio.seed = semente + 1000 * jogador
	else:
		sorteio.randomize()


func _physics_process(delta: float) -> void:
	direcao = Vector2.ZERO
	if partida == null or partida.bola == null:
		return
	_relogio += delta
	if partida._escolhendo_cartas():
		return
	var time := jogador - 1
	match partida.estado:
		partida.Estado.SAQUE:
			_plano = {}
			_jogar_saque(time, delta)
		partida.Estado.RALLY:
			_saque = {}
			_jogar_rally(time)
		_:
			_saque = {}
			_plano = {}


# --- Saque ---

func _jogar_saque(time: int, delta: float) -> void:
	if time != partida.placar.quem_saca:
		_saque = {}
		return
	if _saque.is_empty():
		var forca: Array = ajustes["forca_do_saque"]
		_saque = {
			"espera": sorteio.randf_range(ESPERA_DO_SAQUE[0], ESPERA_DO_SAQUE[1]),
			"forca": sorteio.randf_range(float(forca[0]), float(forca[1])),
			"botao": "saque_flutuante" if sorteio.randf() < float(ajustes["chance_de_flutuante"]) else "ataque",
			"alvo": _alvo_do_saque(time),
			"segurando": false, "feito": false, "tempo": 0.0,
		}
	if _saque["feito"]:
		return
	if not _saque["segurando"]:
		if partida.tempo_no_saque >= _saque["espera"]:
			_saque["segurando"] = true
			comando.emit(jogador, _saque["botao"])
		return
	_saque["tempo"] += delta
	# Enquanto carrega, leva o alvo do saque até o lugar escolhido.
	var lado_do_alvo: float = partida._lado(1 - time)
	var falta: Vector2 = _saque["alvo"] - partida.alvo_do_saque
	if falta.length() > 0.2:
		_apertar_no_mundo(time, Vector2(falta.x, falta.y * lado_do_alvo).normalized())
	if _saque["tempo"] >= float(_saque["forca"]) * Mira.TEMPO_DA_CARGA:
		_saque["feito"] = true
		soltou.emit(jogador, _saque["botao"])


## Pra onde sacar: no buraco da recepção (se for esperto agora) ou num
## lugar qualquer.
func _alvo_do_saque(time: int) -> Vector2:
	var outro := 1 - time
	if sorteio.randf() < float(ajustes["esperteza"]):
		var melhor: Vector2 = ALVOS_DO_SAQUE[0]
		var maior := -INF
		for alvo in ALVOS_DO_SAQUE:
			var folga := _folga_no_ponto(outro, Vector3(alvo.x, 0.0, alvo.y * partida._lado(outro)))
			if folga > maior:
				maior = folga
				melhor = alvo
		return melhor
	return ALVOS_DO_SAQUE[sorteio.randi_range(0, ALVOS_DO_SAQUE.size() - 1)]


# --- Rally ---

func _jogar_rally(time: int) -> void:
	var bola = partida.bola
	if bola.lancamentos != _lance:
		_novo_lance()
	if not bola.em_voo:
		return
	if not partida.cortadas[time].is_empty():
		_no_ar_da_cortada()
		return
	if partida._lado_da_queda() != time:
		_talvez_bloquear(time)
		return
	if partida.saque_em_jogo and time == partida.placar.quem_saca:
		return
	# Tempo de reação: ainda "lendo" a bola.
	if _relogio - _lance_visto_em < float(ajustes["reacao"]):
		return
	if _plano.get("errar", false):
		return
	if _apertou:
		direcao = _segurando
		return

	var atleta: Node3D = partida.controlados[time]
	var lado: float = partida._lado(time)
	var nossos: int = partida.toques.toques if partida.toques.time_com_a_bola == time else 0
	# Vai até onde a bola vai cair (um pouco atrás, pro lado da própria quadra).
	# No 3º toque, fica embaixo de onde a bola vai estar na batida.
	var queda: Vector3 = bola.ponto_previsto
	var alvo := Vector3(queda.x, 0.0, queda.z + lado * 0.25)
	if nossos >= 2:
		var prevista: Vector3 = bola.posicao_daqui_a(partida.TEMPO_ATE_A_BATIDA)
		alvo = Vector3(prevista.x, 0.0, prevista.z + lado * 0.3)
	_andar_ate(time, atleta, alvo)

	if nossos < 2:
		_tentar_passe(time, atleta, nossos)
	else:
		_tentar_ataque(time, atleta)
	if not _apertou:
		_talvez_mergulhar(time, atleta)


## Bola lançada de novo (toque, saque, rede): sorteia como vai ser este lance.
func _novo_lance() -> void:
	_lance = partida.bola.lancamentos
	_lance_visto_em = _relogio
	_apertou = false
	_segurando = Vector2.ZERO
	_plano = {
		# Erro: "congela" e deixa a bola cair.
		"errar": sorteio.randf() < float(ajustes["chance_de_errar"]),
		# Quanto antes (+) ou depois (-) da hora certa ele aperta, em segundos.
		"tempo": sorteio.randfn(0.0, float(ajustes["erro_do_tempo"])),
	}


func _andar_ate(time: int, atleta: Node3D, alvo: Vector3) -> void:
	var falta := Vector2(alvo.x - atleta.position.x, alvo.z - atleta.position.z)
	if falta.length() <= PERTO:
		return
	# Perto do lugar, vai mais devagar (não fica tremendo em volta dele).
	var passo := clampf(falta.length() / 0.5, 0.3, 1.0) * float(ajustes["velocidade"])
	_apertar_no_mundo(time, falta.normalized() * passo)


## Passe (1º toque) ou levantamento (2º): aperta perto da hora certa, com o
## erro sorteado no lance.
func _tentar_passe(time: int, _atleta: Node3D, nossos: int) -> void:
	var bola = partida.bola
	if not partida._alcanca_bola(time, 0.0, partida.ALTURA_MAXIMA_PASSE):
		return
	var tipo := "passe" if nossos == 0 else "levantamento"
	var erro := TempoDoToque.erro_do_botao(tipo, bola.position, bola.velocidade_atual())
	if erro > float(_plano.get("tempo", 0.0)):
		return
	if nossos == 1:
		_segurando = _direcao_do_levantamento(time)
		direcao = _segurando
	_apertou = true
	comando.emit(jogador, "passe")


## Cortada (3º toque): pula perto da hora certa, já mirando. Se não der pra
## cortar, devolve de graça quando a bola chega baixa.
func _tentar_ataque(time: int, atleta: Node3D) -> void:
	var bola = partida.bola
	var prevista: Vector3 = bola.posicao_daqui_a(partida.TEMPO_ATE_A_BATIDA)
	var no_chao := Vector2(prevista.x - atleta.position.x, prevista.z - atleta.position.z).length()
	var alcanca: bool = no_chao <= partida.ALCANCE and prevista.y >= partida.ALTURA_MINIMA_CORTADA \
		and prevista.y <= partida.ALTURA_MAXIMA_CORTADA and not partida._esta_pulando(atleta)
	var erro := TempoDoToque.erro_do_botao("cortada", bola.position, bola.velocidade_atual(), partida.TEMPO_ATE_A_BATIDA)
	if alcanca and erro <= float(_plano.get("tempo", 0.0)):
		_escolher_ataque(time)
		direcao = _plano["mira"]
		_apertou = true
		comando.emit(jogador, "ataque")
		return
	var descendo: bool = bola.velocidade_atual().y < 0.0
	if descendo and bola.position.y < 1.6 and partida._alcanca_bola(time, 0.0, partida.ALTURA_MAXIMA_PASSE):
		_apertou = true
		comando.emit(jogador, "passe")


## No pulo da cortada: segura a mira e, se decidiu, vira largada.
func _no_ar_da_cortada() -> void:
	if not _plano.has("mira"):
		return
	direcao = _plano["mira"]
	if _plano.get("largada", false) and not _plano.get("largou", false):
		_plano["largou"] = true
		comando.emit(jogador, "passe")


## Decide a mira da cortada e se vai ser largada.
func _escolher_ataque(time: int) -> void:
	var outro := 1 - time
	var lado_do_alvo: float = partida._lado(outro)
	var esperto := sorteio.randf() < float(ajustes["esperteza"])
	# Direções possíveis: esquerda/meio/direita x curta/meio/funda.
	var opcoes: Array[Vector2] = []
	for x in [-1.0, 0.0, 1.0]:
		for frente in [-1.0, 0.0, 1.0]:
			opcoes.append(Vector2(x, frente * lado_do_alvo).limit_length(1.0))
	var escolhida: Vector2 = opcoes[sorteio.randi_range(0, opcoes.size() - 1)]
	if esperto:
		var maior := -INF
		for opcao in opcoes:
			var alvo := Mira.alvo_da_cortada(opcao, lado_do_alvo)
			var folga := _folga_no_ponto(outro, Vector3(alvo.x, 0.0, alvo.y * lado_do_alvo))
			if folga > maior:
				maior = folga
				escolhida = opcao
	_plano["mira"] = _na_tela(time, escolhida)

	# Largada: às vezes; o esperto larga quando a quadra curta está vazia.
	var chance := float(ajustes["chance_de_largada"])
	if esperto:
		var curta := Vector3(escolhida.x * Mira.CORTADA_LADO, 0.0, 2.0 * lado_do_alvo)
		chance = chance * 2.5 if _folga_no_ponto(outro, curta) > LARGADA_COBERTA else chance * 0.5
	_plano["largada"] = sorteio.randf() < chance


## Pra que lado levantar: um ataque liberado pelo passe. O esperto manda pro
## lado com menos gente no bloqueio.
func _direcao_do_levantamento(time: int) -> Vector2:
	var outro := 1 - time
	var passe = partida.qualidade_do_passe[time]
	var alvos: Array = []
	for i in partida.ATAQUES.size():
		if TempoDoToque.ataque_liberado(passe, partida.ATAQUES[i]["nome"]):
			alvos.append(partida.alvos_de_ataque[time][i])
	if alvos.size() < 2:
		return Vector2.ZERO
	var escolhido: Vector3 = alvos[sorteio.randi_range(0, alvos.size() - 1)]
	if sorteio.randf() < float(ajustes["esperteza"]):
		var maior := -INF
		for alvo in alvos:
			var livre := INF
			for atleta in partida.atletas[outro]:
				if partida._e_da_rede(outro, atleta):
					livre = minf(livre, absf(atleta.position.x - alvo.x))
			if livre > maior:
				maior = livre
				escolhido = alvo
	var centro := EscolhaAtaque.centro_de(alvos)
	var rumo := Vector2(escolhido.x - centro.x, escolhido.z - centro.z)
	if rumo.length() < 0.1:
		return Vector2.ZERO
	return _na_tela(time, rumo.normalized())


## Bloqueio: quando o adversário sobe pra cortar, às vezes salta junto (com
## um atraso que depende da dificuldade), indo pro lado do atacante.
func _talvez_bloquear(time: int) -> void:
	var outro := 1 - time
	if partida.cortadas[outro].is_empty():
		return
	if not _plano.has("bloquear"):
		_plano["bloquear"] = sorteio.randf() < float(ajustes["chance_de_bloquear"])
		_plano["bloquear_em"] = _relogio + sorteio.randf_range(0.0, float(ajustes["atraso_do_bloqueio"]))
	if not _plano["bloquear"] or _relogio < float(_plano["bloquear_em"]):
		return
	_plano["bloquear"] = false
	var atacante: Node3D = partida.cortadas[outro]["atleta"]
	var bloqueador := _da_rede_mais_perto(time, atacante.position)
	if bloqueador:
		var diferenca: float = atacante.position.x - bloqueador.position.x
		if absf(diferenca) > 0.3:
			_apertar_no_mundo(time, Vector2(signf(diferenca), 0.0))
	comando.emit(jogador, "bloqueio")


## Mergulho: bola baixa, fora do alcance normal mas ao alcance do mergulho.
## Sorteia uma vez por lance se vai tentar.
func _talvez_mergulhar(time: int, atleta: Node3D) -> void:
	var bola = partida.bola
	if bola.velocidade_atual().y >= 0.0 or bola.position.y > partida.ALTURA_MAXIMA_DO_MERGULHO:
		return
	var distancia: float = partida._distancia_no_chao(atleta, bola.position)
	if distancia <= partida.ALCANCE or distancia > partida.ALCANCE_DO_MERGULHO:
		return
	if not _plano.has("mergulhar"):
		_plano["mergulhar"] = sorteio.randf() < float(ajustes["chance_de_mergulho"])
	if _plano["mergulhar"]:
		_apertou = true
		comando.emit(jogador, "mergulho")


# --- Ajudas ---

## Menor distância de um atleta do "time" até o "ponto" (quanto maior, mais
## livre o lugar).
func _folga_no_ponto(time: int, ponto: Vector3) -> float:
	var menor := INF
	for atleta in partida.atletas[time]:
		menor = minf(menor, partida._distancia_no_chao(atleta, ponto))
	return menor


func _da_rede_mais_perto(time: int, ponto: Vector3) -> Node3D:
	var melhor: Node3D = null
	var menor := INF
	for atleta in partida.atletas[time]:
		if not partida._e_da_rede(time, atleta):
			continue
		var distancia: float = absf(atleta.position.x - ponto.x)
		if distancia < menor:
			menor = distancia
			melhor = atleta
	return melhor


## "Aperta" uma direção dada no mundo (x, z).
func _apertar_no_mundo(time: int, no_mundo: Vector2) -> void:
	direcao = _na_tela(time, no_mundo)


## Direção do mundo convertida pra tela do jogador (a partida faz o contrário).
func _na_tela(time: int, no_mundo: Vector2) -> Vector2:
	return no_mundo * float(partida._lado_da_camera(time))
