#!/usr/bin/env bash
# Vincula la cuenta de Google Drive al remoto rclone "gdrive".
# Ejecútalo en una terminal con navegador (este equipo o tu PC).
set -euo pipefail

if ! command -v rclone >/dev/null 2>&1 && [ -x "$HOME/.local/bin/rclone" ]; then
	export PATH="$HOME/.local/bin:$PATH"
fi
if ! command -v rclone >/dev/null 2>&1; then
	echo "ERROR: rclone no está instalado." >&2
	exit 1
fi

if ! rclone listremotes 2>/dev/null | grep -qx 'gdrive:'; then
	echo "Creando remoto 'gdrive' (tipo drive, scope drive)..."
	rclone config create gdrive drive scope drive
fi

echo
echo "Se abrirá el navegador para autorizar Google Drive."
echo "Si estás en otro equipo, usa: rclone authorize \"drive\" y pega el token."
echo
rclone config reconnect gdrive:

echo
if rclone lsd gdrive: >/dev/null 2>&1; then
	echo "OK: gdrive: autorizado. Ya puedes usar ./scripts_vps/crear_apk_drive.sh"
else
	echo "AVISO: la autorización no se completó. Revisa la salida anterior." >&2
	exit 1
fi
