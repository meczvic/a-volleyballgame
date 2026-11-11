extends SubViewportContainer
## Retrato 3D do atleta destaque do time, desenhado ao vivo na seleção.
##
## Usa o mesmo personagem da partida (Dados.carregar_personagem: VRM, gerado ou
## nada), num mundo 3D só dele, com fundo transparente. Parado, ele respira na
## pose de espera; quando o jogador confirma, comemora.
##
## Uso: configurar(olhando_pra_direita) uma vez; mostrar(time) quando o cursor
## muda; comemorar(true/false) quando confirma ou desfaz.

const Dados := preload("res://scripts/comum/dados.gd")
const Animador := preload("res://scripts/visual/animador.gd")

## Quanto o atleta vira pro meio da tela (rad): 0 = de frente.
const GIRO := 0.42
## Distância da câmera em "alturas do atleta" e abertura (graus).
const DISTANCIA := 2.75
const ABERTURA := 30.0
const MISTURA := 0.25

var _mundo: Node3D
var _camera: Camera3D
var _luz_de_contorno: DirectionalLight3D
var _personagem: Node3D
var _player: AnimationPlayer
## chave "<time>|<cores>" -> personagem já montado (fora da árvore).
var _guardados := {}
var _olhando_pra_direita := true
var _comemorando := false


func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_4X
	add_child(viewport)

	_mundo = Node3D.new()
	viewport.add_child(_mundo)

	var ambiente := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.82, 0.84, 0.9)
	env.ambient_light_energy = 0.45
	ambiente.environment = env
	_mundo.add_child(ambiente)

	# Luz principal quente, de frente e de cima.
	var principal := DirectionalLight3D.new()
	principal.rotation_degrees = Vector3(-35.0, 25.0, 0.0)
	principal.light_energy = 1.0
	principal.light_color = Color(1.0, 0.95, 0.88)
	_mundo.add_child(principal)

	# Luz de contorno, de trás, na cor do time: separa o atleta do fundo.
	_luz_de_contorno = DirectionalLight3D.new()
	_luz_de_contorno.rotation_degrees = Vector3(-20.0, 160.0, 0.0)
	_luz_de_contorno.light_energy = 2.2
	_mundo.add_child(_luz_de_contorno)

	_camera = Camera3D.new()
	_camera.fov = ABERTURA
	_camera.current = true
	_mundo.add_child(_camera)


## Os atletas guardados fora da árvore não somem sozinhos: libera ao sair.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for personagem in _guardados.values():
			if is_instance_valid(personagem) and not personagem.is_inside_tree():
				personagem.free()
		_guardados.clear()


func configurar(olhando_pra_direita: bool) -> void:
	_olhando_pra_direita = olhando_pra_direita


## Mostra o atleta destaque de "time" (já com o uniforme reserva, se for o caso).
func mostrar(time: Dictionary, cor_de_contorno: Color) -> void:
	_luz_de_contorno.light_color = cor_de_contorno
	var chave := "%s|%s" % [time.get("id", ""), str(time.get("cores", []))]
	if _personagem != null:
		_mundo.remove_child(_personagem)
	_personagem = _guardados.get(chave)
	if _personagem == null:
		_personagem = Dados.carregar_personagem(time, Dados.atleta_destaque(time))
		if _personagem == null:
			_player = null
			return
		_guardados[chave] = _personagem
	_mundo.add_child(_personagem)
	_personagem.rotation.y = GIRO if _olhando_pra_direita else -GIRO

	var altura := float(_personagem.get_meta("altura", 1.8))
	var alvo := Vector3(0.0, altura * 0.5, 0.0)
	_camera.position = Vector3(0.0, altura * 0.45, altura * DISTANCIA)
	_camera.look_at(alvo)

	_player = _personagem.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if _player != null and not _player.has_animation_library(Animador.BIBLIOTECA):
		_player.add_animation_library(Animador.BIBLIOTECA, Animador.biblioteca())
	_tocar(true)


func comemorar(sim: bool) -> void:
	if sim == _comemorando:
		return
	_comemorando = sim
	_tocar(false)


func esta_comemorando() -> bool:
	return _comemorando


func animacao_atual() -> String:
	if _player == null:
		return ""
	return str(_player.current_animation).trim_prefix(Animador.BIBLIOTECA + "/")


func _tocar(do_comeco: bool) -> void:
	if _player == null:
		return
	var nome := "comemoracao_torcida" if _comemorando else "parado"
	var completo := Animador.BIBLIOTECA + "/" + nome
	if not _player.has_animation(completo):
		return
	_player.play(completo, 0.0 if do_comeco else MISTURA)
	if do_comeco:
		# Cada time começa num ponto diferente da respiração, pra não ficarem iguais.
		_player.seek(randf() * _player.current_animation_length, true)
