# CLAUDE.md — Contexto del proyecto SIMS

> **Fuente NotebookLM (copia sincronizada de `CLAUDE.md` · 22/11/2026):** Referencia de arquitectura, autoloads, nodos de escena, convenciones, guardado, build Android y listado de funcionalidades implementadas.

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
| `Sistema_Bolsa` | `Scripts/Logica/Escena_Principal/Economia/Sistema_Bolsa.gd` |
| `Guardar_Variables_Dinamicas` | `Scripts/Otro/Guardar/Guardar_Variables_Dinamicas.gd` |
| `Guardar_Variables_Estaticas` | `Scripts/Otro/Guardar/Guardar_Variables_Estaticas.gd` |
| `Funciones_Globales` | `Scripts/Globales/Funciones_Globales.gd` |
| `Trabajo` | `Scripts/Logica/Escena_Principal/Actividades/Trabajo/Trabajo.gd` |
| `Actividades_Habilidades` | `Scripts/Logica/Escena_Principal/Actividades/Actividades_Habilidades.gd` |
| `Actividades_Necesidades_Basicas` | `Scripts/Logica/Escena_Principal/Actividades/Actividades_Necesidades_Basicas.gd` |
| `Sistema_Examenes` | `Scripts/Logica/Escena_Principal/Actividades/Carreras/Sistema_Examenes.gd` |
| `Sistema_Carreras_Deportivas` | `Scripts/Logica/Escena_Principal/Actividades/Sistema_Carreras_Deportivas.gd` |
| `Sistema_Notificaciones` | `Scripts/Globales/Sistema_Notificaciones.gd` |
| `Actividades` | `Scripts/Logica/Escena_Principal/Actividades/Actividades.gd` |
| `Sistema_Futbol` | `Scripts/Logica/Escena_Principal/Actividades/Futbol/Sistema_Futbol.gd` |
| `Alimentacion` | `Scripts/Logica/Escena_Principal/Actividades/Alimentacion.gd` |
| `Sistema_Cocina` | `Scripts/Logica/Escena_Principal/Minijuego_Cocina/Sistema_Cocina.gd` |
| `Eventos_Aleatorios` | `Scripts/Logica/Escena_Principal/Actividades/Eventos_Aleatorios.gd` |
| `Gestionar_Visibilidad` | `Scripts/GUI/Escena_Principal/Gestionar_Visibilidad.gd` |
| `Debug_Cargar_Guardado` | `Scripts/Otro/Debug/Debug_Cargar_Guardado.gd` |
| `Ajustes` | `Scripts/Globales/Ajustes.gd` |
| `Recompensas` | `Scripts/Globales/Recompensas.gd` |
| `Musica` | `Scripts/Globales/Musica.gd` |
| `Pantalla_Carga` | `Scripts/Globales/Pantalla_Carga.gd` |

---

## Estructura de escenas

| Archivo | Líneas | Contenido |
|---|---|---|
| `Escenas/Escena_Principal/Escena principal.tscn` | ~1634 | Root + barra nav + paneles stats + calendario actividades |
| `Escenas/Escena_Principal/Tienda.tscn` | ~40 | Pantalla tienda: escena mínima; `Tienda_Objetos.gd` construye la barra de 7 categorías (Dormir, Comer, Duchar, Salón, Estudio, Cocina y Bienestar) y una rejilla desplazable de 36 muebles. Pestaña Bienestar con anuncios y clínica en `Objetos_Ventajas` |
| `Escenas/Escena_Principal/Pantalla_Mensajes.tscn` | ~235 | Pantalla perfil (Mensajes/Info/Apuntes) |
| `Escenas/Escena_Principal/Panel_Futbol.tscn` | ~15 | Panel overlay de la carrera de futbolista (se instancia desde `Script_Principal`) |
| `Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn` | ~12 | Minijuego de cocina de gestión de pedidos: selector horizontal `1280×720` de 4 mundos jugables (Burger, Bistró, Mercado y Alta Cocina) con fondos propios, pantalla de carga y partida horizontal `1280×720` (overlay `CanvasLayer` desde `Script_Principal`); partidas por clientes (sin límite de tiempo), botón MENÚ, pase de cuatro huecos (2/3/4 abiertos con candados `Nv.2`/`Nv.3`), despensa integrada bajo la encimera (ingredientes distintos por mundo) y modales cartoon de pausa, ficha de nivel, salida y resultados (`Arte_Modal_Cocina.gd`: panel azul, título dorado y botones glossy 9-patch) |

