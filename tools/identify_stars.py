#!/usr/bin/env python3
"""Karedeki yildizlari BSC5 kataloguyla eslestirir.

Neden gerekli: fotometri bir yildizin kac ADU verdigini soyler, ama
sifir noktasi icin o yildizin GERCEK kadiri lazim. "Kullanici Vega'yi
ortaladi" varsayimi Vega doydugunda cokuyor — o zaman baska bir yildiz
olculuyor ve kimligi bilinmiyor.

Bu bir sifirdan plate solve DEGIL. Aracin elinde zaten cok sey var:
nereye bakildigi (hedef), ne zaman (EXIF), nereden (konum), hangi
olcekte (odak + piksel adimi). Bilinmeyen tek sey **donme acisi** ve
merkezin birkac derecelik kaymasi. Bu, aranacak alani kucuk ve
cozumu hizli kiliyor.

Kullanim:
    python tools/identify_stars.py <kare.CR2> \\
        --ra 279.235 --dec 38.784 \\
        --focal 14 --pixel-pitch 3.72
"""
from __future__ import annotations

import argparse
import json
import subprocess
from dataclasses import dataclass
from pathlib import Path

import numpy as np

import sys
sys.path.insert(0, str(Path(__file__).parent))
import bsc5
import starphot as sp
from sensor_ptc import load_plane


def gnomonic(ra_deg, dec_deg, ra0_deg, dec0_deg):
    """Gnomonik (merkezi) izdusum. Donen degerler DERECE.

    Normal (rectilinear) lensin gercek davranisi bu — projenin FOV
    hesabiyla ayni matematik.
    """
    ra = np.radians(ra_deg)
    dec = np.radians(dec_deg)
    ra0 = np.radians(ra0_deg)
    dec0 = np.radians(dec0_deg)
    cosc = (np.sin(dec0) * np.sin(dec)
            + np.cos(dec0) * np.cos(dec) * np.cos(ra - ra0))
    # Arka yarikure: izdusum tanimsiz.
    ok = cosc > 1e-6
    xi = np.where(ok, np.cos(dec) * np.sin(ra - ra0) / np.where(ok, cosc, 1), np.nan)
    eta = np.where(
        ok,
        (np.cos(dec0) * np.sin(dec)
         - np.sin(dec0) * np.cos(dec) * np.cos(ra - ra0)) / np.where(ok, cosc, 1),
        np.nan,
    )
    return np.degrees(xi), np.degrees(eta)


@dataclass
class Solution:
    ra0: float
    dec0: float
    roll_deg: float
    parity: int          # +1 veya -1 (ayna)
    scale_deg_per_px: float
    matches: list        # (detected_index, catalog_index, ayrim_px)
    rms_px: float

    @property
    def match_count(self) -> int:
        return len(self.matches)


def project_to_pixels(cat, ra0, dec0, roll_deg, parity, scale, cx, cy):
    xi, eta = gnomonic(cat.ra_deg, cat.dec_deg, ra0, dec0)
    r = np.radians(roll_deg)
    # parity: goruntunun aynalanmis olup olmadigi. Kamerada dogu genelde
    # SOLDA kalir; hangi yonde oldugu okuma sirasina bagli, o yuzden
    # ikisi de deneniyor.
    x = (xi * np.cos(r) + eta * np.sin(r)) * parity
    y = (-xi * np.sin(r) + eta * np.cos(r))
    return cx + x / scale, cy + y / scale


def score(detected_xy, pred_x, pred_y, tol_px):
    """Her algilanan yildiza en yakin katalog yildizi; tolerans icinde
    olanlar eslesme sayilir."""
    matches = []
    used = set()
    for i, (dx, dy) in enumerate(detected_xy):
        d = np.hypot(pred_x - dx, pred_y - dy)
        d = np.where(np.isnan(d), np.inf, d)
        order = np.argsort(d)
        for j in order[:3]:
            if d[j] > tol_px:
                break
            if j in used:
                continue
            matches.append((i, int(j), float(d[j])))
            used.add(int(j))
            break
    return matches


