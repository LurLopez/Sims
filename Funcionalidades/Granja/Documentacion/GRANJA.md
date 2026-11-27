# La Granja — plan simple (MVP) + conversión diaria

> **Estado:** **implementado y jugable** (MVP simple). Tests GUT: 24/24;
> suite completa del proyecto: 437/437.
>
> **Referencia:** *Family Farm* clásico (el de la captura: isométrico,
> horizontal, campo, animales, máquinas y «Premio nivel»), pero **solo la parte
> simple**. Nada de ranchos secundarios, eventos, social, vales ni monedas
> raras por ahora.
>
> **Novedad:** la granja tiene su propia moneda (**Monedas de Granja, MG**) y
> se convierte a euros del Sim con una tasa diaria decreciente.
>
> **QA:** `Sistema_Granja.GRANJA_GRATIS_QA = true` hace que la compra sea
> gratuita durante las pruebas. Ponerlo en `false` antes de publicar.

---

## 0.1. Implementación actual

| Pieza | Archivo |
|---|---|
| Autoload | `Scripts/Logica/Escena_Principal/Granja/Sistema_Granja.gd` |
| Catálogo | `Scripts/Logica/Escena_Principal/Granja/Datos_Granja.gd` |
| Pantalla | `Escenas/Granja/Granja.tscn` + `Scripts/GUI/Granja/Granja.gd` |
| Objetos del mapa | `Scripts/GUI/Granja/Slot_Mapa.gd` |
| Iconos de producto | `Scripts/GUI/Granja/Icono_Producto.gd` |
| Estado persistente | `Variables_Dinamicas.Granja_Estado` |
| Entrada desde el hub | `Script_Principal._Anadir_Tarjeta_Granja()` + `_Abrir_Granja()` |
| Entrada rápida | `Boton_Granja_Header` (solo visible con la granja comprada) |
| Transición | `Transicion_Minijuego` tema `granja` (gallina + acento verde) |
| Tests | `Funcionalidades/Granja/Tests/test_granja.gd` (21) + `test_ui_granja.gd` (2) |
| Capturas QA | `Funcionalidades/Granja/Documentacion/Capturas/granja_01..08.png` |
| Capturas | `Escenas/Herramientas/Captura_Granja.tscn` y `Captura_Granja_Hub.tscn` |

**Flujo real:** Minijuegos → tarjeta «La Granja» → compra gratuita en QA →
pantalla horizontal → sembrar, alimentar, cargar máquinas, vender y cobrar.
La granja empieza con **100 MG**, **1 gallina**, **1 molino**, **4 parcelas**
y un kit de bienvenida de **1 maíz + 2 trigo** para poder probar la cadena en
la primera visita.

**Cómo probar:**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir=res://Funcionalidades/Granja -ginclude_subdirs -gexit

# Capturas (Xvfb o pantalla virtual; no es necesario abrir el navegador)
godot --path . res://Escenas/Herramientas/Captura_Granja.tscn
godot --path . res://Escenas/Herramientas/Captura_Granja_Hub.tscn
```

---

## 0. Decisión

La granja será una pantalla horizontal `1280×720` con una composición fija:

- un **campo** con parcelas,
- un **corral** con animales,
- un **taller** con máquinas,
- un **almacén** de productos,
- una **tienda/mejoras** que se paga con Monedas de Granja,
- una **ventanilla de cambio** MG → euros.

No hay rejilla libre, cámara, colocación isométrica interactiva, niveles, XP,
pedidos, vecinos ni eventos. Si el MVP funciona, se amplía.

---

## 1. Qué incluye

| Elemento | MVP |
|---|---|
| Compra | **Gratis en QA**; 1.500 € (150 € en Modo Rápido) fuera de QA |
| Pantalla | Horizontal 1280×720, composición fija |
| Campo | 4 parcelas iniciales; hasta 6 con mejoras |
| Animales | 1 gallina inicial; hasta 2 con mejoras |
| Máquinas | 1 molino inicial; hasta 3 con mejoras |
| Cultivos | Trigo, zanahoria y maíz |
| Animales | Gallina y vaca |
| Máquinas | Molino, panadería y quesería |
| Moneda interna | **Monedas de Granja (MG)** |
| Conversión | MG → euros del Sim, una vez al día, con tasa decreciente |
| Tiempos | Horas reales; Modo Rápido divide entre 7 |
| Mejoras | Más parcelas, más animales, más máquinas y velocidad |
| Guardado | `Variables_Dinamicas.Granja_Estado` |
| Kit inicial | 100 MG + 1 gallina + 1 molino + 1 maíz + 2 trigo |
| Offline | Sí: los relojes siguen con la app cerrada |

**No incluye:** niveles, XP, Doblones, OP, gasolina, vales, logros, Farmer's
Club, pedidos, camión, vecinos, eventos, Water Ranch, Garden Ranch, pesca,
clima ni colocación libre.

---

## 2. Bucle

```
Comprar granja (euros del Sim)
   ↓
