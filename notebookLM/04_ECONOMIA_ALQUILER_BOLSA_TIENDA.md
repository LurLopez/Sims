# Análisis del Sistema de Alquiler Timer-Based

## Implementación

### Método elegido: Timer absoluto

Se implementó con `Ultima_Fecha_Alquiler` guardando el minuto absoluto en que se cobró el último alquiler.

```
Lógica de cobro: if (Minute_Actual - Ultima_Fecha_Alquiler) >= 7*1440 → Cobrar
```

**Ventajas:**
- Preciso al minuto (no depende de qué día de la semana sea)
- Si pagas el martes 14:30, próximo alquiler es martes 14:30 +7 días
- Resistente a cambios de reloj del sistema

**Alternativa rechazada:** Guardar `Proxima_Fecha_Alquiler = Ultima_Fecha + 7*1440`
- Requeriría actualizar una segunda variable
- Menos flexible ante desincronizaciones

---

## Casos de Prueba

### Test 1: Primera vez - Alquiler cobra después de 7 días
**Inicial:**
- Dinero: 1000€
- En_La_Calle: false
- Ultima_Fecha_Alquiler: 0 (minuto de creación)

**Acción:** Esperar 7 días (7*1440 = 10080 minutos)

**Esperado:**
- Dinero: 800€ (1000 - 200)
- En_La_Calle: false (sigue alquilando)
- Ultima_Fecha_Alquiler: 10080 (se actualiza al cobro)

**Validación:** ✓ Correcto
- Cuando `(10080 - 0) >= 10080` es true → se ejecuta `Cobrar_Alquiler()`
- `Cobrar_Alquiler()` restituye dinero y actualiza `Ultima_Fecha_Alquiler`

---

### Test 2: Ir a la calle voluntariamente
**Inicial:**
- Dinero: 1000€
- En_La_Calle: false
- Ultima_Fecha_Alquiler: 0

**Acción:** Pulsar botón "En alquiler" → Confirmar "Irme a la calle"

**Esperado:**
- Dinero: 1000€ (sin cambio)
- En_La_Calle: true
- Ultima_Fecha_Alquiler: -1 (se anula el timer)

**Validación:** ✓ Correcto
- `Ir_A_La_Calle()` marca `En_La_Calle=true` y `Ultima_Fecha_Alquiler=-1`
- No se cobra nada
- Próximo cobro se cancela porque `Ultima_Fecha_Alquiler < 0`

---

### Test 3: Dinero insuficiente al cobrar
**Inicial:**
- Dinero: 150€
- En_La_Calle: false
- Ultima_Fecha_Alquiler: 0

**Acción:** Esperar 7 días

**Esperado:**
- Dinero: 150€ (sin cambio, no se cobra)
- En_La_Calle: true (automáticamente a la calle)
- Ultima_Fecha_Alquiler: -1 (se anula el timer)

**Validación:** ✓ Correcto
- Cuando llega la hora de cobrar, `Cobrar_Alquiler()` chequea:
  ```gdscript
  if Variables_Dinamicas.Dinero >= ALQUILER_SEMANAL:
      # Cobrar
  else:
      # Ir a la calle sin cobrar
      Ir_A_La_Calle()
  ```
- Se preserva el dinero (no puedes quedarte en negativo)

---

### Test 4: Volver a alquiler desde la calle (con 300€)
**Inicial:**
- Dinero: 300€
- En_La_Calle: true
- Ultima_Fecha_Alquiler: -1

**Acción:** Pulsar botón "En la calle" → Se cobra 200€ automático

**Esperado:**
- Dinero: 100€ (300 - 200)
- En_La_Calle: false (vuelve a alquiler)
- Ultima_Fecha_Alquiler: Minute_Actual (nuevo timer de 7 días)

**Validación:** ✓ Correcto
- `Volver_A_Alquiler()` chequea dinero:
  ```gdscript
  if Variables_Dinamicas.Dinero >= ALQUILER_SEMANAL:
      En_La_Calle = false
      Dinero -= 200
      Ultima_Fecha_Alquiler = Minute_Actual
  ```
- Próximo cobro será en 7 días desde el minuto actual

---

### Test 5: Intenta volver a alquiler sin dinero suficiente (150€)
**Inicial:**
- Dinero: 150€
- En_La_Calle: true
- Ultima_Fecha_Alquiler: -1

**Acción:** Pulsar botón "En la calle" → No pasa nada (silenciosamente)

