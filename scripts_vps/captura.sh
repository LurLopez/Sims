#!/usr/bin/env bash
# Ejecuta una escena de captura de QA y publica los PNG para verlos desde el móvil.
#
# Uso:
#   ./scripts_vps/captura.sh Captura_Tienda
#   ./scripts_vps/captura.sh Captura_Bienestar
#   ./scripts_vps/captura.sh Captura_Minijuego_Cocina
#
# Sin argumentos lista las capturas disponibles.
set -euo pipefail

PROYECTO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-$(command -v godot || true)}"
DIR_ESCENAS="$PROYECTO_DIR/Escenas/Herramientas"
WEB_DIR="${SIMS_WEB_DIR:-/var/www/sims-web}"
DESTINO="$WEB_DIR/capturas"
URL_BASE="${SIMS_WEB_URL:-https://dev.cifraresearch.com/sims}"

if [ -z "$GODOT_BIN" ] || [ ! -x "$GODOT_BIN" ]; then
	echo "ERROR: no se encontró Godot (define GODOT_BIN)." >&2
	exit 1
fi

if [ $# -lt 1 ]; then
	echo "Uso: $0 <escena>"
	echo
	echo "Capturas disponibles:"
	for f in "$DIR_ESCENAS"/Captura_*.tscn; do
		[ -e "$f" ] || continue
		echo "  - $(basename "$f" .tscn)"
	done
	exit 1
fi

NOMBRE="${1%.tscn}"
ESCENA="res://Escenas/Herramientas/${NOMBRE}.tscn"

if [ ! -f "$DIR_ESCENAS/${NOMBRE}.tscn" ]; then
	echo "ERROR: no existe $DIR_ESCENAS/${NOMBRE}.tscn" >&2
	exit 1
fi

if ! mkdir -p "$DESTINO" 2>/dev/null || [ ! -w "$DESTINO" ]; then
	WEB_DIR="$PROYECTO_DIR/build/capturas"
	DESTINO="$WEB_DIR"
	URL_BASE=""
	mkdir -p "$DESTINO"
	echo "AVISO: se guardan en $DESTINO" >&2
fi

INICIO=$(date +%s)
echo "== Ejecutando $NOMBRE =="
if [ -n "${DISPLAY:-}" ]; then
	"$GODOT_BIN" --path "$PROYECTO_DIR" --resolution 720x1280 "$ESCENA"
elif command -v xvfb-run >/dev/null 2>&1; then
	xvfb-run -a -s "-screen 0 1440x1600x24" "$GODOT_BIN" --path "$PROYECTO_DIR" --resolution 720x1280 "$ESCENA"
else
	echo "ERROR: no hay DISPLAY ni xvfb-run; no se puede renderizar la captura." >&2
	exit 1
fi

RAIZ_USUARIO="$HOME/.local/share/godot/app_userdata/Sims"
[ -d "$RAIZ_USUARIO" ] || RAIZ_USUARIO="$HOME/.local/share/godot/app_userdata"

ENCONTRADAS=0
while IFS= read -r -d '' IMAGEN; do
	cp -f "$IMAGEN" "$DESTINO/"
	NOMBRE_PNG="$(basename "$IMAGEN")"
	ENCONTRADAS=$((ENCONTRADAS + 1))
	if [ -n "$URL_BASE" ]; then
		echo "  $URL_BASE/capturas/$NOMBRE_PNG"
	else
		echo "  $DESTINO/$NOMBRE_PNG"
	fi
done < <(find "$RAIZ_USUARIO" -name '*.png' -newermt "@$((INICIO - 1))" -print0 2>/dev/null)

if [ "$ENCONTRADAS" -eq 0 ]; then
	echo "AVISO: la escena no generó capturas nuevas." >&2
	exit 1
fi

echo
echo "Listo: $ENCONTRADAS captura(s)."
