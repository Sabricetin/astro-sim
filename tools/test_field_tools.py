#!/usr/bin/env python3
"""analyze_darks.py ve analyze_sky.py'yi sentetik veriyle dogrular.

Bilinen karanlik akim ve bilinen fon uretip araclarin geri
kazanmasini olcer. Ayrica bilerek bozulmus senaryolarda dogru
uyariyi verip vermediklerine bakar — uyarmayan bir uyari sistemi,
olmayandan daha kotudur cunku guven verir.
"""
import io
import json
import sys
from contextlib import redirect_stdout
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
import analyze_darks as dk
import analyze_sky as sky

RNG = np.random.default_rng(20260822)
BIAS = 2049.0
GAIN = 0.1265           # e-/ADU
SIZE = 120


def frame(level_adu, noise=6.0, hot_fraction=0.0):
    img = RNG.normal(level_adu, noise, (SIZE, SIZE))
    if hot_fraction > 0:
        n = int(hot_fraction * img.size)
        idx = RNG.choice(img.size, n, replace=False)
        img.flat[idx] += 400
    return img


def patch(module, store, metas):
    module.load_plane = lambda p, ch, roi=0: (store[Path(p).name], {})
    module.raw_files = lambda folder: [Path(n) for n in sorted(store)]
    module.read_meta = lambda paths: metas


def run(module, argv, store, metas):
    patch(module, store, metas)
    old = sys.argv
    sys.argv = argv
    buf = io.StringIO()
    try:
        with redirect_stdout(buf):
            module.main()
    except BaseException:
        print(buf.getvalue()); raise
    finally:
        sys.argv = old
    return buf.getvalue()


def build_darks(dark_e_per_s, exposures, temp=37, hot=0.0, nr_on=False):
    store, metas = {}, {}
    for i, t in enumerate(exposures):
        name = f"D_{i:03d}.CR2"
        level = BIAS + (0.0 if nr_on else dark_e_per_s / GAIN * t)
        store[name] = frame(level, hot_fraction=hot)
        metas[name] = {"SourceFile": name, "ISO": 1600, "ExposureTime": t,
                       "ShutterSpeedValue": t, "CameraTemperature": temp}
    return store, metas


def build_sky(rate_e_per_s, isos, exposures, gains, nonlinear=0.0):
    store, metas = {}, {}
    i = 0
    for iso in isos:
        for t in exposures:
            name = f"S_{i:03d}.CR2"; i += 1
            adu = rate_e_per_s / gains[iso] * t
            adu *= (1 + nonlinear * adu / 13311)
            store[name] = frame(BIAS + adu)
            metas[name] = {"SourceFile": name, "ISO": iso, "ExposureTime": t,
                           "ShutterSpeedValue": t, "CreateDate": "2026:09:10 23:00:00",
                           "CameraTemperature": 20}
    return store, metas


