extends Node
## Anima um personagem do VRoid dentro da partida.
##
## Fica como filho do atleta. Sozinho, olha quanto o atleta andou a cada quadro
## e escolhe parado, correr ou passo lateral. A partida chama tocar("cortada"),
## tocar("saque") etc. nos lances; depois do lance ele volta pro movimento.
##
## As animações vêm da pasta animacoes/ (veja animacoes/LEIA-ME.md) e são
## carregadas uma vez só, pra todos os atletas.

const ARQUIVOS := {
	"parado": "res://animacoes/parado.fbx",
	"correr": "res://animacoes/correr.fbx",
	"lateral_esquerda": "res://animacoes/lateral_esquerda.fbx",
	"lateral_direita": "res://animacoes/lateral_direita.fbx",
	# Manchete, toque, saque em pé e saque viagem de verdade: DeepMotion a partir
	# de vídeos livres do Pexels (producao/videos_pexels/LEIA-ME.md). As antigas
	# do Mixamo (manchete.fbx, saque.fbx) continuam na pasta.
	"manchete": "res://animacoes/manchete_deepmotion.tres",
	"levantamento": "res://animacoes/levantamento_deepmotion.tres",
	"cortada": "res://animacoes/cortada_deepmotion.tres",
	"bloqueio": "res://animacoes/bloqueio.fbx",
	"saque": "res://animacoes/saque_deepmotion.tres",
	"saque_viagem": "res://animacoes/saque_viagem_deepmotion.tres",
	"mergulho": "res://animacoes/mergulho.fbx",
	"mergulho_direita": "res://animacoes/mergulho_deepmotion.tres",
	"espera_defesa": "res://animacoes/espera_defesa.fbx",
	"comemoracao_palmas": "res://animacoes/comemoracao_palmas.fbx",
	"comemoracao_torcida": "res://animacoes/comemoracao_torcida.fbx",
	"comemoracao_punho": "res://animacoes/comemoracao_punho.fbx",
	"comemoracao_pulo": "res://animacoes/comemoracao_pulo.fbx",
	"ponto_perdido_frustrado": "res://animacoes/ponto_perdido_frustrado.fbx",
	"ponto_perdido_desanimado": "res://animacoes/ponto_perdido_desanimado.fbx",
}
const EM_LOOP := ["parado", "espera", "espera_defesa", "correr", "lateral_esquerda", "lateral_direita",
	"comemoracao_palmas", "comemoracao_torcida", "comemoracao_punho", "comemoracao_pulo"]
## Lances que param assim que o atleta anda (ele não escorrega deitado nem
## fazendo a reação). As de EM_LOOP também param. Nos primeiros CARENCIA
## segundos não param (o mergulho já começa com um deslocamento curto).
const SAEM_AO_ANDAR := ["mergulho", "mergulho_direita", "ponto_perdido_frustrado", "ponto_perdido_desanimado"]
const CARENCIA := 0.25
## Comemorações do ponto e reações de quem perdeu: cada atleta faz uma.
const COMEMORACOES := ["comemoracao_palmas", "comemoracao_punho", "comemoracao_pulo"]
const REACOES_AO_PONTO_PERDIDO := ["ponto_perdido_desanimado", "ponto_perdido_desanimado", "ponto_perdido_frustrado"]
## Pose de espera do jogo (Fase 06): a "parado" com os joelhos dobrados, o
## quadril mais baixo, o tronco inclinado pra frente e os braços na frente do
## corpo, como um atleta pronto pra receber. [osso, eixo local, ângulo (rad)];
## nos braços, o ângulo troca de sinal do lado direito.
const POSE_DE_ESPERA := [
	["UpperLeg", Vector3.RIGHT, 0.35], ["LowerLeg", Vector3.RIGHT, 0.7], ["Foot", Vector3.RIGHT, 0.32],
	["Spine", Vector3.RIGHT, 0.15], ["Chest", Vector3.RIGHT, 0.1],
	["UpperArm", Vector3.UP, 0.6], ["LowerArm", Vector3.FORWARD, -0.6],
]
## Quanto o quadril desce na pose de espera (fração da altura do quadril em
## pé), pra os pés continuarem no chão com os joelhos dobrados.
const DESCIDA_DO_QUADRIL := 0.131
## Animação que o atleta toca parado em quadra.
const PARADO_NO_JOGO := "espera"

