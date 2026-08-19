/// T3.6-T3.8 — Maksimum poz suresi ve yildiz izi.
///
/// Yer donuyor; takipci yoksa yildizlar sensorde iz birakir. Soru su:
/// iz gozle fark edilmeden en fazla ne kadar poz verilebilir?
library;

import 'dart:math' as math;

import '../math/angles.dart';
import 'field_of_view.dart';

/// Yildizlarin gokyuzunde gorunur hareket hizi, yay saniyesi / saniye.
///
/// Bir yildiz gunu 86164.09 saniye; bu surede gokyuzu 360 derece doner.
/// 360 * 3600 / 86164.09 = 15.041 yay saniyesi/saniye.
const double siderealRateArcsecPerSecond = 15.041;

/// Deklinasyon duzeltmesinde kullanilan en kucuk cos degeri.
///
/// Kutupta cos(delta) sifira gider ve poz suresi sonsuza cikar. Fiziksel
/// olarak dogru (kutup yildizi neredeyse kimildamaz) ama pratikte baska
/// sinirlar devreye girer: takip hatasi, ruzgar, atmosfer. 0.05 kirpmasi
/// ust siniri 20 katla sabitler.
const double _minCosDeclination = 0.05;

/// NPF kurali: takipsiz maksimum poz suresi, saniye.
///
///     t = (35 * N + 30 * p) / f
///
/// [aperture] diyafram sayisi N (f/2.8 icin 2.8).
/// [pixelPitchMicrometers] piksel adimi p, **mikrometre**.
/// [focalLengthMm] odak uzunlugu f, milimetre.
/// [declinationDegrees] hedefin sapmasi; verilirse [t / cos(delta)]
/// duzeltmesi uygulanir.
///
/// **Neden NPF, 500 kurali degil:** 500 kurali (t = 500/f) piksel
/// yogunlugunu yok sayar. 45 MP bir govdede yalan soyler — %100'de
/// bakildiginda izler gorunur. NPF piksel adimini hesaba katar.
///
/// **Ilginc ozellik:** NPF sinirindaki iz uzunlugu odak uzunlugundan
/// BAGIMSIZDIR. t odakla ters, acisal olcek de odakla ters orantili
/// oldugu icin ikisi sadelesir; tipik degerlerle iz ~4 piksel cikar.
/// Kuralin tutarli olmasinin sebebi bu.
double npfMaxExposureSeconds({
  required double aperture,
  required double pixelPitchMicrometers,
  required double focalLengthMm,
  double? declinationDegrees,
}) {
  if (focalLengthMm <= 0) {
    throw ArgumentError.value(focalLengthMm, 'focalLengthMm', 'pozitif olmali');
  }
  final base = (35.0 * aperture + 30.0 * pixelPitchMicrometers) / focalLengthMm;
  if (declinationDegrees == null) return base;
  return base / declinationFactor(declinationDegrees);
}

/// Deklinasyona bagli gorunur hareket carpani, `cos(delta)`.
///
/// Ekvatorda 1 (en hizli), kutba dogru sifira yaklasir. Temel NPF formulu
/// bunu yok sayar ve hedefin ekvatorda oldugunu varsayar; yol haritasi
/// bu duzeltmeyi ayri gorev olarak isaretledi.
///
/// Galaktik merkez icin (sapma -29 derece) carpan 0.87, yani gercek sinir
/// temel formulun verdiginin %15 uzerinde.
double declinationFactor(double declinationDegrees) =>
    math.max(math.cos(toRadians(declinationDegrees)).abs(), _minCosDeclination);

/// Verilen pozda yildizin birakacagi iz uzunlugu, **piksel**.
///
/// Sifira yakin bir deger noktasal yildiz demektir; 1-2 pikselin ustu
/// %100 goruntulemede fark edilir.
double starTrailPixels({
  required double exposureSeconds,
  required double pixelPitchMicrometers,
  required double focalLengthMm,
  double declinationDegrees = 0.0,
}) {
  final scale = arcsecondsPerPixel(
    pixelPitchMicrometers: pixelPitchMicrometers,
    focalLengthMm: focalLengthMm,
  );
  final movedArcseconds =
      siderealRateArcsecPerSecond *
      declinationFactor(declinationDegrees) *
      exposureSeconds;
  return movedArcseconds / scale;
}

/// 500 kurali — **karsilastirma icin**, oneri olarak degil.
///
/// Arayuzde NPF'nin yaninda gosterilirse kullanici farki gorur: eski
/// kural yuksek cozunurluklu govdelerde ciddi sekilde iyimserdir.
double fiveHundredRuleSeconds(double focalLengthMm) => 500.0 / focalLengthMm;
