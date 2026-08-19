/// T2.8 — Takim yildizi cizgileri ve parlak yildiz adlari.
///
/// **Neden opsiyonel degil:** Yol haritasinda bu gorev "opsiyonel ama
/// motivasyon icin degerli" diye isaretlenmisti. Pratikte Faz 2'nin cikis
/// kriterini (Orion'u ve Buyuk Ayi'yi taniyabiliyor musun) dogrulamayi
/// mumkun kilan sey bu: 8404 nokta, cizgi olmadan hicbir seye benzemiyor.
///
/// **Lisans:** Cizgiler burada elle yazildi. Stellarium'un cizgi verisi
/// GPL, HYG projesininki CC BY-SA — ikisi de ticari plana uymuyor.
/// Yildiz kimlikleri (hangi HR numarasi hangi yildiz) olgusal bilgidir;
/// bunlari hangi sirayla birlestirecegimiz bizim secimimiz.
///
/// Figurler geleneksel cizimlerin sade halleridir: amac estetik degil,
/// taninabilirlik.
library;

/// Bir takim yildizinin cizgi figuru.
class Constellation {
  /// Turkce ad.
  final String name;

  /// Uluslararasi uc harfli kisaltma (IAU).
  final String abbreviation;

  /// Cizgi parcalari: her ikili bir HR numarasi cifti.
  ///
  /// Duz liste olarak tutuluyor — cizim kodu ikiser ikiser ilerler.
  /// Ayri bir nesne listesi olusturmak, her karede gereksiz dolayli
  /// erisim demek olurdu.
  final List<int> segments;

  const Constellation({
    required this.name,
    required this.abbreviation,
    required this.segments,
  });

  /// Cizgi parcasi sayisi.
  int get segmentCount => segments.length ~/ 2;
}

/// Ilk sette taninabilirligi en yuksek sekiz takim yildizi var.
///
/// Secim olcutu: gozle hemen ayirt edilen, belirgin geometrisi olan
/// figurler. Butun gokyuzunu kaplamak amac degil — amac kullanicinin
/// "evet, bu gercekten gokyuzu" diyebilmesi.
const List<Constellation> constellations = [
  Constellation(
    name: 'Orion',
    abbreviation: 'Ori',
    segments: [
      // Omuzlar: Betelgeuse - Bellatrix
      2061, 1790,
      // Bas: her iki omuzdan Lambda'ya
      2061, 1879,
      1879, 1790,
      // Omuzlardan kusaga
      2061, 1948, // Betelgeuse -> Alnitak
      1790, 1852, // Bellatrix  -> Mintaka
      // Kusak: Mintaka - Alnilam - Alnitak
      1852, 1903,
      1903, 1948,
      // Kusaktan ayaklara
      1852, 1713, // Mintaka -> Rigel
      1948, 2004, // Alnitak -> Saiph
    ],
  ),
  Constellation(
    name: 'Buyuk Ayi',
    abbreviation: 'UMa',
    segments: [
      // Kepce govdesi
      4301, 4295, // Dubhe  - Merak
      4295, 4554, // Merak  - Phecda
      4554, 4660, // Phecda - Megrez
      4660, 4301, // Megrez - Dubhe
      // Sap
      4660, 4905, // Megrez - Alioth
      4905, 5054, // Alioth - Mizar
      5054, 5191, // Mizar  - Alkaid
    ],
  ),
  Constellation(
    name: 'Kasiyopeya',
    abbreviation: 'Cas',
    segments: [
      // Belirgin W harfi
      21, 168,
      168, 264,
      264, 403,
      403, 542,
    ],
  ),
  Constellation(
    name: 'Kugu',
    abbreviation: 'Cyg',
    segments: [
      // Kuzey Hac'in uzun ekseni: Deneb - Sadr - Albireo
      7924, 7796,
      7796, 7417,
      // Kanatlar
      7528, 7796,
      7796, 7949,
    ],
  ),
  Constellation(
    name: 'Akrep',
    abbreviation: 'Sco',
    segments: [
      // Kiskaclar
      5944, 5953,
      5953, 5984,
      // Govde: Antares'ten kuyruga
      5953, 6084,
      6084, 6134, // Antares
      6134, 6165,
      6165, 6241,
      6241, 6247,
      6247, 6271,
      6271, 6380,
      6380, 6553,
      6553, 6615,
      6615, 6580,
      6580, 6527, // Shaula, ignenin ucu
    ],
  ),
  Constellation(
    name: 'Aslan',
    abbreviation: 'Leo',
    segments: [
      // Orak (bas ve yele)
      3873, 3905,
      3905, 4031,
      4031, 4057,
      4057, 3975,
      3975, 3982, // Regulus
      // Govde
      3982, 4359,
      4359, 4534, // Denebola
      4359, 4357,
      4357, 4057,
      4357, 4534,
    ],
  ),
  Constellation(
    name: 'Boga',
    abbreviation: 'Tau',
    segments: [
      // Yuz (Hyades) ve kuzey boynuz
      1346, 1373,
      1373, 1409,
      1409, 1791, // Elnath
      // Aldebaran ve guney boynuz
      1346, 1457, // Aldebaran
      1457, 1910,
    ],
  ),
  Constellation(
    name: 'Lir',
    abbreviation: 'Lyr',
    segments: [
      7001, 7178, // Vega
      7178, 7106,
      7106, 7001,
    ],
  ),
];

/// Parlak yildizlarin ozel adlari, HR numarasina gore.
///
/// Ekranda etiket gostermek icin. Yildiz adlari olgusal bilgidir; bu liste
/// katalogdaki en parlak ve en cok bilinen yildizlarla sinirli tutuldu —
/// hepsini etiketlemek gokyuzunu okunmaz hale getirir.
const Map<int, String> brightStarNames = {
  2491: 'Sirius',
  2326: 'Canopus',
  5340: 'Arcturus',
  7001: 'Vega',
  1708: 'Capella',
  1713: 'Rigel',
  2943: 'Procyon',
  2061: 'Betelgeuse',
  472: 'Achernar',
  5459: 'Rigil Kentaurus',
  7557: 'Altair',
  1457: 'Aldebaran',
  6134: 'Antares',
  7924: 'Deneb',
  3982: 'Regulus',
  1790: 'Bellatrix',
  1852: 'Mintaka',
  1903: 'Alnilam',
  1948: 'Alnitak',
  2004: 'Saiph',
  4301: 'Dubhe',
  4295: 'Merak',
  4905: 'Alioth',
  5054: 'Mizar',
  5191: 'Alkaid',
  168: 'Schedar',
  264: 'Tsih',
  4534: 'Denebola',
  6527: 'Shaula',
  1791: 'Elnath',
  7796: 'Sadr',
  7417: 'Albireo',
  5056: 'Spica',
  4554: 'Phecda',
  4660: 'Megrez',
};
