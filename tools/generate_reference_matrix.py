#!/usr/bin/env python3
"""
T1.7 — Dogrulama matrisi uretici.

5 yildiz x 3 konum x 3 zaman = 45 referans deger uretir ve Dart test
verisi olarak yazar.

NEDEN astropy, Stellarium degil
-------------------------------
Yol haritasi Stellarium diyor. Amac bagimsiz bir kaynakla karsilastirmak;
astropy o amaci daha iyi karsiliyor:

  - Bagimsiz: farkli ekip, farkli dil, farkli algoritma (ERFA/SOFA).
  - Script'lenebilir: 45 degeri elle okuyup yazmak gerekmiyor, dolayisiyla
    transkripsiyon hatasi riski yok.
  - Tekrar uretilebilir: bu script her calistiginda ayni sayilari verir;
    Stellarium surumu degisince ne oldugunu kimse bilemez.

Stellarium yine de degerli bir capraz kontrol — birkac degeri elle
dogrulamak icin. Ama 45'inin tamami icin degil.

KIRILMA
-------
pressure=0 verilir, yani astropy kirilma UYGULAMAZ. Karsilastirma
geometrik yukseklik uzerinden yapilir. Kirilma T1.6'da ayrica test
edildi; ikisini ayni testte karistirmak, hata cikinca hangisinden
geldigini gizler.

Kalan fark ne olacak
--------------------
astropy nutasyon, aberasyon ve isik sapmasini uygular; bizim kod bilerek
uygulamiyor (bkz. sidereal_time.dart ve precession.dart). Toplam etki
~0.01 derecenin altinda, projenin 0.1 derecelik toleransinin onda biri.

Calistir:
    ./.venv/bin/python tools/generate_reference_matrix.py
"""

from __future__ import annotations

from pathlib import Path

import astropy.units as u
from astropy.coordinates import AltAz, EarthLocation, SkyCoord
from astropy.time import Time
from astropy.utils import iers

# Internetten IERS verisi indirmeyi kapat: script'in cevrimdisi ve
# tekrar uretilebilir olmasi, UT1-UTC'nin son milisaniyesinden onemli.
# Bu projenin toleransinda fark yaratmaz (DUT1 < 0.9 s -> < 0.004 derece).
iers.conf.auto_download = False
iers.conf.iers_degraded_accuracy = "ignore"

OUT = Path("packages/astro_core/test/coords/reference_matrix.g.dart")


def hms(h: float, m: float, s: float) -> float:
    """Saat-dakika-saniyeyi dereceye cevirir."""
    return (h + m / 60 + s / 3600) * 15


def dms(sign: int, d: float, m: float, s: float) -> float:
    """Derece-dakika-saniyeyi ondalik dereceye cevirir."""
    return sign * (d + m / 60 + s / 3600)


# --- 5 yildiz, J2000 katalog konumlari -------------------------------------
# Farkli sapmalar bilerek secildi: kutup, orta kuzey, ekvator civari, guney.
STARS = [
    ("Vega", hms(18, 36, 56.336), dms(+1, 38, 47, 1.28)),
    ("Polaris", hms(2, 31, 49.09), dms(+1, 89, 15, 50.8)),
    ("Sirius", hms(6, 45, 8.917), dms(-1, 16, 42, 58.02)),
    ("Antares", hms(16, 29, 24.46), dms(-1, 26, 25, 55.2)),
    ("Deneb", hms(20, 41, 25.915), dms(+1, 45, 16, 49.22)),
]

# --- 3 konum ---------------------------------------------------------------
# Ekvator bilerek tam 0,0: enlem sifirda bazi formuller bozunur, test etsin.
LOCATIONS = [
    ("Gaziantep", 37.0662, 37.3833, 850.0),
    ("Istanbul", 41.0082, 28.9784, 40.0),
    ("Ekvator", 0.0, 0.0, 0.0),
]

# --- 3 zaman ---------------------------------------------------------------
TIMES = [
    ("yaz gecesi", "2026-07-15T22:00:00"),
    ("kis gecesi", "2026-01-15T22:00:00"),
    ("gunduz", "2026-07-15T10:00:00"),
]


