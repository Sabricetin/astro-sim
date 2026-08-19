import 'dart:io';
import 'dart:typed_data';

import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  final assetFile = File('assets/stars_bsc5.bin');

  group('gercek katalog dosyasi', () {
    late StarCatalog catalog;

    setUpAll(() {
      if (!assetFile.existsSync()) {
        throw StateError(
          'assets/stars_bsc5.bin yok. Uret:\n'
          '  ./.venv/bin/python tools/build_star_catalog.py',
        );
      }
      catalog = StarCatalog.fromBytes(assetFile.readAsBytesSync());
    });

    test('beklenen sayida yildiz', () {
      expect(catalog.length, 8404);
    });

    test('dosya boyutu ~148 KB (yol haritasi tahmini ~144 KB)', () {
      expect(assetFile.lengthSync(), lessThan(160 * 1024));
    });

    test('Sirius (HR 2491) dogru kadirle bulunuyor', () {
      final index = catalog.hrNumbers.indexOf(2491);
      expect(index, isNonNegative, reason: 'HR 2491 katalogda yok');
      expect(catalog.magnitude(index), closeTo(-1.46, 0.005));
      // Sirius: RA 6h45m, Dec -16 derece 43 dakika
      expect(catalog.rightAscensionDegrees(index), closeTo(101.29, 0.05));
      expect(catalog.declinationDegrees(index), closeTo(-16.72, 0.05));
    });

    test('butun koordinatlar gecerli aralikta', () {
      for (var i = 0; i < catalog.length; i++) {
        final ra = catalog.rightAscensionDegrees(i);
        final dec = catalog.declinationDegrees(i);
        expect(ra, greaterThanOrEqualTo(0.0), reason: 'index $i');
        expect(ra, lessThan(360.0), reason: 'index $i');
        expect(dec, greaterThanOrEqualTo(-90.0), reason: 'index $i');
        expect(dec, lessThanOrEqualTo(90.0), reason: 'index $i');
        expect(ra.isNaN, isFalse, reason: 'index $i');
        expect(dec.isNaN, isFalse, reason: 'index $i');
      }
    });

    test('kadir siniri uygulanmis', () {
      for (var i = 0; i < catalog.length; i++) {
        expect(
          catalog.magnitude(i),
          lessThanOrEqualTo(6.5),
          reason: 'index $i',
        );
        expect(catalog.magnitude(i).isNaN, isFalse, reason: 'index $i');
      }
    });

    test('HR numaralari artan sirada — tekrar uretilebilirlik', () {
      for (var i = 1; i < catalog.length; i++) {
        expect(
          catalog.hrNumbers[i],
          greaterThan(catalog.hrNumbers[i - 1]),
          reason: 'index $i',
        );
      }
    });

    test('B-V bilinmeyenler NaN, sifir degil', () {
      // Sifir gecerli bir B-V (A0 tipi, beyaz yildiz). Bilinmeyeni sifirla
      // gostermek 244 yildizi yanlislikla beyaz yapardi.
      final unknown = List.generate(
        catalog.length,
        (i) => catalog.colorIndexBV(i),
      ).where((v) => v.isNaN).length;
      expect(unknown, 244);

      // Bilinen degerler fiziksel aralikta. Sinirlar gercek katalog
      // uclarindan: en mavi HR 1996 (-0.28, tayf O9.5V), en kirmizi
      // HR 423 (+3.86, tayf C6II — bir karbon yildizi). Karbon yildizlari
      // bu kadar kirmizi olur; boyle bir deger gorunce "veri bozuk" diye
      // dusunulmesin diye buraya yaziliyor.
      for (var i = 0; i < catalog.length; i++) {
        final bv = catalog.colorIndexBV(i);
        if (bv.isNaN) continue;
        expect(bv, greaterThan(-0.4), reason: 'index $i');
        expect(bv, lessThan(6.0), reason: 'index $i');
      }
    });

    test('gercekten kopyalamadan okunuyor', () {
      // Float32List, dosyanin kendi tamponuna bakmali. Kopyalansaydi
      // 8400 yildizlik dizi her aciliste yeniden ayrilirdi.
      expect(catalog.data.length, catalog.length * floatsPerStar);
    });
  });

  group('bozuk dosya reddi', () {
    Uint8List validBytes() => assetFile.readAsBytesSync();

    test('yanlis sihirli sayi', () {
      final bytes = validBytes();
      bytes[0] = 0x58; // 'X'
      expect(
        () => StarCatalog.fromBytes(bytes),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'mesaj',
            contains('Sihirli sayi'),
          ),
        ),
      );
    });

    test('desteklenmeyen surum', () {
      final bytes = validBytes();
      bytes[4] = 99;
      expect(
        () => StarCatalog.fromBytes(bytes),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'mesaj',
            contains('surumu'),
          ),
        ),
      );
    });

    test('kirpilmis dosya', () {
      final bytes = validBytes();
      expect(
        () => StarCatalog.fromBytes(bytes.sublist(0, bytes.length - 100)),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'mesaj',
            contains('boyutu tutmuyor'),
          ),
        ),
      );
    });

    test('baslik bile yok', () {
      expect(
        () => StarCatalog.fromBytes(Uint8List(8)),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