## Trecho de cada lance que vale: [início, fim] em segundos da animação, e
## opcionalmente a velocidade (1 = normal). O resto é preparo ou volta.
## Medido num modelo do VRoid. O jogo faz o pulo em 0,6 s, com o alto em 0,3 s:
## - bloqueio: o alto do pulo da animação (0,85 s) cai no alto do pulo do jogo;
## - cortada (do DeepMotion): começa no ar com o braço armado (1,25 s); a mão
##   da batida (MAO_DA_CORTADA) passa pela bola em 1,62 s (BATIDA_DA_CORTADA), que a 1,23x cai em
##   0,3 s, o alto do pulo, quando a partida solta a bola da mão; a queda (2,0 s)
##   fica no fim do pulo.
## - manchete e levantamento: o toque começa NA POSE DE CONTATO. O preparo até
##   essa pose fica em PREPARO e roda antes da bola chegar (preparar_toque).
## - manchete (DeepMotion, 13/11/2026): mãos juntas (~0,19 m) de 0,5 a 2,4 s;
##   de 1,6 a 2,2 s o atleta afunda na base (quadril de 0,74 a 0,70 m) e o
##   contato é em 2,2 s; até 3,0 s os braços seguem e ele começa a levantar.
## - saque em pé (DeepMotion, vídeo em câmera lenta, 2x): começa em 4,1 s com a
##   bola na mão, lança em ~4,4 s e o braço direito passa por cima da cabeça (a
##   batida) em 5,3 s, que a 2x cai em 0,6 s (BATIDA_DO_FLUTUANTE da partida).
## - saque viagem (DeepMotion, câmera lenta, 3x): corrida de 1,75 a 3,6 s (0,62 s
##   no jogo, CORRIDA_DO_SAQUE_VIAGEM), sai do chão em 3,6 s, bate com a mão
##   esquerda no alto em 4,9 s (1,05 s depois de soltar, metade do pulo) e cai
##   em 6,25 s. Até 13/11/2026 o jogo mostrava só o pulo, a 4,4x.
## - levantamento (toque de verdade, DeepMotion): de 0 a 1,2 s os joelhos
##   dobrados e as mãos na frente do peito (parecia manchete, por isso o preparo
##   começa em 0,9 s); as mãos chegam na testa em 1,45 s, o contato; até 2,4 s
##   braços e pernas terminam de empurrar a bola (mãos a 1,72 m).
const TRECHOS := {
	"manchete": [2.2, 3.0],
	"levantamento": [1.45, 2.4],
	"cortada": [1.25, 2.0, 1.23],
	"bloqueio": [0.55, 1.6],
	"saque": [4.1, 6.6, 2.0],
	"saque_viagem": [1.75, 6.25, 3.0],
	# Mergulho a 2,2x: deita em ~0,45 s e começa a levantar em ~0,8 s, quando o
	# atleta pode andar de novo (TEMPO_NO_CHAO da partida).
	"mergulho": [0.5, 2.8, 2.2],
	# Mergulho pra direita do DeepMotion (13/11/2026, vídeo 12169434 na areia):
	# base até 0,4 s, passo largo e braço direito esticado, no chão em ~2,2 s.
	"mergulho_direita": [0.4, 3.0, 2.2],
	# Nas reações, o começo e o fim são quase parados.
	"ponto_perdido_frustrado": [0.6, 3.0],
	"ponto_perdido_desanimado": [0.1, 2.4],
}
## Os dois mergulhos: "mergulho" vai pra esquerda do atleta (+x da animação),
## "mergulho_direita" pra direita.
const MERGULHO_ESQUERDA := "mergulho"
const MERGULHO_DIREITA := "mergulho_direita"
## Mão que bate na bola na cortada, e em que segundo da animação ela bate.
const MAO_DA_CORTADA := "LeftHand"
const BATIDA_DA_CORTADA := 1.62
## Gesto da cortada, escrito à mão: a animação do DeepMotion deixava o braço
## esticado pra cima e depois cobria o rosto, sem puxar o braço pra trás nem
## chicotear. Cada linha é [segundo da animação, { osso: giro em graus }]; o giro
## é aplicado em cima da pose de referência do esqueleto humanoide (a mesma em
## todos os atletas). Eixos medidos num modelo do VRoid: nos braços, X negativo
## levanta e positivo abaixa, Z leva pra frente (esquerdo +, direito -); no
## cotovelo, Z dobra; no tronco, X positivo curva pra frente e negativo arqueia.
## O braço que bate é o esquerdo (MAO_DA_CORTADA); a batida é em BATIDA_DA_CORTADA.
const GESTO_DA_CORTADA := [
	# Armar: tronco arqueado, cotovelo alto atrás, o outro braço aponta a bola.
	[1.25, {"Spine": Vector3(-12, 12, 0), "Chest": Vector3(-12, 12, 0),
		"LeftUpperArm": Vector3(-20, 0, -25), "LeftLowerArm": Vector3(0, 0, 100),
		"RightUpperArm": Vector3(-60, 0, -50), "RightLowerArm": Vector3.ZERO}],
	# O cotovelo vem na frente, a mão ainda atrás (o "chicote" carregando).
	[1.46, {"Spine": Vector3(-18, 8, 0), "Chest": Vector3(-18, 8, 0),
		"LeftUpperArm": Vector3(-55, 0, 5), "LeftLowerArm": Vector3(0, 0, 90),
		"RightUpperArm": Vector3(-30, 0, -45), "RightLowerArm": Vector3(0, 0, -30)}],
	# Batida: braço esticado, tronco solto, o outro braço recolhido.
	[1.62, {"Spine": Vector3(2, -5, 0), "Chest": Vector3(2, -5, 0),
		"LeftUpperArm": Vector3(-80, 0, 25), "LeftLowerArm": Vector3.ZERO,
		"RightUpperArm": Vector3(65, 0, -20), "RightLowerArm": Vector3(0, 0, -70)}],
	# Finalização: o tronco dobra pra frente e o braço desce cruzando.
	[1.82, {"Spine": Vector3(25, -10, 0), "Chest": Vector3(20, -10, 0),
		"LeftUpperArm": Vector3(10, 0, 60), "LeftLowerArm": Vector3(0, 0, 30),
		"RightUpperArm": Vector3(60, 0, -10), "RightLowerArm": Vector3.ZERO}],
	[2.0, {"Spine": Vector3(25, -10, 0), "Chest": Vector3(20, -10, 0),
		"LeftUpperArm": Vector3(15, 0, 55), "LeftLowerArm": Vector3(0, 0, 25),
		"RightUpperArm": Vector3(60, 0, -10), "RightLowerArm": Vector3.ZERO}],
]

