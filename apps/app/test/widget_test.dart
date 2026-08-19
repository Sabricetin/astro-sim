import 'dart:io';
import 'dart:typed_data';

import 'package:astro_core/astro_core.dart';
import 'package:astro_sim/src/sky_model.dart';
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
}
