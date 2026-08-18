#!/usr/bin/env python3
"""
sensor_ptc.py matematiginin dogrulamasi.

Bilinen kazanc ve okuma gurultusuyle sentetik kareler uretir, boru hattini
calistirir, degerleri geri kazanip kazanmadigina bakar. rawpy gerektirmez —
load_plane monkeypatch ile degistirilir.

Calistir:  ./.venv/bin/python tools/test_ptc_math.py
"""

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
import sensor_ptc as ptc  # noqa: E402

# --- gercek degerler (bunlari geri kazanmaliyiz) --------------------------
TRUE_GAIN = 2.35        # e-/ADU
TRUE_READ_E = 4.10      # e-
BIAS_OFFSET = 512.0     # ADU
WHITE_LEVEL = 16383
SIZE = 400              # ROI kenari
LEVELS_E = [900, 2200, 4500, 8000, 13000, 19000, 26000, 32000]  # elektron

rng = np.random.default_rng(20260818)


def synth(signal_e: float) -> np.ndarray:
    """Tek kare: Poisson foton + Gauss okuma, ADU cinsinden."""
    electrons = rng.poisson(signal_e, size=(SIZE, SIZE)).astype(np.float64)
    electrons += rng.normal(0.0, TRUE_READ_E, size=(SIZE, SIZE))
    return electrons / TRUE_GAIN + BIAS_OFFSET


# --- sahte kare deposu ----------------------------------------------------
STORE: dict[str, np.ndarray] = {}
INFO = {
    "white_level": WHITE_LEVEL,
    "black_level": BIAS_OFFSET,
    "color_desc": "RGBG",
    "raw_pattern": [[0, 1], [3, 2]],
}


def fake_load_plane(path, channel, roi):
    return STORE[str(path)], INFO


ptc.load_plane = fake_load_plane


def make(name: str, signal_e: float, exposure: float | None) -> ptc.Frame:
    STORE[name] = synth(signal_e)
    return ptc.Frame(Path(name), 800, exposure)


def main() -> int:
    # 20 bias karesi (sinyal yok, sadece okuma gurultusu)
    bias = [make(f"bias{i}", 0.0, 1 / 4000) for i in range(20)]

    # her seviyede 2 flat; poz suresi sinyalle orantili (dogrusallik testi icin)
    flats = []
    for i, s_e in enumerate(LEVELS_E):
        exposure = s_e / 10000.0
        flats.append(make(f"flat{i}a", s_e, exposure))
        flats.append(make(f"flat{i}b", s_e, exposure))

    master, read_adu, offset, info = ptc.analyse_bias(bias, "G1", 0)
    points = ptc.build_ptc(ptc.group_flats(flats), master, "G1", 0)
    full_scale = info["white_level"] - info["black_level"]
    slope, intercept, r2, used = ptc.fit_ptc(points, full_scale)

    gain = 1.0 / slope
    read_e = read_adu * gain
    read_e_fit = float(np.sqrt(max(intercept, 0.0))) * gain
    lin = ptc.check_linearity(points, full_scale)

    checks = [
        ("kazanc            ", gain,       TRUE_GAIN,    1.0),   # %1 tolerans
        ("okuma gur. (bias) ", read_e,     TRUE_READ_E,  3.0),
        # PTC kesiminden turetilen okuma gurultusu zayif bir tahmindir:
        # ~3 ADU^2'lik bir kesim, binlerce ADU^2'lik veriden ekstrapole
        # ediliyor. Sentetik (kusursuz) veride bile %10-15 sapar. Bu yuzden
        # tolerans genis — birincil olcum bias karelerinden geliyor, bu
        # sadece capraz kontrol.
        ("okuma gur. (PTC)  ", read_e_fit, TRUE_READ_E, 25.0),
        ("bias offset       ", offset,     BIAS_OFFSET,  0.5),
    ]

    print(f"{'olcum':<20} {'bulunan':>10} {'gercek':>10} {'hata %':>8}  sonuc")
    print("-" * 60)
    ok = True
    for label, got, want, tol_pct in checks:
        err = abs(got - want) / want * 100.0
        passed = err <= tol_pct
        ok &= passed
        print(f"{label:<20} {got:>10.4f} {want:>10.4f} {err:>7.2f}%  "
              f"{'GECTI' if passed else f'KALDI (tol {tol_pct}%)'}")

    print("-" * 60)
    print(f"{'uydurma R^2':<20} {r2:>10.6f}   ({len(used)} nokta)")
    if lin:
        d = lin["max_deviation_pct"]
        print(f"{'dogrusallik sapma':<20} {d:>9.3f}%   (sentetik veri ~0 olmali)")
        ok &= d < 1.0

    print()
    print("TUM TESTLER GECTI" if ok else "BAZI TESTLER KALDI")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
