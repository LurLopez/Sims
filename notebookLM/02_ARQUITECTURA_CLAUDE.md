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
| `Alimentacion` | `Scripts/Logica/Escena_Principal/Actividades/Alimentacion.gd` |
| `Actividades_Habilidades` | `Scripts/Logica/Escena_Principal/Actividades/Actividades_Habilidades.gd` |
| `Actividades_Necesidades_Basicas` | `Scripts/Logica/Escena_Principal/Actividades/Actividades_Necesidades_Basicas.gd` |
| `Gestionar_Visibilidad` | `Scripts/GUI/Escena_Principal/Gestionar_Visibilidad.gd` |
| `Ajustes` | `Scripts/Globales/Ajustes.gd` |
| `Recompensas` | `Scripts/Globales/Recompensas.gd` |
| `Sistema_Cocina` | `Scripts/Logica/Escena_Principal/Minijuego_Cocina/Sistema_Cocina.gd` |
| `Musica` | `Scripts/Globales/Musica.gd` |
| `Pantalla_Carga` | `Scripts/Globales/Pantalla_Carga.gd` |

---

## Estructura de escenas

| Archivo | Líneas | Contenido |
|---|---|---|
| `Escenas/Escena_Principal/Escena principal.tscn` | ~1634 | Root + barra nav + paneles stats + calendario actividades |
| `Escenas/Escena_Principal/Tienda.tscn` | ~880 | Pantalla tienda (objetos Dormir/Comer/Duchar + pestaña Bienestar con anuncios y clínica de rejuvenecimiento) |
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
├── Boton_Perfil · Tienda_Button (oculto) · Economia_Button · Calendario_Button · Carrera_Button · Minijuegos_Button · Vestuario_Button
├── Tienda [instancia Tienda.tscn] → Categorias/[Tab_Dormir|Tab_Comer|Tab_Duchar|Tab_Ventajas] · Objetos_Ventajas (Bienestar: anuncios y clínica)
├── Pantalla_Minijuegos (generada en código; hub modular)
├── Pantalla_Vestuario (generada en código; armario con vista previa y tarjetas)
├── Tienda [instancia Tienda.tscn]
│   ├── Flecha_Atras · Titulo · Categorias/[Tab_Dormir|Tab_Comer|Tab_Duchar]
│   ├── Objetos_Dormir/[Cama_Basica|Cama_Premium|Cama_Lujo]/[Imagen_Placeholder(→Tier_Pill+Icono_Item)|Nombre|Precio|Multiplicador|En_Uso|Comprar|Vender|Elegir]
│   ├── Objetos_Comer/[Mesa_Basica]/[...]
│   └── Objetos_Duchar/[Ducha_Basica|Ducha_Premium]/[...]
└── Pantalla_Mensajes [instancia Pantalla_Mensajes.tscn]
    ├── Fondo_Mensajes · Header_Bar · Titulo · Boton_Cerrar
    ├── Tab_Bar/[Tab_Mensajes|Tab_Info|Tab_Apuntes|Tab_Despensa]
    ├── Panel_Info/Scroll_Info/VBox_Info
    ├── Panel_Apuntes/[Scroll_Inventario/Grid_Libros|Sin_Apuntes_Label]
    ├── Panel_Despensa/Scroll_Tuppers/VBox_Tuppers
    ├── Lista_Mensajes/VBoxContainer
    └── Contenido_Mensaje/[Mensaje_Card|Boton_Volver|Hora_Mensaje_Label|Titulo_Mensaje_Label|Descripcion_Mensaje_Label]
