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

  /// Zaman kaydiricisinin bulundugu an.
  final DateTime currentUtc;

  /// Kullaniciya gosterilecek yerel saat farki. Hesap hep UTC; yalnizca
  /// gosterimde yerele cevriliyor (yol haritasi: "yerel saat sadece ekranda").
  final Duration localOffset;

  const NightPanel({
    super.key,
    required this.plan,
    required this.targetName,
    required this.currentUtc,
    required this.localOffset,
  });

  /// Kaydiricinin bulundugu ana en yakin ornek.
  SkyConditions? get _now {
    if (plan.samples.isEmpty) return null;
    return plan.samples.reduce(
      (a, b) =>
          a.utc.difference(currentUtc).inSeconds.abs() <
              b.utc.difference(currentUtc).inSeconds.abs()
          ? a
          : b,
    );
  }

  String _local(DateTime utc) {
    final t = utc.add(localOffset);
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  /// Ekranda gosterilen ceza degeri. Renk ve metin ikisi de BUNU
  /// kullanir, ham degeri degil.
  ///
  /// Sebebi: ham deger bir ondalige yuvarlanarak yaziliyor ve yuvarlama
  /// esigin obur tarafina gecebiliyor. 24 Mayis 2026'da gercek ceza
  /// 1.4643 — ekranda "1.5 kadir" yaziyor ama nokta turuncu, cunku renk
  /// 1.4643 < 1.5 diye karar veriyor. Kullanici "1.5 yaziyor ama kirmizi
  /// degil" diye hakli olarak sasiriyor. Yil boyunca bu 5 gun oluyor.
  ///
  /// Esikler zaten keskin fiziksel sabitler degil (0.5 gozle ayirt
  /// edilebilirligin, 1.5 difuz hedeflerin bogulmasinin kabaca siniri),
  /// o yuzden gosterilen degere hizalamanin fiziksel bir bedeli yok.
  /// Kazanc: gordugun sayi ile gordugun renk hicbir zaman celismiyor.
  double _shownPenalty(double penalty) =>
      double.parse(penalty.toStringAsFixed(1));

  /// Ay cezasini karara cevirir.
  ///
  /// Esikler fiziksel: 0.5 kadir altinda fon farki gozle ayirt edilmez,
  /// 1.5 uzeri difuz hedefleri (Samanyolu, bulutsu) bogar.
  ({Color color, String verdict}) _moonVerdict(double rawPenalty) {
    final penalty = _shownPenalty(rawPenalty);
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
            if (_now != null) _liveConditions(_now!),
            const SizedBox(height: 8),
            AltitudeGraph(plan: plan, currentUtc: currentUtc),
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

  /// Kaydiricinin bulundugu andaki kosullar.
  ///
  /// Pencere gecenin ozelligi, bu ise ANIN ozelligi — kaydirici
  /// oynatildikca degisen tek sey burasi. Ikisini ayirmak, kullanicinin
  /// "neden hicbir sey degismiyor" diye sormasini onluyor.
  Widget _liveConditions(SkyConditions now) => DefaultTextStyle(
    style: const TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      height: 1.5,
      color: Color(0xFFBFD4E6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_local(now.utc)} — hedef '
          '${now.targetAltitudeDegrees.toStringAsFixed(1)}°'
          '${now.targetAltitudeDegrees < 0 ? " (ufkun altinda)" : ""}',
        ),
        Text(
          '  Ay ${now.moonAltitudeDegrees.toStringAsFixed(1)}°   '
          'ayrim ${now.moonSeparationDegrees.toStringAsFixed(0)}°   '
          'ceza ${now.moonPenaltyMagnitudes.toStringAsFixed(2)} kadir',
        ),
        Text(
          '  gokyuzu: ${now.isDark ? "astronomik karanlik" : "aydinlik / alacakaranlik"}',
          style: TextStyle(
            color: now.isDark
                ? const Color(0xFF5FD08A)
                : const Color(0xFF6B8299),
          ),
        ),
      ],
    ),
  );

  String _moonSentence(int percent, double penalty, String verdict) {
    final buffer = StringBuffer('Ay %$percent dolu');
    if (plan.moonRise != null) {
      buffer.write(", ${_local(plan.moonRise!)}'te doguyor");
    }
    if (plan.moonSet != null) {
      buffer.write(", ${_local(plan.moonSet!)}'te batiyor");
    }
    buffer.write(
      ' — ${_shownPenalty(penalty).toStringAsFixed(1)} kadir, $verdict',
    );
    return buffer.toString();
  }
}
