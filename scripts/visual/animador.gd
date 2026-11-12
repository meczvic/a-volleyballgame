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
	"manchete": "res://animacoes/manchete.fbx",
	"levantamento": "res://animacoes/levantamento.tres",
	"cortada": "res://animacoes/cortada_deepmotion.tres",
	"bloqueio": "res://animacoes/bloqueio.fbx",
	"saque": "res://animacoes/saque.fbx",
	"mergulho": "res://animacoes/mergulho.fbx",
	"mergulho_direita": "res://animacoes/mergulho_direita.fbx",
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
const TRECHOS := {
	"manchete": [0.2, 1.2],
	"levantamento": [0.2, 1.0],
	"cortada": [1.25, 2.0, 1.23],
	"bloqueio": [0.55, 1.6],
	"saque": [1.0, 2.0],
	# Mergulho a 2,2x: deita em ~0,45 s e começa a levantar em ~0,8 s, quando o
	# atleta pode andar de novo (TEMPO_NO_CHAO da partida).
	"mergulho": [0.5, 2.8, 2.2],
	"mergulho_direita": [0.5, 2.75, 2.2],
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
## Lances em que o jogo já faz o atleta subir: aí a animação não sobe junto.
const PULAM_NO_JOGO := ["cortada", "bloqueio"]

## Velocidade (m/s) em que a corrida toca na velocidade normal.
const VELOCIDADE_DA_CORRIDA := 4.0
const PARADO_ABAIXO_DE := 0.4
const MISTURA := 0.15
const TELEPORTE := 15.0

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
		_no_lugar(animacao, nome in PULAM_NO_JOGO)
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
static func _no_lugar(animacao: Animation, sem_subir: bool) -> void:
	for trilha in animacao.get_track_count():
		if animacao.track_get_type(trilha) != Animation.TYPE_POSITION_3D:
			continue
		if animacao.track_get_path(trilha).get_concatenated_subnames() != "Hips":
			continue
		if animacao.track_get_key_count(trilha) == 0:
			continue
		var inicio: Vector3 = animacao.track_get_key_value(trilha, 0)
		for chave in animacao.track_get_key_count(trilha):
			var valor: Vector3 = animacao.track_get_key_value(trilha, chave)
			valor.x = inicio.x
			valor.z = inicio.z
			if sem_subir:
				valor.y = minf(valor.y, inicio.y)
			animacao.track_set_key_value(trilha, chave, valor)
