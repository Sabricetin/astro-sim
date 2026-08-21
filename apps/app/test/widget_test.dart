import 'dart:io';
import 'dart:typed_data';

import 'package:astro_core/astro_core.dart';
import 'package:astro_sim/src/report_panel.dart';
import 'package:astro_sim/src/site.dart';
import 'package:astro_sim/src/sky_model.dart';
import 'package:astro_sim/src/camera_settings.dart';
import 'package:astro_sim/src/night_panel.dart';
import 'package:astro_sim/src/star_style.dart';
import 'package:flutter/material.dart';
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

  group('Hedef acilir listesi — cokme regresyonu', () {
    // Uygulama Messier hedefi secilince cokuyordu: designation getter'i
    // her nesne icin ayni metni donduruyordu, 110 ogenin degeri
    // ayni oluyordu ve DropdownButton "tam olarak bir oge eslesmeli"
    // onermesinde patliyordu. Bu test o acilir listeyi main.dart'taki
    // gibi kurup gercekten bir Messier hedefi secili halde ciziyor.
    Widget dropdownWithValue(String value) => MaterialApp(
      home: Scaffold(
        body: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: [
            const DropdownMenuItem(
              value: 'Galaktik merkez',
              child: Text('Galaktik merkez'),
            ),
            for (final m in messierCatalog)
              DropdownMenuItem(
                value: m.designation,
                child: Text(m.designation),
              ),
          ],
          onChanged: (_) {},
        ),
      ),
    );

    testWidgets('Messier hedefi secili halde cizilebiliyor', (tester) async {
      await tester.pumpWidget(dropdownWithValue('M31'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('varsayilan hedef de cizilebiliyor', (tester) async {
      await tester.pumpWidget(dropdownWithValue('Galaktik merkez'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('listedeki her hedef secilebilir durumda', (tester) async {
      // Tek tek pump etmek yavas; degerlerin benzersizligi acilir
      // listenin onermesiyle ayni sey.
      final values = [
        'Galaktik merkez',
        ...messierCatalog.map((m) => m.designation),
      ];
      expect(values.toSet().length, values.length);
      expect(values.length, 111);
    });
  });

  group('Ay cezasi — gosterilen deger ile renk celismiyor', () {
    // 24 Mayis 2026'da gercek ceza 1.4643: ekranda "1.5 kadir" yaziliyor
    // ama renk esigi ham degere bakinca turuncu kaliyor. Kullanici
    // "1.5 yaziyor, neden kirmizi degil" diye hakli olarak sasirir.
    // Renk artik gosterilen sayidan turuyor.
    final gaziantep = Observer(
      latitudeDegrees: 37.0662,
      longitudeEastDegrees: 37.3833,
      elevationMeters: 850,
    );
    final galacticCenter = Equatorial.fromHours(
      rightAscensionHours: 17 + 45 / 60 + 40.0 / 3600,
      declinationDegrees: -(29 + 28.0 / 3600),
    );

    testWidgets('yil boyunca hicbir gunde sayi ile renk celismiyor', (
      tester,
    ) async {
      final conflicts = <String>[];
      for (var d = 1; d <= 365; d++) {
        final utc = DateTime.utc(2026, 1, 1, 22).add(Duration(days: d));
        final plan = planNight(
          target: galacticCenter,
          observer: gaziantep,
          aroundUtc: utc,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NightPanel(
                plan: plan,
                targetName: 'Galaktik merkez',
                currentUtc: utc,
                localOffset: const Duration(hours: 3),
              ),
            ),
          ),
        );
        final shown = double.parse(plan.worstMoonPenalty.toStringAsFixed(1));
        // Metinde gecen sayi ile renk ayni esik tarafinda olmali.
        final text = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .firstWhere((t) => t.contains('kadir,'), orElse: () => '');
        if (text.isEmpty) continue;
        final expected = shown < 0.5
            ? 'sorun degil'
            : shown < 1.5
            ? 'dikkat'
            : 'cekilemez';
        if (!text.contains(expected)) {
          conflicts.add('${utc.toIso8601String().substring(0, 10)}: $text');
        }
      }
      expect(conflicts, isEmpty, reason: conflicts.take(5).join('\n'));
    });
  });

  group('Konum secimi', () {
    test('hazir konumlarin adi benzersiz', () {
      // Acilir liste degeri ada gore; tekrar eden ad Messier'daki
      // cokmenin aynisini uretirdi.
      final names = sites.map((s) => s.name).toList();
      expect(names.toSet().length, names.length);
    });

    test('koordinat metni VIIRS bicimi — ondalik derece, 5 hane', () {
      expect(
        RegExp(
          r'^-?\d+\.\d{5}, -?\d+\.\d{5}$',
        ).hasMatch(sites.first.coordinateText),
        isTrue,
        reason: sites.first.coordinateText,
      );
    });

    test('enlemler ve boylamlar gecerli aralikta', () {
      for (final s in sites) {
        expect(s.latitudeDegrees, inInclusiveRange(-90, 90), reason: s.name);
        expect(
          s.longitudeEastDegrees,
          inInclusiveRange(-180, 180),
          reason: s.name,
        );
        expect(s.elevationMeters, greaterThanOrEqualTo(-500), reason: s.name);
      }
    });

    test('kuzeye gidildikce galaktik merkez alcaliyor', () {
      // Konum gercekten hesaba giriyor mu? Girmiyorsa hepsi ayni cikardi.
      final gc = Equatorial.fromHours(
        rightAscensionHours: 17 + 45 / 60 + 40.0 / 3600,
        declinationDegrees: -(29 + 28.0 / 3600),
      );
      double peak(Site site) {
        final plan = planNight(
          target: gc,
          observer: site.observer,
          aroundUtc: DateTime.utc(2026, 7, 15, 22),
        );
        return plan.samples
            .map((s) => s.targetAltitudeDegrees)
            .reduce((a, b) => a > b ? a : b);
      }

      final mersin = sites.firstWhere((s) => s.name.startsWith('Mersin'));
      final istanbul = sites.firstWhere((s) => s.name == 'Istanbul');
      expect(peak(mersin), closeTo(24.2, 0.15));
      expect(peak(istanbul), closeTo(20.0, 0.15));
      // Guneydeki hedef kuzeye gidildikce alcalmali.
      expect(peak(mersin), greaterThan(peak(istanbul)));
    });

    test('Istanbul\'dan galaktik merkez icin pencere yok', () {
      // Esik 20 derece; Istanbul'da zirve tam 20.0 — pencere kapanir.
      // Sabit konumlu bir arac bu cevabi hic veremezdi.
      final gc = Equatorial.fromHours(
        rightAscensionHours: 17 + 45 / 60 + 40.0 / 3600,
        declinationDegrees: -(29 + 28.0 / 3600),
      );
      final plan = planNight(
        target: gc,
        observer: sites.firstWhere((s) => s.name == 'Istanbul').observer,
        aroundUtc: DateTime.utc(2026, 7, 15, 22),
      );
      expect(plan.best, isNull);
    });
  });

  group('Rapor paneli — T5 arayuzu', () {
    final canon = cameras.firstWhere((c) => c.name == 'Canon EOS 760D');

    Widget panel(CameraSettings settings, {double? mag}) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ReportPanel(
            settings: settings,
            targetName: 'Test hedefi',
            altitudeDegrees: 24,
            declinationDegrees: -29,
            vMagnitude: mag,
            colorIndexBV: null,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    testWidgets('olculmus ISO icin rapor uretiyor', (tester) async {
      await tester.pumpWidget(
        panel(CameraSettings(camera: canon, iso: 1600), mag: 8),
      );
      expect(tester.takeException(), isNull);
      // Geometrik kisim her zaman hesaplanir.
      expect(find.textContaining('hava kutlesi'), findsOneWidget);
      expect(find.textContaining('OLCUM BEKLEYEN'), findsOneWidget);
    });

    testWidgets('olculmemis ISO icin hesap yapmayi reddediyor', (tester) async {
      // ISO 400 Faz 0.A'da olculmedi. Panel ara deger uretmemeli.
      await tester.pumpWidget(
        panel(CameraSettings(camera: canon, iso: 400), mag: 8),
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('olculmus sensor verisi yok'), findsOneWidget);
      expect(find.textContaining('hava kutlesi'), findsNothing);
    });

    testWidgets('olculmemis GOVDE icin de reddediyor', (tester) async {
      final sony = cameras.firstWhere((c) => c.name != 'Canon EOS 760D');
      await tester.pumpWidget(
        panel(CameraSettings(camera: sony, iso: 1600), mag: 8),
      );
      expect(find.textContaining('olculmus sensor verisi yok'), findsOneWidget);
    });

    testWidgets('difuz hedefte yildiz sinyali hesaplanamadigini soyluyor', (
      tester,
    ) async {
      await tester.pumpWidget(
        panel(CameraSettings(camera: canon, iso: 1600), mag: null),
      );
      expect(find.textContaining('V kadiri yok'), findsOneWidget);
    });

    test('yalnizca olculmus ISO\'lar secilebilir', () {
      expect(measuredIsoValues, [800, 1600, 3200]);
      for (final iso in measuredIsoValues) {
        expect(
          measuredProfileFor(cameraName: 'Canon EOS 760D', iso: iso),
          isNotNull,
          reason: 'ISO $iso listede ama olcumu yok',
        );
      }
    });

    test('ISO secimi digerlerini bozmuyor', () {
      final base = CameraSettings(camera: canon, exposureSeconds: 30);
      final changed = base.copyWith(iso: 3200);
      expect(changed.exposureSeconds, 30);
      expect(changed.iso, 3200);
      expect(base.iso, 1600, reason: 'varsayilan ISO 1600 olmali');
    });
  });
}
