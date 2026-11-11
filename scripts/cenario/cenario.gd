extends Node3D
## Cenário da partida, montado em código: a quadra com as linhas, a rede com
## antenas e postes, a cadeira do juiz com os árbitros, e o lugar em volta
## (ginásio ou arena), com luz e público. Não tem física: a bola e os atletas
## usam só as medidas (as mesmas de partida.gd e bola.gd).
##
## O estilo vem de dados/estadios.json ("estilo"): "ginasio" (ginasio_japones.gd)
## ou "arena" (arena.gd, pros outros estádios). As cores também vêm de lá.
##
## Cada câmera fica atrás do próprio time, do lado de fora do ginásio. O que
## fica no fundo atrás de um time vai pra uma camada que a câmera daquele time
## não desenha (CAMADA_ATRAS_DO_TIME), senão tamparia a quadra.
##
## Uso: add_child(cenario) e depois montar(estadio, times_em_jogo, medidas).
##
## Pessoas em volta da quadra (árbitros, reservas, técnicos, mesários) são
## personagens do próprio jogo (gerador_de_atleta.gd), parados e respirando.

const Pecas := preload("res://scripts/cenario/pecas.gd")
const Dados := preload("res://scripts/comum/dados.gd")
const GeradorDeAtleta := preload("res://scripts/visual/gerador_de_atleta.gd")
const Animador := preload("res://scripts/visual/animador.gd")
const GinasioJapones := preload("res://scripts/cenario/ginasio_japones.gd")
const Polyfork := preload("res://scripts/cenario/polyfork.gd")
const Arena := preload("res://scripts/cenario/arena.gd")
const SHADER_REDE := preload("res://shaders/rede.gdshader")

## Camada de desenho do fundo atrás de cada time: [atrás do time 0 (+z), atrás do time 1 (-z)].
const CAMADA_ATRAS_DO_TIME := [13, 14]
## A partir daqui (distância da rede, em m) um objeto conta como "fundo atrás do time".
const COMECO_DO_FUNDO := 14.6

var estadio: Dictionary = {}
var times: Array = []
## "largura" e "comprimento" da quadra, "altura_da_rede", "zona_livre" (Vector2: largura, comprimento).
var medidas: Dictionary = {}
var largura := 9.0
var comprimento := 18.0
var altura_da_rede := 2.43
## Árbitros (pra testes e pra animar).
var arbitros: Array[Node3D] = []
## Reservas, técnicos e mesários.
var pessoas: Array[Node3D] = []


func montar(dados_do_estadio: Dictionary, times_em_jogo: Array, medidas_da_quadra: Dictionary) -> void:
	estadio = dados_do_estadio
	times = times_em_jogo
	medidas = medidas_da_quadra
	largura = float(medidas.get("largura", largura))
	comprimento = float(medidas.get("comprimento", comprimento))
	altura_da_rede = float(medidas.get("altura_da_rede", altura_da_rede))

	match estilo():
		"arena":
			Arena.montar(self)
		_:
			GinasioJapones.montar(self)
	_criar_quadra()
	_criar_rede()
	_criar_cadeira_do_juiz()
	_criar_bancos_e_mesa()
	_separar_os_fundos()


func estilo() -> String:
	return str(estadio.get("estilo", "ginasio"))


## Cor do estádio (dados/estadios.json, "cores").
func cor(chave: String, padrao: Color) -> Color:
	return Dados.cor(estadio.get("cores", {}), chave, padrao)


## Texto do estádio (dados/estadios.json), ou "padrao".
func texto(chave: String, padrao: String) -> String:
	return str(estadio.get(chave, padrao))


## Cores do uniforme em jogo do time (0 ou 1).
func cores_do_time(time: int) -> Array:
	if time < times.size():
		var cores: Array = times[time].get("cores", [])
		var lista: Array = []
		for c in cores:
			lista.append(Color.from_string(str(c), Color.WHITE))
		if not lista.is_empty():
			return lista
	return [Color.GRAY, Color.WHITE, Color.BLACK]


func cor_do_menu_do_time(time: int) -> Color:
	if time < times.size():
		return Dados.cor(times[time], "cor_do_menu", cores_do_time(time)[0])
	return Color.GRAY


func id_do_time(time: int) -> String:
	return str(times[time].get("id", "")) if time < times.size() else ""


