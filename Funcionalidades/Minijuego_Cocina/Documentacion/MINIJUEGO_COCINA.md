# Minijuego de Cocina (*Cooking Fever*) + Apartado Minijuegos + Ropa Equipable

## 1. Resumen

Funcionalidad completa en Godot 4.4+ (GDScript 2.0) que añade:
- **Apartado modular de Minijuegos** (`Minijuegos_Button` en la barra superior de 5 botones + vista `Pantalla_Minijuegos` preparada para futuros minijuegos).
- **Minijuego de Cocina estilo *Cooking Fever*** (`Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn`) con rotación obligatoria a **horizontal (`1280×720`)** y retorno automático a **vertical (`720×1280`)**, ejecutado como overlay `CanvasLayer` sobre `Script_Principal` para que el reloj del Sim siga avanzando en tiempo real.
- **Desbloqueo al primer minuto real trabajado en hostelería** (`Trabajar_En_Comida_Rapida`, `Trabajar_De_Ayudante_Cocina`, `Trabajar_De_Cocinero_Partida`, `Trabajar_De_Chef_Ejecutivo`), nunca al programar el bloque, con notificación toast en pantalla, badge y mensaje en buzón.
- **Economía de doble moneda** (`Fondos_Cocina` para mejoras vs. `Dinero` del Sim para propinas/bonos), logros progresivos cada 5 niveles (**Rangos 0–9**) y **ropa equipable** (`Objeto_Ropa`, categoría `"Ropa"`) gestionable en **Perfil → Apuntes → Ropa**.

---

## 2. Arquitectura y Archivos

| Archivo | Rol |
|---|---|
| `Scripts/Logica/Escena_Principal/Minijuego_Cocina/Sistema_Cocina.gd` | Autoload `Sistema_Cocina`. Catálogo data-driven de 3 restaurantes (15 niveles de `burger_street`), 5 mejoras, fórmulas puras `static func`, desbloqueo, micro-recompensas, fin de nivel, logros y helpers de ropa. |
| `Scripts/Logica/Escena_Principal/Economia/Herencia/Objeto_Ropa.gd` | Subclase `Objeto_Ropa extends Objeto` (`bonus_salario_hosteleria`, `reduccion_higiene_trabajo`, `bonus_propinas_minijuego`, `descripcion_efecto`). |
| `Scripts/GUI/Minijuego_Cocina/Minijuego_Cocina.gd` | Controlador de la escena horizontal `1280×720`: Subvista 1 (Mapa + Modal Inicio + Modal 5 Mejoras), Subvista 2 (Cocina Jugable *tap-to-move*), Subvista 3 (Modal de Resultados) y rotación segura con salvaguarda en `_exit_tree()`. |
| `Scripts/GUI/Minijuego_Cocina/Sprites_Cocina.gd` | Sprites vectoriales 2.5D estilo *Cooking Fever*: fondo de diner con suelo ajedrezado y barra turquesa, 8 arquetipos de clientes expresivos, burbujas de pedido con barra de paciencia vertical, platos de cerámica con papel encerado, hamburguesas por capas, sartenes de hierro, freidora, dispensador de refrescos y bandejas de ingredientes. |
| `Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn` | Escena autocontenida del minijuego. |
| `Scripts/Globales/Principales_Variables/Variables_Dinamicas.gd` | `Cocina_Estado` (`COCINA_ESTADO_BASE` y `Cocina_Estado_Por_Defecto()`), defaults de `"Ropa_Calle"` y `Objeto_Seleccionado["Ropa"]`. |
| `Scripts/Globales/Principales_Variables/Variables_Estaticas.gd` | `Record_Max_Niveles_Cocina` y registro de las 5 prendas `Objeto_Ropa` en `Catalogo_Objetos`. |
| `Scripts/Otro/Guardar/Guardar_Variables_Dinamicas.gd` | Guardado/carga con merge recursivo (`_Normalizar_Cocina_Estado`) y fallback `"Ropa_Calle"` / `"Ropa"`. |
| `Scripts/Otro/Guardar/Guardar_Variables_Estaticas.gd` | Persistencia de `Record_Max_Niveles_Cocina` (fallback `0`). |
| `Scripts/Globales/Menu.gd` & `First_Time.gd` | Reseteo/inicialización limpia de `Cocina_Estado` y `"Ropa"` en nuevas partidas. |
| `Scripts/Logica/Escena_Principal/Actividades/Actividades.gd` | Desbloqueo al primer minuto trabajado y pago de nómina con bonus de ropa + `+10%` de `plus_nomina_turno_hoy`. |
| `Scripts/Logica/Escena_Principal/Actividades/Actividades_Necesidades_Basicas.gd` | Reducción de desgaste de Higiene (`-5%`) en empleos de hostelería según prenda equipada. |
| `Scripts/Logica/Escena_Principal/Actividades/Actividades_Habilidades.gd` | Bono Rango ≥ 5 (`+15%` eficiencia en `Progreso[2]` Manualidades y `Progreso_Cocina`). |
| `Scripts/Logica/Escena_Principal/Actividades/Alimentacion.gd` | Bonos Rango ≥ 2 (`+2` Salud Mental), Rango ≥ 4 (`-20%` coste comida rápida, `+15%` saciedad tupper) y Rango ≥ 7 (`+15%` recuperación Hambre y `+1` Salud Física). |
| `Scripts/Logica/Escena_Principal/Actividades/Eventos_Aleatorios.gd` | Inmunidad a `"Intoxicación alimentaria"` con Rango ≥ 8 (40 niveles). |
| `Escenas/Escena_Principal/Escena principal.tscn`, `Pantalla_Mensajes.tscn`, `Script_Principal.gd`, `Estilos_UI.gd`, `Gestionar_Visibilidad.gd` | Barra superior de 5 pestañas (`Minijuegos_Button`), `Pantalla_Minijuegos`, toast de desbloqueo, `Atuendo` y `Maestría Culinaria` en Perfil → Info, conmutador `Apuntes | Ropa` en Perfil → Apuntes. |
| `export_presets.cfg` | `permissions/set_orientation=true` en preset Android. |
| `Funcionalidades/Minijuego_Cocina/Tests/test_minijuego_cocina.gd` | Suite GUT (11 tests, 336 asserts). |

