extends SceneTree
## Testes da interface da partida: mensagens por time, texto do ponto, barra
## de força do saque, avisos empilhados e a tela de fim de jogo.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_interface_na_partida.gd
##
## Usa _initialize e espera o 1º quadro porque a partida precisa dos
## autoloads e da árvore pronta.

const AvisoDeToque := preload("res://scripts/partida/aviso_de_toque.gd")
const Mira := preload("res://scripts/regras/mira.gd")
const PASSO := 1.0 / 60.0

var falhas := 0
var cena: PackedScene


func _initialize() -> void:
	cena = load("res://cenas/partida.tscn")
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	_teste_mensagens_do_saque_por_time()
	_teste_texto_do_ponto()
	_teste_barra_de_forca()
	_teste_avisos_empilham()
	_teste_fim_de_jogo_limpa_a_tela()

	if falhas == 0:
		print("OK: todos os testes da interface na partida passaram.")
	else:
		print("FALHOU: %d verificação(ões) da interface na partida." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _nova_partida() -> Node:
	var partida = cena.instantiate()
	root.add_child(partida)
	partida.placar.quem_saca = 0
	partida._preparar_saque()
	return partida


func _fechar(partida: Node) -> void:
	root.remove_child(partida)
	partida.free()


func _teste_mensagens_do_saque_por_time() -> void:
	var partida = _nova_partida()
	_verificar(partida.rotulos_do_time[0].text.begins_with("Saque"), "quem saca vê a instrução do saque na metade dele")
	_verificar(partida.rotulos_do_time[1].text.begins_with("Recepção"), "quem recebe vê a instrução da recepção")
	_verificar(partida.rotulo_mensagem.text == "", "nada no meio da tela antes do saque")
	partida._sacar(0, false)
	_verificar(partida.rotulos_do_time[0].text == "" and partida.rotulos_do_time[1].text == "",
		"o saque limpa as mensagens dos dois lados")
	_fechar(partida)


func _teste_texto_do_ponto() -> void:
	var partida = _nova_partida()
	partida._sacar(0, false)
	partida._encerrar_rally(0, "dentro")
	_verificar(partida.rotulo_mensagem.text == "Ponto %s!" % partida.times_em_jogo[0]["nome"],
		"bola dentro: só 'Ponto X!' (%s)" % partida.rotulo_mensagem.text)
	_fechar(partida)
	partida = _nova_partida()
	partida._sacar(0, false)
	partida._encerrar_rally(1, "fora")
	_verificar(partida.rotulo_mensagem.text.ends_with("(bola fora)"), "bola fora diz 'bola fora' (%s)" % partida.rotulo_mensagem.text)
	_verificar(partida.faixa._subtitulo.text.ends_with("bola fora"), "a faixa também")
	_fechar(partida)
	partida = _nova_partida()
	partida._sacar(0, false)
	partida._encerrar_rally(1, "toque na rede")
	_verificar(partida.rotulo_mensagem.text.ends_with("(toque na rede)"), "falta mostra o motivo (%s)" % partida.rotulo_mensagem.text)
	_fechar(partida)


func _teste_barra_de_forca() -> void:
	var partida = _nova_partida()
	var barra = partida.barras_de_forca[0]
	_verificar(not barra.visible, "barra escondida antes de carregar")
	partida._ao_receber_comando(1, "ataque")
	for i in 20:
		partida._physics_process(PASSO)
	_verificar(barra.visible, "segurando Ataque, a barra aparece")
	_verificar(barra.fracao() > 0.2 and barra.fracao() < 0.6,
		"a barra acompanha a força (%.2f)" % barra.fracao())
	_verificar(not partida.barras_de_forca[1].visible, "a barra do outro time fica escondida")
	partida._ao_soltar_botao(1, "ataque")
	partida._physics_process(PASSO)
	_verificar(not barra.visible, "soltou: a barra some")
	_fechar(partida)


func _teste_avisos_empilham() -> void:
	var partida = _nova_partida()
	var ponto := Vector3(0.0, 2.0, 3.0)
	var primeiro: Label3D = AvisoDeToque.mostrar(partida, ponto, "Perfeito!", Color.WHITE)
	var segundo: Label3D = AvisoDeToque.mostrar(partida, ponto + Vector3(0.5, 0.0, 0.3), "Bloqueio!", Color.WHITE)
	var longe: Label3D = AvisoDeToque.mostrar(partida, ponto + Vector3(6.0, 0.0, 0.0), "Bom", Color.WHITE)
	_verificar(segundo.global_position.y > primeiro.global_position.y + 0.3,
		"o segundo aviso no mesmo lugar sobe um degrau (%.2f x %.2f)" % [primeiro.global_position.y, segundo.global_position.y])
	_verificar(is_equal_approx(longe.global_position.y, ponto.y), "aviso longe fica na altura normal")
	_fechar(partida)


func _teste_fim_de_jogo_limpa_a_tela() -> void:
	var partida = _nova_partida()
	partida._ao_encerrar_partida(0)
	_verificar(partida.rotulo_mensagem.text == "", "no fim de jogo a mensagem do meio some (a tela de fim já diz quem venceu)")
	_verificar(not partida.caixa_da_pausa.visible, "o lembrete 'Esc ou Start: pausa' some no fim de jogo")
	_verificar(partida.faixa.texto() == "JOGO!", "a faixa JOGO! aparece")
	_fechar(partida)
