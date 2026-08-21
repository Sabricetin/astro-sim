#!/usr/bin/env python3
"""Yale Bright Star kataloğunun ikili biçimini okur.

Dart tarafi (`StarCatalog.fromBytes`) ayni dosyayi okuyor. Ikisinin
ayni biciminden okumasi bilincli: katalog tek yerde uretiliyor
(`build_star_catalog.py`), iki taraf da ondan besleniyor. Ayri
kopyalar tutulsa er ya da gec ayrisirlardi.

Bicim:
    0    4    'ASTR'
    4    2    surum (uint16)
    6    2    dolgu
    8    4    yildiz sayisi N (uint32)
    12   4    dolgu
    16   16N  N x 4 float32  (RA, Dec, Vmag, B-V)
    16+16N 2N N x uint16     (HR numaralari)

Basligin 16 bayt olmasi tesadufi degil: float32 bolumu 4 bayta
hizali basliyor.
"""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np

MAGIC = b"ASTR"
DEFAULT_PATH = Path(__file__).parent.parent / "packages/astro_core/assets/stars_bsc5.bin"


@dataclass
class StarCatalog:
    ra_deg: np.ndarray       # J2000
    dec_deg: np.ndarray      # J2000
    vmag: np.ndarray
    bv: np.ndarray           # NaN = katalogda yok
    hr: np.ndarray

    def __len__(self) -> int:
        return len(self.ra_deg)

    def brighter_than(self, limit: float) -> "StarCatalog":
        m = self.vmag <= limit
        return StarCatalog(self.ra_deg[m], self.dec_deg[m], self.vmag[m],
                           self.bv[m], self.hr[m])

    def index_of_hr(self, hr: int) -> int | None:
        w = np.where(self.hr == hr)[0]
        return int(w[0]) if len(w) else None


def load(path: Path | None = None) -> StarCatalog:
    raw = (path or DEFAULT_PATH).read_bytes()
    if raw[:4] != MAGIC:
        raise ValueError(f"Sihirli sayi tutmuyor: {raw[:4]!r}. "
                         f"Katalog bozuk veya baska bir dosya.")
    version = int(np.frombuffer(raw, dtype="<u2", count=1, offset=4)[0])
    if version != 1:
        raise ValueError(f"Bilinmeyen surum {version}; bu okuyucu 1 biliyor.")
    n = int(np.frombuffer(raw, dtype="<u4", count=1, offset=8)[0])

    vals = np.frombuffer(raw, dtype="<f4", count=4 * n, offset=16)
    vals = vals.reshape(n, 4)
    hr = np.frombuffer(raw, dtype="<u2", count=n, offset=16 + 16 * n)

    return StarCatalog(
        ra_deg=vals[:, 0].astype(np.float64),
        dec_deg=vals[:, 1].astype(np.float64),
        vmag=vals[:, 2].astype(np.float64),
        bv=vals[:, 3].astype(np.float64),
        hr=hr.astype(np.int32),
    )


if __name__ == "__main__":
    c = load()
    print(f"{len(c)} yildiz")
    print(f"kadir araligi {c.vmag.min():.2f} .. {c.vmag.max():.2f}")
    print(f"B-V bilinmeyen {int(np.isnan(c.bv).sum())} yildiz")
    i = c.index_of_hr(7001)
    print(f"HR 7001 (Vega): RA {c.ra_deg[i]:.4f}  Dec {c.dec_deg[i]:.4f}  "
          f"V {c.vmag[i]:.2f}  B-V {c.bv[i]:.2f}")