## Preparo de cada toque: [início, pose de contato] em segundos da animação.
## A pose de contato é o começo do trecho do toque (TRECHOS), então o preparo
## termina exatamente onde o toque começa.
const PREPARO := {
	"manchete": [1.6, 2.2],
	"levantamento": [0.9, 1.45],
	# Cortada: a última passada e o braço indo pra trás e subindo (0,2 a 1,0 s),
	# antes do botão; o toque (TRECHOS) continua do ar, com o braço armado.
	"cortada": [0.2, 1.0],
}
## O preparo pode tocar mais rápido ou mais devagar pra chegar junto com a bola.
const PREPARO_VELOCIDADE_MINIMA := 0.6
const PREPARO_VELOCIDADE_MAXIMA := 2.5
## Quanto o preparo segura na pose se a bola demorar um pouco mais (s).
const PREPARO_FOLGA := 0.25

## Lances em que o jogo já faz o atleta subir: aí a animação não sobe junto.
const PULAM_NO_JOGO := ["cortada", "bloqueio", "saque_viagem"]
## Em que segundo da animação medir a altura do quadril em pé (o teto do
## quadril nas que pulam no jogo). Sem entrada, é o primeiro quadro. No saque
## viagem o DeepMotion deixou o corpo flutuando no começo (a câmera mexe), então
## mede na hora de sair do chão.
const QUADRIL_EM_PE := {"saque_viagem": 3.6}
## Lances em que o quadril fica sempre virado como na hora da batida (segundo da
## animação): o vídeo do saque viagem foi filmado com a câmera acompanhando o
## atleta de lado, e a corrida saía uns 75° virada (pedido do Victor, 13/11/2026).
## O tronco ainda gira sobre o quadril, como numa batida de verdade.
const GIRO_TRAVADO := {"saque_viagem": 4.9}

