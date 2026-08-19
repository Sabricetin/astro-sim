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

Ana arka plan tamamen saf siyah olmak zorunda değil.

Önerilen yaklaşım:

```text
Background Primary:
Very deep blue-black

Background Secondary:
Slightly elevated dark surface

Surface:
Subtle dark graphite / midnight

Primary Text:
Soft white

Secondary Text:
Cool gray

Tertiary Text:
Muted blue-gray
```

Accent renkleri sadece bilgi anlamı taşımalıdır.

Örnek:

```text
Blue / Cyan
Navigation, coordinates, neutral scientific data

Warm Gold
Moon, exposure warnings, recommended values

Green
Good shooting conditions

Orange
Warning / degraded conditions

Red
Critical problems
```

Gradient kullanımını minimumda tut.

Gökyüzü render alanında doğal gradient kullanılabilir.

UI elemanlarında gereksiz gradient kullanma.

---

# 5. TYPOGRAPHY

Premium, modern, son derece okunabilir bir tipografi sistemi oluştur.

Font tercihi:

- iOS: SF Pro
- Android/Web: Inter veya sistem fontu

Hiyerarşi:

### Display

Büyük sonuçlar:

```text
SNR 8.4
02:10 – 04:35
23° Altitude
45s
```

### Headline

```text
Best shooting window
Sky conditions
Exposure simulation
```

### Body

Kısa açıklamalar.

### Data Label

```text
ISO
ALT
AZ
MOON
BORTLE
SNR
FOV
```

Veri etiketleri küçük, ancak okunabilir olmalıdır.

Bilimsel his için bazı teknik veri etiketlerinde:

- Slight letter spacing
- Uppercase
- Monospaced numerals

kullanılabilir.

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

Ana navigasyon:

```text
Explore
Plan
Camera
Reports
Library
```

Mobile için 5 tab kullanılabilir.

Alternatif olarak ana ürün odağı için:

```text
Sky
Plan
Capture
Report
More
```

Önerilen yapı:

### 1. SKY

Canlı gökyüzü simülasyonu.

### 2. PLAN

Tarih, saat, konum ve hedef planlama.

### 3. CAMERA

Kamera, lens ve exposure ayarları.

### 4. REPORT

Radyometri, SNR ve çekim sonucu.

### 5. LIBRARY

Presetler, kayıtlı planlar ve ayarlar.

---

# 8. ANA EKRAN — SKY SIMULATION

Bu uygulamanın en önemli ekranlarından biridir.

Ekranın yaklaşık %60–70'i gökyüzü olmalıdır.

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

## Main target card

Bottom sheet veya floating card:

```text
Galactic Center

Altitude
23°

Azimuth
182°

Visible for
2h 14m

Best window
01:20 – 03:40
```

Kart dokunulduğunda detaylı analize açılmalıdır.

---

# 9. SKY SCREEN INTERACTIONS

Kullanıcı:

### Drag

Gökyüzüne bakış yönünü değiştirir.

### Pinch

Zoom.

### Two finger rotation

View rotation.

### Tap object

Nesne detayını açar.

Örnek:

```text
M42
Orion Nebula

Magnitude 4.0
Altitude 38°
Visible for 5h 12m
```

Hedef seçildiğinde arayüz odağı hedefe kaymalıdır.

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

Kullanıcı zamanı kaydırdığında gökyüzü anlık güncellenmelidir.

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

★★★★☆

Good conditions

SNR
8.4

Star trailing
Low

Sky background
Moderate

Clipping
0.3%
```

Ancak yıldız puanı tek başına karar mekanizması olmamalıdır.

Kullanıcı puana dokunduğunda:

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

[ Start Exploring ]

Onboarding'de uzun teknik açıklamalar yapma.

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

- Arayüz kırmızı tonlara geçebilir
- Parlak beyazlar azaltılır
- Ekran göz adaptasyonunu mümkün olduğunca az bozar

Ancak bu mod varsayılan tema olmamalıdır.

Kullanıcı tarafından açılmalıdır.

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

- Timeline
- Altitude graph
- Histogram
- SNR scale
- Horizon profile
- Sky map
- FOV frame

## Status

- Excellent
- Good
- Moderate
- Poor
- Critical

Her durum için sadece renk değil:

- Icon
- Text
- Visual hierarchy

kullan.

Accessibility için renk tek başına anlam taşımasın.

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

Tüm platformlarda aynı design language korunmalı.

---

# 34. ACCESSIBILITY

Uygulama:

- Dynamic text
- High contrast
- Color-independent warnings
- Large touch targets
- Screen reader labels

desteklemelidir.

Gece modu ile accessibility modu birbirinden ayrı düşünülmelidir.

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

Temel kullanıcı yolculuğu:

```text
Open App
    ↓
Select Location
    ↓
Select Date / Time
    ↓
Select Target
    ↓
Select Camera + Lens
    ↓
View Sky Simulation
    ↓
Check Best Shooting Window
    ↓
Set Exposure
    ↓
Analyze Result
    ↓
Read SNR / Background / Trailing
    ↓
Adjust Settings
    ↓
Find Best Configuration
    ↓
Save Plan
```

Bu akış mümkün olduğunca kesintisiz olmalıdır.

Kullanıcı her adımda ayrı ayrı sayfa dolduruyormuş gibi hissetmemelidir.

---

# 37. ANA ÜRÜN EKRANI — ÖNERİLEN KOMPOZİSYON

Uygulamanın ana ekranında ideal yapı:

```text
┌──────────────────────────────────┐
│ Istanbul              02:14      │
│ Astronomical Darkness            │
│                                  │
│                                  │
│                                  │
│          SKY SIMULATION          │
│                                  │
│       ✦        ✧        ✦        │
│              TARGET              │
│                                  │
│                                  │
├──────────────────────────────────┤
│ Galactic Center                  │
│                                  │
│ 23° ALT      SNR 4.2      18s    │
│                                  │
│ Best Window                      │
│ 01:20 ━━━━━━━━━━━ 03:40          │
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