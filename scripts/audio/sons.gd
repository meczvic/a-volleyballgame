extends Node
## Efeitos sonoros da partida: batida na bola, bloqueio, bola no chão, apito,
## torcida e os avisos do tempo certo.
##
## Os sons são feitos no próprio jogo, por conta (sem arquivo de áudio): cada
## um é uma mistura de ondas e ruído, montada uma vez só e guardada. Assim não
## tem licença pra conferir nem arquivo pra importar. Pra trocar um som por um
## arquivo de verdade no futuro, basta pôr o .wav/.ogg em SONS_DE_ARQUIVO.
##
## Uso (na partida): sons.tocar("cortada", 1.0)
##
## Não usa o sorteio da partida nem o randf() solto: a variação de tom tem um
## sorteio próprio, então ligar o som não muda a partida com semente.

## Amostras por segundo dos sons feitos no jogo.
const TAXA := 22050
## Quantos sons podem tocar ao mesmo tempo.
const CANAIS := 10
## Variação de tom de uma batida pra outra (fração), pra não soar repetido.
const VARIACAO_DO_TOM := 0.05

## Volume (dB) e tom base de cada som. Ajuste aqui se algum ficar alto ou baixo.
const AJUSTES := {
	"passe": { "volume": -2.0, "tom": 1.0 },
	"levantamento": { "volume": -4.0, "tom": 1.0 },
	"saque": { "volume": -3.0, "tom": 1.15 },
	"cortada": { "volume": 0.0, "tom": 1.0 },
	"bloqueio": { "volume": -1.0, "tom": 1.0 },
	"rede": { "volume": -6.0, "tom": 1.0 },
	"quique": { "volume": -3.0, "tom": 1.0 },
	"mergulho": { "volume": -5.0, "tom": 1.0 },
	"apito": { "volume": -9.0, "tom": 1.0 },
	"torcida": { "volume": -8.0, "tom": 1.0 },
	"perfeito": { "volume": -8.0, "tom": 1.0 },
	"super": { "volume": -5.0, "tom": 1.0 },
	"ruim": { "volume": -12.0, "tom": 1.0 },
	"falhou": { "volume": -10.0, "tom": 1.0 },
}

## Sons que vêm de arquivo em vez de serem feitos no jogo (vazio por enquanto).
## Ex.: { "apito": "res://sons/apito.ogg" }
const SONS_DE_ARQUIVO := {}

## Desligue pra jogar sem som.
var ligado := true
## Últimos sons tocados (nome), pros testes conferirem. Guarda os 32 últimos.
var historico: Array[String] = []

## Sons já montados, compartilhados por todas as partidas (montar leva um
## instante, e os testes abrem a partida muitas vezes).
static var _prontos: Dictionary = {}

var _canais: Array[AudioStreamPlayer] = []
var _proximo := 0
var _tom := RandomNumberGenerator.new()


func _ready() -> void:
	_tom.seed = 7
	for i in CANAIS:
		var canal := AudioStreamPlayer.new()
		canal.name = "Canal%d" % i
		add_child(canal)
		_canais.append(canal)


## Toca o som "nome". "intensidade" (0 a 1, pode passar um pouco de 1) deixa
## mais alto e um pouco mais grave quando é forte.
## Cada som pedido (o online repassa pro convidado).
signal tocou(nome: String, intensidade: float)


func tocar(nome: String, intensidade := 1.0) -> void:
	tocou.emit(nome, intensidade)
	historico.append(nome)
	if historico.size() > 32:
		historico.remove_at(0)
	if not ligado or _canais.is_empty():
		return
	var audio := som(nome)
	if audio == null:
		return
	var ajuste: Dictionary = AJUSTES.get(nome, { "volume": 0.0, "tom": 1.0 })
	var canal := _canais[_proximo]
	_proximo = (_proximo + 1) % _canais.size()
	canal.stream = audio
	canal.volume_db = float(ajuste["volume"]) + linear_to_db(clampf(intensidade, 0.05, 1.5))
	var variacao := _tom.randf_range(-VARIACAO_DO_TOM, VARIACAO_DO_TOM)
	# Batida forte sai um pouco mais grave (mais "peso").
	canal.pitch_scale = maxf(float(ajuste["tom"]) * (1.0 + variacao) * (1.08 - 0.08 * clampf(intensidade, 0.0, 1.0)), 0.1)
	canal.play()


