# CONTEXTO MAESTRO DEL PROYECTO: SIMS 0.33 ("Sims Life")

> **Uso:** Sube este archivo como fuente en **NotebookLM** o pégalo al inicio de tu **chat de Chrome** para planificar nuevas funcionalidades con conocimiento del 100 % del proyecto y generar prompts cerrados para Antigravity.
> **Mantenimiento:** Este archivo debe actualizarse cada vez que se implemente o documente una nueva funcionalidad (variables, actividades, autoloads, escenas, fórmulas, sistemas y roadmap).

Actúa como **Game Designer Senior y Arquitecto de Godot 4.4 (GDScript 2.0)** especializado en el proyecto **SIMS 0.33** (`/home/lur/sims-0.33`).
Tu objetivo es **planificar, diseñar y especificar al 100 % nuevas funcionalidades** conmigo en este chat para ahorrar al máximo el uso de Antigravity. Cuando cerremos un diseño, generarás un **Prompt de Implementación cerrado** para que Antigravity solo tenga que leer los archivos exactos, programar, pasar tests y entregar el informe.

---

## 1. Visión General del Juego y Escala Temporal
- **Género:** Simulador de vida simplificado tipo BitLife / Los Sims para **Android** (`720×1280` portrait, renderer `gl_compatibility`, `stretch/mode="canvas_items"`, `stretch/aspect="expand"`, `pointing/emulate_touch_from_mouse=true`).
- **Motor:** Godot 4.x (`config/features=PackedStringArray("4.7", "Mobile")`, GDScript válido para Godot 4.4+).
- **Escena de arranque:** `res://Escenas/Menu/Menu.tscn`.
- **Tema global:** `res://UI/Tema_Principal.tres`.
- **Escala de tiempo real:**
  - El juego avanza en **minutos Unix reales**. `Script_Principal._process` calcula cuántos minutos reales han pasado desde el último tick y llama a `Actividades.Actualizar_Horario(minutos_a_procesar)`.
  - Cada día tiene **1440 minutos** (`0..1439`). La vida máxima cubre **574 días** (`0..573`, ~82 semanas).
  - **Modo normal (`Variables_Estaticas.Modo_Rapido == false`):**
    - **1 semana real (7 días) = 1 año de juego** (`Dias_Por_Anio() = 7`).
    - Edad = `18 + int(max(0, dia - First_Time_Minute_Day) / 7.0)` (de 18 a ~100 años en 574 días, ~82 años de partida).
    - Capital inicial: `1000€`. Alquiler semanal: `200€`.
  - **Modo rápido (`Variables_Estaticas.Modo_Rapido == true`):**
    - **1 día real = 1 año de juego** (`Dias_Por_Anio() = 1`).
    - Multiplicador de precios: `0.1` (alquiler `20€`, objetos y matrículas ×0.1, bonus carrera ×0.1).
    - Capital inicial: `100€`.
    - Multiplicador de salario: `10.0 / 7.0` por hora (para compensar que 1 año dura 1 día en lugar de 7).
    - En trabajos (`Trabajo.gd`), empieza al día siguiente (`Minute_Day + 1`) y trabaja todos los días (no filtra `dias_laborales`).

---

## 2. Reglas Técnicas Inviolables
1. **GDScript 2.0 (Godot 4.4+):** Prohibida sintaxis de Godot 3. Usar tipado explícito en funciones nuevas.
2. **Autoloads globales:** Se usan directamente por su nombre global (sin `get_node` ni `preload` para ellos, salvo excepciones puntuales existentes). Las clases con `class_name` también son globales.
3. **Comparación segura de celdas en `Matriz_Jugador`:** Las celdas pueden contener `String` (`""` o `"Actividad_Aleatoria"`), `null`, o un objeto `Actividad`. **Nunca** comparar un objeto `Actividad` directamente contra `String` sin filtrar antes (`if celda is String and celda == "..."` o `if celda is Actividad_Fija_Trabajo and celda == actividad`).
4. **Referencias en `Matriz_Jugador`:** Las celdas programadas deben guardar **referencias al mismo objeto** de `Variables_Estaticas.Catalogo_Actividades`, porque la GUI y la lógica comparan por referencia.
5. **Rutas de recursos:** `res://...` relativo a la raíz del proyecto.
6. **Claves ASCII estables:** Sin tildes ni espacios en claves de `Catalogo_Actividades`, `Catalogo_Objetos` o diccionarios de guardado.
7. **Rendimiento O(1) por minuto:** Nada de escaneos completos de `Matriz_Jugador` ni trabajo pesado en `_process`.
8. **Compatibilidad hacia atrás en saves:** Cualquier campo nuevo en `Variables_Dinamicas` debe tener fallback seguro en `Guardar_Variables_Dinamicas.load_game()` usando `.get("clave", default)` o `if game_data.has(...)`.
9. **Resolución 720×1280 portrait:** Toda UI nueva debe caber en 720px de ancho sin desbordarse ni cortarse. Con `stretch/aspect="expand"` el alto visible crece en móviles alargados (p. ej. 720×1600); los fondos, el dock inferior y las secciones deben usar `_Alto_Pantalla()` (alto real del viewport) en vez de 1280 fijo, y recolocarse en `get_viewport().size_changed`.
10. **Orientación Android:** `display/window/handheld/orientation` debe ser el entero `1` (Portrait). El exportador hace `int()` del valor; el string `"portrait"` se convierte en `0` (Landscape).

---

## 3. Autoloads (Singletons en `project.godot`)
1. `Variables_Dinamicas` (`Scripts/Globales/Principales_Variables/Variables_Dinamicas.gd`) — Estado mutable de la partida.
2. `Variables_Estaticas` (`Scripts/Globales/Principales_Variables/Variables_Estaticas.gd`) — Constantes, catálogos y configuración fija de partida.
3. `Sistema_Bolsa` (`Scripts/Logica/Escena_Principal/Economia/Sistema_Bolsa.gd`) — Inversión pasiva en bolsa, cartera, eventos, historial, estadísticas y auto-venta por pánico.
4. `Guardar_Variables_Dinamicas` (`Scripts/Otro/Guardar/Guardar_Variables_Dinamicas.gd`) — Save/Load binario atómico (`.tmp` + `.bak`) de estado dinámico.
5. `Guardar_Variables_Estaticas` (`Scripts/Otro/Guardar/Guardar_Variables_Estaticas.gd`) — Save/Load binario atómico (`.tmp` + `.bak`) de estado estático.
6. `Funciones_Globales` (`Scripts/Globales/Funciones_Globales.gd`) — Utilidades de tiempo, matriz, aleatorios y logs debug (`user://guardado/otros/`).
7. `Trabajo` (`Scripts/Logica/Escena_Principal/Actividades/Trabajo/Trabajo.gd`) — Contratación y abandono/cancelación de trabajos.
8. `Actividades_Habilidades` (`Scripts/Logica/Escena_Principal/Actividades/Actividades_Habilidades.gd`) — Fórmulas de Progreso, decadencia, pistas contextuales y Descubrimiento de habilidades.
9. `Actividades_Necesidades_Basicas` (`Scripts/Logica/Escena_Principal/Actividades/Actividades_Necesidades_Basicas.gd`) — Aplicación de efectos a necesidades, multiplicadores de objetos y cap de bancarrota.
10. `Sistema_Examenes` (`Scripts/Logica/Escena_Principal/Actividades/Carreras/Sistema_Examenes.gd`) — Progreso de carrera, matrículas y cálculo de exámenes semanales.
11. `Sistema_Carreras_Deportivas` (`Scripts/Logica/Escena_Principal/Actividades/Sistema_Carreras_Deportivas.gd`) — Competición semanal de atletismo (inscripción L–V, carrera Sáb/Dom P3, premios).
12. `Sistema_Notificaciones` (`Scripts/Globales/Sistema_Notificaciones.gd`) — Notificaciones locales Android (actividades programadas y recordatorio de inactividad).
13. `Actividades` (`Scripts/Logica/Escena_Principal/Actividades/Actividades.gd`) — Bucle principal minuto a minuto (`Actualizar_Horario`), ejecución de actividades, alquiler, tienda y muerte.
14. `Sistema_Futbol` (`Scripts/Logica/Escena_Principal/Actividades/Futbol/Sistema_Futbol.gd`) — Carrera de futbolista: fichaje, calendario, liga dominical, playoff, Modo Rápido, primas, salario, lesiones y conflictos con el trabajo.
15. `Alimentacion` (`Scripts/Logica/Escena_Principal/Actividades/Alimentacion.gd`) — Cocina, tuppers, caducidad, intoxicación, comida rápida y selección de comida de la IA.
16. `Sistema_Cocina` (`Scripts/Logica/Escena_Principal/Minijuego_Cocina/Sistema_Cocina.gd`) — Minijuego de cocina de gestión de pedidos: **4 mundos jugables** con 15 niveles cada uno y mecánicas propias (Burger: montaje; Bistró: punto del filete, servicio por toque y mejoras propias; Mercado: guisos por lotes; Alta Cocina: ventana del horno, salsa y maridaje), 5 mejoras, desbloqueo por trabajo o por superar el mundo anterior (más `desbloqueo_total_qa`), economía de Caja + costes con paga completa 2/día y modo práctica, logros Rangos 0–9 y ropa equipable (`Objeto_Ropa`). La cocina jugable usa **arrastrar y soltar + toque rápido** sobre el pack PNG (`Arte_Cocina.gd` + `Arrastre_Cocina.gd`), selector de mundos y mapa de niveles cartoon como vistas separadas (panel celeste, monedas verdes con estrellas, ATRÁS y flecha; `Selector_Niveles_Arte.gd`), pedidos deterministas por nivel, tutorial contextual del nivel 1, clientes que entran caminando desde la izquierda y salen caminando a la derecha, animaciones de chef/cocina, **botón MENÚ** (seguir / repetir / salir) con modales cartoon (`Arte_Modal_Cocina.gd`: panel azul con brillo, título dorado con contorno, botones glossy 9-patch), **partidas por clientes** (el nivel termina cuando ya no queda ninguno, no por tiempo) con contador de restantes en el HUD, pase de **cuatro huecos** (dos abiertos; Nv.2 y Nv.3 abren los otros dos con candado) con platos en perspectiva 3/4, ingredientes en un **mueble bajo la encimera** con panera de dos huecos y recipientes integrados (sin botonera inferior), confirmación de salida y 15 SFX originales (`Sonidos_Cocina.gd`). La pantalla **Mejoras** vive en `Scripts/GUI/Minijuego_Cocina/Mejoras_Cocina.gd` (`class_name Mejoras_Cocina`, montada por `Minijuego_Cocina._Construir_Modal_Mejoras()`): modal a pantalla completa con las 5 mejoras y sus estrellas, escaparate de la siguiente versión, pestañas Nv.1–3 y compra pagada con la Caja del local.
17. `Eventos_Aleatorios` (`Scripts/Logica/Escena_Principal/Actividades/Eventos_Aleatorios.gd`) — Despido por higiene y 20 eventos generales con franja horaria.
18. `Gestionar_Visibilidad` (`Scripts/GUI/Escena_Principal/Gestionar_Visibilidad.gd`) — Control de pantallas/paneles en `Escena principal.tscn` y protección del grupo `overlay_modal`.
19. `Debug_Cargar_Guardado` (`Scripts/Otro/Debug/Debug_Cargar_Guardado.gd`) — Utilidades de debug.
20. `Ajustes` (`Scripts/Globales/Ajustes.gd`) — Preferencias globales del juego. Crea los buses `Musica` y `SFX`, aplica volumen/silencio independientes y persiste `user://configuracion_ajustes.cfg` (migra `configuracion_audio.cfg`). Expone `Obtener/Establecer_Volumen_Musica`, `Obtener/Establecer_Volumen_SFX`, silencio por bus, `Probar_Efecto_Sonido()` y `Restablecer_Audio()`.
21. `Recompensas` (`Scripts/Globales/Recompensas.gd`) — Dominio de la pestaña Tienda > Bienestar: anuncios recompensados simulados con espera persistente y servicios pagados con euros del juego. Aplica dinero, necesidades, tuppers y años de rejuvenecimiento a `Variables_Dinamicas`, y persiste esperas/historial en `user://recompensas.cfg`. No hay gemas, pagos reales ni moneda premium; el proveedor de anuncios es intercambiable (`Proveedor_Anuncios`/`Proveedor_Simulado_Anuncios`). UI en `Scripts/GUI/Tienda/Tienda_Bienestar.gd`.
22. `Musica` (`Scripts/Globales/Musica.gd`) — Música de fondo global: pista general (`Lunchtime_Conspiracies.mp3`) y pista del minijuego de cocina (`Seven_Minutes_to_Service.mp3`), fundido cruzado, bus `Musica`, pausa al background en Android. El volumen y el silencio los gestiona `Ajustes`; su API histórica delega en él.
23. `Pantalla_Carga` (`Scripts/Globales/Pantalla_Carga.gd`) — Pantalla de carga autoload (`CanvasLayer` 200) con barra de progreso real: precarga en hilo la escena principal, cubre el cambio de escena y solo se retira cuando el juego ha terminado su `_ready` (evita el fondo gris al entrar desde el menú o la intro del cómic).

---

## 4. Arquitectura de Escenas, Nodos y UI

### Escenas principales (`.tscn`)
1. **`Escenas/Menu/Menu.tscn`** (`Scripts/Globales/Menu.gd`):
   - Carga saves al arrancar. Si `Variables_Dinamicas.Muerto == true`, muestra Game Over.
   - Gestiona creación de nueva partida (`Intro_Nueva_Partida.gd`, `Creador_Personaje.gd`), selección de modo normal/rápido, apariencia y personalidad. Al entrar al juego delega en `Pantalla_Carga` (barra de progreso + precarga en hilo) para no mostrar el fondo gris.
