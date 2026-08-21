#!/usr/bin/env python3
"""Faz 0.B Dizi A — gokyuzu fonu, dogrusallik ve ISO capraz kontrolu.

Uc soruyu birden cevaplar:

  A1 (poz merdiveni)  Fon poz suresiyle dogru orantili mi?
                      -> 0.A.6'nin laboratuvar testinin yerini alir.
                         Astronomik karanlikta gokyuzu, oda LED'inden
                         cok daha kararli bir kaynak.
  A2 (ISO merdiveni)  Uc ISO'nun ELEKTRON cinsinden fonu ayni mi?
                      -> Faz 0.A'da olculen kazanclarin gokyuzunde de
                         tuttugunun testi. Tutmuyorsa kazanc yanlis.
  Her ikisi           Fonun elektron/piksel/saniye degeri.
                      -> Faz 5'in 'mu_sky' girdisinin alet tarafi.

**Fon parlakligini kadir/arcsec^2'ye cevirmez.** O donusum QE ve T
gerektirir; ikisi de henuz olculmedi. Bu arac aletin gordugunu verir,
mutlak olcek Faz 0.D'de baglanir. Uydurma bir donusum katsayisi
koymaktansa donusumu hic yapmamak dogru.

Kullanim:
    python tools/analyze_sky.py --frames data/faz0b/A1-fon-poz \\
        --gain-iso 800=0.2473 --gain-iso 1600=0.1265 --gain-iso 3200=0.0655 \\
        --bias data/faz0/bias
"""
from __future__ import annotations

import argparse
import json
import subprocess
from datetime import datetime
from pathlib import Path

import numpy as np

import sys
sys.path.insert(0, str(Path(__file__).parent))
import starphot as sp
from sensor_ptc import load_plane, raw_files


def read_meta(paths):
    out = subprocess.run(
        ["exiftool", "-j", "-n", "-ISO", "-ExposureTime", "-ShutterSpeedValue",
         "-CreateDate", "-CameraTemperature", *[str(p) for p in paths]],
        capture_output=True, text=True, check=True).stdout
    return {Path(d["SourceFile"]).name: d for d in json.loads(out)}


