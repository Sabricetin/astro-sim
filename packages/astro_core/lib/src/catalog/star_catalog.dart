/// T2.3 — Yildiz katalogu yukleyici.
///
/// Dosya `tools/build_star_catalog.py` tarafindan uretilir. Amac tek bir
/// bayt okumasiyla dogrudan kullanilabilir bir [Float32List] elde etmek:
/// metin ayristirmak mobilde 8400 yildiz icin gozle gorulur gecikme yapar,
/// binary okumak yapmaz.
///
/// Bicim tanimi ureticinin basindaki aciklamada.
library;

import 'dart:typed_data';

/// Yildiz basina float sayisi: RA, Dec, Vmag, B-V.
const int floatsPerStar = 4;

/// Baslik boyutu, bayt. 16 secilmesi tesadufi degil: float32 bolumunun
/// 4 baytlik hizalamaya oturmasi gerekiyor ki view kopyalamasiz calissin.
const int _headerBytes = 16;

const int _magic = 0x52545341; // 'ASTR' little-endian okundugunda

/// Bu kodun okuyabildigi bicim surumu.
const int supportedCatalogVersion = 1;

/// Kompakt binary katalog. Cizim kodu [data] uzerinde dogrudan calisir.
class StarCatalog {
  /// Siki paketlenmis yildiz verisi: her yildiz icin 4 float.
  ///
  /// Dogrudan indekslemek yerine [rightAscensionDegrees] gibi erisimcileri
  /// kullan; ham diziye erisim, cizim dongusu gibi her karede calisan
  /// yerler icin acik birakildi.
  final Float32List data;

  /// Harvard Revised numaralari, [data] ile ayni sirada.
  ///
  /// Ayri bir dizide tutuluyor ki [data] siki paketli kalsin — cizim kodu
  /// kimlik bilgisine ihtiyac duymaz, takim yildizi cizgileri duyar.
  final Uint16List hrNumbers;

  const StarCatalog._(this.data, this.hrNumbers);

  /// Katalogdaki yildiz sayisi.
  int get length => hrNumbers.length;

  /// Sag aciklik J2000, derece `[0, 360)`.
  double rightAscensionDegrees(int index) => data[index * floatsPerStar];

  /// Sapma J2000, derece `[-90, 90]`.
  double declinationDegrees(int index) => data[index * floatsPerStar + 1];

  /// Gorsel kadir. Kucuk deger = parlak. Sirius -1.46, ciplak goz siniri 6.5.
  double magnitude(int index) => data[index * floatsPerStar + 2];

  /// B-V renk indeksi. **Veri yoksa NaN** — sifir degil.
  ///
  /// Sifir gecerli bir B-V degeridir (A0 tipi, beyaz yildiz); bilinmeyeni
  /// sifirla gostermek 244 yildizi yanlislikla beyaz yapardi. Cagiran
  /// [double.isNaN] ile kontrol edip varsayilan renge dusmeli.
  double colorIndexBV(int index) => data[index * floatsPerStar + 3];

  /// Bayt dizisinden katalog okur.
  ///
  /// Mumkun oldugunda kopyalamaz: [bytes] uygun hizalamadaysa [data]
  /// dogrudan ayni tampona bakar.
  factory StarCatalog.fromBytes(Uint8List bytes) {
    if (bytes.lengthInBytes < _headerBytes) {
      throw const FormatException('Katalog dosyasi cok kisa (baslik yok)');
    }

    // Bicim little-endian yazildi; Float32List.view ise ana makine sirasini
    // kullanir. Big-endian bir platformda sessizce cop uretmek yerine
    // gurultulu hata ver. (Pratikte ARM64/x64/web hepsi little-endian.)
    if (Endian.host != Endian.little) {
      throw UnsupportedError(
        'Katalog bicimi little-endian; bu platform big-endian. '
        'Yavas yol henuz yazilmadi cunku hedef platformlarin hicbiri '
        'big-endian degil.',
      );
    }

    final header = ByteData.sublistView(bytes, 0, _headerBytes);
    final magic = header.getUint32(0, Endian.little);
    if (magic != _magic) {
      throw FormatException(
        'Sihirli sayi tutmuyor: 0x${magic.toRadixString(16)} '
        '(beklenen ASTR). Yanlis dosya mi?',
      );
    }

    final version = header.getUint16(4, Endian.little);
    if (version != supportedCatalogVersion) {
      throw FormatException(
        'Katalog surumu $version, bu kod $supportedCatalogVersion okuyor. '
        'tools/build_star_catalog.py ile yeniden uret.',
      );
    }

    final count = header.getUint32(8, Endian.little);
    final expected = _headerBytes + count * (floatsPerStar * 4 + 2);
    if (bytes.lengthInBytes != expected) {
      throw FormatException(
        'Dosya boyutu tutmuyor: ${bytes.lengthInBytes} bayt, '
        '$count yildiz icin $expected bekleniyordu. Dosya bozuk olabilir.',
      );
    }

    final floatStart = bytes.offsetInBytes + _headerBytes;
    final hrStart = floatStart + count * floatsPerStar * 4;

    // view yalnizca hizalama uygunsa kopyalamadan calisir. Asset olarak
    // gelen tampon genelde ofset 0'dadir; degilse kopyalamaya duseriz.
    final Float32List floats;
    if (floatStart % 4 == 0) {
      floats = Float32List.view(
        bytes.buffer,
        floatStart,
        count * floatsPerStar,
      );
    } else {
      final copy = Uint8List.fromList(
        bytes.sublist(_headerBytes, _headerBytes + count * floatsPerStar * 4),
      );
      floats = Float32List.view(copy.buffer);
    }

    final Uint16List hr;
    if (hrStart % 2 == 0) {
      hr = Uint16List.view(bytes.buffer, hrStart, count);
    } else {
      final copy = Uint8List.fromList(
        bytes.sublist(hrStart - bytes.offsetInBytes),
      );
      hr = Uint16List.view(copy.buffer);
    }

    return StarCatalog._(floats, hr);
  }
}