## Velocidade (m/s) em que a corrida toca na velocidade normal.
const VELOCIDADE_DA_CORRIDA := 4.0
const PARADO_ABAIXO_DE := 0.4
const MISTURA := 0.15
const TELEPORTE := 15.0

## Cabeça acompanhando a bola (olhar_para): até onde a cabeça pode virar em
## relação ao corpo, quanto o olhar soma à animação (graus) e quanto do caminho
## até a bola ela faz (0 a 1).
const OLHAR_LIMITE := 75.0
const OLHAR_GIRO_MAXIMO := 55.0
const OLHAR_PARTE := 0.8

const OlharDaCabeca := preload("res://scripts/visual/olhar_da_cabeca.gd")

const BIBLIOTECA := "volei"
static var _biblioteca: AnimationLibrary

## Pra onde o personagem olha quando está parado (a rede).
var giro_da_rede := 0.0
## Animação de quando ele está parado em quadra: "espera" (pronto) ou
## "espera_defesa" (agachado esperando o ataque do outro time). A partida troca.
var parado_no_jogo := PARADO_NO_JOGO
var _personagem: Node3D
var _player: AnimationPlayer
var _ultima_posicao := Vector3.ZERO
var _tempo_do_lance := 0.0
var _sai_ao_andar := false
var _carencia := 0.0
var _em_loop := ""
var _altura_da_mao := -1.0


## Liga o animador ao personagem (o nó do .vrm). Devolve false se o personagem
## não tem AnimationPlayer (aí ele só fica parado em T).
func preparar(personagem: Node3D, giro: float) -> bool:
	_personagem = personagem
	giro_da_rede = giro
	_personagem.rotation.y = giro
	_player = personagem.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if _player == null:
		return false
	if not _player.has_animation_library(BIBLIOTECA):
		_player.add_animation_library(BIBLIOTECA, biblioteca())
	_tocar_loop(PARADO_NO_JOGO)
	return true


func _ready() -> void:
	_ultima_posicao = _posicao_do_atleta()


## Toca um lance ("manchete", "cortada", "comemoracao_palmas"...).
## Comemorações ficam em loop até o próximo lance ou movimento.
func tocar(lance: String) -> void:
	if _player == null or not ARQUIVOS.has(lance):
		return
	var nome := BIBLIOTECA + "/" + lance
	if lance in EM_LOOP:
		_tocar_loop(lance)
		_player.speed_scale = 1.0
		_tempo_do_lance = 9999.0
		_sai_ao_andar = true
		_carencia = 0.0
		return
	_sai_ao_andar = lance in SAEM_AO_ANDAR
	_carencia = CARENCIA
	var trecho: Array = TRECHOS.get(lance, [0.0, _player.get_animation(nome).length])
	_player.play(nome, MISTURA)
	_player.seek(trecho[0], true)
	var velocidade: float = trecho[2] if trecho.size() > 2 else 1.0
	_player.speed_scale = velocidade
	_tempo_do_lance = (trecho[1] - trecho[0]) / velocidade
	_em_loop = ""
	_personagem.rotation.y = giro_da_rede


