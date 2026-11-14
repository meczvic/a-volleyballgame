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
## - Não existe falta de toque na rede: quem está colado nela é afastado. A bola tem que passar entre as antenas.
## - Sem líbero: 6 atletas por time.
##
## Os times e o estádio vêm da seleção de times (autoload Configuracao).
## Rodando esta cena direto (F6), vale o padrão: Karasuno x Nekoma no Ginásio Japonês.
## Atleta sem personagem do VRoid aparece como cápsula. Com personagem, ele
## corre, para e faz cada lance (scripts/visual/animador.gd).

const Placar := preload("res://scripts/regras/placar.gd")
const Ajustes := preload("res://scripts/comum/ajustes.gd")
const Toques := preload("res://scripts/regras/toques.gd")
const Rodizio := preload("res://scripts/regras/rodizio.gd")
const Escalacao := preload("res://scripts/regras/escalacao.gd")
const Formacao := preload("res://scripts/regras/formacao.gd")
const EscolhaAtaque := preload("res://scripts/regras/escolha_ataque.gd")
const JeitosDeAtacar := preload("res://scripts/regras/jeitos_de_atacar.gd")
const JeitosDeDefender := preload("res://scripts/regras/jeitos_de_defender.gd")
const EntradaLocal := preload("res://scripts/entrada/entrada_local.gd")
const EntradaDoComputador := preload("res://scripts/entrada/entrada_do_computador.gd")
const EntradaPelaRede := preload("res://scripts/entrada/entrada_pela_rede.gd")
const EntradaGravada := preload("res://scripts/entrada/entrada_gravada.gd")
const OnlineNaPartida := preload("res://scripts/partida/online_na_partida.gd")
const Bola := preload("res://scripts/partida/bola.gd")
const MarcadorQueda := preload("res://scripts/partida/marcador_queda.gd")
const VisualAnime := preload("res://scripts/visual/visual_anime.gd")
const Dados := preload("res://scripts/comum/dados.gd")
const MenuDePausa := preload("res://scripts/menus/menu_de_pausa.gd")
const Estilo := preload("res://scripts/menus/estilo.gd")
const Lance := preload("res://scripts/regras/lance.gd")
const InterfaceDaPartida := preload("res://scripts/partida/interface_da_partida.gd")
const LancesDaPartida := preload("res://scripts/partida/lances_da_partida.gd")
const BloqueioNaPartida := preload("res://scripts/partida/bloqueio_na_partida.gd")
const IaDosAtletas := preload("res://scripts/partida/ia_dos_atletas.gd")
const CartasDaPartida := preload("res://scripts/partida/cartas_da_partida.gd")
const MontagemDaPartida := preload("res://scripts/partida/montagem_da_partida.gd")
const Animador := preload("res://scripts/visual/animador.gd")
const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")
const Trajetoria := preload("res://scripts/regras/trajetoria.gd")
const AnelDeTempo := preload("res://scripts/partida/anel_de_tempo.gd")
const AvisoDeToque := preload("res://scripts/partida/aviso_de_toque.gd")
const Impacto := preload("res://scripts/visual/impacto.gd")
const VelocidadeDaBola := preload("res://scripts/regras/velocidade_da_bola.gd")
const Rastro := preload("res://scripts/visual/rastro.gd")
const Mira := preload("res://scripts/regras/mira.gd")
const Atributos := preload("res://scripts/regras/atributos.gd")
const MiraVisual := preload("res://scripts/partida/mira_visual.gd")
const Cenario := preload("res://scripts/cenario/cenario.gd")
const OndaNoChao := preload("res://scripts/visual/onda_no_chao.gd")
const AnelDoControlado := preload("res://scripts/partida/anel_do_controlado.gd")
const CameraDaPartida := preload("res://scripts/partida/camera_da_partida.gd")
const Energia := preload("res://scripts/regras/energia.gd")
const Cartas := preload("res://scripts/regras/cartas.gd")
const EscolhaDeCartas := preload("res://scripts/partida/escolha_de_cartas.gd")
const Sons := preload("res://scripts/audio/sons.gd")
const Estouro := preload("res://scripts/visual/estouro.gd")
const SetaDoControlado := preload("res://scripts/partida/seta_do_controlado.gd")
const Qualidade := TempoDoToque.Qualidade

