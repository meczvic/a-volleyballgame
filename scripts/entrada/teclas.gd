extends Node
## Cria as ações de teclado e controle dos 2 jogadores ao abrir o jogo.
##
## Cada ação vira "p1_passe", "p2_ataque" etc.
## Jogador 1: WASD + J K L I Espaço, ou o 1º controle.
## Jogador 2: setas + teclado numérico, ou o 2º controle.
##
## Também cria "pausa" (Esc ou Start) e "voltar" (Esc ou Backspace),
## e ajusta as ações dos menus (ui_accept, ui_cancel...) pra combinar com o jogo.

const ACOES := ["cima", "baixo", "esquerda", "direita", "passe", "ataque", "saque_flutuante", "bloqueio", "mergulho"]

const TECLAS := {
	1: {
		"cima": KEY_W, "baixo": KEY_S, "esquerda": KEY_A, "direita": KEY_D,
		"passe": KEY_J, "ataque": KEY_K, "bloqueio": KEY_L,
		"saque_flutuante": KEY_I, "mergulho": KEY_SPACE,
	},
	2: {
		"cima": KEY_UP, "baixo": KEY_DOWN, "esquerda": KEY_LEFT, "direita": KEY_RIGHT,
		"passe": KEY_KP_1, "ataque": KEY_KP_2, "bloqueio": KEY_KP_3,
		"saque_flutuante": KEY_KP_5, "mergulho": KEY_KP_0,
	},
}

const BOTOES_CONTROLE := {
	"passe": JOY_BUTTON_A,
	"ataque": JOY_BUTTON_X,
	"bloqueio": JOY_BUTTON_Y,
	"mergulho": JOY_BUTTON_B,
	"saque_flutuante": JOY_BUTTON_RIGHT_SHOULDER,
}

## Direcional do controle (setas do controle).
const DIRECIONAL_CONTROLE := {
	"cima": JOY_BUTTON_DPAD_UP,
	"baixo": JOY_BUTTON_DPAD_DOWN,
	"esquerda": JOY_BUTTON_DPAD_LEFT,
	"direita": JOY_BUTTON_DPAD_RIGHT,
}

## Ação -> [eixo do analógico esquerdo, direção].
const EIXOS_CONTROLE := {
	"cima": [JOY_AXIS_LEFT_Y, -1.0],
	"baixo": [JOY_AXIS_LEFT_Y, 1.0],
	"esquerda": [JOY_AXIS_LEFT_X, -1.0],
	"direita": [JOY_AXIS_LEFT_X, 1.0],
}


static func acao_de(jogador: int, acao: String) -> String:
	return "p%d_%s" % [jogador, acao]


func _ready() -> void:
	for jogador in [1, 2]:
		var controle: int = jogador - 1
		for acao in ACOES:
			var nome := acao_de(jogador, acao)
			if InputMap.has_action(nome):
				continue
			InputMap.add_action(nome, 0.3)

			var tecla := InputEventKey.new()
			tecla.physical_keycode = TECLAS[jogador][acao]
			InputMap.action_add_event(nome, tecla)

			if BOTOES_CONTROLE.has(acao):
				var botao := InputEventJoypadButton.new()
				botao.device = controle
				botao.button_index = BOTOES_CONTROLE[acao]
				InputMap.action_add_event(nome, botao)

			if DIRECIONAL_CONTROLE.has(acao):
				var seta := InputEventJoypadButton.new()
				seta.device = controle
				seta.button_index = DIRECIONAL_CONTROLE[acao]
				InputMap.action_add_event(nome, seta)

			if EIXOS_CONTROLE.has(acao):
				var eixo := InputEventJoypadMotion.new()
				eixo.device = controle
				eixo.axis = EIXOS_CONTROLE[acao][0]
				eixo.axis_value = EIXOS_CONTROLE[acao][1]
				InputMap.action_add_event(nome, eixo)

	_criar_acoes_gerais()
	_ajustar_acoes_dos_menus()


## Ações que não são de um jogador só.
func _criar_acoes_gerais() -> void:
	_adicionar_tecla("pausa", KEY_ESCAPE)
	_adicionar_botao("pausa", JOY_BUTTON_START)
	_adicionar_tecla("voltar", KEY_ESCAPE)
	_adicionar_tecla("voltar", KEY_BACKSPACE)


## Nos menus: J, 1 (numérico) e A escolhem; Espaço, 0 (numérico) e B voltam;
## WASD e o direcional também navegam. Espaço é o "mergulho" do Jogador 1,
## então ele deixa de escolher nos menus pra não confundir.
func _ajustar_acoes_dos_menus() -> void:
	for evento in InputMap.action_get_events("ui_accept"):
		var tecla := evento as InputEventKey
		if tecla != null and (tecla.keycode == KEY_SPACE or tecla.physical_keycode == KEY_SPACE):
			InputMap.action_erase_event("ui_accept", evento)

	_adicionar_tecla("ui_accept", KEY_J)
	_adicionar_tecla("ui_accept", KEY_KP_1)
	_adicionar_botao("ui_accept", JOY_BUTTON_A)
	_adicionar_tecla("ui_cancel", KEY_SPACE)
	_adicionar_tecla("ui_cancel", KEY_KP_0)
	_adicionar_botao("ui_cancel", JOY_BUTTON_B)

	var direcoes := {
		"ui_up": [KEY_W, JOY_BUTTON_DPAD_UP],
		"ui_down": [KEY_S, JOY_BUTTON_DPAD_DOWN],
		"ui_left": [KEY_A, JOY_BUTTON_DPAD_LEFT],
		"ui_right": [KEY_D, JOY_BUTTON_DPAD_RIGHT],
	}
	for acao in direcoes:
		_adicionar_tecla(acao, direcoes[acao][0])
		_adicionar_botao(acao, direcoes[acao][1])


## Adiciona uma tecla (pela posição no teclado) a uma ação, criando a ação se faltar.
func _adicionar_tecla(acao: String, tecla) -> void:
	var evento := InputEventKey.new()
	evento.physical_keycode = tecla
	_adicionar_evento(acao, evento)


## Adiciona um botão de qualquer controle a uma ação, criando a ação se faltar.
func _adicionar_botao(acao: String, botao) -> void:
	var evento := InputEventJoypadButton.new()
	evento.device = -1  # qualquer controle
	evento.button_index = botao
	_adicionar_evento(acao, evento)


func _adicionar_evento(acao: String, evento: InputEvent) -> void:
	if not InputMap.has_action(acao):
		InputMap.add_action(acao)
	if not InputMap.action_has_event(acao, evento):
		InputMap.action_add_event(acao, evento)
