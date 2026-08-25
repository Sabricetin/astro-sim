import 'dart:typed_data';

import 'package:astro_core/astro_core.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Belirli bir an ve konum icin gokyuzunun onceden hesaplanmis hali.
///
/// **Neden onceden hesaplaniyor:** Katalogda 8404 yildiz var. Her karede
/// hepsi icin presesyon + koordinat donusumu yapmak (agir trigonometri)
/// gereksiz — bu degerler yalnizca ZAMAN veya KONUM degisince degisir.
/// Kullanici bakisi surukledginde gokyuzu donmez, sadece hangi parcasina
/// baktigi degisir. O yuzden burada alt/az sabitlenir, her karede yalnizca
/// projeksiyon calisir.
/// Samanyolu seridini cizmek icin hazirlanmis egriler.
///
/// Galaktik enlem b = 0, +-10 ve +-20 derece cizgileri. Panorama
/// GORUNTUSU degil, saf geometri — lisans sorunu yok ve kalibrasyon
/// beklemiyor. Serit nerede geciyor sorusunu cevaplamak icin bu
/// yeterli; parlaklik dokusu Faz 6'nin geri kalani.
///
/// Presesyon uygulaniyor: galaktik tanim J2000, gokyuzu ise tarihin
/// gercek ekinoksunda ciziliyor. Yildizlarla ayni islemden gecmezse
/// serit yildizlara gore kayar.
class MilkyWayBands {
  /// Her serit icin alt/az cifti dizisi. Uzunluk = 2 * nokta sayisi.
  final List<Float32List> bands;

  /// Her seridin galaktik enlemi, derece.
  static const latitudes = <double>[0.0, 10.0, -10.0, 20.0, -20.0];

  const MilkyWayBands(this.bands);

  /// Verilen an ve gozlemci icin seritleri hesaplar.
  factory MilkyWayBands.compute({
    required DateTime utc,
    required Observer observer,
    double stepDegrees = 3.0,
  }) {
    final jd = julianDay(utc);
    final lst = localMeanSiderealTimeDegrees(jd, observer.longitudeEastDegrees);
    final out = <Float32List>[];
    for (final b in latitudes) {
      final n = (360 / stepDegrees).ceil();
      final buf = Float32List(n * 2);
      for (var i = 0; i < n; i++) {
        final eq = galacticToEquatorial(
          Galactic(longitudeDegrees: i * stepDegrees, latitudeDegrees: b),
        );
        final precessed = precessFromJ2000(j2000Position: eq, toJd: jd);
        final h = equatorialToHorizontal(
          equatorial: precessed,
          observer: observer,
          localSiderealTimeDegrees: lst,
        );
        buf[i * 2] = h.azimuthDegrees;
        buf[i * 2 + 1] = h.altitudeDegrees;
      }
      out.add(buf);
    }
    return MilkyWayBands(out);
  }
}

class SkyModel {
  final StarCatalog catalog;

  /// Yildiz basina iki deger: azimut, yukseklik (derece).
  /// Katalogla ayni sirada.
  final Float32List horizontal;

  /// Presesyonla tarihe tasinmis RA/Dec, yildiz basina iki deger.
  ///
  /// Presesyon bir gecede ~0.0001 derece degisir — yani pratikte sabit.
  /// Ayri tutuluyor ki zaman kaydiricisi oynatildiginda 8404 yildiz icin
  /// presesyon YENIDEN HESAPLANMASIN; sadece alt/az guncellensin.
  final Float32List precessedEquatorial;

  /// Cizim kovasi indeksi (boyut sinifi + renk sinifi birlesik).
  ///
  /// Kovalar onceden siralanmis oldugu icin cizim kodu tek bir gecisle
  /// ayni boyut/renkteki yildizlari toplu cizebilir.
  final Uint8List bucket;

  /// [bucket] degerine gore siralanmis yildiz indeksleri.
  final Int32List orderByBucket;

  /// Her kovanin [orderByBucket] icindeki baslangic ofseti; son eleman
  /// toplam sayidir.
  final Int32List bucketStart;

  /// HR numarasindan katalog indeksine. Takim yildizi cizgileri ve
  /// etiketler bunu kullanir; her cizimde arama yapmamak icin bir kez
  /// kuruluyor.
  final Map<int, int> indexByHr;

  final DateTime utc;
  final Observer observer;

  const SkyModel._({
    required this.catalog,
    required this.horizontal,
    required this.precessedEquatorial,
    required this.bucket,
    required this.orderByBucket,
    required this.bucketStart,
    required this.indexByHr,
    required this.utc,
    required this.observer,
  });

  int get starCount => catalog.length;

  double azimuthDegrees(int index) => horizontal[index * 2];
  double altitudeDegrees(int index) => horizontal[index * 2 + 1];

