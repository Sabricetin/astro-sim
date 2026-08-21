#!/usr/bin/env python3
"""
FAZ 0.A — Sensor karakterizasyonu: foton transfer egrisi (PTC).

Bias + flat karelerinden olcer:
  - kazanc            g  [e-/ADU]
  - okuma gurultusu   sigma_read [e-]
  - dolum kapasitesi  [e-]  (doyum seviyesinden turetilir)
  - dogrusallik sapmasi [%]

Yontem
------
Iki flat kare F1, F2 ayni pozlama seviyesinde cekilir.
  sinyal   S   = ortalama(F1 - master_bias)                     [ADU]
  varyans  V   = varyans(F1 - F2) / 2                           [ADU^2]
  (fark almak sabit desen gurultusunu ve bias'i eler; /2 fark
   isleminin varyansi ikiye katlamasini geri alir)

Poisson istatistigi:  V = S/g + sigma_read_adu^2
  => V-S grafiginin egimi = 1/g   ==>  g = 1/egim
  => kesim noktasi = sigma_read_adu^2

Onemli: hesap TEK CFA kanali uzerinde yapilir. Demosaic YOK,
beyaz ayari YOK, ton egrisi YOK. Aksi halde komsu pikseller
korelasyonlu hale gelir ve varyans yalan soyler.

Kullanim
--------
  python tools/sensor_ptc.py \
      --bias  data/faz0/bias \
      --flats data/faz0/flats \
      --channel G1 \
      --out    data/faz0/sonuc

Cikti: <out>.json  (versiyonlanabilir sonuc)  ve  <out>.png (grafik)
"""

from __future__ import annotations

import argparse
from datetime import datetime
import json
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass, asdict
from pathlib import Path

import numpy as np

try:
    import rawpy
except ImportError:
    sys.exit("rawpy kurulu degil.  ./.venv/bin/pip install rawpy")

RAW_EXT = {
    ".cr2", ".cr3", ".crw",   # Canon
    ".nef", ".nrw",           # Nikon
    ".arw", ".srf", ".sr2",   # Sony
    ".raf",                   # Fujifilm
    ".orf",                   # Olympus / OM
    ".rw2",                   # Panasonic
    ".pef", ".dng",           # Pentax / Adobe / telefon
    ".raw", ".rwl", ".iiq",
}

# rawpy renk indeksleri (color_desc genelde b'RGBG')
CHANNEL_INDEX = {"R": 0, "G1": 1, "B": 2, "G2": 3}

# PTC dogrusunun uydurulacagi araligi, doyum orani cinsinden.
# Alt sinir: okuma gurultusunun bogdugu bolgeyi disla.
# Ust sinir: doyuma yaklasan dogrusal olmayan bolgeyi disla.
FIT_LO = 0.03
FIT_HI = 0.65


# --------------------------------------------------------------------------
# RAW okuma
# --------------------------------------------------------------------------

@dataclass
class Frame:
    path: Path
    iso: int | None
    exposure: float | None   # saniye
    taken_at: float | None = None   # unix zaman, kaymayi olcmek icin


def raw_files(folder: Path) -> list[Path]:
    return sorted(p for p in folder.iterdir() if p.suffix.lower() in RAW_EXT)