2. **`Escenas/Escena_Principal/Escena principal.tscn`** (`Scripts/Globales/Script_Principal.gd`):
   - **Nodos de primer nivel:**
     - `Top_Bar_Panel`, `Moneda_Fondo`/`Dinero_Label`, `Avatar_Header_Btn`, `Boton_Ajustes_Header` (engranaje) y `Boton_Tienda_Header` (icono de tienda, junto al chip del dinero), más una barra de 6 pestañas (`Boton_Perfil`, `Economia_Button`, `Calendario_Button`, `Carrera_Button`, `Minijuegos_Button`, `Vestuario_Button`). `Tienda_Button` sigue en la escena por compatibilidad, pero `_Redisenar_Superior()` y `Visibilizar_Lo_Basico()` lo mantienen oculto: la tienda se abre únicamente desde `Boton_Tienda_Header`.
     - `Barra_Abajo` → `Boton_Habilidades`, `Boton_Progreso`, `Boton_Actividades`, `Boton_Necesidades_Basicas`.
     - `Fondo`, `Progreso` (oculto), `Necesidades_Basicas`, `Trabajo` (oculto), `Habilidades` (oculto).
     - `Actividades`: contiene `Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/[Necesidades_Basicas_Opciones|Progreso_Opciones]`, `Horario_Semanal/[OPCIONES_CALENDARIO|Cabezal_horario|Mover_Vertical/Todo calendario/Dias|Boton_Ir_Hoy|Boton_Semana_Actual_Inferior]`, `Seleccionar_Horario/[Inicio|Final|Cancelar|Crear_Actividad]`. El botón inferior «Volver a la semana actual» siempre es visible en el horario (deshabilitado cuando ya estás en la semana actual).
     - **Creación de actividades (orden actividad → horario):** al pulsar una actividad del catálogo se abre `Seleccionar_Horario` con una franja propuesta (hora actual en la semana actual; 09:00 en semanas futuras; 18:00–06:00 para `Salir_De_Fiesta`) o con el bloque marcado previamente en el calendario. `Crear_Actividad` valida y escribe; `Cancelar` vuelve al submenú exacto del catálogo. Desde el calendario, `OCUPAR_ACTIVIDAD` ("Elegir actividad") conserva la franja marcada y abre el catálogo.
     - `Tienda` (instancia de `Tienda.tscn`): `Flecha_Atras`, `Titulo`, `Fondo_Seccion` y `Objetos_Ventajas` (pestaña Bienestar: anuncios y clínica, construida en código). El resto lo construye `Tienda_Objetos.gd`: barra desplazable de categorías (Dormir, Comer, Duchar, Salón, Estudio, Cocina y Bienestar) y rejilla vertical de tarjetas generada desde `Catalogo_Tienda.DATOS`.
     - `Panel_Bolsa` (generada en código dentro de Economía: `Scripts/GUI/Escena_Principal/Bolsa/Panel_Bolsa.gd` + `Grafico_Bolsa.gd`): pantalla de inversión en bolsa con pestañas Resumen / Evolución / Estadísticas.
     - `Pantalla_Mensajes` (instancia de `Pantalla_Mensajes.tscn`): `Tab_Bar/[Tab_Mensajes|Tab_Info|Tab_Apuntes|Tab_Despensa]`, `Panel_Info`, `Panel_Apuntes/[Scroll_Inventario|Sin_Apuntes_Label]`, `Panel_Despensa/Scroll_Tuppers/VBox_Tuppers`, `Lista_Mensajes`, `Contenido_Mensaje`.
     - `Pantalla_Minijuegos` (generada en código en `Script_Principal.gd`): hub modular con tarjetas de minijuegos.
     - `Pantalla_Vestuario` (generada en código en `Script_Principal.gd`, `Scripts/GUI/Escena_Principal/Vestuario/Pantalla_Vestuario.gd`): armario a pantalla completa con 25 atuendos (10 gratis de inicio, 11 de tienda y 4 por rango), filtros por categoría, saldo, precios y compra integrada, vista previa animada del Sim, bonificaciones y tarjeta de Maestría Culinaria visible solo en el filtro `Cocina`. Accesible desde `Vestuario_Button` (barra superior), botón «Vestuario» en Inicio y «Cambiar de atuendo» en Perfil → Info. La ropa equipada se dibuja en `Escenario_Actividad`, avatar de cabecera, retrato del perfil y logo.
     - `Panel_Futbol` (instancia dinámica de `Panel_Futbol.tscn`): overlay a pantalla completa con `ScrollContainer` para la carrera de futbolista.
     - `Minijuego_Cocina` (`Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn`): overlay `CanvasLayer` que se abre en horizontal `1280×720` (`permissions/set_orientation=true`), con selector de mundos 2×2 y mapa de niveles cartoon 5×3 como vista aparte (sin niveles hasta tocar un mundo; el panel celeste y las monedas verdes se dibujan en `Selector_Niveles_Arte.gd`, y «ATRÁS» regresa al selector) y pantalla de carga + partida también en horizontal, manteniendo `Script_Principal._process` corriendo. Al salir restaura la vertical `720×1280`. Cocina con drag & drop + toque rápido, sprites PNG, cliente con bocadillo/paciencia animada, chef reactivo, SFX, botón MENÚ, partidas por clientes (reloj de tiempo transcurrido y píldora azul con el número de clientes) y confirmación al abandonar la partida en modales cartoon (`Arte_Modal_Cocina.gd`). La barra superior del mapa abre la pantalla **Mejoras** a tamaño completo (`Mejoras_Cocina.gd`): 5 mejoras con estrellas y coste, escaparate de la siguiente versión, pestañas Nv.1–3 y CTA de compra con la Caja del local.
   - **Modales dinámicos:** Creados/instanciados desde código. La UI rediseñada de Carreras usa `Modal_Carrera_Base.gd` + `Anillo_Nota.gd` + `Modal_Seleccionar_Carrera.gd`, `Modal_Seleccionar_Examen.gd`, `Modal_Examen.gd`, `Modal_Resultado_Examen.gd` y `Lector_Libros.gd` (y `Lector_Libro.gd` en Perfil → Apuntes); además `Tutorial_Inicial.gd`, `Modal_Tuppers.gd` y `Panel_Ajustes.gd` (grupo `overlay_modal`).
   - **Escenario visual:** `Escenario_Actividad.gd`, `Escenografia_Inicio.gd`, `Personaje_Visual.gd`, `Apariencia_Personaje.gd` (creador tipo Los Sims en `Creador_Personaje.gd` con 6 pasos guiados —Identidad, Cuerpo, Cara, Pelo, Ropa y Extras—, valor actual en cada sección, navegación Atrás/Siguiente, rasgos faciales/corporales, 16 peinados, ropa por partes con calzado/complementos, personalidad y vista previa animada reflejada en `Menu.gd`, `Logo_Juego.gd`, `Intro_Nueva_Partida.gd` y el Home de `Script_Principal.gd`). `Escenografia_Inicio.gd` dibuja las 11 escenografías de actividad con iluminación dinámica según `_franja_horaria()` (mañana, tarde, atardecer, noche), muebles equipados y variante de calle; `Personaje_Visual.obtener_rig_pose()` mezcla la pose base y la micro-acción en el 14 % inicial y final, y `_escena_clip` hace un fundido de 0,28 s al cambiar de actividad. El tiempo libre (`idle`) dibuja un salón cálido con ventana al cielo, planta frondosa y encimera de madera; el Sim aparece de pie detrás de la barra y no hay comida ni platos. Las piezas de `idle` están en `_fondo_idle()` y `_CapaMostradorIdle`.

### Sistema de Diseño UI (`Scripts/GUI/Escena_Principal/Estilos_UI.gd`)
- Paleta unificada estilo BitLife: `FONDO` (`#efeff4`), `SUPERFICIE` (`#ffffff`), `ROJO_BIT` (`#d62828`), `EXITO` (`#1ea34a`), `AVISO` (`#f59e0b`), `PELIGRO` (`#dc2626`), `AZUL` (`#1d7afc`), `INDIGO` (`#4f46e5`), `MORADO` (`#7c3aed`), `NAVY` (`#182234`), `TINTA` (`#111827`).
- Fuentes en `Fuentes/UI/`: `DMSans` (400/500/600/700), `Bricolage`, `Fraunces`, `Manrope`, `Mulish`, `RussoOne`, `TitanOne`.
- Iconos SVG en `Imagenes/UI/Iconos/` mapeados en `Estilos_UI.ICONOS_BOTONES`.

### Dónde añadir elementos comunes en UI
- **Nuevo objeto en Tienda:** añadir un diccionario a `Catalogo_Tienda.DATOS` (`clave`, `nombre`, `categoria`, `precio`, `tier`, `efecto`, bonus), guardar su ilustración con el mismo nombre en `Arte_Fuente/Tienda/Fuente/` (JPG magenta o PNG con alfa) y ejecutar `python3 tools/procesar_iconos_tienda.py`. La barra y la rejilla de `Tienda_Objetos.gd` se generan solas; `Estilos_UI.icono_tienda(clave)` resuelve `Imagenes/Tienda/Iconos/<clave>.png` automáticamente. Para una categoría nueva, añadirla a `Catalogo_Tienda.CATEGORIAS` con su `basico` y su icono Lucide.
- **Nuevo anuncio o servicio de bienestar:** añadir la entrada a `Scripts/Globales/Recompensas/Recompensas_Catalogo.gd` (sección `anuncios` o `servicios`, grupo `rejuvenecimiento`/`cuidado`). La pestaña Bienestar lo recoge sola. Si la recompensa usa un tipo nuevo, ampliar `Recompensas._Aplicar_Recompensas()` y sus tests. Los anuncios son simulados: no integrar redes reales sin cambiar el proveedor y validar en servidor.
- **Nueva actividad temporal:** botón en `Escena principal.tscn` dentro de `Necesidades_Basicas_Opciones` o `Progreso_Opciones`, registrar en `Variables_Estaticas._Inicializar_Catalogo()`, añadir subtítulo/icono en `Script_Principal.gd` / `Estilos_UI.gd` y handler de botón.
- **Nuevo trabajo de nómina:** botón en `Fijas_Opciones/Trabajo_Opciones` o, si es de hostelería, en `Trabajo_Opciones/Cocinero_Opciones` (y en `Trabajo/Actividades_Trabajo_Nomina_Opciones` por compatibilidad), registrar `Actividad_Fija_Trabajo` en `Variables_Estaticas.gd`, helper en `Trabajo.gd` y verificación de requisitos en `Script_Principal._Cumple_Requisitos_Trabajo()`.
- **Carrera de futbolista:** botón `Boton_Carrera_Futbol` en `Fijas_Opciones`; lógica en `Sistema_Futbol`, horarios en `Calendario_Futbol.gd`, fórmulas en `Simulador_Futbol.gd` y UI en `Panel_Futbol.tscn` + `Panel_Futbol_GUI.gd`.
- **Música de fondo:** pistas en `Sonidos/Musica/` importadas con `loop=true`; autoload `Musica` con `Reproducir_General()` / `Reproducir_Minijuego()`. No hay botones de altavoz: volumen y silencio de la música se gestionan desde `Panel_Ajustes` (engranaje `Boton_Ajustes` en el menú y `Boton_Ajustes_Header` en la escena principal).
- **Ajustes de audio:** engranaje (`Boton_Ajustes` en el menú, `Boton_Ajustes_Header` en la escena principal, icono `settings`) abre `Panel_Ajustes`; el autoload `Ajustes` controla los buses `Musica` y `SFX`, con volumen/silencio independientes, prueba de efecto y restablecer. Es la única entrada de audio en la cabecera (sustituye al antiguo botón de altavoz) y el panel usa el mismo icono `settings` en su banda roja. Los SFX del minijuego usan el bus `SFX`.

### Build Android (APK)
- **Compilar:** `./exportar_apk.sh` (debug) o `./exportar_apk.sh --release`; `--instalar` instala por ADB. Salida: `build/sims-0.33.apk` (arm64-v8a).
- **Orientación:** `display/window/handheld/orientation=1` (int, Portrait). Un string `"portrait"` se interpreta como `0` (Landscape) al exportar.
- **Pantalla completa:** `screen/immersive_mode=true` en `export_presets.cfg` → `--fullscreen` al arrancar. `screen/edge_to_edge=false`.
- **Splash sin logo de Godot:** `application/boot_splash/show_image=false` + `splash_screen/disable_godot_boot_splash=true` en el preset.
- **Iconos:** `Iconos_Android/` (192, adaptativo frente/fondo/monocromo 432, splash 512) generados desde los assets de `Arte_Fuente/Marca/` con `Scripts/Otro/Herramientas/Generar_Iconos_Android.gd`.
- **Arranque optimizado:** `Script_Principal` ya no precarga la escena del minijuego ni sus ~150 texturas; `Arte_Cocina` las carga con getters perezosos y las pantallas de Carrera, Economía, Minijuegos y Vestuario se construyen al abrirse. La flecha de 2400×2400 se redujo a 256×256.
- **Texturas móviles:** los 160 PNG grandes del minijuego y del cómic usan `compress/mode=2` con `high_quality=false` (ETC2 en Android, S3TC/BPTC en escritorio) mediante `python3 tools/optimizar_import_texturas.py`; el resto se queda en lossless. Reduce la memoria de texturas del arranque en ~75 MB.
- **Renderizado:** `renderer/rendering_method="gl_compatibility"` y `rendering_device/fallback_to_opengl3=true`; es un juego 2D y evita la compilación de pipelines Vulkan y drivers problemáticos en móviles modestos.
- **Empaquetado:** `export_filter="exclude"` omite tests GUT, documentación, capturas y escenas de herramientas del APK.

