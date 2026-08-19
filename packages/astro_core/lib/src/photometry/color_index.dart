/// T2.7 — B-V renk indeksinden yildiz renk sicakligi.
///
/// B-V, yildizin mavi (B) ve gorsel (V) bantlardaki kadirleri arasindaki
/// farktir. Negatif = mavi/sicak, pozitif = kirmizi/soguk. Sicaklikla
/// dogrudan iliskilidir ve katalogda hazir gelir.
///
/// Bu dosya **fizik** yapar: B-V -> Kelvin. Kelvin -> ekran rengi donusumu
/// sunum katmaninda (Flutter uygulamasinda) yasar; astro_core hicbir cizim
/// karari vermez.
library;

import 'dart:math' as math;

/// Ballesteros formulunun gecerli kaldigi B-V alt siniri.
///
/// Bunun altinda payda sifira yaklasir ve sonuc patlar. Katalogdaki en
/// mavi yildiz -0.28 (HR 1996, tayf O9.5V), yani pratikte sinira
/// carpilmiyor; yine de korumasiz birakilmiyor.
const double minValidColorIndex = -0.4;

/// Ust sinir. Katalogdaki en kirmizi yildiz +3.86 (HR 423, karbon yildizi).
const double maxValidColorIndex = 6.0;

/// B-V renk indeksinden etkin sicaklik, **Kelvin**.
///
/// Ballesteros (2012) yaklasimi: yildizi iki siyah cisim toplami sayar.
/// Gunes icin sasirtici derecede iyi tutar — B-V 0.65 girildiginde 5779 K
/// verir, gercek deger 5778 K.
///
/// **Sinirlama:** cok sicak yildizlarda dusuk tahmin eder. O9.5V bir yildiz
/// (B-V -0.28) icin ~15.900 K verir, gercegi ~32.000 K. Gorsel renk icin
/// bu onemsiz — 10.000 K'nin ustunde her sey zaten mavi-beyaz gorunur ve
/// goz farki ayirt etmez. Radyometride (Faz 5) sicaklik gerekirse tayf
/// tipinden gitmek daha dogru olur.
///
/// [bv] gecerli aralik disindaysa kirpilir; NaN girdi NaN dondurur
/// (katalogda B-V'si olmayan 244 yildiz icin).
double colorTemperatureFromBV(double bv) {
  if (bv.isNaN) return double.nan;
  final b = bv.clamp(minValidColorIndex, maxValidColorIndex);
  return 4600.0 * (1.0 / (0.92 * b + 1.7) + 1.0 / (0.92 * b + 0.62));
}

/// Yildizin gorsel kadirinden bagil parlaklik orani.
///
/// Kadir logaritmik bir olcektir: 5 kadirlik fark tam 100 kat parlaklik
/// demektir. Ekranda nokta boyutu secerken bu olcegin dogrudan
/// kullanilmasi gerekir — dogrusal esleme 1. kadir ile 6. kadiri
/// birbirine yakin gosterir.
///
/// [referenceMagnitude] hangi kadirin 1.0 sayilacagi.
double relativeBrightness(
  double magnitude, {
  double referenceMagnitude = 0.0,
}) => math.pow(10.0, -0.4 * (magnitude - referenceMagnitude)).toDouble();