## Começa o preparo do toque ("manchete" ou "levantamento") pra pose de contato
## ficar pronta daqui a "segundos_ate_a_bola". Quando o toque vem (tocar), ele
## continua dali, sem pulo na pose. Se o toque não vier, volta pro movimento
## normal. Devolve true se começou.
func preparar_toque(lance: String, segundos_ate_a_bola: float) -> bool:
	if _player == null or not PREPARO.has(lance) or _tempo_do_lance > 0.0:
		return false
	var trecho: Array = PREPARO[lance]
	var duracao: float = trecho[1] - trecho[0]
	var velocidade := clampf(duracao / maxf(segundos_ate_a_bola, 0.01), PREPARO_VELOCIDADE_MINIMA, PREPARO_VELOCIDADE_MAXIMA)
	_player.play(BIBLIOTECA + "/" + lance, MISTURA)
	_player.seek(trecho[0], true)
	_player.speed_scale = velocidade
	_tempo_do_lance = duracao / velocidade + PREPARO_FOLGA
	# Pode estar chegando na bola: não para no meio do preparo por andar.
	_sai_ao_andar = true
	_carencia = duracao / velocidade
	_em_loop = ""
	_personagem.rotation.y = giro_da_rede
	return true


## Mergulho pro lado do "rumo" (direção no chão, x e z do mundo) em relação a
## pra onde o atleta olha (a rede).
func mergulhar(rumo: Vector2) -> void:
	tocar(lance_do_mergulho(rumo, giro_da_rede))


## Qual dos dois mergulhos vai pro lado do "rumo", com o atleta virado em "giro".
## O personagem olha pro +z dele; a esquerda dele é o +x, que no mundo fica em
## (cos giro, -sen giro).
static func lance_do_mergulho(rumo: Vector2, giro: float) -> String:
	var esquerda := Vector2(cos(giro), -sin(giro))
	return MERGULHO_ESQUERDA if rumo.dot(esquerda) >= 0.0 else MERGULHO_DIREITA


## Onde está agora a mão que bate na cortada (no mundo), ou null se o
## personagem não tem esse osso.
func posicao_da_mao():
	var esqueleto := _esqueleto()
	if esqueleto == null:
		return null
	var osso := esqueleto.find_bone(MAO_DA_CORTADA)
	if osso < 0:
		return null
	return esqueleto.global_transform * esqueleto.get_bone_global_pose(osso).origin


## Altura da mão da cortada acima dos pés, na pose da batida. Medida uma vez
## (põe o personagem na pose por um instante; chame logo antes de tocar um lance).
func altura_da_mao_na_batida() -> float:
	if _altura_da_mao >= 0.0:
		return _altura_da_mao
	var atleta := get_parent() as Node3D
	if _player == null or atleta == null or not atleta.is_inside_tree():
		return 2.35
	_player.play(BIBLIOTECA + "/cortada")
	_player.seek(BATIDA_DA_CORTADA, true)
	_player.advance(0.0)
	var mao = posicao_da_mao()
	_em_loop = ""
	if mao == null:
		return 2.35
	_altura_da_mao = (mao as Vector3).y - atleta.global_position.y
	return _altura_da_mao


func _esqueleto() -> Skeleton3D:
	if _personagem == null:
		return null
	var esqueleto := _personagem.get_node_or_null("%GeneralSkeleton") as Skeleton3D
	if esqueleto == null:
		esqueleto = _personagem.get_node_or_null("GeneralSkeleton") as Skeleton3D
	return esqueleto


