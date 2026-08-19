# Astro Poz Simülatörü — Master UI/UX & Product Design Prompt

## Rolün

Sen kıdemli bir **Product Designer, UX Architect, Mobile App Designer ve Flutter UI Specialist** olarak çalışıyorsun.

Görevin, **“Astro Poz Simülatörü”** adlı profesyonel bir astro fotoğrafçılık planlama ve simülasyon uygulaması için eksiksiz bir tasarım sistemi ve uygulama arayüzü oluşturmaktır.

Bu sadece güzel görünen bir uzay uygulaması olmamalıdır.

Uygulamanın temel amacı:

> Kullanıcının bir konum, tarih, saat, kamera, lens ve çekim ayarı belirleyerek, o anda o gökyüzünden fiziksel olarak ne elde edebileceğini önceden anlamasını sağlamak.

Ürün bir yıldız haritası değildir.

Gökyüzü haritası yalnızca bir araçtır.

Asıl ürün değeri:

- Çekim planlama
- Kadraj simülasyonu
- Gökyüzü görünürlüğü
- Astronomik karanlık
- Ay etkisi
- Işık kirliliği
- Hedef nesnenin yüksekliği
- Önerilen maksimum poz süresi
- Yıldız izi riski
- Gökyüzü fon parlaklığı
- SNR
- Histogram ve clipping riski
- Çekimin fiziksel olarak ne kadar başarılı olabileceğinin kestirimi

olmalıdır.

---

# 0. REVİZYON NOTU (v2)

Bu doküman v1'e göre iki yönde derinleştirilmiştir: **niteliksel tarifler token seviyesine indirilmiş**, **eksik akışlar eklenmiştir**.

Değişen kararlar (v1 geçersiz):

| Konu | v1 | v2 |
|---|---|---|
| Navigasyon | 5 sekme (Sky/Plan/Camera/Report/Library) | 3 sekme (Sky/Targets/Library) + global context bar — §7 |
| Parametreler | Ayrı ekranlar | Uygulama-genel context + bottom sheet — §7.1 |
| Ana akış | 13 adımlık doğrusal form | 1 varsayılan + 3 karar + döngü — §36 |
| Font | iOS SF Pro / Android Inter | Tüm platformlarda Inter — §5.1 |
| Renk | İsimle tanımlı ("soft white") | Hex token + kontrast oranı — §4 |
| Capture skoru | ★★★★☆ | Kelime + şekil ikonu verdict — §16.1 |
| İki parmak rotasyonu | Birincil jest | Varsayılan kapalı, ayar arkasında — §9.2 |
| Report | Ayrı sekme | Sky sheet'in `full` durumu — §7.3 |

Eklenen bölümler: §5A (spacing/grid), §5B (elevation), §5C (motion), §41 (offline), §42 (hata matrisi), §43 (izinler), §44 (ayarlar), §45 (abonelik/paywall), §46 (bildirimler), §47 (hedef keşfi), §48 (ekipman yönetimi), §49 (paylaşım/export), §50 (hava durumu), §51 (widget), §52 (performans bütçesi), §53 (Flutter implementation notes), §54 (ilk kurulum/indirme).

---

# 1. GENEL TASARIM FELSEFESİ

Tasarım dili şu üç dünyanın birleşimi olmalıdır:

### %40 Apple-level Premium Minimalism

İlham alınabilecek prensipler:

- Apple
- Halide
- Linear
- Arc Browser
- Apple Weather

Özellikleri:

- Çok temiz
- Gereksiz çizgi ve kutulardan kaçınan
- Yüksek kaliteli tipografi
- Bol negatif alan
- Büyük ve okunabilir bilgiler
- Hassas spacing
- Premium his
- Az ama etkili animasyon
- Karmaşık bilgiyi sakin şekilde sunma

### %35 Scientific / Professional Interface

Uygulama oyuncak gibi görünmemeli.

Kullanıcı şunu hissetmeli:

> "Bu uygulama gerçekten hesap yapıyor."

Bilimsel hissi oluşturmak için:

- Gerçek sayısal değerler
- Ölçü birimleri
- Grafikler
- Küçük veri etiketleri
- Precision
- Durum göstergeleri
- Zaman çizelgeleri
- SNR değerleri
- Altitude grafikleri
- Exposure bilgileri

kullanılmalı.

Ancak arayüz:

❌ eski NASA kontrol paneli gibi karmaşık  
❌ hacker terminali gibi  
❌ aşırı teknik tablo çöplüğü gibi

olmamalı.

Bilimsel karmaşıklık **arka planda**, kullanıcı deneyimi ise **sade** olmalıdır.

### %25 Cinematic / Immersive Astronomy

Uygulama açıldığında kullanıcıda şu his oluşmalı:

> "Bu gece gerçekten gökyüzüne çıkmak istiyorum."

Gökyüzü:

- Derin
- Atmosferik
- Sinematik
- Sessiz
- Premium

hissettirmeli.

Ancak:

❌ Neon mavi uzay teması kullanma  
❌ Mor/pembe sci-fi efekti kullanma  
❌ Fazla parlak yıldız efektleri kullanma  
❌ Gaming UI görünümü oluşturma

Gerçek gece gökyüzüne yakın, sofistike ve karanlık bir atmosfer oluştur.

---

# 2. PLATFORM STRATEJİSİ

Tasarım şu platformlarda çalışmalıdır:

1. iOS
2. Android
3. Tablet
4. Web/Desktop

Ancak aynı ekranı her platformda büyütme.

Responsive tasarım sistemi oluştur.

## Mobile

Ana kullanım:

- Sahada
- Gece
- Tek elle kullanım
- Hızlı karar verme

Bu nedenle:

- Bottom navigation
- Bottom sheet
- Büyük touch target
- Hızlı preset seçimi
- Minimum yazı girişi

kullan.

## Tablet

Ana kullanım:

- Çekim planlama
- Grafik inceleme
- Simülasyon

İki kolonlu veya genişletilmiş layout kullanılabilir.

## Desktop/Web

Ana kullanım:

- Detaylı planlama
- Karşılaştırma
- Büyük gökyüzü görünümü
- Çoklu panel

Desktop layout:

```text
┌─────────────────────────────────────────────────────────────┐
│ Top Navigation                                              │
├──────────────┬──────────────────────────────┬───────────────┤
│ Controls     │                              │ Live Data     │
│              │       SKY SIMULATION         │               │
│ Location     │                              │ Target        │
│ Date/Time    │                              │ Altitude      │
│ Camera       │                              │ SNR           │
│ Exposure     │                              │ Moon          │
│              │                              │               │
├──────────────┴──────────────────────────────┴───────────────┤
│ Timeline / Best Shooting Window                             │
└─────────────────────────────────────────────────────────────┘
```

Soldaki "Controls" kolonu, mobildeki context bar sheet'lerinin (§7.2) kalıcı panel karşılığıdır — ayrı bir bilgi mimarisi değildir. Breakpoint'ler için bkz. §33.1.

---

# 3. BRAND / VISUAL IDENTITY

Uygulama adı:

# Astro Poz Simülatörü

Şimdilik bu isim kullanılmalı ancak marka yapısı daha sonra kolayca değiştirilebilmelidir.

Logo aşırı literal olmamalı.

❌ Kamera + yıldız clipart  
❌ Teleskop ikonu  
❌ Galaxy emoji tarzı

Yerine:

- Minimal celestial geometry
- Lens aperture
- Celestial coordinate
- Exposure framing

kavramlarını soyut şekilde birleştiren premium bir marka işareti düşün.

---

# 4. RENK SİSTEMİ

Varsayılan tema:

# True Dark / Night Mode

Ana arka plan saf siyah değildir. Saf siyah, gökyüzü render alanı ile UI arasındaki sınırı yok eder ve OLED'de smear yapar. Bunun yerine çok koyu mavi-siyah kullanılır.

Bu bölümdeki değerler **normatiftir**. "Soft white", "cool gray" gibi niteliksel tanımlar artık geçerli değildir — implementasyonda aşağıdaki token isimleri kullanılır.

## 4.1 Zemin ve yüzey token'ları

| Token | Hex | Kullanım |
|---|---|---|
| `bg/primary` | `#0A0E14` | Uygulama zemini, sky canvas arkası |
| `bg/secondary` | `#10151D` | Scroll bölge zemini, liste arkaplanı |
| `surface` | `#161C26` | Kartlar, metric card, target card |
| `surface/elevated` | `#1D2530` | Bottom sheet, modal, popover |
| `surface/overlay` | `#0A0E14` @ 72% | Sky üzerine binen floating layer |
| `border/subtle` | `#2A3441` @ 40% | Ayırıcı çizgi, kart kenarı (opsiyonel) |
| `border/strong` | `#3A4655` | Focus ring, seçili segment |

## 4.2 Metin token'ları

| Token | Hex | Kontrast (bg/primary) | Kullanım |
|---|---|---|---|
| `text/primary` | `#F2F5F8` | 15.8:1 | Display, headline, birincil değerler |
| `text/secondary` | `#9AAABB` | 7.1:1 | Body, açıklama |
| `text/tertiary` | `#6B7D91` | 3.9:1 | Sadece ≥16sp veya data label — body'de kullanma |
| `text/disabled` | `#4A5666` | 2.3:1 | Sadece devre dışı kontrol, metin taşımaz |

Kural: `text/tertiary` hiçbir zaman 13sp altında kullanılmaz. Body metni her zaman `text/secondary` veya üstüdür (WCAG AA 4.5:1).

## 4.3 Accent token'ları

Accent renkleri **yalnızca bilgi anlamı** taşır. Dekoratif accent kullanımı yasaktır.

| Token | Hex | Anlam |
|---|---|---|
| `accent/blue` | `#5CC8FF` | Navigasyon, koordinat, nötr bilimsel veri, seçili durum |
| `accent/gold` | `#E8B657` | Ay, poz uyarısı, önerilen değer |
| `status/excellent` | `#4ADE80` | Mükemmel koşul |
| `status/good` | `#A3D977` | İyi koşul |
| `status/moderate` | `#E8B657` | Orta / dikkat |
| `status/poor` | `#F5A65B` | Zayıf / bozulmuş |
| `status/critical` | `#F0555B` | Kritik / mümkün değil |

Her status rengi **ayrıca bir şekil ikonuyla** eşleşir (bkz. §32.5). Renk hiçbir durumda tek başına anlam taşımaz.

## 4.4 Night Vision eşlemesi

