import 'dart:math' as math;
import 'dart:ui' show Color;

import 'sky_model.dart';

/// Yildizlarin ekrandaki gorunumu: nokta boyutu ve rengi.
///
/// Bu dosya **sunum** karari verir. Fizik (B-V -> Kelvin) astro_core'da;
/// buradaki secimler gozle ayarlanmis, kalibre degil. Yol haritasi Faz 5'te
/// bunun yerini fiziksel PSF ve gercek parlaklik hesabi alacak — o zamana
/// kadar amac taninabilirlik.
class StarStyle {
  /// Kadir sinifindan nokta yaricapi, piksel.
  ///
  /// Kadir logaritmik bir olcek: 1. kadir ile 6. kadir arasinda 100 kat
  /// parlaklik farki var. Yaricapi dogrusal esleseydik parlak yildizlar
  /// kaybolurdu; bu yuzden kademeler ustte genis, altta dar.
  static const List<double> _radiusBySizeClass = [
    3.4, // kadir < 0   (Sirius, Canopus, Vega...)
    2.6, // < 1
    2.0, // < 2
    1.5, // < 3
    1.1, // < 4
    0.85, // < 5
    0.65, // geri kalan, 6.5'e kadar
  ];

  /// Renk sinifindan renk.
  ///
  /// Siyah cisim renklerinin gozle ayarlanmis hali. Doygunluk bilerek
  /// dusuk tutuldu: gercek gokyuzunde yildizlar neredeyse beyaz gorunur,
  /// renk ancak uzun pozda ortaya cikar. Asiri doygun renkler "oyuncak"
  /// gosterir.
  static const List<Color> _colorByClass = [
    Color(0xFFB6CCFF), // > 9000 K — mavi-beyaz (O, B)
    Color(0xFFD7E4FF), // > 7200 K — beyaz-mavi (A)
    Color(0xFFF4F4FF), // > 6000 K — beyaz (F)
    Color(0xFFFFF6E8), // > 5200 K — sari-beyaz (G, Gunes)
    Color(0xFFFFE9C4), // > 4200 K — sari (K)
    Color(0xFFFFD2A1), // > 3400 K — turuncu
    Color(0xFFFFB380), // geri kalan — kirmizi (M, C)
  ];

  static double radiusForBucket(int bucket) =>
      _radiusBySizeClass[bucket ~/ SkyModel.colorClassCount];

  static Color colorForBucket(int bucket) =>
      _colorByClass[bucket % SkyModel.colorClassCount];

  /// Genis acida noktalar seyrelir, dar acida yigilir. Yaricapi gorus
  /// alanina gore olceklemek, farkli zoom seviyelerinde benzer bir
  /// yogunluk hissi verir.
  ///
  /// Tamamen gorsel bir duzeltme — fiziksel bir karsiligi yok.
  static double zoomScale(double horizontalFovDegrees) =>
      math.max(0.55, math.min(1.9, 55.0 / horizontalFovDegrees));
}
