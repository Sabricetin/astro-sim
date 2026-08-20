/// T5.10 — Sinyal / gurultu.
///
/// Iki ayri soru, iki ayri formul:
///
/// - **Nokta kaynak** (yildiz): sinyal birkac piksele toplanir, gurultu
///   o piksellerin tamamindan gelir.
/// - **Difuz hedef** (Samanyolu, bulutsu): sinyal de gurultu de piksel
///   basinadir; "kac piksel" sorusu yoktur.
///
/// Ikisini ayirmamak yol haritasinin acikca uyardigi hata: difuz bir
/// hedefi nokta kaynak gibi hesaplamak SNR'i olcek kadar sisirir.
///
/// Temel baginti (CCD denklemi):
///
///     SNR = S / sqrt( S + n · (B + D + R²) )
///
/// S toplam yildiz elektronu, n yildizin kapladigi piksel sayisi,
/// B piksel basina fon, D piksel basina karanlik akim, R okuma
/// gurultusu.
library;

import 'dart:math' as math;

import 'calibration.dart';
import 'missing.dart';
import 'sensor_calibration.dart';

/// Bir pozdaki nokta kaynak SNR'i.
///
/// [starElectronsPerSecond] zincirden gelen yildiz sinyali.
/// [skyElectronsPerPixelPerSecond] fon.
/// [footprintPixels] yildizin kapladigi piksel sayisi (bkz. psf.dart).
Radiometric pointSourceSnr({
  required Radiometric starElectronsPerSecond,
  required Radiometric skyElectronsPerPixelPerSecond,
  required double footprintPixels,
  required double exposureSeconds,
  required MeasuredSensorProfile sensor,
  Measured? darkCurrentElectronsPerSecond,
}) {
  if (darkCurrentElectronsPerSecond == null) {
    return starElectronsPerSecond
        .combine(skyElectronsPerPixelPerSecond, (a, b) => a + b)
        .combine(RadiometricGap.single(darkCurrentMissing), (a, b) => a + b);
  }
  return starElectronsPerSecond.combine(skyElectronsPerPixelPerSecond, (
    starRate,
    skyRate,
  ) {
    final signal = starRate * exposureSeconds;
    final sky = skyRate * exposureSeconds;
    final dark = darkCurrentElectronsPerSecond.value * exposureSeconds;
    final read = sensor.readNoise.value;
    final variance = signal + footprintPixels * (sky + dark + read * read);
    return variance <= 0 ? 0.0 : signal / math.sqrt(variance);
  });
}

/// Difuz hedef icin piksel basina SNR.
///
/// [targetElectronsPerPixelPerSecond] hedefin kendi yuzey parlakligi;
/// fon bundan ayri.
Radiometric diffuseSnrPerPixel({
  required Radiometric targetElectronsPerPixelPerSecond,
  required Radiometric skyElectronsPerPixelPerSecond,
  required double exposureSeconds,
  required MeasuredSensorProfile sensor,
  Measured? darkCurrentElectronsPerSecond,
}) {
  if (darkCurrentElectronsPerSecond == null) {
    return targetElectronsPerPixelPerSecond
        .combine(skyElectronsPerPixelPerSecond, (a, b) => a + b)
        .combine(RadiometricGap.single(darkCurrentMissing), (a, b) => a + b);
  }
  return targetElectronsPerPixelPerSecond.combine(
    skyElectronsPerPixelPerSecond,
    (targetRate, skyRate) {
      final signal = targetRate * exposureSeconds;
      final sky = skyRate * exposureSeconds;
      final dark = darkCurrentElectronsPerSecond.value * exposureSeconds;
      final read = sensor.readNoise.value;
      final variance = signal + sky + dark + read * read;
      return variance <= 0 ? 0.0 : signal / math.sqrt(variance);
    },
  );
}

/// N kare yiginlandiginda SNR kok N kati artar.
///
/// Yol haritasi Faz 8'in konusu; burada oldugu icin poz suresi ile kare
/// sayisi arasindaki takasi simdiden dogru gosterebiliyoruz.
/// Varsayim: kareler bagimsiz ve hizalama kaybi yok.
Radiometric stackedSnr({
  required Radiometric singleFrameSnr,
  required int frameCount,
}) => singleFrameSnr.map((snr) => snr * math.sqrt(frameCount));

/// Okuma gurultusunun fona gomuldugu poz suresi, saniye.
///
/// Pratikteki en yararli tek sayi: bundan uzun pozlarda okuma gurultusu
/// artik onemli degildir, kareyi uzatmak yerine cogaltmak daha iyidir.
/// Olcut: fon varyansi okuma varyansinin [factor] katini gecsin.
Radiometric readNoiseSwampedExposure({
  required Radiometric skyElectronsPerPixelPerSecond,
  required MeasuredSensorProfile sensor,
  double factor = 10.0,
}) => skyElectronsPerPixelPerSecond.map((skyRate) {
  if (skyRate <= 0) return double.infinity;
  final read = sensor.readNoise.value;
  return factor * read * read / skyRate;
});
