# Vestuario y ropa equipable

## Resumen

El **Vestuario** es la sección propia para cambiar la ropa del Sim. Sustituye al
antiguo conmutador `Apuntes | Ropa` que vivía dentro de la pestaña de inventario
del Perfil: la ropa ya no se mezcla con los libros y apuntes de carrera.

El armario se amplió a **25 atuendos**: 10 gratis desde el inicio, 11 que se
compran con dinero y 4 que se ganan con Maestría Culinaria. La pantalla incluye
filtros por categoría, saldo visible, precio en las tarjetas y compra integrada.

- **Acceso principal:** pestaña `Vestuario` de la barra superior (icono `shirt`),
  junto a Perfil, Economía, Horario, Carrera y Minijuegos.
- **Accesos secundarios:** botón «Vestuario» en la tarjeta de Inicio y botón
  «Cambiar de atuendo» en Perfil → Info.
- **Vista previa:** el personaje se dibuja a cuerpo completo y animado con la
  prenda seleccionada antes de comprarla o equiparla.
- **Animaciones:** la ropa equipada se usa en el escenario animado de Inicio
  (todas las poses de actividad), el avatar de la cabecera, el retrato del
  Perfil y el logo del menú.

## Archivos

| Archivo | Contenido |
|---|---|
| `Scripts/Logica/Escena_Principal/Economia/Ropa_Catalogo.gd` | Datos centralizados de las 25 prendas (precio, desbloqueo, categoría, estilo, paleta, detalles y bonificaciones) |
| `Scripts/GUI/Escena_Principal/Vestuario/Pantalla_Vestuario.gd` | Pantalla completa del armario: vista previa, filtros, tarjetas, compra y CTA |
| `Escenas/Escena_Principal/Escena principal.tscn` | Nodo `Vestuario_Button` de la barra superior |
| `Scripts/Globales/Script_Principal.gd` | Creación de `Pantalla_Vestuario`, navegación, refresco de apariencia y saldo |
| `Scripts/GUI/Escena_Principal/Estilos_UI.gd` | Icono `Vestuario_Button` y aplicación global de la ropa en avatares |
| `Scripts/GUI/Escena_Principal/Gestionar_Visibilidad.gd` | Visibilidad del botón en la navegación básica |
| `Scripts/Logica/Personaje/Apariencia_Personaje.gd` | Campos de atuendo, `detalle_ropa` y `aplicar_atuendo()` |
| `Scripts/GUI/Personaje/Personaje_Visual.gd` | Dibujo de la ropa base y de los detalles de cada atuendo |
| `Scripts/Logica/Escena_Principal/Economia/Herencia/Objeto_Ropa.gd` | Datos de la prenda (desbloqueo, categoría, bonificaciones + aspecto) |
| `Scripts/Globales/Principales_Variables/Variables_Estaticas.gd` | Llama a `Ropa_Catalogo.Registrar_En()` al construir el catálogo |
| `Scripts/Logica/Escena_Principal/Minijuego_Cocina/Sistema_Cocina.gd` | Bonificaciones, compra, equipado, prendas iniciales, rangos y apariencia |
| `Escenas/Herramientas/Captura_Vestuario.tscn` | Herramienta de QA visual: pantalla, tienda, cocina y parrilla de todos los atuendos |
| `Funcionalidades/Vestuario/Tests/test_vestuario.gd` | Tests GUT del sistema (12 tests) |

## Atuendos disponibles

### Inicio (gratis, 10)

| Clave | Nombre | Estilo visual | Efecto |
|---|---|---|---|
| `Ropa_Calle` | Ropa de Calle | `base` | Sin bonificaciones; conserva la ropa y colores del creador |
| `Camiseta_Blanca` | Camiseta Blanca | `base` | Sin bonificaciones |
| `Sudadera_Gris` | Sudadera con Capucha | `base` | Sin bonificaciones |
| `Camisa_Cuadros` | Camisa de Cuadros | `casual` | Sin bonificaciones |
| `Conjunto_Verano` | Conjunto de Verano | `verano` | Sin bonificaciones |
| `Vestido_Flores` | Vestido de Flores | `vestido` | Sin bonificaciones |
| `Pijama_Estrellada` | Pijama Estrellada | `pijama` | Sin bonificaciones |
| `Jersey_Invierno` | Jersey de Invierno | `invierno` | Sin bonificaciones |
| `Conjunto_Deportivo` | Conjunto Deportivo | `deportivo` | +2% progreso Deportivo |
| `Equipacion_Futbol` | Equipación de Fútbol | `futbol` | +3% progreso Deportivo |