**Esperado:**
- Dinero: 150€ (sin cambio)
- En_La_Calle: true (se queda en la calle)
- Ultima_Fecha_Alquiler: -1 (sin cambio)

**Validación:** ✓ Correcto
- `Volver_A_Alquiler()` chequea:
  ```gdscript
  if Variables_Dinamicas.Dinero >= ALQUILER_SEMANAL:
      # Cambiar a alquiler
  else:
      pass  # No hace nada
  ```
- El usuario se queda en la calle hasta conseguir 200€

---

### Test 6: Segundo alquiler después de volver (7 días después de entrar)
**Inicial:** (Estado después de Test 4)
- Dinero: 100€
- En_La_Calle: false
- Ultima_Fecha_Alquiler: Minuto_Actual (ej: 100)

**Acción:** Esperar 7 días

**Esperado:**
- Dinero: ??? (no hay dinero suficiente para cobrar)
- En_La_Calle: true (va automáticamente a la calle)
- Ultima_Fecha_Alquiler: -1

**Validación:** ✓ Correcto - Variante de Test 3

---

## Edge Cases Identificados

### 1. Save/Load en la calle
- Al cargar un save donde estás en la calle:
  - `En_La_Calle = true`
  - `Ultima_Fecha_Alquiler = -1`
  - No hay timer activo ✓

### 2. Save/Load con timer activo
- Al cargar un save donde estás alquilando:
  - `En_La_Calle = false`
  - `Ultima_Fecha_Alquiler = <minuto anterior>`
  - Timer se reanuda correctamente ✓

### 3. Fallback para saves viejos
- En `Guardar_Variables_Dinamicas.load_game()`:
  ```gdscript
  if not game_data.has("En_La_Calle"):
      En_La_Calle = false
      Ultima_Fecha_Alquiler = Minute_Day * 1440 + Minute_Minute
  ```
  - Los saves antiguos se asumen como "en alquiler" con 7 días de gracia ✓

### 4. Necesidades capadas a 20
- Cuando `En_La_Calle = true` O `Dinero < 0`:
  - Necesidades nunca suben de 20 ✓
  - El jugador se deteriora rápidamente en la calle

---

## Conclusión

La implementación es **robusta y correcta**:
- ✓ No permite dinero negativo
- ✓ Timer basado en minutos absolutos (preciso)
- ✓ Transición suave alquiler ↔ calle
- ✓ Compatible con save/load
- ✓ Fallback para saves viejos
- ✓ Necesidades caen rápidamente en la calle (mecánica de presión)
# Invertir en Bolsa

Sistema de inversión **pasiva** con cartera, eventos de mercado, historial y estadísticas. La lógica vive en el autoload `Sistema_Bolsa` (`Scripts/Logica/Escena_Principal/Economia/Sistema_Bolsa.gd`); la UI es una pantalla completa con pestañas **Resumen / Evolución / Estadísticas** (`Scripts/GUI/Escena_Principal/Bolsa/Panel_Bolsa.gd` + `Grafico_Bolsa.gd`).

## Funciones principales

- **Aportar**: abre o amplía la posición. `Dinero_Invertido` es el coste base y el snapshot de salud mental solo se captura al abrir una posición nueva.
- **Retirar**: permite retiradas parciales o el cierre total. El coste base se libera de forma proporcional y el beneficio se materializa.
- **Beneficio acumulado**: `Inversion_Beneficio_Realizado + (Valor_Inversion - Dinero_Invertido)`. El gráfico no baja artificialmente al aportar o retirar.
- **Eventos**: 1/480 por minuto invertido. `prob_subida = clamp(0.15 + ((nivel-1)/99)*0.70 + (mental-50)/300 + tendencia*0.05, 0.05, 0.95)`. La tendencia es un paseo aleatorio con reversión (`t*0.90 + randfn(0,0.20)`, ±1). Movimiento normal 0,5–3,0 %; shock (6 %) 3,0–6,5 % con titulares.
- **Auto-venta por pánico**: `Sangre_Fría < 30` y pérdida > 15 % → venta total, `Inversion_Panicos += 1` y mensaje en el perfil.
- **Nivel inversor**: +1 con probabilidad 1/20 por evento y +1 al cerrar una posición completa en positivo (máx. 100). Corregida su carga desde el guardado.
- **Historial**: puntos `{minuto, beneficio, valor, invertido}` tras eventos/operaciones; máximo 600 con compactación. `Inversion_Operaciones` guarda 40 operaciones y `Inversion_Eventos` 30 titulares.
- **Estadísticas**: aportado, retirado, beneficio total, rentabilidad, tasa de acierto, mejor/peor operación, tiempo invertido, eventos (subidas/bajadas), rachas y máxima caída.
- **UI**: gráfico verde/rojo con línea de cero, marcadores de aportes/retiradas/pánico, periodos 1/5/10 años/Todo; diálogo de cantidad con 25/50/75/Todo y validación. Sin comisiones en la inversión pasiva.

