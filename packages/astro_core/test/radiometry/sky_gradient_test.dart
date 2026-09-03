import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

/// T6.6 — Gokyuzu fonunun yukseklige gore degisimi.
///
/// Onemi: projenin ana hedefi 24 derecede duruyor ve orada fon,
/// basucuna gore yarim kadir daha parlak. Tek sayilik fon modeli
/// SNR'i iyimser gosterirdi.
void main() {
  const k = Measured(value: 0.30, unit: 'kadir/X', source: 'TEST');

  group('Van Rhijn fonksiyonu', () {
    test('basucunda tam 1', () {
      expect(vanRhijnFactor(90), closeTo(1.0, 1e-12));
    });

    test('alcaldikca buyuyor', () {
      var previous = 0.0;
      for (final alt in [90.0, 60.0, 45.0, 30.0, 20.0, 10.0]) {
        final v = vanRhijnFactor(alt);
        expect(v, greaterThan(previous), reason: '$alt derece');
        previous = v;
      }
    });

    test('ufukta SONLU kaliyor — sec z sonsuza giderdi', () {
      // Katman sonlu yukseklikte oldugu icin ufukta bile sinirli.
      // Duz sec(z) yaklasimi burada patlardi.
      // 1/sqrt(1 - (6378/6468)^2) = 6.015. Ilk yazimda 11.6
      // beklemistim — yanlisti, kod dogruydu.
      final horizon = vanRhijnFactor(0);
      expect(horizon.isFinite, isTrue);
      expect(horizon, closeTo(6.015, 0.01));
    });

    test('24 derecede ~2.3', () {
      expect(vanRhijnFactor(24), closeTo(2.30, 0.02));
    });

    test('daha yuksek katman daha az etki', () {
      // Katman ne kadar yuksekse yol uzamasi o kadar az.
      expect(
        vanRhijnFactor(20, layerHeightKm: 300),
        lessThan(vanRhijnFactor(20, layerHeightKm: 90)),
      );
    });
  });

  group('Yukseklige gore fon', () {
    double at(double alt) => skyBrightnessAtAltitude(
      zenithMagPerSquareArcsec: 21.5,
      altitudeDegrees: alt,
      extinctionCoefficient: k,
    ).valueOrNull!;

    test('basucunda degismiyor', () {
      // Tam sifir degil: Kasten-Young uydurmasi basucunda X = 0.99971
      // veriyor (tam 1 degil, bilinen bir ozellik). Bu 8.6e-5 kadirlik
      // bir etki — olcum belirsizliginin binde biri, ihmal edilebilir.
      // Toleransi 1e-9 tutmak modeli degil uydurmanin yuvarlanmasini
      // test etmek olurdu.
      expect(at(90), closeTo(21.5, 1e-3));
    });

    test('24 derecede 0.47 kadir daha PARLAK', () {
      // Daha parlak = daha kucuk kadir.
      expect(at(24), closeTo(21.5 - 0.47, 0.02));
      expect(at(24), lessThan(at(90)));
    });

    test('projenin calistigi bolgede etki ihmal edilemez', () {
      // Yarim kadir, akista %55 fark demek. SNR hesabina dogrudan girer.
      final ratio = relativeBrightness(at(24)) / relativeBrightness(at(90));
      expect(ratio, greaterThan(1.4));
    });

    test('cok alcakta sonum baskin cikmaya basliyor', () {
      // Van Rhijn artiyor ama sonum de artiyor; egri bir yerde
      // tepe yapip donuyor. Fizik boyle; model bunu yakalamali.
      final peak = [
        for (var a = 5.0; a <= 40.0; a += 1.0) (a, at(a)),
      ].reduce((p, q) => p.$2 < q.$2 ? p : q);
      expect(
        peak.$1,
        inInclusiveRange(15.0, 25.0),
        reason: 'en parlak nokta ${peak.$1} derecede',
      );
    });

    test('sonum katsayisi yoksa hesap yapilmiyor', () {
      final r = skyBrightnessAtAltitude(
        zenithMagPerSquareArcsec: 21.5,
        altitudeDegrees: 24,
      );
      expect(r.isKnown, isFalse);
      expect(r.missing.single.symbol, 'k');
    });

    test('buyuk sonum gradyani BASTIRIYOR', () {
      // Pusli gecede alcaktaki isik daha cok yutuluyor; net artis azalir.
      double withK(double kv) => skyBrightnessAtAltitude(
        zenithMagPerSquareArcsec: 21.5,
        altitudeDegrees: 24,
        extinctionCoefficient: Measured(
          value: kv,
          unit: 'kadir/X',
          source: 'TEST',
        ),
      ).valueOrNull!;
      expect(withK(0.6), greaterThan(withK(0.15)));
    });
  });

  group('Yapay parlama — olculur, modellenmez', () {
    const glow = SkyGlow(
      azimuthDegrees: 180,
      horizonBoostMagnitudes: Measured(
        value: 1.2,
        unit: 'kadir',
        source: 'TEST',
      ),
    );

    test('sehir yonunde en guclu', () {
      final toward = glow.magnitudeBoostAt(10, 180);
      final away = glow.magnitudeBoostAt(10, 0);
      expect(toward, greaterThan(away));
    });

    test('sirtini donunce SIFIR degil — parlama sacilir', () {
      expect(glow.magnitudeBoostAt(10, 0), greaterThan(0));
    });

    test('yukseldikce zayifliyor', () {
      expect(
        glow.magnitudeBoostAt(60, 180),
        lessThan(glow.magnitudeBoostAt(10, 180)),
      );
    });

    test('fona uygulaninca daha parlak yapiyor', () {
      final without = skyBrightnessAt(
        zenithMagPerSquareArcsec: 21.5,
        altitudeDegrees: 20,
        azimuthDegrees: 180,
        extinctionCoefficient: k,
      ).valueOrNull!;
      final with_ = skyBrightnessAt(
        zenithMagPerSquareArcsec: 21.5,
        altitudeDegrees: 20,
        azimuthDegrees: 180,
        extinctionCoefficient: k,
        artificialGlow: glow,
      ).valueOrNull!;
      expect(with_, lessThan(without));
    });

    test('verilmezse dogal gradyanla ayni — iyimser alt sinir', () {
      final a = skyBrightnessAt(
        zenithMagPerSquareArcsec: 21.5,
        altitudeDegrees: 20,
        azimuthDegrees: 180,
        extinctionCoefficient: k,
      ).valueOrNull!;
      final b = skyBrightnessAtAltitude(
        zenithMagPerSquareArcsec: 21.5,
        altitudeDegrees: 20,
        extinctionCoefficient: k,
      ).valueOrNull!;
      expect(a, closeTo(b, 1e-12));
    });

    test('eksik buyukluk olarak kayitli', () {
      expect(artificialGlowMissing.symbol, 'glow');
      expect(artificialGlowMissing.why, contains('olculur'));
    });
  });

  _extrapolationTests();
}

