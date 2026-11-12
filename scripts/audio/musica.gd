extends Node
## Música de fundo, feita pelo próprio jogo (sem arquivo de áudio), como os
## sons de scripts/audio/sons.gd.
##
## Duas faixas em loop: "menu" (mais calma) e "partida" (mais animada, estilo
## anime de esporte). O autoload "Musica" olha a cena aberta e troca sozinho:
## na partida toca "partida", no resto "menu". Tecla M liga e desliga.
##
## Volume e se começa ligada: dados/ajustes.json, grupo "musica". Sem tela
## (testes, robô --headless) não monta nada, pra não atrasar nem fazer barulho.

const TAXA := 22050
## Notas (Hz) da escala de lá menor usadas nos acordes.
const NOTAS := {
	"A2": 110.0, "C3": 130.81, "D3": 146.83, "E3": 164.81, "F2": 87.31, "G2": 98.0,
	"C2": 65.41, "A3": 220.0, "B3": 246.94, "C4": 261.63, "D4": 293.66, "E4": 329.63,
	"F4": 349.23, "G4": 392.0, "A4": 440.0, "B4": 493.88, "C5": 523.25, "E5": 659.25,
	"G3": 196.0, "F3": 174.61,
}
## Acordes (baixo, notas do arpejo) de cada faixa, um por compasso.
const FAIXAS := {
	"partida": {
		"bpm": 140.0,
		"acordes": [
			["A2", ["A3", "C4", "E4", "A4"]], ["F2", ["F3", "A3", "C4", "F4"]],
			["C2", ["G3", "C4", "E4", "G4"]], ["G2", ["G3", "B3", "D4", "G4"]],
			["A2", ["A3", "C4", "E4", "A4"]], ["F2", ["F3", "A3", "C4", "F4"]],
			["C2", ["G3", "C4", "E4", "G4"]], ["G2", ["B3", "D4", "G4", "B4"]],
		],
		"bateria": "cheia",
		"arpejo": 16,
	},
	"menu": {
		"bpm": 104.0,
		"acordes": [
			["F2", ["F3", "A3", "C4", "E4"]], ["G2", ["G3", "B3", "D4", "G4"]],
			["A2", ["A3", "C4", "E4", "G4"]], ["A2", ["A3", "C4", "E4", "A4"]],
		],
		"bateria": "leve",
		"arpejo": 8,
	},
}

var _player: AudioStreamPlayer
var _faixas := {}
var _tocando := ""
var _ligada := true
var _volume_db := -14.0
var _espera := 0.0
## Faixa que a cena pede agora (pode ainda estar montando).
var _querida := ""
## Faixas montando em segundo plano: nome -> id da tarefa.
var _tarefas := {}
var _trava := Mutex.new()
## Sorteio próprio (não mexe no sorteio da partida).
var _sorteio := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	_sorteio.seed = 7
	var ajustes := _ajustes()
	_ligada = bool(ajustes.get("ligada", true))
	_volume_db = float(ajustes.get("volume_db", -14.0))
	_player = AudioStreamPlayer.new()
	_player.volume_db = _volume_db
	add_child(_player)


func _process(delta: float) -> void:
	# Faixas que terminaram de montar (em segundo plano).
	for nome in _tarefas.keys():
		if WorkerThreadPool.is_task_completed(_tarefas[nome]):
			WorkerThreadPool.wait_for_task_completion(_tarefas[nome])
			_tarefas.erase(nome)
			if nome == _querida and _ligada:
				_comecar(nome)
	_espera -= delta
	if _espera > 0.0:
		return
	_espera = 0.5
	var cena := get_tree().current_scene
	var faixa := "partida" if cena and str(cena.scene_file_path).contains("partida") else "menu"
	tocar(faixa)


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_M:
		ligar(not _ligada)


## Liga ou desliga a música.
func ligar(sim: bool) -> void:
	_ligada = sim
	if _player == null:
		return
	if not sim:
		_player.stop()
		_tocando = ""


func ligada() -> bool:
	return _ligada


## Toca a faixa. Na primeira vez ela é montada em segundo plano e começa
## quando fica pronta. Já tocando essa, não faz nada.
func tocar(nome: String) -> void:
	if _player == null or not _ligada or nome == _tocando or not FAIXAS.has(nome):
		return
	_querida = nome
	_trava.lock()
	var pronta := _faixas.has(nome)
	_trava.unlock()
	if pronta:
		_comecar(nome)
	elif not _tarefas.has(nome):
		_tarefas[nome] = WorkerThreadPool.add_task(_montar_em_segundo_plano.bind(nome))


func _comecar(nome: String) -> void:
	_trava.lock()
	var faixa: AudioStreamWAV = _faixas.get(nome)
	_trava.unlock()
	if faixa == null:
		return
	_tocando = nome
	_player.stream = faixa
	_player.play()


func _montar_em_segundo_plano(nome: String) -> void:
	var faixa := montar(nome)
	_trava.lock()
	_faixas[nome] = faixa
	_trava.unlock()


