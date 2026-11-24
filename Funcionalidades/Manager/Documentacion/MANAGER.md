# El Mánager (Fase 2 — Modo Club Top Eleven)

## Resumen
«El Mánager» es el modo de gestión integral de club que se desbloquea tras retirarse como futbolista (`Sistema_Futbol`) o tras obtener el título oficial de entrenador. A diferencia de la Fase 1 (`Sistema_Futbol`, donde solo gestionas a tu jugador), aquí diriges un ecosistema cerrado y vivo de **16 clubes** (4 divisiones × 4 clubes) y **288 futbolistas** con rostros y vestuario humanos, economía propia, instalaciones, cantera, pizarra táctica interactiva y partidos de 90 minutos en directo sobre un campo 2D animado.

---

## Desbloqueo e identidad del club
- **Por retiro:** si `Sistema_Futbol.Puede_Retirarse()` es cierto (`≥ 32` años o `≥ 3` temporadas), el Sim se retira gratis con reputación inicial heredada (`15..70`) y deja cerrada su carrera de jugador.
- **Por título oficial:** si no hay carrera de futbolista activa, cuesta `1.500 € × Multiplicador_Precios()` y otorga reputación base `25`.
- **QA temporal:** `Sistema_Manager.DESBLOQUEO_MANAGER_QA = true` permite abrir y probar el modo desde el principio (poner en `false` antes de publicar).
- **Fundación:** gratuita una vez desbloqueado; nombre libre (≥ 2 letras, sin duplicar rivales IA), ciudad, paleta de 12×2 colores, **5 patrones heráldicos** (`Liso`, `Franjas`, `Diagonal`, `Mitades`, `Cruz`) con vista previa simultánea del escudo (`Cresta_Manager`), camiseta del jugador (`Personaje_Visual` `"club_<patron>_10"`) y el propio Sim en traje (`Estilo_Manager.crear_retrato_manager`).

---

## Arquitectura de archivos

### Lógica y simulación (`Scripts/Logica/Escena_Principal/Manager/`)
| Archivo | Responsabilidad |
|---|---|
| `Datos_Manager.gd` | Constantes puras: divisiones, horarios, roles, colores de línea (`COLORES_LINEA`), atributos clave por demarcación (`ATRIBUTOS_CLAVE_ROL`), patrones de escudo (`PATRONES_ESCUDO`), sugerencias de club/ciudad, costes y descripciones de instalaciones (`INSTALACIONES_*`), ojeo de cantera (`COSTE_OJEAR_CANTERA`), clubs IA, velocidades (`[1, 2, 4, 8]`, `3.6 s/min` a x1). |
| `Simulador_Manager.gd` | Matemática pura sin efectos secundarios: ecosistema 16×18, calidad/estrellas/valor/salario/cláusula, `Calcular_Fuerza_Club`, `Evaluar_Alineacion_Slots`, ascensos/descensos (`×0,80`/`×1,20`), jubilación y cantera (`Generar_Canteranos_Ojeo`), motor de partido minuto a minuto (`Simular_Minuto`, tiros, córners, faltas, tarjetas, cansancio), clasificación y calendario (`Parejas_Jornada_Division`), y rasgos/apariencia determinista por `id` (`Apariencia_De_Jugador`, `Rasgo_Humano_Jugador`, `Frase_Vestuario_Jugador`). |
| `Sistema_Manager.gd` | Autoload conectado al reloj en `Script_Principal`. Orquesta `Variables_Dinamicas.Manager_Estado`, normalización retrocompatible (`Normalizar_Estado`), recuperaciones (10 min reales + bonus de Ciudad Deportiva), envejecimiento, nóminas, mercado IA, amistosos diarios (`Iniciar_Partido_Amistoso`), entreno individual y por línea (`Entrenar_Linea_Equipo`), instalaciones (`Mejorar_Instalacion`), cantera (`Ojear_Cantera` / `Fichar_Canterano`), capitanía/dorsal/contratos, cambios tácticos (`Intercambiar_Titulares`, `Establecer_Tactica`, `Cambiar_Presion_Partido`), renuncia (`Renunciar_Al_Club`) y `Hay_Novedad()` para el badge de Minijuegos. |

