# Prompt de Implementación — Minijuego Extenso de Cocina (*Cooking Fever*, `1280×720` Horizontal) + Apartado Minijuegos + Ropa Equipable

> **Cómo usarlo:** Copia todo el bloque a partir de `PROMPT (pegar desde aquí)` y pégalo en el agente implementador. Esta especificación está verificada contra el código real de `/home/lur/sims-0.33` (Godot 4.4 / GDScript 2.0) e incluye todas las decisiones cerradas.

---

PROMPT (pegar desde aquí)

### Tarea: Implementar Minijuego Extenso de Cocina estilo *Cooking Fever* (`1280×720` Horizontal) + Apartado de Minijuegos + Progresión Hostelería + Ropa Equipable

Actúa como **Game Designer Senior y Arquitecto de Godot 4.4 (GDScript 2.0)** en `/home/lur/sims-0.33` (**SIMS 0.33**). Implementa de principio a fin:
1. El **Apartado de Minijuegos** (`Minijuegos_Button` en la barra superior junto a Perfil/Economía/Horario/Carrera + panel `Pantalla_Minijuegos` preparado para albergar varios minijuegos).
2. El **Minijuego de Cocina estilo *Cooking Fever*** (`Minijuego_Cocina.tscn`) con rotación obligatoria a **horizontal (`1280×720`)** y retorno automático a **vertical (`720×1280`)**, manteniendo el reloj del Sim corriendo con normalidad en segundo plano.
3. El **desbloqueo al primer minuto trabajado** en hostelería (nunca al programar el bloque) con **notificación visual en pantalla + mensaje en el buzón**.
4. La integración con `Progreso_Cocina`, habilidades innatas, necesidades básicas, `Alimentacion.gd` (`Comer_Tupper` / `Comer_Basura`), `Eventos_Aleatorios.gd`, logros progresivos cada 5 niveles y **ropa equipable** en Perfil.

No pidas confirmación interactiva: lee los archivos reales antes de editar, implementa todo, ejecuta los tests GUT y entrega un informe técnico detallado.

---

#### 1. Contexto Obligatorio del Proyecto (Léelo antes de editar)
* `CLAUDE.md` y `project.godot` (autoloads, display, orientación).
* `export_presets.cfg` (permiso `permissions/set_orientation`).
* `Scripts/Globales/Principales_Variables/Variables_Dinamicas.gd` (ya contiene `Progreso_Cocina: int = 1`).
* `Scripts/Globales/Principales_Variables/Variables_Estaticas.gd` (ya contiene `Trabajar_En_Comida_Rapida`, `Trabajar_De_Ayudante_Cocina`, `Trabajar_De_Cocinero_Partida`, `Trabajar_De_Chef_Ejecutivo` y `Catalogo_Objetos`).
* `Scripts/Otro/Guardar/Guardar_Variables_Dinamicas.gd` y `Guardar_Variables_Estaticas.gd`.
* `Scripts/Globales/Menu.gd` (reseteo de variables al iniciar nueva partida).
* `Scripts/Globales/Script_Principal.gd` (barra superior de botones alrededor de línea 2911, `_Actualizar_Nav_Activa()`, Perfil → Info / Apuntes, notificaciones).
* `Scripts/GUI/Escena_Principal/Gestionar_Visibilidad.gd` y `Estilos_UI.gd`.
* `Scripts/Logica/Escena_Principal/Actividades/Actividades.gd` (`Ejecutar_Actividad()`).
* `Scripts/Logica/Escena_Principal/Actividades/Alimentacion.gd` (`Ejecutar_Minuto_Comer_Tupper`, `Ejecutar_Minuto_Comer_Basura`).
* `Scripts/Logica/Escena_Principal/Actividades/Eventos_Aleatorios.gd` (evento `"Intoxicación alimentaria"`).
* `Scripts/Logica/Escena_Principal/Economia/Herencia/Objeto.gd`.
* `Escenas/Escena_Principal/Escena principal.tscn` y `Escenas/Escena_Principal/Pantalla_Mensajes.tscn`.