const EstadoDaPartida := preload("res://scripts/regras/estado_da_partida.gd")
## Estados da partida e as trocas que valem (scripts/regras/estado_da_partida.gd).
const Estado := EstadoDaPartida.Estado

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
## Cortada segurada (pedido do Victor, 13/11/2026): apertar o ataque pula.
## Soltar antes de SOLTAR_PARA_LARGADA s vira largada; segurar mais deixa a
## cortada mais forte (cheia se segurar até a batida), mais rápida e mais
## arriscada (a mira erra mais e, quase no talo, a bola pode sair).
const SOLTAR_PARA_LARGADA := 0.12
## Erro a mais (m) da cortada com força cheia; sem limite da quadra (pode sair).
const RISCO_DA_CORTADA_CHEIA := 1.2
const ALTURA_DO_PULO := 0.95
## Na cortada, o atleta sai do chão quando aperta Ataque e bate na bola no
## alto do pulo, com a mão. Esse é o tempo do botão até a batida (s).
const TEMPO_ATE_A_BATIDA := DURACAO_DO_PULO / 2.0
## Saque no tempo do movimento de verdade (auditoria 2, 13/11/2026). Antes a
## bola saía 0,3 s depois de soltar e a animação passava 4 vezes mais rápida.
## Viagem: corre CORRIDA_DO_SAQUE_VIAGEM s lançando a bola, pula (pulo de
## PULO_DO_SAQUE_VIAGEM s e ALTURA_DO_PULO_DO_SAQUE m) e bate no alto do pulo.
## Flutuante (em pé): lança a bola e bate BATIDA_DO_FLUTUANTE s depois.
## As alturas são onde a bola está na batida (m). Os tempos batem com a
## animação (TRECHOS do animador; teste_sincronia_dos_toques confere).
const ALTURA_DO_PULO_DO_SAQUE := 1.0
const CORRIDA_DO_SAQUE_VIAGEM := 0.62
const PULO_DO_SAQUE_VIAGEM := 0.86
const BATIDA_DO_FLUTUANTE := 0.6
const ALTURA_DA_BATIDA_DO_VIAGEM := 3.4
const ALTURA_DA_BATIDA_DO_FLUTUANTE := 2.5
## Quanto o sacador anda pra frente na corrida do viagem (sem pisar na linha).
const PASSADA_DO_SAQUE_VIAGEM := 1.2
## Até quantos metros da linha de fundo o quadril chega na corrida do viagem.
const MARGEM_DA_LINHA_NO_SAQUE := 0.9
## Quanto antes da bola chegar o atleta começa o preparo da manchete ou do
## levantamento (s). Só visual.
const PREPARO_ANTES_DA_BOLA := 0.35
## Na cortada o preparo (passada e braço armando) começa antes: é o tempo até
## a hora de apertar o ataque (s).
const PREPARO_ANTES_DA_CORTADA := 0.55
## Bola na mão do sacador, antes de lançar (m).
const ALTURA_DA_BOLA_NO_SAQUE := 1.25
## Quanto (m) o balanço do flutuante pode mudar o lugar onde a bola cai.
const BALANCO_DO_FLUTUANTE := 1.4
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
const POSICAO_DO_SACADOR := Vector2(2.5, 11.0)
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
const COR_DA_SUPER_CORTADA := Color("#FF5722")
## Texto do aviso "Cedo!" / "Tarde!" do toque ruim (pequeno; o Perfeito não escreve nada).
const TAMANHO_DO_AVISO_RUIM := 22

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
## Quanto a câmera segue a bola pro lado (veja camera_da_partida.gd).
var acompanhamento_da_camera := 0.22
## Números da câmera de TV (os exportados), guardados pra poder voltar pra ela.
var _camera_de_tv: Array = []
## Raio do desenho da bola na câmera escolhida (m).
var tamanho_da_bola: float = 0.22
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
## Levantamento segurado: quando o botão de passe foi apertado (relógio), ou
## -1. O toque sai quando solta; o tempo segurando escolhe a altura
## (TempoDoToque.altura_pelo_tempo_segurado), guardada em altura_pedida.
var levantamento_segurado: Array[float] = [-1.0, -1.0]
var altura_pedida: Array[float] = [-1.0, -1.0]
var entradas: Array = []
## Posições de ataque no mundo, por time (calculadas de ATAQUES).
var alvos_de_ataque: Array = [[], []]
## Marcas no chão com as setas de cada ataque, por time.
var marcas_de_ataque: Array[Node3D] = [null, null]

var bola
var marcador
var menu
## Tudo que aparece por cima da partida (interface_da_partida.gd).
var interface: Node
## O que muda no online, quando é dono ou convidado (online_na_partida.gd).
var online = OnlineNaPartida.new(self)
## Quadros de física desde que a partida abriu (o 1º é 1).
var quadro := 0
## Comandos de cada jogador com o número do quadro: [quadro, jogador, tipo, valor].
## Botão: valor true (apertou) ou false (soltou). Direção: tipo "dir", valor [x, y].
## Com a mesma semente, repetir isso (EntradaGravada) repete a partida igual.
var registro: Array = []
var _ultima_direcao: Array = [Vector2.ZERO, Vector2.ZERO]
## Sem tela dividida: de que lado fica a câmera (0 = time 1; o convidado do online usa 1).
var time_da_camera := 0
## Cada time vê pela própria câmera mesmo sem dividir a tela (online).
var lados_proprios := false
## Lances com a bola: passe, levantamento, cortada (do pulo à batida), largada e mergulho. (lances_da_partida.gd).
var lances = LancesDaPartida.new(self)
## Pulo e bloqueio: quem pula, que tipo de bloqueio sai (devolve, toca ou nada) e o que acontece quando a bola bate no bloqueio. (bloqueio_na_partida.gd).
var bloqueios = BloqueioNaPartida.new(self)
## Para onde cada atleta anda: o controlado pelo jogador e os companheiros (cobertura, defesa, bloqueio, formação). (ia_dos_atletas.gd).
var ia = IaDosAtletas.new(self)
## Modo Caos dentro da partida: abre a tela de escolha, troca cartas e aplica o efeito delas nos times. (cartas_da_partida.gd).
var caos = CartasDaPartida.new(self)
## Monta a cena da partida: cenário, atletas (personagem, animador, anel e seta), marcas dos ataques e câmeras. (montagem_da_partida.gd).
var montagem = MontagemDaPartida.new(self)
## Quadra, rede e ginásio em volta (scripts/cenario/cenario.gd).
var cenario: Node3D
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
## Medidor de energia de cada time e a barra dele na tela (Etapa 4).
var energias: Array = [Energia.new(), Energia.new()]
## Espera depois de cada ponto. É um nó (e não um "await") pra parar junto
## quando o jogo pausa e sumir junto quando a cena fecha.
var temporizador_do_ponto: Timer
## Câmeras (uma por jogador na tela dividida), pro tremor do impacto.
var cameras: Array[Camera3D] = []
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
## Saque viagem em andamento (o atleta pulou e a bola ainda não saiu da mão):
## { time, forca, alvo, tempo }. Vazio quando não há.
var saque_viagem := {}
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
## Saque Canhão em jogo: a recepção desse saque sai ruim.
var _saque_canhao := false
## Cortada Sinistra em jogo: a bola passa pelo bloqueio.
var _ataque_atravessa := false


