/// Presesyon: katalog epogundan gozlem tarihine koordinat tasima.
///
/// Yer'in donme ekseni ~25.800 yilda bir koni cizer. Bu, gok kutbunu ve
/// bahar noktasini kaydirir; dolayisiyla bir yildizin RA/Dec degerleri
/// zamanla degisir — yildiz kimildamadan.
///
/// Buyukluk: yilda ~50 yay saniyesi, yani **25 yilda ~0.35 derece.** Katalog
/// verisi J2000 epogunda; bugun 2026 ise duzeltmeden birakmak, projenin
/// 0.1 derecelik toleransini tek basina uc katiyla asar. Ihmal edilemez.
///
/// Kaynak: Meeus, *Astronomical Algorithms*, 2. baski, Bolum 21 (titiz
/// yontem, 21.2–21.4).
library;

import 'dart:math' as math;

import '../math/angles.dart';
import '../time/julian_day.dart';
import 'types.dart';

/// Bir yay saniyesi kac derece eder.
const double _degreesPerArcsecond = 1.0 / 3600.0;

/// Presesyon acilari (zeta, z, theta), derece cinsinden.
///
/// [fromJd] baslangic epogu, [toJd] hedef tarih.
({double zeta, double z, double theta}) _precessionAngles(
  double fromJd,
  double toJd,
) {
  // T: baslangic epogunun J2000'den uzakligi (Julian yuzyili)
  // t: iki epok arasindaki aralik (Julian yuzyili)
  final bigT = (fromJd - j2000) / daysPerJulianCentury;
  final t = (toJd - fromJd) / daysPerJulianCentury;

  // Meeus 21.2. Katsayilar yay saniyesi cinsinden.
  // fromJd == J2000 oldugunda bigT = 0 ve ifadeler 21.3'e indirgenir.
  final a = (2306.2181 + 1.39656 * bigT - 0.000139 * bigT * bigT) * t;

  final zeta = a + (0.30188 - 0.000344 * bigT) * t * t + 0.017998 * t * t * t;
  final z = a + (1.09468 + 0.000066 * bigT) * t * t + 0.018203 * t * t * t;
  final theta =
      (2004.3109 - 0.85330 * bigT - 0.000217 * bigT * bigT) * t -
      (0.42665 + 0.000217 * bigT) * t * t -
      0.041833 * t * t * t;

  return (
    zeta: zeta * _degreesPerArcsecond,
    z: z * _degreesPerArcsecond,
    theta: theta * _degreesPerArcsecond,
  );
}

/// Ekvatoral koordinati bir epoktan digerine tasir.
///
/// [position] [fromJd] epogundaki konum, donen deger [toJd] epogundaki konum.
///
/// Ozdevinim (proper motion) **dahil degildir.** O, yildizin gercekten uzayda
/// hareket etmesidir ve ayri bir duzeltmedir; presesyon ise koordinat
/// sisteminin kendisinin kaymasidir. Ozdevinim buyuk cogunluk icin yilda
/// 0.1 yay saniyesinin altinda — bu projenin toleransinda ihmal edilebilir.
/// (Barnard yildizi gibi birkac istisna vardir, ama onlar kadir 9'un
/// altinda ve katalogumuzda yoklar.)
Equatorial precess({
  required Equatorial position,
  required double fromJd,
  required double toJd,
}) {
  final angles = _precessionAngles(fromJd, toJd);

  final ra0 = toRadians(position.rightAscensionDegrees);
  final dec0 = toRadians(position.declinationDegrees);
  final zeta = toRadians(angles.zeta);
  final z = toRadians(angles.z);
  final theta = toRadians(angles.theta);

  final cosDec0 = math.cos(dec0);
  final sinDec0 = math.sin(dec0);
  final cosRaZeta = math.cos(ra0 + zeta);
  final sinRaZeta = math.sin(ra0 + zeta);
  final cosTheta = math.cos(theta);
  final sinTheta = math.sin(theta);

  // Meeus 21.4
  final capA = cosDec0 * sinRaZeta;
  final capB = cosTheta * cosDec0 * cosRaZeta - sinTheta * sinDec0;
  final capC = sinTheta * cosDec0 * cosRaZeta + cosTheta * sinDec0;

  final ra = toDegrees(z + math.atan2(capA, capB));

  // Kutba yakin cisimlerde asin(C) hassasiyet kaybeder cunku C 1'e yaklasir
  // ve turevi sifirlanir. Orada acos(sqrt(A^2+B^2)) kullanmak gerekir —
  // Kutup Yildizi (sapma +89.26) tam bu duruma girer ve dogrulama
  // matrisinde var.
  final double dec;
  if (capC.abs() > 0.99) {
    final r = math.sqrt(capA * capA + capB * capB);
    dec = toDegrees(math.acos(r.clamp(-1.0, 1.0))) * (capC.isNegative ? -1 : 1);
  } else {
    dec = toDegrees(math.asin(capC.clamp(-1.0, 1.0)));
  }

  return Equatorial(
    rightAscensionDegrees: normalizeDegrees(ra),
    declinationDegrees: dec.clamp(-90.0, 90.0),
  );
}

/// J2000 katalog koordinatini verilen tarihe tasir. En sik kullanilan hal.
Equatorial precessFromJ2000({
  required Equatorial j2000Position,
  required double toJd,
}) => precess(position: j2000Position, fromJd: j2000, toJd: toJd);

/// J2000 katalog koordinatini verilen UTC anina tasir.
Equatorial precessFromJ2000At({
  required Equatorial j2000Position,
  required DateTime utc,
}) => precessFromJ2000(j2000Position: j2000Position, toJd: julianDay(utc));