---

## 5. Modelo de Datos Completo

### `Variables_Dinamicas` (`user://guardado/variables/Guardar_Variables_Dinamicas.dat`)
> **Guardado atómico y protección de tests:** tanto `Guardar_Variables_Dinamicas.gd` como `Guardar_Variables_Estaticas.gd` escriben primero a `.tmp`, respaldan el archivo anterior en `.bak` y renombran de forma atómica (con fallback a `.bak` al cargar); además bloquean la escritura sobre los saves reales durante la ejecución de tests GUT (`_Ejecutando_Tests_Gut()`).

- `Matriz_Jugador`: Array 2D `[1440][574]`. Cada celda es `""`, `"Actividad_Aleatoria"`, o referencia a un objeto `Actividad`. En disco se serializa con compresión **RLE** (`formato: "rle"`). `load_game()` sanea la matriz a 1440×574 y `Progreso`/`Necesidades_Basicas`/`Habilidades_Mostradas`/`Habilidades_Cap_Notificado` a 3/5/7/7; `First_Time_Function` es idempotente.
- `Minute_Day` (int, `0..573`), `Minute_Minute` (int, `0..1439`), `Minute` (int, minuto Unix).
- `Necesidades_Basicas`: Array de 5 ints (`1..100`):
  - `[0]` Salud Física
  - `[1]` Salud Mental
  - `[2]` Hambre
  - `[3]` Descanso
  - `[4]` Higiene
- `Progreso`: Array de 3 ints/floats (`1..100`):
  - `[0]` Deporte
  - `[1]` Académico
  - `[2]` Manualidades
- `Ultimo_Uso_Progreso`, `Ultimo_Check_Decadencia` (Arrays de 3 ints en minutos para decadencia por desuso) y `Ultimas_Pistas_Progreso` (Array de hasta 5 strings de feedback).
- `Progreso_Cocina`: int (`1..100`), destreza culinaria; sube cocinando y no decae.
- `Tuppers`: Array de diccionarios `{id, porcentaje_restante, calidad, minuto_creacion, minuto_caducidad}`. Un tupper completo = 30 min (3,333 %/min).
- `Tupper_Seleccionado_Idx`: int (`-1` = automático).
- `Minutos_Cocinando_Actuales`: int volátil (no se guarda).
- `Habilidades_Mostradas`: Array de **7 ints** (`0..100`), uno por cada habilidad innata. Solo sube; se detiene al alcanzar `Variables_Estaticas.Habilidades[i]`. En Perfil → Info, mientras no se alcance ese límite, la habilidad se muestra como `? / 100`; al descubrirla se revela el valor innato exacto.
- `Dinero`: float.
- `En_La_Calle`: bool (`true` si no pudo pagar alquiler).
- `Ultima_Fecha_Alquiler`: int (minuto absoluto `Minute_Day * 1440 + Minute_Minute` del último pago, o `-1` si está en la calle).
- `Trabajo_Actual`: `Actividad_Fija_Trabajo` o `null`.
- `Objetos_Poseidos`: Dictionary `{clave_objeto: bool}` (incluye las 10 prendas gratuitas de inicio, las de tienda compradas y las de rango desbloqueadas).
- `Objeto_Seleccionado`: Dictionary `{nombre_actividad: clave_objeto}` (para `"Dormir"`, `"Comer"`, `"Duchar"`, `"Ropa"`).
- `Cocina_Estado`: Dictionary del minijuego de cocina (`restaurantes_desbloqueados`, `fondos_cocina` (Caja en €), `estrellas_nivel`, `mejoras` por restaurante con 5 claves `1..3`, `rango_logro` `0..9` normalizado desde las estrellas totales al cargar, `servicios_remunerados_hoy`, `ultimo_dia_remunerado`, `plus_nomina_turno_hoy`). Normalización recursiva en `Guardar_Variables_Dinamicas.load_game()`.
- `Carrera_Actual`: instancia de `Carrera` o `null`.
- `Carreras_Completadas`: Array de `Carrera`.
- `Inicio_Semana_Carrera`: int (`-1` si no aplica).
- `Carrera_Deportiva_Pendiente`: Dictionary `{inscrito, dia, hora_inicio, semana_inscripcion, total_inscritos, resultado_puesto, resultado_procesado}` para la carrera semanal de atletismo (P3).
- `Carrera_Futbol`: Dictionary con la carrera de futbolista: `Activo`, `Division` (4 = 3ª Regional, 3 = 2ª Nacional, 2 = 1ª Élite, 1 = Superliga), `Relacion_Entrenador`, `Entrenamientos_Cancelados_Seguidos`, `Partidos_Jugados`, `Goles_Totales`, `Asistencias_Totales`, `Temporadas_Jugadas`, `Titulos_Superliga`, `Salario_Semanal`, `Estado_Temporada`, `Entrenamientos_Asistencia` (`Martes`, `Jueves`, `Diario`) y `Liga_Domingo` (`Jornada_Actual`, `Puntos_Jugador`, `Puntos_Rivales`, `Medias_Rivales`, `Posicion_Regular`). Incluye claves internas para bloques en curso, último día de salario y ascenso pendiente. Un save sin esta clave carga el diccionario por defecto con `Activo = false`.
- `Mensajes`: Array de objetos `Mensaje` (`titulo`, `descripcion`, `leido`, `minuto`).
- `Estados_Temporales`: Dictionary `{ "Euforia"|"Resacon"|"Intoxicacion"|"Lesion_Deportiva": minutos_restantes }`. Euforia y Resacón son mutuamente excluyentes; Intoxicación y Lesión Deportiva pueden convivir con ellos. Todos duran 1440 min (480 de meseta + 960 de bajada; la lesión usa 360 de meseta y techo de Salud Física 35 → 100).
- `Fiesta_Evento_Ocurrido`: bool. `true` si ya ocurrió un evento (ligar o resacón) en el bloque de fiesta actual.
- `Esta_Invirtiendo`: bool, `Dinero_Invertido`: float, `Valor_Inversion`: float, `Salud_Mental_Al_Invertir`: int (snapshot al invertir), `Progreso_Inversion`: int (`1..100`), más las claves persistentes `Inversion_*` (historial hasta 600 puntos, 40 operaciones, 30 eventos, tendencia, aportado/retirado total, beneficio realizado, rachas, pánicos y máxima caída).
- `Cooldown_Trabajos`: Dictionary `{nombre_trabajo: minuto_fin_cooldown}`.
- `Muerto`: bool, `Edad_Muerte`: int, `Prob_Supervivencia_Acumulada`: float.
- `Rejuvenecimiento_Anios`: int (años restados en `Variables_Estaticas.Calcular_Edad()`, suelo 18), `Tratamientos_Rejuvenecimiento`: int (escala el precio de los tratamientos en Bienestar).

### `Variables_Estaticas` (`user://guardado/variables/Guardar_Variables_Estaticas.dat`)
- Constantes: `ALQUILER_SEMANAL = 200`, `BANCARROTA_MAX_NECESIDAD = 20`, `COSTE_COCINAR_BASE = 2.0`, `COSTE_COMIDA_BASURA_BASE = 2.0`, `DIAS_CADUCIDAD_TUPPER = 3`, `MINUTOS_POR_TUPPER = 15`, `MINUTOS_COMIDOS_POR_TUPPER = 30`.
- `First_Time`: bool, `Modo_Rapido`: bool, `Tutorial_Completado`: bool.
- `First_Time_Minute`, `First_Time_Minute_Day`, `First_Time_Minute_Minute`, `First_Time_Year`, `First_Time_Month`, `First_Time_Day_Of_Month`.
- `Personalidad`: `"Trabajador_Compulsivo"` | `"Deportista"` | `"Culo_Del_Sofa"`.
- `Apariencia`: Dictionary.
- `Habilidades`: Array de **7 ints innatos secretos** (`1..100`) generados al crear el personaje:
  - `[0]` Deporte
  - `[1]` Inteligencia
  - `[2]` Destreza manual
  - `[3]` Memoria
  - `[4]` Liderazgo
  - `[5]` Paciencia
  - `[6]` **Sangre Fría** (usada en exámenes académicos y auto-venta por pánico en bolsa).
- `Catalogo_Actividades`: Dictionary `{nombre: Actividad}` (no se guarda, se reconstruye en `_ready()`).
- `Estados_Temporales`: Dictionary con las definiciones de `Euforia`, `Resacon`, `Intoxicacion` y `Lesion_Deportiva` (duración, meseta, curvas, índices, títulos y mensajes de inicio/fin).
- `Actividades`: Array de 6 actividades elegibles para relleno aleatorio cuando una celda está vacía. `Cocinar`, `Comer_Tupper`, `Comer_Basura`, `Salir_De_Fiesta`, `Entrenamiento_Futbol` y `Partido_Futbol` quedan fuera del pool.
- `Catalogo_Objetos`: Dictionary `{clave: Objeto}`. Incluye **36 muebles** de 6 categorías (Dormir, Comer, Duchar, Salón, Estudio y Cocina), construidos desde `Catalogo_Tienda.DATOS` (6 por categoría, con tier, precio, multiplicador o bonus), y 25 prendas `Objeto_Ropa` con `afecta_a = "Ropa"`, construidas desde `Ropa_Catalogo.DATOS`: 10 de inicio, 11 de tienda (precio en euros) y 4 de rango (`Delantal_Aprendiz`, `Chaqueta_Chef`, `Atuendo_Chef_Gala`, `Traje_Estrella_Michelin`). Cada prenda define `desbloqueo`, `categoria`, `estilo_visual`, `detalle_visual`, paleta y bonificaciones.
- `Record_Max_Niveles_Cocina`: int (récord entre partidas de niveles superados en el minijuego de cocina).

---

## 6. Mecánicas y Fórmulas Exactas de Todos los Sistemas

### A. Ejecución Minuto a Minuto (`Actividades.Actualizar_Horario`)
Por cada minuto transcurrido:
1. Si `Minute_Day >= 574` → muerte inmediata.
2. `Sistema_Futbol.Tick_Minuto()`: cierra entrenamientos/partidos en curso, inicia los que empiezan este minuto, paga el salario a las 23:59 y resetea la temporada al inicio del día. Se ejecuta antes de leer la celda para que un bloque recién programado ya se ejecute.
3. Lee `celda = Matriz_Jugador[Minute_Minute][Minute_Day]`:
   - Si es `""` o `null`: la marca como `"Actividad_Aleatoria"` y ejecuta `Crear_Actividad_Aleatoria()` con `es_aleatoria = true`.
   - Si es `"Actividad_Aleatoria"`: ejecuta `Crear_Actividad_Aleatoria()` con `es_aleatoria = true`.
   - Si es un objeto `Actividad`: ejecuta `Ejecutar_Actividad(celda, false)`.
4. **Fiesta:** si la celda es `Salir_De_Fiesta`, comprueba `Es_Primer_Minuto_Del_Bloque`; si es el primero, `Fiesta_Evento_Ocurrido = false`. Tras aplicar los efectos del minuto, si no ha ocurrido un evento, `Resolver_Evento_Fiesta()` tira ligar (primero) y resacón.
5. **Actividad aleatoria (`Crear_Actividad_Aleatoria`):**
   - Busca la necesidad básica más baja. Si `< 30`, elige la actividad que la recupera (`0→Salir_A_Correr`, `1→Ver_La_Television`, `2→Alimentacion.Elegir_Comida_IA()`, `3→Dormir`, `4→Duchar`). Para Hambre, la IA usa tupper vigente, comida rápida si hay dinero, tupper caducado como último recurso o `Ver_La_Television` si no puede comer.
   - Si todas `>= 30`, tiene 50 % de probabilidad de elegir la actividad favorita de `Personalidad` (`Trabajador_Compulsivo→Estudiar`, `Deportista→Salir_A_Correr`, `Culo_Del_Sofa→Ver_La_Television`) y 50 % de elegir una al azar de `Variables_Estaticas.Actividades`.
   - **Importante:** cuando `es_aleatoria == true`, **solo** aplica Necesidades Básicas; **no** da Progreso, **no** revela Habilidades y **no** avanza la Carrera.
6. Llama a `Eventos_Aleatorios.Tick_Eventos(celda)`.
7. Llama a `Tick_Estados()`: aplica Euforia/Resacón/Intoxicación/Lesión con el contador actual y descuenta 1 min. Si llega a 0, elimina el estado y añade el mensaje de fin.
8. Avanza `Minute_Minute`, `Minute_Day`, `Minute`.
9. Si `Esta_Invirtiendo`: llama a `_Tick_Inversion()`.
10. Si `not En_La_Calle` y `Ultima_Fecha_Alquiler >= 0`: si `Minute - Ultima_Fecha_Alquiler >= Dias_Por_Anio() * 1440` → `Cobrar_Alquiler()`.
11. Si `Carrera_Actual != null`: gestiona conversión de prematrícula a matrícula (Lunes 00:00 en modo normal, 00:00 del día elegido en modo rápido) y disparo del examen al terminar su bloque de 60 min.
12. Llama a `Comprobar_Muerte()` (después de `Tick_Estados`).

