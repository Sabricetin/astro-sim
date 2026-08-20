/// T5.11 — Yildizin kac piksele yayildigi.
///
/// SNR hesabinin girdisi: yildizin sinyali kac pikselden toplanacak ve
/// o piksellerin her biri ne kadar fon gurultusu getirecek.
///
/// **Genis acida bu is atmosferle degil, ornekleme ile belirlenir.**
/// 14 mm ve 3.72 um piksel icin olcek 54.8 yay saniyesi/piksel; tipik
/// 2 yay saniyelik seeing bunun yaninda gorunmez. Yildiz bir pikselin
/// icine duser — sistem asiri az orneklenmistir. Tele odaklarda durum
/// tersine doner ve seeing belirleyici olur.
///
/// Bu yuzden PSF genisligi hesaplanmaz, **olculur**: kullanicinin kendi
/// karelerindeki yildiz FWHM'i. Lensin keskinligi, odak hatasi, kromatik
/// sapma ve seeing hepsi o tek sayinin icindedir.
library;

import 'dart:math' as math;

import 'calibration.dart';

/// PSF genisligi olculmemisse bildirilecek eksik.
const psfFwhmMissing = MissingQuantity(
  name: 'yildiz profili genisligi (FWHM)',
  symbol: 'FWHM',
  unit: 'piksel',
  comesFrom: 'Faz 0.B — kullanicinin kendi karelerinde yildiz olcumu',
  why:
      'Lens keskinligi, odak hatasi ve seeing tek bir sayida birlesiyor '
      've bu sayi lense, diyaframa, hatta cerceve icindeki konuma gore '
      'degisiyor. Teorik bir difraksiyon limiti yazmak gercek lensin '
      'iki-uc kati keskin oldugunu varsaymak olurdu.',
);

/// Yildizin kapladigi etkin piksel sayisi.
///
/// Iz birakan yildiz dikdortgene benzer: uzunluk iz + FWHM, genislik
/// FWHM. Iz yoksa daireye yaklasir. Taban 1 piksel — yildiz bir
/// pikselden az yere sigamaz.
///
/// [trailLengthPixels] Faz 3'te hesaplanan iz uzunlugu. Zincirin
/// buraya baglanmasi onemli: uzun poz daha cok foton toplar ama izi de
/// uzatir, yani sinyali daha cok piksele yayar ve her piksel kendi fon
/// gurultusunu getirir. Poz suresinin SNR'i her zaman iyilestirmedigi
/// nokta tam burasi.
double starFootprintPixels({
  required double psfFwhmPixels,
  required double trailLengthPixels,
}) {
  final width = math.max(psfFwhmPixels, 1.0);
  final length = trailLengthPixels + width;
  // Dikdortgen yerine elips: pi/4 carpani, ~%79.
  final area = math.pi / 4.0 * width * length;
  return math.max(area, 1.0);
}

/// Sistemin orneklemesi. 2'nin altinda az orneklenmis (yildiz pikselden
/// kucuk), 3 civari dengeli.
///
/// Genis aci astrofotografide bu deger neredeyse her zaman 1'in
/// altindadir; arac bunu bir kusur gibi degil, rejimin ozelligi gibi
/// bildirmeli.
double samplingRatio({
  required double psfFwhmArcseconds,
  required double arcsecondsPerPixel,
}) => psfFwhmArcseconds / arcsecondsPerPixel;
