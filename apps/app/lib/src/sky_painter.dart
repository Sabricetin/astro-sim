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
  final bool showConstellations;
  final bool showLabels;

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
    this.showConstellations = true,
    this.showLabels = true,
  });

  /// Bir yildizi ekran koordinatina cevirir. Gorunmuyorsa null.
  Offset? _screenPosition(
    int index,
    double pixelsPerTangent,
    double cx,
    double cy,
    Size size,
  ) {
    final p = astro.project(
      azimuthDegrees: sky.azimuthDegrees(index),
      altitudeDegrees: sky.altitudeDegrees(index),
      centerAzimuthDegrees: centerAzimuthDegrees,
      centerAltitudeDegrees: centerAltitudeDegrees,
      rollDegrees: rollDegrees,
    );
    if (p == null) return null;
    return Offset(cx + p.x * pixelsPerTangent, cy - p.y * pixelsPerTangent);
  }

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

    if (showConstellations) {
      _paintConstellations(canvas, size, pixelsPerTangent, cx, cy);
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

    if (showLabels) {
      _paintLabels(canvas, size, pixelsPerTangent, cx, cy);
    }
  }

  /// Takim yildizi cizgileri.
  ///
  /// Yildizlardan ONCE cizilir ki noktalar cizgilerin ustunde kalsin.
  /// Renk bilerek soluk: cizgiler yildizlari bastirmamali, sadece
  /// desene isaret etmeli.
  void _paintConstellations(
    Canvas canvas,
    Size size,
    double pixelsPerTangent,
    double cx,
    double cy,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0x4A5C8FB8);

    for (final constellation in astro.constellations) {
      for (var k = 0; k < constellation.segmentCount; k++) {
        final a = sky.indexByHr[constellation.segments[k * 2]];
        final b = sky.indexByHr[constellation.segments[k * 2 + 1]];
        if (a == null || b == null) continue;

        final pa = _screenPosition(a, pixelsPerTangent, cx, cy, size);
        final pb = _screenPosition(b, pixelsPerTangent, cx, cy, size);
        if (pa == null || pb == null) continue;

        // Ikisi de ekran disindaysa cizme. Biri icerideyse ciz —
        // yarim cizgiler kadraj kenarinda dogaldir.
        final bounds = Rect.fromLTWH(0, 0, size.width, size.height);
        if (!bounds.contains(pa) && !bounds.contains(pb)) continue;

        canvas.drawLine(pa, pb, paint);
      }
    }
  }

  /// Parlak yildiz adlari.
  ///
  /// Yalnizca ekranda gercekten gorunenler cizilir. Tumu her zaman
  /// gosterilseydi genis acida gokyuzu okunmaz olurdu.
  void _paintLabels(
    Canvas canvas,
    Size size,
    double pixelsPerTangent,
    double cx,
    double cy,
  ) {
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);
    for (final entry in astro.brightStarNames.entries) {
      final index = sky.indexByHr[entry.key];
      if (index == null) continue;
      final p = _screenPosition(index, pixelsPerTangent, cx, cy, size);
      if (p == null || !bounds.contains(p)) continue;

      final painter = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: const TextStyle(
            color: Color(0xCCD3E2F0),
            fontSize: 11,
            letterSpacing: 0.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, p + const Offset(7, -6));
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
  // Liste, Map degil: Dart const Map'te double anahtar kabul etmiyor
  // (double == operatorunu ezdigi icin).
  static const _compassPoints = <({double azimuth, String label})>[
    (azimuth: 0, label: 'K'),
    (azimuth: 45, label: 'KD'),
    (azimuth: 90, label: 'D'),
    (azimuth: 135, label: 'GD'),
    (azimuth: 180, label: 'G'),
    (azimuth: 225, label: 'GB'),
    (azimuth: 270, label: 'B'),
    (azimuth: 315, label: 'KB'),
  ];

  void _paintCompass(
    Canvas canvas,
    Size size,
    double pixelsPerTangent,
    double cx,
    double cy,
  ) {
    for (final point in _compassPoints) {
      final p = astro.project(
        azimuthDegrees: point.azimuth,
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
          text: point.label,
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
      old.showHorizon != showHorizon ||
      old.showConstellations != showConstellations ||
      old.showLabels != showLabels;
}
