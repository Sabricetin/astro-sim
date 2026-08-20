/// T5.6 — Gokyuzu fonunun sensordeki karsiligi.
///
/// [magPerSquareArcsecToNanoLamberts] ve Ay katkisi Faz 4'te hazirdi;
/// burada o parlaklik **elektrona** ceviriliyor.
///
/// **Sonum burada UYGULANMAZ.** Yildiz isigi atmosferden gecerek gelir
/// ve sonume ugrar; gokyuzu fonu ise atmosferin kendisinin ve sehrin
/// urettigi isiktir — zaten yerde olculur. Ikisine ayni duzeltmeyi
/// uygulamak sik yapilan ve sessizce yaniltan bir hatadir.
library;

import 'calibration.dart';
import 'missing.dart';
import 'optics.dart';
import 'photon_flux.dart';

/// Bir pikselin gordugu gokyuzu parcasinin alani, yay saniyesi kare.
double pixelSolidAngleArcsec2(double arcsecondsPerPixel) =>
    arcsecondsPerPixel * arcsecondsPerPixel;

/// Gokyuzu fonunun urettigi elektron hizi, elektron / piksel / saniye.
///
/// [skyMagPerSquareArcsec] Ay katkisi dahil edilmis toplam fon
/// parlakligi. Ay'siz taban deger 0.C'den (VIIRS) gelir, Ay'in katkisi
/// Faz 4'teki K&S modelinden.
Radiometric skyElectronsPerPixelPerSecond({
  required double arcsecondsPerPixel,
  required double focalLengthMm,
  required double fNumber,
  Measured? skyMagPerSquareArcsec,
  Measured? lensTransmission,
  Measured? quantumEfficiency,
}) {
  if (skyMagPerSquareArcsec == null) {
    return RadiometricGap.single(skyBackgroundMissing);
  }
  // Yay saniyesi kare basina foton akisi.
  final perArcsec2 = RadiometricValue(
    photonFluxFromMagnitude(skyMagPerSquareArcsec.value),
    'foton cm^-2 s^-1 arcsec^-2',
  );
  final perPixel = perArcsec2.map(
    (f) => f * pixelSolidAngleArcsec2(arcsecondsPerPixel),
  );
  final collected = perPixel.combine(
    effectiveApertureAreaCm2(
      focalLengthMm: focalLengthMm,
      fNumber: fNumber,
      lensTransmission: lensTransmission,
    ),
    (f, a) => f * a,
  );
  if (quantumEfficiency == null) {
    return collected.combine(
      RadiometricGap.single(quantumEfficiencyMissing),
      (a, b) => a * b,
    );
  }
  return collected.map((p) => p * quantumEfficiency.value);
}
