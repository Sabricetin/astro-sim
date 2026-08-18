# FAZ 0.A — Referans karşılaştırması ve kalan belirsizlik

**Tarih:** 2026-08-19
**Gövde:** Canon EOS 760D (14 bit, beyaz seviye 15360, siyah 2049)
**Referans:** photonstophotos.net — RN_ADU.htm ve RN_e.htm grafikleri

## Ölçülen değerler (bu proje)

| ISO | Kazanç (e⁻/ADU) | Okuma gür. (ADU) | Okuma gür. (e⁻) | Doyum (e⁻) |
|---|---|---|---|---|
| 800  | 0.2473 | 10.41 | 2.57 | 3.292 |
| 1600 | 0.1265 | 16.11 | 2.04 | 1.683 |
| 3200 | 0.0655 | 25.89 | 1.69 | 871 |

Yöntem: foton transfer eğrisi, G1 kanalı, 400 px merkez ROI, seviye başına 2 kare.
R² = 0.9998 / 0.9995 / 0.9997. Ham veri: `iso{800,1600,3200}.json`.

## Referans değerler (photonstophotos.net)

| ISO | Okuma gür. (DN) | Okuma gür. (e⁻) | Türetilen kazanç |
|---|---|---|---|
| 800  | 10.196 | 2.204 | 0.2162 |
| 1600 | 16.912 | 1.828 | 0.1081 |
| 3200 | 26.325 | 1.424 | 0.0541 |

## Fark

| Büyüklük | ISO 800 | ISO 1600 | ISO 3200 |
|---|---|---|---|
| Okuma gürültüsü (ADU) | %2.1 | %4.7 | %1.6 |
| Okuma gürültüsü (e⁻) | %16.8 | %11.5 | %19.0 |
| Kazanç | %14.4 | %17.0 | %21.0 |

**Doğrudan ölçülen büyüklük (ADU cinsinden okuma gürültüsü) %5 içinde uyuşuyor.**
Kalan tüm fark tek bir sistematik kazanç farkından geliyor: bizimki ~%17 yüksek.

## Hangisinin doğru olduğu belirlenemedi

Taban ISO'ya götürülmüş dolum kapasitesi:

- **Bizim:** 26.334 / 26.934 / 27.880 e⁻ → %5.7 yayılım (bağımsız ölçüm hatası)
- **Site:** 23.019 / 23.020 / 23.041 e⁻ → **%0.10 yayılım**

Sitenin üç değerinin bu kadar tutarlı olması, üç bağımsız ölçümden değil tek bir
kazanç çapasından türetildiğini gösterir. Yani karşılaştırmada üç değil bir
bağımsız nokta var.

İkisi de fiziksel olarak makul (3.72 µm piksel için 1.660–1.950 e⁻/µm²).

## Karar

**Faz 0.A geçmiş sayıldı**, aşağıdaki çekinceyle:

- Kazanç değerleri **±%17 belirsizlikle** kullanılacak.
- Faz 0.D'de (hesaplanan vs gerçek gökyüzü fonu) sistematik bir sapma çıkarsa,
  ilk şüpheli bu kazanç farkıdır — oraya bakılmadan başka yer aranmasın.
- Faz 5'in kriteri %15'e sıkıştığında bu belirsizlik yeterli olmayabilir.
  O noktada ya gökyüzü kalibrasyonu kazancı düzeltir, ya kazanç ölçümü
  bağımsız bir yöntemle tekrarlanır (ör. bilinen bir ışık kaynağıyla mutlak
  fotometri, veya ikinci bir gövdeyle çapraz kontrol).

## Ölçülemeyen: doğrusallık

Işık kaynağı kararsızdı (sinyal/poz oranı ISO 800 merdiveninde %37 yayıldı).
Kazancı ve okuma gürültüsünü etkilemez — ikisi de poz süresine bağlı değil —
ama doğrusallık testi geçersiz. Kararlı bir ışıkla (kısılmamış akkor ampul)
tek ISO merdiveni tekrar çekilerek kapatılabilir. Faz 0.A'nın çıkış kriteri
değil, Faz 5 radyometri modelinin girdisi.