def angular_separation(ra1, dec1, ra2, dec2):
    """Iki yon arasindaki aci, derece. Haversine — kucuk acilarda da
    sayisal olarak kararli."""
    r1, d1, r2, d2 = map(np.radians, (ra1, dec1, ra2, dec2))
    dr, dd = r2 - r1, d2 - d1
    a = np.sin(dd / 2) ** 2 + np.cos(d1) * np.cos(d2) * np.sin(dr / 2) ** 2
    return np.degrees(2 * np.arcsin(np.sqrt(np.clip(a, 0, 1))))


def solve(detected_xy, cat, ra0, dec0, scale, cx, cy,
          tol_px=6.0, roll_step=1.0, brightest=9, pair_stars=120,
          verbose=False):
    """Merkezi ve donmeyi YILDIZ CIFTLERININ ARALIKLARINDAN bulur.

    Onceki surum yalnizca donme acisini tariyordu ve merkez tahmininin
    dogru olmasina guveniyordu. Olculdu: **1 derecelik sapma tanimayi
    tamamen cokertiyor** — cunku 1 derece 42 piksel eder, tolerans ise
    6 piksel. Elle nisan alan bir kullanici 5-10 derece rahat sasar.

    Yeni yol merkez tahminine bagli degil: iki yildiz arasindaki ACISAL
    ARALIK, kadrajin nereye baktigindan ve nasil dondugunden bagimsizdir.
    Olcek zaten biliniyor (odak + piksel adimi), o yuzden piksel araligi
    dogrudan acisal aralik demek.

    Yontem: algilanan en parlak yildizlarin cift araliklarini katalog
    ciftlerininkiyle eslestir; her aday eslesme bir merkez+donme
    onerir; en cok yildizi dogrulayan oneri kazanir.
    """
    xy = np.asarray(detected_xy, dtype=float)
    k = min(brightest, len(xy))
    if k < 3:
        return None

    tol_deg = tol_px * scale

    # Cift eslestirmesi yalnizca PARLAK katalog yildizlariyla yapiliyor.
    #
    # Sebep iki katli. Birincisi hiz: cift sayisi n^2 ile buyuyor ve
    # genis arama yaricapinda binlerce yildiz olur — 2 milyon cift
    # hesaplanamaz. Ikincisi dogruluk: karede guvenilir sekilde
    # algilanan yildizlar zaten parlak olanlar, sonuklarla eslestirmeye
    # calismak gurultu ekler.
    #
    # Dogrulama asamasi (score) katalogun TAMAMINI kullaniyor; kisitlama
    # sadece ilk adayi bulmak icin.
    if len(cat.ra_deg) > pair_stars:
        keep = np.argsort(cat.vmag)[:pair_stars]
        pcat_ra, pcat_dec = cat.ra_deg[keep], cat.dec_deg[keep]
    else:
        keep = np.arange(len(cat.ra_deg))
        pcat_ra, pcat_dec = cat.ra_deg, cat.dec_deg

    n = len(pcat_ra)
    ci, cj = np.triu_indices(n, 1)
    csep = angular_separation(pcat_ra[ci], pcat_dec[ci],
                              pcat_ra[cj], pcat_dec[cj])
    ci, cj = keep[ci], keep[cj]
    order = np.argsort(csep)
    csep_s, ci_s, cj_s = csep[order], ci[order], cj[order]

    best = None
    for a in range(k):
        for b in range(a + 1, k):
            dsep_px = float(np.hypot(*(xy[a] - xy[b])))
            dsep = dsep_px * scale
            if dsep < 3 * tol_deg:      # cok yakin cift ayirt edici degil
                continue
            lo = np.searchsorted(csep_s, dsep - 2 * tol_deg)
            hi = np.searchsorted(csep_s, dsep + 2 * tol_deg)
            for t in range(lo, hi):
                for (u, v) in ((ci_s[t], cj_s[t]), (cj_s[t], ci_s[t])):
                    sol = _from_pair(xy, a, b, cat, u, v, scale, cx, cy,
                                     tol_px, detected_xy)
                    if sol is not None and (best is None
                                            or sol.match_count > best.match_count):
                        best = sol
    if best is None:
        # Cift eslestirme tutmadiysa eski yola dus: merkez dogru varsayilir.
        for parity in (1, -1):
            for roll in np.arange(0.0, 360.0, roll_step):
                px, py = project_to_pixels(cat, ra0, dec0, roll, parity,
                                           scale, cx, cy)
                m = score(detected_xy, px, py, tol_px)
                if best is None or len(m) > best.match_count:
                    rms = (float(np.sqrt(np.mean([d ** 2 for _, _, d in m])))
                           if m else 1e9)
                    best = Solution(ra0, dec0, float(roll), parity, scale, m, rms)
    return best