`Tienda` y `Pantalla_Mensajes` son instancias en la escena principal. La tienda ya no expone tarjetas fijas: `Script_Principal` habla con `Tienda_Objetos.gd` mediante `Abrir_Categoria()`, `Refrescar()` y las señales `dinero_cambiado`/`objetos_cambiados`. La tienda se abre desde el icono `Boton_Tienda_Header` de la cabecera; su antigua pestaña `Tienda_Button` permanece en la escena pero oculta.

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
├── Boton_Perfil · Economia_Button · Calendario_Button · Carrera_Button · Minijuegos_Button · Vestuario_Button (6 pestañas)
├── Tienda_Button (solo por compatibilidad; _Redisenar_Superior y Visibilizar_Lo_Basico lo dejan oculto)
├── Avatar_Header_Btn · Boton_Ajustes_Header (engranaje) · Boton_Tienda_Header (icono de tienda, junto al chip del dinero) (generados en _Redisenar_Superior)
├── Pantalla_Minijuegos (generada en código; contenedor modular para minijuegos)
├── Pantalla_Vestuario (generada en código; armario con vista previa y tarjetas de atuendos)
├── Panel_Bolsa (generada en código dentro de Economía; Resumen / Evolución / Estadísticas)
├── Tienda [instancia Tienda.tscn]
│   ├── Flecha_Atras · Titulo · Fondo_Seccion
│   ├── Categorias_Scroll/Categorias/[Tab_Dormir|Tab_Comer|Tab_Duchar|Tab_Salon|Tab_Estudio|Tab_Cocina|Tab_Ventajas] (generadas en código)
│   ├── Contenido_Scroll/Margen_Objetos/Rejilla_Objetos (2 columnas × 36 tarjetas generadas desde Catalogo_Tienda.DATOS)
│   └── Objetos_Ventajas (script: Tienda_Bienestar.gd) → Scroll/[Estado de edad y dinero|Clínica de rejuvenecimiento|Cuidado exprés|Anuncios|Pie]
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