func _ready() -> void:
	_carregar_escolhas()
	sons = Sons.new()
	sons.name = "Sons"
	add_child(sons)

	montagem._criar_cenario()
	for time in 2:
		montagem._criar_atletas(time)
		montagem._criar_marcas_de_ataque(time)
	montagem._criar_camera()
	_criar_interface()

	bola = Bola.new()
	bola.name = "Bola"
	bola.usar_visual_anime = visual_anime
	add_child(bola)
	bola.mudar_tamanho_do_desenho(tamanho_da_bola)
	# Os atletas acompanham a bola com a cabeça (nasceram antes dela).
	for time in 2:
		for atleta in atletas[time]:
			var animador = _animador_de(atleta)
			if animador:
				animador.olhar_para(bola)
	bola.verificar_bloqueio = bloqueios._tipo_do_bloqueio
	bola.tocou_chao.connect(_ao_bola_tocar_chao)
	bola.bloqueada.connect(bloqueios._ao_bola_ser_bloqueada)
	bola.tocou_bloqueio.connect(bloqueios._ao_bola_tocar_bloqueio)
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
	# Rastro mais fino que a bola, pra não parecer uma fila de bolas brancas.
	rastro.raio = tamanho_da_bola * 0.7
	add_child(rastro)

	marcador = MarcadorQueda.new()
	marcador.name = "MarcadorQueda"
	add_child(marcador)
	# Bateu na rede: a bola muda de rumo, então o anel muda de lugar e o
	# controle passa pra quem vai nela agora (se ela voltar pro lado de quem
	# tocou, não é ele de novo: seriam dois toques).
	bola.tocou_rede.connect(_ao_lancar_bola)
	bola.balancou.connect(func() -> void: marcador.mostrar_em(bola.ponto_previsto))
	bola.tocou_rede.connect(func() -> void: sons.tocar("rede"))

	for jogador in [1, 2]:
		var entrada
		var rede := get_node_or_null("/root/Rede")
		if str(Configuracao.repeticao) != "":
			entrada = EntradaGravada.new()
			entrada.jogador = jogador
			entrada.partida = self
			entrada.carregar(EntradaGravada.ler(str(Configuracao.repeticao)))
		elif jogador == 2 and rede != null and rede.e_dono():
			entrada = EntradaPelaRede.new()
			entrada.jogador = jogador
		elif _jogador_e_o_computador(jogador):
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
	interface.cortina.abrir()
	# Modo Caos: os dois escolhem a primeira carta antes do 1º saque.
	if modo_caos:
		caos._abrir_escolha_de_cartas(Callable())
	online.preparar()


func _physics_process(delta: float) -> void:
	quadro += 1
	_anotar_direcoes()
	_relogio += delta
	_gastar_relampago(delta)
	for time in 2:
		var controlado := controlados[time]
		var sacando: bool = estado == Estado.SAQUE and time == placar.quem_saca
		var em_jogo: bool = estado == Estado.SAQUE or estado == Estado.RALLY
		if not cortadas[time].is_empty():
			lances._atualizar_cortada(time, delta)
		elif em_jogo and not caos._escolhendo_cartas() and not sacando and not _esta_no_chao(controlado):
			ia._mover(controlado, time, _direcao_no_mundo(time), delta)
			if estado == Estado.SAQUE:
				ia._manter_na_ordem(time, controlado)
		_atender_pedido(time)
		_vigiar_levantamento_segurado(time)

		# Os outros 5 vão sozinhos pro lugar certo.
		if em_jogo:
			for i in 6:
				var atleta: Node3D = atletas[time][i]
				if atleta != controlado:
					ia._mover_ia(atleta, ia._alvo_da_ia(time, i), delta, _atributo(time, "velocidade"))
		elif estado == Estado.PONTO and _tempo_desde_o_ponto() >= COMEMORACAO_ANTES_DE_VOLTAR:
			# Depois de comemorar (ou reagir) um pouco, todo mundo anda até o
			# lugar do próximo saque enquanto o ponto é mostrado. Só visual: no
			# saque, _colocar_na_formacao põe cada um no lugar de qualquer jeito.
			for i in 6:
				ia._mover_ia(atletas[time][i], ia._alvo_depois_do_ponto(time, i), delta, PRESSA_DEPOIS_DO_PONTO)

		for atleta in atletas[time]:
			bloqueios._atualizar_pulo(atleta, delta)
		aneis_do_controlado[time].seguir(controlado)
		setas_do_controlado[time].seguir(controlado, delta)
		_atualizar_anel_de_tempo(time)
		_atualizar_mira(time, delta)
	_atualizar_poses_de_espera()

	# Antes do saque, a bola fica na mão de quem saca.
	online.depois_do_quadro()
	if estado == Estado.SAQUE:
		var sacador := controlados[placar.quem_saca]
		var frente := -_lado(placar.quem_saca) * 0.5
		if saque_viagem.is_empty():
			bola.segurar_em(sacador.position + Vector3(0.0, ALTURA_DA_BOLA_NO_SAQUE, frente))
		else:
			_atualizar_saque_viagem(delta, sacador, frente)
		if not caos._escolhendo_cartas():
			_contar_tempo_do_saque(delta)


# --- IA dos atletas sem controle ---

# --- Pulo e bloqueio ---

## Toca um lance no personagem do atleta (a cápsula não tem animação).
func _animar(atleta: Node3D, lance: String) -> void:
	online.ao_animar(atleta, lance)
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
	registro.append([quadro, jogador, tipo, true])
	if caos._escolhendo_cartas():
		return
	var time := jogador - 1
	_segurando_botao[time][tipo] = true
	match estado:
		Estado.SAQUE:
			# Segurar carrega a força; o saque sai quando solta (_ao_soltar_botao).
			if time == placar.quem_saca and carga_do_saque < 0.0 and saque_viagem.is_empty() \
					and (tipo == Lance.BOTAO_ATAQUE or tipo == Lance.BOTAO_FLUTUANTE):
				carga_do_saque = 0.0
				saque_flutuante = tipo == Lance.BOTAO_FLUTUANTE
				alvo_do_saque = Mira.ALVO_INICIAL
		Estado.RALLY:
			if tipo == Lance.BOTAO_PASSE:
				if not cortadas[time].is_empty():
					# Passe no ar, durante a cortada: vira largada.
					controlados[time].set_meta("largada", true)
				elif _vai_levantar(time):
					# Levantamento: segura e solta na hora do toque.
					levantamento_segurado[time] = _relogio
				elif not lances._tentar_tocar(time, false):
					_guardar_pedido(time, tipo)
			elif tipo == Lance.BOTAO_ATAQUE:
				if not lances._comecar_cortada(time):
					_guardar_pedido(time, tipo)
			elif tipo == Lance.BOTAO_BLOQUEIO:
				bloqueios._bloquear(time)
			elif tipo == Lance.BOTAO_MERGULHO:
				lances._mergulhar(time)


