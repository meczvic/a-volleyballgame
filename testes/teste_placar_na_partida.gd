extends SceneTree
## Testes do placar novo e dos efeitos de ponto dentro da partida: números,
## avisos de SET POINT / MATCH POINT, faixa de ACE!/BLOQUEIO!/PONTO!/SET! e
## onda no chão.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_placar_na_partida.gd
##
## Usa _initialize e espera o 1º quadro porque a partida precisa dos
## autoloads e da árvore pronta.

const OndaNoChao := preload("res://scripts/visual/onda_no_chao.gd")

var falhas := 0
var cena: PackedScene


func _initialize() -> void:
	cena = load("res://cenas/partida.tscn")
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	_teste_ponto_atualiza_e_pula()
	_teste_ace()
	_teste_ponto_de_bloqueio()
	_teste_falta_mostra_o_motivo()
	_teste_avisos_no_placar()
	_teste_set_mostra_faixa_de_set()
	_teste_onda_no_chao()
	_teste_visual_do_placar()

	if falhas == 0:
		print("OK: todos os testes do placar na partida passaram.")
	else:
		print("FALHOU: %d verificação(ões) do placar na partida." % falhas)
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
	partida.estado = partida.Estado.RALLY
	partida.saque_em_jogo = false
	partida.toques.reiniciar()
	return partida


func _fechar(partida: Node) -> void:
	partida.temporizador_do_ponto.stop()
	root.remove_child(partida)
	partida.free()


func _teste_ponto_atualiza_e_pula() -> void:
	var partida = _nova_partida()
	partida._encerrar_rally(1, "dentro")
	_verificar(partida.placar_visual.texto_dos_pontos(1) == "1", "placar mostra o ponto do time 1")
	_verificar(partida.placar_visual.texto_dos_pontos(0) == "0", "placar do time 0 continua 0")
	_verificar(partida.placar_visual.numero_pulando(1), "o número de quem pontuou pula")
	_verificar(not partida.placar_visual.numero_pulando(0), "o do outro não")
	_verificar(partida.faixa.texto() == "PONTO!", "faixa de PONTO! (%s)" % partida.faixa.texto())
	_fechar(partida)


func _teste_ace() -> void:
	var partida = _nova_partida()
	partida.saque_em_jogo = true
	partida._encerrar_rally(0, "dentro")
	_verificar(partida.faixa.texto() == "ACE!", "saque que cai dentro sem ninguém tocar é ACE! (%s)" % partida.faixa.texto())
	_fechar(partida)


func _teste_ponto_de_bloqueio() -> void:
	var partida = _nova_partida()
	partida.ultimo_toque = 0
	partida._ao_bola_ser_bloqueada()
	partida._encerrar_rally(1, "dentro")
	_verificar(partida.faixa.texto() == "BLOQUEIO!", "bola bloqueada que cai é BLOQUEIO! (%s)" % partida.faixa.texto())
	_fechar(partida)


func _teste_falta_mostra_o_motivo() -> void:
	var partida = _nova_partida()
	partida._encerrar_rally(1, "4 toques")
	_verificar(partida.faixa.texto() == "PONTO!", "falta também mostra PONTO!")
	_verificar(partida.faixa._subtitulo.text.contains("4 toques"), "com o motivo embaixo")
	_fechar(partida)


func _teste_avisos_no_placar() -> void:
	var partida = _nova_partida()
	_pontos(partida, 6, 2)
	partida._atualizar_placar()
	_verificar(partida.placar_visual.texto_do_aviso() == "SET POINT", "6 x 2 mostra SET POINT (%s)" % partida.placar_visual.texto_do_aviso())
	partida.placar.sets[1] = 1
	_pontos(partida, 2, 6)
	partida._atualizar_placar()
	_verificar(partida.placar_visual.texto_do_aviso() == "MATCH POINT", "com 1 set, mostra MATCH POINT")
	_pontos(partida, 3, 3)
	partida._atualizar_placar()
	_verificar(partida.placar_visual.texto_do_aviso() == "", "3 x 3: sem aviso")
	_fechar(partida)