### Interfaz de usuario (`Scripts/GUI/Escena_Principal/Manager/` y `Scripts/GUI/Personaje/Personaje_Visual.gd`)
| Archivo | Responsabilidad |
|---|---|
| `Estilo_Manager.gd` | Paleta común de club, retratos de jugador y de Sim Mánager usando `Personaje_Visual`, botones con estado `disabled` de alto contraste (`#64748b` sobre `#e2e8f0`), selectores tipo *pill* (`selector_chips`, `toggle_pill`), barras comparativas/de atributos y reproductor SFX único en el bus `SFX` (silenciado en headless). |
| `Cresta_Manager.gd` | Escudo heráldico curvado dibujado por vectores con recorte geométrico (`Geometry2D.intersect_polygons`), 5 patrones, sombreado 2.5D y medallón central legible según luminancia. |
| `Banner_Manager.gd` | Banner procedural para la tarjeta del hub Minijuegos (`Script_Principal._Anadir_Tarjeta_Manager()`): focos del estadio, césped en franjas, escudo del club, balón y retrato en traje del Sim entrenador. |
| `Campo_Manager.gd` | Pizarra táctica vertical interactiva (`slot_tocado`). Dibuja al once en la formación activa con dorsal, apellido, aro de energía, insignia de capitán `(C)`, alerta fuera de puesto (`!`) y halo de selección para intercambiar puestos entre titulares o con el banquillo. |
| `Panel_Manager.gd` | Pantalla principal **horizontal `1280×720`** (`Panel_Manager.tscn`): rotación automática a apaisado al abrir y vuelta a vertical `720×1280` al salir, manejo de botón atrás/Escape, cabecera fija con escudo y estado en línea (`Caja`, `Directiva`, `Próximo partido`), 5 pestañas (`Club •`, `Plantilla`, `Táctica`, `Mercado`, `Liga`), Desbloqueo y Fundación en 2 columnas, Plantilla en cuadrícula de 3 columnas y pizarra `Campo_Manager` paralela a sistema/titulares/banquillo. |
| `Panel_Manager_Vistas.gd` | Builders modulares apaisados consumidos por `Panel_Manager`: ficha humana del jugador en modal de 2 columnas (rostro, rasgo, frase de vestuario, capitanía, renovación, selector `- / +` de dorsal, 15 atributos con estrella y entrenamiento), Mercado y Cantera en rejillas de 2–3 columnas (`Fichar`, `Vender`, `Cantera`), modal de oferta con pasos `+ / −` y Liga en 2 columnas (tabla + emparejamientos / líderes + resultados). |
| `Vista_Partido_Campo.gd` | Campo 2D horizontal en directo con 22 fichas móviles guiadas por posesión/zona, balón animado y destello de evento (gol, ocasión, córner, tarjeta). |
| `Panel_Manager_Partido.gd` | Emisión en directo en diseño apaisado de 2 columnas (`Panel_Manager_Partido.tscn`): marcador panorámico superior con escudos y barra de tiempo; izquierda con `Vista_Partido_Campo`, pausa, velocidades `x1/x2/x4/x8` (`3,6 s/min` a x1 ≈ 5,4 min reales) + `Saltar` y banquillo reactivo con botones de Mentalidad/Presión; derecha con estadísticas comparativas y teletipo fijo. Incluye **charla en el descanso (45')**, modal de cambios en 2 columnas paralelas y resumen final horizontal. |
| `Transicion_Minijuego.gd` | Telón animado reutilizado (`configurar_tema("manager", club)`): al entrar desde `Script_Principal._Abrir_Manager()` y al salir por `cerrado`, sube cubriendo la pantalla con rayos verde estadio, escudo del club y el Sim mánager en traje mientras ejecuta el giro entre vertical y horizontal `1280×720`. |
| `Personaje_Visual.gd` | `_dibujar_detalles_futbol()` soporta `"club_<patron>_<dorsal>"` y `"dorsal_<n>"`, manteniendo el `"10"` clásico para Fase 1 y vestuario general. |

---

## Mecánicas clave añadidas y actualizadas
- **Entrenamiento colectivo e individual:** 1 sesión grupal diaria por línea (`defensa`, `medio`, `ataque`, `fisico`) que consume `8` pts de energía y mejora atributos afines, además del entrenamiento individual diario (`-12` pts de energía). Ciudad Deportiva potencia recuperaciones y progreso.
- **Instalaciones (Nv 1–5):** `Estadio` (`+20 %` taquilla local/nivel y afición), `Ciudad Deportiva` (`+15 %` recuperación/nivel y mejor entreno) y `Academia de Cantera` (mejores juveniles).
- **Cantera:** ojeo diario de 3 promesas (16–20 años) ajustado a la división y nivel de Academia, con incorporación directa al primer equipo si hay hueco (`< 18`).
- **Amistosos diarios:** 1 amistoso al día cuando no hay partido oficial pendiente (`Iniciar_Partido_Amistoso`), útil para probar táctica, rodar jugadores y obtener un `35 %` de taquilla sin afectar puntos ligueros.
- **Mercado sin bloqueo de día 1:** `Vender_Jugador` prioriza clubes IA locales con hueco (`< 18`) y presupuesto; si todos los clubes locales están llenos (`18/18`), concreta el traspaso con un club extranjero para permitir compras o promociones de cantera desde la primera jornada.

---

## Tests y QA visual
- **Suite GUT (`Funcionalidades/Manager/Tests/test_manager.gd`):** **35 tests** pasando (26 base + 9 nuevos de pizarra, instalaciones, entreno por línea, cantera, amistosos, capitanía/dorsal/renovación, fuerza/apariencia/`Hay_Novedad`, *smoke test* completo de UI para `Panel_Manager`/`Panel_Manager_Partido` y transición/orientación horizontal `1280×720`).
- **Escena de QA visual (`Escenas/Herramientas/Captura_Manager.tscn` / `Scripts/Otro/Herramientas/Captura_Manager.gd`):** genera **16 capturas apaisadas** a `1280×720` en `/tmp/opencode/capturas_manager/` (`club`, `plantilla`, `ficha`, `tactica`, `mercado`, `cantera`, `oferta`, `liga`, `descanso`, `partido`, `cambios`, `resultado`, `desbloqueo`, `fundacion`, `banner` y `transicion`).
