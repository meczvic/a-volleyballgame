extends RefCounted
## Os jeitos de atacar da Etapa 3A: ataque rápido do meio, pipe, diagonal e
## paralela. Só regras e números (sem tela), pra testar sozinho.
##
## "efeito" devolve o que o jeito muda na cortada:
## - nome: o que aparece na tela ("" = cortada comum);
## - bloqueio: multiplicador da largura do bloqueio (menor = bloqueio pega menos);
## - subida_a_menos: metros a menos na subida da bola (cortada mais forte);
## - erro_a_mais: metros a mais no erro da mira (negativo = mais segura).

const Ajustes := preload("res://scripts/comum/ajustes.gd")

## Bloqueio contra cada jeito (1.0 = normal).
const BLOQUEIO_DO_RAPIDO_DO_MEIO := 0.6
const BLOQUEIO_DO_RAPIDO := 0.8
const BLOQUEIO_DO_PIPE := 0.7
const BLOQUEIO_DA_PARALELA := 0.85
## O pipe sai mais forte que a cortada de fundo comum.
const SUBIDA_A_MENOS_NO_PIPE := 0.08
## A paralela anda rente à lateral: arrisca sair. A diagonal tem mais quadra.
const ERRO_A_MAIS_NA_PARALELA := 0.4
const ERRO_A_MENOS_NA_DIAGONAL := -0.2
## Levantamento rápido forçado com passe só "bom" erra mais o atacante.
const ERRO_DO_RAPIDO_FORCADO := 1.8

## Quem sai do centro da rede (menos que isso de x) não ataca em diagonal
## nem em paralela: é o meio.
const ZONA_DO_MEIO := 1.5
## Diagonal: a bola cruza pelo menos isso de lado (m) e termina no outro lado.
const CRUZAMENTO_DA_DIAGONAL := 3.0
const LADO_MINIMO_DA_DIAGONAL := 1.0
## Paralela: termina perto da lateral do mesmo lado de onde saiu.
const LADO_MINIMO_DA_PARALELA := 2.5
const DESVIO_DA_PARALELA := 1.5


## "diagonal", "paralela" ou "" (reta), pelo x de quem ataca e o x do alvo.
static func jeito_da_mira(saida_x: float, alvo_x: float) -> String:
	if absf(saida_x) < valor("zona_do_meio", ZONA_DO_MEIO):
		return ""
	var cruza := absf(alvo_x - saida_x)
	if alvo_x * saida_x < 0.0 and absf(alvo_x) >= valor("lado_minimo_da_diagonal", LADO_MINIMO_DA_DIAGONAL) and cruza >= valor("cruzamento_da_diagonal", CRUZAMENTO_DA_DIAGONAL):
		return "diagonal"
	if alvo_x * saida_x > 0.0 and absf(alvo_x) >= valor("lado_minimo_da_paralela", LADO_MINIMO_DA_PARALELA) and cruza <= valor("desvio_da_paralela", DESVIO_DA_PARALELA):
		return "paralela"
	return ""


## Efeito da cortada. "levantamento" é o nome do ataque (Ponta, Meio, Oposto,
## Fundo), "rapido" diz se o levantamento foi rápido e "jeito" vem de jeito_da_mira.
static func efeito(levantamento: String, rapido: bool, jeito: String) -> Dictionary:
	var resultado := { "nome": "", "bloqueio": 1.0, "subida_a_menos": 0.0, "erro_a_mais": 0.0 }
	if levantamento == "Fundo":
		resultado["nome"] = "Pipe!"
		resultado["bloqueio"] = valor("bloqueio_do_pipe", BLOQUEIO_DO_PIPE)
		resultado["subida_a_menos"] = valor("subida_a_menos_no_pipe", SUBIDA_A_MENOS_NO_PIPE)
	elif rapido:
		resultado["bloqueio"] = valor("bloqueio_do_rapido_do_meio", BLOQUEIO_DO_RAPIDO_DO_MEIO) if levantamento == "Meio" else valor("bloqueio_do_rapido", BLOQUEIO_DO_RAPIDO)
		if levantamento == "Meio":
			resultado["nome"] = "Ataque rápido!"
	if jeito == "paralela":
		resultado["bloqueio"] = float(resultado["bloqueio"]) * valor("bloqueio_da_paralela", BLOQUEIO_DA_PARALELA)
		resultado["erro_a_mais"] = valor("erro_a_mais_na_paralela", ERRO_A_MAIS_NA_PARALELA)
		if resultado["nome"] == "":
			resultado["nome"] = "Paralela!"
	elif jeito == "diagonal":
		resultado["erro_a_mais"] = valor("erro_a_menos_na_diagonal", ERRO_A_MENOS_NA_DIAGONAL)
		if resultado["nome"] == "":
			resultado["nome"] = "Diagonal!"
	return resultado


## Número de equilíbrio: vem de dados/ajustes.json (grupo "ataques") ou, se faltar lá,
## do valor padrão que está no código.
static func valor(chave: String, padrao: float) -> float:
	return Ajustes.pegar("ataques", chave, padrao)
