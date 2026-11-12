extends RefCounted
## Lê os números de equilíbrio de dados/ajustes.json (Etapa 5 do plano de
## jogabilidade). Cada número tem um valor padrão no código; se o arquivo
## faltar, estiver quebrado ou não tiver a chave, vale o padrão. Assim dá pra
## ajustar o jogo editando só o JSON, sem mexer em script.
##
## Uso: var bloqueio := Ajustes.pegar("ataques", "bloqueio_do_pipe", 0.7)

const ARQUIVO := "res://dados/ajustes.json"

static var _dados: Dictionary = {}
static var _carregado := false


static func pegar(grupo: String, chave: String, padrao: float) -> float:
	if not _carregado:
		recarregar()
	var do_grupo = _dados.get(grupo, {})
	if do_grupo is Dictionary and do_grupo.has(chave):
		var valor = do_grupo[chave]
		if valor is float or valor is int:
			return float(valor)
	return padrao


## Lê o arquivo de novo (pros testes e pra quem editou o JSON com o jogo aberto).
static func recarregar() -> void:
	_carregado = true
	_dados = {}
	if not FileAccess.file_exists(ARQUIVO):
		return
	var texto := FileAccess.get_file_as_string(ARQUIVO)
	var lido = JSON.parse_string(texto)
	if lido is Dictionary:
		_dados = lido


## Pros testes: usa estes dados em vez do arquivo (vazio = só os padrões).
static func usar_dados(dados: Dictionary) -> void:
	_carregado = true
	_dados = dados
