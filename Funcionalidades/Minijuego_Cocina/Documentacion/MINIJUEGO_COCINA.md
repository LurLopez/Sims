# Minijuego de Cocina (gestión de pedidos) + Apartado Minijuegos + Ropa Equipable

## 1. Resumen

Funcionalidad completa en Godot 4.4+ (GDScript 2.0) que añade:

- **Apartado modular de Minijuegos** (`Minijuegos_Button` en la barra superior de 6 botones + vista `Pantalla_Minijuegos` preparada para futuros minijuegos). Ver también [`MUNDOS_NUEVOS.md`](MUNDOS_NUEVOS.md) para el detalle completo de los mundos 2–4.
- **Minijuego de Cocina de gestión de pedidos** (`Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn`) con **selector de mundos/niveles, Mejoras, pantalla de carga y partida en horizontal** (`1280×720`), ejecutado como overlay `CanvasLayer` sobre `Script_Principal` para que el reloj del Sim siga avanzando. Al entrar gira a horizontal y al volver al Sim restaura la vertical `720×1280`.
- **Cocina jugable con arrastrar y soltar + toque rápido**: los ingredientes, la carne cocinada, las patatas, los platos montados y los refrescos se arrastran con el dedo/ratón hasta la plancha, la freidora, el plato, el cliente (o su bocadillo de pedido) o la papelera. Tocar un recipiente hace su acción principal (carne → plancha, patatas → freidora, pan → siguiente plato y queso/lechuga/tomate → plato con pan) y la carne cocinada se arrastra hasta el pan. Los ingredientes viven en un **mueble bajo la encimera** con recipientes reales, no en una botonera inferior.
- **Niveles por clientes, no por tiempo**: cada nivel tiene un número fijo de clientes (11 en el nivel 1 y hasta 31 en el 15) y el servicio termina cuando ya no queda ninguno por llegar ni sentado. El HUD muestra los clientes restantes, el reloj cuenta el tiempo transcurrido y un botón de **pausa** permite seguir, repetir el nivel o salir.
- **Arte del pack de sprites PNG** (`Imagenes/Minijuego_Cocina/`): fondo de diner 1280×720, 8 clientes + 8 versiones enfadadas, 7 poses de chef, estaciones, comida, UI y efectos.
- **Animaciones de personajes y cocina**: llegada y saludo del cliente, pedido que aparece con rebote, paciencia con cambio de cara y avisos, masticación/celebración y salida airada; reacciones del chef; volteo de la carne al estar lista; vapor, humo, fuego, chispas, monedas y estrellas.
- **Efectos de sonido originales** sintetizados (15 WAV) con pool de voces en el bus `SFX` (volumen/silencio en Ajustes); música del minijuego a través del autoload `Musica`.
- **Economía de Caja + costes** (la Caja del restaurante recibe ventas menos ingredientes/gastos/merma y paga las 5 mejoras; el Sim cobra propinas, una parte del beneficio y primas por estrellas), **dos servicios con paga completa al día** fuera de turno y modo práctica al 25% después, **Maestría Culinaria por estrellas** (cada 20 ★, Rangos 0–9) y **ropa equipable** (`Objeto_Ropa`, categoría `"Ropa"`) gestionable en la sección **Vestuario** de la barra superior (también accesible desde Inicio y Perfil → Info).

---

## 2. Arquitectura y Archivos

| Archivo | Rol |
|---|---|
| `Scripts/Logica/Escena_Principal/Minijuego_Cocina/Sistema_Cocina.gd` | Autoload `Sistema_Cocina`. Catálogo data-driven de 4 mundos de cocina, uno por trabajo de hostelería (**15 niveles jugables en cada mundo**), recetas por restaurante, perfiles de estación/despensa, 5 mejoras, fórmulas puras `static func`, desbloqueo por trabajo o por progresión, micro-recompensas, fin de nivel, logros y helpers de ropa. |
| `Scripts/GUI/Minijuego_Cocina/Minijuego_Cocina.gd` | Controlador de orientación: selector de mundos (cuadrícula 2×2 + chef + tarjeta de Maestría), mapa de 15 niveles (5×3), pantalla de carga y cocina jugable, todos en horizontal `1280×720`; HUD (reloj transcurrido y clientes restantes) y modales cartoon de pausa, ficha de nivel, confirmación de salida, Maestría y resultados, construidos con `_Crear_Modal_Base()` y `_Animar_Entrada_Modal()` (fundido + pop). Gira a horizontal al abrirse y restaura la vertical al salir; comprueba `DisplayServer.get_name().to_lower()` porque Android devuelve `Android` con mayúscula. El mapa delega el dibujo en `Selector_Niveles_Arte.gd`. |
| `Scripts/GUI/Minijuego_Cocina/Mejoras_Cocina.gd` | Pantalla de Mejoras a tamaño completo: lista de 5 mejoras con estrellas, escaparate grande de la siguiente versión (`Escaparate_Mejora`), pestañas de nivel con coste, comparativa de rendimiento, CTA de compra con la Caja y animaciones de apertura/celebración. |
| `Scripts/GUI/Minijuego_Cocina/Selector_Niveles_Arte.gd` | Arte cartoon del selector: `Fondo_Mapa` (foto desenfocada + viñeteado), `Marco_Mapa` (marco celeste/tablero azul), `Titulo_Dorado` (degradado con shader), `Boton_Nivel` (moneda verde + estrellas + candado), `Boton_Atras`, `Boton_Siguiente` y `Barra_Scroll_Niveles`. |
| `Scripts/GUI/Minijuego_Cocina/Arte_Modal_Cocina.gd` | Arte cartoon compartido por los modales de pausa, ficha de nivel, confirmación de salida y resultados: `Marco_Modal` (panel azul con degradado, brillo y destellos), `Titulo_Modal` (dorado con degradado por shader y contorno azul marino), `Boton_Modal` (botones glossy 9-patch del pack), placas hundidas (`caja_placa`), píldoras doradas (`caja_pildora_oro`), iconos de usuarios/estrella, divisor y textos con sombra (`texto_modal`, `texto_cartoon`). Helpers: `crear_titulo`, `crear_boton`. |
| `Imagenes/Minijuego_Cocina/UI/Boton_Modal_{Azul,Verde,Naranja,Rojo}.png` | Texturas 9-patch de los botones glossy de los modales (600×64, remaches laterales de 64 px y centro estirable). Se generan con `tools/generar_botones_modal.py` a partir de `Boton_Azul/Verde/Naranja.png` del pack; el rojo se obtiene por rotación de tono. |
| `tools/generar_botones_modal.py` | Pipeline PIL de los 9-patch: escala el botón del pack a 64 px de alto, copia los remaches izquierdo/derecho y rellena el centro con una columna uniforme para estirar sin deformar el brillo. |
| `Scripts/GUI/Minijuego_Cocina/Arte_Cocina.gd` | Registro de texturas del pack, **fondos por restaurante**, composición de hamburguesas por capas y de los platos de bistró/mercado/alta cocina, tickets/bocadillos, platos, puntos de cocción (filete, huevo, solomillo, lubina, pato), bebidas, mueble/recipientes de ingredientes (`Puesto_Ingrediente` y `Fondo_Despensa`), estaciones dibujadas (`Estacion_Olla`, `Sarten_Salsa`, `Estacion_Horno`, `Estacion_Botellas`) y capa de partículas. |
| `Scripts/GUI/Minijuego_Cocina/Arrastre_Cocina.gd` | Gestor de arrastrar y soltar: zonas de origen/destino, fantasma animado, resaltado de destino y señales de soltado. |
| `Scripts/GUI/Minijuego_Cocina/Sonidos_Cocina.gd` | Pool de 12 `AudioStreamPlayer` en el bus `SFX` para los 15 SFX originales; volumen y silencio se configuran en `Ajustes`. |
| `Scripts/GUI/Minijuego_Cocina/Sprites_Cocina.gd` | **Legacy**: sprites vectoriales 2.5D usados antes de integrar el pack PNG. El minijuego ya no lo carga; se conserva como referencia/fallback. |
| `Sonidos/SFX/*.wav` | Efectos sintetizados: click, pop, drop, sizzle, ding, burn, coin, happy, angry, trash, pour, star, combo, start y level_end. |
| `Imagenes/UI/Iconos/triangle-alert.svg` | Icono Lucide de aviso (triángulo con exclamación) usado por otras pantallas (Mejoras y Bienestar); no interviene en los modales del minijuego, que usan el arte cartoon de `Arte_Modal_Cocina.gd`. |
| `Scripts/Logica/Escena_Principal/Economia/Herencia/Objeto_Ropa.gd` | Subclase `Objeto_Ropa extends Objeto` (`desbloqueo`, `categoria`, bonificaciones de salario general/hostelería, progreso, higiene y propinas, `descripcion_efecto`) y campos visuales (`estilo_visual`, `detalle_visual`, `prenda_superior`, `prenda_inferior`, `calzado`, paleta). |
| `Scripts/Logica/Escena_Principal/Economia/Ropa_Catalogo.gd` | Catálogo central de las 25 prendas: inicio gratis, tienda con precio y rango de cocina. |
| `Scripts/Globales/Principales_Variables/Variables_Dinamicas.gd` | `Cocina_Estado` (`COCINA_ESTADO_BASE` y `Cocina_Estado_Por_Defecto()`), defaults de `"Ropa_Calle"` y `Objeto_Seleccionado["Ropa"]`. |
| `Scripts/Globales/Principales_Variables/Variables_Estaticas.gd` | `Record_Max_Niveles_Cocina` y llamada a `Ropa_Catalogo.Registrar_En()` para construir las 25 prendas en `Catalogo_Objetos`. |
| `Scripts/Otro/Guardar/Guardar_Variables_Dinamicas.gd` | Guardado/carga con merge recursivo (`_Normalizar_Cocina_Estado`) y fallback `"Ropa_Calle"` / `"Ropa"`. |
| `Scripts/Otro/Guardar/Guardar_Variables_Estaticas.gd` | Persistencia de `Record_Max_Niveles_Cocina` (fallback `0`). |
| `Scripts/Globales/Menu.gd` & `First_Time.gd` | Reseteo/inicialización limpia de `Cocina_Estado` y `"Ropa"` en nuevas partidas. |
| `Scripts/Logica/Escena_Principal/Actividades/Actividades.gd` | Desbloqueo al primer minuto trabajado y pago de nómina con bonus de ropa + `+10%` de `plus_nomina_turno_hoy`. |
| `Scripts/Logica/Escena_Principal/Actividades/Actividades_Necesidades_Basicas.gd` | Reducción de desgaste de Higiene en trabajos: `-5%` de hostelería o `-10%` de uniformes generales, según la prenda equipada. |
| `Scripts/Logica/Escena_Principal/Actividades/Actividades_Habilidades.gd` | Bono Rango ≥ 5 (`+15%` eficiencia en `Progreso[2]` Manualidades y `Progreso_Cocina`). |
| `Scripts/Logica/Escena_Principal/Actividades/Alimentacion.gd` | Bonos Rango ≥ 2 (`+2` Salud Mental), Rango ≥ 4 (`-20%` coste comida rápida, `+15%` saciedad tupper) y Rango ≥ 7 (`+15%` recuperación Hambre y `+1` Salud Física). |
| `Scripts/Logica/Escena_Principal/Actividades/Eventos_Aleatorios.gd` | Inmunidad a `"Intoxicación alimentaria"` con Rango ≥ 8 (160 ★). |
| `Escenas/Escena_Principal/Escena principal.tscn`, `Pantalla_Mensajes.tscn`, `Script_Principal.gd`, `Estilos_UI.gd`, `Gestionar_Visibilidad.gd`, `Scripts/GUI/Escena_Principal/Vestuario/Pantalla_Vestuario.gd` | Barra superior de 6 pestañas (`Minijuegos_Button`, `Vestuario_Button`; la Tienda se abre con el icono `Boton_Tienda_Header` y `Tienda_Button` queda oculto por compatibilidad), `Pantalla_Minijuegos` (banner con arte del minijuego), toast de desbloqueo, `Atuendo` y `Maestría Culinaria` en Perfil → Info y armario independiente en Vestuario (vista previa, tarjetas y progreso). |
| `export_presets.cfg` | `permissions/set_orientation=true` en preset Android. |
| `Funcionalidades/Minijuego_Cocina/Tests/test_minijuego_cocina.gd` | Suite GUT de economía, fórmulas, desbloqueo, logros y UI, incluida la navegación selector de mundos ↔ mapa de niveles, la confirmación de salida, la pausa, el fin por clientes, el HUD superior (menú/clientes/dinero), el marco cartoon y las monedas con número (15 tests). |
| `Funcionalidades/Minijuego_Cocina/Tests/test_arrastre_cocina.gd` | Suite GUT del gesto de arrastre, flujo carne→plancha→plato→cliente, rechazos, papelera, bebidas, toques rápidos, disposición de los puestos y pase de cuatro huecos con candados (11 tests). |
| `Funcionalidades/Minijuego_Cocina/Tests/test_pedidos_cocina.gd` | Test de determinismo de la secuencia de pedidos entre partidas (1 test). |
| `Funcionalidades/Minijuego_Cocina/Tests/test_mundos_cocina.gd` | **12 tests** de los mundos 2–4: catálogo y fondos, punto del filete, combos de la olla, ventana del horno, progresión de desbloqueo, arranque de los 60 niveles, modo QA y partidas completas de bistró, mercado y alta cocina (plato + bebida/vino). |
| `Funcionalidades/Minijuego_Cocina/Tests/test_alineacion_arte_cocina.gd` | Tests de recorte/alineación del arte por capas (6 tests). |
| `Escenas/Herramientas/Captura_Mundos_Cocina.tscn` + `Scripts/Otro/Herramientas/Captura_Mundos_Cocina.gd` | Capturas de QA de los tres mundos nuevos: cocina preparada y modal de inicio con menú/mecánica; guarda en `user://capturas_mundos_cocina`. |
| `Escenas/Herramientas/Captura_Selector_Cocina.tscn` + `Scripts/Otro/Herramientas/Captura_Selector_Cocina.gd` | Herramienta de QA visual del selector (mundos, niveles y modal) en `SubViewport`; acepta `CAPTURA_ANCHO`/`CAPTURA_ALTO` y guarda en `/tmp/opencode/capturas_selector`. |
| `tools/generar_fondo_selector.py` | Regenera `Fondo_Restaurante_Selector.png` (360×640) desde el fondo de la cocina: recorte vertical, desenfoque, tinte azul y reducción. |