---

#### 2. Reglas Duras e Inviolables
1. **Godot 4.4 / GDScript 2.0:** Tipado explícito obligatorio en todas las funciones y variables nuevas. Prohibida sintaxis de Godot 3.
2. **No duplicar lo ya existente:**
   * `Variables_Dinamicas.Progreso_Cocina` **ya existe**: reutilizarlo.
   * `Trabajar_De_Ayudante_Cocina`, `Trabajar_De_Cocinero_Partida` y `Trabajar_De_Chef_Ejecutivo` **ya existen** en `Variables_Estaticas.gd`: reutilizarlos (verificar si ya tienen botón en `Escena principal.tscn` antes de añadir).
3. **Rotación Horizontal Obligatoria (`1280×720` ↔ `720×1280`):**
   * Habilitar `permissions/set_orientation=true` en `export_presets.cfg` para que Android permita rotar por código.
   * Al abrir `Minijuego_Cocina`:
     ```gdscript
     DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
     get_window().content_scale_size = Vector2i(1280, 720)
     if OS.has_feature("pc"):
         DisplayServer.window_set_size(Vector2i(1280, 720))
     ```
   * Al salir (y como salvaguarda en `_exit_tree()`):
     ```gdscript
     DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
     get_window().content_scale_size = Vector2i(720, 1280)
     if OS.has_feature("pc"):
         DisplayServer.window_set_size(Vector2i(720, 1280))
     ```
   * Al volver a la escena principal, forzar refresco de layout/viewport (`_Alto_Pantalla()`).
4. **Reloj del Sim en tiempo real:** El reloj de `Script_Principal._process` **sigue corriendo con normalidad** mientras se juega el minijuego (no pausar la simulación del mundo).
5. **Comparación segura de celdas en `Matriz_Jugador`:** Siempre filtrar tipo antes de comparar (`if celda is String and celda == "..."` o `if celda is Actividad_Fija_Trabajo`).
6. **Claves ASCII estables y retrocompatibilidad:** Sin tildes ni espacios en claves de diccionarios/guardado. Fallback seguro en `load_game()` para saves antiguos.
7. **Rendimiento O(1):** Prohibido llamar `save_game()` dentro de `_process`; guardar solo al desbloquear restaurante, finalizar nivel, comprar mejora, equipar ropa o finalizar turno.
8. **Funciones puras para GUT:** Toda la matemática (cocción, quemado, paciencia, propinas, `Modo_Rapido` ×7, recompensas, rangos y bonus de ropa) debe vivir en funciones estáticas/puras en `Sistema_Cocina.gd`.

---

#### 3. Especificación Técnica Detallada

##### 3.1. Datos, Ropa y Persistencia
1. **En `Variables_Dinamicas.gd`:**
   * Añadir helper `Cocina_Estado_Por_Defecto() -> Dictionary` y `var Cocina_Estado: Dictionary = Cocina_Estado_Por_Defecto()`:
     ```gdscript
     {
         "restaurantes_desbloqueados": [], # "burger_street", "bistro_tradicional", "alta_cocina"
         "fondos_cocina": 0,
         "estrellas_nivel": {}, # {"burger_street_1": 3, ...}
         "mejoras": {
             "burger_street": {"plancha": 1, "emplatado": 1, "termostato": 1, "ingredientes": 1, "ambiente": 1},
             "bistro_tradicional": {"plancha": 1, "emplatado": 1, "termostato": 1, "ingredientes": 1, "ambiente": 1},
             "alta_cocina": {"plancha": 1, "emplatado": 1, "termostato": 1, "ingredientes": 1, "ambiente": 1}
         },
         "rango_logro": 0, # 0..9 (sube cada 5 niveles superados con >= 1 estrella)
         "servicios_remunerados_hoy": 0,
         "ultimo_dia_remunerado": -1,
         "plus_nomina_turno_hoy": false
     }
     ```
   * En `Objetos_Poseidos` y `Objeto_Seleccionado`, asegurar `"Ropa_Calle": true` y `Objeto_Seleccionado["Ropa"] = "Ropa_Calle"`.
