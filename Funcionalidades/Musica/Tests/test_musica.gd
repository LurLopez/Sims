extends GutTest

# Tests del autoload de música: bus, bucles, cambio de pista y silencio.

const ESPERA_FUNDIDO: float = 1.1


func test_bus_de_musica_y_bucles_configurados() -> void:
	assert_ne(AudioServer.get_bus_index(Musica.BUS_MUSICA), -1,
		"El bus de música debe existir")
	assert_true((Musica.PISTA_GENERAL as AudioStreamMP3).loop,
		"La pista general debe estar importada con bucle")
	# La pista del minijuego se carga de forma diferida (no se precarga al
	# arrancar); el test comprueba el recurso importado directamente.
	var pista_minijuego := load(Musica.RUTA_PISTA_MINIJUEGO) as AudioStreamMP3
	assert_not_null(pista_minijuego)
	assert_true(pista_minijuego.loop,
		"La pista del minijuego debe estar importada con bucle")


func test_cambio_general_minijuego_y_vuelta() -> void:
	Musica.Reproducir_General()
	await wait_seconds(ESPERA_FUNDIDO)
	assert_eq(Musica._pista_activa, Musica.Pista.GENERAL)
	assert_true(Musica._reproductor_general.playing)
	assert_false(Musica._reproductor_general.stream_paused)

	Musica.Reproducir_Minijuego()
	await wait_seconds(ESPERA_FUNDIDO)
	assert_eq(Musica._pista_activa, Musica.Pista.MINIJUEGO)
	assert_true(Musica._reproductor_minijuego.playing)
	assert_true(Musica._reproductor_general.stream_paused,
		"La pista general debe pausarse durante el minijuego")

	Musica.Reproducir_General()
	await wait_seconds(ESPERA_FUNDIDO)
	assert_eq(Musica._pista_activa, Musica.Pista.GENERAL)
	assert_false(Musica._reproductor_general.stream_paused)
	assert_false(Musica._reproductor_minijuego.playing,
		"La pista del minijuego debe detenerse al volver")


func test_silencio_se_aplica_al_bus_y_se_restaura() -> void:
	var anterior: bool = Musica.Esta_Silenciado()
	var indice: int = AudioServer.get_bus_index(Musica.BUS_MUSICA)

	Musica.Establecer_Silencio(true)
	assert_true(Musica.Esta_Silenciado())
	assert_true(AudioServer.is_bus_mute(indice))

	Musica.Establecer_Silencio(false)
	assert_false(Musica.Esta_Silenciado())
	assert_false(AudioServer.is_bus_mute(indice))

	# No dejar la preferencia del usuario modificada por el test.
	Musica.Establecer_Silencio(anterior)