---

## 3. Reglas de Juego y Fórmulas

### Mundos de Cocina y Desbloqueo
Cada uno de los 4 trabajos de hostelería tiene su propio mundo, con 15 niveles y una mecánica distinta. Un mundo se desbloquea por **dos vías alternativas**: trabajar al menos 1 minuto en el puesto de hostelería asociado o **superar al menos 1 nivel del mundo anterior**. La segunda vía permite progresar dentro del minijuego sin esperar al turno.

| Mundo (`id`) | Trabajo requerido | Mecánica | Estado |
|---|---|---|---|
| `burger_street` (*Burger & Street Food*) | `Trabajar_En_Comida_Rapida` | Montaje de hamburguesas, plancha y freidora | Implementado (15 niveles, 11–31 clientes) |
| `bistro_tradicional` (*Bistró Tradicional*) | `Trabajar_De_Ayudante_Cocina` | **Punto del filete**: crudo → poco hecho → al punto → hecho → quemado | Implementado (15 niveles) |
| `cocina_mercado` (*Cocina de Mercado*) | `Trabajar_De_Cocinero_Partida` | **Guisos por lotes**: combinar ingredientes en la olla y servir 4 raciones | Implementado (15 niveles) |
| `alta_cocina` (*Alta Cocina Gourmet*) | `Trabajar_De_Chef_Ejecutivo` | **Precisión**: ventana dorada del horno, salsa que se quema si no se remueve y maridaje de vinos | Implementado (15 niveles) |

- **Modo prueba (QA):** `Sistema_Cocina.desbloqueo_total_qa = true` (valor actual) desbloquea los 4 mundos y los 60 niveles para probar todo el contenido sin depender de trabajos ni estrellas. El mapa muestra «MODO PRUEBA: todos los mundos abiertos». Los tests lo desactivan en sus setups para validar la progresión real. Ponerlo en `false` antes de publicar.

### Mecánicas de los mundos 2–4

- **Bistró Tradicional (`bistro_tradicional`)**
  - La parrilla cocina **filetes con punto**. La barra bajo cada filete muestra el tramo y la etiqueta superior indica `CRUDO`, `POCO HECHO`, `AL PUNTO`, `HECHO` o `QUEMADO`. Un filete crudo o quemado no se puede servir; el punto se elige retirándolo en el momento justo.
  - La freidora produce **patatas** como guarnición del pase (no se sirven sueltas).
  - El pase monta `proteína + punto + patatas + salsa`. Recetas: `filete_punto`, `filete_patatas`, `filete_completo`, `solomillo_jugoso` (poco hecho) y `entrecot_hecho`.
  - La cafetera sirve **café**; la vitrina de la despensa entrega **tarta de cereza** directamente al cliente (postre listo, sin pasar por el pase).
  - Despensa: filete crudo, patatas, salsa y tarta.
- **Cocina de Mercado (`cocina_mercado`)**
  - La **olla** admite ingredientes de la despensa (alubias, chorizo, tomate, pimiento, arroz, marisco). Dos ingredientes válidos forman un guiso: **fabada** (alubias + chorizo), **pisto** (tomate + pimiento) o **arroz del senyoret** (arroz + marisco). Una tanda rinde **4 raciones**; se sirven tocando la olla o arrastrando la ración al pase.
  - La **plancha** fríe huevos; el huevo se añade al pisto para `pisto_huevo`.
  - Recetas: `fabada`, `pisto`, `pisto_huevo`, `arroz_senyoret`; bebidas `agua` y `sangría`.
  - Despensa: alubias, chorizo, tomate, pimiento, arroz, marisco y huevo.
- **Alta Cocina Gourmet (`alta_cocina`)**
  - El **horno** tiene una **ventana dorada** estrecha (62–88 % del progreso). Antes de la ventana la proteína está cruda; después se considera pasada y hay que tirarla. La barra del slot dibuja la franja dorada y el marcador de progreso.
  - La **sartén de salsa** se quema si no se remueve. Tocar la sartén remueve y baja el medidor; arrastrarla al pase añade la reducción. Si llega al 100 % queda arruinada y hay que reiniciarla.
  - La **bodega** sirve copas de tinto o blanco. Cada plato tiene un `maridaje` y el cliente pide siempre la copa correcta; el ticket muestra plato + vino.
  - El pase monta `proteína + salsa + guarnición`; la **flor** es opcional y añade **+3 € de propina** al servir el plato.
  - Recetas: `solomillo_tinto`, `lubina_blanca` y `pato_tinto`; vinos `vino_tinto` y `vino_blanco`.
  - Despensa: solomillo, lubina, pato, puré, espárragos y flor.

