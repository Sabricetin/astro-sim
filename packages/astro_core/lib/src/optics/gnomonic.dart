/// T2.5 — Gnomonik (rectilinear) projeksiyon.
///
/// Kureyi, bakis yonundeki teget duzleme, kurenin MERKEZINDEN projekte eder.
/// Normal (balik gozu olmayan) bir lensin gercek davranisi budur: duz
/// cizgiler duz kalir, kadraj gercekle ortusur.
///
/// **Neden bu projeksiyon, stereografik degil:** Stereografik daha "hos"
/// gorunur ve kenarlarda daha az gerdirir, ama yanlis cerceveleme verir.
/// Bu araci kullanan kisi "bu lensle bu kadraj cikar mi" sorusunu soruyor;
/// cevabin gercek lensle ayni olmasi sart.
///
/// **Kenar gerdirmesi bir bug degil:** 14 mm'de (yaklasik 104 derece)
/// koselerde ciddi gerdirme olur — gercek lensler de yapar. Ama 180
/// dereceye yaklasildikca matematik patlar; balik gozu icin ayri bir
/// projeksiyon gerekir (yol haritasi Faz 9).
library;

import 'dart:math' as math;

import '../math/angles.dart';

/// Teget duzlemdeki nokta, **tanjant birimi** cinsinden.
///
/// Birim mesafedeki teget duzlemde olculur: `x = tan(aci)`. Piksele cevirmek
/// icin odak uzunlugunu piksel cinsinden carp:
///
/// ```
/// pikselX = x * (odak_mm / piksel_adimi_mm)
/// ```
///
/// Bu, dogrudan rectilinear lens modelidir — Faz 3'teki FOV hesabiyla ayni
/// matematik.
typedef TangentPoint = ({double x, double y});

/// Gnomonik projeksiyonun matematiksel siniri, derece.
///
/// Merkeze tam 90 derece uzaklikta teget duzlem sonsuza gider. Pratikte
/// 88 derecenin otesinde sayilar kullanilmaz hale gelir; o yuzden
/// [project] bu esigin otesini `null` dondurur.
const double gnomonicMaxHalfAngleDegrees = 88.0;

/// Bakis yonune gore bir gok noktasini teget duzleme projekte eder.
///
/// Tum acilar derece. [azimuthDegrees] kuzeyden baslar, doguya artar —
/// paketin geri kalaniyla ayni sozlesme.
///
/// Donen `x` **saga**, `y` **yukari** pozitiftir. Ekran koordinati genelde
/// asagi pozitif oldugu icin cizim katmani `y`'yi ters cevirir; bu paket
/// ekran degil, gokyuzu koordinati uretir.
///
/// [rollDegrees] kamera dondurmesi (saat yonunun tersi pozitif). Faz 3'teki
/// iki parmakla dondurme bunu besleyecek.
///
/// Nokta bakisin **arkasindaysa veya sinirin otesindeyse `null`** doner.
/// Cagiran bunu "cizme" diye okumali; sifir dondurmek noktalari merkeze
/// yigardi.
TangentPoint? project({
  required double azimuthDegrees,
  required double altitudeDegrees,
  required double centerAzimuthDegrees,
  required double centerAltitudeDegrees,
  double rollDegrees = 0.0,
}) {
  final alt = toRadians(altitudeDegrees);
  final alt0 = toRadians(centerAltitudeDegrees);
  final deltaAz = toRadians(
    angularDifferenceDegrees(azimuthDegrees, centerAzimuthDegrees),
  );

  final sinAlt = math.sin(alt);
  final cosAlt = math.cos(alt);
  final sinAlt0 = math.sin(alt0);
  final cosAlt0 = math.cos(alt0);
  final cosDeltaAz = math.cos(deltaAz);

  // cos(c): noktanin bakis yonunden acisal uzakliginin kosinusu.
  final cosC = sinAlt0 * sinAlt + cosAlt0 * cosAlt * cosDeltaAz;

  // Sifir veya negatif: nokta teget duzlemin arkasinda kaliyor.
  // Esik, 88 derecenin kosinusu.
  final minCosC = math.cos(toRadians(gnomonicMaxHalfAngleDegrees));
  if (cosC <= minCosC) return null;

  final x = cosAlt * math.sin(deltaAz) / cosC;
  final y = (cosAlt0 * sinAlt - sinAlt0 * cosAlt * cosDeltaAz) / cosC;

  if (rollDegrees == 0.0) return (x: x, y: y);

  final roll = toRadians(rollDegrees);
  final cosRoll = math.cos(roll);
  final sinRoll = math.sin(roll);
  return (x: x * cosRoll + y * sinRoll, y: -x * sinRoll + y * cosRoll);
}

/// Teget duzlemdeki bir noktayi gok koordinatina geri cevirir.
///
/// "Ekranda su noktada ne var?" sorusunun cevabi. Kullanici bakisi
/// suruklediginde veya bir yildiza dokundugunda gerekli.
({double azimuthDegrees, double altitudeDegrees}) unproject({
  required double x,
  required double y,
  required double centerAzimuthDegrees,
  required double centerAltitudeDegrees,
  double rollDegrees = 0.0,
}) {
  var px = x;
  var py = y;
  if (rollDegrees != 0.0) {
    // Ileri donusumdeki dondurmeyi geri al.
    final roll = toRadians(-rollDegrees);
    final cosRoll = math.cos(roll);
    final sinRoll = math.sin(roll);
    final rx = px * cosRoll + py * sinRoll;
    final ry = -px * sinRoll + py * cosRoll;
    px = rx;
    py = ry;
  }

  final alt0 = toRadians(centerAltitudeDegrees);
  final rho = math.sqrt(px * px + py * py);

  // Merkezin tam kendisi: bolme yok, dogrudan bakis yonu.
  if (rho == 0.0) {
    return (
      azimuthDegrees: normalizeDegrees(centerAzimuthDegrees),
      altitudeDegrees: centerAltitudeDegrees,
    );
  }

  final c = math.atan(rho);
  final sinC = math.sin(c);
  final cosC = math.cos(c);
  final sinAlt0 = math.sin(alt0);
  final cosAlt0 = math.cos(alt0);

  final altitude = math.asin(
    (cosC * sinAlt0 + py * sinC * cosAlt0 / rho).clamp(-1.0, 1.0),
  );
  final deltaAz = math.atan2(
    px * sinC,
    rho * cosAlt0 * cosC - py * sinAlt0 * sinC,
  );

  return (
    azimuthDegrees: normalizeDegrees(centerAzimuthDegrees + toDegrees(deltaAz)),
    altitudeDegrees: toDegrees(altitude),
  );
}