Night Vision modunda (§31) tüm palet tek kanala indirgenir. Bu modda status renkleri ayırt edilemez hale geleceği için **anlam ikonlarla ve parlaklık kademeleriyle** taşınır:

| Normal token | Night Vision karşılığı |
|---|---|
| `bg/primary` | `#000000` |
| `surface` | `#140404` |
| `text/primary` | `#FF6B6B` @ 90% |
| `text/secondary` | `#B84A4A` |
| `accent/blue` → | `#FF8A8A` (parlaklık L3) |
| `accent/gold` → | `#E05555` (parlaklık L2) |
| `status/*` → | Tek kırmızı ton; ayrım **yalnızca ikon + parlaklık kademesi** ile |

Night Vision modunda maksimum ekran parlaklığı %40'a sınırlanır ve beyaz nokta hiçbir yerde kullanılmaz.

## 4.5 Gradient kuralı

- Gökyüzü render alanında **doğal atmosferik gradient serbesttir** (ufuk parlaması, ışık kirliliği kubbesi).
- UI elemanlarında (kart, buton, sheet, nav) gradient **yasaktır**.
- Tek istisna: sky canvas ile alttaki sheet arasındaki okunabilirlik scrim'i — `bg/primary` 0% → 80% dikey.

---

# 5. TYPOGRAPHY

## 5.1 Font ailesi kararı

**Tüm platformlarda tek aile: Inter.** (bundle edilir, sistem fontuna bırakılmaz)

Gerekçe: SF Pro ve Inter'in x-height ve karakter genişlikleri farklıdır. İki aile kullanmak, aynı type scale'in iOS ve Android'de farklı optik ağırlıkta görünmesine ve "Display" satırlarının (`02:10 — 03:40`) platform başına farklı taşmasına yol açar. Tek kod tabanından tek görsel dil hedefi, tek aileyi zorunlu kılar.

Sayısal değerlerde **tabular figures** zorunludur (`FontFeature.tabularFigures()`). Bir zaman aralığı veya SNR değeri değişirken sayıların yatay olarak zıplaması, ürünün "hesap yapıyor" hissini bozar.

Ayrı bir monospace aile kullanılmaz — Inter'in tabular figures özelliği bu ihtiyacı karşılar.

## 5.2 Type scale

| Stil | Boyut/Satır | Ağırlık | Letter spacing | Kullanım |
|---|---|---|---|---|
| `display/lg` | 40 / 46 | 600 | −0.5 | Tek hero sonuç (`SNR 8.4`, `01:20 — 03:40`) |
| `display/md` | 34 / 40 | 600 | −0.4 | Ekran başına birincil sonuç |
| `display/sm` | 28 / 34 | 600 | −0.3 | Kart içi büyük değer (`23°`, `18s`) |
| `headline` | 22 / 28 | 600 | −0.2 | Bölüm başlığı |
| `subhead` | 17 / 22 | 500 | 0 | Kart başlığı, liste satır başlığı |
| `body` | 15 / 22 | 400 | 0 | Açıklama metni |
| `caption` | 13 / 18 | 400 | 0 | İkincil açıklama, birim |
| `data/label` | 11 / 14 | 500 | +0.6 | UPPERCASE etiket: `ISO`, `ALT`, `AZ`, `SNR`, `BORTLE`, `FOV` |
| `data/value` | 15 / 20 | 500 | 0 | Etiketin altındaki değer, tabular |

Değerler `sp`/logical pixel cinsindendir.

## 5.3 Kurallar

- Bir ekranda **en fazla bir** `display/lg` bulunur. Birden fazla hero sonuç, hiyerarşiyi yok eder.
- `data/label` her zaman uppercase ve her zaman `text/tertiary` rengindedir; değeri `text/primary`.
- Birim (`°`, `s`, `mag/arcsec²`) değerden bir kademe küçük ve `text/secondary` renginde yazılır: `23°` → `23` display/sm + `°` subhead.
- Dynamic Type / sistem font ölçeklendirmesi desteklenir; `display/*` stilleri **maksimum 1.3×** ölçeklenir (taşmayı önlemek için), gövde stilleri sınırsız ölçeklenir.

## 5.4 Örnek hiyerarşi

```text
data/label     BEST SHOOTING WINDOW
display/lg     01:20 — 03:40
subhead        Excellent window
caption        Astronomik karanlık + düşük ay etkisi
```

---

# 5A. SPACING, GRID VE DOKUNMA HEDEFLERİ

## Spacing skalası

Tek skala kullanılır. Ara değer üretilmez.

```text
4 · 8 · 12 · 16 · 24 · 32 · 48 · 64
```

| Bağlam | Değer |
|---|---|
| Ekran kenar boşluğu (mobil) | 16 |
| Ekran kenar boşluğu (tablet/desktop) | 24 |
| Kart iç padding | 16 |
| Kart içi bölüm arası | 12 |
| Kartlar arası | 12 |
| Bölüm (section) arası | 24 |
| Etiket ↔ değer | 4 |
| Liste satır yüksekliği (min) | 56 |

## Border radius

| Token | Değer | Kullanım |
|---|---|---|
| `radius/sm` | 8 | Chip, input, küçük buton |
| `radius/md` | 12 | Kart |
| `radius/lg` | 20 | Bottom sheet, modal (sadece üst köşeler) |
| `radius/pill` | tam yuvarlak | Segmented control, status pill |

§39'daki "overly rounded childish components" yasağı gereği 20'nin üzerinde radius kullanılmaz.

## Dokunma hedefleri

