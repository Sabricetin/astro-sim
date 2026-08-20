/// T5 — Kalibrasyon defteri ve "hesap yapmayi reddetme" mekanizmasi.
///
/// Yol haritasinin Faz 5 karari: **iskelet hicbir uydurma sabit
/// icermez.** Kalibrasyonu gelmemis her buyukluk, varsayilan deger
/// tasimak yerine hesap yapmayi reddeder.
///
/// Sebebi tek cumleyle: gecici bir sabit konursa testler yesile doner,
/// ekran sayi gosterir ve bir hafta sonra hangi sayinin olculmus
/// hangisinin uydurma oldugu ayirt edilemez. **Uydurmanin maliyeti
/// yanlis sonuc degil — yanlis oldugunu bilememek.**
///
/// Bu yuzden zincirin sonucu ya bir sayidir ya da eksik buyukluklerin
/// listesidir; ucuncu bir ihtimal yok. Sealed tip secilmesinin sebebi
/// de bu: cagiran taraf eksik durumu ele almak zorunda kalir, istisna
/// gibi sessizce yutulamaz.
library;

/// Olculmus bir buyukluk.
///
/// Deger tek basina yetmez: nereden geldigi ve ne kadar belirsiz oldugu
/// da tasinir. Yol haritasinin "sihirli sayi yasak — her sabitin yaninda
/// birimi ve kaynagi" kuralinin tipe donusmus hali.
class Measured {
  final double value;
  final String unit;

  /// Bu sayinin nereden geldigi. Olcum, yayin veya hesap.
  final String source;

  /// Bagil belirsizlik: 0.17 = %17. Bilinmiyorsa null — ama null olmasi
  /// "belirsizlik yok" demek degil, "olculmedi" demek.
  final double? relativeUncertainty;

  const Measured({
    required this.value,
    required this.unit,
    required this.source,
    this.relativeUncertainty,
  });

  @override
  String toString() {
    final u = relativeUncertainty;
    final pct = u == null ? '' : ' ±%${(u * 100).toStringAsFixed(0)}';
    return '$value $unit$pct ($source)';
  }
}

/// Zincirde eksik olan bir buyukluk.
///
/// `why` alani zorunlu: bir buyuklugun neden uydurulamayacagi
/// yazilamiyorsa, muhtemelen uydurulabilir demektir ve o zaman bu
/// listede isi yoktur.
class MissingQuantity {
  /// Insan okuyacak ad.
  final String name;

  /// Formullerdeki sembol.
  final String symbol;

  final String unit;

  /// Hangi olcumden gelecek. Bos birakilamaz — gelmeyecekse bu
  /// buyukluk zincirde olmamali.
  final String comesFrom;

  /// Neden makul bir varsayilan konulamaz.
  final String why;

  const MissingQuantity({
    required this.name,
    required this.symbol,
    required this.unit,
    required this.comesFrom,
    required this.why,
  });

  @override
  String toString() => '$symbol ($name, $unit) — $comesFrom';
}

/// Radyometri zincirinin bir adiminin sonucu.
///
/// Ya sayi tasir ([RadiometricValue]) ya da eksik buyukluklerin listesini
/// ([RadiometricGap]). Eksiklik zincir boyunca **birikerek** tasinir:
/// uc halka eksikse kullaniciya ucu birden soylenir, ilkinde durup
/// digerlerini gizlemez.
sealed class Radiometric {
  const Radiometric();

  /// Sayiya bir islem uygular. Eksikse eksik kalir.
  Radiometric map(double Function(double) f);

  /// Iki sonucu birlestirir. Biri bile eksikse sonuc eksik ve eksikler
  /// birlesir.
  Radiometric combine(Radiometric other, double Function(double, double) f);

  /// Sayiysa degeri, degilse null. Yalnizca test ve gosterim icin;
  /// hesapta kullanilirsa eksigi sessizce yutma riski doger.
  double? get valueOrNull => switch (this) {
    RadiometricValue(:final value) => value,
    RadiometricGap() => null,
  };

  /// Eksik buyuklukler. Sayiysa bos liste.
  List<MissingQuantity> get missing => switch (this) {
    RadiometricValue() => const [],
    RadiometricGap(:final quantities) => quantities,
  };

  bool get isKnown => this is RadiometricValue;
}

/// Hesaplanabilmis deger.
final class RadiometricValue extends Radiometric {
  final double value;
  final String unit;

  const RadiometricValue(this.value, this.unit);

  @override
  Radiometric map(double Function(double) f) =>
      RadiometricValue(f(value), unit);

  @override
  Radiometric combine(Radiometric other, double Function(double, double) f) =>
      switch (other) {
        RadiometricValue(value: final b) => RadiometricValue(f(value, b), unit),
        RadiometricGap() => other,
      };

  @override
  String toString() => '$value $unit';
}

/// Kalibrasyon eksik oldugu icin hesaplanamamis sonuc.
final class RadiometricGap extends Radiometric {
  final List<MissingQuantity> quantities;

  const RadiometricGap(this.quantities);

  RadiometricGap.single(MissingQuantity q) : quantities = [q];

  @override
  Radiometric map(double Function(double) f) => this;

  @override
  Radiometric combine(Radiometric other, double Function(double, double) f) =>
      switch (other) {
        RadiometricValue() => this,
        // Ayni buyukluk iki koldan gelirse tekrar etmesin.
        RadiometricGap(quantities: final b) => RadiometricGap([
          ...quantities,
          ...b.where((q) => !quantities.any((a) => a.symbol == q.symbol)),
        ]),
      };

  @override
  String toString() =>
      'hesaplanamadi — eksik: ${quantities.map((q) => q.symbol).join(', ')}';
}
