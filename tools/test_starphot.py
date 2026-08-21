#!/usr/bin/env python3
"""starphot.py'yi bilinen sentetik yildizlarla dogrular.

Aranan sey: bilinen akisi ve bilinen FWHM'i geri kazanabiliyor muyuz.
Kazanamiyorsak sahadan gelen k ve FWHM degerleri de yanlis olur ve
bunu anlamanin baska yolu yok.
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
import starphot as sp

RNG = np.random.default_rng(20260822)


def make_frame(stars, size=256, sky=500.0, noise=8.0, fwhm=3.0):
    """stars: (y, x, toplam_akis) listesi."""
    yy, xx = np.mgrid[0:size, 0:size]
    img = np.full((size, size), sky, dtype=float)
    sigma = fwhm / 2.3548
    for y, x, flux in stars:
        # Toplam akisi flux olan 2B Gaussian: tepe = flux/(2 pi sigma^2)
        amp = flux / (2 * np.pi * sigma ** 2)
        img += amp * np.exp(-((yy - y) ** 2 + (xx - x) ** 2) / (2 * sigma ** 2))
    return img + RNG.normal(0, noise, img.shape)


def main() -> int:
    ok = True

    # --- 1. Fon tahmini yildizlardan etkilenmemeli ---
    img = make_frame([(60, 60, 2e5), (180, 190, 1e5)], sky=500.0, noise=8.0)
    bg, nz = sp.estimate_background(img)
    good = abs(bg - 500) < 2 and abs(nz - 8) < 1.5
    ok &= good
    print(f"{'fon tahmini':<34} {bg:8.2f} (gercek 500)   "
          f"gurultu {nz:5.2f} (gercek 8)   {'OK' if good else 'HATA'}")

    # --- 2. Yildiz bulma ---
    truth = [(60, 60, 2e5), (180, 190, 1e5), (100, 200, 4e4)]
    img = make_frame(truth)
    peaks = sp.find_stars(img)
    found = len(peaks) == 3
    ok &= found
    print(f"{'yildiz bulma':<34} {len(peaks)} bulundu (gercek 3)"
          f"{'':<18}{'OK' if found else 'HATA'}")

    # --- 3. Merkez hassasiyeti (yarim piksel kaydirilmis) ---
    img = make_frame([(80.4, 120.7, 2e5)])
    peaks = sp.find_stars(img)
    cy, cx = sp.centroid(img, peaks[0][0], peaks[0][1])
    err = np.hypot(cy - 80.4, cx - 120.7)
    good = err < 0.15
    ok &= good
    print(f"{'merkez hatasi':<34} {err:8.3f} px"
          f"{'':<22}{'OK' if good else 'HATA'}")

    # --- 4. FWHM geri kazanimi ---
    print()
    for true_fwhm in [1.5, 2.5, 4.0, 6.0]:
        img = make_frame([(128, 128, 3e5)], fwhm=true_fwhm)
        peaks = sp.find_stars(img)
        cy, cx = sp.centroid(img, peaks[0][0], peaks[0][1])
        got = sp.fit_gaussian_fwhm(img, cy, cx, box=max(9, int(3 * true_fwhm)))
        err = abs(got - true_fwhm) / true_fwhm * 100
        good = err < 5
        ok &= good
        print(f"{'FWHM ' + str(true_fwhm) + ' px':<34} {got:8.3f} px   "
              f"hata {err:5.2f}%          {'OK' if good else 'HATA'}")

    # --- 5. Akis geri kazanimi ---
    print()
    for true_flux in [4e4, 1e5, 5e5]:
        img = make_frame([(128, 128, true_flux)], fwhm=3.0)
        peaks = sp.find_stars(img)
        m = sp.measure_star(img, peaks[0][0], peaks[0][1])
        err = (m["flux_adu"] - true_flux) / true_flux * 100
        # 1.5*FWHM yaricapli aciklik Gaussian'in ~%96'sini toplar.
        # Sistematik eksiklik BEKLENIYOR; onemli olan SABIT olmasi,
        # cunku sonum olcumu akis ORANLARINA bakiyor.
        good = -8 < err < 1
        ok &= good
        print(f"{'akis ' + f'{true_flux:.0e}':<34} {m['flux_adu']:10.0f}   "
              f"sapma {err:+6.2f}%      {'OK' if good else 'HATA'}")

    # --- 6. KRITIK: akis oranlari korunuyor mu ---
    # Sonum olcumu mutlak akisi degil, yuksekligle DEGISIMI kullanir.
    # Aciklik kaybi sabitse oranlar bozulmaz.
    print()
    ratios = []
    for f in [1e5, 5e4, 2.5e4]:
        img = make_frame([(128, 128, f)], fwhm=3.0)
        peaks = sp.find_stars(img)
        ratios.append(sp.measure_star(img, peaks[0][0], peaks[0][1])["flux_adu"] / f)
    spread = (max(ratios) - min(ratios)) / np.mean(ratios) * 100
    good = spread < 2.0
    ok &= good
    print(f"{'aciklik kaybi sabit mi':<34} yayilim {spread:5.2f}%"
          f"{'':<15}{'OK' if good else 'HATA'}")

    # --- 7. Kadir farki dogru olculuyor mu ---
    img_bright = make_frame([(128, 128, 1e5)], fwhm=3.0)
    img_faint = make_frame([(128, 128, 1e5 / 2.512)], fwhm=3.0)  # tam 1 kadir
    pb = sp.find_stars(img_bright); pf = sp.find_stars(img_faint)
    mb = sp.measure_star(img_bright, pb[0][0], pb[0][1])["instrumental_mag"]
    mf = sp.measure_star(img_faint, pf[0][0], pf[0][1])["instrumental_mag"]
    dm = mf - mb
    good = abs(dm - 1.0) < 0.02
    ok &= good
    print(f"{'1 kadir farki':<34} {dm:8.4f} kadir"
          f"{'':<18}{'OK' if good else 'HATA'}")

    print()
    print("SONUC:", "TUM TESTLER GECTI" if ok else "KALDI")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