```

### Dónde añadir cosas comunes

- **Nuevo objeto en Tienda** → `Tienda.tscn`. Copiar bloque `Cama_Basica`/`Cama_Premium`, ajustar nombre/precio/emoji/multiplicador. Añadir conexiones al final de `Escena principal.tscn`. Registrar en `Variables_Estaticas.gd`.
- **Nueva actividad temporal** → botón en `Escena principal.tscn` dentro de `Actividades/Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/Necesidades_Basicas_Opciones` o `Progreso_Opciones`. Añadir al catálogo en `Variables_Estaticas.gd` y handler en `Script_Principal.gd`.
- **Nueva pestaña en Perfil** → `Pantalla_Mensajes.tscn`: botón en `Tab_Bar` + panel hijo del root.
- **Nuevo atuendo o prenda equipable** → añadir un diccionario a `Ropa_Catalogo.DATOS` (`Scripts/Logica/Escena_Principal/Economia/Ropa_Catalogo.gd`) con `clave`, `precio`, `desbloqueo` (`inicio`/`tienda`/`rango`), `categoria` (`diario`/`deporte`/`elegante`/`trabajo`/`fiesta`/`cocina`), `estilo_visual`, `detalle_visual`, paleta y bonificaciones. Añadir la clave a `Sistema_Cocina.ORDEN_ROPA` y `NOMBRES_ROPA` y, si aplica, al campo `prenda` de `RANGOS_LOGRO`. La sección `Vestuario` lo muestra automáticamente con filtros y compra, y `Personaje_Visual._dibujar_atuendo_encima()` añade los detalles visuales del estilo (19 estilos disponibles).
- **Nuevo trabajo de nómina** → botón en `Escena principal.tscn` > `Actividades/Elegir_Actividad/Tipos_De_Actividades/Fijas_Opciones/Trabajo_Opciones` o, si es de hostelería, dentro del submenú `Trabajo_Opciones/Cocinero_Opciones` (y en `Trabajo/Actividades_Trabajo_Nomina_Opciones` por compatibilidad). Registrar como `Actividad_Fija_Trabajo` en `Variables_Estaticas.gd`. Si exige cocina, usar `requisito_cocina`. Lógica en `Trabajo.gd`.
- **Nueva pestaña de Despensa/Tuppers** → la lógica de filas reutilizables está en `Scripts/GUI/Escena_Principal/Tuppers/Tupper_UI.gd`; la despensa del Perfil en `Pantalla_Mensajes.tscn` y el selector modal en `Modal_Tuppers.gd`.

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

### Cocina y tuppers

- `Progreso_Cocina` (1–100): destreza culinaria; sube cocinando y no decae.
- `Tuppers`: Array de diccionarios individuales `{id, porcentaje_restante, calidad, minuto_creacion, minuto_caducidad}`. Un tupper completo = 30 min de comida (3.333 % por minuto); cocinar produce 1 tupper al 100 % cada 15 min.
- `Tupper_Seleccionado_Idx`: índice manual elegido en la Despensa (`-1` = automático).
- `Minutos_Cocinando_Actuales`: contador volátil de minutos consecutivos cocinando (no se guarda).
- Costes: `2,00 €` por ciclo de 15 min de cocina y `2,00 €` cada 5 min de comida rápida (`Multiplicador_Precios()` reduce a `0,20 €` en modo rápido).
- Caducidad: 3 días en modo normal, 1 día en modo rápido. Los tuppers caducados permanecen en el inventario y pueden comerse con riesgo de `Intoxicacion`.
- La lógica pura vive en el autoload `Alimentacion` (`Ejecutar_Minuto_Cocinar`, `Ejecutar_Minuto_Comer_Tupper`, `Ejecutar_Minuto_Comer_Basura`).

---

## Estados temporales (`Variables_Dinamicas.Estados_Temporales`)

Dictionary `{ "Euforia"|"Resacon"|"Intoxicacion": minutos_restantes }`. `Euforia` y `Resacon` son mutuamente excluyentes y duran 1440 min (480 de meseta + 960 de bajada). `Euforia` impone un suelo gradual a Salud Mental (100→50); `Resacon` e `Intoxicacion` imponen un techo gradual a Salud Física/Mental (30→100). `Intoxicacion` puede convivir con Euforia/Resacón; si ambos techos coinciden, prevalece el más bajo. En calle/bancarrota el efecto efectivo se limita a 20. `Variables_Dinamicas.Fiesta_Evento_Ocurrido` impide más de un evento por bloque de `Salir_De_Fiesta`.

---

## Habilidades innatas (`Variables_Estaticas.Habilidades`)

Array de 7 valores (1–100) aleatorios al inicio:

| Índice | Habilidad | Contribuye a (en `Actividades_Habilidades.gd`) |
|---|---|---|
| `[0]` | Deporte | Deportivo: `50*D + 40*L + 10*M` |
| `[1]` | Inteligencia | Académico: `50*I + 20*P + 30*M` |
| `[2]` | Destreza manual | Manualidades: `50*De + 30*P + 10*M + 10*L` · Cocina (peso 40) |
| `[3]` | Memoria (M) | Todos los progresos · Cocina (peso 15) |
| `[4]` | Liderazgo (L) | Deporte + Manualidades |
| `[5]` | Paciencia (P) | Académico + Manualidades · Cocina (peso 25) |
| `[6]` | Sangre fría | Exámenes, auto-venta de bolsa · Cocina (peso 20) |

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
| `Cocinar` | Actividad_Temporal | `[-1, 1, -2, -2, -2]` | `[0,0,0]` · produce tuppers y sube `Progreso_Cocina` |
| `Comer_Tupper` | Actividad_Temporal | `[1, 2, 20, -1, -1]` | `[0,0,0]` · modulado por calidad del tupper |
| `Comer_Basura` | Actividad_Temporal | `[-2, 2, 20, -1, -1]` | `[0,0,0]` · cobra cada 5 min |
| `Duchar` | Actividad_Temporal | `[1, 1, -1, -1, 20]` | `[0,0,0]` |
| `Ver_La_Television` | Actividad_Temporal | `[-1, 5, -1, 2, -1]` | `[0,0,0]` |
| `Estudiar` | Actividad_Temporal | `[-1, -2, -1, -2, -1]` | `[0,4,0]` |
| `Salir_A_Correr` | Actividad_Temporal | `[4, 2, -3, -3, -4]` | `[4,0,0]` |
| `Practicar_Manualidades` | Actividad_Temporal | `[-2, -1, -1, -2, -1]` | `[0,0,4]` |
| `Salir_De_Fiesta` | Actividad_Temporal | `[0, 9, -3, -4, -2]` | `[0,0,0]` |
| `Trabajar_En_Comida_Rapida` | Actividad_Fija_Trabajo | `[-1,-1,-1,-2,-1]` | `[0,0,0]` · hora 8–16 · salario 10.0 |
| `Trabajar_De_Carpintero` | Actividad_Fija_Trabajo | `[-1,-1,-1,-2,-2]` | `[0,0,0]` · hora 7–15 · salario 18.0 · requisito_progreso Manualidades≥30 |
| `Trabajar_De_Cientifico` | Actividad_Fija_Trabajo | `[-1,-2,-1,-2,-1]` | `[0,0,0]` · hora 9–17 · salario 28.0 · requisito_progreso Académico≥65 · requisito_carrera `Ingenieria_Informatica` |
| `Trabajar_De_Abogado` | Actividad_Fija_Trabajo | `[-1,-2,-1,-2,-1]` | `[0,0,0]` · hora 9–17 · salario 30.0 · requisito_progreso Académico≥50 · requisito_carrera `Derecho` |
| `Trabajar_De_Medico` | Actividad_Fija_Trabajo | `[-1,-2,-1,-2,-1]` | `[0,0,0]` · hora 9–17 · salario 35.0 · requisito_progreso Académico≥60 · requisito_carrera `Medicina` |
| `Trabajar_De_Artista` | Actividad_Fija_Trabajo | `[-1,-2,-1,-2,-1]` | `[0,0,0]` · hora 9–17 · salario 25.0 · requisito_progreso Manualidades≥50 · requisito_carrera `Bellas_Artes` |
| `Trabajar_De_Ayudante_Cocina` | Actividad_Fija_Trabajo | `[-1,-1,-1,-2,-1]` | `[0,0,0]` · hora 11–19 · salario 17.0 · requisito_cocina 30 |
| `Trabajar_De_Cocinero_Partida` | Actividad_Fija_Trabajo | `[-1,-1,-1,-2,-1]` | `[0,0,0]` · hora 12–20 · salario 24.0 · requisito_cocina 60 |
| `Trabajar_De_Chef_Ejecutivo` | Actividad_Fija_Trabajo | `[-1,-2,-1,-2,-1]` | `[0,0,0]` · hora 13–21 · salario 36.0 · requisito_cocina 85 |

Cada carrera universitaria completada (`Variables_Dinamicas.Carreras_Completadas`) desbloquea exactamente uno de estos trabajos de alto salario vía `requisito_carrera` (comprobado en `Script_Principal._Cumple_Requisitos_Trabajo()`). Las carreras jugables son: Ingeniería Informática (4 años), Derecho (4 años), Bellas Artes (4 años) y **Medicina (5 años, la única con duración distinta)**. El selector de carrera (`Carreras/UI/Modal_Seleccionar_Carrera.gd`) excluye las carreras ya presentes en `Carreras_Completadas`.

`Salir_De_Fiesta`, `Cocinar`, `Comer_Tupper` y `Comer_Basura` **no** entran en `Variables_Estaticas.Actividades` (pool aleatorio). `Salir_De_Fiesta` solo se ejecuta si el jugador la programa dentro de su ventana 18:00–06:00; sus estados `Euforia`/`Resacon` se guardan en `Variables_Dinamicas.Estados_Temporales` y su flag de evento por bloque en `Variables_Dinamicas.Fiesta_Evento_Ocurrido`. La IA pasiva solo come usando tuppers vigentes o pagando comida rápida; nunca comida gratis.

---

## Marca y logo

- **Logo dinámico in-game:** `Scripts/GUI/Menu/Logo_Juego.gd` compone un medallón ilustrado (marco PNG con centro transparente + `Personaje_Visual` en modo `retrato`, `margen_retrato=12`, expresión `sonrisa`) + wordmark oficial `SIMS` + etiqueta `LIFE` dorada. La cara sale de `Variables_Estaticas.Apariencia`, así que cambia con el Sim creado. Se usa en el menú principal (`Menu.gd`).
- **Icono fijo Play Store:** `Imagenes/Marca/logo_play_store_512.png` (subir a Play Console); maestro `logo_play_store_1024.png`; `feature_graphic_1024x500.png`, lockups rojo/claro/oscuro y `logo_vertical_1024.png` para marketing. El icono de la ficha y el del lanzador Android son fijos: Android no permite generar un icono de lanzador arbitrario en runtime (solo `activity-alias` predefinidos).
- **Iconos del APK:** `Iconos_Android/` generados desde los assets de `Arte_Fuente/Marca/` con `Scripts/Otro/Herramientas/Generar_Iconos_Android.gd`. Los assets oficiales de marca se generan con `python3 Arte_Fuente/Marca/generar_logo.py`; `Exportar_Logo_Marca.gd` crea variantes personalizadas.
- Documentación completa en `Documentacion/Marca/README.md`.

---

## Sistema de guardado

- **Dinámicas** (`Guardar_Variables_Dinamicas.dat`): al guardar, objetos `Actividad` → string `nombre`; al cargar, string → referencia del catálogo. Campos: `Matriz_Jugador`, `Progreso`, `Necesidades_Basicas`, `Dinero`, `Minute`, `Minute_Day`, `Minute_Minute`, `Progreso_Cocina`, `Tuppers`, `Tupper_Seleccionado_Idx`.
  - Compatibilidad: las celdas antiguas `"Comer"` se migran a `"Comer_Basura"` al cargar. Los saves sin campos de cocina usan `Progreso_Cocina=1`, `Tuppers=[]`, `Tupper_Seleccionado_Idx=-1`; `Minutos_Cocinando_Actuales` siempre empieza en 0.
- **Estáticas** (`Guardar_Variables_Estaticas.dat`): `Catalogo_Actividades` y `Actividades` **no se guardan** — se reconstruyen en `Variables_Estaticas._ready()`.
- **Logs debug** (no saves): `user://guardado/otros/Guardar_Matriz.txt` y `Matriz_Dia.txt`. Desactivar en producción.

