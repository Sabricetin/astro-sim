/// T3.1 — Sensor formatlari ve govde veritabani.
///
/// FOV ve NPF hesaplarinin ikisi de sensorun fiziksel boyutuna ve piksel
/// adimina bagli. Bu dosya o iki sayiyi tek yerde tutar.
///
/// **Piksel adimi turetilir, girilmez.** Genislik ve piksel sayisi zaten
/// biliniyorsa adim onlardan cikar; ayrica girilirse ucu birbiriyle
/// celisebilir ve hangisinin dogru oldugu belirsiz kalir.
library;

import 'dart:math' as math;

/// 35 mm tam kare kosegeni, mm. Kirpma carpaninin referansi.
const double fullFrameDiagonalMm = 43.267;

/// Sensorun fiziksel boyutu.
class SensorFormat {
  final String name;

  /// Uzun kenar, mm.
  final double widthMm;

  /// Kisa kenar, mm.
  final double heightMm;

  const SensorFormat({
    required this.name,
    required this.widthMm,
    required this.heightMm,
  });

  double get diagonalMm => math.sqrt(widthMm * widthMm + heightMm * heightMm);

  /// Kirpma carpani: tam karenin kosegeni bolu bu sensorun kosegeni.
  double get cropFactor => fullFrameDiagonalMm / diagonalMm;
}

const fullFrame = SensorFormat(name: 'Tam kare', widthMm: 36.0, heightMm: 24.0);

/// Canon'un APS-C'si digerlerinden kucuk — kirpma 1.6, otekilerde 1.5.
/// Yol haritasinda ayrica isaretlenmisti; ayni "APS-C" etiketi altinda
/// birlestirmek FOV hesabinda %7 hata verirdi.
const apscCanon = SensorFormat(
  name: 'APS-C (Canon)',
  widthMm: 22.3,
  heightMm: 14.9,
);

const apsc = SensorFormat(name: 'APS-C', widthMm: 23.5, heightMm: 15.6);

const microFourThirds = SensorFormat(
  name: 'Micro Four Thirds',
  widthMm: 17.3,
  heightMm: 13.0,
);

const oneInch = SensorFormat(name: '1 inc', widthMm: 13.2, heightMm: 8.8);

/// Tipik ust segment telefon ana kamerasi (1/1.3 inc civari).
///
/// Telefon sensorleri modelden modele cok degisir ve ureticiler tam
/// boyut yayinlamaz; bu deger yaklasiktir. Kesin sonuc icin kullanici
/// kendi govdesini elle girmeli.
const phoneMain = SensorFormat(
  name: 'Telefon (yaklasik)',
  widthMm: 9.8,
  heightMm: 7.3,
);

const List<SensorFormat> sensorFormats = [
  fullFrame,
  apscCanon,
  apsc,
  microFourThirds,
  oneInch,
  phoneMain,
];

/// Belirli bir fotograf makinesi govdesi.
class Camera {
  final String name;
  final SensorFormat format;

  /// Uzun kenardaki piksel sayisi.
  final int horizontalPixels;

  /// Kisa kenardaki piksel sayisi.
  final int verticalPixels;

  const Camera({
    required this.name,
    required this.format,
    required this.horizontalPixels,
    required this.verticalPixels,
  });

  /// Piksel adimi, **mikrometre**.
  ///
  /// NPF kuralinin girdisi. Paketin geri kalaninda `p` her zaman
  /// mikrometre; acisal olcek formulunde milimetre isteyen surum
  /// kullanilmaz (bkz. yol-haritasi.md, birim tuzagi).
  double get pixelPitchMicrometers =>
      format.widthMm * 1000.0 / horizontalPixels;

  /// Toplam cozunurluk, megapiksel.
  double get megapixels => horizontalPixels * verticalPixels / 1e6;

  @override
  String toString() => name;
}

/// Hazir govde profilleri.
///
/// Amac butun piyasayi kapsamak degil — her formattan temsilci bir govde
/// olmasi ve kullanicinin kendi govdesini elle girebilmesi. Yol haritasi
/// "kac govde yeter?" sorusunu bilinmeyenler arasinda birakti; cevabi
/// kullanici geri bildirimi verecek.
const List<Camera> cameras = [
  // Bu projenin kalibrasyonu bu govdeyle yapildi (bkz. data/faz0).
  Camera(
    name: 'Canon EOS 760D',
    format: apscCanon,
    horizontalPixels: 6000,
    verticalPixels: 4000,
  ),
  Camera(
    name: 'Canon EOS R5',
    format: fullFrame,
    horizontalPixels: 8192,
    verticalPixels: 5464,
  ),
  Camera(
    name: 'Sony A7 III',
    format: fullFrame,
    horizontalPixels: 6000,
    verticalPixels: 4000,
  ),
  Camera(
    name: 'Sony A7R V',
    format: fullFrame,
    horizontalPixels: 9504,
    verticalPixels: 6336,
  ),
  Camera(
    name: 'Nikon Z6 II',
    format: fullFrame,
    horizontalPixels: 6048,
    verticalPixels: 4024,
  ),
  Camera(
    name: 'Sony A6400',
    format: apsc,
    horizontalPixels: 6000,
    verticalPixels: 4000,
  ),
  Camera(
    name: 'Fujifilm X-T5',
    format: apsc,
    horizontalPixels: 7728,
    verticalPixels: 5152,
  ),
  Camera(
    name: 'OM System OM-1',
    format: microFourThirds,
    horizontalPixels: 5184,
    verticalPixels: 3888,
  ),
  Camera(
    name: 'Sony RX100 VII',
    format: oneInch,
    horizontalPixels: 5472,
    verticalPixels: 3648,
  ),
];