  /// Kadir siniflari — buyukten kucuge nokta boyutu.
  ///
  /// Sinirlar gozle secildi: amac 1. kadir ile 6. kadir arasinda gozle
  /// ayirt edilebilir bir kademe olmasi. Kadir logaritmik oldugu icin
  /// esit araliklar dogru gorunmez.
  static const List<double> magnitudeBreaks = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0];
  static int get sizeClassCount => magnitudeBreaks.length + 1;

  /// Renk sicakligi siniflari, Kelvin. Sicaktan soguga.
  static const List<double> temperatureBreaks = [
    9000,
    7200,
    6000,
    5200,
    4200,
    3400,
  ];
  static int get colorClassCount => temperatureBreaks.length + 1;

  static int get bucketCount => sizeClassCount * colorClassCount;

  static int _sizeClass(double magnitude) {
    for (var i = 0; i < magnitudeBreaks.length; i++) {
      if (magnitude < magnitudeBreaks[i]) return i;
    }
    return magnitudeBreaks.length;
  }

  static int _colorClass(double bv) {
    final t = colorTemperatureFromBV(bv);
    // B-V bilinmiyorsa NaN gelir; ortadaki (gunes benzeri) sinifa koy.
    // Beyaza dusmek de olurdu ama o zaman 244 yildiz digerlerinden
    // belirgin sekilde ayrisirdi.
    if (t.isNaN) return temperatureBreaks.length ~/ 2;
    for (var i = 0; i < temperatureBreaks.length; i++) {
      if (t > temperatureBreaks[i]) return i;
    }
    return temperatureBreaks.length;
  }

  /// Katalogu asset'ten okur. Uygulama acilisinda bir kez cagrilir.
  static Future<StarCatalog> loadCatalog() async {
    final data = await rootBundle.load(
      'packages/astro_core/assets/stars_bsc5.bin',
    );
    return StarCatalog.fromBytes(data.buffer.asUint8List());
  }

  /// Verilen an ve konum icin gokyuzunu hesaplar.
  ///
  /// Zincir: J2000 katalog konumu -> presesyon -> Alt/Az. Kirilma
  /// uygulanmaz; bu goruntu icin ihmal edilebilir (24 derecede 2.25 yay
  /// dakikasi) ve Faz 7'de ufuk profiliyle birlikte gelecek.
  factory SkyModel.compute({
    required StarCatalog catalog,
    required DateTime utc,
    required Observer observer,
  }) {
    final n = catalog.length;
    final horizontal = Float32List(n * 2);
    final precessed = Float32List(n * 2);
    final bucket = Uint8List(n);

    final jd = julianDay(utc);
    final lst = localMeanSiderealTimeDegrees(jd, observer.longitudeEastDegrees);

    for (var i = 0; i < n; i++) {
      final ofDate = precessFromJ2000(
        j2000Position: Equatorial(
          rightAscensionDegrees: catalog.rightAscensionDegrees(i),
          declinationDegrees: catalog.declinationDegrees(i),
        ),
        toJd: jd,
      );
      precessed[i * 2] = ofDate.rightAscensionDegrees;
      precessed[i * 2 + 1] = ofDate.declinationDegrees;

      final h = equatorialToHorizontal(
        equatorial: ofDate,
        observer: observer,
        localSiderealTimeDegrees: lst,
      );
      horizontal[i * 2] = h.azimuthDegrees;
      horizontal[i * 2 + 1] = h.altitudeDegrees;

      bucket[i] =
          _sizeClass(catalog.magnitude(i)) * colorClassCount +
          _colorClass(catalog.colorIndexBV(i));
    }

    // Kova sayimi -> ofsetler -> siralama (sayarak siralama).
    final counts = Int32List(bucketCount + 1);
    for (var i = 0; i < n; i++) {
      counts[bucket[i] + 1]++;
    }
    for (var b = 0; b < bucketCount; b++) {
      counts[b + 1] += counts[b];
    }
    final bucketStart = Int32List.fromList(counts);
    final order = Int32List(n);
    final cursor = Int32List.fromList(counts);
    for (var i = 0; i < n; i++) {
      order[cursor[bucket[i]]++] = i;
    }

    return SkyModel._(
      catalog: catalog,
      horizontal: horizontal,
      precessedEquatorial: precessed,
      bucket: bucket,
      orderByBucket: order,
      bucketStart: bucketStart,
      indexByHr: {for (var i = 0; i < n; i++) catalog.hrNumbers[i]: i},
      utc: utc,
      observer: observer,
    );
  }

  /// Ayni gece icinde zamani ilerletir.
  ///
  /// Presesyon, kova siniflari ve HR indeksi yeniden hesaplanmaz —
  /// hicbiri bir gece icinde anlamli sekilde degismez. Sadece alt/az
  /// guncellenir, yani zaman kaydiricisi akici kalir.
  ///
  /// Farkli bir GUNE gecerken [SkyModel.compute] kullanilmali; presesyon
  /// orada yeniden yapilir.
  SkyModel atTime(DateTime newUtc) {
    final n = catalog.length;
    final updated = Float32List(n * 2);
    final lst = localMeanSiderealTimeDegrees(
      julianDay(newUtc),
      observer.longitudeEastDegrees,
    );

    for (var i = 0; i < n; i++) {
      final h = equatorialToHorizontal(
        equatorial: Equatorial(
          rightAscensionDegrees: precessedEquatorial[i * 2],
          declinationDegrees: precessedEquatorial[i * 2 + 1],
        ),
        observer: observer,
        localSiderealTimeDegrees: lst,
      );
      updated[i * 2] = h.azimuthDegrees;
      updated[i * 2 + 1] = h.altitudeDegrees;
    }

    return SkyModel._(
      catalog: catalog,
      horizontal: updated,
      precessedEquatorial: precessedEquatorial,
      bucket: bucket,
      orderByBucket: orderByBucket,
      bucketStart: bucketStart,
      indexByHr: indexByHr,
      utc: newUtc,
      observer: observer,
    );
  }
}