Las prendas de inicio se entregan automáticamente en partidas nuevas y al cargar
partidas antiguas (`Asegurar_Prendas_Iniciales()`); no se pierden al vender
objetos porque la ropa no entra en el sistema de venta de muebles.

### Tienda (se compran con dinero, 11)

| Clave | Nombre | Precio | Categoría | Efecto |
|---|---|---:|---|---|
| `Camiseta_Universidad` | Camiseta Universitaria | 90 € | Diario | +3% progreso Académico |
| `Mono_Taller` | Mono de Taller | 160 € | Trabajo | +8% progreso Manualidades |
| `Uniforme_Camarero` | Uniforme de Camarero | 180 € | Trabajo | +10% propinas en el minijuego |
| `Bata_Laboratorio` | Bata de Laboratorio | 220 € | Trabajo | +8% progreso Académico |
| `Chaqueta_Neon` | Chaqueta Neón | 260 € | Fiesta | +5% propinas en el minijuego |
| `Abrigo_Invierno` | Abrigo de Invierno | 280 € | Diario | -10% desgaste de Higiene en cualquier trabajo |
| `Chaqueta_Cuero` | Chaqueta de Cuero | 320 € | Diario | +3% salario en cualquier trabajo |
| `Traje_Ejecutivo` | Traje Ejecutivo | 420 € | Elegante | +5% salario en cualquier trabajo |
| `Vestido_Gala` | Vestido de Gala | 700 € | Elegante | +6% salario en cualquier trabajo |
| `Esmoquin_Noir` | Esmoquin Noir | 850 € | Elegante | +8% salario en cualquier trabajo |
| `Traje_Astronauta` | Traje de Astronauta | 1200 € | Trabajo | +10% salario y -10% desgaste de Higiene |

Los precios usan `Variables_Estaticas.Obtener_Precio_Objeto()`, por lo que se
escalan automáticamente en Modo Rápido (×0,1). La compra descuenta el dinero de
`Variables_Dinamicas.Dinero`, marca la prenda en `Objetos_Poseidos` y guarda la
partida. Desde el Vestuario se puede **probar antes de comprar**: la tarjeta se
selecciona, la vista previa muestra el atuendo y el CTA cambia a «Comprar por
X €». Si no hay saldo suficiente, el CTA muestra «Faltan X €» y queda
deshabilitado.

### Cocina (Maestría Culinaria, 4)

| Clave | Nombre | Estilo visual | Rango | Efecto |
|---|---|---|---:|---|
| `Delantal_Aprendiz` | Delantal de Aprendiz | `delantal` | 1 | -5% desgaste de Higiene en hostelería |
| `Chaqueta_Chef` | Chaqueta de Chef | `chef` | 3 | +10% salario en hostelería y -5% Higiene |
| `Atuendo_Chef_Gala` | Atuendo de Chef de Gala | `gala` | 6 | +20% salario en hostelería y -5% Higiene |
| `Traje_Estrella_Michelin` | Traje Estrella Michelin | `michelin` | 9 | +30% salario, -5% Higiene y +25% propinas |

Los rangos se ganan reuniendo estrellas en `Minijuego_Cocina` (cada 20 ★).
Las prendas bloqueadas aparecen en el carrusel con candado y el rango necesario;
se pueden previsualizar al tocar su tarjeta, pero no se pueden equipar.

## Categorías y filtros

`Sistema_Cocina.CATEGORIAS_ROPA` define los filtros de la pantalla:

`Todo` · `Tienda` · `Diario` · `Deporte` · `Elegante` · `Trabajo` · `Fiesta` · `Cocina`

Cada `Objeto_Ropa` declara su `categoria`. El filtro `Tienda` es especial: muestra
todas las prendas con `desbloqueo == "tienda"`, estén compradas o no. Al cambiar
de filtro se reconstruye el carrusel, se actualiza el contador («X/Y en tu
armario») y, en el filtro `Cocina`, aparece la tarjeta de Maestría Culinaria. Si
la prenda seleccionada no pertenece al filtro, se intenta seleccionar la primera
prenda disponible o comprable.

## Modelo visual

Cada `Objeto_Ropa` añade a los campos de bonificación:

```gdscript
@export var desbloqueo: String = "inicio"   # inicio | tienda | rango
@export var categoria: String = "diario"    # diario | deporte | elegante | trabajo | fiesta | cocina
@export var prenda_superior: String = ""    # vacío = combinación por defecto del estilo
@export var prenda_inferior: String = ""
@export var calzado: String = ""
@export var detalle_visual: String = ""     # cuadros, corbata, bufanda, estrellas...
@export var estilo_visual: String = "base"
@export var color_principal: String = ""
@export var color_secundario: String = ""
@export var color_detalle: String = ""
@export var color_pantalon: String = ""
@export var color_zapatillas: String = ""
```

