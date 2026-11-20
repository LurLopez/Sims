# Sprites del Minijuego de Cocina

Pack de **134 PNG** originales (arte generado por IA) con estética *Cooking Fever* para el escenario del minijuego: 2.5D casual, brillos suaves, colores saturados y perspectiva 3/4.

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
| Raíz | 1 | `Fondo_Restaurante.png` (1280×720) |

También contiene `escenario_layout.json`, el layout de 54 entradas que usa la escena de muestra.

## Ver el escenario

```bash
./ver_escenario.sh
```

Abre `Escenas/Minijuego_Cocina/Escenario_Cooking_Fever.tscn` a 1280×720.
`./ver_escenario.sh --captura` guarda una captura en `user://escenario_cocina_godot.png` y cierra.

La escena es una **maqueta visual independiente**: no está enganchada al minijuego jugable ni modifica su lógica.

## Documentación

- `Funcionalidades/Minijuego_Cocina/Documentacion/ARTE_SPRITES.md` — inventario, estilo, pipeline, uso en Godot, tamaños, limitaciones y aviso legal.
- `Funcionalidades/Minijuego_Cocina/Documentacion/MINIJUEGO_COCINA.md` — minijuego jugable (sección 10: pack de sprites).
- `Arte_Fuente/Minijuego_Cocina/` — prompts, hojas originales, maestros y catálogos visuales.