## Faz a cabeça do atleta acompanhar "alvo" (a bola), em vez de ficar fixa
## olhando pra rede (veja olhar_da_cabeca.gd: roda por cima da animação, com
## limite de ângulo pra não torcer o pescoço).
## Devolve false se o personagem não tem osso "Head" (cápsula, outro esqueleto).
func olhar_para(alvo: Node3D) -> bool:
	var esqueleto := _esqueleto()
	if esqueleto == null or alvo == null or esqueleto.find_bone("Head") < 0:
		return false
	var olhar := OlharDaCabeca.new()
	olhar.name = "OlharABola"
	olhar.referencia = _personagem
	olhar.alvo = alvo
	olhar.limite = deg_to_rad(OLHAR_LIMITE)
	olhar.giro_maximo = deg_to_rad(OLHAR_GIRO_MAXIMO)
	olhar.parte = OLHAR_PARTE
	esqueleto.add_child(olhar)
	return true


## Volta pro movimento normal (fim de uma comemoração, novo saque).
func soltar() -> void:
	_tempo_do_lance = 0.0


func _process(delta: float) -> void:
	if _player == null or delta <= 0.0:
		return
	var agora := _posicao_do_atleta()
	var andou := Vector2(agora.x - _ultima_posicao.x, agora.z - _ultima_posicao.z) / delta
	_ultima_posicao = agora
	# Mudou de lugar de uma vez (formação do saque): não é corrida.
	if andou.length() > TELEPORTE:
		andou = Vector2.ZERO

	if _tempo_do_lance > 0.0:
		_tempo_do_lance -= delta
		_carencia -= delta
		if not _sai_ao_andar or _carencia > 0.0 or andou.length() < PARADO_ABAIXO_DE:
			return
		_tempo_do_lance = 0.0

	var velocidade := andou.length()
	if velocidade < PARADO_ABAIXO_DE:
		_tocar_loop(parado_no_jogo)
		_player.speed_scale = 1.0
		_virar_para(giro_da_rede, delta)
		return

	# De frente pra rede, andar pro lado é passo lateral; o resto é corrida
	# virada pra onde ele vai.
	var frente := Vector2(sin(giro_da_rede), cos(giro_da_rede))
	var lado := Vector2(frente.y, -frente.x)
	var pro_lado := andou.dot(lado)
	if absf(pro_lado) > absf(andou.dot(frente)) * 1.5:
		_tocar_loop("lateral_esquerda" if pro_lado < 0.0 else "lateral_direita")
		_player.speed_scale = clampf(velocidade / 3.0, 0.7, 1.6)
		_virar_para(giro_da_rede, delta)
	else:
		_tocar_loop("correr")
		_player.speed_scale = clampf(velocidade / VELOCIDADE_DA_CORRIDA, 0.7, 1.6)
		_virar_para(atan2(andou.x, andou.y), delta)


func _tocar_loop(nome: String) -> void:
	if _em_loop == nome:
		return
	_em_loop = nome
	_player.play(BIBLIOTECA + "/" + nome, MISTURA)


func _virar_para(alvo: float, delta: float) -> void:
	_personagem.rotation.y = lerp_angle(_personagem.rotation.y, alvo, minf(1.0, delta * 12.0))


func _posicao_do_atleta() -> Vector3:
	var atleta := get_parent() as Node3D
	return atleta.global_position if atleta and atleta.is_inside_tree() else Vector3.ZERO