- **Nuevo objeto en Tienda** → añadir un diccionario a `Catalogo_Tienda.DATOS` (`Scripts/Logica/Escena_Principal/Economia/Catalogo_Tienda.gd`) con `clave`, `nombre`, `categoria`, `precio`, `tier`, `efecto`, `descripcion` y los bonus correspondientes. La rejilla de `Tienda_Objetos.gd` y la barra de categorías se generan solas; no hay que tocar `Tienda.tscn` ni añadir conexiones en `Script_Principal`. Si es el primer mueble de una categoría nueva, añadir la categoría a `Catalogo_Tienda.CATEGORIAS` con su `basico`.
- **Ilustración de un objeto de Tienda** → JPG con fondo magenta plano o PNG con alfa en `Arte_Fuente/Tienda/Fuente/`; procesarlo con `python3 tools/procesar_iconos_tienda.py` para obtener el PNG con alfa en `Imagenes/Tienda/Iconos/<clave>.png`. `Estilos_UI.icono_tienda(clave)` resuelve la ruta automáticamente (no hay que añadirla a `RUTAS_ICONOS_TIENDA`). Las láminas nuevas de 2×2 se cortan con `python3 tools/cortar_sprites.py <lamina> Arte_Fuente/Tienda/Fuente --grid 2x2 --names ...`.
- **Nueva actividad temporal** → botón en `Escena principal.tscn` dentro de `Actividades/Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/Necesidades_Basicas_Opciones` o `Progreso_Opciones`. Añadir al catálogo en `Variables_Estaticas.gd` y handler en `Script_Principal.gd`. El flujo es **actividad → horario**: el handler debe llamar a `_Abrir_Horario_Para_Actividad("Nombre")` y registrar su duración sugerida en `DURACIONES_PREDETERMINADAS`.
- **Nueva pestaña en Perfil** → `Pantalla_Mensajes.tscn`: botón en `Tab_Bar` + panel hijo del root.
- **Nuevo atuendo o prenda equipable** → añadir un diccionario a `Ropa_Catalogo.DATOS` (`Scripts/Logica/Escena_Principal/Economia/Ropa_Catalogo.gd`) con `clave`, `precio`, `desbloqueo` (`inicio` gratis, `tienda` con dinero o `rango` de Maestría Culinaria), `categoria` (`diario`/`deporte`/`elegante`/`trabajo`/`fiesta`/`cocina`), `estilo_visual`, paleta (`color_principal`, `color_secundario`, `color_detalle`, `color_pantalon`, `color_zapatillas`), `detalle_visual` y bonificaciones. Añadir su clave a `Sistema_Cocina.ORDEN_ROPA` y `NOMBRES_ROPA`; si es de rango, al campo `prenda` de `RANGOS_LOGRO`. El vestuario (`Pantalla_Vestuario.gd`) lo muestra con filtros, precio y compra automáticamente; `Personaje_Visual._dibujar_atuendo_encima()` añade los detalles visuales del nuevo estilo (estilos actuales: `base`, `delantal`, `chef`, `gala`, `michelin`, `casual`, `deportivo`, `verano`, `invierno`, `traje`, `bata`, `mono`, `camarero`, `pijama`, `fiesta`, `futbol`, `cuero`, `astronauta`, `vestido`). No hace falta tocar la pestaña Apuntes.
- **Nuevo trabajo de nómina** → botón en `Escena principal.tscn` > `Actividades/Elegir_Actividad/Tipos_De_Actividades/Fijas_Opciones/Trabajo_Opciones` o, si es de hostelería, dentro del submenú `Trabajo_Opciones/Cocinero_Opciones` (y en `Trabajo/Actividades_Trabajo_Nomina_Opciones` por compatibilidad). Registrar como `Actividad_Fija_Trabajo` en `Variables_Estaticas.gd`. Si exige cocina, usar `requisito_cocina`. Lógica en `Trabajo.gd`.
- **Nueva pestaña de Despensa/Tuppers** → la lógica de filas reutilizables está en `Scripts/GUI/Escena_Principal/Tuppers/Tupper_UI.gd`; la despensa del Perfil en `Pantalla_Mensajes.tscn` y el selector modal en `Modal_Tuppers.gd`.
- **Ajustar el envejecimiento visual del Sim** → curvas de edad en `Scripts/Logica/Personaje/Envejecimiento_Personaje.gd` (`CURVAS`, `color_pelo`, `color_piel`, `dibujar_marcas_cara`). `Personaje_Visual.edad = -1` usa la edad real de la partida; cualquier otro valor la fuerza (creador, capturas). Lámina comparativa: `godot --path . --script res://Scripts/Otro/Herramientas/Exportar_Envejecimiento.gd`. Documentación: `Funcionalidades/Personaje/Envejecimiento/Documentacion/ENVEJECIMIENTO.md`.
- **Fondo de tiempo libre** → `Escenario_Actividad._fondo_idle()` dibuja el salón (pared crema, ventana con cielo, planta y haz de luz); `_CapaMostradorIdle` pinta la encimera delante del torso y `_aplicar_layout_personaje()` ajusta el encuadre de busto del Sim detrás de la barra. Sin comida ni platos en esta pose. Las 11 poses de actividad usan `Scripts/GUI/Personaje/Escenografia_Inicio.gd` (`dibujar_fondo()` / `dibujar_frente()`) con iluminación según `_franja_horaria()`, mezcla de rig del 14 % y fundido de escena de 0,28 s. Capturas de QA: `Escenas/Herramientas/Captura_Tiempo_Libre.tscn`, `Captura_Poses_Inicio.tscn`, `Captura_Animaciones_Inicio.tscn`, `Captura_Home_Poses.tscn` y `Captura_Variantes_Inicio.tscn`.
- **Probar una animación del escenario de Inicio** → `Debug_Pose_Inicio` (`Scripts/Otro/Herramientas/Debug_Pose_Inicio.gd`): `POSE_FORZADA = "0"` mantiene el comportamiento normal; `"idle"`, `"correr"`, `"dormir"`, `"comer"`… (o el nombre exacto de una actividad) fuerza esa pose en el Home y el menú sin programarla. `FORZAR_CALLE` (`-1` real, `0` vivienda, `1` calle) alterna la variante de `idle`/`comer`. Enganchado en `Escenario_Actividad.actualizar_estado()`. Documentación: `Funcionalidades/Personaje/Documentacion/ESCENARIO_INICIO.md`.
- **UI de carreras y exámenes** → la base visual común es `Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Carrera_Base.gd` (velo, tarjeta, cabecera, scroll y pie). Los modales concretos viven en la misma carpeta: `Modal_Seleccionar_Carrera.gd`, `Modal_Seleccionar_Examen.gd`, `Modal_Examen.gd`, `Modal_Resultado_Examen.gd` (con `Anillo_Nota.gd`) y `Lector_Libros.gd`. La pantalla principal se construye en `Script_Principal._Crear_Pantalla_Carrera()`. Capturas de todos los estados: `./scripts_vps/captura.sh Captura_Carreras`. Tests de humo: `Funcionalidades/Carreras/Tests/test_ui_carreras.gd`. Documentación: `Funcionalidades/Carreras/Documentacion/SISTEMA_CARRERAS.md`.
- **Carrera de futbolista** → botón `Boton_Carrera_Futbol` en `Actividades/Elegir_Actividad/Tipos_De_Actividades/Fijas_Opciones`. La lógica vive en el autoload `Sistema_Futbol`; los horarios en `Calendario_Futbol.gd` y las fórmulas puras en `Simulador_Futbol.gd`. El panel está en `Escenas/Escena_Principal/Panel_Futbol.tscn` y `Scripts/GUI/Escena_Principal/Actividades/Futbol/Panel_Futbol_GUI.gd`. Documentación: `Funcionalidades/Actividades/Futbol/Documentacion/CARRERA_FUTBOL.md`.
- **Apartado Minijuegos y Cocina** → botón `Minijuegos_Button` en la barra superior (6 pestañas: Perfil, Economía, Horario, Carrera, Minijuegos y Vestuario; la Tienda se abre con el icono `Boton_Tienda_Header` de la cabecera) abre `Pantalla_Minijuegos` en `Script_Principal.gd` (tarjeta «Cocina» con banner propio `Banner_Cocina.png`, plato en perspectiva y sombras de contacto). Lógica pura y estado en el autoload `Sistema_Cocina`; escena horizontal en `Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn` (selector de mundos/niveles, Mejoras, barra de carga y cocina en `1280×720`; al salir restaura la vertical `720×1280`) + `Scripts/GUI/Minijuego_Cocina/{Minijuego_Cocina,Arte_Cocina,Arrastre_Cocina,Sonidos_Cocina,Arte_Modal_Cocina}.gd`. Cocina con **arrastrar y soltar** sobre los 134 PNG de `Imagenes/Minijuego_Cocina/`, animaciones de clientes (entrada caminando desde la izquierda, pedido, paciencia, servicio y salida caminando a la derecha), chef reactivo, cocina animada y 15 SFX originales en `Sonidos/SFX/`. El pase es un puesto 3D con bandeja metálica (`Bandeja_Metal.png`), alfombrilla hundida y **mampara de cristal** con marco cromado; muestra **siempre cuatro huecos**: dos abiertos, el tercero con Emplatado Nv.2 y el cuarto con Nv.3; los cerrados llevan candado dorado y pastilla de nivel. Los platos usan `Plato_Perspectiva.png` (3/4, filo celeste) y el pan se dibuja cerrado (`dibujar_pan_cerrado`: canto inferior + tapa, sin cara de miga) para que se lea en volumen como la referencia. Los ingredientes viven en un **mueble bajo la encimera** con recipientes reales (panera de dos huecos con panecillos cerrados, bandeja de carne, tabla de queso, bol de lechuga, bandeja de tomate y cesta de patatas; sin botonera inferior) y el **nivel termina cuando se agotan los clientes** (11–31 según nivel), no por tiempo: el HUD muestra el contador de clientes con una píldora azul y un botón **MENÚ** (seguir / repetir / al mapa); los modales de pausa, ficha de nivel, salida y resultados comparten el arte cartoon de `Arte_Modal_Cocina.gd` (panel azul con brillo, título dorado con contorno azul marino, placas hundidas y botones glossy 9-patch `Boton_Modal_*` generados con `tools/generar_botones_modal.py`), con entrada de fundido + pop. Tocar un ingrediente ejecuta su acción principal (carne → plancha, patatas → freidora, pan → plato, toppings → plato con pan) y la carne cocinada se arrastra al pan. Los **tres mundos nuevos** usan fondos propios en `Imagenes/Minijuego_Cocina/Fondos/` (`Fondo_Bistro.png`, `Fondo_Mercado.png`, `Fondo_Alta_Cocina.png`) y estaciones dibujadas en `Arte_Cocina.gd` (`Estacion_Olla`, `Sarten_Salsa`, `Estacion_Horno`, `Estacion_Botellas`): el **Bistró** cocina filetes con punto (crudo → poco hecho → al punto → hecho → quemado), patatas y café; el **Mercado** combina ingredientes en la olla y sirve guisos por lotes de 4 raciones; la **Alta Cocina** exige cortar pescado entero a clicks en tabla y freírlo en sartén, retirar carnes en la ventana dorada del horno, remover la salsa para que no se queme y servir el vino del maridaje en bodega, con 33 sprites 2.5D propios (`Imagenes/Minijuego_Cocina/Alta/`). Se desbloquean al trabajar 1 minuto en su puesto o al superar 1 nivel del mundo anterior. Ropa equipable en `Objeto_Ropa.gd` y sección propia **Vestuario** (`Vestuario_Button` en la barra superior + botón en Inicio y Perfil → Info). El selector de niveles es un panel cartoon propio (`Selector_Niveles_Arte.gd`: marco celeste, tablero azul, título dorado, monedas verdes de 3 estrellas, barra lateral, ATRÁS y flecha verde) con fondo desenfocado `Fondo_Restaurante_Selector.png`; capturas de QA con `Escenas/Herramientas/Captura_Selector_Cocina.tscn`. La pantalla **Mejoras** (`Scripts/GUI/Minijuego_Cocina/Mejoras_Cocina.gd`, montada por `Minijuego_Cocina._Construir_Modal_Mejoras()`) es un modal a pantalla completa con las 5 mejoras a la izquierda, escaparate de la siguiente versión a la derecha, pestañas Nv.1–3 y compra pagada con la Caja del local (nunca el dinero del Sim); usa 15 sprites propios en `Imagenes/Minijuego_Cocina/Mejoras/`. Documentación: `Funcionalidades/Minijuego_Cocina/Documentacion/MINIJUEGO_COCINA.md` y `Funcionalidades/Vestuario/Documentacion/VESTUARIO.md`.
- **Pack de sprites del escenario** → 134 PNG en `Imagenes/Minijuego_Cocina/` **integrados en el minijuego jugable** vía `Arte_Cocina.gd`, más dos recursos de composición: `Banner_Cocina.png` (1288×284, fondo del banner de la tarjeta) y `Emplatado/Plato_Perspectiva.png` (640×297, plato vacío en 3/4). La escena de muestra `Escenas/Minijuego_Cocina/Escenario_Maqueta_Cocina.tscn` (`./ver_escenario.sh`) sigue siendo una maqueta visual para revisar el pack completo. Pipeline y catálogos en `Arte_Fuente/Minijuego_Cocina/`; documentación en `Funcionalidades/Minijuego_Cocina/Documentacion/ARTE_SPRITES.md` y capturas en `.../Documentacion/Capturas/`. Las texturas se cargan de forma perezosa (`Arte_Cocina._tex()`), no con `preload`, y los 160 PNG grandes del minijuego/cómic usan ETC2/S3TC (`python3 tools/optimizar_import_texturas.py`).
- **Música de fondo** → pistas en `Sonidos/Musica/` con `loop=true` en el `.import`; autoload `Musica` (`Reproducir_General()` / `Reproducir_Minijuego()`). La pista del minijuego se carga de forma diferida al entrar. No hay botones de altavoz: volumen y silencio se gestionan desde `Panel_Ajustes` (engranaje `Boton_Ajustes` en el menú y `Boton_Ajustes_Header` en la escena principal). Documentación: `Funcionalidades/Musica/Documentacion/MUSICA.md`.
- **Ajustes de audio** → autoload `Ajustes` (`Scripts/Globales/Ajustes.gd`), que crea los buses `Musica` y `SFX`, aplica volumen/silencio y guarda `user://configuracion_ajustes.cfg` (migra `configuracion_audio.cfg`). Panel modal `Panel_Ajustes` (`Scripts/GUI/Ajustes/Panel_Ajustes.gd`), abierto con `Boton_Ajustes` (menú) o `Boton_Ajustes_Header` (escena principal, única entrada de audio en la cabecera); dos barras táctiles independientes, botones de silencio, «Probar sonido» y «Restablecer». Ambos botones usan el icono `settings` (`Imagenes/UI/Iconos/settings.svg`), también en la banda roja del panel. Los SFX del minijuego usan el bus `SFX`. Documentación: `Funcionalidades/Ajustes/Documentacion/AJUSTES.md`.
- **Añadir un ajuste** → campo + getter/setter + persistencia en `Ajustes.gd`, y su bloque correspondiente en `Panel_Ajustes.gd`. Si afecta al audio, usar los buses `Musica`/`SFX`; no crear reproductores en `Master` para sonidos que deban respetar los ajustes.
- **Overlays modales persistentes:** todo modal que deba permanecer visible al cambiar de pestaña debe unirse al grupo `Gestionar_Visibilidad.GRUPO_OVERLAY_MODAL` (`"overlay_modal"`), como hace `Panel_Ajustes`; `Recursivo_Desvisibilizar()` y `Recursivo_Visibilizar()` ignoran ese subárbol.
- **Guardado atómico:** `Guardar_Variables_Dinamicas.gd` y `Guardar_Variables_Estaticas.gd` escriben en `.tmp`, respaldan la versión anterior en `.bak` y renombran de forma atómica; al cargar, si falta o falla el principal, recuperan desde `.bak`. Ambos bloquean la escritura sobre los saves reales cuando se ejecutan bajo GUT (`_Ejecutando_Tests_Gut()`).
- **Nuevo anuncio o servicio de bienestar** → añadir la entrada a `Scripts/Globales/Recompensas/Recompensas_Catalogo.gd` (`SECCION_ANUNCIOS` o `SECCION_SERVICIOS`, grupo `rejuvenecimiento`/`cuidado`) con su recompensa. La pestaña `Tienda → Bienestar` (`Scripts/GUI/Tienda/Tienda_Bienestar.gd`) lo recoge automáticamente. Si la recompensa es de un tipo nuevo, ampliar `Recompensas._Aplicar_Recompensas()` y sus tests. Los anuncios son simulados: no integrar SDKs reales sin sustituir `Proveedor_Anuncios`/`Proveedor_Simulado_Anuncios`. No existe moneda premium ni pasarela de pago. Documentación: `Funcionalidades/Bienestar/Documentacion/BIENESTAR.md`.

