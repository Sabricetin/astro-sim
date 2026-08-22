/// T5 — Kalibrasyon defterinin dosya bicimi.
///
/// `tools/analyze_field_night.py` bu bicimi uretiyor, uygulama okuyor.
/// Iki taraf ayni bicimden gectigi icin sahadan donen olcum dogrudan
/// arayuze giriyor; arada elle kopyalama yok.
///
/// **Kaynaksiz deger kabul edilmiyor.** Dosyada `source` alani yoksa
/// veya bos ise okuma reddediliyor. Sebep projenin baslangicindaki
/// kural: her sabitin yaninda birimi ve kaynagi olacak. Bir sayinin
/// nereden geldigi kaybolursa, olculmus mu uydurma mi oldugu bir hafta
/// sonra ayirt edilemez.
library;

import 'dart:convert';

import 'calibration.dart';
import 'exposure_report.dart';

/// Kalibrasyon dosyasi okunamadiginda atilir.
class CalibrationFormatException implements Exception {
  final String message;
  const CalibrationFormatException(this.message);
  @override
  String toString() => message;
}

/// Dosyadan okunmus kalibrasyon + kimin urettigi.
class LoadedCalibration {
  final CalibrationSet calibration;
  final String source;
  final String? measuredAt;
  final int? iso;
  final double? focalLengthMm;
  final double? pixelPitchMicrometers;
  final int? identifiedStarHr;

  /// Dosyada bulunan ama bu surumun tanimadigi alanlar. Sessizce
  /// yutmak yerine gosteriliyor — ileri surumden gelen bir dosya
  /// oldugunu anlamanin tek yolu.
  final List<String> unknownFields;

  const LoadedCalibration({
    required this.calibration,
    required this.source,
    this.measuredAt,
    this.iso,
    this.focalLengthMm,
    this.pixelPitchMicrometers,
    this.identifiedStarHr,
    this.unknownFields = const [],
  });
}

const _knownFields = {
  'format',
  'version',
  'source',
  'measured_at',
  'extinction_coefficient_k',
  'extinction_k_uncertainty',
  'zero_point_f_number',
  'identified_star_hr',
  'psf_fwhm_px',
  'dark_current_e_per_px_per_s',
  'sky_instrumental_e_per_px_per_s',
  'photometric_zero_point',
  'sky_mag_per_sq_arcsec',
  'band_correction_per_color_index',
  'iso',
  'gain_used',
  'focal_length_mm',
  'pixel_pitch_um',
  'site',
};

double? _num(Object? v) => v is num ? v.toDouble() : null;

/// Kalibrasyon defterini JSON metninden okur.
///
/// Eksik alanlar sorun degil — o buyukluk olculmemis demektir ve
/// zincir onu zaten eksik olarak bildirir. Sorun olan tek sey
/// **kaynaksiz** dosya.
LoadedCalibration parseCalibrationJson(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException catch (e) {
    throw CalibrationFormatException('JSON okunamadi: ${e.message}');
  }
  if (decoded is! Map<String, dynamic>) {
    throw const CalibrationFormatException(
      'Beklenen bicim bir JSON nesnesi. Dosyanin tamamini yapistirdigindan '
      'emin ol.',
    );
  }
  final j = decoded;

  final format = j['format'];
  if (format != null && format != 'astro-sim-kalibrasyon') {
    throw CalibrationFormatException(
      'Bu bir astro-sim kalibrasyon dosyasi degil (format: $format).',
    );
  }
  final version = j['version'];
  if (version is num && version > 1) {
    throw CalibrationFormatException(
      'Dosya surumu $version, bu uygulama 1 biliyor. Uygulamayi guncelle.',
    );
  }

  final source = (j['source'] as String?)?.trim() ?? '';
  if (source.isEmpty) {
    throw const CalibrationFormatException(
      'Dosyada "source" alani yok. Kaynagi bilinmeyen olcum kabul '
      'edilmiyor: bir sayinin nereden geldigi kaybolursa, olculmus mu '
      'uydurma mi oldugu sonradan ayirt edilemez.',
    );
  }

  Measured? m(String key, String unit, {double? uncertainty}) {
    final v = _num(j[key]);
    return v == null
        ? null
        : Measured(
            value: v,
            unit: unit,
            source: source,
            relativeUncertainty: uncertainty,
          );
  }

  final k = _num(j['extinction_coefficient_k']);
  final kErr = _num(j['extinction_k_uncertainty']);

  return LoadedCalibration(
    calibration: CalibrationSet(
      extinctionCoefficient: k == null
          ? null
          : Measured(
              value: k,
              unit: 'kadir/X',
              source: source,
              relativeUncertainty: (kErr != null && k != 0)
                  ? (kErr / k).abs()
                  : null,
            ),
      zeroPoint: m('photometric_zero_point', 'kadir'),
      zeroPointFNumber: _num(j['zero_point_f_number']),
      bandCorrectionPerColorIndex: m(
        'band_correction_per_color_index',
        'kadir',
      ),
      darkCurrent: m('dark_current_e_per_px_per_s', 'e-/px/s'),
      skyMagPerSquareArcsec: m('sky_mag_per_sq_arcsec', 'kadir/arcsec^2'),
      psfFwhmPixels: m('psf_fwhm_px', 'px'),
    ),
    source: source,
    measuredAt: j['measured_at'] as String?,
    iso: (j['iso'] as num?)?.toInt(),
    focalLengthMm: _num(j['focal_length_mm']),
    pixelPitchMicrometers: _num(j['pixel_pitch_um']),
    identifiedStarHr: (j['identified_star_hr'] as num?)?.toInt(),
    unknownFields: j.keys.where((k) => !_knownFields.contains(k)).toList()
      ..sort(),
  );
}
