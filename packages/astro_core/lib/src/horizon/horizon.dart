/// T7.4-7.6 — Ufuk profili.
///
/// "Konumu buldum ama onumde tepe varmis" — yol haritasinin
/// farklilastirici dedigi sey. Projenin ana hedefi (galaktik merkez,
/// ~24 derece) neredeyse her konumda bir sirt tarafindan kesilir, yani
/// bu bir luks degil ana senaryonun on kosulu.
///
/// **DEM verisi beklemiyoruz.** Yukseklik modeli (Copernicus GLO-30)
/// ileride otomatik profil uretecek, ama iki sebeple elle girilen ufuk
/// once geliyor:
///   1. Internet gerektirmiyor.
///   2. DEM agaclari, binalari ve duvari GOREMEZ. Sahada gozle olculen
///      ufuk cogu zaman daha dogrudur.
library;

import 'dart:math' as math;

import '../coords/types.dart';
import '../math/angles.dart';

/// Azimuta gore ufuk yuksekligi.
///
/// Ic temsil: [sampleCount] esit araliki ornek, 0 derecelik azimuttan
/// baslayarak. Aradaki degerler dogrusal olarak, **cember uzerinde
/// sarilarak** hesaplanir — 359 ile 1 derece arasi komsu, 358 derece
/// uzakta degil.
class Horizon {
  /// Ornek sayisi. 360 = derece basina bir ornek.
  static const sampleCount = 360;

  /// Her ornegin ufuk yuksekligi, derece. Uzunluk [sampleCount].
  final List<double> samples;

  /// Bu profilin nereden geldigi. Olcum mu, tahmin mi, DEM mi.
  final String source;

  const Horizon._(this.samples, this.source);

  /// Duz ufuk — engel yok.
  ///
  /// [altitudeDegrees] sifirdan buyuk verilirse her yonde ayni
  /// yukseklikte bir engel demektir (orn. duz ovada uzak agac hatti).
  factory Horizon.flat([double altitudeDegrees = 0.0, String? source]) =>
      Horizon._(
        List<double>.filled(sampleCount, altitudeDegrees),
        source ?? 'duz ufuk',
      );

  /// Elle girilen noktalardan profil uretir.
  ///
  /// [points] azimut -> yukseklik. Aradaki azimutlar dogrusal
  /// interpolasyonla dolduruluyor. Tek nokta verilirse profil her yerde
  /// o degere esitlenir.
  ///
  /// Sahada olcmenin pratik yolu: telefonun egim olcerini kullanip
  /// birkac yonde tepe acisini not etmek. Sekiz nokta (her 45 derecede
  /// bir) cogu yer icin yeterli.
  factory Horizon.fromPoints(
    Map<double, double> points, {
    String source = 'elle girildi',
  }) {
    if (points.isEmpty) return Horizon.flat(0, source);
    final entries =
        points.entries
            .map((e) => MapEntry(normalizeDegrees(e.key), e.value))
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    if (entries.length == 1) {
      return Horizon.flat(entries.first.value, source);
    }

    final out = List<double>.filled(sampleCount, 0);
    for (var i = 0; i < sampleCount; i++) {
      final az = i * 360.0 / sampleCount;
      // Bu azimutu saran iki nokta. Liste sirali; sonuncudan sonra
      // ilkine SARILIYOR — cember uzerinde calisiyoruz.
      var before = entries.last;
      var after = entries.first;
      for (var k = 0; k < entries.length; k++) {
        if (entries[k].key <= az) {
          before = entries[k];
          after = entries[(k + 1) % entries.length];
        }
      }
      if (az < entries.first.key) {
        before = entries.last;
        after = entries.first;
      }
      var span = after.key - before.key;
      if (span <= 0) span += 360.0;
      var offset = az - before.key;
      if (offset < 0) offset += 360.0;
      final t = span == 0 ? 0.0 : offset / span;
      out[i] = before.value + (after.value - before.value) * t;
    }
    return Horizon._(out, source);
  }

  /// Hazir ornek dizisinden (orn. DEM taramasi).
  factory Horizon.fromSamples(List<double> samples, {required String source}) {
    if (samples.length != sampleCount) {
      throw ArgumentError(
        'Ufuk profili $sampleCount ornek bekliyor, ${samples.length} geldi.',
      );
    }
    return Horizon._(List<double>.unmodifiable(samples), source);
  }

  /// Verilen azimutta ufkun yuksekligi, derece.
  double altitudeAt(double azimuthDegrees) {
    final az = normalizeDegrees(azimuthDegrees);
    final x = az * sampleCount / 360.0;
    final i0 = x.floor() % sampleCount;
    final i1 = (i0 + 1) % sampleCount;
    final t = x - x.floor();
    return samples[i0] + (samples[i1] - samples[i0]) * t;
  }

  /// Bu yon ufkun altinda mi kaliyor?
  bool blocks(Horizontal position) =>
      position.altitudeDegrees < altitudeAt(position.azimuthDegrees);

  /// Profilin en yuksek noktasi ve hangi azimutta.
  (double altitude, double azimuth) get highest {
    var best = 0, bestValue = samples[0];
    for (var i = 1; i < sampleCount; i++) {
      if (samples[i] > bestValue) {
        bestValue = samples[i];
        best = i;
      }
    }
    return (bestValue, best * 360.0 / sampleCount);
  }

  /// Profil duz mu — hicbir yerde engel yok mu?
  bool get isFlat => samples.every((s) => s.abs() < 1e-9);

  /// Ortalama ufuk yuksekligi. Kaba bir "ne kadar kapali" olcusu.
  double get meanAltitude => samples.reduce((a, b) => a + b) / sampleCount;

  /// Gokyuzunun ne kadarini kapatiyor, 0-1.
  ///
  /// Kure uzerindeki alan orani: ufuk yuksekligi h olan bir yonde
  /// kaybedilen dilim sin(h) ile orantili.
  double get blockedSkyFraction {
    var sum = 0.0;
    for (final s in samples) {
      sum += math.sin(toRadians(s.clamp(0.0, 90.0)));
    }
    return sum / sampleCount;
  }
}