---

## Descripción del juego

SIMS simplificado para Android. Personaje de 18 a ~80 años.
- **Escala de tiempo:** 1 semana real = 1 año de juego (~60 semanas totales).
- El tiempo corre en minutos Unix: `Script_Principal._process` llama `Actividades.Actualizar_Horario(minuto_actual)` cada minuto real transcurrido.
- **Roadmap vigente:** `ROADMAP.md` (v3.0, nov 2026). Prioridad: rediseño de universidad/exámenes, minijuego de fútbol, minijuego de bolsa y balance de cocina. No empezar el modo mánager ni ampliar el contenido de cocina hasta cerrar la Fase 1.

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

**Flujo de creación:** primero se elige la actividad en el catálogo (`Actividades → Temporales/Fijas/Especiales`) y después el horario en `Seleccionar_Horario`. El selector propone una franja automática o reutiliza el bloque marcado en el calendario; `Crear_Actividad` confirma y `Cancelar` vuelve al submenú del catálogo. La tarjeta `Temporales` ya no abre el calendario: despliega `Necesidades_Basicas`/`Progreso`.

---

## Marca y logo

- **Logo dinámico in-game:** `Scripts/GUI/Menu/Logo_Juego.gd` compone un medallón ilustrado (marco PNG con centro transparente + `Personaje_Visual` en modo `retrato`, `margen_retrato=12`, expresión `sonrisa`) + wordmark oficial `SIMS` + etiqueta `LIFE` dorada. La cara sale de `Variables_Estaticas.Apariencia`, así que cambia con el Sim creado. Se usa en el menú principal (`Menu.gd`).
- **Icono fijo Play Store:** `Imagenes/Marca/logo_play_store_512.png` (subir a Play Console); maestro `logo_play_store_1024.png`; `feature_graphic_1024x500.png`, lockups `logo_horizontal_1024x240.png`, `logo_horizontal_claro_1024x240.png` y `logo_horizontal_oscuro_1024x240.png`, más `logo_vertical_1024.png` para marketing. El icono de la ficha y el del lanzador Android son fijos: Android no permite generar un icono de lanzador arbitrario en runtime (solo `activity-alias` predefinidos).
- **Iconos del APK:** `Iconos_Android/` generados desde los assets de `Arte_Fuente/Marca/` con `Scripts/Otro/Herramientas/Generar_Iconos_Android.gd`. Los assets oficiales de marca se generan con `python3 Arte_Fuente/Marca/generar_logo.py`; `Exportar_Logo_Marca.gd` crea variantes personalizadas en `Imagenes/Marca/Personalizado/`.
- Documentación completa en `Documentacion/Marca/README.md`.

