import 'package:astro_core/astro_core.dart';

/// Kullanicinin sectigi ekipman ve cekim ayarlari.
///
/// Faz 3'un ciktisi: "bu lensle bu kadraj cikar mi" ve "bu pozda yildiz
/// iz birakir mi" sorularinin cevabi.
/// Olculmus ISO degerleri.
///
/// Faz 0.A yalniz bu ucunu olctu. Listeye ISO 400 eklemek, kazanci
/// bilinmeyen bir ayari secilebilir yapmak demek olurdu.
const measuredIsoValues = <int>[800, 1600, 3200];

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

  /// Secili ISO.
  ///
  /// Radyometri raporu icin gerekli: kazanc ve okuma gurultusu ISO'ya
  /// gore degisir ve yalnizca OLCULMUS ISO'lar kullanilabilir. Olculmemis
  /// bir ISO secilirse rapor sayi uretmeyi reddeder — ara degeri
  /// interpolasyonla uydurmak tam da yasakladigimiz sey.
  final int iso;

  const CameraSettings({
    required this.camera,
    this.focalLengthMm = 14,
    this.aperture = 2.8,
    this.exposureSeconds = 20,
    this.portrait = false,
    this.targetDeclinationDegrees = 0,
    this.iso = 1600,
  });

  CameraSettings copyWith({
    Camera? camera,
    double? focalLengthMm,
    double? aperture,
    double? exposureSeconds,
    bool? portrait,
    double? targetDeclinationDegrees,
    int? iso,
  }) => CameraSettings(
    camera: camera ?? this.camera,
    focalLengthMm: focalLengthMm ?? this.focalLengthMm,
    aperture: aperture ?? this.aperture,
    exposureSeconds: exposureSeconds ?? this.exposureSeconds,
    portrait: portrait ?? this.portrait,
    targetDeclinationDegrees:
        targetDeclinationDegrees ?? this.targetDeclinationDegrees,
    iso: iso ?? this.iso,
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
  /// Diyafram degerleri.
  ///
  /// Kisik degerler (f/11-f/22) sadece bir tercih degil: Faz 0.B'nin
  /// sonum dizisinde parlak yildizin doymasini engellemek icin
  /// gerekiyorlar. Vega, 18 mm f/3.5'te dolum kapasitesini kat kat
  /// asiyor; f/22'de 1 saniyeye kadar temiz kaliyor.
  static const apertures = [
    1.4,
    1.8,
    2.0,
    2.8,
    3.5,
    4.0,
    5.6,
    8.0,
    11.0,
    16.0,
    22.0,
  ];

  /// Yaygin odak uzunluklari, mm.
  ///
  /// 18 ve 55 kit lensin (EF-S 18-55) uclari — en yaygin baslangic
  /// ekipmani ve projenin referans gövdesinde kullanilan lens.
  static const focalLengths = [
    8.0,
    14.0,
    18.0,
    20.0,
    24.0,
    35.0,
    50.0,
    55.0,
    85.0,
    135.0,
    200.0,
    400.0,
  ];
}
