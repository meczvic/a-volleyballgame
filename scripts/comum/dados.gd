extends RefCounted
## Lê os arquivos da pasta "dados/" (times e estádios).
##
## Uso: var times := Dados.times()
##      var karasuno := Dados.por_id(times, "karasuno")

const ARQUIVO_TIMES := "res://dados/times.json"
const ARQUIVO_ESTADIOS := "res://dados/estadios.json"


static func times() -> Array:
	return _ler(ARQUIVO_TIMES).get("times", [])


static func estadios() -> Array:
	return _ler(ARQUIVO_ESTADIOS).get("estadios", [])


## Procura um item pelo "id". Se não achar, devolve o primeiro da lista
## (assim um id antigo ou digitado errado nunca trava o jogo).
static func por_id(lista: Array, id: String) -> Dictionary:
	if lista.is_empty():
		return {}
	return lista[indice_de(lista, id)]


## Posição do item com esse "id" na lista (0 se não achar).
static func indice_de(lista: Array, id: String) -> int:
	for i in lista.size():
		if str(lista[i].get("id", "")) == id:
			return i
	return 0


## Lê uma cor "#RRGGBB" de um dicionário. Se faltar ou estiver errada, usa "padrao".
static func cor(dados: Dictionary, chave: String, padrao: Color) -> Color:
	return Color.from_string(str(dados.get(chave, "")), padrao)


static func _ler(caminho: String) -> Dictionary:
	var texto := FileAccess.get_file_as_string(caminho)
	var dados = JSON.parse_string(texto)
	if typeof(dados) != TYPE_DICTIONARY:
		push_error("Não consegui ler o arquivo %s (confira se o JSON está certo)." % caminho)
		return {}
	return dados
