#!/usr/bin/env bash
# Roda os testes de testes/ no Godot, sem janela, e diz quais passaram.
#
# Uso (de qualquer pasta):
#   GODOT=/caminho/do/godot ferramentas/rodar_testes.sh            # todos
#   GODOT=/caminho/do/godot ferramentas/rodar_testes.sh mira placar # só os que têm "mira" ou "placar" no nome
#
# Sem a variável GODOT, usa o comando "godot".
# Um teste passa quando: termina sozinho dentro do limite de tempo, sai com
# código 0, imprime uma linha começando com "OK:" e não imprime "FALHOU" nem
# "SCRIPT ERROR". (Um erro de script trava o Godot sem fechar; o limite de
# tempo pega esse caso.)
# O script sai com código 0 só se todos passarem; senão, com 1.
#
# Outras variáveis:
#   LIMITE_POR_TESTE  segundos que cada teste pode levar (padrão 600)
#   SEM_IMPORTAR=1    pula a importação dos arquivos (.vrm, .fbx...) antes dos testes

set -u

cd "$(dirname "$0")/.." || exit 1
GODOT="${GODOT:-godot}"
LIMITE="${LIMITE_POR_TESTE:-600}"

if ! command -v "$GODOT" > /dev/null 2>&1 && [ ! -x "$GODOT" ]; then
	echo "Não achei o Godot em \"$GODOT\". Rode com GODOT=/caminho/do/godot $0"
	exit 1
fi

saidas="$(mktemp -d)"
trap 'rm -rf "$saidas"' EXIT

if [ "${SEM_IMPORTAR:-0}" != "1" ]; then
	echo "Importando os arquivos do projeto..."
	if ! timeout "$LIMITE" "$GODOT" --headless --path . --import > "$saidas/_importacao.txt" 2>&1; then
		echo "FALHOU: a importação não terminou bem. Últimas linhas:"
		tail -n 20 "$saidas/_importacao.txt"
		exit 1
	fi
fi

testes=()
for arquivo in testes/teste_*.gd; do
	nome="$(basename "$arquivo" .gd)"
	if [ "$#" -gt 0 ]; then
		escolhido=0
		for filtro in "$@"; do
			case "$nome" in *"$filtro"*) escolhido=1 ;; esac
		done
		[ "$escolhido" = "1" ] || continue
	fi
	testes+=("$arquivo")
done

if [ "${#testes[@]}" -eq 0 ]; then
	echo "Nenhum teste encontrado com esse nome."
	exit 1
fi

passaram=0
falharam=()
for arquivo in "${testes[@]}"; do
	nome="$(basename "$arquivo" .gd)"
	saida="$saidas/$nome.txt"
	inicio=$(date +%s)
	timeout "$LIMITE" "$GODOT" --headless --path . --script "res://$arquivo" > "$saida" 2>&1
	codigo=$?
	segundos=$(( $(date +%s) - inicio ))

	motivo=""
	if [ "$codigo" -eq 124 ] || [ "$codigo" -eq 137 ]; then
		motivo="passou de ${LIMITE} s sem terminar (erro de script trava o Godot)"
	elif grep -q "SCRIPT ERROR" "$saida"; then
		motivo="erro de script"
	elif grep -q "FALHOU" "$saida"; then
		motivo="imprimiu FALHOU"
	elif [ "$codigo" -ne 0 ]; then
		motivo="saiu com código $codigo"
	elif ! grep -q "^OK:" "$saida"; then
		motivo="não imprimiu a linha OK:"
	fi

	if [ -z "$motivo" ]; then
		passaram=$((passaram + 1))
		printf "  ok      %-32s %4d s\n" "$nome" "$segundos"
	else
		falharam+=("$nome")
		printf "  FALHOU  %-32s %4d s  (%s)\n" "$nome" "$segundos" "$motivo"
		grep -E "FALHOU|SCRIPT ERROR|at: .*res://" "$saida" | head -n 15 | sed 's/^/          /'
		echo "          --- fim da saída ---"
		tail -n 5 "$saida" | sed 's/^/          /'
	fi
done

echo
echo "$passaram de ${#testes[@]} testes passaram."
if [ "${#falharam[@]}" -gt 0 ]; then
	echo "Falharam: ${falharam[*]}"
	exit 1
fi