---

## Sistema de guardado

- **Dinámicas** (`Guardar_Variables_Dinamicas.dat`): guardado atómico vía `.tmp` + respaldo `.bak` (fallback automático a `.bak` al leer) y bloqueo de escritura sobre el save real bajo GUT (`_Ejecutando_Tests_Gut()`). Al guardar, objetos `Actividad` → string `nombre`; al cargar, string → referencia del catálogo. Incluye matrices RLE, finanzas/bolsa (`Inversion_*`), carreras, fútbol, cocina (`rango_logro` normalizado según estrellas totales), tuppers, estados temporales y bienestar.
- **Saneado**: `First_Time_Function` limpia arrays/matriz antes de crearlos (idempotente) y `load_game` recorta/rellena `Progreso` (3), `Necesidades_Basicas` (5), `Habilidades_Mostradas`/`Habilidades_Cap_Notificado` (7), `Habilidades` (7) y `Matriz_Jugador` (1440×574).
  - Compatibilidad: las celdas antiguas `"Comer"` se migran a `"Comer_Basura"` al cargar. Los saves sin campos de cocina usan `Progreso_Cocina=1`, `Tuppers=[]`, `Tupper_Seleccionado_Idx=-1`; `Minutos_Cocinando_Actuales` siempre empieza en 0.