/// Fon olcumunun yonu — tek olcumle gokyuzu ayrisamaz.
void _extrapolationTests() {
  group('Fon olcumu yonu — tahmin uyarisi', () {
    ExposureReport report({double? measuredAtB, double? targetB}) =>
        buildExposureReport(
          targetName: 'test',
          vMagnitude: 8,
          altitudeDegrees: 45,
          declinationDegrees: 0,
          focalLengthMm: 18,
          fNumber: 3.5,
          exposureSeconds: 15,
          sensor: canon760dIso1600,
          pixelPitchMicrometers: 3.72,
          targetGalacticLatitude: targetB,
          calibration: CalibrationSet(
            skyMeasuredAtGalacticLatitude: measuredAtB,
          ),
        );

    test('ayni enlemde olculmusse uyari yok', () {
      final r = report(measuredAtB: -31, targetB: -28);
      expect(r.skyExtrapolationDegrees, closeTo(3, 1e-9));
      expect(r.skyExtrapolationWarning, isNull);
    });

    test('Samanyolu seridine tahmin yurutulurse UYARIYOR', () {
      // Pegasus'ta (b=-31) olculup galaktik merkez icin (b=0)
      // tahmin yurutmek: 31 derecelik ekstrapolasyon.
      final r = report(measuredAtB: -31, targetB: 0);
      expect(r.skyExtrapolationDegrees, closeTo(31, 1e-9));
      expect(r.skyExtrapolationWarning, isNotNull);
      expect(r.skyExtrapolationWarning, contains('31'));
    });

    test('olcum yonu bilinmiyorsa uyari da yok', () {
      // Sessizce guvenli varsaymak yerine bilgi yoklugu bildiriliyor:
      // uyari uretilemiyor cunku karsilastirilacak sey yok.
      final r = report(measuredAtB: null, targetB: 0);
      expect(r.skyExtrapolationDegrees, isNull);
      expect(r.skyExtrapolationWarning, isNull);
    });

    test('esik 20 derece', () {
      expect(
        report(measuredAtB: 0, targetB: 19).skyExtrapolationWarning,
        isNull,
      );
      expect(
        report(measuredAtB: 0, targetB: 21).skyExtrapolationWarning,
        isNotNull,
      );
    });
  });
}