---

## Build Android (APK)

- **Orientación (crítico):** `display/window/handheld/orientation=1` (entero). El exportador Android hace `int()` del valor; un string como `"portrait"` se convierte en `0` (**Landscape**). Valores: `0` landscape, `1` portrait.
- **Pantalla completa:** `screen/immersive_mode=true` en `export_presets.cfg` añade `--fullscreen` al arranque (oculta barras del sistema). `screen/edge_to_edge=false`.
- **Splash sin logo de Godot:** `application/boot_splash/show_image=false` en `project.godot` y `splash_screen/disable_godot_boot_splash=true` en el preset. El splash del sistema Android 12+ usa los iconos de `Iconos_Android/`.
- **Iconos Android:** `Iconos_Android/icono_192.png`, `icono_adaptativo_frente_432.png`, `icono_adaptativo_fondo_432.png`, `icono_monocromo_432.png` y `splash_icon_512.png`. Se regeneran con:
  `godot --headless --path . --script res://Scripts/Otro/Herramientas/Generar_Iconos_Android.gd`
- **Compilar:** `./exportar_apk.sh` (debug) o `./exportar_apk.sh --release`; `--instalar` instala por ADB. Salida: `build/sims-0.33.apk` (arm64-v8a).
- **Verificar orientación:** `aapt2 dump xmltree --file AndroidManifest.xml build/sims-0.33.apk | grep screenOrientation` debe devolver `1`.