- **Estáticas** (`Guardar_Variables_Estaticas.dat`): guardado atómico `.tmp`/`.bak` con bloqueo bajo GUT. `Catalogo_Actividades` y `Actividades` **no se guardan** — se reconstruyen en `Variables_Estaticas._ready()`.
- **Logs debug** (no saves): `user://guardado/otros/Guardar_Matriz.txt` y `Matriz_Dia.txt`. Desactivar en producción.
- **Bienestar**: las esperas de los anuncios y el historial de la tienda se guardan aparte en `user://recompensas.cfg` (autoload `Recompensas`). El dinero, los tuppers, las necesidades y los años de rejuvenecimiento (`Rejuvenecimiento_Anios`, `Tratamientos_Rejuvenecimiento`) forman parte de la partida y se guardan con ella.

---

## Ejecutar en escritorio (sin editor)

- `./jugar.sh` abre el juego directamente con Godot (`--path .`, sin `--editor`), en ventana 450x800.
- `./jugar.sh --fondo` lo desengancha de la terminal (log en `/tmp/sims-0.33-juego.log`); `./jugar.sh --completo` usa pantalla completa; `--resolution 540x960` permite otra resolución.
- `GODOT_BIN=/ruta/a/godot ./jugar.sh` fuerza un binario concreto.

## Vista web y capturas para el móvil

- `./scripts_vps/exportar_web.sh` exporta a HTML5 y publica en `https://dev.cifraresearch.com/sims/` (usuario `sims`; la contraseña está configurada en el VPS). Recargar el navegador para ver el cambio, sin instalar APK.
- `./scripts_vps/captura.sh Captura_Tienda` (también `Captura_Bienestar`, `Captura_Minijuego_Cocina`, `Captura_Vestuario`, `Captura_Creador`, `Captura_Tiempo_Libre`, `Captura_Selector_Cocina`, `Captura_Mejoras_Cocina`, `Captura_Bienestar_Alta`, `Captura_Carreras`) ejecuta la escena con Xvfb y publica los PNG en `https://dev.cifraresearch.com/sims/capturas/`.
- Flujo recomendado desde el móvil: captura para cambios visuales → vista web para interacción → APK (`crear_apk_drive.sh`) solo para hitos y pruebas en dispositivo real.

## Build Android (APK)

- **Orientación (crítico):** `display/window/handheld/orientation=1` (entero). El exportador Android hace `int()` del valor; un string como `"portrait"` se convierte en `0` (**Landscape**). Valores: `0` landscape, `1` portrait.
- **Pantalla completa:** `screen/immersive_mode=true` en `export_presets.cfg` añade `--fullscreen` al arranque (oculta barras del sistema). `screen/edge_to_edge=false`.
- **Splash sin logo de Godot:** `application/boot_splash/show_image=false` en `project.godot` y `splash_screen/disable_godot_boot_splash=true` en el preset. El splash del sistema Android 12+ usa los iconos de `Iconos_Android/`.
- **Iconos Android:** `Iconos_Android/icono_192.png`, `icono_adaptativo_frente_432.png`, `icono_adaptativo_fondo_432.png`, `icono_monocromo_432.png` y `splash_icon_512.png`. Se regeneran desde los assets de `Arte_Fuente/Marca/` con:
  `python3 Arte_Fuente/Marca/generar_logo.py` y, opcionalmente,
  `godot --headless --path . --script res://Scripts/Otro/Herramientas/Generar_Iconos_Android.gd`
