extends SceneTree
## Fase E: comandos com número do quadro. Grava uma partida do computador
## contra ele mesmo (robô com gravar=) e repete só com a gravação (repetir=).
## As duas têm que sair iguais: mesmo placar, mesmos lances, mesmas quedas.
##   godot --headless --path . --script res://testes/teste_repeticao.gd

const GRAVACAO := "user://teste_repeticao.json"
const ARGUMENTOS := ["computador=dificil", "semente=9", "segundos=40", "times=brasil,karasuno", "estadio=ginasio_japones"]

var falhas := 0


func _initialize() -> void:
	var caminho := ProjectSettings.globalize_path(GRAVACAO)
	DirAccess.remove_absolute(caminho)
	var gravada := _rodar_o_robo(["dois=1", "gravar=" + caminho])
	_verificar(FileAccess.file_exists(caminho), "a gravação foi salva")
	var repetida := _rodar_o_robo(["repetir=" + caminho])
	_verificar(gravada.size() == 3, "a partida gravada terminou (%d linhas)" % gravada.size())
	_verificar(gravada == repetida, "a repetição sai igual à gravada\n    gravada:  %s\n    repetida: %s" % [gravada, repetida])
	if falhas == 0:
		print("OK: a partida repetida pela gravação sai igual.")
	else:
		print("FALHOU: %d verificação(ões) da repetição." % falhas)
	quit(1 if falhas > 0 else 0)


## Roda o robô e devolve as linhas do resumo (fim, rallies, quedas).
func _rodar_o_robo(extras: Array) -> Array[String]:
	var argumentos: Array[String] = ["--headless", "--fixed-fps", "60",
		"--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://ferramentas/robo.gd", "--"]
	for a in ARGUMENTOS:
		argumentos.append(a)
	for a in extras:
		argumentos.append(str(a))
	var saida: Array = []
	OS.execute(OS.get_executable_path(), argumentos, saida, true)
	var linhas: Array[String] = []
	for linha in "\n".join(saida).split("\n"):
		var limpa := linha.strip_edges()
		# Sem depender do acento de "Robô" (o terminal pode trocar).
		for marca in ["fim depois de", " rallies (maior", "quedas (cm)"]:
			var onde := limpa.find(marca)
			if onde >= 0:
				linhas.append(limpa.substr(onde))
	return linhas


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)
