# İlerleme kaydı

Her fazın **ne zaman, hangi kanıtla** kapandığı. Amaç: "bitti" demenin
neye dayandığını sonradan da gösterebilmek. Bir faz burada kayıtlı
değilse kapanmamıştır.

---

## Faz 0.A — Sensör karakterizasyonu ✅

**Kanıt:** Canon EOS 760D için foton transfer eğrisiyle ölçülmüş kazanç ve
okuma gürültüsü, üç ISO'da.

| ISO | Kazanç (e⁻/ADU) | Okuma gürültüsü | Doyum (e⁻) |
|---|---|---|---|
| 800 | 0.2473 | 2.57 e⁻ | 3.292 |
| 1600 | 0.1265 | 2.04 e⁻ | 1.683 |
| 3200 | 0.0655 | 1.69 e⁻ | 871 |

Üç ISO'nun taban ISO'ya götürülmüş dolum kapasitesi **%5.7 içinde**
uyuşuyor — birbirinden bağımsız üç ölçümün aynı fiziksel büyüklüğe
yakınsaması.

**Açık kalan:** photonstophotos referansına göre kazanç sistematik olarak
~%17 yüksek. Sitenin üç değeri, dolum kapasitesini %0.10 sabit tutuyor —
yani tek bir çapadan türetilmiş, etkin olarak tek karşılaştırma noktası.
Ayrıntı ve karar gerekçesi: `data/faz0/referans-karsilastirma.md`.

**Araç doğrulaması:** `tools/test_ptc_math.py` bilinen kazancı %0.14 ile
geri buluyor — yani analiz kodu değil, verinin kendisi tartışılıyor.

### 0.A.6 — Doğrusallık ✅ (22 Ağustos 2026)

Üç deneme sonunda kapandı. **Doğrusalsızlık saptanmadı** (β = +2.85% ±
2.46%, yani 1.2σ). Kayma düzeltildikten sonra RMS sapma **%1.96**,
maks %3.60. Kalan sapmada doluluk seviyesiyle **eğilim yok** — bu
gürültü, sensörün eğrisi değil.

**Yol boyunca bulunan araç hatası:** `sensor_ptc.py` EXIF'teki
`ExposureTime` alanını kullanıyordu — o alan makinenin *gösterdiği*
yuvarlanmış değer. Gerçek süre `ShutterSpeedValue`'da: "0.4 s" aslında
0.3856 s (−%3.6), "2.5 s" aslında 2.5937 s (+%3.75). Test tam da bu
büyüklükteki sapmaları aradığı için yuvarlanmış değer testi anlamsız
kılıyordu. Düzeltince artık RMS %3.02 → %1.88 ve düşük dolulukta görülen
sistematik eğilim kayboldu. Kazanç etkilenmedi.

**Palindrom protokolü:** merdiven çık-in sırada çekilince poz süresi dizi
ortasına göre simetrik olur, böylece ışık kayması (tek fonksiyon)
doğrusalsızlıktan (çift fonksiyon) ayrılabilir. Ölçülen korelasyon
−0.012. Araç bu düzeltmeyi artık kendisi yapıyor —
**tek tek kareler üzerinden**, çift ortalaması üzerinden değil: palindromda
kayma bilgisi çiftin *içindeki* farkta durur, ortalama alınırsa yok olur.
İlk denemem bu yüzden çalışmadı.

`tools/test_drift_correction.py` sentetik veriyle doğruluyor, özellikle
iki şeyi: gerçek doğrusalsızlığın **silinmediğini**, ve tek yönlü
merdivende düzeltmenin **atlandığını** (orada ışık kayması %3.83'lük
sahte bir doğrusalsızlık üretiyor).

**Beklenmedik ikramiye:** bu ölçüm kazancı 0.1254 e⁻/ADU verdi; kayıtlı
değer 0.1265. Farklı gün, farklı ışık kaynağı, farklı sıcaklık —
**%0.9 uyum.** Kazancın tekrarlanabilirliği bağımsız doğrulandı; bu,
doğrusallık sonucundan daha değerli çıktı.

