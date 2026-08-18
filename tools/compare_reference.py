#!/usr/bin/env python3
"""
FAZ 0.A cikis kriteri: olcumlerimizi photonstophotos.net referansiyla karsilastir.

Siteden okunacak iki grafik:
  RN_ADU.htm  -> "Read Noise in DNs versus ISO Setting"        [ADU]
  RN_e.htm    -> "Input-referred Read Noise versus ISO Setting" [e-]

Kazanc siteden ayrica okunmaz, bu ikisinden turetilir:
  kazanc = okuma_gurultusu_e / okuma_gurultusu_adu

Kullanim (siteden okudugun degerler, ISO 800 1600 3200 sirasiyla):
  ./.venv/bin/python tools/compare_reference.py \
      --rn-adu 10.2 16.0 25.5 \
      --rn-e    2.5  2.0  1.7
"""
import argparse, json, sys
from pathlib import Path

ISOS = (800, 1600, 3200)
TOL = 20.0   # yol haritasindaki cikis kriteri: %20


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--rn-adu", nargs=3, type=float, required=True, metavar=("I800", "I1600", "I3200"))
    ap.add_argument("--rn-e",   nargs=3, type=float, required=True, metavar=("I800", "I1600", "I3200"))
    ap.add_argument("--dir", type=Path, default=Path("data/faz0"))
    a = ap.parse_args()

    mine = {}
    for iso in ISOS:
        f = a.dir / f"iso{iso}.json"
        if not f.exists():
            sys.exit(f"Sonuc dosyasi yok: {f}  (once sensor_ptc.py calistir)")
        d = json.loads(f.read_text())
        mine[iso] = (d["read_noise_adu"], d["read_noise_e_from_bias"], d["gain_e_per_adu"])

    print(f"{'olcum':<22}{'ISO':>6}{'bizim':>10}{'site':>10}{'fark':>9}   sonuc")
    print("-" * 68)
    all_ok = True
    for label, idx, ref_list, derive in (
        ("okuma gurultusu ADU", 0, a.rn_adu, None),
        ("okuma gurultusu e-",  1, a.rn_e,   None),
        ("kazanc e-/ADU",       2, None,     True),
    ):
        for i, iso in enumerate(ISOS):
            ours = mine[iso][idx]
            ref = (a.rn_e[i] / a.rn_adu[i]) if derive else ref_list[i]
            err = abs(ours - ref) / ref * 100.0
            ok = err <= TOL
            all_ok &= ok
            print(f"{label:<22}{iso:>6}{ours:>10.4f}{ref:>10.4f}{err:>8.1f}%   "
                  f"{'GECTI' if ok else 'KALDI'}")
        print()

    print("-" * 68)
    if all_ok:
        print(f"  FAZ 0.A CIKIS KRITERI GECILDI  (hepsi %{TOL:.0f} icinde)")
        print("  Sensor modelinde artik uydurma sayi yok. Faz 0.B'ye gecebilirsin.")
    else:
        print(f"  Bazi degerler %{TOL:.0f} disinda. Once sunlari kontrol et:")
        print("   - Sitede dogru govde mi secili? (760D / Rebel T6s / EOS 8000D ayni makine)")
        print("   - Isim sonunda _14 var mi? (12 bit varyanti farkli sayi verir)")
        print("   - Grafikten okurken dogru ISO sutununa mi baktin?")
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
