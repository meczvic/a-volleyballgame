extends RefCounted
## Lê os arquivos da pasta "dados/" (times, estádios e elenco).
##
## Uso: var times := Dados.times()
##      var karasuno := Dados.por_id(times, "karasuno")

const ARQUIVO_TIMES := "res://dados/times.json"
const ARQUIVO_ESTADIOS := "res://dados/estadios.json"
const ARQUIVO_ELENCO := "res://dados/elenco.json"
const PASTA_PERSONAGENS := "res://personagens"


static func times() -> Array:
	return _ler(ARQUIVO_TIMES).get("times", [])


static func estadios() -> Array:
	return _ler(ARQUIVO_ESTADIOS).get("estadios", [])


## Os 6 atletas do time, na ordem do rodízio inicial (vazio se o time não tiver elenco).
static func elenco(id_time: String) -> Array:
	return _ler(ARQUIVO_ELENCO).get("times", {}).get(id_time, [])


## Caminho do personagem do VRoid: personagens/<time>/<número com 2 dígitos>_<arquivo>.vrm
static func caminho_do_personagem(id_time: String, atleta: Dictionary) -> String:
	return "%s/%s/%02d_%s.vrm" % [PASTA_PERSONAGENS, id_time, int(atleta.get("numero", 0)), str(atleta.get("arquivo", ""))]


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
