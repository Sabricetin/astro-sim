import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  final gaziantep = Observer(
    latitudeDegrees: 37.0662,
    longitudeEastDegrees: 37.3833,
    elevationMeters: 850,
  );

  /// Galaktik merkez — projenin baslik hedefi.
  final galacticCenter = Equatorial.fromHours(
    rightAscensionHours: 17 + 45 / 60 + 40.0 / 3600,
    declinationDegrees: -(29 + 0 / 60 + 28.0 / 3600),
  );

  group('galaktik merkez, yaz gecesi', () {
    late NightPlan plan;

    setUpAll(() {
      plan = planNight(
        target: galacticCenter,
        observer: gaziantep,
        aroundUtc: DateTime.utc(2026, 7, 15, 22),
      );
    });

    test('cekim penceresi bulunuyor', () {
      expect(plan.best, isNotNull);
      expect(plan.best!.duration.inMinutes, greaterThan(30));
    });

    test('pencere hem karanlik hem hedef yeterince yuksek', () {
      final window = plan.best!;
      for (final s in plan.samples) {
        if (!window.contains(s.utc)) continue;
        expect(s.isDark, isTrue, reason: '${s.utc}');
        expect(
          s.targetAltitudeDegrees,
          greaterThanOrEqualTo(20.0),
          reason: '${s.utc}',
        );
      }
    });

    test('pencere karanlik penceresinin icinde kaliyor', () {
      final window = plan.best!;
      expect(plan.darkness.contains(window.start), isTrue);
      expect(plan.darkness.contains(window.end), isTrue);
    });

    test('hedef 24 dereceyi asmiyor — projenin temel kisiti', () {
      // maximumAltitudeDegrees ile ayni sonucu vermeli.
      final peak = plan.samples
          .map((s) => s.targetAltitudeDegrees)
          .reduce((a, b) => a > b ? a : b);
      final theoretical = maximumAltitudeDegrees(
        declinationDegrees: galacticCenter.declinationDegrees,
        latitudeDegrees: gaziantep.latitudeDegrees,
      );
      expect(peak, closeTo(theoretical, 0.2));
      expect(peak, lessThan(24.5));
    });

    test('pencere dar — 20 derece esigi zorlukla asiliyor', () {
      // Zirve 24 derecede oldugu icin 20 derecenin uzerinde gecirilen
      // sure kisa. Bu, projenin var olma sebebinin sayisal ifadesi:
      // "gitmeden once pozunu dogrula" cunku pencere gercekten dar.
      expect(plan.best!.duration.inHours, lessThan(4));
    });
  });

  group('esik etkisi', () {
    test('esik yukseldikce pencere kisaliyor', () {
      Duration windowFor(double minAltitude) =>
          planNight(
            target: galacticCenter,
            observer: gaziantep,
            aroundUtc: DateTime.utc(2026, 7, 15, 22),
            minimumAltitudeDegrees: minAltitude,
          ).best?.duration ??
          Duration.zero;

      expect(windowFor(10), greaterThan(windowFor(20)));
      expect(windowFor(20), greaterThan(windowFor(23)));
    });

    test('erisilemez esikte pencere yok', () {
      final plan = planNight(
        target: galacticCenter,
        observer: gaziantep,
        aroundUtc: DateTime.utc(2026, 7, 15, 22),
        minimumAltitudeDegrees: 40, // zirve 24 — asla olmaz
      );
      expect(plan.best, isNull);
      expect(plan.shootingWindows, isEmpty);
    });
  });

  group('Ay etkisi', () {
    test('dolunay gecesi ceza yuksek, yeni ay gecesi dusuk', () {
      // 2026 icinde bir dolunay ve bir yeni ay gecesi bul.
      double penaltyOn(DateTime night) => planNight(
        target: galacticCenter,
        observer: gaziantep,
        aroundUtc: night,
      ).worstMoonPenalty;

      var brightest = 0.0;
      var darkest = 99.0;
      for (var day = 0; day < 30; day++) {
        final p = penaltyOn(DateTime.utc(2026, 7, 1 + day, 22));
        if (p > brightest) brightest = p;
        if (p < darkest) darkest = p;
      }
      expect(brightest, greaterThan(1.0), reason: 'dolunay gecesi bulunamadi');
      expect(darkest, lessThan(0.2), reason: 'aysiz gece bulunamadi');
    });

    test('Ay dogus/batis anlari yakalaniyor', () {
      // Bir ay boyunca en az bir gecede Ay gece ortasinda doguyor olmali.
      var found = false;
      for (var day = 0; day < 30 && !found; day++) {
        final plan = planNight(
          target: galacticCenter,
          observer: gaziantep,
          aroundUtc: DateTime.utc(2026, 7, 1 + day, 22),
        );
        if (plan.moonRise != null) found = true;
      }
      expect(found, isTrue);
    });
  });

  group('yuksek enlem — karanlik yoksa pencere de yok', () {
    test('Tromso yaz gecesi: pencere uretilmiyor', () {
      final plan = planNight(
        target: Equatorial(rightAscensionDegrees: 270, declinationDegrees: 60),
        observer: Observer(latitudeDegrees: 69.65, longitudeEastDegrees: 18.96),
        aroundUtc: DateTime.utc(2026, 6, 21, 23),
      );
      expect(plan.darkness.neverDark, isTrue);
      expect(plan.shootingWindows, isEmpty);
      expect(plan.best, isNull);
    });
  });

  group('ornekleme grafik icin kullanilabilir (T4.7)', () {
    test('dakika dakika ve zamanda artan', () {
      final plan = planNight(
        target: galacticCenter,
        observer: gaziantep,
        aroundUtc: DateTime.utc(2026, 7, 15, 22),
      );
      expect(plan.samples.length, greaterThan(900));
      for (var i = 1; i < plan.samples.length; i++) {
        expect(plan.samples[i].utc.isAfter(plan.samples[i - 1].utc), isTrue);
      }
    });

    test('yukseklik egrisi tek tepeli — hedef dogup batiyor', () {
      final plan = planNight(
        target: galacticCenter,
        observer: gaziantep,
        aroundUtc: DateTime.utc(2026, 7, 15, 22),
      );
      final altitudes = plan.samples
          .map((s) => s.targetAltitudeDegrees)
          .toList();
      var directionChanges = 0;
      for (var i = 2; i < altitudes.length; i++) {
        final before = altitudes[i - 1] - altitudes[i - 2];
        final after = altitudes[i] - altitudes[i - 1];
        if (before > 0 && after < 0) directionChanges++;
        if (before < 0 && after > 0) directionChanges++;
      }
      // 16 saatlik pencerede en fazla bir zirve ve bir dip.
      expect(directionChanges, lessThanOrEqualTo(2));
    });
  });
}
