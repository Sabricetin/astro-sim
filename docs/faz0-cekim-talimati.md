# FAZ 0.A — Çekim talimatı

**Amaç:** Sensörünün kazancını (e⁻/ADU) ve okuma gürültüsünü (e⁻) *ölçmek*. Tahmin etmek değil.

**Süre:** ~2 saat. **Gökyüzü gerekmez.** Hava durumuna bağlı değilsin, bu akşam yapabilirsin.

**Neden ilk bu:** Radyometri denkleminde en büyük bilinmeyen gökyüzü değil, sensörün kendisi. Bunu ölçmeden gökyüzüne çıkarsan, sapmanın fizikten mi sensör tahmininden mi geldiğini ayıramazsın — ve Faz 0'ın asıl amacı tam olarak bu ayrımı yapmak.

---

## 0 — Önce kapatılacaklar

Bunlar RAW'a müdahale eder ve ölçümü sessizce bozar:

- [ ] **Uzun poz gürültü azaltma** (Long Exposure NR) — KAPALI. Açıksa kamera arka planda kendi dark karesini çıkarır, bias ölçümün anlamsızlaşır.
- [ ] **Yüksek ISO gürültü azaltma** — KAPALI. Bazı gövdelerde RAW'a da dokunur.
- [ ] **Lens düzeltmeleri** (vinyetleme / distorsiyon) — KAPALI. Bazı Sony ve Nikon gövdeleri vinyetleme düzeltmesini RAW'a gömer; bu düzlüğü bozar.
- [ ] **Auto ISO** — KAPALI.
- [ ] **Genişletilmiş ISO** değerlerini kullanma (L, H, 50, 102400 gibi). Sadece **yerel** ISO'lar.
- [ ] Kayıt formatı: **RAW**, sıkıştırmasız veya kayıpsız. "Lossy compressed RAW" varsa kapat.

---

## 1 — Bias kareleri (~15 dakika)

Sıfır ışık, mümkün olan en kısa poz. Bunlar okuma gürültüsünü ve offset seviyesini verir.

| Ayar | Değer |
|---|---|
| Mod | Manuel (M) |
| Enstantane | En kısa (1/4000 veya 1/8000) |
| Diyafram | Fark etmez |
| ISO | Hedef ISO (aşağıya bak) |
| Lens | Kapak takılı |
| **Vizör** | **Kapalı** — DSLR'de optik vizörden ışık sızar. Bu en sık yapılan hata. |
| Kare sayısı | **20+**, seri çekimle arka arkaya |

Karanlık bir odada çek. Kapağın üstünü ayrıca bir bezle ört.

> ⚠️ **Bias, flat'larla AYNI ISO'da olmak zorunda.** Okuma gürültüsü ISO'ya bağlıdır; ISO 100 bias'ıyla ISO 800 okuma gürültüsü hesaplanamaz. Üç ISO kullanacaksan **üç ayrı bias seti** çekeceksin (her biri 20 kare). Araç karışık ISO görürse durur, sessizce yanlış sonuç vermez.
>
> Bu ilk denemede atlanan adım buydu — bias ISO 100'de, flat'lar 800/1600/3200'de çekilmişti.

> Sonuçta "iki okuma gürültüsü tahmini çok ayrışıyor" uyarısı alırsan, suçlu neredeyse her zaman ışık sızıntısıdır.

---

## 2 — Flat kareler (~1 saat)

Düzgün aydınlatılmış bir yüzey, karanlıktan doyuma kadar bir **poz merdiveni**, her basamakta **2 kare**.

### Işık kaynağı — buradaki tek gerçek tuzak

Ölçüm, iki karenin farkının varyansını foton gürültüsü sayar. Işık kaynağın titriyorsa, o titreme varyansa eklenir ve **kazancı olduğundan küçük gösterir.**

**İyi kaynaklar:**
- Pencereden gelen gün ışığının beyaz duvardan yansıması
- Akkor / halojen ampul (titremez)
- Alacakaranlık göğü

**Kötü kaynaklar:**
- Kısılmış LED lamba — PWM ile titrer
- Telefon / laptop ekranı, düşük parlaklıkta — PWM
- Ucuz LED paneller

LED kullanmak zorundaysan: **tam parlaklıkta** kullan ve poz sürelerini **1/50 s'den uzun** tut, titreme ortalamada sönsün.

### Kurulum

- Lensin önüne difüzör: 2–3 kat beyaz tişört, aydınger kağıdı veya buzlu plastik
- **Netliği tamamen boz** (manuel odak) — toz ve doku görüntülenmesin
- Diyafram sabit, f/5.6 civarı
- ISO sabit (bias ile aynı)

### Merdiven