## Persistencia

Se añaden las claves `Inversion_*` a `Guardar_Variables_Dinamicas.game_data_func()` y se sanean al cargar con `Sistema_Bolsa.Asegurar_Estado()`. Los saves antiguos sin claves cargan con valores por defecto; si tenían una posición activa se rellena el coste base y se siembra el primer punto del historial.

## Tests y documentación

- Tests GUT: `Funcionalidades/Economia/Invertir_En_Bolsa/Tests/test_sistema_bolsa.gd` (19 tests).
- Documentación completa: `Funcionalidades/Economia/Invertir_En_Bolsa/Documentacion/INVERTIR.md`.
- El minijuego activo de trading sigue pendiente; la inversión pasiva se mantiene como modo cómodo.

# Sistema de Objetos/Muebles

## Descripción
Tienda de muebles con **36 objetos repartidos en 6 categorías** (`Dormir`, `Comer`, `Duchar`, `Salón`, `Estudio`, `Cocina`). Cada categoría actúa como una ranura exclusiva: el Sim equipa un mueble por categoría y ese mueble aplica un multiplicador a una necesidad básica o un bonus pasivo de progreso/calidad.

## Estructura

### Clases
```
Scripts/Logica/Escena_Principal/Economia/
├── Catalogo_Tienda.gd          ← datos de las 6 categorías y los 36 muebles
├── Herencia/
│   ├── Objeto.gd               ← precio, multiplicador, tier, efecto y bonus
│   ├── Objeto_Dormir.gd
│   ├── Objeto_Comer.gd
│   ├── Objeto_Duchar.gd
│   └── Objeto_Ropa.gd          ← ropa equipable del Vestuario
```

### Variables
**Variables_Estaticas:**
```gdscript
var Catalogo_Objetos: Dictionary  # Materializado desde Catalogo_Tienda.DATOS + Ropa_Catalogo.DATOS
```

**Variables_Dinamicas:**
```gdscript
var Objetos_Poseidos: Dictionary = { "Cama_Basica": true, ... }
var Objeto_Seleccionado: Dictionary = {
    "Dormir": "Cama_Basica",
    "Comer": "Mesa_Basica",
    "Duchar": "Ducha_Basica",
    "Salon": "Sofa_Basico",
    "Estudio": "Escritorio_Basico",
    "Cocina": "Cocina_Basica",
    "Ropa": "Ropa_Calle"
}
```
`Variables_Estaticas.Asegurar_Objetos_Basicos()` entrega automáticamente los básicos gratuitos de cada categoría en partidas nuevas y en saves antiguos.

## Flujos

### Compra
`Actividades.Comprar_Objeto(clave)` valida existencia, no posesión y saldo suficiente → descuenta precio y marca `Objetos_Poseidos[clave] = true`.

### Venta
`Actividades.Vender_Objeto(clave)` valida posesión, que no sea el único de su categoría y que no esté seleccionado → devuelve `precio * 0.5`.

### Selección
`Actividades.Seleccionar_Objeto(categoria, clave)` valida posesión y categoría → actualiza `Objeto_Seleccionado[categoria]`.

## Lógica de Multiplicadores y Bonificaciones

En `Actividades_Necesidades_Basicas.gd`:

```gdscript
const _CATEGORIA_POR_ACTIVIDAD := {
    "Dormir": "Dormir",
    "Duchar": "Duchar",
    "Comer_Tupper": "Comer",
    "Comer_Basura": "Comer",
    "Ver_La_Television": "Salon",
}

func _Obtener_Multiplicador(nombre_actividad: String) -> float:
    var categoria: String = str(_CATEGORIA_POR_ACTIVIDAD.get(nombre_actividad, ""))
    if categoria == "":
        return 1.0
    return Variables_Estaticas.Obtener_Multiplicador_Objeto(categoria)
```

