# Astro Poz Simülatörü — Yol Haritası

**Tek cümlelik hedef:** Gitmeden önce pozunu doğrula. Konum + tarih + kamera ayarları gir, o gökyüzünden ne çıkacağını fiziksel olarak öğren.

**Ne DEĞİL:** Stellarium klonu. Yıldız haritası zaten var. Bizim sattığımız şey harita değil, *kestirim*.

**İş modeli:** Ücretsiz başlangıç → abonelik. Bu bir teknik karar değil ama teknik kararları bağlıyor: kullandığın her veri kaynağı ticari kullanıma uygun olmak zorunda. Aşağıdaki lisans bölümü bu yüzden var.

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
| Yıldız kataloğu | Yale Bright Star (BSC5) | HYG değil — lisans bölümüne bak. Kapsam aynı: V≈6.5'e kadar 9.110 yıldız. |
| Fotometrik bant | Yeşil kanal ≈ Johnson V + B−V düzeltmesi | Aşağıdaki "bant kararı" bölümüne bak. Bu kararı vermezsen radyometri yalan söyler. |
| Birimler | Piksel adımı `p` **her yerde µm**, odak `f` **her yerde mm** | Aşağıya bak — bu belgede birim karışıklığı bir kez oldu bile. |

### Bant kararı (Faz 0'dan önce oku)

Katalogdaki kadirler **Johnson V** bandında ölçülü. Senin sensörünün R/G/B kanalları V bandı değil. `F = F₀ · 10^(−0.4m)` formülünü uygulayıp çıkan fotonu doğrudan ADU'ya çevirirsen, yıldızın renk sıcaklığına göre iki yönde birden sapma alırsın — kırmızı yıldızda bir yöne, mavi yıldızda diğerine, tipik %30–50.

**Karar:** Yeşil kanalı V bandına yaklaşık kabul et, üstüne B−V renk indeksine bağlı doğrusal bir düzeltme terimi koy. Katsayıyı Faz 0'daki ölçümlerinden türet.

**Neden tam çözüm değil:** Doğrusu, sensörün spektral tepki eğrisi ile yıldızın spektrumunun çarpımının integralini almak. Doğru ama Faz 5'i haftalarca uzatır ve sensör spektral verisi çoğu gövde için yayınlanmamış. Yaklaşık düzeltme %15 kriterini tutturmaya yeter.

**Arayüzde belirt:** Renk hesabı yaklaşıktır. Kullanıcıya doğruluk sözü verdiğin yer fon seviyesi ve SNR, yıldızın tam rengi değil.

### Birim tuzağı

İki formül, iki farklı birim beklentisi — kendi "sihirli sayı yasak" kuralının ilk kurbanı bu olur:

- NPF (3.6): `t_max = (35N + 30p) / f` → **p mikrometre**, f milimetre
- Açısal ölçek (5.4): `arcsec/px = 206265 · p / f` → bu katsayı **p'nin milimetre** olmasını ister

Çözüm: `p` her yerde µm tutulur, açısal ölçek formülü `arcsec/px = 206.265 · p(µm) / f(mm)` olarak yazılır. Kodda tip düzeyinde ayır — çıplak `double` yerine `Micrometers` / `Millimeters` sarmalayıcıları kullanmayı düşün.

### Klasör iskeleti
```
astro_sim/
├── packages/
│   └── astro_core/          # saf Dart, Flutter import YOK
│       ├── lib/
│       │   ├── time/        # Julian Day, LST
│       │   ├── coords/      # RA/Dec ↔ Alt/Az, galaktik, kırılma
│       │   ├── catalog/     # yıldız + hedef nesne verisi okuma
│       │   ├── optics/      # FOV, projeksiyon, NPF
│       │   ├── radiometry/  # foton, gürültü, SNR  ← projenin kalbi
│       │   └── ephemeris/   # Güneş, Ay
│       └── test/            # her modülün testi
├── apps/
│   └── app/                 # Flutter arayüz
└── tools/                   # katalog dönüştürme scriptleri
```

---

## Lisans kararları — ticari plan olduğu için ŞİMDİ ver

Ücretsiz bir hobi projesinde bunlar ertelenebilir. Abonelik satacaksan erteleyemezsin: veri formatını ve loader'ı yazdıktan sonra kaynak değiştirmek, o kodu çöpe atmak demek.

