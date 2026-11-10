extends RefCounted
## Cartas do Modo Caos: sorteio, mão de cada time e o que cada carta muda.
##
## Regra pura, sem nós nem gráfico. As cartas vêm de dados/cartas.json
## (Dados.cartas()). A mão de um time é uma lista de ids de cartas.
##
## O que a partida usa: Cartas.modificadores(dados, mao) devolve os números
## que mudam o jogo (ver scripts/regras/atributos.gd). A partida guarda esse
## dicionário em time["modificadores"].

## Cartas que já têm efeito no jogo. Só estas entram no sorteio; as outras
## continuam em dados/cartas.json esperando o efeito ser feito.
const IMPLEMENTADAS := [
	"maos_firmes", "pes_leves", "tapete_vermelho", "saque_firme", "levantador_preciso",
	"muro", "ataque_rapido",
	"troca_de_lugar",
]

## Peso de cada raridade no sorteio (prata sai mais, prismática é rara).
const PESO_DA_RARIDADE := { "prata": 60, "ouro": 30, "prismatica": 10 }

## O que cada carta muda. Os números em SOMAS são somados (começam em 0); os
## outros são multiplicados (começam em 1.0). "levantamento_perfeito" e
## "levantamento_rapido" valem 1 quando a carta está na mão.
const EFEITOS := {
	"maos_firmes": { "janela_passe": 1.2 },
	"pes_leves": { "velocidade": 1.15 },
	"tapete_vermelho": { "tempo_no_chao": 0.5 },
	"saque_firme": { "erro_do_saque": 0.8 },
	"levantador_preciso": { "levantamento_perfeito": 1.0 },
	"muro": { "largura_do_bloqueio": 1.3 },
	"ataque_rapido": { "levantamento_rapido": 1.0 },
}

## Bônus de conjunto: conjunto -> quantidade mínima -> efeito. Quem tem 3
## cartas do conjunto também ganha o bônus de 2.
const BONUS_DE_CONJUNTO := {
	"ataque": { 2: { "forca_da_cortada": 0.08 } },
	"defesa": { 2: { "janela_passe": 1.1 } },
	"saque": { 2: { "erro_do_saque": 0.9 } },
	"velocidade": { 2: { "velocidade": 1.1 }, 3: { "tempo_no_chao": 0.0 } },
}

const SOMAS := ["forca_da_cortada", "alcance_do_mergulho", "levantamento_perfeito", "levantamento_rapido"]

const ID_DA_TROCA := "troca_de_lugar"


static func todas(dados: Dictionary) -> Array:
	return dados.get("cartas", [])


## A carta com esse id, ou {} se não existir.
static func por_id(dados: Dictionary, id: String) -> Dictionary:
	for carta in todas(dados):
		if str(carta.get("id", "")) == id:
			return carta
	return {}


static func tempo_limite(dados: Dictionary) -> float:
	return float(dados.get("tempo_limite_escolha", 60))


static func cartas_por_escolha(dados: Dictionary) -> int:
	return maxi(int(dados.get("cartas_por_escolha", 3)), 1)


## A cada quantos pontos (de todo o jogo) os dois escolhem uma carta.
static func pontos_por_escolha(dados: Dictionary) -> int:
	return maxi(int(dados.get("pontos_por_escolha", 3)), 1)


## Depois do ponto de número "pontos_jogados" (1, 2, 3...), abre a escolha?
static func deve_escolher(dados: Dictionary, pontos_jogados: int) -> bool:
	return pontos_jogados > 0 and pontos_jogados % pontos_por_escolha(dados) == 0


## Ids que podem ser sorteados agora: têm efeito, ainda não estão na mão e,
## no caso da Troca de Lugar, o adversário já pegou uma carta que dá pra copiar.
static func disponiveis(dados: Dictionary, mao: Array, ultima_do_adversario := "") -> Array:
	var ids: Array = []
	for carta in todas(dados):
		var id := str(carta.get("id", ""))
		if not IMPLEMENTADAS.has(id) or mao.has(id):
			continue
		if id == ID_DA_TROCA and not _da_pra_copiar(ultima_do_adversario, mao):
			continue
		ids.append(id)
	return ids


