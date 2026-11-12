extends Node3D
## Cena de teste: saque, 3 toques, bloqueio, rodízio, IA dos atletas e tela dividida.
##
## Como jogar:
## - Quem saca (o atleta na posição 1 do rodízio) aperta Ataque.
## - Um anel amarelo mostra onde a bola vai cair, e o jogo troca sozinho
##   pro atleta mais perto dele. Os outros 5 se posicionam sozinhos.
## - 1º toque: Passe manda a bola pro levantador.
## - 2º toque: Passe levanta. Segure uma direção pra escolher o atacante
##   (as setas aparecem no chão). Sem direção, vai pro meio.
## - 3º toque: Ataque com a bola alta corta (a direção mira).
##   Passe só devolve de graça.
## - Ataque em qualquer toque, com a bola alta, já manda pro outro lado.
## - Bloqueio: os 3 da rede pulam. A direção desloca o bloqueio.
##   Acertar o tempo do pulo devolve a cortada.
## - Esc ou Start pausa (continuar, recomeçar, trocar times, menu).
##
## Regras oficiais (FIVB) que o jogo cobra (o placar segue o formato do jogo:
## sets até 7, 2 de diferença, limite 10):
## - Escalação 5-1 pela função de cada atleta (scripts/regras/escalacao.gd)
##   e formação na ordem do rodízio no saque (scripts/regras/formacao.gd).
##   Fora de posição na hora do saque é ponto do outro time.
## - Gira no sentido horário quando ganha o saque de volta. Cada set começa
##   com a escalação do começo. 1º saque: sorteio no 1º set, o outro time no
##   2º, sorteio no desempate.
## - 8 segundos pra sacar. Quem sacou não toca no próprio saque.
## - 3 toques por time; o bloqueio não conta e quem bloqueou pode tocar de novo.
##   O mesmo atleta não toca duas vezes seguidas (dois toques).
## - Só os 3 da rede bloqueiam. Atleta do fundo só ataca com a bola acima da
##   rede se estiver atrás da linha de 3 m. Não pode bloquear nem atacar o saque
##   (com a bola acima da rede, perto dela).
## - Pular colado na rede é toque na rede. A bola tem que passar entre as antenas.
## - Sem líbero: 6 atletas por time.
##
## Os times e o estádio vêm da seleção de times (autoload Configuracao).
## Rodando esta cena direto (F6), vale o padrão: Karasuno x Nekoma no Ginásio Japonês.
## Atleta sem personagem do VRoid aparece como cápsula. Com personagem, ele
## corre, para e faz cada lance (scripts/visual/animador.gd).

const Placar := preload("res://scripts/regras/placar.gd")
const Toques := preload("res://scripts/regras/toques.gd")
const Rodizio := preload("res://scripts/regras/rodizio.gd")
const Escalacao := preload("res://scripts/regras/escalacao.gd")
const Formacao := preload("res://scripts/regras/formacao.gd")
const EscolhaAtaque := preload("res://scripts/regras/escolha_ataque.gd")
const JeitosDeAtacar := preload("res://scripts/regras/jeitos_de_atacar.gd")
const JeitosDeDefender := preload("res://scripts/regras/jeitos_de_defender.gd")
const EntradaLocal := preload("res://scripts/entrada/entrada_local.gd")
const EntradaDoComputador := preload("res://scripts/entrada/entrada_do_computador.gd")
const Bola := preload("res://scripts/partida/bola.gd")
const MarcadorQueda := preload("res://scripts/partida/marcador_queda.gd")
const VisualAnime := preload("res://scripts/visual/visual_anime.gd")
const Dados := preload("res://scripts/comum/dados.gd")
const MenuDePausa := preload("res://scripts/menus/menu_de_pausa.gd")
const Estilo := preload("res://scripts/menus/estilo.gd")
const Animador := preload("res://scripts/visual/animador.gd")
const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")
const Trajetoria := preload("res://scripts/regras/trajetoria.gd")
const AnelDeTempo := preload("res://scripts/partida/anel_de_tempo.gd")
const AvisoDeToque := preload("res://scripts/partida/aviso_de_toque.gd")
const Impacto := preload("res://scripts/visual/impacto.gd")
const Rastro := preload("res://scripts/visual/rastro.gd")
const Mira := preload("res://scripts/regras/mira.gd")
const Atributos := preload("res://scripts/regras/atributos.gd")
const MiraVisual := preload("res://scripts/partida/mira_visual.gd")
const PlacarVisual := preload("res://scripts/partida/placar_visual.gd")
const FaixaDePonto := preload("res://scripts/partida/faixa_de_ponto.gd")
const Cenario := preload("res://scripts/cenario/cenario.gd")
const OndaNoChao := preload("res://scripts/visual/onda_no_chao.gd")
const AnelDoControlado := preload("res://scripts/partida/anel_do_controlado.gd")
const CameraDaPartida := preload("res://scripts/partida/camera_da_partida.gd")
const Cortina := preload("res://scripts/menus/cortina.gd")
const BarraDeForca := preload("res://scripts/partida/barra_de_forca.gd")
const Cartas := preload("res://scripts/regras/cartas.gd")
const EscolhaDeCartas := preload("res://scripts/partida/escolha_de_cartas.gd")
const Sons := preload("res://scripts/audio/sons.gd")
const Estouro := preload("res://scripts/visual/estouro.gd")
const SetaDoControlado := preload("res://scripts/partida/seta_do_controlado.gd")
const Qualidade := TempoDoToque.Qualidade

enum Estado { SAQUE, RALLY, PONTO, FIM }

## Medidas oficiais da quadra, em metros.
const COMPRIMENTO := 18.0
const LARGURA := 9.0
const ALTURA_REDE := 2.43
## Chão em volta da quadra, até as placas.
const COMPRIMENTO_ZONA_LIVRE := COMPRIMENTO + 10.0
const LARGURA_ZONA_LIVRE := LARGURA + 8.0

## Velocidade do atleta controlado e dos outros (m/s).
const VELOCIDADE := 6.0
const VELOCIDADE_IA := 5.0
## Distância (no chão) em que o atleta alcança a bola.
const ALCANCE := 1.8
## Altura máxima da bola pra passar ou levantar.
const ALTURA_MAXIMA_PASSE := 3.0
## Faixa de altura da bola pra cortar (o atleta pula).
const ALTURA_MINIMA_CORTADA := 1.6
const ALTURA_MAXIMA_CORTADA := 3.5
## Tempo mostrando "Ponto!" antes do próximo saque. Nesse tempo os atletas
## andam até a formação do saque (em vez de pular de lugar).
const PAUSA_DEPOIS_DO_PONTO := 1.8
## Depois do ponto, todo mundo anda mais rápido pra formação (multiplicador).
const PRESSA_DEPOIS_DO_PONTO := 1.6
## Segundos que os atletas ficam parados comemorando (ou reagindo) depois do
## ponto, antes de andar pro lugar do próximo saque.
const COMEMORACAO_ANTES_DE_VOLTAR := 0.8
## Botão apertado um pouco cedo (bola ainda fora do alcance) vale por esse
## tempo (s): o toque sai assim que der. Depois disso o anel do atleta pisca.
const TEMPO_DO_PEDIDO := 0.15
## Tempo pra sacar depois que o saque é liberado (regra: 8 s).
const TEMPO_PARA_SACAR := 8.0
## Linha de ataque, a 3 m da rede. Atleta do fundo só ataca com a bola
## acima da rede se pular de trás dela.
const LINHA_DE_ATAQUE := 3.0
## Pular (bloqueio ou cortada) mais perto da rede que isso é encostar nela.
const DISTANCIA_MINIMA_DA_REDE := 0.5
## O levantador só deixa outro passar se estiver bem mais perto da bola (m).
const VANTAGEM_PRO_PASSE_DO_LEVANTADOR := 2.5

## Pulo: duração (s) e altura máxima (m).
const DURACAO_DO_PULO := 0.6
const ALTURA_DO_PULO := 0.95
## Na cortada, o atleta sai do chão quando aperta Ataque e bate na bola no
## alto do pulo, com a mão. Esse é o tempo do botão até a batida (s).
const TEMPO_ATE_A_BATIDA := DURACAO_DO_PULO / 2.0
## Se a mão chega a essa distância da bola (m), a bola vai pra mão: nos
## últimos IMA_DA_MAO segundos antes da batida ela é puxada até a mão.
const ALCANCE_DA_MAO := 1.5
const IMA_DA_MAO := 0.15
## Na cortada o atleta pula o que precisa pra mão chegar na bola, dentro disso (m).
const PULO_MINIMO_DA_CORTADA := 0.5
const PULO_MAXIMO_DA_CORTADA := 1.2
## Altura das mãos de um atleta em pé com os braços pra cima.
const ALTURA_DAS_MAOS := 2.35
## Até quantos metros pro lado da mão o bloqueio alcança a bola.
const LARGURA_DO_BLOQUEIO := 0.5
## Mais pro lado que isso (até esta folga a mais), o bloqueio só raspa na
## bola: ela segue pro lado de quem bloqueou, mais devagar ("toque no bloqueio").
const FOLGA_DO_TOQUE_NO_BLOQUEIO := 0.3
## O bloqueio só devolve a bola com o atleta perto do alto do pulo (fração da
## altura do pulo). Mais baixo que isso é toque no bloqueio.
const ALTURA_MINIMA_DO_BLOQUEIO := 0.55
## Resultado de _tipo_do_bloqueio.
enum Bloqueio { NENHUM, DEVOLVE, TOQUE }
## Mergulho: alcança bola mais longe e mais baixa, mas a bola sai pior e o
## atleta fica no chão um instante.
const ALCANCE_DO_MERGULHO := 3.2
const ALTURA_MAXIMA_DO_MERGULHO := 1.4
const TEMPO_NO_CHAO := 0.8
## Quanto o atleta se joga quando o mergulho não alcança a bola (m).
const MERGULHO_NO_VAZIO := 1.5
## Largada: em vez de bater, o atacante empurra a bola devagar por cima do
## bloqueio, pra cair curta (entre essas distâncias da rede, em m).
const LARGADA_FUNDO_MIN := 1.0
const LARGADA_FUNDO_MAX := 3.0
## Quanto a largada sobe acima do ponto de contato (m): alto o bastante pra
## passar por cima das mãos do bloqueio.
const SUBIDA_DA_LARGADA := 1.3
## Erro da mira da largada (m), por qualidade (o tempo do botão da cortada).
const ERRO_DA_LARGADA := [0.2, 0.5, 1.2]
## Leitura do bloqueio: os bloqueadores da ponta só ajudam se o levantamento
## vai pro lado deles (até essa distância, em m). O central vai sempre.
const AJUDA_DO_BLOQUEIO := 4.0
## Tempo de reação do bloqueio (s): só depois disso de bola no ar ele "lê" o
## levantamento e corre. É o que faz o levantamento rápido chegar antes.
const REACAO_DO_BLOQUEIO := 0.4
## Só bloqueia quem está até essa distância da rede.
const DISTANCIA_MAXIMA_DO_BLOQUEIO := 1.2
## Quanto a direção desloca o bloqueio na hora do pulo (m).
const DESLOCAMENTO_DO_BLOQUEIO := 0.7
## Quem fica fora do bloqueio (duplo ou simples) ajuda na defesa por esse tempo (s).
const TEMPO_FORA_DO_BLOQUEIO := 1.2
## Cobertura: quando o nosso atacante vai cortar, os outros chegam até esta
## distância (m) dele pra pegar a bola que voltar do bloqueio.
const COBERTURA_DA_REDE := 2.0
const COBERTURA_DO_FUNDO := 3.5
## Defesa: o quanto os do fundo andam pro lado do atacante do outro time
## (fração do x dele) e o quanto recuam ou avançam (m) pela distância até ele.
const DEFESA_PRO_LADO_DO_ATAQUE := 0.3
const DEFESA_RECUO := 0.8
## Ninguém do time fica mais perto que isso (m) de um colega (sem amontoar).
const ESPACO_ENTRE_ATLETAS := 1.2

## Coordenadas "do time": x = lado (negativo = esquerda de quem olha pra rede),
## y = distância da rede. A formação de cada posição do rodízio está em
## scripts/regras/formacao.gd.
## Onde quem saca fica (atrás da linha de fundo).
const POSICAO_DO_SACADOR := Vector2(2.5, 10.0)
## Onde o passe deve chegar: perto da rede, um pouco à direita.
const PONTO_DO_LEVANTADOR := Vector2(1.0, 1.0)
## Giro do personagem .vrm pro time do Jogador 1 olhar pra rede (-z).
## VRM 1.0 olha pra +z, por isso meia volta. Conferir com o primeiro personagem (Hinata).
const GIRO_DO_PERSONAGEM := PI

## Pra onde o levantador pode mandar a bola.
const ATAQUES := [
	{ "nome": "Ponta", "posicao": Vector2(-3.5, 1.2) },
	{ "nome": "Meio", "posicao": Vector2(0.0, 1.2) },
	{ "nome": "Oposto", "posicao": Vector2(3.5, 1.2) },
	{ "nome": "Fundo", "posicao": Vector2(0.0, 4.0) },
]
## Sem direção apertada, o levantamento vai pro meio.
const ATAQUE_PADRAO := 1
## O anel de tempo só aparece se o atleta estiver a menos disso (m) de onde
## a bola vai estar na hora certa.
const DISTANCIA_DO_ANEL_DE_TEMPO := 3.5
## Camada de desenho do anel de tempo de cada time: na tela dividida, cada
## jogador só vê o próprio anel.
const CAMADA_DO_ANEL_DE_TEMPO := [11, 12]
## Cor das faíscas e do rastro da cortada perfeita.
const COR_DA_CORTADA_PERFEITA := Color("#FFD23F")
## Texto do aviso "Perfeito!" (maior que o "Bom" e o "Ruim", pra comemorar).
const TAMANHO_DO_AVISO_PERFEITO := 44

## Câmera atrás do próprio time, como numa transmissão de TV (referência:
## Spike Volleyball). Desde a Fase 04 ela fica mais baixa e mais perto, com a
## lente um pouco mais aberta, pra mostrar o ginásio em volta e deixar os
## atletas maiores (antes: altura 14,5, distância 29,5, foco 1,5, abertura 27).
## Ajuste aqui ou no Inspetor. Altura e distância da rede, em metros.
@export var altura_camera := 10.5
@export var distancia_camera := 24.0
## Pra onde a câmera aponta: metros antes da rede, do lado do próprio time.
## Mais alto mostra mais o fundo da sua quadra (onde fica quem saca).
@export var foco_da_camera := 0.0
## Abertura vertical da câmera, em graus. Menor = mais "zoom" e menos distorção.
@export var abertura_da_camera := 37.0
## Tela dividida: cada jogador vê de trás do próprio time.
## Desligado: uma câmera só, do lado do Jogador 1.
@export var tela_dividida := true
## Visual anime (sombra "chapada" e contorno escuro) nos atletas e na bola.
@export var visual_anime := true

