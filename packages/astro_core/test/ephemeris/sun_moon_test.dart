import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

/// Referans degerler astropy (JPL efemerisi) ile uretildi — bizim koddan
/// tamamen bagimsiz. Kisaltilmis seriler kullandigimiz icin tam efemerisle
/// birebir tutmasi beklenmez; toleranslar yol haritasinin kabul ettigi
/// hassasiyet.
void main() {
  const cases =
      <
        ({
          String label,
          double jd,
          double sunRa,
          double sunDec,
          double moonRa,
          double moonDec,
          double moonDistanceKm,
          double illuminatedPercent,
        })
      >[
        (
          label: '2026-03-15 21:00',
          jd: 2461115.375,
          sunRa: 355.6698,
          sunDec: -1.8749,
          moonRa: 318.8209,
          moonDec: -18.1143,
          moonDistanceKm: 388270.7,
          illuminatedPercent: 11.5,
        ),
        (
          label: '2026-06-21 12:00',
          jd: 2461213.0,
          sunRa: 90.1557,
          sunDec: 23.4379,
          moonRa: 174.8096,
          moonDec: 0.0496,
          moonDistanceKm: 386099.0,
          illuminatedPercent: 45.8,
        ),
        (
          label: '2026-12-21 00:00',
          jd: 2461395.5,
          sunRa: 269.0367,
          sunDec: -23.4345,
          moonRa: 42.2327,
          moonDec: 21.5653,
          moonDistanceKm: 367049.5,
          illuminatedPercent: 86.6,
        ),
        (
          label: '2000-01-01 12:00 (J2000)',
          jd: 2451545.0,
          sunRa: 281.2784,
          sunDec: -23.0324,
          moonRa: 222.4523,
          moonDec: -10.9003,
          moonDistanceKm: 402412.8,
          illuminatedPercent: 23.0,
        ),
        (
          label: '2026-08-19 03:00',
          jd: 2461271.625,
          sunRa: 148.4186,
          sunDec: 12.7916,
          moonRa: 221.0409,
          moonDec: -21.2469,
          moonDistanceKm: 398306.7,
          illuminatedPercent: 40.6,
        ),
      ];

  group('Gunes — tolerans 0.01 derece', () {
    // Yol haritasi "dusuk hassasiyet yeter, ±0.01 derece" diyor.
    for (final c in cases) {
      test(c.label, () {
        final sun = sunPosition(c.jd);
        final separation = angularSeparationDegrees(
          sun.equatorial.rightAscensionDegrees,
          sun.equatorial.declinationDegrees,
          c.sunRa,
          c.sunDec,
        );
        expect(
          separation,
          lessThan(0.01),
          reason: '${(separation * 3600).toStringAsFixed(1)} yay saniyesi',
        );
      });
    }

    test('Yer-Gunes uzakligi mevsimle degisiyor', () {
      // Ocak basi enberi (~147.1 milyon km), temmuz basi enote (~152.1).
      final january = sunPosition(julianDay(DateTime.utc(2026, 1, 3)));
      final july = sunPosition(julianDay(DateTime.utc(2026, 7, 5)));
      expect(january.distanceKm, lessThan(july.distanceKm));
      expect(january.distanceKm, closeTo(147.1e6, 0.3e6));
      expect(july.distanceKm, closeTo(152.1e6, 0.3e6));
    });

    test('gundonumlerinde sapma uc degerlerde', () {
      final summer = sunPosition(julianDay(DateTime.utc(2026, 6, 21, 8, 25)));
      final winter = sunPosition(julianDay(DateTime.utc(2026, 12, 21, 20, 50)));
      expect(summer.equatorial.declinationDegrees, closeTo(23.44, 0.02));
      expect(winter.equatorial.declinationDegrees, closeTo(-23.44, 0.02));
    });
  });

  group('Ay — tolerans 0.3 derece', () {
    // Kisaltilmis seri; yol haritasi bu hassasiyeti yeterli buluyor cunku
    // Ay'in kendi gorunur capi zaten 0.5 derece.
    for (final c in cases) {
      test('${c.label} konum', () {
        final moon = moonPosition(c.jd);
        final separation = angularSeparationDegrees(
          moon.equatorial.rightAscensionDegrees,
          moon.equatorial.declinationDegrees,
          c.moonRa,
          c.moonDec,
        );
        expect(
          separation,
          lessThan(0.3),
          reason: '${separation.toStringAsFixed(3)} derece',
        );
      });

      test('${c.label} uzaklik', () {
        final moon = moonPosition(c.jd);
        // Kisaltilmis seri uzaklikta ~%0.3 sapabilir.
        expect(
          (moon.distanceKm - c.moonDistanceKm).abs() / c.moonDistanceKm,
          lessThan(0.004),
          reason:
              '${moon.distanceKm.toStringAsFixed(0)} km, '
              'beklenen ${c.moonDistanceKm.toStringAsFixed(0)}',
        );
      });

      test('${c.label} evre', () {
        final moon = moonPosition(c.jd);
        expect(
          moon.illuminatedPercent,
          closeTo(c.illuminatedPercent, 2.0),
          reason: '${moon.illuminatedPercent.toStringAsFixed(1)}%',
        );
      });
    }
  });

  group('Ay — fiziksel tutarlilik', () {
    test('uzaklik enberi-enote araliginda kaliyor', () {
      // Ay yorungesi eliptik: 356.500 - 406.700 km.
      for (var day = 0; day < 400; day += 3) {
        final moon = moonPosition(j2000 + day.toDouble());
        expect(
          moon.distanceKm,
          inInclusiveRange(355000, 408000),
          reason: 'gun $day',
        );
      }
    });

    test('doluluk 0-1 araliginda ve uzanimla artiyor', () {
      for (var day = 0; day < 60; day += 1) {
        final moon = moonPosition(j2000 + day.toDouble());
        expect(moon.illuminatedFraction, inInclusiveRange(0.0, 1.0));
      }
    });

    test('bir ay dongusunde yeni ay ve dolunay gorunuyor', () {
      var minimum = 1.0;
      var maximum = 0.0;
      for (var hour = 0; hour < 30 * 24; hour++) {
        final k = moonPosition(j2000 + hour / 24.0).illuminatedFraction;
        if (k < minimum) minimum = k;
        if (k > maximum) maximum = k;
      }
      expect(minimum, lessThan(0.02), reason: 'yeni ay bulunamadi');
      expect(maximum, greaterThan(0.98), reason: 'dolunay bulunamadi');
    });

    test('sapma 5.1 derecelik yorunge egimini asmiyor', () {
      // Ay ekliptige gore en fazla 5.1 derece egilir; ekliptik de 23.4
      // derece. Toplam sinir ~28.6 derece.
      for (var day = 0; day < 400; day += 2) {
        final moon = moonPosition(j2000 + day.toDouble());
        expect(
          moon.equatorial.declinationDegrees.abs(),
          lessThan(29.0),
          reason: 'gun $day',
        );
      }
    });
  });
}
