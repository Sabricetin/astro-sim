/// T4.5 — Ay'in gokyuzu fon parlakligina katkisi.
///
/// **Bu dosya Faz 5'in dogrudan girdisi.** T4.6'daki "Ay %78 dolu, cekilmez"
/// uyarisi niteliksel; bu ise sayisal. Ay'li gecede fon 2-3 kadir
/// parlayabilir, bu da SNR'i 3-4 kat dusurur. Terim konmazsa arac Ay'li
/// gece icin tamamen yanlis poz onerir.
///
/// Model: Krisciunas & Schaefer (1991), *PASP* 103, 1033.
/// Yayinlanmis, gozlemle kalibre edilmis bir model — uydurma degil.
library;

import 'dart:math' as math;

import '../math/angles.dart';

/// V bandi sonum katsayisi, kadir / hava kutlesi.
///
/// K&S makalesinin kalibrasyonunda kullanilan deger. Iyi bir gozlem
/// yerinde 0.15-0.20 arasi; deniz seviyesinde ve nemli havada daha yuksek.
const double defaultExtinctionCoefficient = 0.172;

/// Karanlik gokyuzu fonu, mag/arcsec^2 — Bortle 1 referansi.
const double darkestSkyMagPerSquareArcsec = 22.0;

/// Kadir/arcsec^2 degerini nanoLambert parlakligina cevirir.
///
/// Iki birim arasindaki standart baginti (K&S denklem 27). Toplama
/// islemi kadirde YAPILAMAZ — kadir logaritmiktir. Iki isik kaynagini
/// birlestirmek icin once ikisini de bu birime cevirmek gerekir.
double magPerSquareArcsecToNanoLamberts(double magnitude) =>
    34.08 * math.exp(20.7233 - 0.92104 * magnitude);

/// nanoLambert parlakligini kadir/arcsec^2 degerine cevirir.
double nanoLambertsToMagPerSquareArcsec(double nanoLamberts) =>
    (20.7233 - math.log(nanoLamberts / 34.08)) / 0.92104;

/// Hava kutlesi, K&S makalesinin kullandigi bicimle.
///
/// `X = (1 - 0.96 sin^2 Z)^(-1/2)`. Basit `sec(Z)` yaklasimindan farkli
/// ve ufka yakin daha dogru; model bu bicimle kalibre edildigi icin
/// tutarlilik adina burada da ayni kullaniliyor.
double kriscunasAirmass(double zenithDistanceDegrees) {
  final z = toRadians(zenithDistanceDegrees.clamp(0.0, 90.0));
  final s = math.sin(z);
  return 1.0 / math.sqrt(math.max(1.0 - 0.96 * s * s, 1e-6));
}

/// Ay'in gokyuzune ekledigi parlaklik, **nanoLambert**.
///
/// Sifir doner: Ay ufkun altindaysa katki yoktur.
///
/// [moonPhaseAngleDegrees] evre acisi (0 = dolunay, 180 = yeni ay).
/// [moonAltitudeDegrees] Ay'in yuksekligi.
/// [targetAltitudeDegrees] bakilan noktanin yuksekligi.
/// [separationDegrees] Ay ile hedef arasindaki gorunur aci.
double moonSkyBrightnessNanoLamberts({
  required double moonPhaseAngleDegrees,
  required double moonAltitudeDegrees,
  required double targetAltitudeDegrees,
  required double separationDegrees,
  double extinctionCoefficient = defaultExtinctionCoefficient,
}) {
  // Ay batmissa hicbir katkisi yok.
  if (moonAltitudeDegrees <= 0) return 0.0;
  // Hedef de ufkun altindaysa soracak bir sey kalmiyor.
  if (targetAltitudeDegrees <= 0) return 0.0;

  final alpha = moonPhaseAngleDegrees.abs().clamp(0.0, 180.0);

  // K&S denklem 20 — atmosfer disinda Ay'in aydinlatma siddeti.
  // alpha^4 terimi dolunaya yakin keskin parlama artisini yakalar
  // (karsit etkisi).
  final illuminance =
      math.pow(
            10.0,
            -0.4 * (3.84 + 0.026 * alpha + 4.0e-9 * math.pow(alpha, 4)),
          )
          as double;

  // K&S denklem 21 — sacilma fonksiyonu. Iki terim: Rayleigh sacilmasi
  // (genis acilarda) ve aerosol (Ay'in yakininda keskin).
  final rho = toRadians(separationDegrees.clamp(0.0, 180.0));
  final cosRho = math.cos(rho);
  final scattering =
      math.pow(10.0, 5.36) * (1.06 + cosRho * cosRho) +
      math.pow(10.0, 6.15 - separationDegrees / 40.0);

  final moonAirmass = kriscunasAirmass(90.0 - moonAltitudeDegrees);
  final targetAirmass = kriscunasAirmass(90.0 - targetAltitudeDegrees);

  // K&S denklem 15: Ay'in isigi once atmosferden gecerken soner
  // (moonAirmass), sonra hedef yonunde sacilan miktar hedefin hava
  // kutlesiyle artar.
  return scattering *
      illuminance *
      math.pow(10.0, -0.4 * extinctionCoefficient * moonAirmass) *
      (1.0 - math.pow(10.0, -0.4 * extinctionCoefficient * targetAirmass));
}

/// Ay katkisi dahil toplam gokyuzu fonu, mag/arcsec^2.
///
/// [baseSkyMagPerSquareArcsec] Ay'siz fon — Bortle sinifindan veya
/// VIIRS verisinden gelir (Faz 0.C ve Faz 7.2).
///
/// **Toplama parlaklikta yapilir, kadirde degil.** Kadir logaritmik
/// oldugu icin iki kadiri toplamak fiziksel olarak anlamsizdir.
double totalSkyBrightnessMagPerSquareArcsec({
  required double baseSkyMagPerSquareArcsec,
  required double moonContributionNanoLamberts,
}) {
  final base = magPerSquareArcsecToNanoLamberts(baseSkyMagPerSquareArcsec);
  return nanoLambertsToMagPerSquareArcsec(base + moonContributionNanoLamberts);
}

/// Ay'in fonu kac kadir parlattigi. Pozitif deger = gokyuzu aydinlandi.
///
/// Arayuzde tek sayiyla anlatmanin en dogrudan yolu: "Ay gokyuzunu 2.3
/// kadir parlatiyor" cumlesi, kullanicinin sezgisine dogrudan oturur.
double moonBrightnessPenaltyMagnitudes({
  required double baseSkyMagPerSquareArcsec,
  required double moonContributionNanoLamberts,
}) =>
    baseSkyMagPerSquareArcsec -
    totalSkyBrightnessMagPerSquareArcsec(
      baseSkyMagPerSquareArcsec: baseSkyMagPerSquareArcsec,
      moonContributionNanoLamberts: moonContributionNanoLamberts,
    );
