# Sprites del Minijuego de Cocina

Pack de **149 PNG** originales (arte generado por IA) con estética de cocina casual para el escenario del minijuego: 2.5D casual, brillos suaves, colores saturados y perspectiva 3/4. Además del pack, la carpeta contiene **3 recursos de composición** para el banner de la tarjeta «Cocina» y el selector de niveles (ver más abajo), que no se cuentan entre los 149 sprites.

## Carpetas

| Carpeta | Nº | Contenido |
|---|---:|---|
| `Chef/` | 7 | Chef protagonista + `Poses/` con 6 expresiones |
| `Clientes/` | 8 | Bustos de clientes |
| `Clientes/Enojados/` | 8 | Versiones enfadadas de los mismos clientes |
| `Comida/Platos/` | 8 | Platos terminados e iconos de pedido |
| `Comida/Ingredientes/` | 12 | Ingredientes y estados de carne/salchicha |
| `Comida/Extras/` | 12 | Platos y bebidas extra |
| `Estaciones/` | 8 | Máquinas de cocina |
| `Mostrador/` | 8 | Módulos, vitrina, caja y tiras de mostrador |
| `Emplatado/` | 22 | Platos, bandejas, salsas y props |
| `UI/` | 24 | HUD, tickets, monedas, botones y estrellas |
| `Decoracion/` | 8 | Toldos, rótulos, planta, lámpara y trofeo |
| `Efectos/` | 8 | Vapor, humo, chispas, fuego, monedas, estrellas, frescura y enfado |
| `Mejoras/` | 15 | Tres variantes por mejora (plancha, emplatado, termostato, ingredientes y ambiente) |
| Raíz | 1 | `Fondo_Restaurante.png` (1280×720) |

También contiene `escenario_layout.json`, el layout de 54 entradas que usa la escena de muestra.

## Recursos de composición (fuera de los 149)

| Archivo | Tamaño | Uso |
|---|---|---|
| `Banner_Cocina.png` | 1288×284 | Fondo del banner de la tarjeta «Cocina» de `Pantalla_Minijuegos`: mostrador de diner con damero crema/negro, borde metálico y comedor desenfocado. Lleva horneados el desenfoque, la viñeta y la luz cálida. |
| `Emplatado/Plato_Perspectiva.png` | 640×297 | Plato vacío de cerámica blanca en perspectiva 3/4 (ala, hueco y brillos) para el banner, en lugar del plato cenital `Plato_Vacio.png`. |
| `Fondo_Restaurante_Selector.png` | 360×640 | Fondo vertical desenfocado y viñeteado del selector cartoon de niveles, generado con `tools/generar_fondo_selector.py` a partir del fondo del restaurante. |

Los maestros de IA del banner y el plato viven fuera de Godot: `Arte_Fuente/Minijuego_Cocina/Fondos/banner_cocina_maestro.png` (1913×822) y `Arte_Fuente/Minijuego_Cocina/plato_perspectiva_maestro.png` (1336×1177). Con estos tres recursos, `Imagenes/Minijuego_Cocina/` suma **152 PNG**: 149 del pack + 3 de composición.

## Ilustraciones de Mejoras

`Mejoras/` contiene 15 PNG (3 por cada una de las 5 mejoras) que usa la pantalla `Mejoras_Cocina.gd`:

- `plancha_nv1..3` — sartén/plancha con 2, 3 y 4 hamburguesas.
- `emplatado_nv1..3` — 2 platos + 1 refresco, 3 + 2 y 4 + 3.
- `termostato_nv1..3` — dial manual, dial de precisión y panel digital.
- `ingredientes_nv1..3` — caja de madera, bandeja de acero y cesta premium.
- `ambiente_nv1..3` — jukebox de mesa, de diner y de lujo.

Se generan desde las hojas maestras de `Arte_Fuente/Minijuego_Cocina/Mejoras/` con:

```bash
python3 tools/procesar_mejoras_cocina.py
```

El script recorta las tres variantes, limpia el halo blanco, aplica un despill de magenta fuerte, limita el lado mayor a 640 px y compone el catálogo `catalogo_mejoras.png`.

## Ver el escenario

```bash
./ver_escenario.sh
```

Abre `Escenas/Minijuego_Cocina/Escenario_Maqueta_Cocina.tscn` a 1280×720.
`./ver_escenario.sh --captura` guarda una captura en `user://escenario_cocina_godot.png` y cierra.

El pack **ya está integrado en el minijuego jugable** mediante `Arte_Cocina.gd` (fondo, clientes, chef, estaciones, comida, UI, efectos y animaciones). `Escenario_Maqueta_Cocina.tscn` sigue siendo una maqueta visual para revisar el arte completo.

## Documentación

- `Funcionalidades/Minijuego_Cocina/Documentacion/ARTE_SPRITES.md` — inventario, estilo, pipeline, uso en Godot, tamaños, limitaciones y aviso legal.
- `Funcionalidades/Minijuego_Cocina/Documentacion/MINIJUEGO_COCINA.md` — minijuego jugable (sección 10: pack de sprites).
- `Arte_Fuente/Minijuego_Cocina/` — prompts, hojas originales, maestros y catálogos visuales.
