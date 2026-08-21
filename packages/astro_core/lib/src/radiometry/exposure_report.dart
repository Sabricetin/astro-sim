/// T5 — Zincirin ciktisi: bir pozun raporu.
///
/// Yol haritasinin "aracin ciktisi guzel bir goruntu degil, bir rapor"
/// dedigi sey. Hedeflenen cumle:
///
/// > Galaktik merkez: 23 derece yukseklik, hava kutlesi 2.5, sonum 0.63
/// > kadir. SNR 4.2. Yildiz izi 2.1 px. Fon histogramin %38'ini
/// > dolduruyor. Parlak yildizlarda kirpma yok.
///
/// Bugun bu cumlenin **geometrik yarisi** kuruluyor: yukseklik, hava
/// kutlesi ve iz hesaplanabiliyor. Sonum, SNR ve histogram kalibrasyon
/// bekliyor ve o kismi bos birakmak yerine **neyin eksik oldugunu**
/// yaziyor.
///
/// Bunun onemi sunda: eksik kismi "hesaplaniyor..." veya "0.0" diye
/// gostermek kullaniciya arac bozukmus hissi verir. "Sonum icin k
/// olculmedi, 0.B Dizi B'den gelecek" demek ise durumu dogru anlatir.
library;

import 'dart:math' as math;

import 'calibration.dart';
import 'extinction.dart';
import 'histogram.dart';
import 'optics.dart';
import 'photon_flux.dart';
import 'missing.dart';
import 'psf.dart';
import 'sensor_calibration.dart';
import 'signal_chain.dart';
import 'snr.dart';
import '../camera/exposure.dart';
import '../camera/field_of_view.dart';

/// Kalibrasyon defterinin tamami.
///
/// Alti olcum bekleyen buyukluk tek yerde. Hepsi null iken zincir
/// hicbir sayi uretmez; doldukca zincirin daha buyuk kismi acilir.
class CalibrationSet {
  final Measured? extinctionCoefficient;

  /// Fotometrik sifir noktasi — QE, lens verimi ve aciklik alanini
  /// BIRLIKTE tasir. Ucu ayri ayri olculemez; carpimlari tek olcumle
  /// elde edilir.
  ///
  /// Belirli bir diyaframda olculur. Baska diyaframa tasimak icin
  /// [zeroPointAtAperture] kullanilir — aciklik alani geometrik oldugu
  /// icin bu tasima kesindir.
  final Measured? zeroPoint;

  /// [zeroPoint]'in olculdugu diyafram.
  final double? zeroPointFNumber;

  final Measured? bandCorrectionPerColorIndex;
  final Measured? darkCurrent;
  final Measured? skyMagPerSquareArcsec;
  final Measured? psfFwhmPixels;

  const CalibrationSet({
    this.extinctionCoefficient,
    this.zeroPoint,
    this.zeroPointFNumber,
    this.bandCorrectionPerColorIndex,
    this.darkCurrent,
    this.skyMagPerSquareArcsec,
    this.psfFwhmPixels,
  });

  /// Sifir noktasini baska bir diyaframa tasir.
  ///
  ///     ZP(N) = ZP_ref + 2.5·log10( A(N) / A(N_ref) )
  ///
  /// Aciklik alani saf geometri oldugu icin bu tasima kesin. Tasinmayan
  /// tek sey lens veriminin diyaframla degisimi — pratikte kucuk.
  Measured? zeroPointAtAperture(double fNumber) {
    final zp = zeroPoint;
    final ref = zeroPointFNumber;
    if (zp == null || ref == null) return null;
    if ((fNumber - ref).abs() < 1e-9) return zp;
    final ratio =
        apertureAreaCm2(focalLengthMm: 100, fNumber: fNumber) /
        apertureAreaCm2(focalLengthMm: 100, fNumber: ref);
    return Measured(
      value: zp.value + 2.5 * (math.log(ratio) / math.ln10),
      unit: zp.unit,
      source: '${zp.source} (f/$ref -> f/$fNumber tasindi)',
      relativeUncertainty: zp.relativeUncertainty,
    );
  }

  /// Hicbir olcumun gelmedigi bugunku durum.
  static const empty = CalibrationSet();

  List<MissingQuantity> get missing => [
    if (extinctionCoefficient == null) extinctionCoefficientMissing,
    if (zeroPoint == null) zeroPointMissing,
    if (bandCorrectionPerColorIndex == null) bandCorrectionMissing,
    if (darkCurrent == null) darkCurrentMissing,
    if (skyMagPerSquareArcsec == null) skyBackgroundMissing,
    if (psfFwhmPixels == null) psfFwhmMissing,
  ];

