/// Julian Day donusumleri.
///
/// Julian Day (JD), MO 4713 1 Ocak 12:00 UTC'den itibaren gecen gun sayisidir.
/// Astronomik hesaplarin tamami bu tek surekli zaman ekseni uzerinde yapilir —
/// takvim ay/gun sinirlari, arti gunler ve zaman dilimleri hesaba girmez.
///
/// Kaynak: Meeus, *Astronomical Algorithms*, 2. baski, Bolum 7.
library;

/// J2000.0 standart epok: 2000-01-01 12:00 TT, Julian Day cinsinden.
///
/// Katalog koordinatlari (RA/Dec) bu epoga gore verilir; presesyon
/// duzeltmesi buradan simdiki tarihe tasir.
const double j2000 = 2451545.0;

/// Bir Julian yuzyilindaki gun sayisi. Presesyon ve GMST serilerinin
/// zaman degiskeni bu birimdedir.
const double daysPerJulianCentury = 36525.0;

/// Gregoryen takvimin yururluge girdigi gun: 1582-10-15.
///
/// Bu tarihten oncesi Julian takvimidir ve artik gun kurali farklidir.
/// Proje modern tarihlerle calisiyor, ama tarihsel gozlem verisi
/// kullanilirsa dogru sonuc versin diye ayrim korunuyor.
const double _gregorianStartJd = 2299160.5;

/// UTC bir [DateTime]'i Julian Day'e cevirir.
///
/// [utc] **UTC olmak zorunda.** Yerel saat kabul edilmez: zaman dilimi,
/// bu tur hesaplarda en sik hata kaynagidir ve sessizce yanlis sonuc
/// uretir. `DateTime.utc(...)` veya `.toUtc()` kullan.
///
/// ```dart
/// julianDay(DateTime.utc(2000, 1, 1, 12));  // 2451545.0
/// ```
double julianDay(DateTime utc) {
  if (!utc.isUtc) {
    throw ArgumentError.value(
      utc,
      'utc',
      'Julian Day hesabi UTC ister. .toUtc() cagir veya DateTime.utc(...) kullan.',
    );
  }

  // Gun icindeki kesir. Mikrosaniyeye kadar korunur: 1 us ~ 1.2e-11 gun,
  // yani JD'nin kayan nokta hassasiyetinin altinda kalir.
  final dayFraction =
      (utc.hour +
          (utc.minute +
                  (utc.second +
                          (utc.millisecond + utc.microsecond / 1000.0) /
                              1000.0) /
                      60.0) /
              60.0) /
      24.0;

  return julianDayFromCalendar(utc.year, utc.month, utc.day + dayFraction);
}

/// Takvim bilesenlerinden dogrudan Julian Day.
///
/// [day] kesirli olabilir: `10.5` = ayin 10'u 12:00 UTC.
///
/// **Neden [DateTime] almayan bir surum var:** Dart'in [DateTime]'i
/// *proleptik Gregoryen* takvim kullanir — 1582-10-15 oncesi tarihleri de
/// Gregoryen kurallarla yorumlar. Oysa o tarihten oncesi tarihsel olarak
/// Julian takvimidir. Modern tarihlerde fark yok, ama tarihsel gozlem
/// verisi (ornegin Meeus'un dogrulama ornekleri) gercek Julian takvim
/// tarihleridir ve [DateTime] uzerinden dogru ifade edilemez.
///
/// Modern tarihler icin [julianDay] kullan; bu fonksiyon takvim ayriminin
/// onemli oldugu durumlar icindir.
double julianDayFromCalendar(int year, int month, double day) {
  // Ocak ve Subat, onceki yilin 13. ve 14. ayi sayilir; boylece artik gun
  // her zaman yilin sonuna duser ve tek bir formul yeter.
  if (month <= 2) {
    year -= 1;
    month += 12;
  }

  // Once takvim ayrimi olmadan hesapla, sonra Gregoryen duzeltmesini ekle.
  final jdJulian =
      (365.25 * (year + 4716)).floor() +
      (30.6001 * (month + 1)).floor() +
      day -
      1524.5;

  if (jdJulian < _gregorianStartJd) {
    return jdJulian; // Julian takvimi: yuzyil duzeltmesi yok
  }

  final a = (year / 100).floor();
  final b = 2 - a + (a / 4).floor();
  return jdJulian + b;
}

/// `double` ile temsil edilen bir Julian Day'in zaman cozunurlugu (mikrosaniye).
///
/// JD modern tarihlerde ~2.46e6 buyuklugunde; `double`'in goreli hassasiyeti
/// 2.2e-16 oldugundan bir ULP ~5.5e-10 gun = ~47 us eder. Gidis-donus
/// donusumlerinde bu mertebede sapma **beklenen davranistir**, hata degil.
///
/// **Bu proje icin fazlasiyla yeterli:** Yer 15 derece/saat doner, yani 0.1
/// derecelik konum toleransi ~24 saniyelik zaman hassasiyetine karsilik gelir.
/// 47 us, ihtiyacin ~500.000 kati altinda. Daha yuksek hassasiyet gerekirse
/// (ki bu projede gerekmiyor) JD'yi tamsayi gun + kesir olarak ayri tutmak
/// gerekir.
const int julianDayResolutionMicroseconds = 50;

/// Julian Day'i UTC [DateTime]'e cevirir. [julianDay]'in tersi.
///
/// Gidis-donus sapmasi icin [julianDayResolutionMicroseconds]'a bak.
DateTime dateTimeFromJulianDay(double jd) {
  final shifted = jd + 0.5;
  final z = shifted.floor();
  final f = shifted - z;

  final int a;
  if (z < 2299161) {
    a = z; // Julian takvimi
  } else {
    final alpha = ((z - 1867216.25) / 36524.25).floor();
    a = z + 1 + alpha - (alpha / 4).floor();
  }

  final b = a + 1524;
  final c = ((b - 122.1) / 365.25).floor();
  final d = (365.25 * c).floor();
  final e = ((b - d) / 30.6001).floor();

  final dayWithFraction = b - d - (30.6001 * e).floor() + f;
  final day = dayWithFraction.floor();
  final month = e < 14 ? e - 1 : e - 13;
  final year = month > 2 ? c - 4716 : c - 4715;

  final microsOfDay = ((dayWithFraction - day) * Duration.microsecondsPerDay)
      .round();

  return DateTime.utc(
    year,
    month,
    day,
  ).add(Duration(microseconds: microsOfDay));
}

/// J2000.0'dan itibaren gecen Julian yuzyili sayisi.
///
/// Presesyon, GMST ve efemeris serilerinin standart zaman degiskeni (`T`).
/// Negatif deger J2000 oncesini gosterir.
double julianCenturies(double jd) => (jd - j2000) / daysPerJulianCentury;

/// [utc]'den dogrudan Julian yuzyili. `julianCenturies(julianDay(utc))` kisayolu.
double julianCenturiesFromUtc(DateTime utc) => julianCenturies(julianDay(utc));
