/// T5.1 — Kadirden foton akisina.
///
/// Zincirin ilk halkasi ve **kalibrasyon gerektirmeyen** kismi: Johnson V
/// bandinin sifir noktasi yayinlanmis bir fiziksel sabit, olculecek bir
/// buyukluk degil.
///
/// Kaynak: Bessell (1979), PASP 91, 589; Bessell & Murphy (2012),
/// PASP 124, 140.
library;

import 'dart:math' as math;

/// Planck sabiti, erg·s.
const planckConstantErgSeconds = 6.62607015e-27;

/// Isik hizi, cm/s.
const speedOfLightCmPerSecond = 2.99792458e10;

/// Johnson V bandinin etkin dalga boyu, angstrom.
const vBandEffectiveWavelengthAngstrom = 5500.0;

/// Johnson V bandinin etkin genisligi, angstrom.
const vBandEffectiveWidthAngstrom = 890.0;

/// V = 0 bir yildizin bant disi akis yogunlugu,
/// erg cm^-2 s^-1 angstrom^-1. Bessell (1979).
const vBandZeroPointFluxDensity = 3.63e-9;

/// Bir angstrom'luk fotonun enerjisi, erg. E = hc / lambda.
///
/// Angstrom -> cm donusumu burada, tek yerde yapiliyor. Birim tuzagi
/// bolumunun dedigi gibi: donusum sinirda olur, formulun icinde degil.
double photonEnergyErg(double wavelengthAngstrom) =>
    planckConstantErgSeconds *
    speedOfLightCmPerSecond /
    (wavelengthAngstrom * 1e-8);

/// V = 0 yildizin foton akisi, foton cm^-2 s^-1 angstrom^-1.
///
/// Elle yazilmis bir sayi degil — yukaridaki sabitlerden turetiliyor.
/// Yaklasik 1005; degistirmek isteyen sabiti degistirsin, sonucu degil.
double get vBandZeroPointPhotonFlux =>
    vBandZeroPointFluxDensity /
    photonEnergyErg(vBandEffectiveWavelengthAngstrom);

/// V = 0 yildizin bant boyunca toplam foton akisi,
/// foton cm^-2 s^-1. Yaklasik 8.9e5.
double get vBandZeroPointTotalPhotonFlux =>
    vBandZeroPointPhotonFlux * vBandEffectiveWidthAngstrom;

/// V kadirinden atmosfer disindaki foton akisi, foton cm^-2 s^-1.
///
///     F = F0 · 10^(-0.4 m)
///
/// Bu deger **atmosfer disi**. Sonum [extinctionMagnitudes] ile ayrica
/// uygulanir; ikisini birlestirmemek bilincli — sonum konuma ve geceye
/// bagli olculmus bir buyukluk, bu ise degil.
double photonFluxFromMagnitude(double vMagnitude) =>
    vBandZeroPointTotalPhotonFlux * math.pow(10, -0.4 * vMagnitude);

/// Iki kadir arasindaki akis orani. m2 - m1 kadir farki icin
/// 10^(0.4 · fark).
double fluxRatioFromMagnitudeDifference(double magnitudeDifference) =>
    math.pow(10, 0.4 * magnitudeDifference).toDouble();