## Quantos objetos do cenário cada câmera esconde (pra testes).
func objetos_na_camada(camada: int) -> int:
	var n := 0
	for no in find_children("*", "VisualInstance3D", true, false):
		if (no as VisualInstance3D).get_layer_mask_value(camada):
			n += 1
	return n


# --- Quadra ---

func _criar_quadra() -> void:
	var meia_largura := largura / 2.0
	var meio_comprimento := comprimento / 2.0
	var quadra := cor("quadra", Color("#2F6FC4"))
	Pecas.no_chao(self, Vector2(largura, comprimento), Vector3(0.0, 0.004, 0.0), Pecas.material(quadra, 0.55))
	# Zona de ataque (entre a rede e a linha dos 3 m) num azul um pouco mais escuro.
	for lado in [-1.0, 1.0]:
		Pecas.no_chao(self, Vector2(largura, 3.0), Vector3(0.0, 0.006, 1.5 * lado), Pecas.material(quadra.darkened(0.14), 0.55))

	var linhas := Pecas.material_aceso(cor("linhas", Color.WHITE), 0.97)
	var y := 0.01
	var espessura := 0.05
	for x in [-meia_largura, meia_largura]:
		Pecas.no_chao(self, Vector2(espessura, comprimento + espessura), Vector3(x, y, 0.0), linhas)
	for z in [-meio_comprimento, -3.0, 0.0, 3.0, meio_comprimento]:
		Pecas.no_chao(self, Vector2(largura, espessura), Vector3(0.0, y, z), linhas)

	# Linha de ataque continua pra fora da quadra, tracejada (1,75 m de cada lado).
	for z in [-3.0, 3.0]:
		for lado in [-1.0, 1.0]:
			for k in 5:
				var x: float = lado * (meia_largura + 0.25 + k * 0.35)
				Pecas.no_chao(self, Vector2(0.15, espessura), Vector3(x, y, z), linhas)
	# Marcas da zona de saque: 15 cm atrás da linha de fundo, no prolongamento das laterais.
	for z in [-meio_comprimento, meio_comprimento]:
		for x in [-meia_largura, meia_largura]:
			Pecas.no_chao(self, Vector2(espessura, 0.15), Vector3(x, y, z + signf(z) * 0.3), linhas)


# --- Rede ---

func _criar_rede() -> void:
	var meia_largura := largura / 2.0
	var largura_da_rede := largura + 1.0
	var branco := Pecas.material(Color("#F4F4F2"), 0.7)

	# Malha (vazada, escura) entre a fita de cima e a de baixo.
	var malha := QuadMesh.new()
	malha.size = Vector2(largura_da_rede, 0.95)
	var rede := MeshInstance3D.new()
	rede.name = "Rede"
	rede.mesh = malha
	var material_da_rede := ShaderMaterial.new()
	material_da_rede.shader = SHADER_REDE
	rede.material_override = material_da_rede
	rede.position = Vector3(0.0, altura_da_rede - 0.5, 0.0)
	rede.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rede)

	Pecas.caixa(self, Vector3(largura_da_rede, 0.07, 0.025), Vector3(0.0, altura_da_rede - 0.035, 0.0), branco)
	Pecas.caixa(self, Vector3(largura_da_rede, 0.05, 0.02), Vector3(0.0, altura_da_rede - 0.975, 0.0), branco)
	# Faixas laterais brancas em cima das linhas laterais.
	for x in [-meia_largura, meia_largura]:
		Pecas.caixa(self, Vector3(0.05, 1.0, 0.03), Vector3(x, altura_da_rede - 0.5, 0.0), branco)

	# Antenas: varetas listradas de vermelho e branco, 80 cm acima da rede.
	var vermelho := Pecas.material(Color("#D7262E"), 0.6)
	for x in [-meia_largura, meia_largura]:
		var ax: float = x + signf(x) * 0.03
		Pecas.cilindro(self, 0.01, 1.8, Vector3(ax, altura_da_rede - 0.1, 0.0), branco, 6)
		for k in 9:
			if k % 2 == 0:
				Pecas.cilindro(self, 0.012, 0.1, Vector3(ax, altura_da_rede - 1.0 + 0.05 + k * 0.2, 0.0), vermelho, 6)
		# Os 80 cm de cima, com listras de 10 cm.
		for k in 8:
			if k % 2 == 0:
				Pecas.cilindro(self, 0.012, 0.1, Vector3(ax, altura_da_rede + 0.05 + k * 0.1, 0.0), vermelho, 6)

	# Postes com proteção azul e o cabo até a fita.
	var protecao := Pecas.material(cor("protecao", Color("#2456C8")), 0.7)
	var metal := Pecas.material(Color("#B9BEC6"), 0.4, 0.6)
	for lado in [-1.0, 1.0]:
		var px: float = lado * (meia_largura + 1.0)
		Pecas.cilindro(self, 0.055, altura_da_rede + 0.3, Vector3(px, (altura_da_rede + 0.3) / 2.0, 0.0), metal, 10, true)
		Pecas.caixa(self, Vector3(0.3, 1.9, 0.3), Vector3(px, 0.95, 0.0), protecao, true)
		Pecas.cilindro(self, 0.25, 0.04, Vector3(px, 0.02, 0.0), metal, 14)
		Pecas.caixa(self, Vector3(0.5, 0.012, 0.012), Vector3(lado * (meia_largura + 0.75), altura_da_rede - 0.02, 0.0), metal)


