extends RefCounted
## Pulo e bloqueio: quem pula, que tipo de bloqueio sai (devolve, toca ou nada) e o que acontece quando a bola bate no bloqueio.
##
## Saiu do partida.gd (Fase C do plano de melhorias). "p" é a partida:
## tudo que é dela aparece como p.algo.

const Atributos := preload("res://scripts/regras/atributos.gd")
const AvisoDeToque := preload("res://scripts/partida/aviso_de_toque.gd")
const Bola := preload("res://scripts/partida/bola.gd")
const Energia := preload("res://scripts/regras/energia.gd")
const Estouro := preload("res://scripts/visual/estouro.gd")
const JeitosDeDefender := preload("res://scripts/regras/jeitos_de_defender.gd")
const Rodizio := preload("res://scripts/regras/rodizio.gd")
const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")

const Lance := preload("res://scripts/regras/lance.gd")

## A partida (partida.gd).
var p


func _init(partida) -> void:
	p = partida


## "altura" muda a altura do pulo (a cortada pula até a mão alcançar a bola).
func _pular(atleta: Node3D, altura: float = p.ALTURA_DO_PULO) -> void:
	if _esta_pulando(atleta):
		return
	atleta.set_meta("tempo_do_pulo", 0.0)
	atleta.set_meta("altura_do_pulo", altura)


func _esta_pulando(atleta: Node3D) -> bool:
	return float(atleta.get_meta("tempo_do_pulo", -1.0)) >= 0.0


func _atualizar_pulo(atleta: Node3D, delta: float) -> void:
	if not _esta_pulando(atleta):
		return
	var tempo: float = float(atleta.get_meta("tempo_do_pulo")) + delta
	if tempo >= p.DURACAO_DO_PULO:
		atleta.position.y = 0.0
		atleta.set_meta("tempo_do_pulo", -1.0)
		return
	var fracao = tempo / p.DURACAO_DO_PULO
	var altura: float = atleta.get_meta("altura_do_pulo", p.ALTURA_DO_PULO)
	atleta.position.y = 4.0 * altura * fracao * (1.0 - fracao)
	atleta.set_meta("tempo_do_pulo", tempo)


func _bloquear(time: int) -> void:
	var direcao = p._direcao_no_mundo(time)
	var deslocamento = direcao.x * p.DESLOCAMENTO_DO_BLOQUEIO
	# Quantos bloqueiam: direção pra frente = triplo, neutro = dupla, pra trás = só um.
	var indices: Array[int] = []
	var xs: Array = []
	for i in 6:
		if Rodizio.e_da_rede(p.rodizios[time].posicao_de(i)) and not _esta_pulando(p.atletas[time][i]):
			indices.append(i)
			xs.append(p.atletas[time][i].position.x)
	var pra_frente = direcao.y * p._lado(1 - time)
	var escolhidos = JeitosDeDefender.quem_bloqueia(xs, direcao.x, pra_frente)
	p._qualidade_do_bloqueio[time] = _qualidade_do_botao_do_bloqueio(time)
	p._rumo_do_bloqueio[time] = direcao.x
	for k in indices.size():
		var atleta: Node3D = p.atletas[time][indices[k]]
		if not escolhidos.has(k):
			# Fica fora do bloqueio e ajuda na defesa.
			atleta.set_meta("fora_do_bloqueio_ate", p._relogio + p.TEMPO_FORA_DO_BLOQUEIO)
			continue
		atleta.position.x += deslocamento
		_pular(atleta)
		if p.estado == p.Estado.RALLY and absf(atleta.position.z) < p.DISTANCIA_MINIMA_DA_REDE:
			p._encerrar_rally(1 - time, "toque na rede")
		p._animar(atleta, "bloqueio")


## Tempo do botão do bloqueio: o pico do pulo tem que cair quando a bola passa
## pela rede. Sem ataque vindo, o bloqueio sai ruim.
func _qualidade_do_botao_do_bloqueio(time: int) -> TempoDoToque.Qualidade:
	var outro = 1 - time
	var ate_a_batida = -1.0
	if not p.cortadas[outro].is_empty():
		ate_a_batida = maxf(p.TEMPO_ATE_A_BATIDA - float(p.cortadas[outro]["tempo"]), 0.0)
	elif p.bola.em_voo and p.toques.time_com_a_bola == outro and p.toques.toques >= 2 and p._lado_da_queda() == outro:
		ate_a_batida = maxf(TempoDoToque.tempo_ate_altura(p.bola.position, p.bola.velocidade_atual(), TempoDoToque.ALTURA_IDEAL[Lance.CORTADA], p.bola.gravidade), 0.0)
	if ate_a_batida < 0.0:
		return TempoDoToque.Qualidade.RUIM
	return JeitosDeDefender.qualidade_do_bloqueio(JeitosDeDefender.erro_do_bloqueio(ate_a_batida, p.DURACAO_DO_PULO))