### 5 Mejoras por Restaurante (Caja del restaurante, €)
- **`plancha`**: Nv.1 (`2` huecos, `1` cesta, `×1.00`) → Nv.2 (`120 €`, `3` huecos, `2` cestas, `×0.80`) → Nv.3 (`320 €`, `4` huecos, `2` cestas, `×0.65`).
- **`emplatado`**: Nv.1 (`2` platos, `1` bebida `4.0 s`) → Nv.2 (`100 €`, `3` platos, `2` bebidas `2.5 s`) → Nv.3 (`280 €`, `4` platos, `3` bebidas `1.0 s`).
- **`termostato`**: Nv.1 (`6.0 s`) → Nv.2 (`90 €`, `8.1 s`) → Nv.3 (`240 €`, `10.5 s` + aviso temprano al 45%).
- **`ingredientes`**: Nv.1 (`×1.00`) → Nv.2 (`140 €`, `×1.25`) → Nv.3 (`360 €`, `×1.50`).
- **`ambiente`**: Nv.1 (`×1.00` paciencia/propinas) → Nv.2 (`110 €`, `×1.15` / `×1.20`) → Nv.3 (`300 €`, `×1.30` / `×1.40`).

La **Caja** (`fondos_cocina`) es un monedero de euros separado de `Variables_Dinamicas.Dinero`:
- Ingresa `ventas − costes` al cerrar cada servicio.
- Paga las 5 mejoras (90–360 €).
- Las propinas no se quedan en la Caja: se reparten entre el Sim (50%) y el equipo (50%).

### Pantalla de Mejoras (`Mejoras_Cocina.gd`)

El botón **Mejoras** del mapa abre una pantalla propia a tamaño completo (tarjeta horizontal `1180×640` sobre `1280×720`), construida como componente independiente (`Scripts/GUI/Minijuego_Cocina/Mejoras_Cocina.gd`) y montada desde `Minijuego_Cocina._Construir_Modal_Mejoras()`.

- **Cabecera:** título dorado «MEJORAS DE COCINA», nombre del restaurante, píldora **CAJA DEL LOCAL** con el saldo real y botón circular de cierre. El velo de detrás se puede tocar para cerrar.
- **Columna izquierda:** las 5 mejoras en filas seleccionables con el icono de su **nivel actual**, nombre corto, tres estrellas, `Nv. X` y el coste del siguiente nivel (o `MÁX.` en verde). La fila activa lleva marco dorado; al llegar a Nv.3 aparece un check verde. Debajo, una tarjeta de **TU PROGRESO** (rango, estrellas totales y barra hacia el siguiente rango) y el recordatorio «La Caja del local paga las mejoras».
- **Escaparate derecho:** muestra la **siguiente versión** de la mejora (o la actual si ya está al máximo) con el arte grande, rayos y destellos del color de acento, sombra de contacto y movimiento de flotación suave. La píldora `SIGUIENTE MEJORA` / `TU MEJOR VERSIÓN` y las tres estrellas del nivel completan el marco.
- **Pestañas de nivel:** `Nv.1` / `Nv.2` / `Nv.3` con estado **INCLUIDO** (verde), **coste siguiente** (verde brillante) o **precio futuro** atenuado con candado. Al comprar, la pestaña correspondiente pasa a INCLUIDO y la siguiente muestra su precio.
- **Panel de rendimiento:** fondo crema con chips de los beneficios actuales (`AHORA · Nv. X`) y de lo que aporta la compra (`CON LA MEJORA · Nv. X`), más una frase editorial que invita a subir de nivel.
- **Compra:** CTA verde `MEJORAR A NV. X · coste`; si la Caja no llega, pasa a ámbar con `FALTAN X € · SIRVE MÁS CLIENTES` y sacude el botón al tocarlo. Nunca se descuenta el dinero personal del Sim. Al comprar se actualiza la Caja, suena `coin` (y `star` al llegar a Nv.3), se lanza el aviso `¡NIVEL X!` y se refresca el mapa.
- **Datos de presentación:** `MEJORAS_DEF` conserva costes y efectos y añade `nombre_corto`, `acento` y `niveles` (nombre, `beneficios`, `ganancias` y `frase`). Los helpers `Obtener_Info_Nivel_Mejora`, `Obtener_Nombre_Nivel_Mejora`, `Obtener_Beneficios_Nivel_Mejora`, `Obtener_Ganancias_Nivel_Mejora` y `Obtener_Frase_Nivel_Mejora` alimentan la pantalla sin duplicar textos.
- **Sprites:** 15 PNG nuevos (3 por mejora) en `Imagenes/Minijuego_Cocina/Mejoras/` (`<mejora>_nv1.png` … `_nv3.png`). Se cargan con `Arte_Cocina.TEXTURAS_MEJORAS` / `Arte_Cocina.textura_mejora(id, nivel)` y se generan desde las hojas maestras de `Arte_Fuente/Minijuego_Cocina/Mejoras/` con `python3 tools/procesar_mejoras_cocina.py`.
- **QA:** `godot --path . res://Escenas/Herramientas/Captura_Mejoras_Cocina.tscn` genera en `user://capturas_mejoras_cocina` una captura por mejora, el estado sin Caja, el nivel máximo y la compra recién realizada.


### Fórmulas Puras (`Sistema_Cocina`)
- **Cocción:** `max(0.5, base * mult_plancha * (1 - 0.15 * Destreza/100))`
- **Quemado:** `base_termostato * (1 + 0.15 * Paciencia/100) * (0.85 si Resacón)`
- **Velocidad de paciencia:** `(1 / mult_ambiente) * (1 - 0.10 * Paciencia/100 - 0.10 * SangreFria/100) * (1.20 si Descanso < 25 o SaludMental < 25)`
- **Drops por cliente:**
  - `Progreso_Cocina`: `0.15 * (2.0 si En Turno) * (7.0 si Modo Rápido)`
  - `Progreso[2]` (Manualidades): `0.05 * (7.0 si Modo Rápido)`
  - Necesidad (`Salud_Mental` o `Hambre`): `12%` de `+1` (respetando caps de calle/bancarrota/resacón/intoxicación)
  - Micro-propina: `10%` de `1–3 € * Multiplicador_Precios()` con tope `6 € * Multiplicador_Precios()` por servicio (`×0.25` en modo práctica).
- **Fin de nivel:** la partida se cierra cuando `clientes_pendientes == 0` y no queda ningún cliente activo ni animación de entrada/salida (`_Nivel_Completado()`). No hay límite de tiempo: el reloj del HUD solo cuenta lo que dura el servicio.
  - **Ticket** = ventas de platos/bebidas + propinas. Las propinas también suman para las estrellas (bonus de servicio).
  - **Ventas** = `ticket − propinas_servicio`.
  - **Costes** = `round(ventas * 0.30)` (ingredientes) + `6 € + 2 € * nivel` (servicio) + `round(valor_descartado * 0.30)` (merma).
  - **Beneficio neto** = `max(0, ventas − costes)`.
  - **Caja** += `beneficio_neto − reparto_sim`.
  - **Reparto al Sim** = `round(beneficio_neto * 0.05)` con paga completa; `25%` de esa cifra en modo práctica.
  - **Propinas netas** = `propinas_servicio * 0.50 * (1.5 si En Turno) * (1 + bonus_ropa_propinas) * Multiplicador_Precios() * (0.25 si práctica)`.
  - **Prima de estrellas** (solo al mejorar el récord del nivel, se paga al Sim): `suma(meta[s] * 0.10 por cada nueva estrella) * Multiplicador_Precios()`.
  - **Tirar comida** (plato, carne, patatas o bebida a la papelera) suma el valor de venta del descarte a la merma; se descuenta el 30% al cerrar el servicio.

**Paga completa y modo práctica:** fuera de turno, los 2 primeros servicios del día con ≥1 estrella pagan el 100% de propinas y reparto; a partir del tercero se aplica el modo práctica (25% para el Sim, la Caja sigue al 100%). En turno activo no hay límite, las propinas son ×1.5 y se marca `plus_nomina_turno_hoy` (+10% de nómina al terminar el turno). Un servicio de 0 estrellas no paga propinas ni reparto, pero la Caja conserva el beneficio neto. `Multiplicador_Precios()` (`×0.1` en Modo Rápido) solo escala el dinero personal, no los costes ni las mejoras de la Caja.

### Bloqueos de Entrada
No permite iniciar un servicio si:
1. `restaurantes_desbloqueados` está vacío.
2. `Necesidades_Basicas[3] <= 5` (Descanso crítico).
3. Hay un examen universitario (`Actividad_Examen`, P3) activo o a ≤ 5 minutos.

### Rangos de Maestría Culinaria (cada 20 estrellas) y Ropa Equipable
| Rango | Estrellas | Beneficio / Prenda |
|---|---|---|
| 1 | 20 ★ | `Delantal_Aprendiz` (`-5%` desgaste Higiene hostelería) |
| 2 | 40 ★ | `+2` extra Salud Mental al comer (`Comer_Tupper` / `Comer_Basura`) |
| 3 | 60 ★ | `Chaqueta_Chef` (`+10%` salario hostelería, `-5%` Higiene) |
| 4 | 80 ★ | `-20%` coste en `Comer_Basura` y `+15%` saciedad en `Comer_Tupper` |
| 5 | 100 ★ | `+15%` eficiencia en `Progreso[2]` (Manualidades) y `Progreso_Cocina` |
| 6 | 120 ★ | `Atuendo_Chef_Gala` (`+20%` salario hostelería, `-5%` Higiene) |
| 7 | 140 ★ | `+15%` velocidad recuperación Hambre y `+1` Salud Física al comer |
| 8 | 160 ★ | Inmunidad total al evento aleatorio `"Intoxicación alimentaria"` |
| 9 | 180 ★ | `Traje_Estrella_Michelin` (`+30%` salario hostelería, `-5%` Higiene, `+25%` propinas) |