| Varlık | Karar | Not |
|---|---|---|
| Yıldız kataloğu | **Yale Bright Star (BSC5)**, VizieR üzerinden | Kamuya açık klasik katalog, atıfla kullanılır. 9.110 nesne, V≈6.5 sınırı — senin filtrenle birebir örtüşüyor. Kullanmadan önce VizieR sayfasındaki kullanım koşullarını bir kez oku. |
| ~~HYG~~ | **Kullanma** | CC BY-SA. Share-alike, ürettiğin türev veritabanını da bağlar; ücretli bir uygulamanın içinde dağıtman katalog dosyanı BY-SA yapar. Yasak değil ama gereksiz bir yük — BSC5 aynı işi görürken buna girme. |
| Derin gökyüzü hedefleri | **Messier kataloğu** | Kamuya açık, 110 nesne. Ad, RA/Dec, kadir, tip. NGC'ye Faz 6+'da bakarsın. |
| Samanyolu panoraması | **ESO veya NASA kaynaklı** | ESO görselleri genel olarak CC BY 4.0 (ticari kullanıma uygun, atıf yeter) — kullanacağın spesifik görselin sayfasında teyit et. NASA görselleri kamu malı. Popüler amatör panoramaların çoğu CC BY-NC — **ticari planla uyumsuz**, cezbedici görünseler de alma. |
| Sensör verisi (kazanç, okuma gürültüsü) | `photonstophotos.net` referans, kendi ölçümün asıl | Ölçüm verisini uygulamanın içine gömüyorsan kaynağın kullanım koşullarına bak. Kendi ölçtüğün gövdeler için bu sorun yok. |
| Işık kirliliği (VIIRS) | Kamu verisi | NOAA/Colorado School of Mines kaynaklı, serbest. |
| Yükseklik verisi (Copernicus GLO-30) | Ücretsiz, atıf gerekli | Ticari kullanıma açık. |

**Abonelik ekonomisi — şimdi bilmen gereken:** Faz 7 ve 9'daki özelliklerin tekrarlayan maliyeti var (hava durumu API çağrıları, DEM barındırma/işleme, geocoding). Aboneliğin fiyatlandırmasını bu maliyetler belirleyecek. Faz 7'ye gelmeden kaba bir kullanıcı başına aylık maliyet hesabı çıkar — özelliği yapıp sonra "bunu bu fiyata sürdüremiyorum" demek en pahalı hata.

---

## FAZ 0 — Risk avı (3–4 gün) ⚠️ ATLAMA

Bu fazı normalde kimse yapmaz ve o yüzden projeler ölür. Amaç: en riskli parçayı, en az emekle, en başta test etmek.

Projenin riski gökyüzü haritasında değil (o çözülmüş bir problem), **ışık hesabında**. Radyometri gerçekle tutmuyorsa, üstüne 6 hafta arayüz yazmanın anlamı yok.

Arayüz yok. Ekranda yıldız yok. Sadece terminalde sayı.

**Kurgu mantığı:** Denklemdeki en büyük bilinmeyen gökyüzü değil, **sensörün kendisi**. Kazanç ve okuma gürültüsünü ölçmeden gökyüzüne bakarsan, sapmanın fizikten mi sensör tahmininden mi geldiğini ayıramazsın. O yüzden önce sensörü sabitliyoruz, sonra gökyüzüne çıkıyoruz.

### 0.A — Sensör karakterizasyonu (evde, gökyüzü gerekmez, ~2 saat)

| Task | İş |
|---|---|
| 0.A.1 | Bias kareleri: lens kapağı takılı, en kısa enstantane, ISO sabit, 20+ kare |
| 0.A.2 | Flat kareler: düz aydınlatılmış yüzey (beyaz ekran, aydınger kağıdı), farklı poz süreleriyle karanlıktan doyuma kadar bir merdiven, her seviyeden 2 kare |
| 0.A.3 | Foton transfer eğrisi: her seviye için ortalama sinyal (ADU) vs iki karenin farkının varyansı. Eğimin tersi = **kazanç (e⁻/ADU)** |
| 0.A.4 | Bias karelerinin standart sapması × kazanç = **okuma gürültüsü (e⁻)** |
| 0.A.5 | Kullandığın her ISO için tekrarla (en az 3 ISO: düşük, orta, yüksek) |
| 0.A.6 | Doğrusallık kontrolü: sinyal-poz süresi grafiği doyuma kadar düz mü? Kırıldığı nokta senin gerçek dolum kapasiten |

**Çıkış kriteri:** Ölçtüğün kazanç ve okuma gürültüsü, `photonstophotos.net`'teki aynı gövde ölçümlerinin **%20'si içinde**. Tutmuyorsa ölçüm yönteminde hata var, gövdende değil — tekrar et.

**Kazanç:** Bundan sonra sensör modelinde uydurma sayı yok. Faz 5.6'nın yarısı burada bitiyor.

### 0.B — Kontrollü gökyüzü çekimi (bir gece, tek konum)

| Task | İş |
|---|---|
| 0.B.1 | Bilinen bir konumda, açık ve aysız bir gecede çek. Konumu GPS'ten not al — EXIF'e güvenme, elle yaz |
| 0.B.2 | ISO merdiveni: aynı kadraj, aynı poz süresi, 3 farklı ISO |
| 0.B.3 | Poz merdiveni: aynı kadraj, aynı ISO, 3 farklı poz süresi |
| 0.B.4 | Hepsi RAW. Kadraj gökyüzünün boş bir bölgesini içersin (fon ölçümü için) ve 30° üstünde olsun |

**Neden merdiven:** Tek kare tek denklem verir; modelin doğru mu yoksa şanslı mı olduğunu ayırt edemezsin. Merdiven, modelin ISO ve poz süresine *tepkisini* test eder — asıl kanıt bu.

### 0.C — Bağımsız fon parlaklığı

| Task | İş |
|---|---|
| 0.C.1 | 0.B'deki konumun VIIRS / World Atlas verisinden mag/arcsec² değerini al (lightpollutionmap.info gibi bir kaynak yeter) |
| 0.C.2 | SQM cihazın varsa yerinde ölç — varsa bu birincil kaynak |

