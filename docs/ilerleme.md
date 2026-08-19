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

## Sıradaki

| Faz | Durum | Engel |
|---|---|---|
| 0.A.6 | Doğrusallık merdiveni yeniden çekimi | Kararlı ışık kaynağı, ~20 dk, iç mekân |
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
