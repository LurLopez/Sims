#!/usr/bin/env bash
# Sincroniza este repositorio con GitHub desde el PC o desde el VPS.
#
# Uso:
#   ./sincronizar_git.sh estado             Ver cambios y commits pendientes
#   ./sincronizar_git.sh subir "mensaje"    Commit + integrar remoto + push
#   ./sincronizar_git.sh bajar              Traer cambios (guarda los locales)
#
# Opciones:
#   -y, --si    No pedir confirmación (para agentes o ejecución no interactiva)
#
# Alias: status = estado · push = subir · pull = bajar
#
# Ejemplos:
#   ./sincronizar_git.sh subir "arreglo del calendario"
#   ./sincronizar_git.sh subir -y "build automática"
#   ./sincronizar_git.sh bajar
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

REMOTE="${GIT_REMOTE:-origin}"
UMBRAL_MB=50
SI=false

if [ -t 1 ]; then
	C_INFO=$'\033[1;34m'; C_OK=$'\033[1;32m'; C_WARN=$'\033[1;33m'; C_ERR=$'\033[1;31m'; C_OFF=$'\033[0m'
else
	C_INFO=""; C_OK=""; C_WARN=""; C_ERR=""; C_OFF=""
fi

info() { printf '%s==>%s %s\n' "$C_INFO" "$C_OFF" "$*"; }
ok()   { printf '%sOK%s  %s\n' "$C_OK" "$C_OFF" "$*"; }
warn() { printf '%sAVISO%s %s\n' "$C_WARN" "$C_OFF" "$*" >&2; }
err()  { printf '%sERROR%s %s\n' "$C_ERR" "$C_OFF" "$*" >&2; }

uso() {
	sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
	exit "${1:-0}"
}

confirmar() {
	[ "$SI" = true ] && return 0
	if [ ! -t 0 ]; then
		err "Sin terminal interactiva: añade -y para confirmar automáticamente."
		return 1
	fi
	local respuesta
	read -r -p "$1 [s/N] " respuesta || return 1
	case "$respuesta" in
		s|S|si|Si|SI|y|Y) return 0 ;;
		*) return 1 ;;
	esac
}

comprobar_repo() {
	if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		err "$REPO_DIR no es un repositorio git."
		exit 1
	fi
	BRANCH="$(git symbolic-ref --short -q HEAD || true)"
	if [ -z "$BRANCH" ]; then
		err "Estás en HEAD desacoplado. Cambia a una rama (git switch main) y repite."
		exit 1
	fi
	if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
		err "No existe el remoto '$REMOTE'."
		exit 1
	fi
}

fetch_remoto() {
	info "Consultando $REMOTE…"
	if ! git fetch --prune "$REMOTE" >/dev/null 2>&1; then
		warn "No se pudo contactar con $REMOTE (revisa la red o las credenciales)."
		return 1
	fi
	return 0
}

linea_pendientes() {
	local counts behind ahead
	if ! counts="$(git rev-list --left-right --count "$REMOTE/$BRANCH...HEAD" 2>/dev/null)"; then
		echo "  (la rama $REMOTE/$BRANCH aún no existe)"
		return
	fi
	behind="$(awk '{print $1}' <<<"$counts")"
	ahead="$(awk '{print $2}' <<<"$counts")"
	echo "  Pendientes de subir: $ahead · Pendientes de bajar: $behind"
}

comprobar_archivos_grandes() {
	local f size mb grandes=0
	while IFS= read -r f; do
		[ -n "$f" ] || continue
		size="$(stat -c %s "$f" 2>/dev/null || echo 0)"
		mb=$(( size / 1024 / 1024 ))
		if [ "$size" -gt $(( UMBRAL_MB * 1024 * 1024 )) ]; then
			err "Archivo demasiado grande para GitHub: $f (${mb} MB > ${UMBRAL_MB} MB)"
			grandes=1
		fi
	done < <(git diff --cached --name-only --diff-filter=ACM)
	[ "$grandes" -eq 0 ]
}