---

## Convenciones

- Nombres en `PascalCase_Con_Guiones` (estilo del proyecto).
- Días: Lunes=0 … Domingo=6.
- Resolución: 720×1280 portrait. Con `stretch/aspect="expand"` el alto visible puede crecer (p. ej. 720×1600): usa `_Alto_Pantalla()` y recoloca en `get_viewport().size_changed`; no ancles nada a `y=1280` fijo.

---

## Bugs conocidos

1. `Necesidades_Basicas_GUI`: llama `Inicializar(raiz)` cada frame — debería hacerse una sola vez.
2. `Guardar_Variables_Dinamicas.save_game()`: convierte ~827K celdas a strings cada minuto — muy lento en móvil.
3. `Funciones_Globales.Guardar_Matriz()`: escribe disco cada minuto — solo debug, desactivar en producción.
4. ~~`Trabajo.gd`: `Trabajar_De_Carpintero()` y `Trabajar_De_Cientifico()` referencian entradas del catálogo inexistentes~~ — desactualizado: ambas entradas existen en `Variables_Estaticas.gd` y el requisito de carrera se comprueba correctamente en `Script_Principal._Cumple_Requisitos_Trabajo()`.
5. `ActividadesBloqueGUI.gd` y `Consultar_Y_Eliminar_Actividades.gd`: lógica de renderizado duplicada.
6. `Guardar_Variables_Estaticas.gd`: typo `"First_TIme_Minute_Minute"` (I mayúscula) — consistente entre save/load, no rompe nada pero confunde.