var placar = Placar.new()
## Todo sorteio que muda o jogo (erro do saque e do toque, quem saca primeiro,
## cartas) sai daqui, nunca do randf() solto. Com Configuracao.semente fixa, a
## partida se repete igual. Sorteios só visuais (tremor, faíscas) ficam de fora.
var sorteio := RandomNumberGenerator.new()
var toques = Toques.new()
var rodizios: Array = [Rodizio.new(), Rodizio.new()]
var estado := Estado.SAQUE
var ultimo_toque := -1
## Quantos pontos já tiveram comemoração (só pra variar a animação).
var _pontos_animados := 0
## _relogio na hora do último ponto (os atletas comemoram antes de voltar).
var _relogio_do_ponto := -100.0
## Função de cada atleta: funcoes[time][índice] = "levantador", "ponteiro",
## "central" ou "oposto" (veja escalacao.gd).
var funcoes: Array = [{}, {}]
## Índice do levantador de cada time.
var levantadores: Array[int] = [0, 0]
## O saque está no ar e o time que recebe ainda não tocou na bola.
var saque_em_jogo := false
## Segundos desde que o saque foi liberado (limite: TEMPO_PARA_SACAR).
var tempo_no_saque := 0.0
var _segundos_mostrados := -1
## Relógio da partida (s), pra saber até quando o atleta fica no chão.
var _relogio := 0.0

var times_em_jogo: Array = []
## Estádio escolhido (cores da quadra, do fundo e da luz). Veja dados/estadios.json.
var estadio: Dictionary = {}
## atletas[0] = time do Jogador 1, atletas[1] = time do Jogador 2.
var atletas: Array = [[], []]
var controlados: Array[Node3D] = [null, null]
## Anel no chão de quem está sendo controlado, por time.
var aneis_do_controlado: Array = [null, null]
## Seta em cima da cabeça de quem está sendo controlado, por time (pula na troca).
var setas_do_controlado: Array = [null, null]
## Efeitos sonoros (scripts/audio/sons.gd). Só som: não muda o jogo.
var sons
## Botão apertado cedo demais, esperando a bola chegar ao alcance, por time:
## { "tipo": "passe" ou "ataque", "ate": relógio }. Vazio = nenhum.
var pedidos: Array = [{}, {}]
var entradas: Array = []
## Posições de ataque no mundo, por time (calculadas de ATAQUES).
var alvos_de_ataque: Array = [[], []]
## Marcas no chão com as setas de cada ataque, por time.
var marcas_de_ataque: Array[Node3D] = [null, null]

var bola
var marcador
var menu
var placar_visual: PanelContainer
## Quadra, rede e ginásio em volta (scripts/cenario/cenario.gd).
var cenario: Node3D
## Faixa grande do ponto ("PONTO!", "ACE!", "BLOQUEIO!", "SET!").
var faixa: Control
## Time que bloqueou por último no rally (pra saber se o ponto foi de
## bloqueio). -1 depois de qualquer toque.
var _ponto_de_bloqueio := -1
## Botões que cada time está segurando agora ({ tipo: true }): o levantamento
## rápido pede o botão de flutuante segurado enquanto levanta.
var _segurando_botao: Array = [{}, {}]
## Último levantamento de cada time: { "nome": ataque, "rapido": bool }. A cortada lê.
var _ultimo_levantamento: Array = [{}, {}]
## Quanto o último ataque encolhe a largura do bloqueio (1.0 = normal).
var _bloqueio_do_ataque := 1.0
## Qualidade (tempo do botão) do último bloqueio de cada time e o lado
## apertado nele (x no mundo, -1 a 1).
var _qualidade_do_bloqueio: Array = [Qualidade.BOM, Qualidade.BOM]
var _rumo_do_bloqueio: Array = [0.0, 0.0]
## Qualidade (int de Qualidade) da última cortada, pra recepção. -1 = nenhuma.
var _forca_da_cortada := -1
var rotulo_mensagem: Label
## Caixa escura atrás da mensagem; some quando não tem mensagem.
var caixa_da_mensagem: PanelContainer
## Mensagem de cada time, na metade da tela dele (saque, levantamento, largada).
var rotulos_do_time: Array[Label] = []
var caixas_do_time: Array[PanelContainer] = []
## Barra de força do saque de cada time.
var barras_de_forca: Array = [null, null]
## Lembrete "Esc ou Start: pausa"; some no fim de jogo.
var caixa_da_pausa: PanelContainer
## Espera depois de cada ponto. É um nó (e não um "await") pra parar junto
## quando o jogo pausa e sumir junto quando a cena fecha.
var temporizador_do_ponto: Timer
## Câmeras (uma por jogador na tela dividida), pro tremor do impacto.
var cameras: Array[Camera3D] = []
## Cortina preta das trocas de cena.
var cortina: ColorRect
## Anel que mostra a hora de apertar, um por time.
var aneis_de_tempo: Array = [null, null]
## Qualidade do último passe de cada time (decide o levantamento).
var qualidade_do_passe: Array = [Qualidade.BOM, Qualidade.BOM]
var impacto
var rastro
## Mira de cada time (saque carregado e cortada).
var miras: Array = [null, null]
## Segundos segurando o botão do saque (-1 = não está carregando).
var carga_do_saque := -1.0
var saque_flutuante := false
## Alvo do saque na quadra do outro time (x = lado, y = distância da rede).
var alvo_do_saque := Mira.ALVO_INICIAL
## Cortada de cada time que já saiu do chão e ainda vai bater na bola
## (vazio = nenhuma). Ver _comecar_cortada.
var cortadas: Array = [{}, {}]

## Modo Caos: cartas de cada time (ids), a última que cada um pegou, os dados
## das cartas, quantos pontos já saíram e a tela de escolha (null = fechada).
var modo_caos := false
var cartas_dos_times: Array = [[], []]
## Trocas de cartas (TROCAR) que cada time ainda tem na partida.
var trocas_restantes: Array = [0, 0]
var ultima_carta: Array = ["", ""]
var dados_das_cartas: Dictionary = {}
var pontos_jogados := 0
var escolha_de_cartas = null
## Texto das cartas de cada time, no canto da quadra (só no Modo Caos).
var rotulos_de_cartas: Array[Label] = []


func _ready() -> void:
	_carregar_escolhas()
	sons = Sons.new()
	sons.name = "Sons"
	add_child(sons)

	_criar_cenario()
	for time in 2:
		_criar_atletas(time)
		_criar_marcas_de_ataque(time)
	_criar_camera()
	_criar_interface()

	bola = Bola.new()
	bola.name = "Bola"
	bola.usar_visual_anime = visual_anime
	add_child(bola)
	bola.verificar_bloqueio = _tipo_do_bloqueio
	bola.tocou_chao.connect(_ao_bola_tocar_chao)
	bola.bloqueada.connect(_ao_bola_ser_bloqueada)
	bola.tocou_bloqueio.connect(_ao_bola_tocar_bloqueio)
	for camera in cameras:
		camera.alvo = bola
	bola.cruzou_a_rede.connect(_ao_bola_cruzar_a_rede)

	# Toque no tempo certo: anel de tempo de cada time, impacto e rastro.
	for time in 2:
		var anel_de_tempo = AnelDeTempo.new()
		anel_de_tempo.name = "AnelDeTempo%d" % time
		add_child(anel_de_tempo)
		anel_de_tempo.usar_camada(CAMADA_DO_ANEL_DE_TEMPO[time])
		aneis_de_tempo[time] = anel_de_tempo
		var mira = MiraVisual.new()
		mira.name = "Mira%d" % time
		add_child(mira)
		mira.usar_camada(CAMADA_DO_ANEL_DE_TEMPO[time])
		miras[time] = mira
	impacto = Impacto.new()
	impacto.name = "Impacto"
	impacto.cameras = cameras
	add_child(impacto)
	rastro = Rastro.new()
	rastro.name = "RastroDaBola"
	rastro.alvo = bola
	add_child(rastro)

	marcador = MarcadorQueda.new()
	marcador.name = "MarcadorQueda"
	add_child(marcador)
	# Bateu na rede: a bola muda de rumo, então o anel muda de lugar e o
	# controle passa pra quem vai nela agora (se ela voltar pro lado de quem
	# tocou, não é ele de novo: seriam dois toques).
	bola.tocou_rede.connect(_ao_lancar_bola)
	bola.tocou_rede.connect(func() -> void: sons.tocar("rede"))

	for jogador in [1, 2]:
		var entrada
		if _jogador_e_o_computador(jogador):
			entrada = EntradaDoComputador.new()
			entrada.jogador = jogador
			entrada.configurar(self, str(Configuracao.dificuldade), int(Configuracao.semente))
		else:
			entrada = EntradaLocal.new()
			entrada.jogador = jogador
		entrada.name = "EntradaJogador%d" % jogador
		entrada.comando.connect(_ao_receber_comando)
		entrada.soltou.connect(_ao_soltar_botao)
		add_child(entrada)
		entradas.append(entrada)

	temporizador_do_ponto = Timer.new()
	temporizador_do_ponto.name = "TemporizadorDoPonto"
	temporizador_do_ponto.one_shot = true
	temporizador_do_ponto.wait_time = PAUSA_DEPOIS_DO_PONTO
	temporizador_do_ponto.timeout.connect(_depois_do_ponto)
	add_child(temporizador_do_ponto)

	menu = MenuDePausa.new()
	menu.name = "MenuDePausa"
	add_child(menu)
	menu.pausa_pedida.connect(func() -> void: menu.abrir_pausa(_resumo_do_placar()))

	_conectar_placar()
	_preparar_saque()
	cortina.abrir()
	# Modo Caos: os dois escolhem a primeira carta antes do 1º saque.
	if modo_caos:
		_abrir_escolha_de_cartas(Callable())


func _physics_process(delta: float) -> void:
	_relogio += delta
	for time in 2:
		var controlado := controlados[time]
		var sacando: bool = estado == Estado.SAQUE and time == placar.quem_saca
		var em_jogo: bool = estado == Estado.SAQUE or estado == Estado.RALLY
		if not cortadas[time].is_empty():
			_atualizar_cortada(time, delta)
		elif em_jogo and not _escolhendo_cartas() and not sacando and not _esta_no_chao(controlado):
			_mover(controlado, time, _direcao_no_mundo(time), delta)
			if estado == Estado.SAQUE:
				_manter_na_ordem(time, controlado)
		_atender_pedido(time)

		# Os outros 5 vão sozinhos pro lugar certo.
		if em_jogo:
			for i in 6:
				var atleta: Node3D = atletas[time][i]
				if atleta != controlado:
					_mover_ia(atleta, _alvo_da_ia(time, i), delta, _atributo(time, "velocidade"))
		elif estado == Estado.PONTO and _tempo_desde_o_ponto() >= COMEMORACAO_ANTES_DE_VOLTAR:
			# Depois de comemorar (ou reagir) um pouco, todo mundo anda até o
			# lugar do próximo saque enquanto o ponto é mostrado. Só visual: no
			# saque, _colocar_na_formacao põe cada um no lugar de qualquer jeito.
			for i in 6:
				_mover_ia(atletas[time][i], _alvo_depois_do_ponto(time, i), delta, PRESSA_DEPOIS_DO_PONTO)

		for atleta in atletas[time]:
			_atualizar_pulo(atleta, delta)
		aneis_do_controlado[time].seguir(controlado)
		setas_do_controlado[time].seguir(controlado, delta)
		_atualizar_anel_de_tempo(time)
		_atualizar_mira(time, delta)
	_atualizar_poses_de_espera()

	# Antes do saque, a bola fica na mão de quem saca.
	if estado == Estado.SAQUE:
		var sacador := controlados[placar.quem_saca]
		var frente := -_lado(placar.quem_saca) * 0.5
		bola.segurar_em(sacador.position + Vector3(0.0, 2.2, frente))
		if not _escolhendo_cartas():
			_contar_tempo_do_saque(delta)


func _mover(atleta: Node3D, time: int, direcao: Vector2, delta: float) -> void:
	atleta.position += Vector3(direcao.x, 0.0, direcao.y) * VELOCIDADE * _atributo(time, "velocidade") * delta
	# Cada time fica no próprio lado da rede (com um pouco de área livre).
	var limite_x := LARGURA / 2.0 + 2.0
	atleta.position.x = clampf(atleta.position.x, -limite_x, limite_x)
	var fundo := COMPRIMENTO / 2.0 + 2.0
	if time == 0:
		atleta.position.z = clampf(atleta.position.z, 0.4, fundo)
	else:
		atleta.position.z = clampf(atleta.position.z, -fundo, -0.4)


# --- IA dos atletas sem controle ---