def read_metadata(paths: list[Path]) -> list[Frame]:
    """exiftool ile ISO ve pozlama suresini toplu oku."""
    if not paths:
        return []
    cmd = ["exiftool", "-j", "-n", "-ISO", "-ExposureTime", "-ShutterSpeedValue", "-CreateDate",
           *[str(p) for p in paths]]
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, check=True).stdout
        meta = {Path(d["SourceFile"]).name: d for d in json.loads(out)}
    except (subprocess.CalledProcessError, FileNotFoundError, json.JSONDecodeError) as e:
        print(f"  ! exiftool okunamadi ({e}); dosyalar sirayla eslestirilecek")
        meta = {}

    frames = []
    for p in paths:
        d = meta.get(p.name, {})
        iso = d.get("ISO")
        # EXIF ExposureTime GOSTERILEN degerdir ve yuvarlanmistir: makine
        # "0.4 s" yazar ama gercekte 0.3856 s poz verir (1/3 durak serisi
        # 2^(-4/3)). ShutterSpeedValue APEX'ten turer ve gercege yakindir.
        #
        # Fark buyuk: 0.4 ve 0.8 icin -%3.6, 2.5 icin +%3.75. Dogrusallik
        # testi tam da bu buyuklukteki sapmalari aradigi icin yuvarlanmis
        # degeri kullanmak testi anlamsiz kiliyordu — 0.A.6'nin ucuncu
        # denemesinde artik RMS'i %3.02'den %1.88'e dusuren duzeltme bu.
        #
        # Kazanc olcumu etkilenmez (kazanc poz suresini bilmeyi
        # gerektirmez); yalnizca dogrusallik ve sinyal-zaman iliskisi
        # etkilenir.
        exp = d.get("ShutterSpeedValue") or d.get("ExposureTime")
        taken = d.get("CreateDate")
        ts = None
        if taken:
            try:
                ts = datetime.strptime(taken, "%Y:%m:%d %H:%M:%S").timestamp()
            except ValueError:
                ts = None
        frames.append(Frame(p, int(iso) if iso else None,
                            float(exp) if exp else None, ts))
    return frames


def channel_offsets(raw, channel: str) -> tuple[int, int]:
    """CFA deseninde istenen kanalin (y, x) baslangic ofseti."""
    want = CHANNEL_INDEX[channel]
    pattern = np.asarray(raw.raw_pattern)
    hits = np.argwhere(pattern == want)
    if len(hits) == 0 and channel == "G2":
        hits = np.argwhere(pattern == CHANNEL_INDEX["G1"])  # tek yesilli desen
        if len(hits):
            print("  ! Bu sensorde ayri G2 yok, G1 kullaniliyor")
    if len(hits) == 0:
        raise SystemExit(
            f"'{channel}' kanali CFA deseninde bulunamadi. "
            f"raw_pattern={pattern.tolist()}, color_desc={raw.color_desc!r}"
        )
    y, x = hits[0]
    return int(y), int(x)


def load_plane(path: Path, channel: str, roi: int) -> tuple[np.ndarray, dict]:
    """Tek CFA kanalini, merkezden roi x roi kirpilmis halde float64 dondur."""
    with rawpy.imread(str(path)) as raw:
        cfa = raw.raw_image_visible
        oy, ox = channel_offsets(raw, channel)
        info = {
            "white_level": int(raw.white_level),
            "black_level": float(np.mean(raw.black_level_per_channel)),
            "color_desc": raw.color_desc.decode(errors="replace"),
            "raw_pattern": np.asarray(raw.raw_pattern).tolist(),
        }
        plane = cfa[oy::2, ox::2].astype(np.float64)

    h, w = plane.shape
    if roi > 0:
        half = min(roi, h, w) // 2
        cy, cx = h // 2, w // 2
        plane = plane[cy - half:cy + half, cx - half:cx + half]
    return plane, info


# --------------------------------------------------------------------------
# Olcumler
# --------------------------------------------------------------------------

def analyse_bias(frames: list[Frame], channel: str, roi: int):
    if len(frames) < 2:
        raise SystemExit("En az 2 bias karesi gerekli (20+ onerilir).")

    planes, info = [], None
    for f in frames:
        p, info = load_plane(f.path, channel, roi)
        planes.append(p)

    stack = np.stack(planes)
    master = np.median(stack, axis=0)

    # Okuma gurultusu: ardisik ciftlerin farkindan, /sqrt(2) ile tek kareye indir.
    sigmas = [float(np.std(planes[i] - planes[i + 1]) / np.sqrt(2))
              for i in range(len(planes) - 1)]
    read_adu = float(np.median(sigmas))
    offset = float(np.mean(master))

    return master, read_adu, offset, info