**Neden %1 değil %2–3 ile kapatıldı:** kalan gürültü ışık kaynağının kısa
süreli oynaklığı — ard arda 9 sn arayla çekilen iki 3.2 s karesi arasında
bile %0.6 açıklanamayan fark var. %1'in altına inmek entegre küre ister.
Faz 5'in çıkış kriteri %15; %2–3 bu bütçeye rahat sığıyor. Kesin
doğrulama **Faz 0.B Dizi A'ya** devredildi: gökyüzü merdiveni zaten bir
doğrusallık testi ve astronomik karanlıkta gökyüzü çok daha kararlı bir
kaynak.

---

## Faz 1 — Zaman ve koordinat ✅

**Kanıt:** 5 yıldız × 3 konum × 3 zaman = **45 noktalık doğrulama
matrisi**, astropy (ERFA/SOFA) ile bağımsız karşılaştırma.

- Tolerans: 0.1°
- En kötü sapma: **26.9 yay saniyesi (0.0075°)** — payın %7.5'i

**Matrisin ritüel olmadığının kanıtı:** Ayrı bir test, presesyon
kaldırıldığında noktaların yarısından fazlasının **düşmesi gerektiğini**
doğruluyor. Geçen ama hiçbir şeyi yakalayamayan test, test değildir.

**Yol boyunca yakalanan kendi hatalarım:** `horizontalToEquatorial`'da iki
işaret hatası (ters çevirerek yazmak yerine üç bağıntıyı çözmek
gerekiyormuş), `normalizeDegrees`'in [0,360) sözleşmesini ULP sınırında
ihlal etmesi, ve iki kez çerçeve uyuşmazlığı (GCRS ↔ TETE). Sonuncusunun
imzası öğreticiydi: **sabit sapma her zaman çerçeve uyuşmazlığına işaret
eder** — Güneş'te her epokta tam 0.375°, yani 26 yıllık presesyon.

---

## Faz 2 — Gökyüzü haritası ✅

**Kanıt:** Kullanıcı ekranda Orion'u tanıdı.

8404 yıldız (BSC5), 110 Messier nesnesi, 8 takım yıldızı figürü.

**Ders:** Çıkış kriteri "ekranda Orion tanınıyor" idi, ama takım yıldızı
çizgileri yol haritasında *opsiyonel* işaretliydi. Çizgiler olmadan
kullanıcı nokta bulutuna bakıp "ben bir şey anlamadım" dedi — haklıydı.
Kriteri doğrulanabilir kılan şey opsiyonel olamaz.

---

## Faz 3 — Kamera ve kadraj ✅

**Kanıt:** Kullanıcı 14 mm tam karede Orion'un çerçeveye sığdığını gördü.

FOV, NPF kuralı (deklinasyon düzeltmeli), iz uzunluğu, kırpma çarpanı.
500 kuralı karşılaştırma olarak gösteriliyor — 14 mm f/2.8'de NPF 15.0 s
derken 500 kuralı 36 s diyor.

---

## Faz 4 — Zaman ve gökyüzü olayları ✅

**Kapanış tarihi:** 18 Ağustos 2026
**Kanıt:** `docs/test-plani.md` — 20 maddelik el ile doğrulama listesi,
kullanıcı tarafından baştan sona geçildi.

Araç artık şu cümleyi kuruyor:

> Pencere 21:38 – 00:19 (161 dk), zirve 24°
> Ay %3 dolu, 20:55'te batıyor — 0.0 kadir, sorun değil

Ay'ın fon parlaklığına katkısı Krisciunas & Schaefer (1991) modeliyle.

### El ile test iki gerçek hata buldu

Otomatik testlerin (o an 308 tanesi) hiçbirinin göremediği iki hata:

