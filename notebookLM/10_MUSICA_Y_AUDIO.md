# Música, efectos de sonido y ajustes de audio — Fuente NotebookLM

> **Propósito de este documento:** Describir el sistema de música de fondo implementado en **SIMS 0.33** para que NotebookLM y los chats externos dispongan del contexto completo al proponer nuevas pantallas, minijuegos o pistas de audio.

**Estado:** Implementado (autoloades `Ajustes` y `Musica`).

---

## 1. Resumen

El juego tiene una **pista general** que suena en el menú, la escena principal y el resto de pantallas, y una **pista específica para el minijuego de cocina de comida rápida**. El cambio entre ambas es un fundido cruzado y la pista general se reanuda donde se quedó al salir del minijuego. El jugador puede silenciar la música desde el menú o la cabecera, y dispone de un panel de **Ajustes** con volumen y silencio independientes para música y efectos de sonido. Las preferencias se conservan entre sesiones.

---

## 2. Archivos y recursos

| Elemento | Ruta |
|---|---|
| Autoload de ajustes | `Scripts/Globales/Ajustes.gd` |
| Panel modal de ajustes | `Scripts/GUI/Ajustes/Panel_Ajustes.gd` |
| Autoload de música | `Scripts/Globales/Musica.gd` |
| Pista general | `Sonidos/Musica/Lunchtime_Conspiracies.mp3` |
| Pista del minijuego | `Sonidos/Musica/Seven_Minutes_to_Service.mp3` |
| Preferencias de audio | `user://configuracion_ajustes.cfg` |
| Configuración antigua (migración) | `user://configuracion_audio.cfg` |
| Documentación | `Funcionalidades/Musica/Documentacion/MUSICA.md` y `Funcionalidades/Ajustes/Documentacion/AJUSTES.md` |
| Tests | `Funcionalidades/Musica/Tests/test_musica.gd` y `Funcionalidades/Ajustes/Tests/test_ajustes.gd` |

Los MP3 usan el importador nativo de Godot (`AudioStreamMP3`) y están configurados con `loop=true` en su archivo `.import`, por lo que el bucle es continuo y sin reinicios manuales.

---

## 3. Autoload `Musica`

- **Bus:** `Ajustes` crea el bus `Musica` y lo envía a `Master`; `Musica` lo reutiliza.
- **Reproductores:** `Reproductor_General` y `Reproductor_Minijuego` (`AudioStreamPlayer`, `PROCESS_MODE_ALWAYS`).
- **Fundido:** `0.9 s`, `Tween` senoidal; general a `-9 dB` y minijuego a `-7 dB`.
- **API pública:**
  - `Reproducir_General()`
  - `Reproducir_Minijuego()`
  - `Alternar_Silencio()` / `Establecer_Silencio(valor)`
  - `Esta_Silenciado()`
  - `Establecer_Volumen(0.0–1.0)` / `Obtener_Volumen()`
  - Señal `silencio_cambiado(silenciado: bool)`
- **Persistencia:** las preferencias las guarda `Ajustes` en `user://configuracion_ajustes.cfg`; la API de música delega en él.
- **Móvil:** pausa con `NOTIFICATION_APPLICATION_PAUSED` y reanuda con `NOTIFICATION_APPLICATION_RESUMED`.
- **Bucle de seguridad:** si un stream termina, el reproductor activo se reinicia.

---

## 4. Autoload `Ajustes` y bus `SFX`

- `Ajustes` se carga **antes** que `Musica` y crea los buses `Musica` y `SFX` (ambos envían a `Master`).
- Volumen y silencio independientes por bus; un volumen a `0` también mutea el bus.
- API: `Obtener/Establecer_Volumen_Musica`, `Obtener/Establecer_Volumen_SFX`, `Esta_Silenciado_Musica/SFX`, `Establecer_Silencio_Musica/SFX`, `Alternar_Silencio_Musica/SFX`, `Probar_Efecto_Sonido()` y `Restablecer_Audio()`.
- Señal `ajustes_cambiados` para refrescar la UI y señales específicas por valor.
- `Sonidos_Cocina.gd` reproduce sus 15 SFX en el bus `SFX`, por lo que se puede silenciar la música sin perder los efectos (y viceversa).
- El panel `Panel_Ajustes` (`CanvasLayer` 120) ofrece dos barras táctiles, porcentajes, botones de silencio, «Probar sonido», «Restablecer» y «Hecho». Se abre con `Boton_Ajustes` (menú) y `Boton_Ajustes_Header` (escena principal).

---

## 5. Integración con escenas

- `Menu.gd` → `Musica.Reproducir_General()` en `_ready()`.
- `Script_Principal.gd` → `Musica.Reproducir_General()` en `_ready()`.
- `Minijuego_Cocina.gd` → `Musica.Reproducir_Minijuego()` en `_ready()` y `Musica.Reproducir_General()` en `_exit_tree()`.
- La pista general **no se detiene** al entrar al minijuego: se pausa conservando la posición y se reanuda al salir.
- Botones de altavoz: `Boton_Musica` (menú) y `Boton_Musica_Header` (cabecera principal). El icono cambia entre `volume-2` y `x`.
- Botones de engranaje: `Boton_Ajustes` (menú) y `Boton_Ajustes_Header` (cabecera principal) abren `Panel_Ajustes`.

---

## 6. Reglas para futuras pistas

1. Guardar el archivo en `Sonidos/Musica/`.
2. Importarlo desde Godot y marcar `loop=true` en el `.import`; reimportar si se sustituye.
3. Añadir la constante de la pista y una función `Reproducir_*()` en `Musica.gd`.
4. Llamar a esa función al abrir la pantalla o minijuego y a `Reproducir_General()` al salir.
5. Evitar pausar o detener el autoload desde otras escenas: centralizar siempre el cambio en `Musica`.

---

## 7. Criterios de aceptación

- Al abrir el juego suena la pista general, tanto en el menú como en la escena principal.
- Al abrir el minijuego de cocina se funde a la segunda pista sin cortes ni silencios.
- Al cerrar el minijuego (botón de volver o salida forzada) vuelve la pista general en el punto donde estaba.
- El botón de altavoz silencia/restaura el bus de música y recuerda el estado tras reiniciar.
- El panel de Ajustes permite subir/bajar música y efectos por separado, silenciarlos, probar el efecto y restablecer; los valores se conservan tras reiniciar.
- Silenciar la música no silencia los efectos del minijuego (bus `SFX` independiente).
- En Android, al mandar la app a segundo plano la música se pausa y al volver se reanuda.
- Los MP3 hacen bucle continuo.
