import 'dart:io';
import 'dart:typed_data';

import 'package:astro_core/astro_core.dart';
import 'package:astro_sim/src/sky_model.dart';
import 'package:astro_sim/src/camera_settings.dart';
import 'package:astro_sim/src/star_style.dart';
import 'package:flutter_test/flutter_test.dart';

/// Katalogu dosyadan okur. Widget testinde rootBundle yerine dogrudan
/// dosyadan okumak daha basit ve asset kanalindan bagimsiz.
StarCatalog _loadCatalog() {
  final file = File('../../packages/astro_core/assets/stars_bsc5.bin');
  if (!file.existsSync()) {
    throw StateError(
      'Katalog yok: ${file.path}\n'
      'Uret: ./.venv/bin/python tools/build_star_catalog.py',
    );
  }
  return StarCatalog.fromBytes(file.readAsBytesSync());
}

void main() {
  late StarCatalog catalog;

  setUpAll(() => catalog = _loadCatalog());

  group('SkyModel', () {
    test('her yildiz icin alt/az hesapliyor', () {
      final sky = SkyModel.compute(
        catalog: catalog,
        utc: DateTime.utc(2026, 3, 15, 21),
        observer: Observer(
          latitudeDegrees: 37.0662,
          longitudeEastDegrees: 37.3833,
        ),
      );
      expect(sky.starCount, catalog.length);
      expect(sky.horizontal.length, catalog.length * 2);

      for (var i = 0; i < sky.starCount; i++) {
        expect(sky.azimuthDegrees(i), inInclusiveRange(0, 360));
        expect(sky.altitudeDegrees(i), inInclusiveRange(-90, 90));
      }
    });

    test('Buyuk Ayi hazir ayarinda Dubhe beklenen yerde', () {
      // main.dart'taki 'Buyuk Ayi' hazir ayari bu ani kullaniyor.
      // Deger astropy ile bagimsiz hesaplandi: alt 65.5, az 0.6.
      final sky = SkyModel.compute(
        catalog: catalog,
        utc: DateTime.utc(2026, 3, 15, 21),
        observer: Observer(
          latitudeDegrees: 37.0662,
          longitudeEastDegrees: 37.3833,
        ),
      );
      final i = catalog.hrNumbers.indexOf(4301); // HR 4301 = Dubhe
      expect(i, isNonNegative, reason: 'Dubhe (HR 4301) katalogda yok');
      expect(sky.altitudeDegrees(i), closeTo(65.5, 0.5));
      expect(
        angularDifferenceDegrees(sky.azimuthDegrees(i), 0.6).abs(),
        lessThan(1.5),
      );
    });

    test('kovalar butun yildizlari tam bir kez kapsiyor', () {
      final sky = SkyModel.compute(
        catalog: catalog,
        utc: DateTime.utc(2026, 3, 15, 21),
        observer: Observer(latitudeDegrees: 37, longitudeEastDegrees: 37),
      );
      expect(sky.bucketStart.last, catalog.length);

      final seen = Uint8List(catalog.length);
      for (var b = 0; b < SkyModel.bucketCount; b++) {
        for (var k = sky.bucketStart[b]; k < sky.bucketStart[b + 1]; k++) {
          final i = sky.orderByBucket[k];
          expect(sky.bucket[i], b, reason: 'index $i yanlis kovada');
          seen[i]++;
        }
      }
      expect(seen.every((v) => v == 1), isTrue, reason: 'eksik/tekrar var');
    });
  });

  group('StarStyle', () {
    test('parlak yildiz daha buyuk cizilir', () {
      // Kova indeksi = boyutSinifi * renkSinifiSayisi + renkSinifi.
      double radiusOfSizeClass(int sizeClass) =>
          StarStyle.radiusForBucket(sizeClass * SkyModel.colorClassCount);
      var previous = double.infinity;
      for (var s = 0; s < SkyModel.sizeClassCount; s++) {
        final r = radiusOfSizeClass(s);
        expect(r, lessThan(previous), reason: 'boyut sinifi $s');
        previous = r;
      }
    });

    test('her kova icin renk ve yaricap tanimli', () {
      for (var b = 0; b < SkyModel.bucketCount; b++) {
        expect(StarStyle.radiusForBucket(b), greaterThan(0));
        expect(StarStyle.colorForBucket(b).a, 1.0);
      }
    });

    test('zoom olcegi sinirlar icinde kaliyor', () {
      for (final fov in [2.0, 20.0, 55.0, 104.0, 140.0]) {
        final s = StarStyle.zoomScale(fov);
        expect(s, inInclusiveRange(0.55, 1.9), reason: 'FOV $fov');
      }
    });
  });

  group('CameraSettings — Faz 3', () {
    final canon = cameras.firstWhere((c) => c.name == 'Canon EOS 760D');

    test('varsayilan: 14 mm f/2.8, NPF ~15 s', () {
      final s = CameraSettings(camera: canon);
      expect(s.maxExposureSeconds, closeTo(14.96, 0.05));
      // 2 * atan(22.3 / (2 * 14)) = 77.07 derece. Canon APS-C'nin 22.3 mm
      // genisligi, digerlerinin 23.5 mm'sinden kucuk — o yuzden ayni lens
      // burada daha dar goruyor.
      expect(s.fieldOfView.horizontalDegrees, closeTo(77.07, 0.02));
    });

    test('20 s poz 14 mm\'de siniri asiyor', () {
      final s = CameraSettings(camera: canon, exposureSeconds: 20);
      expect(s.exceedsLimit, isTrue);
      expect(s.trailPixels, greaterThan(4));
    });

    test('galaktik merkeze bakinca sinir uzuyor', () {
      final equator = CameraSettings(camera: canon);
      final galactic = CameraSettings(
        camera: canon,
        targetDeclinationDegrees: -29,
      );
      expect(
        galactic.maxExposureSeconds,
        greaterThan(equator.maxExposureSeconds),
      );
    });

    test('dikey cevirmek kadraji donduruyor', () {
      final landscape = CameraSettings(camera: canon);
      final portrait = CameraSettings(camera: canon, portrait: true);
      expect(
        portrait.fieldOfView.horizontalDegrees,
        closeTo(landscape.fieldOfView.verticalDegrees, 1e-9),
      );
    });

    test('500 kurali her zaman NPF\'den iyimser', () {
      for (final f in CameraSettings.focalLengths) {
        final s = CameraSettings(camera: canon, focalLengthMm: f);
        expect(
          s.fiveHundredRule,
          greaterThan(s.maxExposureSeconds),
          reason: '$f mm',
        );
      }
    });

    test('copyWith digerlerini bozmuyor', () {
      final base = CameraSettings(camera: canon, exposureSeconds: 30);
      final changed = base.copyWith(aperture: 4.0);
      expect(changed.exposureSeconds, 30);
      expect(changed.camera, canon);
      expect(changed.aperture, 4.0);
    });
  });

  group('SkyModel.atTime — Faz 4 zaman kaydiricisi', () {
    final gaziantep = Observer(
      latitudeDegrees: 37.0662,
      longitudeEastDegrees: 37.3833,
    );

    test('presesyon yeniden hesaplanmadan ayni sonucu veriyor', () {
      // atTime, tam hesabin kisayolu. Bir gece icinde presesyon ~0.0001
      // derece degistigi icin ikisi ayni sonucu vermeli — vermezse
      // kisayol yanlis demektir.
      final base = SkyModel.compute(
        catalog: catalog,
        utc: DateTime.utc(2026, 7, 15, 20),
        observer: gaziantep,
      );
      final shortcut = base.atTime(DateTime.utc(2026, 7, 15, 23));
      final full = SkyModel.compute(
        catalog: catalog,
        utc: DateTime.utc(2026, 7, 15, 23),
        observer: gaziantep,
      );

      var worst = 0.0;
      for (var i = 0; i < catalog.length; i++) {
        final d = angularSeparationDegrees(
          shortcut.azimuthDegrees(i),
          shortcut.altitudeDegrees(i),
          full.azimuthDegrees(i),
          full.altitudeDegrees(i),
        );
        if (d > worst) worst = d;
      }
      // Projenin toleransi 0.1 derece; kisayolun sapmasi onun binde biri
      // altinda kalmali.
      expect(worst, lessThan(0.0001), reason: 'en kotu sapma $worst derece');
    });

    test('kova ve indeks yapilari paylasiliyor', () {
      final base = SkyModel.compute(
        catalog: catalog,
        utc: DateTime.utc(2026, 7, 15, 20),
        observer: gaziantep,
      );
      final later = base.atTime(DateTime.utc(2026, 7, 15, 23));
      // Ayni nesneye bakmali — kopyalanirsa her kaydirmada 8404 elemanlik
      // diziler yeniden ayrilirdi.
      expect(identical(later.bucket, base.bucket), isTrue);
      expect(identical(later.orderByBucket, base.orderByBucket), isTrue);
      expect(identical(later.indexByHr, base.indexByHr), isTrue);
    });

    test('gokyuzu gercekten donuyor', () {
      final base = SkyModel.compute(
        catalog: catalog,
        utc: DateTime.utc(2026, 7, 15, 20),
        observer: gaziantep,
      );
      final later = base.atTime(DateTime.utc(2026, 7, 15, 26 - 3));
      // Uc saatte gokyuzu ~45 derece donmeli.
      final i = catalog.hrNumbers.indexOf(7001); // Vega
      final moved = angularSeparationDegrees(
        base.azimuthDegrees(i),
        base.altitudeDegrees(i),
        later.azimuthDegrees(i),
        later.altitudeDegrees(i),
      );
      expect(moved, greaterThan(20));
    });
  });
}