def parse_gains(items):
    gains = {}
    for it in items:
        iso, g = it.split("=")
        gains[int(iso)] = float(g)
    return gains


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--frames", required=True, type=Path)
    ap.add_argument("--gain-iso", action="append", required=True,
                    metavar="ISO=GAIN", help="orn. 1600=0.1265, birden cok kez")
    ap.add_argument("--bias-adu", type=float, default=None,
                    help="bias seviyesi; verilmezse uydurmanin kesimi kullanilir")
    ap.add_argument("--dark-current", type=float, default=None,
                    help="e-/px/s; verilirse fondan cikarilir")
    ap.add_argument("--channel", default="G1")
    ap.add_argument("--roi", type=int, default=600,
                    help="merkezden kirpma; vinyetlemeden kacinmak icin")
    ap.add_argument("--out", type=Path, default=Path("data/faz0b/fon"))
    args = ap.parse_args()

    gains = parse_gains(args.gain_iso)
    paths = raw_files(args.frames)
    meta = read_meta(paths)

    rows = []
    for p in paths:
        d = meta[p.name]
        iso = int(d["ISO"])
        if iso not in gains:
            print(f"  ! {p.name}: ISO {iso} icin kazanc verilmedi — atlandi. "
                  f"Olculmemis ISO kullanilamaz.")
            continue
        exp = float(d.get("ShutterSpeedValue") or d["ExposureTime"])
        plane, _ = load_plane(p, args.channel, args.roi)
        # PSF genisligi BU dizinin diyafragminda olculuyor.
        #
        # Onemli: Dizi B genelde kisilmis diyaframla cekilir (parlak
        # yildiz doymasin diye) ve kisik diyaframda yildiz daha keskin
        # olur. Faz 5'in istedigi FWHM ise ASIL cekim diyaframindaki
        # deger — yani buradaki.
        fwhms = []
        for (py, px, pk) in sp.find_stars(plane, threshold_sigma=12.0,
                                          max_stars=12):
            if pk >= 0.95 * 15360:
                continue
            cy, cx = sp.centroid(plane, py, px)
            f = sp.fit_gaussian_fwhm(plane, cy, cx)
            if f is not None:
                fwhms.append(f)
        rows.append({
            "file": p.name, "iso": iso, "exposure_s": exp,
            "median_adu": float(np.median(plane)),
            "fwhm_px": float(np.median(fwhms)) if fwhms else None,
            "star_count": len(fwhms),
            "temp_c": d.get("CameraTemperature"),
            "taken_at": d.get("CreateDate"),
        })
    if len(rows) < 3:
        raise SystemExit(f"Yetersiz kare ({len(rows)}).")

    result = {"faz": "0.B", "dizi": "A", "frames": rows}
    warn = []

    # ---- A1: tek ISO icinde poz merdiveni -> dogrusallik + fon hizi ----
    by_iso = {}
    for r in rows:
        by_iso.setdefault(r["iso"], []).append(r)

    print(f"\n{'ISO':>6} {'poz':>7} {'medyan ADU':>11} {'e-/px/s':>10}")
    print("-" * 40)
    per_iso = {}
    for iso in sorted(by_iso):
        grp = sorted(by_iso[iso], key=lambda r: r["exposure_s"])
        t = np.array([r["exposure_s"] for r in grp])
        y = np.array([r["median_adu"] for r in grp])
        if len(set(np.round(t, 2))) >= 3:
            slope, intercept = np.polyfit(t, y, 1)
            pred = slope * t + intercept
            dev = (y - pred) / np.maximum(pred - intercept, 1) * 100
            maxdev = float(np.max(np.abs(dev)))
        else:
            bias = args.bias_adu
            if bias is None:
                warn.append(f"ISO {iso}: 3'ten az farkli poz — bias bilinmeden "
                            f"fon hizi hesaplanamaz, --bias-adu ver")
                continue
            slope = float(np.mean((y - bias) / t)); intercept = bias
            maxdev = None
        rate_e = float(slope * gains[iso])
        if args.dark_current is not None:
            rate_e -= args.dark_current
        per_iso[iso] = {"adu_per_s": float(slope), "bias_adu": float(intercept),
                        "sky_e_per_px_per_s": rate_e,
                        "linearity_max_dev_pct": maxdev}
        for r in grp:
            print(f"{iso:>6} {r['exposure_s']:7.1f} {r['median_adu']:11.2f} "
                  f"{'':>10}")
        print(f"{'':>6} {'egim':>7} {slope:11.3f} {rate_e:10.4f}"
              + (f"   dogrusallik sapmasi %{maxdev:.2f}" if maxdev is not None else ""))
        print("-" * 40)
        if maxdev is not None and maxdev > 3.0:
            warn.append(f"ISO {iso}: fon poz suresiyle dogru orantili degil "
                        f"(sapma %{maxdev:.1f}). Gokyuzu degisiyor olabilir "
                        f"(alacakaranlik? Ay dogdu mu?) veya doyma var.")

    result["per_iso"] = per_iso

    # ---- A2: ISO capraz kontrolu ----
    if len(per_iso) >= 2:
        rates = {iso: v["sky_e_per_px_per_s"] for iso, v in per_iso.items()}
        vals = np.array(list(rates.values()))
        spread = float((vals.max() - vals.min()) / vals.mean() * 100)
        print(f"\n  ISO CAPRAZ KONTROLU — elektron cinsinden fon ayni cikmali")
        for iso in sorted(rates):
            print(f"    ISO {iso:<5} {rates[iso]:8.4f} e-/px/s")
        print(f"    yayilim {spread:.1f}%")
        result["iso_cross_check_spread_pct"] = spread
        if spread > 15:
            warn.append(f"ISO'lar arasi fon %{spread:.0f} ayrisiyor — Faz 0.A'da "
                        f"olculen kazanclardan biri yanlis olabilir. Bu, kazanc "
                        f"olcumunun gokyuzunde yapilan bagimsiz sinavi.")
        else:
            print(f"    -> kazanc olcumu gokyuzunde dogrulandi")

    # ---- Fon hizi ozeti ----
    if per_iso:
        best = np.mean([v["sky_e_per_px_per_s"] for v in per_iso.values()])
        result["sky_e_per_px_per_s"] = float(best)
        print(f"\n  GOKYUZU FONU = {best:.4f} e-/piksel/saniye")
        print(f"  (Faz 5'in mu_sky girdisinin ALET tarafi; kadir/arcsec^2'ye")
        print(f"   cevrimi QE ve T olculdukten sonra, Faz 0.D'de yapilacak)")

    all_fwhm = [r["fwhm_px"] for r in rows if r["fwhm_px"]]
    if all_fwhm:
        result["psf_fwhm_px_median"] = float(np.median(all_fwhm))
        print(f"\n  PSF genisligi = {np.median(all_fwhm):.2f} px  "
              f"(bu dizinin diyaframinda, {len(all_fwhm)} kare)")
        print(f"  Faz 5 FWHM olarak BUNU bekliyor — Dizi B kisilmis")
        print(f"  diyaframla cekildiyse oradaki deger daha keskin cikar.")

    for w in warn:
        print(f"  ! {w}")
    result["warnings"] = warn

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.with_suffix(".json").write_text(json.dumps(result, indent=2))
    print(f"\n  sonuc: {args.out.with_suffix('.json')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
