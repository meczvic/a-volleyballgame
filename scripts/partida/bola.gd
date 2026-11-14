extends Node3D
## A bola: voa em parábola, bate na rede e avisa quando toca o chão.
##
## Usa a conta exata da trajetória (não o motor de física do Godot).
## Assim o ponto de queda previsto é sempre o ponto real, e o jogo
## fica igual nos dois computadores quando for online.

signal tocou_chao(posicao: Vector3)
signal tocou_rede
## Bloqueio no alto e na frente da bola: ela voltou pra quem atacou.
signal bloqueada
## A bola raspou no bloqueio e seguiu, mais devagar, pro lado de quem bloqueou.
signal tocou_bloqueio
## A bola passou pro outro lado: por cima da rede ou por fora dela.
## "ponto" é onde ela cruzou a linha da rede (veja a regra das antenas na partida).
signal cruzou_a_rede(ponto: Vector3)
## A bola do saque flutuante balançou e vai cair em outro lugar (ponto_previsto).
signal balancou

const Trajetoria := preload("res://scripts/regras/trajetoria.gd")
const VisualAnime := preload("res://scripts/visual/visual_anime.gd")
const SHADER_DA_BOLA := preload("res://shaders/bola.gdshader")

## Um pouco maior que a bola real (0,105 m) pra enxergar bem de cima.
const RAIO := 0.18
## O desenho é maior ainda que o raio das regras, pra bola não sumir atrás
## dos atletas do outro lado na câmera de longe.
const RAIO_DO_DESENHO := 0.22
const ALTURA_REDE := 2.43
## A rede passa 0,5 m pra fora de cada lateral da quadra.
const LARGURA_REDE := 10.0
## Folga mínima por cima da fita da rede nos lançamentos.
const FOLGA_REDE := 0.4
## Lance reto (cortada): folga mínima da bola por cima da fita da rede (m).
const FOLGA_REDE_NO_RETO := 0.25

var em_voo := false
## Quantas vezes a bola já foi lançada (ou desviada). Serve pra saber se um
## toque mandou a bola.
var lancamentos := 0
## Ímã: puxa a bola pra um ponto (a mão de quem vai cortar) sem mudar o
## caminho dela. Peso 0 = solta, 1 = no ponto. Ver puxar_para.
var _ima_ponto := Vector3.ZERO
var _ima_peso := 0.0
## Onde a bola vai tocar o chão (válido enquanto está em voo).
var ponto_previsto := Vector3.ZERO
## Quem cuida do bloqueio: função(ponto_na_rede: Vector3, lado_destino: float) -> int.
## Devolve 0 (ninguém encosta), 1 (bloqueio devolve a bola) ou 2 (a bola
## raspa no bloqueio e segue). Veja Bloqueio em partida.gd.
var verificar_bloqueio := Callable()
## Ajustes do rebote do bloqueio que devolve a bola (a partida define na hora de
## decidir o bloqueio): multiplicador da força e empurrão pro lado (m/s no x).
var forca_do_bloqueio := 1.0
var empurrao_do_bloqueio := 0.0
## Visual anime (contorno escuro). Defina antes de colocar a bola na cena.
var usar_visual_anime := true

var _origem := Vector3.ZERO
var _velocidade_inicial := Vector3.ZERO
var _tempo := 0.0
## Gravidade do voo de agora (m/s²): maior = bola mais rápida e reta.
var gravidade := Trajetoria.GRAVIDADE
## Quantas cortadas saíram em linha reta (lancar_reto), pra medir nos testes.
var retos := 0
## Balanços do flutuante que ainda vão acontecer: [[segundos desde o lançamento,
## mudança na velocidade de lado (m/s)], ...].
var _balancos: Array = []
var _desde_o_lancamento := 0.0
## Giro da bola no voo (só visual), em voltas por segundo. Cada lançamento gira
## conforme a velocidade; o flutuante quase não gira (sem_giro).
var _giro := 0.0
var _eixo_do_giro := Vector3.RIGHT
## Voltas por segundo por m/s de velocidade.
const GIRO_POR_VELOCIDADE := 0.12
var _sombra: MeshInstance3D
var _visual: MeshInstance3D