  /// Zincirdeki toplam halka sayisi.
  static const linkCount = 6;

  bool get isComplete => missing.isEmpty;

  /// Kac halkanin tamamlandigi — arayuzde ilerleme gostermek icin.
  int get completedCount => linkCount - missing.length;
}

/// Bir pozun tam raporu.
class ExposureReport {
  final String targetName;
  final double altitudeDegrees;

  /// Hesaplanabilen: geometri.
  final double airmass;
  final double trailPixels;
  final double arcsecondsPerPixel;
  final double maxExposureSecondsNpf;

  /// Kalibrasyon bekleyenler.
  final Radiometric extinctionMagnitudes;
  final Radiometric starElectronsPerSecond;
  final Radiometric skyElectronsPerPixelPerSecond;
  final Radiometric snr;
  final Radiometric histogramFill;
  final Radiometric starClipped;
  final Radiometric readNoiseSwampedAt;

  final List<MissingQuantity> missing;

  const ExposureReport({
    required this.targetName,
    required this.altitudeDegrees,
    required this.airmass,
    required this.trailPixels,
    required this.arcsecondsPerPixel,
    required this.maxExposureSecondsNpf,
    required this.extinctionMagnitudes,
    required this.starElectronsPerSecond,
    required this.skyElectronsPerPixelPerSecond,
    required this.snr,
    required this.histogramFill,
    required this.starClipped,
    required this.readNoiseSwampedAt,
    required this.missing,
  });

  bool get isComplete => missing.isEmpty;

  /// Bugun soylenebilenler. Kalibrasyon geldikce uzar.
  List<String> get statements {
    final lines = <String>[
      '$targetName: ${altitudeDegrees.toStringAsFixed(0)} derece yukseklik, '
          'hava kutlesi ${airmass.toStringAsFixed(2)}',
      'Olcek ${arcsecondsPerPixel.toStringAsFixed(1)}"/px, '
          'yildiz izi ${trailPixels.toStringAsFixed(1)} px '
          '(NPF siniri ${maxExposureSecondsNpf.toStringAsFixed(1)} s)',
    ];
    final ext = extinctionMagnitudes.valueOrNull;
    if (ext != null) {
      lines.add('Sonum ${ext.toStringAsFixed(2)} kadir');
    }
    final s = snr.valueOrNull;
    if (s != null) {
      lines.add('SNR ${s.toStringAsFixed(1)}');
    }
    final fill = histogramFill.valueOrNull;
    if (fill != null) {
      lines.add(
        'Fon histogramin %${(fill * 100).toStringAsFixed(0)}\'ini dolduruyor',
      );
    }
    final clipped = starClipped.valueOrNull;
    if (clipped != null) {
      lines.add(
        clipped > 0
            ? 'Parlak yildizlarda kirpma VAR'
            : 'Parlak yildizlarda kirpma yok',
      );
    }
    return lines;
  }

  /// Neden eksik oldugunu anlatan satirlar. Bos liste = rapor tam.
  List<String> get pendingStatements => [
    for (final q in missing) '${q.symbol} olculmedi — ${q.comesFrom}',
  ];
}