### B. Necesidades Básicas y Objetos (`Actividades_Necesidades_Basicas.gd`)
- Frecuencias base por índice: `[30, 30, 12, 15, 20]` (Salud Física 30, Salud Mental 30, Hambre 12, Descanso 15, Higiene 20).
- Para cada necesidad cuyo efecto `por_cuanto != 0`:
  - `valor_maximo = floor(frecuencia / abs(por_cuanto))`
  - Si `por_cuanto > 0`, `_CATEGORIA_POR_ACTIVIDAD` aplica el `multiplicador` del objeto equipado (`Dormir` → `"Dormir"`, `Duchar` → `"Duchar"`, `Comer_Tupper`/`Comer_Basura` → `"Comer"`, `Ver_La_Television` → `"Salon"`): `valor_maximo = max(1, floor(valor_maximo / multiplicador))`.
  - En trabajos (`Trabajar_*`), la ropa de hostelería equipada reduce la pérdida de Higiene (`Sistema_Cocina.Obtener_Reduccion_Higiene_Para_Trabajo`).
  - Con probabilidad `1 / valor_maximo` (cuando `randi() % valor_maximo == 0`), suma o resta `1` a `Necesidades_Basicas[indice]` (rango `1..100`).
- **Penalización de calle / bancarrota:** si `En_La_Calle == true` o `Dinero < 0`, cualquier necesidad por encima de `BANCARROTA_MAX_NECESIDAD` (`20`) se recorta a `20`.

### C. Progreso Volátil y Descubrimiento de Habilidades (`Actividades_Habilidades.gd`)
- **Combinaciones ponderadas de habilidades innatas para Progreso:**
  - Deporte (`[0]`): `50*Deporte + 40*Liderazgo + 10*Memoria`
  - Académico (`[1]`): `50*Inteligencia + 20*Paciencia + 30*Memoria`
  - Manualidades (`[2]`): `50*Destreza + 30*Paciencia + 10*Memoria + 10*Liderazgo`
- **Fórmula exponencial de dificultad:**
  ```gdscript
  potencia1 = (30 + valor_actual) / 100.0
  potencia2 = 15000 / float(5000 + suma_habilidad)
  max_val = floor(por_cuanto_ecuacion * (8 ** potencia1) ** potencia2)
  ```
  - Para **Progreso**: `por_cuanto_ecuacion = 20`, `max_ajustado = floor(max_val / por_cuanto_efecto)`, modulado además por ropa (`Sistema_Cocina.Obtener_Bonus_Progreso`), muebles (`Variables_Estaticas.Obtener_Bonus_Progreso_Objeto`) y Maestría Culinaria rango ≥ 5 (+15 % en Manualidades); probabilidad `1 / max_ajustado` de sumar `+1` (tope `100`).
  - **Decadencia por desuso (`Comprobar_Decadencia_Progreso()`):** tras 5 días sin usar un área (`Ultimo_Uso_Progreso[i]`), pierde 1 punto cada 3 días (escala 1/7 en `Modo_Rapido`; tope mínimo 1).
  - **Pistas contextuales (`Registrar_Pista_Contextual()`):** guarda hasta 5 frases recientes en `Ultimas_Pistas_Progreso` («Lo has bordado», «Bien», «Te ha costado bastante»).
  - Para **Descubrimiento (`Habilidades_Mostradas[i]`)**: usa la misma fórmula con `valor_actual = Habilidades_Mostradas[i]`, `suma_habilidad = 5000`, `por_cuanto_ecuacion = 8`, `max_ajustado = max(1, floor(max_val * 100.0 / (por_cuanto_efecto * peso_porcentaje)))` y se detiene al llegar al valor innato `Variables_Estaticas.Habilidades[i]`, enviando un `Mensaje` de límite natural.

### D. Catálogo de Actividades y Jerarquía de Prioridades
Clases en `Scripts/Logica/Escena_Principal/Actividades/Herencia/`:
- `Actividad` (Prioridad **P1**): base.
- `Actividad_Temporal` (P1):
  - `Dormir`: NB `[1, 1, -1, 4, -1]`, Prog `[0,0,0]`
  - `Cocinar`: NB `[-1, 1, -2, -2, -2]`, Prog `[0,0,0]` (produce tuppers y sube `Progreso_Cocina`; ver D3)
  - `Comer_Tupper`: NB `[1, 2, 20, -1, -1]`, Prog `[0,0,0]` (física/mental moduladas por calidad)
  - `Comer_Basura`: NB `[-2, 2, 20, -1, -1]`, Prog `[0,0,0]`
  - `Duchar`: NB `[1, 1, -1, -1, 20]`, Prog `[0,0,0]`
  - `Ver_La_Television`: NB `[-1, 5, -1, 2, -1]`, Prog `[0,0,0]`
  - `Estudiar`: NB `[-1, -2, -1, -2, -1]`, Prog `[0, 4, 0]` (también avanza `Carrera_Actual` si hay una activa)
  - `Salir_A_Correr`: NB `[4, 2, -3, -3, -4]`, Prog `[4, 0, 0]`
  - `Practicar_Manualidades`: NB `[-2, -1, -1, -2, -1]`, Prog `[0, 0, 4]`
  - `Salir_De_Fiesta`: NB `[0, 9, -3, -4, -2]`, Prog `[0, 0, 0]`. P1, **fuera del pool aleatorio**; ventana 18:00–06:00, 2–12 h.
- `Actividad_Carrera` (`Estudiar_Carrera`, P1): NB `[-1, -2, -1, -2, -1]`, avanza `Carrera_Actual.progreso_actual`.
- `Actividad_Examen` (`Examen_Carrera`, Prioridad **P3** máxima): NB `[-1, -3, -1, -3, -1]`, bloque de 60 min.
- `Actividad_Partido` (`Partido_Futbol`, P3): NB `[-1, 3, -4, -5, -4]`, Prog `[6, 0, 0]`, bloque de 60 min. No entra en el pool aleatorio.
- `Actividad_Fija` (`Entrenamiento_Futbol`, P2): NB `[2, 1, -2, -3, -3]`, Prog `[4, 0, 0]`. No entra en el pool aleatorio.
- `Actividad_Fija` → `Actividad_Fija_Trabajo` (Prioridad **P2**):
  - Paga el salario completo al cruzar el último minuto de la jornada (`Minute_Minute == hora_final - 1`): `Obtener_Salario_Hora(actividad) * ((hora_final - hora_inicio) / 60.0)`.
  - `Trabajar_En_Comida_Rapida`: 8–16h, `10.0€/h`, sin requisitos.
  - `Trabajar_De_Carpintero`: 7–15h, `18.0€/h`, Manualidades ≥ 30.
  - `Trabajar_De_Cientifico`: 9–17h, `28.0€/h`, Académico ≥ 65, carrera `Ingenieria_Informatica`.
  - `Trabajar_De_Abogado`: 9–17h, `30.0€/h`, Académico ≥ 50, carrera `Derecho`.
  - `Trabajar_De_Medico`: 9–17h, `35.0€/h`, Académico ≥ 60, carrera `Medicina`.
  - `Trabajar_De_Artista`: 9–17h, `25.0€/h`, Manualidades ≥ 50, carrera `Bellas_Artes`.
  - `Trabajar_De_Ayudante_Cocina`: 11–19h, `17.0€/h`, `requisito_cocina = 30`.
  - `Trabajar_De_Cocinero_Partida`: 12–20h, `24.0€/h`, `requisito_cocina = 60`.
  - `Trabajar_De_Chef_Ejecutivo`: 13–21h, `36.0€/h`, `requisito_cocina = 85`.
  - `Actividad_Fija_Trabajo` incorpora `requisito_cocina: int = 0`, validado en `Script_Principal._Cumple_Requisitos_Trabajo()`.

### D2. Salir de Fiesta (`Salir_De_Fiesta`)
- Actividad `Actividad_Temporal` P1, color `Color(0.85, 0.15, 0.45)`, NB `[0, 9, -3, -4, -2]`, Prog `[0, 0, 0]`. **No** está en `Variables_Estaticas.Actividades`.
- Ventana: inicio 18:00–04:00, fin 20:00–06:00, duración 120–720 min. Cruce de medianoche por horas; domingo(6) → lunes(0) se normaliza a `dia_inicio + 1` para `_Calcular_Rango`. Con `semana`, el día final absoluto no puede superar 573.
- Por minuto, tras aplicar los efectos de la fiesta:
  - `puntaje_ligar = clamp(50 + 0.30*(Mental-50) + 0.25*(Higiene-50) + 0.20*(Deporte-50) + 0.15*(Académico-50) + 0.10*(Descanso-50) + mod_personalidad + mod_edad, 0, 100)`.
  - `prob_ligar = (0.00001 + 0.00099 * puntaje_ligar / 100) * mult_dia`. `mod_edad = clamp(10 - (edad-20)*0.625, -25, 12)`. Personalidad: Deportista +10, Culo_Del_Sofa −10, Trabajador_Compulsivo −5.
  - `mult_dia`: L–X 0.70, J 1.00, V 1.25, S 1.45, D 0.80. La noche pertenece al día de inicio; **las 06:00 cuentan como el día anterior**.
  - `aguante_resacon = clamp(50 + 0.40*(Hambre-50) + 0.30*(Descanso-50) + 0.20*(Física-50) + 0.10*(Deporte-50) + mod_edad, 0, 100)`; `prob_resacon = 0.00001 + 0.00099 * (100-aguante)/100`.
  - Tirada: primero ligar; si no, resacón. `Fiesta_Evento_Ocurrido` limita a un evento por bloque (dos bloques adyacentes cuentan como uno).
- Estados mutuamente excluyentes, 1440 min (480 de meseta + 960 de bajada):
  - `Euforia`: suelo de Salud Mental 100 → 50; al activarse sube a 100 (20 en calle/bancarrota). `suelo = floor(100 - progreso*50)`.
  - `Resacon`: techo de Salud Física/Mental 30 → 100; al activarse recorta a 30 (20 en calle/bancarrota). `cap = 30 + floor(progreso*70)`. `Cambiar_Necesidades_Basicas` aplica el cap a índices 0 y 1.
  - `Tick_Estados()` aplica el efecto, descuenta 1 y al llegar a 0 elimina el estado y añade el mensaje de fin. Se ejecuta siempre.
  - Mensajes en `Variables_Dinamicas.Mensajes` con `leido = false` (badge del perfil): `Has ligado`, `Resacón`, `Fin de la euforia`, `Fin del resacón`.
- Vista previa pura `Simular_Preview_Fiesta`: proyecta NB con `delta = signo(efecto) * min(1, abs(efecto)/frecuencia)` y acumula riesgos competitivos. `p_ligar + p_resacon + p_nada = 1`.
- UI: botón `Necesidades_Basicas_Opciones/Salir_De_Fiesta` (`party-popper`, `Noche · 2–12 h · Prob. según estado`), flujo actividad → horario para reabrir `Seleccionar_Horario` con preview, panel `Preview_Fiesta` (688×584 en y=174) y label `Estado_Temporal_Label` en `Resumen_Necesidades`.
- Persistencia: `Estados_Temporales` y `Fiesta_Evento_Ocurrido` en el save dinámico, con fallback `{}`/`false`, filtrado de claves y saneado de ambos estados.
- Tests: `Funcionalidades/Actividades/Actividades_Temporales/Tests/test_salir_de_fiesta.gd` y `test_cocina_y_alimentacion.gd` (suite de Actividades Temporales).

### D3. Cocina, Tuppers y Alimentación Dual (`Alimentacion.gd`)
- **Actividades:** `Cocinar`, `Comer_Tupper`, `Comer_Basura` (P1, fuera del pool aleatorio). La antigua `Comer` gratuita se elimina del catálogo; las celdas `"Comer"` de saves antiguos se migran a `"Comer_Basura"` al cargar.
- **Costes:** `2 € * Multiplicador_Precios()` por ciclo de 15 min de cocina y por cada cobro de 5 min de comida rápida. Caducidad: 3 días (normal) / 1 día (rápido).
- **Cocinar:**
  - Requiere `En_La_Calle == false` y ≥ 15 min. Si el bloque ya estaba programado y el personaje se queda en la calle, se cancela al ejecutar.
  - Cada minuto: `suma = 40*Destreza + 25*Paciencia + 20*Sangre_Fría + 15*Memoria`; `max_val = floor(20 * (8^((30+Progreso_Cocina)/100))^(15000/(5000+suma)))`; con probabilidad `1/max_val`, `Progreso_Cocina += 1` (tope 100). También descubre habilidades con pesos 40/25/20/15.
  - Cada 15 min: descuenta el coste y crea un tupper al 100 % con `calidad = Progreso_Cocina`, `minuto_creacion = Minute` y `minuto_caducidad = Minute + dias*1440`.
  - Si `Dinero < coste` o `En_La_Calle`, se limpia el bloque actual y las celdas contiguas futuras, se resetea el contador y se envía un mensaje.
  - `Minutos_Cocinando_Actuales` se resetea en cualquier minuto que no sea `Cocinar`.
- **Comer_Tupper:**
  - 1 tupper = 30 min; `porcentaje_restante -= 100/30` por minuto.
  - Selección manual (`Tupper_Seleccionado_Idx`) o automática: vigentes primero (ya empezados y caducidad más cercana), luego el menos caducado.
  - Efectos: física `+1/+2/+3` según calidad `1–30/31–70/71–100`; mental `+2` (`+3` si calidad > 60); hambre `20` (frecuencia 12); descanso/higiene `-1`.
  - Al agotarse se elimina y se reinicia la selección. Si quedan tuppers, encadena; si no, el resto del bloque pasa a `Comer_Basura` (cobrando). Si empieza sin tuppers, también pasa a basura.
