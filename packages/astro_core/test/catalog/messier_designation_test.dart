import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

/// Uretec `$` isaretini kacirmisti: designation her nesne icin ayni
/// literal metni ('M' + dolar + 'number') donduruyordu. Arayuzde 110
/// acilir liste ogesinin degeri ayni olunca DropdownButton'un
/// "tam olarak bir oge eslesmeli" onermesi patliyor ve uygulama
/// cokuyordu. Hesap testleri bunu goremezdi — hicbiri designation'a
/// bakmiyordu.
void main() {
  test('designation gercekten numaraya gore uretiliyor', () {
    expect(messierCatalog.firstWhere((m) => m.number == 31).designation, 'M31');
    expect(messierCatalog.firstWhere((m) => m.number == 7).designation, 'M7');
    expect(messierCatalog.first.designation, 'M1');
  });

  test('110 nesnenin designation degeri benzersiz', () {
    final all = messierCatalog.map((m) => m.designation).toSet();
    expect(all.length, 110, reason: 'acilir liste benzersiz deger istiyor');
  });

  test('hicbir designation ham kacis dizisi icermiyor', () {
    for (final m in messierCatalog) {
      expect(m.designation, isNot(contains(r'$')));
    }
  });
}