## Lugar (no mundo) pra onde o atleta "indice" do "time" deve ir agora.
##
## No saque: a formação na ordem do rodízio (regra). Depois do saque, cada
## um vai pro lado da sua função (ponteiro na esquerda, central no meio,
## oposto e levantador na direita) e o levantador do fundo infiltra pra
## levantar quando a bola vem pro nosso lado. Quando o nosso time ataca, os
## outros cobrem o atacante; quando o outro time ataca, os do fundo se
## posicionam pelo lado do atacante. E ninguém fica em cima de um colega.
func _alvo_da_ia(time: int, indice: int) -> Vector3:
	var posicao: int = rodizios[time].posicao_de(indice)
	var da_rede := Rodizio.e_da_rede(posicao)
	var e_levantador := indice == levantadores[time]
	if estado != Estado.RALLY:
		var recebendo: bool = time != placar.quem_saca
		return _no_mundo(time, Formacao.lugar_no_saque(posicao, e_levantador, recebendo))

	var outro := 1 - time
	var funcao: String = funcoes[time].get(indice, "")
	var x_da_funcao := Formacao.x_da_funcao(funcao, da_rede)
	var bola_vem_pra_ca: bool = bola.em_voo and _lado_da_queda() == time
	# O adversário levantou ou atacou: a rede fica pro bloqueio até a gente tocar.
	var adversario_vai_atacar: bool = toques.time_com_a_bola == outro and toques.toques >= 2
	var montando_o_ataque: bool = (toques.time_com_a_bola == time and toques.toques < 3) \
		or (bola_vem_pra_ca and not adversario_vai_atacar)
	var lugar: Vector2

	if da_rede and adversario_vai_atacar \
			and float(atletas[time][indice].get_meta("fora_do_bloqueio_ate", -1.0)) > _relogio:
		# Ficou fora do bloqueio (duplo ou simples): ajuda na defesa.
		return _no_mundo(time, _abrir_espaco(time, indice, _lugar_na_defesa(time, x_da_funcao)))
	if da_rede and adversario_vai_atacar:
		# Sobe pra rede e lê o levantamento: corre pra onde a bola vai.
		# (Sem abrir espaço: o bloqueio duplo é um do lado do outro.)
		lugar = Vector2(_x_do_bloqueio(time, indice, funcao, x_da_funcao), 0.7)
		return _no_mundo(time, lugar)
	if _vamos_atacar(time):
		# Cobertura: chega perto do atacante, cada um do seu lado.
		var padrao := Vector2(x_da_funcao, 1.5 if da_rede else Formacao.Y_FUNDO)
		lugar = _lugar_na_cobertura(time, padrao, COBERTURA_DA_REDE if da_rede else COBERTURA_DO_FUNDO)
	elif e_levantador and montando_o_ataque:
		# Infiltração: o levantador vai pro lugar do levantamento.
		return _no_mundo(time, PONTO_DO_LEVANTADOR)
	elif da_rede and montando_o_ataque:
		# Recua pra ter espaço de correr pro ataque.
		lugar = Vector2(x_da_funcao, LINHA_DE_ATAQUE)
	elif da_rede:
		lugar = Vector2(x_da_funcao, 1.5)
	elif adversario_vai_atacar:
		lugar = _lugar_na_defesa(time, x_da_funcao)
	else:
		lugar = Vector2(x_da_funcao, Formacao.Y_FUNDO)
	return _no_mundo(time, _abrir_espaco(time, indice, lugar))


## O nosso time vai atacar: levantamento no ar vindo pra cá, ou atacante no pulo.
func _vamos_atacar(time: int) -> bool:
	if not cortadas[time].is_empty():
		return true
	return toques.time_com_a_bola == time and toques.toques == 2 and bola.em_voo and _lado_da_queda() == time


## Onde vai ser a cortada do "time" (em coordenadas do time): o atacante no
## pulo, ou onde a bola levantada vai estar na altura da cortada.
func _ponto_do_ataque(time: int) -> Vector2:
	if not cortadas[time].is_empty():
		return _no_time(time, (cortadas[time]["atleta"] as Node3D).position)
	var ate_a_batida := TempoDoToque.tempo_ate_altura(bola.position, bola.velocidade_atual(), TempoDoToque.ALTURA_IDEAL["cortada"])
	return _no_time(time, bola.posicao_daqui_a(maxf(ate_a_batida, 0.0)))


## Cobertura: do lugar de sempre ("padrao"), chega até "raio" metros do
## ponto do ataque, mantendo o lado (assim cada um cobre um pedaço).
func _lugar_na_cobertura(time: int, padrao: Vector2, raio: float) -> Vector2:
	var ataque := _ponto_do_ataque(time)
	var lugar := ataque + (padrao - ataque).limit_length(raio)
	lugar.y = maxf(lugar.y, 1.0)
	return lugar


## Defesa do fundo contra o ataque do outro time: anda um pouco pro lado do
## atacante; quem fica longe dele (a diagonal) recua, quem fica perto (a
## paralela) avança.
func _lugar_na_defesa(time: int, x_da_funcao: float) -> Vector2:
	var outro := 1 - time
	if not bola.em_voo or _lado_da_queda() == time and cortadas[outro].is_empty():
		return Vector2(x_da_funcao, Formacao.Y_FUNDO)
	var mundo := _no_mundo(outro, _ponto_do_ataque(outro))
	var ataque_x := _no_time(time, mundo).x
	var x := clampf(x_da_funcao + ataque_x * DEFESA_PRO_LADO_DO_ATAQUE, -LARGURA / 2.0 + 0.5, LARGURA / 2.0 - 0.5)
	var longe := clampf((absf(x_da_funcao - ataque_x) - 3.0) / 3.0, -1.0, 1.0)
	return Vector2(x, Formacao.Y_FUNDO + longe * DEFESA_RECUO)


## Sem amontoar: se um colega já está perto do "lugar", afasta o lugar dele.
func _abrir_espaco(time: int, indice: int, lugar: Vector2) -> Vector2:
	var ajustado := lugar
	for i in 6:
		if i == indice:
			continue
		var colega := _no_time(time, atletas[time][i].position)
		var afastar := ajustado - colega
		var distancia := afastar.length()
		if distancia >= ESPACO_ENTRE_ATLETAS:
			continue
		if distancia < 0.01:
			# Em cima do colega: sai pro lado (cada um pra um lado, pelo número).
			afastar = Vector2(1.0 if indice > i else -1.0, 0.0)
		ajustado += afastar.normalized() * (ESPACO_ENTRE_ATLETAS - distancia)
	ajustado.x = clampf(ajustado.x, -LARGURA / 2.0 - 1.5, LARGURA / 2.0 + 1.5)
	ajustado.y = maxf(ajustado.y, 1.0)
	return ajustado


## Depois do ponto: cada um vai pro lugar que vai ocupar no próximo saque
## (quem saca vai pra trás da linha de fundo).
func _alvo_depois_do_ponto(time: int, indice: int) -> Vector3:
	if time == placar.quem_saca and indice == rodizios[time].atleta_na(1):
		return _no_mundo(time, POSICAO_DO_SACADOR)
	return _alvo_da_ia(time, indice)


## Leitura do bloqueio: com o levantamento no ar, o bloqueio vê onde a bola
## vai estar na hora da cortada e corre pra lá. O central vai sempre; os
## da ponta só se a bola vai pro lado deles. Com o tempo de reação e a
## velocidade limitada, o levantamento rápido chega antes do bloqueio fechar.
## Antes do levantamento, acompanha a bola.
func _x_do_bloqueio(time: int, indice: int, funcao: String, x_da_funcao: float) -> float:
	var bola_x_do_time: float = bola.position.x * _lado(time)
	if toques.toques < 2 or not bola.em_voo or _lado_da_queda() == time:
		return lerpf(x_da_funcao, bola_x_do_time, 0.5)
	if bola.tempo_de_voo() < REACAO_DO_BLOQUEIO:
		# Ainda lendo o levantamento: fica onde está.
		return atletas[time][indice].position.x * _lado(time)
	# Onde a bola vai estar na altura da cortada (descendo).
	var ate_a_batida := TempoDoToque.tempo_ate_altura(bola.position, bola.velocidade_atual(), TempoDoToque.ALTURA_IDEAL["cortada"])
	var alvo_x: float = bola.posicao_daqui_a(maxf(ate_a_batida, 0.0)).x * _lado(time)
	if funcao == "central" or absf(alvo_x - x_da_funcao) <= AJUDA_DO_BLOQUEIO:
		return alvo_x
	return x_da_funcao


## Antes do saque, o atleta controlado do time que recebe não pode sair da
## ordem do rodízio nem da quadra (senão é falta de posição).
func _manter_na_ordem(time: int, atleta: Node3D) -> void:
	var indice: int = atletas[time].find(atleta)
	if indice < 0:
		return
	var lugares := _lugares_do_time(time)
	var posicao: int = rodizios[time].posicao_de(indice)
	var ignorar := 1 if time == placar.quem_saca else 0
	var ajustado := Formacao.limitar(posicao, lugares[posicao], lugares, ignorar)
	var no_mundo := _no_mundo(time, ajustado)
	atleta.position.x = no_mundo.x
	atleta.position.z = no_mundo.z


## Onde está cada posição do rodízio do "time", em coordenadas do time.
func _lugares_do_time(time: int) -> Dictionary:
	var lugares := {}
	for i in 6:
		lugares[rodizios[time].posicao_de(i)] = _no_time(time, atletas[time][i].position)
	return lugares


func _mover_ia(atleta: Node3D, alvo: Vector3, delta: float, fator := 1.0) -> void:
	if _esta_no_chao(atleta):
		return
	var atual := Vector2(atleta.position.x, atleta.position.z)
	var novo := atual.move_toward(Vector2(alvo.x, alvo.z), VELOCIDADE_IA * fator * delta)
	atleta.position.x = novo.x
	atleta.position.z = novo.y


# --- Pulo e bloqueio ---

## "altura" muda a altura do pulo (a cortada pula até a mão alcançar a bola).
func _pular(atleta: Node3D, altura: float = ALTURA_DO_PULO) -> void:
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
	if tempo >= DURACAO_DO_PULO:
		atleta.position.y = 0.0
		atleta.set_meta("tempo_do_pulo", -1.0)
		return
	var fracao := tempo / DURACAO_DO_PULO
	var altura: float = atleta.get_meta("altura_do_pulo", ALTURA_DO_PULO)
	atleta.position.y = 4.0 * altura * fracao * (1.0 - fracao)
	atleta.set_meta("tempo_do_pulo", tempo)


func _bloquear(time: int) -> void:
	var direcao := _direcao_no_mundo(time)
	var deslocamento := direcao.x * DESLOCAMENTO_DO_BLOQUEIO
	# Quantos bloqueiam: direção pra frente = triplo, neutro = dupla, pra trás = só um.
	var indices: Array[int] = []
	var xs: Array = []
	for i in 6:
		if Rodizio.e_da_rede(rodizios[time].posicao_de(i)) and not _esta_pulando(atletas[time][i]):
			indices.append(i)
			xs.append(atletas[time][i].position.x)
	var pra_frente := direcao.y * _lado(1 - time)
	var escolhidos := JeitosDeDefender.quem_bloqueia(xs, direcao.x, pra_frente)
	_qualidade_do_bloqueio[time] = _qualidade_do_botao_do_bloqueio(time)
	_rumo_do_bloqueio[time] = direcao.x
	for k in indices.size():
		var atleta: Node3D = atletas[time][indices[k]]
		if not escolhidos.has(k):
			# Fica fora do bloqueio e ajuda na defesa.
			atleta.set_meta("fora_do_bloqueio_ate", _relogio + TEMPO_FORA_DO_BLOQUEIO)
			continue
		atleta.position.x += deslocamento
		_pular(atleta)
		if estado == Estado.RALLY and absf(atleta.position.z) < DISTANCIA_MINIMA_DA_REDE:
			_encerrar_rally(1 - time, "toque na rede")
		_animar(atleta, "bloqueio")


## Tempo do botão do bloqueio: o pico do pulo tem que cair quando a bola passa
## pela rede. Sem ataque vindo, o bloqueio sai ruim.
func _qualidade_do_botao_do_bloqueio(time: int) -> Qualidade:
	var outro := 1 - time
	var ate_a_batida := -1.0
	if not cortadas[outro].is_empty():
		ate_a_batida = maxf(TEMPO_ATE_A_BATIDA - float(cortadas[outro]["tempo"]), 0.0)
	elif bola.em_voo and toques.time_com_a_bola == outro and toques.toques >= 2 and _lado_da_queda() == outro:
		ate_a_batida = maxf(TempoDoToque.tempo_ate_altura(bola.position, bola.velocidade_atual(), TempoDoToque.ALTURA_IDEAL["cortada"]), 0.0)
	if ate_a_batida < 0.0:
		return Qualidade.RUIM
	return JeitosDeDefender.qualidade_do_bloqueio(JeitosDeDefender.erro_do_bloqueio(ate_a_batida, DURACAO_DO_PULO))


## Chamado pela bola quando ela cruza a rede por cima da fita. Diz o que o
## bloqueio do lado de destino faz com a bola:
## - DEVOLVE: um atleta da rede no alto do pulo, bem na frente da bola e com
##   as mãos acima dela. A bola volta pra quem atacou.
## - TOQUE: alguém encosta, mas baixo (cedo ou tarde no pulo) ou só com a
##   ponta da mão. A bola segue pro lado do bloqueio, mais devagar.
## - NENHUM: ninguém encosta.
func _tipo_do_bloqueio(ponto_na_rede: Vector3, lado_destino: float) -> Bloqueio:
	var time := 0 if lado_destino > 0.0 else 1
	var largura := LARGURA_DO_BLOQUEIO * Atributos.largura_do_bloqueio(times_em_jogo[time]) * _bloqueio_do_ataque
	var resultado := Bloqueio.NENHUM
	for i in 6:
		if not Rodizio.e_da_rede(rodizios[time].posicao_de(i)):
			continue
		var atleta: Node3D = atletas[time][i]
		if not _esta_pulando(atleta):
			continue
		if absf(atleta.position.z) > DISTANCIA_MAXIMA_DO_BLOQUEIO:
			continue
		var distancia := absf(atleta.position.x - ponto_na_rede.x)
		if distancia > largura + FOLGA_DO_TOQUE_NO_BLOQUEIO:
			continue
		if ponto_na_rede.y > ALTURA_DAS_MAOS + atleta.position.y + Bola.RAIO:
			continue
		var no_alto: bool = atleta.position.y >= ALTURA_DO_PULO * ALTURA_MINIMA_DO_BLOQUEIO
		if distancia <= largura and no_alto \
				and JeitosDeDefender.pode_devolver(_qualidade_do_bloqueio[time]):
			# Bloqueio perfeito devolve mais forte e pro lado apertado.
			var qualidade_do_bloqueio: Qualidade = _qualidade_do_bloqueio[time]
			bola.forca_do_bloqueio = JeitosDeDefender.forca_do_rebote(qualidade_do_bloqueio)
			bola.empurrao_do_bloqueio = float(_rumo_do_bloqueio[time]) * JeitosDeDefender.EMPURRAO_LATERAL_PERFEITO \
				if qualidade_do_bloqueio == Qualidade.PERFEITO else 0.0
			return Bloqueio.DEVOLVE
		resultado = Bloqueio.TOQUE
	return resultado


## Se algum bloqueador encosta na bola que cruza a rede em "ponto_na_rede".
func _tem_bloqueio(ponto_na_rede: Vector3, lado_destino: float) -> bool:
	return _tipo_do_bloqueio(ponto_na_rede, lado_destino) != Bloqueio.NENHUM


