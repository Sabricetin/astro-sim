import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

/// Referans degerler: Meeus, *Astronomical Algorithms*, 2. baski, Bolum 12,
/// ornek 12.a ve 12.b. Bagimsiz, elle hesaplanmis degerlerdir.
void main() {
  // 1987 Nisan 10, 0h UT
  const jd12a = 2446895.5;
  const gmst12aHours = 13.0 + 10.0 / 60.0 + 46.3668 / 3600.0;

  // 1987 Nisan 10, 19h21m00s UT
  const jd12b = 2446896.30625;
  const gmst12bHours = 8.0 + 34.0 / 60.0 + 57.0896 / 3600.0;

  group('GMST — Meeus referans degerleri', () {
    test('ornek 12.a: 1987-04-10 00:00 UT', () {
      // Tolerans 1e-6 saat = 3.6 milisaniye zaman = 0.000015 derece konum.
      expect(
        greenwichMeanSiderealTimeHours(jd12a),
        closeTo(gmst12aHours, 1e-6),
      );
      expect(
        formatHms(greenwichMeanSiderealTimeHours(jd12a), decimals: 4),
        '13h10m46.3668s',
      );
    });

    test('ornek 12.b: 1987-04-10 19:21:00 UT (gun ici kesirli an)', () {
      expect(
        greenwichMeanSiderealTimeHours(jd12b),
        closeTo(gmst12bHours, 1e-6),
      );
      expect(
        formatHms(greenwichMeanSiderealTimeHours(jd12b), decimals: 4),
        '8h34m57.0896s',
      );
    });

    test('DateTime uzerinden ayni sonuc', () {
      expect(
        gmstFromUtc(DateTime.utc(1987, 4, 10)),
        closeTo(hoursToDegrees(gmst12aHours), 1e-5),
      );
      expect(
        gmstFromUtc(DateTime.utc(1987, 4, 10, 19, 21)),
        closeTo(hoursToDegrees(gmst12bHours), 1e-5),
      );
    });

    test('cikti her zaman [0, 360) icinde', () {
      for (var i = -20000; i <= 20000; i += 137) {
        final g = greenwichMeanSiderealTimeDegrees(j2000 + i.toDouble());
        expect(g, greaterThanOrEqualTo(0.0));
        expect(g, lessThan(360.0));
      }
    });
  });

  group('GMST — fiziksel tutarlilik', () {
    test('yildiz gunu 23h56m04.09s (gunes gununden ~4 dakika kisa)', () {
      // Bir yildiz gunu = gokyuzunun 360 derece donmesi icin gecen sure.
      const siderealDaySeconds = 86164.0905;
      final start = greenwichMeanSiderealTimeDegrees(j2000);
      final after = greenwichMeanSiderealTimeDegrees(
        j2000 + siderealDaySeconds / Duration.secondsPerDay,
      );
      // Tam tur atip ayni yere donmeli.
      expect(normalizeDegreesSigned(after - start).abs(), lessThan(0.001));
    });

    test('bir gunes gununde GMST 360.9856 derece ilerler', () {
      final a = greenwichMeanSiderealTimeDegrees(j2000);
      final b = greenwichMeanSiderealTimeDegrees(j2000 + 1.0);
      // 360'i asan kisim: gunde ~0.9856 derece kayma. Yildizlarin her gece
      // ~4 dakika erken dogmasinin sebebi bu.
      expect(normalizeDegrees(b - a), closeTo(0.98565, 1e-4));
    });

    test('bir saat UT, 15.041 derece yildiz zamani ilerletir', () {
      final a = greenwichMeanSiderealTimeDegrees(j2000);
      final b = greenwichMeanSiderealTimeDegrees(j2000 + 1.0 / 24.0);
      expect(normalizeDegrees(b - a), closeTo(360.98564736629 / 24.0, 1e-6));
    });
  });

  group('LST — boylam dogu pozitif', () {
    test('+15 derece boylam, GMST\'yi tam 1 saat ileri alir', () {
      final gmst = greenwichMeanSiderealTimeDegrees(jd12b);
      final lst = localMeanSiderealTimeDegrees(jd12b, 15.0);
      expect(normalizeDegrees(lst - gmst), closeTo(15.0, 1e-9));
      expect(
        localMeanSiderealTimeHours(jd12b, 15.0),
        closeTo(
          normalizeHours(greenwichMeanSiderealTimeHours(jd12b) + 1.0),
          1e-9,
        ),
      );
    });

    test('bati boylam (negatif) yildiz zamanini geri alir', () {
      final gmst = greenwichMeanSiderealTimeDegrees(jd12b);
      final lst = localMeanSiderealTimeDegrees(jd12b, -75.0); // New York civari
      expect(normalizeDegreesSigned(lst - gmst), closeTo(-75.0, 1e-9));
    });

    test('Greenwich (0 boylam) GMST ile ayni', () {
      expect(
        localMeanSiderealTimeDegrees(jd12b, 0.0),
        closeTo(greenwichMeanSiderealTimeDegrees(jd12b), 1e-12),
      );
    });

    test('Gaziantep, dogu pozitif isaretiyle', () {
      // Isaret ters olsaydi fark boylamin iki kati = ~74.8 derece olurdu.
      // Bu test o hatayi yakalar.
      const gaziantepLongitude = 37.38;
      final gmst = greenwichMeanSiderealTimeDegrees(jd12b);
      final lst = localMeanSiderealTimeDegrees(jd12b, gaziantepLongitude);
      expect(
        normalizeDegreesSigned(lst - gmst),
        closeTo(gaziantepLongitude, 1e-9),
      );
    });

    test('cikti her zaman [0, 360) icinde', () {
      for (final lon in [-180.0, -74.0, 0.0, 37.38, 179.9]) {
        final lst = localMeanSiderealTimeDegrees(jd12b, lon);
        expect(lst, greaterThanOrEqualTo(0.0));
        expect(lst, lessThan(360.0));
      }
    });
  });

  group('saat acisi', () {
    test('cisim meridyendeyken sifir', () {
      const lst = 197.69319506;
      expect(hourAngleDegrees(lst, lst), closeTo(0.0, 1e-12));
    });

    test('isaret sozlesmesi: negatif = doguda/yukseliyor', () {
      // RA, LST'den buyukse cisim henuz meridyene varmamistir.
      expect(hourAngleDegrees(100.0, 130.0), closeTo(-30.0, 1e-12));
      // RA, LST'den kucukse meridyeni gecmistir.
      expect(hourAngleDegrees(130.0, 100.0), closeTo(30.0, 1e-12));
    });

    test('her zaman [-180, 180) araliginda', () {
      expect(hourAngleDegrees(10.0, 350.0), closeTo(20.0, 1e-12));
      expect(hourAngleDegrees(350.0, 10.0), closeTo(-20.0, 1e-12));
    });
  });
}
