import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  group('Meeus 13.b — Venus, Washington DC, 1987-04-10 19:21 UT', () {
    // Referans: Meeus, Astronomical Algorithms, 2. baski, ornek 13.b.
    final venus = Equatorial.fromHours(
      rightAscensionHours: 23 + 9 / 60 + 16.641 / 3600,
      declinationDegrees: -(6 + 43 / 60 + 11.61 / 3600),
    );
    final washington = Observer(
      latitudeDegrees: 38 + 55 / 60 + 17 / 3600,
      // Meeus bati-pozitif yazar (77°03'56" W); biz dogu-pozitifiz.
      longitudeEastDegrees: -(77 + 3 / 60 + 56 / 3600),
    );
    final utc = DateTime.utc(1987, 4, 10, 19, 21);

    // Tolerans 0.01 derece. Meeus GERCEK (apparent) yildiz zamani kullanir,
    // biz ORTALAMA kullaniyoruz; aradaki fark (ekinoksun denklemi) burada
    // ~0.001 derece. Projenin toleransi 0.1 derece, yani 10 kat pay var.
    const tolerance = 0.01;

    test('yukseklik 15.1249 derece', () {
      final h = equatorialToHorizontalAt(
        equatorial: venus,
        observer: washington,
        utc: utc,
      );
      expect(h.altitudeDegrees, closeTo(15.1249, tolerance));
    });

    test('azimut 248.0337 derece (kuzey tabanli)', () {
      // Meeus 68.0337 der ama GUNEY tabanli olcer. Kuzey tabanli = +180.
      // Bu test tam olarak o sozlesme farkini koruyor: kod guney tabanli
      // donseydi 68 cikar ve sessizce 180 derece yanlis olurdu.
      final h = equatorialToHorizontalAt(
        equatorial: venus,
        observer: washington,
        utc: utc,
      );
      expect(h.azimuthDegrees, closeTo(248.0337, tolerance));
    });
  });

  group('gok kutuplari — en guclu fiziksel kontrol', () {
    test('kuzey gok kutbu: yukseklik = enlem, azimut = 0 (Kuzey)', () {
      // Sapmasi +90 olan bir nokta, saat acisindan bagimsiz olarak
      // her zaman kuzeyde ve enlem kadar yuksektedir.
      for (final lat in [0.0, 37.07, 51.5, 89.0]) {
        final h = equatorialToHorizontal(
          equatorial: Equatorial(
            rightAscensionDegrees: 0,
            declinationDegrees: 90,
          ),
          observer: Observer(latitudeDegrees: lat, longitudeEastDegrees: 0),
          localSiderealTimeDegrees: 123.456, // fark etmemeli
        );
        expect(h.altitudeDegrees, closeTo(lat, 1e-9), reason: 'enlem $lat');
        // Dairesel karsilastirma sart: 359.9999... ile 0.0 ayni yondur.
        expect(
          angularDifferenceDegrees(h.azimuthDegrees, 0.0).abs(),
          lessThan(1e-9),
          reason: 'enlem $lat',
        );
      }
    });

    test(
      'guney gok kutbu, guney yarikure: yukseklik = |enlem|, azimut = 180',
      () {
        final h = equatorialToHorizontal(
          equatorial: Equatorial(
            rightAscensionDegrees: 0,
            declinationDegrees: -90,
          ),
          observer: Observer(
            latitudeDegrees: -33.87, // Sydney
            longitudeEastDegrees: 151.2,
          ),
          localSiderealTimeDegrees: 200.0,
        );
        expect(h.altitudeDegrees, closeTo(33.87, 1e-9));
        expect(h.azimuthDegrees, closeTo(180.0, 1e-9));
      },
    );

    test('gozlemci tam kuzey kutbunda: azimut tanimsiz ama patlamamali', () {
      // Enlem 90'da butun yonler guneydir; azimut bozunur. Deger keyfi
      // olabilir ama NaN olmamali ve yukseklik dogru cikmali.
      final h = equatorialToHorizontal(
        equatorial: Equatorial(
          rightAscensionDegrees: 0,
          declinationDegrees: 90,
        ),
        observer: Observer(latitudeDegrees: 90, longitudeEastDegrees: 0),
        localSiderealTimeDegrees: 45.0,
      );
      expect(h.altitudeDegrees, closeTo(90.0, 1e-9));
      expect(h.azimuthDegrees.isNaN, isFalse);
    });
  });

  group('azimut sozlesmesi — kuzeyden, doguya artar', () {
    final observer = Observer(latitudeDegrees: 40.0, longitudeEastDegrees: 0.0);

    test('ekvatordaki cisim, saat acisi -90: tam Dogu\'da, ufukta', () {
      final h = equatorialToHorizontal(
        equatorial: Equatorial(
          rightAscensionDegrees: 90,
          declinationDegrees: 0,
        ),
        observer: observer,
        localSiderealTimeDegrees: 0.0, // H = 0 - 90 = -90 (henuz dogmakta)
      );
      expect(h.azimuthDegrees, closeTo(90.0, 1e-9)); // Dogu
      expect(h.altitudeDegrees, closeTo(0.0, 1e-9));
    });

    test('ekvatordaki cisim, saat acisi +90: tam Bati\'da, ufukta', () {
      final h = equatorialToHorizontal(
        equatorial: Equatorial(
          rightAscensionDegrees: 270,
          declinationDegrees: 0,
        ),
        observer: observer,
        localSiderealTimeDegrees: 0.0, // H = 0 - 270 = -270 -> +90
      );
      expect(h.azimuthDegrees, closeTo(270.0, 1e-9)); // Bati
      expect(h.altitudeDegrees, closeTo(0.0, 1e-9));
    });

    test('basucunun guneyinde, meridyende: azimut 180', () {
      final h = equatorialToHorizontal(
        equatorial: Equatorial(rightAscensionDegrees: 0, declinationDegrees: 0),
        observer: observer,
        localSiderealTimeDegrees: 0.0, // H = 0, meridyende
      );
      expect(h.azimuthDegrees, closeTo(180.0, 1e-9));
      expect(h.altitudeDegrees, closeTo(50.0, 1e-9)); // 90 - 40
    });
  });

  group('uc durumlar', () {
    test('tam basucu: NaN uretmemeli, yukseklik 90', () {
      // sinAlt kayan nokta hatasiyla 1.0000000002 olabilir; clamp olmasa
      // asin NaN dondururdu.
      final h = equatorialToHorizontal(
        equatorial: Equatorial(
          rightAscensionDegrees: 0,
          declinationDegrees: 40,
        ),
        observer: Observer(latitudeDegrees: 40, longitudeEastDegrees: 0),
        localSiderealTimeDegrees: 0.0, // H = 0
      );
      expect(h.altitudeDegrees.isNaN, isFalse);
      expect(h.altitudeDegrees, closeTo(90.0, 1e-6));
    });

    test('ufkun altindaki cisim negatif yukseklik verir', () {
      final h = equatorialToHorizontal(
        equatorial: Equatorial(
          rightAscensionDegrees: 0,
          declinationDegrees: -60,
        ),
        observer: Observer(latitudeDegrees: 60, longitudeEastDegrees: 0),
        localSiderealTimeDegrees: 0.0,
      );
      expect(h.altitudeDegrees, lessThan(0));
      expect(h.isAboveHorizon, isFalse);
    });
  });

  group('gidis-donus: ufuk -> ekvatoral -> ufuk', () {
    test('genis ornekleme uzerinde kapali', () {
      final observer = Observer(
        latitudeDegrees: 37.07,
        longitudeEastDegrees: 37.38,
      );
      const lst = 128.7378733;
      for (var az = 0.0; az < 360.0; az += 37.0) {
        for (var alt = -80.0; alt <= 80.0; alt += 23.0) {
          final start = Horizontal(azimuthDegrees: az, altitudeDegrees: alt);
          final eq = horizontalToEquatorial(
            horizontal: start,
            observer: observer,
            localSiderealTimeDegrees: lst,
          );
          final back = equatorialToHorizontal(
            equatorial: eq,
            observer: observer,
            localSiderealTimeDegrees: lst,
          );
          expect(
            back.altitudeDegrees,
            closeTo(alt, 1e-9),
            reason: 'az=$az alt=$alt',
          );
          expect(
            angularDifferenceDegrees(back.azimuthDegrees, az).abs(),
            lessThan(1e-9),
            reason: 'az=$az alt=$alt',
          );
        }
      }
    });
  });

  group('gorunurluk yardimcilari', () {
    // Galaktik merkez: RA 17h45m40s, Dec -29 derece.
    const galacticCenterDec = -(29 + 0 / 60 + 28 / 3600);
    const gaziantepLat = 37.07;

    test('galaktik merkez Gaziantep\'ten en fazla ~24 dereceye cikar', () {
      // Yol haritasindaki temel iddia bu: proje dusuk yukseklik projesi.
      final maxAlt = maximumAltitudeDegrees(
        declinationDegrees: galacticCenterDec,
        latitudeDegrees: gaziantepLat,
      );
      expect(maxAlt, closeTo(23.92, 0.05));
    });

    test('en yuksek nokta, saat acisi sifirdayken ulasilan degerdir', () {
      final observer = Observer(
        latitudeDegrees: gaziantepLat,
        longitudeEastDegrees: 37.38,
      );
      final target = Equatorial(
        rightAscensionDegrees: 100.0,
        declinationDegrees: galacticCenterDec,
      );
      final atMeridian = equatorialToHorizontal(
        equatorial: target,
        observer: observer,
        localSiderealTimeDegrees: 100.0, // H = 0
      );
      expect(
        atMeridian.altitudeDegrees,
        closeTo(
          maximumAltitudeDegrees(
            declinationDegrees: galacticCenterDec,
            latitudeDegrees: gaziantepLat,
          ),
          1e-9,
        ),
      );
    });

    test('circumpolar / hic dogmayan', () {
      // Kutup yildizi Gaziantep'ten hic batmaz.
      expect(
        isCircumpolar(declinationDegrees: 89.26, latitudeDegrees: gaziantepLat),
        isTrue,
      );
      // Guney gok kutbu Gaziantep'ten hic dogmaz.
      expect(
        isNeverVisible(
          declinationDegrees: -89.0,
          latitudeDegrees: gaziantepLat,
        ),
        isTrue,
      );
      // Galaktik merkez ikisi de degil: dogar, batar.
      expect(
        isCircumpolar(
          declinationDegrees: galacticCenterDec,
          latitudeDegrees: gaziantepLat,
        ),
        isFalse,
      );
      expect(
        isNeverVisible(
          declinationDegrees: galacticCenterDec,
          latitudeDegrees: gaziantepLat,
        ),
        isFalse,
      );
    });
  });

  group('girdi dogrulamasi', () {
    test('sinir disi sapma reddedilir', () {
      expect(
        () => Equatorial(rightAscensionDegrees: 0, declinationDegrees: 91),
        throwsArgumentError,
      );
    });

    test('sinir disi enlem reddedilir', () {
      expect(
        () => Observer(latitudeDegrees: -91, longitudeEastDegrees: 0),
        throwsArgumentError,
      );
    });

    test('boylam [-180, 180) araligina normalize edilir', () {
      expect(
        Observer(
          latitudeDegrees: 0,
          longitudeEastDegrees: 200,
        ).longitudeEastDegrees,
        closeTo(-160.0, 1e-12),
      );
    });
  });
}
