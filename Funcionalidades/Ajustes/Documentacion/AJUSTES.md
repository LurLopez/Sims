# Ajustes globales del juego

Sistema de preferencias del jugador. En esta primera versión solo incluye
**audio**: volumen de la música y de los efectos de sonido, con silencio
independiente para cada bus y opción de restablecer los valores por defecto.

## Archivos

| Elemento | Ruta |
|---|---|
| Autoload de ajustes | `Scripts/Globales/Ajustes.gd` |
| Panel modal | `Scripts/GUI/Ajustes/Panel_Ajustes.gd` (`class_name Panel_Ajustes`) |
| Preferencias | `user://configuracion_ajustes.cfg` |
| Configuración antigua (solo migración) | `user://configuracion_audio.cfg` |
| Tests | `Funcionalidades/Ajustes/Tests/test_ajustes.gd` |

## Autoload `Ajustes`

Se registra en `project.godot` **antes** que `Musica`, porque es el encargado de
crear los buses de audio en tiempo de ejecución:

| Bus | Uso | Reproductores |
|---|---|---|
| `Musica` | Banda sonora | `Reproductor_General` y `Reproductor_Minijuego` de `Musica.gd` |
| `SFX` | Efectos de sonido | Pool de `Sonidos_Cocina.gd` y el reproductor de prueba del panel |

Ambos buses envían a `Master`. El volumen se aplica con
`AudioServer.set_bus_volume_db()` y el silencio con
`AudioServer.set_bus_mute()`. Un volumen a `0` también deja el bus muteado, para
que el silencio sea total (no solo `-60 dB`).

### API pública

Música:

- `Obtener_Volumen_Musica() -> float`
- `Establecer_Volumen_Musica(0.0–1.0)`
- `Esta_Silenciado_Musica() -> bool`
- `Establecer_Silencio_Musica(bool)` / `Alternar_Silencio_Musica()`

Efectos:

- `Obtener_Volumen_SFX() -> float`
- `Establecer_Volumen_SFX(0.0–1.0)`
- `Esta_Silenciado_SFX() -> bool`
- `Establecer_Silencio_SFX(bool)` / `Alternar_Silencio_SFX()`

Utilidades:

- `Probar_Efecto_Sonido()`: reproduce `Sonidos/SFX/ding.wav` en el bus `SFX`.
- `Restablecer_Audio()`: vuelve a `85 %` de música, `85 %` de efectos y sin
  silencios.
- Señal `ajustes_cambiados`: se emite al cambiar cualquier valor (sirve para
  refrescar la UI).
- Señales específicas: `volumen_musica_cambiado`, `volumen_sfx_cambiado`,
  `silencio_musica_cambiado` y `silencio_sfx_cambiado`.

`Musica.gd` mantiene su API histórica (`Obtener_Volumen()`,
`Establecer_Volumen()`, `Esta_Silenciado()`, `Establecer_Silencio()`,
`Alternar_Silencio()` y la señal `silencio_cambiado`) como delegación a
`Ajustes`, de modo que los botones de altavoz existentes siguen funcionando sin
cambios.

## Panel `Panel_Ajustes`

Overlay `CanvasLayer` con `layer = 120`, fondo oscurecido y tarjeta centrada
estilo BitLife. Se construye por completo en código con `Estilos_UI` y contiene:

- Cabecera roja con el icono `settings-2` y el título «AJUSTES».
- Bloque **Música** (icono `volume-2`, color rojo): porcentaje, botón de
  silencio, barra táctil y actualización inmediata de la música de fondo.
- Bloque **Efectos de sonido** (icono `sparkles`, color azul): porcentaje,
  botón de silencio, barra táctil y botón «Probar sonido».
- Botones **Restablecer** y **Hecho**.
- Cierre tocando fuera de la tarjeta, con `ui_cancel`/Escape o con «Hecho».

La barra de volumen es un `Control` propio (`Barra_Volumen`, clase interna del
panel) para no depender del tema del `HSlider`: dibuja la pista, el relleno y la
perilla, admite arrastre con ratón/táctil y ajuste con las flechas del teclado.
Al soltar la barra de efectos se reproduce una prueba; al subir el volumen
estando muteado se desactiva el silencio.

### Puntos de apertura

- Menú principal: botón `Boton_Ajustes` (icono `settings-2`) en la cabecera,
  junto al altavoz `Boton_Musica`. Abre `Panel_Ajustes` desde `Menu.gd`.
- Escena principal: botón `Boton_Ajustes_Header` en la cabecera roja, a la
  izquierda del altavoz. Abre `Panel_Ajustes` desde `Script_Principal.gd`.

Ambos scripts guardan una única referencia al panel para no abrir duplicados y
la liberan al recibir la señal `cerrado`.

## Persistencia y migración

`Ajustes` guarda el archivo `user://configuracion_ajustes.cfg`:

```ini
[audio]
volumen_musica=0.85
volumen_sfx=0.85
silencio_musica=false
silencio_sfx=false
```

- Las escrituras por arrastre se agrupan con un `Timer` de `0.35 s` para no
  escribir en disco en cada píxel. También se guarda al pausar la app o cerrar.
- Si el archivo nuevo no existe pero sí el antiguo
  `user://configuracion_audio.cfg` (usado antes por `Musica`), se importan
  `volumen` y `silenciado` como volumen/silencio de música. Los efectos usan el
  valor por defecto.
- El archivo antiguo no se borra.

## Efectos de sonido

`Sonidos_Cocina.gd` asigna sus reproductores al bus `SFX` (con caída a `Master`
si el bus no existiera) y ya no consulta el silencio de la música. Así el
jugador puede silenciar la banda sonora y seguir oyendo los efectos del
minijuego, o al revés.

## Añadir un ajuste nuevo

1. Añadir el campo y su API en `Ajustes.gd`, leyéndolo/escribiéndolo en
   `_Cargar_Configuracion()` y `_Guardar_Configuracion()` con valor por defecto
   para saves antiguos.
2. Añadir un bloque en `Panel_Ajustes.gd` (o una sección nueva si no es audio) y
   suscribirlo a `ajustes_cambiados`.
3. Documentar el ajuste y actualizar `MEGA_PROMPT_CONTEXTO.md` y
   `notebookLM/00_CONTEXTO_MAESTRO_Y_ROL.md`.

## Prueba rápida

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd \
	-gdir=res://Funcionalidades/Ajustes/Tests \
	-gdir=res://Funcionalidades/Musica/Tests -gexit
```

Los tests comprueban los buses, la aplicación de volumen/silencio, la
delegación de `Musica`, el bus `SFX` de la cocina y la construcción del panel.
