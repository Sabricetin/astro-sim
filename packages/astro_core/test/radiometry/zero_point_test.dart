import 'dart:math' as math;

import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

/// Sifir noktasi tabanli zincir.
///
/// Bu yol QE ve T'nin yerine gecti: ikisi de tek baslarina olculemez
/// ama carpimlari TEK bir olcumle elde edilir — kadiri bilinen bir
/// yildizin kac ADU verdigi.
void main() {
  const zp = Measured(value: 20.0, unit: 'kadir', source: 'TEST');
  const k = Measured(value: 0.25, unit: 'kadir/X', source: 'TEST');
  const band = Measured(value: 0.0, unit: 'kadir', source: 'TEST');

  group('Sifir noktasi tanimi', () {
    test('m_alet = 0 tam 1 ADU/s demek', () {
      expect(aduPerSecondFromInstrumentalMagnitude(0), closeTo(1.0, 1e-12));
    });

    test('5 kadir tam 100 kat', () {
      expect(
        aduPerSecondFromInstrumentalMagnitude(0) /
            aduPerSecondFromInstrumentalMagnitude(5),
        closeTo(100.0, 1e-9),
      );
    });
  });

  group('Yildiz — sifir noktasindan ADU', () {
    test('basucunda ZP kadirindeki yildiz 1 ADU/s verir', () {
      // Basucunda X=1, sonum k. V = ZP - k olan yildiz m_alet = 0 verir.
      final r = starAduPerSecond(
        vMagnitude: zp.value - k.value * airmassKastenYoung(90),
        altitudeDegrees: 90,
        colorIndexBV: 0.0,
        extinctionCoefficient: k,
        zeroPoint: zp,
        bandCorrectionPerColorIndex: band,
      );
      expect(r.valueOrNull, closeTo(1.0, 1e-6));
    });

    test('alcalan yildiz sonuyor, hava kutlesiyle uyumlu', () {
      double at(double alt) => starAduPerSecond(
        vMagnitude: 8,
        altitudeDegrees: alt,
        colorIndexBV: 0.0,
        extinctionCoefficient: k,
        zeroPoint: zp,
        bandCorrectionPerColorIndex: band,
      ).valueOrNull!;
      final high = at(90), low = at(24);
      final dX = airmassKastenYoung(24) - airmassKastenYoung(90);
      // Kayip tam olarak k*dX kadir olmali.
      final lostMag = -2.5 * (math.log(low / high) / math.ln10);
      expect(lostMag, closeTo(k.value * dX, 1e-9));
    });

    test('ZP 1 kadir artarsa sinyal 2.512 kat artar', () {
      double at(Measured z) => starAduPerSecond(
        vMagnitude: 8,
        altitudeDegrees: 45,
        colorIndexBV: 0.0,
        extinctionCoefficient: k,
        zeroPoint: z,
        bandCorrectionPerColorIndex: band,
      ).valueOrNull!;
      final a = at(zp);
      final b = at(const Measured(value: 21.0, unit: 'kadir', source: 'TEST'));
      expect(b / a, closeTo(math.pow(10, 0.4), 1e-9));
    });
  });

  group('Gokyuzu fonu — sifir noktasindan', () {
    test('bilinen fon dogru ADU veriyor', () {
      // mu = 21, ZP = 20 -> m_alet = 1 -> arcsec^2 basina 10^-0.4 ADU/s
      final r = skyAduPerPixelPerSecond(
        arcsecondsPerPixel: 10.0,
        skyMagPerSquareArcsec: const Measured(
          value: 21.0,
          unit: 'kadir/as^2',
          source: 'TEST',
        ),
        zeroPoint: zp,
      );
      expect(r.valueOrNull, closeTo(math.pow(10, -0.4) * 100, 1e-9));
    });

    test('4 kadir parlak gokyuzu 40 kat sinyal', () {
      double at(double mu) => skyAduPerPixelPerSecond(
        arcsecondsPerPixel: 54.8,
        skyMagPerSquareArcsec: Measured(
          value: mu,
          unit: 'kadir/as^2',
          source: 'TEST',
        ),
        zeroPoint: zp,
      ).valueOrNull!;
      // Bortle 9 (18) ile Bortle 1 (22) arasi.
      expect(at(18) / at(22), closeTo(39.81, 0.01));
    });

    test('fona SONUM UYGULANMIYOR — yukseklik parametresi bile yok', () {
      // Gokyuzu fonu atmosferin kendi isigi; yerde olculur. Yildiz
      // isigiyla ayni duzeltmeyi uygulamak sik yapilan bir hata.
      final r = skyAduPerPixelPerSecond(
        arcsecondsPerPixel: 54.8,
        skyMagPerSquareArcsec: const Measured(
          value: 21.0,
          unit: 'kadir/as^2',
          source: 'TEST',
        ),
        zeroPoint: zp,
      );
      expect(r.isKnown, isTrue);
    });
  });

  group('REDDETME — sifir noktasi yolunda da gecerli', () {
    test('ZP yoksa yildiz hesaplanmiyor', () {
      final r = starAduPerSecond(
        vMagnitude: 8,
        altitudeDegrees: 45,
        colorIndexBV: 0.0,
        extinctionCoefficient: k,
        bandCorrectionPerColorIndex: band,
      );
      expect(r.isKnown, isFalse);
      expect(r.missing.single.symbol, 'ZP');
    });

    test('ZP yoksa fon da hesaplanmiyor', () {
      final r = skyAduPerPixelPerSecond(
        arcsecondsPerPixel: 54.8,
        skyMagPerSquareArcsec: const Measured(
          value: 21,
          unit: 'k',
          source: 't',
        ),
      );
      expect(r.missing.single.symbol, 'ZP');
    });

    test('hicbiri yoksa hepsi birden bildiriliyor', () {
      final r = starAduPerSecond(vMagnitude: 8, altitudeDegrees: 45);
      final syms = r.missing.map((q) => q.symbol).toSet();
      expect(syms, containsAll(['k', 'ZP', 'dV_G']));
    });

    test('renk bilinmiyorsa B-V eksigi bildiriliyor', () {
      final r = starAduPerSecond(
        vMagnitude: 8,
        altitudeDegrees: 45,
        extinctionCoefficient: k,
        zeroPoint: zp,
        bandCorrectionPerColorIndex: band,
      );
      expect(r.missing.single.symbol, 'B-V');
    });
  });

  group('Defter kisaldi', () {
    test('QE ve T artik ayri eksik degil', () {
      final syms = allMissingQuantities.map((q) => q.symbol).toList();
      expect(syms, contains('ZP'));
      expect(syms, isNot(contains('QE')));
      expect(syms, isNot(contains('T')));
      // Bes eksik: k, ZP, dV_G, I_d, mu_sky
      expect(allMissingQuantities.length, 5);
    });

    test('mu_sky artik VIIRS bekleme diyor', () {
      final q = allMissingQuantities.firstWhere((q) => q.symbol == 'mu_sky');
      expect(q.comesFrom, contains('0.B'));
      expect(q.why, contains('VIIRS'));
    });
  });
}
