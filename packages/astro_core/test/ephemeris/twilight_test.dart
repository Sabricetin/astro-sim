import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  final gaziantep = Observer(
    latitudeDegrees: 37.0662,
    longitudeEastDegrees: 37.3833,
  );
  // Tromso, Norvec — yazin hic kararmayan enlem.
  final tromso = Observer(latitudeDegrees: 69.65, longitudeEastDegrees: 18.96);
  // Kuzey Kutbu — kisin Gunes surekli -18 derecenin altinda.
  final northPole = Observer(latitudeDegrees: 89.9, longitudeEastDegrees: 0);

  group('Gaziantep — normal gece', () {
    test('kis gecesi uzun karanlik penceresi veriyor', () {
      final window = darknessWindow(
        aroundUtc: DateTime.utc(2026, 1, 15, 22),
        observer: gaziantep,
      );
      expect(window.neverDark, isFalse);
      expect(window.alwaysDark, isFalse);
      expect(window.start, isNotNull);
      expect(window.end, isNotNull);
      // Ocak ortasinda 37 kuzeyde astronomik karanlik ~11-12 saat.
      expect(window.duration.inMinutes, inInclusiveRange(10 * 60, 13 * 60));
    });

    test('yaz gecesi kis gecesinden kisa', () {
      final winter = darknessWindow(
        aroundUtc: DateTime.utc(2026, 1, 15, 22),
        observer: gaziantep,
      );
      final summer = darknessWindow(
        aroundUtc: DateTime.utc(2026, 6, 21, 22),
        observer: gaziantep,
      );
      expect(summer.duration, lessThan(winter.duration));
      // Haziranda bile karanlik oluyor — Gaziantep yeterince guneyde.
      expect(summer.neverDark, isFalse);
      expect(summer.duration.inMinutes, greaterThan(4 * 60));
    });

    test('pencere icinde Gunes gercekten esigin altinda', () {
      final window = darknessWindow(
        aroundUtc: DateTime.utc(2026, 1, 15, 22),
        observer: gaziantep,
      );
      final middle = window.start!.add(window.duration ~/ 2);
      final altitude = sunAltitudeDegrees(
        jd: julianDay(middle),
        observer: gaziantep,
      );
      expect(altitude, lessThan(-18.0));
      expect(window.contains(middle), isTrue);
    });

    test('pencere sinirlarinda Gunes tam esikte', () {
      final window = darknessWindow(
        aroundUtc: DateTime.utc(2026, 1, 15, 22),
        observer: gaziantep,
      );
      for (final t in [window.start!, window.end!]) {
        final altitude = sunAltitudeDegrees(
          jd: julianDay(t),
          observer: gaziantep,
        );
        // 1 saniye cozunurlukte esige oturmali.
        expect(altitude, closeTo(-18.0, 0.02), reason: '$t');
      }
    });

    test('gecenin hangi aninda sorulursa sorulsun ayni pencere', () {
      // Pencere takvim gunune degil GECEYE baglanmali: 23:00'te bakan
      // ile 01:00'de bakan ayni cevabi almali.
      final evening = darknessWindow(
        aroundUtc: DateTime.utc(2026, 1, 15, 21),
        observer: gaziantep,
      );
      final afterMidnight = darknessWindow(
        aroundUtc: DateTime.utc(2026, 1, 16, 1),
        observer: gaziantep,
      );
      expect(
        evening.start!.difference(afterMidnight.start!).inMinutes.abs(),
        lessThan(2),
      );
    });
  });

  group('esikler', () {
    test('sivil > denizci > astronomik pencere uzunlugu', () {
      Duration windowFor(TwilightPhase phase) => darknessWindow(
        aroundUtc: DateTime.utc(2026, 3, 15, 22),
        observer: gaziantep,
        phase: phase,
      ).duration;

      expect(
        windowFor(TwilightPhase.civil),
        greaterThan(windowFor(TwilightPhase.nautical)),
      );
      expect(
        windowFor(TwilightPhase.nautical),
        greaterThan(windowFor(TwilightPhase.astronomical)),
      );
    });
  });

  group('yuksek enlem — uc durumlar', () {
    test('Tromso yazin hic kararmiyor', () {
      final window = darknessWindow(
        aroundUtc: DateTime.utc(2026, 6, 21, 23),
        observer: tromso,
      );
      // Bos bir pencere degil, ACIK bir bayrak: "bu gece cekim yapilamaz".
      expect(window.neverDark, isTrue);
      expect(window.duration, Duration.zero);
    });

    test('Tromso kisin kutup gecesi ama surekli KARANLIK degil', () {
      // Kutup gecesi "Gunes dogmuyor" demek (yukseklik < 0). Astronomik
      // karanlik ise -18 derece esigi — bambaska bir sey. Tromso'de Gunes
      // aralikta ogleyin -3 dereceye kadar cikar, yani gun ortasinda
      // alacakaranlik yasanir. Ikisini karistirmak, kullaniciya "24 saat
      // cekim yapabilirsin" demek olurdu.
      final noon = sunAltitudeDegrees(
        jd: julianDay(DateTime.utc(2026, 12, 21, 11)),
        observer: tromso,
      );
      expect(noon, lessThan(0), reason: 'Gunes dogmamali');
      expect(noon, greaterThan(-18), reason: 'ama -18 esigini gecmeli');

      final window = darknessWindow(
        aroundUtc: DateTime.utc(2026, 12, 21, 22),
        observer: tromso,
      );
      expect(window.alwaysDark, isFalse);
      expect(window.duration.inHours, greaterThan(12));
    });

    test('Kuzey Kutbu kisin gercekten surekli karanlik', () {
      final window = darknessWindow(
        aroundUtc: DateTime.utc(2026, 12, 21, 12),
        observer: northPole,
      );
      expect(window.alwaysDark, isTrue);
      expect(window.duration, const Duration(hours: 24));
      expect(window.contains(DateTime.utc(2026, 12, 21, 12)), isTrue);
    });
  });
}