## O próximo toque do "time" é o levantamento (2º toque, bola vindo pro nosso lado).
func _vai_levantar(time: int) -> bool:
	return bola.em_voo and toques.time_com_a_bola == time and toques.toques == 1 and _lado_da_queda() == time


## Solta o levantamento segurado: a altura sai do tempo segurando e o toque
## vale agora (se a bola ainda não chegou, guarda o pedido como um botão cedo).
func _soltar_levantamento(time: int) -> void:
	if levantamento_segurado[time] < 0.0:
		return
	altura_pedida[time] = TempoDoToque.altura_pelo_tempo_segurado(_relogio - levantamento_segurado[time])
	levantamento_segurado[time] = -1.0
	if not lances._tentar_tocar(time, false):
		_guardar_pedido(time, Lance.BOTAO_PASSE)


## Segurando demais: se a bola já passou da hora e vai sair do alcance,
## levanta assim mesmo (sai "Tarde"), pra não perder o ponto por segurar.
func _vigiar_levantamento_segurado(time: int) -> void:
	if levantamento_segurado[time] < 0.0:
		return
	if estado != Estado.RALLY or not _vai_levantar(time):
		levantamento_segurado[time] = -1.0
		return
	var erro := TempoDoToque.erro_do_botao(Lance.LEVANTAMENTO, bola.position, bola.velocidade_atual(), 0.0, bola.gravidade)
	if erro < -TempoDoToque.JANELA_BOA and _alcanca_bola(time, 0.0, ALTURA_MAXIMA_PASSE):
		_soltar_levantamento(time)


## O botão veio cedo (a bola ainda não está ao alcance): guarda o pedido
## por TEMPO_DO_PEDIDO e tenta de novo a cada quadro (_atender_pedido).
func _guardar_pedido(time: int, tipo: String) -> void:
	pedidos[time] = { "tipo": tipo, "ate": _relogio + TEMPO_DO_PEDIDO, "apertou_em": _relogio }


## Tenta de novo o botão guardado. Se o tempo acabou e a bola não chegou,
## o anel do atleta pisca: o jogo ouviu, mas não dava pra tocar.
func _atender_pedido(time: int) -> void:
	if pedidos[time].is_empty():
		return
	if estado != Estado.RALLY:
		pedidos[time] = {}
		return
	var tipo: String = pedidos[time]["tipo"]
	var atendido: bool = lances._comecar_cortada(time) if tipo == Lance.BOTAO_ATAQUE else lances._tentar_tocar(time, false)
	if atendido:
		# Ataque apertado cedo e já solto: vale o tempo que ficou segurado.
		if tipo == Lance.BOTAO_ATAQUE and pedidos[time].has("segurou"):
			lances.soltou_depois_de(time, float(pedidos[time]["segurou"]))
		pedidos[time] = {}
	elif _relogio > float(pedidos[time]["ate"]):
		pedidos[time] = {}
		aneis_do_controlado[time].piscar()
		sons.tocar("falhou")


func _ao_soltar_botao(jogador: int, tipo: String) -> void:
	registro.append([quadro, jogador, tipo, false])
	var time := jogador - 1
	_segurando_botao[time].erase(tipo)
	if caos._escolhendo_cartas():
		return
	if tipo == Lance.BOTAO_PASSE:
		_soltar_levantamento(time)
	if tipo == Lance.BOTAO_ATAQUE and estado == Estado.RALLY:
		lances._soltar_cortada(time)
		if cortadas[time].is_empty() and pedidos[time].get("tipo", "") == Lance.BOTAO_ATAQUE:
			pedidos[time]["segurou"] = _relogio - float(pedidos[time]["apertou_em"])
	if estado != Estado.SAQUE or time != placar.quem_saca or carga_do_saque < 0.0:
		return
	if tipo != (Lance.BOTAO_FLUTUANTE if saque_flutuante else Lance.BOTAO_ATAQUE):
		return
	var forca := Mira.forca(carga_do_saque)
	carga_do_saque = -1.0
	_comecar_saque_viagem(time, forca, alvo_do_saque, saque_flutuante)


## Soltou o botão do saque: começa o movimento (_atualizar_saque_viagem).
## Viagem (botão de ataque): corre lançando a bola, pula e bate no alto do pulo.
## Flutuante (botão I): em pé, lança a bola e bate. A bola só sai na batida.
func _comecar_saque_viagem(time: int, forca: float, alvo: Vector2, flutuante := false) -> void:
	miras[time].esconder()
	var sacador: Node3D = controlados[time]
	var batida := BATIDA_DO_FLUTUANTE if flutuante else CORRIDA_DO_SAQUE_VIAGEM + PULO_DO_SAQUE_VIAGEM / 2.0
	# A corrida para antes da linha: o pé da frente vai uns 0,7 m à frente do
	# quadril na passada (MARGEM_DA_LINHA_NO_SAQUE).
	var passada := 0.0 if flutuante else clampf(absf(sacador.position.z) - COMPRIMENTO / 2.0 - MARGEM_DA_LINHA_NO_SAQUE, 0.0, PASSADA_DO_SAQUE_VIAGEM)
	saque_viagem = {
		"time": time, "forca": forca, "alvo": alvo, "tempo": 0.0, "flutuante": flutuante,
		"batida": batida, "de": sacador.position, "passada": passada, "pulou": false,
	}
	_animar(sacador, "saque" if flutuante else "saque_viagem")


## Movimento do saque até a batida: a bola sobe da mão num lançamento (parábola
## de verdade) e chega na altura da batida na hora certa; no viagem o atleta
## anda pra frente na corrida e pula. Na batida, o saque sai (`_sacar`).
func _atualizar_saque_viagem(delta: float, sacador: Node3D, frente: float) -> void:
	var s := saque_viagem
	s["tempo"] += delta
	var tempo: float = s["tempo"]
	var batida: float = s["batida"]
	var flutuante: bool = s["flutuante"]
	if not flutuante:
		var de: Vector3 = s["de"]
		var andou: float = float(s["passada"]) * smoothstep(0.0, CORRIDA_DO_SAQUE_VIAGEM, tempo)
		sacador.position.z = de.z - signf(de.z) * andou
		if not s["pulou"] and tempo >= CORRIDA_DO_SAQUE_VIAGEM:
			s["pulou"] = true
			bloqueios._pular(sacador, ALTURA_DO_PULO_DO_SAQUE, PULO_DO_SAQUE_VIAGEM)
	var altura_da_batida := ALTURA_DA_BATIDA_DO_FLUTUANTE if flutuante else ALTURA_DA_BATIDA_DO_VIAGEM
	bola.segurar_em(Vector3(sacador.position.x, altura_do_lancamento(minf(tempo, batida), batida, altura_da_batida), sacador.position.z + frente))
	if tempo < batida:
		return
	saque_viagem = {}
	_sacar(s["time"], flutuante, s["forca"], s["alvo"], true)