2. **Nueva clase `Objeto_Ropa.gd`** (`Scripts/Logica/Escena_Principal/Economia/Herencia/Objeto_Ropa.gd`, `extends Objeto`):
   * `@export var bonus_salario_hosteleria: float = 0.0`
   * `@export var reduccion_higiene_trabajo: float = 0.0`
   * `@export var bonus_propinas_minijuego: float = 0.0`
   * `@export var descripcion_efecto: String = ""`
3. **En `Variables_Estaticas.gd`:**
   * Añadir `var Record_Max_Niveles_Cocina: int = 0`.
   * Registrar en `_Inicializar_Catalogo_Objetos()` (`afecta_a = "Ropa"`, `precio = 0.0`, `es_basico = true`):
     * `"Ropa_Calle"`: sin bonus.
     * `"Delantal_Aprendiz"` (5 niveles): `reduccion_higiene_trabajo = 0.05`.
     * `"Chaqueta_Chef"` (15 niveles): `bonus_salario_hosteleria = 0.10`, `reduccion_higiene_trabajo = 0.05`.
     * `"Atuendo_Chef_Gala"` (30 niveles): `bonus_salario_hosteleria = 0.20`, `reduccion_higiene_trabajo = 0.05`.
     * `"Traje_Estrella_Michelin"` (45 niveles): `bonus_salario_hosteleria = 0.30`, `reduccion_higiene_trabajo = 0.05`, `bonus_propinas_minijuego = 0.25`.
4. **Persistencia (`Guardar_Variables_Dinamicas.gd`, `Guardar_Variables_Estaticas.gd`, `Menu.gd`):**
   * Guardar/cargar `Cocina_Estado` (merge recursivo de claves faltantes), `"Ropa_Calle": true` y `Objeto_Seleccionado["Ropa"]` con fallback `"Ropa_Calle"`.
   * Guardar/cargar `Record_Max_Niveles_Cocina` (fallback `0`) en `Guardar_Variables_Estaticas.gd`.
   * Resetear `Cocina_Estado` y `"Ropa"` en `Menu.gd` al iniciar nueva partida.

##### 3.2. Nuevo Autoload `Sistema_Cocina.gd` (`project.godot`)
Crear `Scripts/Logica/Escena_Principal/Minijuego_Cocina/Sistema_Cocina.gd` y registrarlo como autoload `Sistema_Cocina`:
1. **Señal:** `signal restaurante_desbloqueado(restaurante_id: String, nombre_restaurante: String)`.
2. **Desbloqueo en el primer minuto trabajado (CRÍTICO):**
   * Mapeo trabajo → restaurante:
     * `"Trabajar_En_Comida_Rapida"` → `"burger_street"` (*Burger & Street Food*)
     * `"Trabajar_De_Ayudante_Cocina"` / `"Trabajar_De_Cocinero_Partida"` → `"bistro_tradicional"` (*Bistró Tradicional*)
     * `"Trabajar_De_Chef_Ejecutivo"` → `"alta_cocina"` (*Alta Cocina Gourmet*)
   * Función `Registrar_Minuto_Trabajo_Hosteleria(nombre_trabajo: String) -> bool`:
     * Se llama desde `Actividades.Ejecutar_Actividad()` **cuando pasa un minuto real ejecutando ese trabajo** (no al asignarlo en el calendario).
     * Si el restaurante asociado no está en `restaurantes_desbloqueados`, lo añade, guarda partida (`Guardar_Variables_Dinamicas.save_game()`), añade un `Mensaje.new()` al buzón (`Variables_Dinamicas.Mensajes`) avisando del desbloqueo en el apartado **Minijuegos**, y emite `restaurante_desbloqueado` para que la UI muestre la notificación en pantalla.
