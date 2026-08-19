/// T4.2 — Gunes'in konumu.
///
/// Yol haritasi "dusuk hassasiyet yeter, ±0.01 derece" diyor. Meeus'un
/// 25. bolumdeki kisa serisi tam bunu verir; tam VSOP87 teorisine girmek
/// bu proje icin gereksiz.
///
/// Gunes'in konumu iki yerde lazim: alacakaranlik pencereleri (T4.3) ve
/// Ay'in evresi (T4.4) — evre, Gunes ile Ay arasindaki acidan cikar.
///
/// Kaynak: Meeus, *Astronomical Algorithms*, 2. baski, Bolum 25.
library;

import 'dart:math' as math;

import '../coords/types.dart';
import '../math/angles.dart';
import '../time/julian_day.dart';

/// Gunes'in Yer'e ortalama uzakligi, km. Ay evresi hesabinda kullanilir.
const double astronomicalUnitKm = 149597870.7;

/// Ekliptigin egimi, derece. Ekliptik <-> ekvatoral donusumun ekseni.
///
/// Zamanla cok yavas degisir (yuzyilda ~0.013 derece); [julianCenturies]
/// ile duzeltiliyor.
double obliquityDegrees(double julianCentury) {
  final t = julianCentury;
  // Meeus 22.2, yay saniyesi cinsinden terimler dereceye cevrildi.
  return 23.4392911 -
      (46.8150 * t + 0.00059 * t * t - 0.001813 * t * t * t) / 3600.0;
}

/// Gunes'in gorunur ekvatoral konumu ve Yer'e uzakligi.
class SunPosition {
  final Equatorial equatorial;

  /// Ekliptik boylam, derece. Ay evresi ve mevsim hesaplarinda lazim.
  final double eclipticLongitudeDegrees;

  /// Yer-Gunes uzakligi, km.
  final double distanceKm;

  const SunPosition({
    required this.equatorial,
    required this.eclipticLongitudeDegrees,
    required this.distanceKm,
  });
}

/// Verilen Julian Day icin Gunes'in konumu.
SunPosition sunPosition(double jd) {
  final t = julianCenturies(jd);

  // Meeus 25.2 — ortalama boylam
  final l0 = normalizeDegrees(280.46646 + 36000.76983 * t + 0.0003032 * t * t);
  // Ortalama anomali
  final m = normalizeDegrees(357.52911 + 35999.05029 * t - 0.0001537 * t * t);
  final mRad = toRadians(m);

  // Yorunge disMerkezligi
  final e = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t;

  // Merkez denklemi — dairesel yorunge varsayimindan sapma
  final c =
      (1.914602 - 0.004817 * t - 0.000014 * t * t) * math.sin(mRad) +
      (0.019993 - 0.000101 * t) * math.sin(2 * mRad) +
      0.000289 * math.sin(3 * mRad);

  final trueLongitude = l0 + c;
  final trueAnomaly = toRadians(m + c);

  // Yer-Gunes uzakligi, astronomik birim (Meeus 25.5)
  final radiusVectorAu =
      1.000001018 * (1 - e * e) / (1 + e * math.cos(trueAnomaly));

  // Gorunur boylam: nutasyon ve aberasyon duzeltmeleri.
  final omega = toRadians(125.04 - 1934.136 * t);
  final apparentLongitude = trueLongitude - 0.00569 - 0.00478 * math.sin(omega);

  final epsilon = toRadians(obliquityDegrees(t) + 0.00256 * math.cos(omega));
  final lambda = toRadians(apparentLongitude);

  final ra = math.atan2(math.cos(epsilon) * math.sin(lambda), math.cos(lambda));
  final dec = math.asin(math.sin(epsilon) * math.sin(lambda));

  return SunPosition(
    equatorial: Equatorial(
      rightAscensionDegrees: normalizeDegrees(toDegrees(ra)),
      declinationDegrees: toDegrees(dec),
    ),
    eclipticLongitudeDegrees: normalizeDegrees(apparentLongitude),
    distanceKm: radiusVectorAu * astronomicalUnitKm,
  );
}

/// Gunes'in verilen an ve konumdaki yuksekligi, derece.
///
/// Alacakaranlik hesabinin cekirdegi. Kirilma UYGULANMAZ — alacakaranlik
/// tanimlari (−6, −12, −18) geometrik yukseklik uzerinden yapilir.
double sunAltitudeDegrees({required double jd, required Observer observer}) {
  final sun = sunPosition(jd);
  final lst = _localSiderealTime(jd, observer.longitudeEastDegrees);
  return _altitudeOf(sun.equatorial, observer, lst);
}

// Dairesel bagimlilik olmasin diye yerel yardimcilar.
double _localSiderealTime(double jd, double longitudeEastDegrees) {
  final d = jd - j2000;
  final t = d / daysPerJulianCentury;
  return normalizeDegrees(
    280.46061837 +
        360.98564736629 * d +
        0.000387933 * t * t -
        (t * t * t) / 38710000.0 +
        longitudeEastDegrees,
  );
}

double _altitudeOf(Equatorial eq, Observer observer, double lstDegrees) {
  final h = toRadians(
    normalizeDegreesSigned(lstDegrees - eq.rightAscensionDegrees),
  );
  final dec = toRadians(eq.declinationDegrees);
  final lat = toRadians(observer.latitudeDegrees);
  return toDegrees(
    math.asin(
      (math.sin(lat) * math.sin(dec) +
              math.cos(lat) * math.cos(dec) * math.cos(h))
          .clamp(-1.0, 1.0),
    ),
  );
}