## Se o som "nome" foi tocado desde "desde" (posição no histórico).
func tocou_desde(nome: String, desde: int) -> bool:
	for i in range(maxi(desde, 0), historico.size()):
		if historico[i] == nome:
			return true
	return false


## O som "nome" pronto pra tocar (null se não existe).
static func som(nome: String) -> AudioStream:
	if _prontos.has(nome):
		return _prontos[nome]
	var pronto: AudioStream = null
	if SONS_DE_ARQUIVO.has(nome) and ResourceLoader.exists(SONS_DE_ARQUIVO[nome]):
		pronto = load(SONS_DE_ARQUIVO[nome])
	else:
		var amostras := _montar(nome)
		if not amostras.is_empty():
			pronto = _em_wav(amostras)
	_prontos[nome] = pronto
	return pronto


## Todos os nomes de som que o jogo sabe fazer.
static func nomes() -> Array:
	return AJUSTES.keys()


# --- Montagem dos sons ---

static func _montar(nome: String) -> PackedFloat32Array:
	match nome:
		# Golpes em camadas: grave (corpo da bola), estalo (couro), tapa (mão) e,
		# nos fortes, o sopro de ar da bola saindo.
		"passe":
			return _golpe(0.28, 140.0, 60.0, 20.0, 0.9, 0.5, 120.0, 0.9, 45.0, 0.0, 1.8, 41)
		"levantamento":
			return _golpe(0.16, 300.0, 200.0, 40.0, 0.35, 0.8, 90.0, 0.5, 60.0, 0.0, 1.4, 43)
		"saque":
			return _golpe(0.5, 200.0, 50.0, 14.0, 1.0, 1.0, 70.0, 1.0, 30.0, 0.7, 2.2, 47)
		"cortada":
			return _golpe(0.5, 220.0, 45.0, 12.0, 1.0, 1.1, 60.0, 1.1, 26.0, 0.5, 2.6, 53)
		"bloqueio":
			return _bloqueio()
		"rede":
			return _rede()
		"quique":
			return _quique()
		"mergulho":
			return _batida(0.3, 90.0, 55.0, 14.0, 0.6, 0.04)
		"apito":
			return _apito()
		"torcida":
			return _torcida()
		"perfeito":
			return _sininho([880.0, 1318.5], 0.07, 0.5)
		"super":
			return _sininho([523.25, 659.25, 784.0, 1046.5, 1568.0], 0.06, 0.7)
		"ruim":
			return _batida(0.22, 210.0, 150.0, 12.0, 0.0, 0.0, true)
		"falhou":
			return _batida(0.07, 620.0, 560.0, 70.0, 0.0, 0.0)
	return PackedFloat32Array()


## Batida grave: um tom que cai de "de" pra "ate" Hz e some com "decaimento"
## (1/s), mais um tiquinho de ruído no começo ("ruido" de força, por "estalo" s).
## "quadrada" deixa o tom mais áspero (som de erro).
static func _batida(duracao: float, de: float, ate: float, decaimento: float, ruido: float, estalo: float, quadrada := false) -> PackedFloat32Array:
	var rng := _rng(int(de))
	var n := int(duracao * TAXA)
	var amostras := PackedFloat32Array()
	amostras.resize(n)
	var fase := 0.0
	var baixa := 0.0
	for i in n:
		var t := float(i) / TAXA
		var frequencia := lerpf(de, ate, minf(t / duracao * 2.0, 1.0))
		fase += TAU * frequencia / TAXA
		var onda := sin(fase)
		if quadrada:
			onda = clampf(onda * 3.0, -1.0, 1.0) * 0.6
		var valor := onda * exp(-decaimento * t) * minf(t * 800.0, 1.0)
		if estalo > 0.0 and t < estalo * 4.0:
			baixa += 0.35 * (rng.randf_range(-1.0, 1.0) - baixa)
			valor += baixa * ruido * exp(-t / estalo)
		amostras[i] = valor
	return _normalizar(amostras)


