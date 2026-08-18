# Astro Poz Simülatörü — Yol Haritası

**Tek cümlelik hedef:** Gitmeden önce pozunu doğrula. Konum + tarih + kamera ayarları gir, o gökyüzünden ne çıkacağını fiziksel olarak öğren.

**Ne DEĞİL:** Stellarium klonu. Yıldız haritası zaten var. Bizim sattığımız şey harita değil, *kestirim*.

---

## Teknoloji kararları (bir kez ver, geri dönme)

| Karar | Seçim | Neden |
|---|---|---|
| Dil | Dart | Web + iOS + Android tek kod tabanı. JS'le başlarsan hepsini yeniden yazarsın. |
| Yapı | Monorepo: `astro_core` (saf Dart) + `app` (Flutter) | Hesap kodu Flutter'a bağımlı olmasın → test edilebilir, taşınabilir. |
| Çizim | `CustomPainter` / Canvas | 10.000 nokta için yeterli. `drawRawPoints` ile daha da hızlı. |
| Web | Flutter Web (CanvasKit) | Aynı kod. Vitrin sitesi değil, araç — SEO derdi yok. |
| Durum yönetimi | Başta `ValueNotifier`, gerekirse Riverpod | Faz 3'ten önce state yönetimi mimarisi kurmak vakit kaybı. |
| Zaman | Her şey içeride UTC | En sık hata kaynağı. Yerel saat sadece ekranda. |

### Klasör iskeleti
```
astro_sim/
├── packages/
│   └── astro_core/          # saf Dart, Flutter import YOK
│       ├── lib/
│       │   ├── time/        # Julian Day, LST
│       │   ├── coords/      # RA/Dec ↔ Alt/Az, galaktik
│       │   ├── catalog/     # yıldız verisi okuma
│       │   ├── optics/      # FOV, projeksiyon, NPF
│       │   ├── radiometry/  # foton, gürültü, SNR  ← projenin kalbi
│       │   └── ephemeris/   # Güneş, Ay
│       └── test/            # her modülün testi
├── apps/
│   └── app/                 # Flutter arayüz
└── tools/                   # katalog dönüştürme scriptleri
```

---

## FAZ 0 — Risk avı (2–3 gün) ⚠️ ATLAMA

Bu fazı normalde kimse yapmaz ve o yüzden projeler ölür. Amaç: en riskli parçayı, en az emekle, en başta test etmek.

Projenin riski gökyüzü haritasında değil (o çözülmüş bir problem), **ışık hesabında**. Eğer radyometri gerçekle tutmuyorsa, üstüne 6 hafta arayüz yazmanın hiçbir anlamı yok.

Arayüz yok. Ekranda yıldız yok. Sadece terminalde sayı.

| Task | İş |
|---|---|
| 0.1 | Kendi çektiğin 3 astro karesini seç. Farklı olsunlar: biri şehirden, biri karanlık gökten, biri farklı ISO. |
| 0.2 | Her biri için EXIF'ten çek: lens mm, diyafram, enstantane, ISO, tarih-saat, GPS. `exiftool` yeter. |
| 0.3 | **RAW dosyadan** gökyüzü fonunun ortalama ADU değerini oku. RawDigger (deneme sürümü) veya `rawpy`. JPEG kullanma — üstünde ton eğrisi var, sayı yalan olur. |
| 0.4 | `dart run` ile çalışan tek dosyalık bir script yaz: aynı parametrelerden beklenen fon ADU'sunu hesapla. |
| 0.5 | Karşılaştır. |

**Çıkış kriteri:** Hesaplanan fon ADU'su ile gerçek fon ADU'su **2 kat içinde** olsun. (Evet, 2 kat gevşek görünüyor — ama Bortle sınıflarını elle tahmin ediyorsun, bu aşamada büyüklük mertebesi tutuyorsa fizik doğru.)

**Tutmazsa:** Devam etme. Bana gel, birlikte nerede saptığını bulalım. Genelde suçlu: sensör kazanç değeri (e-/ADU) veya piksel açısal boyutu.

**Kazanç:** Bu 3 günün kodu çöp değil — doğrudan `radiometry/` paketinin çekirdeği oluyor.

---

## FAZ 1 — Temel: zaman ve koordinat (4–6 gün)

Amaç: "Şu yıldız, şu konumda, şu saatte gökyüzünde tam olarak nerede?" sorusuna doğru cevap.

