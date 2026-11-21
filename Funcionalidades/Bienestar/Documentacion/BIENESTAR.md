# Bienestar y rejuvenecimiento

> Tienda → **Bienestar**. Sustituye por completo al antiguo prototipo de
> monetización (Pase VIP, gemas y pasarela de pago simulada).

## Resumen

La pestaña **Bienestar** agrupa dos cosas, siempre conectadas con la partida:

1. **Anuncios recompensados simulados** con espera entre uno y otro.
2. **Servicios de bienestar pagados con euros del juego**: cuidado exprés y
   tratamientos de rejuvenecimiento que restan años reales al Sim.

No hay moneda premium, ni pagos reales, ni SDKs. El diseño busca que la tienda
sea una herramienta de partida (dinero, necesidades, comida y longevidad), no
una pantalla de compras.

## Archivos

| Archivo | Responsabilidad |
|---|---|
| `Scripts/Globales/Recompensas.gd` | Autoload: valida anuncios y servicios, aplica recompensas, persiste esperas e historial |
| `Scripts/Globales/Recompensas/Recompensas_Catalogo.gd` | Catálogo único de anuncios, servicios, precios, creatividades y textos |
| `Scripts/Globales/Recompensas/Proveedor_Anuncios.gd` | Interfaz base de la red de anuncios |
| `Scripts/Globales/Recompensas/Proveedor_Simulado_Anuncios.gd` | Red simulada con latencia y fallo forzable |
| `Scripts/GUI/Tienda/Tienda_Bienestar.gd` | Pestaña: estado, héroe de edad, tratamientos, cuidado y anuncios |
| `Scripts/GUI/Tienda/Modal_Tratamiento.gd` | Confirmación antes/después y resultado de un servicio |
| `Scripts/GUI/Tienda/Modal_Anuncio_Bienestar.gd` | Reproducción del anuncio, verificación y recompensa |
| `Scripts/GUI/Tienda/Visual_Bienestar.gd` | Fondo del héroe, medidor de edad, fondo de creatividades y confeti |
| `Funcionalidades/Bienestar/Tests/test_bienestar.gd` | 20 tests de catálogo, dominio, persistencia y UI |

## Catálogo

### Anuncios

| ID | Recompensa | Duración | Espera |
|---|---|---|---|
| `anuncio_dinero` | `+150 €` | 5 s | 30 min |
| `anuncio_bienestar` | `+30` a cada necesidad | 6 s | 10 min |
| `anuncio_comida` | 2 tuppers al 100 % | 6 s | 15 min |
| `anuncio_juventud` | `−1 año` | 8 s | 60 min |

Los anuncios son gratuitos. La espera es real (reloj del dispositivo) y se
guarda en `user://recompensas.cfg`, así que sobrevive al cierre de la app.

### Servicios

| ID | Grupo | Precio base | Recompensa |
|---|---|---|---|
| `servicio_spa` | rejuvenecimiento | 400 € | `−1 año` |
| `servicio_clinica` | rejuvenecimiento | 1.100 € | `−3 años` |
| `servicio_capsula` | rejuvenecimiento | 2.200 € | `−5 años` |
| `servicio_bienestar` | cuidado | 120 € | Necesidades al 100 % |
| `servicio_cesta` | cuidado | 90 € | 3 tuppers gourmet |

Los tres tratamientos de rejuvenecimiento suben de precio con cada sesión:

```
coste = base + incremento_por_uso × Tratamientos_Rejuvenecimiento
```

El incremento es propio de cada tratamiento (150 € el spa, 350 € la clínica y
700 € la cápsula). El contador es global: cualquier tratamiento comprado sube
el precio de la siguiente sesión de todos ellos. Los servicios de cuidado
mantienen tarifa fija (`coste_incremento = 0`).

## Flujo de un anuncio

1. La UI llama `Recompensas.Solicitar_Anuncio(id)`. El dominio comprueba que el
   anuncio existe, que no hay otro en curso, que el proveedor está disponible,
   que la espera ha terminado y que el Sim no está ya en 18 años si el anuncio
   rejuvenece.
2. Si todo está bien, devuelve un **token** y emite `anuncio_autorizado`.
3. `Modal_Anuncio_Bienestar` reproduce la creatividad durante la duración del
   catálogo. Al terminar emite `visto(token)`; si se cierra antes, emite
   `cancelado(token)` y no se concede nada.
4. La tienda llama `Recompensas.Completar_Anuncio(token)`. El dominio invalida
   el token, pide confirmación al proveedor, aplica la recompensa, arranca la
   espera y emite `anuncio_completado` + `estado_cambiado`.
5. La UI repinta saldo, edad, necesidades, tuppers y tarjetas de anuncio.

## Flujo de un servicio

1. La UI comprueba que hay dinero suficiente y que el Sim puede rejuvenecer.
2. `Modal_Tratamiento` muestra el antes/después, el coste y el saldo restante.
3. Al confirmar, la tienda llama `Recompensas.Comprar_Servicio(id)`.
4. El dominio vuelve a validar dinero y edad, descuenta los euros, aplica la
   recompensa, suma un tratamiento si corresponde y guarda el historial.
5. La UI muestra el resultado con confeti y refresca toda la pantalla.

## Rejuvenecimiento

La edad efectiva vive en `Variables_Estaticas.Calcular_Edad()`:

```gdscript
edad_natural = 18 + int((Minute_Day - First_Time_Minute_Day) / Dias_Por_Anio())
edad_efectiva = max(18, edad_natural - Variables_Dinamicas.Rejuvenecimiento_Anios)
```