Las estrellas se acumulan con la **mejor marca de cada nivel** (hasta 3 ★ por nivel). Los 4 mundos × 15 niveles × 3 ★ suman los 180 ★ del Rango 9. El selector de mundos muestra una tarjeta de **MAESTRÍA CULINARIA** con el rango actual, la barra `estrellas / siguiente umbral`, cuántas ★ faltan y la próxima recompensa; el botón `RANGO X/9 · N ★` de la cabecera (y `VER RANGOS`) abre el modal con el progreso y la lista completa de recompensas, marcando el rango actual y el siguiente. El mismo progreso se refleja en `Mejoras → TU PROGRESO`, en la tarjeta del **Vestuario** y en la ficha del minijuego.

Las prendas desbloqueadas se prueban y equipan en la sección **Vestuario** (barra superior, Inicio y Perfil → Info). Véase `Funcionalidades/Vestuario/Documentacion/VESTUARIO.md`.

---

## 4. Presentación y Animaciones

### 4.0 Orientación y pantalla de carga

- **Todo el minijuego se abre en horizontal `1280×720`**, incluido el selector de mundos, el mapa de niveles y la pantalla de Mejoras. Al instanciarse llama a `_Aplicar_Orientacion_Horizontal()` y fija `content_scale_size` a `1280×720`; al salir (`_Salir_Al_Sim`, `_exit_tree`) restaura la vertical `720×1280`.
- La comprobación de plataforma usa `DisplayServer.get_name().to_lower()`: en Android el nombre real es `Android` (con mayúscula) y la comparación anterior contra `"android"` impedía que se aplicara la rotación en el APK.
- El **selector de mundos** ocupa la vista completa: barra superior de dos filas (mundo/rango y Caja/dinero/Mejoras) y panel cartoon con las **4 tarjetas de mundo en cuadrícula 2×2**, la chef como reclamo y la **tarjeta de Maestría** (rango, estrellas, barra y próxima recompensa) a la derecha. El mapa de 15 niveles es una vista aparte que sustituye a la lista al entrar en un mundo.
- Al pulsar **«¡Empezar Servicio!»** aparece `Vista_Carga` (ya sin giro, porque el minijuego entero está en horizontal): barra de progreso animada (~2 s), porcentaje, pasos («Calentando la plancha…», «Picando los ingredientes…», «Preparando las mesas…», «¡Abriendo el restaurante!») y botón **Cancelar** que vuelve al mapa.
- Al completar la barra arranca la cocina. El botón **MENÚ** del HUD (con «Al mapa» y confirmación si hay partida en curso, ver 4.0.2), el **Mapa** del modal de resultados y **ATRÁS** del panel vuelven al selector horizontal.
- `_Centrar_Contenido()` da al mapa el viewport completo y centra cocina/carga; el panel, el `Grid_Niveles` (envuelto en `Centro_Niveles`) y la botonera se recolocan con `_Ajustar_Disposicion_Mapa()` tras un cambio de resolución. El panel tiene un ancho máximo de `1240` para no deformarse en pantallas muy alargadas.

### 4.0.1 Navegación entre el selector de mundos y el mapa de niveles

- El mapa horizontal usa un **único panel cartoon celeste** dibujado por `Selector_Niveles_Arte.Marco_Mapa`: marco turquesa con brillo, tablero azul embutido, título dorado con contorno azul marino (`Titulo_Dorado`), botón **ATRÁS** en la esquina inferior izquierda y botón circular verde en la inferior derecha. El fondo es una foto desenfocada del restaurante (`Fondo_Restaurante_Selector.png`).
- Al abrir el mapa **solo se muestran los 4 mundos** en una `GridContainer` de 2 columnas: `_restaurante_expandido` empieza vacía, `_lista_restaurantes` está visible y `_contenedor_niveles` permanece oculta. Cada mundo es una tarjeta crema con borde dorado, **miniatura de su fondo**, nombre, progreso `X/45 ★` y una píldora de estado si corresponde; la chef Michelle y la tarjeta `Panel_Maestria_Mapa` ocupan la franja derecha del tablero.
- Al tocar un mundo jugable se asigna su `id` a `_restaurante_expandido`, se oculta la lista y se construye en `Grid_Niveles` (5 columnas × 3 filas) un tablero con los **15 niveles visibles de una vez**: placa verde con marco dorado, número central, tres estrellas superpuestas y candado en los niveles bloqueados. Las monedas se revelan con una animación escalonada (`_Animar_Revelado_Niveles()`).
- El panel de niveles incluye una **barra de desplazamiento** dibujada a la izquierda (`Barra_Scroll_Niveles`) y un pie con `X / 45 ★ · Y / 15 niveles`; el botón verde derecho abre el **siguiente nivel pendiente** (`_Abrir_Siguiente_Nivel()`).
- La barra superior reúne el mundo activo, el botón de **rango/estrellas** (abre el detalle de Maestría), la **Caja**, el **dinero del Sim**, la píldora **EN TURNO** y el botón **Mejoras** (dorado). Este último permanece **deshabilitado** mientras no haya un mundo abierto, desbloqueado e implementado (`_btn_mapa_mejoras.disabled = not rest_jugable`).
- **ATRÁS** llama a `_Volver_Mapa()`: dentro de un mundo regresa al selector sin cerrar el minijuego; en el selector sale al Sim. La misma cascada se usa con el botón atrás físico/Escape (ver 4.0.2).
- Los mundos bloqueados aparecen como **botones deshabilitados** (`btn.disabled = true`), con miniatura desaturada, fondo azul grisáceo, el trabajo asociado en el subtítulo y la píldora **BLOQUEADO**. Se desbloquean al trabajar 1 minuto en su puesto de hostelería o al superar 1 nivel del mundo anterior. No se pueden abrir ni iniciar partida hasta entonces.

### 4.0.2 Modales cartoon, pausa y confirmación de salida

- Los cuatro modales del minijuego (`Modal_Pausa`, `Modal_Confirmar_Salida`, `Modal_Inicio_Nivel` y `Modal_Resultados`) se montan con `Minijuego_Cocina._Crear_Modal_Base()`, que devuelve el modal, la tarjeta y el `VBoxContainer` de contenido: velo azul noche (`Color(0.02, 0.07, 0.16, 0.78)`) y tarjeta centrada de ancho fijo (560 px pausa, 590 px salida, 780 px resultados, 900 px ficha) dibujada por `Arte_Modal_Cocina.Marco_Modal`. Al abrirse, `_Animar_Entrada_Modal()` hace un fundido de 0,16 s y un pop de la tarjeta de `0,93` a `1,00` con `TRANS_BACK` en 0,30 s.
- El estilo es cartoon de juego casual y sustituye a las tarjetas planas de aspecto web: canto azul oscuro, cara celeste con degradado, brillo de cristal y destellos; título `Titulo_Modal` (Titan One dorado con degradado por shader y contorno azul marino); placas hundidas `caja_placa()`, píldoras doradas `caja_pildora_oro()`, píldoras crema para los platos y botones `Boton_Modal` con texturas 9-patch glossy `Boton_Modal_{Azul,Verde,Naranja,Rojo}.png` (generadas por `tools/generar_botones_modal.py`). Los textos y helpers (`crear_titulo`, `crear_boton`, `texto_modal`, `texto_cartoon`, `icono_usuarios`, `icono_estrella`, `divisor`) viven en `Arte_Modal_Cocina.gd`.
- El botón **MENÚ** del HUD horizontal (sustituye a los antiguos botones «Mapa» y «Pausa») llama a `_Abrir_Modal_Pausa()` y congela la partida. `_Intentar_Volver_Al_Mapa()` sigue existiendo para el botón atrás y las pruebas: sin partida activa va al mapa y con `_jugando` o `_pausado_por_confirmacion` abre `Modal_Confirmar_Salida`.
- `Modal_Pausa` es un panel cartoon azul (`Arte_Modal_Cocina.Marco_Modal`) con título dorado **«PAUSA»**, subtítulo, una placa hundida con el resumen **«NIVEL N · TICKET X € · META M €»** y **«QUEDAN N CLIENTES»**, y tres botones glossy apilados: **SEGUIR COCINANDO** (`_Reanudar_Partida()`, verde), **REPETIR NIVEL** (`_Repetir_Desde_Pausa()`, naranja) y **AL MAPA** (`_Salir_Desde_Pausa()`, azul, encadena la confirmación de salida).
- `Modal_Confirmar_Salida` reutiliza el mismo marco azul, título **«¿SALIR AL MAPA?»**, el aviso de que se perderán las ventas, las estrellas y la Caja, el resumen **«TICKET ACTUAL X € · N CLIENTES ATENDIDOS»** en una placa hundida y dos botones glossy: **SEGUIR COCINANDO** (verde) y **SALIR Y PERDER PROGRESO** (rojo).
- Al abrir el modal de pausa o el de confirmación de salida, la partida queda **pausada**: `_pausado_por_confirmacion = true`, `_jugando = false` (el `_process` de cocina sale de inmediato y se detienen reloj, clientes y cocción), se cancela el arrastre en curso y se deshabilita `_arrastre`.
- **«Seguir cocinando»** cierra el modal, reactiva `_jugando` y vuelve a habilitar el arrastre registrando las zonas (`_Registrar_Zonas_Arrastre()`). **«Salir y perder progreso»** cierra el modal y llama a `_Mostrar_Mapa()` **sin pasar por `Sistema_Cocina.Procesar_Fin_Nivel()`**: no se otorgan estrellas, propinas, Caja ni guardado del nivel.
- La ficha de inicio (`Modal_Inicio_Nivel`) y el modal de resultados (`Modal_Resultados`) usan el mismo lenguaje visual. La ficha muestra la píldora dorada **«N CLIENTES»** con el icono `users`, tres placas hundidas con estrella y meta (`META 1/2/3`), píldoras crema por plato del menú con el icono compuesto de `Arte_Cocina.Icono_Item`, la explicación de la mecánica del mundo y los modificadores del Sim, y los botones **CANCELAR** (azul) / **¡EMPEZAR SERVICIO!** (verde). Los resultados muestran el título `¡SERVICIO SUPERADO!` / `SERVICIO INCOMPLETO`, tres estrellas del pack con pop escalonado, filas `_Agregar_Fila_Resultado()` con etiqueta crema y valor dorado, y los botones **MAPA** (azul), **REPETIR** (naranja) y **SIGUIENTE NIVEL** (verde).
- El **Mapa del modal de resultados** sigue yendo directo al mapa, porque el nivel ya terminó y las recompensas ya se procesaron.
- **Botón atrás físico/Android y `Escape`:** `_notification(NOTIFICATION_WM_GO_BACK_REQUEST)` y `_unhandled_input("ui_cancel")` llaman a `_Volver_Atras()`, que resuelve en cascada: reanuda si el modal de pausa está abierto, cierra el modal de salida (equivale a seguir cocinando), abre la confirmación si hay partida, cancela la carga pendiente, cierra los modales de inicio/mejoras/resultados y, ya en el mapa, si hay un mundo abierto vuelve al selector de mundos y, si no, sale al Sim. Así Android no cierra la app de golpe.
- **«Quit On Go Back» desactivado mientras dura el minijuego:** `_ready()` guarda el valor previo de `SceneTree.is_quit_on_go_back()` en `_quit_on_go_back_previo` y llama a `get_tree().set_quit_on_go_back(false)`; `_exit_tree()` restaura el valor guardado. De este modo, aunque el proyecto tenga «Quit On Go Back» activado por defecto, el botón atrás de Android llega al minijuego como `NOTIFICATION_WM_GO_BACK_REQUEST` en lugar de cerrar la aplicación.
- Capturas: `Documentacion/Capturas/13b_modal_pausa.png` (pausa), `13_confirmar_salida.png` (salida), `01c_modal_nivel.png` (ficha de nivel), `05_resultados.png` (resultados) y `22_modal_mercado.png` (ficha de Mercado). La herramienta `Captura_Minijuego_Cocina.gd` genera esas cuatro vistas en `user://capturas_minijuego_cocina` como `modal_pausa.png`, `modal_confirmar_salida.png`, `modal_nivel.png` y `modal_resultados.png`.