---

## 3. Reglas de Juego y Fórmulas

### Restaurantes y Desbloqueo
| Restaurante (`id`) | Trabajo requerido | Estado |
|---|---|---|
| `burger_street` (*Burger & Street Food*) | `Trabajar_En_Comida_Rapida` | Implementado (15 niveles, 60–90 s) |
| `bistro_tradicional` (*Bistró Tradicional*) | `Trabajar_De_Ayudante_Cocina` / `Trabajar_De_Cocinero_Partida` | Fase 2 (estructura preparada) |
| `alta_cocina` (*Alta Cocina Gourmet*) | `Trabajar_De_Chef_Ejecutivo` | Fase 2 (estructura preparada) |

### 5 Mejoras por Restaurante (`Fondos_Cocina`)
- **`plancha`**: Nv.1 (`2` huecos, `1` cesta, `×1.00`) → Nv.2 (`120`, `3` huecos, `2` cestas, `×0.80`) → Nv.3 (`320`, `4` huecos, `2` cestas, `×0.65`).
- **`emplatado`**: Nv.1 (`2` platos, `1` bebida `4.0 s`) → Nv.2 (`100`, `3` platos, `2` bebidas `2.5 s`) → Nv.3 (`280`, `4` platos, `3` bebidas `1.0 s`).
- **`termostato`**: Nv.1 (`6.0 s`) → Nv.2 (`90`, `8.1 s`) → Nv.3 (`240`, `10.5 s` + aviso temprano al 45%).
- **`ingredientes`**: Nv.1 (`×1.00`) → Nv.2 (`140`, `×1.25`) → Nv.3 (`360`, `×1.50`).
- **`ambiente`**: Nv.1 (`×1.00` paciencia/propinas) → Nv.2 (`110`, `×1.15` / `×1.20`) → Nv.3 (`300`, `×1.30` / `×1.40`).