- **Intoxicación:** si `Minute > minuto_caducidad`, `p30 = clamp(horas_caducado/48, 0.05, 1.0)`; `p_min = 1 - (1-p30)^(1/30)`. Si dispara y no está activo, `Estados_Temporales["Intoxicacion"] = 1440` (techo 30→100 a índices 0 y 1; 20 en calle/bancarrota).
- **Comer_Basura:** cobra cada 5 min (`Minute_Minute % 5 == 0`); si no hay saldo, cancela y limpia el bloque. Efectos `[-2, 2, 20, -1, -1]`.
- **IA:** tupper vigente → `Comer_Tupper`; si no, basura si hay dinero; si solo hay caducados y no hay dinero, tupper (riesgo); si no, `Ver_La_Television`. Nunca comida gratis.
- **UI:** botón `🍳 COCINAR` en Necesidades; el reloj de `Comer` tiene pestañas `📦 Comida casera` / `🍔 Comida rápida` con vista previa de coste/calidad/caducidad; pestaña `Despensa` en el Perfil; modal `Modal_Tuppers.gd`; indicador `🍱 N` junto a Hambre; `Progreso_Cocina` en Perfil/Info y cuarta barra del panel Progreso.
- **Persistencia:** `Progreso_Cocina`, `Tuppers` y `Tupper_Seleccionado_Idx`; `Minutos_Cocinando_Actuales = 0` al cargar. Saves antiguos usan `1`, `[]`, `-1`.
- **Tests:** `Funcionalidades/Actividades/Actividades_Temporales/Tests/test_cocina_y_alimentacion.gd` (TC-01 a TC-11 + integración UI).

### E. Tienda y Objetos (`Catalogo_Tienda.gd` / `Actividades.gd`)

- **6 categorías × 6 muebles = 36 objetos** definidos en `Catalogo_Tienda.DATOS` y materializados en `Variables_Estaticas.Catalogo_Objetos`:
  - `Dormir`: `Cama_Basica` 0 €, `Litera_Compacta` 90 € (×1.02), `Cama_Premium` 200 € (×1.05), `Cama_Nube` 460 € (×1.07), `Cama_Lujo` 800 € (×1.10), `Cama_Imperial` 1.800 € (×1.15).
  - `Comer`: `Mesa_Basica` 0 €, `Mesa_Familiar` 120 € (×1.03), `Mesa_Roble` 260 € (×1.05), `Mesa_Cristal` 450 € (×1.07), `Isla_Desayuno` 750 € (×1.10), `Mesa_Chef` 1.500 € (×1.15).
  - `Duchar`: `Ducha_Basica` 0 €, `Banera_Clasica` 160 € (×1.03), `Ducha_Premium` 200 € (×1.05), `Ducha_Lluvia` 390 € (×1.07), `Banera_Jacuzzi` 850 € (×1.10), `Cabina_Spa` 1.750 € (×1.15).
  - `Salon`: `Sofa_Basico` 0 €, `Sofa_Esquinero` 180 € (×1.03), `Sofa_Chester` 360 € (×1.05), `Sofa_Relax` 620 € (×1.08), `Sofa_Modular` 980 € (×1.11), `Sofa_Imperial` 1.900 € (×1.16).
  - `Estudio`: escritorios con bonus de progreso (`Escritorio_Moderno` +4 % Académico, `Mesa_Dibujo` +9 % Manualidades, `Escritorio_Gaming` +10 %/+3 %, `Biblioteca_Roble` +14 %/+5 %).
  - `Cocina`: cocinas con bonus de `Progreso_Cocina` y calidad de tupper (`Cocina_Modular` +4 %, `Cocina_Isla` +6 %, `Cocina_Chef` +8 %/+5 %, `Cocina_Pro` +10 %/+8 %, `Cocina_Industrial` +14 %/+12 %).
- `Mesa_Premium` sigue retirada y se limpia de saves antiguos. `Asegurar_Objetos_Basicos()` entrega los básicos de Salón/Estudio/Cocina a partidas anteriores.
- **UI:** `Tienda.tscn` es mínima; `Scripts/GUI/Tienda/Tienda_Objetos.gd` construye la barra de 7 pestañas (6 categorías + Bienestar) y una rejilla de 2 columnas con `ScrollContainer`. Tarjetas 332×390 con vitrina tintada, píldora BÁSICO/PREMIUM/LUJO/ÉLITE, precio, efecto, estado y botones Comprar/Equipar/Vender; toast para avisos. `Estilos_UI.icono_tienda(clave)` resuelve `Imagenes/Tienda/Iconos/<clave>.png` automáticamente, con carga perezosa por categoría (36 ilustraciones 2.5D integradas + respaldo Lucide).
- **Efectos:** el multiplicador se aplica a efectos positivos de `Dormir`, `Duchar`, `Comer_Tupper`/`Comer_Basura` y `Ver_La_Television`; los bonus de Estudio se aplican en `Actividades_Habilidades.Ejecutar_Actividad_Progreso()` y los de Cocina en `Calcular_Max_Progreso_Cocina()` y `Alimentacion.Crear_Tupper()`.
- Tests: `Funcionalidades/Economia/Sistema_Objetos_Muebles/Tests/test_tienda_objetos.gd` (8 tests, 87 asserts).
- Venta: devuelve el **50 %** del precio actual (`precio * 0.5`). No se puede vender si es el único objeto poseído de su categoría ni si está seleccionado actualmente.

### F. Bolsa e inversiones (`Sistema_Bolsa`)
- La lógica vive en el autoload `Sistema_Bolsa`; `Actividades._Tick_Inversion()` solo delega. La UI está en `Scripts/GUI/Escena_Principal/Bolsa/Panel_Bolsa.gd` y `Grafico_Bolsa.gd`.
- Se evalúa cada minuto si `Esta_Invirtiendo == true`: dispara evento de mercado con probabilidad `1/480` (~3 veces/día).
- `prob_subida = clamp(0.15 + ((Progreso_Inversion - 1.0) / 99.0) * 0.70 + ((Salud_Mental_Al_Invertir - 50.0) / 300.0) + Inversion_Tendencia * 0.05, 0.05, 0.95)`. La tendencia es un paseo aleatorio con reversión (`t * 0.90 + randfn(0, 0.20)`, límite ±1).
- Variación normal por evento: `0.5%`–`3.0%`. Shock (6 %): `3.0%`–`6.5%`.
- **Cartera:** aportes y retiradas parciales. `Dinero_Invertido` es el coste base; una retirada libera coste proporcional y materializa beneficio. `Beneficio_Acumulado = Beneficio_Realizado + (Valor_Inversion - Dinero_Invertido)`.
- **Auto-venta por pánico:** si `Habilidades[6]` (`Sangre_Fría`) `< 30` y las pérdidas superan el `15%`, vende automáticamente y envía un `Mensaje`.
- `Progreso_Inversion` sube +1 con probabilidad `1/20` por evento y +1 al cerrar una posición completa en positivo (máximo 100). Se corrigió su carga desde el guardado.
- **Historial:** puntos `{minuto, beneficio, valor, invertido}` tras cada evento/operación, máximo 600 con compactación. `Inversion_Operaciones` guarda 40 operaciones y `Inversion_Eventos` 30 titulares.
- **Estadísticas:** aportado, retirado, beneficio total, rentabilidad, tasa de acierto, mejor/peor operación, tiempo invertido, eventos, rachas y máxima caída.
- **UI:** tarjeta de Economía → pantalla completa con pestañas **Resumen / Evolución / Estadísticas**; gráfico verde/rojo con línea de cero, periodos 1/5/10 años/Todo y marcadores de operaciones; diálogo de cantidad con 25/50/75/Todo y validación. Sin comisiones en la inversión pasiva (la del 1 % queda para el futuro minijuego).
- Tests: `Funcionalidades/Economia/Invertir_En_Bolsa/Tests/test_sistema_bolsa.gd` (19 tests GUT). Documentación: `Funcionalidades/Economia/Invertir_En_Bolsa/Documentacion/INVERTIR.md`.

### G. Carreras Universitarias y Exámenes (`Sistema_Examenes.gd`)
- 4 carreras: `Ingenieria_Informatica` (4 años), `Derecho` (4 años), `Bellas_Artes` (4 años) y `Medicina` (5 años).
- Cada año desbloquea apuntes (`apuntes_<carrera>_anio<N>.txt`) visibles en Perfil → Apuntes (`Lector_Libro.gd`, que también renderiza diplomas) y en el botón Apuntes de Carrera (`Lector_Libros.gd`), más preguntas (`preguntas_<carrera>.json`) para `Modal_Examen.gd`.
- **UI rediseñada (nov 2026):** `Modal_Carrera_Base.gd` + `Anillo_Nota.gd` + `Modal_Seleccionar_Carrera.gd`, `Modal_Seleccionar_Examen.gd`, `Modal_Examen.gd` (tarjetas táctiles, confirmación al salir y aviso de respuestas pendientes), `Modal_Resultado_Examen.gd` y `Lector_Libros.gd`. Tests de humo: `Funcionalidades/Carreras/Tests/test_ui_carreras.gd`; QA: `Escenas/Herramientas/Captura_Carreras.tscn`. El rediseño jugable del ciclo y examen es la Prioridad 1 del Roadmap v3.0 (pendiente).
- **Cálculo de nota final actual:**
  - `hab_acad = Inteligencia*0.35 + Memoria*0.15 + Sangre_Fria*0.50`
  - `nec_examen = Descanso*0.40 + Salud_Mental*0.40 + Hambre*0.20`
  - `valor_esperado = progreso_actual*0.60 + hab_acad*0.20 + nec_examen*0.20`
  - `nota_personaje = Distribucion_Normal(valor_esperado, sigma=15.0)` (clamp `0..100`)
  - `nota_final = clamp(nota_personaje + nota_real_jugador * 0.1, 0.0, 100.0)`
  - Aprueba con `>= 50` (Matrícula de honor `>= 90`). Al completar todos los años, otorga bonus `2000 * Multiplicador_Precios()`.

### H. Eventos Aleatorios (`Eventos_Aleatorios.gd`)
- **Despido por higiene:** mientras trabaja, si Higiene es baja puede ser despedido y añade un cooldown de **5 días** (`5 * 1440` min) a ese trabajo en `Cooldown_Trabajos`.
- **20 eventos generales:** probabilidad base `1/2880` por minuto (~1 cada 2 días), acumulativa tras `1440` min sin eventos. Tipos: `ENFERMEDAD_LEVE`, `ENFERMEDAD_GRAVE`, `BONUS_DINERO`, `BONUS_DINERO_GRANDE`, `ACCIDENTE_LEVE`, `ACCIDENTE_GRAVE`, `EVENTO_SOCIAL_POSITIVO`, `EVENTO_SOCIAL_NEGATIVO`, `HALLAZGO`, `INSPIRACION`, con franja horaria opcional (`hora_inicio..hora_fin`, soporta cruzar medianoche).

### I. Muerte (`Actividades.Comprobar_Muerte`)
- Muerte garantizada al llegar al final de los 574 días (`Minute_Day >= 573 and Minute_Minute >= 1439`).
- En cada minuto:
  - `factor_edad = pow(2.0, (edad - 18) / 10.0)`
  - `factor_nec = pow(35.0, media_necesidades / 100.0)`
  - `factor_modo = 7.0 if Modo_Rapido else 1.0`
  - `max_valor = max(1, int((1_875_000.0 * factor_nec / factor_edad) / factor_modo))`
  - Muere si `randi() % max_valor == 0`.

### J. Marca y Logo Dinámico (`Logo_Juego.gd`)
- `Logo_Juego` (HBoxContainer) = medallón ilustrado con la cara real del Sim + wordmark oficial `SIMS` + etiqueta `LIFE` dorada.
- El medallón usa `Personaje_Visual` en modo `retrato` (`margen_retrato = 12`, expresión `sonrisa`) y `Variables_Estaticas.Apariencia`; la cara cambia con el personaje creado. El marco es `Imagenes/Marca/medallon_marco.png` (centro transparente) y se recorta con una máscara circular.
- **Personalización tipo Sims y pantallas de inicio:** `Apariencia_Personaje.gd` + `Creador_Personaje.gd` permiten configurar complexión (`atletica`, `normal`, `robusta`), 12 tonos de piel, rasgos faciales (cara, ojos, cejas, nariz, boca, color de labios, rubor, lunares/pecas, eyeliner), 16 peinados, 7 estilos de vello facial, 6 prendas superiores (con mangas largas/cortas/remangadas/tirantes), 5 inferiores (vaqueros, chino, chándal, shorts, falda), 3 calzados, gafas/sombreros/pendientes, arquetipos rápidos, rasgo de personalidad (`Variables_Estaticas.Personalidad`), 3 niveles de zoom (`Cara`, `Busto`, `Cuerpo`), barra de poses en vivo y flujo guiado en 6 pasos con barra de progreso, valor actual por sección y botón Atrás/Siguiente (el último paso inicia la partida). Tanto la tarjeta de partida activa en `Menu.gd` como el Home de `Script_Principal.gd` incrustan un `Escenario_Actividad` animado (11 poses con escenografía propia en `Escenografia_Inicio.gd` y variación por `_franja_horaria()`, variante de calle en `idle`/`comer`, 3–6 micro-acciones por pose con mezcla de rig del 14 % y fundido de escena de 0,28 s). Tests: `Funcionalidades/Personaje/Tests/test_personaje_personalizacion.gd`.
- **QA de las animaciones de inicio:** `Debug_Pose_Inicio` (`Scripts/Otro/Herramientas/Debug_Pose_Inicio.gd`) fuerza la pose del `Escenario_Actividad` del Home y del menú sin programar la actividad: `POSE_FORZADA = "0"` es el comportamiento normal y `"idle"`, `"correr"`, `"dormir"`, `"comer"`, `"duchar"`, `"estudiar"`, `"tv"`, `"manualidades"`, `"cocinar"`, `"fiesta"`, `"futbol"`, `"trabajar"` (o el nombre exacto de una actividad) la fija; `FORZAR_CALLE` (`-1` real, `0` vivienda, `1` calle) alterna la variante de `idle`/`comer`. Escenas QA: `Captura_Tiempo_Libre.tscn`, `Captura_Poses_Inicio.tscn`, `Captura_Animaciones_Inicio.tscn`, `Captura_Home_Poses.tscn` y `Captura_Variantes_Inicio.tscn`. Doc: `Funcionalidades/Personaje/Documentacion/ESCENARIO_INICIO.md`.
- El wordmark es un asset (`wordmark_claro.png` / `wordmark_oscuro.png`); el subtítulo usa Mulish-700 y se escala con `tamano_insignia`. `variante_oscura = true` para fondos claros.
- Se usa en el menú principal (`Scripts/Globales/Menu.gd`).
- **Fijo (no dinámico):** icono de Play Store (`Imagenes/Marca/logo_play_store_512.png`) e iconos del lanzador/APK (`Iconos_Android/`). Android no permite generar un icono de lanzador arbitrario en runtime; solo `activity-alias` predefinidos.
- Pipeline: `python3 Arte_Fuente/Marca/generar_logo.py` genera icono, lockups (rojo/claro/oscuro), vertical, feature graphic, wordmarks, marco y fondos. `Exportar_Mascota_Logo.gd` regenera la mascota base; `Generar_Iconos_Android.gd` prepara el APK; `Exportar_Logo_Marca.gd` crea variantes personalizadas en `Imagenes/Marca/Personalizado/`.
- Documentación: `Documentacion/Marca/README.md`.

