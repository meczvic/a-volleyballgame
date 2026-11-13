extends SceneTree
## Teste da cabeça que acompanha a bola (scripts/visual/olhar_da_cabeca.gd).
## O Godot só mostra o efeito do modificador na hora de desenhar (ler a pose do
## osso por script não enxerga), então o teste confere o que o modificador
## calcula: que ele roda, que o giro aponta pro lado certo, que respeita o
## limite e que alvo atrás do atleta não vira a cabeça pra trás. O resultado
## na tela foi conferido olhando as imagens (12/11/2026).
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_olhar_da_cabeca.gd

const Dados := preload("res://scripts/comum/dados.gd")
const Animador := preload("res://scripts/visual/animador.gd")

var falhas := 0


func _initialize() -> void:
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _rodar() -> void:
	var time: Dictionary = Dados.times()[0]
	var atleta := Node3D.new()
	root.add_child(atleta)
	var personagem := Dados.carregar_personagem(time, Dados.elenco(time["id"])[0])
	atleta.add_child(personagem)
	var animador := Animador.new()
	atleta.add_child(animador)
	_verificar(animador.preparar(personagem, PI), "o personagem tem animador")
	var esqueleto: Skeleton3D = animador._esqueleto()
	_verificar(esqueleto != null, "o personagem tem esqueleto")
	if esqueleto == null:
		quit(1)
		return
	await create_timer(0.4).timeout

	var alvo := Node3D.new()
	root.add_child(alvo)
	_verificar(animador.olhar_para(alvo), "olhar_para liga")
	var olhar = esqueleto.get_node_or_null("OlharABola")
	_verificar(olhar != null, "o modificador foi criado no esqueleto")
	if olhar == null:
		quit(1)
		return

	# O atleta olha pro -Z do mundo (giro PI). A bola de lado e em cima puxa a cabeça.
	var giros := {}
	for nome in {"direita": Vector3(3.0, 1.6, -2.0), "esquerda": Vector3(-3.0, 1.6, -2.0), "em cima": Vector3(0.0, 6.0, -3.0)}:
		var antes: int = olhar.chamadas
		alvo.global_position = {"direita": Vector3(3.0, 1.6, -2.0), "esquerda": Vector3(-3.0, 1.6, -2.0), "em cima": Vector3(0.0, 6.0, -3.0)}[nome]
		await create_timer(0.8).timeout
		_verificar(olhar.chamadas > antes + 5, "o Godot chama o modificador a cada quadro (%d chamadas)" % (olhar.chamadas - antes))
		var giro: Quaternion = olhar._giro
		giros[nome] = giro
		var graus := rad_to_deg(giro.get_angle())
		print("  alvo %s: a cabeça gira %.0f graus" % [nome, graus])
		_verificar(graus > 10.0, "alvo %s puxa a cabeça (%.0f graus)" % [nome, graus])
		_verificar(graus <= rad_to_deg(olhar.giro_maximo) + 1.0, "respeita o giro máximo (%.0f graus)" % graus)
	var giro_direita: Quaternion = giros["direita"]
	var giro_esquerda: Quaternion = giros["esquerda"]
	_verificar(giro_direita.get_axis().dot(giro_esquerda.get_axis()) < 0.0, "direita e esquerda giram pra lados opostos")

	# Alvo atrás do atleta: não torce o pescoço, volta pro meio.
	alvo.global_position = Vector3(0.0, 1.6, 6.0)
	await create_timer(1.0).timeout
	var atras := rad_to_deg((olhar._giro as Quaternion).get_angle())
	_verificar(atras < 5.0, "alvo atrás não vira a cabeça (%.0f graus)" % atras)

	if falhas == 0:
		print("OK: a cabeça acompanha a bola.")
	else:
		print("FALHOU: %d verificação(ões) do olhar da cabeça." % falhas)
	quit(1 if falhas > 0 else 0)