**Bu adım neden var:** Bortle sınıfını gözle tahmin edip sonra modeli o tahmine kalibre edersen doğrulama yapmış olmazsın, eğri uydurmuş olursun. Fon parlaklığının bağımsız bir ölçümü olmadan Faz 5'in %15 kriteri anlamsız. Bir öğleden sonralık iş, karşılığında bütün kalibrasyon zinciri anlam kazanıyor.

### 0.D — Hesap

| Task | İş |
|---|---|
| 0.D.1 | `dart run` ile çalışan tek dosyalık script: 0.A'daki ölçülmüş sensör parametreleri + 0.C'deki fon parlaklığı → beklenen fon ADU'su |
| 0.D.2 | **RAW'dan gerçek fon ADU'sunu oku.** Yeşil kanal (G1 veya G2), beyaz ayarı çarpanları uygulanmamış, ton eğrisi yok. `rawpy` veya RawDigger. JPEG kullanma — üstünde ton eğrisi var, sayı yalan olur |
| 0.D.3 | Karşılaştır — sadece tek kare için değil, ISO ve poz merdiveninin **her basamağı** için |

**Çıkış kriteri:**
- Tek kare için hesaplanan/gerçek fon ADU oranı **2 kat içinde**
- **Ve** bu oran merdivenin tüm basamaklarında **tutarlı** — yani ISO'yu iki katına çıkardığında hata iki katına çıkmıyor

İkinci kriter birincisinden daha önemli. Sabit bir çarpan hatası bulunabilir bir hatadır (genelde eksik bir verim terimi). Basamaktan basamağa değişen hata, modelin yapısının yanlış olduğu anlamına gelir.

**Tutmazsa:** Devam etme. Genelde suçlu, önem sırasıyla: (1) lens aktarım verimi ihmal edilmiş — T-stop f-stop'tan farklıdır, tipik %10–20 kayıp, (2) piksel açısal boyutu birim hatası (yukarıdaki birim tuzağına bak), (3) bant uyumsuzluğu düzeltmesi eksik.

**B planı — elindeki kareler yetersizse:** 0.A tamamen evde yapılır, hiçbir şeye bağlı değil — her koşulda yap. 0.B için tek bir açık gece ve balkon bile yeter; farklı Bortle sınıflarından kare şart değil, o Faz 5'in işi. **İnternetten fotoğraf indirip kalibrasyon yapma** — o karenin gerçek fon parlaklığını, o sensörün kazancını, işlenip işlenmediğini bilemezsin. Bilinmeyen veriye kalibre etmek, kalibre etmemekten kötüdür çünkü sana yanlış bir güven verir.

---

## FAZ 1 — Temel: zaman ve koordinat (5–7 gün)

Amaç: "Şu yıldız, şu konumda, şu saatte gökyüzünde tam olarak nerede?" sorusuna doğru cevap.

| Task | İş | Test |
|---|---|---|
| 1.1 | Monorepo + `astro_core` paketi kur | `dart test` çalışıyor |
| 1.2 | `DateTime` (UTC) → Julian Day | 1 Ocak 2000 12:00 UTC = 2451545.0 |
| 1.3 | Julian Day → GMST → LST (boylamla) | Bilinen bir tarih için tablo değeriyle karşılaştır |
| 1.4 | RA/Dec → Alt/Az dönüşümü | Aşağıdaki doğrulama matrisi |
| 1.5 | Presesyon (J2000 → şimdi) | Küçük düzeltme ama 25 yılda 0.35° kayma yapar, ekle |
| 1.6 | **Atmosferik kırılma** — Bennett formülü: `R = 1/tan(h + 7.31/(h+4.4))` arcdakika | Aşağıdaki nota bak |
| 1.7 | Doğrulama matrisi: 5 yıldız × 3 konum × 3 zaman = 45 test | Stellarium ile **±0.1°** içinde |

**Kırılma neden burada ve neden kritik:** Bu proje düşük yükseklik projesidir. Galaktik merkezin deklinasyonu ≈ −29°; Gaziantep'ten (~37°K) maksimum yüksekliği **~24°**. Yani senin başlık kullanım senaryon, atmosferin en kalın olduğu bölgede geçiyor. Kırılmanın büyüklüğü:

| Gerçek yükseklik | Kırılma |
|---|---|
| 45° | ~1' |
| 24° (galaktik merkez zirvesi) | ~2' |
| 10° | ~5' |
| 5° | ~10' |
| 0° (ufuk) | ~34' |

Senin toleransın ±0.1° = 6 arcdakika. Yani 10°'nin altında kırılma tek başına toleransı yer.

**Ve asıl tuzak: Stellarium varsayılan olarak kırılmayı uygular.** Bunu bilmezsen 1.7'de düşük yükseklikteki testlerin tutmaz ve nedenini bulmak günlerini alır. İki seçenek — birini seç ve buraya yaz:
- Stellarium'da atmosferi kapat, saf geometrik konumu karşılaştır (testler daha temiz)
- Kırılmayı uygula, Stellarium'un varsayılanıyla karşılaştır (uygulamanın gerçek davranışına daha yakın)

