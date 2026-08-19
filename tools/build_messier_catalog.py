#!/usr/bin/env python3
"""
T2.4 — Messier katalogunu Dart kaynak dosyasina cevirir.

NEDEN BINARY DEGIL
------------------
110 nesne. Yildiz katalogunda binary sart cunku 8404 kayit var ve her
aciliste ayristirilamaz; burada veri o kadar kucuk ki Dart sabit listesi
hem daha okunabilir hem git'te diff'lenebilir olur.

KAYNAK
------
NGC 2000.0 (Sky Publishing Corp. / Roger W. Sinnott, 1988), VizieR VII/118.
names.dat Messier numarasini NGC/IC adina baglar; ngc2000.dat koordinat,
tur, boyut ve kadir verir.

Messier katalogu 1771 tarihli, kamuya acik. Modern koordinatlar olgusal
olcum verisi.

Calistir:
    ./.venv/bin/python tools/build_messier_catalog.py
"""

from __future__ import annotations

import re
from pathlib import Path

NAMES = Path("data/catalog/names.dat")
NGC = Path("data/catalog/ngc2000.dat")
OUT = Path("packages/astro_core/lib/src/catalog/messier.g.dart")

# Tur kodlarindan okunabilir Turkce adlara.
TYPE_NAMES = {
    "Gx": "Galaksi",
    "OC": "Acik yildiz kumesi",
    "Gb": "Kuresel yildiz kumesi",
    "Nb": "Bulutsu",
    "Pl": "Gezegenimsi bulutsu",
    "C+N": "Kume + bulutsu",
    "Ast": "Yildiz toplulugu",
    "Kt": "Galakside dugum",
    "***": "Uclu yildiz",
    "D*": "Cift yildiz",
    "*": "Yildiz",
    "?": "Belirsiz",
}

# NGC karsiligi olmayan dort nesne. Koordinatlar J2000.
# M102 tarihsel olarak tartismali; yaygin kabul NGC 5866 yonunde, o
# kullanildi.
MANUAL = {
    24: dict(ra=18 + 17 / 60, dec=-18.48, type="Ast", size=90.0, mag=4.6,
             note="Samanyolu yildiz bulutu"),
    40: dict(ra=12 + 22.4 / 60, dec=+58.08, type="D*", size=0.8, mag=9.6,
             note="Winnecke 4"),
    45: dict(ra=3 + 47.4 / 60, dec=+24.12, type="OC", size=110.0, mag=1.6,
             note="Ulker (Pleiades)"),
    102: dict(ra=15 + 6.5 / 60, dec=+55.76, type="Gx", size=6.6, mag=10.0,
              note="Tartismali; NGC 5866 kabul edildi"),
}


def parse_ngc() -> dict[str, dict]:
    out = {}
    for line in NGC.read_text(encoding="latin-1").splitlines():
        name = line[0:5].strip()
        if not name:
            continue
        try:
            ra = int(line[10:12]) + float(line[13:17]) / 60.0
            sign = -1.0 if line[19:20] == "-" else 1.0
            dec = sign * (int(line[20:22]) + int(line[23:25]) / 60.0)
        except ValueError:
            continue
        size = line[33:38].strip()
        mag = line[40:44].strip()
        out[name] = dict(
            ra=ra * 15.0,  # saat -> derece
            dec=dec,
            type=line[6:9].strip(),
            size=float(size) if size else None,
            mag=float(mag) if mag else None,
        )
    return out