| Task | İş | Test |
|---|---|---|
| 1.1 | Monorepo + `astro_core` paketi kur | `dart test` çalışıyor |
| 1.2 | `DateTime` (UTC) → Julian Day | 1 Ocak 2000 12:00 UTC = 2451545.0 |
| 1.3 | Julian Day → GMST → LST (boylamla) | Bilinen bir tarih için tablo değeriyle karşılaştır |
| 1.4 | RA/Dec → Alt/Az dönüşümü | Aşağıdaki doğrulama matrisi |
| 1.5 | Presesyon (J2000 → şimdi) | Küçük düzeltme ama 25 yılda 0.35° kayma yapar, ekle |
| 1.6 | Doğrulama matrisi: 5 yıldız × 3 konum × 3 zaman = 45 test | Stellarium ile **±0.1°** içinde |

**Doğrulama matrisi için öneri:** Vega, Polaris, Sirius, Antares, Deneb × Gaziantep / İstanbul / Ekvator × yaz gecesi / kış gecesi / gündüz.

**Tuzak:** Zaman dilimi. Türkiye UTC+3, DST yok — ama kullanıcı Şili'den girerse? İçeride her şey UTC. `DateTime.utc()` kullan, `DateTime.now()` değil.

**Çıkış kriteri:** 45 testin hepsi ±0.1° içinde geçiyor. Bu geçmeden Faz 2'ye başlama — sonraki her şey bu sayıların üstüne kuruluyor.

---

## FAZ 2 — Gökyüzü haritası (5–8 gün)

Amaç: Ekranda tanıyabildiğin bir gökyüzü.

| Task | İş | Not |
|---|---|---|
| 2.1 | HYG kataloğunu indir (GitHub, ücretsiz CSV) | ~120k yıldız |
| 2.2 | Filtrele: kadir ≤ 6.5 | ~9000 yıldız kalır. Çıplak göz sınırı, başlangıç için fazlası bile. |
| 2.3 | `tools/` içinde dönüştürme scripti: CSV → kompakt binary | RA, Dec, kadir, B-V → 4× Float32. ~144 KB. CSV parse mobilde yavaş, bunu atlama. |
| 2.4 | Loader: asset → `Float32List` | Tek `ByteData` okuması, sıfır parse |
| 2.5 | Gnomonik (rectilinear) projeksiyon | **Neden bu:** normal lensin gerçek davranışı bu. Stereografik daha "hoş" görünür ama yanlış çerçeveleme verir. |
| 2.6 | `CustomPainter` ile çiz: kadir → nokta boyutu | Logaritmik ölçek. 1. kadir ile 6. kadir arasında 100 kat parlaklık farkı var. |
| 2.7 | B-V renk indeksi → yıldız rengi | Mavi-beyaz-sarı-turuncu. Küçük detay, büyük görsel fark. |
| 2.8 | Takım yıldızı çizgileri | Opsiyonel ama motivasyon için değerli — ilk kez "gökyüzü" gibi görünür. |

**Çıkış kriteri:** Ekranda Büyük Ayı'yı ve Orion'u **gözle tanıyabiliyorsun.** Bu senin projeksiyon testin — 45 unit testten daha güvenilir.

**Tuzak:** Geniş açıda (14mm, ~104°) gnomonik projeksiyon kenarlarda ciddi gerdirme yapar. Bu bir bug değil, gerçek lensler de yapar. Ama 180°'ye yaklaşırsan matematik patlar — fisheye için ayrı projeksiyon gerekir, onu Faz 9'a bırak.

---

## FAZ 3 — Kamera (3–5 gün)

Amaç: Araç ilk kez işe yarıyor. Bu fazın sonunda kullanabilir hale geliyor.

| Task | İş |
|---|---|
| 3.1 | Sensör veritabanı: full frame, APS-C (Canon 1.6 / diğerleri 1.5), MFT, 1", telefon. Her biri için genişlik/yükseklik mm + piksel adımı (µm) |
| 3.2 | FOV hesabı: `2·atan(sensör_kenarı / 2f)` — yatay, dikey, köşegen |
| 3.3 | Ekranda çerçeve kutusu, dışını karart |
| 3.4 | Bakış kontrolü: sürükle → azimut/yükseklik, iki parmak → döndürme |
| 3.5 | Dikey/yatay çevirme |
| 3.6 | NPF kuralı: `t_max = (35N + 30p) / f` (N=diyafram, p=piksel adımı µm, f=odak mm) → maksimum poz |
| 3.7 | Poz süresi > t_max ise iz uzunluğunu **piksel cinsinden** göster |

**Çıkış kriteri:** 14mm full frame'de Orion tam sığıyor; PhotoPills veya Stellarium'un FOV göstergesiyle aynı sonucu veriyor.

**Neden NPF, 500 kuralı değil:** 500 kuralı piksel yoğunluğunu ve deklinasyonu yok sayar. 45 MP bir gövdede 500 kuralı sana yalan söyler — %100'de baktığında izler görünür. NPF gerçek sınırı verir. Bu detay, aracını "ciddi" yapan şeylerden biri.

