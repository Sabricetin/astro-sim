import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// T5 — Kalibrasyon defterini yukleme ekrani (urun karari: Kademe 2).
///
/// Uygulama RAW dosyasi cozemiyor (LibRaw gerekiyor), o yuzden kopru
/// buradan kuruluyor: Python araclari olcumu yapar ve
/// `kalibrasyon.json` uretir, kullanici icerigini buraya yapistirir.
///
/// Yapistirma secildi cunku her yerde calisiyor — masaustu, web,
/// telefon. Dosya secici eklemek bir bagimlilik ve web'de ayri bir yol
/// demek olurdu.
class CalibrationPanel extends StatefulWidget {
  final LoadedCalibration? loaded;
  final ValueChanged<LoadedCalibration?> onChanged;

  const CalibrationPanel({
    super.key,
    required this.loaded,
    required this.onChanged,
  });

  @override
  State<CalibrationPanel> createState() => _CalibrationPanelState();
}

class _CalibrationPanelState extends State<CalibrationPanel> {
  final _controller = TextEditingController();
  String? _error;
  bool _editing = false;

  static const _mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    height: 1.55,
    color: Color(0xFFBFD4E6),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    try {
      final loaded = parseCalibrationJson(_controller.text);
      setState(() {
        _error = null;
        _editing = false;
      });
      widget.onChanged(loaded);
    } on CalibrationFormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loaded = widget.loaded;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE60B1018),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (loaded == null || _editing)
              ..._input()
            else
              ..._summary(loaded),
          ],
        ),
      ),
    );
  }

  List<Widget> _input() => [
    const Text(
      'Sahadan donunce olcum sonucunu buraya yapistir.',
      style: TextStyle(fontSize: 12, color: Color(0xFFDDE8F2)),
    ),
    const SizedBox(height: 4),
    const Text(
      './.venv/bin/python tools/analyze_field_night.py ...\n'
      'komutunun urettigi  sonuc/kalibrasyon.json  dosyasinin icerigi',
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 10,
        height: 1.5,
        color: Color(0xFF6B8299),
      ),
    ),
    const SizedBox(height: 8),
    ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 120),
      child: TextField(
        controller: _controller,
        maxLines: null,
        expands: false,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
        decoration: InputDecoration(
          hintText: '{ "format": "astro-sim-kalibrasyon", ... }',
          hintStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: Color(0xFF44586B),
          ),
          isDense: true,
          border: const OutlineInputBorder(),
          errorText: _error,
          errorMaxLines: 6,
        ),
      ),
    ),
    const SizedBox(height: 8),
    // Wrap, Row degil: dar ekranda uc dugme yan yana sigmiyor ve
    // tasma hatasi veriyordu (390 px'te 26 piksel tasiyordu).
    Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton(onPressed: _apply, child: const Text('Yukle')),
        TextButton(
          onPressed: () async {
            final data = await Clipboard.getData('text/plain');
            if (data?.text != null) {
              _controller.text = data!.text!;
              _apply();
            }
          },
          child: const Text('Panodan yapistir'),
        ),
        if (widget.loaded != null)
          TextButton(
            onPressed: () => setState(() {
              _editing = false;
              _error = null;
            }),
            child: const Text('Vazgec'),
          ),
      ],
    ),
  ];

  List<Widget> _summary(LoadedCalibration l) {
    final c = l.calibration;
    final rows = <(String, String, Measured?)>[
      ('k', 'sonum katsayisi', c.extinctionCoefficient),
      ('ZP', 'sifir noktasi', c.zeroPoint),
      ('FWHM', 'yildiz profili', c.psfFwhmPixels),
      ('I_d', 'karanlik akim', c.darkCurrent),
      ('mu_sky', 'gokyuzu fonu', c.skyMagPerSquareArcsec),
      ('dV_G', 'bant duzeltmesi', c.bandCorrectionPerColorIndex),
    ];
    return [
      Row(
        children: [
          const Icon(
            Icons.verified_outlined,
            size: 14,
            color: Color(0xFF5FD08A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.source,
              style: const TextStyle(fontSize: 12, color: Color(0xFFDDE8F2)),
            ),
          ),
          if (l.measuredAt != null)
            Text(
              l.measuredAt!,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B8299)),
            ),
        ],
      ),
      if (l.identifiedStarHr != null) ...[
        const SizedBox(height: 2),
        Text(
          'sifir noktasi HR ${l.identifiedStarHr} ile olculdu'
          '${c.zeroPointFNumber != null ? ", f/${c.zeroPointFNumber!.toStringAsFixed(0)}'de" : ""}',
          style: const TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            color: Color(0xFF6B8299),
          ),
        ),
      ],
      const SizedBox(height: 10),
      DefaultTextStyle(
        style: _mono,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [for (final (sym, name, m) in rows) _row(sym, name, m)],
        ),
      ),
      if (l.unknownFields.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          'Bu surumun tanimadigi alanlar: ${l.unknownFields.join(", ")}\n'
          'Dosya daha yeni bir surumden gelmis olabilir.',
          style: const TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            color: Color(0xFFE0A44C),
          ),
        ),
      ],
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        children: [
          TextButton(
            onPressed: () => setState(() => _editing = true),
            child: const Text('Degistir'),
          ),
          TextButton(
            onPressed: () {
              _controller.clear();
              setState(() {
                _editing = false;
                _error = null;
              });
              widget.onChanged(null);
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
    ];
  }

  Widget _row(String symbol, String name, Measured? m) {
    final has = m != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            has ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 13,
            color: has ? const Color(0xFF5FD08A) : const Color(0xFF44586B),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 58, child: Text(symbol)),
          SizedBox(
            width: 118,
            child: Text(
              name,
              style: const TextStyle(fontSize: 11, color: Color(0xFF8FA5B8)),
            ),
          ),
          Expanded(
            child: Text(
              has
                  ? '${m.value.toStringAsFixed(3)} ${m.unit}'
                        '${m.relativeUncertainty != null ? "  ±%${(m.relativeUncertainty! * 100).toStringAsFixed(0)}" : ""}'
                  : 'olculmedi',
              style: TextStyle(
                fontSize: 11,
                color: has ? const Color(0xFFBFD4E6) : const Color(0xFF6B8299),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
