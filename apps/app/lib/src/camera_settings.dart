import 'package:astro_core/astro_core.dart';

/// Kullanicinin sectigi ekipman ve cekim ayarlari.
///
/// Faz 3'un ciktisi: "bu lensle bu kadraj cikar mi" ve "bu pozda yildiz
/// iz birakir mi" sorularinin cevabi.
class CameraSettings {
  final Camera camera;
  final double focalLengthMm;
  final double aperture;
  final double exposureSeconds;

  /// Govde dik mi tutuluyor?
  final bool portrait;

  /// Hedefin sapmasi — NPF duzeltmesi icin. Ekranin ortasindaki noktanin
  /// sapmasi kullanilir.
  final double targetDeclinationDegrees;

  const CameraSettings({
    required this.camera,
    this.focalLengthMm = 14,
    this.aperture = 2.8,
    this.exposureSeconds = 20,
    this.portrait = false,
    this.targetDeclinationDegrees = 0,
  });

  CameraSettings copyWith({
    Camera? camera,
    double? focalLengthMm,
    double? aperture,
    double? exposureSeconds,
    bool? portrait,
    double? targetDeclinationDegrees,
  }) => CameraSettings(
    camera: camera ?? this.camera,
    focalLengthMm: focalLengthMm ?? this.focalLengthMm,
    aperture: aperture ?? this.aperture,
    exposureSeconds: exposureSeconds ?? this.exposureSeconds,
    portrait: portrait ?? this.portrait,
    targetDeclinationDegrees:
        targetDeclinationDegrees ?? this.targetDeclinationDegrees,
  );

  FieldOfView get fieldOfView => FieldOfView.of(
    format: camera.format,
    focalLengthMm: focalLengthMm,
    portrait: portrait,
  );

  /// NPF siniri, hedefin sapmasi hesaba katilarak.
  double get maxExposureSeconds => npfMaxExposureSeconds(
    aperture: aperture,
    pixelPitchMicrometers: camera.pixelPitchMicrometers,
    focalLengthMm: focalLengthMm,
    declinationDegrees: targetDeclinationDegrees,
  );

  /// Secilen pozda beklenen iz uzunlugu, piksel.
  double get trailPixels => starTrailPixels(
    exposureSeconds: exposureSeconds,
    pixelPitchMicrometers: camera.pixelPitchMicrometers,
    focalLengthMm: focalLengthMm,
    declinationDegrees: targetDeclinationDegrees,
  );

  /// Poz NPF sinirini asiyor mu?
  bool get exceedsLimit => exposureSeconds > maxExposureSeconds;

  /// Karsilastirma icin eski 500 kurali.
  double get fiveHundredRule => fiveHundredRuleSeconds(focalLengthMm);

  /// Yaygin diyafram degerleri (tam duraklar ve astro icin sik kullanilanlar).
  static const apertures = [1.4, 1.8, 2.0, 2.8, 4.0, 5.6, 8.0];

  /// Yaygin odak uzunluklari, mm.
  static const focalLengths = [
    8.0,
    14.0,
    20.0,
    24.0,
    35.0,
    50.0,
    85.0,
    135.0,
    200.0,
    400.0,
  ];
}
