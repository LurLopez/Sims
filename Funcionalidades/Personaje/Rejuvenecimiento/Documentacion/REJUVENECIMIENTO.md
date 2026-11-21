# Rejuvenecimiento del Sim

Sistema de longevidad de `Tienda → Bienestar`: los tratamientos de la clínica
restan años reales a la edad efectiva del Sim. No es una moneda ni un estado
temporal: el cambio es permanente y se guarda con la partida.

## Modelo de edad

`Variables_Estaticas.Calcular_Edad()` calcula primero la edad natural a partir
del reloj de la partida y después resta los años comprados:

```gdscript
edad_natural = 18 + int((Minute_Day - First_Time_Minute_Day) / Dias_Por_Anio())
edad_efectiva = max(18, edad_natural - Variables_Dinamicas.Rejuvenecimiento_Anios)
```

- **Suelo:** 18 años. No se puede rejuvenecer por debajo.
- **Persistencia:** `Rejuvenecimiento_Anios` y `Tratamientos_Rejuvenecimiento`
  se guardan en `Guardar_Variables_Dinamicas.dat`.
- **Nueva partida:** `First_Time_Function()` pone ambos contadores a cero.
- **Saneado:** al cargar, `Rejuvenecimiento_Anios` se limita a `0..200` y
  `Tratamientos_Rejuvenecimiento` a `>= 0`.

## Efectos

- Todos los retratos de `Personaje_Visual` usan `Calcular_Edad()` y se repintan
  solos cuando la edad pintada cambia: canas, arrugas, postura, etc.
- El HUD de Inicio (`_home_edad`) y el panel de fútbol muestran la edad efectiva.
- `Comprobar_Muerte()` usa la edad efectiva, así que rejuvenecer reduce la
  probabilidad de muerte.
- El requisito de edad de la carrera de futbolista también usa la edad efectiva.

## Tratamientos

| Servicio | Años | Precio base | Incremento por sesión |
|---|---|---|---|
| Spa revitalizante | −1 | 400 € | 150 € |
| Clínica regenerativa | −3 | 1.100 € | 350 € |
| Cápsula del tiempo | −5 | 2.200 € | 700 € |

El precio actual se calcula con:

```
coste = base + incremento × Tratamientos_Rejuvenecimiento
```

El contador es global: cualquier tratamiento de la clínica sube el precio de la
siguiente sesión de todos ellos. Los servicios se pagan con euros del juego;
no hay moneda premium ni compra real.

El anuncio **Spa express** también resta un año, gratis y con una espera de 60
minutos. Si el Sim está en 18 años, tanto los tratamientos como ese anuncio se
bloquean.

## UI

- `Tienda_Bienestar.gd`: héroe de la clínica con edad actual, medidor de 18 a
  100, marca fantasma de la edad sin tratamientos y listado de tratamientos.
- `Modal_Tratamiento.gd`: confirmación con el antes/después, coste, saldo
  restante y resultado con confeti.
- `Visual_Bienestar.Medidor_Edad`: barra dibujada con el marcador actual y la
  referencia de la edad original.

## Tests

La cobertura vive en `Funcionalidades/Bienestar/Tests/test_bienestar.gd`:

- Un anuncio de juventud resta un año.
- Un servicio de rejuvenecimiento resta los años indicados, cobra y sube el
  precio de la siguiente sesión.
- El suelo de 18 años bloquea la compra.
- La UI muestra el antes/después y el éxito.

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir=res://Funcionalidades/Bienestar/Tests -gexit
```

## Documentación relacionada

- `Funcionalidades/Bienestar/Documentacion/BIENESTAR.md` — anuncios, servicios,
  catálogo y arquitectura completa.
- `Funcionalidades/Personaje/Envejecimiento/Documentacion/ENVEJECIMIENTO.md` —
  curvas visuales de edad.