func _ajustes() -> Dictionary:
	var arquivo := FileAccess.get_file_as_string("res://dados/ajustes.json")
	var dados = JSON.parse_string(arquivo) if arquivo != "" else null
	if dados is Dictionary and dados.get("musica") is Dictionary:
		return dados["musica"]
	return {}


## Monta a faixa inteira num AudioStreamWAV em loop.
static func montar(nome: String) -> AudioStreamWAV:
	var faixa: Dictionary = FAIXAS[nome]
	var batida := 60.0 / float(faixa["bpm"])
	var compasso := batida * 4.0
	var acordes: Array = faixa["acordes"]
	var n := int(compasso * acordes.size() * TAXA)
	var som := PackedFloat32Array()
	som.resize(n)
	for c in acordes.size():
		var inicio := c * compasso
		var baixo: float = NOTAS[acordes[c][0]]
		var notas: Array = acordes[c][1]
		# Fundo: acorde suave o compasso todo.
		for nota in notas:
			_nota(som, inicio, compasso, float(NOTAS[nota]), 0.035, "suave")
		# Baixo: colcheias (o baixo pulsando), oitava alternada na partida.
		for k in 8:
			var oitava := 2.0 if (k % 2 == 1 and faixa["bateria"] == "cheia") else 1.0
			_nota(som, inicio + k * batida / 2.0, batida / 2.0 * 0.9, baixo * oitava, 0.16, "baixo")
		# Arpejo em cima (semicolcheias na partida, colcheias no menu).
		var passos: int = faixa["arpejo"]
		for k in passos:
			var nota: float = NOTAS[notas[k % notas.size()]] * 2.0
			_nota(som, inicio + k * compasso / passos, compasso / passos * 0.8, nota, 0.05, "quadrada")
		# Bateria.
		for k in 8:
			var t := inicio + k * batida / 2.0
			var cheia: bool = faixa["bateria"] == "cheia"
			if k % 2 == 0 and (cheia or k % 4 == 0):
				_bumbo(som, t, 0.5)
			if k == 2 or k == 6:
				_caixa(som, t, 0.22 if cheia else 0.12)
			_chimbal(som, t, 0.06 if k % 2 == 1 else 0.035)
	# Normaliza e evita estalo no fim do loop.
	var pico := 0.001
	for v in som:
		pico = maxf(pico, absf(v))
	var ganho := 0.85 / pico
	for i in n:
		som[i] = som[i] * ganho
	return _em_wav(som)


static func _nota(som: PackedFloat32Array, inicio: float, duracao: float, freq: float, volume: float, tipo: String) -> void:
	var a := int(inicio * TAXA)
	var b := mini(a + int(duracao * TAXA), som.size())
	var fase := 0.0
	var passo := TAU * freq / TAXA
	for i in range(a, b):
		var t := float(i - a) / TAXA
		var envelope: float
		var onda: float
		match tipo:
			"baixo":
				envelope = exp(-t * 6.0)
				onda = sin(fase) + 0.35 * sin(2.0 * fase)
			"quadrada":
				envelope = exp(-t * 14.0)
				onda = 1.0 if sin(fase) >= 0.0 else -1.0
			_:
				envelope = minf(t / 0.08, 1.0) * minf((duracao - t) / 0.2, 1.0)
				onda = sin(fase) + 0.2 * sin(3.0 * fase)
		som[i] += onda * envelope * volume
		fase += passo


static func _bumbo(som: PackedFloat32Array, inicio: float, volume: float) -> void:
	var a := int(inicio * TAXA)
	var b := mini(a + int(0.22 * TAXA), som.size())
	var fase := 0.0
	for i in range(a, b):
		var t := float(i - a) / TAXA
		fase += TAU * lerpf(140.0, 45.0, minf(t / 0.08, 1.0)) / TAXA
		som[i] += sin(fase) * exp(-t * 16.0) * volume


## Ruído que não depende de sorteio (o mesmo toda vez).
static func _ruido(i: int) -> float:
	var x := (i * 1103515245 + 12345) & 0x7fffffff
	return float(x % 2000) / 1000.0 - 1.0


static func _caixa(som: PackedFloat32Array, inicio: float, volume: float) -> void:
	var a := int(inicio * TAXA)
	var b := mini(a + int(0.18 * TAXA), som.size())
	for i in range(a, b):
		var t := float(i - a) / TAXA
		som[i] += (_ruido(i) * 0.8 + 0.4 * sin(TAU * 190.0 * t)) * exp(-t * 22.0) * volume


static func _chimbal(som: PackedFloat32Array, inicio: float, volume: float) -> void:
	var a := int(inicio * TAXA)
	var b := mini(a + int(0.05 * TAXA), som.size())
	var anterior := 0.0
	for i in range(a, b):
		var t := float(i - a) / TAXA
		var r := _ruido(i * 7)
		som[i] += (r - anterior) * exp(-t * 60.0) * volume
		anterior = r


static func _em_wav(amostras: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(amostras.size() * 2)
	for i in amostras.size():
		bytes.encode_s16(i * 2, int(clampf(amostras[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = TAXA
	wav.stereo = false
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = amostras.size()
	return wav