## Sorteia até "quantidade" cartas diferentes (menos se não houver tantas).
## Primeiro sorteia a raridade pelo peso, depois uma carta dessa raridade.
static func sortear(dados: Dictionary, mao: Array, rng: RandomNumberGenerator,
		quantidade := 3, ultima_do_adversario := "") -> Array:
	var restantes := disponiveis(dados, mao, ultima_do_adversario)
	var sorteadas: Array = []
	while sorteadas.size() < quantidade and not restantes.is_empty():
		var raridade := _sortear_raridade(dados, restantes, rng)
		var da_raridade: Array = []
		for id in restantes:
			if str(por_id(dados, id).get("raridade", "")) == raridade:
				da_raridade.append(id)
		var escolhida: String = da_raridade[rng.randi_range(0, da_raridade.size() - 1)]
		sorteadas.append(escolhida)
		restantes.erase(escolhida)
	return sorteadas


## Mão nova com a carta escolhida. A Troca de Lugar não fica na mão: no lugar
## dela entra uma cópia da última carta do adversário.
static func adicionar(mao: Array, id: String, ultima_do_adversario := "") -> Array:
	var nova := mao.duplicate()
	if id == ID_DA_TROCA:
		if _da_pra_copiar(ultima_do_adversario, mao):
			nova.append(ultima_do_adversario)
		return nova
	if not nova.has(id):
		nova.append(id)
	return nova


## Quantas cartas de cada conjunto a mão tem.
static func conjuntos(dados: Dictionary, mao: Array) -> Dictionary:
	var contagem := {}
	for id in mao:
		var conjunto := str(por_id(dados, id).get("conjunto", ""))
		if conjunto == "" or conjunto == "coringa":
			continue
		contagem[conjunto] = int(contagem.get(conjunto, 0)) + 1
	return contagem


## Todos os números que a mão muda no jogo (cartas + bônus de conjunto).
## Só aparecem as chaves que alguma carta mexe; o resto o jogo lê como normal.
static func modificadores(dados: Dictionary, mao: Array) -> Dictionary:
	var mods := {}
	for id in mao:
		_combinar(mods, EFEITOS.get(id, {}))
	var contagem := conjuntos(dados, mao)
	for conjunto in contagem:
		var bonus: Dictionary = BONUS_DE_CONJUNTO.get(conjunto, {})
		for minimo in bonus:
			if int(contagem[conjunto]) >= int(minimo):
				_combinar(mods, bonus[minimo])
	return mods


## Texto curto dos conjuntos completos da mão ("Defesa 2: Recepção mais fácil").
static func bonus_ativos(dados: Dictionary, mao: Array) -> Array:
	var textos: Array = []
	var contagem := conjuntos(dados, mao)
	for conjunto in dados.get("conjuntos", []):
		var id := str(conjunto.get("id", ""))
		var n := int(contagem.get(id, 0))
		if n >= 3 and BONUS_DE_CONJUNTO.get(id, {}).has(3):
			textos.append("%s 3: %s" % [id.capitalize(), conjunto.get("com_3", "")])
		elif n >= 2 and BONUS_DE_CONJUNTO.get(id, {}).has(2):
			textos.append("%s 2: %s" % [id.capitalize(), conjunto.get("com_2", "")])
	return textos


static func _combinar(mods: Dictionary, efeito: Dictionary) -> void:
	for chave in efeito:
		var valor := float(efeito[chave])
		if SOMAS.has(chave):
			mods[chave] = float(mods.get(chave, 0.0)) + valor
		else:
			mods[chave] = float(mods.get(chave, 1.0)) * valor


static func _da_pra_copiar(id: String, mao: Array) -> bool:
	return id != "" and id != ID_DA_TROCA and EFEITOS.has(id) and not mao.has(id)


static func _sortear_raridade(dados: Dictionary, ids: Array, rng: RandomNumberGenerator) -> String:
	var total := 0
	var presentes := {}
	for id in ids:
		var raridade := str(por_id(dados, id).get("raridade", ""))
		if not presentes.has(raridade):
			presentes[raridade] = int(PESO_DA_RARIDADE.get(raridade, 10))
			total += presentes[raridade]
	var ponto := rng.randi_range(1, total)
	for raridade in presentes:
		ponto -= int(presentes[raridade])
		if ponto <= 0:
			return raridade
	return presentes.keys()[0]
