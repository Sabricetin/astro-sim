import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';

/// T4.7 — Hedefin yukseklik/zaman grafigi.
///
/// Uc bilgiyi ust uste bindirir: hedefin yuksekligi (egri), gokyuzunun
/// karanlik oldugu araliklar (koyu bant) ve cekim penceresi (vurgulu bant).
/// Ayri ayri sunulsalardi kullanicinin kafasinda birlestirmesi gerekirdi;
/// yol haritasinin "asil deger tek ekranda birlestirmek" dedigi sey bu.
class AltitudeGraph extends StatelessWidget {
  final NightPlan plan;
  final double minimumAltitudeDegrees;

  const AltitudeGraph({
    super.key,
    required this.plan,
    this.minimumAltitudeDegrees = 20,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 120,
    child: CustomPaint(
      painter: _AltitudeGraphPainter(
        plan: plan,
        minimumAltitude: minimumAltitudeDegrees,
      ),
      size: Size.infinite,
    ),
  );
}

class _AltitudeGraphPainter extends CustomPainter {
  final NightPlan plan;
  final double minimumAltitude;

  _AltitudeGraphPainter({required this.plan, required this.minimumAltitude});

  /// Grafigin dikey araligi. Ufkun biraz altini da gostermek, hedefin ne
  /// zaman dogdugunu okunur kilar.
  static const double _minAltitude = -15;
  static const double _maxAltitude = 90;

  @override
  void paint(Canvas canvas, Size size) {
    final samples = plan.samples;
    if (samples.length < 2) return;

    final from = samples.first.utc;
    final span = samples.last.utc.difference(from).inSeconds.toDouble();
    if (span <= 0) return;

    double x(DateTime t) => t.difference(from).inSeconds / span * size.width;
    double y(double altitude) =>
        size.height *
        (1 - (altitude - _minAltitude) / (_maxAltitude - _minAltitude));

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF080D14),
    );

    // Karanlik araliklar.
    final darkPaint = Paint()..color = const Color(0x33223A52);
    DateTime? darkStart;
    for (final s in samples) {
      if (s.isDark && darkStart == null) darkStart = s.utc;
      if (!s.isDark && darkStart != null) {
        canvas.drawRect(
          Rect.fromLTRB(x(darkStart), 0, x(s.utc), size.height),
          darkPaint,
        );
        darkStart = null;
      }
    }
    if (darkStart != null) {
      canvas.drawRect(
        Rect.fromLTRB(x(darkStart), 0, size.width, size.height),
        darkPaint,
      );
    }

    // Cekim pencereleri.
    for (final w in plan.shootingWindows) {
      canvas.drawRect(
        Rect.fromLTRB(x(w.start), 0, x(w.end), size.height),
        Paint()..color = const Color(0x335FD08A),
      );
    }

    // Ufuk ve esik cizgileri.
    final gridPaint = Paint()
      ..color = const Color(0x44557088)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, y(0)), Offset(size.width, y(0)), gridPaint);
    canvas.drawLine(
      Offset(0, y(minimumAltitude)),
      Offset(size.width, y(minimumAltitude)),
      Paint()
        ..color = const Color(0x335FD08A)
        ..strokeWidth = 1,
    );

    // Ay yuksekligi — soluk, ikincil bilgi.
    final moonPath = Path();
    for (var i = 0; i < samples.length; i++) {
      final p = Offset(x(samples[i].utc), y(samples[i].moonAltitudeDegrees));
      i == 0 ? moonPath.moveTo(p.dx, p.dy) : moonPath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      moonPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x66E0C48C),
    );

    // Hedefin yukseklik egrisi.
    final targetPath = Path();
    for (var i = 0; i < samples.length; i++) {
      final p = Offset(x(samples[i].utc), y(samples[i].targetAltitudeDegrees));
      i == 0 ? targetPath.moveTo(p.dx, p.dy) : targetPath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      targetPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF8FC8F0),
    );

    _label(canvas, '90°', Offset(4, y(90) + 2));
    _label(
      canvas,
      '${minimumAltitude.toStringAsFixed(0)}°',
      Offset(4, y(minimumAltitude) + 2),
    );
    _label(canvas, 'ufuk', Offset(4, y(0) + 2));
  }

  void _label(Canvas canvas, String text, Offset at) {
    TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Color(0x996B8299),
            fontSize: 9,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )
      ..layout()
      ..paint(canvas, at);
  }

  @override
  bool shouldRepaint(_AltitudeGraphPainter old) =>
      old.plan != plan || old.minimumAltitude != minimumAltitude;
}
