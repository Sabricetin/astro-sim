/// T5.3 — Atmosferik sonum.
///
/// Iki parca: hava kutlesi (**hesaplanir**) ve sonum katsayisi
/// (**olculur**). Ayri tutulmalari onemli — birincisi geometri,
/// ikincisi o gecenin havasi.
library;

import 'dart:math' as math;

import 'calibration.dart';
import 'missing.dart';

/// Kasten & Young (1989) hava kutlesi.
///
///     X = 1 / (cos z + 0.50572 · (96.07995 - z)^-1.6364)
///
/// Duz cos z yaklasimi 60 derece zenit uzakliginin otesinde hizla bozulur
/// ve ufukta sonsuza gider; bu bagintı 90 derecede bile sonlu (~38)
/// kalir. Asil hedefin 24 derece yukseklikte, yani z = 66 derecede
/// oldugu icin bu fark projede dogrudan onemli.
///
/// [altitudeDegrees] ufuk uzeri yukseklik, derece.
double airmassKastenYoung(double altitudeDegrees) {
  final z = 90.0 - altitudeDegrees;
  if (z >= 96.07995) {
    // Bagintinin gecerli oldugu araligin disi: ufkun cok altinda.
    return double.infinity;
  }
  final zRad = z * math.pi / 180.0;
  return 1.0 / (math.cos(zRad) + 0.50572 * math.pow(96.07995 - z, -1.6364));
}

/// Sonum, kadir. `A = k · X`.
///
/// Katsayi [k] olculmemisse sonuc **sayi tasimaz**: hangi buyuklugun
/// eksik oldugunu tasir. Kitabi bir 0.25 koymak burada en cazip ve en
/// zararli kisayol olurdu — bkz. [extinctionCoefficientMissing].
Radiometric extinctionMagnitudes({
  required double altitudeDegrees,
  Measured? extinctionCoefficient,
}) {
  if (extinctionCoefficient == null) {
    return RadiometricGap.single(extinctionCoefficientMissing);
  }
  final x = airmassKastenYoung(altitudeDegrees);
  return RadiometricValue(extinctionCoefficient.value * x, 'kadir');
}

/// Sonumun akisi kactan bire dusurdugu. 1.0 = kayip yok.
Radiometric atmosphericTransmission({
  required double altitudeDegrees,
  Measured? extinctionCoefficient,
}) => extinctionMagnitudes(
  altitudeDegrees: altitudeDegrees,
  extinctionCoefficient: extinctionCoefficient,
).map((mag) => math.pow(10, -0.4 * mag).toDouble());
