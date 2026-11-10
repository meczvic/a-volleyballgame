extends RefCounted
## Lê os arquivos da pasta "dados/" (times, estádios e elenco).
##
## Uso: var times := Dados.times()
##      var karasuno := Dados.por_id(times, "karasuno")

const ARQUIVO_TIMES := "res://dados/times.json"
const ARQUIVO_ESTADIOS := "res://dados/estadios.json"
const ARQUIVO_ELENCO := "res://dados/elenco.json"
const ARQUIVO_APARENCIA := "res://dados/aparencia.json"
const ARQUIVO_CARTAS := "res://dados/cartas.json"
const PASTA_PERSONAGENS := "res://personagens"
const GeradorDeAtleta := preload("res://scripts/visual/gerador_de_atleta.gd")


static func times() -> Array:
	return _ler(ARQUIVO_TIMES).get("times", [])


static func estadios() -> Array:
	return _ler(ARQUIVO_ESTADIOS).get("estadios", [])


## Cartas e conjuntos do Modo Caos (dados/cartas.json).
static func cartas() -> Dictionary:
	return _ler(ARQUIVO_CARTAS)


## Os 6 atletas do time, na ordem do rodízio inicial (vazio se o time não tiver elenco).
static func elenco(id_time: String) -> Array:
	return _ler(ARQUIVO_ELENCO).get("times", {}).get(id_time, [])


## Caminho do personagem do VRoid: personagens/<time>/<número com 2 dígitos>_<arquivo>.vrm
static func caminho_do_personagem(id_time: String, atleta: Dictionary) -> String:
	return "%s/%s/%02d_%s.vrm" % [PASTA_PERSONAGENS, id_time, int(atleta.get("numero", 0)), str(atleta.get("arquivo", ""))]


## Chave do atleta nos arquivos de produção: "10_hinata".
static func chave_do_atleta(atleta: Dictionary) -> String:
	return "%02d_%s" % [int(atleta.get("numero", 0)), str(atleta.get("arquivo", ""))]


## Aparência do atleta (dados/aparencia.json), ou {} se ele ainda não tem.
static func aparencia(id_time: String, atleta: Dictionary) -> Dictionary:
	return _ler(ARQUIVO_APARENCIA).get("times", {}).get(id_time, {}).get(chave_do_atleta(atleta), {})


## De onde vem o personagem que a partida usa pra esse atleta:
## "vrm" (arquivo do VRoid), "gerado" (código + dados/aparencia.json) ou "capsula".
static func fonte_do_personagem(id_time: String, atleta: Dictionary) -> String:
	if atleta.is_empty():
		return "capsula"
	if ResourceLoader.exists(caminho_do_personagem(id_time, atleta)):
		return "vrm"
	if not aparencia(id_time, atleta).is_empty():
		return "gerado"
	return "capsula"


## Monta o personagem do atleta com o uniforme do time ("cores" do time, já com
## o reserva aplicado se for o caso). Devolve null quando só sobra a cápsula.
## É o mesmo caminho da partida e das ferramentas de captura e teste.
static func carregar_personagem(time: Dictionary, atleta: Dictionary) -> Node3D:
	var id_time := str(time.get("id", ""))
	match fonte_do_personagem(id_time, atleta):
		"vrm":
			var cena = load(caminho_do_personagem(id_time, atleta))
			if not cena is PackedScene:
				push_warning("O arquivo %s não virou uma cena (o plugin VRM está ativo?)." % caminho_do_personagem(id_time, atleta))
				return null
			return cena.instantiate() as Node3D
		"gerado":
			var uniforme := {"cores": time.get("cores", []), "numero": int(atleta.get("numero", 0))}
			return GeradorDeAtleta.criar(aparencia(id_time, atleta), uniforme)
	return null


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
