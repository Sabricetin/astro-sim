#!/usr/bin/env python3
"""Faz 0.B Dizi B — atmosferik sonum katsayisi k.

Bouguer dogrusu: ayni yildizin aleti kadiri hava kutlesiyle dogrusal
artar.

    m_alet(X) = m_0 + k · X

Egim k, aradigimiz sey. Sonum katsayisi zincirdeki EN KRITIK eksik
buyukluk: yere ve geceye gore 0.15 (yuksek, kuru) ile 0.60 (sahil,
puslu) arasinda degisiyor ve asil hedef 24 derecede, yani X=2.4'te
duruyor. Kitabi bir deger kullanmak orada iki kat hata demek.

Kullanim:
    python tools/analyze_extinction.py --frames data/faz0b/B-sonum \\
        --lat 36.80 --lon 34.62 --elev 10 --utc-offset 3

Varsayilan hedef Vega. Baska yildiz icin --ra/--dec ver.
"""
from __future__ import annotations

import argparse
import json
import subprocess
from datetime import datetime, timedelta
from pathlib import Path

import numpy as np
from scipy.optimize import least_squares

import sys
sys.path.insert(0, str(Path(__file__).parent))
import starphot as sp
from sensor_ptc import load_plane, raw_files

# Vega (alpha Lyr), J2000.
VEGA_RA_DEG = 279.23473
VEGA_DEC_DEG = 38.78369


def airmass_kasten_young(altitude_deg: float) -> float:
    """Kasten & Young (1989). astro_core'daki ile ayni bagintı —
    olcum ile modelin ayni tanimi kullanmasi sart, yoksa k yanlis
    olcege oturur."""
    z = 90.0 - altitude_deg
    if z >= 96.07995:
        return float("inf")
    return 1.0 / (np.cos(np.radians(z)) + 0.50572 * (96.07995 - z) ** -1.6364)


def read_meta(paths: list[Path]) -> dict:
    out = subprocess.run(
        ["exiftool", "-j", "-n", "-ISO", "-ExposureTime", "-ShutterSpeedValue",
         "-CreateDate", "-FNumber", "-FocalLength", *[str(p) for p in paths]],
        capture_output=True, text=True, check=True).stdout
    return {Path(d["SourceFile"]).name: d for d in json.loads(out)}