- Minimum dokunma alanı: **44 × 44** (iOS HIG / Material ortak alt sınır).
- Gece + eldiven kullanımı beklenen birincil kontroller (time scrubber tutamacı, poz stepper'ı, hedef seçimi): **minimum 56 × 56**.
- İki bitişik dokunma hedefi arasında en az 8 boşluk.

---

# 5B. ELEVATION VE YÜZEY SİSTEMİ

Karanlık temada gölge işe yaramaz. Yükseklik **surface-tint** ile ifade edilir: yüzey rengi, üzerine bindirilen beyaz overlay oranıyla açılır.

| Seviye | Overlay | Sonuç | Kullanım |
|---|---|---|---|
| L0 | — | `bg/primary` | Ekran zemini |
| L1 | +4% white | `bg/secondary` | Bölüm zemini |
| L2 | +8% white | `surface` | Kart |
| L3 | +12% white | `surface/elevated` | Bottom sheet, modal, popover |

Kurallar:

- Aynı ekranda **en fazla iki** elevation seviyesi bulunur. L0 → L2 → L3 zinciri kabul edilebilir; L0 → L1 → L2 → L3 iç içe yığılması yasaktır (§39 "too many floating cards").
- Kart kenarlığı (`border/subtle`) yalnızca elevation farkının yeterli olmadığı yerde kullanılır — varsayılan olarak kenarlıksız çalış.
- Sky canvas üzerinde duran floating layer'lar elevation değil `surface/overlay` + scrim kullanır; gökyüzü onların arkasından kısmen görünmelidir.

---

# 5C. MOTION SİSTEMİ

"Premium hissettiren yavaşlık" ile "işi bloke eden gecikme" arasındaki sınır sayısal olarak tanımlanır.

| Kategori | Süre | Easing | Örnek |
|---|---|---|---|
| `motion/micro` | 120–150ms | `Curves.easeOut` | Toggle, chip seçimi, segment değişimi |
| `motion/transition` | 250ms | `Curves.easeInOutCubic` | Sekme geçişi, sheet snap |
| `motion/hero` | 400ms | spring (mass 1, stiffness 180, damping 20) | FOV frame büyümesi, hedefe odaklanma |
| `motion/data` | 300ms | `Curves.easeOut` | Sayı tween'i (SNR, altitude) |
| `motion/chart` | 400ms | `Curves.easeInOutCubic` | Grafik çizgisi, histogram yeniden çizimi |
| `motion/scrub` | **0ms** | — | Time scrubber → gökyüzü. Animasyon yok, kare başına senkron güncelleme. |

Kurallar:

- Time scrub sırasında hiçbir şey animate edilmez ve debounce uygulanmaz. Kullanıcının parmağı ile gökyüzü arasında gecikme hissi olursa simülasyon inandırıcılığını kaybeder. Performans bütçesi için bkz. §52.
- Sayısal değerler **tween ile** değişir, anlık zıplamaz (`motion/data`).
- Yasak: bounce, elastic, overshoot, parçacık efekti, sürekli parlama/pulse animasyonu (§39).
- Sistem "reduce motion" ayarı açıkken tüm süreler 0'a iner; `motion/scrub` zaten 0 olduğu için etkilenmez.

---

# 6. TASARIM PRENSİBİ: INFORMATION FIRST

Uygulamada her bilgi aynı öneme sahip değildir.

Arayüz şu sırayla düşünülmelidir:

## Layer 1 — Kullanıcının bilmek istediği cevap

Örnek:

> "Bu gece çekebilir miyim?"

veya:

> "En iyi zaman ne zaman?"

## Layer 2 — Kararı destekleyen bilgiler

Örnek:

- Ay
- Hedef yüksekliği
- Karanlık
- Işık kirliliği

## Layer 3 — Teknik detay

Örnek:

- Air mass
- Extinction
- Read noise
- Sky background ADU

## Layer 4 — Advanced mode

Profesyonel kullanıcılar için.

Teknik bilgiyi asla ilk ekrana tamamen yığma.

Progressive disclosure kullan.

---

# 7. UYGULAMA BİLGİ MİMARİSİ

## 7.1 Temel karar: parametreler sekme değildir

Konum, tarih/saat ve ekipman **ekran değil, uygulama genelinde geçerli bağlamdır (context)**. Bunları ayrı sekmelere koymak, kullanıcıyı tek bir soruyu ("bu gece çekim yapabilir miyim?") cevaplamak için sekmeler arasında gidip gelmeye zorlar ve §6'daki information-first ilkesiyle çelişir.

Bu nedenle:

- **Parametreler → global context bar + bottom sheet**
- **Sonuçlar → sekmeler**

## 7.2 Global Context Bar

Her ekranın üstünde kalıcı olarak durur. Yüksekliği 44, `surface/overlay` üzerinde.

```text
┌──────────────────────────────────────────────┐
│ İstanbul · Bu gece 02:14 · A7III 14mm     ⌄ │
└──────────────────────────────────────────────┘
```

Üç bölüme ayrılmış, her bölüm ayrı dokunma hedefidir:

| Bölüm | Dokununca açılan |
|---|---|
| `İstanbul` | Konum sheet'i (§10) |
| `Bu gece 02:14` | Tarih/zaman sheet'i (§11) |
| `A7III 14mm` | Ekipman + poz sheet'i (§13, §15) |

Bar daralınca (dar ekran) ekipman bölümü ikona iner; tam metin `half` sheet'te görünür.

Kural: context bar hiçbir zaman gizlenmez — Milky Way immersive modu (§23) hariç, orada da tek dokunuşla geri gelir.

## 7.3 Ana navigasyon — 3 sekme

```text
Sky        Targets        Library
```

### 1. SKY — hub

Canlı gökyüzü simülasyonu **ve** o anki konfigürasyonun sonucu. Kullanıcının zamanının %80'ini geçirdiği ekran.

Sonuç katmanlaması bottom sheet'in snap-point'leri ile yapılır (§8.3):

- `peek` → tek satır özet (hedef · ALT · SNR · en iyi pencere)
- `half` → capture feasibility kartı (§16) + neden açıklaması
- `full` → radyometri raporu, histogram, SNR skalası, advanced veri (§17, §18, §19, §26)

**Report ayrı bir sekme değildir.** Rapor, gökyüzünün fiziksel devamıdır; ayrı sekmeye taşındığında kullanıcı "gördüğü gökyüzü" ile "okuduğu sayı" arasındaki bağı kaybeder.

### 2. TARGETS — keşif

Hedef nesneyi bulma ve seçme. Arama, filtre, "bu gece önerilenler", katalog gezinme (§47).

Hedef seçildiği anda otomatik olarak Sky sekmesine döner — Targets bir seçim ekranıdır, kalınacak yer değil.

### 3. LIBRARY — kayıtlı olan her şey

Kayıtlı planlar, ekipman presetleri (§25), ekipman yönetimi (§48), ayarlar (§44), hesap ve abonelik (§45).

## 7.4 Neden 3 sekme

| Eski sekme | Yeni yeri |
|---|---|
| Explore / Sky | **Sky** sekmesi |
| Plan (konum, tarih) | Context bar → sheet |
| Camera (ekipman, poz) | Context bar → sheet |
| Report | Sky sheet `full` state |
| — (hedef keşfi tanımsızdı) | **Targets** sekmesi |
| Library | **Library** sekmesi |

Sonuç: parametre değiştirmek artık hiçbir zaman ekran değiştirmek değildir. Kullanıcı gökyüzünü görürken lensi değiştirir ve FOV çerçevesinin anında değiştiğini görür — ürünün temel vaadi budur.

---

# 8. ANA EKRAN — SKY SIMULATION

Bu uygulamanın en önemli ekranlarından biridir.

Ekranın yaklaşık %60–70'i gökyüzü olmalıdır. Bu oran **sheet'in `peek` durumunda** ölçülür (§8.3) — kullanıcı sheet'i yukarı çektiğinde gökyüzü küçülebilir, ama uygulama her açıldığında bu orana geri döner.

Gökyüzü görünümü:

- Gerçekçi yıldız yoğunluğu
- Yıldız parlaklığı magnitude'a göre
- Hafif B−V renk farklılıkları
- Messier hedefleri
- Horizon
- Compass orientation
- Optional constellation lines

Üzerinde:

```text
NW
N
NE
```

gibi minimal yön göstergeleri olabilir.

## Floating information layer

Üst tarafta:

```text
Istanbul, Türkiye
Tonight
02:14
```

Altında durum:

```text
ASTRONOMICAL DARKNESS
● Excellent
```

veya:

```text
MOONLIGHT IMPACT
Moderate
```

## 8.3 Sonuç sheet'i — üç snap-point

Sky ekranındaki tüm sonuç bilgisi **tek bir bottom sheet** içinde yaşar. Ayrı floating kartlar kullanılmaz (§39 "too many floating cards").

### `peek` — varsayılan (72 yükseklik)

Tek satır. Gökyüzünün %60–70 oranını koruyan durum budur.

```text
━━━
Galactic Center      23° ALT   SNR 4.2   01:20–03:40
```

### `half` (~%45 ekran)

Karar katmanı. §16'daki capture feasibility kartı ve "neden" açıklaması.

```text
━━━
Galactic Center

Altitude        Azimuth       Visible for
23°             182°          2h 14m

Best window
01:20 — 03:40

GOOD  ● Çekilebilir
✓ Astronomik karanlık   ✓ Düşük ay etkisi
! 25s sonrası yıldız izi
```

### `full` (%92 ekran)

Teknik katman: radyometri raporu (§17), histogram (§18), SNR skalası (§19), advanced sensör verisi (§26).

Kurallar:

- Sheet açıkken arkadaki gökyüzü **etkileşimli kalır** — kullanıcı sheet'i kapatmadan gökyüzünü sürükleyebilir. Sheet, gökyüzünü kilitlemez.
- Sheet `full` durumdayken üstteki 40 yükseklikte gökyüzünün bir şeridi görünür kalır; tam ekran modal olmaz.
- Snap geçişleri `motion/transition` (250ms, easeInOutCubic).
- Hedef değiştiğinde sheet mevcut snap-point'ini korur, `peek`'e düşmez.

---

# 9. SKY SCREEN INTERACTIONS

Bu ekranda beş ayrı jest aynı yüzey üzerinde yarışır. Sahiplik açıkça tanımlanmadan implementasyona geçilmez.

## 9.1 Gesture Ownership tablosu

| Bölge | Jest | Sonuç |
|---|---|---|
| Sky canvas (kenarlar hariç) | 1 parmak sürükleme | Bakış yönü (az/alt pan) |
| Sky canvas | 2 parmak pinch | Zoom (FOV daraltma) |
| Sky canvas | Tek dokunuş (nesne üzerinde) | Nesne detayı |
| Sky canvas | Tek dokunuş (boşluk) | UI katmanlarını gizle/göster |
| Sky canvas | Çift dokunuş | Seçili hedefe ortala + `motion/hero` |
| **Timeline şeridi** (ayrı, sabit yükseklikte alt bar) | 1 parmak yatay sürükleme | Zaman scrub |
| Bottom sheet tutamacı ve içeriği | Dikey sürükleme | Sheet snap |
| Ekran sol/sağ kenarı 20 | Yatay sürükleme | **OS'a bırakılır** (iOS swipe-back, Android sistem geri) |

## 9.2 İki parmak rotasyonu kaldırıldı

View rotation birincil jest olmaktan çıkarılmıştır.

Gerekçe: hiçbir referans uygulama (Halide, Apple Weather, Stellarium mobile) bunu birincil jest yapmaz; pinch ile aynı iki parmaklı arena içinde yarıştığı için yanlışlıkla tetiklenme oranı yüksektir ve gece, eldivenle kullanımda bu oran daha da artar.

Yerine: Ayarlar → "Gökyüzü rotasyonu" toggle'ı (varsayılan **kapalı**). Açıkken iki parmak rotasyonu etkinleşir ve pinch eşiği yükseltilir.

## 9.3 Zaman scrub'ı canvas'tan ayrıdır

Time scrubber, gökyüzü canvas'ının içine gömülmez. Bunun iki nedeni var:

1. Yatay sürükleme, bakış yönü pan'i ile doğrudan çakışır — aynı jest, iki farklı anlam.
2. Kullanıcı zamanı kaydırırken gökyüzünü sabit görmek ister; parmağı gökyüzünün üstündeyse hem manzarayı kapatır hem de yanlışlıkla pan yapar.

Scrubber, sky canvas ile bottom sheet arasında 56 yüksekliğinde kendi hit-alanına sahip sabit bir şerittir.

## 9.4 Nesne seçimi

Tek dokunuşla nesne detayı:

```text
M42
Orion Nebula

Magnitude 4.0
Altitude 38°
Visible for 5h 12m
```

- Dokunma toleransı: nesnenin görsel yarıçapı + 12 (parmak hedefi asla 44'ten küçük olmaz).
- Üst üste binen nesnelerde en parlak (en düşük magnitude) olan kazanır; ikinci dokunuşta bir sonrakine geçer.
- Hedef seçildiğinde kamera `motion/hero` ile hedefe yumuşak kayar ve context bar'daki hedef adı güncellenir.

---

# 10. LOCATION SELECTION

Konum seçimi sade olmalıdır.

Ekran:

```text
Search location
────────────────────

📍 Current Location

Recent Locations

• Istanbul
• Gaziantep
• Cappadocia

Map
```

Konum seçildikten sonra özet:

```text
Location

37.1234°
37.5678°

Light Pollution
Bortle 5

Sky Brightness
20.2 mag/arcsec²
```

İleri aşamada ufuk profili eklendiğinde:

```text
Horizon Profile

● Calculated
```

veya:

```text
Horizon analysis available
Calculate
```

gibi bir yapı kullanılmalı.

---

# 11. DATE & TIME SELECTOR

Klasik date picker yeterli değildir.

Astro odaklı bir zaman seçici tasarla.

Örnek:

```text
TODAY

18 Aug
19 Aug
20 Aug
21 Aug

────────────── Timeline ──────────────

18:00
20:00
22:00
00:00
02:00
04:00
06:00
```

Timeline üzerinde:

- Sunset
- Blue hour
- Civil twilight
- Nautical twilight
- Astronomical darkness
- Moonrise
- Moonset

farklı katmanlar olarak gösterilmelidir.

Kullanıcı zamanı kaydırdığında gökyüzü anlık güncellenmelidir (`motion/scrub` = 0ms, debounce yok).

## 11.1 Tek Timeline component'i, iki mod

§11 (seçim) ve §12 (sonuç görselleştirme) **aynı component'i** kullanır, farklı modda:

| Mod | Kullanım | Etkileşim |
|---|---|---|
| `interactive` | Tarih/zaman seçici, Sky ekranı scrubber'ı | Sürüklenebilir tutamaç, haptic tick |
| `readonly` | Best shooting window (§12), hedef detayı (§21) | Sürüklenemez; en iyi pencereye dokunarak o zamana atlanır |

İki ayrı timeline bileşeni tasarlanmaz — katman renkleri, saat etiketleri ve tutamaç görünümü tek yerde tanımlanır.

## 11.2 Katman renkleri

| Katman | Token |
|---|---|
| Gündüz | `bg/secondary` |
| Civil twilight | `#1A2432` |
| Nautical twilight | `#131B27` |
| Astronomical darkness | `bg/primary` |
| Ay üstte (illumination oranıyla opaklık) | `accent/gold` @ %15–45 |
| Hedef ufkun üstünde | `accent/blue` @ %25 şerit |
| En iyi pencere | `status/excellent` 2px çerçeve + %12 dolgu |

---

# 12. BEST SHOOTING WINDOW

Bu ekran ürünün en güçlü UX anlarından biri olmalıdır.

Başlık:

# Tonight's Best Window

Büyük sonuç:

```text
01:20 — 03:40

EXCELLENT WINDOW
```

Altında timeline.

Katmanlar:

```text
Darkness
██████████████████

Target altitude
      ╭───────╮
──────╯       ╰──────

Moon impact
██ low ██ medium ██ high
```

En iyi pencere, tüm şartların kesiştiği noktada highlight edilmelidir.

Kullanıcı teknik grafikleri açıp kapatabilmelidir.

---

# 13. CAMERA & LENS SELECTOR

Bu ekran bir kamera mağazası gibi görünmemelidir.

Minimal ve hızlı olmalıdır.

```text
Camera Setup

Camera
Sony A7 III
›

Lens
14mm f/1.8
›

Orientation
Horizontal

Exposure
Manual
```

Alt tarafta canlı hesap:

```text
FIELD OF VIEW

104° × 81°
```

Ve:

```text
MAXIMUM EXPOSURE

18s

NPF calculation
```

Kullanıcı bu değere dokunursa açıklama:

```text
Recommended maximum exposure
before visible star trailing.
```

---

# 14. FIELD OF VIEW SIMULATION

Kamera ayarı değiştikçe gökyüzü gerçek zamanlı değişmelidir.

Ekran:

```text
┌─────────────────────────────┐
│                             │
│        SKY VIEW             │
│                             │
│     ┌──────────────┐        │
│     │ CAMERA FRAME │        │
│     │              │        │
│     └──────────────┘        │
│                             │
└─────────────────────────────┘
```

Frame dışında kalan alan hafif karartılmalıdır.

Frame içerisinde:

- Target object
- Stars
- Milky Way
- Horizon

görünebilir.

FOV kullanıcıya gerçekten:

> "Bu lensle kadrajda ne olacak?"

cevabını vermelidir.

---

# 15. EXPOSURE CONTROL

Ayarlar:

```text
Shutter
20s

ISO
3200

Aperture
f/2.8
```

Bunlar klasik input alanları yerine tactile controls ile tasarlanmalıdır.

Örnek:

- Horizontal value picker
- Stepper
- Large segmented values

Değer değiştikçe sonuç paneli canlı güncellenmeli.

---

# 16. CAPTURE FEASIBILITY CARD

Kullanıcının en çok göreceği kartlardan biri.

Örnek:

```text
CAPTURE ANALYSIS

●  GOOD
   Çekilebilir

SNR
8.4

Star trailing
Low

Sky background
Moderate

Clipping
0.3%
```

## 16.1 Yıldız puanı kullanılmaz

Beş yıldızlı puanlama bu üründe kullanılmaz. Gerekçe: yıldız, arkasında gerçek bir ölçek olmayan sentetik bir sayıdır ve §39'daki "fake technical numbers / decorative charts without meaning" yasağının kapsamına girer. Ayrıca kartın en baskın görsel öğesi olduğu için, "yıldız tek başına karar mekanizması olmamalı" kuralını görsel olarak çiğner.

Yerine **tek kelimelik verdict + şekil kodlu ikon** kullanılır:

| Verdict | İkon | Anlam |
|---|---|---|
| `EXCELLENT` | ● dolu daire | Koşullar en iyi durumda |
| `GOOD` | ◐ yarım daire | Çekilebilir, küçük ödünler var |
| `MARGINAL` | ◓ çeyrek daire | Mümkün ama sonuç zayıf olacak |
| `POOR` | △ üçgen | Ciddi engel var |
| `NOT VIABLE` | ✕ çarpı | Bu konfigürasyonla çekim mümkün değil |

Verdict, `display/sm` boyutunda ve ilgili `status/*` renginde yazılır. Renk kaldırıldığında (Night Vision veya renk körlüğü) anlam kelime ve ikonla tam olarak korunur.

Kullanıcı verdict'e dokunduğunda:

```text
Why?

✓ Target altitude is good
✓ Astronomical darkness
✓ Low moon impact

! Moderate light pollution
! Star trailing after 25s
```

açılmalıdır.

---

# 17. RADIOMETRY REPORT

Bu ekran Faz 5'in görsel merkezi olmalıdır.

Ancak kullanıcıyı formüllerle boğma.

## Hero Result

```text
EXPECTED CAPTURE

SNR 4.2

Usable, but challenging
```

Altında:

```text
Galactic Center

Altitude
23°

Air Mass
2.5

Atmospheric Extinction
0.63 mag

Sky Background
38%

Star Trailing
2.1 px
```

## Visual hierarchy

En üstte:

```text
Can I get the shot?
```

Sonra:

```text
How good will it be?
```

Sonra:

```text
Why?
```

En altta:

```text
Advanced physical data
```

---

# 18. HISTOGRAM SCREEN

Histogram modern bir kamera arayüzü gibi görünmelidir.

Bilgiler:

```text
BACKGROUND LEVEL
38%

HIGHLIGHT CLIPPING
0.3%

SHADOW CLIPPING
0%
```

Histogram altında:

```text
✓ Safe exposure
```

veya:

```text
⚠ Highlights approaching saturation
```

---

# 19. SNR VISUALIZATION

SNR sadece sayı olmamalıdır.

Bir quality scale oluştur:

```text
0 ─────── 5 ─────── 10 ─────── 20

Very Low   Usable   Good   Excellent
```

Kullanıcının mevcut sonucu bu çizgide göster.

Örnek:

```text
SNR 4.2

Low signal
Stacking recommended
```

İleri aşamada:

```text
1 × 120s

vs

30 × 4s
```

karşılaştırması görselleştirilebilir.

---

# 20. MOON IMPACT

Ay bilgisi ayrı bir bilgi kartı olarak çok güçlü görünmeli.

Örnek:

```text
MOON

31% illuminated

Below horizon until 02:50

Impact
Low
```

Olumsuz durumda:

```text
MOON WARNING

78% illuminated
34° altitude

High impact on sky brightness
```

Bu kart görsel olarak panik yaratmamalı.

Kırmızı kullanmak yerine:

- Warm amber
- Soft warning tone

kullan.

---

# 21. TARGET OBJECT SCREEN

Messier ve hedef nesneler için.

Örnek:

# M42

Orion Nebula

```text
Magnitude
4.0

Altitude
38°

Best Time
22:30 – 03:15

Visibility
Excellent
```

Altında altitude graph.

Ayrıca:

```text
Frame Preview
```

butonu olmalı.

---

# 22. ALTITUDE GRAPH

Minimal ve okunabilir bir grafik.

X axis:

```text
20:00 → 06:00
```

Y axis:

```text
0°
20°
40°
60°
80°
```

Önemli alanlar:

```text
Below horizon
0°–20° Poor
20°–35° Usable
35°+ Good
```

Renkler çok agresif olmamalı.

---

# 23. MILKY WAY MODE

İleri aşamada ayrı bir immersive mod.

Ekran:

```text
MILKY WAY

Galactic Core

Visible
01:20 – 03:40

Maximum altitude
24°
```

Kamera frame'i Samanyolu üzerine bindirilir.

## 23.1 Render kararı (küçük bir detay değildir)

"Samanyolu'nu göster" tek cümlelik bir tasarım isteği gibi okunur, ancak teknik olarak **ekvatoryal panorama texture'ının gnomonik projeksiyona warp edilmesi** demektir. Bu, projenin muhtemelen en ağır render işidir ve tasarım kararı verilmeden efor tahmini yapılamaz.

İki seçenek:

| Yaklaşım | Artı | Eksi |
|---|---|---|
| **A. Pre-rendered tile'lar** — panorama, sabit bakış açılarına göre önceden warp edilmiş kareler halinde saklanır | Performanslı, düşük risk, eski cihazlarda çalışır | Zoom ve serbest rotasyonda kalite kaybı, disk boyutu |
| **B. Fragment shader** — `FragmentShader` ile gerçek zamanlı örnekleme | Her açıda ve zoom'da doğru, tek texture | Shader yazımı ve platform testi gerekir, web/eski GPU riski |

**Karar: B (fragment shader), A'ya fallback ile.** Cihaz shader'ı desteklemiyorsa veya kare süresi bütçeyi aşıyorsa (§52) otomatik olarak A'ya düşülür ve kullanıcıya bildirilmez.

Bu karar Faz planlamasında ayrı bir iş kalemi olarak yer almalıdır — "gökyüzü çizimi" görevinin içine gömülmemelidir.

Kullanıcı:

- Time scrub
- Drag sky
- Change lens
- Change orientation

yapabilir.

Ancak arayüz gökyüzünün önüne geçmemelidir.

UI elemanları gerektiğinde otomatik gizlenebilir.

---

# 24. HORIZON PROFILE

Bu özellik uygulamanın farklılaştırıcı özelliklerinden biri olarak görünmelidir.

Bir polar veya panoramic horizon visualization tasarla.

Örnek:

```text
             45°
        /\          /\
     __/  \________/  \__

W         S         E
```

Gökyüzü hedefinin yolu bu profil üzerinde gösterilir.

Örnek insight:

```text
Galactic Center

Rises at 01:40

Blocked by terrain until 03:10
```

Bu sonucu büyük ve anlaşılır göster.

---

# 25. PRESETS

Kullanıcı sık kullandığı kombinasyonları kaydedebilir.

Örnek:

```text
My Gear

★ Milky Way Setup

Sony A7 III
14mm f/1.8

Default:
ISO 3200
20s
f/1.8
```

Kartlar sade olmalı.

Fazla skeuomorphic kamera görselleri kullanma.

---

# 26. ADVANCED SETTINGS

Tüm kullanıcılar şu değerleri görmek zorunda değildir:

- Gain
- Read noise
- Quantum efficiency
- Dark current
- Full well capacity
- Bit depth
- Lens transmission

Bunları:

```text
Advanced Sensor Profile
```

altında gizle.

Normal kullanıcı:

```text
Standard Profile
```

seçebilir.

Profesyonel kullanıcı:

```text
Custom Sensor Calibration
```

açabilir.

---

# 27. EMPTY STATES

Boş ekranlar bile ürün deneyiminin parçası olmalı.

Örnek:

```text
No target selected

Choose an object
to analyze tonight's conditions.
```

Minimal celestial illustration kullanılabilir.

Aşırı büyük illustration kullanma.

Boş durum şablonu — her zaman üç parça:

```text
[minimal illüstrasyon, maks. 96×96]

Başlık        (subhead)      Hedef seçilmedi
Açıklama      (body)         Bu geceki koşulları analiz etmek için bir nesne seç.
Aksiyon       (primary btn)  Hedef seç
```

Hata durumları boş durum değildir — bkz. §42.

---

# 28. LOADING STATES

Astronomik hesaplamalar sırasında:

❌ Generic spinner

yerine bağlama uygun loading:

```text
Calculating sky conditions…

Analyzing moonlight
Calculating target altitude
Estimating background brightness
```

gibi aşamalar gösterilebilir.

---

# 29. ONBOARDING

Onboarding kısa olmalıdır.

Maksimum 4 ekran.

### Screen 1

# Plan before you go.

See what your camera can capture before you reach the location.

### Screen 2

# Your sky is unique.

Location, time, moonlight and light pollution change everything.

### Screen 3

# Your camera changes the result.

Add your camera and lens to simulate the frame.

### Screen 4

# Ready for tonight?

Konumunu kullanarak bu geceki gökyüzünü senin için hesaplıyoruz. Konumun cihazından çıkmaz.

[ Konumumu kullan ]
[ Konumu elle seçeceğim ]

Onboarding'de uzun teknik açıklamalar yapma.

## 29.1 İzin priming kuralı

Son ekran aynı zamanda **konum izni priming ekranıdır**. Native izin dialogu asla bağlamsız açılmaz — önce neden istendiği tek cümleyle açıklanır, kullanıcı [Konumumu kullan]'a bastıktan **sonra** sistem dialogu gösterilir.

Gerekçe: native dialog bir kez reddedilirse iOS'ta tekrar gösterilemez; kullanıcı Ayarlar'a gitmek zorunda kalır. Priming, bu tek şansı korur.

"Konumu elle seçeceğim" seçeneği eşit görsel ağırlıktadır — izin vermeyen kullanıcı da ürünü tam kullanabilmelidir (§43).

---

# 30. MICRO INTERACTIONS

Animasyonlar:

- Smooth
- Slow enough to feel premium
- Fast enough not to block work

Örnek:

Zaman slider hareket ettiğinde:

- Stars subtly rotate
- Target position changes
- Altitude graph updates
- Moon position transitions

Camera focal length değiştiğinde:

- FOV frame smoothly expands/contracts

SNR değiştiğinde:

- Number transitions naturally

Avoid:

❌ Bounce animations  
❌ Gaming particles  
❌ Excessive glowing  
❌ Flashing effects

---

# 31. NIGHT FIELD MODE

Uygulama gece kullanılacağı için özel bir mod düşün.

Opsiyonel:

# Night Vision Mode

Bu modda:

- Tüm palet tek kırmızı kanala indirgenir (§4.4 eşleme tablosu)
- Beyaz nokta hiçbir yerde kullanılmaz
- Uygulama içi maksimum parlaklık %40'a sınırlanır
- Zemin `#000000` olur (OLED'de gerçek siyah = sıfır ışık)

## 31.1 Kritik çakışma: status renkleri

Night Vision modunda `status/excellent` (yeşil), `status/moderate` (altın) ve `status/critical` (kırmızı) **ayırt edilemez hale gelir**. Bu, §34'ün "renk tek başına anlam taşımasın" kuralının zorunlu olarak devreye girdiği tek senaryodur.

Çözüm — Night Vision aktifken:

1. Her status göstergesi **şekil ikonunu zorunlu gösterir** (● ◐ ◓ △ ✕ — §16.1).
2. Her verdict **kelimesiyle birlikte** yazılır; sadece renkli nokta gösterilmez.
3. Ayrım ikinci olarak **parlaklık kademesiyle** desteklenir: excellent en parlak, critical en sönük değil — tam tersi, critical en parlak (dikkat çekmesi gerekir), excellent en sönük.

Bu kural test edilebilirdir: ekran görüntüsü grayscale'e çevrildiğinde tüm status'lar hâlâ ayırt edilebilmelidir.

## 31.2 Tetikleme

| Yöntem | Davranış |
|---|---|
| Manuel | Ayarlar ve Sky ekranı hızlı erişim menüsünde toggle |
| Öneri | Gün batımından 30 dk sonra, kullanıcı ilk kez uygulamayı açtığında tek seferlik bir bilgi şeridi: "Gece modu? Göz adaptasyonunu korur." → [Aç] / [Şimdi değil] |
| Otomatik | **Yok.** Ortam ışığı sensörüne göre otomatik geçiş yapılmaz — kullanıcı ekranına bakarken temanın kendiliğinden değişmesi rahatsız edicidir. |

Bu mod varsayılan tema değildir; kullanıcı tarafından açılır ve seçim kalıcı olarak saklanır.

---

# 32. DESIGN SYSTEM COMPONENTS

Eksiksiz component library oluştur.

## Buttons

- Primary
- Secondary
- Ghost
- Icon
- Destructive

## Cards

- Result Card
- Metric Card
- Warning Card
- Target Card
- Equipment Card

## Inputs

- Search
- Numeric stepper
- Slider
- Segmented control
- Date selector
- Time scrubber

## Visualization

- Timeline (`interactive` / `readonly` — §11.1)
- Altitude graph
- Histogram
- SNR scale
- Horizon profile
- Sky map
- FOV frame
- **Comparison view** — yan yana iki sonuç (1×120s vs 30×4s, iki lens, iki tarih)
- **Moon phase indicator** — aydınlanma oranı + ufuk durumu

## Navigation & Chrome

- **Context bar** (§7.2) — üç bölümlü, her bölüm ayrı hedef
- **Bottom sheet** — üç snap-point (`peek` / `half` / `full`, §8.3)
- Bottom nav (compact) / Nav rail (medium, expanded)
- **Time scrubber strip** — kendi hit-alanına sahip 56 yüksekliğinde şerit

## Feedback & System

- **Permission card** — izin öncesi bağlam açıklaması (§43)
- **Error state** — mesaj + tek birincil aksiyon (§42)
- **Empty state** — minimal celestial illüstrasyon + tek aksiyon
- **Offline banner** — kalıcı, kapatılabilir değil, `accent/gold`
- **Download progress** — boyut + kalan süre + iptal (§54)
- **Coach mark** — ilk kullanımda tek seferlik jest ipucu (maksimum 3 adet, tüm uygulamada)
- **Paywall sheet** — §45
- **Settings row** — etiket + değer + chevron / toggle / segmented

## Status

| Durum | Renk | İkon | Kelime |
|---|---|---|---|
| Excellent | `status/excellent` | ● | EXCELLENT |
| Good | `status/good` | ◐ | GOOD |
| Moderate | `status/moderate` | ◓ | MARGINAL |
| Poor | `status/poor` | △ | POOR |
| Critical | `status/critical` | ✕ | NOT VIABLE |

Her durum **üç kanalı birden** taşır: renk + ikon + kelime. İkon veya kelime, "yerden tasarruf" gerekçesiyle bile atlanamaz.

Accessibility için renk tek başına anlam taşımaz (§31.1 grayscale testi).

---

# 33. RESPONSIVE DESIGN RULES

## Mobile

```text
Single focus
Bottom sheets
One-handed interaction
Large controls
```

## Tablet

```text
Sky + data
Two panel mode
```

## Desktop

```text
Persistent controls
Large simulation canvas
Multiple simultaneous panels
```

## 33.1 Breakpoint'ler

| Sınıf | Genişlik | Layout |
|---|---|---|
| `compact` | < 600 | Tek kolon, bottom nav, bottom sheet |
| `medium` | 600 – 1024 | İki kolon: sky + yan panel; nav rail |
| `expanded` | > 1024 | Üç kolon (§2 desktop şeması); nav rail genişletilmiş |

## 33.2 Layout kuralları

- Web'de içerik maksimum genişliği **1440**. Sky canvas bu sınırdan muaftır (edge-to-edge kalabilir), ancak kartlar, paneller ve metin blokları 1440'ı aşmaz.
- `medium` ve `expanded` sınıflarında bottom sheet yerine **kalıcı yan panel** kullanılır; snap-point'ler (§8.3) panel bölümlerinin açık/kapalı durumuna dönüşür.
- Context bar (§7.2) tüm sınıflarda kalır; `expanded` sınıfında sol kolonun üstüne taşınır ve genişletilmiş halde (tam metin) gösterilir.
- Bottom nav yalnızca `compact` sınıfındadır; `medium` ve üzerinde nav rail'e dönüşür.

Tüm platformlarda aynı design language korunmalı.

---

# 34. ACCESSIBILITY

## 34.1 Temel gereksinimler

| Gereksinim | Kabul kriteri |
|---|---|
| Kontrast | Body metin ≥ 4.5:1, ≥16sp metin ve ikon ≥ 3:1 (§4.2 token'ları bunu garanti eder) |
| Dynamic Type | Gövde stilleri sınırsız, `display/*` maksimum 1.3× ölçeklenir; hiçbir layout 200% ölçekte kırılmaz |
| Renk bağımsızlığı | Grayscale ekran görüntüsünde tüm status'lar ayırt edilebilir (§31.1 testi) |
| Dokunma hedefi | ≥ 44; saha kontrolleri ≥ 56 (§5A) |
| Reduce motion | Tüm `motion/*` süreleri 0'a iner |

## 34.2 Sky canvas ve ekran okuyucu

Gökyüzü bir `CustomPainter` ile çizildiği için **varsayılan olarak ekran okuyucuya tamamen görünmezdir**. Bu, uygulamanın en büyük erişilebilirlik riskidir ve implementasyon sırasında çözülmesi zorunludur.

Kural: canvas üzerindeki her etkileşimli nesne için bir `Semantics` düğümü üretilir.

```text
Semantics label örneği:
"M42, Orion Bulutsusu. Kadir 4.0. Yükseklik 38 derece,
azimut 172 derece. 5 saat 12 dakika görünür. Seçmek için çift dokunun."
```

Ek olarak canvas'ın kendisi için özet bir label bulunur:

```text
"Gökyüzü görünümü. Kuzeye bakılıyor, 84 derece görüş alanı.
Görünür hedef sayısı: 12. Listeyi açmak için çift dokunun."
```

Bu "listeyi aç" eylemi, ekran okuyucu kullanıcısını Targets sekmesinin (§47) liste görünümüne yönlendirir — gökyüzünün metinsel eşdeğeri budur.

## 34.3 Gece + saha koşulları

Bunlar erişilebilirliğin ayrılmaz parçasıdır, ayrı bir "nice to have" değildir:

- **Eldivenle kullanım:** Birincil kontroller ≥ 56 dokunma hedefi; hassas sürükleme gerektiren tek kontrol time scrubber'dır ve tutamacı 56 genişliğindedir.
- **Haptic geri bildirim:** Ekrana bakmadan onay alabilmek için — timeline'da saat başı geçişte hafif tick, snap-point'e oturmada medium impact, verdict sınıfı değiştiğinde (GOOD → POOR) belirgin uyarı haptic'i.
- **Tek elle erişim:** Tüm birincil eylemler ekranın alt %40'ında konumlanır. Üst bölge yalnızca context bar ve salt-okunur bilgi taşır.
- **Soğukta pil:** Gece sahada pil kritiktir. Sky canvas kullanıcı etkileşimi olmadığında saniyede 1 kareye düşer (bkz. §52); tam parlaklık asla zorlanmaz.
- **Islak/çıplak gözle okuma:** Kritik değerler (`display/*`) hiçbir zaman `text/tertiary` renginde yazılmaz.

## 34.4 Gece modu ≠ erişilebilirlik modu

Night Vision Mode (§31) göz adaptasyonunu korumak içindir ve **kontrastı düşürür**. Yüksek kontrast erişilebilirlik ihtiyacı olan kullanıcı için ayrı bir "Yüksek kontrast" ayarı bulunur. İki mod aynı anda açılabilir; bu durumda Night Vision paletinin kırmızı tonları arasındaki kontrast farkı maksimuma çekilir, parlaklık sınırı korunur.

---

# 35. UX PRIORITY

Her tasarım kararında şu soruyu sor:

> Kullanıcı bunu gerçekten bilmek zorunda mı?

Eğer cevap hayırsa:

- Gizle
- Collapse et
- Advanced section'a taşı
- Tooltip'e koy

Uygulamanın amacı:

> Astro fotoğrafçılığın karmaşık fiziğini kullanıcıdan saklamak değil, karmaşıklığı anlaşılır hale getirmektir.

---

# 36. ANA USER FLOW

## 36.1 Doğrusal akış modeli terk edilmiştir

Aşağıdaki 13 adımlık doğrusal akış **artık geçerli değildir**:

```text
Open App → Location → Date/Time → Target → Camera → Sky → Window →
Exposure → Analyze → Read SNR → Adjust → Find Best → Save
```

Sorun: bu model, kullanıcıyı çekim gecesinden önce 13 adımlık bir form doldurmaya zorlar. Oysa gerçek kullanım döngüseldir — kullanıcı bir parametreyi değiştirir, sonucu görür, tekrar değiştirir.

## 36.2 Gerçek akış: 1 varsayılan + 3 karar + 1 döngü

### Adım 0 — Açılış (kullanıcı hiçbir şey yapmaz)

Uygulama açıldığında konum (GPS veya son kullanılan), zaman (şu an) ve ekipman (son kullanılan preset) **zaten doludur**. Kullanıcı hiçbir seçim yapmadan gökyüzünü ve bu geceye ait bir sonuç görür.

İlk kurulumda ekipman yoksa varsayılan olarak "genel APS-C 18mm f/3.5" kullanılır ve context bar'da ekipman bölümü `accent/blue` ile işaretlenir.

### Karar 1 — Ne çekeceğim? (Targets)

Kullanıcı hedef seçer veya "bu gece önerilenler"den birine dokunur → Sky'a döner.

### Karar 2 — Neyle çekeceğim? (context bar → ekipman sheet)

Kamera + lens seçilir. FOV çerçevesi anında güncellenir.

### Karar 3 — Ne zaman çekeceğim? (timeline scrubber veya "en iyi pencereye git")

### Döngü — Ayarla ve gör

```text
        ┌──────────────────────────────┐
        │                              │
   Poz / lens / zaman değiştir         │
        │                              │
        ↓                              │
   Gökyüzü + FOV + sonuç anında güncellenir
        │                              │
        ↓                              │
   Verdict + SNR + trailing oku        │
        │                              │
        └──────────────────────────────┘
                     │
                     ↓
              Planı kaydet
```

Bu döngü **tek ekranda** (Sky) gerçekleşir. Sekme değişimi gerektirmez.

## 36.3 Kabul kriteri

Ürünün akış tasarımı şu testten geçmelidir:

> Uygulamayı ilk kez açan bir kullanıcı, **hiçbir şeye dokunmadan** "bu gece çekim yapılabilir mi?" sorusunun cevabını görmelidir.

> Ekipmanını değiştiren bir kullanıcı, sonucu görmek için **hiçbir sekme değiştirmemelidir**.

Kullanıcı hiçbir adımda ayrı ayrı sayfa dolduruyormuş gibi hissetmemelidir.

---

# 37. ANA ÜRÜN EKRANI — ÖNERİLEN KOMPOZİSYON

Uygulamanın ana ekranında ideal yapı:

```text
┌──────────────────────────────────┐
│ İstanbul · Bu gece 02:14 · 14mm ⌄│  ← context bar (§7.2)
│ ASTRONOMICAL DARKNESS  ● Excellent│
│                                  │
│                                  │
│          SKY SIMULATION          │
│                                  │
│       ✦        ✧        ✦        │
│              TARGET              │
│                                  │
│                                  │
├──────────────────────────────────┤
│ 20:00 ──────●──────────── 06:00  │  ← time scrubber (§9.3)
├──────────────────────────────────┤
│ ━━━                              │  ← sheet peek (§8.3)
│ Galactic Center  23° ALT  SNR 4.2│
│ ◐ GOOD · 01:20 — 03:40           │
├──────────────────────────────────┤
│   Sky        Targets      Library│
└──────────────────────────────────┘
```

Bu ekran uygulamanın kimliğini taşımalıdır.

Kullanıcı uygulamayı açtığında:

- Nerede olduğunu
- Saatin ne olduğunu
- Gökyüzü durumunu
- Ne çektiğini
- Çekimin mümkün olup olmadığını

birkaç saniye içinde anlayabilmelidir.

---

# 38. GÖRSEL REFERANS DUYGUSU

Tasarım şu hissin birleşimi olmalıdır:

```text
Apple Weather
+
Halide
+
Linear
+
Professional scientific instrument
+
Real night sky
```

Ama hiçbir markanın birebir kopyası olmamalıdır.

Sonuç:

# Calm.
# Precise.
# Cinematic.
# Scientific.
# Premium.

olmalıdır.

---

# 39. KAÇINILMASI GEREKENLER

Kesinlikle kaçın:

- Neon sci-fi UI
- Purple galaxy gradients everywhere
- Gaming dashboard aesthetics
- Excessive glassmorphism
- Too many floating cards
- Too many borders
- Too much text
- Fake technical numbers
- Decorative charts without meaning
- Generic space illustrations
- Cartoon planets
- Emoji-style icons
- Overly rounded childish components

---

# 40. SON HEDEF

Ortaya çıkan uygulama şu hissi vermeli:

> "Bu uygulama bana gökyüzünü göstermiyor sadece. Bana çekime gitmeden önce ne yapmam gerektiğini söylüyor."

Kullanıcı uygulamayı açmalı, konumunu ve ekipmanını seçmeli, gökyüzünü görmeli ve birkaç dakika içinde şu soruların cevabını almalıdır:

1. Bu gece çekim mümkün mü?
2. En iyi saat ne zaman?
3. Hedef ne kadar yüksekte olacak?
4. Ay çekimi ne kadar etkileyecek?
5. Lensimle hedef kadraja sığacak mı?
6. Kaç saniye poz verebilirim?
7. Yıldız izi oluşacak mı?
8. Gökyüzü fonu ne kadar parlak?
9. Tahmini SNR ne olacak?
10. Ayarları değiştirirsem sonuç nasıl değişecek?

Tasarımın tüm ekranları, component'leri ve kullanıcı akışları bu hedefe hizmet etmelidir.

Öncelik her zaman:

# Decision → Explanation → Technical Detail

olmalıdır.

Önce kullanıcıya sonucu göster.

Sonra nedenini açıkla.

En son fiziksel ve teknik detayları isteyen kullanıcıya sun.

---

# 41. OFFLINE-FIRST STRATEJİSİ

Bu uygulamanın birincil kullanım yeri **şehir dışı, karanlık gökyüzü bölgeleridir** — yani kapsama alanının en zayıf olduğu yer. İnternet gerektiren bir astro planlama uygulaması, tam da ihtiyaç duyulduğu anda çalışmaz.

## 41.1 Çevrimdışı çalışması zorunlu olanlar

- Yıldız ve Messier katalogları (cihazda gömülü)
- Tüm astronomik hesaplamalar (efemeris, altitude, twilight, ay)
- Radyometri, SNR, NPF, FOV hesapları
- Kayıtlı planlar, ekipman presetleri, ayarlar
- Son kullanılan konumlar ve onların ışık kirliliği değerleri (önbellekte)

## 41.2 İnternet gerektirenler (ve çevrimdışı davranışları)

| Özellik | Çevrimdışı davranış |
|---|---|
| Konum arama (geocoding) | Son kullanılan konumlar listesi + harita üzerinde elle seçim |
| Işık kirliliği (yeni konum) | Kullanıcıdan Bortle sınıfını elle seçmesi istenir |
| Hava durumu (§50) | Kart "Çevrimdışı — hava verisi yok" durumunda gösterilir, gizlenmez |
| Ufuk profili DEM verisi | Daha önce indirilen bölgeler çalışır; yenisi indirilemez |
| Hesap/abonelik doğrulama | Son doğrulanan durum 30 gün geçerli sayılır |

## 41.3 Offline banner

Ağ kaybedildiğinde context bar'ın altında kalıcı, kapatılamaz bir şerit belirir:

```text
⚡ Çevrimdışısın — hesaplamalar çalışıyor, arama ve hava durumu kapalı
```

Renk `accent/gold`. Kırmızı kullanılmaz: çevrimdışı olmak bir hata değil, beklenen bir saha durumudur.

---

# 42. HATA VE BOŞ SONUÇ MATRİSİ

Her hata durumu **üç parçadan** oluşur: ne oldu (suçlayıcı olmayan dille) · neden önemli · tek birincil aksiyon.

Yasak: "Bir hata oluştu", "Something went wrong", ham hata kodu, teknik stack bilgisi.

| Durum | Mesaj | Birincil aksiyon | İkincil |
|---|---|---|---|
| Konum izni reddedildi | "Konumun olmadan gökyüzünü hesaplayamayız. Konumunu elle de seçebilirsin." | Konum seç | Ayarları aç |
| GPS timeout (>10s) | "Konum alınamadı — açık alanda tekrar dene." | Tekrar dene | Elle seç |
| Ağ yok (arama) | "Çevrimdışısın. Kayıtlı konumların kullanılabilir." | Kayıtlılardan seç | — |
| Katalog yüklenemedi | "Yıldız kataloğu açılamadı. Uygulamayı yeniden başlatmak sorunu çözebilir." | Tekrar yükle | Destek |
| Arama sonuçsuz | "'{sorgu}' bulunamadı." | Yakın öneriler | Haritadan seç |
| Hedef bu enlemden hiç görünmüyor | "M83 senin enlemindan hiçbir zaman ufkun üstüne çıkmıyor." | Benzer hedefler öner | — |
| Hedef bu gece görünmüyor | "Orion Bulutsusu bu gece ufkun altında. 14 Kasım'dan itibaren görünür olacak." | O tarihe git | Bu gece görünenler |
| Hava verisi alınamadı | "Hava verisi şu an alınamıyor." | Tekrar dene | — |
| Ufuk profili verisi yok | "Bu bölge için arazi verisi indirilmemiş." | İndir (12 MB) | Ufuksuz devam et |

## 42.1 Kritik ilke

**Hiçbir hata, sonucu tamamen bloke etmez.** Işık kirliliği verisi alınamadıysa varsayılan Bortle 5 ile hesap yapılır ve değerin yanında bir "tahmini" işareti gösterilir. Kullanıcı her zaman bir cevap alır; cevabın güven düzeyi belirtilir.

---

# 43. İZİN AKIŞLARI

## 43.1 İstenen izinler

| İzin | Ne zaman istenir | Reddedilirse |
|---|---|---|
| Konum (when in use) | Onboarding son ekranında, priming sonrası (§29.1) | Elle konum seçimi; ürün tam çalışır |
| Bildirim | İlk kez bir "en iyi pencere hatırlatıcısı" kurulurken (§46) | Hatırlatıcı özelliği pasif; başka hiçbir şey etkilenmez |
| Fotoğraflara yazma | Yalnızca kullanıcı bir plan görselini kaydetmek istediğinde (§49) | Paylaş sayfası üzerinden yönlendirilir |

Kural: **hiçbir izin uygulama açılışında toplu olarak istenmez.** Her izin, o izne ihtiyaç duyan eylemin tam öncesinde ve bağlamıyla birlikte istenir.

## 43.2 Permission card şablonu

```text
[ikon]

Konumunu kullanalım mı?

Gökyüzü, konumuna göre tamamen değişir.
Konumun cihazından çıkmaz ve paylaşılmaz.

[ İzin ver ]
[ Elle seçeceğim ]
```

## 43.3 Kalıcı reddetme

Kullanıcı sistem düzeyinde izni reddettiyse uygulama bunu **bir kez** hatırlatır ve bir daha ısrar etmez. İlgili ekranda tek satırlık pasif bir bilgi kalır: "Konum kapalı — elle seçiliyor. [Aç]"

---

# 44. AYARLAR EKRANI

Library sekmesi altında yer alır.

```text
GÖRÜNÜM
  Tema                    Sistem / Koyu / Night Vision
  Yüksek kontrast         [toggle]
  Gökyüzü rotasyonu       [toggle]  (§9.2)
  Takımyıldız çizgileri   [toggle]
  Yıldız adları           [toggle]

BİRİMLER
  Sıcaklık                °C / °F
  Mesafe                  km / mi
  Saat formatı            24s / 12s
  Koordinat gösterimi     Ondalık / DMS

VERİ
  İndirilen veriler       412 MB  ›
  Yalnızca Wi-Fi'de indir [toggle]
  Önbelleği temizle

BİLDİRİMLER
  En iyi pencere hatırlatıcısı  ›
  Ay fazı bildirimleri          [toggle]

HESAP
  Abonelik                Premium ›
  Satın alımları geri yükle

HAKKINDA
  Veri kaynakları ve lisanslar  ›
  Gizlilik politikası           ›
  Sürüm                         1.0.0 (128)
```

## 44.1 Veri kaynakları ve lisanslar — zorunlu

Kullanılan katalog ve veri setlerinin (ör. Yale BSC5, Messier, ESO/NASA görselleri, Copernicus DEM) atıf gereksinimleri yasal olarak zorunludur ve store incelemesinde kontrol edilir. Bu ekran "hoş olur" değil, **yayın öncesi zorunlu** kalemdir.

Her kaynak için: ad · sağlayıcı · lisans türü · lisans metnine bağlantı.

---

# 45. ABONELİK, PAYWALL VE HESAP

Yol haritasındaki "ücretsiz başlangıç → abonelik" modeli tasarımda karşılığı olmadan kalamaz.

## 45.1 Ücretsiz / Premium ayrımı

| Özellik | Ücretsiz | Premium |
|---|---|---|
| Gökyüzü simülasyonu, hedef seçimi | ✓ | ✓ |
| Altitude, twilight, ay hesapları | ✓ | ✓ |
| FOV simülasyonu, NPF max poz | ✓ | ✓ |
| Temel SNR / verdict | ✓ | ✓ |
| Kayıtlı plan | 3 adet | Sınırsız |
| Ekipman preseti | 2 adet | Sınırsız |
| Ufuk profili (arazi engeli) | — | ✓ |
| Hava durumu entegrasyonu | — | ✓ |
| Radyometri detay raporu, histogram | — | ✓ |
| Stacking karşılaştırması | — | ✓ |
| Bildirim hatırlatıcıları | — | ✓ |

İlke: **ücretsiz sürüm tek başına gerçekten faydalı olmalıdır.** Ücretsiz kullanıcı "bu gece çekim yapabilir miyim?" sorusunun cevabını tam olarak alır. Premium, derinlik ve otomasyon satar.

## 45.2 Paywall tetikleme noktaları

Paywall yalnızca kullanıcı premium bir özelliğe **kendi isteğiyle dokunduğunda** açılır. Açılışta, onboarding'de veya rastgele bir anda gösterilmez.

Kilitli özellik, kilitli olduğunu **önceden** belli eder (satır sonunda küçük bir kilit işareti) — kullanıcı dokunmadan önce bilir, tuzağa düşmüş hissetmez.

## 45.3 Paywall sheet içeriği

```text
Ufuk profili — Premium

Bulunduğun noktadaki dağ ve ağaç
engellerini hesaba katarak hedefin
gerçekte ne zaman görüneceğini gösterir.

[görsel: aynı hedef, engelli vs engelsiz]

Yıllık    ₺X/yıl    (ayda ₺Y — %Z tasarruf)
Aylık     ₺Y/ay

[ Premium'a geç ]

Satın alımları geri yükle · Şartlar · Gizlilik
```

Zorunlu unsurlar (store politikası): net fiyat, abonelik süresi, otomatik yenileme bilgisi, geri yükleme bağlantısı, şartlar ve gizlilik bağlantıları.

## 45.4 Hesap

Hesap **isteğe bağlıdır**. Uygulama hesapsız tam çalışır. Hesap yalnızca iki şey için vardır: cihazlar arası plan senkronu ve aboneliğin yeni cihazda tanınması.

---

# 46. BİLDİRİMLER VE HATIRLATICILAR

Ürünün temel vaadi "gitmeden önce doğrula" olduğu için bildirim, doğal bir uzantıdır — reklam kanalı değildir.

## 46.1 Bildirim türleri

| Tür | Örnek | Varsayılan |
|---|---|---|
| Pencere hatırlatıcısı | "Samanyolu çekim pencereni 45 dk sonra açılıyor — 01:20'de İstanbul'da." | Kullanıcı kurarsa açık |
| Koşul değişimi | "Bu gece için tahmin değişti: bulutluluk %20 → %70." | Premium, açık |
| Ay fazı | "Yeni ay yaklaşıyor — önümüzdeki 5 gece en karanlık gökyüzü." | Kapalı |
| Ürün/pazarlama | — | **Yok.** Bu kanal pazarlama için kullanılmaz. |

## 46.2 Kurallar

- Gece 23:00 – 06:00 arası yalnızca kullanıcının **kendi kurduğu** hatırlatıcılar gönderilir.
- Bir gecede en fazla 2 bildirim.
- Her bildirim doğrudan ilgili plana veya Sky ekranının o zamanına açılır (deep link).

---

# 47. HEDEF KEŞFİ — TARGETS SEKMESİ

Ana akışın (§36) en kritik kararı burada verilir; önceki sürümde bu ekran hiç tanımlanmamıştı.

## 47.1 Yapı

```text
┌──────────────────────────────────────┐
│ Ara: nesne adı, katalog no, tür      │
├──────────────────────────────────────┤
│ BU GECE ÖNERİLENLER                  │
│                                      │
│  ●  Samanyolu Merkezi                │
│     23° · 01:20–03:40 · GOOD         │
│                                      │
│  ●  M31 Andromeda                    │
│     58° · 22:10–05:00 · EXCELLENT    │
│                                      │
│  ◐  M42 Orion                        │
│     38° · 03:15–06:00 · GOOD         │
├──────────────────────────────────────┤
│ TÜM KATALOG                          │
│ [Bulutsu] [Galaksi] [Küme] [Geniş]   │
└──────────────────────────────────────┘
```

## 47.2 "Bu gece önerilenler" sıralama mantığı

Liste alfabetik veya katalog sırasına göre değil, **kullanıcının bu gece gerçekten çekebileceğine göre** sıralanır. Sıralama girdileri:

1. Verdict sınıfı (§16.1)
2. Maksimum altitude
3. Görünür kalma süresi
4. Kullanıcının mevcut lensiyle kadraja sığma oranı
5. Ay ayrımı (hedefin aydan açısal uzaklığı)

Her satır neden önerildiğini tek satırda gösterir — sıralama asla açıklamasız kalmaz.

## 47.3 Kurallar

- Hedef seçildiği anda Sky sekmesine dönülür (§7.3). Targets kalınacak yer değildir.
- Bu gece görünmeyen hedefler listede kalır ama sönükleşir ve "14 Kasım'dan itibaren" etiketi taşır — kullanıcı yokluğu da bilgi olarak alır.
- Filtre çipleri çoklu seçim yapılabilir, seçim kalıcı değildir (sekmeden çıkınca sıfırlanır).

---

# 48. EKİPMAN YÖNETİMİ

Library → Ekipmanım.

## 48.1 Gereken akışlar

| Akış | Not |
|---|---|
| Kamera ekle | Marka/model arama → gövde veritabanından seçim |
| Lens ekle | Odak uzunluğu + diyafram; zoom lens için aralık |
| **Özel ekipman** | Veritabanında olmayan gövde/lens için elle giriş: sensör genişliği/yüksekliği (mm), piksel sayısı, odak uzunluğu, maksimum diyafram |
| Düzenle / sil | Kayıtlı planlarda kullanılan ekipman silinirse uyarı |
| Varsayılan seç | Uygulama açılışında hangi kombinasyonun yükleneceği |

## 48.2 Özel sensör girişi

Basit mod yeterlidir (sensör boyutu + piksel sayısı → piksel adımı otomatik hesaplanır). Read noise, quantum efficiency, full well gibi değerler §26'daki "Custom Sensor Calibration" altında kalır ve **hiçbir zaman zorunlu alan değildir** — boş bırakılırsa sensör sınıfının tipik değeri kullanılır ve sonuçta "tahmini" işareti gösterilir.

---

# 49. PAYLAŞIM VE DIŞA AKTARMA

## 49.1 Plan kartı görseli

Kaydedilmiş bir plan, tek bir görsel olarak dışa aktarılabilir: gökyüzü görünümü + FOV çerçevesi + hedef · konum · tarih · pencere · ekipman · poz özeti.

Görsel kompozisyonu paylaşıma uygun olmalı (1:1 ve 9:16 varyantları), ekran görüntüsü gibi görünmemelidir.

## 49.2 Web deep link

Web sürümünde uygulama durumu URL'ye yansır:

```text
/sky?lat=41.01&lon=28.98&t=2026-08-19T02:14Z&target=M42&cam=a7iii&lens=14-1.8
```

Bu URL paylaşıldığında karşı taraf **aynı simülasyonu** görür. Mobilde aynı bağlantı uygulamayı açar (universal link).

## 49.3 Metin özeti

Kopyalanabilir düz metin — mesajlaşma uygulamaları için:

```text
Samanyolu Merkezi · 19 Ağu · Kapadokya
En iyi pencere 01:20–03:40 · maks 24°
A7III + 14mm f/1.8 · 20s ISO3200 · SNR 4.2
```

---

# 50. HAVA DURUMU VE GÖRÜŞ KALİTESİ

Bulutluluk, "bu gece çekim yapabilir miyim?" sorusunun **en belirleyici girdisidir** ve gökyüzü fiziğinin tamamından daha çok fark yaratır. Önceki sürümde tasarımda hiç yer almıyordu.

## 50.1 Sky ekranındaki yeri

Verdict hesabına bir girdi olarak katılır. Bulutluluk yüksekse verdict, astronomik koşullar mükemmel olsa bile düşer:

```text
◓  MARGINAL
   Gökyüzü uygun, hava değil

   ✓ Astronomik karanlık
   ✓ Hedef 58° yükseklikte
   ! Bulutluluk %70
```

## 50.2 Hava kartı

```text
HAVA

Bulutluluk      %20      ●
Nem             %65
Rüzgar          8 km/s
Seeing          2.1"     ◐
Şeffaflık       İyi

Son güncelleme 21:40
```

## 50.3 Kurallar

- Tahmin belirsizliği gizlenmez: 48 saatten uzak tahminler "düşük güven" işaretiyle gösterilir.
- Zaman scrubber'ı ilerledikçe bulutluluk katmanı timeline üzerinde ayrı bir şerit olarak güncellenir.
- Hava verisi yoksa hesap yine yapılır, verdict'in yanında "hava verisi yok" notu görünür (§42.1).

---

# 51. HOME SCREEN WIDGET

Uygulamayı açmadan tek bilgiyi görmek: bu gece çekim var mı?

| Boyut | İçerik |
|---|---|
| Küçük | Verdict ikonu + pencere saati (`01:20–03:40`) |
| Orta | Verdict + hedef adı + altitude + bulutluluk |
| Büyük | Yukarıdakiler + gecenin mini timeline'ı |

Kurallar: widget karanlık palete sadık kalır, saatte bir güncellenir, dokunulduğunda ilgili Sky durumuna açılır. Widget üzerinde etkileşimli kontrol bulunmaz.

---

# 52. PERFORMANS VE MOTION BÜTÇESİ

Tasarım kararlarının çoğu, kare bütçesi tutmadığında geçersizdir. Bu bölüm tasarım ile implementasyon arasındaki sözleşmedir.

## 52.1 Bütçe

| Senaryo | Hedef |
|---|---|
| Time scrub sırasında kare süresi | **< 16 ms** (60 fps), animasyonsuz |
| Sky pan/zoom | < 16 ms |
| Etkileşim yokken | 1 fps'e düş (pil tasarrufu — §34.3) |
| Soğuk açılış → ilk gökyüzü karesi | < 2 s |
| Sheet snap geçişi | Kare düşürmeden 250 ms |

## 52.2 Bütçeyi tutmak için kurallar

- **Ana thread'de kalabilir:** görünür yıldızların ekran koordinatına projeksiyonu, çizim.
- **Isolate'e taşınmalı:** katalog yükleme ve ayrıştırma, gece boyu altitude eğrisi hesabı, en iyi pencere aramaları, radyometri/SNR tarama, ufuk profili DEM işleme.
- **Frame başına yeniden hesaplanmaz:** yıldız katalogunun tamamı (yalnızca görünür kadran + magnitude eşiği), takımyıldız çizgileri (zamanla değişmez, yalnızca dönüşüm uygulanır), ay/güneş efemerisi (dakikada bir yeterli, kare başına değil).
- Magnitude eşiği zoom seviyesine göre uyarlanır: geniş açıda yalnızca parlak yıldızlar çizilir, zoom yapıldıkça sönük yıldızlar eklenir. Ekranda aynı anda çizilen yıldız sayısı üst sınırı belirlenmelidir.
- Time scrub sırasında sonuç kartı sayıları da anlık güncellenir; ağır radyometri hesabı ise scrub bitiminde (parmak kalkınca) çalışır ve o ana kadar bir önceki değeri "hesaplanıyor" işaretiyle gösterir.

---

# 53. IMPLEMENTATION NOTES (FLUTTER)

Tasarımcı olmayan geliştiricinin de referans alabileceği teknik ek.

## 53.1 Tema mimarisi

- Token'lar (§4, §5, §5A–5C) tek bir tema tanımında toplanır; widget'lar içinde ham renk/ölçü yazılmaz.
- Üç tema varyantı: `dark` (varsayılan), `nightVision`, `highContrast`. Night Vision, ayrı bir tema nesnesidir — mevcut temaya kırmızı filtre uygulanmaz (filtre yaklaşımı, §31.1'deki ikon/parlaklık kurallarını uygulayamaz).

## 53.2 Sky canvas

- `CustomPainter` + `shouldRepaint` sıkı kontrol.
- Etkileşimli nesneler için `Semantics` düğümleri canvas'ın üzerine bindirilir (§34.2) — bu, painter-only tasarımın en kolay atlanan ve en pahalı geri dönülen kısmıdır, ilk sürümde yapılmalıdır.
- Gesture: pan ve zoom tek `onScaleUpdate` içinde birleşiktir; rotasyon ayrı toggle arkasındadır (§9.2). Timeline scrubber ve sheet, canvas'ın gesture arena'sının dışında ayrı widget'lardır.
- Kenar 20'lik şeritlerde canvas pan başlatılmaz (§9.1) — sistem geri jestine bırakılır.

## 53.3 Durum yönetimi

Konum, zaman, ekipman ve hedef **tek bir uygulama-genel context nesnesinde** tutulur (§7.1). Ekranlar bu nesneyi okur; kendi kopyalarını tutmaz. Context'in her değişimi tek bir yeniden hesaplama zincirini tetikler.

## 53.4 Test edilebilir tasarım kriterleri

Aşağıdakiler otomatik veya yarı otomatik doğrulanabilir olmalıdır:

- Grayscale ekran görüntüsünde tüm status'lar ayırt edilebilir (§31.1)
- Metin kontrast oranları §4.2 tablosundaki değerleri tutar
- 200% Dynamic Type ölçeğinde hiçbir ekran kırılmaz
- Tüm dokunma hedefleri ≥ 44 (saha kontrolleri ≥ 56)
- Time scrub sırasında kare süresi < 16 ms

---

# 54. İLK KURULUM VE VERİ İNDİRME

Yıldız kataloğu, Samanyolu panorama texture'ı ve ufuk profili DEM verisi ciddi boyuttadır. Bu, kurulumdan sonraki ilk deneyimin parçasıdır.

## 54.1 Katmanlı indirme

| Katman | Ne zaman | Boyut (yaklaşık) |
|---|---|---|
| Çekirdek katalog (parlak yıldızlar + Messier) | Uygulamayla birlikte gömülü | küçük |
| Genişletilmiş yıldız kataloğu | İlk açılışta arka planda | orta |
| Samanyolu texture'ı | İlk açılışta arka planda | büyük |
| Ufuk profili DEM'i | Kullanıcı o bölge için isteyince | bölge başına |

Kullanıcı, indirme bitmeden **uygulamayı kullanmaya başlayabilir** — çekirdek katman gömülü olduğu için ilk gökyüzü karesi anında çizilir.

## 54.2 İndirme UI'ı

```text
Gökyüzü verileri hazırlanıyor

Genişletilmiş yıldız kataloğu      ✓
Samanyolu görüntüsü        ▓▓▓▓▓░░░  62%

Kalan 84 MB · yalnızca Wi-Fi

[ Arka planda devam et ]
```

Kurallar: hücresel veride otomatik indirme yapılmaz (ayarlardan açılabilir), indirme kesintiye uğrarsa kaldığı yerden devam eder, indirilen veri boyutu ve temizleme seçeneği Ayarlar → Veri altında görünür (§44).