import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';

import 'altitude_graph.dart';

/// T4.6 + T4.8 — Gece ozeti ve "en iyi pencere" gostergesi.
///
/// Faz 4'un cikis kriteri, aracin su cumleyi kurabilmesi:
///   "Bu gece galaktik merkez icin pencere 01:20-03:40.
///    Ay 02:50'de doguyor, %31 dolu — sorun degil."
/// Bu widget o cumleyi ekrana yaziyor.
class NightPanel extends StatelessWidget {
  final NightPlan plan;
  final String targetName;

  /// Kullaniciya gosterilecek yerel saat farki. Hesap hep UTC; yalnizca
  /// gosterimde yerele cevriliyor (yol haritasi: "yerel saat sadece ekranda").
  final Duration localOffset;

  const NightPanel({
    super.key,
    required this.plan,
    required this.targetName,
    required this.localOffset,
  });

  String _local(DateTime utc) {
    final t = utc.add(localOffset);
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  /// Ay cezasini karara cevirir.
  ///
  /// Esikler fiziksel: 0.5 kadir altinda fon farki gozle ayirt edilmez,
  /// 1.5 uzeri difuz hedefleri (Samanyolu, bulutsu) bogar.
  ({Color color, String verdict}) _moonVerdict(double penalty) {
    if (penalty < 0.5) {
      return (color: const Color(0xFF5FD08A), verdict: 'sorun degil');
    }
    if (penalty < 1.5) {
      return (color: const Color(0xFFE0A44C), verdict: 'dikkat');
    }
    return (color: const Color(0xFFE06C6C), verdict: 'cekilemez');
  }

  @override
  Widget build(BuildContext context) {
    final best = plan.best;
    final moonPercent = (plan.moonIlluminatedFraction * 100).round();
    final penalty = plan.worstMoonPenalty;
    final verdict = _moonVerdict(penalty);

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
            Text(
              targetName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE4EEF6),
              ),
            ),
            const SizedBox(height: 8),
            if (plan.darkness.neverDark)
              const Text(
                'Bu gece hic astronomik karanlik olmuyor.',
                style: TextStyle(color: Color(0xFFE06C6C), fontSize: 13),
              )
            else if (best == null)
              const Text(
                'Hedef bu gece esik yuksekliginin uzerine cikmiyor.',
                style: TextStyle(color: Color(0xFFE0A44C), fontSize: 13),
              )
            else ...[
              Text(
                'Pencere ${_local(best.start)} – ${_local(best.end)}'
                '   (${best.duration.inMinutes} dk)',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  color: Color(0xFF8FC8F0),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: verdict.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _moonSentence(moonPercent, penalty, verdict.verdict),
                      style: TextStyle(
                        color: verdict.color,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            AltitudeGraph(plan: plan),
            const SizedBox(height: 4),
            Text(
              'mavi: hedef   sari: Ay   koyu bant: karanlik   yesil: pencere',
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B8299)),
            ),
          ],
        ),
      ),
    );
  }

  String _moonSentence(int percent, double penalty, String verdict) {
    final buffer = StringBuffer('Ay %$percent dolu');
    if (plan.moonRise != null) {
      buffer.write(", ${_local(plan.moonRise!)}'te doguyor");
    }
    if (plan.moonSet != null) {
      buffer.write(", ${_local(plan.moonSet!)}'te batiyor");
    }
    buffer.write(' — ${penalty.toStringAsFixed(1)} kadir, $verdict');
    return buffer.toString();
  }
}
