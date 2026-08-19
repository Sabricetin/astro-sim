#!/usr/bin/env python3
"""
T2.2 — BSC5 katalogunu kompakt binary formata cevirir.

NEDEN BINARY
------------
Metin parse etmek mobilde yavas. 9096 satirlik sabit genislikli metni
her aciliste ayristirmak yerine, tek bir `ByteData` okumasiyla dogrudan
`Float32List` haline gelen bir dosya uretiyoruz — sifir parse.

DOSYA FORMATI
-------------
Tum sayilar **little-endian**. Hedef platformlarin hepsi (ARM64, x64,
web) little-endian; loader bunu calisma aninda dogruluyor.

  Ofset  Boyut  Icerik
  -----  -----  ------------------------------------------------------
      0      4  Sihirli sayi: 'ASTR' (ASCII)
      4      2  Surum (uint16), su an 1
      6      2  Ayrilmis (sifir)
      8      4  Yildiz sayisi N (uint32)
     12      4  Ayrilmis (sifir)
  -----  -----  ------------------------------------------------------
     16  16*N  Yildiz verisi: N adet 4 x float32
                 [0] RA  J2000, derece [0,360)
                 [1] Dec J2000, derece [-90,90]
                 [2] Vmag (gorsel kadir)
                 [3] B-V renk indeksi; veri yoksa NaN
  -----  -----  ------------------------------------------------------
  16+16*N  2*N  HR numaralari (uint16), yildizlarla ayni sirada

Basligin 16 bayt olmasi tesadufi degil: float32 bolumunun 4 baytlik
hizalamaya oturmasi gerekiyor ki `Float32List.view` kopyalamadan
calissin.

HR numaralari AYRI bir bolumde tutuluyor, float dizisine karistirilmiyor.
Boylece cizim kodu tek parca, siki paketlenmis float dizisini okur;
HR'yi sadece takim yildizi cizgileri gibi kimlik gerektiren isler acar.

KAYNAK VE ATIF
--------------
Bright Star Catalogue, 5th Revised Ed. (Hoffleit D., Warren Jr W.H., 1991)
Astronomical Data Center, NSSDC/ADC. VizieR katalog V/50.

Not: ReadMe'de acik bir lisans metni yok. Ticari dagitim oncesi
kullanim kosullarinin teyit edilmesi gerekir (bkz. yol-haritasi.md,
Lisans kararlari).

Calistir:
    ./.venv/bin/python tools/build_star_catalog.py
"""

from __future__ import annotations

import math
import struct
from pathlib import Path

SOURCE = Path("data/catalog/bsc5")
OUT = Path("packages/astro_core/assets/stars_bsc5.bin")

MAGIC = b"ASTR"
FORMAT_VERSION = 1

# BSC5 zaten kadir 6.5 sinirinda derlenmis, ama birkac daha sonik kayit
# iceriyor. Ciplak goz siniri ~6.5; bunun otesi ekranda gorunmez ama
# dosyayi buyutur.
MAGNITUDE_LIMIT = 6.5


def parse_line(line: str) -> dict | None:
    """Sabit genislikli BSC5 satirini cozer. Koordinatsizsa None."""
    # Sutun konumlari ReadMe'deki 1 tabanli araliklardan; Python 0 tabanli.
    ra_h = line[75:77].strip()
    if not ra_h:
        return None  # kaldirilmis kayit (nova vb.)

    ra_hours = int(ra_h) + int(line[77:79]) / 60 + float(line[79:83]) / 3600
    dec_sign = -1.0 if line[83:84] == "-" else 1.0
    dec = dec_sign * (
        int(line[84:86]) + int(line[86:88]) / 60 + int(line[88:90]) / 3600
    )

    vmag_raw = line[102:107].strip()
    if not vmag_raw:
        return None
    vmag = float(vmag_raw)

    bv_raw = line[109:114].strip()
    # B-V her yildizda yok. NaN sentinel: cizim kodu bunu "renk bilinmiyor"
    # diye okuyup beyaza duser. Sifir kullanmak yanlis olurdu — sifir
    # gecerli bir B-V degeri (A0 tipi, beyaz yildiz).
    bv = float(bv_raw) if bv_raw else math.nan

    return {
        "hr": int(line[0:4]),
        "ra": ra_hours * 15.0,  # saat -> derece
        "dec": dec,
        "vmag": vmag,
        "bv": bv,
    }


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(
            f"Katalog yok: {SOURCE}\n"
            "  Once indir:\n"
            "  curl -o data/catalog/bsc5.gz "
            "https://cdsarc.cds.unistra.fr/ftp/V/50/catalog.gz && "
            "gunzip -k data/catalog/bsc5.gz"
        )

    stars, skipped_no_coords, skipped_faint = [], 0, 0
    for line in SOURCE.read_text(encoding="latin-1").splitlines():
        star = parse_line(line)
        if star is None:
            skipped_no_coords += 1
            continue
        if star["vmag"] > MAGNITUDE_LIMIT:
            skipped_faint += 1
            continue
        stars.append(star)

    # HR sirasina gore sabitle: uretim tekrar edilebilir olsun ve takim
    # yildizi cizgileri kararli bir indeksleme bulsun.
    stars.sort(key=lambda s: s["hr"])

    n = len(stars)
    buf = bytearray()
    buf += MAGIC
    buf += struct.pack("<HHII", FORMAT_VERSION, 0, n, 0)
    for s in stars:
        buf += struct.pack("<ffff", s["ra"], s["dec"], s["vmag"], s["bv"])
    for s in stars:
        buf += struct.pack("<H", s["hr"])

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(buf)

    no_bv = sum(1 for s in stars if math.isnan(s["bv"]))
    brightest = min(stars, key=lambda s: s["vmag"])
    print(f"{OUT}  ({len(buf) / 1024:.1f} KB)")
    print(f"  yazilan yildiz    : {n}")
    print(f"  atlanan (koordinatsiz): {skipped_no_coords}")
    print(f"  atlanan (kadir > {MAGNITUDE_LIMIT}) : {skipped_faint}")
    print(f"  B-V verisi olmayan: {no_bv}")
    print(f"  en parlak         : HR {brightest['hr']}, Vmag {brightest['vmag']}")
    print(f"  kadir araligi     : {brightest['vmag']} .. "
          f"{max(s['vmag'] for s in stars)}")


if __name__ == "__main__":
    main()