### K. Carrera de Futbolista — Fase 1 (`Sistema_Futbol.gd`)
- **Alcance:** Modo Jugador. La Fase 2 (Modo Mánager / Top Eleven) no está implementada.
- **Archivos:** `Futbol/Simulador_Futbol.gd` (puro), `Futbol/Calendario_Futbol.gd`, `Futbol/Sistema_Futbol.gd` (autoload), `Herencia/Actividad_Partido.gd`, `Panel_Futbol.tscn` + `Panel_Futbol_GUI.gd`, tests `Funcionalidades/Actividades/Futbol/Tests/test_futbol.gd`.
- **Actividades:** `Entrenamiento_Futbol` (P2) y `Partido_Futbol` (P3, `Actividad_Partido`). Fuera del pool aleatorio. Programadas por `Sistema_Futbol` en `Matriz_Jugador` al fichar, cambiar de división o cambiar la asistencia; `Tick_Minuto()` hace O(1) por minuto.
- **Calendario normal:** entrenamiento martes/jueves 120 min (3ª 19:00–21:00; profesional 10:00–12:00). Liga dominical de 4 equipos: 3 jornadas a las 10:00, 13:00 y 16:00 + playoff a las 19:00. Posiciones 1–2 juegan ascenso; 3–4 permanencia.
- **Calendario rápido:** entrenamiento diario 45 min (3ª 18:30–19:15; profesional 10:00–10:45) y partido decisivo diario 20:30–21:30.
- **Fórmulas:** condición `clamp(0.45*Física + 0.35*Descanso + 0.20*Hambre, 0, 100)`; innata `0.50*Deporte + 0.25*Liderazgo + 0.25*SangreFría`; convocatoria `0.55*Relación + 0.30*Condición + 0.15*Liderazgo` (bloqueos: lesionado, Física < 30, Relación < 25); puntuación normal `0.50*Deporte + 0.30*Condición + 0.20*Innata`; decisiva `0.42*Deporte + 0.25*Condición + 0.13*Innata + 0.20*SangreFría`; penaltis `clamp(0.25 + 0.55*SangreFría/100 + 0.20*Deporte/100, 0.15, 0.90)`.
- **Divisiones:** 3ª Regional (umbral 45, 150 €/sem, prima victoria 50, gol 15), 2ª Nacional (62, 600 €, 200/50), 1ª Élite (78, 2500 €, 800/150), Superliga (90, 10000 €, 3000/500).
- **Economía:** primas y salario × `Multiplicador_Precios()`; salario domingo 23:59 (normal) o diario 23:59 (rápido). Lesión deportiva: 25 % si condición < 30 o Física < 25; estado `Lesion_Deportiva` 1440 min con techo de Física 35 → 100.
- **Conflictos:** entrenamientos y partidos frente a `Trabajo_Actual`; modales “Seguir con el fútbol” / “Mantener trabajo” al fichar o ascender, y “Dejar el fútbol y trabajar” / “Seguir en el fútbol” al aceptar un empleo. El ascenso conflictivo queda en `Conflicto_Ascenso_Pendiente` hasta que el jugador decide.
- **Persistencia:** `Carrera_Futbol` en el save dinámico con normalización de claves; saves antiguos cargan `Activo = false`.
- **UI:** botón `Carrera futbolística` en Actividades → Fijas; panel overlay responsive con requisitos, club, división, salario, barras, estadísticas, tabla dominical, toggles de asistencia y rescisión.

