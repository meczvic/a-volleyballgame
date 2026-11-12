extends RefCounted
## Estados da partida e quais trocas valem (Fase D do plano de melhorias).
##
## SAQUE: esperando o saque. RALLY: bola em jogo. PONTO: comemoração depois do
## ponto. FIM: acabou a partida. A partida troca de estado por
## partida._mudar_estado(); troca que não está em TROCAS avisa no console
## (é sinal de erro de lógica), mas acontece mesmo assim, pra não travar o jogo.

enum Estado { SAQUE, RALLY, PONTO, FIM }

## De cada estado, pra quais pode ir.
const TROCAS := {
	Estado.SAQUE: [Estado.SAQUE, Estado.RALLY, Estado.PONTO],
	Estado.RALLY: [Estado.PONTO],
	Estado.PONTO: [Estado.SAQUE, Estado.FIM],
	Estado.FIM: [],
}


static func pode_mudar(de: int, para: int) -> bool:
	return TROCAS.get(de, []).has(para)


static func nome(estado: int) -> String:
	return Estado.keys()[estado] if estado >= 0 and estado < Estado.size() else "?"
