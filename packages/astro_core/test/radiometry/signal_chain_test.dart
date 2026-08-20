import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

/// Faz 5 iskeleti. En kritik test grubu "reddetme" — kalibrasyonu
/// gelmemis buyukluk varsayilan tasimak yerine hesap yapmayi
/// reddediyor mu.
void main() {
  group('T5.1 — kadirden foton akisina', () {
    test('sifir noktasi sabitlerden turetiliyor, elle yazilmiyor', () {
      // F_lambda / (hc/lambda) = 3.63e-9 / 3.61e-12 ~ 1005
      expect(vBandZeroPointPhotonFlux, closeTo(1005, 5));
      // Bant boyunca toplam ~8.9e5 foton/cm2/s. Literaturde V=0 icin
      // "yaklasik 10^6 foton/cm2/s" diye gecer.
      expect(vBandZeroPointTotalPhotonFlux, closeTo(8.9e5, 0.2e5));
    });

    test('V=0 sifir noktasinin kendisini veriyor', () {
      expect(
        photonFluxFromMagnitude(0),
        closeTo(vBandZeroPointTotalPhotonFlux, 1e-6),
      );
    });

    test('5 kadir tam 100 kat', () {
      // Kadir olceginin tanimi. Tutmuyorsa 2.512 tabanini yanlis
      // kullanmisiz demektir.
      expect(
        photonFluxFromMagnitude(0) / photonFluxFromMagnitude(5),
        closeTo(100.0, 1e-9),
      );
    });

    test('Sirius Vega\'dan parlak', () {
      expect(
        photonFluxFromMagnitude(-1.46),
        greaterThan(photonFluxFromMagnitude(0.03)),
      );
    });
  });

  group('T5.3 — hava kutlesi', () {
    test('basucunda 1', () {
      expect(airmassKastenYoung(90), closeTo(1.0, 0.001));
    });

    test('30 derecede ~2', () {
      // Duz 1/sin(h) yaklasimi burada tam 2.00 der; Kasten-Young
      // atmosferin egriligini hesaba kattigi icin cok az farkli.
      expect(airmassKastenYoung(30), closeTo(2.0, 0.02));
    });

    test('ufukta sonlu kaliyor — 1/cos z sonsuza giderdi', () {
      final horizon = airmassKastenYoung(0);
      expect(horizon, greaterThan(30));
      expect(horizon, lessThan(45));
      expect(horizon.isFinite, isTrue);
    });

    test('yukseklik azaldikca hava kutlesi artiyor', () {
      var previous = 0.0;
      for (final alt in [90.0, 60.0, 45.0, 30.0, 20.0, 10.0]) {
        final x = airmassKastenYoung(alt);
        expect(x, greaterThan(previous), reason: '$alt derece');
        previous = x;
      }
    });

    test('projenin calistigi bolge: 24 derecede X ~ 2.4', () {
      // Galaktik merkezin zirvesi. Modelin en cok zorlandigi yer burasi
      // ve tam da kalibrasyonun onemli oldugu yer.
      expect(airmassKastenYoung(24), closeTo(2.44, 0.05));
    });
  });

  group('T5.4 — optik toplama', () {
    test('aciklik alani geometriden: 50mm f/2 -> capi 25mm', () {
      // D = 50/2 = 25 mm = 2.5 cm, alan = pi * 1.25^2 = 4.909 cm2
      expect(
        apertureAreaCm2(focalLengthMm: 50, fNumber: 2.0),
        closeTo(4.909, 0.001),
      );
    });

    test('bir diyafram durak alani yariya indiriyor', () {
      final wide = apertureAreaCm2(focalLengthMm: 50, fNumber: 2.0);
      final narrow = apertureAreaCm2(focalLengthMm: 50, fNumber: 2.828);
      expect(wide / narrow, closeTo(2.0, 0.01));
    });
  });

  group('REDDETME — kalibrasyonsuz hesap yapilmiyor', () {
    test('sonum katsayisi yoksa sayi donmuyor', () {
      final r = extinctionMagnitudes(altitudeDegrees: 24);
      expect(r.isKnown, isFalse);
      expect(r.valueOrNull, isNull);
      expect(r.missing.single.symbol, 'k');
    });

    test('katsayi verilince hesapliyor', () {
      final r = extinctionMagnitudes(
        altitudeDegrees: 24,
        extinctionCoefficient: const Measured(
          value: 0.25,
          unit: 'kadir/X',
          source: 'test',
        ),
      );
      expect(r.isKnown, isTrue);
      // X(24) = 2.44, k=0.25 -> 0.61 kadir
      expect(r.valueOrNull, closeTo(0.61, 0.02));
    });

    test('aktarim verimi yoksa efektif aciklik hesaplanmiyor', () {
      final r = effectiveApertureAreaCm2(focalLengthMm: 14, fNumber: 2.8);
      expect(r.isKnown, isFalse);
      expect(r.missing.single.symbol, 'T');
    });

    test('tam zincir bugun DORT eksik bildiriyor', () {
      final r = starElectronRate(
        vMagnitude: 0.03,
        altitudeDegrees: 24,
        focalLengthMm: 14,
        fNumber: 2.8,
        colorIndexBV: 0.0,
      );
      expect(r.isKnown, isFalse);
      expect(r.valueOrNull, isNull);
      final symbols = r.missing.map((q) => q.symbol).toSet();
      expect(symbols, containsAll(['dV_G', 'k', 'T', 'QE']));
      expect(
        symbols.length,
        4,
        reason: 'eksikler birikmeli, ilkinde durmamali',
      );
    });

    test('eksikler birikiyor, ilkinde durmuyor', () {
      // Bir tanesi verilirse geri kalan uc tanesi hala bildirilmeli.
      final r = starElectronRate(
        vMagnitude: 0.03,
        altitudeDegrees: 24,
        focalLengthMm: 14,
        fNumber: 2.8,
        colorIndexBV: 0.0,
        lensTransmission: const Measured(value: 0.9, unit: '-', source: 'test'),
      );
      final symbols = r.missing.map((q) => q.symbol).toSet();
      expect(symbols, isNot(contains('T')));
      expect(symbols.length, 3);
    });

    test('hepsi verilince zincir gercekten sayi uretiyor', () {
      const m = Measured(value: 0.0, unit: '-', source: 'test');
      final r = starElectronRate(
        vMagnitude: 0.0,
        altitudeDegrees: 90,
        focalLengthMm: 50,
        fNumber: 2.0,
        colorIndexBV: 0.0,
        extinctionCoefficient: m,
        lensTransmission: const Measured(value: 1.0, unit: '-', source: 'test'),
        quantumEfficiency: const Measured(
          value: 1.0,
          unit: 'e-/foton',
          source: 'test',
        ),
        bandCorrectionPerColorIndex: m,
      );
      expect(r.isKnown, isTrue);
      // Kayipsiz durumda: akis × alan. 50mm f/2 -> 4.909 cm2.
      expect(
        r.valueOrNull,
        closeTo(vBandZeroPointTotalPhotonFlux * 4.909, 1e3),
      );
    });

    test('renk indeksi bilinmeyen yildiz icin de reddediliyor', () {
      final r = starElectronRate(
        vMagnitude: 5.0,
        altitudeDegrees: 45,
        focalLengthMm: 14,
        fNumber: 2.8,
        colorIndexBV: null,
        bandCorrectionPerColorIndex: const Measured(
          value: 0.1,
          unit: 'kadir',
          source: 'test',
        ),
      );
      expect(r.isKnown, isFalse);
      expect(r.missing.map((q) => q.symbol), contains('B-V'));
    });

    test('bekleyen kalibrasyon listesi alti buyuklugu sayiyor', () {
      expect(pendingCalibration().length, 6);
    });

    test('her eksik buyuklugun gerekcesi yazili', () {
      // Gerekcesi yazilamayan eksiklik, muhtemelen eksiklik degil.
      for (final q in allMissingQuantities) {
        expect(q.why.length, greaterThan(40), reason: q.symbol);
        expect(q.comesFrom, isNotEmpty, reason: q.symbol);
        expect(q.unit, isNotEmpty, reason: q.symbol);
      }
    });
  });

  group('T5.7 — olculmus sensor verisi', () {
    test('uc ISO da olculmus', () {
      expect(measuredSensorProfiles.length, 3);
      for (final p in measuredSensorProfiles) {
        expect(p.gain.value, greaterThan(0));
        expect(p.readNoise.value, greaterThan(0));
        expect(p.gain.source, contains('Faz 0.A'));
      }
    });

    test('kazanc ISO ile ters orantili', () {
      // ISO iki katina cikinca kazanc yariya inmeli. Olculen degerler
      // bunu %10 icinde tutuyor — tutmasaydi olcumde sorun olurdu.
      expect(
        canon760dIso800.gain.value / canon760dIso1600.gain.value,
        closeTo(2.0, 0.2),
      );
      expect(
        canon760dIso1600.gain.value / canon760dIso3200.gain.value,
        closeTo(2.0, 0.2),
      );
    });

    test('kazancin belirsizligi kayitli — %17', () {
      // referans-karsilastirma.md'deki sistematik sapma. Belirsizligi
      // tasimayan olcum, tasidigi sayi kadar yaniltici.
      for (final p in measuredSensorProfiles) {
        expect(p.gain.relativeUncertainty, closeTo(0.17, 0.001));
      }
    });

    test('olculmemis ISO icin profil yok', () {
      expect(
        measuredProfileFor(cameraName: 'Canon EOS 760D', iso: 400),
        isNull,
      );
      expect(
        measuredProfileFor(cameraName: 'Canon EOS 760D', iso: 1600),
        isNotNull,
      );
    });

    test('taban ISO\'ya goturulen dolum kapasitesi tutarli', () {
      // Uc bagimsiz olcumun ayni fiziksel buyukluge yakinsamasi.
      final referred = [
        canon760dIso800.fullWell.value * 8,
        canon760dIso1600.fullWell.value * 16,
        canon760dIso3200.fullWell.value * 32,
      ];
      final mean = referred.reduce((a, b) => a + b) / 3;
      for (final r in referred) {
        expect((r - mean).abs() / mean, lessThan(0.06));
      }
    });
  });

  group('T5.9 — gurultu', () {
    test('karanlik akim yoksa gurultu hesaplanmiyor', () {
      final r = totalNoiseElectrons(
        signalElectrons: const RadiometricValue(1000, 'e-'),
        sensor: canon760dIso1600,
        exposureSeconds: 15,
      );
      expect(r.isKnown, isFalse);
      expect(r.missing.single.symbol, 'I_d');
    });

    test('verilince shot + okuma + karanlik toplaniyor', () {
      final r = totalNoiseElectrons(
        signalElectrons: const RadiometricValue(1000, 'e-'),
        sensor: canon760dIso1600,
        exposureSeconds: 15,
        darkCurrentElectronsPerSecond: const Measured(
          value: 0.1,
          unit: 'e-/px/s',
          source: 'test',
        ),
      );
      // sqrt(1000 + 2.037^2 + 1.5) = sqrt(1005.6) = 31.71
      expect(r.valueOrNull, closeTo(31.71, 0.05));
    });

    test('sinyal yoksa gurultu de bilinmiyor', () {
      final r = totalNoiseElectrons(
        signalElectrons: RadiometricGap.single(quantumEfficiencyMissing),
        sensor: canon760dIso1600,
        exposureSeconds: 15,
        darkCurrentElectronsPerSecond: const Measured(
          value: 0.1,
          unit: 'e-/px/s',
          source: 'test',
        ),
      );
      expect(r.isKnown, isFalse);
    });

    test('SNR zincirin eksigini devraliyor', () {
      final snr = signalToNoise(
        signalElectrons: RadiometricGap.single(quantumEfficiencyMissing),
        noiseElectrons: const RadiometricValue(30, 'e-'),
      );
      expect(snr.isKnown, isFalse);
      expect(snr.missing.single.symbol, 'QE');
    });
  });
}
