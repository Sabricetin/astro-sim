import 'dart:convert';

import 'package:astro_core/astro_core.dart';

import 'camera_settings.dart';
import 'horizon_panel.dart';
import 'site.dart';

/// Uygulamanin kaydedilen durumu.
///
/// **Neden gerekli:** ufuk profilini olcmek sahada 15 dakika suruyor,
/// kalibrasyon defteri bir gecelik cekimin urunu. Bunlarin uygulama
/// kapaninca kaybolmasi kabul edilemez.
///
/// **Neden tek JSON blogu:** ayri ayri anahtarlar yerine tek metin.
/// Boylece surum alani tek yerde duruyor ve kismi yazma sirasinda
/// tutarsiz bir durum olusamiyor.
///
/// **Zaman KAYDEDILMIYOR.** Uygulama acildiginda gecerli ana donuyor;
/// bir hafta onceki gokyuzunu gostermek yanilticidir.
class AppState {
  static const _key = 'astro_sim_state';
  static const _version = 1;

  final String siteName;
  final List<double> horizonAltitudes;
  final bool horizonEnabled;

  /// Kalibrasyon defterinin HAM METNI.
  ///
  /// Cozumlenmis nesne degil metin saklaniyor: boylece her acilista
  /// ayni dogrulamadan geciyor. Kaynaksiz bir defter diske yazilmis
  /// olsa bile okunurken reddedilir.
  final String? calibrationJson;

  final String cameraName;
  final double focalLengthMm;
  final double aperture;
  final double exposureSeconds;
  final bool portrait;
  final int iso;

  final bool showConstellations;
  final bool showLabels;
  final bool showMilkyWay;
  final bool showFrame;

  const AppState({
    required this.siteName,
    required this.horizonAltitudes,
    required this.horizonEnabled,
    required this.calibrationJson,
    required this.cameraName,
    required this.focalLengthMm,
    required this.aperture,
    required this.exposureSeconds,
    required this.portrait,
    required this.iso,
    required this.showConstellations,
    required this.showLabels,
    required this.showMilkyWay,
    required this.showFrame,
  });

  static const storageKey = _key;

  Map<String, dynamic> toJson() => {
    'version': _version,
    'site': siteName,
    'horizon': horizonAltitudes,
    'horizonEnabled': horizonEnabled,
    if (calibrationJson != null) 'calibration': calibrationJson,
    'camera': cameraName,
    'focal': focalLengthMm,
    'aperture': aperture,
    'exposure': exposureSeconds,
    'portrait': portrait,
    'iso': iso,
    'showConstellations': showConstellations,
    'showLabels': showLabels,
    'showMilkyWay': showMilkyWay,
    'showFrame': showFrame,
  };

  String encode() => jsonEncode(toJson());

  /// Kaydedilmis durumu okur.
  ///
  /// Bozuk, eksik veya bilinmeyen surumdeki her sey **sessizce
  /// varsayilana duser**. Sebep: kaydedilmis tercih, uygulamanin
  /// acilmasini engelleyecek kadar onemli degil. Kalibrasyon farkli —
  /// o metin olarak saklanip okunurken yeniden dogrulaniyor, yani
  /// bozuksa zaten reddedilir.
  static AppState? decode(String? text) {
    if (text == null || text.isEmpty) return null;
    try {
      final j = jsonDecode(text);
      if (j is! Map<String, dynamic>) return null;
      if (j['version'] is num && (j['version'] as num) > _version) return null;

      // Tip donusumleri GUVENLI olmali. `j['iso'] as num?` yazmak,
      // alan bir metinse istisna atar ve butun kaydi cope atardi —
      // tek bozuk alan yuzunden ufuk profilini de kaybederdik.
      // Amac "bozuk alan varsayilana duser", "bozuk alan her seyi
      // silmez".
      double num_(Object? v, double fallback) =>
          v is num ? v.toDouble() : fallback;
      bool bool_(Object? v, bool fallback) => v is bool ? v : fallback;
      int int_(Object? v, int fallback) => v is num ? v.toInt() : fallback;
      String? str_(Object? v) => v is String ? v : null;

      final rawHorizon = j['horizon'];
      final horizon = rawHorizon is List && rawHorizon.length == 8
          ? [for (final v in rawHorizon) num_(v, 0)]
          : List<double>.from(HorizonPanel.flat);

      return AppState(
        siteName: str_(j['site']) ?? sites.first.name,
        horizonAltitudes: horizon,
        horizonEnabled: bool_(j['horizonEnabled'], false),
        calibrationJson: str_(j['calibration']),
        cameraName: str_(j['camera']) ?? cameras.first.name,
        focalLengthMm: num_(j['focal'], 18),
        aperture: num_(j['aperture'], 3.5),
        exposureSeconds: num_(j['exposure'], 20),
        portrait: bool_(j['portrait'], false),
        iso: int_(j['iso'], 1600),
        showConstellations: bool_(j['showConstellations'], true),
        showLabels: bool_(j['showLabels'], true),
        showMilkyWay: bool_(j['showMilkyWay'], true),
        showFrame: bool_(j['showFrame'], true),
      );
    } catch (_) {
      return null;
    }
  }

  /// Adi listede bulunmayan konum/govde icin varsayilana duser.
  ///
  /// Liste degisebilir: bir govde kaldirilirsa eski kayit onu isaret
  /// eder ve `firstWhere` istisna atardi.
  Site get site =>
      sites.firstWhere((s) => s.name == siteName, orElse: () => sites.first);

  Camera get camera => cameras.firstWhere(
    (c) => c.name == cameraName,
    orElse: () => cameras.first,
  );

  CameraSettings get cameraSettings => CameraSettings(
    camera: camera,
    focalLengthMm: focalLengthMm,
    aperture: aperture,
    exposureSeconds: exposureSeconds,
    portrait: portrait,
    iso: iso,
  );

  /// Kaydedilmis kalibrasyon. Bozuksa veya kaynaksizsa null.
  LoadedCalibration? get calibration {
    final text = calibrationJson;
    if (text == null) return null;
    try {
      return parseCalibrationJson(text);
    } on CalibrationFormatException {
      return null;
    }
  }
}