Önerim: **ikisini de yap.** `apparentAltitude()` ve `geometricAltitude()` ayrı fonksiyonlar olsun, ikisi de test edilsin. Faz 7'de ufuk profiliyle karşılaştırma yaparken görünür yüksekliğe ihtiyacın olacak.

**Doğrulama matrisi:** Vega, Polaris, Sirius, Antares, Deneb × Gaziantep / İstanbul / Ekvator × yaz gecesi / kış gecesi / gündüz.

**Matrise şunu ekle:** En az bir test **10° altı yükseklikte** olsun. Kırılma kodunun sessizce yanlış olmadığını kanıtlayan tek test bu. Matrisin kalanı yüksek irtifada geçer ve kırılma hatasını gizler.

**Tuzak — zaman dilimi:** Türkiye UTC+3, DST yok — ama kullanıcı Şili'den girerse? İçeride her şey UTC. `DateTime.utc()` kullan, `DateTime.now()` değil.

**Not — neyi eklemene gerek yok:** Nutasyon (max ~17") ve yıllık aberasyon (max ~20.5") toplamı 0.01° altında kalır. ±0.1° toleransında ihmal edilebilir. Presesyon + kırılma yeter.

**Çıkış kriteri:** 45 testin hepsi ±0.1° içinde geçiyor, düşük yükseklik testi dahil. Bu geçmeden Faz 2'ye başlama — sonraki her şey bu sayıların üstüne kuruluyor.

---

## FAZ 2 — Gökyüzü haritası (5–8 gün)

Amaç: Ekranda tanıyabildiğin bir gökyüzü.

| Task | İş | Not |
|---|---|---|
| 2.1 | **BSC5** kataloğunu indir (VizieR, katalog V/50) | 9.110 yıldız, V≈6.5 sınırı. Filtrelemeye bile gerek yok — kapsam zaten senin hedefin. Lisans bölümüne bak: HYG değil, bu. |
| 2.2 | `tools/` içinde dönüştürme scripti: katalog → kompakt binary | RA, Dec, kadir, B−V → 4× Float32. ~145 KB. Metin parse mobilde yavaş, bunu atlama. |
| 2.3 | Loader: asset → `Float32List` | Tek `ByteData` okuması, sıfır parse |
| 2.4 | **Messier kataloğu** (110 nesne): ad, RA/Dec, kadir, tip, açısal boyut | Küçük, elle bile girilebilir. Faz 4.6'nın "hedef nesne" grafiği buna dayanacak — şimdi eklemezsen orada tıkanırsın. |
| 2.5 | Gnomonik (rectilinear) projeksiyon | **Neden bu:** normal lensin gerçek davranışı bu. Stereografik daha "hoş" görünür ama yanlış çerçeveleme verir. |
| 2.6 | `CustomPainter` ile çiz: kadir → nokta boyutu | Logaritmik ölçek. 1. kadir ile 6. kadir arasında 100 kat parlaklık farkı var. |
| 2.7 | B−V renk indeksi → yıldız rengi | Mavi-beyaz-sarı-turuncu. Küçük detay, büyük görsel fark. B−V'yi sakla — Faz 5'teki bant düzeltmesi de bunu kullanacak. |
| 2.8 | Takım yıldızı çizgileri | Opsiyonel ama motivasyon için değerli — ilk kez "gökyüzü" gibi görünür. Çizgi verisi için kaynak lisansına bak. |

**Çıkış kriteri:** Ekranda Büyük Ayı'yı ve Orion'u **gözle tanıyabiliyorsun.** Bu senin projeksiyon testin — 45 unit testten daha güvenilir.

**Tuzak:** Geniş açıda (14mm, ~104°) gnomonik projeksiyon kenarlarda ciddi gerdirme yapar. Bu bir bug değil, gerçek lensler de yapar. Ama 180°'ye yaklaşırsan matematik patlar — fisheye için ayrı projeksiyon gerekir, onu Faz 9'a bırak.

---

## FAZ 3 — Kamera (3–5 gün)

Amaç: Araç ilk kez işe yarıyor. Bu fazın sonunda kullanabilir hale geliyor.

| Task | İş |
|---|---|
| 3.1 | Sensör veritabanı: full frame, APS-C (Canon 1.6 / diğerleri 1.5), MFT, 1", telefon. Her biri için genişlik/yükseklik mm + piksel adımı (**µm**) |
| 3.2 | FOV hesabı: `2·atan(sensör_kenarı / 2f)` — yatay, dikey, köşegen |
| 3.3 | Ekranda çerçeve kutusu, dışını karart |
| 3.4 | Bakış kontrolü: sürükle → azimut/yükseklik, iki parmak → döndürme |
| 3.5 | Dikey/yatay çevirme |
| 3.6 | NPF kuralı: `t_max = (35N + 30p) / f` (N=diyafram, p=piksel adımı **µm**, f=odak **mm**) → maksimum poz |
| 3.7 | Deklinasyon düzeltmesi: iz hızı ekvatorda maksimum, kutupta sıfır — `t_max / cos(δ)` |
| 3.8 | Poz süresi > t_max ise iz uzunluğunu **piksel cinsinden** göster |

