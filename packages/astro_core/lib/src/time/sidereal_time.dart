/// Yildiz zamani (sidereal time).
///
/// Yildiz zamani, gokyuzunun donusunu olcen saattir: bir yildizin sag acikligi
/// (RA) yerel yildiz zamanina esitse, o yildiz tam o anda meridyendedir
/// (gunun en yuksek noktasinda).
///
/// Bu, RA/Dec -> Alt/Az donusumunun kilidi. Saat acisi soyle bulunur:
///
///     H = LST - RA
///
/// Kaynak: Meeus, *Astronomical Algorithms*, 2. baski, Bolum 12.
library;

import '../math/angles.dart';
import 'julian_day.dart';

/// Greenwich ortalama yildiz zamani, **derece** cinsinden `[0, 360)`.
///
/// [jd] UT1 olcegindeki Julian Day. Pratikte UTC kullaniyoruz: aradaki fark
/// (DUT1) her zaman 0.9 saniyenin altinda tutulur, bu da 0.0037 derecelik
/// bir konum farki demektir — bu projenin 0.1 derecelik toleransinin
/// ~27'de biri. Onemsiz.
double greenwichMeanSiderealTimeDegrees(double jd) {
  final d = jd - j2000; // J2000'den itibaren gun (kesirli)
  final t = d / daysPerJulianCentury;

  // Meeus 12.4. Katsayilarin birimi derece; ikinci terim gunde donus hizidir
  // (360.98565 derece/gun — 360'tan buyuk cunku Yer hem doner hem ilerler,
  // yildiz gunu gunes gununden ~4 dakika kisadir).
  final theta =
      280.46061837 +
      360.98564736629 * d +
      0.000387933 * t * t -
      (t * t * t) / 38710000.0;

  return normalizeDegrees(theta);
}

/// Greenwich ortalama yildiz zamani, **saat** cinsinden `[0, 24)`.
double greenwichMeanSiderealTimeHours(double jd) =>
    degreesToHours(greenwichMeanSiderealTimeDegrees(jd));

/// UTC bir [DateTime]'den Greenwich ortalama yildiz zamani (derece).
double gmstFromUtc(DateTime utc) =>
    greenwichMeanSiderealTimeDegrees(julianDay(utc));

/// Yerel ortalama yildiz zamani, **derece** cinsinden `[0, 360)`.
///
/// [longitudeEastDegrees] **dogu pozitif.** Gaziantep ~ +37.4, New York ~ -74.
///
/// > ⚠️ Meeus ve bazi eski astronomi kaynaklari boylami **bati pozitif**
/// > alir ve formulu `GMST - L` diye yazar. GPS, harita servisleri ve
/// > kullanicidan gelecek her veri dogu pozitiftir. Bu paket bastan sona
/// > dogu pozitif kullanir; isaret cevrimi varsa sadece burada olur.
/// > Yanlis isaret, boylamin iki kati kadar kayma uretir ve Turkiye icin
/// > bu ~75 derecedir — sessizce yanlis, kolayca gozden kacar.
double localMeanSiderealTimeDegrees(double jd, double longitudeEastDegrees) =>
    normalizeDegrees(
      greenwichMeanSiderealTimeDegrees(jd) + longitudeEastDegrees,
    );

/// Yerel ortalama yildiz zamani, **saat** cinsinden `[0, 24)`.
double localMeanSiderealTimeHours(double jd, double longitudeEastDegrees) =>
    degreesToHours(localMeanSiderealTimeDegrees(jd, longitudeEastDegrees));

/// UTC bir [DateTime] ve dogu-pozitif boylamdan yerel yildiz zamani (derece).
double lstFromUtc(DateTime utc, double longitudeEastDegrees) =>
    localMeanSiderealTimeDegrees(julianDay(utc), longitudeEastDegrees);

/// Saat acisi: bir cismin meridyenden ne kadar uzakta oldugu, `[-180, 180)`.
///
/// Negatif = henuz meridyene varmadi (doguda, yukseliyor).
/// Sifir     = tam meridyende, gunun en yuksek noktasinda.
/// Pozitif   = meridyeni gecti (batida, alcaliyor).
///
/// [rightAscensionDegrees] cismin sag acikligi, derece cinsinden. Katalog
/// verisi genelde saat cinsindendir; [hoursToDegrees] ile cevir.
double hourAngleDegrees(
  double localSiderealTimeDegrees,
  double rightAscensionDegrees,
) => normalizeDegreesSigned(localSiderealTimeDegrees - rightAscensionDegrees);

// ---------------------------------------------------------------------------
// Neden "ortalama" (mean), "gercek" (apparent) degil
// ---------------------------------------------------------------------------
//
// Gercek yildiz zamani (GAST), ortalamaya ekinoksun denklemini ekler; bu da
// nutasyondan gelir ve genligi en fazla ~17 yay saniyesi = 0.005 derecedir.
//
// Bu projenin dogrulama toleransi 0.1 derece (6 yay dakikasi). Nutasyon
// bunun ~20'de biri kadar; presesyon ve atmosferik kirilmanin yaninda
// gurultu seviyesinde kalir. Eklemek karmasiklik getirir, dogruluk
// getirmez — bilerek disarida birakildi.
//
// Eger ileride tolerans 0.01 dereceye inerse (ki bu projede gerekmiyor),
// once nutasyon, sonra yillik aberasyon eklenmelidir.