- **Compilar:** `./exportar_apk.sh` (debug) o `./exportar_apk.sh --release`; `--instalar` instala por ADB. Salida: `build/sims-0.33.apk` (arm64-v8a).
- **Renderer:** `renderer/rendering_method="gl_compatibility"` (juego 2D) con `rendering_device/fallback_to_opengl3=true`. Evita pipelines Vulkan y drivers problemáticos en móviles modestos.
- **Arranque:** `Script_Principal` carga el minijuego y sus texturas solo al abrirlo; Carrera/Economía/Minijuegos/Vestuario se construyen al pulsar su botón. `Pantalla_Carga` tiene vigilante de 8 s sin avance / 30 s máximo. Documentación: `Funcionalidades/Rendimiento/Documentacion/OPTIMIZACION_ARRANQUE.md`.
- **Verificar orientación:** `aapt2 dump xmltree --file AndroidManifest.xml build/sims-0.33.apk | grep screenOrientation` debe devolver `1`.

---

## Convenciones

- Nombres en `PascalCase_Con_Guiones` (estilo del proyecto).
- Días: Lunes=0 … Domingo=6.
- Resolución: 720×1280 portrait. Con `stretch/aspect="expand"` el alto visible puede crecer (p. ej. 720×1600): usa `_Alto_Pantalla()` y recoloca en `get_viewport().size_changed`; no ancles nada a `y=1280` fijo. Excepción: el Minijuego de Cocina se abre en horizontal `1280×720` (selector, Mejoras y partida) y restaura la vertical al volver al Sim.

---

## Bugs conocidos