cmd_estado() {
	comprobar_repo
	fetch_remoto || true
	info "Repositorio: $REPO_DIR"
	info "Rama: $BRANCH · Remoto: $REMOTE ($(git remote get-url "$REMOTE"))"
	echo
	git status -sb
	echo
	linea_pendientes
	echo
	info "Últimos commits:"
	git log --oneline -5
}

cmd_subir() {
	local mensaje="${1:-}"
	comprobar_repo
	fetch_remoto || true

	git add -A

	if git diff --cached --quiet; then
		ok "No hay cambios que commitear."
	else
		comprobar_archivos_grandes || {
			err "Quita esos archivos del commit (o añádelos a .gitignore) y repite."
			exit 1
		}

		if [ -z "$mensaje" ]; then
			echo
			info "Cambios que se van a commitear:"
			git diff --cached --stat | tail -n 20
			echo
			if [ ! -t 0 ]; then
				err "Falta el mensaje del commit: ./sincronizar_git.sh subir \"mensaje\""
				exit 1
			fi
			read -r -p "Mensaje del commit: " mensaje || exit 1
		fi
		if [ -z "$mensaje" ]; then
			err "El mensaje del commit no puede estar vacío."
			exit 1
		fi

		if ! confirmar "¿Crear el commit y subirlo a $REMOTE/$BRANCH?"; then
			info "Cancelado. Los cambios siguen en el árbol de trabajo (sin commit)."
			exit 0
		fi

		git commit -m "$mensaje"
		ok "Commit creado: $(git log -1 --oneline)"
	fi

	info "Integrando cambios del remoto (rebase)…"
	if ! git pull --rebase "$REMOTE" "$BRANCH"; then
		err "No se pudo integrar $REMOTE/$BRANCH. Resuelve el conflicto y repite."
		git rebase --abort >/dev/null 2>&1 || true
		exit 1
	fi

	info "Subiendo a $REMOTE/$BRANCH…"
	if git push "$REMOTE" "$BRANCH"; then
		ok "Subido correctamente."
	else
		err "El push falló. Revisa las credenciales de GitHub."
		exit 1
	fi
}

cmd_bajar() {
	local guardados=false
	comprobar_repo
	fetch_remoto || true

	if [ -n "$(git status --porcelain)" ]; then
		info "Guardando cambios locales temporalmente…"
		git stash push -u -m "sincronizar_git: autostash $(date '+%Y-%m-%d %H:%M:%S')" >/dev/null
		guardados=true
	fi

	info "Trayendo cambios de $REMOTE/$BRANCH…"
	if ! git pull --rebase "$REMOTE" "$BRANCH"; then
		err "No se pudo actualizar (conflicto o red)."
		git rebase --abort >/dev/null 2>&1 || true
		if [ "$guardados" = true ]; then
			if git stash pop >/dev/null 2>&1; then
				ok "Cambios locales restaurados."
			else
				err "Tus cambios locales siguen guardados: git stash list / git stash pop"
			fi
		fi
		exit 1
	fi
	ok "Repositorio actualizado en $(git log -1 --oneline)"

	if [ "$guardados" = true ]; then
		if git stash pop >/dev/null 2>&1; then
			ok "Cambios locales restaurados."
		else
			err "Conflicto al restaurar tus cambios. Siguen en: git stash list"
			exit 1
		fi
	fi
}

CMD="${1:-}"
if [ $# -gt 0 ]; then shift; fi

ARGS=()
for arg in "$@"; do
	case "$arg" in
		-y|--si) SI=true ;;
		-h|--help) uso 0 ;;
		*) ARGS+=("$arg") ;;
	esac
done

case "$CMD" in
	estado|status) cmd_estado ;;
	subir|push)    cmd_subir "${ARGS[0]:-}" ;;
	bajar|pull)    cmd_bajar ;;
	""|-h|--help|ayuda|help) uso 0 ;;
	*)
		err "Comando desconocido: $CMD"
		uso 1
		;;
esac