### 4.0.3 Transición entre el juego principal y el minijuego

- La entrada y la salida ya no son instantáneas: `Scripts/GUI/Transiciones/Transicion_Minijuego.gd` crea un `CanvasLayer` (`layer = 120`) con un **telón de cocina** que sube desde el borde inferior, cubre la pantalla y continúa subiendo hasta salir por arriba para descubrir la vista nueva.
- **Entrada:** `Script_Principal._Abrir_Minijuego_Cocina()` valida el acceso, crea el telón y espera a `Cubrir("Cocina", "Preparando los fogones…")`. Con la pantalla cubierta instancia el minijuego (`_Instanciar_Minijuego_Cocina()`), deja `0,12 s` de margen y llama a `Descubrir("¡A cocinar!")`.
- **Salida:** al emitirse `cerrado`, `Script_Principal._on_minijuego_cocina_cerrado()` espera a `Cubrir("Volviendo al Sim", "Recogiendo la cocina…")`, libera la capa del minijuego, ejecuta `_Refrescar_Tras_Minijuego_Cocina()` y descubre la escena principal con `Descubrir("¡De vuelta a casa!")`.
- **Composición del telón:** fondo `#0b1220` (el mismo del mapa de la cocina), borde superior naranja `#ea580c`, esquinas inferiores redondeadas, 16 rayos cálidos girando lentamente, el chef `Chef_Pulgar_Arriba.png` con balanceo, título, subtítulo ámbar y tres puntos rebotando.
- **Tiempos:** `0,34 s` para cubrir, `0,12 s` de espera mientras se prepara la siguiente vista y `0,40 s` para descubrir. La música hace su fundido cruzado de `0,9 s` debajo del telón.
- **Bloqueo de entrada:** el telón usa `MOUSE_FILTER_STOP`, por lo que no se puede pulsar nada mientras dura la animación. La bandera `_transicion_minijuego_activa` impide aperturas o cierres duplicados y el telón se libera solo al terminar `Descubrir()`.

### 4.1 Escenario y reparto
- **Fondo:** `Fondo_Restaurante.png` a 1280×720 con el diner completo y la encimera de acero en primer plano.
- **Clientes:** 4 puestos en las mesas/booths del fondo. Cada puesto tiene un retrato (190×170) y un **bocadillo de pedido** (160×134) sobre la cabeza.
- **Mostrador (y ≈ 430–616):** plancha (hasta 4 fogones), freidora (hasta 2 cestas), dispensador de refrescos (hasta 3 vasos), bandeja de emplatado (hasta 4 platos), papelera y bote de propinas.
- **Bandeja de emplatado:** el pase es un puesto 3D: una **bandeja metálica** renderizada (`Bandeja_Metal.png`) con borde, paredes interiores y sombra de contacto, una alfombrilla beige hundida y, detrás, una **mampara de cristal** con marco cromado, filo verde y reflejos (`Fondo_Pase`). Al empezar solo se abren dos de los **cuatro huecos**; la mejora `emplatado` abre el tercero en Nv.2 y el cuarto en Nv.3. Los cerrados son rebajes metálicos oscuros con un **candado dorado** y una pastilla `Nv.2`/`Nv.3`, de modo que la progresión se ve sin abrir la pantalla de Mejoras. La fila mantiene el mismo eje vertical y cada plato se escala al hueco. Cada hueco activo contiene un **plato de cerámica 3/4** (`Plato_Perspectiva.png`) con filo celeste grueso y sombra de contacto; los platos vacíos muestran un **fantasma de pan cerrado** y un botón «+» centrado en el propio pan para indicar dónde colocar el pan.
- **Mueble bajo la encimera con los ingredientes (y ≈ 620–716):** frente de armario teal con zócalo de acero y estante de madera, como la despensa de la cocina de referencia. No hay tarjetas ni botonera: cada alimento tiene su recipiente y su placa grabada. La **panera de madera** ocupa el centro bajo el pase y tiene **dos huecos** con panecillos; a la izquierda quedan la bandeja metálica de carne cruda y la cesta roja de patatas; a la derecha, el bol de lechuga, la bandeja de tomate y la tabla de queso. El hueco libre se rellena con pilas de platos y bandejas apiladas. Al pasar el ratón/dedo el recipiente se ilumina con un halo cálido y la pieza se levanta ligeramente; el nombre va en una placa pequeña en el estante, no en una tarjeta. Tocar un recipiente ejecuta su acción principal (carne → plancha, patatas → freidora, pan → siguiente plato libre, topping → plato con pan) y arrastrar sigue disponible para colocar la carne cocinada en el pan o servir.
- **Chef:** cut-in en la zona izquierda, por delante del fondo y por detrás de la barra; reacciona con 7 poses.
- **Banner de la tarjeta «Cocina» (`Pantalla_Minijuegos`):** la tarjeta usa un fondo propio, `Imagenes/Minijuego_Cocina/Banner_Cocina.png` (1288×284, ≈4,5:1): mostrador de diner en primer plano con damero crema/negro, borde metálico inferior y comedor desenfocado detrás; el desenfoque, la viñeta y la luz cálida van horneados en el PNG. Sobre él se compone en 3/4 el chef (104×142), la hamburguesa (104×104), el plato (124×58), las patatas (90×96), el refresco (62×112) y la plancha (146×100); los cinco objetos apoyados en el mostrador llevan una **sombra elíptica de contacto** (5 en total). En el banner, el plato ya no es el `Plato_Vacio.png` cenital: se usa `Emplatado/Plato_Perspectiva.png` (640×297), cerámica blanca en perspectiva con ala, hueco y brillos. Código: `Arte_Cocina.TEX_BANNER`, `TEX_PLATO_PERSPECTIVA` y `textura_sombra_contacto()` (degradado radial cacheado); `Script_Principal._Actualizar_Pantalla_Minijuegos()` y los helpers `_Anadir_Item_Banner()` / `_Anadir_Sombra_Banner()`. Es un cambio solo visual: la suite del minijuego sigue en **45/45 tests**.

### 4.2 Estados y animaciones de los clientes
Cada cliente pasa por `inactivo → entrando → esperando → saliendo`:

