# Música y audio de fondo — Fuente NotebookLM

> **Propósito de este documento:** Describir el sistema de música de fondo implementado en **SIMS 0.33** para que NotebookLM y los chats externos dispongan del contexto completo al proponer nuevas pantallas, minijuegos o pistas de audio.

**Estado:** Implementado (autoload `Musica`).

---

## 1. Resumen

El juego tiene una **pista general** que suena en el menú, la escena principal y el resto de pantallas, y una **pista específica para el minijuego de cocina de comida rápida**. El cambio entre ambas es un fundido cruzado y la pista general se reanuda donde se quedó al salir del minijuego. El jugador puede silenciar la música desde el menú o la cabecera principal, y la preferencia se conserva entre sesiones.

---

## 2. Archivos y recursos

| Elemento | Ruta |
|---|---|
| Autoload de música | `Scripts/Globales/Musica.gd` |
| Pista general | `Sonidos/Musica/Lunchtime_Conspiracies.mp3` |
| Pista del minijuego | `Sonidos/Musica/Seven_Minutes_to_Service.mp3` |
| Preferencias | `user://configuracion_audio.cfg` |
| Documentación | `Funcionalidades/Musica/Documentacion/MUSICA.md` |
| Tests | `Funcionalidades/Musica/Tests/test_musica.gd` |

Los MP3 usan el importador nativo de Godot (`AudioStreamMP3`) y están configurados con `loop=true` en su archivo `.import`, por lo que el bucle es continuo y sin reinicios manuales.

---

## 3. Autoload `Musica`

- **Bus:** crea el bus `Musica` en tiempo de ejecución y lo envía a `Master`.
- **Reproductores:** `Reproductor_General` y `Reproductor_Minijuego` (`AudioStreamPlayer`, `PROCESS_MODE_ALWAYS`).
- **Fundido:** `0.9 s`, `Tween` senoidal; general a `-9 dB` y minijuego a `-7 dB`.
- **API pública:**
  - `Reproducir_General()`
  - `Reproducir_Minijuego()`
  - `Alternar_Silencio()` / `Establecer_Silencio(valor)`
  - `Esta_Silenciado()`
  - `Establecer_Volumen(0.0–1.0)` / `Obtener_Volumen()`
  - Señal `silencio_cambiado(silenciado: bool)`
- **Persistencia:** volumen y silencio en `user://configuracion_audio.cfg`.
- **Móvil:** pausa con `NOTIFICATION_APPLICATION_PAUSED` y reanuda con `NOTIFICATION_APPLICATION_RESUMED`.
- **Bucle de seguridad:** si un stream termina, el reproductor activo se reinicia.

---

## 4. Integración con escenas

- `Menu.gd` → `Musica.Reproducir_General()` en `_ready()`.
- `Script_Principal.gd` → `Musica.Reproducir_General()` en `_ready()`.
- `Minijuego_Cocina.gd` → `Musica.Reproducir_Minijuego()` en `_ready()` y `Musica.Reproducir_General()` en `_exit_tree()`.
- La pista general **no se detiene** al entrar al minijuego: se pausa conservando la posición y se reanuda al salir.
- Botones de altavoz: `Boton_Musica` (menú) y `Boton_Musica_Header` (cabecera principal). El icono cambia entre `volume-2` y `x`.

---

## 5. Reglas para futuras pistas

1. Guardar el archivo en `Sonidos/Musica/`.
2. Importarlo desde Godot y marcar `loop=true` en el `.import`; reimportar si se sustituye.
3. Añadir la constante de la pista y una función `Reproducir_*()` en `Musica.gd`.
4. Llamar a esa función al abrir la pantalla o minijuego y a `Reproducir_General()` al salir.
5. Evitar pausar o detener el autoload desde otras escenas: centralizar siempre el cambio en `Musica`.

---

## 6. Criterios de aceptación

- Al abrir el juego suena la pista general, tanto en el menú como en la escena principal.
- Al abrir el minijuego de cocina se funde a la segunda pista sin cortes ni silencios.
- Al cerrar el minijuego (botón de volver o salida forzada) vuelve la pista general en el punto donde estaba.
- El botón de altavoz silencia/restaura el bus completo y recuerda el estado tras reiniciar.
- En Android, al mandar la app a segundo plano la música se pausa y al volver se reanuda.
- Los MP3 hacen bucle continuo.
