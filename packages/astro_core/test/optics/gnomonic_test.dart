import 'dart:math' as math;

import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  group('temel projeksiyon', () {
    test('bakis merkezi tam orijine duser', () {
      final p = project(
        azimuthDegrees: 137.0,
        altitudeDegrees: 42.0,
        centerAzimuthDegrees: 137.0,
        centerAltitudeDegrees: 42.0,
      );
      expect(p, isNotNull);
      expect(p!.x, closeTo(0.0, 1e-12));
      expect(p.y, closeTo(0.0, 1e-12));
    });

    test('yatay sapma tanjant verir — rectilinear lens tanimi', () {
      // Gnomonik projeksiyonun tanimlayici ozelligi: merkeze aci uzakligi
      // teta olan nokta, teget duzlemde tan(teta) mesafesine duser.
      for (final angle in [1.0, 10.0, 30.0, 45.0, 60.0]) {
        final p = project(
          azimuthDegrees: angle,
          altitudeDegrees: 0.0,
          centerAzimuthDegrees: 0.0,
          centerAltitudeDegrees: 0.0,
        );
        expect(p, isNotNull, reason: '$angle derece');
        expect(
          p!.x,
          closeTo(math.tan(toRadians(angle)), 1e-9),
          reason: '$angle derece',
        );
        expect(p.y, closeTo(0.0, 1e-9), reason: '$angle derece');
      }
    });

    test('dikey sapma da tanjant verir', () {
      for (final angle in [1.0, 10.0, 30.0, 45.0]) {
        final p = project(
          azimuthDegrees: 0.0,
          altitudeDegrees: angle,
          centerAzimuthDegrees: 0.0,
          centerAltitudeDegrees: 0.0,
        );
        expect(p!.y, closeTo(math.tan(toRadians(angle)), 1e-9));
        expect(p.x, closeTo(0.0, 1e-9));
      }
    });

    test('x saga, y yukari pozitif', () {
      // Kuzeye bakarken azimut artisi doguya, yani saga gider.
      final right = project(
        azimuthDegrees: 10,
        altitudeDegrees: 0,
        centerAzimuthDegrees: 0,
        centerAltitudeDegrees: 0,
      )!;
      expect(right.x, greaterThan(0));

      final up = project(
        azimuthDegrees: 0,
        altitudeDegrees: 10,
        centerAzimuthDegrees: 0,
        centerAltitudeDegrees: 0,
      )!;
      expect(up.y, greaterThan(0));
    });
  });

  group('gorus alani disi', () {
    test('arkadaki nokta null doner', () {
      final behind = project(
        azimuthDegrees: 180,
        altitudeDegrees: 0,
        centerAzimuthDegrees: 0,
        centerAltitudeDegrees: 0,
      );
      expect(behind, isNull);
    });

    test('tam 90 derece yanda null — teget duzlem sonsuza gider', () {
      expect(
        project(
          azimuthDegrees: 90,
          altitudeDegrees: 0,
          centerAzimuthDegrees: 0,
          centerAltitudeDegrees: 0,
        ),
        isNull,
      );
    });

    test('sinirin hemen icinde hala cizilir', () {
      final p = project(
        azimuthDegrees: gnomonicMaxHalfAngleDegrees - 1,
        altitudeDegrees: 0,
        centerAzimuthDegrees: 0,
        centerAltitudeDegrees: 0,
      );
      expect(p, isNotNull);
      expect(p!.x.isFinite, isTrue);
    });

    test('null donmek "cizme" demek — sifir DEGIL', () {
      // Sifir dondurulseydi arkadaki butun yildizlar merkeze yigilirdi.
      // Bu, gozle hemen fark edilmeyen ama tamamen yanlis bir goruntu
      // uretirdi.
      final behind = project(
        azimuthDegrees: 200,
        altitudeDegrees: 0,
        centerAzimuthDegrees: 0,
        centerAltitudeDegrees: 0,
      );
      expect(behind, isNull);
    });
  });

  group('14 mm tam kare senaryosu', () {
    // 14 mm lens, 36 mm genislik -> yatay FOV = 2*atan(18/14) = 104.2 derece.
    // Yani merkeze 52.1 dereceye kadar olan noktalar cerceveye girer.
    const halfFovDegrees = 52.1;

    test('cerceve kenari, odak uzunlugu oraniyla ortusur', () {
      final edge = project(
        azimuthDegrees: halfFovDegrees,
        altitudeDegrees: 0,
        centerAzimuthDegrees: 0,
        centerAltitudeDegrees: 0,
      )!;
      // tan(52.1) = 1.2857 = 18mm / 14mm
      expect(edge.x, closeTo(18.0 / 14.0, 0.005));
    });

    test('kenarda gerdirme gercek — bug degil', () {
      // Merkeze gore acisal olarak esit araliklarla giden noktalar,
      // duzlemde giderek acilir. Gercek genis aci lensler de bunu yapar.
      double x(double deg) => project(
        azimuthDegrees: deg,
        altitudeDegrees: 0,
        centerAzimuthDegrees: 0,
        centerAltitudeDegrees: 0,
      )!.x;
      // tan(10)-tan(0)  = 0.1763
      // tan(52)-tan(42)  = 0.3795
      // oran = 2.15: cerceve kenarindaki 10 derece, merkezdekinin iki
      // katindan fazla yer kaplar.
      final firstStep = x(10) - x(0);
      final lastStep = x(52) - x(42);
      expect(lastStep / firstStep, closeTo(2.15, 0.01));
    });
  });

  group('dondurme (roll)', () {
    test('sifir dondurme hicbir seyi degistirmez', () {
      final a = project(
        azimuthDegrees: 20,
        altitudeDegrees: 10,
        centerAzimuthDegrees: 0,
        centerAltitudeDegrees: 0,
      )!;
      final b = project(
        azimuthDegrees: 20,
        altitudeDegrees: 10,
        centerAzimuthDegrees: 0,
        centerAltitudeDegrees: 0,
        rollDegrees: 0,
      )!;
      expect(a.x, b.x);
      expect(a.y, b.y);
    });

    test('90 derece dondurme: sagdaki nokta asagi iner', () {
      // Kamera saat yonunun tersine donunce, goruntu icerigi saat
      // yonunde doner — sagdaki yildiz asagi gider.
      final p = project(
        azimuthDegrees: 10,
        altitudeDegrees: 0,
        centerAzimuthDegrees: 0,
        centerAltitudeDegrees: 0,
        rollDegrees: 90,
      )!;
      final r = math.tan(toRadians(10.0));
      expect(p.x, closeTo(0.0, 1e-9));
      expect(p.y, closeTo(-r, 1e-9));
    });

    test('dondurme uzunlugu korur', () {
      for (final roll in [0.0, 37.0, 90.0, 180.0, -45.0]) {
        final p = project(
          azimuthDegrees: 25,
          altitudeDegrees: 15,
          centerAzimuthDegrees: 5,
          centerAltitudeDegrees: 10,
          rollDegrees: roll,
        )!;
        final base = project(
          azimuthDegrees: 25,
          altitudeDegrees: 15,
          centerAzimuthDegrees: 5,
          centerAltitudeDegrees: 10,
        )!;
        expect(
          math.sqrt(p.x * p.x + p.y * p.y),
          closeTo(math.sqrt(base.x * base.x + base.y * base.y), 1e-12),
          reason: 'roll $roll',
        );
      }
    });
  });

  group('gidis-donus: project <-> unproject', () {
    test('genis ornekleme uzerinde kapali', () {
      const centerAz = 137.0;
      const centerAlt = 35.0;
      for (var dAz = -50.0; dAz <= 50.0; dAz += 17.0) {
        for (var dAlt = -40.0; dAlt <= 40.0; dAlt += 13.0) {
          final az = normalizeDegrees(centerAz + dAz);
          final alt = (centerAlt + dAlt).clamp(-89.0, 89.0);
          final p = project(
            azimuthDegrees: az,
            altitudeDegrees: alt,
            centerAzimuthDegrees: centerAz,
            centerAltitudeDegrees: centerAlt,
          );
          if (p == null) continue;
          final back = unproject(
            x: p.x,
            y: p.y,
            centerAzimuthDegrees: centerAz,
            centerAltitudeDegrees: centerAlt,
          );
          expect(
            angularSeparationDegrees(
              back.azimuthDegrees,
              back.altitudeDegrees,
              az,
              alt,
            ),
            lessThan(1e-9),
            reason: 'az=$az alt=$alt',
          );
        }
      }
    });

    test('dondurme ile de kapali', () {
      for (final roll in [30.0, -75.0, 180.0]) {
        final p = project(
          azimuthDegrees: 45,
          altitudeDegrees: 20,
          centerAzimuthDegrees: 30,
          centerAltitudeDegrees: 25,
          rollDegrees: roll,
        )!;
        final back = unproject(
          x: p.x,
          y: p.y,
          centerAzimuthDegrees: 30,
          centerAltitudeDegrees: 25,
          rollDegrees: roll,
        );
        expect(
          angularSeparationDegrees(
            back.azimuthDegrees,
            back.altitudeDegrees,
            45,
            20,
          ),
          lessThan(1e-9),
          reason: 'roll $roll',
        );
      }
    });

    test('orijin bakis yonunu verir', () {
      final back = unproject(
        x: 0,
        y: 0,
        centerAzimuthDegrees: 200,
        centerAltitudeDegrees: -15,
      );
      expect(back.azimuthDegrees, closeTo(200.0, 1e-12));
      expect(back.altitudeDegrees, closeTo(-15.0, 1e-12));
    });
  });

  group('basucuna bakma — bozunma noktasi', () {
    test('basucunda projeksiyon patlamaz', () {
      final p = project(
        azimuthDegrees: 90,
        altitudeDegrees: 80,
        centerAzimuthDegrees: 0,
        centerAltitudeDegrees: 90,
      );
      expect(p, isNotNull);
      expect(p!.x.isFinite, isTrue);
      expect(p.y.isFinite, isTrue);
    });

    test('basucundan bakinca gidis-donus hala kapali', () {
      final p = project(
        azimuthDegrees: 45,
        altitudeDegrees: 70,
        centerAzimuthDegrees: 0,
        centerAltitudeDegrees: 90,
      )!;
      final back = unproject(
        x: p.x,
        y: p.y,
        centerAzimuthDegrees: 0,
        centerAltitudeDegrees: 90,
      );
      expect(
        angularSeparationDegrees(
          back.azimuthDegrees,
          back.altitudeDegrees,
          45,
          70,
        ),
        lessThan(1e-9),
      );
    });
  });
}