func _ready() -> void:
	var esfera := SphereMesh.new()
	esfera.radius = RAIO_DO_DESENHO
	esfera.height = RAIO_DO_DESENHO * 2.0
	var visual := MeshInstance3D.new()
	visual.mesh = esfera
	var cor := Color("#F7F3E8")
	if usar_visual_anime:
		# Gomos amarelos e azuis (shaders/bola.gdshader), com contorno fino.
		var gomos := ShaderMaterial.new()
		gomos.shader = SHADER_DA_BOLA
		gomos.next_pass = VisualAnime.contorno(0.012)
		visual.material_override = gomos
	else:
		var material := StandardMaterial3D.new()
		material.albedo_color = cor
		visual.material_override = material
	add_child(visual)
	_visual = visual

	# Sombra redonda sempre no chão, embaixo da bola.
	var disco := CylinderMesh.new()
	disco.top_radius = RAIO
	disco.bottom_radius = RAIO
	disco.height = 0.01
	_sombra = MeshInstance3D.new()
	_sombra.mesh = disco
	var material_sombra := StandardMaterial3D.new()
	material_sombra.albedo_color = Color(0, 0, 0, 0.45)
	material_sombra.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_sombra.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_sombra.material_override = material_sombra
	_sombra.top_level = true
	add_child(_sombra)


## Lança a bola da posição atual até "destino" (no chão), subindo até
## "altura_maxima". Se precisar, sobe mais pra passar a rede.
## Achata a bola na batida e deixa ela voltar à forma (squash). "forca" de 0 a 1.
## Só visual.
func amassar(forca: float) -> void:
	if _visual == null or forca <= 0.0:
		return
	var f := clampf(forca, 0.0, 1.0)
	var achatada := Vector3(1.0 + 0.3 * f, 1.0 - 0.38 * f, 1.0 + 0.3 * f)
	_visual.scale = achatada
	var tween := create_tween()
	tween.tween_property(_visual, "scale", Vector3(1.0 - 0.1 * f, 1.0 + 0.16 * f, 1.0 - 0.1 * f), 0.07)
	tween.tween_property(_visual, "scale", Vector3.ONE, 0.1)


func lancar(destino: Vector3, altura_maxima: float, gravidade_do_lance := Trajetoria.GRAVIDADE) -> void:
	var alvo := Vector3(destino.x, RAIO, destino.z)
	var velocidade := Trajetoria.velocidade_passando_rede(
		position, alvo, altura_maxima, ALTURA_REDE + FOLGA_REDE, gravidade_do_lance
	)
	_comecar_voo(position, velocidade, gravidade_do_lance)


## Lance em linha quase reta (a cortada): a bola sai da mão na velocidade
## horizontal dada (m/s), sem subir antes de descer, passa rente por cima da
## rede e cai no destino (Trajetoria.voo_reto). Devolve false (sem lançar nada)
## se não dá (ataque curto, que precisa de arco): aí quem chamou usa `lancar`.
func lancar_reto(destino: Vector3, velocidade: float) -> bool:
	var alvo := Vector3(destino.x, RAIO, destino.z)
	var voo := Trajetoria.voo_reto(position, alvo, velocidade, ALTURA_REDE + FOLGA_REDE_NO_RETO)
	if voo.is_empty():
		return false
	_comecar_voo(position, voo["velocidade"], voo["gravidade"])
	retos += 1
	return true


## Para a bola num ponto (por exemplo, na mão de quem vai sacar).
func segurar_em(ponto: Vector3) -> void:
	em_voo = false
	position = ponto


## Puxa a bola pra "ponto" (peso 0 a 1) enquanto ela voa. Peso 0 solta.
func puxar_para(ponto: Vector3, peso: float) -> void:
	_ima_ponto = ponto
	_ima_peso = clampf(peso, 0.0, 1.0)


## Onde a bola vai estar daqui a "segundos", se nada tocar nela.
func posicao_daqui_a(segundos: float) -> Vector3:
	if not em_voo:
		return position
	return Trajetoria.posicao_em(_origem, _velocidade_inicial, _tempo + segundos, gravidade)


## Há quantos segundos a bola foi lançada (ou desviada).
func tempo_de_voo() -> float:
	return _tempo


func velocidade_atual() -> Vector3:
	return _velocidade_inicial + Vector3(0.0, -gravidade * _tempo, 0.0)


## Saque flutuante: a bola muda de lado no meio do voo, como no vôlei de
## verdade (sem giro, o ar empurra a bola). "desvios": [[segundos depois do
## lançamento, mudança na velocidade de lado (m/s)], ...]. Chame logo depois
## de lancar.
func balancar(desvios: Array) -> void:
	_balancos = desvios.duplicate()
	# Flutuante: a bola vai sem girar (por isso balança).
	_giro = 0.05


## Tamanho do desenho da bola (raio, m). As regras continuam com RAIO. Na
## câmera perto a bola fica perto do tamanho real; na de TV, maior.
func mudar_tamanho_do_desenho(raio: float) -> void:
	if _visual and _visual.mesh is SphereMesh:
		_visual.mesh.radius = raio
		_visual.mesh.height = raio * 2.0


