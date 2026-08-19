/// T4.8 — Gece plani: karanlik, hedef yuksekligi ve Ay etkisinin birlesimi.
///
/// Yol haritasinin cikis kriteri, aracin su cumleyi kurabilmesi:
///
///   "Bu gece galaktik merkez icin pencere 01:20-03:40.
///    Ay 02:50'de doguyor, %31 dolu — sorun degil."
///
/// Bu dosya o cumlenin arkasindaki hesap. Parcalar (Gunes, Ay, koordinat,
/// parlaklik) ayri ayri dogrulandi; burada birlestiriliyor.
///
/// **Neden bu faz kritik:** Rakiplerin cogu bu parcalari ayri ayri
/// veriyor. Tek ekranda birlestirmek asil deger.
library;

import '../coords/horizontal.dart';
import '../coords/types.dart';
import '../ephemeris/moon.dart';
import '../ephemeris/twilight.dart';
import '../math/angles.dart';
import '../radiometry/sky_brightness.dart';
import '../time/julian_day.dart';
import '../time/sidereal_time.dart';

/// Kapali zaman araligi.
class TimeRange {
  final DateTime start;
  final DateTime end;

  const TimeRange(this.start, this.end);

  Duration get duration => end.difference(start);

  bool contains(DateTime t) => !t.isBefore(start) && !t.isAfter(end);

  @override
  String toString() =>
      '${_hhmm(start)}-${_hhmm(end)} (${duration.inMinutes} dk)';

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}

/// Bir an icin hesaplanmis kosullar.
class SkyConditions {
  final DateTime utc;
  final double targetAltitudeDegrees;
  final double moonAltitudeDegrees;
  final double moonIlluminatedFraction;

  /// Ay ile hedef arasindaki gorunur aci, derece.
  final double moonSeparationDegrees;

  /// Ay'in fonu kac kadir parlattigi. Sifir = Ay etkisi yok.
  final double moonPenaltyMagnitudes;

  final bool isDark;

  const SkyConditions({
    required this.utc,
    required this.targetAltitudeDegrees,
    required this.moonAltitudeDegrees,
    required this.moonIlluminatedFraction,
    required this.moonSeparationDegrees,
    required this.moonPenaltyMagnitudes,
    required this.isDark,
  });
}

/// Bir gecelik cekim plani.
class NightPlan {
  final DarknessWindow darkness;

  /// Dakika dakika hesaplanmis kosullar. Yukseklik/zaman grafigi (T4.7)
  /// bunu dogrudan cizer.
  final List<SkyConditions> samples;

  /// Hedefin esik yuksekliginin uzerinde OLDUGU ve gokyuzunun karanlik
  /// oldugu araliklar.
  final List<TimeRange> shootingWindows;

  /// En uzun cekim penceresi. Hic yoksa null.
  final TimeRange? best;

  /// Ay'in ufkun uzerine ciktigi an (gece icinde). Yoksa null.
  final DateTime? moonRise;

  /// Ay'in battigi an. Yoksa null.
  final DateTime? moonSet;

  const NightPlan({
    required this.darkness,
    required this.samples,
    required this.shootingWindows,
    required this.best,
    required this.moonRise,
    required this.moonSet,
  });

  /// Gecenin ortasindaki Ay dolulugu — arayuzde tek sayiyla ozet.
  double get moonIlluminatedFraction => samples.isEmpty
      ? 0.0
      : samples[samples.length ~/ 2].moonIlluminatedFraction;

  /// En iyi pencere boyunca goruklen en kotu Ay cezasi, kadir.
  ///
  /// Karar burada verilir: 0.5 kadirin altinda Ay pratik olarak
  /// onemsizdir, 1.5 uzeri difuz hedefleri bitirir.
  double get worstMoonPenalty {
    final window = best;
    if (window == null) return 0.0;
    var worst = 0.0;
    for (final s in samples) {
      if (!window.contains(s.utc)) continue;
      if (s.moonPenaltyMagnitudes > worst) worst = s.moonPenaltyMagnitudes;
    }
    return worst;
  }
}

