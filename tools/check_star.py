#!/usr/bin/env python3
"""Tek karede yildizlarin doyup doymadigini kontrol eder.

Dizi B'yi cekmeden ONCE calistir. Genis acida parlak yildizlar
sanildigindan cok daha kolay doyar: Vega 14 mm f/2.8 15 s ISO 1600'de
dolum kapasitesini **161 kat** asiyor. Doymus yildizin fotometrisi
anlamsizdir ve sonum olcumu yapilamaz.

Kullanim:
    python tools/check_star.py <kare.CR2>

Hedef: en parlak yildizin tepe pikseli tam olcegin %40-70'i.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
import starphot as sp
from sensor_ptc import load_plane


def main() -> int:
    args = [a for a in sys.argv[1:] if a not in ("-h", "--help")]
    if len(args) == 0 or len(args) != len(sys.argv) - 1:
        # Sahada gece yarisi yardim istenince patlamamali.
        print(__doc__)
        return 0 if len(args) != len(sys.argv) - 1 else 2
    white = 15360.0
    black = 2049.0
    full = white - black

    print(f"{'dosya':<22} {'en parlak':>10} {'doluluk':>9} {'FWHM':>7}  durum")
    print("-" * 66)
    worst = 0
    for arg in args:
        p = Path(arg)
        plane, _ = load_plane(p, "G1", roi=0)
        peaks = sp.find_stars(plane, threshold_sigma=10.0, max_stars=5)
        if not peaks:
            print(f"{p.name:<22} {'-':>10} {'-':>9} {'-':>7}  YILDIZ YOK — "
                  f"odak veya poz yetersiz")
            worst = max(worst, 2)
            continue
        y, x, peak = peaks[0]
        fill = (peak - black) / full
        cy, cx = sp.centroid(plane, y, x)
        fwhm = sp.fit_gaussian_fwhm(plane, cy, cx)

        if fill >= 0.95:
            verdict, level = "DOYMUS — kis veya kisalt", 2
        elif fill > 0.75:
            verdict, level = "sinirda — bir durak kis", 1
        elif fill < 0.15:
            verdict, level = "cok sonuk — bir durak ac", 1
        else:
            verdict, level = "TAMAM", 0
        worst = max(worst, level)
        print(f"{p.name:<22} {peak:10.0f} {fill * 100:8.1f}% "
              f"{(fwhm or 0):7.2f}  {verdict}")

    print("-" * 66)
    if worst == 0:
        print("Merdivene baslayabilirsin.")
    else:
        print("Ayari duzelt, tek kare daha cek, tekrar sor.")
    print()
    print("Not: bu arac EN PARLAK yildiza bakar. Analiz araci doymus")
    print("yildizi atlayip bir sonraki siraya gecebiliyor, ama merkezdeki")
    print("yildizlarin hepsi doymussa hicbir sey yapamaz.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