## Aplica um balanço: continua do mesmo ponto, com a mesma gravidade, mas
## indo mais pra um lado. Não conta como lançamento novo (ninguém tocou).
func _balancar_agora(desvio_x: float) -> void:
	var v := velocidade_atual()
	_origem = position
	_velocidade_inicial = Vector3(v.x + desvio_x, v.y, v.z)
	_tempo = 0.0
	ponto_previsto = Trajetoria.ponto_de_queda(_origem, _velocidade_inicial, RAIO, gravidade)
	balancou.emit()

## Muda o rumo da bola no meio do voo (rede ou bloqueio).
func _desviar(ponto: Vector3, nova_velocidade: Vector3) -> void:
	position = ponto
	_comecar_voo(ponto, nova_velocidade)


func _comecar_voo(de: Vector3, velocidade: Vector3, gravidade_do_voo := Trajetoria.GRAVIDADE) -> void:
	gravidade = gravidade_do_voo
	lancamentos += 1
	_ima_peso = 0.0
	_origem = de
	_velocidade_inicial = velocidade
	_tempo = 0.0
	_balancos = []
	_desde_o_lancamento = 0.0
	var no_chao := Vector3(velocidade.x, 0.0, velocidade.z)
	if no_chao.length() > 0.1:
		_eixo_do_giro = Vector3.UP.cross(no_chao.normalized())
	_giro = velocidade.length() * GIRO_POR_VELOCIDADE
	em_voo = true
	ponto_previsto = Trajetoria.ponto_de_queda(_origem, _velocidade_inicial, RAIO, gravidade)


func _physics_process(delta: float) -> void:
	if em_voo:
		_voar(delta)
		if _visual and _giro > 0.0:
			_visual.rotate(_eixo_do_giro, _giro * TAU * delta)
	_sombra.global_position = Vector3(global_position.x, 0.02, global_position.z)


func _voar(delta: float) -> void:
	var antes := position
	_tempo += delta
	_desde_o_lancamento += delta
	if not _balancos.is_empty() and _desde_o_lancamento >= float(_balancos[0][0]):
		_balancar_agora(float(_balancos.pop_front()[1]))
	var agora := Trajetoria.posicao_em(_origem, _velocidade_inicial, _tempo, gravidade)

	# Cruzou a linha da rede neste quadro?
	if antes.z != 0.0 and signf(antes.z) != signf(agora.z):
		var fracao := antes.z / (antes.z - agora.z)
		var cruzamento := antes.lerp(agora, fracao)
		var na_largura_da_rede := absf(cruzamento.x) < LARGURA_REDE / 2.0
		var lado_de_onde_veio := signf(antes.z)

		# Abaixo da fita: bateu na rede.
		if na_largura_da_rede and cruzamento.y < ALTURA_REDE + RAIO:
			var v := velocidade_atual()
			# Volta devagar pro lado de quem bateu e cai perto da rede.
			var rebote := Vector3(v.x * 0.5, minf(v.y, 0.0), -v.z * 0.25)
			_desviar(Vector3(cruzamento.x, cruzamento.y, lado_de_onde_veio * (RAIO + 0.02)), rebote)
			tocou_rede.emit()
			return

		# Acima da fita, mas com alguém bloqueando ali.
		var bloqueio := 0
		if na_largura_da_rede and verificar_bloqueio.is_valid():
			bloqueio = int(verificar_bloqueio.call(cruzamento, signf(agora.z)))
		if bloqueio == 1:
			# Bloqueio em cheio: volta pra quem atacou.
			var v := velocidade_atual()
			var rebote := Vector3(v.x * 0.3 + empurrao_do_bloqueio, -absf(v.y) * 0.3 - 1.5, -v.z * 0.35 * forca_do_bloqueio)
			forca_do_bloqueio = 1.0
			empurrao_do_bloqueio = 0.0
			_desviar(Vector3(cruzamento.x, cruzamento.y, lado_de_onde_veio * (RAIO + 0.3)), rebote)
			bloqueada.emit()
			return
		if bloqueio == 2:
			# Raspou: sobe um pouco e segue devagar pro lado de quem bloqueou.
			var v := velocidade_atual()
			var desvio := Vector3(v.x * 0.5, absf(v.y) * 0.4 + 2.0, v.z * 0.4)
			_desviar(Vector3(cruzamento.x, cruzamento.y, -lado_de_onde_veio * (RAIO + 0.3)), desvio)
			tocou_bloqueio.emit()
			return

		cruzou_a_rede.emit(cruzamento)

	if agora.y <= RAIO:
		position = ponto_previsto
		em_voo = false
		tocou_chao.emit(position)
		return

	position = agora.lerp(_ima_ponto, _ima_peso) if _ima_peso > 0.0 else agora
