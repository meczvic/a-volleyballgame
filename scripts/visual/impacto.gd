extends Node
## Impacto ("juice") dos lances fortes: congela o jogo por um instante e
## treme as câmeras. Funciona mesmo com o jogo em câmera lenta.
##
## Uso (na partida): impacto.cameras = [...]; impacto.cortada(forte)

## Congelada da cortada perfeita e da normal (segundos de verdade).
const CONGELAR_FORTE := 0.09
const CONGELAR_NORMAL := 0.04
## Tremor das câmeras (m) e quanto dura (s).
const TREMOR_FORTE := 0.35
const TREMOR_NORMAL := 0.15
const DURACAO_DO_TREMOR := 0.3
const CONGELAR_BLOQUEIO := 0.06
const TREMOR_BLOQUEIO := 0.25
const TREMOR_PONTO := 0.1
## Velocidade do jogo enquanto congela (quase parado).
const ESCALA_CONGELADA := 0.03
## "Soco" de zoom: a lente fecha uns graus de uma vez e abre de volta devagar.
## Só visual (não mexe no tempo do jogo). Graus a menos na abertura e duração (s).
const ZOOM_FORTE := 5.0
const ZOOM_NORMAL := 1.5
const ZOOM_BLOQUEIO := 3.0
const DURACAO_DO_ZOOM := 0.4

var cameras: Array[Camera3D] = []

var _forca := 0.0
var _resta := 0.0
var _congelado_ate := -1.0
var _ultimo := 0.0
var _zoom := 0.0
var _zoom_resta := 0.0
## Abertura normal de cada câmera (guardada no primeiro zoom).
var _aberturas := {}


func _ready() -> void:
	# Precisa rodar com o jogo congelado ou pausado pra conseguir voltar.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ultimo = _agora()


func _exit_tree() -> void:
	# Nunca deixa o jogo lento ao sair da partida.
	Engine.time_scale = 1.0


## Impacto da cortada. "forte": cortada perfeita.
func cortada(forte: bool) -> void:
	congelar(CONGELAR_FORTE if forte else CONGELAR_NORMAL)
	tremer(TREMOR_FORTE if forte else TREMOR_NORMAL)
	zoom(ZOOM_FORTE if forte else ZOOM_NORMAL)


## Impacto do bloqueio: congela um pouco, treme e dá um soco de zoom.
func bloqueio() -> void:
	congelar(CONGELAR_BLOQUEIO)
	tremer(TREMOR_BLOQUEIO)
	zoom(ZOOM_BLOQUEIO)


## Fecha a lente das câmeras "graus" de uma vez; ela volta sozinha em DURACAO_DO_ZOOM.
func zoom(graus: float) -> void:
	for camera in cameras:
		if is_instance_valid(camera) and not _aberturas.has(camera):
			_aberturas[camera] = camera.fov
	_zoom = maxf(_zoom, graus)
	_zoom_resta = DURACAO_DO_ZOOM
	_aplicar_zoom()


## Pra testes: quantos graus de zoom estão valendo agora.
func zoom_atual() -> float:
	if _zoom_resta <= 0.0:
		return 0.0
	var fracao := _zoom_resta / DURACAO_DO_ZOOM
	return _zoom * fracao * fracao


## Bola caindo dentro: um tremor curto.
func ponto() -> void:
	tremer(TREMOR_PONTO)


## Deixa o jogo quase parado por "segundos" (tempo de verdade).
func congelar(segundos: float) -> void:
	Engine.time_scale = ESCALA_CONGELADA
	_congelado_ate = maxf(_congelado_ate, _agora() + segundos)


func tremer(forca: float) -> void:
	_forca = maxf(_forca, forca)
	_resta = DURACAO_DO_TREMOR


func _process(_delta: float) -> void:
	# Mede em tempo de verdade, porque o delta encolhe com o jogo congelado.
	var agora := _agora()
	var passou := agora - _ultimo
	_ultimo = agora
	if _congelado_ate > 0.0 and agora >= _congelado_ate:
		_congelado_ate = -1.0
		Engine.time_scale = 1.0

	if _resta > 0.0:
		_resta = maxf(_resta - passou, 0.0)
		var forca := _forca * (_resta / DURACAO_DO_TREMOR)
		for camera in cameras:
			if is_instance_valid(camera):
				camera.h_offset = randf_range(-forca, forca)
				camera.v_offset = randf_range(-forca, forca)
		if _resta == 0.0:
			_forca = 0.0

	if _zoom_resta > 0.0:
		_zoom_resta = maxf(_zoom_resta - passou, 0.0)
		_aplicar_zoom()
		if _zoom_resta == 0.0:
			_zoom = 0.0


func _aplicar_zoom() -> void:
	var graus := zoom_atual()
	for camera in _aberturas:
		if is_instance_valid(camera):
			camera.fov = float(_aberturas[camera]) - graus



## Relógio de verdade contado em quadros de física: eles continuam no mesmo
## ritmo com o jogo congelado (só o delta encolhe). Assim a congelada dura
## sempre os mesmos quadros e a partida com semente fixa se repete igual
## (com o relógio do sistema, ela durava quadros diferentes a cada vez).
func _agora() -> float:
	return float(Engine.get_physics_frames()) / Engine.physics_ticks_per_second
