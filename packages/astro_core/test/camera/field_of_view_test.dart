import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  group('bilinen FOV degerleri', () {
    test('14 mm tam kare yatay = 104.2 derece', () {
      // Faz 2'deki gnomonik projeksiyon testinde de ayni sayi cikmisti;
      // ayni matematik, iki farkli yerden dogrulaniyor.
      expect(
        fieldOfViewDegrees(sensorDimensionMm: 36, focalLengthMm: 14),
        closeTo(104.25, 0.05),
      );
    });

    test('50 mm tam kare kosegen = 47 derece (klasik "normal" lens)', () {
      expect(
        fieldOfViewDegrees(
          sensorDimensionMm: fullFrame.diagonalMm,
          focalLengthMm: 50,
        ),
        closeTo(46.8, 0.1),
      );
    });

    test('odak uzadikca gorus alani daralir', () {
      var previous = 180.0;
      for (final f in [8.0, 14.0, 24.0, 50.0, 200.0, 600.0]) {
        final fov = fieldOfViewDegrees(sensorDimensionMm: 36, focalLengthMm: f);
        expect(fov, lessThan(previous), reason: '$f mm');
        previous = fov;
      }
    });

    test('sifir veya negatif odak reddedilir', () {
      expect(
        () => fieldOfViewDegrees(sensorDimensionMm: 36, focalLengthMm: 0),
        throwsArgumentError,
      );
    });
  });

  group('FieldOfView.of', () {
    test('tam kare 24 mm: yatay > dikey > yok', () {
      final fov = FieldOfView.of(format: fullFrame, focalLengthMm: 24);
      expect(fov.horizontalDegrees, greaterThan(fov.verticalDegrees));
      expect(fov.diagonalDegrees, greaterThan(fov.horizontalDegrees));
      expect(fov.horizontalDegrees, closeTo(73.7, 0.1));
      expect(fov.verticalDegrees, closeTo(53.1, 0.1));
    });

    test('dikey cevirince yatay ve dikey yer degistirir', () {
      final landscape = FieldOfView.of(format: fullFrame, focalLengthMm: 24);
      final portrait = FieldOfView.of(
        format: fullFrame,
        focalLengthMm: 24,
        portrait: true,
      );
      expect(
        portrait.horizontalDegrees,
        closeTo(landscape.verticalDegrees, 1e-9),
      );
      expect(
        portrait.verticalDegrees,
        closeTo(landscape.horizontalDegrees, 1e-9),
      );
      // Kosegen degismez.
      expect(
        portrait.diagonalDegrees,
        closeTo(landscape.diagonalDegrees, 1e-9),
      );
    });

    test('kirpma sensorde ayni lens dar gorur', () {
      final ff = FieldOfView.of(format: fullFrame, focalLengthMm: 50);
      final canon = FieldOfView.of(format: apscCanon, focalLengthMm: 50);
      expect(canon.horizontalDegrees, lessThan(ff.horizontalDegrees));

      // 50 mm Canon APS-C'de, tam karede ~80 mm gibi cerceveler.
      final equivalent = focalLengthForFieldOfView(
        sensorDimensionMm: fullFrame.widthMm,
        fieldOfViewDegrees: canon.horizontalDegrees,
      );
      expect(equivalent, closeTo(50 * apscCanon.cropFactor, 0.5));
    });
  });

  group('focalLengthForFieldOfView — ters yon', () {
    test('gidis-donus kapali', () {
      for (final f in [8.0, 14.0, 35.0, 85.0, 400.0]) {
        final fov = fieldOfViewDegrees(sensorDimensionMm: 36, focalLengthMm: f);
        final back = focalLengthForFieldOfView(
          sensorDimensionMm: 36,
          fieldOfViewDegrees: fov,
        );
        expect(back, closeTo(f, 1e-9), reason: '$f mm');
      }
    });
  });

  group('arcsecondsPerPixel — birim tuzagi', () {
    test('katsayi 206.265 (p mikrometre)', () {
      // Yaygin yazilan 206265 katsayisi p'nin MILIMETRE olmasini ister.
      // Bu paket p'yi her yerde mikrometre tuttugu icin 206.265 dogru.
      // 3.717 um adim, 14 mm odak -> 54.8 yay saniyesi/piksel.
      expect(
        arcsecondsPerPixel(pixelPitchMicrometers: 3.717, focalLengthMm: 14),
        closeTo(54.76, 0.05),
      );
    });

    test('uzun odak daha ince olcek verir', () {
      final wide = arcsecondsPerPixel(
        pixelPitchMicrometers: 3.717,
        focalLengthMm: 14,
      );
      final tele = arcsecondsPerPixel(
        pixelPitchMicrometers: 3.717,
        focalLengthMm: 400,
      );
      expect(tele, lessThan(wide));
      expect(wide / tele, closeTo(400 / 14, 1e-9));
    });
  });
}