## Altura da bola no lançamento do saque, "t" segundos depois de soltar: sai
## da mão (ALTURA_DA_BOLA_NO_SAQUE) e está em "altura_da_batida" na "batida",
## caindo com a gravidade normal (sobe mais quanto mais longa a espera).
static func altura_do_lancamento(t: float, batida: float, altura_da_batida: float) -> float:
	var g := Trajetoria.GRAVIDADE
	var subida := (altura_da_batida - ALTURA_DA_BOLA_NO_SAQUE + 0.5 * g * batida * batida) / batida
	return ALTURA_DA_BOLA_NO_SAQUE + subida * t - 0.5 * g * t * t


## Saque viagem: sai do alto do pulo quase em linha reta e bem mais rápido
## que o flutuante (VelocidadeDaBola.do_saque_viagem, em m/s). Se não dá reto
## (bola baixa demais pra passar a rede), devolve false e sai em arco.
func _sacar_reto(time: int, destino: Vector3, forca: float) -> bool:
	var velocidade := VelocidadeDaBola.do_saque_viagem(forca) * Atributos.modificador(times_em_jogo[time], "velocidade_do_saque")
	return bola.lancar_reto(destino, velocidade)


## Flutuante: dois balanços pro lado no meio do voo (o anel de queda anda junto).
## O lado e o tamanho são sorteados; a queda muda até BALANCO_DO_FLUTUANTE m.
func _balancar_o_flutuante() -> void:
	var voo := Trajetoria.tempo_ate_altura(bola.position, bola.velocidade_atual(), Bola.RAIO, bola.gravidade)
	if voo <= 0.2:
		return
	var quantos := [sorteio.randf_range(-1.0, 1.0) * BALANCO_DO_FLUTUANTE / 2.0, sorteio.randf_range(-1.0, 1.0) * BALANCO_DO_FLUTUANTE / 2.0]
	# O balanço não joga pra fora uma bola que ia cair dentro: se fosse sair
	# pela lateral, balança pro outro lado.
	var x_final: float = bola.ponto_previsto.x + quantos[0] + quantos[1]
	if absf(bola.ponto_previsto.x) < LARGURA / 2.0 and absf(x_final) > LARGURA / 2.0 - 0.2:
		quantos = [-quantos[0], -quantos[1]]
	var desvios := []
	for k in 2:
		var fracao: float = [0.45, 0.7][k]
		desvios.append([voo * fracao, quantos[k] / (voo * (1.0 - fracao))])
	bola.balancar(desvios)

## Saque com "forca" (0 a 1) mirando "alvo" (na quadra do outro time).
## Mais força: mais baixo e rápido, mas com mais erro (pode sair).
## "pulou": o atleta já está no ar (saque viagem), então não toca o arremesso em pé.
func _sacar(time: int, flutuante: bool, forca := 0.4, alvo := Mira.ALVO_INICIAL, pulou := false) -> void:
	carga_do_saque = -1.0
	miras[time].esconder()
	if not pulou:
		_animar(controlados[time], "saque")
	# Na hora do saque, os dois times têm que estar na ordem do rodízio.
	var falta_de_posicao := _time_fora_de_posicao()
	if falta_de_posicao >= 0:
		_encerrar_rally(1 - falta_de_posicao, "posição errada no saque")
		return
	interface.esconder_ajuda()
	_bloqueio_do_ataque = 1.0
	_forca_da_cortada = -1
	_ultimo_levantamento = [{}, {}]
	toques.reiniciar()
	toques.registrar(time, atletas[time].find(controlados[time]))
	sons.tocar("saque", lerpf(0.5, 1.1, forca))
	saque_em_jogo = true
	var ponto := Mira.com_erro(alvo, _erro_do_saque(time, forca), Vector2(sorteio.randf(), sorteio.randf()))
	var destino := Vector3(ponto.x, 0.0, ponto.y * _lado(1 - time))
	_peso_do_toque(time, bola.position, forca if not flutuante else forca * 0.5)
	# Viagem: reto e rápido. Flutuante: mais lento, mas balança no ar.
	# Modo Caos: Super Saque deixa a bola mais rápida; Saque Canhão derruba quem recebe.
	var gravidade_do_saque := VelocidadeDaBola.gravidade(VelocidadeDaBola.do_saque(forca, flutuante) * Atributos.modificador(times_em_jogo[time], "velocidade_do_saque"))
	_saque_canhao = Atributos.gastar_carga(times_em_jogo[time], "saque_canhao")
	if _saque_canhao:
		interface.mostrar_mensagem("Saque Canhão!", time, false)
	if flutuante or not _sacar_reto(time, destino, forca):
		bola.lancar(destino, Mira.altura_do_saque(forca, flutuante), gravidade_do_saque)
	if flutuante:
		_balancar_o_flutuante()
	ultimo_toque = time
	_mudar_estado(Estado.RALLY)
	interface.limpar_mensagens()
	_ao_lancar_bola()


## Soma energia ao time. Quando enche, avisa que a super cortada está pronta.
func _ganhar_energia(time: int, quanto: float) -> void:
	if quanto <= 0.0:
		return
	var encheu: bool = energias[time].encher(quanto)
	_atualizar_barra_de_energia(time)
	if encheu:
		sons.tocar("perfeito")
		interface.mostrar_mensagem("Super pronta!", time, false)


func _atualizar_barra_de_energia(time: int) -> void:
	var barra = interface.barras_de_energia[time]
	if barra != null:
		barra.mostrar(energias[time].valor, energias[time].cheia())


