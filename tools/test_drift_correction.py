#!/usr/bin/env python3
"""sensor_ptc.py'nin isik kaymasi duzeltmesini sentetik veriyle dogrular.

Bilinen bir kayma ve bilinen bir dogrusalsizlik uretip aracin ikisini
birbirinden ayirabildigini kontrol eder. 0.A.6'nin ucuncu denemesinde
eklenen duzeltme buydu; dogrulamasi olmadan birakilamaz.

Kritik nokta: duzeltme yalnizca merdiven PALINDROM sirada cekildiginde
gecerli. Tek yonlu cekimde poz suresi zamanla korele olur ve duzeltme
dogrusalsizligi de yer. Test ikisini de kontrol ediyor.
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
import sensor_ptc as ptc

BIAS = 2048.0
FULL = 13312.0
GAIN = 0.125          # e-/ADU
RATE = 3000.0         # ADU/s, kaymasiz taban


def build(order, drift_per_min, beta, t0=0.0, gap=8.0):
    """order: cekim sirasindaki poz sureleri. beta: dogrusalsizlik katsayisi."""
    points = []
    by_exp = {}
    clock = t0
    for exp in order:
        # Isik kaymasi: dogrusal, dizinin ortasina gore degil mutlak zamanda.
        light = 1.0 + drift_per_min / 100.0 * (clock / 60.0)
        ideal = RATE * exp * light
        # Doyuma dogru sapma: sinyal = ideal * (1 + beta * doluluk)
        sig = ideal * (1.0 + beta * ideal / FULL)
        by_exp.setdefault(exp, []).append({"signal_adu": sig, "taken_at": clock})
        clock += exp + gap
    for exp, frames in by_exp.items():
        points.append({
            "iso": 800,
            "exposure_s": exp,
            "signal_adu": float(np.mean([f["signal_adu"] for f in frames])),
            "per_frame": frames,
            "variance_adu2": 0.0,
            "n_frames": len(frames),
        })
    return points


LADDER = [0.4, 0.5, 0.8, 1.3, 1.6, 2.0, 2.5, 3.2]
PALINDROME = LADDER + LADDER[::-1]
ONE_WAY = LADDER + LADDER          # iki kez ayni yonde


def main() -> int:
    ok = True
    print(f"{'senaryo':<44} {'ham':>8} {'duzeltilmis':>12} {'kayma':>9}")
    print("-" * 78)

    cases = [
        ("palindrom, kayma yok, dogrusal", PALINDROME, 0.0, 0.0, 0.5, 0.3),
        ("palindrom, -5%/dk kayma, dogrusal", PALINDROME, -5.0, 0.0, 0.5, 0.3),
        ("palindrom, -10%/dk kayma, dogrusal", PALINDROME, -10.0, 0.0, 0.5, 0.5),
    ]
    for label, order, drift, beta, max_corrected, tol_drift in cases:
        lin = ptc.check_linearity(build(order, drift, beta), FULL)
        raw = lin["max_deviation_pct"]
        cor = lin["max_deviation_pct_drift_corrected"]
        got_drift = lin["light_drift_pct_per_min"]
        if cor is None:
            print(f"{label:<44} {raw:>7.2f}%   DUZELTILMEDI")
            ok = False
            continue
        good = cor < max_corrected and abs(got_drift - drift) < max(abs(drift) * 0.15, tol_drift)
        ok &= good
        print(f"{label:<44} {raw:>7.2f}% {cor:>11.2f}% {got_drift:>8.2f}%  "
              f"{'OK' if good else 'HATA'}")

    # Gercek dogrusalsizlik: kayma varken bile GORULMELI, silinmemeli.
    lin = ptc.check_linearity(build(PALINDROME, -5.0, 0.05), FULL)
    cor = lin["max_deviation_pct_drift_corrected"]
    # beta=0.05 -> %78 dolulukta ~%3.9 sapma. Duzeltme bunu yememeli.
    seen = cor > 1.5
    ok &= seen
    print(f"{'palindrom, kayma VAR + gercek dogrusalsizlik':<44} "
          f"{lin['max_deviation_pct']:>7.2f}% {cor:>11.2f}%      "
          f"{'OK (goruldu)' if seen else 'HATA (silindi)'}")

    # Tek yonlu merdiven: duzeltme UYGULANMAMALI.
    lin = ptc.check_linearity(build(ONE_WAY, -5.0, 0.0), FULL)
    skipped = lin["max_deviation_pct_drift_corrected"] is None
    ok &= skipped
    print(f"{'TEK YONLU merdiven — duzeltme atlanmali':<44} "
          f"{lin['max_deviation_pct']:>7.2f}% "
          f"{'      atlandi  OK' if skipped else '   UYGULANDI  HATA'}")

    print("-" * 78)
    print("SONUC:", "gecti" if ok else "KALDI")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
