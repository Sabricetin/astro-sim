/// T6.6 — Gokyuzu fonunun yone gore degisimi.
///
/// Fon tek bir sayi degil. Iki sebeple ufka dogru parlar:
///
///   1. **Hava parildamasi (airglow)** ~90 km yukseklikte ince bir
///      katmandan gelir. Alcaga bakinca o katmanda daha uzun yol
///      alinir, yani daha cok isik toplanir. Van Rhijn (1921).
///   2. **Sonum** ise ters yonde calisir: alcaktaki isik daha kalin
///      atmosferden geciyor ve zayifliyor.
///
/// Ikisi birbirini kismen goturur ama **birincisi baskin**: 24
/// derecede net etki basucuna gore 0.47 kadir daha PARLAK. Projenin
/// ana hedefi tam orada durdugu icin bu ihmal edilemez — tek sayilik
/// fon modeli SNR'i iyimser gosterirdi.
///
/// **Yapay isik (sehir parlamasi) burada YOK.** O yone bagli ve
/// tamamen yere ozel; modellenemez, olculur. Bkz.
/// [artificialGlowMissing].
library;

import 'dart:math' as math;

import '../math/angles.dart';
import 'calibration.dart';
import 'extinction.dart';
import 'missing.dart';

/// Hava parildamasi katmaninin yuksekligi, km.
///
/// Yesil OI 557.7 nm satiri ~90-100 km'de olusur. Deger literaturden;
/// olculmus bir kalibrasyon degil, iyi bilinen bir atmosfer ozelligi.
const airglowLayerHeightKm = 90.0;

/// Dunya yaricapi, km.
const earthRadiusKm = 6378.0;

/// Van Rhijn fonksiyonu: hava parildamasi katmanindaki yol uzamasi.
///
///     V(z) = 1 / sqrt(1 - (R/(R+h))^2 · sin^2 z)
///
/// Basucunda 1, ufka dogru buyur. Duz `sec z` yaklasimindan farkli:
/// katman sonlu yukseklikte oldugu icin ufukta bile SONLU kalir
/// (~11.6), sonsuza gitmez.
double vanRhijnFactor(
  double altitudeDegrees, {
  double layerHeightKm = airglowLayerHeightKm,
}) {
  final z = toRadians(90.0 - altitudeDegrees.clamp(-5.0, 90.0));
  final ratio = earthRadiusKm / (earthRadiusKm + layerHeightKm);
  final inner = 1.0 - ratio * ratio * math.pow(math.sin(z), 2);
  if (inner <= 0) return double.infinity;
  return 1.0 / math.sqrt(inner);
}

/// Basucu fonundan verilen yukseklikteki fona, kadir/arcsec^2.
///
/// Iki etki birlikte:
///   - Van Rhijn: yol uzuyor, parlaklik ARTIYOR.
///   - Sonum: o isik atmosferden geciyor, ZAYIFLIYOR.
///
///     I(z)/I(zenit) = V(z) · 10^(-0.4·k·(X-1))
///
/// Sonum katsayisi [extinctionCoefficient] olculmemisse hesap
/// yapilmaz: sonum terimi olmadan gradyan yalnizca yariya kadar
/// dogru olurdu ve ufka dogru sistematik olarak fazla parlak cikardi.
Radiometric skyBrightnessAtAltitude({
  required double zenithMagPerSquareArcsec,
  required double altitudeDegrees,
  Measured? extinctionCoefficient,
  double layerHeightKm = airglowLayerHeightKm,
}) {
  if (extinctionCoefficient == null) {
    return RadiometricGap.single(extinctionCoefficientMissing);
  }
  final v = vanRhijnFactor(altitudeDegrees, layerHeightKm: layerHeightKm);
  if (!v.isFinite) {
    return const RadiometricValue(double.negativeInfinity, 'kadir/arcsec^2');
  }
  final x = airmassKastenYoung(altitudeDegrees);
  final extinctionFactor = math.pow(
    10,
    -0.4 * extinctionCoefficient.value * (x - 1.0),
  );
  final ratio = v * extinctionFactor;
  // Parlaklik orani kadire: daha parlak = daha KUCUK kadir.
  final deltaMag = -2.5 * (math.log(ratio) / math.ln10);
  return RadiometricValue(
    zenithMagPerSquareArcsec + deltaMag,
    'kadir/arcsec^2',
  );
}