---

## FAZ 4 — Zaman ve gökyüzü olayları (5–8 gün)

Amaç: "Bu gece ne zaman?" sorusuna cevap.

| Task | İş |
|---|---|
| 4.1 | Zaman kaydırıcısı (dakika hassasiyeti) — yıldızlar dönsün |
| 4.2 | Güneş konumu (düşük hassasiyet yeter, ±0.01°) |
| 4.3 | Alacakaranlık: güneş −18° altı = astronomik karanlık penceresi |
| 4.4 | Ay konumu + evre. Meeus'un kısaltılmış serisi (±0.3°) yeterli — tam ELP teorisine girmeye gerek yok |
| 4.5 | Ay yüksekte ve doluysa **uyarı**: "Ay %78 dolu, 34° yükseklikte — Samanyolu çekilemez" |
| 4.6 | Hedef nesnenin yükseklik/zaman grafiği |
| 4.7 | "En iyi pencere" birleşik göstergesi: karanlık ∧ aysız ∧ hedef > 20° |

**Çıkış kriteri:** Araç şu cümleyi kurabiliyor: *"Bu gece galaktik merkez için pencere 01:20–03:40. Ay 02:50'de doğuyor, %31 dolu — sorun değil."*

**Neden bu faz kritik:** Rakiplerin çoğu bunu yapıyor ama parça parça. Tek ekranda birleştirmek asıl değer.

---

## FAZ 5 — Işık hesabı / radyometri (2–4 hafta) 🎯 PROJENİN KALBİ

Faz 0'daki spike kodu buraya taşınıyor ve olgunlaşıyor. Bu faz projenin var olma sebebi.

| Task | İş |
|---|---|
| 5.1 | Kadir → foton akısı: `F = F₀ · 10^(−0.4m)` |
| 5.2 | Atmosferik sönüm: hava kütlesi `X ≈ 1/cos(z)`, ~0.25 mag/X (yükseltiye göre ayarla) |
| 5.3 | Optik toplama: giriş açıklığı alanı, aktarım verimi, vinyetleme (opsiyonel) |
| 5.4 | Açısal ölçek: arcsec/piksel = `206265 · p / f` |
| 5.5 | Gökyüzü fonu: Bortle 1–9 seçimi → mag/arcsec² (Bortle 9 ≈ 18, Bortle 1 ≈ 22 — arada **40 kat** fark) |
| 5.6 | Sensör modeli: QE, ISO kazancı (e⁻/ADU), okuma gürültüsü, karanlık akım, dolum kapasitesi, bit derinliği |
| 5.7 | 3–4 hazır sensör profili + kullanıcı elle girme | 
| 5.8 | Gürültü toplamı: shot (√sinyal) + okuma² + karanlık² |
| 5.9 | SNR hesabı — nokta kaynak için ve difüz fon için ayrı |
| 5.10 | PSF: Gaussian, seeing + lens keskinliği; yıldızları bu profille boya |
| 5.11 | Histogram + kırpma yüzdesi + siyah kesim uyarısı |
| 5.12 | Ton eğrisi → ekran görüntüsü (kalibre değil, sadece illüstrasyon — bunu arayüzde açıkça belirt) |
| 5.13 | **KALİBRASYON:** 3 gerçek karenle karşılaştır |

**Çıkış kriteri:** Kendi 3 karenin fon seviyesi %15 içinde tutuyor. Faz 0'daki 2 kat gevşekliği burada sıkıyoruz.

**Tuzak 1 — Sensör verisi:** Uydurma değer girersen tüm proje yalan olur. Gerçek okuma gürültüsü ve kazanç verilerini `photonstophotos.net` gibi ölçüm kaynaklarından al. Bu veriyi uydurma.

**Tuzak 2 — Fotogerçekçilik:** Güzel görüntü peşine düşme. Bu fazın çıktısı bir *rapor*:
> Galaktik merkez: 23° yükseklik. SNR ≈ 4.2. Yıldız izi 2.1 px. Fon histogramın %38'ini dolduruyor. Parlak yıldızlarda kırpma yok.

Sahada işine yarayan şey bu rapor. Güzel görüntü Faz 6'da gelir.

---

## FAZ 6 — Samanyolu ve difüz gökyüzü (1–2 hafta)

| Task | İş |
|---|---|
| 6.1 | Tüm-gökyüzü panorama görüntüsü bul. **İlk iş: lisans kontrolü.** Ticari kullanacaksan CC BY-SA seni bağlar. |
| 6.2 | Galaktik ↔ ekvatoral koordinat dönüşümü |
| 6.3 | Küresel eşleme (equirectangular → gökyüzü küresi) |
| 6.4 | Parlaklık kalibrasyonu: piksel değeri → mag/arcsec² |
| 6.5 | Fon + Samanyolu + yıldızları birleştir |
| 6.6 | Hava parıltısı / ufuk gradyanı (şehir yönünde parlama) |

