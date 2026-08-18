#!/usr/bin/env python3
"""
Hizli kontrol: bir flat karesi doyumun yuzde kacinda?

Merdivenin TAMAMINI cekmeden once ilk kareyi bununla kontrol et.
Bir saatlik cekimin sonunda kullanilamaz oldugunu ogrenmektense,
ilk karede ogren.

Kullanim:
    ./.venv/bin/python tools/check_flat.py data/faz0/flats/IMG_0229.CR2
    ./.venv/bin/python tools/check_flat.py data/faz0/flats/*.CR2
"""

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
from sensor_ptc import load_plane  # noqa: E402

# PTC dogrusunun uydurulabildigi pencere (sensor_ptc ile ayni)
FIT_LO, FIT_HI = 3.0, 65.0


def verdict(pct: float) -> str:
    if pct < 1.0:
        return "COK KARANLIK — pozu uzat"
    if pct < FIT_LO:
        # Pencerenin hemen altinda: tek kare olarak uydurmaya girmez ama
        # merdivenin ALT BASAMAGI olarak dogru yer. Buradan yukari cikilir.
        return "merdiven basi — buradan yukari cik"
    if pct > 90:
        return "DOYMUS — kullanilamaz, pozu kisalt"
    if pct > FIT_HI:
        return "cok parlak — uydurma penceresi disinda"
    return "KULLANILABILIR"


def main() -> int:
    paths = [Path(a) for a in sys.argv[1:]]
    if not paths:
        sys.exit(__doc__)

    print(f"{'dosya':<18}{'sinyal ADU':>12}{'doyum':>9}   durum")
    print("-" * 62)

    usable = 0
    for p in paths:
        if not p.exists():
            print(f"{p.name:<18}{'—':>12}{'—':>9}   dosya yok")
            continue
        plane, info = load_plane(p, "G1", 400)
        full = info["white_level"] - info["black_level"]
        sig = float(plane.mean()) - info["black_level"]
        pct = sig / full * 100.0
        v = verdict(pct)
        usable += v == "KULLANILABILIR"
        print(f"{p.name:<18}{sig:>12.1f}{pct:>8.1f}%   {v}")

    if len(paths) > 1:
        print("-" * 62)
        print(f"  {usable} / {len(paths)} kare uydurma penceresinde "
              f"({FIT_LO:.0f}-{FIT_HI:.0f}%)")
        if usable < 3:
            print("  ! Dogru uydurmak icin ayni ISO'da en az 3 kullanilabilir "
                  "SEVIYE gerekiyor (her seviyede 2 kare).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
