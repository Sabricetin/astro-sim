#!/usr/bin/env python3
"""analyze_extinction.py'yi uctan uca sentetik veriyle dogrular.

Bilinen bir k ile sonmus sahte kareler uretilir; arac o k'yi geri
kazanmali. Kazanamiyorsa sahadan gelecek k de yanlis olur ve bunu
anlamanin baska yolu yok — gercek gokyuzunde "dogru cevap" yok.

Yukseklik hesabi astropy'ye birakiliyor; astropy zaten Faz 1'de 45
noktalik matrisle bagimsiz olarak dogrulandi, o yuzden burada referans
olarak kullanilmasi mesru.
"""
import io
import json
import sys
from contextlib import redirect_stdout
from datetime import datetime, timedelta
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
import analyze_extinction as ext

RNG = np.random.default_rng(20260822)
SIZE = 200
SKY = 600.0
NOISE = 9.0
FWHM = 3.0
EXPOSURE = 15.0
# Atmosfer disi akis, ADU. Tepe piksel beyaz seviyenin (15360) altinda
# kalacak sekilde secildi — aksi halde arac kareyi DOYMUS sayip hakli
# olarak atar. Ilk denememde 3e6 yazip bu tuzaga kendim dustum.
F0 = 1.0e5

LAT, LON, ELEV = 36.80, 34.62, 10.0
UTC_OFFSET = 3.0


WHITE = 15360.0


def make_star_frame(flux, extra=None, clip=False):
    yy, xx = np.mgrid[0:SIZE, 0:SIZE]
    sigma = FWHM / 2.3548
    cy, cx = SIZE / 2 + 3.2, SIZE / 2 - 2.7
    amp = flux / (2 * np.pi * sigma ** 2)
    img = SKY + amp * np.exp(-((yy - cy) ** 2 + (xx - cx) ** 2) / (2 * sigma ** 2))
    # Birkac sonuk yildiz: merkez secimi dogru olani bulmali.
    for (sy, sx, sf) in (extra if extra is not None else
                        [(30, 40, flux * 0.05), (170, 150, flux * 0.03)]):
        img += (sf / (2 * np.pi * sigma ** 2)) * np.exp(
            -((yy - sy) ** 2 + (xx - sx) ** 2) / (2 * sigma ** 2))
    img = img + RNG.normal(0, NOISE, img.shape)
    return np.clip(img, 0, WHITE) if clip else img


def run_case(true_k, times_local, cloud_on=None, label="", saturate_main=False):
    """Sahte kareler uretip aracin k'yi geri kazanmasini olcer."""
    store, metas = {}, {}
    for i, lt in enumerate(times_local):
        name = f"IMG_{9000 + i}.CR2"
        utc = lt - timedelta(hours=UTC_OFFSET) + timedelta(seconds=EXPOSURE / 2)
        alt, _ = ext.altitude_of(ext.VEGA_RA_DEG, ext.VEGA_DEC_DEG,
                                 utc, LAT, LON, ELEV)
        X = ext.airmass_kasten_young(alt)
        flux = F0 * 10 ** (-0.4 * true_k * X)
        if cloud_on is not None and i in cloud_on:
            flux *= 0.6          # ince bulut
        if saturate_main:
            # Ana yildiz doymus, ikinci sira temiz: arac ikinciye gecmeli.
            store[name] = make_star_frame(
                flux * 400,
                extra=[(SIZE / 2 + 30, SIZE / 2 + 25, flux)],
                clip=True)
        else:
            store[name] = make_star_frame(flux)
        metas[name] = {
            "SourceFile": name, "ISO": 1600, "ExposureTime": EXPOSURE,
            "ShutterSpeedValue": EXPOSURE,
            "CreateDate": lt.strftime("%Y:%m:%d %H:%M:%S"),
            "FNumber": 2.8, "FocalLength": 14.0,
        }

    ext.load_plane = lambda p, ch, roi=0: (store[Path(p).name], {})
    ext.raw_files = lambda folder: [Path(n) for n in sorted(store)]
    ext.read_meta = lambda paths: metas

    out = Path("/tmp/_ext_test")
    argv = sys.argv
    sys.argv = ["x", "--frames", ".", "--lat", str(LAT), "--lon", str(LON),
                "--elev", str(ELEV), "--utc-offset", str(UTC_OFFSET),
                "--out", str(out)]
    buf = io.StringIO()
    try:
        with redirect_stdout(buf):
            ext.main()
    except BaseException:
        # Teshis kolay olsun: arac ne dediyse gorunsun.
        print(buf.getvalue())
        raise
    finally:
        sys.argv = argv
    return json.loads(out.with_suffix(".json").read_text())