Enstantaneyi histogramın sola yapıştığı yerden başlat, her adımda **iki katına çıkar**, sağdan taşmaya başlayana kadar devam et. Tipik olarak 8–12 basamak.

> **Canon EOS 760D için ölçülmüş değerler (18 Ağustos denemesinden)**
>
> İlk denemede f/3.5'te 1/50 s zaten doyumun %22'sini veriyordu; merdiven iki adımda tavana çarptı ve ISO 3200'de ilk kare bile doydu. Işığı ~10× kısmak gerekiyor.
>
> | ISO | Diyafram | Enstantane aralığı | Adım |
> |---|---|---|---|
> | 800 | f/11 | 1/50 s → 0.6 s | ½ durak |
> | 1600 | f/11 | 1/100 s → 0.3 s | ½ durak |
> | 3200 | f/11 | 1/200 s → 0.15 s | ½ durak |
>
> ISO 800 için somut liste: `1/50, 1/30, 1/20, 1/13, 1/8, 1/5, 0.3, 0.5, 0.6` → 9 seviye × 2 kare = 18 kare.
>
> Diyaframı kısmak yerine difüzöre 2 kat daha katman eklemek de aynı işi görür.
>
> **Kontrol:** İlk kareyi çektikten sonra devam etmeden önce doyum yüzdesini ölç. Bir saatlik çekimin sonunda kullanılamaz olduğunu öğrenmektense, ilk karede öğren.

Her basamakta **arka arkaya 2 kare** çek. Çiftin iki karesi arasında ışık değişmemeli — bu yüzden aynı anda, ayarı ellemeden.

> **1/250 s'den kısa pozlardan kaçın.** Mekanik perdenin zamanlama hatası çok kısa pozlarda büyür. Bu kazanç ölçümünü etkilemez (kazanç poz süresini bilmeyi gerektirmez) ama doğrusallık testini bozar.

---

## 3 — Hangi ISO'lar

En az **3 ISO**: düşük, orta, yüksek. Astro çekimde gerçekten kullandıkların olsun.

Tipik: **800, 1600, 3200** (veya 400 / 1600 / 6400).

Her ISO için 1. ve 2. adımın **tamamını** tekrarla — o ISO'nun bias'ı + o ISO'nun flat merdiveni. Kazanç ve okuma gürültüsü ISO'ya göre değişir; karıştırılamaz.

---

## 4 — Dosyaları yerleştir

```
data/faz0/
├── bias/     ← tüm ISO'ların bias kareleri
└── flats/    ← tüm ISO'ların flat kareleri
```

Hepsi tek klasöre girebilir; araç ISO'ya göre filtreler. Yanlışlıkla karıştırırsan araç durdurur, sessizce yanlış sonuç vermez.

---

## 5 — Çalıştır

Her ISO için ayrı:

```bash
cd ~/Desktop/Sanal-Uzay

./.venv/bin/python tools/sensor_ptc.py \
    --bias  data/faz0/bias \
    --flats data/faz0/flats \
    --iso   800 \
    --out   data/faz0/iso800
```

Çıktı:
- `data/faz0/iso800.json` — sonuçlar, repoda versiyonlanır (alışkanlık #7)
- `data/faz0/iso800.png` — foton transfer eğrisi grafiği

---

## 6 — Çıkış kriteri

Bulduğun **kazanç** ve **okuma gürültüsü**, `photonstophotos.net` sitesindeki aynı gövde ölçümlerinin **%20'si içinde** olmalı.

Tutuyorsa: Faz 0.A bitti. Sensör modelinde artık uydurma sayı yok, Faz 5.7'nin yarısı hazır.

Tutmuyorsa, sırayla bak:

| Belirti | Muhtemel neden |
|---|---|
| R² < 0.98 | Işık kaynağı titriyor (PWM). Kaynağı değiştir. |
| Kazanç beklenenden **düşük** | Yine titreme — fazladan varyans kazancı küçültür. |
| Kazanç beklenenden **yüksek** | Karelerin çifti aynı seviyede değil, ya da arada ışık değişmiş. |
| İki okuma gürültüsü tahmini çok ayrışıyor | Bias karelerine ışık sızmış. Vizörü kapat. |
| "Yetersiz nokta" hatası | Merdiven çok dar. Daha fazla basamak, daha geniş aralık. |
| Doğrusallık sapması > %2 | Çok kısa pozlar kullanılmış (perde zamanlama hatası) ya da doyuma çok yaklaşılmış. |

Hangi belirtiyi aldığını bana söyle, birlikte bakarız.

---

## Sıradaki

0.A bittikten sonra **0.B** (bir gece, tek konum, ISO + poz merdiveni) ve **0.C** (VIIRS'ten bağımsız fon parlaklığı) geliyor. 0.A'nın çıktısı ikisinin de girdisi — o yüzden önce bu.