---

## Funcionalidades implementadas

Documentación detallada en `Funcionalidades/<ruta>/Documentacion/`.

| Funcionalidad | Ruta | Descripción breve |
|---|---|---|
| Cobrar_Alquiler | `Economia/Cobrar_Alquiler` | 200€/semana; sin dinero → calle; necesidades cap 20 en calle |
| Ver_Calendario | `Ver Calendario` | Botón horario: calendario en solo lectura (`calendario_solo_lectura`) |
| Perfil/Informacion | `Perfil/Informacion` | Pantalla perfil 4 pestañas (Info, Mensajes, Apuntes, Despensa); datos en tiempo real |
| Perfil/Mensajes | `Perfil/Mensajes` | Tab Mensajes dentro del perfil |
| Perfil/Inventario | `Perfil/Inventario` | Tab Apuntes: libros desbloqueados por carrera |
| Vestuario | `Vestuario` | Sección propia en la barra superior: vista previa animada, tarjetas de atuendos, candados por rango y equipado persistente; la ropa se dibuja en todas las animaciones |
| Invertir_En_Bolsa | `Economia/Invertir_En_Bolsa` | Inversión pasiva; ~3 eventos/día; auto-venta si pánico (Sangre_Fría<30) |
| Sistema_Objetos | `Economia/Sistema_Objetos_Muebles` | Compra/venta de objetos con multiplicadores de efectos |
| Carreras | `Carreras` | Sistema de carreras universitarias |
| Muerte | `Muerte` | Condiciones de muerte del personaje |
| Jerarquia_Actividades | `Actividades/Jerarquia` | Prioridades P1/P2/P3 (Normal/Trabajo/Examen) |
| Salir_De_Fiesta | `Actividades/Actividades_Temporales` | Fiesta 18:00–06:00 (2–12 h), ligar/resacón por minuto y estados Euforia/Resacón de 24 h |
| Cocina_Y_Alimentacion | `Actividades/Cocina_Y_Alimentacion` | Cocinar, tuppers individuales, caducidad, intoxicación, comer tupper/basura y hostelería |
| Eventos_Aleatorios | `Actividades/Eventos_Aleatorios` | Despido por higiene (cooldown 5 días) + 20 eventos generales con franja horaria |
| Marca/Logo | `Documentacion/Marca` | Medallón dinámico con la cara del Sim + wordmark SIMS/LIFE, icono fijo de Play Store/lanzador y lockups rojo/claro/oscuro |

---

## Mantenimiento del Mega Prompt de Contexto

Al implementar o documentar una nueva funcionalidad, actualizar también `Prompts/MEGA_PROMPT_CONTEXTO.md` y su copia en `notebookLM/00_CONTEXTO_MAESTRO_Y_ROL.md` (nuevos autoloads, variables de `Variables_Dinamicas` / `Variables_Estaticas`, actividades, sistemas implementados y estado en el roadmap), así como la fuente correspondiente en `notebookLM/`, para que NotebookLM y los chats externos dispongan siempre del contexto al 100 %.


---

## Bienestar y rejuvenecimiento (pestaña Bienestar)

