# CLAUDE.md — Contexto del proyecto SIMS

## Reglas Godot 4.4
- GDScript válido para Godot 4.4 únicamente. No sintaxis de Godot 3.
- Autoloads se usan directamente como globales — no `get_node`, no imports.
- Rutas de recursos: `res://` (relativo a la carpeta `JOKUA/`).
- **Crítico:** al comparar celdas con strings usar `celda is String and celda == "Actividad_Aleatoria"` — nunca comparar directamente con un objeto `Actividad`.

---

## Autoloads (project.godot)

| Nombre global | Archivo |
|---|---|
| `Variables_Dinamicas` | `Scripts/Globales/Principales_Variables/Variables_Dinamicas.gd` |
| `Variables_Estaticas` | `Scripts/Globales/Principales_Variables/Variables_Estaticas.gd` |
| `Guardar_Variables_Dinamicas` | `Scripts/Otro/Guardar/Guardar_Variables_Dinamicas.gd` |
| `Guardar_Variables_Estaticas` | `Scripts/Otro/Guardar/Guardar_Variables_Estaticas.gd` |
| `Funciones_Globales` | `Scripts/Globales/Funciones_Globales.gd` |
| `Trabajo` | `Scripts/Logica/Escena_Principal/Actividades/Trabajo/Trabajo.gd` |
| `Actividades` | `Scripts/Logica/Escena_Principal/Actividades/Actividades.gd` |
| `Actividades_Habilidades` | `Scripts/Logica/Escena_Principal/Actividades/Actividades_Habilidades.gd` |
| `Actividades_Necesidades_Basicas` | `Scripts/Logica/Escena_Principal/Actividades/Actividades_Necesidades_Basicas.gd` |
| `Gestionar_Visibilidad` | `Scripts/GUI/Escena_Principal/Gestionar_Visibilidad.gd` |

---

## Estructura de escenas

| Archivo | Líneas | Contenido |
|---|---|---|
| `Escenas/Escena_Principal/Escena principal.tscn` | ~1634 | Root + barra nav + paneles stats + calendario actividades |
| `Escenas/Escena_Principal/Tienda.tscn` | ~869 | Pantalla tienda (objetos Dormir/Comer/Duchar) |
| `Escenas/Escena_Principal/Pantalla_Mensajes.tscn` | ~235 | Pantalla perfil (Mensajes/Info/Apuntes) |

`Tienda` y `Pantalla_Mensajes` son instancias en la escena principal. Los paths de nodo desde el root son idénticos (`$Tienda/Objetos_Dormir/Cama_Basica`, etc.) — los scripts no cambian.

### Nodos de primer nivel (Escena principal)

```
Node2D (root, Script_Principal.gd)
├── Top_Bar_Panel
├── Barra_Abajo → Boton_Habilidades · Boton_Progreso · Boton_Actividades · Boton_Necesidades_Basicas
├── Fondo
├── Progreso (oculto) → Panel_BG · Progreso_Barra/[Deporte|Academico|Manualidades] · Progreso_Texto/[...]
├── Necesidades_Basicas → Necesidades_Basicas_Barra/[Salud_Fisica|Salud_Mental|Hambre|Descanso|Higiene]
├── Trabajo (oculto) → Actividades_Trabajo_Opciones2 · Actividades_Trabajo_Nomina_Opciones/[COMIDA_RAPIDA|CARPINTERO|CIENTIFICO]
├── Habilidades (oculto) → Habilidades_Barra/[Slot_0..4] · Habilidades_Texto/[Slot_0..4]
├── Actividades
│   ├── Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/[Necesidades_Basicas_Opciones|Progreso_Opciones]
│   ├── Horario_Semanal/[OPCIONES_CALENDARIO|Cabezal_horario|Mover_Vertical/Todo calendario/Dias]
│   └── Seleccionar_Horario/[Inicio|Final|Cancelar|Crear_Actividad]
├── Boton_Perfil · Tienda_Button (oculto) · Economia_Button · Calendario_Button · Carrera_Button
├── Tienda [instancia Tienda.tscn]
│   ├── Flecha_Atras · Titulo · Categorias/[Tab_Dormir|Tab_Comer|Tab_Duchar]
│   ├── Objetos_Dormir/[Cama_Basica|Cama_Premium]/[Imagen_Placeholder|Nombre|Precio|Multiplicador|En_Uso|Comprar|Vender|Elegir]
│   ├── Objetos_Comer/[Mesa_Basica|Mesa_Premium]/[...]
│   └── Objetos_Duchar/[Ducha_Basica|Ducha_Premium]/[...]
└── Pantalla_Mensajes [instancia Pantalla_Mensajes.tscn]
    ├── Fondo_Mensajes · Header_Bar · Titulo · Boton_Cerrar
    ├── Tab_Bar/[Tab_Mensajes|Tab_Info|Tab_Apuntes]
    ├── Panel_Info/Scroll_Info/VBox_Info
    ├── Panel_Apuntes/[Tabs_Libros|Texto_Apuntes|Sin_Apuntes_Label]
    ├── Lista_Mensajes/VBoxContainer
    └── Contenido_Mensaje/[Mensaje_Card|Boton_Volver|Hora_Mensaje_Label|Titulo_Mensaje_Label|Descripcion_Mensaje_Label]
```

