# 0.A.6 doğrusallık — 1. deneme (20 Ağustos 2026)

**Sonuç: geçmedi.** Ama ilk denemeden çok daha bilgilendirici; ikisi de
düzeltilebilir iki ayrı sorun var ve hiçbiri sensörün suçu değil.

Kurulum: doğal pencere ışığı, EF-S 18-55 @ 18 mm f/14, ISO 1600,
8 basamak × 2 kare, 1/60 → 2 s. Toplam süre 70 sn. Sensör 35–37 °C.

## Bulgu 1 — En üst basamak doymuş

| Poz | Sinyal | Tam ölçeğin |
|---|---|---|
| 1 s | 7940 ADU | %59.7 |
| **2 s** | **13256 ADU** | **%99.6** ← doymuş |

2 s karesinin −16.4'lük "sapması" doğrusalsızlık değil, **kırpma.**
Doymuş bir pikselin sinyali artmaz; ölçüm oraya bakmamalı.

## Bulgu 2 — Asıl aralık hiç test edilmemiş

Doyan kare atılınca merdiven **%60'ta bitiyor.** Doğrusalsızlığın
gerçekten ortaya çıktığı yer ise **%60–%90** arası. Yani bu merdiven
temiz çıksaydı bile sorulan soruyu cevaplamamış olurdu.

## Bulgu 3 — İki plato, arada %5.1 basamak

| Poz aralığı | Eğim (ADU/s) |
|---|---|
| 1/60 – 1/15 | 7546 |
| 1/8 – 1 s | 7932 |
| Fark | **+5.1%** |

Işık kararsızlığı **değil**: aynı basamaktaki iki kare birbirini
%0.2–2.3 içinde tutuyor, yani her basamak çekilirken ışık sabitti.
Sıçrama 1/15 ile 1/8 arasında, 4 saniye içinde oluyor.

İki aday, bu veriyle ayırt edilemiyor:

1. **Perde zamanlama hatası** — kısa pozlarda deklanşörün gerçek süresi
   yazandan farklı.
2. **Ortam ışığının gerçekten değişmesi** — bulut kenarı geçmiş olabilir.

Ayırt edecek deney ucuz: **merdiveni ters sırayla tekrarla.** Basamak
poz süresini takip ediyorsa perde, saati takip ediyorsa ışık.

## İyi haber — plato içinde sensör doğrusal

1/8 – 1 s aralığına ayrıca uydurulduğunda:

| Poz | Sapma |
|---|---|
| 1/8 s | +1.58% |
| 1/4 s | +0.04% |
| 1/2 s | −0.53% |
| 1 s | +0.11% |

Dördün üçü **%0.6 içinde.** 1/8'deki 1.58 basamağın hemen yanında,
muhtemelen ondan bulaşmış. Sensörün kendisi bu aralıkta temiz görünüyor.

## Projeye özel not

Bu araç **5–60 saniyelik** pozlarla çalışıyor. 1/60–1/15 bölgesi
astrofotoğrafta hiç kullanılmıyor. Yani Bulgu 3 merak konusu ama
**kritik değil**; kritik olan Bulgu 2, yani %60–90 aralığının
ölçülmemiş olması.
