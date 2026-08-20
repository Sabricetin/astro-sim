/// T5 — Isik zinciri: kadirden elektrona.
///
/// Zincirin tamami:
///
///     kadir -> foton akisi        (yayinlanmis sabit, hesaplanir)
///           -> bant duzeltmesi    (OLCULECEK: dV_G)
///           -> atmosferik sonum   (OLCULECEK: k)
///           -> optik toplama      (geometri × OLCULECEK: T)
///           -> kuantum verimi     (OLCULECEK: QE)
///           -> elektron / saniye
///
/// Alti halkanin ikisi hesaplanabiliyor, dordu olcum bekliyor. Bu
/// yuzden [starElectronRate] bugun **sayi dondurmez** — hangi dort
/// buyuklugun eksik oldugunu dondurur.
///
/// Eksikler birikerek tasinir: ilk eksikte durup digerlerini gizlemez.
/// Sebep pratik — kullaniciya "once sunu olc" deyip her seferinde bir
/// sonrakini kesfettirmek yerine, gerekenlerin tamamini bir kerede
/// soylemek.
library;

import 'dart:math' as math;

import 'calibration.dart';
import 'extinction.dart';
import 'missing.dart';
import 'optics.dart';
import 'photon_flux.dart';
import 'sensor_calibration.dart';

/// Bir yildizin sensorde urettigi elektron hizi, elektron/saniye.
///
/// [vMagnitude] Johnson V kadiri.
/// [colorIndexBV] B-V renk indeksi; bant duzeltmesi buna bagli.
/// Katalogda yoksa null gelir ve duzeltme uygulanamaz.
Radiometric starElectronRate({
  required double vMagnitude,
  required double altitudeDegrees,
  required double focalLengthMm,
  required double fNumber,
  double? colorIndexBV,
  Measured? extinctionCoefficient,
  Measured? lensTransmission,
  Measured? quantumEfficiency,
  Measured? bandCorrectionPerColorIndex,
}) {
  // 1. Atmosfer disi foton akisi — hesaplanir.
  final flux = RadiometricValue(
    photonFluxFromMagnitude(vMagnitude),
    'foton cm^-2 s^-1',
  );

  // 2. Bant duzeltmesi. Kameranin yesil kanali Johnson V degil; fark
  //    yildizin rengine bagli.
  final Radiometric banded;
  if (bandCorrectionPerColorIndex == null) {
    banded = RadiometricGap.single(bandCorrectionMissing);
  } else if (colorIndexBV == null) {
    // Katsayi olculmus ama yildizin rengi bilinmiyor. Bu bir kalibrasyon
    // eksigi degil, veri eksigi — ama sonuc yine hesaplanamaz.
    banded = RadiometricGap.single(
      const MissingQuantity(
        name: 'yildizin renk indeksi',
        symbol: 'B-V',
        unit: 'kadir',
        comesFrom: 'yildiz katalogu',
        why:
            'Bant duzeltmesi renge bagli. Rengi bilinmeyen yildiz icin '
            'ortalama bir renk varsaymak, duzeltmenin duzeltmeye '
            'calistigi hatayi geri getirir.',
      ),
    );
  } else {
    final deltaMag = bandCorrectionPerColorIndex.value * colorIndexBV;
    banded = flux.map((f) => f * fluxRatioFromMagnitudeDifference(-deltaMag));
  }

  // 3. Atmosferik sonum — k olculecek.
  final transmitted = banded.combine(
    atmosphericTransmission(
      altitudeDegrees: altitudeDegrees,
      extinctionCoefficient: extinctionCoefficient,
    ),
    (f, t) => f * t,
  );

  // 4. Optigin topladigi alan — geometri × T.
  final collected = transmitted.combine(
    effectiveApertureAreaCm2(
      focalLengthMm: focalLengthMm,
      fNumber: fNumber,
      lensTransmission: lensTransmission,
    ),
    (f, a) => f * a,
  );

  // 5. Kuantum verimi.
  if (quantumEfficiency == null) {
    return collected.combine(
      RadiometricGap.single(quantumEfficiencyMissing),
      (a, b) => a * b,
    );
  }
  return collected.map((p) => p * quantumEfficiency.value);
}

/// Toplam gurultu, elektron. Shot + okuma + karanlik akim.
///
///     sigma = sqrt(S + N_read^2 + I_d · t)
///
/// Bu **hesaplanabilir** bir formul; icine giren sinyal ve karanlik akim
/// olculmus olmak zorunda. Okuma gurultusu Faz 0.A'da olculdu, karanlik
/// akim Faz 0.B Dizi C'yi bekliyor.
Radiometric totalNoiseElectrons({
  required Radiometric signalElectrons,
  required MeasuredSensorProfile sensor,
  required double exposureSeconds,
  Measured? darkCurrentElectronsPerSecond,
}) {
  if (darkCurrentElectronsPerSecond == null) {
    return signalElectrons.combine(
      RadiometricGap.single(darkCurrentMissing),
      (a, b) => a + b,
    );
  }
  return signalElectrons.map((s) {
    final read = sensor.readNoise.value;
    final dark = darkCurrentElectronsPerSecond.value * exposureSeconds;
    final variance = s + read * read + dark;
    return variance <= 0 ? 0.0 : math.sqrt(variance);
  });
}

/// Sinyal/gurultu orani.
Radiometric signalToNoise({
  required Radiometric signalElectrons,
  required Radiometric noiseElectrons,
}) => signalElectrons.combine(noiseElectrons, (s, n) => n == 0 ? 0 : s / n);

/// Zincirin bugun neyi bekledigi. Arayuz "hesap neden yok" diye
/// sordugunda cevap bu.
List<MissingQuantity> pendingCalibration({
  Measured? extinctionCoefficient,
  Measured? lensTransmission,
  Measured? quantumEfficiency,
  Measured? bandCorrectionPerColorIndex,
  Measured? darkCurrent,
  Measured? skyBackground,
}) => [
  if (extinctionCoefficient == null) extinctionCoefficientMissing,
  if (lensTransmission == null) lensTransmissionMissing,
  if (quantumEfficiency == null) quantumEfficiencyMissing,
  if (bandCorrectionPerColorIndex == null) bandCorrectionMissing,
  if (darkCurrent == null) darkCurrentMissing,
  if (skyBackground == null) skyBackgroundMissing,
];
