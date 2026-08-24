import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:astro_core/astro_core.dart' as astro;
import 'package:flutter/material.dart';

import 'camera_settings.dart';
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

  /// Arazi profili. Verilirse ufuk cizgisinin uzerine engel silueti
  /// cizilir ve altindaki gokyuzu karartilir.
  final astro.Horizon? horizonProfile;
  final bool showConstellations;
  final bool showLabels;

  /// Verilirse cerceve kutusu cizilir ve disi karartilir.
  final CameraSettings? frame;

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
    this.horizonProfile,
    this.showConstellations = true,
    this.showLabels = true,
    this.frame,
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

    final frameSettings = frame;
    if (frameSettings != null) {
      _paintFrame(canvas, size, pixelsPerTangent, cx, cy, frameSettings);
    }
  }

  /// Kadraj kutusu: secilen govde + lensin gercekte gorecegi alan.
  ///
  /// Boyut, gorus alaninin tanjantindan gelir — gnomonik projeksiyon
  /// zaten rectilinear lensi modelledigi icin kutu, gercek cercevenin
  /// birebir karsiligidir. Yaklasiklik yok.
  void _paintFrame(
    Canvas canvas,
    Size size,
    double pixelsPerTangent,
    double cx,
    double cy,
    CameraSettings settings,
  ) {
    final fov = settings.fieldOfView;
    final halfWidth =
        math.tan(astro.toRadians(fov.horizontalDegrees / 2)) * pixelsPerTangent;
    final halfHeight =
        math.tan(astro.toRadians(fov.verticalDegrees / 2)) * pixelsPerTangent;
    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: halfWidth * 2,
      height: halfHeight * 2,
    );

    // Cercevenin disini karart: hangi kismin kadraja girdigi tek bakista
    // anlasilsin.
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRect(rect),
    );
    canvas.drawPath(outside, Paint()..color = const Color(0x99000000));

    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xCC7FC4E8),
    );

    // Ucte bir cizgileri — kadraj kurarken referans.
    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = const Color(0x338FB8D4);
    for (var i = 1; i < 3; i++) {
      final x = rect.left + rect.width * i / 3;
      final y = rect.top + rect.height * i / 3;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), guide);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), guide);
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
    Offset? at(double az, double alt) {
      final p = astro.project(
        azimuthDegrees: az,
        altitudeDegrees: alt,
        centerAzimuthDegrees: centerAzimuthDegrees,
        centerAltitudeDegrees: centerAltitudeDegrees,
        rollDegrees: rollDegrees,
      );
      if (p == null) return null;
      return Offset(cx + p.x * pixelsPerTangent, cy - p.y * pixelsPerTangent);
    }

    // Matematiksel ufuk (0 derece) — her zaman, referans olarak.
    final flat = Path();
    var started = false;
    for (var az = 0.0; az <= 360.0; az += 0.5) {
      final o = at(az, 0.0);
      if (o == null) {
        started = false;
        continue;
      }
      if (!started) {
        flat.moveTo(o.dx, o.dy);
        started = true;
      } else {
        flat.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(
      flat,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x66407080),
    );

    final profile = horizonProfile;
    if (profile == null || profile.isFlat) return;

    // Arazi silueti.
    //
    // "Ufkun alti" ekranda asagi DEMEK DEGIL — kadraj dondurulmus
    // olabilir (roll). O yuzden dolgu ekran dibine kadar cizilmiyor;
    // her azimutta profil yuksekliginden -25 dereceye kadar inen bir
    // serit olarak, gokyuzu koordinatlarinda kuruluyor. Boylece her
    // yonelimde dogru yer kararir.
    const floor = -25.0;
    var run = <Offset>[];
    var runFloor = <Offset>[];

    void flush() {
      if (run.length < 2) {
        run = [];
        runFloor = [];
        return;
      }
      final fill = Path()..moveTo(run.first.dx, run.first.dy);
      for (final o in run.skip(1)) {
        fill.lineTo(o.dx, o.dy);
      }
      for (final o in runFloor.reversed) {
        fill.lineTo(o.dx, o.dy);
      }
      fill.close();
      canvas.drawPath(fill, Paint()..color = const Color(0xCC0A0E14));

      final ridge = Path()..moveTo(run.first.dx, run.first.dy);
      for (final o in run.skip(1)) {
        ridge.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        ridge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xAA6B8299),
      );
      run = [];
      runFloor = [];
    }

    for (var az = 0.0; az <= 360.0; az += 0.5) {
      final top = at(az, profile.altitudeAt(az));
      final bottom = at(az, floor);
      if (top == null || bottom == null) {
        flush();
        continue;
      }
      run.add(top);
      runFloor.add(bottom);
    }
    flush();
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
      old.horizonProfile != horizonProfile ||
      old.sky != sky ||
      old.centerAzimuthDegrees != centerAzimuthDegrees ||
      old.centerAltitudeDegrees != centerAltitudeDegrees ||
      old.horizontalFovDegrees != horizontalFovDegrees ||
      old.rollDegrees != rollDegrees ||
      old.showHorizon != showHorizon ||
      old.showConstellations != showConstellations ||
      old.showLabels != showLabels ||
      old.frame != frame;
}
