import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

/// Uydurma kalibrasyon degil — zincirin doldugunda calistigini gostermek
/// icin kullanilan TEST degerleri. Gercek degerler Faz 0.B/0.C/0.D'den
/// gelecek; bunlar oraya asla kopyalanmayacak.
CalibrationSet _testCalibration() => const CalibrationSet(
  extinctionCoefficient: Measured(
    value: 0.25,
    unit: 'kadir/X',
    source: 'TEST DEGERI — gercek deger 0.B Dizi B\'den gelecek',
  ),
  lensTransmission: Measured(value: 0.90, unit: '-', source: 'TEST DEGERI'),
  quantumEfficiency: Measured(
    value: 0.45,
    unit: 'e-/foton',
    source: 'TEST DEGERI',
  ),
  bandCorrectionPerColorIndex: Measured(
    value: 0.10,
    unit: 'kadir',
    source: 'TEST DEGERI',
  ),
  darkCurrent: Measured(value: 0.05, unit: 'e-/px/s', source: 'TEST DEGERI'),
  skyMagPerSquareArcsec: Measured(
    value: 21.0,
    unit: 'kadir/arcsec^2',
    source: 'TEST DEGERI',
  ),
  psfFwhmPixels: Measured(value: 1.8, unit: 'px', source: 'TEST DEGERI'),
);

ExposureReport _report({
  CalibrationSet calibration = CalibrationSet.empty,
  double exposureSeconds = 15,
  double vMagnitude = 8.0,
  double altitudeDegrees = 24,
}) => buildExposureReport(
  targetName: 'Galaktik merkez',
  vMagnitude: vMagnitude,
  altitudeDegrees: altitudeDegrees,
  declinationDegrees: -29,
  focalLengthMm: 14,
  fNumber: 2.8,
  exposureSeconds: exposureSeconds,
  sensor: canon760dIso1600,
  pixelPitchMicrometers: 3.72,
  colorIndexBV: 0.6,
  calibration: calibration,
);

