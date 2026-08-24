#!/usr/bin/env python3
"""identify_stars.py'yi GERCEK katalogla sentetik kare uzerinde dogrular.

Bilinen bir donme acisi, bilinen bir merkez ve gercek BSC5 yildizlariyla
kare uretilir; arac o parametreleri geri kazanmali ve yildizlari DOGRU
eslestirmeli.

Onemli: yildiz konumlari sentetik degil — katalogdan geliyor. Yani test
sadece matematigi degil, katalogla olan baglantiyi da siniyor.
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
import bsc5
import identify_stars as ident

RNG = np.random.default_rng(20260822)
W, H = 720, 480              # G1 duzlemi (sensorun yarisi)
PITCH, FOCAL = 3.72, 14.0
WHITE = 15360.0
SKY, NOISE = 600.0, 8.0


def build_frame(ra0, dec0, roll, parity, mag_limit=6.0, fwhm=2.2,
                saturate_brightest=False, missing=0, spurious=0):
    """Gercek katalog yildizlarindan sahte kare uretir."""
    pitch = PITCH * 2                      # CFA tek kanal
    scale = (206.265 * pitch / FOCAL) / 3600.0
    cat = bsc5.load().brighter_than(mag_limit)
    px, py = ident.project_to_pixels(cat, ra0, dec0, roll, parity,
                                     scale, W / 2, H / 2)
    inside = (np.isfinite(px) & (px > 12) & (px < W - 12)
              & (py > 12) & (py < H - 12))
    idx = np.where(inside)[0]
    # Kadraja gore parlaklik sirasi
    idx = idx[np.argsort(cat.vmag[idx])]

    img = np.full((H, W), SKY)
    yy, xx = np.mgrid[0:H, 0:W]
    sigma = fwhm / 2.3548
    truth = []
    drop = set(RNG.choice(len(idx), min(missing, len(idx)), replace=False)) \
        if missing else set()
    for rank, j in enumerate(idx):
        if rank in drop:
            continue
        # V=6 -> zayif, V=0 -> parlak. Tepe degeri kadire gore.
        peak = 300 * 10 ** (-0.4 * (cat.vmag[j] - 6.0))
        if saturate_brightest and rank == 0:
            peak *= 200
        img += peak * np.exp(-((yy - py[j]) ** 2 + (xx - px[j]) ** 2)
                             / (2 * sigma ** 2))
        truth.append({"hr": int(cat.hr[j]), "x": float(px[j]), "y": float(py[j]),
                      "vmag": float(cat.vmag[j])})
    for _ in range(spurious):
        sx, sy = RNG.uniform(20, W - 20), RNG.uniform(20, H - 20)
        img += 800 * np.exp(-((yy - sy) ** 2 + (xx - sx) ** 2) / (2 * sigma ** 2))
    img = np.clip(img + RNG.normal(0, NOISE, img.shape), 0, WHITE)
    return img, truth


def check(label, ra0, dec0, roll, parity, pointing_error_deg=0.0, **kw):
    """[pointing_error_deg]: kullanicinin sandigi merkez ile gercek
    merkez arasindaki fark. Elle nisan alan biri 5-15 derece rahat
    sasar; arac buna dayanikli olmali."""
    img, truth = build_frame(ra0, dec0, roll, parity, **kw)
    guess_ra = ra0 + pointing_error_deg / np.cos(np.radians(dec0))
    sol, detected, cat = ident.identify(img, guess_ra, dec0, FOCAL, PITCH,
                                        mag_limit=kw.get("mag_limit", 6.0))
    if sol is None:
        print(f"{label:<42} COZUM YOK")
        return False
    truth_hr = {t["hr"] for t in truth}
    matched_hr = {int(cat.hr[j]) for _, j, _ in sol.matches}
    correct = len(matched_hr & truth_hr)
    wrong = len(matched_hr - truth_hr)
    droll = abs(((sol.roll_deg - roll + 180) % 360) - 180)
    ok = (correct >= max(4, int(0.6 * len(truth))) and wrong == 0
          and droll < 1.0 and sol.parity == parity)
    print(f"{label:<42} {correct:>3}/{len(truth):<3} dogru  {wrong} yanlis  "
          f"donme hata {droll:5.2f}°  RMS {sol.rms_px:4.2f}px  "
          f"{'OK' if ok else 'HATA'}")
    return ok


def main() -> int:
    ok = True
    print("Gercek BSC5 yildizlariyla uretilmis sentetik kareler")
    print("-" * 92)

    # Vega bolgesi, cesitli donme acilari ve iki parite
    for roll in [0.0, 37.5, 130.0, 245.0, 310.0]:
        ok &= check(f"Vega bolgesi, donme {roll:.0f}°",
                    279.235, 38.784, roll, 1)
    ok &= check("Vega bolgesi, AYNALANMIS", 279.235, 38.784, 73.0, -1)

    print()
    # Baska gokyuzu bolgeleri
    ok &= check("Orion (yogun alan)", 83.0, -1.2, 22.0, 1)
    ok &= check("Pegasus (seyrek alan)", 345.0, 25.0, 155.0, 1)
    ok &= check("Kutup yakini (Dec +70)", 200.0, 70.0, 95.0, 1)
    ok &= check("Guney (Dec -30)", 250.0, -30.0, 15.0, 1)

    print()
    # Bozulmus senaryolar
    ok &= check("en parlak yildiz DOYMUS", 279.235, 38.784, 60.0, 1,
                saturate_brightest=True)
    ok &= check("3 yildiz eksik (bulut/kenar)", 279.235, 38.784, 60.0, 1,
                missing=3)
    ok &= check("4 sahte tepe (sicak piksel)", 279.235, 38.784, 60.0, 1,
                spurious=4)
    ok &= check("odak bozuk (FWHM 5 px)", 279.235, 38.784, 60.0, 1, fwhm=5.0)

    print()
    # NISAN HATASI — gercek kullanim kosulu.
    #
    # Ilk surum yalnizca donme acisini tariyordu ve merkez tahminine
    # guveniyordu. Olculdu: 1 DERECELIK sapma tanimayi tamamen
    # cokertiyordu (1 derece = 42 piksel, tolerans 6 piksel).
    # Cift-aralik eslestirmesi bunu cozdu.
    for err in [1.0, 5.0, 15.0, 25.0]:
        ok &= check(f"nisan hatasi {err:.0f} derece", 279.235, 38.784,
                    60.0, 1, pointing_error_deg=err)

    print("-" * 92)
    print("SONUC:", "TUM TESTLER GECTI" if ok else "KALDI")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