- **Autoload de dominio:** `Scripts/Globales/Recompensas.gd`.
- **Catálogo:** `Scripts/Globales/Recompensas/Recompensas_Catalogo.gd`.
- **Interfaces:** `Proveedor_Anuncios.gd` y `Proveedor_Simulado_Anuncios.gd`.
  Para producción se registra con `Recompensas.Configurar_Proveedor_Anuncios()`.
- **UI:** `Scripts/GUI/Tienda/Tienda_Bienestar.gd`, `Modal_Tratamiento.gd`,
  `Modal_Anuncio_Bienestar.gd` y `Visual_Bienestar.gd`, dentro de
  `Tienda.tscn → Objetos_Ventajas`.
- **Persistencia propia:** `user://recompensas.cfg` (esperas e historial); el
  dinero, necesidades, tuppers y años de rejuvenecimiento se guardan con la
  partida en `Guardar_Variables_Dinamicas.dat`.
- **Recompensas:** euros, necesidades, tuppers y años de rejuvenecimiento.
  No hay gemas, VIP, moneda premium ni pasarela de pago.
- **Rejuvenecimiento:** `Variables_Dinamicas.Rejuvenecimiento_Anios` se resta en
  `Variables_Estaticas.Calcular_Edad()` con suelo 18;
  `Tratamientos_Rejuvenecimiento` escala el precio.
- **Hooks:** `Script_Principal.gd` refresca HUD/necesidades/tienda al recibir
  `recompensa_aplicada` y `_Actualizar_Home()` repinta la edad.
- **Doc:** `Funcionalidades/Bienestar/Documentacion/BIENESTAR.md`.

---

## Minijuego de cocina y pantalla de Mejoras

- **Lógica y estado:** autoload `Sistema_Cocina` (`Scripts/Logica/Escena_Principal/Minijuego_Cocina/Sistema_Cocina.gd`). La escena `Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn` mantiene el selector vertical `720×1280` y la cocina horizontal `1280×720`.
- **Pantalla de Mejoras:** `Scripts/GUI/Minijuego_Cocina/Mejoras_Cocina.gd` (`class_name Mejoras_Cocina`), instanciada por `Minijuego_Cocina._Construir_Modal_Mejoras()`. Modal a pantalla completa (tarjeta `696×1168`) con dos columnas: a la izquierda las 5 mejoras seleccionables con icono del nivel actual, tres estrellas, `Nv. X` y coste siguiente (o `MÁX.`), tarjeta **TU PROGRESO** y aviso de que paga la Caja; a la derecha escaparate grande de la siguiente versión, pestañas `Nv.1/Nv.2/Nv.3` con `INCLUIDO`/coste/`BLOQUEADO`, comparativa `AHORA / CON LA MEJORA` y CTA de compra.
- **Compra:** `Sistema_Cocina.Comprar_Mejora` descuenta de la **Caja del local** (`fondos_cocina`), nunca de `Variables_Dinamicas.Dinero`. Si falta saldo, el CTA pasa a ámbar `FALTAN X € · SIRVE MÁS CLIENTES`. No hay gemas, diamantes ni moneda premium.
- **Datos de presentación:** `Sistema_Cocina.MEJORAS_DEF` añade `nombre_corto`, `acento` y `niveles` (nombre, beneficios, ganancias y frase). Helpers: `Obtener_Info_Nivel_Mejora`, `Obtener_Nombre_Nivel_Mejora`, `Obtener_Beneficios_Nivel_Mejora`, `Obtener_Ganancias_Nivel_Mejora` y `Obtener_Frase_Nivel_Mejora`.
- **Arte:** 15 PNG (3 variantes por mejora) en `Imagenes/Minijuego_Cocina/Mejoras/`, expuestos por `Arte_Cocina.TEXTURAS_MEJORAS` y `Arte_Cocina.textura_mejora(id, nivel)`. Se procesan con `python3 tools/procesar_mejoras_cocina.py` desde las hojas maestras `Arte_Fuente/Minijuego_Cocina/Mejoras/hoja_<mejora>.png` (prompts P22–P26).
- **QA y tests:** `Escenas/Herramientas/Captura_Mejoras_Cocina.tscn` genera las capturas 01–08 en `user://capturas_mejoras_cocina`. La suite del minijuego suma **33/33 tests** con `test_12_mejoras_presentacion_y_compra_en_modal` y el pase de cuatro huecos con candados.
- **Documentación de referencia:** `Funcionalidades/Minijuego_Cocina/Documentacion/MINIJUEGO_COCINA.md` y `ARTE_SPRITES.md`; capturas en `.../Documentacion/Capturas/06_mejoras*.png`.
