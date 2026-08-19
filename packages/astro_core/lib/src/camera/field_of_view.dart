/// T3.2 — Gorus alani (FOV) hesabi.
///
/// Rectilinear (balik gozu olmayan) lens bagintisi:
///
///     FOV = 2 * atan(sensor_kenari / (2 * odak))
///
/// Bu, gnomonik projeksiyonla ayni matematiktir — teget duzlemde
/// `tan(aci)` mesafesine dusen nokta, sensorde o kadar milimetreye duser.
/// Iki yerde ayni formulun cikmasi tesadufi degil: projeksiyon zaten
/// lensin davranisini modelliyor.
library;

import 'dart:math' as math;

import '../math/angles.dart';
import 'sensor.dart';

/// Bir sensor kenari ve odak uzunlugundan gorus acisi, derece.
///
/// [sensorDimensionMm] hangi kenar olcululuyorsa o (yatay, dikey veya
/// kosegen). [focalLengthMm] pozitif olmali.
double fieldOfViewDegrees({
  required double sensorDimensionMm,
  required double focalLengthMm,
}) {
  if (focalLengthMm <= 0) {
    throw ArgumentError.value(
      focalLengthMm,
      'focalLengthMm',
      'Odak uzunlugu pozitif olmali',
    );
  }
  return 2.0 * toDegrees(math.atan(sensorDimensionMm / (2.0 * focalLengthMm)));
}

/// Bir govde + lens kombinasyonunun uc yondeki gorus alani.
class FieldOfView {
  /// Uzun kenar boyunca, derece.
  final double horizontalDegrees;

  /// Kisa kenar boyunca, derece.
  final double verticalDegrees;

  /// Kosegen boyunca, derece.
  final double diagonalDegrees;

  const FieldOfView({
    required this.horizontalDegrees,
    required this.verticalDegrees,
    required this.diagonalDegrees,
  });

  /// [portrait] true ise govde dik tutulur; yatay ve dikey yer degistirir.
  factory FieldOfView.of({
    required SensorFormat format,
    required double focalLengthMm,
    bool portrait = false,
  }) {
    final long = fieldOfViewDegrees(
      sensorDimensionMm: format.widthMm,
      focalLengthMm: focalLengthMm,
    );
    final short = fieldOfViewDegrees(
      sensorDimensionMm: format.heightMm,
      focalLengthMm: focalLengthMm,
    );
    return FieldOfView(
      horizontalDegrees: portrait ? short : long,
      verticalDegrees: portrait ? long : short,
      diagonalDegrees: fieldOfViewDegrees(
        sensorDimensionMm: format.diagonalMm,
        focalLengthMm: focalLengthMm,
      ),
    );
  }

  @override
  String toString() =>
      '${horizontalDegrees.toStringAsFixed(1)} x '
      '${verticalDegrees.toStringAsFixed(1)} derece';
}

/// Verilen yatay gorus alanini ureten odak uzunlugu, mm.
///
/// Arayuzde ters yonde gerekiyor: kullanici gokyuzunu yakinlastirdiginda
/// "bu hangi lense denk geliyor?" sorusunun cevabi.
double focalLengthForFieldOfView({
  required double sensorDimensionMm,
  required double fieldOfViewDegrees,
}) => sensorDimensionMm / (2.0 * math.tan(toRadians(fieldOfViewDegrees / 2.0)));

/// Acisal olcek: bir piksel kac yay saniyesi gorur.
///
/// **Birim tuzagi:** yaygin yazilan `206265 * p / f` formulu `p`'nin
/// MILIMETRE olmasini ister. Bu paket `p`'yi her yerde mikrometre
/// tuttugu icin katsayi 206.265'tir. Yol haritasinda bu tuzak ayrica
/// isaretlendi.
double arcsecondsPerPixel({
  required double pixelPitchMicrometers,
  required double focalLengthMm,
}) => 206.265 * pixelPitchMicrometers / focalLengthMm;
