import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

/// Kalibrasyon dosyasi Python araclarindan geliyor, uygulama okuyor.
/// Iki tarafin ayni bicimden gecmesi, sahadan donen olcumun elle
/// kopyalanmadan arayuze girmesini sagliyor.
void main() {
  const full = '''
{
  "format": "astro-sim-kalibrasyon",
  "version": 1,
  "source": "Faz 0.B, faz0b, ISO 1600",
  "measured_at": "2026-09-11",
  "extinction_coefficient_k": 0.312,
  "extinction_k_uncertainty": 0.018,
  "zero_point_f_number": 11.0,
  "identified_star_hr": 7001,
  "psf_fwhm_px": 2.15,
  "dark_current_e_per_px_per_s": 0.042,
  "sky_instrumental_e_per_px_per_s": 1.83,
  "photometric_zero_point": 17.42,
  "sky_mag_per_sq_arcsec": 20.31,
  "iso": 1600,
  "gain_used": 0.1265,
  "focal_length_mm": 14.0,
  "pixel_pitch_um": 3.72
}
''';

  group('Dolu defter', () {
    test('butun degerler okunuyor', () {
      final l = parseCalibrationJson(full);
      final c = l.calibration;
      expect(c.extinctionCoefficient!.value, closeTo(0.312, 1e-9));
      expect(c.zeroPoint!.value, closeTo(17.42, 1e-9));
      expect(c.zeroPointFNumber, 11.0);
      expect(c.darkCurrent!.value, closeTo(0.042, 1e-9));
      expect(c.skyMagPerSquareArcsec!.value, closeTo(20.31, 1e-9));
      expect(c.psfFwhmPixels!.value, closeTo(2.15, 1e-9));
      expect(l.identifiedStarHr, 7001);
      expect(l.iso, 1600);
    });

    test('her degere kaynak isleniyor', () {
      final c = parseCalibrationJson(full).calibration;
      for (final m in [
        c.extinctionCoefficient!,
        c.zeroPoint!,
        c.darkCurrent!,
        c.skyMagPerSquareArcsec!,
        c.psfFwhmPixels!,
      ]) {
        expect(m.source, contains('Faz 0.B'));
      }
    });

    test('k belirsizligi BAGIL degere cevriliyor', () {
      // Dosyada mutlak (0.018 kadir/X), Measured bagil bekliyor.
      final c = parseCalibrationJson(full).calibration;
      expect(
        c.extinctionCoefficient!.relativeUncertainty,
        closeTo(0.018 / 0.312, 1e-9),
      );
    });

    test('bant duzeltmesi hala eksik — tek kalan', () {
      final c = parseCalibrationJson(full).calibration;
      expect(c.missing.map((q) => q.symbol), ['dV_G']);
      expect(c.completedCount, CalibrationSet.linkCount - 1);
    });
  });

  group('REDDETME — kaynaksiz deger kabul edilmiyor', () {
    test('source alani yoksa okuma reddediliyor', () {
      const noSource = '{"extinction_coefficient_k": 0.3}';
      expect(
        () => parseCalibrationJson(noSource),
        throwsA(
          isA<CalibrationFormatException>().having(
            (e) => e.message,
            'mesaj',
            contains('source'),
          ),
        ),
      );
    });

    test('bos source de reddediliyor', () {
      expect(
        () => parseCalibrationJson('{"source": "   ", "psf_fwhm_px": 2}'),
        throwsA(isA<CalibrationFormatException>()),
      );
    });

    test('reddetme gerekcesi aciklaniyor', () {
      try {
        parseCalibrationJson('{"psf_fwhm_px": 2}');
        fail('atmali');
      } on CalibrationFormatException catch (e) {
        // Kullaniciya sadece "hata" demek yetmez; NEDEN reddedildigi
        // yazmali, yoksa kural keyfi gorunur.
        expect(e.message.length, greaterThan(80));
        expect(e.message, contains('uydurma'));
      }
    });
  });

  group('Bicim korumalari', () {
    test('baska bir uygulamanin dosyasi reddediliyor', () {
      expect(
        () => parseCalibrationJson('{"format": "baska-sey", "source": "x"}'),
        throwsA(isA<CalibrationFormatException>()),
      );
    });

    test('ileri surum reddediliyor, guncelleme soyleniyor', () {
      try {
        parseCalibrationJson('{"version": 7, "source": "x"}');
        fail('atmali');
      } on CalibrationFormatException catch (e) {
        expect(e.message, contains('guncelle'));
      }
    });

    test('bozuk JSON anlasilir hata veriyor', () {
      expect(
        () => parseCalibrationJson('{bu json degil'),
        throwsA(isA<CalibrationFormatException>()),
      );
    });

    test('JSON dizisi reddediliyor', () {
      expect(
        () => parseCalibrationJson('[1,2,3]'),
        throwsA(isA<CalibrationFormatException>()),
      );
    });

    test('tanimayan alanlar SESSIZCE yutulmuyor', () {
      // Ileri surumden gelen bir dosya oldugunu anlamanin tek yolu.
      final l = parseCalibrationJson(
        '{"source": "x", "psf_fwhm_px": 2, "gelecek_alan": 5, "baska": 1}',
      );
      expect(l.unknownFields, ['baska', 'gelecek_alan']);
    });
  });

  group('Eksik defter — kismi olcum', () {
    test('sadece bazi degerler varsa gerisi eksik kaliyor', () {
      final l = parseCalibrationJson(
        '{"source": "yarim gece", "extinction_coefficient_k": 0.28}',
      );
      final syms = l.calibration.missing.map((q) => q.symbol).toSet();
      expect(syms, isNot(contains('k')));
      expect(syms, containsAll(['ZP', 'I_d', 'mu_sky', 'FWHM', 'dV_G']));
      expect(l.calibration.completedCount, 1);
    });

    test('bos ama kaynakli dosya gecerli — hicbir sey olculmemis', () {
      final l = parseCalibrationJson('{"source": "bulutlu gece"}');
      expect(l.calibration.completedCount, 0);
      expect(l.source, 'bulutlu gece');
    });
  });

  group('Rapor gercek olcumle doluyor', () {
    test('yuklenen defterle zincir sayi uretiyor', () {
      final l = parseCalibrationJson(full);
      // dV_G disinda hepsi var; onu ekleyip tam rapor kuruyoruz.
      final c = CalibrationSet(
        extinctionCoefficient: l.calibration.extinctionCoefficient,
        zeroPoint: l.calibration.zeroPoint,
        zeroPointFNumber: l.calibration.zeroPointFNumber,
        bandCorrectionPerColorIndex: const Measured(
          value: 0.0,
          unit: 'kadir',
          source: 'TEST',
        ),
        darkCurrent: l.calibration.darkCurrent,
        skyMagPerSquareArcsec: l.calibration.skyMagPerSquareArcsec,
        psfFwhmPixels: l.calibration.psfFwhmPixels,
      );
      final r = buildExposureReport(
        targetName: 'M13',
        vMagnitude: 5.8,
        altitudeDegrees: 60,
        declinationDegrees: 36.5,
        focalLengthMm: 14,
        fNumber: 2.8,
        exposureSeconds: 15,
        sensor: canon760dIso1600,
        pixelPitchMicrometers: 3.72,
        colorIndexBV: 0.6,
        calibration: c,
      );
      expect(r.isComplete, isTrue);
      expect(r.snr.valueOrNull, greaterThan(0));
      expect(r.histogramFill.valueOrNull, greaterThan(0));
      // ZP f/11'de olculdu, rapor f/2.8 — tasima uygulanmali.
      expect(r.starElectronsPerSecond.valueOrNull, greaterThan(0));
    });
  });
}
