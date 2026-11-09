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
## Velocidade do jogo enquanto congela (quase parado).
const ESCALA_CONGELADA := 0.03

var cameras: Array[Camera3D] = []

var _forca := 0.0
var _resta := 0.0
var _congelado_ate := -1.0
var _ultimo := 0.0


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



func _agora() -> float:
	return Time.get_ticks_msec() / 1000.0