func _ao_bola_ser_bloqueada() -> void:
	if estado != Estado.RALLY:
		return
	# Quem bloqueou é o time do lado pra onde a bola ia.
	var time_que_bloqueou := 1 - ultimo_toque
	if saque_em_jogo:
		# Bloquear o saque é falta.
		_encerrar_rally(ultimo_toque, "bloqueio no saque")
		return
	# O bloqueio não conta como toque: quem bloqueou ainda tem 3 toques.
	toques.registrar_bloqueio(time_que_bloqueou)
	ultimo_toque = time_que_bloqueou
	_bloqueio_do_ataque = 1.0
	_forca_da_cortada = -1
	_ponto_de_bloqueio = time_que_bloqueou
	impacto.bloqueio()
	sons.tocar("bloqueio")
	Estouro.mostrar(self, bola.position, _cor_do_time(time_que_bloqueou), 0.8)
	AvisoDeToque.mostrar(self, bola.position + Vector3(0.0, 0.8, 0.0), "Bloqueio!", _cor_do_time(time_que_bloqueou))
	_ao_lancar_bola()


## A bola raspou no bloqueio e seguiu pro lado de quem bloqueou. Não conta
## toque, e quem bloqueou pode tocar de novo; mas se a bola sair, a falta é
## de quem encostou por último (o bloqueio).
func _ao_bola_tocar_bloqueio() -> void:
	if estado != Estado.RALLY:
		return
	var time_que_bloqueou := 1 - ultimo_toque
	if saque_em_jogo:
		_encerrar_rally(ultimo_toque, "bloqueio no saque")
		return
	toques.registrar_bloqueio(time_que_bloqueou)
	ultimo_toque = time_que_bloqueou
	_bloqueio_do_ataque = 1.0
	_forca_da_cortada = -1
	_ponto_de_bloqueio = -1
	impacto.ponto()
	sons.tocar("bloqueio", 0.45)
	AvisoDeToque.mostrar(self, bola.position + Vector3(0.0, 0.8, 0.0), "Toque no bloqueio", Color(0.95, 0.95, 0.95))
	_ao_lancar_bola()


## Toca um lance no personagem do atleta (a cápsula não tem animação).
func _animar(atleta: Node3D, lance: String) -> void:
	var animador = _animador_de(atleta)
	if animador:
		animador.tocar(lance)


## Parado em quadra, quem espera o saque ou o ataque do outro time fica
## agachado na defesa ("espera_defesa"); quem está com a bola fica na "espera".
func _atualizar_poses_de_espera() -> void:
	var defendendo := -1
	if estado == Estado.SAQUE:
		defendendo = 1 - placar.quem_saca
	elif estado == Estado.RALLY and ultimo_toque >= 0:
		defendendo = 1 - ultimo_toque
	for time in 2:
		var pose := "espera_defesa" if time == defendendo else Animador.PARADO_NO_JOGO
		for atleta in atletas[time]:
			var animador = _animador_de(atleta)
			if animador:
				animador.parado_no_jogo = pose


## O animador do personagem do atleta, ou null (cápsula, sem personagem).
func _animador_de(atleta: Node3D):
	if atleta == null or not atleta.has_meta("animador"):
		return null
	return atleta.get_meta("animador")


# --- Comandos ---

func _ao_receber_comando(jogador: int, tipo: String) -> void:
	if _escolhendo_cartas():
		return
	var time := jogador - 1
	_segurando_botao[time][tipo] = true
	match estado:
		Estado.SAQUE:
			# Segurar carrega a força; o saque sai quando solta (_ao_soltar_botao).
			if time == placar.quem_saca and carga_do_saque < 0.0 \
					and (tipo == "ataque" or tipo == "saque_flutuante"):
				carga_do_saque = 0.0
				saque_flutuante = tipo == "saque_flutuante"
				alvo_do_saque = Mira.ALVO_INICIAL
		Estado.RALLY:
			if tipo == "passe":
				if not cortadas[time].is_empty():
					# Passe no ar, durante a cortada: vira largada.
					controlados[time].set_meta("largada", true)
				elif not _tentar_tocar(time, false):
					_guardar_pedido(time, tipo)
			elif tipo == "ataque":
				if not _comecar_cortada(time):
					_guardar_pedido(time, tipo)
			elif tipo == "bloqueio":
				_bloquear(time)
			elif tipo == "mergulho":
				_mergulhar(time)


## O botão veio cedo (a bola ainda não está ao alcance): guarda o pedido
## por TEMPO_DO_PEDIDO e tenta de novo a cada quadro (_atender_pedido).
func _guardar_pedido(time: int, tipo: String) -> void:
	pedidos[time] = { "tipo": tipo, "ate": _relogio + TEMPO_DO_PEDIDO }


## Tenta de novo o botão guardado. Se o tempo acabou e a bola não chegou,
## o anel do atleta pisca: o jogo ouviu, mas não dava pra tocar.
func _atender_pedido(time: int) -> void:
	if pedidos[time].is_empty():
		return
	if estado != Estado.RALLY:
		pedidos[time] = {}
		return
	var tipo: String = pedidos[time]["tipo"]
	var atendido: bool = _comecar_cortada(time) if tipo == "ataque" else _tentar_tocar(time, false)
	if atendido:
		pedidos[time] = {}
	elif _relogio > float(pedidos[time]["ate"]):
		pedidos[time] = {}
		aneis_do_controlado[time].piscar()
		sons.tocar("falhou")


func _ao_soltar_botao(jogador: int, tipo: String) -> void:
	var time := jogador - 1
	_segurando_botao[time].erase(tipo)
	if _escolhendo_cartas():
		return
	if estado != Estado.SAQUE or time != placar.quem_saca or carga_do_saque < 0.0:
		return
	if tipo != ("saque_flutuante" if saque_flutuante else "ataque"):
		return
	var forca := Mira.forca(carga_do_saque)
	carga_do_saque = -1.0
	_sacar(time, saque_flutuante, forca, alvo_do_saque)


## Saque com "forca" (0 a 1) mirando "alvo" (na quadra do outro time).
## Mais força: mais baixo e rápido, mas com mais erro (pode sair).
func _sacar(time: int, flutuante: bool, forca := 0.4, alvo := Mira.ALVO_INICIAL) -> void:
	carga_do_saque = -1.0
	miras[time].esconder()
	_animar(controlados[time], "saque")
	# Na hora do saque, os dois times têm que estar na ordem do rodízio.
	var falta_de_posicao := _time_fora_de_posicao()
	if falta_de_posicao >= 0:
		_encerrar_rally(1 - falta_de_posicao, "posição errada no saque")
		return
	_bloqueio_do_ataque = 1.0
	_forca_da_cortada = -1
	_ultimo_levantamento = [{}, {}]
	toques.reiniciar()
	toques.registrar(time, atletas[time].find(controlados[time]))
	sons.tocar("saque", lerpf(0.5, 1.1, forca))
	saque_em_jogo = true
	var ponto := Mira.com_erro(alvo, _erro_do_saque(time, forca), Vector2(sorteio.randf(), sorteio.randf()))
	var destino := Vector3(ponto.x, 0.0, ponto.y * _lado(1 - time))
	# Provisório: o flutuante só sai mais baixo. O balanço vem depois.
	bola.lancar(destino, Mira.altura_do_saque(forca, flutuante))
	ultimo_toque = time
	estado = Estado.RALLY
	_limpar_mensagens()
	_ao_lancar_bola()


## Passe (atacando = false) ou ataque (atacando = true) do atleta controlado.
## Devolve false se a bola estava fora do alcance (o botão não valeu).
func _tentar_tocar(time: int, atacando: bool, mergulho := false) -> bool:
	var alcancou: bool
	if mergulho:
		alcancou = true
	elif atacando:
		alcancou = _alcanca_bola(time, ALTURA_MINIMA_CORTADA, ALTURA_MAXIMA_CORTADA)
	else:
		alcancou = _alcanca_bola(time, 0.0, ALTURA_MAXIMA_PASSE)
	if not alcancou:
		return false
	if saque_em_jogo and time == placar.quem_saca:
		# Quem sacou não pode tocar no próprio saque: o toque é ignorado.
		# (Se a bola não passar a rede, ela cai do lado de quem sacou e é ponto do outro.)
		return true

	var falta := _falta_no_toque(time, atacando)
	if falta != "":
		_encerrar_rally(1 - time, falta)
		return true
	if not toques.registrar(time, atletas[time].find(controlados[time])):
		_encerrar_rally(1 - time, "4 toques")
		return true
	if time != placar.quem_saca:
		saque_em_jogo = false
	ultimo_toque = time
	_ponto_de_bloqueio = -1
	_bloqueio_do_ataque = 1.0
	var cortada_recebida := _forca_da_cortada
	_forca_da_cortada = -1
	_mostrar_marcas_de_ataque(-1)

	var numero: int = toques.toques
	var tipo := _tipo_do_toque(numero, atacando)
	var qualidade := _qualidade_do_toque(tipo, time)
	var atleta_que_tocou := controlados[time]
	if atacando and atleta_que_tocou.has_meta("qualidade_da_cortada"):
		qualidade = atleta_que_tocou.get_meta("qualidade_da_cortada")
		atleta_que_tocou.remove_meta("qualidade_da_cortada")
	if mergulho:
		# Mergulho: no máximo "bom"; de longe (fora do alcance normal), ruim.
		var longe := _distancia_no_chao(atleta_que_tocou, bola.position) > ALCANCE
		qualidade = JeitosDeDefender.qualidade_do_mergulho(qualidade, longe)
	if numero == 1 and not atacando:
		# Cortada perfeita do outro time: passe só bom foge e sai ruim.
		var antes := qualidade
		qualidade = JeitosDeDefender.qualidade_da_recepcao(qualidade, cortada_recebida)
		if qualidade != antes:
			_mostrar_mensagem("Cortada forte! Acerte o tempo", time)
	if atacando or numero <= 2:
		_avisar_qualidade(controlados[time], qualidade)
	if atacando:
		_cortar(time, qualidade)
	elif numero == 1:
		_passar_pro_levantador(time, qualidade)
	elif numero == 2:
		_levantar(time, qualidade)
	else:
		_devolver_de_graca(time)
	return true


## 1º toque. A qualidade decide o quanto a bola erra o levantador e o que
## ele vai poder levantar.
func _passar_pro_levantador(time: int, qualidade: Qualidade) -> void:
	_animar(controlados[time], "manchete")
	sons.tocar("passe", _intensidade_do_som(qualidade))
	qualidade_do_passe[time] = qualidade
	_ultimo_levantamento[time] = {}
	var erro := _erro_aleatorio(TempoDoToque.ERRO_DO_PASSE[qualidade])
	# O passe nunca passa da rede nem sai pela lateral.
	var lugar := PONTO_DO_LEVANTADOR + erro
	lugar.x = clampf(lugar.x, -LARGURA / 2.0 + 0.5, LARGURA / 2.0 - 0.5)
	lugar.y = maxf(lugar.y, 0.6)
	bola.lancar(_no_mundo(time, lugar), TempoDoToque.ALTURA_DO_PASSE[qualidade])
	_ao_lancar_bola()
	_mostrar_marcas_de_ataque(time)


## 2º toque. Passe ruim só deixa levantar alto (ponta ou fundo); passe e
## levantamento perfeitos dão o levantamento rápido, que chega antes do bloqueio.
func _levantar(time: int, qualidade: Qualidade) -> void:
	_animar(controlados[time], "levantamento")
	sons.tocar("levantamento", _intensidade_do_som(qualidade))
	var passe: Qualidade = qualidade_do_passe[time]
	var escolhido := _ataque_escolhido(time, passe)
	var altura := TempoDoToque.altura_do_levantamento(passe, qualidade)
	if Atributos.levantamento_rapido(times_em_jogo[time]):
		altura = TempoDoToque.ALTURA_DO_LEVANTAMENTO_RAPIDO
	# Segurando o botão de flutuante: levantamento rápido mesmo com passe só
	# "bom". Passe ou levantamento ruim não deixam. Se não forem perfeitos, o
	# atacante recebe a bola com mais erro.
	var raio: float = TempoDoToque.ERRO_DO_LEVANTAMENTO[qualidade]
	var quer_rapido: bool = _segurando_botao[time].get("saque_flutuante", false)
	if quer_rapido and altura != TempoDoToque.ALTURA_DO_LEVANTAMENTO_RAPIDO \
			and passe != Qualidade.RUIM and qualidade != Qualidade.RUIM:
		altura = TempoDoToque.ALTURA_DO_LEVANTAMENTO_RAPIDO
		if passe != Qualidade.PERFEITO or qualidade != Qualidade.PERFEITO:
			raio *= JeitosDeAtacar.ERRO_DO_RAPIDO_FORCADO
	var erro := _erro_aleatorio(raio)
	var alvo: Vector3 = alvos_de_ataque[time][escolhido] + Vector3(erro.x, 0.0, erro.y)
	bola.lancar(alvo, altura)
	_ao_lancar_bola()
	var nome: String = ATAQUES[escolhido]["nome"]
	var rapido: bool = altura == TempoDoToque.ALTURA_DO_LEVANTAMENTO_RAPIDO
	_ultimo_levantamento[time] = { "nome": nome, "rapido": rapido }
	if rapido:
		_mostrar_mensagem("Levantamento rápido: %s" % nome, time)
	elif altura == TempoDoToque.ALTURA_DO_LEVANTAMENTO_ALTO:
		_mostrar_mensagem("Levantamento alto: %s" % nome, time)
	else:
		_mostrar_mensagem("Levantamento: %s" % nome, time)


## Pra onde o levantador manda: a direção apertada, só entre os ataques que
## o passe deixou. Sem direção, o meio (ou a ponta, se o meio não der).
func _ataque_escolhido(time: int, passe: Qualidade) -> int:
	var liberados: Array[int] = []
	var alvos: Array = []
	for i in ATAQUES.size():
		if TempoDoToque.ataque_liberado(passe, ATAQUES[i]["nome"]):
			liberados.append(i)
			alvos.append(alvos_de_ataque[time][i])
	var padrao := liberados.find(ATAQUE_PADRAO)
	if padrao < 0:
		padrao = 0
	var escolhido := EscolhaAtaque.escolher(alvos, _direcao_no_mundo(time), padrao)
	return liberados[escolhido]