Estilos que sabe dibujar `Personaje_Visual`:

`base`, `delantal`, `chef`, `gala`, `michelin`, `casual`, `deportivo`,
`verano`, `invierno`, `traje`, `bata`, `mono`, `camarero`, `pijama`, `fiesta`,
`futbol`, `cuero`, `astronauta` y `vestido`.

`Apariencia_Personaje.aplicar_atuendo(datos, ropa)` devuelve una copia
normalizada de la apariencia con:

- `estilo_ropa` = estilo visual de la prenda.
- `detalle_ropa` = detalle decorativo del estilo.
- `ropa_superior`, `ropa_inferior` y `calzado` sustituidos por la combinación
  base del estilo y, después, por los campos explícitos de la ficha.
- `color_ropa`, `color_ropa_secundario`, `color_ropa_detalle`,
  `color_pantalon` y `color_calzado` sustituidos por la paleta de la prenda
  (solo los campos no vacíos).
- `Ropa_Calle` deja intactos `ropa_superior`, `ropa_inferior`, `color_ropa`,
  `color_pantalon` y `color_calzado` del creador.

`Personaje_Visual._draw()` lee esos campos y llama a
`_dibujar_atuendo_encima()` después del torso base. Los brazos usan la manga y
el color de la capa exterior cuando el atuendo la tiene (traje, bata, cuero,
chaqueta neón, abrigo, astronauta) para que no parezca un chaleco.

Detalles visuales principales:

- **Casual:** camiseta con bolsillo, camisa a cuadros o sello universitario.
- **Deportivo:** cremallera, franjas de hombro y escudo.
- **Verano:** top, shorts, cordón, franja diagonal y sol estampado.
- **Invierno:** jersey de punto y bufanda con flecos; variante de abrigo largo
  con solapas, cinturón y doble botonadura.
- **Traje / Esmoquin:** chaqueta abierta, solapas, corbata o pajarita, pañuelo
  de bolsillo y botones.
- **Bata:** bata larga abierta, solapas, bolsillos, insignia y bolígrafo.
- **Mono:** peto vaquero, tirantes, botones y bolsillo de herramientas.
- **Camarero:** chaleco, pajarita y bloc de notas.
- **Pijama:** tapeta, ribetes, estrellas y luna.
- **Fiesta:** chaqueta de neón, lentejuelas y rayo.
- **Fútbol:** cuello en V, franjas, escudo, dorsal «10» y medias.
- **Cuero:** chaqueta con cremalleras, tachuelas y cinturón.
- **Astronauta:** panel pectoral, controles, manguera, anillo de cuello,
  insignia y bandas naranjas en los brazos.
- **Vestido:** falda acampanada corta o larga, cinturón, flores o lentejuelas.

En la ducha (`en_ducha = true`) no se dibuja ropa, como corresponde a la pose.
En el resto de poses (correr, dormir, comer, estudiar, cocinar, trabajar,
fútbol, fiesta, etc.) la prenda se dibuja igual porque el atuendo forma parte
de la apariencia que consume el renderizador.

## Pantalla

`Pantalla_Vestuario` se construye por código y se monta como overlay `Control`
(`z_index = 5`) sobre la escena principal.

- **Cabecera:** botón volver, título «Vestuario», subtítulo y píldora de saldo.
- **Tarjeta de vista previa:** escenario con degradado, rayos, halo y sombra de
  suelo; personaje `cuerpo_completo` animado; columna con categoría, nombre,
  píldora `EQUIPADO`/`EN PRUEBA`/`EN TIENDA`, efecto, chips de bonificaciones y
  desbloqueo/precio.
- **Colección:** contador, flechas de carrusel y filtros por categoría.
- **Tarjetas:** miniatura circular del Sim con esa prenda, nombre, estado
  (`Equipado`/`Disponible`/`En tienda`/`Rango N`), check verde, candado o
  píldora de precio. Las prendas bloqueadas por rango también se pueden tocar
  para verlas en la vista previa (píldora `BLOQUEADO` y CTA deshabilitado),
  pero no se pueden equipar.
- **Barra inferior fija:** CTA dinámico `Equipar atuendo`, `Comprar por X €`,
  `Faltan X €` o `Atuendo equipado`.
- **Tarjeta de Maestría Culinaria (solo filtro Cocina):** muestra el rango
  actual (`Rango X/9 · Nombre`), el progreso de estrellas hacia el siguiente
  rango y el aviso «Gana estrellas en el minijuego de Cocina para ascender de rango».

