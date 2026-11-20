#!/usr/bin/env bash
# Lanza el juego directamente (sin abrir el editor de Godot).
#
# Uso:
#   ./jugar.sh                 # ventana 450x800
#   ./jugar.sh --fondo         # se desengancha de la terminal (puedes cerrarla)
#   ./jugar.sh --completo      # pantalla completa
#   ./jugar.sh --resolution 540x960   # resolución personalizada
#
# Variables:
#   GODOT_BIN=/ruta/a/godot    # fuerza un binario concreto de Godot
set -euo pipefail

PROYECTO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Localizar Godot ---------------------------------------------------------
GODOT_BIN="${GODOT_BIN:-}"
if [ -z "$GODOT_BIN" ]; then
	for candidato in "$HOME/.local/bin/godot" "$(command -v godot || true)" "$(command -v godot4 || true)" \
		"/home/lur/Lur/Godot/Godot_v4.7-stable_linux.x86_64"; do
		if [ -n "$candidato" ] && [ -x "$candidato" ]; then
			GODOT_BIN="$candidato"
			break
		fi
	done
fi

if [ -z "$GODOT_BIN" ] || [ ! -x "$GODOT_BIN" ]; then
	echo "Error: no se encontró el ejecutable de Godot. Define GODOT_BIN=/ruta/a/godot."
	exit 1
fi

if [ ! -f "$PROYECTO_DIR/project.godot" ]; then
	echo "Error: no se encontró project.godot en $PROYECTO_DIR."
	exit 1
fi

# --- Opciones propias --------------------------------------------------------
FONDO=false
COMPLETO=false
ARGS=()
TIENE_RESOLUCION=false

for arg in "$@"; do
	case "$arg" in
		--fondo)
			FONDO=true
			;;
		--completo)
			COMPLETO=true
			;;
		--resolution|-r)
			TIENE_RESOLUCION=true
			ARGS+=("$arg")
			;;
		*)
			ARGS+=("$arg")
			;;
	esac
done

# La ventana por defecto es 720x1280 (9:16). En escritorio se abre a 450x800
# para que quepa en pantallas de 1080p manteniendo la misma proporción.
if [ "$COMPLETO" = true ]; then
	ARGS=("--fullscreen" "${ARGS[@]}")
elif [ "$TIENE_RESOLUCION" = false ]; then
	ARGS=("--resolution" "450x800" "${ARGS[@]}")
fi

# --- Ejecutar ----------------------------------------------------------------
cmd=("$GODOT_BIN" --path "$PROYECTO_DIR" "${ARGS[@]}")

if [ "$FONDO" = true ]; then
	LOG="/tmp/sims-0.33-juego.log"
	nohup "${cmd[@]}" >"$LOG" 2>&1 &
	PID=$!
	disown "$PID" 2>/dev/null || true
	echo "Juego lanzado en segundo plano (PID $PID)."
	echo "Log: $LOG"
else
	echo "Abriendo el juego (sin editor)..."
	exec "${cmd[@]}"
fi
