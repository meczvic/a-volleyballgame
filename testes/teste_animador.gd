extends SceneTree
## Confere o animador dos personagens (scripts/visual/animador.gd): todas as
## animações carregam, as de movimento repetem, os lances não, e nenhuma
## tira o personagem do lugar (quem anda é o atleta, não a animação).
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_animador.gd

const Animador := preload("res://scripts/visual/animador.gd")

var falhas := 0


func _init() -> void:
	var biblioteca := Animador.biblioteca()
	for nome in Animador.ARQUIVOS:
		_verificar(biblioteca.has_animation(nome), "a animação %s carregou" % nome)
	for nome in Animador.TRECHOS:
		_verificar(Animador.ARQUIVOS.has(nome), "o trecho de %s tem animação" % nome)

	for nome in biblioteca.get_animation_list():
		var animacao := biblioteca.get_animation(nome)
		var repete := animacao.loop_mode != Animation.LOOP_NONE
		_verificar(repete == (nome in Animador.EM_LOOP), "%s repete só se for movimento ou comemoração" % nome)
		if Animador.TRECHOS.has(nome):
			var trecho: Array = Animador.TRECHOS[nome]
			_verificar(trecho[0] < trecho[1] and trecho[1] <= animacao.length + 0.01,
				"o trecho de %s cabe na animação (%.2f s)" % [nome, animacao.length])
			_verificar(trecho.size() == 2 or (trecho.size() == 3 and trecho[2] > 0.0),
				"o trecho de %s é [início, fim] ou [início, fim, velocidade]" % nome)
		_teste_no_lugar(nome, animacao)

	# Carregar de novo não refaz o trabalho.
	_verificar(Animador.biblioteca() == biblioteca, "a biblioteca é carregada uma vez só")

	if falhas == 0:
		print("OK: as %d animações do animador estão prontas." % biblioteca.get_animation_list().size())
	else:
		print("FALHOU: %d verificação(ões) do animador." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


## O quadril não anda no chão; na cortada e no bloqueio também não sobe
## (o pulo é do jogo).
func _teste_no_lugar(nome: String, animacao: Animation) -> void:
	var trilha := animacao.find_track(NodePath("%GeneralSkeleton:Hips"), Animation.TYPE_POSITION_3D)
	if trilha < 0:
		return
	var inicio: Vector3 = animacao.track_get_key_value(trilha, 0)
	var maior_y := inicio.y
	for chave in animacao.track_get_key_count(trilha):
		var valor: Vector3 = animacao.track_get_key_value(trilha, chave)
		_verificar(is_equal_approx(valor.x, inicio.x) and is_equal_approx(valor.z, inicio.z),
			"%s não tira o quadril do lugar" % nome)
		maior_y = maxf(maior_y, valor.y)
		if not is_equal_approx(valor.x, inicio.x) or not is_equal_approx(valor.z, inicio.z):
			return
	if nome in Animador.PULAM_NO_JOGO:
		_verificar(maior_y <= inicio.y + 0.001, "%s não sobe (o jogo já faz o pulo)" % nome)
