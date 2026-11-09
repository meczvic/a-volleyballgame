extends SceneTree
## Monta as animações que o Mixamo não tem, juntando pedaços das que já temos.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://ferramentas/animacoes_combinadas.gd
##
## cortada.tres:      pulo do bloqueio + braço esquerdo do saque (a batida
##                    acontece no alto do pulo). O braço direito sobe junto.
## levantamento.tres: corpo parado + braços do bloqueio subindo acima da cabeça.
##
## Os tempos abaixo foram medidos num modelo do VRoid (altura das mãos e do quadril).

const FPS := 30.0
const ESQUERDO := ["LeftShoulder", "LeftUpperArm", "LeftLowerArm", "LeftHand"]
const DIREITO := ["RightShoulder", "RightUpperArm", "RightLowerArm", "RightHand"]


func _init() -> void:
	var bloqueio := _animacao("bloqueio")
	var saque := _animacao("saque")
	var parado := _animacao("parado")

	# Cortada: 0 a 1,7 s do bloqueio (agacha, pula, cai). O braço do saque entra
	# entre 0,17 e 1,13 s, com a batida (saque em 1,45 s) no alto do pulo (0,85 s).
	var cortada := _combinar(bloqueio, 0.0, 1.7, saque, _com_dedos(ESQUERDO),
		func(t: float) -> float: return 1.45 + (t - 0.85) / 0.8, 0.17, 1.13)
	_salvar(cortada, "res://animacoes/cortada.tres")

	# Levantamento: pernas paradas (sem pulo); tronco e braços vêm do bloqueio
	# entre 0,4 e 1,1 s, quando as mãos sobem acima da cabeça e voltam.
	var cima := _com_dedos(ESQUERDO) + _com_dedos(DIREITO) + ["Spine", "Chest", "UpperChest", "Neck", "Head"]
	var levantamento := _combinar(parado, 0.0, 1.0, bloqueio, cima,
		func(t: float) -> float: return 0.4 + t * 0.7, 0.12, 0.88)
	_salvar(levantamento, "res://animacoes/levantamento.tres")
	quit()


func _animacao(nome: String) -> Animation:
	var cena: Node = load("res://animacoes/%s.fbx" % nome).instantiate()
	var animacao: Animation = cena.get_node("AnimationPlayer").get_animation("mixamo_com").duplicate()
	cena.free()
	return animacao


## Os ossos do braço e os dos dedos daquela mão.
func _com_dedos(braco: Array) -> Array:
	var lado := "Left" if braco[0].begins_with("Left") else "Right"
	var ossos := braco.duplicate()
	for dedo in ["Thumb", "Index", "Middle", "Ring", "Little"]:
		for parte in ["Metacarpal", "Proximal", "Intermediate", "Distal"]:
			ossos.append(lado + dedo + parte)
	return ossos


## Copia "base" entre inicio e fim. Nos "ossos", troca pelo que "extra" faz no
## tempo tempo_extra(t), só entre janela_ini e janela_fim, com transição suave.
func _combinar(base: Animation, inicio: float, fim: float, extra: Animation, ossos: Array,
		tempo_extra: Callable, janela_ini: float, janela_fim: float) -> Animation:
	var nova := Animation.new()
	nova.length = fim - inicio
	var quadros := int(round(nova.length * FPS))
	for trilha in base.get_track_count():
		var tipo := base.track_get_type(trilha)
		if tipo != Animation.TYPE_POSITION_3D and tipo != Animation.TYPE_ROTATION_3D:
			continue
		var caminho := base.track_get_path(trilha)
		var osso := caminho.get_concatenated_subnames()
		var trilha_extra := extra.find_track(caminho, tipo) if osso in ossos else -1
		var nova_trilha := nova.add_track(tipo)
		nova.track_set_path(nova_trilha, caminho)
		for q in quadros + 1:
			var t := q / FPS
			var t_base := inicio + t
			if tipo == Animation.TYPE_POSITION_3D:
				nova.position_track_insert_key(nova_trilha, t, base.position_track_interpolate(trilha, t_base))
				continue
			var rotacao := base.rotation_track_interpolate(trilha, t_base)
			if trilha_extra >= 0:
				var peso := _peso(t, janela_ini, janela_fim, 0.12)
				var t_extra := clampf(tempo_extra.call(t), 0.0, extra.length)
				rotacao = rotacao.slerp(extra.rotation_track_interpolate(trilha_extra, t_extra), peso)
			nova.rotation_track_insert_key(nova_trilha, t, rotacao)
	return nova


## 0 fora da janela, 1 dentro, com rampa suave de "rampa" segundos nas pontas.
func _peso(t: float, ini: float, fim: float, rampa: float) -> float:
	return smoothstep(ini - rampa, ini, t) * (1.0 - smoothstep(fim, fim + rampa, t))


func _salvar(animacao: Animation, caminho: String) -> void:
	var erro := ResourceSaver.save(animacao, caminho)
	print("%s: %d trilhas, %.2f s (%s)" % [caminho, animacao.get_track_count(), animacao.length, error_string(erro)])