/// Bir poz icin tam rapor uretir.
///
/// Geometrik kisim her zaman hesaplanir; radyometrik kisim
/// [calibration] doldukca acilir.
ExposureReport buildExposureReport({
  required String targetName,
  required double vMagnitude,
  required double altitudeDegrees,
  required double declinationDegrees,
  required double focalLengthMm,
  required double fNumber,
  required double exposureSeconds,
  required MeasuredSensorProfile sensor,
  required double pixelPitchMicrometers,
  double? colorIndexBV,
  CalibrationSet calibration = CalibrationSet.empty,
}) {
  final scale = arcsecondsPerPixel(
    pixelPitchMicrometers: pixelPitchMicrometers,
    focalLengthMm: focalLengthMm,
  );
  final trail = starTrailPixels(
    exposureSeconds: exposureSeconds,
    pixelPitchMicrometers: pixelPitchMicrometers,
    focalLengthMm: focalLengthMm,
    declinationDegrees: declinationDegrees,
  );

  // Sifir noktasi yolu. ZP olculdugu diyaframdan buradakine tasiniyor;
  // aciklik alani geometrik oldugu icin tasima kesin.
  final zp = calibration.zeroPointAtAperture(fNumber);

  // ADU -> elektron: kazanc e-/ADU oldugu icin CARPILIR.
  final star = starAduPerSecond(
    vMagnitude: vMagnitude,
    altitudeDegrees: altitudeDegrees,
    colorIndexBV: colorIndexBV,
    extinctionCoefficient: calibration.extinctionCoefficient,
    zeroPoint: zp,
    bandCorrectionPerColorIndex: calibration.bandCorrectionPerColorIndex,
  ).map((adu) => adu * sensor.gain.value);

  final sky = skyAduPerPixelPerSecond(
    arcsecondsPerPixel: scale,
    skyMagPerSquareArcsec: calibration.skyMagPerSquareArcsec,
    zeroPoint: zp,
  ).map((adu) => adu * sensor.gain.value);

  // PSF olculmemisse ayak izi bilinmez; SNR de bilinmez.
  final fwhm = calibration.psfFwhmPixels;
  final footprint = fwhm == null
      ? null
      : starFootprintPixels(
          psfFwhmPixels: fwhm.value,
          trailLengthPixels: trail,
        );

  final Radiometric snrResult;
  final Radiometric peak;
  if (footprint == null) {
    snrResult = RadiometricGap.single(psfFwhmMissing);
    peak = RadiometricGap.single(psfFwhmMissing);
  } else {
    snrResult = pointSourceSnr(
      starElectronsPerSecond: star,
      skyElectronsPerPixelPerSecond: sky,
      footprintPixels: footprint,
      exposureSeconds: exposureSeconds,
      sensor: sensor,
      darkCurrentElectronsPerSecond: calibration.darkCurrent,
    );
    peak = starPeakElectrons(
      starElectronsPerSecond: star,
      exposureSeconds: exposureSeconds,
      footprintPixels: footprint,
    );
  }

  return ExposureReport(
    targetName: targetName,
    altitudeDegrees: altitudeDegrees,
    airmass: airmassKastenYoung(altitudeDegrees),
    trailPixels: trail,
    arcsecondsPerPixel: scale,
    maxExposureSecondsNpf: npfMaxExposureSeconds(
      aperture: fNumber,
      pixelPitchMicrometers: pixelPitchMicrometers,
      focalLengthMm: focalLengthMm,
      declinationDegrees: declinationDegrees,
    ),
    extinctionMagnitudes: extinctionMagnitudes(
      altitudeDegrees: altitudeDegrees,
      extinctionCoefficient: calibration.extinctionCoefficient,
    ),
    starElectronsPerSecond: star,
    skyElectronsPerPixelPerSecond: sky,
    snr: snrResult,
    histogramFill: exposureLevels(
      skyElectronsPerPixelPerSecond: sky,
      exposureSeconds: exposureSeconds,
      sensor: sensor,
      darkCurrentElectronsPerSecond: calibration.darkCurrent,
    ),
    starClipped: starClipped(starPeak: peak, sensor: sensor),
    readNoiseSwampedAt: readNoiseSwampedExposure(
      skyElectronsPerPixelPerSecond: sky,
      sensor: sensor,
    ),
    missing: calibration.missing,
  );
}

/// Sifir noktasinin ilk ilkelerden **tahmini**.
///
/// QE, lens verimi ve aciklik alanindan hesaplanir. Olculmus ZP ile
/// karsilastirilmasi tam olarak **Faz 0.D'nin isidir**: ikisi uyusuyorsa
/// foton zinciri (kadir -> foton -> elektron) dogru kurulmus demektir.
///
/// Ayrisma varsa suclu adaylar: QE tahmini, lens verimi, bant
/// duzeltmesi veya kazanc olcumu. Yani bu karsilastirma bir dogrulama
/// degil, bir **teshis**.
Radiometric predictedZeroPoint({
  required double focalLengthMm,
  required double fNumber,
  required MeasuredSensorProfile sensor,
  Measured? lensTransmission,
  Measured? quantumEfficiency,
}) {
  final gaps = <MissingQuantity>[];
  if (lensTransmission == null) gaps.add(lensTransmissionMissing);
  if (quantumEfficiency == null) gaps.add(quantumEfficiencyMissing);
  if (gaps.isNotEmpty) return RadiometricGap(gaps);

  // V=0 yildiz atmosfer disinda kac ADU/s verir?
  final area = apertureAreaCm2(focalLengthMm: focalLengthMm, fNumber: fNumber);
  final electronsPerSecond =
      vBandZeroPointTotalPhotonFlux *
      area *
      lensTransmission!.value *
      quantumEfficiency!.value;
  final aduPerSecond = electronsPerSecond / sensor.gain.value;
  // m_alet = -2.5 log10(ADU/s);  ZP = V - m_alet = 0 + 2.5 log10(ADU/s)
  return RadiometricValue(2.5 * (math.log(aduPerSecond) / math.ln10), 'kadir');
}
