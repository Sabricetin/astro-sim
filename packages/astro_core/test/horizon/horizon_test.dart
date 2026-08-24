import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

/// T7 — Ufuk profili.
///
/// Yol haritasi bunu "farklilastirici" diye isaretlemis, ama projenin
/// ana hedefi (galaktik merkez ~24 derece) neredeyse her konumda bir
/// sirt tarafindan kesildigi icin aslinda ON KOSUL.
void main() {
  group('Profil kurma', () {
    test('duz ufuk her yerde sifir', () {
      final h = Horizon.flat();
      expect(h.isFlat, isTrue);
      for (final az in [0.0, 90.0, 180.0, 270.0, 359.9]) {
        expect(h.altitudeAt(az), closeTo(0, 1e-12));
      }
    });

    test('tek nokta her yone yayiliyor', () {
      final h = Horizon.fromPoints({90.0: 12.0});
      expect(h.altitudeAt(0), closeTo(12, 1e-9));
      expect(h.altitudeAt(270), closeTo(12, 1e-9));
    });

    test('iki nokta arasi dogrusal', () {
      final h = Horizon.fromPoints({0.0: 0.0, 180.0: 20.0});
      expect(h.altitudeAt(0), closeTo(0, 1e-9));
      expect(h.altitudeAt(90), closeTo(10, 0.1));
      expect(h.altitudeAt(180), closeTo(20, 1e-9));
      // Geri donusde de dogrusal: 180 -> 360 arasi 20'den 0'a.
      expect(h.altitudeAt(270), closeTo(10, 0.1));
    });

    test('interpolasyon CEMBER uzerinde sariliyor', () {
      // 350 ile 10 derece komsu; aralarindaki deger ortalamaya yakin
      // olmali. Duz dizi mantigiyla 340 derecelik yoldan gidilseydi
      // sonuc tamamen farkli olurdu.
      final h = Horizon.fromPoints({350.0: 10.0, 10.0: 20.0});
      expect(h.altitudeAt(0), closeTo(15, 0.5));
    });

    test('noktalar sirasiz verilebilir', () {
      final a = Horizon.fromPoints({270.0: 5.0, 0.0: 0.0, 90.0: 10.0});
      final b = Horizon.fromPoints({0.0: 0.0, 90.0: 10.0, 270.0: 5.0});
      for (final az in [0.0, 45.0, 135.0, 200.0, 300.0]) {
        expect(a.altitudeAt(az), closeTo(b.altitudeAt(az), 1e-9));
      }
    });

    test('negatif ve 360 ustu azimutlar normalize ediliyor', () {
      final h = Horizon.fromPoints({0.0: 0.0, 180.0: 20.0});
      expect(h.altitudeAt(-90), closeTo(h.altitudeAt(270), 1e-9));
      expect(h.altitudeAt(450), closeTo(h.altitudeAt(90), 1e-9));
    });

    test('yanlis uzunlukta ornek dizisi reddediliyor', () {
      expect(
        () => Horizon.fromSamples([1, 2, 3], source: 'test'),
        throwsArgumentError,
      );
    });

    test('en yuksek nokta bulunuyor', () {
      final h = Horizon.fromPoints({0.0: 2.0, 120.0: 25.0, 240.0: 8.0});
      final (alt, az) = h.highest;
      expect(alt, closeTo(25, 0.2));
      expect(az, closeTo(120, 1.5));
    });

    test('kapatilan gokyuzu orani makul', () {
      expect(Horizon.flat().blockedSkyFraction, closeTo(0, 1e-12));
      // Her yonde 30 derece: sin(30) = 0.5
      expect(Horizon.flat(30).blockedSkyFraction, closeTo(0.5, 0.001));
    });
  });

  group('Plan — ufuk pencereyi kisiyor', () {
    final mersin = Observer(
      latitudeDegrees: 36.80,
      longitudeEastDegrees: 34.62,
      elevationMeters: 10,
    );
    final galacticCenter = Equatorial.fromHours(
      rightAscensionHours: 17 + 45 / 60 + 40.0 / 3600,
      declinationDegrees: -(29 + 28.0 / 3600),
    );
    final when = DateTime.utc(2026, 7, 15, 22);

    NightPlan plan({Horizon? horizon}) => planNight(
      target: galacticCenter,
      observer: mersin,
      aroundUtc: when,
      horizon: horizon,
    );

    test('duz ufukta pencere degismiyor', () {
      final a = plan();
      final b = plan(horizon: Horizon.flat());
      expect(a.best!.duration, b.best!.duration);
      expect(b.lostToHorizon, Duration.zero);
      expect(b.blockedByHorizon, isNull);
    });

    // Gercek bir dag sirti GENIS bir azimut araligini kaplar. Ilk
    // yazimda sirti yalnizca 180 derecede tepe yapacak sekilde
    // tanimlamistim; interpolasyon onu hizla dusurunce hedef kenardan
    // siyriliyordu. Galaktik merkez pencere boyunca 168-205 derece
    // arasinda geziyor, sirt o araligi kapsamali.
    Horizon southRidge(double altitude) => Horizon.fromPoints({
      0.0: 0.0,
      90.0: 0.0,
      130.0: altitude,
      180.0: altitude,
      230.0: altitude,
      280.0: 0.0,
    });

    test('guney sirti pencereyi tamamen kapatiyor', () {
      // Galaktik merkez guneyde 24.2 derecede zirve yapiyor; 28
      // derecelik bir sirt onu hic gostermez.
      expect(plan().best, isNotNull);
      expect(
        plan(horizon: southRidge(28)).best,
        isNull,
        reason: 'zirveden yuksek sirt hedefi hic gostermez',
      );
    });

    test('alcak sirt pencereyi kirpiyor ama bitirmiyor', () {
      final flat = plan().best!.duration;
      final ridged = plan(horizon: southRidge(22));
      expect(ridged.best, isNotNull);
      expect(ridged.best!.duration, lessThan(flat));
      expect(ridged.lostToHorizon.inMinutes, greaterThan(0));
    });

    test('DOGU sirti guneydeki hedefi etkilemiyor', () {
      // Ufuk yone bagli. Yanlis kurulmus bir model burada da kaybettirirdi.
      final flat = plan().best!.duration;
      final east = plan(
        horizon: Horizon.fromPoints({
          90.0: 40.0,
          180.0: 0.0,
          270.0: 0.0,
          0.0: 0.0,
        }),
      );
      expect(east.best!.duration, flat);
      expect(east.lostToHorizon, Duration.zero);
    });

    test('esik ve ufuk BIRBIRININ YERINE gecmiyor', () {
      // 10 derecelik sirt, 20 derecelik hava kutlesi esiginin altinda:
      // hicbir sey degismemeli. Etkin esik ikisinin buyugu.
      final flat = plan().best!.duration;
      final low = plan(horizon: Horizon.flat(10));
      expect(low.best!.duration, flat);
    });

    test('engellenen aralik raporlaniyor', () {
      final p = plan(horizon: southRidge(22.5));
      final blocked = p.blockedByHorizon;
      expect(blocked, isNotNull);
      expect(blocked!.duration.inMinutes, greaterThan(0));
      // Engellenen sure, kaybedilen sureden buyuk olamaz.
      expect(
        blocked.duration.inMinutes,
        lessThanOrEqualTo(p.lostToHorizon.inMinutes + 1),
      );
    });

    test('hedefin azimutu ornekte tasiniyor', () {
      final p = plan();
      for (final s in p.samples) {
        expect(s.targetAzimuthDegrees, inInclusiveRange(0, 360));
      }
      // Galaktik merkez zirvede guneyde olmali.
      final peak = p.samples.reduce(
        (a, b) => a.targetAltitudeDegrees > b.targetAltitudeDegrees ? a : b,
      );
      expect(peak.targetAzimuthDegrees, closeTo(180, 15));
    });
  });
}