3. **3 Restaurantes (data-driven):**
   * `burger_street`: `implementado = true`, **15 niveles** completos (60–90 s, objetivos `1★ / 2★ / 3★`, pedidos de 1–3 ítems: *Hamburguesa sola, con queso, completa [lechuga+tomate+queso], doble, patatas fritas, refresco*).
   * `bistro_tradicional` y `alta_cocina`: `implementado = false` (estructura lista para Fase 2, mostrando su estado y trabajo requerido).
4. **5 Mejoras por Restaurante (Nv. 1 → Nv. 3 en `Fondos_Cocina`):**
   * `plancha`: Nv.1 (`2` huecos, `×1.00`) → Nv.2 (`120`, `3` huecos, `×0.80`) → Nv.3 (`320`, `4` huecos, `×0.65`).
   * `emplatado`: Nv.1 (`2` platos, `1` bebida `4.0 s`) → Nv.2 (`100`, `3` platos, `2` bebidas `2.5 s`) → Nv.3 (`280`, `4` platos, `3` bebidas `1.0 s`).
   * `termostato`: Nv.1 (`6.0 s`) → Nv.2 (`90`, `8.1 s`) → Nv.3 (`240`, `10.5 s` + aviso visual temprano).
   * `ingredientes`: Nv.1 (`×1.00`) → Nv.2 (`140`, `×1.25`) → Nv.3 (`360`, `×1.50`).
   * `ambiente`: Nv.1 (`×1.00` paciencia/propinas) → Nv.2 (`110`, `×1.15` paciencia, `×1.20` propinas) → Nv.3 (`300`, `×1.30` paciencia, `×1.40` propinas).
5. **Fórmulas puras:**
   * `Calcular_Tiempo_Coccion(base_seg, nivel_plancha, destreza_innata)` (`Habilidades[2]` reduce hasta `-15%`).
   * `Calcular_Tiempo_Quemado(nivel_termostato, paciencia_innata, tiene_resacon)` (`Habilidades[5]` suma hasta `+15%`; `Resacon` aplica `×0.85`).
   * `Calcular_Velocidad_Paciencia(nivel_ambiente, paciencia_innata, sangre_fria, descanso, salud_mental)` (`Habilidades[5]` y `[6]` reducen desgaste; `descanso < 25` o `salud_mental < 25` aplica `×1.20`).
   * `Esta_En_Turno_Activo(restaurante_id)`: comprueba si la celda actual de `Matriz_Jugador` es `Actividad_Fija_Trabajo` asociada al restaurante.
   * Bloqueos de entrada: `restaurantes_desbloqueados` vacío, `Necesidades_Basicas[3] <= 5`, o examen universitario (P3) activo o en ≤5 min.
6. **Micro-recompensas por cliente y fin de nivel:**
   * Por cliente: `15%` base de `+1` `Progreso_Cocina` (`×2.0` en turno, **`×7.0` en `Modo_Rapido`**), `5%` base de `+1` `Progreso[2]` Manualidades (`×7.0` en `Modo_Rapido`), `12%` de `+1` Salud Mental o Hambre (respetando caps de calle/bancarrota/resacón), `10%` de micro-propina (`2–5 € * Multiplicador_Precios()`, tope `15 € * Multiplicador_Precios()` por partida).
   * Fin de nivel (`Procesar_Fin_Nivel`): calcula `0..3★`, suma `Fondos_Cocina` (`×1.5` en turno), bono 1.ª vez por estrellas (`15/15/20 € * Multiplicador_Precios()`), propinas netas (tope 2 servicios/día en modo libre; ilimitado en turno + marca `plus_nomina_turno_hoy = true`, `+25%` si `"Traje_Estrella_Michelin"`). Actualiza `rango_logro` (cada 5 niveles superados), desbloquea prendas en `Objetos_Poseidos` y envía `Mensaje.new()` al buzón.