### Fórmulas Puras (`Sistema_Cocina`)
- **Cocción:** `max(0.5, base * mult_plancha * (1 - 0.15 * Destreza/100))`
- **Quemado:** `base_termostato * (1 + 0.15 * Paciencia/100) * (0.85 si Resacón)`
- **Velocidad de paciencia:** `(1 / mult_ambiente) * (1 - 0.10 * Paciencia/100 - 0.10 * SangreFria/100) * (1.20 si Descanso < 25 o SaludMental < 25)`
- **Drops por cliente:**
  - `Progreso_Cocina`: `0.15 * (2.0 si En Turno) * (7.0 si Modo Rápido)`
  - `Progreso[2]` (Manualidades): `0.05 * (7.0 si Modo Rápido)`
  - Necesidad (`Salud_Mental` o `Hambre`): `12%` de `+1` (respetando caps de calle/bancarrota/resacón/intoxicación)
  - Micro-propina: `10%` de `2–5 € * Multiplicador_Precios()` con tope `15 € * Multiplicador_Precios()` por servicio.
- **Fin de nivel:**
  - `Fondos_Cocina += round(recaudacion * (1.5 si En Turno))`
  - Bono 1.ª vez por estrellas: `[15, 15, 20] € * Multiplicador_Precios()`
  - Propinas netas: `propinas_servicio * 0.50 * (1.5 si En Turno) * (1 + bonus_ropa_propinas) * Multiplicador_Precios()` (tope 2 servicios/día en modo libre; ilimitado en turno + marca `plus_nomina_turno_hoy = true`).

### Bloqueos de Entrada
No permite iniciar un servicio si:
1. `restaurantes_desbloqueados` está vacío.
2. `Necesidades_Basicas[3] <= 5` (Descanso crítico).
3. Hay un examen universitario (`Actividad_Examen`, P3) activo o a ≤ 5 minutos.

### Rangos de Maestría Culinaria (cada 5 niveles superados) y Ropa Equipable
| Rango | Niveles | Beneficio / Prenda |
|---|---|---|
| 1 | 5 | `Delantal_Aprendiz` (`-5%` desgaste Higiene hostelería) |
| 2 | 10 | `+2` extra Salud Mental al comer (`Comer_Tupper` / `Comer_Basura`) |
| 3 | 15 | `Chaqueta_Chef` (`+10%` salario hostelería, `-5%` Higiene) |
| 4 | 20 | `-20%` coste en `Comer_Basura` y `+15%` saciedad en `Comer_Tupper` |
| 5 | 25 | `+15%` eficiencia en `Progreso[2]` (Manualidades) y `Progreso_Cocina` |
| 6 | 30 | `Atuendo_Chef_Gala` (`+20%` salario hostelería, `-5%` Higiene) |
| 7 | 35 | `+15%` velocidad recuperación Hambre y `+1` Salud Física al comer |
| 8 | 40 | Inmunidad total al evento aleatorio `"Intoxicación alimentaria"` |
| 9 | 45 | `Traje_Estrella_Michelin` (`+30%` salario hostelería, `-5%` Higiene, `+25%` propinas) |

---

## 4. Tests GUT

Ejecución:
```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://Funcionalidades/Minijuego_Cocina/Tests -gexit
```
Suite completa de no regresión:
```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://Funcionalidades -ginclude_subdirs -gexit
```

---

## 10. Pack de sprites del escenario

Además del sistema jugable, el proyecto incluye un pack de **134 sprites PNG** y una escena de muestra a `1280×720` con la composición del restaurante: chef, clientes, tickets, vitrina, estaciones y primer plano de acero inoxidable.

- Sprites: `Imagenes/Minijuego_Cocina/` (chef + 6 poses, 8 clientes + 8 enfadados, 32 comidas, 8 estaciones, 8 piezas de mostrador, 22 de emplatado/props, 24 de UI, 8 de decoración, 8 efectos y fondo).
- Layout: `Imagenes/Minijuego_Cocina/escenario_layout.json` (58 entradas).
- Escena editable: `Escenas/Minijuego_Cocina/Escenario_Cooking_Fever.tscn`; se abre con `./ver_escenario.sh` (o `./ver_escenario.sh --captura` para guardar una captura y cerrar).
- Captura y catálogos: `Arte_Fuente/Minijuego_Cocina/` (fuera de `res://` por `.gdignore`).
- Documentación detallada: [`ARTE_SPRITES.md`](ARTE_SPRITES.md) — inventario completo, estilo, pipeline, integración en Godot, tamaños, limitaciones y aviso legal.
- La escena es una **maqueta visual independiente**: no se instancia desde el minijuego jugable ni modifica su lógica, y este sigue usando los sprites vectoriales de `Sprites_Cocina.gd`.
