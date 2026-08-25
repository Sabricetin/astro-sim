import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

/// T6.2 — Galaktik koordinat donusumu.
///
/// Referans degerler literaturden; donusum bozulursa hepsi birden
/// kayar. Tanim sabitleri olculmus degil TANIM oldugu icin
/// belirsizlikleri yok — beklenen uyum cok siki olmali.
void main() {
  Galactic gal(double ra, double dec) => equatorialToGalactic(
    Equatorial(rightAscensionDegrees: ra, declinationDegrees: dec),
  );

  group('Tanim noktalari', () {
    test('galaktik merkez literaturdeki yerde', () {
      final gc = galacticCenterEquatorial;
      // Sagittarius A*: RA 266.41684, Dec -29.00781 (gercek kaynak).
      // l=0,b=0 tanim noktasi ondan biraz farkli: RA 266.40510,
      // Dec -28.93617. Ikisini karistirmamak onemli — biri fiziksel
      // nesne, oteki koordinat sisteminin sifiri.
      expect(gc.rightAscensionDegrees, closeTo(266.40510, 0.001));
      expect(gc.declinationDegrees, closeTo(-28.93617, 0.001));
    });

    test('kuzey galaktik kutup b=+90 veriyor', () {
      final g = gal(northGalacticPoleRaDegrees, northGalacticPoleDecDegrees);
      expect(g.latitudeDegrees, closeTo(90.0, 1e-9));
    });

    test('guney galaktik kutup b=-90 veriyor', () {
      final g = gal(
        northGalacticPoleRaDegrees + 180,
        -northGalacticPoleDecDegrees,
      );
      expect(g.latitudeDegrees, closeTo(-90.0, 1e-9));
    });

    test('galaktik anti-merkez l=180', () {
      final anti = galacticToEquatorial(
        const Galactic(longitudeDegrees: 180, latitudeDegrees: 0),
      );
      final back = equatorialToGalactic(anti);
      expect(back.longitudeDegrees, closeTo(180.0, 1e-9));
      expect(back.latitudeDegrees, closeTo(0.0, 1e-9));
    });
  });

  group('Bilinen yildizlar — literaturle karsilastirma', () {
    // (RA, Dec, l, b)
    const cases = <(String, double, double, double, double)>[
      ('Vega', 279.2347, 38.7837, 67.45, 19.24),
      ('Deneb', 310.3580, 45.2803, 84.28, 2.00),
      ('Altair', 297.6958, 8.8683, 47.74, -8.91),
      ('Sirius', 101.2872, -16.7161, 227.23, -8.89),
      ('Betelgeuse', 88.7929, 7.4071, 199.79, -8.96),
      ('Polaris', 37.9546, 89.2641, 123.28, 26.46),
    ];

    for (final (name, ra, dec, l, b) in cases) {
      test('$name', () {
        final g = gal(ra, dec);
        expect(g.longitudeDegrees, closeTo(l, 0.02), reason: '$name boylam');
        expect(g.latitudeDegrees, closeTo(b, 0.02), reason: '$name enlem');
      });
    }
  });

  group('Gidis-donus', () {
    test('yuzlerce nokta icin kayipsiz', () {
      var worst = 0.0;
      for (var l = 0.0; l < 360; l += 11) {
        for (var b = -85.0; b <= 85.0; b += 17) {
          final g = Galactic(longitudeDegrees: l, latitudeDegrees: b);
          final back = equatorialToGalactic(galacticToEquatorial(g));
          final d = angularSeparationDegrees(
            g.longitudeDegrees,
            g.latitudeDegrees,
            back.longitudeDegrees,
            back.latitudeDegrees,
          );
          if (d > worst) worst = d;
        }
      }
      // Gidis-donus, donusumun kendi ic tutarliligini olcer. Isaret
      // hatasi burada aninda ortaya cikar.
      expect(worst, lessThan(1e-9), reason: 'en kotu sapma $worst derece');
    });

    test('kutuplarda da kayipsiz', () {
      for (final b in [89.9, -89.9, 90.0, -90.0]) {
        final g = Galactic(longitudeDegrees: 37, latitudeDegrees: b);
        final back = equatorialToGalactic(galacticToEquatorial(g));
        expect(back.latitudeDegrees, closeTo(b, 1e-9));
      }
    });
  });

  group('Samanyolu seridi', () {
    test('duzlem ornekleri gercekten b=0 uzerinde', () {
      final samples = galacticPlaneSamples(step: 5);
      expect(samples.length, 72);
      for (final s in samples) {
        expect(equatorialToGalactic(s).latitudeDegrees, closeTo(0, 1e-9));
      }
    });

    test('seride yakinlik dogru bildiriliyor', () {
      // Deneb Samanyolu'nun tam icinde, Vega degil.
      expect(gal(310.3580, 45.2803).nearGalacticPlane(), isTrue);
      expect(gal(279.2347, 38.7837).nearGalacticPlane(), isFalse);
    });

    test('Faz 0.B fon alani Samanyolu DISINDA', () {
      // Pegasus karesi (23h00 +25). Fon olcumu galaktik duzleme yakin
      // yapilirsa Samanyolu'nun kendisi olculur — o yuzden bu alan
      // secildi. Deger saha talimatinda -31 diye yaziyor.
      final g = gal(345.0, 25.0);
      expect(g.latitudeDegrees, closeTo(-31, 1.0));
      expect(g.nearGalacticPlane(), isFalse);
    });
  });
}