Comprar semilla → plantar en una parcela → esperar horas → cosechar
   ↓
Alimentar animal con cultivo → esperar horas → recoger producto
   ↓
Cargar máquina con cultivos/productos → esperar horas → recoger elaborado
   ↓
Vender en el almacén → ganar Monedas de Granja (MG)
   ↓
¿Reinvierto en mejoras o cambio MG a euros?
   ↓
Cambiar MG a euros con la tasa del día
   ↓
Repetir
```

Sesión típica:

1. Abrir la granja.
2. Recoger lo que terminó mientras estaba fuera.
3. Alimentar animales y cargar máquinas.
4. Plantar lo que falte.
5. Vender excedentes.
6. Decidir: comprar una mejora o cambiar MG a euros.
7. Cerrar; los relojes siguen.

---

## 3. Pantalla

```
┌──────────────────────────────────────────────────────────────────┐
│ LA GRANJA          MG: 250        Dinero: 1.250 €      [Cobrar] ✕│
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  CORRAL                 CAMPO                         TALLER     │
│  ┌────────┐        ┌────┐ ┌────┐ ┌────┐        ┌────────┐       │
│  │gallina │        │trigo│ │zanah│ │maíz │        │ molino │       │
│  │2h 10m  │        └────┘ └────┘ └────┘        │ harina │       │
│  └────────┘        ┌────┐ ┌────┐ ┌────┐        └────────┘       │
│  ┌────────┐        │trigo│ │bloq.│ │bloq.│        ┌────────┐       │
│  │ vaca   │        └────┘ └────┘ └────┘        │panader.│       │
│  └────────┘                                     └────────┘       │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│ [Tienda]        [Almacén]        [Mejoras]        [Cerrar]       │
└──────────────────────────────────────────────────────────────────┘
```

La pantalla es un **mapa isométrico** sobre el fondo de la granja: las parcelas
son diamantes de tierra en el centro, el corral queda a la izquierda y el taller
a la derecha. Cada objeto tiene una burbuja con su estado y su cuenta atrás;
tocar una parcela vacía abre el selector de cultivo.

- **Cabecera:** título, MG, dinero del Sim y botón **Cobrar** (abre el cambio).
- **Campo:** 4 parcelas visibles; las 2 extra aparecen al comprarlas.
- **Corral:** 1 animal inicial; el segundo slot se compra.
- **Taller:** 1 máquina inicial; los otros 2 slots se compran.
- **Almacén:** lista de productos y botón “Vender todo”.
- **Tienda:** semillas, animales y máquinas.
- **Mejoras:** parcelas, slots y velocidad.
- **Interacción:** tocar una parcela/animal/máquina abre un panel pequeño con
  la acción disponible.

---

## 4. Contenido del MVP

### 4.1. Cultivos

| Cultivo | Semilla | Tiempo | Venta | Nivel |
|---|---:|---:|---:|---|
| Trigo | 5 MG | 2 h | 12 MG | 1 |
| Zanahoria | 8 MG | 4 h | 22 MG | 1 |
| Maíz | 12 MG | 6 h | 35 MG | 1 |

- Una parcela produce **1 unidad** al cosechar.
- El cultivo no muere; si no se cosecha, se queda listo.
- No hay riego ni malas hierbas en el MVP.

### 4.2. Animales

| Animal | Precio | Come | Tiempo | Produce | Venta |
|---|---:|---|---:|---|---:|
| Gallina | 150 MG | 1 maíz | 4 h | 2 huevos | 10 MG/ud |
| Vaca | 350 MG | 2 trigo | 6 h | 2 leches | 14 MG/ud |

- Alimentar consume el cultivo del almacén.
- Si no está alimentado, no produce.
- Si no se recoge, el producto se queda esperando; no se acumula más.
- No hay muerte ni enfermedad.

### 4.3. Máquinas

| Máquina | Precio | Receta | Tiempo | Venta |
|---|---:|---|---:|---:|
| Molino | 250 MG | 2 trigo → 1 harina | 2 h | 35 MG |
| Panadería | 500 MG | 1 harina + 1 huevo → 1 pan | 3 h | 75 MG |
| Quesería | 700 MG | 2 leches → 1 queso | 4 h | 65 MG |

- Cargar una máquina consume los ingredientes al instante.
- Si no hay ingredientes, no se puede cargar.
- Si no se recoge, el producto se queda listo.
- Una máquina hace un lote cada vez; no hay cola en el MVP.

### 4.4. Mejoras

| Mejora | Coste | Efecto | Límite |
|---|---:|---|---:|
| Parcela 5 | 200 MG | +1 parcela | 1 |
| Parcela 6 | 400 MG | +1 parcela | 1 |
| Segundo corral | 300 MG | +1 animal | 1 |
| Segundo taller | 400 MG | +1 máquina | 1 |
| Tercer taller | 700 MG | +1 máquina | 1 |
| Velocidad I | 400 MG | −10 % tiempo | 1 |
| Velocidad II | 800 MG | −20 % tiempo | 1 |
| Velocidad III | 1.200 MG | −30 % tiempo | 1 |

- La velocidad se aplica a cultivos, animales y máquinas.
- No hay niveles ni XP; el progreso es MG + mejoras.

---

## 5. Monedas de Granja y conversión

### 5.1. Monedas de Granja (MG)

- La granja **no usa directamente los euros del Sim** para operar.
- Vender cultivos, productos animales y elaborados da **MG**.
- Las semillas, animales, máquinas y mejoras cuestan **MG**.
- La granja empieza con **100 MG** al comprarla, además de **1 maíz y 2 trigo**
  para poder alimentar a la gallina y cargar el molino en la primera visita.
- El jugador decide: **reinvertir MG** o **cambiarlos a euros**.

### 5.2. Conversión diaria MG → euros

- Hay una ventanilla **“Cobrar”** en la cabecera.
- Se puede cambiar **la cantidad que quieras**, varias veces al día.
- La tasa no es fija: depende de cuántos MG **ya has cambiado hoy**.
- **Reinicio diario:** a las 04:00 local.
- La tasa se aplica de forma **marginal**, unidad a unidad, para que no se
  pueda hacer trampa cambiando en trozos pequeños.
- El resultado se suma a `Variables_Dinamicas.Dinero`.

### 5.3. Curva de conversión

Constantes iniciales:

```
TRAMO_INICIAL = 10 MG
TASA_INICIAL = 1.0
TASA_DESPUES_DEL_TRAMO = 0.5
ESCALA_LOG = 50
TASA_MINIMA = 0.10
```

Fórmula de la tasa marginal para el MG número `x` cambiado hoy:

```text
Si x < 10:
    tasa(x) = 1.0
