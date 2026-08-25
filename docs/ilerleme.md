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

### Arayüze bağlandı (22 Ağustos 2026)

Alt panelde üçüncü sekme: **Rapor**. Bugün iki satır hesaplıyor
(yükseklik + hava kütlesi, ölçek + iz + NPF) ve yedi eksiği
**kaynağıyla** listeliyor. İlerleme çubuğu `0 / 7 halka` diyor.

Tasarım kararı: eksik kısmı boş bırakmak ya da "0.0" göstermek yerine
neyin eksik olduğunu ve nereden geleceğini yazmak. Boş alan kullanıcıya
"araç bozuk" dedirtir; *"k ölçülmedi, 0.B Dizi B'den gelecek"* ise
durumu doğru anlatır ve ne yapması gerektiğini söyler.

**Reddetme arayüzde de çalışıyor:** ISO listesinde yalnızca ölçülmüş
üç değer var (800/1600/3200), ve ölçülmemiş bir gövde seçilirse panel
hiçbir sayı üretmiyor — hava kütlesi satırı bile çıkmıyor. Widget
testleri bunu doğruluyor.

### Defter yediden altıya indi (22 Ağustos 2026)

Çekim planı kuru provaya sokulunca (bkz. aşağıda) referans sorunu da
görüldü ve tasarım değişti: **QE ve T ayrı ayrı ölçülmüyor, yerlerine
tek bir fotometrik sıfır noktası (ZP) geçti.**

Gerekçe: ikisi de tek başlarına ölçülemez — üretici yayınlamaz,
laboratuvar gerekir. Ama zincirin ihtiyacı zaten çarpımlarıdır ve o
çarpım **tek bir ölçümle** elde edilir: kadiri bilinen bir yıldızın kaç
ADU verdiği. Üçünü ayrı ayrı kestirmek üç ayrı uydurma demek olurdu.

Aynı ZP gökyüzü fonuna da uygulanınca `μ_sky` mutlak ölçeğe oturuyor —
**VIIRS'e gerek kalmadan.** VIIRS elenmedi, yeri değişti: zorunlu
referans değil, isteğe bağlı çapraz kontrol.

**Doğrulama:** ZP yolu, daha önce elle hesaplanmış uçtan uca değerleri
(yıldız 24.2 e⁻/s, fon 0.851 e⁻/px/s) **birebir** yeniden üretti. İki
bağımsız yol aynı sayıya varıyor.

Testte ZP elle yazılmadı, `predictedZeroPoint()` ile QE ve T'den
türetildi — böylece o fonksiyon da sınanmış oluyor. Gerçekte yön
terstir: ZP ölçülür, QE ve T'nin doğruluğu ondan anlaşılır. Faz 0.D'nin
işi tam olarak bu karşılaştırma.

### Korumanın gerçekten çalıştığı doğrulandı

`extinction.dart`'a "geçici, sonra ölçümle değiştiririz" tarzı klasik
bir varsayılan sızdırıldı:

- `dart analyze` → **temiz geçti.** Derleyici bunu yakalamıyor.
- `dart test` → **3 test düştü.**

Aradaki fark önemli: bu kuralı ancak testler koruyabilir. Kod
incelemesinde gözden kaçabilecek tek satırlık bir kısayol, test
katmanında sesli bir hataya dönüşüyor.

---

## Yıldız tanıma ✅ (22 Ağustos 2026)

`tools/identify_stars.py` — karedeki yıldızları BSC5 ile eşleştirir.

**Neden gerekliydi:** Fotometri bir yıldızın kaç ADU verdiğini söyler,
ama sıfır noktası için **gerçek kadiri** lazım. *"Kullanıcı Vega'yı
ortaladı"* varsayımı Vega doyduğunda çöküyordu.

**Yaklaşım — sıfırdan plate solve değil.** Araç zaten nereye
bakıldığını (hedef), ne zaman (EXIF), nereden (konum) ve hangi ölçekte
(odak + piksel adımı) biliyor. Bilinmeyen tek şey **dönme açısı** ve
merkezin birkaç derecelik kayması. Kaba tarama + en küçük kareler
iyileştirmesi yetiyor.

**Yol boyunca yakalanan birim tuzağı:** `starphot` tek CFA kanalında
çalışıyor (`cfa[oy::2, ox::2]`), o düzlemde pikseller sensörün **iki
katı** aralıklı. 14 mm'de sensör ölçeği 54.8″/px ama G1 düzleminde
109.6″/px. Bu çarpanı unutmak ölçeği iki kat yanlış yapar ve **hiçbir
yıldız eşleşmez** — sessiz bir hata değil, gürültülü bir başarısızlık,
o yüzden şanslıyız.

**Doğrulama:** Gerçek BSC5 yıldızlarıyla üretilmiş 14 sentetik senaryo.
Yıldız konumları uydurma değil, katalogdan geliyor — yani test sadece
matematiği değil katalog bağlantısını da sınıyor.

| Senaryo grubu | Sonuç |
|---|---|
| 5 farklı dönme açısı + aynalanmış kare | ✅ |
| Orion (yoğun), Pegasus (seyrek), kutup, güney | ✅ |
| Doymuş yıldız, eksik yıldız, sahte tepe, bozuk odak | ✅ |

**14 senaryoda sıfır yanlış eşleştirme**, dönme açısı 0.01–0.02°
hassasiyetle, konum RMS 0.15–0.76 piksel.

