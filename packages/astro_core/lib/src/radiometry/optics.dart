/// T5.4 — Optigin topladigi isik.
///
/// Geometri kismi hesaplanir; aktarim verimi olculur.
library;

import 'dart:math' as math;

import 'calibration.dart';
import 'missing.dart';

/// Giris acikliginin alani, cm^2.
///
/// Capı D = f / N. Buradaki tek incelik birim: odak uzunlugu mm
/// geliyor, alan cm^2 isteniyor. Donusum sinirda yapiliyor.
///
/// Bu **geometrik** aciklik — camdan gercekte ne kadar isik gectigi
/// ayri bir sorun, bkz. [lensTransmissionMissing].
double apertureAreaCm2({
  required double focalLengthMm,
  required double fNumber,
}) {
  final diameterCm = focalLengthMm / fNumber / 10.0;
  return math.pi * math.pow(diameterCm / 2.0, 2).toDouble();
}

/// Sensore gercekten ulasan foton orani icin efektif toplama alani,
/// cm^2. Geometrik alan × aktarim verimi.
///
/// Verim olculmemisse sonuc sayi tasimaz. "f/2.8 lens f/2.8 kadar isik
/// gecirir" varsayimi yol haritasinin Tuzak 3'u; %15 cikis kriterini
/// tek basina dusurebilir.
Radiometric effectiveApertureAreaCm2({
  required double focalLengthMm,
  required double fNumber,
  Measured? lensTransmission,
}) {
  if (lensTransmission == null) {
    return RadiometricGap.single(lensTransmissionMissing);
  }
  final geometric = apertureAreaCm2(
    focalLengthMm: focalLengthMm,
    fNumber: fNumber,
  );
  return RadiometricValue(geometric * lensTransmission.value, 'cm^2');
}