El multiplicador aplica **solo a efectos positivos** (`if por_cuanto > 0 and multiplicador != 1.0: valor_maximo = max(1, floor(valor_maximo / multiplicador))`).
Los muebles de **Estudio** aportan `bonus_progreso` en `Actividades_Habilidades.Ejecutar_Actividad_Progreso()` (Académico y Manualidades) y los de **Cocina** aceleran `Calcular_Max_Progreso_Cocina()` y mejoran la calidad base de `Alimentacion.Crear_Tupper()`.

## Guardado y Restricciones

- `Guardar_Variables_Dinamicas.gd` guarda `Objetos_Poseidos` y `Objeto_Seleccionado`; al cargar, llama a `Asegurar_Objetos_Basicos()` y `Sistema_Cocina.Asegurar_Prendas_Iniciales()`.
- **Obligatoriedad:** siempre hay al menos un objeto seleccionado por categoría.
- **Venta:** no se puede vender si es el único de su categoría ni si está actualmente seleccionado. Reventa = `50%` del precio original.

## Catálogo Implementado (36 muebles)

6 categorías × 6 muebles, definidos en `Catalogo_Tienda.DATOS`:

| Categoría | Básico | Gama alta | Efecto |
|---|---|---|---|
| **Dormir** | `Cama_Basica` 0 € | `Cama_Imperial` 1.800 € (×1.15) | Descanso de `Dormir` |
| **Comer** | `Mesa_Basica` 0 € | `Mesa_Chef` 1.500 € (×1.15) | Hambre de tupper/comida rápida |
| **Duchar** | `Ducha_Basica` 0 € | `Cabina_Spa` 1.750 € (×1.15) | Higiene de `Duchar` |
| **Salón** | `Sofa_Basico` 0 € | `Sofa_Imperial` 1.900 € (×1.16) | Salud mental de `Ver_La_Television` |
| **Estudio** | `Escritorio_Basico` 0 € | `Biblioteca_Roble` 1.700 € (+14 % Académico, +5 % Manualidades) | Progreso de habilidades |
| **Cocina** | `Cocina_Basica` 0 € | `Cocina_Industrial` 2.100 € (+14 % Cocina, +12 % Tupper) | Progreso culinario y calidad |

Cada categoría tiene 6 niveles: básico, básico mejorado, premium, premium
superior, lujo y élite. La lista completa con precios, multiplicadores y textos
de efecto está en `Funcionalidades/Economia/Sistema_Objetos_Muebles/Documentacion/SISTEMA_OBJETOS.md`.

## Testing

Ubicación: `Funcionalidades/Economia/Sistema_Objetos_Muebles/Tests/test_tienda_objetos.gd`

Cubre:
- [x] Integridad del catálogo (6 × 6) y básicos gratis.
- [x] `Asegurar_Objetos_Basicos()` para partidas nuevas y antiguas.
- [x] Compra, equipado y venta (único y seleccionado).
- [x] Multiplicadores de Dormir, Comer y Salón.
- [x] Bonus de Estudio y Cocina.
- [x] Calidad del tupper según la cocina equipada.

## Cómo Expandir el Catálogo

### Añadir un nuevo mueble

```gdscript
# En Catalogo_Tienda.DATOS
{
    "clave": "Cama_Super_Premium",
    "nombre": "Cama Súper Premium",
    "categoria": "Dormir",
    "precio": 2500.0,
    "multiplicador": 1.20,
    "tier": "elite",
    "efecto": "×1.20 Descanso (+20%)",
    "descripcion": "Cama soñada por encima de cualquier lujo.",
}
```

Después:
1. Guarda `Cama_Super_Premium.jpg` (magenta) o `.png` (alfa) en
   `Arte_Fuente/Tienda/Fuente/`.
2. Ejecuta `python3 tools/procesar_iconos_tienda.py`.
3. La tarjeta aparece automáticamente; no hay que tocar la escena ni añadir
   conexiones en `Script_Principal`.

### Crear una categoría nueva

Añade un diccionario a `Catalogo_Tienda.CATEGORIAS` con `id`, `nombre`, `icono`
Lucide, `color`, `fondo` y `basico`, y registra sus muebles en `DATOS`. Si la
categoría mejora una actividad, añádela al mapa `_CATEGORIA_POR_ACTIVIDAD` de
`Actividades_Necesidades_Basicas.gd`; si aporta progreso, usa los campos
`bonus_progreso_*` y las funciones de `Variables_Estaticas`.

