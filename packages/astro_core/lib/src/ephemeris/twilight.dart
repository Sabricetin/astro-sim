/// T4.3 — Alacakaranlik ve astronomik karanlik penceresi.
///
/// Gunes ufkun altina indikten sonra gokyuzu hemen kararmaz. Uc esik
/// tanimlidir; astro fotografcilikta anlamli olan sonuncusudur.
library;

import '../coords/types.dart';
import '../time/julian_day.dart';
import 'sun.dart';

/// Alacakaranlik esikleri: Gunes'in ufkun ne kadar altinda oldugu, derece.
enum TwilightPhase {
  /// Gunes −6 derecenin ustunde: disarida okunabilir.
  civil(-6.0, 'Sivil alacakaranlik'),

  /// −12 derece: ufuk cizgisi hala secilir.
  nautical(-12.0, 'Denizci alacakaranligi'),

  /// −18 derece: gokyuzu tamamen karanlik. Astro fotografciligin sarti.
  astronomical(-18.0, 'Astronomik karanlik');

  final double sunAltitudeDegrees;
  final String label;

  const TwilightPhase(this.sunAltitudeDegrees, this.label);
}

/// Bir gece icin karanlik penceresi.
class DarknessWindow {
  /// Gunes esigin altina indigi an. Hic inmiyorsa null.
  final DateTime? start;

  /// Gunes esigin ustune ciktigi an. Hic cikmiyorsa null.
  final DateTime? end;

  /// Gunes tum gun esigin ustunde kaldi — hic karanlik olmadi.
  ///
  /// Yuksek enlemlerde yazin olur. Kullaniciya "bu gece cekim yapilamaz"
  /// demenin dogru yolu, bos bir pencere degil bu bayrak.
  final bool neverDark;

  /// Gunes tum gun esigin altinda kaldi — surekli karanlik (kutup gecesi).
  final bool alwaysDark;

  final TwilightPhase phase;

  const DarknessWindow({
    required this.start,
    required this.end,
    required this.neverDark,
    required this.alwaysDark,
    required this.phase,
  });

  /// Pencerenin uzunlugu. Surekli karanlikta 24 saat, hic yoksa sifir.
  Duration get duration {
    if (alwaysDark) return const Duration(hours: 24);
    if (neverDark || start == null || end == null) return Duration.zero;
    return end!.difference(start!);
  }

  bool contains(DateTime utc) {
    if (alwaysDark) return true;
    if (neverDark || start == null || end == null) return false;
    return !utc.isBefore(start!) && !utc.isAfter(end!);
  }
}

/// Verilen gece icin karanlik penceresini bulur.
///
/// [aroundUtc] gecenin herhangi bir ani; pencere bu anin cevresinde
/// aranir. Aramanin merkezine yerel gece yarisi alinir, boylece pencere
/// takvim gunune degil GECEYE baglanir — 23:00'te bakan biri ile
/// 01:00'de bakan biri ayni pencereyi gorur.
///
/// Cozunurluk 1 saniye. Once 5 dakikalik adimlarla isaret degisimi
/// aranir, sonra ikiye bolme ile daraltilir.
DarknessWindow darknessWindow({
  required DateTime aroundUtc,
  required Observer observer,
  TwilightPhase phase = TwilightPhase.astronomical,
}) {
  // Aramayi YEREL GECE YARISI etrafinda merkezle. Takvim gunune baglamak
  // yanlis olurdu: 23:00'te soran ile 01:00'de soran ayni geceyi kastediyor
  // ama takvim gunleri farkli.
  //
  // Yontem: UTC'yi kaba yerel saate cevir, en yakin gece yarisini sec
  // (ogleden sonraysa gelecek, oncesiyse gecmis), sonra UTC'ye geri don.
  final offset = Duration(
    minutes: (observer.longitudeEastDegrees / 15.0 * 60).round(),
  );
  final localClock = aroundUtc.add(offset);
  final nearestLocalMidnight = DateTime.utc(
    localClock.year,
    localClock.month,
    localClock.day,
  ).add(localClock.hour >= 12 ? const Duration(days: 1) : Duration.zero);
  final centre = nearestLocalMidnight.subtract(offset);

  final from = centre.subtract(const Duration(hours: 12));
  const step = Duration(minutes: 5);
  final threshold = phase.sunAltitudeDegrees;

  double altitudeAt(DateTime t) =>
      sunAltitudeDegrees(jd: julianDay(t), observer: observer);

  DateTime? descending;
  DateTime? ascending;
  var previousTime = from;
  var previousBelow = altitudeAt(from) < threshold;
  final startedBelow = previousBelow;
  var everBelow = previousBelow;
  var everAbove = !previousBelow;

  for (var i = 1; i <= 24 * 12; i++) {
    final t = from.add(step * i);
    final below = altitudeAt(t) < threshold;
    if (below) {
      everBelow = true;
    } else {
      everAbove = true;
    }
    if (below != previousBelow) {
      final crossing = _bisect(previousTime, t, threshold, observer);
      if (below) {
        descending ??= crossing;
      } else {
        ascending ??= crossing;
      }
    }
    previousTime = t;
    previousBelow = below;
  }

  // Gece ortasinda basladiysak inis anini bir onceki aksamda arariz;
  // bu durumda pencerenin baslangici tarama araliginin disinda kalir.
  if (startedBelow && descending == null) {
    descending = _bisect(
      from.subtract(const Duration(hours: 6)),
      from,
      threshold,
      observer,
    );
  }

  return DarknessWindow(
    start: descending,
    end: ascending,
    neverDark: !everBelow,
    alwaysDark: !everAbove,
    phase: phase,
  );
}

/// Iki an arasindaki esik gecisini ikiye bolerek 1 saniyeye daraltir.
DateTime _bisect(
  DateTime before,
  DateTime after,
  double threshold,
  Observer observer,
) {
  var low = before;
  var high = after;
  final lowBelow =
      sunAltitudeDegrees(jd: julianDay(low), observer: observer) < threshold;
  while (high.difference(low) > const Duration(seconds: 1)) {
    final mid = low.add(high.difference(low) ~/ 2);
    final midBelow =
        sunAltitudeDegrees(jd: julianDay(mid), observer: observer) < threshold;
    if (midBelow == lowBelow) {
      low = mid;
    } else {
      high = mid;
    }
  }
  return high;
}