1. ~~`Necesidades_Basicas_GUI`: llama `Inicializar(raiz)` cada frame~~ — resuelto: `Inicializar` tiene guardas `_inicializado` y validez de nodos.
2. ~~`Guardar_Variables_Dinamicas.save_game()`: convierte ~827K celdas a strings cada minuto~~ — resuelto: `_Matriz_A_RLE()` con caché y `Matriz_Sucia`.
3. ~~`Funciones_Globales.Guardar_Matriz()`: escribe disco cada minuto~~ — resuelto: `DEBUG_LOGS_MATRIZ := false`.
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
| Perfil/Inventario | `Perfil/Inventario` | Tab Apuntes: libros desbloqueados por carrera y diplomas |
| Invertir_En_Bolsa | `Economia/Invertir_En_Bolsa` | Autoload `Sistema_Bolsa`: inversión pasiva con pantalla propia (`Panel_Bolsa.gd` + `Grafico_Bolsa.gd`, Resumen / Evolución / Estadísticas), aportes y retiradas parciales, eventos de mercado con titulares, gráfico de beneficio acumulado y estadísticas; ~3 eventos/día; auto-venta si pánico (Sangre_Fría<30); 19 tests |
| Sistema_Objetos | `Economia/Sistema_Objetos_Muebles` | 36 muebles en 6 categorías (Dormir, Comer, Duchar, Salón, Estudio, Cocina), compra/venta/equipado, multiplicadores de necesidades, bonus de progreso y calidad de tupper; tienda con rejilla desplazable (`Tienda_Objetos.gd` + `Catalogo_Tienda.gd`) |
| Carreras | `Carreras` | 4 carreras universitarias (4–5 años), matrícula/prematrícula, apuntes, diplomas, desbloqueo de trabajos y rediseño completo de UI móvil (`Modal_Carrera_Base`, `Anillo_Nota`, `Modal_Resultado_Examen`, `Lector_Libros`, `test_ui_carreras.gd`) |
| Carrera_Deportiva | `Actividades/Actividades_Especiales/Carrera_Correr` | Competición semanal de atletismo (Sáb/Dom, P3, inscripción L–V, premios y bonus de Deporte) |
| Muerte | `Muerte` | Condiciones de muerte del personaje |
| Jerarquia_Actividades | `Actividades/Jerarquia` | Prioridades P1/P2/P3 (Normal/Trabajo/Examen) |
| Salir_De_Fiesta | `Actividades/Actividades_Temporales` | Fiesta 18:00–06:00 (2–12 h), ligar/resacón por minuto y estados Euforia/Resacón de 24 h |
| Cocina_Y_Alimentacion | `Actividades/Cocina_Y_Alimentacion` | Cocinar, tuppers individuales, caducidad, intoxicación, comer tupper/basura y hostelería |
| Eventos_Aleatorios | `Actividades/Eventos_Aleatorios` | Despido por higiene (cooldown 5 días) + 20 eventos generales con franja horaria |
| Carrera_Futbol | `Actividades/Futbol` | Fase 1 Modo Jugador: fichaje, entrenamientos, liga dominical, playoff, Modo Rápido, primas, salario y lesiones |
| Minijuego_Cocina | `Minijuego_Cocina` | Apartado Minijuegos con selector horizontal `1280×720` de 4 mundos jugables ligados a los trabajos de hostelería y carga + cocina también en `1280×720`; drag & drop + toque rápido, sprites PNG, animaciones de clientes/chef y SFX; **partidas por clientes** (11–31, sin límite de tiempo, píldora azul de clientes) y **MENÚ** (seguir/repetir/salir); pase de **cuatro huecos** con bandeja metálica 3D, mampara de cristal y platos en perspectiva 3/4 (2 abiertos; Nv.2 y Nv.3 abren los otros con candado) e ingredientes en mueble bajo la encimera; HUD con menú/clientes/dinero; modales cartoon de pausa, ficha de nivel, salida y resultados (`Arte_Modal_Cocina.gd`); 15 niveles por mundo (60 en total, flag `desbloqueo_total_qa` para pruebas), 5 mejoras, **economía de Caja + costes**, desbloqueo por trabajo o por superar el mundo anterior, logros Rangos 0–9 y ropa equipable (`Objeto_Ropa`). **Mecánicas propias (`MUNDOS_NUEVOS.md`):** Burger (montaje), Bistró (punto del filete, filete vectorial 3/4 con hueso, etiquetas bajo la carne, servicio por toque, quemados retirables y mejoras con textos/arte propios), Mercado (guisos por lotes en olla de 4 raciones + huevos) y Alta Cocina (pescado entero cortado a clicks en tabla y frito en sartén, ventana dorada del horno, salsa que se quema, maridaje tinto/blanco, 33 sprites 2.5D propios en `Alta/` sin soplete ni flor y mejoras/guía/tutorial propios); suite cocina 69/69 |
| Vestuario | `Vestuario` | Sección propia en la barra superior (y accesos en Inicio/Perfil → Info): armario de 25 atuendos (10 gratis de inicio, 11 de tienda y 4 por rango), filtros por categoría, saldo y precios, compra integrada, vista previa animada con bonificaciones, tarjeta de Maestría Culinaria solo en el filtro `Cocina` (cada 20 ★) y equipado persistente. La ropa se dibuja en todas las animaciones (`Escenario_Actividad`, avatar, perfil y logo) |
| Pack_Sprites_Escenario | `Minijuego_Cocina/Sprites` | 134 sprites PNG integrados en la cocina jugable + 15 de mejoras + 3 fondos nuevos + 2 composición; escena de muestra 1280×720 (`Escenario_Maqueta_Cocina.tscn`) |
| Musica | `Musica` | Pista general (`Lunchtime_Conspiracies`) en menú/escena principal y pista de comida rápida (`Seven_Minutes_to_Service`) en el minijuego (carga diferida); fundido cruzado, silencio persistente (gestionado por `Ajustes`) y pausa en background |
| Optimizacion_Arranque | `Rendimiento` | Carga perezosa de arte/pantallas, texturas ETC2, RLE rápido, GL Compatibility y vigilante de carga; corrige el cuelgue en la pantalla de carga en móviles modestos |
| Ajustes | `Ajustes` | Panel modal de preferencias (`overlay_modal`, sobrevive cambios de pestaña): volumen y silencio independientes de música (`Musica`) y efectos (`SFX`), prueba de sonido y restablecer; persistencia en `user://configuracion_ajustes.cfg` |
| Bienestar | `Tienda/Bienestar` | Pestaña de bienestar sin gemas ni pagos reales: anuncios recompensados simulados (+dinero, +necesidades, tuppers y −1 año), servicios de cuidado pagados con euros y clínica de rejuvenecimiento con precio creciente. Persistencia de esperas en `user://recompensas.cfg`; 20 tests |
| Rejuvenecimiento | `Personaje/Rejuvenecimiento` | `Rejuvenecimiento_Anios` resta años reales a `Calcular_Edad()` (suelo 18) y actualiza retratos y HUD; `Tratamientos_Rejuvenecimiento` escala el precio de los tratamientos |
| Envejecimiento_Personaje | `Personaje/Envejecimiento` | Canas, arrugas, manchas, piel apagada, cejas finas y postura encorvada repartidas en curvas por años entre los 18 y los 100; se aplica solo en todos los retratos de `Personaje_Visual` |
| Escenario_Inicio | `Personaje` | `Escenario_Actividad.gd` + `Escenografia_Inicio.gd` + `Personaje_Visual.gd`: 11 poses con escenografías por franja horaria/calle/muebles, micro-acciones con mezcla de rig 14 %, fundido 0,28 s y escenas QA |
| Marca/Logo | `Documentacion/Marca` | Logo dinámico con la cara del Sim + icono fijo de Play Store/lanzador |

---

## Mantenimiento del Mega Prompt de Contexto

Al implementar o documentar una nueva funcionalidad, actualizar también `Prompts/MEGA_PROMPT_CONTEXTO.md` y su copia en `notebookLM/00_CONTEXTO_MAESTRO_Y_ROL.md` (nuevos autoloads, variables de `Variables_Dinamicas` / `Variables_Estaticas`, actividades, sistemas implementados y estado en el roadmap), así como la fuente correspondiente en `notebookLM/`, para que NotebookLM y los chats externos dispongan siempre del contexto al 100 %.

---

## Entrega de builds Android (VPS / chat web)

Cuando el usuario pida «quiero ver los cambios», «crea el APK», «sube build a Drive» o similar, ejecuta `./scripts_vps/crear_apk_drive.sh` después de pasar los tests GUT y devuelve el enlace/confirmación de subida a Google Drive. El script compila en headless con el keystore fijo (`~/android-sdk/sims_debug.keystore`), sube el APK con timestamp y `sims-latest.apk` a `gdrive:SIMS_Builds/` y conserva solo los 2 builds más recientes en `/tmp/`.
