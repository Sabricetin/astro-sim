/// T5.12 — Histogram doluluğu ve kirpma.
///
/// Sahada en cok islenen iki soru: "fon histogramin neresinde duruyor"
/// ve "parlak yildizlar patladi mi". Ikisi de elektron cinsinden
/// hesaplanip ADU'ya cevriliyor; ham karenin gercekten neye benzeyecegi
/// bu.
library;

import 'calibration.dart';
import 'missing.dart';
import 'sensor_calibration.dart';

/// Bir pozun ham karedeki fon seviyesi ve kirpma durumu.
class ExposureLevels {
  /// Fonun ulastigi ADU degeri, bias dahil.
  final double backgroundAdu;

  /// Fonun doyum degerine orani, 0-1.
  final double histogramFill;

  /// Fonun elektron cinsinden degeri.
  final double backgroundElectrons;

  const ExposureLevels({
    required this.backgroundAdu,
    required this.histogramFill,
    required this.backgroundElectrons,
  });

  /// Fon doyuma dayanmis mi. Gecmisse poz kurtarilamaz.
  bool get backgroundSaturated => histogramFill >= 1.0;

  /// Fon cok solda mi. Yol haritasinin "siyah kesim uyarisi" dedigi
  /// durum: fon bias'a yapisiksa golgeler nicemleme adiminda eziliyor
  /// ve o bilgi geri gelmez.
  bool get shadowsCrushed => histogramFill < 0.02;
}

/// Fonun ham karede nereye dustugu.
Radiometric exposureLevels({
  required Radiometric skyElectronsPerPixelPerSecond,
  required double exposureSeconds,
  required MeasuredSensorProfile sensor,
  Measured? darkCurrentElectronsPerSecond,
}) {
  if (darkCurrentElectronsPerSecond == null) {
    return skyElectronsPerPixelPerSecond.combine(
      RadiometricGap.single(darkCurrentMissing),
      (a, b) => a + b,
    );
  }
  return skyElectronsPerPixelPerSecond.map((skyRate) {
    final electrons =
        (skyRate + darkCurrentElectronsPerSecond.value) * exposureSeconds;
    // Kazanc e-/ADU; ADU'ya cevirmek icin BOLMEK gerekir.
    final adu = electrons / sensor.gain.value + sensor.biasOffset.value;
    return adu / sensor.saturationAdu;
  });
}

/// Yildizin tepe pikselinin doyup doymadigi.
///
/// Yaklasim: yildizin toplam elektronu ayak izine yayiliyor ve tepe
/// piksel ortalamanin [peakToMeanRatio] kati aliyor. Gaussian bir
/// profil icin bu oran ~2.5; kesin deger PSF bicimine bagli, o yuzden
/// yaklasiklik oldugu burada yaziyor.
Radiometric starPeakElectrons({
  required Radiometric starElectronsPerSecond,
  required double exposureSeconds,
  required double footprintPixels,
  double peakToMeanRatio = 2.5,
}) => starElectronsPerSecond.map(
  (rate) => rate * exposureSeconds / footprintPixels * peakToMeanRatio,
);

/// Yildiz dolum kapasitesini asiyor mu.
Radiometric starClipped({
  required Radiometric starPeak,
  required MeasuredSensorProfile sensor,
}) => starPeak.map((peak) => peak >= sensor.fullWell.value ? 1.0 : 0.0);
