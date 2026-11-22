# Rediseño de interfaz — inspirado en BitLife, con identidad propia

## Referencia y diferenciación

La estructura se inspira en BitLife: menú con tarjeta de perfil y barras, cabecera de marca,
tarjetas de estadísticas y navegación inferior clara. **No es un clon**: se han cambiado la
paleta, las tipografías, la forma de las tarjetas, los botones y la composición del menú.

### Paleta propia "Midnight Bloom"

| Uso | Color |
|---|---|
| Fondo marfil | `#F4EFE7` |
| Lavanda de perfil | `#EAE3F3` |
| Índigo de cabecera/footer | `#2D2342` |
| Tinta | `#221E33` |
| Coral de acción | `#E4572E` |
| Ámbar | `#F2B84B` |
| Verde azulado | `#2A9D8F` |
| Rosa de alerta | `#B23A48` |
| Borde suave | `#DDD5C7` |
| Pista de barras | `#E6E0D6` |

- **Tipografías:** Bricolage Grotesque para logotipo y títulos; Manrope para texto y botones.
- **Formas:** tarjetas de 14 px de radio, borde suave de 1 px y sombra muy ligera;
  botones coral redondeados, sin el óvalo verde de BitLife.
- **Navegación:** barra inferior marfil con pestaña activa coral (no navy con botón verde central).
- **Menú:** fondo índigo con puntos, tarjeta clara, botón coral, banda coral/ámbar/verde y lema
  “VIVE A TU MANERA”. Sin franja arcoíris ni logotipo amarillo.
- **Marca:** hoja verde azulado en lugar de la estrella roja.
- **Barras:** verde azulado/ámbar/rosa según el valor, con porcentaje a la derecha.

## Pantallas rediseñadas

- Menú principal.
- Inicio con perfil, necesidades, accesos rápidos, carrera y mensajes.
- Habilidades, Progreso y Necesidades.
- Actividades, calendario semanal y selección de horario.
  - Cabecera de días alineada con las columnas.
  - Etiquetas de hora a la derecha y filas de 30 minutos coincidentes con la rejilla.
  - Título «Horario semanal», subtítulo con el número de semana, leyenda Libre/Ocupado/Pasado,
    día actual resaltado en coral y selector Anterior / S19 / Siguiente.
  - Botón inferior «Volver a la semana actual», siempre visible: activo al consultar otra
    semana y en gris («Estás en la semana actual») cuando ya se está en la del Sim. El atajo
    superior «Ir a hoy» se mantiene.
  - La vista empieza siempre en las 00:00 y se desplaza verticalmente para ver el día completo.
- Perfil (mensajes, información e inventario).
- Tienda, Carrera y Economía.
- Lector de apuntes y diálogos.

## Cambios técnicos

- `Scripts/GUI/Escena_Principal/Estilos_UI.gd`: paleta, fuentes, tarjetas, barras, botones,
  animaciones y estilizado de diálogos.
- `Escenas/Menu/Menu.tscn` + `Scripts/Globales/Menu.gd`: menú reconstruido.
- `Scripts/Globales/Script_Principal.gd`: cabecera índigo, navegación blanca, barra inferior
  marfil, Home, paneles, perfil, tienda, carrera, economía y calendario.
- `Scripts/GUI/Escena_Principal/Necesidades_Basicas/Necesidades_Basicas_GUI.gd`: barras por valor.
- `Scripts/GUI/Escena_Principal/Actividades/...`: calendario con verde azulado/rosa.
- `Scripts/GUI/Escena_Principal/Lector_Libro.gd`: portada índigo con detalles ámbar.
- `UI/Tema_Principal.tres`: fuente base Manrope.
- `Fuentes/UI`, `Imagenes/UI`, `icon.svg`: fuentes libres, iconos Lucide, fondos marfil/índigo
  e icono de app con hoja.

## Guardado

Se mantiene `application/config/name="Sims"` para conservar la ruta `user://` y la partida
en `~/.local/share/godot/app_userdata/Sims/guardado`.

## Cómo revertir

Los cambios están sin commitear. Revisar con `git diff` / `git status`.
Copia previa al rediseño:
`/tmp/opencode/backup/sims-0.33-pre-redesign-20261117-135138.tar.gz` (temporal).
