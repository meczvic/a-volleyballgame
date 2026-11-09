extends Node
## Cria as ações de teclado e controle dos 2 jogadores ao abrir o jogo.
##
## Cada ação vira "p1_passe", "p2_ataque" etc.
## Jogador 1: WASD + J K L I Espaço, ou o 1º controle.
## Jogador 2: setas + teclado numérico, ou o 2º controle.

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

			if EIXOS_CONTROLE.has(acao):
				var eixo := InputEventJoypadMotion.new()
				eixo.device = controle
				eixo.axis = EIXOS_CONTROLE[acao][0]
				eixo.axis_value = EIXOS_CONTROLE[acao][1]
				InputMap.action_add_event(nome, eixo)