## Todas as animações, já no esqueleto comum, sem o personagem sair do lugar.
static func biblioteca() -> AnimationLibrary:
	if _biblioteca:
		return _biblioteca
	_biblioteca = AnimationLibrary.new()
	for nome in ARQUIVOS:
		var animacao := _carregar(ARQUIVOS[nome])
		if animacao == null:
			push_warning("Animação %s não carregou (%s)." % [nome, ARQUIVOS[nome]])
			continue
		animacao.loop_mode = Animation.LOOP_LINEAR if nome in EM_LOOP else Animation.LOOP_NONE
		_no_lugar(animacao, nome in PULAM_NO_JOGO, QUADRIL_EM_PE.get(nome, -1.0))
		if GIRO_TRAVADO.has(nome):
			_travar_giro(animacao, GIRO_TRAVADO[nome])
		if nome == "cortada":
			_gesto_da_cortada(animacao)
		_biblioteca.add_animation(nome, animacao)
	if _biblioteca.has_animation("parado"):
		_biblioteca.add_animation("espera", _pose_de_espera(_biblioteca.get_animation("parado")))
	return _biblioteca


## A "parado" virada pose de espera (veja POSE_DE_ESPERA): cada chave de
## rotação dos ossos da lista ganha o giro, e o quadril desce.
static func _pose_de_espera(parado: Animation) -> Animation:
	var espera := parado.duplicate(true) as Animation
	espera.loop_mode = Animation.LOOP_LINEAR
	var perfil := SkeletonProfileHumanoid.new()
	for item in POSE_DE_ESPERA:
		for lado in ["Left", "Right"]:
			var osso: String = item[0] if item[0] in ["Spine", "Chest"] else lado + str(item[0])
			if osso.begins_with("Right") and item[0] in ["Spine", "Chest"]:
				continue
			var angulo: float = item[2]
			if osso.begins_with("Right") and str(item[0]).ends_with("Arm"):
				angulo = -angulo
			var giro := Quaternion(item[1], angulo)
			var trilha := espera.find_track(NodePath("%GeneralSkeleton:" + osso), Animation.TYPE_ROTATION_3D)
			if trilha < 0:
				# Sem trilha: parte da pose de referência do perfil humanoide.
				trilha = espera.add_track(Animation.TYPE_ROTATION_3D)
				espera.track_set_path(trilha, NodePath("%GeneralSkeleton:" + osso))
				var indice := perfil.find_bone(osso)
				var base := perfil.get_reference_pose(indice).basis.get_rotation_quaternion() if indice >= 0 else Quaternion.IDENTITY
				espera.rotation_track_insert_key(trilha, 0.0, base)
			for chave in espera.track_get_key_count(trilha):
				var valor: Quaternion = espera.track_get_key_value(trilha, chave)
				espera.track_set_key_value(trilha, chave, valor * giro)
	var quadril := espera.find_track(NodePath("%GeneralSkeleton:Hips"), Animation.TYPE_POSITION_3D)
	if quadril >= 0:
		for chave in espera.track_get_key_count(quadril):
			var valor: Vector3 = espera.track_get_key_value(quadril, chave)
			espera.track_set_key_value(quadril, chave, valor - Vector3(0.0, DESCIDA_DO_QUADRIL, 0.0))
	return espera


## Troca o movimento do tronco e dos braços da cortada pelo GESTO_DA_CORTADA
## (as pernas e o resto continuam os da animação).
static func _gesto_da_cortada(animacao: Animation) -> void:
	var perfil := SkeletonProfileHumanoid.new()
	var ossos := {}
	for chave in GESTO_DA_CORTADA:
		for osso in chave[1]:
			ossos[osso] = true
	# Mesmo nó das outras trilhas (o do esqueleto), pra a trilha nova casar.
	var no_do_esqueleto := "%GeneralSkeleton"
	var trilha_do_quadril := animacao.find_track(NodePath("%GeneralSkeleton:Hips"), Animation.TYPE_POSITION_3D)
	if trilha_do_quadril >= 0:
		no_do_esqueleto = str(animacao.track_get_path(trilha_do_quadril).get_concatenated_names())
	for osso in ossos:
		var caminho := NodePath(no_do_esqueleto + ":" + str(osso))
		var trilha := animacao.find_track(caminho, Animation.TYPE_ROTATION_3D)
		if trilha >= 0:
			animacao.remove_track(trilha)
		trilha = animacao.add_track(Animation.TYPE_ROTATION_3D)
		animacao.track_set_path(trilha, caminho)
		var base := perfil.get_reference_pose(perfil.find_bone(str(osso))).basis.get_rotation_quaternion()
		for chave in GESTO_DA_CORTADA:
			var graus: Vector3 = chave[1].get(osso, Vector3.ZERO)
			var giro := Quaternion.from_euler(Vector3(deg_to_rad(graus.x), deg_to_rad(graus.y), deg_to_rad(graus.z)))
			animacao.rotation_track_insert_key(trilha, float(chave[0]), base * giro)