## Ataque apertado: se a bola vai estar ao alcance no alto do pulo, o atleta
## sai do chão agora e bate nela daqui a TEMPO_ATE_A_BATIDA (_atualizar_cortada).
## As regras (faltas, toques) são conferidas na batida, por _tentar_tocar.
## Devolve false se a bola não vai estar ao alcance (o botão não valeu).
func _comecar_cortada(time: int) -> bool:
	var atleta := controlados[time]
	if not cortadas[time].is_empty() or _esta_pulando(atleta) or not bola.em_voo:
		return false
	var prevista: Vector3 = bola.posicao_daqui_a(TEMPO_ATE_A_BATIDA)
	var no_chao := Vector2(prevista.x - atleta.position.x, prevista.z - atleta.position.z)
	if no_chao.length() > ALCANCE or prevista.y < ALTURA_MINIMA_CORTADA or prevista.y > ALTURA_MAXIMA_CORTADA:
		return false
	# Na regra do ataque do fundo vale de onde o atleta saiu do chão.
	atleta.set_meta("saiu_do_chao_em", atleta.position)
	# Pula o bastante pra mão (na pose da batida) chegar na altura da bola.
	var mao_acima_dos_pes := ALTURA_DAS_MAOS
	var animador = _animador_de(atleta)
	if animador:
		mao_acima_dos_pes = animador.altura_da_mao_na_batida()
	_pular(atleta, clampf(prevista.y - mao_acima_dos_pes, PULO_MINIMO_DA_CORTADA, PULO_MAXIMO_DA_CORTADA))
	_animar(atleta, "cortada")
	# O tempo da cortada vale no botão: a batida vem TEMPO_ATE_A_BATIDA depois.
	atleta.set_meta("qualidade_da_cortada", _qualidade_do_toque("cortada", time))
	cortadas[time] = {
		"atleta": atleta, "tempo": 0.0,
		"de": Vector2(atleta.position.x, atleta.position.z),
	}
	return true


func _atualizar_cortada(time: int, delta: float) -> void:
	var cortada: Dictionary = cortadas[time]
	var atleta: Node3D = cortada["atleta"]
	cortada["tempo"] += delta
	# No ar, o atleta vai pra onde a mão encontra a bola na batida (sem a mão,
	# pra baixo da bola). Sem chegar mais perto da rede do que pode.
	var falta: float = maxf(TEMPO_ATE_A_BATIDA - cortada["tempo"], 0.0)
	var prevista: Vector3 = bola.posicao_daqui_a(falta)
	var alvo := Vector2(prevista.x, prevista.z)
	var mao_agora = _posicao_da_mao(atleta)
	if mao_agora != null:
		alvo -= Vector2((mao_agora as Vector3).x - atleta.position.x, (mao_agora as Vector3).z - atleta.position.z)
	alvo.y = _lado(time) * maxf(alvo.y * _lado(time), DISTANCIA_MINIMA_DA_REDE + 0.05)
	var fracao := smoothstep(0.0, TEMPO_ATE_A_BATIDA, cortada["tempo"])
	var ponto: Vector2 = (cortada["de"] as Vector2).lerp(alvo, fracao)
	atleta.position.x = ponto.x
	atleta.position.z = ponto.y
	if estado != Estado.RALLY or not bola.em_voo or controlados[time] != atleta:
		_terminar_cortada(time, atleta)
		atleta.remove_meta("qualidade_da_cortada")
		return
	if cortada["tempo"] < TEMPO_ATE_A_BATIDA:
		# Chegando na batida, a bola vai encostando na mão.
		var mao = _mao_perto_da_bola(atleta, TEMPO_ATE_A_BATIDA - cortada["tempo"])
		if mao != null:
			var peso := smoothstep(TEMPO_ATE_A_BATIDA - IMA_DA_MAO, TEMPO_ATE_A_BATIDA, cortada["tempo"])
			bola.puxar_para(mao, peso)
		return
	cortadas[time] = {}
	_bater_na_bola(time, atleta)
	_terminar_cortada(time, atleta)


## Fim da cortada (com ou sem batida): solta a bola do ímã e limpa as marcas do atleta.
func _terminar_cortada(time: int, atleta: Node3D) -> void:
	cortadas[time] = {}
	bola.puxar_para(Vector3.ZERO, 0.0)
	atleta.remove_meta("saiu_do_chao_em")
	atleta.remove_meta("largada")


## Posição da mão da cortada, se ela vai estar perto da bola daqui a
## "segundos" (null se longe ou se o atleta não tem personagem).
func _mao_perto_da_bola(atleta: Node3D, segundos: float):
	var mao = _posicao_da_mao(atleta)
	if mao == null or (mao as Vector3).distance_to(bola.posicao_daqui_a(segundos)) > ALCANCE_DA_MAO:
		return null
	return mao


## Onde está a mão da cortada do personagem (null sem personagem).
func _posicao_da_mao(atleta: Node3D):
	var animador = _animador_de(atleta)
	return animador.posicao_da_mao() if animador else null


## Batida da cortada, no alto do pulo: a bola vai pra mão (se a mão chegou
## perto) e sai de lá. Se a cortada não valer, a bola segue o caminho dela.
func _bater_na_bola(time: int, atleta: Node3D) -> void:
	var antes: Vector3 = bola.position
	var lancamentos: int = bola.lancamentos
	var mao = _mao_perto_da_bola(atleta, 0.0)
	if mao != null:
		bola.position = mao
	_tentar_tocar(time, true)
	if bola.lancamentos == lancamentos:
		bola.position = antes


## Cortada, na batida (alto do pulo). A qualidade, medida no botão, decide
## a força (quanto a bola sobe), o erro da mira e a profundidade.
## Cortada ruim sai fraca e torta.
func _cortar(time: int, qualidade: Qualidade = Qualidade.BOM) -> void:
	if toques.toques == 2:
		# Atacar no 2º toque: bola de segunda, o levantador empurra a bola.
		_largar(time, qualidade, "Bola de segunda!")
		return
	if controlados[time].get_meta("largada", false):
		_largar(time, qualidade)
		return
	var jeito: Dictionary = TempoDoToque.CORTADA[qualidade]
	# A direção mira: esquerda/direita, e pra frente (funda) ou pra trás (curta).
	var alvo := _alvo_da_cortada(time)
	alvo.y = clampf(alvo.y, jeito["fundo_min"], jeito["fundo_max"])
	# Jeito do ataque: rápido do meio, pipe, diagonal ou paralela.
	var levantamento: Dictionary = _ultimo_levantamento[time]
	_ultimo_levantamento[time] = {}
	var efeito := JeitosDeAtacar.efeito(
		levantamento.get("nome", ""), levantamento.get("rapido", false),
		JeitosDeAtacar.jeito_da_mira(controlados[time].position.x, alvo.x))
	var erro_da_mira := maxf(float(jeito["erro_da_mira"]) + float(efeito["erro_a_mais"]), 0.1)
	var destino := _destino_na_quadra_do_outro(time, alvo, erro_da_mira)
	miras[time].esconder()
	var subida := maxf(float(jeito["subida"]) - Atributos.cortada_mais_forte(times_em_jogo[time]) - float(efeito["subida_a_menos"]), 0.05)
	if qualidade != Qualidade.RUIM:
		# Cortada ruim não aproveita o jeito: o bloqueio pega normal.
		_bloqueio_do_ataque = float(efeito["bloqueio"])
		if efeito["nome"] != "":
			_mostrar_mensagem(efeito["nome"], time)
	var ponto_da_batida: Vector3 = bola.position
	_forca_da_cortada = int(qualidade)
	bola.lancar(destino, bola.position.y + subida)
	_ao_lancar_bola()
	sons.tocar("cortada", _intensidade_do_som(qualidade))
	if qualidade != Qualidade.RUIM:
		var perfeita := qualidade == Qualidade.PERFEITO
		impacto.cortada(perfeita)
		Estouro.mostrar(self, ponto_da_batida, COR_DA_CORTADA_PERFEITA if perfeita else Color(1.0, 1.0, 1.0), 1.0 if perfeita else 0.45)
		if perfeita:
			rastro.destacar(COR_DA_CORTADA_PERFEITA)


## Largada: bola curta, devagar e por cima do bloqueio. A direção mira o lado
## (esquerda/direita); a qualidade (tempo do botão) só muda o erro.
func _largar(time: int, qualidade: Qualidade, mensagem := "Largada!") -> void:
	var alvo := _alvo_da_cortada(time)
	alvo.y = (LARGADA_FUNDO_MIN + LARGADA_FUNDO_MAX) / 2.0
	var destino := _destino_na_quadra_do_outro(time, alvo, ERRO_DA_LARGADA[qualidade], LARGADA_FUNDO_MIN, LARGADA_FUNDO_MAX)
	miras[time].esconder()
	bola.lancar(destino, bola.position.y + SUBIDA_DA_LARGADA)
	_ao_lancar_bola()
	sons.tocar("levantamento", 0.6)
	_mostrar_mensagem(mensagem, time)


## Ponto do mundo na quadra do outro time: "alvo" (x = lado, y = distância
## da rede) com um erro aleatório de até "erro" metros, sem sair pela
## lateral e, se pedido, com a profundidade entre fundo_min e fundo_max.
func _destino_na_quadra_do_outro(time: int, alvo: Vector2, erro: float, fundo_min := -1.0, fundo_max := -1.0) -> Vector3:
	var ponto := Mira.com_erro(alvo, erro, Vector2(sorteio.randf(), sorteio.randf()))
	ponto.x = clampf(ponto.x, -LARGURA / 2.0 + 0.2, LARGURA / 2.0 - 0.2)
	if fundo_min >= 0.0:
		ponto.y = clampf(ponto.y, fundo_min, fundo_max)
	return Vector3(ponto.x, 0.0, ponto.y * _lado(1 - time))


## Erro aleatório (no chão) de até "raio" metros, espalhado por igual num disco.
func _erro_aleatorio(raio: float) -> Vector2:
	return Vector2.from_angle(sorteio.randf() * TAU) * raio * sqrt(sorteio.randf())


func _devolver_de_graca(time: int) -> void:
	_animar(controlados[time], "manchete")
	sons.tocar("passe", 0.6)
	bola.lancar(_ponto_aleatorio_no_lado(1 - time, 2.0, 8.0), 5.0)
	_ao_lancar_bola()


func _alcanca_bola(time: int, altura_minima: float, altura_maxima: float) -> bool:
	if not bola.em_voo:
		return false
	var atleta := controlados[time]
	var altura: float = bola.position.y
	return _distancia_no_chao(atleta, bola.position) <= ALCANCE and altura >= altura_minima and altura <= altura_maxima


## Mostra o anel e passa o controle pro atleta mais perto de onde a bola vai cair.
## Se a bola fica do mesmo lado (passe ou levantamento), quem acabou de tocar
## não é escolhido de novo.
func _ao_lancar_bola() -> void:
	var queda: Vector3 = bola.ponto_previsto
	marcador.mostrar_em(queda)
	var time_que_recebe := _lado_da_queda()
	controlados[time_que_recebe] = _quem_vai_na_bola(time_que_recebe, queda)


## Quem do "time" vai na bola que cai em "queda", respeitando as funções:
## - 1º toque (bola que vem do outro lado ou que voltou do nosso bloqueio):
##   quem estiver mais perto (o levantador evita, pra poder levantar);
## - 2º toque: o levantador (se não foi ele que passou);
## - 3º toque: quem pode atacar dali (da rede na frente da linha de 3 m,
##   do fundo atrás dela). Ninguém toca duas vezes seguidas.
func _quem_vai_na_bola(time: int, queda: Vector3) -> Node3D:
	var levantador: Node3D = atletas[time][levantadores[time]]
	var bola_nossa: bool = time == ultimo_toque and toques.time_com_a_bola == time
	if not bola_nossa or toques.toques == 0:
		var outro_perto := _mais_perto(time, queda, levantador)
		if _distancia_no_chao(levantador, queda) + VANTAGEM_PRO_PASSE_DO_LEVANTADOR \
				< _distancia_no_chao(outro_perto, queda):
			return levantador
		return outro_perto

	var quem_tocou: Node3D = controlados[time]
	if toques.toques == 1:
		if levantador != quem_tocou:
			return levantador
		return _mais_perto(time, queda, quem_tocou)

	var do_fundo := absf(queda.z) >= LINHA_DE_ATAQUE
	var quem_ataca := _mais_perto(time, queda, quem_tocou, func(atleta: Node3D) -> bool:
		return _e_da_rede(time, atleta) != do_fundo)
	if quem_ataca:
		return quem_ataca
	return _mais_perto(time, queda, quem_tocou)


# --- Toque no tempo certo ---

## Tipo do toque pra medir o tempo: o 1º é passe, o 2º levantamento, o 3º
## (ou qualquer ataque) cortada.
func _tipo_do_toque(numero: int, atacando: bool) -> String:
	if atacando or numero >= 3:
		return "cortada"
	return "levantamento" if numero == 2 else "passe"


## Qualidade do toque feito agora, pelo tempo do botão.
func _qualidade_do_toque(tipo: String, time: int) -> Qualidade:
	if tipo == "levantamento" and Atributos.levantamento_perfeito(times_em_jogo[time]):
		return Qualidade.PERFEITO
	var erro := TempoDoToque.erro_do_botao(tipo, bola.position, bola.velocidade_atual(), _atraso_do_toque(tipo))
	return TempoDoToque.qualidade(erro, Atributos.escala_da_janela(times_em_jogo[time], tipo))


## Tempo entre o botão e a mão encostar na bola (a cortada bate no alto do pulo).
func _atraso_do_toque(tipo: String) -> float:
	return TEMPO_ATE_A_BATIDA if tipo == "cortada" else 0.0


## Mostra o anel de tempo pro atleta controlado do "time" quando a bola está
## vindo pra ele e é a vez dele tocar.
func _atualizar_anel_de_tempo(time: int) -> void:
	var anel = aneis_de_tempo[time]
	if estado != Estado.RALLY or not bola.em_voo or _lado_da_queda() != time \
			or (saque_em_jogo and time == placar.quem_saca):
		anel.esconder()
		return
	var numero := 1
	if toques.time_com_a_bola == time:
		numero = toques.toques + 1
	var tipo := _tipo_do_toque(numero, false)
	var velocidade: Vector3 = bola.velocidade_atual()
	var segundos := TempoDoToque.erro_do_botao(tipo, bola.position, velocidade, _atraso_do_toque(tipo))
	var atleta := controlados[time]
	# Longe de onde a bola vai estar na hora certa, o anel só atrapalha.
	var na_hora := Trajetoria.posicao_em(bola.position, velocidade, maxf(segundos, 0.0))
	if _distancia_no_chao(atleta, na_hora) > DISTANCIA_DO_ANEL_DE_TEMPO:
		anel.esconder()
		return
	anel.mostrar(atleta.position, segundos)