/// Bir gece icin hedefin cekim penceresini hesaplar.
///
/// [minimumAltitudeDegrees] hedefin en az ne kadar yukselmesi gerektigi.
/// Varsayilan 20 derece: altinda hava kutlesi 3'u asar ve sonum ciddi
/// olur (yol haritasi Faz 4.8).
///
/// [baseSkyMagPerSquareArcsec] Ay'siz fon parlakligi. Bortle sinifindan
/// veya VIIRS'ten gelir; varsayilan iyi bir kirsal gokyuzu.
NightPlan planNight({
  required Equatorial target,
  required Observer observer,
  required DateTime aroundUtc,
  double minimumAltitudeDegrees = 20.0,
  double baseSkyMagPerSquareArcsec = 21.5,
  Duration step = const Duration(minutes: 1),
}) {
  final darkness = darknessWindow(aroundUtc: aroundUtc, observer: observer);

  // Ornekleme araligi: karanlik penceresi varsa onun etrafi, yoksa
  // yerel gecenin tamami. Grafik (T4.7) icin karanligin disina da bir
  // miktar tasiyoruz — kullanici hedefin ne zaman yukselmeye basladigini
  // gormek ister.
  final centre = darkness.start != null && darkness.end != null
      ? darkness.start!.add(darkness.duration ~/ 2)
      : aroundUtc;
  final from = centre.subtract(const Duration(hours: 8));
  final sampleCount = (const Duration(hours: 16).inMinutes / step.inMinutes)
      .round();

  final samples = <SkyConditions>[];
  DateTime? moonRise;
  DateTime? moonSet;
  bool? previousMoonUp;

  for (var i = 0; i <= sampleCount; i++) {
    final t = from.add(step * i);
    final jd = julianDay(t);
    final lst = localMeanSiderealTimeDegrees(jd, observer.longitudeEastDegrees);

    final targetHorizontal = equatorialToHorizontal(
      equatorial: target,
      observer: observer,
      localSiderealTimeDegrees: lst,
    );
    final moon = moonPosition(jd);
    final moonHorizontal = equatorialToHorizontal(
      equatorial: moon.equatorial,
      observer: observer,
      localSiderealTimeDegrees: lst,
    );

    final separation = angularSeparationDegrees(
      targetHorizontal.azimuthDegrees,
      targetHorizontal.altitudeDegrees,
      moonHorizontal.azimuthDegrees,
      moonHorizontal.altitudeDegrees,
    );

    final penalty = moonBrightnessPenaltyMagnitudes(
      baseSkyMagPerSquareArcsec: baseSkyMagPerSquareArcsec,
      moonContributionNanoLamberts: moonSkyBrightnessNanoLamberts(
        moonPhaseAngleDegrees: moon.phaseAngleDegrees,
        moonAltitudeDegrees: moonHorizontal.altitudeDegrees,
        targetAltitudeDegrees: targetHorizontal.altitudeDegrees,
        separationDegrees: separation,
      ),
    );

    final moonUp = moonHorizontal.altitudeDegrees > 0;
    if (previousMoonUp != null && moonUp != previousMoonUp) {
      if (moonUp) {
        moonRise ??= t;
      } else {
        moonSet ??= t;
      }
    }
    previousMoonUp = moonUp;

    samples.add(
      SkyConditions(
        utc: t,
        targetAltitudeDegrees: targetHorizontal.altitudeDegrees,
        moonAltitudeDegrees: moonHorizontal.altitudeDegrees,
        moonIlluminatedFraction: moon.illuminatedFraction,
        moonSeparationDegrees: separation,
        moonPenaltyMagnitudes: penalty,
        isDark: darkness.contains(t),
      ),
    );
  }

  // Kosullarin ayni anda saglandigi kesintisiz araliklari cikar.
  //
  // Pencere, kosulun bozuldugu ornekte DEGIL bir onceki ornekte kapanir.
  // Aksi halde bildirilen aralik, hedefin esigin altina dustugu bir
  // dakikayi icerir. Planlama aracinda ihtiyatli taraf dogru taraf:
  // "cekebilirsin" deyip cekilemeyen bir dakika vermektense, gercek
  // pencereyi bir ornekleme adimi kadar kisa bildirmek yeglenir.
  final windows = <TimeRange>[];
  DateTime? openedAt;
  DateTime? lastGood;
  for (final s in samples) {
    final ok = s.isDark && s.targetAltitudeDegrees >= minimumAltitudeDegrees;
    if (ok) {
      openedAt ??= s.utc;
      lastGood = s.utc;
    } else if (openedAt != null) {
      windows.add(TimeRange(openedAt, lastGood!));
      openedAt = null;
      lastGood = null;
    }
  }
  if (openedAt != null && lastGood != null) {
    windows.add(TimeRange(openedAt, lastGood));
  }

  TimeRange? best;
  for (final w in windows) {
    if (best == null || w.duration > best.duration) best = w;
  }

  return NightPlan(
    darkness: darkness,
    samples: samples,
    shootingWindows: windows,
    best: best,
    moonRise: moonRise,
    moonSet: moonSet,
  );
}