## Golpe em camadas, pra bater com peso:
## - grave: tom que cai de "de" pra "ate" Hz (o corpo da bola);
## - estalo: ruído agudo e curtíssimo (o couro);
## - tapa: ruído médio (a mão ou o antebraço);
## - cauda: sopro de ar que dura mais (bola saindo rápido);
## - saturacao: aperta os picos, deixando a batida mais "cheia".
static func _golpe(duracao: float, de: float, ate: float, decaimento: float, grave: float, estalo: float, estalo_decai: float, tapa: float, tapa_decai: float, cauda: float, saturacao: float, semente: int) -> PackedFloat32Array:
	var rng := _rng(semente)
	var n := int(duracao * TAXA)
	var amostras := PackedFloat32Array()
	amostras.resize(n)
	var fase := 0.0
	var l1 := 0.0
	var l2 := 0.0
	var l3 := 0.0
	var l4 := 0.0
	for i in n:
		var t := float(i) / TAXA
		var ruido := rng.randf_range(-1.0, 1.0)
		l1 += 0.3 * (ruido - l1)
		l2 += 0.18 * (ruido - l2)
		l3 += 0.03 * (ruido - l3)
		l4 += 0.08 * (ruido - l4)
		fase += TAU * lerpf(de, ate, minf(t / 0.12, 1.0)) / TAXA
		var valor := sin(fase) * exp(-decaimento * t) * grave
		valor += (ruido - l1) * exp(-estalo_decai * t) * estalo
		valor += (l2 - l3) * 3.0 * exp(-tapa_decai * t) * tapa
		valor += l4 * 3.0 * (1.0 - exp(-t * 60.0)) * exp(-10.0 * t) * cauda
		amostras[i] = tanh(valor * saturacao) * minf(t * 3000.0, 1.0)
	return _normalizar(amostras)


## Estalo da cortada (e do saque): ruído forte e curto, mais um "bum" grave.
static func _estalo() -> PackedFloat32Array:
	var rng := _rng(11)
	var duracao := 0.38
	var n := int(duracao * TAXA)
	var amostras := PackedFloat32Array()
	amostras.resize(n)
	var fase := 0.0
	var baixa := 0.0
	for i in n:
		var t := float(i) / TAXA
		var ruido := rng.randf_range(-1.0, 1.0)
		baixa += 0.25 * (ruido - baixa)
		# Ruído agudo (sem a parte grave) faz o "tapa" da mão na bola.
		var tapa := (ruido - baixa) * exp(-55.0 * t) * 0.9
		fase += TAU * lerpf(210.0, 55.0, minf(t / 0.12, 1.0)) / TAXA
		var bum := sin(fase) * exp(-16.0 * t) * 0.8
		amostras[i] = (tapa + bum) * minf(t * 2000.0, 1.0)
	return _normalizar(amostras)


## Bloqueio: duas mãos batendo quase juntas, seco e grave.
static func _bloqueio() -> PackedFloat32Array:
	var primeira := _batida(0.3, 130.0, 70.0, 20.0, 0.7, 0.02)
	var segunda := _batida(0.3, 115.0, 65.0, 22.0, 0.5, 0.02)
	var atraso := int(0.035 * TAXA)
	for i in range(atraso, primeira.size()):
		primeira[i] += segunda[i - atraso] * 0.7
	return _normalizar(primeira)


## Bola batendo na rede: ruído médio que treme (a rede balançando).
static func _rede() -> PackedFloat32Array:
	var rng := _rng(23)
	var duracao := 0.4
	var n := int(duracao * TAXA)
	var amostras := PackedFloat32Array()
	amostras.resize(n)
	var baixa := 0.0
	var mais_baixa := 0.0
	for i in n:
		var t := float(i) / TAXA
		var ruido := rng.randf_range(-1.0, 1.0)
		baixa += 0.3 * (ruido - baixa)
		mais_baixa += 0.05 * (ruido - mais_baixa)
		var faixa := baixa - mais_baixa
		var tremor := 0.6 + 0.4 * sin(TAU * 38.0 * t)
		amostras[i] = faixa * tremor * exp(-9.0 * t)
	return _normalizar(amostras)