### Dónde añadir cosas comunes

- **Nuevo objeto en Tienda** → `Tienda.tscn`. Copiar bloque `Cama_Basica`/`Cama_Premium`, ajustar nombre/precio/emoji/multiplicador. Añadir conexiones al final de `Escena principal.tscn`. Registrar en `Variables_Estaticas.gd`.
- **Nueva actividad temporal** → botón en `Escena principal.tscn` dentro de `Actividades/Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/Necesidades_Basicas_Opciones` o `Progreso_Opciones`. Añadir al catálogo en `Variables_Estaticas.gd` y handler en `Script_Principal.gd`.
- **Nueva pestaña en Perfil** → `Pantalla_Mensajes.tscn`: botón en `Tab_Bar` + panel hijo del root.
- **Nuevo trabajo de nómina** → botón en `Escena principal.tscn` > `Trabajo/Actividades_Trabajo_Nomina_Opciones`. Registrar como `Actividad_Fija_Trabajo` en `Variables_Estaticas.gd`. Lógica en `Trabajo.gd`.

---

## Descripción del juego

SIMS simplificado para Android. Personaje de 18 a ~80 años.
- **Escala de tiempo:** 1 semana real = 1 año de juego (~60 semanas totales).
- El tiempo corre en minutos Unix: `Script_Principal._process` llama `Actividades.Actualizar_Horario(minuto_actual)` cada minuto real transcurrido.

---

## La Matriz principal (`Variables_Dinamicas.Matriz_Jugador`)

Array 2D de **1440 filas × 574 columnas**:
- Fila = minuto del día (0–1439). Columna = día absoluto (`semana * 7 + dia_semana`).
- Variables de posición: `Minute_Day` (columna actual), `Minute_Minute` (fila actual), `Minute` (minuto Unix).

| Valor de celda | Tipo | Significado |
|---|---|---|
| `""` | String | Sin actividad programada |
| `"Actividad_Aleatoria"` | String | Ya procesada con actividad aleatoria |
| Objeto `Actividad` | Resource | Actividad concreta programada |

Pasado/futuro en GUI se determina por comparación con clase `fecha`, no por valor de celda.

---

## Necesidades básicas (`Variables_Dinamicas.Necesidades_Basicas`)

Array de 5 valores (1–100): `[0]`=Salud física · `[1]`=Salud mental · `[2]`=Hambre · `[3]`=Descanso · `[4]`=Higiene.
GUI: verde ≥50, naranja 30–49, rojo <30.

---

## Progreso (`Variables_Dinamicas.Progreso`)

Array de 3 valores (1–100): `[0]`=Deporte · `[1]`=Académico · `[2]`=Manualidades.

---

## Habilidades innatas (`Variables_Estaticas.Habilidades`)

Array de 6 valores (1–100) aleatorios al inicio:

| Índice | Habilidad | Contribuye a (en `Actividades_Habilidades.gd`) |
|---|---|---|
| `[0]` | Deporte | Deportivo: `50*D + 40*L + 10*M` |
| `[1]` | Inteligencia | Académico: `50*I + 20*P + 30*M` |
| `[2]` | Destreza manual | Manualidades: `50*De + 30*P + 10*M + 10*L` |
| `[3]` | Memoria (M) | Todos los progresos |
| `[4]` | Liderazgo (L) | Deporte + Manualidades |
| `[5]` | Paciencia (P) | Académico + Manualidades |

---

## Personalidad (`Variables_Estaticas.Personalidad`)

`"Trabajador_Compulsivo"` → Estudiar · `"Deportista"` → Salir_A_Correr · `"Culo_Del_Sofa"` → Ver_La_Television

---

## Catálogo de actividades

`Variables_Estaticas.Catalogo_Actividades` (Dict `nombre→Actividad`). `Variables_Estaticas.Actividades` (Array para aleatorias, excluye trabajo).
Las celdas guardan **referencias al mismo objeto del catálogo** — necesario para que las comparaciones de la GUI funcionen por referencia.

Jerarquía de clases (en `Scripts/Logica/Escena_Principal/Actividades/Herencia/`):
`Actividad` → `Actividad_Temporal` / `Actividad_Fija` → `Actividad_Fija_Trabajo` (añade `hora_inicio`, `hora_final`, `salario`, `dias_laborales` — default `[0,1,2,3,4]`).

