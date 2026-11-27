"""
Genera la banda sonora estilo Subway Surfers (`Sonidos/Musica/Subway_Rush_Theme.mp3`)
mediante MIDI + FluidSynth (FluidR3_GM.sf2) + masterización DSP y GStreamer LAME MP3,
y todos los efectos de sonido arcade dedicados para `Minijuego_Correr` (`Sonidos/SFX/runner_*.wav`).

Uso:
  python3 tools/generar_audio_correr.py
"""

import math
import os
import struct
import subprocess
import tempfile
import wave

import numpy as np

RAIZ = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
DIR_MUSICA = os.path.join(RAIZ, "Sonidos", "Musica")
DIR_SFX = os.path.join(RAIZ, "Sonidos", "SFX")
SOUNDFONT = "/usr/share/sounds/sf2/FluidR3_GM.sf2"

SR_SFX = 44100
SR_MUSICA = 44100


# ============================================================================
# 1. Utilidades WAV / DSP
# ============================================================================

def guardar_wav_mono(ruta: str, audio: np.ndarray, sr: int = SR_SFX, peak_db: float = -2.5) -> None:
    os.makedirs(os.path.dirname(ruta), exist_ok=True)
    x = audio.astype(np.float64)
    mx = np.max(np.abs(x))
    if mx > 1e-8:
        target_peak = 10.0 ** (peak_db / 20.0)
        x = x * (target_peak / mx)
    x = np.clip(x, -0.99, 0.99)
    pcm = (x * 32767.0).astype(np.int16)
    with wave.open(ruta, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        wf.writeframes(pcm.tobytes())


def envolvente_adsr(n: int, atk_s: float, dec_s: float, sus: float, rel_s: float, sr: int = SR_SFX) -> np.ndarray:
    a = min(n, max(1, int(atk_s * sr)))
    r = min(n - a, max(1, int(rel_s * sr)))
    d = min(n - a - r, max(0, int(dec_s * sr)))
    s = max(0, n - a - d - r)
    partes = [np.linspace(0.0, 1.0, a, endpoint=False)]
    if d > 0:
        partes.append(np.linspace(1.0, sus, d, endpoint=False))
    if s > 0:
        partes.append(np.full(s, sus))
    if r > 0:
        partes.append(np.linspace(sus if (d > 0 or s > 0) else 1.0, 0.0, r))
    env = np.concatenate(partes)
    if len(env) < n:
        env = np.pad(env, (0, n - len(env)))
    return env[:n]


def _aplicar_rfft_mask(x: np.ndarray, mask_fn, sr: int = SR_SFX, axis: int = -1) -> np.ndarray:
    n = x.shape[axis]
    freqs = np.fft.rfftfreq(n, 1.0 / sr)
    mask = mask_fn(freqs)
    if x.ndim == 2 and axis == 0:
        mask = mask[:, None]
    spec = np.fft.rfft(x, axis=axis)
    return np.fft.irfft(spec * mask, n=n, axis=axis)


def filtro_bp(x: np.ndarray, lo: float, hi: float, sr: int = SR_SFX, _orden: int = 3) -> np.ndarray:
    def mask(f):
        w_lo = 1.0 / (1.0 + (lo / np.maximum(f, 1e-3)) ** 4)
        w_hi = 1.0 / (1.0 + (f / max(hi, 1.0)) ** 4)
        return np.where(f < 1.0, 0.0, w_lo * w_hi)
    return _aplicar_rfft_mask(x, mask, sr, axis=0)


def filtro_lp(x: np.ndarray, cutoff: float, sr: int = SR_SFX, _orden: int = 3) -> np.ndarray:
    return _aplicar_rfft_mask(x, lambda f: 1.0 / (1.0 + (f / max(cutoff, 1.0)) ** 4), sr, axis=0)


def filtro_hp(x: np.ndarray, cutoff: float, sr: int = SR_SFX, axis: int = 0) -> np.ndarray:
    return _aplicar_rfft_mask(x, lambda f: np.where(f < 1.0, 0.0, 1.0 / (1.0 + (cutoff / np.maximum(f, 1e-3)) ** 4)), sr, axis=axis)


def barrido_seno(f0: float, f1: float, dur: float, sr: int = SR_SFX, curva: float = 1.0) -> np.ndarray:
    n = int(dur * sr)
    t = np.linspace(0.0, 1.0, n, endpoint=False) ** curva
    freq = f0 + (f1 - f0) * t
    fase = 2.0 * np.pi * np.cumsum(freq) / sr
    return np.sin(fase)


# ============================================================================
# 2. Síntesis de los 16 efectos de sonido (SFX) del runner
# ============================================================================

def generar_sfx_todos() -> None:
    rng = np.random.default_rng(2026)

    # 1. Cambio de carril (swipe rápido y nítido)
    dur = 0.135
    n = int(dur * SR_SFX)
    t = np.linspace(0.0, dur, n, endpoint=False)
    ruido = rng.normal(0.0, 1.0, n)
    # Barrido rápido de aire + ligero golpe suave
    whoosh_lo = filtro_bp(ruido, 550.0, 2100.0) * np.exp(-t * 19.0)
    whoosh_hi = filtro_bp(ruido, 2000.0, 5600.0) * np.sin(np.pi * t / dur) ** 1.2
    thump = barrido_seno(210.0, 95.0, dur, curva=0.7) * np.exp(-t * 36.0)
    swipe = (whoosh_lo * 0.65 + whoosh_hi * 0.45 + thump * 0.42) * envolvente_adsr(n, 0.006, 0.04, 0.5, 0.06)
    guardar_wav_mono(os.path.join(DIR_SFX, "runner_swipe.wav"), swipe, peak_db=-2.2)

    # 2. Salto normal (impulso elástico hacia arriba + aire)
    dur = 0.19
    n = int(dur * SR_SFX)
    t = np.linspace(0.0, dur, n, endpoint=False)
    body = barrido_seno(220.0, 740.0, dur, curva=0.72) * np.exp(-t * 11.5)
    harm = barrido_seno(440.0, 1480.0, dur, curva=0.72) * np.exp(-t * 16.0) * 0.30
    aire = filtro_bp(rng.normal(0.0, 1.0, n), 1400.0, 4600.0) * np.exp(-t * 18.0) * 0.35
    jump = (body + harm + aire) * envolvente_adsr(n, 0.006, 0.05, 0.6, 0.08)
    guardar_wav_mono(os.path.join(DIR_SFX, "runner_jump.wav"), jump, peak_db=-2.0)

    # 3. Súper salto con zapatillas (impulso biónico brillante)
    dur = 0.29
    n = int(dur * SR_SFX)
    t = np.linspace(0.0, dur, n, endpoint=False)
    s1 = barrido_seno(260.0, 1080.0, dur, curva=0.68) * np.exp(-t * 8.5)
    s2 = barrido_seno(390.0, 1620.0, dur, curva=0.75) * np.exp(-t * 10.5) * 0.45
    brillo = np.sin(2.0 * np.pi * (1320.0 + 420.0 * np.sin(2.0 * np.pi * 16.0 * t)) * t) * np.exp(-t * 9.0) * 0.25
    aire = filtro_bp(rng.normal(0.0, 1.0, n), 1800.0, 6200.0) * np.exp(-t * 12.0) * 0.30
    sjump = (s1 + s2 + brillo + aire) * envolvente_adsr(n, 0.005, 0.06, 0.6, 0.12)
    guardar_wav_mono(os.path.join(DIR_SFX, "runner_super_jump.wav"), sjump, peak_db=-2.0)

    # 4. Rodar / caída rápida (giro descendente con modulación rotativa + roce)
    dur = 0.27
    n = int(dur * SR_SFX)
    t = np.linspace(0.0, dur, n, endpoint=False)
    ruido = rng.normal(0.0, 1.0, n)
    rot_mod = 0.65 + 0.35 * np.sin(2.0 * np.pi * 18.0 * t)
    roce = filtro_bp(ruido, 450.0, 2600.0) * rot_mod * np.exp(-t * 7.5)
    barrido_bajo = barrido_seno(360.0, 105.0, dur, curva=0.65) * np.exp(-t * 9.5)
    tuck = barrido_seno(720.0, 240.0, dur * 0.55, curva=0.8)
    tuck = np.pad(tuck, (0, n - len(tuck))) * np.exp(-t * 14.0) * 0.45
    roll = (roce * 0.72 + barrido_bajo * 0.68 + tuck) * envolvente_adsr(n, 0.008, 0.05, 0.65, 0.10)
    guardar_wav_mono(os.path.join(DIR_SFX, "runner_roll.wav"), roll, peak_db=-1.8)

    # 5. Aterrizaje (golpe seco y compacto)
    dur = 0.115
    n = int(dur * SR_SFX)
    t = np.linspace(0.0, dur, n, endpoint=False)
    thud = barrido_seno(155.0, 52.0, dur, curva=0.55) * np.exp(-t * 28.0)
    grit = filtro_bp(rng.normal(0.0, 1.0, n), 350.0, 2200.0) * np.exp(-t * 38.0) * 0.42
    land = (thud * 0.85 + grit) * envolvente_adsr(n, 0.003, 0.03, 0.4, 0.05)
    guardar_wav_mono(os.path.join(DIR_SFX, "runner_land.wav"), land, peak_db=-2.5)

    # 6. Paso al correr (suave y nítido para gravilla o techo)
    dur = 0.06
    n = int(dur * SR_SFX)
    t = np.linspace(0.0, dur, n, endpoint=False)
    tap = barrido_seno(210.0, 82.0, dur, curva=0.6) * np.exp(-t * 52.0)
    arena = filtro_bp(rng.normal(0.0, 1.0, n), 900.0, 4200.0) * np.exp(-t * 62.0) * 0.48
    step = (tap * 0.75 + arena) * envolvente_adsr(n, 0.002, 0.015, 0.35, 0.025)
    guardar_wav_mono(os.path.join(DIR_SFX, "runner_step.wav"), step, peak_db=-3.0)

    # 7. Tropiezo (golpe sordo + tambaleo)
    dur = 0.28
    n = int(dur * SR_SFX)
    t = np.linspace(0.0, dur, n, endpoint=False)
    bump = barrido_seno(150.0, 48.0, dur, curva=0.5) * np.exp(-t * 14.0)
    wobble_f = 280.0 - 110.0 * (t / dur) + 38.0 * np.sin(2.0 * np.pi * 24.0 * t)
    wobble = np.sin(2.0 * np.pi * np.cumsum(wobble_f) / SR_SFX) * np.exp(-t * 8.5) * 0.45
    scrape = filtro_bp(rng.normal(0.0, 1.0, n), 400.0, 3200.0) * np.exp(-t * 13.0) * 0.50
    stumble = np.tanh((bump * 0.9 + wobble + scrape) * 1.4) * envolvente_adsr(n, 0.004, 0.05, 0.6, 0.10)
    guardar_wav_mono(os.path.join(DIR_SFX, "runner_stumble.wav"), stumble, peak_db=-1.5)

    # 8. Choque fuerte (impacto tren/obstáculo: sub-boom + metal + estallido)
    dur = 0.46
    n = int(dur * SR_SFX)
    t = np.linspace(0.0, dur, n, endpoint=False)
    boom = barrido_seno(125.0, 32.0, dur, curva=0.45) * np.exp(-t * 7.5)
    metal = (
        np.sin(2.0 * np.pi * 318.0 * t) * 0.45
        + np.sin(2.0 * np.pi * 511.0 * t) * 0.35
        + np.sin(2.0 * np.pi * 782.0 * t) * 0.25
        + np.sin(2.0 * np.pi * 1190.0 * t) * 0.20
    ) * np.exp(-t * 9.5)
    crack = filtro_bp(rng.normal(0.0, 1.0, n), 280.0, 5800.0) * np.exp(-t * 10.5) * 0.9
    crash = np.tanh((boom * 1.2 + metal * 0.75 + crack) * 1.65) * envolvente_adsr(n, 0.002, 0.08, 0.65, 0.16)
    guardar_wav_mono(os.path.join(DIR_SFX, "runner_crash.wav"), crash, peak_db=-1.0)

    # 9. Moneda (doble nota metálica brillante estilo Subway Surfers: B5 -> E6)
    dur = 0.20
    n = int(dur * SR_SFX)
    t = np.linspace(0.0, dur, n, endpoint=False)
    corte = int(0.048 * SR_SFX)
    freq = np.where(np.arange(n) < corte, 987.77, 1318.51)
    fase = 2.0 * np.pi * np.cumsum(freq) / SR_SFX
    coin = (
        np.sin(fase) * 0.78
        + np.sin(2.0 * fase) * 0.30
        + np.sin(3.0 * fase) * 0.12
    ) * np.exp(-t * 14.5) * envolvente_adsr(n, 0.002, 0.04, 0.7, 0.08)
    guardar_wav_mono(os.path.join(DIR_SFX, "runner_coin.wav"), coin, peak_db=-2.0)

    # 10. Power-up genérico (arpegio brillante ascendente)
    dur = 0.36
    n = int(dur * SR_SFX)
    notas = [523.25, 659.25, 783.99, 1046.50, 1318.51]
    pu = np.zeros(n)
    paso = int(0.055 * SR_SFX)
    for idx, f in enumerate(notas):
        ini = idx * paso
        if ini >= n:
            break
        ln = n - ini
        tt = np.linspace(0.0, ln / SR_SFX, ln, endpoint=False)
        voz = (np.sin(2.0 * np.pi * f * tt) + 0.35 * np.sin(4.0 * np.pi * f * tt)) * np.exp(-tt * 9.0)
        pu[ini:] += voz * envolvente_adsr(ln, 0.004, 0.04, 0.7, 0.08)
    guardar_wav_mono(os.path.join(DIR_SFX, "runner_powerup.wav"), pu, peak_db=-2.0)

    # 11. Jetpack (ignición cohete + turbina ascendente)
    dur = 0.56
    n = int(dur * SR_SFX)
    t = np.linspace(0.0, dur, n, endpoint=False)
    ruido = rng.normal(0.0, 1.0, n)
    # Barrido progresivo de filtro para simular encendido de reactor
    jet_lo = filtro_bp(ruido, 160.0, 900.0) * (1.0 - np.exp(-t * 18.0)) * np.exp(-t * 3.0)
    jet_hi = filtro_bp(ruido, 900.0, 4800.0) * (t / dur) ** 0.5 * np.exp(-t * 3.6)
    turbina = barrido_seno(135.0, 620.0, dur, curva=0.75) * np.exp(-t * 3.5) * 0.55
    boom_ign = barrido_seno(130.0, 45.0, 0.16, curva=0.5) * np.exp(-np.linspace(0, 0.16, int(0.16 * SR_SFX)) * 20.0)
    boom_ign = np.pad(boom_ign, (0, n - len(boom_ign)))
    jet = np.tanh((jet_lo * 0.9 + jet_hi * 0.65 + turbina + boom_ign * 0.8) * 1.2) * envolvente_adsr(n, 0.01, 0.08, 0.75, 0.18)
    guardar_wav_mono(os.path.join(DIR_SFX, "runner_jetpack.wav"), jet, peak_db=-1.8)

    # 12. Pogo cohete (muelle elástico + lanzamiento)
    dur = 0.40
    n = int(dur * SR_SFX)
    t = np.linspace(0.0, dur, n, endpoint=False)
    f_pogo = 175.0 + 430.0 * (t / dur) ** 0.75 + 48.0 * np.sin(2.0 * np.pi * 24.0 * t)
    fase = 2.0 * np.pi * np.cumsum(f_pogo) / SR_SFX
    muelle = (np.sin(fase) + 0.4 * np.sin(2.0 * fase)) * np.exp(-t * 5.2)
    aire = filtro_bp(rng.normal(0.0, 1.0, n), 1200.0, 5000.0) * np.exp(-t * 7.5) * 0.35
    pogo = (muelle + aire) * envolvente_adsr(n, 0.005, 0.06, 0.7, 0.14)
    guardar_wav_mono(os.path.join(DIR_SFX, "runner_pogo.wav"), pogo, peak_db=-2.0)

    # 13. Tabla Hoverboard activada (golpe de tabla + pulso neón futurista)
    dur = 0.32
    n = int(dur * SR_SFX)
    t = np.linspace(0.0, dur, n, endpoint=False)
    clack = filtro_bp(rng.normal(0.0, 1.0, n), 700.0, 3600.0) * np.exp(-t * 42.0) * 0.85
    sub = barrido_seno(190.0, 85.0, 0.12) * np.exp(-np.linspace(0, 0.12, int(0.12 * SR_SFX)) * 26.0)
    sub = np.pad(sub, (0, n - len(sub)))
    hum = (barrido_seno(240.0, 580.0, dur, curva=0.7) + 0.45 * barrido_seno(360.0, 870.0, dur, curva=0.7)) * np.exp(-t * 6.5) * 0.6
    board = (clack + sub * 0.6 + hum) * envolvente_adsr(n, 0.004, 0.06, 0.65, 0.12)
    guardar_wav_mono(os.path.join(DIR_SFX, "runner_hoverboard.wav"), board, peak_db=-2.0)

    # 14. Escudo de tabla roto al salvar de un choque
    dur = 0.38
    n = int(dur * SR_SFX)
    t = np.linspace(0.0, dur, n, endpoint=False)
    desc = barrido_seno(980.0, 190.0, dur, curva=0.6) * np.exp(-t * 7.5)
    spark = (np.sin(2.0 * np.pi * 1650.0 * t) + np.sin(2.0 * np.pi * 2340.0 * t)) * np.exp(-t * 11.0) * 0.4
    burst = filtro_bp(rng.normal(0.0, 1.0, n), 600.0, 6500.0) * np.exp(-t * 12.0) * 0.8
    shatter = np.tanh((desc + spark + burst) * 1.3) * envolvente_adsr(n, 0.003, 0.06, 0.6, 0.14)
    guardar_wav_mono(os.path.join(DIR_SFX, "runner_shield_break.wav"), shatter, peak_db=-1.6)

    # 15. Llave mágica
    dur = 0.38
    n = int(dur * SR_SFX)
    key_sig = np.zeros(n)
    for idx, f in enumerate([1318.51, 1661.22, 1975.53, 2637.02]):
        ini = idx * int(0.045 * SR_SFX)
        ln = n - ini
        tt = np.linspace(0.0, ln / SR_SFX, ln, endpoint=False)
        key_sig[ini:] += (np.sin(2.0 * np.pi * f * tt) + 0.25 * np.sin(4.0 * np.pi * f * tt)) * np.exp(-tt * 9.5)
    key_sig *= envolvente_adsr(n, 0.003, 0.05, 0.65, 0.14)
    guardar_wav_mono(os.path.join(DIR_SFX, "runner_key.wav"), key_sig, peak_db=-2.0)

    # 16. Silbato del guardia + pequeño ladrido enérgico
    dur = 0.46
    n = int(dur * SR_SFX)
    t = np.linspace(0.0, dur, n, endpoint=False)
    # Silbato con trino de bolita (34 Hz AM + FM) en primeros 0.26s
    n_sil = int(0.26 * SR_SFX)
    ts = t[:n_sil]
    trino = np.sin(2.0 * np.pi * 34.0 * ts)
    fw1 = 2780.0 + 115.0 * trino
    fw2 = 3090.0 + 135.0 * trino
    sil = (np.sin(2.0 * np.pi * np.cumsum(fw1) / SR_SFX) * 0.6
           + np.sin(2.0 * np.pi * np.cumsum(fw2) / SR_SFX) * 0.5)
    sil *= (0.78 + 0.22 * trino) * envolvente_adsr(n_sil, 0.012, 0.04, 0.85, 0.05)
    sil += filtro_bp(rng.normal(0.0, 1.0, n_sil), 2200.0, 4800.0) * 0.18 * envolvente_adsr(n_sil, 0.01, 0.04, 0.7, 0.05)
    out = np.zeros(n)
    out[:n_sil] += sil * 0.85
    # Ladrido corto estilizado en 0.28..0.44s
    ini_b = int(0.28 * SR_SFX)
    ln_b = n - ini_b
    tb = np.linspace(0.0, ln_b / SR_SFX, ln_b, endpoint=False)
    f_bark = 160.0 + 180.0 * np.sin(np.pi * np.minimum(1.0, tb / 0.11))
    fase_b = 2.0 * np.pi * np.cumsum(f_bark) / SR_SFX
    gru = (np.sin(fase_b) + 0.65 * np.sin(2.0 * fase_b) + 0.4 * np.sin(3.0 * fase_b))
    gru = filtro_bp(gru, 260.0, 1750.0) * np.exp(-tb * 18.0)
    out[ini_b:] += gru * 0.9
    guardar_wav_mono(os.path.join(DIR_SFX, "runner_whistle.wav"), out, peak_db=-2.0)

    print(f"16 SFX del runner generados en {DIR_SFX}")


# ============================================================================
# 3. Escritor MIDI Type 1 puro (sin dependencias externas)
# ============================================================================

def _vlq(valor: int) -> bytes:
    buf = [valor & 0x7F]
    valor >>= 7
    while valor > 0:
        buf.append((valor & 0x7F) | 0x80)
        valor >>= 7
    return bytes(reversed(buf))


class PistaMIDI:
    def __init__(self, nombre: str, canal: int = 0) -> None:
        self.nombre = nombre
        self.canal = canal
        self.eventos = []  # (tick, prioridad, bytes)

    def meta_tempo(self, tick: int, bpm: float) -> None:
        us = int(round(60_000_000.0 / bpm))
        data = b"\xFF\x51\x03" + us.to_bytes(3, "big")
        self.eventos.append((tick, 0, data))

    def programa(self, tick: int, prog: int) -> None:
        self.eventos.append((tick, 1, bytes([0xC0 | self.canal, prog & 0x7F])))

    def cc(self, tick: int, ctrl: int, val: int) -> None:
        self.eventos.append((tick, 2, bytes([0xB0 | self.canal, ctrl & 0x7F, val & 0x7F])))

    def nota(self, tick: int, pitch: int, dur_ticks: int, vel: int = 100) -> None:
        p = max(0, min(127, int(pitch)))
        v = max(1, min(127, int(vel)))
        d = max(10, int(dur_ticks))
        self.eventos.append((tick, 4, bytes([0x90 | self.canal, p, v])))
        self.eventos.append((tick + d, 3, bytes([0x80 | self.canal, p, 0])))

    def serializar(self) -> bytes:
        ev_ordenados = sorted(self.eventos, key=lambda e: (e[0], e[1]))
        cuerpo = bytearray()
        # Nombre de pista
        nb = self.nombre.encode("ascii", errors="ignore")
        cuerpo.extend(_vlq(0))
        cuerpo.extend(b"\xFF\x03" + _vlq(len(nb)) + nb)

        ultimo_tick = 0
        for tick, _, data in ev_ordenados:
            delta = max(0, tick - ultimo_tick)
            ultimo_tick = tick
            cuerpo.extend(_vlq(delta))
            cuerpo.extend(data)

        # Fin de pista
        cuerpo.extend(_vlq(0) + b"\xFF\x2F\x00")
        return b"MTrk" + struct.pack(">I", len(cuerpo)) + bytes(cuerpo)


def guardar_midi(pistas: list, ruta: str, ppqn: int = 480) -> None:
    cab = b"MThd" + struct.pack(">IHHH", 6, 1, len(pistas), ppqn)
    with open(ruta, "wb") as f:
        f.write(cab)
        for p in pistas:
            f.write(p.serializar())


# ============================================================================
# 4. Composición estilo Subway Surfers (138 BPM · Surf-Punk / Funk / Electro)
# ============================================================================

def generar_musica_subway() -> None:
    if not os.path.isfile(SOUNDFONT):
        raise FileNotFoundError(f"No se encontró el soundfont GM: {SOUNDFONT}")

    PPQN = 480
    BPM = 138.0
    BAR = PPQN * 4        # 1920 ticks por compás
    S16 = PPQN // 4       # 120 ticks por semicorchea
    E8 = PPQN // 2        # 240 ticks por corchea
    TOTAL_BARS = 48
    RENDER_BARS = 50      # 2 compases extra para envolver colas de reverb/cymbal en el loop

    # Pistas
    t_meta = PistaMIDI("Tempo", 0)
    t_meta.meta_tempo(0, BPM)

    p_gtr_lead = PistaMIDI("SurfGuitar", 0)     # Overdriven Guitar (29)
    p_gtr_mute = PistaMIDI("FunkMute", 1)       # Muted Electric Guitar (28)
    p_gtr_dist = PistaMIDI("PowerChords", 2)    # Distortion Guitar (30)
    p_bass_slap = PistaMIDI("SlapBass", 3)      # Slap Bass 1 (36)
    p_bass_syn = PistaMIDI("SynthBass", 4)      # Synth Bass 1 (38)
    p_lead_syn = PistaMIDI("ArcadeLead", 5)     # Lead 2 Sawtooth (81)
    p_brass = PistaMIDI("BrassStabs", 6)        # Brass Section (61)
    p_clav = PistaMIDI("FunkClav", 7)           # Clavi (7)
    p_pad = PistaMIDI("BrightSynth", 8)         # Lead 1 Square / Warm Pad (80)
    p_drums = PistaMIDI("Drums", 9)             # GM Drum Kit

    # Configuración inicial de instrumentos, paneo y volumen
    configs = [
        (p_gtr_lead, 29, 118, 58, 42, 20),
        (p_gtr_mute, 28, 98,  82, 24, 15),
        (p_gtr_dist, 30, 82,  46, 36, 15),
        (p_bass_slap, 36, 120, 64, 10, 0),
        (p_bass_syn, 38, 92,  64, 8,  10),
        (p_lead_syn, 81, 90,  68, 48, 32),
        (p_brass,    61, 84,  40, 40, 15),
        (p_clav,     7,  104, 86, 28, 18),
        (p_pad,      80, 76,  52, 42, 25),
    ]
    for p, prog, vol, pan, rev, cho in configs:
        p.programa(0, prog)
        p.cc(0, 7, vol)
        p.cc(0, 10, pan)
        p.cc(0, 91, rev)
        p.cc(0, 93, cho)
    p_drums.cc(0, 7, 122)
    p_drums.cc(0, 91, 28)

    # Helpers rítmicos
    def bar_tick(b: int, s16: int = 0) -> int:
        return b * BAR + s16 * S16

    def drum_groove(b: int, estilo: str = "main", fill: bool = False) -> None:
        base = b * BAR
        # Kick
        kicks = [0, 6, 8, 10] if estilo != "funk" else [0, 3, 6, 10, 14]
        if estilo == "chorus":
            kicks = [0, 4, 6, 8, 12, 14]
        for k in kicks:
            p_drums.nota(base + k * S16, 36, 140, 118 if k in (0, 8) else 100)

        # Snare + ghost notes
        if fill:
            for s in [4, 10, 12, 13, 14, 15]:
                vel = 118 if s in (4, 12, 15) else (88 if s % 2 == 0 else 78)
                nota_s = 38 if s in (4, 12, 14, 15) else 47
                p_drums.nota(base + s * S16, nota_s, 110, vel)
        else:
            p_drums.nota(base + 4 * S16, 38, 140, 116)
            p_drums.nota(base + 12 * S16, 38, 140, 120)
            p_drums.nota(base + 7 * S16, 40, 80, 52)
            p_drums.nota(base + 15 * S16, 40, 80, 56)

        # Hi-hats + shaker
        for s in range(16):
            if estilo == "chorus" and s % 2 == 0:
                hh = 46 if s in (2, 10, 14) else 42
                p_drums.nota(base + s * S16, hh, 110, 94 if s % 4 == 0 else 74)
            elif s % 2 == 0:
                hh = 46 if (s == 14 and b % 2 == 1) else 42
                p_drums.nota(base + s * S16, hh, 100, 92 if s % 4 == 0 else 72)
            elif s in (3, 7, 11, 15):
                p_drums.nota(base + s * S16, 42, 70, 54)
            # Shaker constante para energía runner
            if s % 2 == 1:
                p_drums.nota(base + s * S16, 82, 65, 58)

        # Crash al inicio de sección
        if b % 8 == 0 or (b % 4 == 0 and estilo == "chorus"):
            p_drums.nota(base, 49 if b % 16 == 0 else 57, 420, 112)

    def bass_pattern(b: int, root_midi: int, estilo: str = "main") -> None:
        base = b * BAR
        r_lo = root_midi
        r_hi = root_midi + 12
        fifth = root_midi + 7
        flat7 = root_midi + 10
        if estilo == "chorus":
            patron = [(0, r_lo, 105), (2, r_lo, 88), (3, r_hi, 96), (4, r_lo, 95),
                      (6, r_lo, 98), (8, r_hi, 104), (10, flat7, 94), (12, fifth, 98), (14, r_hi, 96)]
        elif estilo == "funk":
            patron = [(0, r_lo, 110), (2, r_hi, 98), (3, r_lo, 82), (6, r_hi, 104),
                      (8, flat7, 92), (10, r_lo, 100), (12, fifth, 94), (14, r_hi, 106)]
        else:
            patron = [(0, r_lo, 108), (3, r_hi, 94), (4, r_lo, 92), (6, r_lo, 96),
                      (8, r_hi, 104), (10, flat7, 90), (12, r_lo, 98), (14, fifth, 94)]
        for step, p, vel in patron:
            p_bass_slap.nota(base + step * S16, p, 190, vel)
            if step in (0, 6, 8, 12):
                p_bass_syn.nota(base + step * S16, p, 200, int(vel * 0.82))

    def mute_funk_chops(b: int, acorde: list) -> None:
        base = b * BAR
        # Patrón sincopado "chicka-chicka" funk
        for s, dur_s, vel in [(2, 90, 86), (4, 70, 68), (6, 100, 92), (10, 90, 88), (11, 65, 66), (14, 110, 94)]:
            for n in acorde:
                p_gtr_mute.nota(base + s * S16, n, dur_s, vel)

    # Acordes base
    AC_AM = [57, 60, 64]       # A3 C4 E4
    AC_F = [53, 57, 60]        # F3 A3 C4
    AC_G = [55, 59, 62]        # G3 B3 D4
    AC_EM = [52, 55, 59]       # E3 G3 B3
    AC_C = [60, 64, 67]        # C4 E4 G4
    AC_DM = [50, 53, 57]       # D3 F3 A3
    AC_E7 = [52, 56, 59, 62]   # E3 G#3 B3 D4

    # ------------------------------------------------------------------------
    # Motivo icónico principal (riff surf-punk sincopado estilo Subway Surfers!)
    # ------------------------------------------------------------------------
    def tocar_riff_principal(b_inicio: int, con_doble_synth: bool = False, con_brass: bool = False) -> None:
        # 8 compases: | Am | Am | F | G | Am | Am | F G | E7 |
        progresion = [
            (45, AC_AM), (45, AC_AM), (41, AC_F), (43, AC_G),
            (45, AC_AM), (45, AC_AM), (41, AC_F), (40, AC_E7),
        ]
        # Riff melódico por compás (step_16, pitch, dur_16s, vel)
        riffs = [
            [(0, 57, 1.4, 112), (2, 57, 0.9, 98), (3, 60, 1.3, 108), (5, 62, 1.0, 104), (6, 64, 1.6, 115),
             (8, 67, 1.2, 110), (10, 64, 1.0, 102), (11, 62, 1.0, 98), (12, 60, 1.4, 108), (14, 57, 1.4, 104)],
            [(0, 57, 1.4, 112), (3, 60, 1.1, 105), (5, 62, 1.0, 104), (6, 64, 1.6, 115),
             (8, 69, 1.8, 118), (11, 67, 1.0, 104), (12, 64, 1.2, 108), (14, 62, 1.2, 100)],
            [(0, 53, 1.4, 110), (2, 53, 0.9, 98), (3, 57, 1.3, 108), (5, 60, 1.0, 104), (6, 62, 1.6, 114),
             (8, 64, 1.2, 110), (10, 62, 1.0, 102), (11, 60, 1.0, 98), (12, 57, 1.6, 106), (14, 55, 1.2, 98)],
            [(0, 55, 1.4, 110), (2, 59, 0.9, 100), (3, 62, 1.3, 108), (5, 64, 1.0, 104), (6, 67, 1.8, 116),
             (9, 66, 0.9, 102), (10, 64, 1.0, 104), (12, 62, 1.2, 104), (14, 59, 1.3, 100)],
            [(0, 57, 1.4, 114), (2, 57, 0.9, 98), (3, 60, 1.3, 110), (5, 62, 1.0, 106), (6, 64, 1.6, 116),
             (8, 67, 1.2, 112), (10, 69, 1.4, 118), (12, 67, 1.2, 108), (14, 64, 1.4, 105)],
            [(0, 69, 1.5, 118), (3, 67, 1.0, 106), (5, 64, 1.0, 104), (6, 62, 1.4, 110),
             (8, 60, 1.2, 108), (10, 62, 1.0, 104), (12, 64, 1.5, 112), (14, 60, 1.3, 102)],
            [(0, 57, 1.6, 112), (3, 60, 1.2, 106), (6, 64, 1.6, 114),
             (8, 59, 1.6, 112), (11, 62, 1.2, 106), (14, 67, 1.6, 116)],
            [(0, 64, 1.5, 114), (2, 62, 1.0, 104), (4, 59, 1.5, 110), (6, 56, 1.5, 108),
             (8, 52, 1.4, 106), (10, 55, 1.0, 102), (12, 56, 1.3, 108), (14, 59, 1.5, 112)],
        ]
        for i in range(8):
            b = b_inicio + i
            root, ac = progresion[i]
            drum_groove(b, "main", fill=(i in (3, 7)))
            if i == 6:
                # F (mitad 1) -> G (mitad 2)
                for step, p, vel in [(0, 41, 108), (3, 53, 98), (4, 41, 94), (6, 53, 98)]:
                    p_bass_slap.nota(bar_tick(b, step), p, 180, vel)
                for step, p, vel in [(8, 43, 110), (11, 55, 100), (12, 43, 96), (14, 55, 102)]:
                    p_bass_slap.nota(bar_tick(b, step), p, 180, vel)
            else:
                bass_pattern(b, root, "main")
            mute_funk_chops(b, ac)

            for st, pitch, d16, vel in riffs[i]:
                tick = bar_tick(b, st)
                dur_t = int(d16 * S16)
                p_gtr_lead.nota(tick, pitch, dur_t, vel)
                if con_doble_synth:
                    p_lead_syn.nota(tick, pitch + 12, dur_t, int(vel * 0.85))
                elif st in (0, 6, 8):
                    p_pad.nota(tick, pitch + 12, dur_t, 76)

            if con_brass:
                for bs in (0, 6, 14):
                    if bs == 0 or (i % 2 == 1 and bs in (6, 14)):
                        for n in ac:
                            p_brass.nota(bar_tick(b, bs), n + 12, 150, 96)

    # ------------------------------------------------------------------------
    # Sección A1 (0..7) y A2 (8..15)
    # ------------------------------------------------------------------------
    tocar_riff_principal(0, con_doble_synth=False, con_brass=False)
    tocar_riff_principal(8, con_doble_synth=True, con_brass=True)

    # ------------------------------------------------------------------------
    # Sección B (16..23): Groove Funk Urbano (Clavinet + Slap Bass + Stabs)
    # ------------------------------------------------------------------------
    progresion_b = [
        (45, AC_AM), (38, AC_DM), (45, AC_AM), (38, AC_DM),
        (41, AC_F),  (43, AC_G),  (45, AC_AM), (40, AC_E7),
    ]
    clav_licks = [
        [(0, 69, 130), (3, 72, 110), (6, 74, 150), (10, 72, 120), (12, 69, 120), (14, 67, 130)],
        [(0, 69, 130), (2, 72, 110), (4, 74, 140), (7, 72, 110), (10, 69, 130), (14, 64, 150)],
    ]
    for i in range(8):
        b = 16 + i
        root, ac = progresion_b[i]
        drum_groove(b, "funk", fill=(i == 7))
        bass_pattern(b, root, "funk")
        mute_funk_chops(b, ac)
        lick = clav_licks[i % 2]
        for st, pitch, dur_t in lick:
            p_clav.nota(bar_tick(b, st), pitch, dur_t, 102)
            if st in (0, 6):
                p_pad.nota(bar_tick(b, st), pitch, dur_t, 74)
        # Pregunta-respuesta de guitarra surf cada 2 compases
        if i % 2 == 1:
            for st, gp in [(8, 64), (10, 67), (12, 69), (14, 72)]:
                p_gtr_lead.nota(bar_tick(b, st), gp, 160, 104)
        if i in (0, 4, 6):
            for n in ac:
                p_brass.nota(bar_tick(b, 0), n + 12, 190, 96)

    # ------------------------------------------------------------------------
    # Sección C (24..31): Pre-Estribillo Creciente (Build-up hacia el estribillo)
    # ------------------------------------------------------------------------
    progresion_c = [
        (41, AC_F), (43, AC_G), (45, AC_AM), (48, AC_C),
        (41, AC_F), (43, AC_G), (40, AC_EM), (40, AC_E7),
    ]
    for i in range(8):
        b = 24 + i
        root, ac = progresion_c[i]
        es_roll_final = (i == 7)
        drum_groove(b, "main", fill=(i in (3, 7)))
        if es_roll_final:
            # Redoble creciente de caja en semicorcheas
            for s in range(8, 16):
                p_drums.nota(bar_tick(b, s), 38, 90, 72 + (s - 8) * 7)
        # Bajo a corcheas crecientes
        for e in range(8):
            p_bass_slap.nota(bar_tick(b, e * 2), root + (12 if e % 2 == 1 else 0), 170, 94 + i * 2)
            p_bass_syn.nota(bar_tick(b, e * 2), root, 180, 82 + i * 2)
        # Acordes sostenidos de guitarra/brass + arpegio synth
        for n in ac:
            p_gtr_dist.nota(bar_tick(b, 0), n, BAR - 120, 82 + i * 3)
            if i >= 2:
                p_brass.nota(bar_tick(b, 0), n + 12, PPQN * 2, 84 + i * 3)
        arp_notas = [ac[0] + 12, ac[1] + 12, ac[2] + 12, ac[0] + 24]
        for s in range(0, 16, 2):
            p_pad.nota(bar_tick(b, s), arp_notas[(s // 2) % len(arp_notas)], 150, 78 + i * 3)

    # ------------------------------------------------------------------------
    # Sección D (32..39): Estribillo Explosivo (Power Chords + Lead + Brass)
    # ------------------------------------------------------------------------
    progresion_d = [
        (45, AC_AM), (41, AC_F), (48, AC_C), (43, AC_G),
        (45, AC_AM), (41, AC_F), (43, AC_G), (40, AC_E7),
    ]
    melodia_d = [
        [(0, 76, 3.0), (3, 79, 3.0), (6, 81, 3.5), (10, 79, 2.0), (12, 76, 3.5)],
        [(0, 72, 2.5), (3, 74, 2.5), (6, 76, 3.5), (10, 74, 2.0), (12, 72, 3.5)],
        [(0, 76, 2.5), (3, 79, 2.5), (6, 84, 3.5), (10, 81, 2.5), (13, 79, 2.5)],
        [(0, 74, 2.5), (3, 76, 2.5), (6, 79, 4.0), (11, 76, 2.0), (13, 74, 2.5)],
        [(0, 76, 3.0), (3, 79, 3.0), (6, 81, 3.5), (10, 83, 2.0), (12, 84, 3.5)],
        [(0, 81, 2.5), (3, 79, 2.5), (6, 77, 3.5), (10, 76, 2.0), (12, 74, 3.5)],
        [(0, 74, 2.5), (3, 76, 2.5), (6, 79, 3.5), (10, 81, 2.5), (13, 79, 2.5)],
        [(0, 76, 3.0), (4, 74, 2.5), (8, 71, 3.0), (12, 74, 1.8), (14, 76, 1.8)],
    ]
    for i in range(8):
        b = 32 + i
        root, ac = progresion_d[i]
        drum_groove(b, "chorus", fill=(i in (3, 7)))
        bass_pattern(b, root, "chorus")
        mute_funk_chops(b, ac)
        # Power chords de guitarra distorsionada (tónica + quinta) en nivel equilibrado
        for bs in (0, 6, 8, 14):
            dur_p = 400 if bs in (0, 8) else 190
            p_gtr_dist.nota(bar_tick(b, bs), root + 12, dur_p, 84)
            p_gtr_dist.nota(bar_tick(b, bs), root + 19, dur_p, 78)
        # Melodía principal doblada por synth lead y guitarra surf
        for st, pitch, d16 in melodia_d[i]:
            tick = bar_tick(b, st)
            dur_t = int(d16 * S16)
            p_lead_syn.nota(tick, pitch, dur_t, 96)
            p_gtr_lead.nota(tick, pitch - 12, dur_t, 102)
        # Golpes de metales
        for bs in (0, 6, 12):
            for n in ac:
                p_brass.nota(bar_tick(b, bs), n + 12, 180, 82)

    # ------------------------------------------------------------------------
    # Sección E (40..47): Solo Arcade + Turnaround hacia el compás 1
    # ------------------------------------------------------------------------
    tocar_riff_principal(40, con_doble_synth=True, con_brass=True)

    # Colas en compases 48-49 (solo nota final suave para envolver reverb sin hueco)
    p_gtr_lead.nota(bar_tick(48, 0), 57, 120, 60)
    p_drums.nota(bar_tick(48, 0), 49, 240, 72)

    pistas = [t_meta, p_gtr_lead, p_gtr_mute, p_gtr_dist, p_bass_slap, p_bass_syn, p_lead_syn, p_brass, p_clav, p_pad, p_drums]

    with tempfile.TemporaryDirectory(prefix="subway_music_") as tmp:
        ruta_mid = os.path.join(tmp, "theme.mid")
        ruta_wav = os.path.join(tmp, "theme_raw.wav")
        ruta_master_wav = os.path.join(tmp, "theme_master.wav")
        ruta_mp3 = os.path.join(DIR_MUSICA, "Subway_Rush_Theme.mp3")

        guardar_midi(pistas, ruta_mid, PPQN)
        print("MIDI generado:", ruta_mid)

        # Renderizar con FluidSynth (FluidR3_GM.sf2) vía GStreamer
        cmd_fluid = [
            "gst-launch-1.0", "-q",
            "filesrc", f"location={ruta_mid}",
            "!", "midiparse",
            "!", "fluiddec", f"soundfont={SOUNDFONT}", "synth-gain=0.68", "synth-reverb=true", "synth-chorus=true",
            "!", "audioconvert",
            "!", "audioresample",
            "!", f"audio/x-raw,format=S16LE,channels=2,rate={SR_MUSICA}",
            "!", "wavenc",
            "!", "filesink", f"location={ruta_wav}",
        ]
        subprocess.run(cmd_fluid, check=True)

        # Masterización + wrap de cola para loop perfecto de exactamente TOTAL_BARS compases
        with wave.open(ruta_wav, "rb") as wf:
            n_frames = wf.getnframes()
            sr = wf.getframerate()
            raw = np.frombuffer(wf.readframes(n_frames), dtype=np.int16).reshape(-1, 2).astype(np.float64) / 32768.0

        dur_loop_s = TOTAL_BARS * 4.0 * 60.0 / BPM
        n_loop = int(round(dur_loop_s * sr))
        loop_audio = np.zeros((n_loop, 2), dtype=np.float64)

        n_cuerpo = min(n_loop, len(raw))
        loop_audio[:n_cuerpo] = raw[:n_cuerpo]
        if len(raw) > n_loop:
            n_cola = min(n_loop, len(raw) - n_loop)
            fade_cola = np.linspace(1.0, 0.0, n_cola)[:, None]
            loop_audio[:n_cola] += raw[n_loop:n_loop + n_cola] * fade_cola

        # Sub-kick sutil sintético al pulso para dar pegada moderna
        beat_s = 60.0 / BPM
        n_kick = int(0.11 * sr)
        tk = np.linspace(0.0, 0.11, n_kick, endpoint=False)
        sub_kick = np.sin(2.0 * np.pi * np.cumsum(112.0 * np.exp(-tk * 26.0) + 46.0) / sr) * np.exp(-tk * 22.0) * 0.16
        for b in range(TOTAL_BARS):
            for step in (0, 8):
                pos_s = (b * 4.0 + step * 0.25) * beat_s
                idx = int(round(pos_s * sr))
                if idx + n_kick <= n_loop:
                    loop_audio[idx:idx + n_kick, 0] += sub_kick
                    loop_audio[idx:idx + n_kick, 1] += sub_kick

        # High-pass 32 Hz + gentle presence boost + nivelador dinámico de envolvente + saturación suave
        loop_audio = filtro_hp(loop_audio, 32.0, sr, axis=0)
        loop_audio = loop_audio + _aplicar_rfft_mask(
            loop_audio,
            lambda f: np.where(f < 1.0, 0.0, (1.0 / (1.0 + (2800.0 / np.maximum(f, 1e-3)) ** 4)) * (1.0 / (1.0 + (f / 6500.0) ** 4))),
            sr, axis=0
        ) * 0.18

        # Compresor de bus suave por ventana RMS de 350 ms para homogeneizar verso y estribillo
        win = int(0.35 * sr)
        mono_sq = np.mean(loop_audio ** 2, axis=1)
        kernel = np.ones(win) / win
        rms_env = np.sqrt(np.convolve(mono_sq, kernel, mode="same") + 1e-7)
        target_bus = 0.14
        gain_env = np.clip((target_bus / np.maximum(rms_env, 0.04)) ** 0.55, 0.58, 1.35)[:, None]
        loop_audio *= gain_env

        rms_actual = math.sqrt(float(np.mean(loop_audio ** 2)))
        rms_objetivo = 10.0 ** (-14.2 / 20.0)
        if rms_actual > 1e-8:
            loop_audio *= rms_objetivo / rms_actual

        # Compresión suave de picos
        loop_audio = np.tanh(loop_audio * 1.15) / math.tanh(1.15)
        pk = float(np.max(np.abs(loop_audio)))
        if pk > 0.94:
            loop_audio *= 0.94 / pk

        # Micro crossfade de 4 ms en los bordes para cero clics al repetir
        cf = int(0.004 * sr)
        loop_audio[:cf] *= np.linspace(0.0, 1.0, cf)[:, None]
        loop_audio[-cf:] *= np.linspace(1.0, 0.0, cf)[:, None]

        pcm_out = np.clip(loop_audio * 32767.0, -32767, 32767).astype(np.int16)
        with wave.open(ruta_master_wav, "wb") as wf:
            wf.setnchannels(2)
            wf.setsampwidth(2)
            wf.setframerate(sr)
            wf.writeframes(pcm_out.tobytes())

        os.makedirs(DIR_MUSICA, exist_ok=True)
        cmd_mp3 = [
            "gst-launch-1.0", "-q",
            "filesrc", f"location={ruta_master_wav}",
            "!", "wavparse",
            "!", "audioconvert",
            "!", "lamemp3enc", "target=bitrate", "bitrate=192", "cbr=true",
            "!", "xingmux",
            "!", "filesink", f"location={ruta_mp3}",
        ]
        subprocess.run(cmd_mp3, check=True)
        rms_f = math.sqrt(float(np.mean((pcm_out / 32768.0) ** 2)))
        print(f"Música generada: {ruta_mp3} ({dur_loop_s:.1f}s, {os.path.getsize(ruta_mp3)/1024:.0f} KB, RMS={20*math.log10(rms_f+1e-9):.1f} dB)")


if __name__ == "__main__":
    generar_sfx_todos()
    generar_musica_subway()