### L. Minijuego de Cocina + Apartado Minijuegos + Ropa Equipable (`Sistema_Cocina.gd`)
- **Archivos:** `Scripts/Logica/Escena_Principal/Minijuego_Cocina/Sistema_Cocina.gd` (autoload con fórmulas puras), `Scripts/GUI/Minijuego_Cocina/{Minijuego_Cocina,Arte_Cocina,Arrastre_Cocina,Sonidos_Cocina,Mejoras_Cocina,Arte_Modal_Cocina}.gd`, `Imagenes/Minijuego_Cocina/UI/Boton_Modal_{Azul,Verde,Naranja,Rojo}.png` (con `tools/generar_botones_modal.py`), `Sonidos/SFX/*.wav`, `Imagenes/UI/Iconos/triangle-alert.svg`, `Scripts/Logica/Escena_Principal/Economia/Herencia/Objeto_Ropa.gd`, `Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn`, tests `Funcionalidades/Minijuego_Cocina/Tests/{test_minijuego_cocina,test_arrastre_cocina,test_pedidos_cocina,test_alineacion_arte_cocina,test_mundos_cocina}.gd` (suite del minijuego **52/52**; suite completa GUT **310/310**), doc `Funcionalidades/Minijuego_Cocina/Documentacion/MINIJUEGO_COCINA.md` y `MUNDOS_NUEVOS.md`.
- **Desbloqueo y Mundos 2–4:** Primer minuto real trabajado en hostelería (`Actividades.Ejecutar_Actividad`), nunca al programar el bloque, **o** superar al menos 1 nivel del mundo anterior (`desbloqueo_total_qa = true` temporalmente en `Sistema_Cocina.gd` para pruebas QA; poner en `false` antes de publicar). Emite señal `restaurante_desbloqueado`. Mapeo 1 mundo ↔ 1 trabajo (15 niveles cada uno, 60 totales): Comida Rápida → `burger_street` (montaje), Ayudante de Cocina → `bistro_tradicional` (**Bistró:** parrilla con punto del filete —crudo/poco hecho/al punto/hecho/quemado—, filete vectorial 3/4 con hueso, etiquetas bajo la carne, servicio completo por toque sin arrastrar gracias a `zona_tocada`, quemados/crudos descartables por toque o basura, plato 3/4 y mejoras con textos/arte propios en `MEJORAS_UI_POR_RESTAURANTE` / `dibujar_mejora_bistro`), Cocinero de Partida → `cocina_mercado` (**Mercado:** olla combinatoria de 2 ingredientes por lotes de 4 raciones + plancha de huevos + barra), Chef Ejecutivo → `alta_cocina` (**Alta Cocina:** horno con ventana dorada 62–88 %, sartén de salsa que se quema si no se remueve, maridaje tinto/blanco y flor opcional +3 € propina).
- **Partidas por clientes y pausa:** cada nivel define `clientes` (11 en el nivel 1 → 31 en el 15) y arranca con `_clientes_pendientes = _clientes_totales`. `_process` solo intenta spawnear mientras queden pendientes; `_Intentar_Spawnear_Cliente()` descuenta uno al sentarse y `_Nivel_Completado()` cierra el servicio cuando no hay pendientes, ni clientes activos, ni animaciones de entrada/salida, llamando a `_Finalizar_Servicio()`. No hay límite de tiempo: `_tiempo_servicio` cuenta hacia arriba y el HUD muestra una píldora azul con el número de clientes (`_Clientes_Restantes()` = pendientes + sentados). El botón **MENÚ** (`Imagenes/UI/Iconos/menu.svg`) abre `Modal_Pausa` —panel azul cartoon de `Arte_Modal_Cocina.gd` con título dorado, placa de resumen y botones glossy apilados— con «Seguir cocinando» (`_Reanudar_Partida()`), «Repetir» (`_Repetir_Desde_Pausa()`) y «Al mapa» (`_Salir_Desde_Pausa()`); la ficha de nivel y el modal de resultados usan el mismo arte. Mientras está abierto `_jugando = false` y `_pausado_por_confirmacion = true`, por lo que se congelan reloj, paciencia, cocción y arrastre. `Escape`/botón atrás reanuda si el modal de pausa está visible.
- **Rotación y Reloj:** Al abrir `Minijuego_Cocina` se gira a horizontal `1280×720` (`SCREEN_LANDSCAPE`, `permissions/set_orientation=true` en `export_presets.cfg`), incluidos el selector de mundos, el mapa de niveles y la pantalla de Mejoras. La comprobación de plataforma debe usar `DisplayServer.get_name().to_lower()` porque en Android el nombre es `Android` con mayúscula. «Mapa»/«Volver» mantienen la horizontal; al salir al Sim (`_Salir_Al_Sim`, `_exit_tree`) se restaura la vertical `720×1280` tras ocultar las vistas. La carga (`Vista_Carga`, ~2 s, pasos y botón Cancelar) y la cocina también son horizontales. Se monta en un `CanvasLayer` sobre `Script_Principal` para que el reloj del Sim siga avanzando normalmente.
- **Transición de entrada y salida:** `Scripts/GUI/Transiciones/Transicion_Minijuego.gd` (`CanvasLayer` en `layer = 120`) dibuja un telón de cocina que sube desde abajo para cubrir la pantalla y sigue subiendo para descubrir la vista nueva. Entrada: `Script_Principal._Abrir_Minijuego_Cocina()` espera `Cubrir("Cocina", "Preparando los fogones…")`, instancia el minijuego debajo y llama a `Descubrir("¡A cocinar!")`. Salida: la señal `cerrado` espera `Cubrir("Volviendo al Sim", "Recogiendo la cocina…")`, retira la capa del minijuego, refresca la escena principal y llama a `Descubrir("¡De vuelta a casa!")`. El telón usa `#0b1220`, borde superior naranja, rayos cálidos animados, el chef `Chef_Pulgar_Arriba.png`, título, subtítulo y tres puntos rebotando; dura `0,34 s` en cubrir, `0,12 s` de espera y `0,40 s` en descubrir. Bloquea el ratón/táctil mientras se anima (`MOUSE_FILTER_STOP`) y `_transicion_minijuego_activa` evita aperturas o cierres duplicados.
- **Selector de mundos y salida segura:** El mapa abre mostrando solo los 4 mundos (`_restaurante_expandido` vacía, `_lista_restaurantes` visible y `_contenedor_niveles` oculta) dentro de un panel cartoon celeste dibujado por `Selector_Niveles_Arte.gd` (`Marco_Mapa`): marco turquesa, tablero azul embutido, título dorado «SELECCIONA UN NIVEL/MUNDO» con contorno azul marino, botón ATRÁS y flecha verde. El fondo es la foto `Fondo_Restaurante_Selector.png` desenfocada. Al tocar una tarjeta jugable se asigna su id, se oculta la lista y el tablero ocupa el panel: `Centro_Niveles` + `Grid_Niveles` (3 columnas) de monedas verdes `Boton_Nivel` con marco dorado, número central, tres estrellas y candado si están bloqueadas; barra de desplazamiento izquierda (`Barra_Scroll_Niveles`), pie `X / 45 ★ · Y / 15 niveles` y revelado escalonado (`_Animar_Revelado_Niveles()`). La flecha verde abre el siguiente nivel pendiente (`_Abrir_Siguiente_Nivel()`). El título de la barra superior pasa de «Cocina · Mundos» al nombre del mundo. «ATRÁS» (`_Volver_Mapa()`) regresa al selector de mundos sin cerrar el minijuego; en el selector sale al Sim. Los mundos se desbloquean al trabajar 1 minuto en su puesto o al superar 1 nivel del mundo anterior; los bloqueados son tarjetas deshabilitadas con miniatura desaturada, fondo azul grisáceo y píldora «BLOQUEADO». «Mejoras» queda deshabilitado hasta que hay un mundo jugable abierto. El botón «MENÚ» del HUD llama a `_Abrir_Modal_Pausa()` y congela la partida. `_Intentar_Volver_Al_Mapa()` sigue existiendo para el botón atrás y las pruebas: sin partida activa va al mapa y con `_jugando` o `_pausado_por_confirmacion` abre `Modal_Confirmar_Salida` —mismo marco azul cartoon, título «¿SALIR AL MAPA?», resumen «TICKET ACTUAL X € · N CLIENTES ATENDIDOS» en placa hundida y botones glossy «SEGUIR COCINANDO» / «SALIR Y PERDER PROGRESO»— y pausa `_jugando`; seguir reanuda y salir vuelve al mapa sin `Procesar_Fin_Nivel` (sin estrellas, propinas ni Caja). `ui_cancel`/Escape y `NOTIFICATION_WM_GO_BACK_REQUEST` pasan por `_Volver_Atras()` (cierra modales, confirma la partida, cancela la carga y, ya en el mapa, vuelve al selector si hay un mundo abierto o sale al Sim). `_ready()` guarda `SceneTree.is_quit_on_go_back()` en `_quit_on_go_back_previo` y llama a `set_quit_on_go_back(false)`; `_exit_tree()` restaura el valor.
- **Arrastrar y soltar:** plancha, freidora, emplatado, clientes y papelera. Cada cliente tiene dos zonas de destino equivalentes (su personaje y su bocadillo de pedido) que comparten la validación `_Puede_Servir_A_Cliente()`.
- **Emplatado visual:** puesto 3D con bandeja metálica renderizada (`Bandeja_Metal.png`) y **mampara de cristal** con marco cromado y filo verde (`Arte_Cocina.Fondo_Pase`). La bandeja tiene borde, paredes interiores y una alfombrilla beige hundida con **cuatro huecos fijos**. Al empezar se abren dos; `emplatado` Nv.2 abre el tercero y Nv.3 el cuarto. Los huecos cerrados son rebajes metálicos con candado dorado (`TEX_CANDADO_CERRADO`), pastilla `Nv.2`/`Nv.3` y plato fantasma apagado. Los platos activos usan `Plato_Perspectiva.png` (3/4, filo celeste grueso, `PLATO_PERSPECTIVA = 0.464`), se centran en su hueco y, vacíos, muestran un fantasma de pan cerrado con el «+» centrado; cuando coinciden con un pedido llevan anillo verde + check y al servir vuelan hasta el cliente. El pan solo (plato sin carne ni toppings, fantasma y panera) se dibuja con `dibujar_pan_cerrado()`: canto inferior de `Pan_Inferior.png` sin la cara de miga + tapa de `Pan_Superior.png` + sombras, para que se lea como un panecillo cerrado en 3/4. La hamburguesa montada se compone por capas normalizadas (ancho, alto y solape propios de cada ingrediente, mismo eje vertical). Los ingredientes viven en un **mueble bajo la encimera** (`Fondo_Despensa`) con recipientes integrados (`Puesto_Ingrediente`): panera de madera de dos huecos con panecillos cerrados (canto inferior + tapa), bandeja metálica de carne cruda, cesta roja de patatas, bol de lechuga, bandeja de tomate y tabla de queso, con placa pequeña en el estante; al pasar el dedo el recipiente se ilumina con un halo cálido. Tocar un puesto ejecuta la acción principal (carne → plancha, patatas → freidora, pan → plato, toppings → plato con pan) y la carne cocinada se arrastra al pan. El resaltado del tutorial también es un halo suave, no un recuadro, y los platos solo muestran el anillo verde cuando un cliente espera ese pedido (la selección no pinta nada).
- **Economía y Mejoras:** Caja del restaurante en € (`fondos_cocina`) para 5 mejoras Nv.1→3 (`plancha`, `emplatado`, `termostato`, `ingredientes`, `ambiente`): cada servicio ingresa `ventas − 30% ingredientes − (6 € + 2 € × nivel) − 30% merma`. El Sim cobra fuera de la Caja: propinas (50% del bote, ×1.5 en turno, ×0.25 en práctica), `5%` del beneficio neto (×0.25 en práctica), prima por nuevas estrellas (`10%` del umbral de cada estrella, escalada por nivel) y micro-propinas (`1–3 €`, tope `6 €`, ×0.25 en práctica). Fuera de turno solo los 2 primeros servicios/día con ≥1★ pagan paga completa; después, modo práctica. Drops por cliente de `Progreso_Cocina` (`15%`, `×2` en turno, `×7` en `Modo_Rapido`) y `Manualidades` (`5%`, `×7` en `Modo_Rapido`).
- **Pantalla de Mejoras (`Mejoras_Cocina.gd`):** modal a pantalla completa montado desde `Minijuego_Cocina._Construir_Modal_Mejoras()` sobre el mapa horizontal `1280×720` (tarjeta `1180×640`, dos columnas, azul noche + latón + crema). **Izquierda:** las 5 mejoras seleccionables con el icono de su nivel actual, nombre corto, tres estrellas, `Nv. X` y el coste siguiente (o `MÁX.` con check verde), tarjeta **TU PROGRESO** y aviso de que la Caja del local paga las mejoras. **Derecha:** escaparate grande de la **siguiente versión** (o la actual si está al máximo) con rayos/destellos del color de acento, sombra de contacto y flotación; píldora `SIGUIENTE MEJORA` / `TU MEJOR VERSIÓN`; pestañas `Nv.1/Nv.2/Nv.3` con `INCLUIDO`, coste siguiente o precio futuro atenuado con candado; panel crema `AHORA / CON LA MEJORA` con chips de beneficios y frase editorial. **Compra:** CTA verde `MEJORAR A NV. X · coste`; sin Caja suficiente pasa a ámbar `FALTAN X € · SIRVE MÁS CLIENTES` y sacude el botón. Llama a `Sistema_Cocina.Comprar_Mejora` (nunca usa `Variables_Dinamicas.Dinero`), actualiza la Caja, suena `coin`/`star`, muestra «¡NIVEL X!» y refresca el mapa. No hay gemas, diamantes ni moneda premium. `MEJORAS_DEF` añade `nombre_corto`, `acento` y `niveles` (nombre, beneficios, ganancias y frase), con los helpers `Obtener_Info_Nivel_Mejora`, `Obtener_Nombre_Nivel_Mejora`, `Obtener_Beneficios_Nivel_Mejora`, `Obtener_Ganancias_Nivel_Mejora` y `Obtener_Frase_Nivel_Mejora`. Arte: 15 PNG (3 por mejora) en `Imagenes/Minijuego_Cocina/Mejoras/`, cargados perezosamente con `Arte_Cocina.textura_mejora(id, nivel)` (`RUTAS_MEJORAS`); QA con `Escenas/Herramientas/Captura_Mejoras_Cocina.tscn` (capturas 01–08 en `user://capturas_mejoras_cocina`) y test `test_12_mejoras_presentacion_y_compra_en_modal`. Detalle en `Funcionalidades/Minijuego_Cocina/Documentacion/MINIJUEGO_COCINA.md`.
- **Logros y Ropa:** Rango `0..9` (sube cada 20 ★ acumuladas). Desbloquea las 4 prendas de cocina `Objeto_Ropa` en Rangos 1, 3, 6 y 9 (equipables en **Vestuario**, con bonus de salario hostelería, `-5%` desgaste Higiene y `+25%` propinas) y bonos pasivos en `Alimentacion.gd` (Rangos 2, 4, 7), `Actividades_Habilidades.gd` (Rango 5) e inmunidad a `"Intoxicación alimentaria"` en `Eventos_Aleatorios.gd` (Rango 8).
- **Vestuario y ropa visual:** `Pantalla_Vestuario.gd` sustituye el antiguo conmutador Ropa de Apuntes. `Ropa_Catalogo.gd` centraliza 25 atuendos con `desbloqueo` (`inicio`/`tienda`/`rango`), `categoria` (`diario`/`deporte`/`elegante`/`trabajo`/`fiesta`/`cocina`), precio, `estilo_visual`, `detalle_visual` y paleta. La tarjeta de Maestría Culinaria solo se muestra en el filtro `Cocina`. Las prendas de tienda se prueban y compran desde la pantalla (`Comprar_Ropa`); las de inicio se entregan con `Asegurar_Prendas_Iniciales()` también en saves antiguos. `Apariencia_Personaje.aplicar_atuendo()` superpone la prenda a la apariencia del creador y `Personaje_Visual._dibujar_atuendo_encima()` dibuja los detalles de los 19 estilos disponibles. El equipado se persiste en `Variables_Dinamicas.Objeto_Seleccionado["Ropa"]`.
- **Pack de sprites del escenario (arte):** `Imagenes/Minijuego_Cocina/` reúne 149 PNG originales —134 del pack base + 15 de mejoras— más los **3 fondos de los mundos nuevos** en `Fondos/` (chef + 6 poses, 8 clientes + 8 enfadados, 32 comidas, 8 estaciones, 8 piezas de mostrador, 22 de emplatado/props, 24 de UI, 8 de decoración, 8 efectos y 4 fondos `1280×720`). **Integrado en el minijuego jugable** vía `Arte_Cocina.gd`: fondo por restaurante, clientes, chef, estaciones, comida por capas, bocadillos de pedido, HUD y partículas. La escena de muestra `Escenario_Maqueta_Cocina.tscn` se conserva como maqueta visual (`./ver_escenario.sh`). La tarjeta «Cocina» de `Pantalla_Minijuegos` usa un banner propio (`Imagenes/Minijuego_Cocina/Banner_Cocina.png`, 1288×284) compuesto en 3/4 con plato en perspectiva (`Emplatado/Plato_Perspectiva.png`) y sombras de contacto. Fuentes, prompts, catálogos y pipeline en `Arte_Fuente/Minijuego_Cocina/` y `tools/`; documentación en `Funcionalidades/Minijuego_Cocina/Documentacion/ARTE_SPRITES.md` y capturas en `.../Documentacion/Capturas/`. Las 15 ilustraciones de mejoras (3 por cada una de las 5 mejoras) viven en `Mejoras/` y se generan con `python3 tools/procesar_mejoras_cocina.py` (recorte, halo blanco, despill de magenta fuerte y tope de 640 px) desde las hojas maestras `Arte_Fuente/Minijuego_Cocina/Mejoras/hoja_<mejora>.png` (prompts P22–P26).

### M. Música de fondo (`Musica.gd`)
- **Archivos:** `Scripts/Globales/Musica.gd` (autoload), `Sonidos/Musica/Lunchtime_Conspiracies.mp3` (general) y `Sonidos/Musica/Seven_Minutes_to_Service.mp3` (minijuego de cocina), ambos con `loop=true` en su `.import`; tests `Funcionalidades/Musica/Tests/test_musica.gd`; doc en `Funcionalidades/Musica/Documentacion/MUSICA.md`.
- **Reproducción:** dos `AudioStreamPlayer` sobre el bus `Musica` con fundido cruzado de `0.9 s`. La pista general arranca automáticamente y suena en menú, escena principal y resto de pantallas; el minijuego de cocina cambia a su pista en `_ready()` y restaura la general en `_exit_tree()`. La general se pausa (no se detiene) durante el minijuego para reanudar en el mismo punto. La pista del minijuego (`RUTA_PISTA_MINIJUEGO`, 4,3 MB) se carga de forma diferida en el primer `Reproducir_Minijuego()`: no se precarga al arrancar.
- **Volumen y silencio:** los gestiona el autoload `Ajustes`; `Musica` conserva su API (`Obtener_Volumen`, `Establecer_Volumen`, `Esta_Silenciado`, `Establecer_Silencio`, `Alternar_Silencio` y señal `silencio_cambiado`) delegando en él. Ya no hay botones de altavoz: el engranaje (`Boton_Ajustes` en el menú, `Boton_Ajustes_Header` en la cabecera) abre `Panel_Ajustes`, donde se regulan música y efectos por separado.

### N. Ajustes globales de audio (`Ajustes.gd`)
- **Archivos:** `Scripts/Globales/Ajustes.gd` (autoload), `Scripts/GUI/Ajustes/Panel_Ajustes.gd` (`class_name Panel_Ajustes`), tests `Funcionalidades/Ajustes/Tests/test_ajustes.gd` y doc `Funcionalidades/Ajustes/Documentacion/AJUSTES.md`.
- **Buses:** `Ajustes` se carga antes que `Musica` y crea los buses `Musica` y `SFX` (envían a `Master`). Aplica `AudioServer.set_bus_volume_db()` y `set_bus_mute()`; un volumen a `0` deja el bus muteado. `Sonidos_Cocina.gd` usa el bus `SFX`.
- **Persistencia:** `user://configuracion_ajustes.cfg` con `volumen_musica`, `volumen_sfx`, `silencio_musica` y `silencio_sfx` (por defecto `0.85`/`0.85`/`false`/`false`). Migra `user://configuracion_audio.cfg` la primera vez y agrupa las escrituras del deslizador con un `Timer` de `0.35 s`; guarda al pausar o cerrar.
- **Panel:** overlay `CanvasLayer` 120 (`Panel_Ajustes`) registrado en el grupo `Gestionar_Visibilidad.GRUPO_OVERLAY_MODAL` (`"overlay_modal"`) para sobrevivir a los cambios de pestaña (`Recursivo_Desvisibilizar`/`Recursivo_Visibilizar` ignoran su subárbol); `Visibilizar_Lo_Basico()` y `_Redisenar_Superior()` mantienen visible `Boton_Ajustes_Header` (un único botón con icono `settings`; ya no existe `Boton_Musica_Header`). Incluye banda roja con el icono `settings`, dos bloques (música roja y efectos azules), barras táctiles propias (`Barra_Volumen`), porcentaje, botón de silencio, «Probar sonido» y botones «Restablecer»/«Hecho». Cierra con `ui_cancel`/Escape, tocando fuera o con «Hecho». Se abre desde `Boton_Ajustes` (menú) y `Boton_Ajustes_Header` (escena principal), sin duplicados.
- **API:** `Obtener/Establecer_Volumen_Musica`, `Obtener/Establecer_Volumen_SFX`, `Esta_Silenciado_Musica/SFX`, `Establecer_Silencio_Musica/SFX`, `Alternar_Silencio_Musica/SFX`, `Probar_Efecto_Sonido()` y `Restablecer_Audio()`; señal `ajustes_cambiados` y señales específicas por valor. Para un ajuste nuevo, añadir campo + persistencia en `Ajustes.gd` y su bloque en `Panel_Ajustes.gd`.