**1. Messier hedefi seçilince uygulama çöküyordu.**
Üreteç Dart çıktısına `'M\$number'` yazıyordu — Python'da `$` özel
karakter olmadığı için kaçış gereksizdi, Dart kaçırılmış doları görüp
yerine koymayı yapmıyordu. 110 nesnenin adı aynı literal metin oldu,
açılır listenin "seçili değerle tam olarak bir öğe eşleşmeli" önermesi
patladı.

*Neden testler görmedi:* hiçbiri `designation`'a bakmıyordu. Hesap
tarafı doğruydu — `planNight` 110 hedefin hepsi için doğru sonuç
üretiyor. Hata hesapla arayüz arasındaki **isim bağındaydı** ve yalnızca
widget ağacı çizilirken ortaya çıkıyordu.

**2. Ay cezasında gösterilen sayı ile renk çelişebiliyordu.**
Ceza ekranda bir ondalığa yuvarlanarak yazılıyor, renk ise ham değere
bakıyordu. Yuvarlama eşiğin öbür tarafına geçebiliyor: 24 Mayıs 2026'da
gerçek değer 1.4643, ekranda "1.5 kadir", nokta turuncu — oysa kural
"1.5 ve üstü kırmızı". Yıl boyunca 5 gün.

Kullanıcı bunu bir doküman hatası sanarak sordu ("21 Temmuz'da 1.4
yazıyor, sen 1.5 demiştin"); o tarihte uygulama haklıydı (gerçek değer
1.4499) ama soru gerçek hatayı ortaya çıkardı.

**Alınan ders:** Otomatik testler hesabın doğruluğunu kanıtlıyor, hesabın
**doğru bağlandığını** kanıtlamıyor. İki hata da o bağlantı katmanındaydı.
Her ikisi için de regresyon testi yazıldı ve **hata geri konarak
doğrulandı** — düzeltme olmadan düşüyorlar.

---

## Faz 5 — Radyometri iskeleti 🔨 (20 Ağustos 2026'da başladı)

Zincirin altı halkası kuruldu. **İkisi hesaplanıyor, dördü ölçüm
bekliyor** — ve bekleyenler varsayılan taşımak yerine hesap yapmayı
reddediyor.

| Halka | Durum | Kaynak |
|---|---|---|
| Kadir → foton akışı | ✅ hesaplanıyor | Bessell (1979) V bandı sıfır noktası |
| Hava kütlesi | ✅ hesaplanıyor | Kasten & Young (1989) |
| Açıklık geometrisi | ✅ hesaplanıyor | D = f/N |
| Gürültü toplamı | ✅ formül hazır | shot + okuma² + karanlık |
| Sönüm katsayısı **k** | ⏸ ölçüm bekliyor | 0.B Dizi B |
| Aktarım verimi **T** | ⏸ | 0.D |
| Kuantum verimi **QE** | ⏸ | 0.D |
| Bant düzeltmesi **dV_G** | ⏸ | 0.B Dizi A/B |
| Karanlık akım **I_d** | ⏸ | 0.B Dizi C |
| Fon parlaklığı **μ_sky** | ⏸ | 0.C VIIRS |

Ölçülmüş olan tek şey sensör: kazanç, okuma gürültüsü ve dolum
kapasitesi Faz 0.A'dan geliyor, **±%17 belirsizliğiyle birlikte
taşınıyor.**

### Reddetme mekanizması

`Radiometric` sealed bir tip: ya sayı taşır ya da eksik büyüklüklerin
listesini. Üçüncü ihtimal yok. Eksikler zincir boyunca **birikerek**
gidiyor — bugün tam zincir çağrıldığında dördünü birden söylüyor,
ilkinde durup diğerlerini gizlemiyor.

Her eksik büyüklüğün yanında **neden uydurulamayacağı** yazılı. Örnek
(sönüm katsayısı): *yere ve geceye göre 0.15 ile 0.60 arasında değişir;
kitabi 0.25'i Mersin sahilinde kullanmak X=2.4'te 0.84 kadir hata verir
— akışta 2.2 kat. Asıl hedef 24°'de, yani tam da bu hatanın en büyüdüğü
yerde.*

### İskeletin tamamı (20 Ağustos 2026)

