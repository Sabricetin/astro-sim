#!/usr/bin/env python3
"""Faz 0.B — tum geceyi tek komutta isler.

Sahadan donunce calistirilacak tek sey bu. Uc alt araci sirayla
cagirir ve sonunda Faz 5'in bekledigi kalibrasyon degerlerini tek
listede toplar.

    python tools/analyze_field_night.py --root data/faz0b \\
        --lat 36.80 --lon 34.62 --elev 10

Beklenen klasor duzeni (docs/saha-talimati.md ile ayni):
    data/faz0b/A1-fon-poz/
    data/faz0b/A2-fon-iso/
    data/faz0b/B-sonum/
    data/faz0b/C-karanlik/

Sira onemli: karanlik akim once olculur, cunku fon hesabi onu
cikarmak icin kullanir.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
PY = sys.executable

# Faz 0.A'da olculen kazanclar. Baska govde icin degistirilecek.
GAINS = {800: 0.2473, 1600: 0.1265, 3200: 0.0655}


def run(script: str, args: list[str]) -> int:
    print(f"\n{'=' * 70}\n  {script}\n{'=' * 70}")
    return subprocess.run([PY, str(HERE / script), *args]).returncode


def load(path: Path):
    return json.loads(path.read_text()) if path.exists() else None


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", required=True, type=Path)
    ap.add_argument("--lat", required=True, type=float)
    ap.add_argument("--lon", required=True, type=float)
    ap.add_argument("--elev", type=float, default=0.0)
    ap.add_argument("--utc-offset", type=float, default=3.0)
    ap.add_argument("--iso", type=int, default=1600)
    args = ap.parse_args()

    out = args.root / "sonuc"
    out.mkdir(parents=True, exist_ok=True)
    gain = GAINS[args.iso]

    # 1. Karanlik akim — once, cunku fon hesabina girdi.
    if (args.root / "C-karanlik").is_dir():
        run("analyze_darks.py", ["--frames", str(args.root / "C-karanlik"),
                                 "--gain", str(gain), "--iso", str(args.iso),
                                 "--out", str(out / "karanlik")])
    dark = load(out / "karanlik.json")
    dark_e = dark["dark_current_e_per_px_per_s"] if dark else None

    # 2. Gokyuzu fonu + dogrusallik + ISO capraz kontrolu.
    for folder, tag in [("A1-fon-poz", "fon-poz"), ("A2-fon-iso", "fon-iso")]:
        if (args.root / folder).is_dir():
            extra = ["--dark-current", str(dark_e)] if dark_e is not None else []
            run("analyze_sky.py", ["--frames", str(args.root / folder)]
                + sum([["--gain-iso", f"{k}={v}"] for k, v in GAINS.items()], [])
                + extra + ["--out", str(out / tag)])

    # 3. Sonum katsayisi + PSF.
    if (args.root / "B-sonum").is_dir():
        run("analyze_extinction.py", ["--frames", str(args.root / "B-sonum"),
                                      "--lat", str(args.lat), "--lon", str(args.lon),
                                      "--elev", str(args.elev),
                                      "--utc-offset", str(args.utc_offset),
                                      "--out", str(out / "sonum")])

    # --- Ozet ---
    sky = load(out / "fon-poz.json") or load(out / "fon-iso.json")
    ext = load(out / "sonum.json")

    print(f"\n{'=' * 70}\n  FAZ 5 ICIN KALIBRASYON DEFTERI\n{'=' * 70}")
    rows = [
        ("k", "sonum katsayisi", "kadir/X",
         ext and ext["extinction_coefficient_k"], "0.B Dizi B"),
        ("FWHM", "yildiz profili", "px",
         ext and ext.get("psf_fwhm_px_median"), "0.B Dizi B"),
        ("I_d", "karanlik akim", "e-/px/s", dark_e, "0.B Dizi C"),
        ("sky_inst", "fon (alet)", "e-/px/s",
         sky and sky.get("sky_e_per_px_per_s"), "0.B Dizi A"),
    ]
    for sym, name, unit, val, src in rows:
        got = f"{val:.5f}" if isinstance(val, (int, float)) else "— OLCULEMEDI"
        print(f"  {sym:<9} {name:<18} {got:>14} {unit:<10} {src}")

    print(f"\n  Hala eksik (bu gece olculemez):")
    print(f"  {'T':<9} {'lens aktarim verimi':<18} {'':>14} {'-':<10} 0.D")
    print(f"  {'QE':<9} {'kuantum verimi':<18} {'':>14} {'e-/foton':<10} 0.D")
    print(f"  {'dV_G':<9} {'bant duzeltmesi':<18} {'':>14} {'kadir':<10} 0.D")
    print(f"  {'mu_sky':<9} {'mutlak fon':<18} {'':>14} {'kadir/as^2':<10} 0.C (VIIRS)")

    summary = {
        "extinction_coefficient_k": ext and ext["extinction_coefficient_k"],
        "psf_fwhm_px": ext and ext.get("psf_fwhm_px_median"),
        "dark_current_e_per_px_per_s": dark_e,
        "sky_instrumental_e_per_px_per_s": sky and sky.get("sky_e_per_px_per_s"),
        "iso": args.iso, "gain_used": gain,
        "site": {"lat": args.lat, "lon": args.lon, "elev_m": args.elev},
    }
    (out / "kalibrasyon.json").write_text(json.dumps(summary, indent=2))
    print(f"\n  ozet: {out / 'kalibrasyon.json'}")
    print(f"\n  Sonraki adim: bu koordinati VIIRS'e sor (0.C), sonra 0.D.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
