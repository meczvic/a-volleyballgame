extends SceneTree
## Confere os arquivos de dados (times e estádios) e quem lê eles.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_dados.gd

const Dados := preload("res://scripts/comum/dados.gd")
const ScriptDaConfiguracao := preload("res://scripts/menus/configuracao.gd")

const ATRIBUTOS := ["ataque", "defesa", "saque", "bloqueio", "velocidade"]
const CORES_DO_ESTADIO := ["fundo", "zona_livre", "quadra", "linhas", "placas", "luz"]

var falhas := 0


func _init() -> void:
	_teste_times()
	_teste_estadios()
	_teste_busca_por_id()
	_teste_padrao_da_configuracao()
	_teste_elenco()

	if falhas == 0:
		print("OK: todos os testes dos dados passaram.")
	else:
		print("FALHOU: %d verificação(ões) dos dados." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _teste_times() -> void:
	var times := Dados.times()
	_verificar(times.size() == 7, "são 7 times")
	var ids := {}
	for time in times:
		var id := str(time.get("id", ""))
		_verificar(id != "" and not ids.has(id), "id único: %s" % id)
		ids[id] = true
		var atributos: Dictionary = time.get("atributos", {})
		var soma := 0
		for atributo in ATRIBUTOS:
			var valor := int(atributos.get(atributo, 0))
			_verificar(valor >= 1 and valor <= 5, "%s: %s entre 1 e 5" % [id, atributo])
			soma += valor
		_verificar(soma == 17, "%s: atributos somam 17 (deu %d)" % [id, soma])
		var cores: Array = time.get("cores", [])
		_verificar(cores.size() == 3, "%s: 3 cores de uniforme" % id)
		for cor in cores:
			_verificar(Color.html_is_valid(str(cor)), "%s: cor %s válida" % [id, cor])
		_verificar(Color.html_is_valid(str(time.get("cor_do_menu", ""))), "%s: cor_do_menu válida" % id)


func _teste_estadios() -> void:
	var estadios := Dados.estadios()
	_verificar(estadios.size() >= 1, "tem pelo menos 1 estádio")
	var ids := {}
	for estadio in estadios:
		var id := str(estadio.get("id", ""))
		_verificar(id != "" and not ids.has(id), "id único: %s" % id)
		ids[id] = true
		_verificar(str(estadio.get("nome", "")) != "", "%s: tem nome" % id)
		var cores: Dictionary = estadio.get("cores", {})
		for chave in CORES_DO_ESTADIO:
			_verificar(Color.html_is_valid(str(cores.get(chave, ""))), "%s: cor %s válida" % [id, chave])


func _teste_busca_por_id() -> void:
	var times := Dados.times()
	_verificar(Dados.por_id(times, "nekoma").get("nome") == "Nekoma", "acha o time pelo id")
	_verificar(Dados.indice_de(times, "brasil") == 6, "Brasil é o 7º da lista")
	_verificar(Dados.por_id(times, "nao_existe").get("id") == times[0].get("id"), "id errado devolve o primeiro")
	_verificar(Dados.por_id([], "karasuno").is_empty(), "lista vazia devolve vazio")
	var cores := {"boa": "#FF0000", "ruim": "azul-ish"}
	_verificar(Dados.cor(cores, "boa", Color.BLACK) == Color(1, 0, 0), "lê cor certa")
	_verificar(Dados.cor(cores, "ruim", Color.BLACK) == Color.BLACK, "cor errada usa o padrão")
	_verificar(Dados.cor(cores, "falta", Color.BLACK) == Color.BLACK, "cor que falta usa o padrão")


## O padrão (rodar a partida direto, sem menus) precisa existir nos dados.
func _teste_padrao_da_configuracao() -> void:
	var configuracao = ScriptDaConfiguracao.new()
	var ids_dos_times := []
	for time in Dados.times():
		ids_dos_times.append(time["id"])
	var ids_dos_estadios := []
	for estadio in Dados.estadios():
		ids_dos_estadios.append(estadio["id"])
	for id in configuracao.times:
		_verificar(id in ids_dos_times, "time padrão existe: %s" % id)
	_verificar(configuracao.estadio in ids_dos_estadios, "estádio padrão existe")
	_verificar(ids_dos_estadios[0] == configuracao.estadio, "o estádio padrão é o primeiro da lista")
	configuracao.free()


## Cada time tem 6 atletas de quadra (1 levantador, 2 ponteiros, 2 centrais, 1 oposto),
## sem líbero, com números diferentes e nome de arquivo no padrão.
func _teste_elenco() -> void:
	var nome_valido := RegEx.create_from_string("^[a-z0-9_]+$")
	for time in Dados.times():
		var id := str(time["id"])
		var elenco := Dados.elenco(id)
		_verificar(elenco.size() == 6, "%s: 6 atletas no elenco" % id)
		var numeros := {}
		var funcoes := {}
		for atleta in elenco:
			var numero := int(atleta.get("numero", 0))
			_verificar(numero >= 1 and numero <= 99, "%s: número %d entre 1 e 99" % [id, numero])
			_verificar(not numeros.has(numero), "%s: número %d repetido" % [id, numero])
			numeros[numero] = true
			_verificar(str(atleta.get("nome", "")) != "", "%s: atleta %d tem nome" % [id, numero])
			_verificar(nome_valido.search(str(atleta.get("arquivo", ""))) != null, "%s: arquivo do %d sem acento nem espaço" % [id, numero])
			_verificar(not atleta.get("libero", false), "%s: %d não é líbero (o jogo não usa líbero)" % [id, numero])
			var funcao := str(atleta.get("posicao", ""))
			funcoes[funcao] = int(funcoes.get(funcao, 0)) + 1
		var esperado := {"levantador": 1, "ponteiro": 2, "central": 2, "oposto": 1}
		_verificar(funcoes == esperado, "%s: 1 levantador, 2 ponteiros, 2 centrais e 1 oposto (tem %s)" % [id, funcoes])
	var hinata := {"numero": 10, "arquivo": "hinata"}
	_verificar(Dados.caminho_do_personagem("karasuno", hinata) == "res://personagens/karasuno/10_hinata.vrm", "caminho do personagem no padrão")
	_verificar(Dados.caminho_do_personagem("nekoma", {"numero": 5, "arquivo": "kenma"}).ends_with("/05_kenma.vrm"), "número com 2 dígitos")
	_verificar(Dados.elenco("nao_existe").is_empty(), "time sem elenco devolve vazio")
