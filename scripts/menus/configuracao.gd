extends Node
## Guarda o que foi escolhido nos menus pra cena da partida usar.
##
## Fica sempre carregado (autoload "Configuracao"). Os valores padrão
## deixam rodar a cena da partida direto (F6), sem passar pelos menus.

## Id do time de cada jogador: [Jogador 1, Jogador 2] (veja dados/times.json).
var times := ["karasuno", "nekoma"]
## Id do estádio (veja dados/estadios.json).
var estadio := "ginasio_japones"
## "rapida" (partida normal) ou "caos" (com cartas, veja scripts/regras/cartas.gd).
var modo := "rapida"
## Semente do sorteio da partida (erro do saque, quem saca primeiro, cartas...).
## -1: cada partida sai diferente. 0 ou mais: com as mesmas teclas nos mesmos
## quadros, a partida se repete igual (o robô e os testes usam isso).
var semente := -1
## Modo 1 jogador: o time do Jogador 2 é jogado pelo computador
## (scripts/entrada/entrada_do_computador.gd) e a tela não se divide.
var contra_computador := false
## Dificuldade do computador: id de dados/dificuldades.json ("facil", "normal", "dificil").
var dificuldade := "normal"
## Os dois times jogados pelo computador (o robô e os testes usam pra assistir).
var computador_nos_dois := false
## Arquivo com os comandos gravados de uma partida (veja
## scripts/entrada/entrada_gravada.gd). Vazio = jogo normal. O robô usa com repetir=.
var repeticao := ""
## Câmera da partida com uma tela só (1 jogador e online): "perto" (de console,
## atrás do time), "tv" (a antiga: alta e longe) ou "alta" (bem de cima, pra
## ver as duas quadras). A tela dividida usa sempre a "tv". Fica salva em
## ARQUIVO_DE_OPCOES e vale pra próxima vez que abrir o jogo.
var camera := "perto"

const CAMERAS := ["perto", "tv", "alta"]
const NOMES_DAS_CAMERAS := {"perto": "PERTO", "tv": "TV", "alta": "ALTA"}
const ARQUIVO_DE_OPCOES := "user://opcoes.cfg"


func _ready() -> void:
	var opcoes := ConfigFile.new()
	if opcoes.load(ARQUIVO_DE_OPCOES) == OK:
		var salva := str(opcoes.get_value("partida", "camera", camera))
		if salva in CAMERAS:
			camera = salva


## Troca pra próxima câmera da lista, salva e devolve o nome dela.
func proxima_camera() -> String:
	mudar_camera(CAMERAS[(CAMERAS.find(camera) + 1) % CAMERAS.size()])
	return camera


func mudar_camera(estilo: String) -> void:
	if not estilo in CAMERAS:
		return
	camera = estilo
	var opcoes := ConfigFile.new()
	opcoes.load(ARQUIVO_DE_OPCOES)
	opcoes.set_value("partida", "camera", camera)
	opcoes.save(ARQUIVO_DE_OPCOES)


func nome_da_camera() -> String:
	return "CÂMERA: " + str(NOMES_DAS_CAMERAS.get(camera, camera.to_upper()))


func definir_partida(time_jogador_1: String, time_jogador_2: String, id_do_estadio: String) -> void:
	times = [time_jogador_1, time_jogador_2]
	estadio = id_do_estadio