**Neden ayrı faz:** Yıldız nokta kaynak, Samanyolu difüz yüzey parlaklığı. Tamamen farklı iki render yolu. Baştan karıştırırsan mimarin bozulur.

---

## FAZ 7 — Konum ve ufuk (1–2 hafta) — FARKLILAŞTIRICI

| Task | İş |
|---|---|
| 7.1 | Konum arama (geocoding) + haritadan seçme |
| 7.2 | Işık kirliliği verisi otomatik: VIIRS / World Atlas → Bortle tahmini (elle seçim yerine) |
| 7.3 | Yükseklik verisi: Copernicus GLO-30 (ücretsiz, 30m) |
| 7.4 | Konum çevresindeki ufuk profilini hesapla (360° tarama) |
| 7.5 | Ufku çerçeveye çiz |
| 7.6 | Uyarı: *"Merkez 01:40'ta doğuyor ama batı sırtı 18° — 03:10'a kadar göremezsin"* |

**Neden değerli:** Bu, rakiplerin düzgün yapmadığı tek şey. "Konumu buldum ama önümde tepe varmış" hikayesini bilen her astro fotoğrafçı bu özellik için para verir.

---

## FAZ 8 — Yığınlama ve ileri seviye (1 hafta)

| Task | İş |
|---|---|
| 8.1 | N kare × t saniye → SNR ∝ √N |
| 8.2 | Takipçi var/yok anahtarı (takipçi varsa NPF sınırı kalkar) |
| 8.3 | Karşılaştırma modu: 30×20s vs 1×600s hangisi daha iyi |
| 8.4 | Dark/flat kare etkisi (opsiyonel) |
| 8.5 | Narrowband filtre etkisi (opsiyonel, şehir için çok değerli) |

**Neden gerekli:** Ciddi astro çekimi tek kare değil. Bunu desteklemeyen araç yarım kalır.

---

## FAZ 9 — Ürünleşme

| Task | İş |
|---|---|
| 9.1 | Preset kaydetme (kamera + lens kombinasyonların) |
| 9.2 | Plan paylaşma / dışa aktarma |
| 9.3 | Hava durumu API: bulut örtüsü tahmini |
| 9.4 | Offline mod (sahada internet yok — bu bir "nice to have" değil, zorunluluk) |
| 9.5 | iOS/Android build, izinler, ikon, ekran görüntüleri |
| 9.6 | App Store / Play yayını |

---

## MVP çizgisi nerede

```
Faz 0 → 1 → 2 → 3 → 4 → 5   ═══ MVP. Yayınlanabilir. ~2–3 ay part-time.
Faz 6 → 7 → 8                ═══ Derinleşme. Ürünü rakiplerden ayıran kısım.
Faz 9                        ═══ Cila.
```

Faz 3'ün sonunda elinde zaten kendi kullanabileceğin bir şey var. Faz 5'in sonunda başkasına gösterebileceğin bir şey.

---

## Baştan kurulacak alışkanlıklar

1. **Her `astro_core` fonksiyonu için test.** Bu bürokrasi değil — burada gözle "yanlış" göremezsin. 0.3° hata ekranda normal görünür ama sahada seni yanlış yere götürür. Test tek savunman.
2. **Sihirli sayı yasak.** Her sabitin yanına birimi ve kaynağı yorum olarak yazılacak. 6 hafta sonra `0.25` neyi ifade ediyordu diye düşünmek istemezsin.
3. **Git commit'leri faz/task numarasıyla.** `feat(coords): T1.4 RA/Dec → Alt/Az dönüşümü`
4. **Her fazın sonunda ekran görüntüsü al ve sakla.** Hem ilerlemeyi görürsün hem sonra portfolyo/mağaza görselleri için malzeme olur.
5. **Faz atlamak yok.** Özellikle Faz 0'ı atlama.

---

## Bilinmeyenler (şimdi karar vermene gerek yok, ama aklında olsun)

- **Panorama lisansı** — Faz 6'ya kadar araştırılmalı. Ticari plan varsa erken bak.
- **Sensör veri kaynağı** — kaç gövde profili yeter? 4 mü, 200 mü? Kullanıcı geri bildirimi karar verir.
- **Ücretlendirme** — tek seferlik mi, abonelik mi? Ufuk profili + hava durumu API maliyeti var, bedavaya sürdürülemez.
- **Derin gökyüzü nesneleri** — bulutsular, galaksiler. Messier kataloğu kolay ama difüz nesneler için görüntü verisi gerekir. Faz 6'nın uzantısı.
