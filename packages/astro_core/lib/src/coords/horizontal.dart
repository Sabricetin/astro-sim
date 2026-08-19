/// Ekvatoral <-> ufuk koordinat donusumu.
///
/// Zincirin son halkasi:
///
///     UTC -> Julian Day -> LST -> saat acisi -> Alt/Az
///
/// Kaynak: Meeus, *Astronomical Algorithms*, 2. baski, Bolum 13.
///
/// **Bu donusum geometriktir.** Atmosferik kirilma dahil degildir; cikan
/// yukseklik *gercek* (geometrik) yukseklitir, gozle gorulen degil. Gorunur
/// yukseklik icin `refraction.dart` (T1.6) uzerinden gecir. Ufkun yakininda
/// aradaki fark yarim dereceye kadar cikar.
library;

import 'dart:math' as math;

import '../math/angles.dart';
import '../time/julian_day.dart';
import '../time/sidereal_time.dart';
import 'types.dart';

/// Ekvatoral koordinati ufuk koordinatina cevirir.
///
/// [localSiderealTimeDegrees] gozlem anindaki yerel yildiz zamani; bkz.
/// [localMeanSiderealTimeDegrees].
///
/// Donen azimut **kuzey tabanlidir** (0 = Kuzey, 90 = Dogu).
Horizontal equatorialToHorizontal({
  required Equatorial equatorial,
  required Observer observer,
  required double localSiderealTimeDegrees,
}) {
  final h = toRadians(
    hourAngleDegrees(
      localSiderealTimeDegrees,
      equatorial.rightAscensionDegrees,
    ),
  );
  final dec = toRadians(equatorial.declinationDegrees);
  final lat = toRadians(observer.latitudeDegrees);

  final sinDec = math.sin(dec);
  final cosDec = math.cos(dec);
  final sinLat = math.sin(lat);
  final cosLat = math.cos(lat);
  final sinH = math.sin(h);
  final cosH = math.cos(h);

  // Meeus 13.6
  final sinAlt = sinLat * sinDec + cosLat * cosDec * cosH;

  // Meeus 13.5, kuzey tabanli azimut icin yeniden duzenlenmis hali.
  // atan2 kullanmak sart: tek argumanli atan, dogru ceyregi bilemez ve
  // azimut 180 derece yanlis cikar.
  //
  // Eksi isareti, azimutun kuzeyden DOGUYA artmasindan gelir. Meeus'un
  // guney tabanli formulunde bu isaret yoktur; aradaki fark tam 180 derece.
  final azimuth = math.atan2(
    -cosDec * sinH,
    sinDec * cosLat - cosDec * sinLat * cosH,
  );

  return Horizontal(
    azimuthDegrees: normalizeDegrees(toDegrees(azimuth)),
    // clamp: kutup gibi uc durumlarda kayan nokta hatasi sinAlt'i
    // 1.0000000002 yapabilir ve asin NaN dondurur.
    altitudeDegrees: toDegrees(math.asin(sinAlt.clamp(-1.0, 1.0))),
  );
}

/// UTC ve gozlemciden dogrudan ufuk koordinati. Yildiz zamanini kendi hesaplar.
Horizontal equatorialToHorizontalAt({
  required Equatorial equatorial,
  required Observer observer,
  required DateTime utc,
}) => equatorialToHorizontal(
  equatorial: equatorial,
  observer: observer,
  localSiderealTimeDegrees: localMeanSiderealTimeDegrees(
    julianDay(utc),
    observer.longitudeEastDegrees,
  ),
);

/// Ufuk koordinatini ekvatoral koordinata cevirir. [equatorialToHorizontal]
/// isleminin tersi.
///
/// Arayuzde "ekrandaki su noktada ne var?" sorusunu yanitlamak icin gerekli:
/// kullanici bakisi surukledginde ufuk koordinati degisir, hangi yildizlarin
/// cerceveye girdigini bulmak icin geri cevirmek gerekir.
Equatorial horizontalToEquatorial({
  required Horizontal horizontal,
  required Observer observer,
  required double localSiderealTimeDegrees,
}) {
  final az = toRadians(horizontal.azimuthDegrees);
  final alt = toRadians(horizontal.altitudeDegrees);
  final lat = toRadians(observer.latitudeDegrees);

  final sinAlt = math.sin(alt);
  final cosAlt = math.cos(alt);
  final sinLat = math.sin(lat);
  final cosLat = math.cos(lat);
  final sinAz = math.sin(az);
  final cosAz = math.cos(az);

  // Ileri donusumun uc bagintisini sinLat/cosLat ile birlestirerek cozulur:
  //   sin(alt)      = sinφ sinδ + cosφ cosδ cosH
  //   cos(alt)cos(A)= cosφ sinδ - sinφ cosδ cosH
  //   cos(alt)sin(A)= -cosδ sinH
  // Birinciyi sinφ, ikinciyi cosφ ile carpip toplayinca sinδ; cosφ ve sinφ
  // ile carpip cikarinca cosδ cosH kalir. Isaretler buradan gelir — elle
  // "tersini al" diye yazmak iki terimde de yanlis isaret uretir.
  final sinDec = sinLat * sinAlt + cosLat * cosAlt * cosAz;
  final hourAngle = math.atan2(
    -cosAlt * sinAz,
    cosLat * sinAlt - sinLat * cosAlt * cosAz,
  );

  return Equatorial(
    rightAscensionDegrees: normalizeDegrees(
      localSiderealTimeDegrees - toDegrees(hourAngle),
    ),
    declinationDegrees: toDegrees(math.asin(sinDec.clamp(-1.0, 1.0))),
  );
}

/// Bir cismin verilen enlemde ulasabilecegi **en yuksek** yukseklik.
///
/// Cisim meridyeni gectigi anda (saat acisi = 0) bu degere ulasir.
/// Hedefin o konumdan cekilebilir olup olmadigini anlamanin en hizli yolu:
/// galaktik merkez (sapma -29 derece) Gaziantep'ten (enlem +37) sadece
/// 24 dereceye cikar.
/// Cisim hic dogmuyorsa deger negatif cikar — bu anlamlidir, kirpilmaz.
double maximumAltitudeDegrees({
  required double declinationDegrees,
  required double latitudeDegrees,
}) => 90.0 - (latitudeDegrees - declinationDegrees).abs();

/// Cisim bu enlemde hic batmaz mi? (circumpolar)
bool isCircumpolar({
  required double declinationDegrees,
  required double latitudeDegrees,
}) => (declinationDegrees + latitudeDegrees).abs() > 90.0;

/// Cisim bu enlemde hic dogmaz mi?
bool isNeverVisible({
  required double declinationDegrees,
  required double latitudeDegrees,
}) => (declinationDegrees - latitudeDegrees).abs() > 90.0;
