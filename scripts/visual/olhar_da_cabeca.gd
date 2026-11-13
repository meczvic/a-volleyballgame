extends SkeletonModifier3D
## A cabeça do atleta acompanha um alvo (a bola), por cima da animação.
##
## É um modificador do esqueleto: o Godot chama _process_modification() depois
## que a animação escreveu a pose do quadro. Gira a cabeça a partir de onde ela
## está (e não do corpo): a pose de espera deixa a cabeça baixa, e olhar a bola
## levanta o rosto. Só uma parte do giro (o resto vem da animação), com limite de
## ângulo pra não torcer o pescoço.
## (O LookAtModifier3D do Godot não fez efeito neste esqueleto, medido em
## 12/11/2026. Teste: teste_olhar_da_cabeca.gd.)

## Quem olha pra frente: o nó do personagem (o jogo vira ele inteiro; o +Z dele é a frente).
var referencia: Node3D
var alvo: Node3D
var nome_do_osso := "Head"
## Giro máximo da cabeça em relação à frente do corpo, em radianos.
var limite := deg_to_rad(75.0)
## Giro máximo que o olhar soma à pose da animação, em radianos.
var giro_maximo := deg_to_rad(55.0)
## Quanto do caminho até o alvo a cabeça faz (0 a 1).
var parte := 0.8
## Rapidez pra seguir o alvo (maior = mais rápido).
var rapidez := 14.0
## Quantas vezes o Godot chamou o modificador (os testes conferem).
var chamadas := 0

var _osso := -1
var _giro := Quaternion.IDENTITY
var _ultimo_ms := 0


func _process_modification() -> void:
	chamadas += 1
	var esqueleto := get_skeleton()
	if esqueleto == null or referencia == null or alvo == null or not is_instance_valid(alvo):
		return
	if _osso < 0:
		_osso = esqueleto.find_bone(nome_do_osso)
		if _osso < 0:
			return
	var agora := Time.get_ticks_msec()
	var delta := clampf((agora - _ultimo_ms) / 1000.0, 0.0, 0.1) if _ultimo_ms > 0 else 0.0
	_ultimo_ms = agora

	var cabeca := esqueleto.global_transform * esqueleto.get_bone_global_pose(_osso)
	var frente_da_cabeca := (cabeca.basis * Vector3(0, 0, 1)).normalized()
	var frente_do_corpo := (referencia.global_transform.basis * Vector3(0, 0, 1)).normalized()
	var para_o_alvo := alvo.global_position - cabeca.origin
	if para_o_alvo.length() < 0.2:
		return
	para_o_alvo = para_o_alvo.normalized()

	# Giro (no mundo) que leva a frente da cabeça até o alvo, só uma parte dele.
	var desejado := Quaternion.IDENTITY.slerp(Quaternion(frente_da_cabeca, para_o_alvo), parte)
	desejado = _limitar(desejado, giro_maximo)
	# Alvo atrás do atleta: não vira a cabeça pra trás, volta pro meio.
	if para_o_alvo.dot(frente_do_corpo) < -0.2:
		desejado = Quaternion.IDENTITY
	# A cabeça não passa do limite em relação à frente do corpo.
	for _i in 4:
		if (desejado * frente_da_cabeca).angle_to(frente_do_corpo) <= limite:
			break
		desejado = Quaternion.IDENTITY.slerp(desejado, 0.5)

	_giro = _giro.slerp(desejado, 1.0 - exp(-rapidez * delta))

	# Converte o giro do mundo pro espaço do osso pai e soma à pose da animação.
	var pai := esqueleto.get_bone_parent(_osso)
	var base_do_pai := (esqueleto.global_transform.basis * esqueleto.get_bone_global_pose(pai).basis).orthonormalized()
	var pose_atual := Basis(esqueleto.get_bone_pose_rotation(_osso))
	var nova := base_do_pai.inverse() * Basis(_giro) * base_do_pai * pose_atual
	esqueleto.set_bone_pose_rotation(_osso, nova.orthonormalized().get_rotation_quaternion())


func _limitar(giro: Quaternion, maximo: float) -> Quaternion:
	var angulo := giro.get_angle()
	if angulo <= maximo or angulo < 0.0001:
		return giro
	return Quaternion.IDENTITY.slerp(giro, maximo / angulo)
