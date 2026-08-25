/// T6.2 — Galaktik koordinatlar.
///
/// Samanyolu gokyuzunde bir seride uzanir ve o seridin dogal koordinat
/// sistemi ekvatoral degil **galaktik**tir: enlem `b` galaktik
/// duzlemden uzakligi, boylam `l` merkez yonunden aciyi verir.
///
/// Projedeki iki dogrudan kullanimi:
///   - Samanyolu seridini haritaya cizmek (b = 0 cizgisi).
///   - Bir hedefin Samanyolu'na ne kadar yakin oldugunu bilmek. Difuz
///     fon olcumunde bu KRITIK: galaktik duzleme yakin bir alanda fon
///     olcumu Samanyolu'nun kendisini olcer. Faz 0.B'nin fon dizisi
///     bu yuzden Pegasus'ta (b = -31) yapiliyor.
///
/// Referans cerceve J2000/ICRS. Tanim degerleri IAU 1958'den gelir ve
/// J2000'e tasinmis halleridir; bunlar OLCULMUS degil TANIM sabitleri,
/// o yuzden belirsizlikleri yok.
library;

import 'dart:math' as math;

import '../math/angles.dart';
import 'types.dart';

/// Kuzey galaktik kutbun ekvatoral konumu, J2000. Tanim.
const northGalacticPoleRaDegrees = 192.85948;
const northGalacticPoleDecDegrees = 27.12825;

/// Kuzey gok kutbunun galaktik boylami, derece. Tanim.
///
/// Donusumdeki sifir noktasini belirler: bu olmadan `l` keyfi bir
/// baslangictan olculurdu.
const northCelestialPoleGalacticLongitude = 122.93192;

/// Galaktik konum.
class Galactic {
  /// Boylam `l`, derece, [0, 360). Merkez yonu sifir.
  final double longitudeDegrees;

  /// Enlem `b`, derece, [-90, 90]. Galaktik duzlem sifir.
  final double latitudeDegrees;

  const Galactic({
    required this.longitudeDegrees,
    required this.latitudeDegrees,
  });

  /// Samanyolu seridine yakin mi?
  ///
  /// [withinDegrees] varsayilani 15: gozle bakildiginda parlak serit
  /// kabaca bu genislikte. Kesin bir sinir degil, isaret.
  bool nearGalacticPlane({double withinDegrees = 15.0}) =>
      latitudeDegrees.abs() <= withinDegrees;

  @override
  String toString() =>
      'l=${longitudeDegrees.toStringAsFixed(2)} '
      'b=${latitudeDegrees.toStringAsFixed(2)}';
}

/// Ekvatoraldan galaktige. Girdi J2000 olmali.
Galactic equatorialToGalactic(Equatorial equatorial) {
  final ra = toRadians(equatorial.rightAscensionDegrees);
  final dec = toRadians(equatorial.declinationDegrees);
  final ngpRa = toRadians(northGalacticPoleRaDegrees);
  final ngpDec = toRadians(northGalacticPoleDecDegrees);

  final sinB =
      math.sin(ngpDec) * math.sin(dec) +
      math.cos(ngpDec) * math.cos(dec) * math.cos(ra - ngpRa);
  final b = math.asin(sinB.clamp(-1.0, 1.0));

  final y = math.cos(dec) * math.sin(ra - ngpRa);
  final x =
      math.cos(ngpDec) * math.sin(dec) -
      math.sin(ngpDec) * math.cos(dec) * math.cos(ra - ngpRa);
  final l = northCelestialPoleGalacticLongitude - toDegrees(math.atan2(y, x));

  return Galactic(
    longitudeDegrees: normalizeDegrees(l),
    latitudeDegrees: toDegrees(b),
  );
}

/// Galaktikten ekvatorala. Cikti J2000.
Equatorial galacticToEquatorial(Galactic galactic) {
  final l = toRadians(galactic.longitudeDegrees);
  final b = toRadians(galactic.latitudeDegrees);
  final ngpDec = toRadians(northGalacticPoleDecDegrees);
  final lNcp = toRadians(northCelestialPoleGalacticLongitude);

  final sinDec =
      math.sin(ngpDec) * math.sin(b) +
      math.cos(ngpDec) * math.cos(b) * math.cos(lNcp - l);
  final dec = math.asin(sinDec.clamp(-1.0, 1.0));

  final y = math.cos(b) * math.sin(lNcp - l);
  final x =
      math.cos(ngpDec) * math.sin(b) -
      math.sin(ngpDec) * math.cos(b) * math.cos(lNcp - l);
  final ra = toDegrees(math.atan2(y, x)) + northGalacticPoleRaDegrees;

  return Equatorial(
    rightAscensionDegrees: normalizeDegrees(ra),
    declinationDegrees: toDegrees(dec),
  );
}

/// Galaktik merkezin ekvatoral konumu, J2000.
///
/// `l = 0, b = 0` noktasinin donusumu. Elle yazmak yerine turetilmesi
/// bilincli: donusum bozulursa bu sabit de bozulur ve test yakalar.
Equatorial get galacticCenterEquatorial => galacticToEquatorial(
  const Galactic(longitudeDegrees: 0, latitudeDegrees: 0),
);

/// Galaktik duzlemi (b = 0) ekvatoral noktalar olarak orneklendirir.
///
/// Haritaya Samanyolu seridini cizmek icin. [step] derece cinsinden
/// boylam adimi.
List<Equatorial> galacticPlaneSamples({double step = 2.0}) => [
  for (var l = 0.0; l < 360.0; l += step)
    galacticToEquatorial(Galactic(longitudeDegrees: l, latitudeDegrees: 0)),
];