func _avisar_qualidade(atleta: Node3D, qualidade: Qualidade) -> void:
	var cor := Color("#FF6B5B")
	if qualidade == Qualidade.PERFEITO:
		cor = AnelDeTempo.COR_PERFEITO
	elif qualidade == Qualidade.BOM:
		cor = AnelDeTempo.COR_BOM
	var aviso := AvisoDeToque.mostrar(self, atleta.position + Vector3(0.0, 2.3, 0.0), TempoDoToque.nome(qualidade), cor)
	# Perfeito: texto maior e um sininho. Ruim: um som curto de erro.
	if qualidade == Qualidade.PERFEITO:
		aviso.font_size = TAMANHO_DO_AVISO_PERFEITO
		aviso.outline_size = 14
		sons.tocar("perfeito")
	elif qualidade == Qualidade.RUIM:
		sons.tocar("ruim")


## Volume das batidas pela qualidade do toque (perfeito = mais forte).
func _intensidade_do_som(qualidade: Qualidade) -> float:
	if qualidade == Qualidade.PERFEITO:
		return 1.0
	if qualidade == Qualidade.BOM:
		return 0.75
	return 0.5


# --- Atributos e mergulho ---

## Multiplicador de um atributo do "time" (só velocidade usa este atalho).
func _atributo(time: int, nome: String) -> float:
	if times_em_jogo.size() <= time:
		return 1.0
	if nome == "velocidade":
		return Atributos.velocidade(times_em_jogo[time])
	return 1.0


func _erro_do_saque(time: int, forca: float) -> float:
	return Mira.erro_do_saque(forca) * Atributos.erro_do_saque(times_em_jogo[time])


func _esta_no_chao(atleta: Node3D) -> bool:
	return atleta != null and float(atleta.get_meta("no_chao_ate", -1.0)) > _relogio


## Mergulho do atleta controlado: se a bola está baixa e ao alcance do
## mergulho, ele se joga e toca (bola pior). Se não, se joga no vazio.
## Nos dois casos fica no chão TEMPO_NO_CHAO segundos.
func _mergulhar(time: int) -> void:
	var atleta := controlados[time]
	if atleta == null or _esta_no_chao(atleta) or _esta_pulando(atleta):
		return
	# Mergulho no tempo alcança mais longe; fora do tempo (ou no vazio) deixa
	# mais tempo no chão.
	var tempo_do_botao := Qualidade.RUIM
	if bola.em_voo:
		tempo_do_botao = _qualidade_do_toque("passe", time)
	var alcance := ALCANCE_DO_MERGULHO + Atributos.alcance_extra_do_mergulho(times_em_jogo[time]) \
		+ JeitosDeDefender.alcance_a_mais(tempo_do_botao)
	var ate_a_bola := Vector2(bola.position.x - atleta.position.x, bola.position.z - atleta.position.z)
	var alcanca: bool = bola.em_voo and bola.position.y <= ALTURA_MAXIMA_DO_MERGULHO \
		and ate_a_bola.length() <= alcance
	var tempo_no_chao := TEMPO_NO_CHAO * Atributos.escala_do_tempo_no_chao(times_em_jogo[time])
	atleta.set_meta("no_chao_ate", _relogio + JeitosDeDefender.tempo_no_chao_do_mergulho(tempo_no_chao, tempo_do_botao, alcanca))
	sons.tocar("mergulho")
	if alcanca:
		_tentar_tocar(time, false, true)
		# Se joga até perto da bola. A animação vem depois do toque, pra
		# manchete do passe não tomar o lugar do mergulho.
		var passo := ate_a_bola.limit_length(maxf(ate_a_bola.length() - 0.5, 0.0))
		_deslocar(atleta, time, passo)
		_animar_mergulho(atleta, ate_a_bola)
		return
	var rumo := ate_a_bola.normalized() if bola.em_voo else _direcao_no_mundo(time).normalized()
	_deslocar(atleta, time, rumo * MERGULHO_NO_VAZIO)
	_animar_mergulho(atleta, rumo)


## Mergulho pro lado do "rumo" (esquerda ou direita de quem mergulha).
func _animar_mergulho(atleta: Node3D, rumo: Vector2) -> void:
	var animador = _animador_de(atleta)
	if animador:
		animador.mergulhar(rumo)


## Move o atleta "passo" metros no chão, sem passar da rede nem sair da área.
func _deslocar(atleta: Node3D, time: int, passo: Vector2) -> void:
	atleta.position += Vector3(passo.x, 0.0, passo.y)
	_mover(atleta, time, Vector2.ZERO, 0.0)


# --- Mira ---

## Alvo da cortada do "time" pela direção apertada agora (na quadra do outro).
func _alvo_da_cortada(time: int) -> Vector2:
	return Mira.alvo_da_cortada(_direcao_no_mundo(time), _lado(1 - time))


## Mostra a mira: no saque carregando (alvo que anda + força) e quando o time
## vai atacar (levantamento no ar ou atleta no pulo da cortada).
func _atualizar_mira(time: int, delta: float) -> void:
	var mira = miras[time]
	var lado_do_alvo := _lado(1 - time)
	if estado == Estado.SAQUE and time == placar.quem_saca and carga_do_saque >= 0.0:
		carga_do_saque += delta
		alvo_do_saque = Mira.mover_alvo(alvo_do_saque, _direcao_no_mundo(time), lado_do_alvo, delta)
		var forca := Mira.forca(carga_do_saque)
		var ponto := Vector3(alvo_do_saque.x, 0.0, alvo_do_saque.y * lado_do_alvo)
		var arriscada: bool = forca >= Mira.FORCA_ARRISCADA
		mira.mostrar(ponto, _erro_do_saque(time, forca), arriscada)
		barras_de_forca[time].mostrar(forca, arriscada)
		return
	barras_de_forca[time].esconder()
	var vai_atacar: bool = estado == Estado.RALLY and (not cortadas[time].is_empty() \
		or (toques.time_com_a_bola == time and toques.toques == 2 and bola.em_voo and _lado_da_queda() == time))
	if not vai_atacar:
		mira.esconder()
		return
	var alvo := _alvo_da_cortada(time)
	var raio: float = TempoDoToque.CORTADA[Qualidade.BOM]["erro_da_mira"]
	mira.mostrar(Vector3(alvo.x, 0.0, alvo.y * lado_do_alvo), raio)


# --- Regras (faltas) ---

## Falta no toque do atleta controlado do "time"? Devolve o motivo, ou "".
func _falta_no_toque(time: int, atacando: bool) -> String:
	var atleta := controlados[time]
	var indice: int = atletas[time].find(atleta)
	if toques.seria_toque_duplo(time, indice):
		return "dois toques"
	if not atacando:
		return ""
	if absf(atleta.position.z) < DISTANCIA_MINIMA_DA_REDE:
		return "toque na rede"
	# Na cortada, a zona vale de onde o atleta saiu do chão (_comecar_cortada).
	var saiu_de: Vector3 = atleta.get_meta("saiu_do_chao_em", atleta.position)
	# Ataque com a bola inteira acima da rede, de dentro da zona de ataque:
	var acima_da_rede: bool = bola.position.y - Bola.RAIO > ALTURA_REDE
	var na_zona_de_ataque := absf(saiu_de.z) < LINHA_DE_ATAQUE
	if acima_da_rede and na_zona_de_ataque:
		if saque_em_jogo:
			return "ataque no saque"
		if not _e_da_rede(time, atleta):
			return "ataque do fundo"
	return ""


## A bola cruzou a linha da rede: tem que passar entre as antenas
## (que ficam em cima das linhas laterais).
func _ao_bola_cruzar_a_rede(ponto: Vector3) -> void:
	if estado != Estado.RALLY:
		return
	if absf(ponto.x) > LARGURA / 2.0:
		_encerrar_rally(1 - ultimo_toque, "fora da antena")


## Algum time fora da ordem do rodízio na hora do saque? Devolve qual, ou -1.
## Quem saca erra primeiro (a falta dele vale mais, como na regra).
func _time_fora_de_posicao() -> int:
	for time in [placar.quem_saca, 1 - placar.quem_saca]:
		var ignorar := 1 if time == placar.quem_saca else 0
		if not Formacao.faltas(_lugares_do_time(time), ignorar).is_empty():
			return time
	return -1


## Conta os 8 s do saque e avisa nos 3 últimos.
func _contar_tempo_do_saque(delta: float) -> void:
	tempo_no_saque += delta
	var restam := ceili(TEMPO_PARA_SACAR - tempo_no_saque)
	if restam <= 0:
		_encerrar_rally(1 - placar.quem_saca, "demorou pra sacar")
		return
	if restam <= 3 and restam != _segundos_mostrados:
		_segundos_mostrados = restam
		_mostrar_mensagem("Saque: segure e solte Ataque (%d)" % restam, placar.quem_saca)


func _e_da_rede(time: int, atleta: Node3D) -> bool:
	var indice: int = atletas[time].find(atleta)
	return indice >= 0 and Rodizio.e_da_rede(rodizios[time].posicao_de(indice))


## De que lado vai cair a bola: 0 = time do Jogador 1 (z positivo), 1 = o outro.
func _lado_da_queda() -> int:
	return 0 if bola.ponto_previsto.z > 0.0 else 1


func _distancia_no_chao(atleta: Node3D, ponto: Vector3) -> float:
	if atleta == null:
		return INF
	return Vector2(atleta.position.x - ponto.x, atleta.position.z - ponto.z).length()


# --- Fim do rally ---

func _ao_bola_tocar_chao(posicao: Vector3) -> void:
	if estado != Estado.RALLY:
		return
	var dentro := absf(posicao.x) <= LARGURA / 2.0 + Bola.RAIO \
		and absf(posicao.z) <= COMPRIMENTO / 2.0 + Bola.RAIO
	if dentro:
		# Caiu do lado do time 0 (z positivo): ponto do time 1, e vice-versa.
		var quem := 1 if posicao.z > 0.0 else 0
		OndaNoChao.mostrar(self, posicao, _cor_do_time(quem))
		Estouro.mostrar(self, Vector3(posicao.x, 0.1, posicao.z), _cor_do_time(quem), 0.6)
		impacto.ponto()
		sons.tocar("quique")
		_encerrar_rally(quem, "dentro")
	else:
		sons.tocar("quique", 0.7)
		_encerrar_rally(1 - ultimo_toque, "fora")


func _encerrar_rally(vencedor: int, motivo: String) -> void:
	if estado != Estado.SAQUE and estado != Estado.RALLY:
		return
	estado = Estado.PONTO
	var saque_do_rally_em_jogo := saque_em_jogo
	saque_em_jogo = false
	marcador.esconder()
	_mostrar_marcas_de_ataque(-1)
	_limpar_mensagens()
	var nome := str(times_em_jogo[vencedor]["nome"])
	var explicacao := _explicacao_do_ponto(motivo)
	_mostrar_mensagem("Ponto %s!%s" % [nome, " (%s)" % explicacao if explicacao != "" else ""])
	# Apito do juiz e a torcida (mais forte nos pontos bonitos).
	sons.tocar("apito")
	var torcida := 0.6
	if motivo == "dentro" and saque_do_rally_em_jogo and vencedor == placar.quem_saca:
		faixa.mostrar("ACE!", nome, _cor_do_time(vencedor), vencedor)
		torcida = 1.0
	elif motivo == "dentro" and vencedor == _ponto_de_bloqueio:
		faixa.mostrar("BLOQUEIO!", nome, _cor_do_time(vencedor), vencedor)
		torcida = 1.0
	elif motivo == "dentro":
		faixa.mostrar("PONTO!", nome, _cor_do_time(vencedor), vencedor)
		torcida = 0.8
	else:
		faixa.mostrar("PONTO!", "%s  ·  %s" % [nome, explicacao], _cor_do_time(vencedor), vencedor)
	sons.tocar("torcida", torcida)
	# A faixa já diz quem pontuou e o motivo: a caixa do meio fica escondida
	# (o texto continua lá, pros testes e pro robô).
	caixa_da_mensagem.visible = false
	_animar_fim_do_ponto(vencedor)
	# Se foi o último ponto, o placar chama _ao_encerrar_partida aqui dentro.
	placar.marcar_ponto(vencedor)
	temporizador_do_ponto.start()


## Segundos desde que o último ponto foi marcado (no relógio da partida).
func _tempo_desde_o_ponto() -> float:
	return _relogio - _relogio_do_ponto


## Quem fez o ponto comemora e quem perdeu reage. Cada atleta faz uma
## animação, e ela muda de um ponto pro outro (sem usar o sorteio, pra não
## mudar as partidas com semente).
func _animar_fim_do_ponto(vencedor: int) -> void:
	_pontos_animados += 1
	_relogio_do_ponto = _relogio
	for i in 6:
		var comemoracoes: Array = Animador.COMEMORACOES
		var reacoes: Array = Animador.REACOES_AO_PONTO_PERDIDO
		_animar(atletas[vencedor][i], comemoracoes[(i + _pontos_animados) % comemoracoes.size()])
		_animar(atletas[1 - vencedor][i], reacoes[(i + _pontos_animados) % reacoes.size()])


## O que aparece pro jogador como motivo do ponto. Bola dentro não precisa
## de explicação; "fora" vira "bola fora"; as faltas ficam como são.
func _explicacao_do_ponto(motivo: String) -> String:
	match motivo:
		"dentro":
			return ""
		"fora":
			return "bola fora"
	return motivo


## Depois da pausa do ponto: próximo saque, ou a tela de fim de jogo.
func _depois_do_ponto() -> void:
	if estado == Estado.FIM:
		var vencedor: int = placar.vencedor
		menu.abrir_fim_de_jogo(
			"%s VENCEU!" % str(times_em_jogo[vencedor]["nome"]).to_upper(),
			"%d sets a %d" % [placar.sets[vencedor], placar.sets[1 - vencedor]]
		)
	elif estado == Estado.PONTO:
		pontos_jogados += 1
		if modo_caos and Cartas.deve_escolher(dados_das_cartas, pontos_jogados):
			_abrir_escolha_de_cartas(_preparar_saque)
		else:
			_preparar_saque()


# --- Modo Caos ---

## A tela de escolha está aberta? (Os botões do jogo ficam parados.)
func _escolhendo_cartas() -> bool:
	return escolha_de_cartas != null and is_instance_valid(escolha_de_cartas)