def _from_pair(xy, a, b, cat, u, v, scale, cx, cy, tol_px, detected_xy):
    """Iki eslesmeden merkez ve donmeyi cozer, sonra butun yildizlarla
    dogrular."""
    # Katalog ciftinin orta noktasi merkez adayi; kabaca yeterli, refine
    # sonra duzeltir.
    ra_mid = np.degrees(np.arctan2(
        (np.sin(np.radians(cat.ra_deg[u])) + np.sin(np.radians(cat.ra_deg[v]))) / 2,
        (np.cos(np.radians(cat.ra_deg[u])) + np.cos(np.radians(cat.ra_deg[v]))) / 2))
    dec_mid = (cat.dec_deg[u] + cat.dec_deg[v]) / 2

    for parity in (1, -1):
        # Katalog ciftinin tanjant duzlemindeki yonu
        xi, eta = gnomonic(np.array([cat.ra_deg[u], cat.ra_deg[v]]),
                           np.array([cat.dec_deg[u], cat.dec_deg[v]]),
                           ra_mid, dec_mid)
        if not np.all(np.isfinite(xi)):
            continue
        # Donme acisinin turetilmesi.
        #
        # Izdusum:  x = (xi·cos r + eta·sin r)·parity
        #           y = -xi·sin r + eta·cos r
        #
        # Iki yildiz arasindaki farki A = atan2(d_eta, d_xi) yonunde ve
        # m uzunlugunda yazarsak:
        #           dx = m·cos(A - r)·parity
        #           dy = m·sin(A - r)
        # yani      A - r = atan2(dy, dx·parity)
        #           r = A - atan2(dy, dx·parity)
        #
        # Ilk yazimda buraya gereksiz bir isaret cevirmesi koymustum ve
        # iki parite dali da ayniydi; sonuc olarak DOGRU cozum hic
        # uretilmiyordu ve yerine 4-6 yildiz tutturan sahte cozumler
        # kazaniyordu. Yogun alanda (Orion) sahte cozum bulmak kolay
        # oldugu icin hata orada en gorunurdu.
        cat_angle = np.arctan2(eta[1] - eta[0], xi[1] - xi[0])
        dxy = np.asarray(xy[b]) - np.asarray(xy[a])
        det_angle = np.arctan2(dxy[1], dxy[0] * parity)
        roll = np.degrees(cat_angle - det_angle)
        # Merkez kaymasi: eslesen yildiz nereye dusmeli, nereye dusuyor
        px, py = project_to_pixels(cat, ra_mid, dec_mid, roll, parity,
                                   scale, cx, cy)
        if not (np.isfinite(px[u]) and np.isfinite(py[u])):
            continue
        shift_x = xy[a][0] - px[u]
        shift_y = xy[a][1] - py[u]
        m = score(detected_xy, px + shift_x, py + shift_y, tol_px)
        # Esik 5: dort yildiz sahte cozumlerde de kolayca tutuyor,
        # ozellikle yogun alanlarda.
        if len(m) >= 5:
            rms = float(np.sqrt(np.mean([d ** 2 for _, _, d in m])))
            return Solution(float(ra_mid), float(dec_mid), float(roll),
                            parity, scale, m, rms)
    return None


