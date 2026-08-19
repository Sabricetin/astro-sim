import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:astro_core/astro_core.dart' as astro;
import 'package:flutter/material.dart';

import 'sky_model.dart';
import 'star_style.dart';

/// Gokyuzunu ekrana cizer.
///
/// Her karede yalnizca PROJEKSIYON calisir; alt/az degerleri [SkyModel]
/// icinde onceden hesaplanmistir. Bakis suruklendiginde gokyuzu yeniden
/// hesaplanmaz.
///
/// Cizim, kova kova yapilir: ayni boyut ve renkteki yildizlar tek bir
/// `drawRawPoints` cagrisiyla gider. 8404 yildiz icin ~49 cagri, yildiz
/// basina bir `drawCircle` yerine.
class SkyPainter extends CustomPainter {
  final SkyModel sky;
  final double centerAzimuthDegrees;
  final double centerAltitudeDegrees;
  final double horizontalFovDegrees;
  final double rollDegrees;
  final bool showHorizon;

  /// Projeksiyon ciktisinin yazildigi tampon. Her karede yeniden
  /// ayrilmamasi icin disaridan veriliyor.
  final Float32List scratch;

  SkyPainter({
    required this.sky,
    required this.centerAzimuthDegrees,
    required this.centerAltitudeDegrees,
    required this.horizontalFovDegrees,
    required this.scratch,
    this.rollDegrees = 0.0,
    this.showHorizon = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF05070E),
    );

    // Teget birimden piksele olcek: yatay gorus alaninin yarisi, ekranin
    // yarisina denk gelmeli. tan() kullanilmasi rectilinear lens modelinin
    // dogrudan sonucu.
    final halfFov = astro.toRadians(horizontalFovDegrees / 2);
    final pixelsPerTangent = (size.width / 2) / math.tan(halfFov);
    final cx = size.width / 2;
    final cy = size.height / 2;

    if (showHorizon) {
      _paintHorizon(canvas, size, pixelsPerTangent, cx, cy);
      _paintCompass(canvas, size, pixelsPerTangent, cx, cy);
    }

    final radiusScale = StarStyle.zoomScale(horizontalFovDegrees);
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (var b = 0; b < SkyModel.bucketCount; b++) {
      final from = sky.bucketStart[b];
      final to = sky.bucketStart[b + 1];
      if (from == to) continue;

      var count = 0;
      for (var k = from; k < to; k++) {
        final i = sky.orderByBucket[k];
        final p = astro.project(
          azimuthDegrees: sky.azimuthDegrees(i),
          altitudeDegrees: sky.altitudeDegrees(i),
          centerAzimuthDegrees: centerAzimuthDegrees,
          centerAltitudeDegrees: centerAltitudeDegrees,
          rollDegrees: rollDegrees,
        );
        // null = bakisin arkasinda veya sinirin otesinde. Cizilmez.
        if (p == null) continue;

        final x = cx + p.x * pixelsPerTangent;
        // Ekran y'si asagi pozitif, gokyuzu y'si yukari — burada cevriliyor.
        final y = cy - p.y * pixelsPerTangent;
        if (x < -8 || x > size.width + 8 || y < -8 || y > size.height + 8) {
          continue;
        }
        scratch[count * 2] = x;
        scratch[count * 2 + 1] = y;
        count++;
      }
      if (count == 0) continue;

      paint
        ..color = StarStyle.colorForBucket(b)
        ..strokeWidth = StarStyle.radiusForBucket(b) * 2 * radiusScale;
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.sublistView(scratch, 0, count * 2),
        paint,
      );
    }
  }

  /// Ufuk cizgisi ve altindaki karartma.
  ///
  /// Yildizlarin nerede battigini gormek, kadrajin gercekci olup
  /// olmadigini anlamanin en hizli yolu.
  void _paintHorizon(
    Canvas canvas,
    Size size,
    double pixelsPerTangent,
    double cx,
    double cy,
  ) {
    final path = Path();
    var started = false;
    for (var az = 0.0; az <= 360.0; az += 0.5) {
      final p = astro.project(
        azimuthDegrees: az,
        altitudeDegrees: 0.0,
        centerAzimuthDegrees: centerAzimuthDegrees,
        centerAltitudeDegrees: centerAltitudeDegrees,
        rollDegrees: rollDegrees,
      );
      if (p == null) {
        started = false;
        continue;
      }
      final x = cx + p.x * pixelsPerTangent;
      final y = cy - p.y * pixelsPerTangent;
      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x66407080),
    );
  }

  /// Ufuk uzerinde yon isaretleri (K, KD, D, ...).
  ///
  /// Tasarim sisteminde (§8) minimal yon gostergeleri isteniyor. Islevsel
  /// karsiligi da var: hedefin dogru yonde olup olmadigini gozle dogrulamanin
  /// en hizli yolu. Orion'un guneyde cikmasi gerektigini bilen biri, bu
  /// isaretler olmadan emin olamaz.
  static const _compassPoints = <double, String>{
    0: 'K',
    45: 'KD',
    90: 'D',
    135: 'GD',
    180: 'G',
    225: 'GB',
    270: 'B',
    315: 'KB',
  };

  void _paintCompass(
    Canvas canvas,
    Size size,
    double pixelsPerTangent,
    double cx,
    double cy,
  ) {
    for (final entry in _compassPoints.entries) {
      final p = astro.project(
        azimuthDegrees: entry.key,
        altitudeDegrees: 0.0,
        centerAzimuthDegrees: centerAzimuthDegrees,
        centerAltitudeDegrees: centerAltitudeDegrees,
        rollDegrees: rollDegrees,
      );
      if (p == null) continue;

      final x = cx + p.x * pixelsPerTangent;
      final y = cy - p.y * pixelsPerTangent;
      if (x < 0 || x > size.width || y < 0 || y > size.height) continue;

      final painter = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: const TextStyle(
            color: Color(0x997FA8C4),
            fontSize: 13,
            fontFamily: 'monospace',
            letterSpacing: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(x - painter.width / 2, y + 6));
    }
  }

  @override
  bool shouldRepaint(SkyPainter old) =>
      old.sky != sky ||
      old.centerAzimuthDegrees != centerAzimuthDegrees ||
      old.centerAltitudeDegrees != centerAltitudeDegrees ||
      old.horizontalFovDegrees != horizontalFovDegrees ||
      old.rollDegrees != rollDegrees ||
      old.showHorizon != showHorizon;
}
