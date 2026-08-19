import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  group('kirpma carpanlari', () {
    test('bilinen degerlerle ortusuyor', () {
      expect(fullFrame.cropFactor, closeTo(1.0, 0.001));
      expect(apscCanon.cropFactor, closeTo(1.61, 0.01));
      expect(apsc.cropFactor, closeTo(1.53, 0.01));
      expect(microFourThirds.cropFactor, closeTo(2.0, 0.01));
      expect(oneInch.cropFactor, closeTo(2.73, 0.01));
    });

    test('Canon APS-C digerlerinden kucuk', () {
      // Yol haritasi bunu ayrica isaretledi: ikisini ayni "APS-C" etiketi
      // altinda birlestirmek FOV hesabinda %5'in uzerinde hata verir.
      expect(apscCanon.cropFactor, greaterThan(apsc.cropFactor));
      final error = (apscCanon.cropFactor - apsc.cropFactor) / apsc.cropFactor;
      expect(error, greaterThan(0.05));
    });

    test('kosegen Pisagor ile tutarli', () {
      for (final f in sensorFormats) {
        final expected = (f.widthMm * f.widthMm + f.heightMm * f.heightMm);
        expect(
          f.diagonalMm * f.diagonalMm,
          closeTo(expected, 1e-9),
          reason: f.name,
        );
      }
    });
  });

  group('piksel adimi turetimi', () {
    test('Canon EOS 760D — bu projenin kalibrasyon govdesi', () {
      final body = cameras.firstWhere((c) => c.name == 'Canon EOS 760D');
      // 22.3 mm / 6000 piksel = 3.717 um. Faz 0.A'daki dolum kapasitesi
      // capraz kontrolunde kullanilan deger buydu.
      expect(body.pixelPitchMicrometers, closeTo(3.717, 0.005));
      expect(body.megapixels, closeTo(24.0, 0.1));
    });

    test('yuksek cozunurluk kucuk adim demek', () {
      final a7r5 = cameras.firstWhere((c) => c.name == 'Sony A7R V');
      final a7iii = cameras.firstWhere((c) => c.name == 'Sony A7 III');
      expect(a7r5.pixelPitchMicrometers, lessThan(a7iii.pixelPitchMicrometers));
      expect(a7r5.pixelPitchMicrometers, closeTo(3.79, 0.02));
      expect(a7iii.pixelPitchMicrometers, closeTo(6.0, 0.02));
    });

    test('butun govdelerde adim makul aralikta', () {
      for (final c in cameras) {
        expect(
          c.pixelPitchMicrometers,
          inInclusiveRange(1.0, 10.0),
          reason: c.name,
        );
      }
    });
  });
}
