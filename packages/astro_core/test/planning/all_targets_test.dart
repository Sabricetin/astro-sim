import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

/// Arayuzden secilebilen HER hedef icin plan hesabi patlamamali.
/// Kullanici Messier hedefi secince uygulama cokuyordu.
void main() {
  final gaziantep = Observer(
    latitudeDegrees: 37.0662,
    longitudeEastDegrees: 37.3833,
    elevationMeters: 850,
  );

  test('110 Messier nesnesinin hepsi icin plan uretilebiliyor', () {
    final failures = <String>[];
    for (final m in messierCatalog) {
      try {
        planNight(
          target: Equatorial(
            rightAscensionDegrees: m.rightAscensionDegrees,
            declinationDegrees: m.declinationDegrees,
          ),
          observer: gaziantep,
          aroundUtc: DateTime.utc(2026, 7, 15, 22),
        );
      } catch (e) {
        failures.add('${m.designation}: $e');
      }
    }
    expect(failures, isEmpty, reason: failures.take(5).join('\n'));
  });

  test('farkli tarihlerde de patlamiyor', () {
    final failures = <String>[];
    for (var day = 1; day <= 28; day++) {
      try {
        planNight(
          target: Equatorial(
            rightAscensionDegrees: messierCatalog[30].rightAscensionDegrees,
            declinationDegrees: messierCatalog[30].declinationDegrees,
          ),
          observer: gaziantep,
          aroundUtc: DateTime.utc(2026, 7, day, 22),
        );
      } catch (e) {
        failures.add('gun $day: $e');
      }
    }
    expect(failures, isEmpty, reason: failures.take(5).join('\n'));
  });

  test('hic gorunmeyen hedefte de patlamiyor', () {
    // M7 en guneydeki Messier: 18 dereceye cikiyor, 20 esiginin altinda.
    final m7 = messierCatalog[6];
    final plan = planNight(
      target: Equatorial(
        rightAscensionDegrees: m7.rightAscensionDegrees,
        declinationDegrees: m7.declinationDegrees,
      ),
      observer: gaziantep,
      aroundUtc: DateTime.utc(2026, 7, 15, 22),
    );
    expect(plan.best, isNull);
    expect(plan.worstMoonPenalty, 0.0);
    expect(plan.moonIlluminatedFraction, isNotNaN);
  });
}
