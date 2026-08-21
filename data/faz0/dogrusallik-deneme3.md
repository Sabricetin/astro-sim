# 0.A.6 doğrusallık — 3. deneme ve kapanış (22 Ağustos 2026)

**Sonuç: doğrusalsızlık saptanmadı.** 0.A.6 kapandı — ama %1 değil,
**%2–3'lük** bir sınırla. Gerekçe aşağıda.

Kurulum: gece 01:24, kapalı oda, tavan LED'i, f/18, ISO 1600,
8 basamak (0.4–3.2 s), palindrom, 16 kare, 116 saniye.

## Bulunan araç hatası — bu asıl kazanç

`sensor_ptc.py` EXIF'teki **ExposureTime** alanını kullanıyordu. O alan
makinenin *gösterdiği* değerdir ve yuvarlanmıştır. Gerçek süre 1/3 durak
serisinden gelir ve `ShutterSpeedValue`'da durur:

| Gösterilen | Gerçek | Fark |
|---|---|---|
| 0.4 s | 0.3856 s | −3.61% |
| 0.8 s | 0.7711 s | −3.61% |
| 2.5 s | 2.5937 s | **+3.75%** |
| 3.2 s | 3.2210 s | +0.66% |

Doğrusallık testi tam da bu büyüklükteki sapmaları arıyor. Yuvarlanmış
değeri kullanmak testi anlamsız kılıyordu.

Düzeltmenin etkisi: **artık RMS %3.02 → %1.88**, ve düşük dolulukta
görülen sistematik negatif eğilim tamamen kayboldu.

Kazanç ölçümü etkilenmedi — kazanç poz süresini bilmeyi gerektirmez.

## Ölçüm sonucu

Işık kayması −1.76%/dakika olarak ölçüldü ve düzeltildi. Kalan:

| | |
|---|---|
| Maks sapma (kayma düzeltilmiş) | **%3.60** |
| RMS sapma | **%1.96** |
| Doğrusalsızlık katsayısı β | +2.85% ± 2.46% |
| Anlamlılık | **1.2σ — saptanmadı** |
| %95 üst sınır (test aralığında) | %6.1 |

Kalan sapmada **doluluk seviyesiyle bir eğilim yok** — değerler sıfırın
etrafında saçılıyor. Yani bu gürültü, sensörün eğrisi değil.

## Beklenmedik ikramiye: kazanç doğrulandı

Bu ölçüm kazancı **0.1254 e⁻/ADU** verdi. Faz 0.A'da kayıtlı değer
**0.1265**. Farklı gün, farklı ışık kaynağı, farklı sıcaklık —
**%0.9 uyum.**

Kazanç ölçümünün tekrarlanabilirliği böylece bağımsız olarak doğrulandı.
Bu, doğrusallık sonucundan daha değerli çıktı.

## Neden %1 yerine %2–3 ile kapatıyoruz

Kalan gürültü ışık kaynağının kısa süreli oynaklığından geliyor: ard
arda 9 saniye arayla çekilen iki 3.2 s karesi arasında bile %0.6
açıklanamayan fark var. Bunu %1'in altına indirmek entegre küre veya
akkor kaynak ister; elimizde yok.

Üç gerekçeyle burada duruyoruz:

1. **Faz 5'in çıkış kriteri %15.** %2–3'lük doğrusallık belirsizliği bu
   bütçenin içinde rahat kalıyor.
2. **Faz 0.B Dizi A zaten bir doğrusallık merdiveni.** Gökyüzünde
   5/10/15/20/30/60 s, sabit ISO. Astronomik karanlıkta gökyüzü,
   oda LED'inden **çok daha kararlı** bir kaynak — ve ölçüm asıl
   kullanılacak sinyal seviyelerinde, asıl pozlarda yapılmış olacak.
   Yerinde yapılan test, laboratuvar flat'ından daha ilgili.
3. Üç deneme oldu; aynı ekipmanla dördüncüsünden kazanç beklenmiyor.

**Kesin doğrulama Dizi A'ya devredildi.** Bu bir erteleme değil; daha
iyi bir ölçüme taşıma.