### O. Pantalla de carga y transición al juego (`Pantalla_Carga.gd`)
- **Archivos:** `Scripts/Globales/Pantalla_Carga.gd` (autoload `Pantalla_Carga`, `CanvasLayer` con `layer=200`).
- **Flujo:** `Menu._reproducir_intro_nueva_partida()` lanza `Pantalla_Carga.Precargar()` mientras se ve el cómic; al terminar el remate final (o al pulsar «Saltar»), `Intro_Nueva_Partida.terminada` llama a `Pantalla_Carga.Ir_A_Escena_Principal()`, que muestra una pantalla roja estilo remate con barra de progreso. La precarga usa `ResourceLoader.load_threaded_request()` y el cambio final `change_scene_to_packed()`.
- **Sin fondo gris:** la capa es autoload y permanece visible durante la instanciación y el `_ready()` de `Escena principal.tscn`; se retira con un fundido cuando `get_tree().current_scene` ya es el juego. También se usa al pulsar «Continuar vida».
- **Vigilante:** si `ResourceLoader.load_threaded_get_status()` no avanza en `8 s` o la carga total supera `30 s`, `_Forzar_Carga_Sincrona()` deja de esperar al hilo y resuelve la carga en primer plano para no dejar la barra congelada.
- **Textos:** para partida nueva conserva el remate del cómic («Tu nueva vida / empieza ahora», «¡Mucha suerte ahí fuera!» y la píldora «18 AÑOS · 1.000 € EN EL BOLSILLO»); para continuar muestra «Tu vida continúa» / «Cargando tu partida…».
- **Persistencia del audio:** la gestiona el autoload `Ajustes` en `user://configuracion_ajustes.cfg`; `Musica` mantiene la pausa/reanudación en Android con `NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_APPLICATION_RESUMED`.

### O2. Optimización de arranque en Android (v0.33)
- **Síntoma corregido:** el APK podía quedarse en la pantalla de carga en un Redmi 11S. La causa principal era que `Script_Principal.gd` precargaba `Minijuego_Cocina.tscn` → `Arte_Cocina.gd` → 152 PNG (~72 MB en RGBA), además de `Juego/Flecha.png` (2400×2400, 22 MB) y varias pantallas completas.
- **Carga perezosa:** `Arte_Cocina.gd` declara las texturas como `static var TEX_*: Texture2D` con getter a `_tex(ruta)` y caché; `Script_Principal` carga `Minijuego_Cocina.tscn`, `Transicion_Minijuego.gd` y `Arte_Cocina` solo al abrir el minijuego. `Musica` carga el MP3 del minijuego al entrar. Carrera, Economía, Minijuegos y Vestuario se construyen la primera vez que se abren.
- **Texturas:** 160 PNG grandes (minijuego + cómic) con `compress/mode=2` y `high_quality=false` → ETC2 en Android / S3TC-BPTC en escritorio; se aplican con `python3 tools/optimizar_import_texturas.py` y `godot --headless --import`. El resto queda lossless. `Flecha.png` 2400→256 y los assets de marca de runtime a 256/512 (`generar_logo.py` guarda los maestros en `Arte_Fuente/Marca/`).
- **Renderizado:** `renderer/rendering_method="gl_compatibility"` (juego 2D) y `rendering_device/fallback_to_opengl3=true`; evita pipelines Vulkan y drivers problemáticos en móviles modestos.
- **Guardado:** `First_Time.Crear_Matriz()` usa `resize`+`fill`+`duplicate`; `_Matriz_A_RLE()` detecta filas vacías completas y `_RLE_A_Matriz()` se salta los tramos vacíos. El primer guardado pasa de ~200 ms a ~5 ms en escritorio.
- **UI:** el escaneo de `find_children()` cada 0,5 s se sustituye por `SceneTree.node_added` para estilar diálogos. `Pantalla_Carga` incorpora vigilante de 8 s sin avance / 30 s máximo.
- **Medición (escritorio de referencia):** carga de `Escena principal.tscn` 1,06 s → 0,52 s; memoria estática tras cargar 124,6 MB → 48 MB; `_ready` + 5 frames 1,7 s → 0,74 s. QA reproducible con `Scripts/Otro/Herramientas/Perfil_Arranque.gd` y `Perfil_Escena_Principal.gd`.

### P. Envejecimiento visual del personaje (`Envejecimiento_Personaje.gd`)
- **Archivos:** `Scripts/Logica/Personaje/Envejecimiento_Personaje.gd` (`class_name`, puro y sin estado), enganches en `Scripts/GUI/Personaje/Personaje_Visual.gd`, herramienta `Scripts/Otro/Herramientas/Exportar_Envejecimiento.gd`, tests `Funcionalidades/Personaje/Envejecimiento/Tests/test_envejecimiento.gd` y doc `Funcionalidades/Personaje/Envejecimiento/Documentacion/ENVEJECIMIENTO.md`.
- **Edad:** no se guarda. `Personaje_Visual.edad = -1` (por defecto) consulta `Variables_Estaticas.Calcular_Edad()` en cada dibujo; `edad = N` la fuerza (creador, capturas, pruebas). Los retratos con `animar_idle = false` repintan solos cuando cambia el año.
- **Curvas:** `Envejecimiento_Personaje.CURVAS` define `[edad_inicio, edad_plenitud]` por rasgo y avanza con smoothstep. Todos los factores valen 0 a los 18 y 1 a los 100. Orden de aparición: surcos (29) → pelo fino (30) → frente/canas (33) → patas de gallo (38) → bolsas (41) → piel apagada/flacidez (44) → cejas finas (50) → manchas (52) → postura (56).
- **Dibujo:** `dibujar_marcas_cara()` pinta frente, entrecejo, patas de gallo, bolsas, surcos nasogenianos, pliegue del mentón, papada, manchas y pliegues del cuello. El pelo pasa de su color a plata y luego a blanco con `color_pelo()` y pierde brillo; la piel se desatura con `color_piel()`. La postura (hombros caídos y cabeza hundida) se aplica en `obtener_rig_pose()`.
- **Alcance:** al vivir en `Personaje_Visual`, se aplica a avatar de cabecera, Perfil → Info, escenario de actividad, logo del menú y viñetas. El Perfil → Info muestra además la fila «Etapa de vida» (`etapa()`).
- **Ajuste:** modificar `CURVAS` o las opacidades de `dibujar_marcas_cara`. Lámina comparativa: `godot --path . --script res://Scripts/Otro/Herramientas/Exportar_Envejecimiento.gd`.

---

### Q. Bienestar y rejuvenecimiento (Tienda → Bienestar)
- **Archivos:** `Scripts/Globales/Recompensas.gd` (autoload), `Scripts/Globales/Recompensas/Recompensas_Catalogo.gd`, `Proveedor_Anuncios.gd`/`Proveedor_Simulado_Anuncios.gd`, `Scripts/GUI/Tienda/Tienda_Bienestar.gd`, `Modal_Tratamiento.gd`, `Modal_Anuncio_Bienestar.gd` y `Visual_Bienestar.gd`. La pestaña se abre con el chip «Bienestar» construido por `Tienda_Objetos.gd` y el contenido vive en `Objetos_Ventajas` de `Tienda.tscn`. Tests: `Funcionalidades/Bienestar/Tests/test_bienestar.gd`. Doc: `Funcionalidades/Bienestar/Documentacion/BIENESTAR.md`.
- **Qué incluye:** anuncios de 5–8 s con +150 €, +30 a cada necesidad, 2 tuppers o −1 año (esperas de 5–60 min); servicios de cuidado con euros (día de spa 120 €, cesta gourmet 90 €) y clínica de rejuvenecimiento: spa −1 año (400 €), clínica −3 años (1.100 €) y cápsula −5 años (2.200 €), con precio creciente por sesión.
- **Rejuvenecimiento:** `Variables_Dinamicas.Rejuvenecimiento_Anios` resta años en `Variables_Estaticas.Calcular_Edad()` con suelo 18; `Tratamientos_Rejuvenecimiento` escala el precio. Se guarda con la partida y actualiza retratos, HUD y fútbol.
- **Arquitectura:** la UI no concede nada; llama a `Recompensas` y espera (`await`). El dominio valida dinero, edad mínima, cooldown y token de anuncio; aplica recompensas en `Variables_Dinamicas`, emite señales y persiste esperas/historial en `user://recompensas.cfg`. No existe pasarela de pago.
- **UI:** barra edad/dinero, héroe de clínica con medidor de edad 18–100 y marca fantasma, tarjetas de tratamientos, cuidado exprés, anuncios con espera/barra y pie con reinicio de esperas. Modales propios con antes/después y éxito con confeti; cuenta atrás y recompensa para anuncios. Se adapta a `720×1280` y pantallas altas (`720×1600`).
- **QA:** 20 tests / 193 aserciones (`godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://Funcionalidades/Bienestar/Tests -gexit`) y capturas reproducibles con `Escenas/Herramientas/Captura_Bienestar.tscn` y `..._Alta.tscn`.

## 7. Roadmap vigente (por prioridad)

> Fuente canónica: `ROADMAP.md` (v3.0, 21/11/2026). Copia de trabajo para NotebookLM: `notebookLM/01_ROADMAP_Y_PROGRESO.md`.

### Fase 1 — Cerrar los cuatro pilares

1. **Universidad y exámenes (prioridad 1).** Rediseño del ciclo anual: matrícula única, clases/asistencia, examen pendiente todo el día (sin ventana de 1 hora), test con temporizador + caso práctico por carrera, nota con desglose y recompensas por tramo. El test del jugador pasa de +10 % a pieza central. Banco de 30–40 preguntas por año. **2–3 semanas.**
2. **Minijuego de fútbol (prioridad 2).** «Partido en 90 segundos»: 5–6 acciones (3 ataques, 2 defensas y penalti), integrado con `Sistema_Futbol`; si el jugador no lo juega, sigue el auto-simulador. **2–3 semanas.**
3. **Minijuego de bolsa (prioridad 3).** «Sala de trading» de 2–3 minutos con 4 activos ficticios, noticias, 8 rondas, comisión y riesgo real; la inversión pasiva se mantiene como modo cómodo. **2 semanas.**
4. **Cocina: balance y pulido (en paralelo).** Sin contenido nuevo: curva de dificultad, economía €/h, claridad de recompensas, mejoras y QA en dispositivo. **3–5 días.**

### Fase 2 — Economía y mundo

Auditoría económica global, modos de dificultad, logros/metaprogresión, relaciones (NPCs), hitos por edad, más actividades, notificaciones locales y onboarding.

### Fase 3 — Lanzamiento

Anuncios reales (AdMob/UMP/SSV sobre `Proveedor_Anuncios`), rendimiento/batería, QA en dispositivos, beta cerrada, assets de tienda, privacidad, rating de edad y diferenciación legal.

### No hacer ahora

Modo mánager de fútbol, más mundos o niveles de cocina, más carreras universitarias, un minijuego distinto por actividad, multijugador, pagos o moneda premium, y ampliación del avatar visual.

---

## 7.1 Infraestructura de desarrollo remoto (OpenCode Web + Android + Drive)

- **Chat web:** `opencode serve` (OpenCode V2; `opencode web` ya no existe) en `127.0.0.1:4096`, gestionado por `opencode-web.service` (systemd de usuario, `Linger=yes`). URL pública HTTPS vía OpenTunnel: `https://2eb947ae0e058eba.og745fnao4l5.opentunnel.xyz`. Contraseña en `~/.config/opencode/web.env`; script de estado `~/iniciar_opencode_web.sh`.
- **Modelos:** OpenCode Go ya autenticado; Google AI Pro/Gemini se vincula con `/connect`. No requiere cambios en `opencode.jsonc`.
- **Android:** Godot 4.7.2 + templates 4.7.2, Temurin JDK 17 en `~/opt`, Android SDK en `~/android-sdk`, keystore fijo `~/android-sdk/sims_debug.keystore`. Package `com.lur.sims033` (no cambiar: rompería actualizaciones y partidas).
- **Build + Drive:** `./scripts_vps/crear_apk_drive.sh` ejecuta GUT headless, reimporta, exporta APK debug a `/tmp/` y sube a `gdrive:SIMS_Builds/` con `rclone`. `sims-latest.apk` es siempre el último build. Vincular Drive una vez con `rclone config reconnect gdrive:`.
- **Doc completa:** `Documentacion/DevOps/ENTORNO_VPS_OPENCODE_ANDROID.md`.

---

## 8. Tu Protocolo de Trabajo Conmigo
Cuando te proponga una nueva funcionalidad o cambio:
1. **Analiza el encaje** con los sistemas actuales (autoloads, variables, matriz, prioridades P1/P2/P3, saves, `Modo_Rapido`, UI portrait 720×1280).
2. **Detecta huecos y hazme preguntas concretas** sobre diseño, balanceo, UX o edge cases antes de cerrar la especificación.
3. **Propón la arquitectura exacta** (archivos a crear/modificar, funciones puras testeables con GUT, nodos `.tscn` y `Estilos_UI`).
4. **Cuando te diga "genera el prompt para Antigravity"**, entrega un único bloque Markdown copiable con:
   - **Contexto obligatorio** (lista exacta de archivos que Antigravity debe leer).
   - **Reglas duras** (Godot 4.4, portrait 720×1280, compatibilidad saves, rendimiento O(1), etc.).
   - **Especificación técnica paso a paso** (archivo por archivo, firmas exactas, fórmulas, nodos UI, textos).
   - **Tests GUT obligatorios** (funciones puras deterministas) y **criterios de aceptación**.

Confirma que has entendido el proyecto al 100 % resumiendo en 3 líneas su arquitectura clave y pregúntame qué nueva funcionalidad queremos diseñar hoy.
