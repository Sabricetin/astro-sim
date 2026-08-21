# 0.A.6 doğrusallık — 2. deneme (21 Ağustos 2026)

**Sonuç: geçmedi.** Ama protokol ve kurulum doğruydu; tek kusur ışık
kaynağı. Üçüncü denemede yalnızca o değişecek.

Kurulum: pencere ışığı 18:52–18:55, EF-S 18-55 @ 18 mm **f/16**,
ISO 1600, 8 basamak (0.4–3.2 s) **palindrom sırada**, 16 kare.

## Doğru olan her şey

| | |
|---|---|
| Doluluk aralığı | **%9.9 – %82** — hedeflenen %60–90 bölgesi kapsandı |
| Doyma | yok, tepe %82'de durdu |
| En kısa poz | 0.4 s — perde zamanlama sorunu devre dışı |
| Palindrom | çalıştı |

## Palindrom işini yaptı

Çift farkı, iki karenin arasındaki **zaman** farkıyla orantılı çıktı:

| Poz | Çiftin zaman aralığı | Fark |
|---|---|---|
| 3.2 s | 10 sn | +0.9% |
| 2.5 s | 36 sn | −1.8% |
| 1.3 s | 102 sn | −5.3% |
| 0.4 s | 193 sn | **−16.5%** |

Poz süresine değil saate bağlı — yani **ışık**, perde değil. 1. denemedeki
%5.1'lik basamağın kaynağı da büyük olasılıkla buydu.

Ayrıca poz süresi ile dizi ortasına olan zaman farkı arasındaki
korelasyon **−0.012** çıktı: palindrom, ışık kaymasını doğrusalsızlıktan
matematiksel olarak ayırdı. Tasarım çalıştı.

## Neden yine de yetmedi

Işık iki bileşenle bozuldu:

1. **Düzgün düşüş: %3.9/dakika.** Bu düzeltilebilir ve düzeltildi.
2. **Düzensiz oynama: RMS %2.0, tepe %3.2.** Bu düzeltilemez.

Kesin kanıt: ard arda, **10 saniye** arayla çekilen iki 3.2 s karesi
arasında ışık %+0.90 değişmiş — oysa düzgün düşüş o sürede %−0.66
bekletiyordu. Yani 10 saniyede ~%1.5 açıklanamayan oynama var.

Düzeltme sonrası artıklar: ±%3.5, RMS %2.6. Sensörün gerçek
doğrusalsızlığı (beklenen <%1) bu gürültünün altında kalıyor.
**Ölçüm, aranan etkiden daha gürültülü.**

## 3. deneme: ışık kaynağını değiştir

Gündüz ışığı bu iş için uygun değil — güneş açısı, ince bulut, atmosfer
hepsi dakika ölçeğinde oynuyor.

**Çözüm: gece, kapalı odada, tavan LED ampulü.**

### LED uyarısı bu merdivende geçersiz

İlk talimatta "LED kullanma, PWM titrer" yazmıştım. O uyarı merdiven
1/60 s ile başlarken doğruydu. Yeni merdivende **en kısa poz 0.4 s** ve
şebeke dalgalanması 100 Hz:

| Poz | 100 Hz çevrim |
|---|---|
| 0.4 s | 40 |
| 0.5 s | 50 |
| 0.8 s | 80 |
| 1.3 s | 130 |
| 1.6 s | 160 |
| 2 s | 200 |
| 2.5 s | 250 |
| 3.2 s | 320 |

Hepsi **tam sayı çevrim** — dalgalanma tam olarak ortalanıyor. 50 Hz
dalgalanmada da öyle. Titreme artık ölçülemez düzeyde.

### Şartlar

- **Kısılabilir ampul kullanma, dimmer'a dokunma.** PWM asıl orada.
- **Ampulü 10 dakika önce yak.** LED ısındıkça ışığı %5–10 düşer, sonra
  sabitlenir. Sıcak halde çek.
- **Perdeleri kapat.** Dışarıdan sızan gün ışığı bütün işi bozar.
- Işığı beyaz kâğıda vurdur, kâğıdın yansımasını çek.
