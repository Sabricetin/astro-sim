import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  group('colorTemperatureFromBV', () {
    test('Gunes: B-V 0.65 -> 5778 K', () {
      // Formulun en guclu dogrulamasi: bagimsiz olarak bilinen bir deger.
      expect(colorTemperatureFromBV(0.65), closeTo(5778, 5));
    });

    test('A0 tipi (B-V 0.0) mavi-beyaz aralikta', () {
      expect(colorTemperatureFromBV(0.0), closeTo(10125, 50));
    });

    test('sicaklik B-V ile monoton azalir', () {
      var previous = double.infinity;
      for (var bv = -0.3; bv <= 3.8; bv += 0.1) {
        final t = colorTemperatureFromBV(bv);
        expect(t, lessThan(previous), reason: 'B-V $bv');
        previous = t;
      }
    });

    test('katalogdaki uc degerler makul sonuc verir', () {
      // HR 1996, O9.5V — formul dusuk tahmin eder ama patlamaz.
      expect(colorTemperatureFromBV(-0.28), greaterThan(12000));
      // HR 423, C6II karbon yildizi — cok soguk cikmali.
      expect(colorTemperatureFromBV(3.86), lessThan(2500));
    });

    test('B-V bilinmiyorsa NaN gecer', () {
      expect(colorTemperatureFromBV(double.nan).isNaN, isTrue);
    });

    test('sinir disi girdi kirpilir, patlamaz', () {
      expect(colorTemperatureFromBV(-99).isFinite, isTrue);
      expect(colorTemperatureFromBV(99).isFinite, isTrue);
      expect(
        colorTemperatureFromBV(-99),
        colorTemperatureFromBV(minValidColorIndex),
      );
    });
  });

  group('relativeBrightness', () {
    test('5 kadir farki tam 100 kat', () {
      // Kadir olceginin tanimi. Yol haritasi: "1. kadir ile 6. kadir
      // arasinda 100 kat parlaklik farki var."
      expect(
        relativeBrightness(1.0) / relativeBrightness(6.0),
        closeTo(100.0, 1e-9),
      );
    });

    test('referans kadirde tam 1.0', () {
      expect(
        relativeBrightness(3.0, referenceMagnitude: 3.0),
        closeTo(1.0, 1e-12),
      );
    });

    test('Sirius Vega\'dan ~3.9 kat parlak', () {
      // Sirius -1.46, Vega 0.03
      expect(
        relativeBrightness(-1.46) / relativeBrightness(0.03),
        closeTo(3.9, 0.1),
      );
    });
  });
}