| Nombre | Clase | efectos_nb `[fís,men,ham,des,hig]` | efectos_prog `[dep,aca,man]` |
|---|---|---|---|
| `Dormir` | Actividad_Temporal | `[1, 1, -1, 4, -1]` | `[0,0,0]` |
| `Comer` | Actividad_Temporal | `[-1, 2, 20, -1, -1]` | `[0,0,0]` |
| `Duchar` | Actividad_Temporal | `[1, 1, -1, -1, 20]` | `[0,0,0]` |
| `Ver_La_Television` | Actividad_Temporal | `[-1, 5, -1, 2, -1]` | `[0,0,0]` |
| `Estudiar` | Actividad_Temporal | `[-1, -2, -1, -2, -1]` | `[0,4,0]` |
| `Salir_A_Correr` | Actividad_Temporal | `[4, 2, -3, -3, -4]` | `[4,0,0]` |
| `Practicar_Manualidades` | Actividad_Temporal | `[-2, -1, -1, -2, -1]` | `[0,0,4]` |
| `Trabajar_En_Comida_Rapida` | Actividad_Fija_Trabajo | `[-1,-1,-1,-2,-1]` | `[0,0,0]` · hora 8–16 · salario 10.0 |

---

## Sistema de guardado

- **Dinámicas** (`Guardar_Variables_Dinamicas.dat`): al guardar, objetos `Actividad` → string `nombre`; al cargar, string → referencia del catálogo. Campos: `Matriz_Jugador`, `Progreso`, `Necesidades_Basicas`, `Dinero`, `Minute`, `Minute_Day`, `Minute_Minute`.
- **Estáticas** (`Guardar_Variables_Estaticas.dat`): `Catalogo_Actividades` y `Actividades` **no se guardan** — se reconstruyen en `Variables_Estaticas._ready()`.
- **Logs debug** (no saves): `user://guardado/otros/Guardar_Matriz.txt` y `Matriz_Dia.txt`. Desactivar en producción.

---

## Convenciones

- Nombres en `PascalCase_Con_Guiones` (estilo del proyecto).
- Días: Lunes=0 … Domingo=6.
- Resolución: 720×1280 portrait.

---

## Bugs conocidos

1. `Necesidades_Basicas_GUI`: llama `Inicializar(raiz)` cada frame — debería hacerse una sola vez.
2. `Guardar_Variables_Dinamicas.save_game()`: convierte ~827K celdas a strings cada minuto — muy lento en móvil.
3. `Funciones_Globales.Guardar_Matriz()`: escribe disco cada minuto — solo debug, desactivar en producción.
4. `Trabajo.gd`: `Trabajar_De_Carpintero()` y `Trabajar_De_Cientifico()` referencian entradas del catálogo inexistentes — error de clave si se llaman.
5. `ActividadesBloqueGUI.gd` y `Consultar_Y_Eliminar_Actividades.gd`: lógica de renderizado duplicada.
6. `Guardar_Variables_Estaticas.gd`: typo `"First_TIme_Minute_Minute"` (I mayúscula) — consistente entre save/load, no rompe nada pero confunde.

---

## Funcionalidades implementadas

Documentación detallada en `Funcionalidades/<ruta>/Documentacion/`.

| Funcionalidad | Ruta | Descripción breve |
|---|---|---|
| Cobrar_Alquiler | `Economia/Cobrar_Alquiler` | 200€/semana; sin dinero → calle; necesidades cap 20 en calle |
| Ver_Calendario | `Ver Calendario` | Botón horario: calendario en solo lectura (`calendario_solo_lectura`) |
| Perfil/Informacion | `Perfil/Informacion` | Pantalla perfil 3 pestañas (Info, Mensajes, Apuntes); datos en tiempo real |
| Perfil/Mensajes | `Perfil/Mensajes` | Tab Mensajes dentro del perfil |
| Perfil/Inventario | `Perfil/Inventario` | Tab Apuntes: libros desbloqueados por carrera |
| Invertir_En_Bolsa | `Economia/Invertir_En_Bolsa` | Inversión pasiva; ~3 eventos/día; auto-venta si pánico (Sangre_Fría<30) |
| Sistema_Objetos | `Economia/Sistema_Objetos_Muebles` | Compra/venta de objetos con multiplicadores de efectos |
| Carreras | `Carreras` | Sistema de carreras universitarias |
| Muerte | `Muerte` | Condiciones de muerte del personaje |
| Jerarquia_Actividades | `Actividades/Jerarquia` | Prioridades P1/P2/P3 (Normal/Trabajo/Examen) |
| Eventos_Aleatorios | `Actividades/Eventos_Aleatorios` | Despido por higiene (cooldown 5 días) + 20 eventos generales con franja horaria |