# --- Cadeira do juiz e árbitros ---

func _criar_cadeira_do_juiz() -> void:
	var x := -(largura / 2.0 + 1.75)
	var estrutura := Pecas.material(cor("protecao", Color("#2456C8")), 0.6)
	var degraus := Pecas.material(Color("#C93A33"), 0.6)
	var altura := 1.5
	for dx in [-0.28, 0.28]:
		for dz in [-0.28, 0.28]:
			Pecas.caixa(self, Vector3(0.06, altura, 0.06), Vector3(x + dx, altura / 2.0, dz), estrutura, true)
	Pecas.caixa(self, Vector3(0.75, 0.08, 0.75), Vector3(x, altura, 0.0), estrutura, true)
	Pecas.caixa(self, Vector3(0.7, 0.9, 0.1), Vector3(x, 0.45, 0.0), estrutura)
	# Grade do lado da rede e escada do outro lado.
	Pecas.caixa(self, Vector3(0.05, 0.6, 0.7), Vector3(x + 0.35, altura + 0.3, 0.0), estrutura)
	for lado in [-0.18, 0.18]:
		Pecas.caixa(self, Vector3(0.05, altura + 0.2, 0.05), Vector3(x - 0.55, (altura + 0.2) / 2.0, lado), degraus)
	for k in 4:
		Pecas.caixa(self, Vector3(0.05, 0.05, 0.4), Vector3(x - 0.55, 0.3 + k * 0.35, 0.0), degraus)

	# 1º árbitro em cima da cadeira, olhando a rede; 2º árbitro em pé do outro lado.
	_criar_arbitro(Vector3(x, altura + 0.04, 0.0), PI / 2.0)
	_criar_arbitro(Vector3(largura / 2.0 + 1.6, 0.0, 0.6), -PI / 2.0)


func _criar_arbitro(posicao: Vector3, giro: float) -> void:
	var arbitro := pessoa(posicao, giro, [Color("#F4F4F4"), Color("#1A1A1E"), Color("#1A1A1E")], 0, 0)
	arbitro.name = "Arbitro%d" % arbitros.size()
	pessoas.erase(arbitro)
	arbitros.append(arbitro)


## Aparências pras pessoas em volta da quadra (variam cabelo, pele e altura).
const APARENCIAS := [
	{"altura": 1.74, "pele": "clara", "cabelo": {"cor": "#1E1A18", "estilo": "curto"}},
	{"altura": 1.82, "pele": "clara_quente", "cabelo": {"cor": "#2A2320", "estilo": "franja"}},
	{"altura": 1.78, "pele": "morena_clara", "cabelo": {"cor": "#1B1E26", "estilo": "curto"}},
	{"altura": 1.86, "pele": "bem_clara", "cabelo": {"cor": "#4A3222", "estilo": "franja"}},
	{"altura": 1.70, "pele": "parda", "cabelo": {"cor": "#14161C", "estilo": "curto"}},
]


## Uma pessoa parada (personagem do jogo) com o uniforme "cores" e o número
## (0 = sem número). "jeito" escolhe a aparência em APARENCIAS.
func pessoa(posicao: Vector3, giro: float, cores: Array, numero: int, jeito: int) -> Node3D:
	var aparencia := GeradorDeAtleta.aparencia_padrao()
	aparencia.merge(APARENCIAS[jeito % APARENCIAS.size()], true)
	var textos: Array = []
	for cor_do_uniforme in cores:
		textos.append("#" + (cor_do_uniforme as Color).to_html(false))
	var nova := GeradorDeAtleta.criar(aparencia, {"cores": textos, "numero": numero})
	nova.position = posicao
	nova.rotation.y = giro
	add_child(nova)
	pessoas.append(nova)
	var player := nova.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player != null:
		player.add_animation_library(Animador.BIBLIOTECA, Animador.biblioteca())
		player.play(Animador.BIBLIOTECA + "/parado")
		player.seek(randf() * 2.0, true)
	return nova


