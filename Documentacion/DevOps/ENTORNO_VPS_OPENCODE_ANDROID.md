# Entorno de desarrollo remoto · OpenCode Web + Android + Google Drive

Este documento describe la infraestructura configurada en el equipo de desarrollo
(`/home/lur`) para trabajar en **SIMS 0.33** desde el navegador de un móvil,
compilar APK Android en headless y publicarlos en Google Drive.

> No es un VPS externo: es un equipo Linux Mint 22.1 doméstico con IP pública
> dinámica. Por eso el acceso remoto usa un túnel HTTPS (OpenTunnel) en lugar de
> abrir puertos del router o depender de Nginx/Caddy.

## 1. Chat web 24/7

| Elemento | Valor |
|---|---|
| Interfaz | OpenCode Web V2 (la antigua orden `opencode web` ya no existe; el servidor es `opencode serve`) |
| Servicio | `opencode-web.service` (systemd de usuario) |
| Escucha | `127.0.0.1:4096` |
| URL pública | `https://2eb947ae0e058eba.og745fnao4l5.opentunnel.xyz` |
| Contraseña | `~/.config/opencode/web.env` (`OPENCODE_PASSWORD`) |
| Proyecto por defecto | `/home/lur/sims-0.33` |
| Túnel | `opentunnel-default.service` (OpenTunnel, HTTPS de extremo a extremo) |
| Linger | Activado (`loginctl enable-linger lur`), arranca sin iniciar sesión |

Comandos útiles:

```bash
~/iniciar_opencode_web.sh              # estado + URL + contraseña
~/iniciar_opencode_web.sh --reiniciar
~/iniciar_opencode_web.sh --detener
systemctl --user status opencode-web opentunnel-default
~/.local/bin/opentunnel status
journalctl --user -u opencode-web -n 50
```

En el móvil: abrir la URL pública → **«Usar contraseña»** → pegar la clave de
`~/.config/opencode/web.env`. La sesión del navegador dura 30 días.

El servicio usa el binario `opencode-cli` 2.3.2 que trae la app de escritorio
(`~/.config/ai.opencode.desktop/cli/2.3.2-x64/opencode-cli`), para que la web y
el escritorio compartan la misma versión del servidor y la misma base de datos.

## 2. Cuentas de modelos

```bash
opencode auth list
```

- **OpenCode Go**: ya vinculado (API key guardada). Sus modelos aparecen como
  `opencode-go/...` en el selector.
- **Google AI Pro / Gemini**: pendiente de vincular por el usuario con `/connect`
  (flujo OAuth interactivo; no se puede automatizar sin sus credenciales).
- También hay claves de DeepSeek y OpenAI ya guardadas.

No hace falta tocar `~/.config/opencode/opencode.jsonc` para que convivan: el
selector de modelos muestra todos los proveedores autenticados.

## 3. Toolchain Android (sin root)

| Herramienta | Ruta / versión |
|---|---|
| Godot | `~/.local/bin/godot` · 4.7.2.stable (el proyecto declara features 4.7) |
| Export templates | `~/.local/share/godot/export_templates/4.7.2.stable/` |
| JDK | `~/opt/jdk-17.0.21.1+2` (Temurin 17) |
| Android SDK | `~/android-sdk` (cmdline-tools latest, platform-tools, build-tools 34/35/36, platforms 34/35/36) |
| Keystore | `~/android-sdk/sims_debug.keystore` (copia del debug histórico, alias `androiddebugkey`, pass `android`) |
| Package | `com.lur.sims033` |
| Firma | APK debug v2+v3, certificado `CN=Android Debug` SHA-256 `3447dc1d…ea0e9d` |

El keystore es **el mismo que usaban los builds anteriores**. No lo sustituyas:
Android solo permite actualizar sin desinstalar si coinciden package name y firma.
La partida vive en `user://guardado/`, así que una actualización normal la conserva.

Ajustes de Godot en `~/.config/godot/editor_settings-4.7.tres`:
`export/android/android_sdk_path`, `java_sdk_path`, `debug_keystore`,
`debug_keystore_user` y `debug_keystore_pass`.

## 4. Compilar y subir a Drive

```bash
cd /home/lur/sims-0.33
./scripts_vps/crear_apk_drive.sh                  # GUT + import + APK debug + Drive
./scripts_vps/crear_apk_drive.sh --skip-tests     # sin GUT
./scripts_vps/crear_apk_drive.sh --no-upload      # solo local
```

El script:

1. Ejecuta GUT headless sobre `res://Funcionalidades` y aborta si falla.
2. Reimporta recursos (`--import`).
3. Exporta a `/tmp/sims-0.33-AAAAMMDD-HHMM.apk` y `/tmp/sims-latest.apk`.
4. Sube ambos a `gdrive:SIMS_Builds/` y pide el enlace directo con `rclone link`.
5. Conserva solo los 2 APK con timestamp más recientes en `/tmp/`.

Destino en Drive: **`SIMS_Builds/sims-latest.apk`** (siempre el último build).
Enlace directo del último build: <https://drive.google.com/open?id=1LdZ0m7h0WeitA3uMDTVpGlm9M1YPHOYk>.

### Vincular Google Drive (paso manual)

El remoto `gdrive:` ya está creado en `~/.config/rclone/rclone.conf` con
`type = drive`, `scope = drive`, pero **sin token OAuth**. Para autorizarlo:

```bash
rclone config reconnect gdrive:
```

Se abre el navegador; inicia sesión con la cuenta de Google y acepta. Al terminar:

```bash
rclone lsd gdrive:          # debe listar sin error
```

Si rclone avisa de que el `client_id` compartido está retirado, crea uno propio
tipo *Desktop app* en Google Cloud Console y añádelo:

```bash
rclone config update gdrive client_id TU_CLIENT_ID client_secret TU_SECRET
rclone config reconnect gdrive:
```

## 5. Verificación realizada

- `godot --headless --version` → `4.7.2.stable.official.ed1daf0bf`.
- GUT: **253 tests, 253 passing, 0 failing** (1999 aserciones).
- Export debug: APK de **68 MB**, `arm64-v8a`, `targetSdk 36`, firmado y verificado
  con `apksigner` (v2/v3), `screenOrientation=1` (portrait).
- Web UI: conectada por HTTPS con contraseña; lista proyectos y sesiones de
  `sims-0.33` correctamente.
- `opencode-web.service` y `opentunnel-default.service`: `enabled` + `Linger=yes`.

## 6. Diferencias respecto al plan original

- **Godot 4.7.2**, no 4.4.1: el proyecto ya declara `config/features=("4.7")` y
  las templates instaladas son 4.7.2. Instalar 4.4.1 rompería el proyecto.
- **`com.lur.sims033`**, no `com.lur.simslife`: cambiarlo habría creado otra app
  y roto la continuidad de partidas/actualizaciones.
- **OpenTunnel + systemd de usuario**, no Nginx/Caddy/Tailscale: no hay servidor
  web instalado, no hay Tailscale y `sudo` requiere contraseña. OpenTunnel da
  HTTPS y una URL estable sin abrir puertos ni tocar el router.
- **`opencode serve`**, no `opencode web`: en OpenCode V2 el subcomando `web` no
  existe; la web se sirve desde el mismo servidor que la TUI.
- `tmux` se instaló en `~/.local` (extraído de paquetes `.deb`) porque no hay
  acceso a `apt` sin contraseña; los servicios usan systemd, no tmux.
