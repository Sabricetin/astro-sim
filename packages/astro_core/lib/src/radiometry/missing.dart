/// T5 — Kalibrasyon bekleyen buyukluklerin defteri.
///
/// Her biri icin **neden makul bir varsayilan konulamayacagi** yazili.
/// Bu alan bos birakilamiyorsa buyuklugun burada isi yoktur: gerekcesi
/// yazilamayan bir eksiklik, muhtemelen eksiklik degil tembelliktir.
library;

import 'calibration.dart';

/// Atmosferik sonum katsayisi.
const extinctionCoefficientMissing = MissingQuantity(
  name: 'atmosferik sonum katsayisi',
  symbol: 'k',
  unit: 'kadir / hava kutlesi',
  comesFrom: 'Faz 0.B Dizi B — Vega\'nin yukseklige gore sonumu',
  why:
      'Yere ve geceye gore 0.15 (yuksek, kuru) ile 0.60 (sahil, puslu) '
      'arasinda degisir. Kitabi 0.25 alip Mersin sahilinde kullanmak '
      'X=2.4\'te 0.84 kadir hata verir — akista 2.2 kat. Asil hedef '
      '24 derecede, yani tam da bu hatanin en buyudugu yerde.',
);

/// Lens aktarim verimi (T-stop / f-stop orani).
const lensTransmissionMissing = MissingQuantity(
  name: 'lens aktarim verimi',
  symbol: 'T',
  unit: 'boyutsuz (0-1)',
  comesFrom: 'Faz 0.D — hesap ile olcumun karsilastirilmasi',
  why:
      'f/2.8 bir lens f/2.8 kadar isik gecirmez. Cam sayisi ve kaplamaya '
      'gore tipik 0.80-0.95. Fotograf lenslerinde T-stop yayinlanmaz. '
      'Faz 5\'in cikis kriteri %15; bu tek basina onu dusurebilir.',
);

/// Sensorun kuantum verimi.
const quantumEfficiencyMissing = MissingQuantity(
  name: 'kuantum verimi',
  symbol: 'QE',
  unit: 'elektron / foton',
  comesFrom: 'Faz 0.D — bilinen parlaklikta yildizla geri hesaplama',
  why:
      'Canon QE yayinlamaz. Govdeye ve dalga boyuna gore 0.35-0.55 '
      'arasinda degisir. Tek sayiyla temsil etmek bile yaklasiklik; '
      'uydurulmus tek sayi butun akis zincirini olcekler.',
);

/// Kameranin yesil kanalini Johnson V bandina baglayan duzeltme.
const bandCorrectionMissing = MissingQuantity(
  name: 'yesil kanal - V bandi donusumu',
  symbol: 'dV_G',
  unit: 'kadir (B-V\'nin fonksiyonu)',
  comesFrom: 'Faz 0.B Dizi A/B — farkli renkteki yildizlarin olcumu',
  why:
      'Bayer yesili Johnson V degildir. Fark yildizin rengine bagli: '
      'kirmizi bir dev ile mavi bir anakol yildizi ayni V kadirde farkli '
      'yesil sinyal verir. Renkten bagimsiz tek katsayi kullanmak '
      'sistematik ve renge bagli hata uretir — en kotu hata turu, cunku '
      'ortalamada kaybolur.',
);

/// Karanlik akim.
const darkCurrentMissing = MissingQuantity(
  name: 'karanlik akim',
  symbol: 'I_d',
  unit: 'elektron / piksel / saniye',
  comesFrom: 'Faz 0.B Dizi C — gece sonunda cekilen karanlik kareler',
  why:
      'Sicaklikla kabaca her 6 derecede iki katina cikar. Laboratuvar '
      'degeri sahada gecerli olmaz; olcum, karelerin cekildigi sensor '
      'sicakliginda yapilmali. O sicaklik EXIF\'te zaten kayitli.',
);

/// Gokyuzu fon parlakligi — konuma ozel.
const skyBackgroundMissing = MissingQuantity(
  name: 'Ay\'siz gokyuzu fon parlakligi',
  symbol: 'mu_sky',
  unit: 'kadir / yay saniyesi kare',
  comesFrom: 'Faz 0.C — VIIRS uydu verisi, cekim noktasinin koordinatiyla',
  why:
      'Bortle 1 ile Bortle 9 arasinda 40 kat fark var. Sinif elle '
      'secilirse kullanicinin tahminine dayanir; gozle Bortle kestirmek '
      'iki sinif sasar, bu da 2.5 kat fon demektir.',
);

/// Zincirin bekledigi butun buyuklukler. Arayuz "daha ne lazim"
/// diye sordugunda bu liste cevaptir.
const allMissingQuantities = <MissingQuantity>[
  extinctionCoefficientMissing,
  lensTransmissionMissing,
  quantumEfficiencyMissing,
  bandCorrectionMissing,
  darkCurrentMissing,
  skyBackgroundMissing,
];
