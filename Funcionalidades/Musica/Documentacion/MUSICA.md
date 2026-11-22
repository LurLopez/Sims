# Música de fondo

Sistema global de música del juego basado en el autoload `Musica`
(`Scripts/Globales/Musica.gd`). Mantiene una pista general para menú/escena
principal y una pista específica para el minijuego de cocina de comida rápida.

## Pistas

| Uso | Archivo | Bucle |
|---|---|---|
| Juego general (menú, escena principal, resto de pantallas) | `Sonidos/Musica/Lunchtime_Conspiracies.mp3` | Sí (`loop=true` en el `.import`) |
| Minijuego de cocina / comida rápida | `Sonidos/Musica/Seven_Minutes_to_Service.mp3` | Sí (`loop=true` en el `.import`) |

Los MP3 se importan con el importador nativo de Godot (`AudioStreamMP3`). El
bucle se configura en los archivos `.import`; si se sustituye una pista hay que
volver a marcar `loop=true` y reimportar (`godot --headless --path . --import`).

## Autoload `Musica`

- Crea el bus de audio `Musica` en tiempo de ejecución (envía a `Master`) y dos
  `AudioStreamPlayer`: `Reproductor_General` y `Reproductor_Minijuego`.
- Arranca automáticamente la pista general al iniciar el juego.
- `Reproducir_General()`: fundido cruzado a la pista general. Si venía del
  minijuego, la general se reanuda exactamente donde se pausó.
- `Reproducir_Minijuego()`: fundido cruzado a la pista del minijuego.
- `Alternar_Silencio()` / `Establecer_Silencio(valor)`: silencia o restaura el
  bus de música. Emite `silencio_cambiado(silenciado)`.
- `Establecer_Volumen(0.0–1.0)` / `Obtener_Volumen()`: volumen del bus.
- Estas funciones delegan en el autoload `Ajustes`, que es el propietario del
  bus y de las preferencias (`user://configuracion_ajustes.cfg`). El archivo
  antiguo `user://configuracion_audio.cfg` se migra automáticamente la primera
  vez. Ver `Funcionalidades/Ajustes/Documentacion/AJUSTES.md`.
- En Android, la música se pausa con `NOTIFICATION_APPLICATION_PAUSED` y se
  reanuda con `NOTIFICATION_APPLICATION_RESUMED`.
- Si un MP3 termina por cualquier motivo (por ejemplo, un import sin bucle), el
  reproductor activo se reinicia solo.

Detalles del fundido: `0.9 s`, con `Tween` senoidal y volumen general `-9 dB` /
minijuego `-7 dB`. El reproductor general no se detiene al entrar al minijuego:
queda pausado (`stream_paused`) para conservar la posición.

La pista general se precarga porque suena desde el menú. La del minijuego
(`RUTA_PISTA_MINIJUEGO`, 4,3 MB) se carga de forma diferida en el primer
`Reproducir_Minijuego()` y se guarda en `_pista_minijuego`: así el arranque del
APK no lee ese MP3 ni crea el segundo reproductor con stream.

## Integración

- `Menu.gd` y `Script_Principal.gd` llaman a `Musica.Reproducir_General()` al
  cargar, garantizando la pista correcta tras cualquier cambio de escena.
- `Minijuego_Cocina.gd` llama a `Musica.Reproducir_Minijuego()` en `_ready()` y a
  `Musica.Reproducir_General()` en `_exit_tree()`, de modo que cualquier salida
  del minijuego (botón, muerte del Sim o cierre de escena) restaura la general.
- El audio se controla con un único botón de ajustes: engranaje `Boton_Ajustes`
  (menú) / `Boton_Ajustes_Header` (cabecera de la escena principal, icono
  `settings`). Abre `Panel_Ajustes`, donde se regulan por separado el volumen y
  el silencio de la música y de los efectos (bus `SFX`). Ya no hay botones de
  altavoz en el menú ni en la cabecera, y se eliminaron
  `_on_boton_musica_pressed`, `_on_musica_silencio_cambiado`,
  `_Actualizar_Boton_Musica` (en `Script_Principal.gd` y `Menu.gd`) y la
  conexión a `Musica.silencio_cambiado`.
- Los efectos del minijuego (`Sonidos_Cocina.gd`) usan el bus `SFX`, no el de
  música; silenciar uno no afecta al otro.

## Añadir una pista nueva

1. Copiar el archivo a `Sonidos/Musica/` y ejecutar la importación de Godot.
2. Marcar `loop=true` en el `.import` y reimportar.
3. Añadir la constante `PISTA_*` en `Musica.gd` y una función
   `Reproducir_*()` que llame a `_Cambiar_Pista()`.
4. Llamar a esa función al abrir la pantalla/minijuego correspondiente y a
   `Reproducir_General()` al salir.

## Prueba rápida headless

```bash
godot --headless --path . --import
```

Tests GUT del sistema:

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd \
	-gdir=res://Funcionalidades/Musica/Tests -gexit
```

Una prueba de integración puede instanciar `Minijuego_Cocina.tscn`, esperar al
fundido y comprobar que `Musica._pista_activa` pasa a `MINIJUEGO`; al liberar la
instancia debe volver a `GENERAL` y el reproductor general debe quedar
despausado.