**Çıkış kriteri:** 14mm full frame'de Orion tam sığıyor; PhotoPills veya Stellarium'un FOV göstergesiyle aynı sonucu veriyor.

**Neden NPF, 500 kuralı değil:** 500 kuralı piksel yoğunluğunu yok sayar. 45 MP bir gövdede 500 kuralı sana yalan söyler — %100'de baktığında izler görünür. NPF gerçek sınırı verir. Bu detay, aracını "ciddi" yapan şeylerden biri.

**3.7 neden ayrı görev:** Temel NPF formülü de deklinasyonu yok sayar — hedefin göksel ekvatorda olduğunu varsayar. Kutup yıldızı civarında sana gereksiz kısa poz önerir, orada çok daha uzun poz verebilirsin. Senin ana hedefin galaktik merkez (δ ≈ −29°, cos δ ≈ 0.87) olduğu için fark %13 — küçük ama ölçülebilir, ve Kuzey Amerika Bulutsusu gibi yüksek deklinasyonlu hedeflerde büyüyor.

---

## FAZ 4 — Zaman ve gökyüzü olayları (5–8 gün)

Amaç: "Bu gece ne zaman?" sorusuna cevap.

| Task | İş |
|---|---|
| 4.1 | Zaman kaydırıcısı (dakika hassasiyeti) — yıldızlar dönsün |
| 4.2 | Güneş konumu (düşük hassasiyet yeter, ±0.01°) |
| 4.3 | Alacakaranlık: güneş −18° altı = astronomik karanlık penceresi |
| 4.4 | Ay konumu + evre. Meeus'un kısaltılmış serisi (±0.3°) yeterli — tam ELP teorisine girmeye gerek yok |
| 4.5 | **Ay'ın fon parlaklığına katkısı** — Krisciunas & Schaefer (1991) modeli: evre + Ay yüksekliği + hedefe açısal uzaklık + hava kütlesi → ek mag/arcsec² |
| 4.6 | Ay yüksekte ve doluysa uyarı: "Ay %78 dolu, 34° yükseklikte — Samanyolu çekilemez" |
| 4.7 | Hedef nesne seçimi (2.4'teki Messier kataloğundan) + yükseklik/zaman grafiği |
| 4.8 | "En iyi pencere" birleşik göstergesi: karanlık ∧ aysız ∧ hedef > 20° |

**Çıkış kriteri:** Araç şu cümleyi kurabiliyor: *"Bu gece galaktik merkez için pencere 01:20–03:40. Ay 02:50'de doğuyor, %31 dolu — sorun değil."*

**4.5 neden kritik ve neden 4.6'dan ayrı:** 4.6 niteliksel bir uyarı — kullanıcıya faydalı ama hesaba girmiyor. 4.5 ise **Faz 5'in doğrudan girdisi**: Ay'lı gecede fon parlaklığı 2–3 kadir artabilir, bu SNR'ı 3–4 kat düşürür. Bu terimi koymazsan aracın Ay'lı gece için tamamen yanlış poz önerir. Faz 5'in fon modeli `taban_fon(Bortle) + ay_katkısı(4.5)` şeklinde kurulmalı — mimariyi baştan böyle kur.

**Neden bu faz kritik:** Rakiplerin çoğu bunu yapıyor ama parça parça. Tek ekranda birleştirmek asıl değer.

---

## FAZ 5 — Işık hesabı / radyometri (3–5 hafta) 🎯 PROJENİN KALBİ

Faz 0'daki spike kodu buraya taşınıyor ve olgunlaşıyor. Bu faz projenin var olma sebebi.

| Task | İş |
|---|---|
| 5.1 | Kadir → foton akısı: `F = F₀ · 10^(−0.4m)`, V bandı sıfır noktasıyla |
| 5.2 | **Bant düzeltmesi:** B−V'ye bağlı düzeltme terimi (bant kararı bölümüne bak). Katsayı Faz 0'daki ölçümlerden gelir |
| 5.3 | Atmosferik sönüm: hava kütlesi **Kasten-Young** `X = 1/(cos z + 0.50572·(96.07995−z)^−1.6364)`, ~0.25 mag/X (yükseltiye göre ayarla) |
| 5.4 | Optik toplama: giriş açıklığı alanı, **lens aktarım verimi (T-stop)**, vinyetleme (opsiyonel) |
| 5.5 | Açısal ölçek: `arcsec/px = 206.265 · p(µm) / f(mm)` — birim tuzağına bak |
| 5.6 | Gökyüzü fonu: Bortle 1–9 seçimi **veya** VIIRS'ten otomatik → mag/arcsec² (Bortle 9 ≈ 18, Bortle 1 ≈ 22 — arada **40 kat** fark) + 4.5'teki Ay katkısı |
| 5.7 | Sensör modeli: **Faz 0.A'da ölçtüğün** kazanç ve okuma gürültüsü + QE, karanlık akım, dolum kapasitesi, bit derinliği |
| 5.8 | 3–4 hazır sensör profili + kullanıcı elle girme |
| 5.9 | Gürültü toplamı: shot (√sinyal) + okuma² + karanlık² |
| 5.10 | SNR hesabı — nokta kaynak için ve difüz fon için ayrı |
| 5.11 | PSF: Gaussian, seeing + lens keskinliği; yıldızları bu profille boya |
| 5.12 | Histogram + kırpma yüzdesi + siyah kesim uyarısı |
| 5.13 | Ton eğrisi → ekran görüntüsü (kalibre değil, sadece illüstrasyon — bunu arayüzde açıkça belirt) |
| 5.14 | **KALİBRASYON:** Faz 0.B'deki merdivenle + varsa yeni karelerle karşılaştır |

### Uygulama sırası kararı — 18 Ağustos 2026

Faz 5, Faz 0.B (kontrollü gökyüzü çekimi), 0.C (VIIRS fon parlaklığı) ve
0.D (hesap–gerçek karşılaştırması) bitmeden **kalibre edilemez.** Bunlar
açık ve ay'sız bir gece bekliyor; takvim havaya bağlı.

**Seçilen yol: iskeleti önce yaz.** Fizik zinciri (kadir → foton akısı →
sönüm → optik → sensör → gürültü → SNR) kalibrasyon beklemeden kurulur;
gece geldiğinde tek bir ölçülmüş katsayıyla bağlanır.

**Bu yolun tek şartı — pazarlıksız:**

> İskelet hiçbir uydurma sabit içermez. Kalibrasyonu gelmemiş her
> büyüklük, varsayılan değer taşımak yerine **hesap yapmayı reddeder.**

Yani `KalibrasyonEksik` gibi açık bir durum döner; "şimdilik 0.9 koyalım,
sonra düzeltiriz" yapılmaz. Sebebi bu belgenin baştan beri söylediği şey:
zincirin bir halkası uydurmaysa çıktı da uydurmadır. Geçici bir sabit
konursa test yeşile döner, ekran sayı gösterir ve hangi sayının ölçülmüş
hangisinin uydurma olduğu bir hafta sonra ayırt edilemez hale gelir.

Uydurmanın maliyeti yanlış sonuç değil — **yanlış olduğunu bilememek.**

### Referans kararı — 22 Ağustos 2026: VIIRS yerine kendi karendeki yıldız

Bu bölüm baştan **VIIRS'i bağımsız referans** olarak öngörüyordu. Faz 5
iskeleti yazılırken sorun görüldü:

VIIRS bir uydu; **yerden yukarı çıkan** ışığı ölçüyor. Bize gereken ise
**yerden yukarı bakınca görünen** fon parlaklığı. Aradaki dönüşüm
(Falchi 2016 atlası) kendi başına **%20–30 saçılma** taşıyor. Yani
referansın belirsizliği, kriterin toleransından (%15) büyük — hassas
teraziyi banyo tartısıyla doğrulamaya çalışmak gibi. Doğru bir model
bile bu testi kaybedebilirdi.

**Yerine geçen yöntem: fotometrik sıfır noktası.** Aynı karedeki,
kadiri katalogdan bilinen bir yıldız ölçülür:

    ZP = V_gerçek − m_atmosfer_dışı        (Bouguer uydurmasının kesimi)
    μ_gökyüzü = −2.5·log10(fon / ω) + ZP

Kuantum verimi, lens aktarım verimi ve açıklık alanı **sadeleşiyor** —
ikisi de aynı optikten, aynı gecede, yerde ölçüldüğü için.

**Bunun üç sonucu var:**

1. `μ_sky` artık 0.C'yi (VIIRS) beklemiyor; **kullanıcının kendi
   karelerinden** çıkıyor.
2. `QE` ve `T` ayrı ayrı ölçülmüyor — **ölçülemezler** (üretici
   yayınlamaz, laboratuvar gerekir) ama zincirin ihtiyacı zaten
   çarpımları ve o çarpım ZP'nin içinde.
3. Kalibrasyon defteri **yediden altıya** indi ve altısının **beşi tek
   gecede** kapanıyor: k, ZP, FWHM, I_d, μ_sky.

**VIIRS elenmedi, yeri değişti:** artık zorunlu referans değil, isteğe
bağlı *çapraz kontrol*. Bir de tersi hâlâ değerli: `predictedZeroPoint()`
QE ve T varsayımından ZP'yi tahmin ediyor; ölçülen ZP ile
karşılaştırması **Faz 0.D'nin teşhis aracı** — ayrışma varsa suçlu
adayları QE, lens verimi, bant düzeltmesi veya kazanç ölçümü.

**Çıkış kriteri buna göre yeniden yazıldı:**

**Çıkış kriteri (iki parçalı, ikisi de gerekli):**
1. Aynı gecenin farklı karelerinden hesaplanan fon parlaklığı kendi
   içinde **%10 (0.1 kadir) tutarlı** — farklı ISO'lar, farklı pozlar
   ve farklı çerçeveler aynı sayıyı vermeli. Bu, referansın belirsizliğine
   bağlı olmayan bir testtir ve daha sıkıdır.
2. Hata ISO, poz süresi ve **hedef yüksekliği** boyunca tutarlı — sistematik bir eğilim göstermiyor

İkinci madde ilkinden zor ve daha değerli. Yükseklik boyunca tutarlılık, hava kütlesi modelinin doğruluğunu test eder — ve senin ana hedefin 24°'de durduğu için bu test gerçekten önemli. Sadece zenit yakınında kalibre edip düşük yüksekliğe güvenme.

**Neden Faz 0'a göre kriter sıkıldı:** Faz 0'da sensör kazancı hâlâ tahminiydi ve fon parlaklığı elle seçilmişti; 2 kat gevşeklik makuldü. Burada kazanç ölçülmüş (0.A) ve fon bağımsız veriyle biliniyor (0.C) — artık gevşemenin bahanesi yok.

**Tuzak 1 — Sensör verisi:** Uydurma değer girersen tüm proje yalan olur. Kendi gövden için Faz 0.A'da ölçtün. Başka gövdeler için `photonstophotos.net` gibi ölçüm kaynaklarını kullan. Bu veriyi uydurma.

**Tuzak 2 — Fotogerçekçilik:** Güzel görüntü peşine düşme. Bu fazın çıktısı bir *rapor*:
> Galaktik merkez: 23° yükseklik, hava kütlesi 2.5, sönüm 0.63 mag. SNR ≈ 4.2. Yıldız izi 2.1 px. Fon histogramın %38'ini dolduruyor. Parlak yıldızlarda kırpma yok.

Sahada işine yarayan şey bu rapor. Güzel görüntü Faz 6'da gelir.

**Tuzak 3 — Lens aktarım verimi:** f/2.8 bir lens f/2.8 kadar ışık geçirmez. T-stop f-stop'tan tipik %10–20 düşüktür (cam sayısına ve kaplamaya göre). %15 kriterinde bu tek başına seni düşürebilir. Sinema lenslerinde T-stop yayınlanır; fotoğraf lenslerinde genelde yayınlanmaz — 0.95 gibi bir varsayılan kullan ve **kaynağını yorum olarak yaz**.

---

## FAZ 6 — Samanyolu ve difüz gökyüzü (2–3 hafta)

| Task | İş |
|---|---|
| 6.1 | Tüm-gökyüzü panorama: **ESO veya NASA kaynaklı** (lisans bölümüne bak). CC BY-NC panoramalar ticari planla uyumsuz — cezbedici görünseler de alma |
| 6.2 | Galaktik ↔ ekvatoral koordinat dönüşümü |
| 6.3 | Küresel eşleme (equirectangular → gökyüzü küresi) |
| 6.4 | Parlaklık kalibrasyonu: piksel değeri → mag/arcsec² |
| 6.5 | Fon + Samanyolu + yıldızları birleştir |
| 6.6 | Hava parıltısı / ufuk gradyanı (şehir yönünde parlama) |

**Neden ayrı faz:** Yıldız nokta kaynak, Samanyolu difüz yüzey parlaklığı. Tamamen farklı iki render yolu. Baştan karıştırırsan mimarin bozulur.

**Risk — render performansı:** Difüz gökyüzünü piksel piksel Dart'ta hesaplayıp `CustomPainter` ile çizmek yavaş kalır; tam ekran her karede yüz binlerce piksel demek. Muhtemel çözüm Flutter'ın **fragment shader** desteği (GLSL) — koordinat dönüşümü ve parlaklık eşlemesi GPU'da yapılır. Bunu fazın ortasında keşfetmek yerine **6.3'ten önce bir gün prototip yap**: tek bir shader ile panoramayı ekrana bas, kare hızını ölç. Yeterliyse devam, değilse mimariyi ona göre kur.

---

## FAZ 7 — Konum ve ufuk (2–3 hafta) — FARKLILAŞTIRICI

| Task | İş |
|---|---|
| 7.1 | Konum arama (geocoding) + haritadan seçme |
| 7.2 | Işık kirliliği verisi otomatik: VIIRS / World Atlas → mag/arcsec² (Faz 0.C'de bu işin çekirdeğini zaten yazdın) |
| 7.3 | Yükseklik verisi: Copernicus GLO-30 (ücretsiz, 30m) |
| 7.4 | Konum çevresindeki ufuk profilini hesapla (360° tarama) |
| 7.5 | Ufku çerçeveye çiz — **görünür** yükseklik kullan (Faz 1.6'daki kırılma) |
| 7.6 | Uyarı: *"Merkez 01:40'ta doğuyor ama batı sırtı 18° — 03:10'a kadar göremezsin"* |

**Neden değerli:** Bu, rakiplerin düzgün yapmadığı tek şey. "Konumu buldum ama önümde tepe varmış" hikayesini bilen her astro fotoğrafçı bu özellik için para verir.

**Sıra hakkında düşün:** Bu faz "derinleşme" bloğunda ama senin ana hedefin (galaktik merkez, ~24° yükseklik) neredeyse her konumda bir tepe tarafından kesilir. Yani ufuk profili senin için lüks bir farklılaştırıcı değil, **ana senaryonun ön koşulu.** 7.2'yi (ışık kirliliği) zaten Faz 0'da kısmen yaptın. 7.3–7.6'yı Faz 6'nın önüne almayı düşün — Samanyolu görselinden önce "bu hedefi görebilir misin" sorusuna cevap vermek daha değerli.

**Karar gerekiyor — offline çelişkisi:** 9.4 "offline zorunluluk" diyor, ama DEM tile'ları indirmeden ufuk profili hesaplanmaz. Üç seçenek, birini seç ve buraya yaz:
1. Ufuk profilini konum başına bir kez hesapla, sonucu (360 float, ~1.5 KB) cihazda önbelleğe al — sahada internet gerekmez, sadece plan yaparken gerekir. **Önerim bu.**
2. DEM tile'larını indir ve sakla — offline tam çalışır ama depolama maliyeti yüksek
3. Hesabı sunucuda yap — en ucuz cihaz tarafı ama abonelik maliyetine sunucu ekler

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
| 9.4 | Offline mod (sahada internet yok — bu bir "nice to have" değil, zorunluluk). Faz 7'deki karara bağlı |
| 9.5 | Ücretsiz/abonelik sınırı: hangi özellik hangi tarafta? |
| 9.6 | iOS/Android build, izinler, ikon, ekran görüntüleri |
| 9.7 | App Store / Play yayını |

**9.5 hakkında:** Ücretsiz tarafın tek başına faydalı olması lazım, yoksa kimse abone olmaz. Kaba öneri — ücretsiz: gökyüzü haritası + FOV + NPF + zaman penceresi (Faz 1–4). Abonelik: radyometri raporu + ufuk profili + otomatik ışık kirliliği + hava durumu (Faz 5, 7, 9.3). Yani **tekrarlayan maliyeti olan her şey ücretli tarafta** — bu tesadüf değil, sürdürülebilirliğin şartı.

---

## MVP çizgisi nerede

```
Faz 0 → 1 → 2 → 3 → 4 → 5   ═══ MVP. Yayınlanabilir.
Faz 7 → 6 → 8                ═══ Derinleşme. (7'yi 6'nın önüne aldık — yukarıdaki nota bak)
Faz 9                        ═══ Cila + ürünleşme.
```

**Gerçekçi süre:** Fazların kendi tahminlerini toplarsan MVP ≈ 60–70 iş günü. Haftada 10–12 saat part-time çalışıyorsan bu **4–6 ay.** 2–3 ay demek kendini kandırmak olur ve üçüncü ayda "geri kaldım" hissiyle projeyi bırakma riski yaratır. Uzun süre, ilerlemeyi görebildiğin sürece sorun değil — o yüzden aşağıdaki 4. alışkanlık önemli.

Faz 3'ün sonunda elinde zaten kendi kullanabileceğin bir şey var. Faz 5'in sonunda başkasına gösterebileceğin bir şey.

---

## Baştan kurulacak alışkanlıklar

1. **Her `astro_core` fonksiyonu için test.** Bu bürokrasi değil — burada gözle "yanlış" göremezsin. 0.3° hata ekranda normal görünür ama sahada seni yanlış yere götürür. Test tek savunman.
2. **Sihirli sayı yasak.** Her sabitin yanına **birimi ve kaynağı** yorum olarak yazılacak. `// 0.25 mag/hava kütlesi, V bandı, deniz seviyesi — kaynak: [x]`. 6 hafta sonra `0.25` neyi ifade ediyordu diye düşünmek istemezsin.
3. **Birimi tip sistemine göm.** Çıplak `double focalLength` yerine anlamlı sarmalayıcılar. Bu belgede birim karışıklığı bir kez oldu bile — kodda olmasın.
4. **Git commit'leri faz/task numarasıyla.** `feat(coords): T1.4 RA/Dec → Alt/Az dönüşümü`
5. **Her fazın sonunda ekran görüntüsü al ve sakla.** Hem ilerlemeyi görürsün hem sonra portfolyo/mağaza görselleri için malzeme olur. 4–6 aylık bir projede bu motivasyon aracıdır, süs değil.
6. **Faz atlamak yok.** Özellikle Faz 0'ı atlama.
7. **Kalibrasyon verisini versiyonla.** Faz 0'daki ölçümlerin (kazanç, okuma gürültüsü, ham kareler, VIIRS değerleri) repoda dursun. Faz 5'te "bu sayı nereden geldi" sorusuna cevap veremezsen kalibrasyon tekrar yapılır.

---

## Bilinmeyenler (şimdi karar vermene gerek yok, ama aklında olsun)

- **Sensör veri kaynağı** — kaç gövde profili yeter? 4 mü, 200 mü? Kullanıcı geri bildirimi karar verir. Kullanıcının kendi gövdesini Faz 0.A yöntemiyle ölçmesini sağlayan bir sihirbaz, hem özellik hem farklılaştırıcı olabilir.
- **Abonelik fiyatı** — Faz 7'ye gelmeden kullanıcı başına aylık altyapı maliyetini hesapla (hava durumu API, DEM, geocoding). Fiyat bu sayının üstüne kurulur.
- **Derin gökyüzü nesneleri** — Messier Faz 2.4'te geliyor. NGC/IC genişlemesi ve difüz nesne görselleri Faz 6'nın uzantısı; görsel verisi için yine lisans kontrolü gerekir.
- **Fisheye / ultra geniş açı** — 180°'ye yaklaşan lensler için ayrı projeksiyon. Faz 9 sonrası.
- **Doğrulama topluluğu** — MVP sonrası birkaç astro fotoğrafçıdan kendi kareleriyle test istemek, kalibrasyonu N=1'den çıkarmanın en ucuz yolu.
