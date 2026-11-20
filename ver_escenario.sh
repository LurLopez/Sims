#!/usr/bin/env bash
# Abre el escenario de muestra del pack de sprites a 1280x720.
# Uso: ./ver_escenario.sh [--captura]
#   --captura guarda user://escenario_cocina_godot.png y cierra.
set -euo pipefail
cd "$(dirname "$0")"
GODOT_BIN="${GODOT_BIN:-godot}"
ARGS=()
if [[ "${1:-}" == "--captura" ]]; then
  shift
  ARGS=(-- --captura)
fi
exec "$GODOT_BIN" --path . --resolution 1280x720 \
  res://Escenas/Minijuego_Cocina/Escenario_Cooking_Fever.tscn "${ARGS[@]}" "$@"
