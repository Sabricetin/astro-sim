/// T4.4 — Ay'in konumu, uzakligi ve evresi.
///
/// Yol haritasi: "Meeus'un kisaltilmis serisi (±0.3 derece) yeterli — tam
/// ELP teorisine girmeye gerek yok." Bu dosya o kisaltilmis seriyi
/// uyguluyor: boylamda alti, enlemde dort, uzaklikta dort terim.
///
/// **Neden ±0.3 derece yeterli:** Ay'in kendi gorunur capi 0.5 derece.
/// Bu projede Ay'in konumu iki soruya cevap veriyor: gokyuzunun neresinde
/// (ufkun ustunde mi, hedefe ne kadar yakin) ve ne kadar dolu. Ikisi de
/// yarim derecelik hassasiyetle bozulmaz. Ay tutulmasi hesaplasaydik
/// yetmezdi — hesaplamiyoruz.
///
/// Kaynak: Meeus, *Astronomical Algorithms*, 2. baski, Bolum 47 ve 48.
library;

import 'dart:math' as math;

import '../coords/types.dart';
import '../math/angles.dart';
import '../time/julian_day.dart';
import 'sun.dart';

/// Ay'in bir andaki durumu.
class MoonPosition {
  final Equatorial equatorial;

  /// Yer merkezinden Ay'a uzaklik, km. Ortalama ~384.400.
  final double distanceKm;

  /// Aydinlanan yuzun orani, 0 (yeni ay) - 1 (dolunay).
  final double illuminatedFraction;

  /// Evre acisi (Gunes-Ay-Yer acisi), derece. 0 = dolunay, 180 = yeni ay.
  final double phaseAngleDegrees;

  /// Gunes ile Ay arasindaki gorunur aci (uzanim), derece.
  final double elongationDegrees;

  const MoonPosition({
    required this.equatorial,
    required this.distanceKm,
    required this.illuminatedFraction,
    required this.phaseAngleDegrees,
    required this.elongationDegrees,
  });

  /// Yuzde olarak dolulukd. Arayuzde "%78 dolu" demek icin.
  double get illuminatedPercent => illuminatedFraction * 100.0;

  /// Kabaca hangi evrede: yeni, ilk dordun, dolunay, son dordun.
  ///
  /// [waxing] buyuyen evre (yeni aydan dolunaya) icin true.
  bool get isWaxing => elongationDegrees < 180.0;
}

/// Verilen Julian Day icin Ay'in konumu ve evresi.
MoonPosition moonPosition(double jd) {
  final t = julianCenturies(jd);

  // Meeus 47.1-47.5 — temel aci argumanlari, derece.
  final lPrime = normalizeDegrees(218.3164477 + 481267.88123421 * t);
  final d = normalizeDegrees(297.8501921 + 445267.1114034 * t);
  final m = normalizeDegrees(357.5291092 + 35999.0502909 * t);
  final mPrime = normalizeDegrees(134.9633964 + 477198.8675055 * t);
  final f = normalizeDegrees(93.2720950 + 483202.0175233 * t);

  final dR = toRadians(d);
  final mR = toRadians(m);
  final mpR = toRadians(mPrime);
  final fR = toRadians(f);

  // Boylamdaki basli terimler (Meeus 47. bolum tablosunun ilk satirlari).
  final longitude =
      lPrime +
      6.288774 * math.sin(mpR) +
      1.274027 * math.sin(2 * dR - mpR) +
      0.658314 * math.sin(2 * dR) +
      0.213618 * math.sin(2 * mpR) -
      0.185116 * math.sin(mR) -
      0.114332 * math.sin(2 * fR);

  // Enlem — Ay'in ekliptikten sapmasi, en fazla ~5.1 derece.
  final latitude =
      5.128122 * math.sin(fR) +
      0.280602 * math.sin(mpR + fR) +
      0.277693 * math.sin(mpR - fR) +
      0.173237 * math.sin(2 * dR - fR);

  // Uzaklik, km.
  final distance =
      385000.56 -
      20905.355 * math.cos(mpR) -
      3699.111 * math.cos(2 * dR - mpR) -
      2955.968 * math.cos(2 * dR) -
      569.925 * math.cos(2 * mpR);

  // Ekliptik -> ekvatoral.
  final epsilon = toRadians(obliquityDegrees(t));
  final lambda = toRadians(normalizeDegrees(longitude));
  final beta = toRadians(latitude);

  final ra = math.atan2(
    math.sin(lambda) * math.cos(epsilon) - math.tan(beta) * math.sin(epsilon),
    math.cos(lambda),
  );
  final dec = math.asin(
    (math.sin(beta) * math.cos(epsilon) +
            math.cos(beta) * math.sin(epsilon) * math.sin(lambda))
        .clamp(-1.0, 1.0),
  );

  final equatorial = Equatorial(
    rightAscensionDegrees: normalizeDegrees(toDegrees(ra)),
    declinationDegrees: toDegrees(dec),
  );

  // Evre: once Gunes-Ay gorunur acisi (uzanim), sonra evre acisi.
  final sun = sunPosition(jd);
  final elongation = _angularSeparation(sun.equatorial, equatorial);

  // Meeus 48.3 — Gunes cok uzak oldugu icin evre acisi uzanimin
  // tumleyenine yakindir ama tam degil; uzakliklar hesaba katiliyor.
  final psi = toRadians(elongation);
  final phaseAngle = math.atan2(
    sun.distanceKm * math.sin(psi),
    distance - sun.distanceKm * math.cos(psi),
  );

  // Meeus 48.1 — aydinlanan oran.
  final illuminated = (1.0 + math.cos(phaseAngle)) / 2.0;

  return MoonPosition(
    equatorial: equatorial,
    distanceKm: distance,
    illuminatedFraction: illuminated.clamp(0.0, 1.0),
    phaseAngleDegrees: toDegrees(phaseAngle),
    elongationDegrees: elongation,
  );
}

double _angularSeparation(Equatorial a, Equatorial b) {
  final dec1 = toRadians(a.declinationDegrees);
  final dec2 = toRadians(b.declinationDegrees);
  final dRa = toRadians(b.rightAscensionDegrees - a.rightAscensionDegrees);
  return toDegrees(
    math.acos(
      (math.sin(dec1) * math.sin(dec2) +
              math.cos(dec1) * math.cos(dec2) * math.cos(dRa))
          .clamp(-1.0, 1.0),
    ),
  );
}