## UI de la Tienda

### Catálogo y estructura

`Catalogo_Tienda.DATOS` define **36 muebles en 6 categorías** (6 por categoría):
Dormir, Comer, Duchar, Salón, Estudio y Cocina. Cada categoría es una ranura
exclusiva (un mueble equipado por categoría). `Asegurar_Objetos_Basicos()`
entrega el básico de cada ranura al empezar y a los saves antiguos.

```
Tienda (Control, Tienda_Objetos.gd)
├── Fondo_Seccion
├── Flecha_Atras
├── Titulo
├── Categorias_Scroll/Categorias
│   └── Tab_Dormir · Tab_Comer · Tab_Duchar · Tab_Salon · Tab_Estudio · Tab_Cocina · Tab_Ventajas
├── Contenido_Scroll/Margen_Objetos/Rejilla_Objetos
│   └── 36 tarjetas Panel generadas desde Catalogo_Tienda.DATOS
└── Objetos_Ventajas (Tienda_Bienestar.gd)
```

Cada tarjeta (332×390) contiene:
- `Imagen_Placeholder` con fondo tintado por categoría e `Icono_Item`
  (`TextureRect`) con el PNG 512×512 del mueble.
- `Tier_Pill` BÁSICO/PREMIUM/LUJO/ÉLITE.
- `Nombre`, `Precio`, `Multiplicador` (efecto) y estado (`En uso`/`En propiedad`/`Te faltan N €`).
- `Comprar`, `Elegir` y `Vender`, visibles según el estado.
- Un toast confirma compras, ventas, equipado y errores de dinero.

### Reglas de visibilidad

| Botón | Visible cuando |
|---|---|
| `Comprar` | No poseído |
| `Elegir` (Equipar) | Poseído y no seleccionado |
| `Vender` | Poseído, no seleccionado y existe otro de la categoría |
| `En uso` | Seleccionado |

### Ilustraciones

- **Originales:** JPG con fondo magenta o PNG recortado en
  `Arte_Fuente/Tienda/Fuente/`. Las nuevas tandas se generan como láminas 2×2
  (`Lamina_Salon.png`, `Lamina_Comer_1.png`, …) y se cortan con
  `python3 tools/cortar_sprites.py <lamina> Arte_Fuente/Tienda/Fuente --grid 2x2 --names ...`.
- **Runtime:** PNG 512×512 con alfa en `Imagenes/Tienda/Iconos/<clave>.png`
  (36 ilustraciones).
- **Pipeline:** `python3 tools/procesar_iconos_tienda.py --preview preview.png`
  acepta JPG magenta (recorte por croma) y PNG con alfa, limpia motas, recorta
  al contenido y centra con 5 % de margen.
- **Carga:** `Estilos_UI.icono_tienda(clave)` resuelve la ruta automáticamente
  (`res://Imagenes/Tienda/Iconos/<clave>.png`) y cachea; si falta, usa un icono
  Lucide de respaldo.

### Navegación

- `Gestionar_Visibilidad.Visibilizar_Tienda()` muestra la tienda y abre Dormir.
- `Mostrar_Categoria_Tienda()` delega en `Tienda_Objetos.Abrir_Categoria()`.
- La tienda ya no es una pestaña de la barra superior: `Tienda_Button` sigue en
  la escena solo por compatibilidad y `_Redisenar_Superior()` /
  `Visibilizar_Lo_Basico()` lo mantienen oculto. El único acceso es el icono
  `Boton_Tienda_Header` (x=460), junto al chip del dinero, que llama a
  `_on_tienda_tab_pressed()`. Su flecha vuelve al inicio; desde Necesidades
  regresa a Necesidades.
- `Script_Principal` conserva los wrappers `_on_tab_<categoria>_pressed()` para
  capturas de QA y abre/cierra la pantalla.

## Estado Actual

- **Implementado:** 36 muebles, 6 categorías, rejilla desplazable, compra/venta/
  equipado, multiplicadores en Dormir/Duchar/Comer/Salón, bonus de progreso de
  Estudio, bonus de Cocina y calidad de tupper, migración de saves, toasts y 36
  ilustraciones 2.5D. Tests en
  `Funcionalidades/Economia/Sistema_Objetos_Muebles/Tests/test_tienda_objetos.gd`.
