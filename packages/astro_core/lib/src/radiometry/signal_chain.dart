/// T5 — Isik zinciri: kadirden elektrona.
///
/// Zincirin tamami:
///
///     kadir -> bant duzeltmesi    (OLCULECEK: dV_G)
///           -> atmosferik sonum    (OLCULECEK: k)
///           -> sifir noktasi       (OLCULECEK: ZP)
///           -> elektron / saniye
///
/// **Sifir noktasi neden QE ve T'nin yerine gecti:** ikisi de tek
/// baslarina olculemez (uretici yayinlamaz, laboratuvar gerekir) ama
/// zincirin ihtiyaci zaten carpimlaridir. Kadiri bilinen bir yildizin
/// kac ADU verdigi TEK olcumle o carpimi veriyor — ustelik aciklik
/// alanini ve poz normalizasyonunu da icine alarak. Uc buyuklugu ayri
/// ayri kestirmek uc ayri uydurma demek olurdu.
///
/// ZP kadir olceginde tanimli:  m_yerdeki = m_alet + ZP,
/// m_alet = -2.5 log10(ADU / saniye).
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

/// Aleti kadirden ADU/saniyeye: `ADU/s = 10^(-0.4 · m_alet)`.
double aduPerSecondFromInstrumentalMagnitude(double instrumentalMag) =>
    _pow10(-0.4 * instrumentalMag);

double _pow10(double x) => math.pow(10, x).toDouble();

/// Bir yildizin sensorde urettigi ADU hizi, ADU/saniye.
///
/// Sifir noktasi tabanli yol. [starElectronRate]'in yerini alir:
/// QE, lens verimi ve aciklik alani [zeroPoint] icinde birlikte
/// tasiniyor.
///
///     m_yerdeki = V + dV_G + k·X       (atmosferden gecmis kadir)
///     m_alet    = m_yerdeki - ZP
///     ADU/s     = 10^(-0.4 · m_alet)
Radiometric starAduPerSecond({
  required double vMagnitude,
  required double altitudeDegrees,
  double? colorIndexBV,
  Measured? extinctionCoefficient,
  Measured? zeroPoint,
  Measured? bandCorrectionPerColorIndex,
}) {
  final gaps = <MissingQuantity>[];
  if (extinctionCoefficient == null) gaps.add(extinctionCoefficientMissing);
  if (zeroPoint == null) gaps.add(zeroPointMissing);
  if (bandCorrectionPerColorIndex == null) {
    gaps.add(bandCorrectionMissing);
  } else if (colorIndexBV == null) {
    gaps.add(colorIndexMissing);
  }
  if (gaps.isNotEmpty) return RadiometricGap(gaps);

  final band = bandCorrectionPerColorIndex!.value * colorIndexBV!;
  final x = airmassKastenYoung(altitudeDegrees);
  final ground = vMagnitude + band + extinctionCoefficient!.value * x;
  return RadiometricValue(
    aduPerSecondFromInstrumentalMagnitude(ground - zeroPoint!.value),
    'ADU/s',
  );
}

/// Gokyuzu fonu, ADU/piksel/saniye — sifir noktasindan.
///
/// **Sonum uygulanmaz.** Yildiz isigi atmosferden gecerek gelir ve
/// soner; gokyuzu fonu atmosferin ve sehrin kendi isigidir, zaten
/// yerde olculur.
Radiometric skyAduPerPixelPerSecond({
  required double arcsecondsPerPixel,
  Measured? skyMagPerSquareArcsec,
  Measured? zeroPoint,
}) {
  final gaps = <MissingQuantity>[];
  if (skyMagPerSquareArcsec == null) gaps.add(skyBackgroundMissing);
  if (zeroPoint == null) gaps.add(zeroPointMissing);
  if (gaps.isNotEmpty) return RadiometricGap(gaps);

  final omega = arcsecondsPerPixel * arcsecondsPerPixel;
  final perArcsec2 = aduPerSecondFromInstrumentalMagnitude(
    skyMagPerSquareArcsec!.value - zeroPoint!.value,
  );
  return RadiometricValue(perArcsec2 * omega, 'ADU/px/s');
}