## Peso do toque: bola amassa, câmera sente e (nos bons) saem faíscas.
## "forca" de 0 a 1. Só visual e sensação.
func _peso_do_toque(time: int, ponto: Vector3, forca: float, faiscas := true) -> void:
	bola.amassar(forca)
	impacto.toque(forca)
	if faiscas and forca >= 0.5:
		Estouro.mostrar(self, ponto, _cor_do_time(time), 0.2 + 0.4 * forca)


## Força do toque pela qualidade (perfeito cheio, bom médio, ruim nada).
func _forca_da_qualidade(qualidade: Qualidade, perfeito := 1.0, bom := 0.4) -> float:
	if qualidade == Qualidade.PERFEITO:
		return perfeito
	if qualidade == Qualidade.BOM:
		return bom
	return 0.0


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

## Anota a direção de cada jogador quando ela muda (ver "registro").
func _anotar_direcoes() -> void:
	for time in mini(entradas.size(), 2):
		var direcao: Vector2 = entradas[time].direcao
		if direcao != _ultima_direcao[time]:
			_ultima_direcao[time] = direcao
			registro.append([quadro, time + 1, "dir", [direcao.x, direcao.y]])


## Salva o "registro" num arquivo JSON (o robô usa com gravar=).
func salvar_registro(caminho: String) -> void:
	var arquivo := FileAccess.open(caminho, FileAccess.WRITE)
	if arquivo:
		arquivo.store_string(JSON.stringify(registro, "", false, true))
		arquivo.close()


## Relâmpago (Modo Caos): o tempo de cada time vai acabando.
func _gastar_relampago(delta: float) -> void:
	for t in 2:
		var resta := Atributos.carga(times_em_jogo[t], "relampago")
		if resta > 0.0:
			Atributos.mudar_carga(times_em_jogo[t], "relampago", resta - delta)


## Defesa de Ferro (Modo Caos): uma vez por set, a bola que ia cair na quadra
## do "time" é salva sozinha pelo atleta mais perto e sobe pro levantador.
## Devolve true se salvou.
func _defesa_de_ferro(time: int, posicao: Vector3) -> bool:
	if Atributos.carga(times_em_jogo[time], "defesa_de_ferro") < 1.0:
		return false
	var atleta := _mais_perto(time, posicao)
	if atleta == null or not toques.registrar(time, atletas[time].find(atleta)):
		return false
	Atributos.gastar_carga(times_em_jogo[time], "defesa_de_ferro")
	controlados[time] = atleta
	ultimo_toque = time
	_ponto_de_bloqueio = -1
	_animar(atleta, "manchete")
	sons.tocar("passe", 0.9)
	bola.position = Vector3(posicao.x, 0.5, posicao.z)
	bola.lancar(_no_mundo(time, Vector2(0.0, 2.0)), 4.5)
	_ao_lancar_bola()
	Estouro.mostrar(self, bola.position, _cor_do_time(time), 0.8)
	interface.mostrar_mensagem("Defesa de Ferro!", time, false)
	return true


## Troca o estado da partida (SAQUE, RALLY, PONTO, FIM). Troca fora da regra
## (EstadoDaPartida.TROCAS) avisa no console, mas acontece.
func _mudar_estado(novo: Estado) -> void:
	if not EstadoDaPartida.pode_mudar(estado, novo):
		push_warning("Troca de estado fora da regra: %s -> %s" % [EstadoDaPartida.nome(estado), EstadoDaPartida.nome(novo)])
	estado = novo


## Tipo do toque pra medir o tempo: o 1º é passe, o 2º levantamento, o 3º
## (ou qualquer ataque) cortada.
func _tipo_do_toque(numero: int, atacando: bool) -> String:
	if atacando or numero >= 3:
		return Lance.CORTADA
	return Lance.LEVANTAMENTO if numero == 2 else Lance.PASSE


## Qualidade do toque feito agora, pelo tempo do botão.
func _qualidade_do_toque(tipo: String, time: int) -> Qualidade:
	var atleta: Node3D = controlados[time]
	atleta.set_meta("erro_do_toque", 0.0)
	if tipo == Lance.LEVANTAMENTO and Atributos.levantamento_perfeito(times_em_jogo[time]):
		return Qualidade.PERFEITO
	var erro := TempoDoToque.erro_do_botao(tipo, bola.position, bola.velocidade_atual(), _atraso_do_toque(tipo), bola.gravidade)
	var qualidade := TempoDoToque.qualidade(erro, Atributos.escala_da_janela(times_em_jogo[time], tipo))
	# Guarda o erro só quando o TEMPO foi o problema, pro aviso dizer "Cedo!"
	# ou "Tarde!" (um toque ruim por outro motivo, como o mergulho de longe,
	# continua "Ruim").
	if qualidade == Qualidade.RUIM:
		atleta.set_meta("erro_do_toque", erro)
	return qualidade


## Tempo entre o botão e a mão encostar na bola (a cortada bate no alto do pulo).
func _atraso_do_toque(tipo: String) -> float:
	return TEMPO_ATE_A_BATIDA if tipo == Lance.CORTADA else 0.0


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
	var segundos := TempoDoToque.erro_do_botao(tipo, bola.position, velocidade, _atraso_do_toque(tipo), bola.gravidade)
	var atleta := controlados[time]
	# Longe de onde a bola vai estar na hora certa, o anel só atrapalha.
	var na_hora := Trajetoria.posicao_em(bola.position, velocidade, maxf(segundos, 0.0), bola.gravidade)
	if _distancia_no_chao(atleta, na_hora) > DISTANCIA_DO_ANEL_DE_TEMPO:
		anel.esconder()
		return
	anel.mostrar(atleta.position, segundos)
	_preparar_animacao_do_toque(atleta, tipo, segundos, na_hora)


## A bola está chegando no atleta controlado: ele já se prepara (abaixa e junta
## os braços, ou sobe as mãos) pra pose de contato ficar pronta junto com a bola.
## Uma vez por voo da bola. Só visual: não muda o resultado do toque.
func _preparar_animacao_do_toque(atleta: Node3D, tipo: String, segundos: float, na_hora: Vector3) -> void:
	var antes := PREPARO_ANTES_DA_CORTADA if tipo == Lance.CORTADA else PREPARO_ANTES_DA_BOLA
	if segundos <= 0.0 or segundos > antes:
		return
	if _distancia_no_chao(atleta, na_hora) > ALCANCE or bloqueios._esta_pulando(atleta) or _esta_no_chao(atleta):
		return
	if int(atleta.get_meta("preparou_no_voo", -1)) == bola.lancamentos:
		return
	var animador = _animador_de(atleta)
	var lance := "cortada" if tipo == Lance.CORTADA else ("levantamento" if tipo == Lance.LEVANTAMENTO else "manchete")
	if animador and animador.preparar_toque(lance, segundos):
		atleta.set_meta("preparou_no_voo", bola.lancamentos)