- **Planeado:** efectos negativos (multiplicador < 1.0), más categorías (Deporte,
  Oficina) y filtros/ordenación por precio o efecto.


---

## Bienestar y rejuvenecimiento (Tienda → Bienestar)

La tienda incorpora una cuarta pestaña, **Bienestar**, que sustituye al antiguo
prototipo de monetización. No hay gemas, Pase VIP, moneda premium ni pasarela de
pago. Solo hay dos fuentes de contenido:

1. **Anuncios recompensados simulados** con espera entre uno y otro.
2. **Servicios pagados con euros del juego**: cuidado exprés y tratamientos que
   restan años reales al Sim.

### Archivos

- `Scripts/Globales/Recompensas.gd` (autoload): anuncios, servicios, tokens,
  recompensas, esperas, historial y señales.
- `Scripts/Globales/Recompensas/Recompensas_Catalogo.gd`: catálogo y
  creatividades.
- `Proveedor_Anuncios.gd` / `Proveedor_Simulado_Anuncios.gd`: interfaz y
  adaptador de la red falsa.
- `Scripts/GUI/Tienda/Tienda_Bienestar.gd`, `Modal_Tratamiento.gd`,
  `Modal_Anuncio_Bienestar.gd` y `Visual_Bienestar.gd`.
- `Tienda.tscn`: `Tab_Ventajas` y `Objetos_Ventajas`.
- Tests: `Funcionalidades/Bienestar/Tests/test_bienestar.gd`.
- Doc: `Funcionalidades/Bienestar/Documentacion/BIENESTAR.md`.

### Catálogo

| Anuncio | Duración | Espera | Recompensa |
|---|---|---|---|
| Bono de 150 € | 5 s | 30 min | +150 € |
| Recarga de bienestar | 6 s | 10 min | +30 a cada necesidad |
| Cesta caliente | 6 s | 15 min | 2 tuppers al 100 % |
| Spa express | 8 s | 60 min | −1 año |

| Servicio | Precio base | Recompensa |
|---|---|---|
| Spa revitalizante | 400 € | −1 año |
| Clínica regenerativa | 1.100 € | −3 años |
| Cápsula del tiempo | 2.200 € | −5 años |
| Día de spa | 120 € | Necesidades al 100 % |
| Cesta gourmet | 90 € | 3 tuppers al 100 % |

Los tratamientos de rejuvenecimiento suben de precio con cada sesión:
`coste = base + incremento × Tratamientos_Rejuvenecimiento`. El contador es
global y se guarda con la partida.

### Rejuvenecimiento

`Variables_Estaticas.Calcular_Edad()` resta `Rejuvenecimiento_Anios` a la edad
natural y aplica un suelo de 18 años. El cambio afecta a todos los retratos de
`Personaje_Visual`, al HUD de Inicio, a la carrera de futbolista y a cualquier
sistema que consulte la edad. `First_Time_Function()` pone el contador a cero
en una partida nueva y `Guardar_Variables_Dinamicas.gd` lo persiste.

### Flujo y arquitectura

1. La UI lee anuncios y servicios de `Recompensas_Catalogo`.
2. `Solicitar_Anuncio` valida proveedor, espera y edad, y emite un token de un
   solo uso. `Completar_Anuncio` lo invalida antes de verificar para evitar
   dobles cobros.
3. `Comprar_Servicio` vuelve a validar dinero y edad mínima, descuenta euros,
   aplica la recompensa y registra el historial.
4. `Script_Principal._On_Recompensa_Bienestar()` repinta dinero, necesidades,
   Home y tarjetas de la tienda.
5. Las esperas y el historial se guardan en `user://recompensas.cfg`, fuera de
   la partida. El dinero, necesidades, tuppers y años se guardan con la partida.

La UI muestra la edad actual, un medidor de 18 a 100 con marca fantasma de la
edad sin tratamientos, tarjetas de servicios, cuidado exprés, anuncios con
barra de espera y pie con reinicio de esperas. Se adapta a `720×1280` y a
pantallas altas (`720×1600`).

### Integración futura

Sustituir `Proveedor_Simulado_Anuncios` por un adaptador real (AdMob u otro).
Antes de publicar: consentimiento (GDPR/UMP), protección de menores, SSV de
anuncios y pruebas de políticas. No hay pagos ni compras integradas; si se
añaden en el futuro deben validarse en servidor y no reutilizar este catálogo.
