/// Aci donusumleri, normalizasyon ve okunabilir bicimlendirme.
///
/// Bu paketin **ic birimi derecedir**. Trigonometri icin radyana cevrilir,
/// ekranda gosterim icin derece/dakika/saniyeye. Radyan sadece hesabin
/// icinde yasar; disari cikan hicbir deger radyan degildir.
///
/// Neden derece: katalog verisi, Stellarium karsilastirmalari ve kullanici
/// girdisi hep derece cinsinden. Sinirlarda tek bir birim olmasi, en sik
/// hata kaynagi olan birim karisikligini kaldirir.
library;

import 'dart:math' as math;

/// Bir radyan kac derece eder.
const double degreesPerRadian = 180.0 / math.pi;

/// Bir derece kac radyan eder.
const double radiansPerDegree = math.pi / 180.0;

/// Saat aciciligi: gokyuzu 24 saatte 360 derece doner.
const double degreesPerHour = 15.0;

/// Dereceyi radyana cevirir. Sadece trigonometri cagrilarinda kullan.
double toRadians(double degrees) => degrees * radiansPerDegree;

/// Radyani dereceye cevirir. Trigonometri sonuclarini hemen buradan gecir.
double toDegrees(double radians) => radians * degreesPerRadian;

/// Aciyi `[0, 360)` araligina indirger.
///
/// Azimut, sag acikligi ve yildiz zamani gibi tam tur donen buyuklukler icin.
/// Negatif girdilerde de dogru calisir: `normalizeDegrees(-90)` -> `270`.
double normalizeDegrees(double degrees) {
  final r = degrees % 360.0;
  return r < 0 ? r + 360.0 : r;
}

/// Aciyi `[-180, 180)` araligina indirger.
///
/// Saat acisi ve boylam farki gibi isaretin anlamli oldugu buyuklukler icin:
/// "meridyenin 10 derece batisinda" ile "350 derece dogusunda" ayni sey ama
/// ilki okunabilir.
double normalizeDegreesSigned(double degrees) {
  final r = normalizeDegrees(degrees);
  return r >= 180.0 ? r - 360.0 : r;
}

/// Saati `[0, 24)` araligina indirger.
double normalizeHours(double hours) {
  final r = hours % 24.0;
  return r < 0 ? r + 24.0 : r;
}

/// Saati dereceye cevirir (1 saat = 15 derece).
double hoursToDegrees(double hours) => hours * degreesPerHour;

/// Dereceyi saate cevirir.
double degreesToHours(double degrees) => degrees / degreesPerHour;

/// Saat degerini `13h10m46.37s` bicimine getirir.
///
/// Sag acikligi ve yildiz zamani karsilastirmalarinda kullanilir — Stellarium
/// ve katalog kaynaklari bu bicimde yazar, ondalik saatle goz karsilastirmasi
/// yapmak zordur.
///
/// [decimals] saniyenin ondalik basamak sayisi.
String formatHms(double hours, {int decimals = 2}) {
  final parts = _sexagesimal(normalizeHours(hours), decimals, 24.0);
  return '${parts.unit}h${_pad(parts.minute)}m'
      '${_padSeconds(parts.second, decimals)}s';
}

/// Aciyi `+41°01′23.4″` bicimine getirir.
///
/// Sapma (declination), yukseklik ve enlem icin. Isaret her zaman yazilir;
/// `-00°30′00″` ile `+00°30′00″` arasindaki fark gozden kacmasin.
String formatDms(double degrees, {int decimals = 1}) {
  final sign = degrees < 0 ? '-' : '+';
  final parts = _sexagesimal(degrees.abs(), decimals, null);
  return '$sign${_pad(parts.unit)}°${_pad(parts.minute)}′'
      '${_padSeconds(parts.second, decimals)}″';
}

/// Saniyeyi iki tam haneye sabitleyip istenen ondalik basamagi ekler.
///
/// Genislik `decimals + 3` diye sabitlenemez: ondalik yokken (`decimals == 0`)
/// nokta da olmadigi icin bu fazladan bir sifir ekler ve `23` yerine `023`
/// yazar.
String _padSeconds(double second, int decimals) {
  final width = decimals > 0 ? decimals + 3 : 2;
  return second.toStringAsFixed(decimals).padLeft(width, '0');
}

/// Bir aciyi/saati tam kisim, dakika ve saniyeye ayirir.
///
/// [wrap] verilirse (ornegin saatler icin 24), saniye yuvarlamasi tasip
/// tam kismi asarsa basa doner. Bu carry olmadan `23h59m59.999s` yanlislikla
/// `23h60m00.00s` olarak yazilir.
({int unit, int minute, double second}) _sexagesimal(
  double value,
  int decimals,
  double? wrap,
) {
  var unit = value.floor();
  final rest = (value - unit) * 60.0;
  var minute = rest.floor();
  var second = (rest - minute) * 60.0;

  // Yuvarlama tasmasini yukari tasi.
  final rounded = double.parse(second.toStringAsFixed(decimals));
  if (rounded >= 60.0) {
    second = 0.0;
    minute += 1;
  } else {
    second = rounded;
  }
  if (minute >= 60) {
    minute = 0;
    unit += 1;
  }
  if (wrap != null && unit >= wrap) {
    unit -= wrap.toInt();
  }
  return (unit: unit, minute: minute, second: second);
}

String _pad(int v) => v.toString().padLeft(2, '0');