| Fase | Animación |
|---|---|
| `entrando` | **Camina desde el borde izquierdo de la pantalla** hasta su mesa con ciclo de paso (rebote, balanceo, micro-squash y sombra en el suelo). Al llegar, aparece el pedido con rebote y saluda con la cabeza y la burbuja «¡Hola!». La paciencia no baja durante el paseo. |
| `esperando` | Balanceo suave, respiración, mirada que se desplaza y el bocadillo se ladea/tambalea conforme baja la paciencia. |
| Paciencia < 50% | La cara cambia a la versión enfadada (<45%), el corazón de la barra pasa a ámbar y aparece «¿Cuánto falta?». |
| Paciencia < 25% | El bocadillo se tiñe de rojo, vibra, emite nubes de enfado y aparece «¡Tengo prisa!». |
| Servido (`feliz`) | Rebote + masticación (squash 3 veces), «¡Gracias!», estrellas y monedas; después **camina hacia el borde derecho** y sale de la pantalla. El ticket se queda en la mesa y se desvanece. |
| Paciencia agotada (`enfadado`) | «¡Me voy!», nubes de enfado, temblor y sacudida de pantalla; después **camina hacia el borde derecho** con paso más marcado. |

El puesto queda bloqueado hasta que termina la caminata de salida para que no se solapen dos clientes. La entrada/salida se hace a velocidad constante (~620 px/s de entrada, ~450 px/s de salida) y el cliente se dibuja por delante de los demás retratos mientras camina.

Cada nivel reparte un número **finito** de clientes (`clientes` en la configuración: 11 en el nivel 1 y 31 en el 15). `_Intentar_Spawnear_Cliente()` descuenta uno de la cola al sentarse y el servicio se cierra en cuanto la cola y las mesas quedan vacías (`_Nivel_Completado()`); los clientes que se marchan enfadados también consumen su turno. El HUD muestra los que faltan en la píldora azul de clientes (solo el número, con insignia verde de comensales).

### 4.3 Chef
Poses usadas: `sirviendo` (inicio/nivel), `pulgar` (servicio rápido), `celebra` (combo), `sorprendida` (comida a punto de quemarse) y `enfadada` (comida quemada / cliente perdido). Entra desde la izquierda con rebote, burbuja de texto y se retira solo.

### 4.4 Estaciones y comida
- **Carne:** crossfade cruda → hecha → quemada, anillo de progreso, vapor, chispas, humo y **voltereta** de 0,3 s al quedar lista (con etiqueta «¡LISTO!»).
- **Patatas:** cesta con aceite, burbujas, vapor y anillo; se sirven arrastrando al cliente.
- **Refrescos:** llenado animado por recorte de la textura, chorro, burbujas y anillo de «pop» al completarse.
- **Pan cerrado:** `Arte_Cocina.dibujar_pan_cerrado()` compone el panecillo con el canto inferior de `Pan_Inferior.png` (recorte `REGION_PAN_CERRADO`, sin la cara de miga) y la tapa de `Pan_Superior.png`, con sombra de contacto y sombra de unión. Se usa en el pase cuando el plato solo lleva pan, en el fantasma del plato vacío y en la panera. Para hamburguesas montadas se mantiene `dibujar_hamburguesa()` con todas las capas.

- **Platos:** el pase tiene una bandeja metálica 3D con alfombrilla beige y una mampara de cristal detrás; los cuatro huecos se dibujan siempre y los que aún no se han desbloqueado llevan candado y su nivel de mejora. Cada plato activo es una pieza de cerámica blanca en perspectiva 3/4 (`Plato_Perspectiva.png`) con filo celeste y sombra de contacto. La hamburguesa se compone por capas reales (pan, carne, queso, lechuga, tomate) con pop al añadir cada ingrediente; el pan solo se dibuja cerrado. Cada capa tiene ancho, alto y solape normalizados sobre un eje vertical común (`Arte_Cocina._capas_hamburguesa`), de modo que la pila queda compacta y proporcionada en cualquier tamaño de hueco. Un plato vacío muestra el fantasma del pan cerrado y un «+» centrado en él; cuando coincide con un pedido se marca con anillo verde, halo pulsante y check, y al servir vuela hasta el cliente.
- **Platos de los mundos 2–4:** `Plato` incorpora los campos genéricos `restaurante`, `proteina`, `punto`, `guiso`, `guarnicion`, `salsa`, `extra` y `flor`. `dibujar_plato_bistro()` compone filete con hueso en T, patatas y salsa; `dibujar_plato_mercado()` dibuja un cuenco de cerámica con guiso, tropezones y huevo; `dibujar_plato_alta()` monta medallón, puntos de salsa, puré/espárragos y flor. Los tickets usan variantes de icono más grandes (`dibujar_icono_bistro`, `dibujar_icono_alta`) para que la receta se lea a 31–48 px.
- **Fondos por restaurante:** `Arte_Cocina.fondo_restaurante(id)` resuelve `Imagenes/Minijuego_Cocina/Fondo_Restaurante.png` (burger) y los tres PNG de `Imagenes/Minijuego_Cocina/Fondos/` (`Fondo_Bistro.png`, `Fondo_Mercado.png`, `Fondo_Alta_Cocina.png`, 1280×720). El mismo fondo se usa en la cocina, la pantalla de carga y la miniatura de la tarjeta de mundo. Los maestros 16:9 están en `Arte_Fuente/Minijuego_Cocina/Fondos/`.
- **Estaciones dibujadas:** `Estacion_Olla` (olla de cobre con borde, asas, guiso, ingredientes y raciones), `Sarten_Salsa` (sartén con medidor de quemado), `Estacion_Horno` (horno de acero con cristal, bandeja y mandos) y `Estacion_Botellas` (estante de barra/bodega con botellas y copas). Se montan en `_Construir_Mostrador()` y `_Actualizar_Estaciones_Mundo()` decide cuáles se ven según `PERFILES_RESTAURANTE`. La cafetera y la freidora reutilizan los PNG `Estaciones/Cafetera.png` y `Estaciones/Freidora.png`.
- **Papelera:** humo y rebote de la tapa al descartar.
- **Bote de propinas:** rebote y monedas volando hacia él.

### 4.5 HUD y feedback
- **HUD superior clonado de la referencia:** botón azul **MENÚ** (icono `menu.svg`) que abre el modal de pausa con «Seguir cocinando», «Repetir» y «Al mapa»; píldora azul de **clientes restantes** con insignia verde de comensales (`users`) y el número en grande; y **contador de dinero** con moneda dorada grande, importe en amarillo y barra de meta con las 3 estrellas. El resto de la barra (nivel, reloj de servicio, propinas y hora del Sim) mantiene el estilo propio del minijuego.
- Reloj de servicio con el **tiempo transcurrido** (cuenta hacia arriba) y contador de clientes que faltan por llegar o atender (solo el número, como en la referencia).
- Barra de recaudación con 3 estrellas troqueladas; al ganar una estrella, la estrella hace pop y sale una lluvia de estrellas.
- Combo con píldora roja, pulso y **barra de tiempo restante**.
- Monedas que vuelan del cliente al HUD y al bote de propinas.
- Sacudida de pantalla al quemar comida o al perder un cliente.
- Modal de resultados cartoon con estrellas PNG animadas y la misma entrada de fundido + pop que el resto de modales (`_Animar_Entrada_Modal()`).

### 4.6 Tutorial contextual (nivel 1)
En la primera partida, antes de superar el nivel 1, aparece una barra de tutorial que cambia según el estado real de la cocina:
- «Toca el PAN para ponerlo en el plato».
- «Toca la CARNE para cocinarla».
- «Espera a que la carne esté lista» / «Arrastra la carne al pan».
- «Sirve el plato al cliente».
- «Arrastra el REFRESCO / las PATATAS al cliente».
- «Tira lo quemado a la BASURA» / «Nadie pide ese plato: tíralo a la BASURA».

El origen y el destino de cada paso se marcan con un **halo cálido pulsante y dos destellos**, sin marcos ni cuadros amarillos. El tutorial no bloquea la interacción y desaparece en cuanto se supera el nivel 1.

### 4.7 Arrastrar y soltar + toque rápido
- **Orígenes:** puestos de ingredientes del mueble bajo la encimera, fogones con carne lista/quemada, cestas con patatas, vasos llenos y platos con contenido.
- **Destinos:** plancha, freidora, platos, clientes y papelera. El cliente acepta el pedido tanto si se suelta sobre **su personaje** como sobre **su bocadillo de pedido** (ambas zonas comparten la misma validación).
- **Toque rápido:** tocar un puesto de ingrediente ejecuta su acción principal sin arrastrar: la carne va a la plancha, las patatas a la freidora, el pan al siguiente plato libre y el queso/lechuga/tomate al primer plato con pan que no los tenga. Un pequeño vuelo del ingrediente hasta la estación confirma la acción. La carne cocinada sigue necesitando arrastrarse hasta el pan (o tocarse en la plancha para pasarla al plato, como atajo).
- El fantasma sigue al dedo con sombra, inclinación por velocidad y escala 1,10; el destino válido se resalta en **cian** y el inválido en rojo.
- Si el objeto no se puede coger (carne aún cruda, plato vacío, vaso llenándose), se muestra un aviso y no se inicia el arrastre.
- Al soltar: se aplica la acción, se reproduce el SFX correspondiente y el objeto vuela si va al cliente.

---

## 5. Sonido y Música

- **Música:** el autoload `Musica` reproduce `Seven_Minutes_to_Service.mp3` al abrir el minijuego (`Musica.Reproducir_Minijuego()`) y restaura la música general al salir.
- **SFX:** `Sonidos_Cocina.gd` precarga los 15 WAV de `Sonidos/SFX/` (sintetizados para el proyecto, sin samples externos) y los reproduce con un pool de 12 voces.
- Eventos: click al levantar, pop al colocar, sizzle al cocinar, ding al estar listo, burn al quemarse, coin al servir, happy/angry en las reacciones, trash al descartar, pour al llenar el vaso, star al ganar estrella, combo al encadenar, start y level_end.
- Todos los SFX usan el bus `SFX` de `Ajustes`, independiente del silencio de la música.