## Sorteia as cartas de cada jogador e abre a tela de escolha. Quando os dois
## escolhem, as cartas valem e "depois" é chamado (por exemplo, preparar o saque).
func _abrir_escolha_de_cartas(depois: Callable) -> void:
	var opcoes: Array = []
	var nomes_das_maos: Array = []
	for time in 2:
		var ids := Cartas.sortear(dados_das_cartas, cartas_dos_times[time], sorteio,
			Cartas.cartas_por_escolha(dados_das_cartas), ultima_carta[1 - time])
		var cartas: Array = []
		for id in ids:
			cartas.append(Cartas.por_id(dados_das_cartas, id))
		opcoes.append(cartas)
		nomes_das_maos.append(_nomes_das_cartas(time))
	# Sem carta nova pra oferecer (já pegaram todas): segue o jogo.
	if (opcoes[0] as Array).is_empty() or (opcoes[1] as Array).is_empty():
		if depois.is_valid():
			depois.call()
		return
	# Tira a mensagem do ponto da frente da tela de escolha.
	_limpar_mensagens()
	escolha_de_cartas = EscolhaDeCartas.new()
	escolha_de_cartas.name = "EscolhaDeCartas"
	escolha_de_cartas.sorteio = sorteio
	add_child(escolha_de_cartas)
	escolha_de_cartas.configurar(
		opcoes,
		[times_em_jogo[0]["nome"], times_em_jogo[1]["nome"]],
		[_cor_do_time(0), _cor_do_time(1)],
		cartas_dos_times, nomes_das_maos,
		Cartas.tempo_limite(dados_das_cartas),
		[str(times_em_jogo[0]["id"]), str(times_em_jogo[1]["id"])],
		times_em_jogo, trocas_restantes.duplicate(), _trocar_cartas)
	escolha_de_cartas.terminou.connect(func(escolhas: Array) -> void:
		escolha_de_cartas = null
		_ao_escolher_cartas(escolhas)
		if depois.is_valid():
			depois.call())


## Botão TROCAR da tela de cartas: gasta uma troca do time e sorteia outras
## cartas (tenta não repetir as que estavam na tela). Sem troca, devolve [].
func _trocar_cartas(time: int, atuais: Array) -> Array:
	if trocas_restantes[time] <= 0:
		return []
	var quantidade := Cartas.cartas_por_escolha(dados_das_cartas)
	var ids: Array = []
	for tentativa in 8:
		ids = Cartas.sortear(dados_das_cartas, cartas_dos_times[time], sorteio,
			quantidade, ultima_carta[1 - time])
		var repetidas := 0
		for id in ids:
			if atuais.has(id):
				repetidas += 1
		if repetidas < ids.size():
			break
	if ids.is_empty():
		return []
	trocas_restantes[time] -= 1
	var cartas: Array = []
	for id in ids:
		cartas.append(Cartas.por_id(dados_das_cartas, id))
	return cartas


## As duas cartas escolhidas entram na mão de cada time. As duas escolhas
## valem ao mesmo tempo (a Troca de Lugar copia a carta que o outro já tinha).
func _ao_escolher_cartas(escolhas: Array) -> void:
	var anteriores: Array = ultima_carta.duplicate()
	for time in 2:
		var id := str(escolhas[time])
		var mao_antes: Array = cartas_dos_times[time]
		cartas_dos_times[time] = Cartas.adicionar(mao_antes, id, str(anteriores[1 - time]))
		# A última carta é a que entrou na mão (a cópia, no caso da Troca de Lugar).
		if cartas_dos_times[time].size() > mao_antes.size():
			ultima_carta[time] = cartas_dos_times[time][cartas_dos_times[time].size() - 1]
	_aplicar_cartas()


## Passa o efeito das cartas de cada time pro jogo (time["modificadores"]).
func _aplicar_cartas() -> void:
	for time in 2:
		times_em_jogo[time]["modificadores"] = Cartas.modificadores(dados_das_cartas, cartas_dos_times[time])
		if rotulos_de_cartas.size() > time:
			var nomes := _nomes_das_cartas(time)
			var texto := ", ".join(PackedStringArray(nomes)) if not nomes.is_empty() else ""
			var bonus := Cartas.bonus_ativos(dados_das_cartas, cartas_dos_times[time])
			if not bonus.is_empty():
				texto += "\n" + " · ".join(PackedStringArray(bonus))
			rotulos_de_cartas[time].text = texto


func _nomes_das_cartas(time: int) -> Array:
	var nomes: Array = []
	for id in cartas_dos_times[time]:
		nomes.append(str(Cartas.por_id(dados_das_cartas, id).get("nome", id)))
	return nomes


func _preparar_saque() -> void:
	estado = Estado.SAQUE
	ultimo_toque = -1
	_ponto_de_bloqueio = -1
	qualidade_do_passe = [Qualidade.BOM, Qualidade.BOM]
	saque_em_jogo = false
	tempo_no_saque = 0.0
	carga_do_saque = -1.0
	_segundos_mostrados = -1
	pedidos = [{}, {}]
	toques.reiniciar()
	marcador.esconder()
	_mostrar_marcas_de_ataque(-1)
	_colocar_na_formacao()
	for lado in 2:
		for atleta in atletas[lado]:
			var animador = _animador_de(atleta)
			if animador:
				animador.soltar()
	# Depois de um set, o placar zera aqui (no fim do set ele mostra o resultado).
	_atualizar_placar()

	# Quem saca é o atleta na posição 1, atrás da linha de fundo.
	var time: int = placar.quem_saca
	var sacador: Node3D = atletas[time][rodizios[time].atleta_na(1)]
	sacador.position = _no_mundo(time, POSICAO_DO_SACADOR)
	controlados[time] = sacador
	# O outro time começa controlando quem passa: o do meio do fundo
	# (ou o da esquerda do fundo, se o do meio for o levantador).
	var outro := 1 - time
	var passador: int = rodizios[outro].atleta_na(6)
	if passador == levantadores[outro]:
		passador = rodizios[outro].atleta_na(5)
	controlados[outro] = atletas[outro][passador]

	_mostrar_mensagem("")
	_mostrar_mensagem("Saque: segure e solte Ataque", time)
	_mostrar_mensagem("Recepção: corra até o anel e aperte Passe", outro)


func _ao_encerrar_partida(vencedor: int) -> void:
	estado = Estado.FIM
	marcador.esconder()
	_mostrar_marcas_de_ataque(-1)
	# A tela de fim de jogo já diz quem venceu.
	_limpar_mensagens()
	caixa_da_pausa.visible = false
	faixa.mostrar("JOGO!", "%s venceu" % times_em_jogo[vencedor]["nome"], _cor_do_time(vencedor), vencedor)
	sons.tocar("torcida", 1.3)
	for atleta in atletas[vencedor]:
		_animar(atleta, "comemoracao_torcida")
	for atleta in atletas[1 - vencedor]:
		_animar(atleta, "ponto_perdido_frustrado")


func _conectar_placar() -> void:
	placar.sortear_primeiro_saque()
	placar.ponto_marcado.connect(func(time: int) -> void:
		_atualizar_placar()
		placar_visual.comemorar(time))
	placar.rodizio.connect(func(time: int) -> void: rodizios[time].girar())
	placar.set_encerrado.connect(_ao_encerrar_set)
	placar.partida_encerrada.connect(_ao_encerrar_partida)
	_atualizar_placar()


## Fim de um set. Se foi o último, _ao_encerrar_partida troca a mensagem logo depois.
func _ao_encerrar_set(vencedor: int) -> void:
	# Cada set começa com a escalação do começo.
	for rodizio in rodizios:
		rodizio.reiniciar()
	_atualizar_placar()
	faixa.mostrar("SET!", "%s  %d x %d" % [
		str(times_em_jogo[vencedor]["nome"]), placar.pontos[vencedor], placar.pontos[1 - vencedor],
	], _cor_do_time(vencedor), vencedor)
	_mostrar_mensagem("Set %d: %s venceu! (%d x %d)" % [
		placar.set_atual, times_em_jogo[vencedor]["nome"],
		placar.pontos[vencedor], placar.pontos[1 - vencedor],
	])
	caixa_da_mensagem.visible = false


func _atualizar_placar() -> void:
	placar_visual.atualizar(placar.pontos, placar.sets, placar.set_atual, placar.quem_saca, placar.aviso())


## Cor do time no placar e nos efeitos: a do menu (ou a do uniforme reserva,
## quando os dois escolheram o mesmo time).
func _cor_do_time(time: int) -> Color:
	var dados: Dictionary = times_em_jogo[time]
	if time == 1 and dados.get("id", "") == times_em_jogo[0].get("id", "-"):
		return Color.from_string(str(dados["cores"][0]), Color.WHITE)
	return Color.from_string(str(dados.get("cor_do_menu", dados["cores"][0])), Color.WHITE)


## Uma linha com o placar, pro menu de pausa.
func _resumo_do_placar() -> String:
	return "%s %d x %d %s  ·  Set %d  ·  Sets %d x %d" % [
		times_em_jogo[0]["nome"], placar.pontos[0], placar.pontos[1], times_em_jogo[1]["nome"],
		placar.set_atual, placar.sets[0], placar.sets[1],
	]


# --- Ajudantes ---

## 1 pro time do Jogador 1 (lado da câmera, z positivo), -1 pro outro.
func _lado(time: int) -> float:
	return 1.0 if time == 0 else -1.0


## De que lado está a câmera que esse jogador olha: 1 = atrás do time 0,
## -1 = atrás do time 1 (só com tela dividida).
func _lado_da_camera(time: int) -> float:
	return _lado(time) if tela_dividida else 1.0


## Direção apertada pelo jogador, convertida pro mundo (x, z).
## "Cima" na tela é sempre "pra frente" na câmera daquele jogador.
func _direcao_no_mundo(time: int) -> Vector2:
	var direcao: Vector2 = entradas[time].direcao
	return direcao * _lado_da_camera(time)


## Converte coordenadas "do time" (x = lado, y = distância da rede) pro mundo.
## Os dois times olham pra rede, então o time de lá fica espelhado.
func _no_mundo(time: int, local: Vector2) -> Vector3:
	var lado := _lado(time)
	return Vector3(local.x * lado, 0.0, local.y * lado)


## O contrário de _no_mundo: ponto do mundo em coordenadas do "time".
func _no_time(time: int, mundo: Vector3) -> Vector2:
	var lado := _lado(time)
	return Vector2(mundo.x * lado, mundo.z * lado)


## Ponto aleatório dentro da quadra do "time", entre z_min e z_max metros da rede.
func _ponto_aleatorio_no_lado(time: int, z_min: float, z_max: float) -> Vector3:
	var x := sorteio.randf_range(-LARGURA / 2.0 + 0.8, LARGURA / 2.0 - 0.8)
	var z := sorteio.randf_range(z_min, z_max) * _lado(time)
	return Vector3(x, 0.0, z)


## Atleta do "time" mais perto do "ponto" (no chão), menos "excluir".
## "filtro" (opcional): função(atleta) -> bool que diz quem pode ser escolhido.
func _mais_perto(time: int, ponto: Vector3, excluir: Node3D = null, filtro := Callable()) -> Node3D:
	var melhor: Node3D = null
	var menor := INF
	for atleta in atletas[time]:
		if atleta == excluir:
			continue
		if filtro.is_valid() and not filtro.call(atleta):
			continue
		var distancia := _distancia_no_chao(atleta, ponto)
		if distancia < menor:
			menor = distancia
			melhor = atleta
	return melhor


## Coloca todo mundo na formação do saque (na ordem do rodízio), no chão.
func _colocar_na_formacao() -> void:
	for time in 2:
		var recebendo: bool = time != placar.quem_saca
		for i in 6:
			var atleta: Node3D = atletas[time][i]
			var posicao: int = rodizios[time].posicao_de(i)
			atleta.position = _no_mundo(time, Formacao.lugar_no_saque(posicao, i == levantadores[time], recebendo))
			atleta.set_meta("tempo_do_pulo", -1.0)


## Mostra as setas de ataque no chão do "time" (ou esconde todas com -1).
func _mostrar_marcas_de_ataque(time: int) -> void:
	for i in 2:
		marcas_de_ataque[i].visible = i == time


## Lê os times e o estádio escolhidos nos menus.
func _carregar_escolhas() -> void:
	var times := Dados.times()
	times_em_jogo = [
		Dados.por_id(times, str(Configuracao.times[0])),
		Dados.por_id(times, str(Configuracao.times[1])),
	]
	# Mesmo time dos dois lados: o Jogador 2 joga com o uniforme reserva.
	if times_em_jogo[0]["id"] == times_em_jogo[1]["id"]:
		times_em_jogo[1] = _com_uniforme_reserva(times_em_jogo[1])
	estadio = Dados.por_id(Dados.estadios(), Configuracao.estadio)
	if int(Configuracao.semente) >= 0:
		sorteio.seed = int(Configuracao.semente)
	else:
		sorteio.randomize()
	placar.sorteio = func() -> int: return sorteio.randi_range(0, 1)
	modo_caos = Configuracao.modo == "caos"
	# Contra o computador, a tela é toda do Jogador 1.
	if Configuracao.contra_computador:
		tela_dividida = false
	if modo_caos:
		trocas_restantes = [Cartas.trocas_por_partida(Dados.cartas()), Cartas.trocas_por_partida(Dados.cartas())]
		dados_das_cartas = Dados.cartas()


## O "jogador" (1 ou 2) é jogado pelo computador?
func _jogador_e_o_computador(jogador: int) -> bool:
	if Configuracao.computador_nos_dois:
		return true
	return Configuracao.contra_computador and jogador == 2


## Uniforme reserva: a regra fica em Dados (a seleção de times usa a mesma).
func _com_uniforme_reserva(time: Dictionary) -> Dictionary:
	return Dados.com_uniforme_reserva(time)


## Cor do estádio (veja dados/estadios.json), ou "padrao" se faltar.
func _cor_do_estadio(chave: String, padrao: Color) -> Color:
	return Dados.cor(estadio.get("cores", {}), chave, padrao)


# --- Construção da cena ---

## Quadra, rede, árbitros e o ginásio ou arena em volta (scripts/cenario/).
func _criar_cenario() -> void:
	cenario = Cenario.new()
	cenario.name = "Cenario"
	add_child(cenario)
	cenario.montar(estadio, times_em_jogo, {
		"largura": LARGURA, "comprimento": COMPRIMENTO, "altura_da_rede": ALTURA_REDE,
		"zona_livre": Vector2(LARGURA_ZONA_LIVRE, COMPRIMENTO_ZONA_LIVRE),
	})