func _avisar_qualidade(atleta: Node3D, qualidade: Qualidade) -> void:
	# "Bom" é o toque comum: sem texto. Só o Perfeito e o Ruim aparecem.
	if qualidade == Qualidade.BOM:
		return
	# Mais limpo (pedido do Victor em 13/11/2026): o Perfeito não escreve nada,
	# só um brilho verde pequeno na bola e o sininho. O Ruim escreve pequeno pra
	# que lado errou ("Cedo!" ou "Tarde!"), que ajuda a acertar o tempo.
	if qualidade == Qualidade.PERFEITO:
		Estouro.mostrar(self, bola.position, AnelDeTempo.COR_PERFEITO, 0.1)
		sons.tocar("perfeito")
		return
	var texto := TempoDoToque.nome_do_ruim(float(atleta.get_meta("erro_do_toque", 0.0)))
	var aviso := AvisoDeToque.mostrar(self, atleta.position + Vector3(0.0, 2.3, 0.0), texto, Color("#FF6B5B"))
	aviso.font_size = TAMANHO_DO_AVISO_RUIM
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
		interface.barras_de_forca[time].mostrar(forca, arriscada)
		return
	interface.barras_de_forca[time].esconder()
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
## Atleta colado na rede volta até DISTANCIA_MINIMA_DA_REDE (do lado dele).
## Substitui a falta de toque na rede, que o jogador não conseguia ver chegando.
func _afastar_da_rede(atleta: Node3D) -> void:
	if absf(atleta.position.z) < DISTANCIA_MINIMA_DA_REDE:
		var lado := signf(atleta.position.z) if atleta.position.z != 0.0 else 1.0
		atleta.position.z = lado * DISTANCIA_MINIMA_DA_REDE


func _falta_no_toque(time: int, atacando: bool) -> String:
	var atleta := controlados[time]
	var indice: int = atletas[time].find(atleta)
	if toques.seria_toque_duplo(time, indice):
		return "dois toques"
	if not atacando:
		return ""
	# Sem falta de toque na rede: colado na rede, o atleta só é afastado.
	_afastar_da_rede(atleta)
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
## Regra da FIVB desde 2025 (Congresso de 2024): só o time que RECEBE precisa
## estar na ordem do rodízio na hora do saque. O time que saca pode ficar onde
## quiser (diretrizes de arbitragem da CEV 2025 e casebook da FIVB 2025).
func _time_fora_de_posicao() -> int:
	var recebe: int = 1 - placar.quem_saca
	if not Formacao.faltas(ia._lugares_do_time(recebe), 0).is_empty():
		return recebe
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
		interface.mostrar_mensagem("Saque: segure e solte (%d)" % restam, placar.quem_saca)


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
		if _defesa_de_ferro(1 - quem, posicao):
			return
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
	_mudar_estado(Estado.PONTO)
	var saque_do_rally_em_jogo := saque_em_jogo
	saque_em_jogo = false
	marcador.esconder()
	_mostrar_marcas_de_ataque(-1)
	interface.limpar_mensagens()
	var nome := str(times_em_jogo[vencedor]["nome"])
	var explicacao := _explicacao_do_ponto(motivo)
	interface.mostrar_mensagem("Ponto %s!%s" % [nome, " (%s)" % explicacao if explicacao != "" else ""])
	# Apito do juiz e a torcida (mais forte nos pontos bonitos).
	sons.tocar("apito")
	var torcida := 0.6
	if motivo == "dentro" and saque_do_rally_em_jogo and vencedor == placar.quem_saca:
		interface.faixa.mostrar("ACE!", nome, _cor_do_time(vencedor), vencedor)
		torcida = 1.0
	elif motivo == "dentro" and vencedor == _ponto_de_bloqueio:
		interface.faixa.mostrar("BLOQUEIO!", nome, _cor_do_time(vencedor), vencedor)
		torcida = 1.0
	elif motivo == "dentro":
		interface.faixa.mostrar("PONTO!", nome, _cor_do_time(vencedor), vencedor)
		torcida = 0.8
	else:
		interface.faixa.mostrar("PONTO!", "%s  ·  %s" % [nome, explicacao], _cor_do_time(vencedor), vencedor)
	sons.tocar("torcida", torcida)
	_ganhar_energia(vencedor, Energia.ajuste("ganho_do_ponto", Energia.GANHO_DO_PONTO))
	_ganhar_energia(1 - vencedor, Energia.ajuste("ganho_do_ponto_perdido", Energia.GANHO_DO_PONTO_PERDIDO))
	# A faixa já diz quem pontuou e o motivo: a caixa do meio fica escondida
	# (o texto continua lá, pros testes e pro robô).
	interface.esconder_caixa_do_meio()
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
			caos._abrir_escolha_de_cartas(_preparar_saque)
		else:
			_preparar_saque()


# --- Modo Caos ---

func _preparar_saque() -> void:
	_mudar_estado(Estado.SAQUE)
	_saque_canhao = false
	_ataque_atravessa = false
	ultimo_toque = -1
	_ponto_de_bloqueio = -1
	qualidade_do_passe = [Qualidade.BOM, Qualidade.BOM]
	saque_em_jogo = false
	saque_viagem = {}
	tempo_no_saque = 0.0
	carga_do_saque = -1.0
	_segundos_mostrados = -1
	pedidos = [{}, {}]
	levantamento_segurado = [-1.0, -1.0]
	altura_pedida = [-1.0, -1.0]
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

	interface.mostrar_mensagem("")
	interface.mostrar_mensagem("Saque: segure e solte", time)
	interface.mostrar_mensagem("Recepção: vá ao anel e aperte Passe", outro)