##### 3.3. Integración con `Actividades.gd`, `Alimentacion.gd` y `Eventos_Aleatorios.gd`
1. **En `Actividades.gd`:**
   * Al ejecutar un minuto de `Actividad_Fija_Trabajo` de hostelería (y `not es_aleatoria`): llamar a `Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria(actividad.nombre)`.
   * Al pagar el salario al final del turno (`Minute_Minute == actividad.hora_final - 1`) en hostelería: aplicar bonus de salario de `Objeto_Ropa` + `+10%` si `plus_nomina_turno_hoy` (y resetear `plus_nomina_turno_hoy = false`).
   * Al aplicar desgaste de Higiene (`[4]`) en trabajos de hostelería: aplicar la reducción del `5%` si la prenda equipada tiene `reduccion_higiene_trabajo > 0`.
2. **En `Alimentacion.gd` (`Ejecutar_Minuto_Comer_Tupper` y `Ejecutar_Minuto_Comer_Basura`):**
   * **Rango ≥ 2:** `+2` extra en `Salud_Mental` al comer (respetando caps de calle/resacón).
   * **Rango ≥ 4:** `-20%` coste en `Comer_Basura` y `+15%` saciedad en `Comer_Tupper`.
   * **Rango ≥ 5:** `+15%` de eficiencia en `Progreso[2]` (Manualidades) y `Progreso_Cocina`.
   * **Rango ≥ 7:** `Comer_Tupper` / `Comer_Basura` recuperan `Hambre` un `+15%` más rápido y añaden `+1` en `Salud_Fisica`.
3. **En `Eventos_Aleatorios.gd`:**
   * Si `Sistema_Cocina.Obtener_Rango_Logro() >= 8` (40 niveles), excluir `"Intoxicación alimentaria"` del pool de eventos elegibles.

##### 3.4. Apartado de Minijuegos (`Minijuegos_Button` + `Pantalla_Minijuegos`) y Notificación en Pantalla
1. **Barra superior (`Escena principal.tscn`, `Script_Principal.gd`, `Gestionar_Visibilidad.gd`):**
   * Añadir `Minijuegos_Button` junto a `Boton_Perfil`, `Economia_Button`, `Calendario_Button`, `Carrera_Button` (reajustar las 5 posiciones y anchos de la fila en `_Estilizar_Header()` — p. ej. 5 botones de `136 px` con separación de `4 px` dentro de `720 px` — y añadirlo a `Gestionar_Visibilidad.Visibilizar_Lo_Basico()` y `_Actualizar_Nav_Activa()`).
   * Crear la vista `Pantalla_Minijuegos` (diseño modular con tarjetas en `VBoxContainer` dentro de `720×1280` portrait):
     * Muestra la tarjeta de **Cocina (*Cooking Fever*)**:
       * Si está bloqueado: icono de candado + explicación (*"Trabaja al menos 1 minuto en Comida Rápida u hostelería para desbloquearlo"*).
       * Si está desbloqueado: muestra rango de *Maestría Culinaria*, niveles superados, estado `En Turno (+50%)` si aplica, y botón **Jugar** que abre `Minijuego_Cocina.tscn`.
     * Dejar el contenedor preparado para añadir futuros minijuegos (p. ej. Fútbol, Trading).
2. **Notificación en pantalla al desbloquear:**
   * Conectar `Sistema_Cocina.restaurante_desbloqueado` en `Script_Principal.gd` para mostrar un **toast/banner animado no intrusivo** en la parte superior de la pantalla (`"¡Nuevo minijuego desbloqueado: Cocina!"`), además del mensaje en el buzón y badge en `Boton_Perfil` / `Minijuegos_Button`.