def refine(sol, detected_xy, cat, cx, cy, tol_px=6.0):
    """Merkez, donme ve olcegi en kucuk karelerle iyilestirir."""
    from scipy.optimize import least_squares
    if sol.match_count < 4:
        return sol

    det = np.array([detected_xy[i] for i, _, _ in sol.matches])
    idx = np.array([j for _, j, _ in sol.matches])

    def resid(p):
        ra0, dec0, roll, scale = p
        px, py = project_to_pixels(cat, ra0, dec0, roll, sol.parity,
                                   scale, cx, cy)
        return np.concatenate([px[idx] - det[:, 0], py[idx] - det[:, 1]])

    r = least_squares(resid, [sol.ra0, sol.dec0, sol.roll_deg,
                              sol.scale_deg_per_px])
    ra0, dec0, roll, scale = r.x
    px, py = project_to_pixels(cat, ra0, dec0, roll, sol.parity, scale, cx, cy)
    m = score(detected_xy, px, py, tol_px)
    rms = float(np.sqrt(np.mean([d ** 2 for _, _, d in m]))) if m else 1e9
    return Solution(float(ra0), float(dec0), float(roll), sol.parity,
                    float(scale), m, rms)


def identify(plane, ra0, dec0, focal_mm, pixel_pitch_um, *,
             cfa_channel=True, mag_limit=6.0, max_stars=60,
             tol_px=6.0, white_level=15360.0, pointing_tolerance_deg=25.0):
    """Karedeki yildizlari tanir. (cozum, algilananlar, katalog) doner."""
    h, w = plane.shape
    peaks = sp.find_stars(plane, threshold_sigma=8.0, max_stars=max_stars,
                          min_separation=8)
    detected = []
    for (y, x, pk) in peaks:
        cy_, cx_ = sp.centroid(plane, y, x)
        detected.append({"x": cx_, "y": cy_, "peak": float(pk),
                         "saturated": bool(pk >= 0.95 * white_level)})
    if len(detected) < 5:
        return None, detected, None

    # ***BIRIM TUZAGI***: starphot tek CFA kanalinda calisiyor
    # (load_plane -> cfa[oy::2, ox::2]). O duzlemde pikseller sensorun
    # IKI KATI aralikli. Bu carpani unutmak olcegi iki kat yanlis yapar
    # ve hicbir yildiz eslesmez.
    pitch = pixel_pitch_um * (2.0 if cfa_channel else 1.0)
    scale_deg_per_px = (206.265 * pitch / focal_mm) / 3600.0

    # Kadraja sigacak yildizlar + nisan hatasi payi.
    #
    # [pointing_tolerance_deg] onemli: kullanici elle nisan aliyor ve
    # 10-15 derece rahat sasabiliyor. Arama yaricapi dar tutulursa
    # gercek yildizlar katalog listesine hic girmez ve cift eslestirme
    # calisamaz — olculdu: 25 derece payla 15 derecelik sapmaya kadar
    # saglam, 10 derece payla 8'de kopuyor.
    radius_deg = float(np.hypot(w, h) / 2 * scale_deg_per_px * 1.15
                       + pointing_tolerance_deg)
    cat = bsc5.load().brighter_than(mag_limit)
    xi, eta = gnomonic(cat.ra_deg, cat.dec_deg, ra0, dec0)
    near = np.isfinite(xi) & (np.hypot(xi, eta) <= radius_deg)
    cat = bsc5.StarCatalog(cat.ra_deg[near], cat.dec_deg[near], cat.vmag[near],
                           cat.bv[near], cat.hr[near])
    if len(cat) < 4:
        return None, detected, cat

    xy = [(d["x"], d["y"]) for d in detected]
    sol = solve(xy, cat, ra0, dec0, scale_deg_per_px, w / 2, h / 2, tol_px)
    sol = refine(sol, xy, cat, w / 2, h / 2, tol_px)
    return sol, detected, cat


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("frame", type=Path)
    ap.add_argument("--ra", required=True, type=float, help="kadraj merkezi RA, derece")
    ap.add_argument("--dec", required=True, type=float, help="kadraj merkezi Dec, derece")
    ap.add_argument("--focal", required=True, type=float, help="odak, mm")
    ap.add_argument("--pixel-pitch", required=True, type=float, help="piksel adimi, um")
    ap.add_argument("--channel", default="G1")
    ap.add_argument("--mag-limit", type=float, default=6.0)
    ap.add_argument("--out", type=Path, default=None)
    args = ap.parse_args()

    plane, _ = load_plane(args.frame, args.channel, roi=0)
    sol, detected, cat = identify(plane, args.ra, args.dec, args.focal,
                                  args.pixel_pitch, mag_limit=args.mag_limit)
    if sol is None or sol.match_count < 4:
        print("Cozum bulunamadi.")
        print(f"  {len(detected)} yildiz algilandi")
        print("  Olasi sebepler: kadraj merkezi cok yanlis, odak bozuk,")
        print("  bulut, ya da kadir siniri cok dusuk (--mag-limit yukselt).")
        return 1

    print(f"{sol.match_count} yildiz eslesti  (RMS {sol.rms_px:.2f} px)")
    print(f"  merkez  RA {sol.ra0:.4f}  Dec {sol.dec0:.4f}")
    print(f"  donme   {sol.roll_deg:.2f}°   ayna {'evet' if sol.parity < 0 else 'hayir'}")
    print(f"  olcek   {sol.scale_deg_per_px * 3600:.2f}\"/px")
    print()
    print(f"{'HR':>6} {'V':>6} {'B-V':>6} {'x':>8} {'y':>8} {'ayrim':>7}  durum")
    print("-" * 56)
    rows = []
    for i, j, d in sorted(sol.matches, key=lambda m: cat.vmag[m[1]]):
        det = detected[i]
        bv = cat.bv[j]
        rows.append({"hr": int(cat.hr[j]), "vmag": float(cat.vmag[j]),
                     "bv": None if np.isnan(bv) else float(bv),
                     "x": det["x"], "y": det["y"], "peak_adu": det["peak"],
                     "saturated": det["saturated"], "sep_px": d})
        print(f"{cat.hr[j]:>6} {cat.vmag[j]:>6.2f} "
              f"{'—' if np.isnan(bv) else f'{bv:>6.2f}'} "
              f"{det['x']:>8.1f} {det['y']:>8.1f} {d:>7.2f}  "
              f"{'DOYMUS' if det['saturated'] else ''}")

    unsat = [r for r in rows if not r["saturated"]]
    if unsat:
        best = min(unsat, key=lambda r: r["vmag"])
        print()
        print(f"  Sifir noktasi icin en uygun: HR {best['hr']}, V={best['vmag']:.2f}"
              + (f", B-V={best['bv']:.2f}" if best["bv"] is not None else ""))
        print(f"  (doymamis en parlak yildiz — en yuksek SNR)")

    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(json.dumps({
            "center_ra": sol.ra0, "center_dec": sol.dec0,
            "roll_deg": sol.roll_deg, "parity": sol.parity,
            "arcsec_per_px": sol.scale_deg_per_px * 3600,
            "match_count": sol.match_count, "rms_px": sol.rms_px,
            "stars": rows,
        }, indent=2))
        print(f"\n  sonuc: {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
