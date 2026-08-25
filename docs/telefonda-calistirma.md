# Uygulamayı telefonda çalıştırma

## Önce bir karışıklık: hangi test nerede yapılıyor

| Test | Nerede | Telefon ne işe yarıyor |
|---|---|---|
| A–G bölümleri (`test-plani.md`) | **Bilgisayarda** | — |
| Ufuk **ölçümü** (`ufuk-olcumu.md`) | Sahada | **Eğim ölçer** olarak |

Yani G testlerini şimdiye kadar yaptığın gibi bilgisayarda yapacaksın.
Telefonu ufkunu ölçerken bir alet gibi kullanacaksın — üzerinde bu
uygulama çalışmasına gerek yok.

**Ama** uygulamayı telefona kurmak yine de mantıklı: sahada gece
yarısı, dizüstü açmadan "Vega şu an nerede, pencere ne zaman bitiyor"
diye bakabilmek işe yarar. Aşağısı onun için.

---

## En kolay yol: tarayıcıdan (5 dakika, kurulum yok)

Uygulama web'de de çalışıyor. Bilgisayarda bir kez başlatıyorsun,
telefondan tarayıcıyla açıyorsun. Ne Xcode gerekiyor ne geliştirici
hesabı ne mağaza.

### 1. Telefon ve bilgisayar aynı ağda olsun

İkisi de aynı Wi-Fi'a bağlı olacak. Wi-Fi yoksa telefonun **kişisel
erişim noktasını** aç ve bilgisayarı ona bağla — o da olur.

### 2. Bilgisayarda tek komut

Terminal'i aç ve şunu yaz:

```bash
cd ~/Desktop/Sanal-Uzay
./tools/telefonda-ac.sh
```

İlk seferde 1–2 dakika sürer (derliyor). Sonunda şuna benzer bir şey
yazacak:

```
==> Hazir.

    Telefonun tarayicisinda su adresi ac:

        http://172.20.10.2:8080
```

**Bu adres senin ağına göre değişir**, ekranda yazanı kullan.

### 3. Telefonda aç

Telefonun tarayıcısında (Safari veya Chrome) o adresi yaz. Uygulama
açılacak.

### 4. Ana ekrana ekle (isteğe bağlı, tavsiye ederim)

Böylece uygulama gibi görünür, adres çubuğu kaybolur:

- **iPhone / Safari:** alttaki **paylaş** simgesi → aşağı kaydır →
  **"Ana Ekrana Ekle"**
- **Android / Chrome:** sağ üstteki **⋮** → **"Ana ekrana ekle"**

### 5. Bitince

Terminal'de **Ctrl+C**. Sunucu kapanır.

---

## Bilmen gereken sınırlar

**Bilgisayar açık olmalı.** Uygulama telefona kurulmuyor; bilgisayarda
çalışıyor, telefon sadece görüntülüyor. Bilgisayarı kapatırsan sayfa
çalışmaz.

Sahada dizüstü yanında olmayacaksa bu yol yetmez — aşağıdaki "gerçek
kurulum" bölümüne bak.

**Arayüz artık telefona uyumlu.** 600 piksel altındaki ekranlarda
düzen kendini ayarlıyor: sekmeler simgeye dönüyor, üstteki durum kutusu
gizleniyor (dikey alan gökyüzüne kalsın diye), hedef ve konum seçiciler
alt alta geçiyor, alt panel kaydırılabiliyor.

Beş ekran genişliğinde (320 / 390 / 430 / 740 / 1024) otomatik taşma
testi var; her değişiklikte çalışıyor.

**İlk açılış yavaş.** 30 MB indiriyor. Sonrasında tarayıcı önbelleğe
alır, hızlanır.

---

## Gerçek kurulum (dizüstü olmadan çalışsın istiyorsan)

Bu, yukarıdakinden **belirgin şekilde zahmetli**. Sahada bilgisayar
yanında olmayacaksa gerekli.

### Android ise — kolay taraf

Telefonu USB ile bağla, telefonda **Geliştirici Seçenekleri → USB hata
ayıklama**'yı aç, sonra:

```bash
cd ~/Desktop/Sanal-Uzay/apps/app
flutter devices          # telefon listede görünmeli
flutter install
```

Uygulama telefona kurulur ve orada kalır. Bilgisayar gerekmez.

Alternatif — kurulum dosyası üretip elle yüklemek:

```bash
flutter build apk --release
# çıktı: build/app/outputs/flutter-apk/app-release.apk
```

Bu dosyayı telefona at ve dokun. Android "bilinmeyen kaynak" uyarısı
verir, izin vermen gerekir.

### iPhone ise — zahmetli taraf

Apple imzasız uygulama çalıştırmıyor. Gerekenler:

1. **Xcode** (App Store'dan, ~10 GB, uzun sürer)
2. Apple kimliğinle **ücretsiz geliştirici hesabı** yeterli
3. Telefonu USB ile bağla:

```bash
cd ~/Desktop/Sanal-Uzay/apps/app
open ios/Runner.xcworkspace
```

Xcode'da: **Runner → Signing & Capabilities → Team** kısmından Apple
kimliğini seç. Sonra üstten telefonunu seçip **▶** düğmesine bas.

İlk seferde telefonda **Ayarlar → Genel → VPN ve Cihaz Yönetimi**'nden
geliştiriciye güvenmen istenir.

**Ücretsiz hesabın kısıtı:** uygulama **7 günde bir** yeniden
yüklenmeli. Kalıcı olması için yıllık Apple Developer üyeliği (99 USD)
gerekiyor.

---

## Hangisini seçmeli

| Durum | Yol |
|---|---|
| Sadece bakmak, denemek | **Tarayıcı** — 5 dakika |
| Sahada dizüstü yanında | **Tarayıcı** — yeterli |
| Sahada dizüstü yok, Android | **`flutter install`** — kolay |
| Sahada dizüstü yok, iPhone | **Xcode** — bir akşam ayır |

Benim önerim: **şimdilik tarayıcı.** Uygulama hâlâ gelişiyor ve
tarayıcı yolu her değişiklikten sonra tek komutla güncelleniyor. Eylül
çekimine yakın, arayüz oturduğunda gerçek kurulumu yaparız.
