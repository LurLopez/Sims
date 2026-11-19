#!/usr/bin/env bash
set -euo pipefail

PROYECTO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_BIN="${GODOT_BIN:-/home/lur/.local/bin/godot}"
if [ ! -x "$GODOT_BIN" ]; then
	GODOT_BIN="$(command -v godot || true)"
fi

if [ -z "$GODOT_BIN" ] || [ ! -x "$GODOT_BIN" ]; then
	echo "Error: no se encontró el ejecutable de Godot."
	exit 1
fi

VERSION_RAW="$("$GODOT_BIN" --version | head -n1)"
# Ejemplo: 4.7.2.stable.official.ed1daf0bf -> tag 4.7.2-stable, carpeta 4.7.2.stable
VERSION_BASE="$(echo "$VERSION_RAW" | cut -d. -f1-3)"
CANAL="$(echo "$VERSION_RAW" | cut -d. -f4)"
TEMPLATE_DIR="$HOME/.local/share/godot/export_templates/${VERSION_BASE}.${CANAL}"
GITHUB_TAG="${VERSION_BASE}-${CANAL}"

if [ ! -d "$TEMPLATE_DIR" ] || [ ! -f "$TEMPLATE_DIR/android_debug.apk" ]; then
	echo "No se encontraron las export templates de Android en: $TEMPLATE_DIR"
	echo "Descargando Godot_v${GITHUB_TAG}_export_templates.tpz..."
	TMP_TPZ="/tmp/godot_templates_${GITHUB_TAG}.tpz"
	TMP_EXTRACT="/tmp/godot_templates_extract_${GITHUB_TAG}"
	mkdir -p "$TEMPLATE_DIR" "$TMP_EXTRACT"
	curl -fL "https://github.com/godotengine/godot/releases/download/${GITHUB_TAG}/Godot_v${GITHUB_TAG}_export_templates.tpz" -o "$TMP_TPZ"
	unzip -q -o "$TMP_TPZ" -d "$TMP_EXTRACT"
	cp -r "$TMP_EXTRACT"/templates/* "$TEMPLATE_DIR"/
	rm -rf "$TMP_TPZ" "$TMP_EXTRACT"
	echo "Templates instaladas correctamente."
fi

MODO="--export-debug"
SALIDA="$PROYECTO_DIR/build/sims-0.33.apk"
INSTALAR=false

for arg in "$@"; do
	case "$arg" in
		--release) MODO="--export-release" ;;
		--instalar) INSTALAR=true ;;
	esac
done

mkdir -p "$PROYECTO_DIR/build"

ICONOS_ANDROID_DIR="$PROYECTO_DIR/Iconos_Android"
if [ ! -f "$ICONOS_ANDROID_DIR/splash_icon_512.png" ]; then
	echo "Generando iconos de Android..."
	"$GODOT_BIN" --headless --path "$PROYECTO_DIR" --script res://Scripts/Otro/Herramientas/Generar_Iconos_Android.gd
fi

echo "Exportando APK ($MODO)..."
"$GODOT_BIN" --headless --path "$PROYECTO_DIR" "$MODO" "Android" "$SALIDA"

echo "APK generado en: $SALIDA"

if [ "$INSTALAR" = true ]; then
	ADB_BIN=""
	if command -v adb >/dev/null 2>&1; then
		ADB_BIN="adb"
	elif [ -x "$HOME/Android/Sdk/platform-tools/adb" ]; then
		ADB_BIN="$HOME/Android/Sdk/platform-tools/adb"
	fi

	if [ -n "$ADB_BIN" ]; then
		echo "Instalando en dispositivo Android por ADB..."
		"$ADB_BIN" install -r "$SALIDA"
	else
		echo "Aviso: 'adb' no está en el PATH; copia manualmente $SALIDA a tu móvil."
	fi
fi