func _ao_encerrar_partida(vencedor: int) -> void:
	_mudar_estado(Estado.FIM)
	marcador.esconder()
	_mostrar_marcas_de_ataque(-1)
	# A tela de fim de jogo já diz quem venceu.
	interface.limpar_mensagens()
	interface.esconder_lembrete_da_pausa()
	interface.faixa.mostrar("JOGO!", "%s venceu" % times_em_jogo[vencedor]["nome"], _cor_do_time(vencedor), vencedor)
	sons.tocar("torcida", 1.3)
	for atleta in atletas[vencedor]:
		_animar(atleta, "comemoracao_torcida")
	for atleta in atletas[1 - vencedor]:
		_animar(atleta, "ponto_perdido_frustrado")


func _conectar_placar() -> void:
	placar.sortear_primeiro_saque()
	placar.ponto_marcado.connect(func(time: int) -> void:
		_atualizar_placar()
		interface.placar_visual.comemorar(time))
	placar.rodizio.connect(func(time: int) -> void: rodizios[time].girar())
	placar.set_encerrado.connect(_ao_encerrar_set)
	placar.partida_encerrada.connect(_ao_encerrar_partida)
	_atualizar_placar()


## Fim de um set. Se foi o último, _ao_encerrar_partida troca a mensagem logo depois.
func _ao_encerrar_set(vencedor: int) -> void:
	# Defesa de Ferro (Modo Caos) vale uma vez por set.
	for t in 2:
		if cartas_dos_times[t].has("defesa_de_ferro"):
			Atributos.mudar_carga(times_em_jogo[t], "defesa_de_ferro", 1.0)
	# Cada set começa com a escalação do começo.
	for rodizio in rodizios:
		rodizio.reiniciar()
	_atualizar_placar()
	interface.faixa.mostrar("SET!", "%s  %d x %d" % [
		str(times_em_jogo[vencedor]["nome"]), placar.pontos[vencedor], placar.pontos[1 - vencedor],
	], _cor_do_time(vencedor), vencedor)
	interface.mostrar_mensagem("Set %d: %s venceu! (%d x %d)" % [
		placar.set_atual, times_em_jogo[vencedor]["nome"],
		placar.pontos[vencedor], placar.pontos[1 - vencedor],
	])
	interface.esconder_caixa_do_meio()


func _atualizar_placar() -> void:
	interface.placar_visual.atualizar(placar.pontos, placar.sets, placar.set_atual, placar.quem_saca, placar.aviso())


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
	return _lado(time) if tela_dividida or lados_proprios else 1.0


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
	# Online: cada um vê a partida inteira pelo lado do próprio time.
	var rede := get_node_or_null("/root/Rede")
	if rede != null and rede.online():
		tela_dividida = false
		lados_proprios = true
		time_da_camera = 1 if rede.e_convidado() else 0
	_escolher_camera()
	if modo_caos:
		trocas_restantes = [Cartas.trocas_por_partida(Dados.cartas()), Cartas.trocas_por_partida(Dados.cartas())]
		dados_das_cartas = Dados.cartas()


## Câmera escolhida no menu ou na pausa (Configuracao.camera): "perto" (de
## console, dados/ajustes.json grupo "camera"), "alta" (grupo "camera_alta") ou
## "tv" (a antiga, os números exportados acima). Na tela dividida fica a de TV
## (a perto não cabe). Também escolhe o tamanho do desenho da bola.
func _escolher_camera() -> void:
	if _camera_de_tv.is_empty():
		_camera_de_tv = [distancia_camera, altura_camera, abertura_da_camera, acompanhamento_da_camera]
	distancia_camera = _camera_de_tv[0]
	altura_camera = _camera_de_tv[1]
	abertura_da_camera = _camera_de_tv[2]
	acompanhamento_da_camera = _camera_de_tv[3]
	tamanho_da_bola = Bola.RAIO_DO_DESENHO
	var estilo: String = "tv" if tela_dividida else Configuracao.camera
	var grupo: String = {"perto": "camera", "alta": "camera_alta"}.get(estilo, "")
	if grupo == "":
		return
	distancia_camera = Ajustes.pegar(grupo, "distancia", distancia_camera)
	altura_camera = Ajustes.pegar(grupo, "altura", altura_camera)
	abertura_da_camera = Ajustes.pegar(grupo, "abertura", abertura_da_camera)
	acompanhamento_da_camera = Ajustes.pegar(grupo, "acompanhamento_lateral", acompanhamento_da_camera)
	tamanho_da_bola = Ajustes.pegar(grupo, "tamanho_da_bola", tamanho_da_bola)


## Troca pra próxima câmera no meio da partida (botão da pausa). Devolve o
## texto do botão. Na tela dividida não troca.
func trocar_camera() -> String:
	if not tela_dividida:
		Configuracao.proxima_camera()
		_escolher_camera()
		for camera in cameras:
			var lado := _lado(str(camera.name).trim_prefix("Camera").to_int())
			camera.preparar(Vector3(0.0, altura_camera, distancia_camera * lado), Vector3(0.0, 0.0, foco_da_camera * lado), abertura_da_camera)
			camera.acompanhamento_lateral = acompanhamento_da_camera
		bola.mudar_tamanho_do_desenho(tamanho_da_bola)
		rastro.raio = tamanho_da_bola * 0.7
	return Configuracao.nome_da_camera()


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

## O personagem do atleta vem de Dados.carregar_personagem: .vrm do VRoid se
## existir, senão o gerado por código (dados/aparencia.json), senão cápsula.


## Cria a interface (placar, mensagens, barras...) por cima da partida.
func _criar_interface() -> void:
	interface = InterfaceDaPartida.new()
	interface.name = "InterfaceDaPartida"
	add_child(interface)
	interface.montar(tela_dividida,
		[times_em_jogo[0]["nome"], times_em_jogo[1]["nome"]],
		[_cor_do_time(0), _cor_do_time(1)],
		[str(times_em_jogo[0]["id"]), str(times_em_jogo[1]["id"])],
		modo_caos)
	# Contra o computador, as dicas do time dele ("Saque: segure e solte") só
	# enchiam a tela (13/11/2026).
	if Configuracao.contra_computador and not Configuracao.computador_nos_dois:
		interface.times_sem_mensagem = [1]

