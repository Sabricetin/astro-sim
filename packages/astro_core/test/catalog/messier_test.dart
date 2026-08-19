import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  group('katalog butunlugu', () {
    test('110 nesne, 1..110 numarali', () {
      expect(messierCatalog, hasLength(110));
      for (var i = 0; i < 110; i++) {
        expect(messierCatalog[i].number, i + 1);
      }
    });

    test('butun koordinatlar gecerli aralikta', () {
      for (final o in messierCatalog) {
        expect(o.rightAscensionDegrees, inInclusiveRange(0, 360), reason: '$o');
        expect(o.declinationDegrees, inInclusiveRange(-90, 90), reason: '$o');
      }
    });

    test('butun tur kodlari tanimli', () {
      for (final o in messierCatalog) {
        expect(
          messierTypeNames.containsKey(o.type),
          isTrue,
          reason: '$o: bilinmeyen tur "${o.type}"',
        );
      }
    });

    test('tur dagilimi Messier katalogunun bilinen kirilimiyla ortusuyor', () {
      int count(String type) =>
          messierCatalog.where((o) => o.type == type).length;
      expect(count('Gx'), 40); // galaksi
      expect(count('Gb'), 29); // kuresel kume
      expect(count('OC'), 27); // acik kume
    });

    test('NGC karsiligi olmayan tam dort nesne', () {
      final withoutNgc = messierCatalog
          .where((o) => o.ngc.isEmpty)
          .map((o) => o.number)
          .toList();
      // M24 Samanyolu yildiz bulutu, M40 cift yildiz, M45 Ulker,
      // M102 tarihsel olarak tartismali.
      expect(withoutNgc, [24, 40, 45, 102]);
    });
  });

  group('bilinen nesneler dogru yerde', () {
    /// Bagimsiz olarak bilinen J2000 konumlari. Tolerans 0.1 derece:
    /// katalogun sapma hassasiyeti 1 yay dakikasi.
    void expectAt(int number, double raHours, double decDegrees) {
      final o = messierCatalog[number - 1];
      expect(
        angularSeparationDegrees(
          o.rightAscensionDegrees,
          o.declinationDegrees,
          hoursToDegrees(raHours),
          decDegrees,
        ),
        lessThan(0.1),
        reason:
            '$o -> ${formatHms(o.rightAscensionHours)} '
            '${formatDms(o.declinationDegrees)}',
      );
    }

    test('M31 Andromeda Galaksisi', () => expectAt(31, 0 + 42.7 / 60, 41.27));
    test('M42 Orion Bulutsusu', () => expectAt(42, 5 + 35.3 / 60, -5.39));
    test('M13 Herkul Kumesi', () => expectAt(13, 16 + 41.7 / 60, 36.46));
    test('M45 Ulker', () => expectAt(45, 3 + 47.4 / 60, 24.12));
    test('M1 Yengec Bulutsusu', () => expectAt(1, 5 + 34.5 / 60, 22.02));
    test('M8 Lagun Bulutsusu', () => expectAt(8, 18 + 3.8 / 60, -24.38));
  });

  group('Gaziantep gorunurlugu — Faz 4.7 icin on kontrol', () {
    const gaziantepLat = 37.07;

    test('butun katalog Gaziantep\'ten dogar', () {
      // Sasirtici gorunebilir ama beklenen sonuc: Messier katalogunu
      // Paris'ten (49 kuzey) derledi, o yuzden katalogda cok guneyde
      // nesne yok. En guneydeki M7, sapma -34.8; Gaziantep'ten (37.07)
      // hic dogmama esigi -52.9. Aradaki 18 derecelik pay, katalogun
      // tamamini bu enlemde erisilebilir kiliyor.
      final never = messierCatalog
          .where(
            (o) => isNeverVisible(
              declinationDegrees: o.declinationDegrees,
              latitudeDegrees: gaziantepLat,
            ),
          )
          .toList();
      expect(never, isEmpty);

      final southernmost = messierCatalog
          .map((o) => o.declinationDegrees)
          .reduce((a, b) => a < b ? a : b);
      expect(southernmost, closeTo(-34.82, 0.05));
    });

    test('en guneydeki nesneler cok alcak zirve yapiyor', () {
      // Dogmasi gorunur olmasi demek degil: M7 sadece 18 dereceye
      // cikiyor, yani atmosferin en kalin oldugu bolgede kaliyor.
      final m7 = messierCatalog[6];
      final maxAlt = maximumAltitudeDegrees(
        declinationDegrees: m7.declinationDegrees,
        latitudeDegrees: gaziantepLat,
      );
      expect(maxAlt, closeTo(18.1, 0.2));
    });

    test('M8 Lagun dusuk yukseklikte zirve yapiyor', () {
      // Galaktik merkez bolgesindeki nesneler bu enlemden alcak kalir —
      // projenin temel kisitini Messier hedeflerinde de gosteriyor.
      final m8 = messierCatalog[7];
      final maxAlt = maximumAltitudeDegrees(
        declinationDegrees: m8.declinationDegrees,
        latitudeDegrees: gaziantepLat,
      );
      expect(maxAlt, lessThan(30));
      expect(maxAlt, greaterThan(20));
    });
  });
}