## Chamado pela bola quando ela cruza a rede por cima da fita. Diz o que o
## bloqueio do lado de destino faz com a bola:
## - DEVOLVE: um atleta da rede no alto do pulo, bem na frente da bola e com
##   as mãos acima dela. A bola volta pra quem atacou.
## - TOQUE: alguém encosta, mas baixo (cedo ou tarde no pulo) ou só com a
##   ponta da mão. A bola segue pro lado do bloqueio, mais devagar.
## - NENHUM: ninguém encosta.
func _tipo_do_bloqueio(ponto_na_rede: Vector3, lado_destino: float) -> int:
	var time = 0 if lado_destino > 0.0 else 1
	var largura = p.LARGURA_DO_BLOQUEIO * Atributos.largura_do_bloqueio(p.times_em_jogo[time]) * p._bloqueio_do_ataque
	var resultado = p.Bloqueio.NENHUM
	for i in 6:
		if not Rodizio.e_da_rede(p.rodizios[time].posicao_de(i)):
			continue
		var atleta: Node3D = p.atletas[time][i]
		if not _esta_pulando(atleta):
			continue
		if absf(atleta.position.z) > p.DISTANCIA_MAXIMA_DO_BLOQUEIO:
			continue
		var distancia = absf(atleta.position.x - ponto_na_rede.x)
		if distancia > largura + p.FOLGA_DO_TOQUE_NO_BLOQUEIO:
			continue
		if ponto_na_rede.y > p.ALTURA_DAS_MAOS + atleta.position.y + Bola.RAIO:
			continue
		var no_alto: bool = atleta.position.y >= p.ALTURA_DO_PULO * p.ALTURA_MINIMA_DO_BLOQUEIO
		if distancia <= largura and no_alto \
				and JeitosDeDefender.pode_devolver(p._qualidade_do_bloqueio[time]):
			# Bloqueio perfeito devolve mais forte e pro lado apertado.
			var qualidade_do_bloqueio: TempoDoToque.Qualidade = p._qualidade_do_bloqueio[time]
			p.bola.forca_do_bloqueio = JeitosDeDefender.forca_do_rebote(qualidade_do_bloqueio)
			p.bola.empurrao_do_bloqueio = float(p._rumo_do_bloqueio[time]) * JeitosDeDefender.valor("empurrao_lateral_perfeito", JeitosDeDefender.EMPURRAO_LATERAL_PERFEITO) \
				if qualidade_do_bloqueio == TempoDoToque.Qualidade.PERFEITO else 0.0
			return p.Bloqueio.DEVOLVE
		resultado = p.Bloqueio.TOQUE
	return resultado


## Se algum bloqueador encosta na bola que cruza a rede em "ponto_na_rede".
func _tem_bloqueio(ponto_na_rede: Vector3, lado_destino: float) -> bool:
	return _tipo_do_bloqueio(ponto_na_rede, lado_destino) != p.Bloqueio.NENHUM


func _ao_bola_ser_bloqueada() -> void:
	if p.estado != p.Estado.RALLY:
		return
	# Quem bloqueou é o time do lado pra onde a bola ia.
	var time_que_bloqueou = 1 - p.ultimo_toque
	if p.saque_em_jogo:
		# Bloquear o saque é falta.
		p._encerrar_rally(p.ultimo_toque, "bloqueio no saque")
		return
	# O bloqueio não conta como toque: quem bloqueou ainda tem 3 toques.
	p.toques.registrar_bloqueio(time_que_bloqueou)
	p.ultimo_toque = time_que_bloqueou
	p._bloqueio_do_ataque = 1.0
	p._forca_da_cortada = -1
	p._ponto_de_bloqueio = time_que_bloqueou
	p._ganhar_energia(time_que_bloqueou, Energia.ajuste("ganho_do_bloqueio_que_devolve", Energia.GANHO_DO_BLOQUEIO_QUE_DEVOLVE))
	p.impacto.bloqueio()
	p.sons.tocar("bloqueio")
	Estouro.mostrar(p, p.bola.position, p._cor_do_time(time_que_bloqueou), 0.8)
	AvisoDeToque.mostrar(p, p.bola.position + Vector3(0.0, 0.8, 0.0), "Bloqueio!", p._cor_do_time(time_que_bloqueou))
	p._ao_lancar_bola()


## A bola raspou no bloqueio e seguiu pro lado de quem bloqueou. Não conta
## toque, e quem bloqueou pode tocar de novo; mas se a bola sair, a falta é
## de quem encostou por último (o bloqueio).
func _ao_bola_tocar_bloqueio() -> void:
	if p.estado != p.Estado.RALLY:
		return
	var time_que_bloqueou = 1 - p.ultimo_toque
	if p.saque_em_jogo:
		p._encerrar_rally(p.ultimo_toque, "bloqueio no saque")
		return
	p.toques.registrar_bloqueio(time_que_bloqueou)
	p.ultimo_toque = time_que_bloqueou
	p._bloqueio_do_ataque = 1.0
	p._forca_da_cortada = -1
	p._ponto_de_bloqueio = -1
	p._ganhar_energia(time_que_bloqueou, Energia.ajuste("ganho_do_toque_no_bloqueio", Energia.GANHO_DO_TOQUE_NO_BLOQUEIO))
	p.impacto.ponto()
	p.sons.tocar("bloqueio", 0.45)
	AvisoDeToque.mostrar(p, p.bola.position + Vector3(0.0, 0.8, 0.0), "Toque no bloqueio", Color(0.95, 0.95, 0.95))
	p._ao_lancar_bola()
