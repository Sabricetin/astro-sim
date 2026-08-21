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


def solve(detected_xy, cat, ra0, dec0, scale, cx, cy,
          tol_px=6.0, roll_step=1.0, verbose=True):
    """Donme acisini tarayip en cok eslesmeyi veren cozumu bulur."""
    best = None
    for parity in (1, -1):
        for roll in np.arange(0.0, 360.0, roll_step):
            px, py = project_to_pixels(cat, ra0, dec0, roll, parity,
                                       scale, cx, cy)
            m = score(detected_xy, px, py, tol_px)
            if best is None or len(m) > best.match_count:
                rms = float(np.sqrt(np.mean([d ** 2 for _, _, d in m]))) if m else 1e9
                best = Solution(ra0, dec0, float(roll), parity, scale, m, rms)
    return best


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
             tol_px=6.0, white_level=15360.0):
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

    # Kadraja sigacak yildizlar + biraz pay.
    radius_deg = float(np.hypot(w, h) / 2 * scale_deg_per_px * 1.3)
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
