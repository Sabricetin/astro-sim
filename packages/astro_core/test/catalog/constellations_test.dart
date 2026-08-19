import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  late StarCatalog catalog;
  late Map<int, int> indexByHr;

  setUpAll(() {
    catalog = StarCatalog.fromBytes(
      File('assets/stars_bsc5.bin').readAsBytesSync(),
    );
    indexByHr = {
      for (var i = 0; i < catalog.length; i++) catalog.hrNumbers[i]: i,
    };
  });

  group('cizgi verisi tutarli', () {
    test('her parca bir cift HR numarasi', () {
      for (final c in constellations) {
        expect(c.segments.length.isEven, isTrue, reason: c.name);
        expect(c.segments, isNotEmpty, reason: c.name);
      }
    });

    test('butun HR numaralari katalogda var', () {
      for (final c in constellations) {
        for (final hr in c.segments) {
          expect(
            indexByHr.containsKey(hr),
            isTrue,
            reason: '${c.name}: HR $hr katalogda yok',
          );
        }
      }
    });

    test('cizgiler gokyuzunu boydan boya kesmiyor', () {
      // Bu testin asil isi YAZIM HATASI yakalamak. Yanlis bir HR numarasi
      // sozdizimsel olarak gecerlidir ama gokyuzunun obur ucundaki bir
      // yildiza baglanir; ekranda absurt bir cizgi cikar. Bir takim
      // yildizinin gercek genisligi 30 dereceyi nadiren asar.
      for (final c in constellations) {
        for (var k = 0; k < c.segmentCount; k++) {
          final a = indexByHr[c.segments[k * 2]]!;
          final b = indexByHr[c.segments[k * 2 + 1]]!;
          final separation = angularSeparationDegrees(
            catalog.rightAscensionDegrees(a),
            catalog.declinationDegrees(a),
            catalog.rightAscensionDegrees(b),
            catalog.declinationDegrees(b),
          );
          expect(
            separation,
            lessThan(30.0),
            reason:
                '${c.name}: HR ${c.segments[k * 2]} - '
                'HR ${c.segments[k * 2 + 1]} arasi '
                '${separation.toStringAsFixed(1)} derece',
          );
        }
      }
    });

    test('her takim yildizinin yildizlari birbirine yakin', () {
      // Ayni takim yildizindaki butun yildizlar tek bir gokyuzu bolgesinde
      // olmali. Yanlis takimdan bir yildiz eklenirse bu yakalar.
      for (final c in constellations) {
        final hrs = c.segments.toSet().toList();
        final first = indexByHr[hrs.first]!;
        for (final hr in hrs) {
          final i = indexByHr[hr]!;
          final d = angularSeparationDegrees(
            catalog.rightAscensionDegrees(first),
            catalog.declinationDegrees(first),
            catalog.rightAscensionDegrees(i),
            catalog.declinationDegrees(i),
          );
          expect(d, lessThan(60.0), reason: '${c.name}: HR $hr uzakta ($d)');
        }
      }
    });

    test('kisaltmalar benzersiz', () {
      final abbreviations = constellations.map((c) => c.abbreviation).toList();
      expect(abbreviations.toSet().length, abbreviations.length);
    });
  });

  group('yildiz adlari', () {
    test('adlandirilan her yildiz katalogda var', () {
      for (final hr in brightStarNames.keys) {
        expect(indexByHr.containsKey(hr), isTrue, reason: 'HR $hr yok');
      }
    });

    test('adlandirilan yildizlar gercekten parlak', () {
      // Etiketler gokyuzunu okunmaz hale getirmesin diye liste kisa
      // tutuldu; hepsinin ayirt edilebilir parlaklikta olmasi gerekir.
      for (final entry in brightStarNames.entries) {
        final magnitude = catalog.magnitude(indexByHr[entry.key]!);
        expect(
          magnitude,
          lessThan(3.6),
          reason: '${entry.value} (HR ${entry.key}) kadir $magnitude',
        );
      }
    });

    test('adlar benzersiz', () {
      final names = brightStarNames.values.toList();
      expect(names.toSet().length, names.length);
    });

    test('Sirius en parlak adlandirilan yildiz', () {
      final brightest = brightStarNames.keys.reduce(
        (a, b) =>
            catalog.magnitude(indexByHr[a]!) < catalog.magnitude(indexByHr[b]!)
            ? a
            : b,
      );
      expect(brightStarNames[brightest], 'Sirius');
    });
  });
}