### API pública (tests y otras pantallas)

```gdscript
pantalla.abrir()
pantalla.seleccionar_atuendo("Chaqueta_Chef")  # false si no está poseída ni es comprable
pantalla.comprar_seleccionado()                # compra la prenda de tienda seleccionada
pantalla.equipar_seleccionado()                # persiste y emite atuendo_equipado
pantalla.obtener_clave_seleccionada()
pantalla.obtener_clave_equipada()
pantalla.obtener_apariencia_preview()
pantalla.obtener_tarjetas()
```

Señales: `cerrado`, `atuendo_equipado(clave: String)` y
`atuendo_comprado(clave: String)`.

## Persistencia y efectos

- `Sistema_Cocina.Comprar_Ropa(clave)` valida que sea una prenda de tienda,
  comprueba el saldo, descuenta el precio, la añade a `Objetos_Poseidos` y
  guarda la partida.
- `Sistema_Cocina.Equipar_Ropa(clave)` valida que la prenda esté poseída, la
  guarda en `Variables_Dinamicas.Objeto_Seleccionado["Ropa"]` y llama a
  `Guardar_Variables_Dinamicas.save_game()`.
- Al comprar, `Pantalla_Vestuario` emite `atuendo_comprado` y
  `Script_Principal._on_atuendo_comprado()` refresca el saldo de la cabecera.
- Al equipar, `Script_Principal._on_atuendo_equipado()` refresca el avatar de
  cabecera, el escenario de Inicio y, si está abierto, Perfil → Info.
- Bonificaciones consultadas por el resto del juego:
  - `Obtener_Bonus_Salario_General()` → `Actividades.gd` (nómina de cualquier trabajo).
  - `Obtener_Bonus_Salario_Hosteleria()` → `Actividades.gd` (nómina de hostelería).
  - `Obtener_Bonus_Progreso(0/1/2)` → `Actividades_Habilidades.gd` (deporte, académico, manualidades).
  - `Obtener_Reduccion_Higiene_Para_Trabajo(nombre)` → `Actividades_Necesidades_Basicas.gd`.
  - `Obtener_Bonus_Propinas_Ropa()` → `Sistema_Cocina` y `Minijuego_Cocina`.

## Cómo añadir un atuendo nuevo

1. Añadir un diccionario a `Ropa_Catalogo.DATOS` con `clave`, `precio`,
   `desbloqueo`, `categoria`, `estilo_visual`, paleta, `detalle_visual` y
   bonificaciones. Si el estilo base no encaja, usar `prenda_superior`,
   `prenda_inferior` y `calzado` para forzar la prenda base.
2. Añadir la clave a `Sistema_Cocina.ORDEN_ROPA` en el bloque que corresponda
   (Inicio, Tienda o Cocina) y el nombre legible a `NOMBRES_ROPA`.
3. Si se desbloquea por rango, añadir su clave al campo `prenda` del
   `RANGOS_LOGRO` correspondiente.
4. Si el estilo visual es nuevo, añadirlo a `Apariencia_Personaje.ESTILOS_ROPA`
   y dibujar sus detalles en `Personaje_Visual._dibujar_atuendo_encima()`.
5. Añadir el caso al test `test_vestuario.gd` y ejecutar la suite.
6. Actualizar las capturas de `Captura_Vestuario.tscn` para revisar el resultado.

## Tests

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir=res://Funcionalidades/Vestuario/Tests -gexit
```

La funcionalidad está cubierta por 12 tests: catálogo de 25 prendas, reparto
inicio/tienda/rango, prendas iniciales, compra con saldo insuficiente,
transformación de apariencia, bonificaciones de las prendas, equipado, pantalla,
filtros, bloqueo de prendas no poseídas y ausencia de la antigua pestaña Ropa
en Apuntes.

## QA visual

```bash
godot --path . res://Escenas/Herramientas/Captura_Vestuario.tscn
```

Genera en `user://capturas_vestuario/`:

- `vestuario_720x1280.png` — armario completo con todo desbloqueado.
- `vestuario_tienda_720x1280.png` — filtro Elegante con precios y CTA de compra.
- `vestuario_sin_saldo_720x1280.png` — misma pantalla con saldo insuficiente («Faltan X €»).
- `vestuario_astronauta_720x1280.png` — filtro Trabajo con el Traje de Astronauta y sus dos bonificaciones.
- `vestuario_cocina_720x1280.png` — filtro Cocina con prendas bloqueadas por rango.
- `atuendos_grid.png` — parrilla de los 25 atuendos sobre un Sim masculino.
- `atuendos_grid_mujer.png` — la misma parrilla sobre un Sim femenino.
