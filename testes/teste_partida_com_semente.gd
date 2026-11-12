extends SceneTree
## Teste de regressão: o robô joga 90 s de Brasil x Karasuno com a semente 42
## e o resultado tem que ser sempre o mesmo (placar, lances e onde a bola caiu
## em cada rally).
##
## Pra que serve: antes de mexer na estrutura da partida (quebrar o partida.gd,
## trocar o estado), este teste mostra se o jogo mudou sem querer. Se a mudança
## foi de propósito (ajuste de número, regra nova), rode o robô com o comando
## abaixo e cole as três linhas novas em ESPERADO.
##
##   godot --headless --fixed-fps 60 --path . --script res://ferramentas/robo.gd -- times=brasil,karasuno estadio=ginasio_japones semente=42 segundos=90
##
## O robô roda em outro processo do Godot, com --fixed-fps 60 (todo quadro tem
## o mesmo tempo). Ele roda duas vezes: as duas têm que dar igual (o jogo é
## repetível) e igual ao gravado. Contas com número quebrado podem sair um
## pouquinho diferentes em outro sistema, por isso o resultado gravado é por
## sistema; num sistema sem resultado gravado, o teste só confere as duas
## rodadas e imprime as linhas pra gravar.

const ARGUMENTOS_DO_ROBO := ["times=brasil,karasuno", "estadio=ginasio_japones", "semente=42", "segundos=90"]
## Linhas do resumo do robô que entram na comparação (um pedaço de cada uma).
## A do desempenho fica de fora: depende da máquina.
const LINHAS_DO_RESUMO := ["fim depois de", "rallies (maior", "quedas (cm)"]
## Resultado gravado, por sistema (OS.get_name()), sem o "Robô: " do começo.
const ESPERADO := {
	"Windows": [
		"fim depois de 90 s de jogo. Sets 0 x 0, pontos 1 x 4, estado RALLY.",
		"5 rallies (maior com 34 toques), lances: { \"saques\": 6, \"passes\": 44, \"levantamentos\": 42, \"cortadas\": 34, \"bloqueios\": 316 }",
		"quedas (cm): 31,583 -353,129 -3,-392 348,117 -359,120",
	],
}

var falhas := 0


func _initialize() -> void:
	var primeira := _rodar_o_robo()
	var segunda := _rodar_o_robo()
	_verificar(primeira.size() == 3, "o robô terminou e imprimiu o resumo (%d linhas)" % primeira.size())
	_verificar(primeira == segunda, "duas rodadas com a mesma semente dão o mesmo resultado")
	var sistema := OS.get_name()
	if ESPERADO.has(sistema):
		var esperado: Array = ESPERADO[sistema]
		for i in esperado.size():
			var obtido: String = primeira[i] if i < primeira.size() else "(nada)"
			_verificar(obtido == esperado[i], "linha %d igual à gravada\n    gravada: %s\n    agora:   %s" % [i + 1, esperado[i], obtido])
	else:
		print("AVISO: sem resultado gravado para %s; só conferi que as duas rodadas são iguais. Pra gravar, cole em ESPERADO:" % sistema)
		for linha in primeira:
			print("    ", linha)

	if falhas == 0:
		print("OK: a partida com semente fixa se repete igual.")
	else:
		print("FALHOU: %d verificação(ões) da partida com semente." % falhas)
	quit(1 if falhas > 0 else 0)


## Roda o robô num Godot separado e devolve as linhas do resumo que não
## dependem da máquina, sem o "Robô: " do começo. (No Windows a saída do outro
## processo chega com o acento trocado, "RobÃ´", por isso a comparação usa só
## o texto depois dele, que não tem acento.)
func _rodar_o_robo() -> Array[String]:
	var argumentos: Array[String] = ["--headless", "--fixed-fps", "60",
		"--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://ferramentas/robo.gd", "--"]
	argumentos.append_array(ARGUMENTOS_DO_ROBO)
	var saida: Array = []
	var codigo := OS.execute(OS.get_executable_path(), argumentos, saida, true)
	var linhas: Array[String] = []
	for linha in "\n".join(saida).split("\n"):
		var limpa := linha.strip_edges()
		var depois := limpa.substr(limpa.find(": ") + 2) if limpa.begins_with("Rob") else ""
		for comeco in LINHAS_DO_RESUMO:
			if depois.contains(comeco):
				linhas.append(depois)
		if limpa.contains("SCRIPT ERROR"):
			_verificar(false, "o robô deu erro de script: %s" % limpa)
	if codigo != 0:
		_verificar(false, "o robô saiu com código %d" % codigo)
	return linhas


func _verificar(condicao: bool, descricao: String) -> void:
	if not condicao:
		falhas += 1
		print("  falhou: ", descricao)