- `Rejuvenecimiento_Anios` acumula los años restados y se guarda con la partida.
- `Tratamientos_Rejuvenecimiento` cuenta las sesiones compradas y escala el precio.
- El suelo es **18 años**: no se puede rejuvenecer por debajo.
- El cambio afecta automáticamente a todos los retratos de `Personaje_Visual`,
  al HUD de Inicio, a la carrera de futbolista y a cualquier sistema que use
  `Calcular_Edad()`.
- El héroe de la pestaña muestra la edad actual, una marca fantasma de la edad
  sin tratamientos y el texto `−N años recuperados`.
- Los retratos se repintan solos porque `Personaje_Visual` compara la edad
  pintada con `Calcular_Edad()`.

### Guardado

`Guardar_Variables_Dinamicas.gd` guarda y carga:

- `Rejuvenecimiento_Anios` (0–200 al cargar, saneado).
- `Tratamientos_Rejuvenecimiento` (mínimo 0).

`First_Time_Function()` los pone a cero al empezar una partida nueva.

## Persistencia

`Recompensas` guarda en `user://recompensas.cfg`:

- `estado/cooldowns`: `{anuncio_id: unix_segundos_hasta}`.
- `estado/historial`: últimas 20 operaciones (tipo, título, detalle, importe y fecha).

El dinero, las necesidades, los tuppers y los años de rejuvenecimiento **no**
se guardan aquí: viven en `Variables_Dinamicas` y se guardan con la partida.

## UI

- **Barra de estado:** edad del Sim y dinero disponible.
- **Héroe de la clínica:** edad actual, medidor de 18 a 100 con marca fantasma,
  años recuperados y aviso de precio creciente.
- **Rejuvenecimiento:** tres tarjetas con precio, estado y botón Reservar.
- **Cuidado exprés:** dos tarjetas compactas pagadas con euros.
- **Anuncios:** cuatro tarjetas con recompensa, duración, espera y barra de
  progreso. Cuando el Sim tiene 18 años, el anuncio de juventud muestra
  «Al máximo».
- **Pie:** aviso de simulación, proveedor de anuncios y botón para reiniciar
  las esperas (no toca la partida).
- **Modales:** `Modal_Tratamiento` (confirmación + éxito con confeti) y
  `Modal_Anuncio_Bienestar` (cuenta atrás + recompensa).

Todo se adapta a `720×1280` y pantallas altas (`720×1600`) mediante el scroll
de la pestaña; no hay posiciones fijas a `y=1280`.

## Añadir contenido

### Un anuncio nuevo

Añade una entrada a `Recompensas_Catalogo.PRODUCTOS` con:

```gdscript
"anuncio_mi_nuevo": {
    "id": "anuncio_mi_nuevo",
    "seccion": SECCION_ANUNCIOS,
    "tipo": TIPO_ANUNCIO,
    "orden": 24,
    "titulo": "…",
    "subtitulo": "Anuncio de N segundos",
    "descripcion": "…",
    "recompensa_texto": "…",
    "icono": "sparkles",
    "color": Color("#0d9488"),
    "etiqueta": "ANUNCIO",
    "cooldown_seg": 600,
    "duracion_simulada": 5.0,
    "creativo": "spa",
    "recompensas": [{"tipo": "euros", "cantidad": 100}],
},
```

La pestaña lo recoge sola. Si usas una creatividad nueva, añádela a
`Recompensas_Catalogo.CREATIVOS`.

### Un servicio nuevo

Añade una entrada a `SECCION_SERVICIOS` con `grupo`
`GRUPO_REJUVENECIMIENTO` o `GRUPO_CUIDADO`, `coste_euros` y
`coste_incremento` (0 si no escala). La tarjeta se genera automáticamente.

### Una recompensa de tipo nuevo

Añade una rama al `match` de `Recompensas._Aplicar_Recompensas()` y su test en
`Funcionalidades/Bienestar/Tests/test_bienestar.gd`.

## Tests

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir=res://Funcionalidades/Bienestar/Tests -gexit
```

Cubren catálogo, recompensas, anuncios, cancelación, token inválido,
servicios, dinero insuficiente, suelo de 18 años, persistencia, construcción
de la UI y los dos flujos completos (tratamiento y anuncio).

## QA visual

```bash
# Pestaña completa en 720×1280
godot --path . --resolution 540x960 \
  res://Escenas/Herramientas/Captura_Bienestar.tscn

# Pantalla alta 720×1600
godot --path . --resolution 540x960 \
  res://Escenas/Herramientas/Captura_Bienestar_Alta.tscn
```

Las capturas se guardan en `user://capturas_bienestar/`.

## Producción

Los anuncios siguen siendo simulados. Para integrar una red real, implementa
`Proveedor_Anuncios` (cargar, mostrar, verificar SSV, consentimiento) y
regístralo con:

```gdscript
Recompensas.Configurar_Proveedor_Anuncios(Mi_Proveedor_AdMob.new())
```

No hay pasarela de pago ni moneda premium: si en el futuro se añade una compra
real, debe hacerse con un proveedor validado en servidor y **no** reutilizar
este catálogo de anuncios.

## Documentación relacionada

- `Funcionalidades/Personaje/Rejuvenecimiento/Documentacion/REJUVENECIMIENTO.md` — modelo de edad, efectos y tratamientos.
- `Funcionalidades/Personaje/Envejecimiento/Documentacion/ENVEJECIMIENTO.md` — curvas visuales de canas, arrugas y postura.