func _teste_set_mostra_faixa_de_set() -> void:
	var partida = _nova_partida()
	_pontos(partida, 6, 0)
	partida._encerrar_rally(0, "dentro")
	_verificar(partida.faixa.texto() == "SET!", "último ponto do set mostra SET! (%s)" % partida.faixa.texto())
	_verificar(partida.placar_visual.sets_acesos(0) == 1 and partida.placar_visual.sets_acesos(1) == 0, "bolinha do set ganho acesa")
	_verificar(partida.placar_visual.texto_do_aviso() == "", "no fim do set, sem aviso de set/match point")
	_fechar(partida)


func _teste_onda_no_chao() -> void:
	var partida = _nova_partida()
	var antes := _ondas(partida)
	partida._ao_bola_tocar_chao(Vector3(1.0, 0.0, -3.0))
	_verificar(_ondas(partida) == antes + 1, "bola dentro abre uma onda no chão")
	_verificar(partida.estado == partida.Estado.PONTO, "e o ponto sai")
	_fechar(partida)


func _ondas(partida: Node) -> int:
	var n := 0
	for filho in partida.get_children():
		if filho.get_script() == OndaNoChao:
			n += 1
	return n


func _pontos(partida: Node, a: int, b: int) -> void:
	partida.placar.pontos[0] = a
	partida.placar.pontos[1] = b


## Visual do placar (Fase 02): número amarelo no ponto, emblema na faixa, bola
## de quem saca, bolinha de cada set na ordem de quem ganhou e "FIM" no final.
func _teste_visual_do_placar() -> void:
	var partida = _nova_partida()
	var visual = partida.placar_visual
	_verificar(visual.saque_visivel(0) and not visual.saque_visivel(1), "bola do saque no time que saca")
	partida._encerrar_rally(1, "dentro")
	_verificar(visual.numero_amarelo(1), "número de quem pontuou fica amarelo")
	_verificar(not visual.numero_amarelo(0), "o do outro não")
	_verificar(partida.faixa.tem_emblema(), "faixa de ponto mostra o emblema de quem pontuou")
	_verificar(visual.saque_visivel(1) and not visual.saque_visivel(0), "bola do saque passa pra quem ganhou o ponto")

	# Set 1 do time 1, set 2 do time 0: as bolinhas guardam a ordem.
	_pontos(partida, 0, 6)
	partida.estado = partida.Estado.RALLY
	partida._encerrar_rally(1, "dentro")
	_pontos(partida, 6, 0)
	partida.estado = partida.Estado.RALLY
	partida._encerrar_rally(0, "dentro")
	_verificar(visual._vencedores_dos_sets == [1, 0], "ordem dos sets: time 1, depois time 0 (%s)" % [visual._vencedores_dos_sets])
	_verificar(visual.sets_acesos(0) == 1 and visual.sets_acesos(1) == 1, "uma bolinha de cada time")
	# No fim do set o placar mostra o resultado; o set novo aparece no próximo saque.
	partida._preparar_saque()
	_verificar(visual.texto_do_set() == "SET 3", "terceiro set no saque seguinte (%s)" % visual.texto_do_set())
	_verificar(visual.texto_dos_pontos(0) == "0" and visual.texto_dos_pontos(1) == "0", "set novo começa 0 x 0")

	# Fim de jogo: "FIM" no meio e nenhuma bola de saque.
	_pontos(partida, 6, 0)
	partida.estado = partida.Estado.RALLY
	partida._encerrar_rally(0, "dentro")
	_verificar(visual.texto_do_set() == "FIM", "fim de jogo mostra FIM (%s)" % visual.texto_do_set())
	_verificar(visual.sets_acesos(0) == 2, "vencedor com 2 bolinhas")
	_verificar(not visual.saque_visivel(0) and not visual.saque_visivel(1), "sem bola de saque no fim")
	_fechar(partida)