Zincirin geri kalanı da yazıldı: gökyüzü fonu (5.6), PSF ve ayak izi
(5.11), nokta kaynak / difüz SNR (5.10), histogram ve kırpma (5.12),
ve hepsini birleştiren `ExposureReport`.

Rapor bugün şunu üretiyor:

```
Galaktik merkez: 24 derece yukseklik, hava kutlesi 2.45
Olcek 54.8"/px, yildiz izi 3.6 px (NPF siniri 17.1 s)
--- eksik ---
k olculmedi      — Faz 0.B Dizi B
mu_sky olculmedi — Faz 0.C VIIRS
... (7 madde, her biri kaynağıyla)
```

Kalibrasyon dolduğunda aynı çağrı şuna dönüşüyor:

```
Sonum 0.61 kadir
SNR 16.3
Fon histogramin %13'ini dolduruyor
Parlak yildizlarda kirpma yok
```

**Doğrulama:** Zincirin çıktısı ayrıca elle hesaplandı ve kod birebir
aynı sonucu verdi — yıldız 24.2 e⁻/s, fon 0.851 e⁻/px/s, iz 3.60 px,
SNR 16.3, histogram %13. Bu değerler teste sabitlendi; zincirde sessiz
bir kayma olursa oradan yakalanır.

### İskeletin ortaya çıkardığı iki gerçek

**1. Sönüm gökyüzü fonuna uygulanmaz.** Yıldız ışığı atmosferden geçerek
gelir ve söner; gökyüzü fonu atmosferin ve şehrin *kendi* ürettiği
ışıktır, zaten yerde ölçülür. İkisine aynı düzeltmeyi uygulamak sık
yapılan ve sessizce yanıltan bir hata.

**2. Geniş açıda PSF'yi atmosfer belirlemiyor.** 14 mm ve 3.72 µm piksel
için ölçek 54.8″/px; tipik 2″ seeing bunun yanında görünmez. Sistem
aşırı az örneklenmiş — bu bir kusur değil, rejimin özelliği. Araç bunu
kusur gibi raporlamamalı.

Ayrıca poz süresinin SNR'ı her zaman iyileştirmediği nokta zincire
bağlandı: uzun poz daha çok foton toplar ama izi de uzatır, yani sinyali
daha çok piksele yayar ve her piksel kendi fon gürültüsünü getirir.
Faz 3'ün iz hesabı buraya doğrudan giriyor.

### Korumanın gerçekten çalıştığı doğrulandı

`extinction.dart`'a "geçici, sonra ölçümle değiştiririz" tarzı klasik
bir varsayılan sızdırıldı:

- `dart analyze` → **temiz geçti.** Derleyici bunu yakalamıyor.
- `dart test` → **3 test düştü.**

Aradaki fark önemli: bu kuralı ancak testler koruyabilir. Kod
incelemesinde gözden kaçabilecek tek satırlık bir kısayol, test
katmanında sesli bir hataya dönüşüyor.

---

## Sıradaki

| Faz | Durum | Engel |
|---|---|---|
| 0.B | Kontrollü gökyüzü çekimi | Açık ve ay'sız gece |
| 0.C | VIIRS fon parlaklığı sorgusu | 0.B'nin konumu belli olunca |
| 0.D | Hesap–gerçek karşılaştırması | 0.B + 0.C |
| 5 | Radyometri — iskelet | Yok; **iskelet yazımı başlayabilir** |
| 5 | Radyometri — kalibrasyon | 0.B, 0.C, 0.D |

Faz 5'in iskelet-önce yazılma kararı ve tek şartı (uydurma sabit yasağı):
`yol-haritasi.md` → FAZ 5 → "Uygulama sırası kararı".

---

## Ticari dağıtımdan önce kapatılacak

- **BSC5 lisansı.** Kataloğun açık lisans metni yok. HYG'nin CC BY-SA
  share-alike yükü gibi bir *kısıt* değil, ama açık bir *izin* de değil.
  Faz 9'a taşınan açık madde.
