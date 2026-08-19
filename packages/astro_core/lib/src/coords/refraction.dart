/// Atmosferik kirilma: geometrik yukseklik <-> gorunur yukseklik.
///
/// Atmosfer isigi buker, bu yuzden cisimler oldugundan **yuksekte** gorunur.
/// Etkinin buyuklugu yuksekliğe cok baglidir:
///
/// | Gercek yukseklik | Kirilma |
/// |---|---|
/// | 45 derece | 1.01 yay dakikasi |
/// | 24 derece | 2.25 |
/// | 10 derece | 5.41 |
/// |  5 derece | 9.67 |
/// |  0 derece | 28.98 |
///
/// (Gorunur yukseklik 0'da, yani cisim ufukta GORUNURKEN, 34.48.)
///
/// **Bu proje icin neden onemli:** Projenin toleransi 0.1 derece = 6 yay
/// dakikasi. 10 derecenin altinda kirilma tek basina bu toleransi yer.
/// Galaktik merkez Gaziantep'ten sadece ~24 dereceye ciktigi icin dusuk
/// yukseklik bu projenin kenar durumu degil, ana durumudur.
///
/// **Stellarium tuzagi:** Stellarium varsayilan olarak atmosferi acik
/// calistirir ve gorunur yukseklik gosterir. Dogrulama matrisinde
/// karsilastirma yaparken hangi tarafta oldugunu bilmek zorundasin;
/// yoksa dusuk yukseklikteki testler tutmaz ve sebebi gunlerce aranir.
///
/// Kaynak: Meeus, *Astronomical Algorithms*, 2. baski, Bolum 16.
library;

import 'dart:math' as math;

import '../math/angles.dart';

/// Standart atmosfer basinci, milibar. Formullerin kalibre edildigi deger.
const double standardPressureMillibars = 1010.0;

/// Standart atmosfer sicakligi, Celsius.
const double standardTemperatureCelsius = 10.0;

/// Formullerin gecerli kaldigi en dusuk gercek yukseklik, derece.
///
/// Bunun altinda cisim zaten ufkun altindadir ve kirilma modeli fiziksel
/// anlamini yitirir (gercek atmosferde serap, kanallanma gibi olaylar
/// devreye girer). Daha alcak degerlerde kirilma sabit tutulur.
const double refractionFloorDegrees = -1.0;

/// Basinc ve sicaklik duzeltme carpani.
///
/// Formuller 1010 mbar / 10 C icin kalibre. Yuksek rakimda basinc duser,
/// kirilma azalir: 2000 m'de ~%20 daha az.
double _conditionsFactor(double pressureMillibars, double temperatureCelsius) =>
    (pressureMillibars / standardPressureMillibars) *
    (283.0 / (273.0 + temperatureCelsius));

/// Gercek (geometrik) yukseklikten kirilma miktari, **derece**.
///
/// Saemundsson formulu (Meeus 16.4). Girdi gercek yukseklik oldugu icin
/// koordinat donusumunun ciktisiyla dogrudan kullanilir.
///
/// Donen deger her zaman pozitiftir: kirilma cismi yukari iter.
double refractionFromTrueAltitude(
  double trueAltitudeDegrees, {
  double pressureMillibars = standardPressureMillibars,
  double temperatureCelsius = standardTemperatureCelsius,
}) {
  final h = math.max(trueAltitudeDegrees, refractionFloorDegrees);
  // Meeus 16.4 — sonuc yay dakikasi cinsinden.
  final arcminutes = 1.02 / math.tan(toRadians(h + 10.3 / (h + 5.11)));
  // Basucuna cok yakinda (h ~ 90) parantez ici 90 dereceyi asar, tanjant
  // isaret degistirir ve formul kucuk bir NEGATIF deger uretir (~-0.002 yay
  // dakikasi). Buyukluk ihmal edilebilir ama isaret fizige aykiri: kirilma
  // cismi asla asagi itmez. Sifira kirp.
  return math.max(0.0, arcminutes) /
      60.0 *
      _conditionsFactor(pressureMillibars, temperatureCelsius);
}

/// Gorunur yukseklikten kirilma miktari, **derece**.
///
/// Bennett formulu (Meeus 16.3). Girdi gozlenen yukseklik oldugu icin
/// olcum verisiyle karsilastirma yaparken bu kullanilir.
double refractionFromApparentAltitude(
  double apparentAltitudeDegrees, {
  double pressureMillibars = standardPressureMillibars,
  double temperatureCelsius = standardTemperatureCelsius,
}) {
  final h = math.max(apparentAltitudeDegrees, refractionFloorDegrees);
  // Meeus 16.3 — sonuc yay dakikasi cinsinden.
  final arcminutes = 1.0 / math.tan(toRadians(h + 7.31 / (h + 4.4)));
  // Bkz. refractionFromTrueAltitude: basucu yakininda isaret donmesi.
  return math.max(0.0, arcminutes) /
      60.0 *
      _conditionsFactor(pressureMillibars, temperatureCelsius);
}

/// Gercek yukseklikten gorunur yuksekligi verir.
///
/// Koordinat donusumu geometrik yukseklik uretir; kullaniciya gosterilecek
/// ve ufuk profiliyle karsilastirilacak olan budur.
double apparentAltitudeDegrees(
  double trueAltitudeDegrees, {
  double pressureMillibars = standardPressureMillibars,
  double temperatureCelsius = standardTemperatureCelsius,
}) =>
    trueAltitudeDegrees +
    refractionFromTrueAltitude(
      trueAltitudeDegrees,
      pressureMillibars: pressureMillibars,
      temperatureCelsius: temperatureCelsius,
    );

/// Gorunur yukseklikten gercek yuksekligi verir. [apparentAltitudeDegrees]
/// isleminin tersi.
double trueAltitudeDegrees(
  double apparentAltitude, {
  double pressureMillibars = standardPressureMillibars,
  double temperatureCelsius = standardTemperatureCelsius,
}) =>
    apparentAltitude -
    refractionFromApparentAltitude(
      apparentAltitude,
      pressureMillibars: pressureMillibars,
      temperatureCelsius: temperatureCelsius,
    );
