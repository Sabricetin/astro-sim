import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

/// Referans degerler: Meeus, *Astronomical Algorithms*, 2. baski, Bolum 7,
/// Tablo 7.A ve 7.B. Bunlar elle hesaplanmis, bagimsiz dogrulama degerleridir —
/// kendi kodumuzun ciktisi degil.
void main() {
  group('julianDay — modern tarihler (Gregoryen)', () {
    test('J2000.0 epogu tam olarak 2451545.0', () {
      expect(julianDay(DateTime.utc(2000, 1, 1, 12)), 2451545.0);
      // Ayni sabit paketten de disa aktariliyor; ikisi tutmali.
      expect(julianDay(DateTime.utc(2000, 1, 1, 12)), j2000);
    });

    test('Meeus dogrulama tarihleri', () {
      final cases = <DateTime, double>{
        DateTime.utc(1999, 1, 1): 2451179.5,
        DateTime.utc(1987, 1, 27): 2446822.5,
        DateTime.utc(1987, 6, 19, 12): 2446966.0,
        DateTime.utc(1988, 1, 27): 2447187.5,
        DateTime.utc(1988, 6, 19, 12): 2447332.0,
        DateTime.utc(1900, 1, 1): 2415020.5,
        DateTime.utc(1600, 1, 1): 2305447.5,
        DateTime.utc(1600, 12, 31): 2305812.5,
      };
      cases.forEach((utc, expected) {
        expect(julianDay(utc), closeTo(expected, 1e-9), reason: '$utc');
      });
    });

    test('artik yil: 2000 artik, 1900 degil', () {
      // 1900 Gregoryen'de artik DEGIL (yuzyil kurali). Subat sonundan
      // Mart basina gecis bunu ortaya cikarir.
      expect(julianDay(DateTime.utc(1900, 3, 1)) -
          julianDay(DateTime.utc(1900, 2, 28)), 1.0);
      // 2000 artik (400'e bolunuyor): 29 Subat var.
      expect(julianDay(DateTime.utc(2000, 3, 1)) -
          julianDay(DateTime.utc(2000, 2, 28)), 2.0);
    });

    test('gun icindeki kesir dogru', () {
      final midnight = julianDay(DateTime.utc(2026, 8, 19));
      expect(julianDay(DateTime.utc(2026, 8, 19, 6)) - midnight,
          closeTo(0.25, 1e-12));
      expect(julianDay(DateTime.utc(2026, 8, 19, 12)) - midnight,
          closeTo(0.50, 1e-12));
      expect(julianDay(DateTime.utc(2026, 8, 19, 18)) - midnight,
          closeTo(0.75, 1e-12));
    });

    test('ardisik gunler tam 1.0 fark eder', () {
      var previous = julianDay(DateTime.utc(2026, 1, 1));
      for (var i = 1; i <= 365; i++) {
        final current = julianDay(DateTime.utc(2026, 1, 1).add(Duration(days: i)));
        expect(current - previous, closeTo(1.0, 1e-9), reason: '$i. gun');
        previous = current;
      }
    });
  });

  group('julianDayFromCalendar — tarihsel (Julian takvimi)', () {
    // Bu tarihler DateTime uzerinden ifade EDILEMEZ: Dart proleptik
    // Gregoryen kullanir, bunlar ise gercek Julian takvim tarihleridir.
    test('Meeus tarihsel ornekleri', () {
      expect(julianDayFromCalendar(837, 4, 10.3), closeTo(2026871.8, 1e-6));
      expect(julianDayFromCalendar(-1000, 7, 12.5), closeTo(1356001.0, 1e-6));
      expect(julianDayFromCalendar(-1001, 8, 17.9), closeTo(1355671.4, 1e-6));
      expect(julianDayFromCalendar(-4712, 1, 1.5), closeTo(0.0, 1e-6));
    });

    test('takvim gecisi: 1582-10-04 (Julian) ve 1582-10-15 (Gregoryen) ardisik',
        () {
      // Tarihsel olarak 4 Ekim'i 15 Ekim izledi; aradaki 10 gun atlandi.
      final lastJulian = julianDayFromCalendar(1582, 10, 4.0);
      final firstGregorian = julianDayFromCalendar(1582, 10, 15.0);
      expect(firstGregorian - lastJulian, closeTo(1.0, 1e-9));
    });
  });

  group('dateTimeFromJulianDay — ters donusum', () {
    test('bilinen degerler', () {
      expect(dateTimeFromJulianDay(2451545.0), DateTime.utc(2000, 1, 1, 12));
      expect(dateTimeFromJulianDay(2446822.5), DateTime.utc(1987, 1, 27));
      expect(dateTimeFromJulianDay(2415020.5), DateTime.utc(1900, 1, 1));
    });

    test('gidis-donus, double cozunurlugu icinde', () {
      // Tolerans keyfi degil: JD ~2.46e6 buyuklugunde ve double'in bir ULP'si
      // ~47 us eder. Bundan daha siki bir test, matematigi degil kayan nokta
      // temsilini olcerdi. Ayrintili gerekce: julianDayResolutionMicroseconds.
      final samples = [
        DateTime.utc(2026, 8, 19, 1, 3, 30),
        DateTime.utc(2000, 2, 29, 23, 59, 59),
        DateTime.utc(1985, 12, 31, 0, 0, 1),
        DateTime.utc(2100, 6, 15, 12, 34, 56),
      ];
      for (final utc in samples) {
        final round = dateTimeFromJulianDay(julianDay(utc));
        expect(round.difference(utc).inMicroseconds.abs(),
            lessThanOrEqualTo(julianDayResolutionMicroseconds),
            reason: '$utc -> ${julianDay(utc)} -> $round');
      }
    });

    test('cozunurluk sabiti gercekten tutuyor (rastgele ornekleme)', () {
      // Sabiti bir kez uydurup gecmeyelim: genis bir tarih araliginda
      // gercekten asilmadigini dogrula.
      final start = DateTime.utc(1950, 1, 1).millisecondsSinceEpoch;
      final span = DateTime.utc(2100, 1, 1).millisecondsSinceEpoch - start;
      var worst = 0;
      for (var i = 0; i < 2000; i++) {
        final utc = DateTime.fromMillisecondsSinceEpoch(
            start + (span * i ~/ 2000),
            isUtc: true);
        final diff =
            dateTimeFromJulianDay(julianDay(utc)).difference(utc).inMicroseconds.abs();
        if (diff > worst) worst = diff;
      }
      expect(worst, lessThanOrEqualTo(julianDayResolutionMicroseconds),
          reason: 'en kotu sapma $worst us');
    });
  });

  group('UTC zorunlulugu', () {
    test('yerel saat reddedilir', () {
      // Yol haritasindaki 1 numarali tuzak: zaman dilimi. Sessizce yanlis
      // sonuc vermektense patlamasi iyidir.
      expect(() => julianDay(DateTime(2026, 8, 19)), throwsArgumentError);
    });

    test('toUtc() ile donusturulmus deger kabul edilir', () {
      expect(() => julianDay(DateTime(2026, 8, 19).toUtc()), returnsNormally);
    });
  });

  group('julianCenturies', () {
    test('J2000 epogunda sifir', () {
      expect(julianCenturies(j2000), 0.0);
      expect(julianCenturiesFromUtc(DateTime.utc(2000, 1, 1, 12)), 0.0);
    });

    test('bir Julian yuzyili sonra tam 1.0', () {
      expect(julianCenturies(j2000 + daysPerJulianCentury), closeTo(1.0, 1e-12));
    });

    test('J2000 oncesi negatif', () {
      expect(julianCenturiesFromUtc(DateTime.utc(1900, 1, 1)), lessThan(0));
    });
  });
}
