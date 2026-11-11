extends SceneTree
## Captura os atletas renderizados pelo próprio jogo (sem arte conceitual).
##
## Precisa de janela (ou tela virtual, veja docs/ESTADO_DO_PROJETO.md):
##
##   godot --path . --script res://ferramentas/capturas.gd -- folha=karasuno
##   godot --path . --script res://ferramentas/capturas.gd -- atleta=karasuno/10_hinata
##   godot --path . --script res://ferramentas/capturas.gd -- todos
##
## Saída em producao/capturas/<time>/:
##   folha.png                     os 6 do time, frente (em cima) e costas (embaixo)
##   <nn>_<nome>_<vista>.png       frente, perfil, tres_quartos, costas, correr, cortada, espera
##
## O atleta vem do mesmo caminho da partida (Dados.carregar_personagem): VRM se
## existir, senão o gerado por código, senão a cápsula.

const Dados := preload("res://scripts/comum/dados.gd")
const Animador := preload("res://scripts/visual/animador.gd")

const VISTAS := {
	"frente": [0.0, "parado", 0.0],
	"tres_quartos": [PI * 0.25, "parado", 0.0],
	"perfil": [PI * 0.5, "parado", 0.0],
	"costas": [PI, "parado", 0.0],
	"correr": [PI * 0.2, "correr", 0.35],
	"cortada": [PI * 0.3, "cortada", 1.62],
	"espera": [PI * 0.2, "espera", 0.5],
}
const PASTA := "res://producao/capturas"

var _mundo: Node3D
var _camera: Camera3D
var _tarefas := []
var _largura := 1280
var _altura := 720


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var pedidos := {}
	for arg in args:
		var partes := arg.split("=")
		pedidos[partes[0]] = partes[1] if partes.size() > 1 else ""
	_montar_mundo()
	var times := Dados.times()
	if pedidos.has("todos"):
		for time in times:
			_tarefas.append(["folha", str(time["id"]), ""])
			for atleta in Dados.elenco(str(time["id"])):
				_tarefas.append(["atleta", str(time["id"]), "%02d_%s" % [int(atleta["numero"]), str(atleta["arquivo"])]])
	if pedidos.has("folha"):
		for id in str(pedidos["folha"]).split(","):
			_tarefas.append(["folha", id, ""])
	if pedidos.has("atleta"):
		for chave in str(pedidos["atleta"]).split(","):
			var partes := chave.split("/")
			_tarefas.append(["atleta", partes[0], partes[1]])
	if _tarefas.is_empty():
		print("Nada pedido. Use folha=<time>, atleta=<time>/<nn>_<nome> ou todos.")
		quit()
		return
	_executar()


func _montar_mundo() -> void:
	_mundo = Node3D.new()
	get_root().add_child(_mundo)
	get_root().size = Vector2i(_largura, _altura)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, 35, 0)
	luz.light_energy = 1.3
	luz.shadow_enabled = true
	_mundo.add_child(luz)
	var ambiente := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#3A3F4A")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.78, 0.85)
	env.ambient_light_energy = 0.9
	ambiente.environment = env
	_mundo.add_child(ambiente)
	var chao := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(20, 20)
	chao.mesh = plano
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#C8894E")
	chao.material_override = mat
	_mundo.add_child(chao)
	_camera = Camera3D.new()
	_camera.fov = 36
	_mundo.add_child(_camera)
	_camera.current = true


func _executar() -> void:
	await process_frame
	await process_frame
	for tarefa in _tarefas:
		if tarefa[0] == "folha":
			await _folha(tarefa[1])
		else:
			await _atleta(tarefa[1], tarefa[2])
	quit()


## Os 6 atletas do time lado a lado, de frente e de costas, numa imagem.
func _folha(id_time: String) -> void:
	var time := Dados.por_id(Dados.times(), id_time)
	var elenco := Dados.elenco(id_time)
	var imagens := []
	for costas in [false, true]:
		var grupo := Node3D.new()
		_mundo.add_child(grupo)
		var k := 0
		for atleta in elenco:
			var personagem := _personagem(time, atleta, 0)
			personagem.position = Vector3((k - 2.5) * 0.8, 0, 0)
			personagem.rotation.y = PI if costas else 0.0
			grupo.add_child(personagem)
			_preparar_animacao(personagem, "parado", 0.0)
			k += 1
		_camera.position = Vector3(0, 1.2, 8.0)
		_camera.look_at(Vector3(0, 1.0, 0))
		await process_frame
		await process_frame
		imagens.append(get_root().get_texture().get_image())
		grupo.queue_free()
		await process_frame
	var folha := Image.create(_largura, _altura * 2, false, imagens[0].get_format())
	folha.blit_rect(imagens[0], Rect2i(0, 0, _largura, _altura), Vector2i(0, 0))
	folha.blit_rect(imagens[1], Rect2i(0, 0, _largura, _altura), Vector2i(0, _altura))
	var caminho := "%s/%s/folha.png" % [PASTA, id_time]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(caminho.get_base_dir()))
	folha.save_png(caminho)
	print("salvo ", caminho)


## Um atleta em close, em cada vista de VISTAS.
func _atleta(id_time: String, chave: String) -> void:
	var time := Dados.por_id(Dados.times(), id_time)
	var dados_atleta := {}
	for atleta in Dados.elenco(id_time):
		if "%02d_%s" % [int(atleta["numero"]), str(atleta["arquivo"])] == chave:
			dados_atleta = atleta
	if dados_atleta.is_empty():
		print("Atleta não achado: ", id_time, "/", chave)
		return
	for vista in VISTAS:
		var cfg: Array = VISTAS[vista]
		var personagem := _personagem(time, dados_atleta, 0)
		_mundo.add_child(personagem)
		personagem.rotation.y = cfg[0]
		_preparar_animacao(personagem, cfg[1], cfg[2])
		var altura: float = float(personagem.get_meta("altura", 1.8))
		var alvo := Vector3(0, altura * 0.55, 0)
		if vista == "cortada":
			alvo.y = altura * 0.75
		_camera.position = alvo + Vector3(0, 0.15, altura * 2.25)
		_camera.look_at(alvo)
		await process_frame
		await process_frame
		var caminho := "%s/%s/%s_%s.png" % [PASTA, id_time, chave, vista]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(caminho.get_base_dir()))
		get_root().get_texture().get_image().save_png(caminho)
		personagem.queue_free()
		await process_frame
	print("salvo ", "%s/%s/%s_*.png" % [PASTA, id_time, chave])


func _personagem(time: Dictionary, atleta: Dictionary, _lado: int) -> Node3D:
	var personagem := Dados.carregar_personagem(time, atleta)
	if personagem == null:
		# Sem personagem: cápsula só pra folha não ficar vazia.
		personagem = Node3D.new()
		var corpo := MeshInstance3D.new()
		corpo.mesh = CapsuleMesh.new()
		corpo.position.y = 1.0
		personagem.add_child(corpo)
		personagem.set_meta("altura", 1.8)
	return personagem


func _preparar_animacao(personagem: Node3D, nome: String, instante: float) -> void:
	var player := personagem.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player == null:
		return
	if not player.has_animation_library(Animador.BIBLIOTECA):
		player.add_animation_library(Animador.BIBLIOTECA, Animador.biblioteca())
	player.play(Animador.BIBLIOTECA + "/" + nome)
	player.seek(instante, true)
	player.advance(0.0)
	player.pause()