/// Yapay isik parlamasi — sehir yonunde fon artisi.
const artificialGlowMissing = MissingQuantity(
  name: 'yapay isik parlamasi',
  symbol: 'glow',
  unit: 'kadir (yone ve yukseklige bagli)',
  comesFrom: 'olcum — sehir yonunde ve karsisinda fon karesi',
  why:
      'Sehir parlamasi yone, mesafeye, arazi engeline ve o gecenin '
      'nemine bagli. Iki komsu tepede bile farkli olur. Modellenebilir '
      'bir sey degil, olculur: sehre bakan ve sirtini donen iki fon '
      'karesinin farki dogrudan bu buyuklugu verir.',
);

/// Basucu fonu ve yukseklik gradyanindan birlesik fon.
///
/// Yapay parlama verilmemisse yalnizca dogal gradyan uygulanir ve
/// sonuc **iyimser** kalir — sehir yonunde gercek fon daha parlaktir.
/// Bu, sessiz bir hata degil bilincli bir alt sinir; arayuz bunu
/// belirtmeli.
Radiometric skyBrightnessAt({
  required double zenithMagPerSquareArcsec,
  required double altitudeDegrees,
  required double azimuthDegrees,
  Measured? extinctionCoefficient,
  SkyGlow? artificialGlow,
}) {
  final natural = skyBrightnessAtAltitude(
    zenithMagPerSquareArcsec: zenithMagPerSquareArcsec,
    altitudeDegrees: altitudeDegrees,
    extinctionCoefficient: extinctionCoefficient,
  );
  final glow = artificialGlow;
  if (glow == null) return natural;
  return natural.map(
    (mag) => mag - glow.magnitudeBoostAt(altitudeDegrees, azimuthDegrees),
  );
}

/// Olculmus yapay parlama profili.
///
/// Basit model: sehir yonunde en guclu, yuksege dogru zayiflayan bir
/// artis. Karmasik bir sacilma modeli yerine **olculen iki sayiyi**
/// tasiyor — cunku bu buyuklugun sekli de yere gore degisiyor ve
/// varsayilan bir sekil uydurmak, sayiyi uydurmak kadar yanlis.
class SkyGlow {
  /// Sehrin yonu, azimut derece.
  final double azimuthDegrees;

  /// Ufka yakin, sehir yonunde fon artisi, kadir.
  final Measured horizonBoostMagnitudes;

  /// Artisin yariya dustugu yukseklik, derece.
  final double halfHeightDegrees;

  const SkyGlow({
    required this.azimuthDegrees,
    required this.horizonBoostMagnitudes,
    this.halfHeightDegrees = 20.0,
  });

  /// Verilen yon icin parlaklik artisi, kadir. Sifir = etki yok.
  double magnitudeBoostAt(double altitude, double azimuth) {
    if (altitude <= 0) return horizonBoostMagnitudes.value;
    final heightFactor = math.pow(0.5, altitude / halfHeightDegrees) as double;
    // Yon: sehre bakarken tam etki, sirtini donunce ucte bir. Sifir
    // degil — parlama gokyuzunun tamamina sacilir.
    final delta = angularDifferenceDegrees(azimuth, azimuthDegrees).abs();
    final directionFactor = 0.33 + 0.67 * math.cos(toRadians(delta / 2));
    return horizonBoostMagnitudes.value * heightFactor * directionFactor;
  }
}
