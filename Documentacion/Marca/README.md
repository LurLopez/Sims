# Marca y logo — Sims Life

## Resumen

El juego usa **dos capas de marca**:

| Capa | ¿Dinámica? | Dónde |
|---|---|---|
| Icono de Play Store | ❌ Fijo | `Imagenes/Marca/logo_play_store_512.png` |
| Icono del lanzador Android / APK | ❌ Fijo | `icon.svg` → `Iconos_Android/` |
| Logo dentro del juego | ✅ Cara del Sim creado | `Scripts/GUI/Menu/Logo_Juego.gd` |

La idea es que la ficha de Play Store tenga una marca estable y reconocible, mientras que
dentro del juego el logo muestre al protagonista que el jugador ha creado.

## Logo dinámico (in-game)

`Scripts/GUI/Menu/Logo_Juego.gd` (`class_name Logo_Juego`) es un `HBoxContainer` reutilizable:

- **Insignia circular**: sombra, aro blanco, anillo rojo, aro interior de tinta y máscara circular.
- **Cara**: `Personaje_Visual` en modo `retrato_cercano` (encuadre cerrado para insignia),
  alimentado por `Variables_Estaticas.Apariencia`.
- **Wordmark**: `SIMS` en Bricolage 800 + pastilla `LIFE` + subtítulo.
- **Destello**: icono `sparkles` dorado como guiño de pegatina cómic.

Se usa en el menú principal (`Scripts/Globales/Menu.gd`). Al volver al menú después de
crear un personaje, la insignia dibuja automáticamente su cara, pelo, gafas, pecas, ropa, etc.

Para actualizar la cara sin reconstruir el logo:

```gdscript
logo.configurar_apariencia(Variables_Estaticas.Apariencia)
```

## Icono fijo de Play Store

- `Imagenes/Marca/logo_play_store_512.png` — **subir este** en Play Console (512×512, PNG 32 bits).
- `Imagenes/Marca/logo_play_store_1024.png` — maestro en alta resolución.
- `Imagenes/Marca/feature_graphic_1024x500.png` — gráfico destacado opcional de la ficha.
- `Imagenes/Marca/logo_horizontal_1024x240.png` — lockup sobre fondo rojo (web, prensa, capturas).
- `Imagenes/Marca/logo_horizontal_claro_1024x240.png` — lockup sobre fondo claro.

El icono de Play Store **no cambia por usuario**: se sube una vez por versión en la consola.
Play Store jamás muestra un icono generado en el dispositivo.

## Icono del lanzador Android

Android **no permite** que una app cambie su icono de lanzador por un bitmap generado en
tiempo de ejecución. El icono se declara en el manifiesto y el lanzador lo cachea.

Lo que sí existe es `activity-alias`: se pueden declarar varios iconos predefinidos y activar
uno u otro con `PackageManager.setComponentEnabledSetting()`. Eso permitiría, por ejemplo,
tener 4–6 caras pre-renderizadas y elegir una, pero **no** el Sim aleatorio creado por el jugador.

Por eso el APK y la ficha usan el icono fijo, y la personalización se queda dentro de la app
(menú, avatar de la barra superior y perfil).

## Regenerar assets

```bash
# Iconos del lanzador / APK desde icon.svg
godot --headless --path . --script res://Scripts/Otro/Herramientas/Generar_Iconos_Android.gd

# Lockup horizontal + feature graphic con la apariencia guardada
godot --path . --script res://Scripts/Otro/Herramientas/Exportar_Logo_Marca.gd
```

`Exportar_Logo_Marca.gd` necesita ventana (no `--headless`) porque captura un `SubViewport`
con el renderizado real de Godot.

## Archivos

```
Imagenes/Marca/
├── logo_play_store_512.png
├── logo_play_store_1024.png
├── feature_graphic_1024x500.png
├── logo_horizontal_1024x240.png
└── logo_horizontal_claro_1024x240.png

Scripts/GUI/Menu/Logo_Juego.gd
Scripts/Otro/Herramientas/Generar_Iconos_Android.gd
Scripts/Otro/Herramientas/Exportar_Logo_Marca.gd
icon.svg
Iconos_Android/
```
