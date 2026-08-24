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
from datetime import datetime
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
    ap.add_argument("--target-mag", type=float, default=0.03,
                    help="Dizi B'deki hedef yildizin V kadiri (Vega: 0.03)")
    ap.add_argument("--pixel-pitch-um", type=float, default=3.72)
    ap.add_argument("--focal-length-mm", type=float, default=18.0,
                    help="Dizi A'nin odak uzunlugu (kit lens: 18)")
    ap.add_argument("--focal-length-b-mm", type=float, default=None,
                    help="Dizi B'nin odak uzunlugu (verilmezse A ile ayni)")
    args = ap.parse_args()

    if args.focal_length_b_mm is None:
        args.focal_length_b_mm = args.focal_length_mm
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

    # 2. Sonum katsayisi + sifir noktasi + PSF.
    #
    # Fon hesabindan ONCE: mutlak fon parlakligi sifir noktasina bagli.
    if (args.root / "B-sonum").is_dir():
        run("analyze_extinction.py", ["--frames", str(args.root / "B-sonum"),
                                      "--lat", str(args.lat), "--lon", str(args.lon),
                                      "--elev", str(args.elev),
                                      "--utc-offset", str(args.utc_offset),
                                      "--target-mag", str(args.target_mag),
                                      # Tanima: olculen yildizin gercek
                                      # kadirini katalogdan al. Hedef doymus
                                      # olsa bile sifir noktasi kurtulur.
                                      "--focal", str(args.focal_length_b_mm),
                                      "--pixel-pitch", str(args.pixel_pitch_um),
                                      "--out", str(out / "sonum")])
    ext = load(out / "sonum.json")
    zp = ext.get("photometric_zero_point") if ext else None

    # 3. Gokyuzu fonu + dogrusallik + ISO capraz kontrolu.
    scale = 206.265 * args.pixel_pitch_um / args.focal_length_mm
    for folder, tag in [("A1-fon-poz", "fon-poz"), ("A2-fon-iso", "fon-iso")]:
        if (args.root / folder).is_dir():
            extra = ["--dark-current", str(dark_e)] if dark_e is not None else []
            if zp is not None:
                extra += ["--zero-point", str(zp),
                          "--arcsec-per-pixel", f"{scale:.4f}"]
                zp_n = ext.get("zero_point_f_number") if ext else None
                if zp_n:
                    extra += ["--zero-point-fnumber", str(zp_n)]
            run("analyze_sky.py", ["--frames", str(args.root / folder)]
                + sum([["--gain-iso", f"{k}={v}"] for k, v in GAINS.items()], [])
                + extra + ["--out", str(out / tag)])

    # --- Ozet ---
    sky = load(out / "fon-poz.json") or load(out / "fon-iso.json")

    print(f"\n{'=' * 70}\n  FAZ 5 ICIN KALIBRASYON DEFTERI\n{'=' * 70}")
    rows = [
        ("k", "sonum katsayisi", "kadir/X",
         ext and ext["extinction_coefficient_k"], "0.B Dizi B"),
        # FWHM tercihen Dizi A'dan: asil cekim diyaframindaki deger o.
        # Dizi B kisilmis diyaframla cekilir (parlak yildiz doymasin
        # diye) ve orada yildiz haksiz yere keskin cikar.
        ("FWHM", "yildiz profili", "px",
         (sky and sky.get("psf_fwhm_px_median"))
         or (ext and ext.get("psf_fwhm_px_median")),
         "0.B Dizi A (asil diyafram)"),
        ("I_d", "karanlik akim", "e-/px/s", dark_e, "0.B Dizi C"),
        ("sky_inst", "fon (alet)", "e-/px/s",
         sky and sky.get("sky_e_per_px_per_s"), "0.B Dizi A"),
        ("ZP", "fotometrik sifir nk", "kadir",
         ext and ext.get("photometric_zero_point"),
         "0.B Dizi B" + (
             f" [HR {ext['identified_star']['hr']}]"
             if ext and ext.get("identified_star") else "")),
        ("mu_sky", "fon (mutlak)", "kadir/as^2",
         sky and sky.get("sky_mag_per_sq_arcsec"), "0.B A+B birlikte"),
    ]
    for sym, name, unit, val, src in rows:
        got = f"{val:.5f}" if isinstance(val, (int, float)) else "— OLCULEMEDI"
        print(f"  {sym:<9} {name:<18} {got:>14} {unit:<10} {src}")

    print(f"\n  Hala eksik:")
    print(f"  {'dV_G':<9} {'bant duzeltmesi':<18} {'':>14} {'kadir':<10} 0.D")
    print(f"\n  QE ve T ayri ayri OLCULMUYOR — ZP ikisini birlikte tasiyor.")
    print(f"  Zincirin ihtiyaci zaten carpimlari; ayirmak laboratuvar isi.")

    # Bu dosya dogrudan uygulamaya yapistiriliyor. Her sayinin yaninda
    # KAYNAGI da gidiyor: uygulama kaynagi olmayan degeri kabul etmiyor.
    # "Sihirli sayi yasak — her sabitin yaninda birimi ve kaynagi"
    # kuralinin dosya bicimine gecmis hali.
    src = f"Faz 0.B, {args.root.name}, ISO {args.iso}"
    summary = {
        "format": "astro-sim-kalibrasyon",
        "version": 1,
        "source": src,
        "measured_at": datetime.now().strftime("%Y-%m-%d"),
        "extinction_coefficient_k": ext and ext["extinction_coefficient_k"],
        "extinction_k_uncertainty": ext and ext.get("k_uncertainty"),
        "zero_point_f_number": ext and ext.get("zero_point_f_number"),
        "identified_star_hr": (ext and ext.get("identified_star") or {}).get("hr"),
        "psf_fwhm_px": (sky and sky.get("psf_fwhm_px_median"))
        or (ext and ext.get("psf_fwhm_px_median")),
        "dark_current_e_per_px_per_s": dark_e,
        "sky_instrumental_e_per_px_per_s": sky and sky.get("sky_e_per_px_per_s"),
        "photometric_zero_point": ext and ext.get("photometric_zero_point"),
        "sky_mag_per_sq_arcsec": sky and sky.get("sky_mag_per_sq_arcsec"),
        "iso": args.iso, "gain_used": gain,
        "focal_length_mm": args.focal_length_mm,
        "pixel_pitch_um": args.pixel_pitch_um,
        "site": {"lat": args.lat, "lon": args.lon, "elev_m": args.elev},
    }
    (out / "kalibrasyon.json").write_text(json.dumps(summary, indent=2))
    print(f"\n  ozet: {out / 'kalibrasyon.json'}")
    print(f"  Bu dosyanin ICERIGINI uygulamadaki Kalibrasyon sekmesine")
    print(f"  yapistir; rapor gercek sayilarla dolar.")
    print(f"\n  Sonraki adim: bu koordinati VIIRS'e sor (0.C), sonra 0.D.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