def main() -> None:
    for path in (NAMES, NGC):
        if not path.exists():
            raise SystemExit(f"Kaynak yok: {path}")

    ngc = parse_ngc()
    objects: dict[int, dict] = {}

    for line in NAMES.read_text(encoding="latin-1").splitlines():
        m = re.match(r"^M\s+(\d+)\s*$", line[0:35].strip())
        if not m:
            continue
        number = int(m.group(1))
        if number in objects:
            continue  # ayni M numarasi birden fazla NGC'ye baglanabilir
        ref = line[36:41].strip()
        if ref and ref in ngc:
            objects[number] = dict(ngc[ref], ngc=ref, note="")

    for number, data in MANUAL.items():
        if number not in objects:
            objects[number] = dict(data, ngc="", ra=data["ra"] * 15.0)

    missing = sorted(set(range(1, 111)) - set(objects))
    if missing:
        raise SystemExit(f"Eksik Messier nesneleri: {missing}")

    lines = [
        "// URETILMIS DOSYA — elle duzenleme.",
        "//",
        "// Uretici: tools/build_messier_catalog.py",
        "// Kaynak : NGC 2000.0 (Sinnott 1988), VizieR VII/118",
        "//",
        "// Messier katalogu 1771 tarihli, kamuya acik. Koordinatlar J2000,",
        "// sapma hassasiyeti 1 yay dakikasi — derin gokyuzu nesneleri genis",
        "// oldugu icin fazlasiyla yeterli.",
        "",
        "/// Derin gokyuzu hedefi.",
        "///",
        "/// Faz 4.7'deki yukseklik/zaman grafigi ve Faz 5'teki hedef secimi",
        "/// bu listeyi kullanir.",
        "class MessierObject {",
        "  /// Messier numarasi, 1-110.",
        "  final int number;",
        "",
        "  /// NGC/IC karsiligi; dordu icin bos (M24, M40, M45, M102).",
        "  final String ngc;",
        "",
        "  /// Sag aciklik J2000, derece.",
        "  final double rightAscensionDegrees;",
        "",
        "  /// Sapma J2000, derece.",
        "  final double declinationDegrees;",
        "",
        "  /// Tur kodu (Gx, OC, Gb, Nb, Pl, ...).",
        "  final String type;",
        "",
        "  /// En buyuk acisal boyut, yay dakikasi. Bilinmiyorsa null.",
        "  final double? sizeArcminutes;",
        "",
        "  /// Butunlesik gorsel kadir. Bilinmiyorsa null.",
        "  final double? magnitude;",
        "",
        "  /// Serbest not (ozel ad, belirsizlik).",
        "  final String note;",
        "",
        "  const MessierObject({",
        "    required this.number,",
        "    required this.ngc,",
        "    required this.rightAscensionDegrees,",
        "    required this.declinationDegrees,",
        "    required this.type,",
        "    required this.sizeArcminutes,",
        "    required this.magnitude,",
        "    required this.note,",
        "  });",
        "",
        "  /// Sag aciklik, saat cinsinden.",
        "  double get rightAscensionHours => rightAscensionDegrees / 15.0;",
        "",
        "  /// Katalog adi: 'M31'.",
        "  String get designation => 'M$number';",
        "",
        "  @override",
        "  String toString() => designation;",
        "}",
        "",
        "/// Tur kodundan okunabilir ada.",
        "const Map<String, String> messierTypeNames = {",
    ]
    for code, name in TYPE_NAMES.items():
        lines.append(f"  '{code}': '{name}',")
    lines += ["};", "", "/// 110 Messier nesnesi, numara sirasinda.",
              "const List<MessierObject> messierCatalog = ["]

    for number in range(1, 111):
        o = objects[number]
        size = "null" if o["size"] is None else f"{o['size']}"
        mag = "null" if o["mag"] is None else f"{o['mag']}"
        lines += [
            "  MessierObject(",
            f"    number: {number},",
            f"    ngc: '{o['ngc']}',",
            f"    rightAscensionDegrees: {o['ra']:.5f},",
            f"    declinationDegrees: {o['dec']:.5f},",
            f"    type: '{o['type']}',",
            f"    sizeArcminutes: {size},",
            f"    magnitude: {mag},",
            f"    note: '{o['note']}',",
            "  ),",
        ]
    lines += ["];", ""]

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines))

    by_type: dict[str, int] = {}
    for o in objects.values():
        by_type[o["type"]] = by_type.get(o["type"], 0) + 1
    print(f"{OUT}  ({len(objects)} nesne)")
    for t, n in sorted(by_type.items(), key=lambda kv: -kv[1]):
        print(f"  {TYPE_NAMES.get(t, t):<24} {n}")


if __name__ == "__main__":
    main()