def main() -> int:
    ok = True
    print("KARANLIK AKIM")
    print(f"{'senaryo':<40} {'gercek':>9} {'bulunan':>9} {'hata%':>8}  sonuc")
    print("-" * 78)
    for true_dark in [0.02, 0.10, 0.50]:
        store, metas = build_darks(true_dark, [5, 10, 15, 20, 30, 60])
        run(dk, ["x", "--frames", ".", "--gain", str(GAIN),
                 "--out", "/tmp/_dk"], store, metas)
        got = json.loads(Path("/tmp/_dk.json").read_text())["dark_current_e_per_px_per_s"]
        err = abs(got - true_dark) / true_dark * 100
        good = err < 5
        ok &= good
        print(f"{'temiz, I_d=' + str(true_dark):<40} {true_dark:>9.3f} {got:>9.4f} "
              f"{err:>7.2f}%  {'OK' if good else 'HATA'}")

    # Uzun Poz Parazit Azaltma acik kalmis -> negatif/sifir akim, uyari
    store, metas = build_darks(0.1, [5, 10, 15, 20, 30, 60], nr_on=True)
    run(dk, ["x", "--frames", ".", "--gain", str(GAIN), "--out", "/tmp/_dk"],
        store, metas)
    r = json.loads(Path("/tmp/_dk.json").read_text())
    near_zero = abs(r["dark_current_e_per_px_per_s"]) < 0.005
    ok &= near_zero
    print(f"{'makine kendi darkini cikarmis':<40} {'~0':>9} "
          f"{r['dark_current_e_per_px_per_s']:>9.4f} {'':>8}  "
          f"{'OK (yakalandi)' if near_zero else 'HATA'}")

    # Sicak piksel uyarisi
    store, metas = build_darks(0.1, [5, 10, 15, 20, 30, 60], hot=0.02)
    run(dk, ["x", "--frames", ".", "--gain", str(GAIN), "--out", "/tmp/_dk"],
        store, metas)
    warned = any("sicak piksel" in w for w in
                 json.loads(Path("/tmp/_dk.json").read_text())["warnings"])
    ok &= warned
    print(f"{'sicak piksel %2 -> uyari':<40} {'':>9} {'':>9} {'':>8}  "
          f"{'OK' if warned else 'HATA (uyarmadi)'}")

    print("\nGOKYUZU FONU")
    print(f"{'senaryo':<40} {'gercek':>9} {'bulunan':>9} {'hata%':>8}  sonuc")
    print("-" * 78)
    gains = {800: 0.2473, 1600: 0.1265, 3200: 0.0655}
    gain_args = [f"{k}={v}" for k, v in gains.items()]
    for true_rate in [0.5, 2.0, 8.0]:
        store, metas = build_sky(true_rate, [1600], [5, 10, 15, 20, 30, 60], gains)
        run(sky, ["x", "--frames", "."] +
            sum([["--gain-iso", g] for g in gain_args], []) +
            ["--out", "/tmp/_sky", "--roi", "0"], store, metas)
        got = json.loads(Path("/tmp/_sky.json").read_text())["sky_e_per_px_per_s"]
        err = abs(got - true_rate) / true_rate * 100
        good = err < 3
        ok &= good
        print(f"{'tek ISO, fon=' + str(true_rate):<40} {true_rate:>9.3f} "
              f"{got:>9.4f} {err:>7.2f}%  {'OK' if good else 'HATA'}")

    # ISO capraz kontrolu: dogru kazanclarla yayilim kucuk olmali
    store, metas = build_sky(2.0, [800, 1600, 3200], [5, 10, 15, 20, 30, 60], gains)
    run(sky, ["x", "--frames", "."] +
        sum([["--gain-iso", g] for g in gain_args], []) +
        ["--out", "/tmp/_sky", "--roi", "0"], store, metas)
    spread = json.loads(Path("/tmp/_sky.json").read_text())["iso_cross_check_spread_pct"]
    good = spread < 2
    ok &= good
    print(f"{'ISO capraz kontrolu (dogru kazanc)':<40} {'<2%':>9} {spread:>8.2f}% "
          f"{'':>8}  {'OK' if good else 'HATA'}")

    # Kazanclardan biri %30 yanlis -> uyari CIKMALI
    bad = dict(gains); bad[3200] = gains[3200] * 1.3
    store, metas = build_sky(2.0, [800, 1600, 3200], [5, 10, 15, 20, 30, 60], gains)
    run(sky, ["x", "--frames", "."] +
        sum([["--gain-iso", f"{k}={v}"] for k, v in bad.items()], []) +
        ["--out", "/tmp/_sky", "--roi", "0"], store, metas)
    r = json.loads(Path("/tmp/_sky.json").read_text())
    warned = any("ayrisiyor" in w for w in r["warnings"])
    ok &= warned
    print(f"{'kazanc %30 yanlis -> uyari':<40} {'':>9} "
          f"{r['iso_cross_check_spread_pct']:>8.1f}% {'':>8}  "
          f"{'OK (yakalandi)' if warned else 'HATA (kacirdi)'}")

    # Fon dogrusal degilse uyari
    # Fon hizi yuksek secildi: sehir gokyuzu. Dusuk fonda sinyal kucuk
    # kalir ve %15'lik bir egrilik bile ADU'da %1 eder — esigin altinda.
    # Ilk denememde bu yuzden uyari cikmadi; test verisi zayifti, arac
    # degil.
    store, metas = build_sky(15.0, [1600], [5, 10, 15, 20, 30, 60], gains,
                             nonlinear=0.15)
    run(sky, ["x", "--frames", "."] +
        sum([["--gain-iso", g] for g in gain_args], []) +
        ["--out", "/tmp/_sky", "--roi", "0"], store, metas)
    warned = any("dogru orantili degil" in w for w in
                 json.loads(Path("/tmp/_sky.json").read_text())["warnings"])
    ok &= warned
    print(f"{'fon dogrusal degil -> uyari':<40} {'':>9} {'':>9} {'':>8}  "
          f"{'OK' if warned else 'HATA (uyarmadi)'}")

    print("\nMUTLAK FON PARLAKLIGI (sifir noktasindan)")
    print(f"{'senaryo':<40} {'gercek':>9} {'bulunan':>9} {'hata':>8}  sonuc")
    print("-" * 78)
    # Ileri yon: mu -> ADU/s.  m_alet = mu - ZP,  ADU/s = omega * 10^(-0.4 m_alet)
    SCALE = 54.8
    OMEGA = SCALE ** 2
    for ZP, mu_true in [(20.0, 21.5), (20.0, 19.0), (22.5, 20.5)]:
        m_inst = mu_true - ZP
        adu_per_s = OMEGA * 10 ** (-0.4 * m_inst)
        # Bu ADU/s'yi uretecek elektron hizi
        rate_e = adu_per_s * gains[1600]
        store, metas = build_sky(rate_e, [1600], [5, 10, 15, 20, 30, 60], gains)
        run(sky, ["x", "--frames", "."] +
            sum([["--gain-iso", g] for g in gain_args], []) +
            ["--zero-point", str(ZP), "--arcsec-per-pixel", str(SCALE),
             "--out", "/tmp/_sky", "--roi", "0"], store, metas)
        got = json.loads(Path("/tmp/_sky.json").read_text())["sky_mag_per_sq_arcsec"]
        err = abs(got - mu_true)
        good = err < 0.02
        ok &= good
        print(f"{'ZP=' + str(ZP) + ', mu=' + str(mu_true):<40} {mu_true:>9.2f} "
              f"{got:>9.3f} {err:>8.3f}  {'OK' if good else 'HATA'}")

    # Sifir noktasi 1 kadir kayarsa fon da tam 1 kadir kaymali.
    # Zincirin dogru sadelestigini gosterir.
    vals = []
    for ZP in [20.0, 21.0]:
        adu_per_s = OMEGA * 10 ** (-0.4 * (20.5 - 20.0))
        store, metas = build_sky(adu_per_s * gains[1600], [1600],
                                 [5, 10, 15, 20, 30, 60], gains)
        run(sky, ["x", "--frames", "."] +
            sum([["--gain-iso", g] for g in gain_args], []) +
            ["--zero-point", str(ZP), "--arcsec-per-pixel", str(SCALE),
             "--out", "/tmp/_sky", "--roi", "0"], store, metas)
        vals.append(json.loads(Path("/tmp/_sky.json").read_text())
                    ["sky_mag_per_sq_arcsec"])
    shift = vals[1] - vals[0]
    good = abs(shift - 1.0) < 0.005
    ok &= good
    print(f"{'ZP 1 kadir kayinca fon da 1 kadir kayiyor':<40} {1.0:>9.2f} "
          f"{shift:>9.3f} {abs(shift - 1):>8.3f}  {'OK' if good else 'HATA'}")

    print("-" * 78)
    print("SONUC:", "TUM TESTLER GECTI" if ok else "KALDI")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
