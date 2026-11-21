#!/usr/bin/env bash
# Exporta el juego a HTML5 y lo publica en la vista web del VPS.
#
# Uso:
#   ./scripts_vps/exportar_web.sh
#   SIMS_WEB_DIR=/ruta/alternativa ./scripts_vps/exportar_web.sh
#
# En el VPS publica en /var/www/sims-web y queda disponible en:
#   https://dev.cifraresearch.com/sims/
set -euo pipefail

PROYECTO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-$(command -v godot || true)}"
DESTINO="${SIMS_WEB_DIR:-/var/www/sims-web}"
URL="${SIMS_WEB_URL:-https://dev.cifraresearch.com/sims/}"

if [ -z "$GODOT_BIN" ] || [ ! -x "$GODOT_BIN" ]; then
	echo "ERROR: no se encontró Godot (define GODOT_BIN)." >&2
	exit 1
fi

if ! mkdir -p "$DESTINO" 2>/dev/null || [ ! -w "$DESTINO" ]; then
	DESTINO="$PROYECTO_DIR/build/web"
	URL=""
	mkdir -p "$DESTINO"
	echo "AVISO: sin permiso sobre /var/www/sims-web; se exporta en $DESTINO" >&2
fi

echo "== Exportando a Web =="
echo "Proyecto: $PROYECTO_DIR"
echo "Destino : $DESTINO"
echo

"$GODOT_BIN" --headless --path "$PROYECTO_DIR" --export-release "Web" "$DESTINO/index.html"

if [ ! -s "$DESTINO/index.wasm" ] || [ ! -s "$DESTINO/index.pck" ]; then
	echo "ERROR: la exportación no generó index.wasm/index.pck." >&2
	exit 1
fi

echo
echo "Vista web lista:"
if [ -n "$URL" ]; then
	echo "  $URL"
	echo "  Usuario: sims (contraseña configurada en el VPS)"
else
	echo "  $DESTINO/index.html"
fi