## Bola no chão do ginásio: batida e um eco mais fraco logo depois.
static func _quique() -> PackedFloat32Array:
	var batida := _batida(0.4, 190.0, 120.0, 30.0, 0.8, 0.01)
	var atraso := int(0.11 * TAXA)
	var eco := batida.duplicate()
	for i in range(atraso, batida.size()):
		batida[i] += eco[i - atraso] * 0.3
	return _normalizar(batida)


## Apito do juiz: tom agudo com o trinado da bolinha do apito.
static func _apito() -> PackedFloat32Array:
	var duracao := 0.5
	var n := int(duracao * TAXA)
	var amostras := PackedFloat32Array()
	amostras.resize(n)
	var fase := 0.0
	for i in n:
		var t := float(i) / TAXA
		var trinado := sin(TAU * 32.0 * t)
		fase += TAU * (2650.0 + 90.0 * trinado) / TAXA
		var onda := sin(fase) + 0.25 * sin(fase * 2.0)
		var envelope := minf(t / 0.02, 1.0) * minf((duracao - t) / 0.08, 1.0)
		amostras[i] = onda * envelope * (0.8 + 0.2 * trinado)
	return _normalizar(amostras)


## Torcida: um "uaaah" de muita gente (ruído grave que sobe e desce devagar).
static func _torcida() -> PackedFloat32Array:
	var rng := _rng(31)
	var duracao := 2.2
	var n := int(duracao * TAXA)
	var amostras := PackedFloat32Array()
	amostras.resize(n)
	var baixa := 0.0
	var mais_baixa := 0.0
	for i in n:
		var t := float(i) / TAXA
		var ruido := rng.randf_range(-1.0, 1.0)
		baixa += 0.12 * (ruido - baixa)
		mais_baixa += 0.02 * (ruido - mais_baixa)
		var vozes := baixa - mais_baixa * 0.6
		# Gente gritando em ondas: soma de balanços lentos.
		var balanco := 0.75 + 0.1 * sin(TAU * 3.1 * t) + 0.08 * sin(TAU * 5.3 * t + 1.0) + 0.07 * sin(TAU * 7.7 * t + 2.0)
		var envelope := minf(t / 0.25, 1.0) * clampf((duracao - t) / 1.2, 0.0, 1.0)
		amostras[i] = vozes * balanco * envelope
	return _normalizar(amostras)


## Sininho do "Perfeito!": notas em sequência ("frequencias", uma a cada
## "intervalo" s), que somem em "duracao" s.
static func _sininho(frequencias: Array, intervalo: float, duracao: float) -> PackedFloat32Array:
	var n := int((duracao + intervalo * frequencias.size()) * TAXA)
	var amostras := PackedFloat32Array()
	amostras.resize(n)
	for k in frequencias.size():
		var comeco := int(k * intervalo * TAXA)
		var frequencia: float = frequencias[k]
		for i in range(comeco, n):
			var t := float(i - comeco) / TAXA
			var onda := sin(TAU * frequencia * t) + 0.3 * sin(TAU * frequencia * 2.0 * t)
			amostras[i] += onda * exp(-7.0 * t) * minf(t * 1500.0, 1.0)
	return _normalizar(amostras)


static func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


## Deixa o pico do som em 0,9 (todos com o mesmo "tamanho"; o volume fica em AJUSTES).
static func _normalizar(amostras: PackedFloat32Array) -> PackedFloat32Array:
	var pico := 0.0
	for valor in amostras:
		pico = maxf(pico, absf(valor))
	if pico > 0.0:
		var fator := 0.9 / pico
		for i in amostras.size():
			amostras[i] *= fator
	return amostras


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
	return wav