Sönüm aracına bağlandı: hedef doysa bile ölçülen yıldız tanınıyor ve
ZP kurtuluyor.

## Kademe 2 arayüzü ✅ (22 Ağustos 2026)

Ürün kararındaki "tek kare ile kalibrasyon" yolunun uygulama tarafı.

**Köprü nereden kuruldu ve neden:** Flutter RAW dosyası çözemiyor —
CR2 için LibRaw gerekiyor, o da mobil/web'de ayrı bir uğraş. O yüzden
iş bölümü net: Python araçları ölçümü yapar ve `kalibrasyon.json`
üretir, uygulama onu okur.

Yükleme yolu **yapıştırma** seçildi; dosya seçici bir bağımlılık ve
web'de ayrı bir yol demek olurdu. Yapıştırma masaüstü, web ve telefonda
aynı şekilde çalışıyor.

**Kaynaksız ölçüm reddediliyor.** Dosyada `source` alanı yoksa okuma
hata veriyor ve gerekçesini yazıyor. Bu, "her sabitin yanında birimi ve
kaynağı" kuralının dosya biçimine geçmiş hali — kural artık sadece kod
içinde değil, veri sınırında da uygulanıyor.

Ayrıca **tanınmayan alanlar sessizce yutulmuyor**, uyarı olarak
gösteriliyor: ileri sürümden gelen bir dosya olduğunu anlamanın tek
yolu bu.

`k`'nın mutlak belirsizliği (kadir/X) okunurken bağıl belirsizliğe
çevriliyor; `Measured` bağıl bekliyor ve iki biçimi karıştırmak
belirsizliği sessizce yanlış ölçekler.

## Faz 7 — Ufuk profili ✅ çekirdek + arayüz (24 Ağustos 2026)

Yol haritası bunu "farklılaştırıcı" diye işaretlemişti ama kendi notunda
daha doğrusunu söylüyordu: projenin ana hedefi (galaktik merkez ~24°)
neredeyse her konumda bir sırt tarafından kesildiği için ufuk bir lüks
değil **ön koşul**.

**Sıra kararı: elle girilen ufuk, DEM'den önce.** Uydu yükseklik verisi
internet ve önbellek tasarımı istiyor; üstelik ağaçları, binaları ve
duvarı **göremez**. Gözle ölçülen profil çoğu zaman daha doğru.
`Horizon.fromSamples` DEM'i sonradan aynı tipe dolduracak.

**Ölçülen değer** — Mersin'den galaktik merkez, 15 Temmuz:

| Ufuk | Pencere | Kayıp |
|---|---|---|
| Düz | 165 dk | — |
| Güneyde 18° bina | 165 dk | 0 dk |
| Güneyde 23° tepe | 106 dk | **59 dk** |

18°'lik engelin etkisiz olması önemli bir ayrımı gösteriyor: **eşik ve
ufuk birbirinin yerine geçmiyor.** Biri fizik (sönüm), öteki coğrafya
(engel); etkin eşik ikisinin büyüğü.

### Çizimde bir tuzak

Arazi siluetinin altını karartırken "ufkun altı" ekranda aşağı **değil**
— kadraj döndürülebiliyor. Dolgu ekran dibine kadar çizilseydi roll
uygulandığında yanlış yer kararırdı. Bunun yerine her azimutta profil
yüksekliğinden −25°'ye inen şeritler, **gökyüzü koordinatlarında**
kuruluyor.

### Test yazarken düştüğüm tuzak

Sırtı yalnızca 180°'de tepe yapacak şekilde tanımlamıştım;
interpolasyon onu hızla düşürünce hedef kenardan sıyrılıyordu. Gerçek
bir dağ sırtı geniş bir azimut aralığını kaplar ve hedef pencere boyunca
168°–205° arasında geziyor.

`docs/ufuk-olcumu.md`: telefonun eğim ölçeriyle 15 dakikada ölçme
talimatı.

## Durum kaydı ✅ (25 Ağustos 2026)

Ufuk profili, kalibrasyon defteri, kamera ayarları, konum ve görünüm
anahtarları artık kalıcı. Gerekçe basit: ufuk ölçümü sahada 15 dakika,
kalibrasyon defteri bir gecelik çekimin ürünü.

**Kalibrasyon HAM METİN olarak saklanıyor**, çözümlenmiş nesne olarak
değil. Böylece her açılışta aynı doğrulamadan geçiyor — kaynaksız bir
defter diske yazılmış olsa bile okunurken reddediliyor. Kural veri
sınırında uygulanıyor; diske yazılmış olmak geçerlilik kazandırmıyor.

**Zaman kaydedilmiyor.** Uygulama açılınca geçerli ana dönüyor; bir
hafta önceki gökyüzünü göstermek yanıltıcı olurdu. Test bunu
sabitledi: kaydedilen JSON'da zamana benzeyen hiçbir alan olmamalı.

### Testin bulduğu dayanıklılık hatası

`{"iso":"cok"}` gibi yanlış tipteki tek bir alan, `as num?` dönüşümünde
istisna atıyor ve **bütün kaydı çöpe atıyordu** — tek bozuk alan
yüzünden ufuk profili de kaybolurdu. Amaç "bozuk alan varsayılana
düşer" idi, "bozuk alan her şeyi siler" değil. Tip dönüşümleri güvenli
hale getirildi.

Ayrıca listeden kaldırılmış bir gövde veya konum adı da varsayılana
düşüyor: liste değişebilir ve eski kayıt onu işaret edebilir.

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
