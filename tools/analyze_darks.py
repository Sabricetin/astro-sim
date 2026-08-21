#!/usr/bin/env python3
"""Faz 0.B Dizi C — karanlik akim I_d.

Kapak takili cekilen karelerde sinyal yalnizca iki seyden gelir: bias
(sabit) ve karanlik akim (poz suresiyle orantili).

    ADU(t) = bias + I_d/g · t

Egim, kazancla carpilinca elektron/piksel/saniye verir.

Neden onemli: karanlik akim sicaklikla kabaca her 6 derecede iki katina
cikar, yani laboratuvar degeri sahada gecerli olmaz. Sensor sicakligi
EXIF'te zaten kayitli; bu arac onu da raporlar.

Kullanim:
    python tools/analyze_darks.py --frames data/faz0b/C-karanlik \\
        --gain 0.1265 --iso 1600
"""
from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path

import numpy as np

import sys
sys.path.insert(0, str(Path(__file__).parent))
from sensor_ptc import load_plane, raw_files


def read_meta(paths):
    out = subprocess.run(
        ["exiftool", "-j", "-n", "-ISO", "-ExposureTime", "-ShutterSpeedValue",
         "-CameraTemperature", *[str(p) for p in paths]],
        capture_output=True, text=True, check=True).stdout
    return {Path(d["SourceFile"]).name: d for d in json.loads(out)}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--frames", required=True, type=Path)
    ap.add_argument("--gain", required=True, type=float, help="e-/ADU (Faz 0.A)")
    ap.add_argument("--iso", type=int, default=None)
    ap.add_argument("--channel", default="G1")
    ap.add_argument("--roi", type=int, default=0, help="0 = tum kare")
    ap.add_argument("--out", type=Path, default=Path("data/faz0b/karanlik"))
    args = ap.parse_args()

    paths = raw_files(args.frames)
    meta = read_meta(paths)
    rows = []
    for p in paths:
        d = meta[p.name]
        if args.iso and int(d.get("ISO", 0)) != args.iso:
            continue
        exp = float(d.get("ShutterSpeedValue") or d["ExposureTime"])
        plane, _ = load_plane(p, args.channel, args.roi)
        rows.append({
            "file": p.name, "exposure_s": exp,
            "mean_adu": float(np.mean(plane)),
            "median_adu": float(np.median(plane)),
            # Sicak pikseller ortalamayi ceker; medyan tipik pikseli
            # temsil eder. Ikisinin farki sicak piksel oranini gosterir.
            "hot_fraction": float(np.mean(plane > np.median(plane) + 50)),
            "temp_c": d.get("CameraTemperature"),
        })
    if len(rows) < 3:
        raise SystemExit(f"En az 3 farkli poz gerekiyor, {len(rows)} kare bulundu.")

    t = np.array([r["exposure_s"] for r in rows])
    if len(set(np.round(t, 3))) < 3:
        raise SystemExit("Karanlik kareler en az 3 FARKLI poz suresinde olmali.")

    # Medyan kullaniliyor: sicak pikseller egimi sisirir ve tipik
    # pikselin karanlik akimini yanlis gosterir.
    y = np.array([r["median_adu"] for r in rows])
    slope, bias = np.polyfit(t, y, 1)
    pred = slope * t + bias
    resid = y - pred
    ss = float(np.sum((y - y.mean()) ** 2))
    r2 = 1.0 - float(np.sum(resid ** 2)) / ss if ss > 0 else float("nan")

    dark_e = float(slope * args.gain)
    temps = [r["temp_c"] for r in rows if r["temp_c"] is not None]

    print(f"{'kare':<16} {'poz':>7} {'medyan':>9} {'ortalama':>9} "
          f"{'sicak%':>7} {'C':>4} {'artik':>7}")
    print("-" * 66)
    for r, e in zip(rows, resid):
        print(f"{r['file']:<16} {r['exposure_s']:7.2f} {r['median_adu']:9.2f} "
              f"{r['mean_adu']:9.2f} {r['hot_fraction']*100:6.3f}% "
              f"{r['temp_c'] if r['temp_c'] is not None else '?':>4} {e:+7.3f}")
    print("-" * 66)
    print(f"\n  KARANLIK AKIM  I_d = {dark_e:.5f} e-/piksel/saniye")
    print(f"                      = {slope:.5f} ADU/s  (kazanc {args.gain} e-/ADU)")
    print(f"  bias kesimi          = {bias:.2f} ADU")
    print(f"  uydurma kalitesi R^2 = {r2:.5f}")
    if temps:
        print(f"  sensor sicakligi     = {min(temps)}-{max(temps)} C  "
              f"(karanlik akim bu sicaklikta gecerli)")

    warn = []
    if r2 < 0.9:
        warn.append("R^2 dusuk — karanlik kareler isik sizdirmis olabilir "
                    "(vizor kapali miydi?)")
    if dark_e < 0:
        warn.append("karanlik akim NEGATIF cikti — fiziksel degil. En olasi "
                    "sebep: makinede Uzun Poz Parazit Azaltma acik kalmis ve "
                    "makine kendi karanlik karesini zaten cikarmis.")
    if any(r["hot_fraction"] > 0.01 for r in rows):
        warn.append("sicak piksel orani %1'in uzerinde — Faz 5'te sicak piksel "
                    "maskesi gerekebilir")
    for w in warn:
        print(f"  ! {w}")

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.with_suffix(".json").write_text(json.dumps({
        "faz": "0.B", "dizi": "C",
        "dark_current_e_per_px_per_s": dark_e,
        "dark_current_adu_per_s": float(slope),
        "bias_intercept_adu": float(bias),
        "gain_used": args.gain, "r_squared": r2,
        "temperature_c_range": [min(temps), max(temps)] if temps else None,
        "frames": rows, "warnings": warn,
    }, indent=2))
    print(f"\n  sonuc: {args.out.with_suffix('.json')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
