/// Koordinat tipleri.
///
/// Bu tipler ciplak `double` yerine kullanilir cunku donusum fonksiyonlari
/// dort-bes aci alir ve sirasi karisirsa kod calisir ama gokyuzu yanlis yere
/// duser. Tip sistemi bunu derleme zamaninda yakalar.
///
/// Tum acilar **derece**. Butun degerler yapicida dogrulanir: sinir disi bir
/// sapma veya enlem, sessiz yanlis sonuc yerine hemen hata verir.
library;

import '../math/angles.dart';

/// Ekvatoral koordinat: gokyuzune sabitlenmis, gozlemciden bagimsiz konum.
///
/// Katalog verisi bu sistemdedir. Yildizlar icin (presesyon disinda)
/// zamanla degismez.
class Equatorial {
  /// Sag aciklik (right ascension), `[0, 360)` derece.
  ///
  /// Katalog kaynaklari genelde **saat** cinsinden verir; [hoursToDegrees]
  /// ile cevir. 23h09m16.6s = 347.3193 derece.
  final double rightAscensionDegrees;

  /// Sapma (declination), `[-90, +90]` derece. Kuzey pozitif.
  final double declinationDegrees;

  Equatorial({
    required this.rightAscensionDegrees,
    required this.declinationDegrees,
  }) {
    if (declinationDegrees < -90.0 || declinationDegrees > 90.0) {
      throw ArgumentError.value(
        declinationDegrees,
        'declinationDegrees',
        'Sapma [-90, +90] araliginda olmali',
      );
    }
  }

  /// Sag acikligi saat cinsinden alan yapici — katalog verisi icin.
  factory Equatorial.fromHours({
    required double rightAscensionHours,
    required double declinationDegrees,
  }) => Equatorial(
    rightAscensionDegrees: normalizeDegrees(
      hoursToDegrees(rightAscensionHours),
    ),
    declinationDegrees: declinationDegrees,
  );

  /// Sag aciklik, saat cinsinden `[0, 24)`.
  double get rightAscensionHours => degreesToHours(rightAscensionDegrees);

  @override
  String toString() =>
      'RA ${formatHms(rightAscensionHours)}  '
      'Dec ${formatDms(declinationDegrees)}';
}

/// Ufuk koordinati: gozlemcinin bulundugu yer ve ana gore konum.
///
/// Ayni cisim, ayni anda, farkli konumlardan farkli ufuk koordinatlarina
/// sahiptir. Cerceveye ne sigacagini bu sistem belirler.
class Horizontal {
  /// Azimut, `[0, 360)` derece. **Kuzeyden baslar, doguya dogru artar.**
  ///
  /// 0 = Kuzey, 90 = Dogu, 180 = Guney, 270 = Bati.
  ///
  /// > ⚠️ Meeus ve bazi astronomi kaynaklari azimutu **guneyden** olcer;
  /// > o sistemde 0 = Guney'dir ve aradaki fark 180 derecedir. Pusula,
  /// > telefon sensoru ve kullanicinin kafasindaki sistem kuzey tabanlidir.
  /// > Bu paket bastan sona kuzey tabanli kullanir.
  final double azimuthDegrees;

  /// Yukseklik (altitude), `[-90, +90]` derece. Ufuk = 0, basucu = +90.
  ///
  /// Negatif deger cismin ufkun altinda oldugunu gosterir — hesap yine de
  /// dogru calisir, "gorunmez" karari cagirana aittir.
  final double altitudeDegrees;

  Horizontal({required this.azimuthDegrees, required this.altitudeDegrees}) {
    if (altitudeDegrees < -90.0 || altitudeDegrees > 90.0) {
      throw ArgumentError.value(
        altitudeDegrees,
        'altitudeDegrees',
        'Yukseklik [-90, +90] araliginda olmali',
      );
    }
  }

  /// Basucundan uzaklik (zenith distance), `[0, 180]` derece.
  ///
  /// Hava kutlesi hesabinin girdisi (Faz 5).
  double get zenithDistanceDegrees => 90.0 - altitudeDegrees;

  /// Cisim ufkun uzerinde mi? Atmosferik kirilma hesaba katilmaz.
  bool get isAboveHorizon => altitudeDegrees > 0.0;

  @override
  String toString() =>
      'Az ${formatDms(azimuthDegrees)}  Alt ${formatDms(altitudeDegrees)}';
}

/// Gozlemcinin yeryuzundeki konumu.
class Observer {
  /// Enlem, `[-90, +90]` derece. Kuzey pozitif.
  final double latitudeDegrees;

  /// Boylam, `[-180, 180)` derece. **Dogu pozitif.**
  ///
  /// Gaziantep ~ +37.4, New York ~ -74. GPS ve harita servisleri bu
  /// sozlesmeyi kullanir; Meeus'un bati-pozitif sistemi degil.
  final double longitudeEastDegrees;

  /// Deniz seviyesinden yukseklik, metre. Faz 5'te atmosferik sonum
  /// hesabinda kullanilir; koordinat donusumunu etkilemez.
  final double elevationMeters;

  Observer({
    required this.latitudeDegrees,
    required double longitudeEastDegrees,
    this.elevationMeters = 0.0,
  }) : longitudeEastDegrees = normalizeDegreesSigned(longitudeEastDegrees) {
    if (latitudeDegrees < -90.0 || latitudeDegrees > 90.0) {
      throw ArgumentError.value(
        latitudeDegrees,
        'latitudeDegrees',
        'Enlem [-90, +90] araliginda olmali',
      );
    }
  }

  @override
  String toString() =>
      'Lat ${formatDms(latitudeDegrees)}  '
      'Lon ${formatDms(longitudeEastDegrees)} (dogu+)  '
      '${elevationMeters.toStringAsFixed(0)} m';
}