def main() -> None:
    rows = []
    for star_name, ra_deg, dec_deg in STARS:
        star = SkyCoord(ra=ra_deg * u.deg, dec=dec_deg * u.deg, frame="icrs")
        for loc_name, lat, lon, height in LOCATIONS:
            site = EarthLocation(lat=lat * u.deg, lon=lon * u.deg, height=height * u.m)
            for time_name, iso in TIMES:
                t = Time(iso, scale="utc")
                altaz = star.transform_to(
                    AltAz(obstime=t, location=site, pressure=0)
                )
                rows.append(
                    {
                        "star": star_name,
                        "ra": ra_deg,
                        "dec": dec_deg,
                        "loc": loc_name,
                        "lat": lat,
                        "lon": lon,
                        "height": height,
                        "time": time_name,
                        "iso": iso,
                        "alt": float(altaz.alt.deg),
                        "az": float(altaz.az.deg),
                    }
                )

    lines = [
        "// URETILMIS DOSYA — elle duzenleme.",
        "//",
        "// Uretici: tools/generate_reference_matrix.py",
        "// Referans: astropy (ERFA/SOFA), kirilma uygulanmadan (pressure=0).",
        "//",
        f"// {len(STARS)} yildiz x {len(LOCATIONS)} konum x {len(TIMES)} zaman"
        f" = {len(rows)} satir.",
        "",
        "/// Bagimsiz kaynaktan uretilmis dogrulama satiri.",
        "class ReferenceRow {",
        "  final String star;",
        "  final double raJ2000Degrees;",
        "  final double decJ2000Degrees;",
        "  final String location;",
        "  final double latitudeDegrees;",
        "  final double longitudeEastDegrees;",
        "  final double elevationMeters;",
        "  final String timeLabel;",
        "  final String utcIso;",
        "  final double expectedAltitudeDegrees;",
        "  final double expectedAzimuthDegrees;",
        "",
        "  const ReferenceRow({",
        "    required this.star,",
        "    required this.raJ2000Degrees,",
        "    required this.decJ2000Degrees,",
        "    required this.location,",
        "    required this.latitudeDegrees,",
        "    required this.longitudeEastDegrees,",
        "    required this.elevationMeters,",
        "    required this.timeLabel,",
        "    required this.utcIso,",
        "    required this.expectedAltitudeDegrees,",
        "    required this.expectedAzimuthDegrees,",
        "  });",
        "",
        "  @override",
        "  String toString() => '$star @ $location, $timeLabel';",
        "}",
        "",
        "const List<ReferenceRow> referenceMatrix = [",
    ]

    for r in rows:
        lines += [
            "  ReferenceRow(",
            f"    star: '{r['star']}',",
            f"    raJ2000Degrees: {r['ra']:.9f},",
            f"    decJ2000Degrees: {r['dec']:.9f},",
            f"    location: '{r['loc']}',",
            f"    latitudeDegrees: {r['lat']},",
            f"    longitudeEastDegrees: {r['lon']},",
            f"    elevationMeters: {r['height']},",
            f"    timeLabel: '{r['time']}',",
            f"    utcIso: '{r['iso']}',",
            f"    expectedAltitudeDegrees: {r['alt']:.9f},",
            f"    expectedAzimuthDegrees: {r['az']:.9f},",
            "  ),",
        ]
    lines += ["];", ""]

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines))

    above = [r for r in rows if r["alt"] > 0]
    low = [r for r in rows if 0 < r["alt"] < 10]
    print(f"{len(rows)} satir yazildi -> {OUT}")
    print(f"  ufkun uzerinde : {len(above)}")
    print(f"  10 derece alti : {len(low)}  (kirilma bolgesi)")
    if low:
        for r in sorted(low, key=lambda x: x["alt"])[:5]:
            print(f"    {r['alt']:6.2f} der  {r['star']} @ {r['loc']}, {r['time']}")
    else:
        print("    ! 10 derece alti ornek yok — matris dusuk yuksekligi test etmiyor")


if __name__ == "__main__":
    main()