def main() -> int:
    ok = True
    # 2026-09-10 gecesi Vega 70 dereceden 20 dereceye iniyor.
    base = datetime(2026, 9, 10, 21, 30)
    times = [base + timedelta(minutes=m) for m in [0, 52, 104, 157, 213, 241, 271]]

    print(f"{'senaryo':<38} {'gercek k':>9} {'bulunan':>9} {'hata':>8}  sonuc")
    print("-" * 74)
    for true_k in [0.15, 0.25, 0.40, 0.60]:
        r = run_case(true_k, times)
        got = r["extinction_coefficient_k"]
        err = abs(got - true_k)
        good = err < 0.02
        ok &= good
        print(f"{'temiz gece, k=' + str(true_k):<38} {true_k:>9.3f} {got:>9.4f} "
              f"{err:>8.4f}  {'OK' if good else 'HATA'}")

    # Bulut gecen kare: saglam uydurma onu yutmali.
    r = run_case(0.25, times, cloud_on={3})
    got = r["extinction_coefficient_k"]
    good = abs(got - 0.25) < 0.04
    ok &= good
    print(f"{'bir karede ince bulut (saglam uydurma)':<38} {0.25:>9.3f} "
          f"{got:>9.4f} {abs(got - 0.25):>8.4f}  {'OK' if good else 'HATA'}")

    # Kaldirac kucukse uyari vermeli.
    # Alti kare (aracin alt siniri) ama hepsi yuksekte: kaldirac kucuk.
    short = [base + timedelta(minutes=m) for m in [0, 10, 20, 30, 40, 50]]
    r = run_case(0.25, short)
    warned = any("kaldirac" in w for w in r["warnings"])
    ok &= warned
    print(f"{'kisa kaldirac -> uyari':<38} {'':<9} {'':<9} {'':<8}  "
          f"{'OK' if warned else 'HATA (uyarmadi)'}")

    # PSF yan urunu dogru mu.
    r = run_case(0.25, times)
    fw = r["psf_fwhm_px_median"]
    good = abs(fw - FWHM) / FWHM < 0.05
    ok &= good
    print(f"{'yan urun FWHM':<38} {FWHM:>9.2f} {fw:>9.3f} "
          f"{abs(fw - FWHM):>8.3f}  {'OK' if good else 'HATA'}")

    # Ana yildiz DOYMUS: arac bir sonraki siraya gecip k'yi yine bulmali.
    # Vega 14 mm f/2.8 15 s'de dolum kapasitesini 161 kat asiyor; bu
    # senaryo teorik degil, planlanan cekimin ta kendisiydi.
    r = run_case(0.25, times, saturate_main=True)
    got = r["extinction_coefficient_k"]
    used = r.get("star_rank_used")
    good = abs(got - 0.25) < 0.03 and used == 1
    ok &= good
    print(f"{'ana yildiz DOYMUS -> ikinci siraya gec':<38} {0.25:>9.3f} "
          f"{got:>9.4f} {abs(got - 0.25):>8.4f}  "
          f"{'OK (sira ' + str(used) + ')' if good else 'HATA'}")

    print("-" * 74)
    print("SONUC:", "TUM TESTLER GECTI" if ok else "KALDI")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