---

## 6. Tests GUT

Ejecución de la suite del minijuego:
```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://Funcionalidades/Minijuego_Cocina/Tests -gexit
```
Suite completa de no regresión:
```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://Funcionalidades -ginclude_subdirs -gexit
```

Cobertura:
- 15 tests de economía, fórmulas, desbloqueo, logros, ropa, UI, pausa y fin de nivel por clientes. `test_10_selector_restaurantes_y_confirmacion_salida` comprueba que el mapa abre sin `Grid_Niveles`, que tocar `Burger & Street Food` revela sus 15 niveles en el marco cartoon con barra lateral y monedas numeradas, que la flecha verde abre el siguiente nivel pendiente, que volver al mapa en plena partida abre `Modal_Confirmar_Salida` y pausa `_jugando`, que «Seguir cocinando» reanuda y que «Salir y perder progreso» vuelve al mapa sin guardar estrellas.
- 11 tests de arrastre y toque rápido: gesto real desde la bandeja, flujo carne→plancha→plato→cliente, rechazo de queso sin pan / cliente equivocado, papelera, bebida, servicio soltando sobre el bocadillo, toques rápidos y pase de cuatro huecos (2 abiertos con Nv.1, 4 con Nv.3).
- 1 test de determinismo de la secuencia de pedidos entre dos partidas.
- 6 tests de arte y alineación: regiones de contenido sin margen transparente, iconos de la bandeja con la misma línea de base y centro, pan de la bandeja = pan superior, pila de hamburguesa compacta y proporcional, orden de capas con panes iguales e inversa `ancho_para_alto`.
- Resultado actual: **45 tests** en la suite del minijuego (15 de minijuego/UI + 11 de arrastre y toque rápido + 6 de alineación + 1 de pedidos + 12 de los mundos 2–4), todos en verde también en headless (incluye el flujo horizontal del selector/mapa → carga → partida → vuelta al mapa, la restauración de la vertical al salir, la confirmación de salida, la pausa, el HUD superior, la compra de mejoras con la Caja y el pase de cuatro huecos con candados).

---

## 7. Capturas

En `Funcionalidades/Minijuego_Cocina/Documentacion/Capturas/`:

| Archivo | Contenido |
|---|---|
| `01b_selector_mundos.png` | Pantalla inicial del minijuego con el panel cartoon celeste: las 4 tarjetas de mundo con su miniatura de fondo (las bloqueadas, desaturadas y con píldora **BLOQUEADO**), la chef decorativa, la tarjeta de **Maestría** con rango/estrellas/próxima recompensa y el botón **ATRÁS**; los niveles no se muestran hasta entrar. |
| `01_mapa_niveles.png` | Mapa de niveles de `Burger & Street Food` en horizontal `1280×720`: título dorado «SELECCIONA UN NIVEL», monedas verdes de 1–15 en cuadrícula 5×3 con sus tres estrellas, candados, barra de desplazamiento, pie de progreso y botones **ATRÁS**/siguiente. |
| `01c_modal_nivel.png` | Ficha de inicio de nivel cartoon: panel azul con degradado y brillo, título dorado con contorno azul marino, píldora dorada de clientes, placas de estrellas, píldoras crema para los platos, modificadores del Sim y botones glossy **CANCELAR** / **¡EMPEZAR SERVICIO!**. |
| `02_arrastrar_ingrediente.png` | Arrastre de un tomate a un plato con el destino resaltado. |
| `03_clientes_combo.png` | Dos clientes servidos, combo x2, monedas y reacción del chef. |
| `04_coccion_plancha.png` | Plancha con carne lista, carne quemándose y avisos. |
| `05_resultados.png` | Modal de resultados cartoon con 3 estrellas, título dorado y desglose de ventas, costes, Caja y dinero personal sobre panel azul. |
| `06_mejoras.png` | Pantalla de Mejoras rediseñada: lista de mejoras con estrellas a la izquierda y escaparate grande de la plancha (Nv.2) a la derecha, con pestañas de nivel, comparativa «AHORA / CON LA MEJORA» y CTA verde. |
| `06b_mejoras_maximo.png` | Misma pantalla con la plancha en Nv.3: check verde en la lista, escaparate con las cuatro hamburguesas, pestañas INCLUIDO y CTA «NIVEL MÁXIMO». |
| `06c_mejoras_compra.png` | Aviso «¡NIVEL 2!» tras comprar el jukebox del Ambiente del Local; la Caja baja de 900 € a 790 € y la siguiente pestaña muestra 300 €. |
| `06d_mejoras_sin_caja.png` | Estado con 40 € en Caja: CTA ámbar «FALTAN 80 € · SIRVE MÁS CLIENTES» y la compra deshabilitada por saldo. |
| `06e_mejoras_ingredientes.png` | Escaparate de Calidad de Ingredientes (Nv.2) con acento verde, bandeja de acero y chips de precio +25%. |
| `06f_mejoras_emplatado.png` | Escaparate de Emplatado y Bebidas (Nv.2) con la bandeja de acero, **3 platos y 2 refrescos**, coherente con los 3 platos / 2 vasos del sistema. |
| `07_tutorial.png` | Tutorial contextual del nivel 1 con anillos dorados sobre origen y destino. |
| `08_clientes_caminando.png` | Cliente cruzando la pantalla caminando desde la izquierda antes de sentarse. |
| `09_pantalla_carga.png` | Transición a horizontal con la barra de progreso, el chef, el nivel y el botón Cancelar. |
| `11_emplatado_bandeja.png` | Pase de nivel 1 con la bandeja metálica 3D, la mampara de cristal, dos platos en perspectiva y dos huecos cerrados con candado `Nv.2`/`Nv.3`. |
| `12_emplatado_detalle.png` | Detalle ampliado del pase con Emplatado Nv.3: bandeja metálica, alfombrilla beige, mampara de cristal y cuatro platos en perspectiva con panecillos cerrados. |
| `13_confirmar_salida.png` | Modal cartoon **«¿SALIR AL MAPA?»** durante una partida: aviso de pérdida de progreso, ticket y clientes atendidos en placa hundida y botones glossy **SEGUIR COCINANDO** / **SALIR Y PERDER PROGRESO**. |
| `13b_modal_pausa.png` | Menú **PAUSA** cartoon: título dorado, resumen del servicio, clientes restantes y botones glossy **SEGUIR COCINANDO** / **REPETIR NIVEL** / **AL MAPA**. |
| `14_banner_cocina.png` | Banner de la tarjeta «Cocina» en `Pantalla_Minijuegos` (render 2×): mostrador de diner con damero, chef, hamburguesa, plato vacío en perspectiva, patatas, refresco y plancha, todos con sombra de contacto. |
| `15_despensa_y_hud.png` | Cocina del nivel 1 con el mueble bajo la encimera (panera de dos huecos con panecillos cerrados, bandeja de carne, cesta de patatas, bol de lechuga, bandeja de tomate y tabla de queso), el pase 3D con bandeja metálica, mampara de cristal, cuatro huecos y candados, y el HUD superior clonado de la referencia (MENÚ, píldora de clientes y dinero). |
| `16_toque_rapido.png` | Flujo de toque rápido: dos carnes en la plancha, panes en los platos, una hamburguesa completa montada y un panecillo en el segundo plato. |
| `17_mundo_bistro.png` | Cocina del **Bistró Tradicional**: fondo francés, parrilla con punto, freidora, cafetera, pase con filete y patatas, y despensa de filete/patatas/salsa/tarta. |
| `18_mundo_mercado.png` | Cocina de **Mercado**: olla de cobre con guiso y 4 raciones, plancha de huevos, barra de agua/sangría, pase con pisto y despensa de ingredientes. |
| `19_mundo_alta_cocina.png` | Cocina de **Alta Cocina**: horno de precisión, sartén de salsa con medidor de quemado, bodega de tintos/blancos, pase gourmet y despensa de solomillo/lubina/pato/puré/espárragos/flor. |
| `20_selector_bistro.png` | Mapa de niveles del Bistró sobre su fondo, con el nivel 1 desbloqueado y los 14 siguientes con candado. |
| `21_mejoras_alta_cocina.png` | Pantalla de Mejoras de Alta Cocina con los nombres adaptados («Horno y Sartén», «Pase y Bodega», «Precisión»…). |
| `22_modal_mercado.png` | Ficha de inicio del nivel de Mercado con el mismo panel cartoon azul, título dorado y píldoras crema: menú de guisos y explicación de la mecánica de lotes. |
| `23_modal_bistro.png` | Ficha de inicio del nivel del Bistró: menú de filete al punto y café, píldoras de metas y botones glossy. |
| `24_mejoras_bistro.png` | Pantalla de Mejoras del Bistró con las cinco mejoras propias (Parrilla y Freidora, Pase y Cafetera, Punto de la Carne, Género Seleccionado y Ambiente del Bistró) y el arte procedural de parrilla, pase con café y comedor. |
| `25_maestria.png` | Modal de Maestría Culinaria con el resumen de rango y la lista desplazable de recompensas por rango. |
| `26_pase_bistro_4_platos.png` | Pase del Bistró con Emplatado Nv.3 y los cuatro platos alineados (poco hecho, al punto con patatas, hecho y al punto con patatas). |

