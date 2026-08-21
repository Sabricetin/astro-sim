# 0.A.6 — Doğrusallık merdiveni kareleri

**CR2 dosyalarını doğrudan bu klasöre at.** Alt klasör açma, isim
değiştirme — araç poz süresini ve ISO'yu EXIF'ten okuyor.

## Neden ayrı klasör

`data/faz0/flats/` içindeki 80 kare **kararsız ışıkla** çekilmişti.
Kazanç ölçümü onlardan geldi ve geçerli (kazanç poz süresini bilmeyi
gerektirmez), ama doğrusallık testi bozuldu.

Yeni kareler oraya karıştırılırsa **zaten geçmiş olan kazanç ölçümü de
bozulur.** İki ölçüm ayrı kalmalı.

## Bias kareleri yeniden çekilmedi — gerekmiyor

`data/faz0/bias/` içindeki ISO 1600 kareleri kullanılacak. Bias, ışık
kaynağından bağımsız (kapak takılı çekiliyor), o yüzden hâlâ geçerli.

Tek kontrol: eski bias kareleri 30–32 °C'de çekilmişti. Yeni karelerin
sıcaklığı çok farklıysa bias seviyesi biraz kaymış olabilir. Analizde
bakılacak.

## Çalıştırma

```bash
./.venv/bin/python tools/sensor_ptc.py \
  --bias data/faz0/bias \
  --flats data/faz0/dogrusallik \
  --iso 1600 \
  --out data/faz0/dogrusallik-sonuc
```

## Geçme ölçütü

| Ölçüt | Eşik | Anlamı |
|---|---|---|
| `light_spread_pct` | **< %2** | Işık kararlıydı — test doğrusallığı ölçtü |
| `max_deviation_pct` | **< %1** | Sensör doğrusal |

**Sıralama önemli:** Önce ışığa bak. Işık kararsızsa sapma değeri
sensörün değil ampulün ölçüsüdür ve okumanın anlamı yoktur. İlk denemede
tam olarak bu oldu.

RAW dosyaları `.gitignore`'da — repoya girmezler, sadece ölçüm sonuçları
(json/png) versiyonlanır.
