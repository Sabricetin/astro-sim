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
class SkyModel {
  final StarCatalog catalog;

  /// Yildiz basina iki deger: azimut, yukseklik (derece).
  /// Katalogla ayni sirada.
  final Float32List horizontal;

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

  final DateTime utc;
  final Observer observer;

  const SkyModel._({
    required this.catalog,
    required this.horizontal,
    required this.bucket,
    required this.orderByBucket,
    required this.bucketStart,
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
      bucket: bucket,
      orderByBucket: order,
      bucketStart: bucketStart,
      utc: utc,
      observer: observer,
    );
  }
}