func _criar_atletas(time: int) -> void:
	var dados_time: Dictionary = times_em_jogo[time]
	var id_time := str(dados_time["id"])
	var elenco := Dados.elenco(id_time)
	var cor_detalhe := Color.from_string(str(dados_time["cores"][1]), Color.WHITE)
	# Escalação pela função de cada um (levantador oposto ao oposto, etc.).
	var ordem := Escalacao.ordem_inicial(elenco)
	rodizios[time].comecar_com(ordem)
	funcoes[time] = Escalacao.funcoes_por_atleta(ordem)
	levantadores[time] = ordem[0]

	for i in 6:
		var atleta := Node3D.new()
		atleta.name = "Time%d_%s_%d" % [time + 1, id_time, i + 1]
		atleta.position = _no_mundo(time, Formacao.lugar_no_saque(rodizios[time].posicao_de(i), false, false))
		atleta.set_meta("tempo_do_pulo", -1.0)
		var dados_atleta: Dictionary = elenco[i] if i < elenco.size() else {}
		atleta.set_meta("dados", dados_atleta)

		var personagem := Dados.carregar_personagem(dados_time, dados_atleta)
		if personagem:
			atleta.add_child(personagem)
			var animador := Animador.new()
			animador.name = "Animador"
			atleta.add_child(animador)
			if animador.preparar(personagem, GIRO_DO_PERSONAGEM if time == 0 else GIRO_DO_PERSONAGEM + PI):
				atleta.set_meta("animador", animador)
		else:
			_criar_capsula(atleta, _cores_do_atleta(dados_time, dados_atleta))
		add_child(atleta)
		atletas[time].append(atleta)

	# Anel no chão que mostra quem está sendo controlado.
	var anel := AnelDoControlado.new()
	anel.name = "AnelDoControlado%d" % time
	anel.cor = cor_detalhe
	add_child(anel)
	aneis_do_controlado[time] = anel
	# Seta em cima da cabeça, na cor forte do time (a do menu). Com os dois
	# jogadores no mesmo time, o Jogador 2 usa a cor de detalhe do uniforme
	# reserva, pra uma seta não ser igual à outra.
	var seta := SetaDoControlado.new()
	seta.name = "SetaDoControlado%d" % time
	var mesmo_time: bool = time == 1 and str(times_em_jogo[0]["id"]) == id_time
	seta.cor = cor_detalhe if mesmo_time \
		else Color.from_string(str(dados_time.get("cor_do_menu", dados_time["cores"][1])), cor_detalhe)
	add_child(seta)
	setas_do_controlado[time] = seta
	controlados[time] = atletas[time][rodizios[time].atleta_na(6)]


## O personagem do atleta vem de Dados.carregar_personagem: .vrm do VRoid se
## existir, senão o gerado por código (dados/aparencia.json), senão cápsula.


## Cores [camisa, detalhe] do atleta: o uniforme do time (não tem líbero).
func _cores_do_atleta(dados_time: Dictionary, _dados_atleta: Dictionary) -> Array:
	var cores: Array = dados_time["cores"]
	return [
		Color.from_string(str(cores[0]), Color.GRAY),
		Color.from_string(str(cores[1]), Color.WHITE),
	]


## Cápsula de teste (1,8 m) com uma faixa no peito na cor de detalhe.
func _criar_capsula(atleta: Node3D, cores: Array) -> void:
	var corpo := MeshInstance3D.new()
	var capsula := CapsuleMesh.new()
	capsula.radius = 0.35
	capsula.height = 1.8
	corpo.mesh = capsula
	corpo.material_override = _material_do_atleta(cores[0], 0.03)
	corpo.position.y = 0.9
	atleta.add_child(corpo)

	var faixa := MeshInstance3D.new()
	var anel_do_peito := CylinderMesh.new()
	anel_do_peito.top_radius = 0.36
	anel_do_peito.bottom_radius = 0.36
	anel_do_peito.height = 0.12
	faixa.mesh = anel_do_peito
	faixa.material_override = _material_do_atleta(cores[1], 0.0)
	faixa.position.y = 1.15
	atleta.add_child(faixa)


## Cria as marcas no chão (círculo + seta + nome) dos 4 ataques do time.
func _criar_marcas_de_ataque(time: int) -> void:
	var grupo := Node3D.new()
	grupo.name = "MarcasDeAtaque%d" % time
	grupo.visible = false
	add_child(grupo)
	marcas_de_ataque[time] = grupo

	for ataque in ATAQUES:
		alvos_de_ataque[time].append(_no_mundo(time, ataque["posicao"]))
	var centro := EscolhaAtaque.centro_de(alvos_de_ataque[time])

	for i in ATAQUES.size():
		var alvo: Vector3 = alvos_de_ataque[time][i]

		var circulo := MeshInstance3D.new()
		var disco := CylinderMesh.new()
		disco.top_radius = 0.55
		disco.bottom_radius = 0.55
		disco.height = 0.01
		circulo.mesh = disco
		var material := _material(Color(1, 1, 1, 0.35))
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		circulo.material_override = material
		circulo.position = Vector3(alvo.x, 0.025, alvo.z)
		grupo.add_child(circulo)

		var texto := Label3D.new()
		texto.text = "%s %s" % [EscolhaAtaque.seta_de(alvo, centro, _lado_da_camera(time)), ATAQUES[i]["nome"]]
		texto.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		texto.no_depth_test = true
		texto.font_size = 48
		texto.outline_size = 12
		texto.pixel_size = 0.01
		texto.position = Vector3(alvo.x, 0.6, alvo.z)
		grupo.add_child(texto)


func _criar_camera() -> void:
	if not tela_dividida:
		_adicionar_camera(self, 0)
		return

	# Duas metades da tela, cada uma com a própria câmera olhando o mesmo mundo.
	# Fica numa camada atrás da interface (placar e mensagens).
	var camada := CanvasLayer.new()
	camada.name = "TelaDividida"
	camada.layer = -1
	add_child(camada)
	for time in 2:
		var moldura := SubViewportContainer.new()
		moldura.name = "TelaJogador%d" % (time + 1)
		moldura.stretch = true
		moldura.anchor_left = 0.5 * time
		moldura.anchor_right = 0.5 * (time + 1)
		moldura.anchor_top = 0.0
		moldura.anchor_bottom = 1.0
		camada.add_child(moldura)

		var tela := SubViewport.new()
		tela.world_3d = get_viewport().find_world_3d()
		tela.msaa_3d = Viewport.MSAA_2X
		moldura.add_child(tela)
		_adicionar_camera(tela, time)


## Câmera alta atrás do time, olhando pra rede (e acompanhando a bola de leve).
func _adicionar_camera(onde: Node, time: int) -> void:
	var lado := _lado(time)
	var camera := CameraDaPartida.new()
	camera.name = "Camera%d" % time
	onde.add_child(camera)
	camera.preparar(
		Vector3(0.0, altura_camera, distancia_camera * lado),
		Vector3(0.0, 0.0, foco_da_camera * lado),
		abertura_da_camera
	)
	camera.current = true
	# O fundo atrás do próprio time fica entre a câmera e a quadra: não desenha.
	camera.set_cull_mask_value(Cenario.CAMADA_ATRAS_DO_TIME[0 if lado > 0.0 else 1], false)
	if tela_dividida:
		# Esconde o anel de tempo do outro jogador.
		camera.set_cull_mask_value(CAMADA_DO_ANEL_DE_TEMPO[1 - time], false)
	elif _jogador_e_o_computador(2) and not _jogador_e_o_computador(1):
		# Contra o computador: o anel de tempo e a mira dele não aparecem.
		camera.set_cull_mask_value(CAMADA_DO_ANEL_DE_TEMPO[1], false)
	cameras.append(camera)


func _criar_interface() -> void:
	var camada := CanvasLayer.new()
	camada.name = "Interface"
	camada.layer = 1
	add_child(camada)

	if tela_dividida:
		# Linha separando as duas metades.
		var divisoria := ColorRect.new()
		divisoria.color = Color("#0F1620")
		divisoria.anchor_left = 0.5
		divisoria.anchor_right = 0.5
		divisoria.anchor_top = 0.0
		divisoria.anchor_bottom = 1.0
		divisoria.offset_left = -2.0
		divisoria.offset_right = 2.0
		camada.add_child(divisoria)

	# Placar em cima, no meio (em cima da divisória na tela dividida).
	var topo := CenterContainer.new()
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topo.position = Vector2(0.0, 10.0)
	topo.size = Vector2(1600.0, 100.0)
	camada.add_child(topo)
	placar_visual = PlacarVisual.new()
	topo.add_child(placar_visual)
	var ids_dos_times := [str(times_em_jogo[0]["id"]), str(times_em_jogo[1]["id"])]
	placar_visual.configurar(
		[times_em_jogo[0]["nome"], times_em_jogo[1]["nome"]],
		[_cor_do_time(0), _cor_do_time(1)], ids_dos_times)

	# Mensagem no meio, em cima. O CenterContainer mantém a caixa centralizada
	# e do tamanho do texto.
	var centro := CenterContainer.new()
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.position = Vector2(0.0, 118.0)
	centro.size = Vector2(1600.0, 56.0)
	camada.add_child(centro)
	caixa_da_mensagem = _caixa_da_interface()
	centro.add_child(caixa_da_mensagem)
	rotulo_mensagem = _rotulo_da_interface(32, true)
	caixa_da_mensagem.add_child(rotulo_mensagem)

	# Mensagem de cada time, embaixo da mensagem geral, na metade dele
	# (sem tela dividida, as duas ficam lado a lado na mesma tela).
	for time in 2:
		var centro_do_time := CenterContainer.new()
		centro_do_time.mouse_filter = Control.MOUSE_FILTER_IGNORE
		centro_do_time.position = Vector2(800.0 * time, 182.0)
		centro_do_time.size = Vector2(800.0, 48.0)
		camada.add_child(centro_do_time)
		var caixa := _caixa_da_interface()
		caixa.visible = false
		centro_do_time.add_child(caixa)
		var rotulo := _rotulo_da_interface(24, true)
		caixa.add_child(rotulo)
		caixas_do_time.append(caixa)
		rotulos_do_time.append(rotulo)

		# Barra de força do saque, embaixo, na metade do time.
		var centro_da_barra := CenterContainer.new()
		centro_da_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
		centro_da_barra.position = Vector2(800.0 * time, 760.0)
		centro_da_barra.size = Vector2(800.0, 70.0)
		camada.add_child(centro_da_barra)
		var barra := BarraDeForca.new()
		barra.name = "BarraDeForca%d" % time
		centro_da_barra.add_child(barra)
		barras_de_forca[time] = barra

		# Modo Caos: as cartas do time, no canto da metade dele.
		if modo_caos:
			var cartas_do_time := _rotulo_da_interface(18, false)
			cartas_do_time.position = Vector2(20.0 + 800.0 * time, 700.0)
			cartas_do_time.size = Vector2(360.0, 50.0)
			cartas_do_time.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			camada.add_child(cartas_do_time)
			rotulos_de_cartas.append(cartas_do_time)

	faixa = FaixaDePonto.new()
	camada.add_child(faixa)
	faixa.configurar(ids_dos_times)

	# Cortina preta por cima de tudo (até da pausa), fechada até a cena abrir.
	var camada_da_cortina := CanvasLayer.new()
	camada_da_cortina.name = "CamadaDaCortina"
	camada_da_cortina.layer = 20
	add_child(camada_da_cortina)
	cortina = Cortina.nova(camada_da_cortina)

	# Comandos de cada jogador embaixo da metade dele (ou só do J1, sem tela dividida).
	var ajudas := [
		"J1 teclado: WASD move · J passe · K saque/cortada · I flutuante · L bloqueio (frente triplo, trás só 1) · Espaço mergulho · I segurado ao levantar = rápido · K no 2º toque = bola de segunda",
		"J2 teclado: setas movem · 1 passe · 2 saque/cortada · 5 flutuante · 3 bloqueio (frente triplo, trás só 1) · 0 mergulho (numérico)",
	]
	for jogador in (2 if tela_dividida else 1):
		var ajuda := _rotulo_da_interface(16, false)
		ajuda.text = ajudas[jogador] + "\nControle: A passe · X saque/cortada · RB flutuante · Y bloqueio (frente triplo, trás só 1) · B mergulho · Passe no pulo = largada · RB segurado ao levantar = rápido · X no 2º toque = bola de segunda"
		ajuda.position = Vector2(20.0 + jogador * 800.0, 848.0)
		camada.add_child(ajuda)

	# Lembrete da pausa no canto direito, crescendo pra esquerda.
	caixa_da_pausa = _caixa_da_interface()
	caixa_da_pausa.anchor_left = 1.0
	caixa_da_pausa.anchor_right = 1.0
	caixa_da_pausa.offset_left = -18.0
	caixa_da_pausa.offset_right = -18.0
	caixa_da_pausa.offset_top = 16.0
	caixa_da_pausa.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	camada.add_child(caixa_da_pausa)
	var dica_da_pausa := _rotulo_da_interface(18, true)
	dica_da_pausa.text = "Esc ou Start: pausa"
	caixa_da_pausa.add_child(dica_da_pausa)


## Mostra uma mensagem no meio da tela (time = -1) ou na metade de um time.
## Texto vazio esconde a caixa.
func _mostrar_mensagem(texto: String, time := -1) -> void:
	if time < 0:
		rotulo_mensagem.text = texto
		caixa_da_mensagem.visible = texto != ""
		return
	rotulos_do_time[time].text = texto
	caixas_do_time[time].visible = texto != ""


## Esconde a mensagem do meio e as dos dois times.
func _limpar_mensagens() -> void:
	_mostrar_mensagem("")
	for time in 2:
		_mostrar_mensagem("", time)


## Caixa escura e inclinada (como as dos menus) atrás dos textos da partida.
func _caixa_da_interface() -> PanelContainer:
	var caixa := PanelContainer.new()
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_theme_stylebox_override("panel",
		Estilo.caixa(Color(0.06, 0.07, 0.09, 0.72), Estilo.INCLINACAO, 22.0, 4.0))
	return caixa


## Texto da interface com contorno escuro, pra ler bem em cima da quadra.
func _rotulo_da_interface(tamanho: int, titulo: bool) -> Label:
	return Estilo.rotulo_com_contorno(tamanho, titulo)


func _caixa(tamanho: Vector3, posicao: Vector3, cor: Color) -> MeshInstance3D:
	var caixa := MeshInstance3D.new()
	var malha := BoxMesh.new()
	malha.size = tamanho
	caixa.mesh = malha
	caixa.material_override = _material(cor)
	caixa.position = posicao
	add_child(caixa)
	return caixa


## Material dos atletas: anime (com contorno) ou comum, conforme "visual_anime".
func _material_do_atleta(cor: Color, contorno: float) -> Material:
	if visual_anime:
		return VisualAnime.material(cor, contorno)
	return _material(cor)


func _material(cor: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = cor
	return material
