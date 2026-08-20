/// T5.7 — Olculmus sensor verisi.
///
/// Bu dosyadaki sayilar **olculdu**, tahmin edilmedi. Kaynak: Faz 0.A,
/// foton transfer egrisi, `tools/sensor_ptc.py`. Ham sonuclar
/// `data/faz0/iso*.json` icinde.
///
/// Baska govde eklenecekse ayni kural gecerli: ya olculmus ya da
/// yayinlanmis olcum kaynagindan (photonstophotos gibi) alinmis olacak.
/// Kestirilmis kazanc bu dosyaya girmez.
library;

import 'calibration.dart';

/// Bir govdenin belirli bir ISO'daki olculmus davranisi.
class MeasuredSensorProfile {
  final String cameraName;
  final int iso;

  /// Kazanc, elektron / ADU.
  final Measured gain;

  /// Okuma gurultusu, elektron.
  final Measured readNoise;

  /// Dolum kapasitesi, elektron.
  final Measured fullWell;

  /// Bias seviyesi, ADU. Ham kareden cikarilacak sabit.
  final Measured biasOffset;

  /// ADU'nun tavani. 760D 14 bit.
  final int bitDepth;

  const MeasuredSensorProfile({
    required this.cameraName,
    required this.iso,
    required this.gain,
    required this.readNoise,
    required this.fullWell,
    required this.biasOffset,
    required this.bitDepth,
  });

  /// Doyum ADU degeri.
  int get saturationAdu => (1 << bitDepth) - 1;
}

/// Faz 0.A'da olculen kazancin bagil belirsizligi.
///
/// photonstophotos referansina gore sistematik olarak ~%17 yuksek
/// cikti. Sitenin uc degeri dolum kapasitesini %0.10 sabit tutuyor,
/// yani tek bir capadan turetilmis — etkin olarak tek karsilastirma
/// noktasi. Karar ve gerekce: `data/faz0/referans-karsilastirma.md`.
const _gainUncertainty = 0.17;

const _source = 'Faz 0.A PTC, tools/sensor_ptc.py, data/faz0/iso%d.json';

String _src(int iso) => _source.replaceFirst('%d', '$iso');

/// Canon EOS 760D, ISO 800.
final canon760dIso800 = MeasuredSensorProfile(
  cameraName: 'Canon EOS 760D',
  iso: 800,
  gain: Measured(
    value: 0.24729932056565473,
    unit: 'e-/ADU',
    source: _src(800),
    relativeUncertainty: _gainUncertainty,
  ),
  // PTC kesisiminden gelen okuma gurultusu negatif ciktigi icin
  // sifira kirpilmisti; bias karelerinden olculen deger kullaniliyor.
  readNoise: Measured(
    value: 2.5739314050116433,
    unit: 'e-',
    source: '${_src(800)} (bias karelerinden)',
  ),
  fullWell: Measured(value: 3291.80, unit: 'e-', source: _src(800)),
  biasOffset: Measured(value: 2048.81, unit: 'ADU', source: _src(800)),
  bitDepth: 14,
);

/// Canon EOS 760D, ISO 1600.
final canon760dIso1600 = MeasuredSensorProfile(
  cameraName: 'Canon EOS 760D',
  iso: 1600,
  gain: Measured(
    value: 0.1264630560138104,
    unit: 'e-/ADU',
    source: _src(1600),
    relativeUncertainty: _gainUncertainty,
  ),
  readNoise: Measured(
    value: 2.037325757374842,
    unit: 'e-',
    source: '${_src(1600)} (bias karelerinden)',
  ),
  fullWell: Measured(value: 1683.35, unit: 'e-', source: _src(1600)),
  biasOffset: Measured(value: 2049.17, unit: 'ADU', source: _src(1600)),
  bitDepth: 14,
);

/// Canon EOS 760D, ISO 3200.
final canon760dIso3200 = MeasuredSensorProfile(
  cameraName: 'Canon EOS 760D',
  iso: 3200,
  gain: Measured(
    value: 0.06545396543855651,
    unit: 'e-/ADU',
    source: _src(3200),
    relativeUncertainty: _gainUncertainty,
  ),
  readNoise: Measured(
    value: 1.6948744504684619,
    unit: 'e-',
    source: '${_src(3200)} (bias karelerinden)',
  ),
  fullWell: Measured(value: 871.23, unit: 'e-', source: _src(3200)),
  biasOffset: Measured(value: 2048.22, unit: 'ADU', source: _src(3200)),
  bitDepth: 14,
);

/// Olculmus butun profiller.
///
/// **Bu listede olmayan ISO kullanilamaz.** Faz 0.A yalniz bu ucunu
/// olctu; ISO 400'de cekilmis bir kare icin kazanc bilinmiyor ve
/// aradaki degeri interpolasyonla uydurmak tam da yasakladigimiz sey.
final measuredSensorProfiles = <MeasuredSensorProfile>[
  canon760dIso800,
  canon760dIso1600,
  canon760dIso3200,
];

/// Govde ve ISO icin olculmus profil. Yoksa null — cagiran taraf
/// hesabi reddetmeli.
MeasuredSensorProfile? measuredProfileFor({
  required String cameraName,
  required int iso,
}) {
  for (final p in measuredSensorProfiles) {
    if (p.cameraName == cameraName && p.iso == iso) return p;
  }
  return null;
}