# --- Bancos e mesa do apontador ---

## Do lado direito (x positivo): banco de cada time na metade dele, com dois
## reservas e o técnico em pé, e a mesa do apontador no meio com dois mesários.
func _criar_bancos_e_mesa() -> void:
	var x := 9.4
	var assento := Pecas.material(Color("#8C5A32") if estilo() == "ginasio" else Color("#2B303A"), 0.6)
	for time in 2:
		var lado := 1.0 if time == 0 else -1.0
		var centro := Vector3(x, 0.0, lado * 6.2)
		# No ginásio, o banco de tábua da Polyfork; na arena (ou sem o arquivo), o desenhado.
		var banco := Polyfork.modelo("plank-bench-c46528") if estilo() == "ginasio" else null
		if banco != null:
			banco.position = centro
			banco.rotation.y = PI / 2.0
			add_child(banco)
		else:
			Pecas.caixa(self, Vector3(0.45, 0.06, 4.6), centro + Vector3(0, 0.45, 0), assento)
			for dz in [-2.1, 0.0, 2.1]:
				Pecas.caixa(self, Vector3(0.4, 0.45, 0.05), centro + Vector3(0, 0.22, dz), assento)
		var cores: Array = cores_do_time(time)
		var numeros := _numeros_livres(time)
		for k in 2:
			pessoa(centro + Vector3(-0.7, 0.0, -0.9 + k * 1.6), -PI / 2.0, cores, numeros[k], time * 2 + k + 1)
		# Técnico de agasalho (na cor de detalhe do time), sem número.
		var agasalho: Color = cores[1].darkened(0.35) if cores[1].get_luminance() > 0.6 else cores[1]
		pessoa(centro + Vector3(-0.9, 0.0, -lado * 2.7), -PI / 2.0, [agasalho, cores[0], cores[0]], 0, time + 3)

	var mesa := Vector3(8.2, 0.0, 0.0)
	Pecas.caixa(self, Vector3(0.75, 0.05, 2.6), mesa + Vector3(0, 0.76, 0), Pecas.material(Color("#F2F2EE"), 0.5))
	Pecas.caixa(self, Vector3(0.04, 0.72, 2.6), mesa + Vector3(-0.37, 0.38, 0), Pecas.material(cor("placas", Color("#8E2B2B")), 0.8))
	Pecas.caixa(self, Vector3(0.3, 0.2, 0.45), mesa + Vector3(0.1, 0.88, 0.3), Pecas.material(Color("#2A2D33"), 0.4))
	for dz in [-0.65, 0.65]:
		pessoa(mesa + Vector3(0.75, 0.0, dz), -PI / 2.0, [Color("#F4F4F4"), Color("#1F3A6E"), Color("#1F3A6E")], 0, 2 if dz < 0.0 else 4)


## Dois números de camisa que o time não usa (pros reservas).
func _numeros_livres(time: int) -> Array:
	var usados: Array = []
	for atleta in Dados.elenco(id_do_time(time)):
		usados.append(int(atleta.get("numero", 0)))
	var livres: Array = []
	for n in [12, 13, 14, 7, 8, 2, 5]:
		if not usados.has(n) and livres.size() < 2:
			livres.append(n)
	while livres.size() < 2:
		livres.append(0)
	return livres


# --- Camadas ---

## O que fica no fundo atrás de cada time vai pra camada daquele lado.
func _separar_os_fundos() -> void:
	for no in find_children("*", "VisualInstance3D", true, false):
		if no is Light3D:
			continue
		var visual := no as VisualInstance3D
		var caixa := visual.global_transform * visual.get_aabb()
		var z := caixa.get_center().z
		if absf(z) < COMECO_DO_FUNDO:
			continue
		var camada: int = CAMADA_ATRAS_DO_TIME[0] if z > 0.0 else CAMADA_ATRAS_DO_TIME[1]
		visual.layers = 1 << (camada - 1)