Si x >= 10:
    tasa(x) = max(0.10, 0.5 / (1 + log2(1 + (x - 10) / 50)))
```

- Los **primeros 10 MG del día** se cambian exactamente a **1:1**.
- A partir del MG 10, la tasa empieza en **0,5** y baja en logarítmico.
- La tasa mínima es **0,10** para que nunca llegue a cero.
- El total recibido es la suma de la tasa de cada MG.

### 5.4. Tabla de referencia

Cambiando desde cero en un día:

| MG cambiados hoy | Tasa marginal siguiente | Euros recibidos | Tasa media |
|---:|---:|---:|---:|
| 10 | 0,50 | 10,00 € | 1,00 |
| 20 | 0,40 | 14,40 € | 0,72 |
| 50 | 0,27 | 24,10 € | 0,48 |
| 100 | 0,20 | 35,60 € | 0,36 |
| 200 | 0,15 | 52,80 € | 0,26 |
| 500 | 0,11 | 91,30 € | 0,18 |
| 1.000 | 0,10 | 142,80 € | 0,14 |

> La tasa marginal es la del **siguiente** MG. Los euros recibidos son el
> acumulado desde cero. Si ya has cambiado 50 MG y cambias otros 50, no recibes
> 24,10 €, recibes la diferencia: 35,60 − 24,10 = **11,50 €**.

### 5.5. Ejemplos

- **Primer cambio del día:** 10 MG → **10,00 €**.
- **Segundo cambio:** otros 10 MG → **4,40 €** (total 20 MG → 14,40 €).
- **Cambio grande:** 100 MG → **35,60 €**.
- **Cambio muy grande:** 500 MG → **91,30 €**.
- **Si cambias 50 MG y luego 50 MG más:** 24,10 € + 11,50 € = **35,60 €**
  (lo mismo que cambiar 100 de golpe; no hay ventaja en trocear).

### 5.6. Por qué es logarítmico y no está roto

- Los primeros MG del día son muy rentables (1:1), así que siempre apetece
  entrar y cobrar algo.
- A partir de 10 MG, cada MG extra vale menos; el jugador no puede convertir
  una fortuna a 1:1.
- La tasa mínima del 10 % evita que el cambio llegue a cero.
- El reinicio diario permite volver a empezar mañana.
- El jugador puede elegir entre **cobrar** o **reinvertir en mejoras**; si
  cobra todo, la granja se estanca.
- La curva es fácil de ajustar con las constantes (`TRAMO_INICIAL`,
  `ESCALA_LOG`, `TASA_MINIMA`) sin tocar el resto del juego.

### 5.7. Interfaz de cambio

Modal “Cambiar Monedas de Granja”:

```
┌──────────────────────────────────────────────┐
│ CAMBIAR MG A EUROS                           │
│                                              │
│ Hoy has cambiado: 50 MG                      │
│ Tasa del siguiente MG: 0,27                  │
│                                              │
│ Cantidad: [ 50 ] MG                          │
│ Recibirás: 11,50 €                           │
│ Tasa media de este cambio: 0,23              │
│                                              │
│ [10] [50] [100] [Todo]                       │
│                                              │
│              [Cambiar]   [Cancelar]          │
└──────────────────────────────────────────────┘
```

- La previsualización se actualiza al escribir la cantidad.
- “Todo” selecciona todas las MG disponibles.
- Si no hay MG, el botón está desactivado.
- Al cambiar, se actualiza `Dinero` y `Convertido_Hoy`.
- Se muestra un toast: “+11,50 €”.

### 5.8. Estado de la conversión

```gdscript
{
  "Version": 1,
  "Comprada": true,
  "Monedas": 250,
  "Convertido_Hoy": 50,
  "Dia_Conversion": "2026-11-24",
  "Parcelas": [...],
  "Animales": [...],
  "Maquinas": [...],
  "Almacen": {"trigo": 3, "huevo": 1, "harina": 0},
  "Mejoras": {"parcelas": 4, "animales": 1, "maquinas": 1, "velocidad": 0}
}
```

- `Dia_Conversion` se compara con la fecha local actual; si cambia, se pone
  `Convertido_Hoy = 0`.
- El reset es a las 04:00 local, no a medianoche.
- La fecha se guarda como string `YYYY-MM-DD` para evitar problemas de zona
  horaria.

---

## 6. Reglas

### 6.1. Tiempo

- Todos los tiempos base están en **horas**.
- **Modo normal:** 2 h = 2 h reales.
- **Modo Rápido:** 2 h = 2 h / 7 ≈ 17 min.
- **Mejora de velocidad:** multiplica el tiempo por `1 - 0,10 × nivel`.
  - Nivel 1: ×0,90.
  - Nivel 2: ×0,80.
  - Nivel 3: ×0,70.
- El tiempo se guarda como **timestamp absoluto** (`fin_en`), no como contador.
- Al abrir la granja se comprueba `ahora >= fin_en`.
- Si la app estuvo cerrada, el tiempo pasó igualmente.
- No hay tope de offline.

### 6.2. Dinero del Sim

- Se usa `Variables_Dinamicas.Dinero` solo para:
  - comprar la granja (1.500 €),
  - recibir el resultado de la conversión.
- La operativa diaria de la granja usa MG.
- La cabecera de la granja muestra MG y el saldo del Sim.
- Al cambiar MG, se actualiza el `Dinero_Label` del Sim.

### 6.3. Almacén

- Guarda cultivos, productos animales y elaborados.
- Capacidad ilimitada en el MVP.
- “Vender todo” vende todo lo vendible y suma MG.
- También se puede vender un producto concreto.
- “Vender todo” vende todo lo vendible. Para conservar ingredientes, vende
  producto a producto.

### 6.4. Interacción

- **Parcela vacía:** abre selector de semilla; si hay MG, planta.
- **Parcela creciendo:** muestra cuenta atrás.
- **Parcela lista:** botón “Cosechar”.
- **Animal sin comer:** abre selector de alimento; si hay, alimenta.
- **Animal produciendo:** cuenta atrás.
- **Animal listo:** botón “Recoger”.
- **Máquina vacía:** abre receta; si hay ingredientes, carga.
- **Máquina trabajando:** cuenta atrás.
- **Máquina lista:** botón “Recoger”.
- **Tienda:** compra animales/máquinas si hay slot libre y MG.
- **Mejoras:** compra la siguiente mejora disponible.
- **Cobrar:** abre el modal de conversión.

### 6.5. Guardado

- Estado pequeño dentro de `Variables_Dinamicas.Granja_Estado`.
- Se guarda con el guardado normal del juego.
- Al empezar partida nueva se reinicia.
- Los saves antiguos cargan con la granja bloqueada.

---

## 7. Integración con SIMS 0.33

- **Compra:** tarjeta en `Pantalla_Minijuegos`.
- **Acceso:** botón “Entrar a la granja” + icono en la cabecera.
- **Pantalla:** escena horizontal `1280×720` dentro de un `CanvasLayer`.
- **Transición:** `Transicion_Minijuego` con tema “granja”; al salir restaura
  la vertical.
- **Reloj del Sim:** sigue corriendo; la granja no pausa necesidades.
- **Dinero:** se actualiza al cambiar MG y al volver.
- **Aviso:** si el Sim está en la calle o sin dinero, la granja sigue
  disponible; no hay bloqueo.
- **Nueva partida:** resetea la granja.
- **Partidas antiguas:** granja bloqueada.

---

## 8. Arquitectura simple

Archivos reales:

```
Escenas/Granja/
  Granja.tscn                 # Pantalla horizontal 1280×720