Herramienta de QA: `godot --path . --resolution 1280x720 res://Escenas/Herramientas/Captura_Minijuego_Cocina.tscn` genera `minijuego_cocina_nivel1.png` (nivel 1 limpio), `minijuego_cocina_tap.png` (toque rápido), `minijuego_cocina_pase.png` (pase con dos huecos activos), `minijuego_cocina_pase_nv3.png` (pase con los cuatro huecos), `modal_pausa.png`, `modal_confirmar_salida.png`, `modal_nivel.png` y `modal_resultados.png` en `user://capturas_minijuego_cocina`. Para los **tres mundos nuevos**, `godot --path . --resolution 1280x720 res://Escenas/Herramientas/Captura_Mundos_Cocina.tscn` genera cocina, modal, mejoras y mapa de cada mundo en `user://capturas_mundos_cocina`. Para la pantalla de Mejoras, `godot --path . res://Escenas/Herramientas/Captura_Mejoras_Cocina.tscn` genera `01`–`08` en `user://capturas_mejoras_cocina` (una por mejora, sin Caja, máximo y compra).

---

## 8. Pack de sprites del escenario

El pack de **152 PNG** vive en `Imagenes/Minijuego_Cocina/` (134 del pack base + 15 mejoras + **3 fondos nuevos en `Fondos/`**) y **ya está integrado en el minijuego jugable** a través de `Arte_Cocina.gd`:

- Chef + 6 poses.
- 8 clientes + 8 versiones enfadadas.
- 32 comidas (platos, ingredientes y extras).
- 8 estaciones, 8 piezas de mostrador, 22 de emplatado/props.
- 24 de UI (+4 botones 9-patch `Boton_Modal_{Azul,Verde,Naranja,Rojo}.png` generados con `tools/generar_botones_modal.py` para los modales), 8 de decoración y 8 de efectos.
- 15 ilustraciones de mejoras (3 variantes por cada una de las 5 mejoras) en `Mejoras/`.
- Fondo `Fondo_Restaurante.png` 1280×720.
- Layout de referencia: `Imagenes/Minijuego_Cocina/escenario_layout.json`.

La escena de muestra `Escenas/Minijuego_Cocina/Escenario_Maqueta_Cocina.tscn` sigue siendo una maqueta visual independiente que se abre con `./ver_escenario.sh`; sirve para revisar el pack completo, pero el juego real ya consume los mismos sprites. Inventario y pipeline en [`ARTE_SPRITES.md`](ARTE_SPRITES.md).

Fuera de esos 149 sprites, el juego usa tres **recursos de composición**: `Banner_Cocina.png` (1288×284, en la raíz), `Emplatado/Plato_Perspectiva.png` (640×297) y `Fondo_Restaurante_Selector.png` (360×640, generado desde el fondo del restaurante para el selector cartoon). No forman parte del pack; su inventario, tamaños y maestros están en [`ARTE_SPRITES.md`](ARTE_SPRITES.md).

---

## 9. Rendimiento

- El bucle de cocina es O(1) por frame y **no llama a `save_game()`**; el guardado se hace al cerrar el nivel.
- Los sprites se dibujan con `_draw` nativo y texturas precargadas; no hay `load()` en caliente.
- La capa de partículas está limitada a 240 partículas y los SFX a 12 voces.
- `_Animar_Escena` solo redibuja los nodos activos; los puestos del mueble de ingredientes se redibujan al cambiar el hover y, mientras el dedo está encima, para animar el halo y el leve balanceo.

---

## 10. Mantenimiento

- **Duración y dificultad de un nivel:** editar su entrada en `Sistema_Cocina._Inicializar_Restaurantes()`: `clientes` fija cuántos clientes reparte la partida (el nivel acaba cuando se agotan), `intervalo_spawn` el ritmo de llegada, `paciencia_base` el margen de cada cliente y `meta_1/2/3` las estrellas. No hay clave `duracion`: el reloj del HUD es solo informativo. Para ajustar la pausa o el fin de nivel, `_Abrir_Modal_Pausa()`/`_Reanudar_Partida()` y `_Nivel_Completado()` en `Minijuego_Cocina.gd`.
- **Nuevo ingrediente/receta:** añadir la textura a `Arte_Cocina` y la composición a `dibujar_item` / `_Puede_Anadir_A_Plato`; registrar el plato en `Sistema_Cocina.RECETAS_BURGER_STREET`.
- **Nueva estación:** añadir el sprite a `Arte_Cocina`, el rectángulo de origen/destino en `_Registrar_Zonas_Arrastre` y la acción en `_Aplicar_Soltar`.
- **Nuevo SFX:** generar/colocar el WAV en `Sonidos/SFX/`, añadirlo a `STREAMS` en `Sonidos_Cocina.gd` y llamarlo desde el evento.
- **Nuevo cliente:** añadir el PNG a `CLIENTES` y su versión enfadada a `CLIENTES_ENOJADOS`; el reparto de variantes es automático.
- Al cambiar el layout de estaciones, ajustar las constantes `ZONA_*` y los centros de fogones/cestas en `_Reconstruir_Estaciones`.
- **Fondo del selector:** `Fondo_Restaurante_Selector.png` se genera con `python3 tools/generar_fondo_selector.py` a partir de `Fondo_Restaurante.png`; si cambia la foto de la cocina, vuelve a ejecutarse y se reimporta solo en Godot. El resto del panel se dibuja en código en `Selector_Niveles_Arte.gd`.
- **Selector de restaurantes y arte cartoon:** `_restaurante_expandido` guarda el mundo abierto (vacío = selector de mundos). `_Ajustar_Disposicion_Mapa()` alterna las dos vistas excluyentes dentro del marco `Marco_Selector_Niveles`: `_lista_restaurantes` visible en el selector y `_contenedor_niveles` visible al entrar en un mundo. `_Volver_Mapa()` cierra el mundo abierto o sale al Sim si ya está el selector; `_Volver_Atras()` reutiliza esa cascada para Android/Escape. Los estados visuales de las tarjetas se generan en `_Refrescar_Lista_Mundos()`; el tablero se compone en `Centro_Niveles` + `Grid_Niveles` con `Boton_Nivel` y se revela con `_Animar_Revelado_Niveles()`. «Mejoras» se habilita solo con un mundo jugable abierto. Todo el dibujo del panel, las monedas, la botonera y la barra de scroll vive en `Scripts/GUI/Minijuego_Cocina/Selector_Niveles_Arte.gd`; el fondo desenfocado se genera aparte en `Imagenes/Minijuego_Cocina/Fondo_Restaurante_Selector.png`.
- **Salidas y botón atrás:** el **Mapa** del HUD usa `_Intentar_Volver_Al_Mapa()` y `Modal_Confirmar_Salida`; añadir una salida nueva debe pasar por `_Volver_Atras()` para que Android/Escape no cierren la app. Los iconos de UI se resuelven por nombre desde `Imagenes/UI/Iconos/` con `Estilos_UI.badge_icono`/`icono_rect`; los modales del minijuego usan el arte de `Arte_Modal_Cocina.gd` y los 9-patch `Boton_Modal_*`, no `triangle-alert.svg`.
- **Modales cartoon:** `Arte_Modal_Cocina.gd` concentra el marco, el título, los botones, las placas y los textos; los cuatro modales se montan con `_Crear_Modal_Base()` (`_Construir_Modal_Pausa()`, `_Construir_Modal_Confirmar_Salida()`, `_Construir_Modal_Inicio()` y `_Construir_Modal_Resultados()`) y la ficha y los resultados se rellenan en `_Abrir_Modal_Inicio()`/`_Mostrar_Modal_Resultados()`. Para cambiar el aspecto, editar `Marco_Modal`/`Titulo_Modal`/`Boton_Modal`; si se tocan los botones 9-patch, regenerarlos con `python3 tools/generar_botones_modal.py` y reimportar los PNG en Godot.
- **Emplatado:** la bandeja y sus huecos viven en `Arte_Cocina.Bandeja_Emplatado` y `_Disposicion_Bandeja_Platos()` (cuatro huecos fijos, con 2/3/4 abiertos según `emplatado`); la base es `Bandeja_Metal.png` y la mampara es `Arte_Cocina.Fondo_Pase`. La geometría de la alfombrilla y las celdas se comparte con `Arte_Cocina.rect_liner_emplatado()` / `celdas_emplatado()`. Los platos se dibujan en `Arte_Cocina.Plato` con `dibujar_plato_hamburguesa()` y `Plato_Perspectiva.png`, y el ancho se acota con `min(size.x * 0.96, size.y * 0.68)` para que la hamburguesa quepa siempre. Los huecos cerrados se pintan como rebajes con `TEX_CANDADO_CERRADO` y la pastilla de nivel; el número de huecos abiertos se pasa con `configurar(celdas, desbloqueados)`. Los recipientes del mueble bajo la encimera (`Arte_Cocina.Puesto_Ingrediente`) se dibujan a mano con las texturas del pack (panera, bandeja, tabla, bol, cesta) y comparten una placa pequeña con el nombre; si se cambia el pack, no hace falta retocar offsets. Actualiza las capturas 11/12 si cambia el número de platos y las capturas del mueble si cambian los recipientes.
- **Banner de la tarjeta:** `Script_Principal._Actualizar_Pantalla_Minijuegos()` reconstruye el banner; el fondo se cambia en `Arte_Cocina.TEX_BANNER` y las posiciones/tamaños de los 6 sprites en las llamadas a `_Anadir_Item_Banner()`. Las 5 sombras se añaden antes que los sprites con `_Anadir_Sombra_Banner()`, de atrás a delante. El plato usa `TEX_PLATO_PERSPECTIVA` (640×297) y no `Plato_Vacio.png`, para conservar la perspectiva 3/4. `textura_sombra_contacto()` cachea el degradado radial, así que reconstruir la tarjeta no recrea la textura.