static func _carregar(caminho: String) -> Animation:
	var recurso = load(caminho)
	if recurso is Animation:
		return recurso.duplicate()
	if recurso is PackedScene:
		var cena: Node = recurso.instantiate()
		var player := cena.get_node_or_null("AnimationPlayer") as AnimationPlayer
		var animacao: Animation = null
		if player and player.has_animation("mixamo_com"):
			animacao = player.get_animation("mixamo_com").duplicate()
		cena.free()
		return animacao
	return null


## Trava o quadril no lugar no chão (x e z): quem anda é o atleta, não a animação.
## Com "sem_subir", trava a altura também, porque o jogo já faz o pulo.
## Deixa o quadril sempre virado pro mesmo lado que no segundo "referencia"
## (só o giro em volta do eixo vertical; inclinação e o resto do corpo ficam).
static func _travar_giro(animacao: Animation, referencia: float) -> void:
	for trilha in animacao.get_track_count():
		if animacao.track_get_type(trilha) != Animation.TYPE_ROTATION_3D:
			continue
		# Quadril e tronco: sem isso o peito gira pro lado na corrida.
		if not animacao.track_get_path(trilha).get_concatenated_subnames() in ["Hips", "Spine", "Chest", "UpperChest"]:
			continue
		var alvo := _giro_vertical(animacao.rotation_track_interpolate(trilha, referencia))
		for chave in animacao.track_get_key_count(trilha):
			var valor: Quaternion = animacao.track_get_key_value(trilha, chave)
			var sobra := wrapf(_giro_vertical(valor) - alvo, -PI, PI)
			animacao.track_set_key_value(trilha, chave, (Quaternion(Vector3.UP, -sobra) * valor).normalized())


## Para que lado (ângulo em volta do eixo vertical) aponta a frente do quadril.
static func _giro_vertical(rotacao: Quaternion) -> float:
	var frente := rotacao * Vector3(0, 0, 1)
	return atan2(frente.x, frente.z)

static func _no_lugar(animacao: Animation, sem_subir: bool, quadril_em_pe := -1.0) -> void:
	for trilha in animacao.get_track_count():
		if animacao.track_get_type(trilha) != Animation.TYPE_POSITION_3D:
			continue
		if animacao.track_get_path(trilha).get_concatenated_subnames() != "Hips":
			continue
		if animacao.track_get_key_count(trilha) == 0:
			continue
		var inicio: Vector3 = animacao.track_get_key_value(trilha, 0)
		if quadril_em_pe >= 0.0:
			# Só a altura vem desse segundo; x e z ficam os do começo (onde o
			# atleta está), senão o corpo aparece metros à frente do anel.
			inicio.y = animacao.position_track_interpolate(trilha, quadril_em_pe).y
		for chave in animacao.track_get_key_count(trilha):
			var valor: Vector3 = animacao.track_get_key_value(trilha, chave)
			valor.x = inicio.x
			valor.z = inicio.z
			if sem_subir:
				valor.y = minf(valor.y, inicio.y)
			animacao.track_set_key_value(trilha, chave, valor)