3. **Perfil → Info y Ropa (`Pantalla_Mensajes.tscn` y `Script_Principal.gd`):**
   * En **Perfil → Info**: añadir `Cocina: X / 100`, `Atuendo: <Nombre>` y `Maestría Culinaria: Rango X/9`.
   * En **Perfil → Apuntes**: añadir conmutador superior `Apuntes | Ropa`. En `Ropa`, listar prendas de `Objetos_Poseidos` con su efecto y botón `Equipar` / `✓ Equipada`.

##### 3.5. Escena del Minijuego (`Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn` + `Minijuego_Cocina.gd`)
Escena autocontenida en `1280×720` horizontal con estilo procedural limpio (`StyleBoxFlat` e iconos de `Imagenes/UI/Iconos/`):
1. **Subvista 1 — Mapa de Niveles y Mejoras:** barra superior (`Fondos_Cocina`, rango, badge `En Turno`, `Mejoras`, `← Volver al Sim`), selector de 3 restaurantes, mapa de 15 niveles con estrellas `0–3★`, modal de inicio de nivel y modal de las 5 mejoras.
2. **Subvista 2 — Cocina Jugable (`1280×720`, *tap-to-move* a dos pulgares):**
   * HUD superior (reloj del servicio, barra de recaudación con marcas `1★/2★/3★`, combo `x2..x5`, badge `En Turno`).
   * Mostrador con **4 clientes simultáneos** (pedido 1–3 ítems, paciencia verde→amarillo→rojo, monedas+propina al entregar, combo `<2.5 s`, feedback flotante de micro-recompensas).
   * Encimera central: dispensador de refrescos (`1–3` vasos), platos de montaje (`2–4` huecos con capas visuales), plancha (`2–4` huecos) + freidora (`1–2` cestas) con 4 estados (*Cocinando → En su punto → Alerta quemado → Quemado*).
   * Bandeja inferior táctil: `Pan`, `Carne`, `Queso`, `Lechuga`, `Tomate`, `Patatas`, `Papelera`.
3. **Subvista 3 — Modal de Resultados del Servicio:** estrellas, recaudación, `Fondos_Cocina`, `Dinero`, `Progreso_Cocina`, logro/prenda desbloqueada, botones `Siguiente Nivel`, `Repetir`, `Mapa`.

---

#### 4. Tests GUT Obligatorios (`Funcionalidades/Minijuego_Cocina/Tests/test_minijuego_cocina.gd`)
1. Estado por defecto, retrocompatibilidad de saves y categoría `"Ropa"`.
2. Desbloqueo solo tras `Registrar_Minuto_Trabajo_Hosteleria` (y emisión de señal + mensaje en buzón).
3. Economía doble moneda (`Fondos_Cocina` vs `Dinero`), límite de 2 servicios/día en modo libre, tope `15 €` micro-propinas y `Multiplicador_Precios()` (`×0.1` en `Modo_Rapido`).
4. Bonus `Esta_En_Turno_Activo` (`×1.5` dinero/fondos, `×2.0` progreso, `+10%` nómina).
5. `Modo_Rapido`: drops de `Progreso_Cocina` y `Manualidades` multiplicados por `×7.0`.
6. Fórmulas de `Destreza`, `Paciencia`, `Sangre_Fria`, `Descanso < 25`, `Salud_Mental < 25`, `Resacon`, bloqueo `Descanso <= 5`.
7. Logros cada 5 niveles (Rangos 1–9), desbloqueo y equipamiento de prendas, efectos en salario/higiene/`Alimentacion.gd` e inmunidad a intoxicación en Rango ≥ 8.
8. No regresión de la suite GUT existente.

---

#### 5. Documentación y Entrega
* Crear `Funcionalidades/Minijuego_Cocina/Documentacion/MINIJUEGO_COCINA.md` y actualizar `CLAUDE.md` y `Prompts/MEGA_PROMPT_CONTEXTO.md`.
* Entregar resumen de archivos creados/modificados, resultados de GUT y verificación de layouts (`1280×720` y `720×1280`).
