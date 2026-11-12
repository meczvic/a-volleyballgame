extends RefCounted
## Os jeitos de defender da Etapa 3B: quantos bloqueiam, a qualidade do
## bloqueio pelo tempo do botão, a cortada forte na recepção e o risco do
## mergulho. Só regras e números (sem tela), pra testar sozinho.

const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")
const Qualidade := TempoDoToque.Qualidade

# --- Quantos bloqueiam ---

## Direção pra frente (rumo à rede) acima disso = bloqueio triplo; pra trás
## (abaixo do negativo) = só um bloqueador; no meio = dupla.
const LIMITE_DA_DIRECAO := 0.5
## Na dupla, o par é o mais perto de um ponto a essa distância (m) do centro,
## pro lado apertado.
const DESLOCAMENTO_DA_DUPLA := 2.0


## Quais dos atletas da rede bloqueiam. "xs" são os x dos atletas da rede (em
## qualquer ordem), "direcao_x" o lado apertado (-1 a 1) e "pra_frente" a
## direção rumo à rede (-1 a 1). Devolve os índices de "xs" que pulam.
static func quem_bloqueia(xs: Array, direcao_x: float, pra_frente: float) -> Array[int]:
	var todos: Array[int] = []
	for i in xs.size():
		todos.append(i)
	if pra_frente > LIMITE_DA_DIRECAO or xs.size() <= 1:
		return todos
	var quantos := 1 if pra_frente < -LIMITE_DA_DIRECAO else mini(2, xs.size())
	var referencia := direcao_x * DESLOCAMENTO_DA_DUPLA if quantos == 2 else 0.0
	todos.sort_custom(func(a, b): return absf(float(xs[a]) - referencia) < absf(float(xs[b]) - referencia))
	return todos.slice(0, quantos)


# --- Bloqueio pelo tempo ---

## O bloqueio é mais folgado que o toque comum (as janelas de TempoDoToque x isso).
const ESCALA_DA_JANELA_DO_BLOQUEIO := 1.5
## Segundos entre a batida da cortada e a bola chegar na rede.
const TRAVESSIA_DA_CORTADA := 0.1
## Quanto o bloqueio perfeito devolve mais forte e o quanto empurra pro lado
## apertado (m/s).
const FORCA_DO_BLOQUEIO_PERFEITO := 1.4
const EMPURRAO_LATERAL_PERFEITO := 3.0


## Erro (s) do botão do bloqueio: positivo = cedo. "ate_a_batida" é quanto
## falta pro atacante bater na bola; o pico do pulo (meio da duração) deve
## coincidir com a bola passando pela rede.
static func erro_do_bloqueio(ate_a_batida: float, duracao_do_pulo: float) -> float:
	return ate_a_batida + TRAVESSIA_DA_CORTADA - duracao_do_pulo / 2.0


static func qualidade_do_bloqueio(erro: float, escala_do_time: float = 1.0) -> Qualidade:
	return TempoDoToque.qualidade(erro, ESCALA_DA_JANELA_DO_BLOQUEIO * escala_do_time)


## Força do rebote do bloqueio que devolve a bola (1.0 = normal).
static func forca_do_rebote(qualidade: Qualidade) -> float:
	return FORCA_DO_BLOQUEIO_PERFEITO if qualidade == Qualidade.PERFEITO else 1.0


## Só bloqueio perfeito ou bom devolve a bola; ruim só raspa (toque).
static func pode_devolver(qualidade: Qualidade) -> bool:
	return qualidade != Qualidade.RUIM


# --- Recepção ---

## Cortada perfeita: o passe só sai bom se o botão for perfeito; se for só
## bom, a bola foge e o passe sai ruim.
static func qualidade_da_recepcao(qualidade: Qualidade, cortada_recebida: int) -> Qualidade:
	if cortada_recebida == int(Qualidade.PERFEITO) and qualidade == Qualidade.BOM:
		return Qualidade.RUIM
	return qualidade


# --- Mergulho ---

## Mergulho fora do tempo (ou no vazio) fica mais tempo no chão.
const RISCO_DO_MERGULHO := 1.6
## Mergulho no tempo (perfeito) alcança mais longe (m).
const ALCANCE_A_MAIS_NO_TEMPO := 0.5


static func tempo_no_chao_do_mergulho(base: float, qualidade: Qualidade, alcancou: bool) -> float:
	if alcancou and qualidade != Qualidade.RUIM:
		return base
	return base * RISCO_DO_MERGULHO


static func alcance_a_mais(qualidade: Qualidade) -> float:
	return ALCANCE_A_MAIS_NO_TEMPO if qualidade == Qualidade.PERFEITO else 0.0


## Qualidade do passe no mergulho. De longe é ruim, a não ser com o tempo
## perfeito (aí é bom). De perto, no máximo bom.
static func qualidade_do_mergulho(qualidade: Qualidade, longe: bool) -> Qualidade:
	if longe:
		return Qualidade.BOM if qualidade == Qualidade.PERFEITO else Qualidade.RUIM
	return TempoDoToque.pior(qualidade, Qualidade.BOM)