def group_flats(frames: list[Frame]) -> dict:
    """Ayni ISO + pozlama suresindeki kareleri grupla."""
    groups: dict[tuple, list[Frame]] = defaultdict(list)
    for i, f in enumerate(frames):
        key = (f.iso, f.exposure) if f.exposure is not None else ("seq", i // 2)
        groups[key].append(f)
    return groups


def build_ptc(groups: dict, master_bias: np.ndarray, channel: str, roi: int):
    points = []
    for key, frames in sorted(groups.items(), key=lambda kv: str(kv[0])):
        if len(frames) < 2:
            print(f"  ! {key}: tek kare, atlandi (seviye basina 2 kare gerekli)")
            continue

        p1, _ = load_plane(frames[0].path, channel, roi)
        p2, _ = load_plane(frames[1].path, channel, roi)
        if p1.shape != p2.shape:
            print(f"  ! {key}: kare boyutlari farkli, atlandi")
            continue

        signal = float(np.mean(p1 - master_bias))
        variance = float(np.var(p1 - p2) / 2.0)
        # Tek tek kareler de saklaniyor: dogrusallik icin kaymayi
        # olcmek gerekiyor ve kayma bilgisi ciftin ICINDEKI farkta.
        # Cifti tek noktaya indirip ortalama zamani almak, palindromda
        # tam olarak bu bilgiyi yok eder.
        per_frame = [
            {"signal_adu": float(np.mean(pl - master_bias)),
             "taken_at": f.taken_at}
            for pl, f in ((p1, frames[0]), (p2, frames[1]))
        ]
        points.append({
            "iso": frames[0].iso,
            "exposure_s": frames[0].exposure,
            "taken_at": (
                sum(f.taken_at for f in frames[:2]) / 2
                if all(f.taken_at is not None for f in frames[:2]) else None
            ),
            "signal_adu": signal,
            "per_frame": per_frame,
            "variance_adu2": variance,
            "n_frames": len(frames),
        })
    return points


def fit_ptc(points: list[dict], full_scale: float):
    lo, hi = FIT_LO * full_scale, FIT_HI * full_scale
    used = [p for p in points if lo <= p["signal_adu"] <= hi]
    if len(used) < 3:
        raise SystemExit(
            f"Dogru uydurmak icin yetersiz nokta ({len(used)}). "
            f"{lo:.0f}-{hi:.0f} ADU araliginda en az 3 pozlama seviyesi gerekiyor.\n"
            f"  Ipucu: pozlama merdivenini karanliktan doyuma kadar 8-12 basamak yay."
        )

    s = np.array([p["signal_adu"] for p in used])
    v = np.array([p["variance_adu2"] for p in used])
    slope, intercept = np.polyfit(s, v, 1)

    if slope <= 0:
        raise SystemExit(
            "PTC egimi pozitif degil — olcum bozuk.\n"
            "  En sik neden: isik kaynagi PWM ile kisilmis (LED titremesi) "
            "veya flat kareler ayni seviyede degil."
        )

    resid = v - (slope * s + intercept)
    r2 = 1.0 - float(np.sum(resid ** 2) / np.sum((v - v.mean()) ** 2))
    return float(slope), float(intercept), r2, used


def check_linearity(points: list[dict], full_scale: float):
    """Sinyal-pozlama suresi dogrusalligi; kirilma noktasi gercek dolum sinirin."""
    pts = [p for p in points if p["exposure_s"] and p["signal_adu"] > 0]
    if len(pts) < 4:
        return None
    pts.sort(key=lambda p: p["exposure_s"])
    t = np.array([p["exposure_s"] for p in pts])
    s = np.array([p["signal_adu"] for p in pts])

    mask = s <= FIT_HI * full_scale
    if mask.sum() < 3:
        return None
    # Bias cikarildiktan sonra sinyal poz suresiyle DOGRU ORANTILI olmali:
    # s = k*t, kesim yok. Bu yuzden orijinden gecen en kucuk kareler.
    # (Kesimli polyfit'in egimini alip orijinden tahmin uretmek tutarsizdir.)
    k = float(np.sum(s[mask] * t[mask]) / np.sum(t[mask] ** 2))
    predicted = k * t
    dev = (s - predicted) / np.maximum(predicted, 1.0) * 100.0

    # Isik kaymasi duzeltmesi.
    #
    # Kaynak kararsizsa (pencere isigi, isinan LED) sinyal hem poz
    # suresine hem SAATE bagli olur. Merdiven palindrom sirada
    # cekildiyse (cik-in) poz suresi dizinin ortasina gore simetriktir,
    # yani zamana bagli terim (tek fonksiyon) dogrusalsizliktan (cift
    # fonksiyon) ayrilabilir.
    #
    # Cift ortalamasi degil TEK TEK kareler kullanilir: palindromda her
    # ciftin iki karesi dizinin iki ucuna duser, kayma bilgisi tam da o
    # farkta durur. Ortalama alinirsa bilgi yok olur.
    drift_pct_per_min = None
    dev_corrected = None
    ft, fs, ftime = [], [], []
    for p in pts:
        for fr in p.get("per_frame") or []:
            if fr.get("taken_at") is None:
                continue
            ft.append(p["exposure_s"]); fs.append(fr["signal_adu"])
            ftime.append(fr["taken_at"] + p["exposure_s"] / 2.0)
    if len(ft) >= 6:
        ft = np.array(ft); fs = np.array(fs); ftime = np.array(ftime)
        fmask = fs <= FIT_HI * full_scale
        if fmask.sum() >= 5:
            dT = ftime - ftime[fmask].mean()
            # Poz suresi ile zaman farki arasindaki korelasyon kucukse
            # ayristirma gecerli. Buyukse merdiven tek yonlu cekilmis
            # demektir ve duzeltme dogrusalsizligi de yer.
            corr = float(np.corrcoef(ft[fmask], dT[fmask])[0, 1])
            if abs(corr) < 0.35:
                from scipy.optimize import least_squares
                k0 = float(np.sum(fs[fmask] * ft[fmask]) / np.sum(ft[fmask] ** 2))

                def _resid(par):
                    kk, cc = par
                    return fs[fmask] - kk * ft[fmask] * (1 + cc * dT[fmask])

                kk, cc = least_squares(_resid, [k0, 0.0]).x
                pred_c = kk * ft * (1 + cc * dT)
                dev_corrected = (fs - pred_c) / np.maximum(pred_c, 1.0) * 100.0
                dev_corrected = dev_corrected[fmask]
                drift_pct_per_min = float(cc * 60 * 100)

    # Isik kararsizsa bu test dogrusalligi degil isigi olcer. Kaba gosterge:
    # ardisik seviyeler arasi s/t oraninin yayilimi.
    ratio = s[mask] / t[mask]
    light_spread = float((ratio.max() - ratio.min()) / ratio.mean() * 100.0)

    return {
        "max_deviation_pct": float(np.max(np.abs(dev[mask]))),
        "max_deviation_pct_drift_corrected": (
            None if dev_corrected is None
            else float(np.max(np.abs(dev_corrected)))
        ),
        "rms_deviation_pct_drift_corrected": (
            None if dev_corrected is None
            else float(np.sqrt(np.mean(dev_corrected ** 2)))
        ),
        "light_drift_pct_per_min": drift_pct_per_min,
        "light_spread_pct": light_spread,
        "per_point": [
            {"exposure_s": float(ti), "signal_adu": float(si),
             "deviation_pct": float(di)}
            for ti, si, di in zip(t, s, dev)
        ],
    }


# --------------------------------------------------------------------------
# Grafik
# --------------------------------------------------------------------------

def plot(points, used, slope, intercept, gain, out_png: Path):
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        print("  ! matplotlib yok, grafik atlandi")
        return

    s_all = [p["signal_adu"] for p in points]
    v_all = [p["variance_adu2"] for p in points]
    s_fit = np.array([p["signal_adu"] for p in used])

    fig, ax = plt.subplots(figsize=(7, 5))
    ax.scatter(s_all, v_all, s=28, label="tum olcumler", color="#9aa0a6")
    ax.scatter(s_fit, [p["variance_adu2"] for p in used], s=34,
               label="uydurmada kullanilan", color="#1a73e8")
    xs = np.linspace(0, max(s_all) * 1.02, 100)
    ax.plot(xs, slope * xs + intercept, "--", color="#d93025",
            label=f"uydurma: g = {gain:.3f} e-/ADU")
    ax.set_xlabel("Sinyal  [ADU]")
    ax.set_ylabel("Varyans  [ADU$^2$]")
    ax.set_title("Foton transfer egrisi")
    ax.legend()
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(out_png, dpi=140)
    print(f"  grafik: {out_png}")


# --------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(
        description="FAZ 0.A — kazanc ve okuma gurultusu olcumu")
    ap.add_argument("--bias", required=True, type=Path, help="bias kareleri klasoru")
    ap.add_argument("--flats", required=True, type=Path, help="flat kareleri klasoru")
    ap.add_argument("--channel", default="G1", choices=list(CHANNEL_INDEX),
                    help="CFA kanali (varsayilan G1 — V bandina en yakin)")
    ap.add_argument("--roi", type=int, default=400,
                    help="merkezden kirpilacak kare boyut, 0 = tum kare")
    ap.add_argument("--iso", type=int, default=None, help="sadece bu ISO'yu isle")
    ap.add_argument("--out", type=Path, default=Path("data/faz0/sonuc"))
    args = ap.parse_args()

    for d in (args.bias, args.flats):
        if not d.is_dir():
            sys.exit(f"Klasor yok: {d}")

    print(f"kanal: {args.channel}   ROI: {args.roi or 'tum kare'}")

    bias_frames = read_metadata(raw_files(args.bias))
    flat_frames = read_metadata(raw_files(args.flats))
    if args.iso:
        bias_frames = [f for f in bias_frames if f.iso == args.iso]
        flat_frames = [f for f in flat_frames if f.iso == args.iso]
    if not bias_frames:
        sys.exit(f"{args.bias} icinde RAW bias karesi yok")
    if not flat_frames:
        sys.exit(f"{args.flats} icinde RAW flat karesi yok")

    # Kazanc ve okuma gurultusu ISO'ya gore degisir. Farkli ISO'lari tek
    # hesapta karistirmak sessizce yanlis sonuc uretir — burada durdur.
    isos = {f.iso for f in bias_frames + flat_frames if f.iso is not None}
    if len(isos) > 1:
        sys.exit(
            f"Birden fazla ISO bulundu: {sorted(isos)}\n"
            f"  Kazanc ISO'ya baglidir; karistirilamaz.\n"
            f"  Her ISO icin ayri calistir:  --iso {sorted(isos)[0]}"
        )

    print(f"\n[1/4] bias: {len(bias_frames)} kare")
    master_bias, read_adu, offset, info = analyse_bias(bias_frames, args.channel, args.roi)
    full_scale = info["white_level"] - info["black_level"]
    print(f"      CFA {info['color_desc']} {info['raw_pattern']}  "
          f"beyaz={info['white_level']}  siyah={info['black_level']:.0f}")
    print(f"      offset = {offset:.1f} ADU   okuma gurultusu = {read_adu:.2f} ADU")

    print(f"\n[2/4] flat: {len(flat_frames)} kare")
    groups = group_flats(flat_frames)
    print(f"      {len(groups)} pozlama seviyesi")
    points = build_ptc(groups, master_bias, args.channel, args.roi)
    print(f"      {len(points)} gecerli seviye (cift kare)")

    print("\n[3/4] dogru uydurma")
    slope, intercept, r2, used = fit_ptc(points, full_scale)
    gain = 1.0 / slope
    read_e = read_adu * gain
    read_e_from_fit = float(np.sqrt(max(intercept, 0.0))) * gain
    full_well = full_scale * gain

    lin = check_linearity(points, full_scale)

    print("\n[4/4] SONUC")
    print(f"  kazanc              g = {gain:.4f} e-/ADU")
    print(f"  okuma gurultusu       = {read_e:.2f} e-   <- BUNU KULLAN (bias'tan)")
    print(f"                        ~ {read_e_from_fit:.2f} e-   (PTC kesimi, kaba capraz kontrol)")
    print(f"  dolum kapasitesi      = {full_well:,.0f} e-")
    print(f"  uydurma kalitesi   R^2 = {r2:.4f}   ({len(used)} nokta)")
    if lin:
        print(f"  dogrusallik sapmasi   = {lin['max_deviation_pct']:.2f} %  (ham, maks)")
        if lin.get("max_deviation_pct_drift_corrected") is not None:
            print(f"                        = "
                  f"{lin['max_deviation_pct_drift_corrected']:.2f} %  "
                  f"(isik kaymasi duzeltilmis, maks)   <- BUNU KULLAN")
            print(f"                        = "
                  f"{lin['rms_deviation_pct_drift_corrected']:.2f} %  (RMS)")
            print(f"  isik kaymasi          = "
                  f"{lin['light_drift_pct_per_min']:+.2f} %/dakika")
        print(f"  isik kararliligi      = {lin['light_spread_pct']:.1f} % yayilim "
              f"(sinyal/poz orani)")

    warn = []
    if r2 < 0.98:
        warn.append("R^2 < 0.98 — isik kaynagi kararsiz olabilir (LED PWM titremesi?)")
    # PTC kesimi zayif bir tahmindir (binlerce ADU^2'lik veriden ~birkac ADU^2
    # ekstrapole edilir), sentetik veride bile %10-15 sapar. Sadece buyuk
    # ayrisma anlamlidir: o zaman bias kareleri isik sizdirmis demektir.
    # Kesim, veriden neredeyse hic belirlenemez: tipik artik RMS, beklenen
    # kesimle ayni buyuklukte. Bu yuzden DUSUK/negatif kesim normaldir ve
    # uyari uretmez. Sadece kesimin bias olcumunun cok USTUNDE olmasi
    # anlamlidir — o zaman flat'larda gercek fazla gurultu var demektir.
    if read_e_from_fit > 1.6 * max(read_e, 1e-9):
        warn.append("PTC kesimi bias olcumunun cok ustunde — flat'larda fazla "
                    "gurultu var (isik titriyor olabilir)")
    if lin and lin["light_spread_pct"] > 10.0:
        warn.append(
            f"isik kaynagi kararsiz (sinyal/poz orani %{lin['light_spread_pct']:.0f} "
            f"yayiliyor) — DOGRUSALLIK SONUCU GECERSIZ. Kazanc ve okuma gurultusu "
            f"etkilenmez (ikisi de poz suresine bagli degildir).")
    elif lin:
        # Kayma duzeltilmisse karar ONA gore verilir; ham deger kaynagin
        # kararsizligini da icerir ve sensoru haksiz yere sucalar.
        d = lin.get("max_deviation_pct_drift_corrected")
        if d is None:
            if lin["max_deviation_pct"] > 2.0:
                warn.append("dogrusallik sapmasi %2'nin ustunde — merdiveni "
                            "PALINDROM sirada cek (cik-in) ki isik kaymasi "
                            "dogrusalsizliktan ayrilabilsin")
        elif d > 2.0:
            warn.append(f"kayma duzeltildikten sonra bile sapma %{d:.1f} — "
                        f"artik gurultu kaynagin kisa surel oynakligindan; "
                        f"daha kararli isik gerekli")
    for w in warn:
        print(f"  ! {w}")

    result = {
        "faz": "0.A",
        "kanal": args.channel,
        "roi": args.roi,
        "iso": args.iso or (bias_frames[0].iso if bias_frames else None),
        "sensor": info,
        "gain_e_per_adu": gain,
        "read_noise_e_from_bias": read_e,
        "read_noise_e_from_ptc": read_e_from_fit,
        "read_noise_adu": read_adu,
        "bias_offset_adu": offset,
        "full_well_e": full_well,
        "ptc_slope": slope,
        "ptc_intercept": intercept,
        "ptc_r2": r2,
        "linearity": lin,
        "points": points,
        "warnings": warn,
    }

    args.out.parent.mkdir(parents=True, exist_ok=True)
    json_path = args.out.with_suffix(".json")
    json_path.write_text(json.dumps(result, indent=2, ensure_ascii=False))
    print(f"\n  sonuc: {json_path}")
    plot(points, used, slope, intercept, gain, args.out.with_suffix(".png"))

    print("\n  Cikis kriteri: bu degerleri photonstophotos.net'teki ayni govde "
          "olcumleriyle karsilastir. %20 icinde olmali.")


if __name__ == "__main__":
    main()
