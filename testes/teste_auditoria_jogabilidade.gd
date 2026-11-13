extends SceneTree
## Mudanças da auditoria de jogabilidade de 13/11/2026 (docs/AUDITORIA_JOGABILIDADE.md):
## - levantamento escolhido segurando o passe (rápida, normal, alta);
## - cortada forte só é defendida na linha do corpo;
## - câmera "perto" de console com uma tela só;
## - companheiros guardam o lugar até mudar o momento do jogo.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --path . --script res://testes/teste_auditoria_jogabilidade.gd

const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")
const JeitosDeDefender := preload("res://scripts/regras/jeitos_de_defender.gd")
const Lance := preload("res://scripts/regras/lance.gd")
const Qualidade := TempoDoToque.Qualidade
const PASSO := 1.0 / 60.0

var falhas := 0
var cena: PackedScene


func _initialize() -> void:
	cena = load("res://cenas/partida.tscn")
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _rodar() -> void:
	_teste_altura_pelo_tempo_segurado()
	_teste_defesa_da_cortada()
	_teste_levantamento_segurado_na_partida()
	_teste_lugares_guardados()
	_teste_camera_perto()
	if falhas == 0:
		print("OK: as mudanças da auditoria de jogabilidade funcionam.")
	else:
		print("FALHOU: %d verificação(ões) da auditoria de jogabilidade." % falhas)
	quit(1 if falhas > 0 else 0)


func _teste_altura_pelo_tempo_segurado() -> void:
	_verificar(TempoDoToque.altura_pelo_tempo_segurado(0.05) == TempoDoToque.ALTURA_DO_LEVANTAMENTO_RAPIDO, "toque curto = rápida")
	_verificar(TempoDoToque.altura_pelo_tempo_segurado(0.35) == TempoDoToque.ALTURA_DO_LEVANTAMENTO_NORMAL, "segurar um pouco = normal")
	_verificar(TempoDoToque.altura_pelo_tempo_segurado(0.9) == TempoDoToque.ALTURA_DO_LEVANTAMENTO_ALTO, "segurar bastante = alta")


func _teste_defesa_da_cortada() -> void:
	var perfeita := int(Qualidade.PERFEITO)
	var boa := int(Qualidade.BOM)
	_verificar(JeitosDeDefender.segura_cortada(perfeita, 0.5), "cortada perfeita na linha do corpo é defendida")
	_verificar(not JeitosDeDefender.segura_cortada(perfeita, 1.2), "cortada perfeita a 1,2 m passa")
	_verificar(JeitosDeDefender.segura_cortada(boa, 1.2), "cortada boa a 1,2 m é defendida")
	_verificar(not JeitosDeDefender.segura_cortada(boa, 1.6), "cortada boa a 1,6 m passa")
	_verificar(JeitosDeDefender.segura_cortada(int(Qualidade.RUIM), 1.7), "cortada ruim (em arco) dá pra pegar de longe")
	_verificar(JeitosDeDefender.segura_cortada(-1, 1.7), "bola que não é cortada não muda")


func _nova_partida() -> Node:
	var partida = cena.instantiate()
	root.add_child(partida)
	partida.placar.quem_saca = 0
	partida._preparar_saque()
	partida.estado = partida.Estado.RALLY
	partida.saque_em_jogo = false
	partida.toques.reiniciar()
	return partida


func _fechar(partida: Node) -> void:
	partida.queue_free()


## Passe do time 0 vindo pro levantador: apertar o passe não toca na hora;
## soltar toca, com a altura do tempo segurado.
func _teste_levantamento_segurado_na_partida() -> void:
	var partida = _nova_partida()
	partida.toques.registrar(0, (partida.levantadores[0] + 1) % 6)
	partida.ultimo_toque = 0
	var levantador: Node3D = partida.atletas[0][partida.levantadores[0]]
	partida.controlados[0] = levantador
	# Bola descendo bem em cima do levantador, ao alcance.
	partida.bola.lancar(levantador.position + Vector3(0.0, 0.0, 0.0), 3.0)
	partida.bola.position = levantador.position + Vector3(0.0, 2.0, 0.0)
	_verificar(partida._vai_levantar(0), "com o passe no ar o próximo toque é o levantamento")
	var lancamentos: int = partida.bola.lancamentos
	partida._ao_receber_comando(1, Lance.BOTAO_PASSE)
	_verificar(partida.bola.lancamentos == lancamentos, "apertar o passe no levantamento não toca na hora")
	_verificar(partida.levantamento_segurado[0] >= 0.0, "fica segurando")
	partida._relogio += 0.9
	partida._ao_soltar_botao(1, Lance.BOTAO_PASSE)
	_verificar(partida.levantamento_segurado[0] < 0.0, "soltou")
	_verificar(partida.bola.lancamentos == lancamentos + 1, "soltar levanta a bola")
	_verificar(partida.toques.toques == 2, "conta como 2º toque")
	_fechar(partida)


## Sem mudar o momento (mesma bola no ar), o lugar de um companheiro não muda
## mesmo se a bola anda; com uma bola nova, muda.
func _teste_lugares_guardados() -> void:
	var partida = _nova_partida()
	var indice := 0
	for i in 6:
		if not partida.ia._esta_no_bloqueio(1, i) and partida.atletas[1][i] != partida.controlados[1]:
			indice = i
			break
	partida.bola.lancar(Vector3(2.0, 0.0, -4.0), 4.0)
	var antes: Vector3 = partida.ia._alvo_da_ia(1, indice)
	partida.bola.position += Vector3(3.0, 0.0, 0.0)
	_verificar(partida.ia._alvo_da_ia(1, indice).is_equal_approx(antes), "na mesma bola, o companheiro mantém o lugar")
	partida.bola.lancar(Vector3(-3.0, 0.0, -6.0), 4.0)
	partida.ia._alvo_da_ia(1, indice)
	var guardado: Array = partida.ia._lugares_guardados["1_%d" % indice]
	_verificar(guardado[0][1] == partida.bola.lancamentos, "bola nova: o lugar é calculado de novo")
	_fechar(partida)


func _teste_camera_perto() -> void:
	var partida = cena.instantiate()
	partida.tela_dividida = false
	partida._escolher_camera()
	_verificar(partida.distancia_camera < 20.0 and partida.altura_camera < 8.0, "uma tela só: câmera perto e baixa (%.1f m, %.1f m)" % [partida.distancia_camera, partida.altura_camera])
	_verificar(partida.abertura_da_camera > 45.0, "e com a lente mais aberta")
	partida.free()
	var dividida = cena.instantiate()
	dividida.tela_dividida = true
	dividida._escolher_camera()
	_verificar(dividida.distancia_camera > 20.0, "tela dividida continua com a câmera de TV")
	dividida.free()