void main() {
  group('Rapor — kalibrasyonsuz hali (bugunku durum)', () {
    test('geometrik kisim yine de hesaplaniyor', () {
      final r = _report();
      // Yukseklik, hava kutlesi, olcek ve iz kalibrasyon istemiyor.
      expect(r.airmass, closeTo(2.44, 0.05));
      expect(r.arcsecondsPerPixel, closeTo(54.8, 0.5));
      expect(r.trailPixels, greaterThan(0));
      expect(r.maxExposureSecondsNpf, greaterThan(0));
      expect(r.statements.length, 2, reason: 'sadece geometri satirlari');
    });

    test('radyometrik kisim sayi uretmiyor', () {
      final r = _report();
      expect(r.isComplete, isFalse);
      expect(r.snr.valueOrNull, isNull);
      expect(r.histogramFill.valueOrNull, isNull);
      expect(r.extinctionMagnitudes.valueOrNull, isNull);
    });

    test('neyin eksik oldugunu ve nereden gelecegini soyluyor', () {
      final r = _report();
      expect(r.missing.length, 7);
      expect(r.pendingStatements.length, 7);
      // Her satir bir kaynak isaret etmeli — "bilinmiyor" demek yetmez.
      for (final line in r.pendingStatements) {
        expect(line, contains('olculmedi'));
        expect(line.length, greaterThan(20));
      }
      expect(
        r.pendingStatements.join(' '),
        contains('0.B'),
        reason: 'kullanici hangi cekimden gelecegini gormeli',
      );
    });

    test('eksik sayaci ilerlemeyi gosteriyor', () {
      expect(CalibrationSet.empty.completedCount, 0);
      expect(_testCalibration().completedCount, 7);
      const partial = CalibrationSet(
        extinctionCoefficient: Measured(
          value: 0.25,
          unit: 'kadir/X',
          source: 'test',
        ),
      );
      expect(partial.completedCount, 1);
      expect(partial.missing.length, 6);
    });
  });

  group('Rapor — kalibrasyon dolunca zincir aciliyor', () {
    test('butun satirlar geliyor', () {
      final r = _report(calibration: _testCalibration());
      expect(r.isComplete, isTrue);
      expect(r.missing, isEmpty);
      expect(r.pendingStatements, isEmpty);
      // Yol haritasindaki cumlenin tamami: yukseklik+hava kutlesi,
      // olcek+iz, sonum, SNR, histogram, kirpma.
      expect(r.statements.length, 6);
      expect(r.statements.join(' '), contains('SNR'));
      expect(r.statements.join(' '), contains('histogramin'));
    });

    test('sonum 24 derecede ~0.61 kadir', () {
      final r = _report(calibration: _testCalibration());
      expect(r.extinctionMagnitudes.valueOrNull, closeTo(0.61, 0.02));
    });

    test('SNR pozitif ve makul buyuklukte', () {
      final r = _report(calibration: _testCalibration());
      final snr = r.snr.valueOrNull!;
      expect(snr, greaterThan(0));
      expect(snr, lessThan(1e4));
    });
  });

  group('Fizik gercekten dogru yonde calisiyor mu', () {
    test('parlak yildizin SNR\'i daha yuksek', () {
      final cal = _testCalibration();
      final bright = _report(calibration: cal, vMagnitude: 4).snr.valueOrNull!;
      final faint = _report(calibration: cal, vMagnitude: 10).snr.valueOrNull!;
      expect(bright, greaterThan(faint));
    });

    test('alcak hedef daha cok soner', () {
      final cal = _testCalibration();
      final high = _report(calibration: cal, altitudeDegrees: 70);
      final low = _report(calibration: cal, altitudeDegrees: 20);
      expect(
        low.extinctionMagnitudes.valueOrNull!,
        greaterThan(high.extinctionMagnitudes.valueOrNull!),
      );
      // Ayni yildiz alcakta daha zayif gorunur.
      expect(
        low.starElectronsPerSecond.valueOrNull!,
        lessThan(high.starElectronsPerSecond.valueOrNull!),
      );
    });

    test('uzun poz fonu histogramda yukari itiyor', () {
      final cal = _testCalibration();
      final short = _report(calibration: cal, exposureSeconds: 5);
      final long = _report(calibration: cal, exposureSeconds: 60);
      expect(
        long.histogramFill.valueOrNull!,
        greaterThan(short.histogramFill.valueOrNull!),
      );
    });

    test('iz uzadikca yildiz daha cok piksele yayiliyor', () {
      final short = starFootprintPixels(
        psfFwhmPixels: 1.8,
        trailLengthPixels: 0,
      );
      final long = starFootprintPixels(
        psfFwhmPixels: 1.8,
        trailLengthPixels: 10,
      );
      expect(long, greaterThan(short * 3));
    });

    test('ayak izi hicbir zaman 1 pikselin altina inmiyor', () {
      expect(
        starFootprintPixels(psfFwhmPixels: 0.2, trailLengthPixels: 0),
        greaterThanOrEqualTo(1.0),
      );
    });

    test('genis acida sistem asiri az orneklenmis', () {
      // 14 mm, 3.72 um -> 54.8 "/px. 2" seeing bunun yaninda yok.
      // Bu bir kusur degil, rejimin ozelligi — arac bunu bilmeli.
      final ratio = samplingRatio(
        psfFwhmArcseconds: 2.0,
        arcsecondsPerPixel: 54.8,
      );
      expect(ratio, lessThan(0.1));
    });
  });

  group('Yigin ve okuma gurultusu', () {
    test('yiginlama SNR\'i kok N kati artiriyor', () {
      const single = RadiometricValue(4.0, '-');
      final stacked = stackedSnr(singleFrameSnr: single, frameCount: 16);
      expect(stacked.valueOrNull, closeTo(16.0, 1e-9));
    });

    test('yiginlama eksigi devraliyor', () {
      final stacked = stackedSnr(
        singleFrameSnr: RadiometricGap.single(quantumEfficiencyMissing),
        frameCount: 16,
      );
      expect(stacked.isKnown, isFalse);
    });

    test('parlak gokyuzunde okuma gurultusu daha cabuk gomuluyor', () {
      final dark = readNoiseSwampedExposure(
        skyElectronsPerPixelPerSecond: const RadiometricValue(0.5, 'e-/px/s'),
        sensor: canon760dIso1600,
      ).valueOrNull!;
      final bright = readNoiseSwampedExposure(
        skyElectronsPerPixelPerSecond: const RadiometricValue(50.0, 'e-/px/s'),
        sensor: canon760dIso1600,
      ).valueOrNull!;
      expect(bright, lessThan(dark));
    });
  });

  group('Difuz hedef nokta kaynaktan ayri', () {
    test('difuz SNR piksel basina, ayak izi kullanmiyor', () {
      final r = diffuseSnrPerPixel(
        targetElectronsPerPixelPerSecond: const RadiometricValue(
          2.0,
          'e-/px/s',
        ),
        skyElectronsPerPixelPerSecond: const RadiometricValue(20.0, 'e-/px/s'),
        exposureSeconds: 60,
        sensor: canon760dIso1600,
        darkCurrentElectronsPerSecond: const Measured(
          value: 0.05,
          unit: 'e-/px/s',
          source: 'test',
        ),
      );
      // sinyal 120, fon 1200, karanlik 3, okuma^2 4.15 -> sqrt(1327)=36.4
      expect(r.valueOrNull, closeTo(120 / 36.43, 0.05));
    });

    test('karanlik akim yoksa difuz SNR de reddediliyor', () {
      final r = diffuseSnrPerPixel(
        targetElectronsPerPixelPerSecond: const RadiometricValue(2, 'e-'),
        skyElectronsPerPixelPerSecond: const RadiometricValue(20, 'e-'),
        exposureSeconds: 60,
        sensor: canon760dIso1600,
      );
      expect(r.isKnown, isFalse);
    });
  });

  group('Fon sinyali', () {
    test('fon parlakligi yoksa hesaplanmiyor', () {
      final r = skyElectronsPerPixelPerSecond(
        arcsecondsPerPixel: 54.8,
        focalLengthMm: 14,
        fNumber: 2.8,
      );
      expect(r.isKnown, isFalse);
      expect(r.missing.first.symbol, 'mu_sky');
    });

    test('parlak gokyuzu daha cok elektron veriyor', () {
      Radiometric at(double mag) => skyElectronsPerPixelPerSecond(
        arcsecondsPerPixel: 54.8,
        focalLengthMm: 14,
        fNumber: 2.8,
        skyMagPerSquareArcsec: Measured(
          value: mag,
          unit: 'kadir/arcsec^2',
          source: 'test',
        ),
        lensTransmission: const Measured(value: 0.9, unit: '-', source: 't'),
        quantumEfficiency: const Measured(
          value: 0.45,
          unit: 'e-/foton',
          source: 't',
        ),
      );
      // Bortle 9 (18) ile Bortle 1 (22) arasi 4 kadir = 40 kat.
      final city = at(18.0).valueOrNull!;
      final rural = at(22.0).valueOrNull!;
      expect(city / rural, closeTo(39.8, 1.0));
    });
  });

  group('Uctan uca — elle hesapla dogrulandi', () {
    // Bu grubun degerleri koddan alinmadi; ayri ayri elle hesaplanip
    // sonra kodun ayni sonucu verdigi gorulda. Zincirde sessiz bir
    // kayma olursa buradan yakalanir.
    //
    // Girdi: V=8 yildiz, 24 derece, 14 mm f/2.8, 15 s, ISO 1600,
    //        3.72 um piksel, B-V 0.6, dec -29.
    //
    // Elle:
    //   akis(V=8)   = 8.94e5 × 10^-3.2      = 564 foton/cm2/s
    //   aciklik     = pi × (0.25 cm)^2      = 0.196 cm2
    //   × T=0.9                             = 0.177 cm2
    //   sonum       = 10^(-0.4 × 0.61)      = 0.570
    //   bant        = 10^(-0.4 × 0.06)      = 0.946
    //   yildiz      = 564×0.946×0.570×0.177×0.45 = 24.2 e-/s
    test('yildiz sinyali 24.2 e-/s', () {
      final r = _report(calibration: _testCalibration());
      expect(r.starElectronsPerSecond.valueOrNull, closeTo(24.2, 0.15));
    });

    //   akis(21/arcsec2) = 8.94e5 × 10^-8.4 = 3.56e-3
    //   piksel aci       = 54.8^2           = 3003 arcsec2
    //   → 10.68 foton/cm2/s/px × 0.177 × 0.45 = 0.851 e-/px/s
    test('fon 0.851 e-/px/s', () {
      final r = _report(calibration: _testCalibration());
      expect(
        r.skyElectronsPerPixelPerSecond.valueOrNull,
        closeTo(0.851, 0.005),
      );
    });

    //   iz = 15.04 × cos(29) × 15 / 54.8 = 3.60 px
    test('iz 3.60 px', () {
      final r = _report(calibration: _testCalibration());
      expect(r.trailPixels, closeTo(3.60, 0.03));
    });

    //   sinyal 363 e-, ayak izi 7.63 px, piksel basina gurultu
    //   12.8 + 0.75 + 4.15 = 17.7 → SNR = 363/sqrt(498) = 16.3
    test('SNR 16.3', () {
      final r = _report(calibration: _testCalibration());
      expect(r.snr.valueOrNull, closeTo(16.3, 0.2));
    });

    //   (0.851+0.05)×15 = 13.5 e- → /0.1265 = 107 ADU
    //   +2049 bias = 2156 / 16383 = %13
    test('histogram %13', () {
      final r = _report(calibration: _testCalibration());
      expect(r.histogramFill.valueOrNull, closeTo(0.132, 0.004));
    });

    test('14 mm f/2.8 acikligi gercekten kucuk — 5 mm cap', () {
      // Genis aci astrofotografinin temel kisiti. 24 e-/s bir V=8 yildiz
      // icin az gorunuyor cunku toplama alani 0.2 cm2.
      expect(
        apertureAreaCm2(focalLengthMm: 14, fNumber: 2.8),
        closeTo(0.196, 0.001),
      );
    });
  });
}