def altitude_of(ra_deg, dec_deg, when_utc, lat, lon, elev):
    from astropy.coordinates import EarthLocation, SkyCoord, AltAz
    from astropy.time import Time
    import astropy.units as u
    loc = EarthLocation(lat=lat * u.deg, lon=lon * u.deg, height=elev * u.m)
    # Cerceve: yildiz katalogu J2000/ICRS. Presesyon astropy'de yapiliyor.
    star = SkyCoord(ra=ra_deg * u.deg, dec=dec_deg * u.deg, frame="icrs")
    # pressure=0 -> kirilma UYGULANMAZ. Kasten-Young zaten gercek isik
    # yolunu yaklasikliyor; ikisini ust uste koymak cift sayardi.
    altaz = star.transform_to(AltAz(obstime=Time(when_utc), location=loc,
                                    pressure=0))
    return float(altaz.alt.deg), float(altaz.az.deg)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--frames", required=True, type=Path)
    ap.add_argument("--lat", required=True, type=float, help="enlem, derece")
    ap.add_argument("--lon", required=True, type=float, help="boylam, DOGU pozitif")
    ap.add_argument("--elev", type=float, default=0.0, help="rakim, metre")
    ap.add_argument("--utc-offset", type=float, default=3.0,
                    help="makine saatinin UTC farki (Turkiye: 3)")
    ap.add_argument("--ra", type=float, default=VEGA_RA_DEG)
    ap.add_argument("--dec", type=float, default=VEGA_DEC_DEG)
    ap.add_argument("--target-mag", type=float, default=0.03,
                    help="hedef yildizin V kadiri (Vega: 0.03). Sifir noktasi "
                         "bundan hesaplanir.")
    ap.add_argument("--channel", default="G1")
    ap.add_argument("--center-fraction", type=float, default=0.5,
                    help="hedefin arandigi merkezi bolge orani")
    ap.add_argument("--white-level", type=float, default=15360.0)
    ap.add_argument("--out", type=Path, default=Path("data/faz0b/sonum"))
    args = ap.parse_args()

    paths = raw_files(args.frames)
    if len(paths) < 6:
        raise SystemExit(f"En az 6 kare gerekiyor, {len(paths)} bulundu.")
    meta = read_meta(paths)

    print(f"konum: {args.lat:.5f}, {args.lon:.5f}  rakim {args.elev:.0f} m")
    print(f"hedef: RA {args.ra:.4f}  Dec {args.dec:.4f}")
    print(f"{len(paths)} kare\n")

    # --- 1. gecis: her karedeki merkezi yildizlari parlaklik sirasiyla topla
    #
    # Hedef yildizi dogrudan "en parlak" diye secmek calismaz: genis acida
    # parlak yildizlar DOYAR. Vega 14 mm f/2.8 15 s'de dolum kapasitesini
    # 161 kat asiyor ve doymus yildizin fotometrisi anlamsizdir.
    #
    # Cozum: yildizlarin BAGIL parlakligi kare kare degismedigi icin
    # siralama kararlidir. Butun karelerde doymamis kalan en parlak
    # SIRAYI bulup onu kullaniyoruz. Boylece her karede ayni fiziksel
    # yildiz olculmus oluyor.
    scans, skipped = [], []
    for p in paths:
        d = meta[p.name]
        exp = float(d.get("ShutterSpeedValue") or d["ExposureTime"])
        local = datetime.strptime(d["CreateDate"], "%Y:%m:%d %H:%M:%S")
        utc = local - timedelta(hours=args.utc_offset) + timedelta(seconds=exp / 2)
        alt, az = altitude_of(args.ra, args.dec, utc, args.lat, args.lon, args.elev)
        if alt <= 3:
            skipped.append(f"{p.name}: hedef {alt:.1f} derecede")
            continue
        plane, _ = load_plane(p, args.channel, roi=0)
        h, w = plane.shape
        peaks = sp.find_stars(plane, threshold_sigma=10.0, max_stars=40)
        f = args.center_fraction
        cy0, cx0 = h * (1 - f) / 2, w * (1 - f) / 2
        central = [
            pk for pk in peaks
            if cy0 <= pk[0] <= h - cy0 and cx0 <= pk[1] <= w - cx0
        ]
        if not central:
            skipped.append(f"{p.name}: merkezde yildiz yok")
            continue
        scans.append({"path": p, "plane": plane, "central": central, "exp": exp,
                      "utc": utc, "alt": alt, "az": az})

    if not scans:
        raise SystemExit("Hicbir karede merkezde yildiz bulunamadi.")

    sat = 0.95 * args.white_level
    ranks = min(len(sc["central"]) for sc in scans)
    chosen = None
    for r in range(ranks):
        if all(sc["central"][r][2] < sat for sc in scans):
            chosen = r
            break
    if chosen is None:
        raise SystemExit(
            "Butun karelerde merkezdeki yildizlarin HEPSI doymus.\n"
            "  Fotometri yapilamaz. Diyaframi kis veya pozu kisalt;\n"
            "  once tools/check_star.py ile tek kare kontrol et."
        )
    if chosen > 0:
        print(f"  not: en parlak {chosen} yildiz doymus, {chosen + 1}. sira "
              f"kullaniliyor (bagil siralama kare kare degismez)")

    # --- 2. gecis: secilen sirayi butun karelerde olc
    rows = []
    for sc in scans:
        y, x, peak = sc["central"][chosen]
        m = sp.measure_star(sc["plane"], y, x)
        if m is None:
            skipped.append(f"{sc['path'].name}: olcum basarisiz")
            continue
        mag = -2.5 * np.log10(m["flux_adu"] / sc["exp"])
        X = airmass_kasten_young(sc["alt"])
        rows.append({"file": sc["path"].name, "utc": sc["utc"].isoformat(),
                     "exposure_s": sc["exp"], "altitude_deg": sc["alt"],
                     "azimuth_deg": sc["az"], "airmass": X,
                     "flux_adu": m["flux_adu"], "fwhm_px": m["fwhm_px"],
                     "peak_adu": float(peak), "instrumental_mag": float(mag)})
    for sk in skipped:
        print(f"  ! {sk} — atlandi")

    if len(rows) < 4:
        raise SystemExit(f"Uydurmak icin yetersiz kare ({len(rows)}).")

    X = np.array([r["airmass"] for r in rows])
    m = np.array([r["instrumental_mag"] for r in rows])

    # Saglam uydurma: ince bulut gecen kareyi disari itsin diye soft_l1.
    def resid(p):
        return m - (p[0] + p[1] * X)
    fit = least_squares(resid, [m.mean(), 0.25], loss="soft_l1", f_scale=0.05)
    m0, k = fit.x
    res = resid(fit.x)
    rms = float(np.sqrt(np.mean(res ** 2)))

    # Belirsizlik
    J = fit.jac
    dof = max(len(X) - 2, 1)
    cov = np.linalg.inv(J.T @ J) * float(np.sum(res ** 2)) / dof
    k_err = float(np.sqrt(cov[1, 1]))

    print(f"\n{'kare':<16} {'yuk':>6} {'X':>6} {'akis':>10} {'FWHM':>6} {'artik':>7}")
    print("-" * 60)
    for r, e in zip(rows, res):
        flag = "  <-- sapkin" if abs(e) > 3 * rms else ""
        print(f"{r['file']:<16} {r['altitude_deg']:5.1f}° {r['airmass']:6.2f} "
              f"{r['flux_adu']:10.0f} "
              f"{(r['fwhm_px'] or 0):6.2f} {e:+7.3f}{flag}")
    print("-" * 60)
    # --- Fotometrik sifir noktasi ---
    #
    # m_alet = m0 + k*X uydurmasinda m0, yildizin atmosfer disi ALETI
    # kadiri. Gercek kadiri biliniyorsa fark sabittir:
    #
    #     ZP = V_gercek - m0
    #     m_yerdeki = m_alet + ZP
    #
    # Bu tek sayi QE, lens verimi ve aciklik alanini BIRLIKTE tasiyor.
    # Ayri ayri olculemezler, ama zincirin ihtiyaci zaten carpimlari.
    #
    # Ayni ZP gokyuzu fonuna da uygulanir — cunku ikisi de ayni optikten,
    # ayni gecede, yerde olculdu. Fona sonum duzeltmesi UYGULANMAZ:
    # yildiz isigi atmosferden gecerek gelir, fon atmosferin kendi isigi.
    zp = None
    if args.target_mag is not None:
        zp = float(args.target_mag - m0)

    print(f"\n  SONUM KATSAYISI  k = {k:.4f} +- {k_err:.4f} kadir / hava kutlesi")
    print(f"  atmosfer disi     m0 = {m0:.4f}")
    if zp is not None:
        print(f"  SIFIR NOKTASI     ZP = {zp:.4f}  "
              f"(hedef V={args.target_mag})")
        print(f"     m_yerdeki = m_alet + ZP")
        print(f"     Bu sayi QE, lens verimi ve aciklik alanini birlikte")
        print(f"     tasiyor. Gokyuzu fonunu kadir/arcsec^2'ye cevirmek icin")
        print(f"     analyze_sky.py'ye --zero-point {zp:.4f} olarak ver.")
    print(f"  artik RMS            = {rms:.4f} kadir")
    print(f"  kaldirac          X = {X.min():.2f} .. {X.max():.2f}")

    warn = []
    if X.max() - X.min() < 1.0:
        warn.append("hava kutlesi kaldiraci 1'den kucuk — k belirsizligi buyur. "
                    "Hedefi daha alcaga kadar takip et.")
    if rms > 0.05:
        warn.append(f"artik RMS {rms:.3f} kadir — bulut gecmis olabilir. "
                    f"Sapkin kareleri cikarip tekrar bak.")
    if k < 0.10:
        warn.append("k beklenenden kucuk (<0.10) — hedef yanlis yildiz olabilir "
                    "veya bazi karelerde doyma var.")
    if k > 0.70:
        warn.append("k cok buyuk (>0.70) — pus/bulut veya isik kirliligi "
                    "fotometriye karisiyor olabilir.")
    if chosen > 0 and zp is not None:
        warn.append(f"SIFIR NOKTASI GECERSIZ: hedef yildiz doymus oldugu icin "
                    f"{chosen + 1}. siradaki BASKA bir yildiz olculdu ve onun "
                    f"gercek kadiri bilinmiyor. k gecerli, ZP degil. "
                    f"Sifir noktasi icin hedefin doymadigi bir kare gerekli.")
    for w in warn:
        print(f"  ! {w}")

    fwhms = [r["fwhm_px"] for r in rows if r["fwhm_px"]]
    if fwhms:
        print(f"\n  YAN URUN — PSF genisligi: medyan {np.median(fwhms):.2f} px "
              f"(yayilim {np.min(fwhms):.2f}-{np.max(fwhms):.2f})")
        print(f"  Faz 5 bunu 'FWHM' olarak bekliyor.")

    args.out.parent.mkdir(parents=True, exist_ok=True)
    result = {
        "faz": "0.B", "dizi": "B",
        "extinction_coefficient_k": float(k),
        "k_uncertainty": k_err,
        "zero_point_m0": float(m0),
        "photometric_zero_point": zp if chosen == 0 else None,
        "target_magnitude": args.target_mag,
        "residual_rms_mag": rms,
        "airmass_range": [float(X.min()), float(X.max())],
        "psf_fwhm_px_median": float(np.median(fwhms)) if fwhms else None,
        "star_rank_used": chosen,
        "frames": rows,
        "warnings": warn,
    }
    args.out.with_suffix(".json").write_text(json.dumps(result, indent=2))
    print(f"\n  sonuc: {args.out.with_suffix('.json')}")

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        fig, ax = plt.subplots(figsize=(7, 5))
        ax.plot(X, m, "o", label="olcum")
        xs = np.linspace(X.min(), X.max(), 50)
        ax.plot(xs, m0 + k * xs, "-",
                label=f"k = {k:.3f} ± {k_err:.3f} kadir/X")
        ax.invert_yaxis()
        ax.set_xlabel("hava kutlesi X")
        ax.set_ylabel("aleti kadir (parlak yukarida)")
        ax.set_title("Bouguer dogrusu — atmosferik sonum")
        ax.legend(); ax.grid(alpha=0.3)
        fig.tight_layout()
        fig.savefig(args.out.with_suffix(".png"), dpi=120)
        print(f"  grafik: {args.out.with_suffix('.png')}")
    except Exception as e:
        print(f"  (grafik cizilemedi: {e})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
