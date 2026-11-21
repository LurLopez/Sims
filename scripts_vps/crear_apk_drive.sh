#!/usr/bin/env bash
# Compila SIMS 0.33 para Android (headless), pasa los tests GUT y sube el APK
# a Google Drive mediante rclone.
#
# Uso:
#   ./scripts_vps/crear_apk_drive.sh                # tests + APK debug + subida
#   ./scripts_vps/crear_apk_drive.sh --skip-tests   # omite GUT
#   ./scripts_vps/crear_apk_drive.sh --no-upload    # solo compila
set -euo pipefail

PROYECTO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-$(command -v godot || true)}"
[ -x "$GODOT_BIN" ] || GODOT_BIN="$HOME/.local/bin/godot"

export ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
if [ -z "${JAVA_HOME:-}" ]; then
	if [ -d "$HOME/opt/jdk-17.0.21.1+2" ]; then
		JAVA_HOME="$HOME/opt/jdk-17.0.21.1+2"
	elif [ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]; then
		JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
	fi
fi
export JAVA_HOME="${JAVA_HOME:-}"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$HOME/.local/bin:$PATH"

RCLONE_BIN="${RCLONE_BIN:-$(command -v rclone || true)}"
[ -x "$RCLONE_BIN" ] || RCLONE_BIN="$HOME/.local/bin/rclone"
REMOTE="gdrive:SIMS_Builds"

SKIP_TESTS=false
MODO="--export-debug"
SUFIJO="debug"
SUBIR=true
for arg in "$@"; do
	case "$arg" in
		--skip-tests) SKIP_TESTS=true ;;
		--no-upload) SUBIR=false ;;
		-h|--help)
			sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
			exit 0
			;;
		*)
			echo "Argumento no reconocido: $arg" >&2
			exit 2
			;;
	esac
done

if [ -z "$GODOT_BIN" ] || [ ! -x "$GODOT_BIN" ]; then
	echo "ERROR: no se encontró Godot (define GODOT_BIN)." >&2
	exit 1
fi
if [ ! -d "$ANDROID_HOME" ]; then
	echo "ERROR: no existe ANDROID_HOME=$ANDROID_HOME" >&2
	exit 1
fi
if [ ! -d "$JAVA_HOME" ]; then
	echo "ERROR: no existe JAVA_HOME=$JAVA_HOME" >&2
	exit 1
fi

GODOT_VERSION="$("$GODOT_BIN" --headless --version 2>/dev/null | head -n1)"
echo "== SIMS 0.33 · build Android =="
echo "Proyecto : $PROYECTO_DIR"
echo "Godot    : $GODOT_VERSION"
echo "Android  : $ANDROID_HOME"
echo "Java     : $JAVA_HOME"
echo "Commit   : $(git -C "$PROYECTO_DIR" rev-parse --short HEAD 2>/dev/null || echo 'sin git')"
echo

echo "== 1/4 · Reimportación de recursos =="
"$GODOT_BIN" --headless --path "$PROYECTO_DIR" --import > /tmp/sims-import.log 2>&1
echo "Importación correcta."
echo

if [ "$SKIP_TESTS" = false ]; then
	echo "== 2/4 · Tests GUT (headless) =="
	LOG_GUT="/tmp/sims-gut-$(date +%Y%m%d-%H%M).log"
	set +e
	"$GODOT_BIN" --headless --path "$PROYECTO_DIR" \
		-s addons/gut/gut_cmdln.gd \
		-gdir=res://Funcionalidades -ginclude_subdirs -gexit 2>&1 | tee "$LOG_GUT"
	GUT_EXIT=${PIPESTATUS[0]}
	set -e
	if [ "$GUT_EXIT" -ne 0 ]; then
		echo "ERROR: los tests GUT fallaron (exit $GUT_EXIT). Log: $LOG_GUT" >&2
		exit "$GUT_EXIT"
	fi
	grep -E "Tests +[0-9]+|Passing Tests|Failing Tests|All tests passed" "$LOG_GUT" | tail -n 5 || true
	echo
else
	echo "== 2/4 · Tests GUT omitidos (--skip-tests) =="
	echo
fi

STAMP="$(date +%Y%m%d-%H%M)"
APK_PATH="/tmp/sims-0.33-${STAMP}.apk"
APK_LATEST="/tmp/sims-latest.apk"

echo "== 3/4 · Exportación APK ($SUFIJO) =="
rm -f "$APK_PATH" "$APK_LATEST"
"$GODOT_BIN" --headless --path "$PROYECTO_DIR" "$MODO" "Android" "$APK_PATH" > /tmp/sims-export.log 2>&1

if [ ! -s "$APK_PATH" ]; then
	echo "ERROR: no se generó el APK. Revisa /tmp/sims-export.log" >&2
	tail -n 30 /tmp/sims-export.log >&2
	exit 1
fi
cp -f "$APK_PATH" "$APK_LATEST"

APK_SIZE="$(du -h "$APK_PATH" | cut -f1)"
APK_SHA="$(sha256sum "$APK_PATH" | cut -d' ' -f1)"
echo "APK generado: $APK_PATH ($APK_SIZE)"
echo

echo "== 4/4 · Google Drive =="
LINK=""
SUBIDO=false
if [ "$SUBIR" = false ]; then
	echo "Subida omitida (--no-upload)."
elif [ -z "$RCLONE_BIN" ] || [ ! -x "$RCLONE_BIN" ]; then
	echo "AVISO: rclone no está instalado; APK solo local."
elif ! "$RCLONE_BIN" listremotes 2>/dev/null | grep -qx 'gdrive:'; then
	echo "AVISO: el remoto 'gdrive:' no está configurado en rclone."
	echo "       APK solo local. Para activarlo: rclone config  (o rclone authorize \"drive\")"
elif ! "$RCLONE_BIN" lsd gdrive: >/dev/null 2>&1; then
	echo "AVISO: 'gdrive:' existe pero no está autorizado (falta el token OAuth)."
	echo "       Ejecuta: rclone config reconnect gdrive:"
	echo "       APK solo local."
else
	"$RCLONE_BIN" copyto "$APK_PATH" "$REMOTE/$(basename "$APK_PATH")"
	"$RCLONE_BIN" copyto "$APK_LATEST" "$REMOTE/sims-latest.apk"
	SUBIDO=true
	LINK="$("$RCLONE_BIN" link "$REMOTE/sims-latest.apk" 2>/dev/null || true)"
	echo "Subido a Google Drive > SIMS_Builds:"
	echo "  - $(basename "$APK_PATH")"
	echo "  - sims-latest.apk"
	[ -n "$LINK" ] && echo "Enlace: $LINK"
fi

# Conserva solo los 2 APK con timestamp más recientes en /tmp.
mapfile -t APKS < <(ls -1t /tmp/sims-0.33-*.apk 2>/dev/null || true)
if [ "${#APKS[@]}" -gt 2 ]; then
	rm -f "${APKS[@]:2}"
fi

echo
echo "=================================================="
echo " APK : $(basename "$APK_PATH")  ($APK_SIZE)"
echo " SHA : $APK_SHA"
echo " Local: $APK_PATH"
if [ -n "$LINK" ]; then
	echo " Drive: $LINK"
elif [ "$SUBIDO" = true ]; then
	echo " Drive: subido a gdrive:SIMS_Builds/ (sin enlace directo)"
elif [ "$SUBIR" = true ]; then
	echo " Drive: pendiente de configurar rclone (gdrive:)"
fi
echo "=================================================="