Scripts/Logica/Escena_Principal/Granja/
  Sistema_Granja.gd           # Autoload: estado, compra, acciones, ventas, cambio
  Datos_Granja.gd             # Cultivos, animales, máquinas, mejoras y curva

Scripts/GUI/Granja/
  Granja.gd                   # Pantalla, mapa, botones y modales
  Slot_Mapa.gd                # Parcela/corral/taller interactivo sobre el mapa
  Icono_Producto.gd           # Iconos vectoriales del almacén

Imagenes/Granja/
  Fondo_Granja.png            # Mapa isométrico de fondo
  Gallina/Vaca/...            # Sprites procesados

Funcionalidades/Granja/
  Documentacion/GRANJA.md
  Documentacion/Capturas/     # granja_01..08.png
  Tests/test_granja.gd
  Tests/test_ui_granja.gd
```

- **Sin** `Granja_Rejilla`, `Granja_Pedidos`, `Granja_Logros`, `Granja_Club`,
  `Granja_Social`, `Granja_Eventos` ni guardado separado.
- El estado cabe en `Variables_Dinamicas.Granja_Estado`.
- La UI usa `Estilos_UI` y modales simples.
- Arte: fondo isométrico fijo + sprites de parcela/animal/máquina. Para el
  prototipo puede ser procedural.
- La curva se implementa con una tabla perezosa de euros acumulados: se amplía
  solo hasta la cantidad consultada, así la previsualización es instantánea y
  no hay que recorrer la curva en cada frame.

---

## 9. Fases (MVP)

### Fase 1 — Compra y campo

- Tarjeta en Minijuegos.
- Compra gratuita en QA (1.500 € fuera de QA).
- Pantalla horizontal.
- 4 parcelas con trigo/zanahoria/maíz.
- Plantar, esperar, cosechar.
- Almacén y venta en MG.
- Guardado/offline.
- 100 MG iniciales.

**Criterio:** comprar, plantar, cerrar, volver a las 2 h y cosechar.

### Fase 2 — Animales

- Gallina y vaca.
- Alimentar con cultivos.
- Producir y recoger.
- Comprar animales.
- Slot extra.

**Criterio:** alimentar una gallina con maíz, volver a las 4 h y recoger
huevos; venderlos.

### Fase 3 — Máquinas y conversión

- Molino, panadería y quesería.
- Cargar recetas, esperar, recoger.
- Cadena trigo → harina → pan.
- Slots extra.
- Modal de conversión MG → euros con curva diaria.
- Tabla/previsualización.

**Criterio:** completar la cadena trigo → harina → pan, vender, cambiar MG a
euros y ver el saldo actualizado.

### Fase 4 — Mejoras y pulido

- Parcelas 5 y 6.
- Velocidad I–III.
- Cuenta atrás visible.
- Iconos “listo”.
- SFX básicos.
- Captura QA.
- Tests.

**Criterio:** el jugador puede gastar MG en mejorar y nota la diferencia; la
conversión diaria se reinicia correctamente.

---

## 10. Tests

- Estado por defecto y compra.
- Compra sin dinero / doble compra.
- Plantar, cosechar, vender en MG.
- Tiempo normal y Modo Rápido (`/7`).
- Mejora de velocidad.
- Alimentar animal y recoger.
- Cargar máquina y recoger.
- Comprar slots y mejoras.
- Guardado/carga y offline.
- Nueva partida.
- Conversión:
  - primeros 10 MG a 1:1,
  - tasa 0,5 después de 10,
  - acumulado diario,
  - reinicio a las 04:00,
  - no se puede mejorar la tasa troceando,
  - tasa mínima 0,10,
  - redondeo a céntimos,
  - saldo del Sim actualizado.

---

## 11. Equilibrio inicial

- **Granja comprada:** gratis en QA; 1.500 € fuera de QA (150 € en Modo Rápido).
- **MG iniciales:** 100.
- **Ingreso típico con 4 parcelas:** 50–100 MG/día con 2–3 visitas.
- **Conversión típica:** 24–36 €/día.
- **Con mejoras:** 200–500 MG/día → 53–91 €/día.
- **Tope práctico:** la curva y la inversión en mejoras evitan que la granja
  sustituya al trabajo de forma trivial.
- **Reinversión:** si cambias todo cada día, no mejoras; si mejoras, ganas más
  a medio plazo.
- **Modo Rápido:** los tiempos se dividen entre 7, pero la curva diaria y el
  reset siguen igual; sirve para probar el bucle, no para romper la economía.

---

## 12. Futuro (solo si el MVP funciona)

- Más cultivos, animales y máquinas.
- Niveles/XP y «Premio nivel».
- Pedidos y camión.
- Colocación libre isométrica.
- Riego/malas hierbas.
- Logros y Farmer's Club.
- Vecinos y eventos.
- Water Ranch y Garden Ranch.

Pero **ahora no**: el MVP se queda en campo + animales + máquinas + MG +
conversión diaria + horas + mejoras.
