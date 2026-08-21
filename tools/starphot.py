#!/usr/bin/env python3
"""Yildiz bulma, merkez hesabi, aciklik fotometrisi ve PSF genisligi.

Faz 0.B'nin iki ciktisi buna dayanir:
  - sonum katsayisi k  (analyze_extinction.py)
  - PSF genisligi FWHM (analyze_psf.py)

Neden hazir bir kutuphane degil: photutils kurulu degil ve buradaki is
dar — bir karede birkac parlak yildiz. Dar isi kendi yazmak, kalibre
edilmemis bir bagimliligi zincire sokmaktan iyi.

**Onemli:** Butun olcumler CFA'nin tek kanalinda (varsayilan G1)
yapilir. Debayer YAPILMAZ — interpolasyon komsu pikselleri karistirir
ve hem fotometriyi hem FWHM'i bozar. Yol haritasinin "yesil kanal ~ V"
karari da zaten tek kanal uzerine kurulu.
"""
from __future__ import annotations

import numpy as np
from scipy.optimize import least_squares

__all__ = [
    "estimate_background",
    "find_stars",
    "centroid",
    "aperture_flux",
    "fit_gaussian_fwhm",
    "measure_star",
]


def estimate_background(plane: np.ndarray) -> tuple[float, float]:
    """Fon seviyesi ve gurultusu, saglam (robust) tahmin.

    Ortanca ve MAD kullanilir: birkac parlak yildiz ortalamayi ve
    standart sapmayi yukari ceker, ortancayi cekmez.
    """
    med = float(np.median(plane))
    mad = float(np.median(np.abs(plane - med)))
    # Gaussian icin sigma = 1.4826 * MAD.
    return med, 1.4826 * mad


def find_stars(
    plane: np.ndarray,
    threshold_sigma: float = 8.0,
    min_separation: int = 12,
    max_stars: int = 50,
    edge_margin: int = 20,
) -> list[tuple[int, int, float]]:
    """Yerel tepe noktalarini bulur. (y, x, tepe_degeri) listesi doner.

    Basit ama bu is icin yeterli: fondan [threshold_sigma] kadar yukarida
    olan ve kendi komsulugunun en parlagi olan pikseller.

    [edge_margin] kenardan uzak durur — kenardaki yildizin acikligi
    kareye sigmaz ve akisi eksik olculur.
    """
    bg, noise = estimate_background(plane)
    if noise <= 0:
        return []
    limit = bg + threshold_sigma * noise
    h, w = plane.shape
    ys, xs = np.where(plane > limit)
    keep = (
        (ys >= edge_margin) & (ys < h - edge_margin)
        & (xs >= edge_margin) & (xs < w - edge_margin)
    )
    ys, xs = ys[keep], xs[keep]
    if len(ys) == 0:
        return []
    vals = plane[ys, xs]
    order = np.argsort(vals)[::-1]

    peaks: list[tuple[int, int, float]] = []
    for i in order:
        y, x = int(ys[i]), int(xs[i])
        if any(abs(y - py) < min_separation and abs(x - px) < min_separation
               for py, px, _ in peaks):
            continue
        peaks.append((y, x, float(vals[i])))
        if len(peaks) >= max_stars:
            break
    return peaks


def centroid(plane: np.ndarray, y: int, x: int, box: int = 7) -> tuple[float, float]:
    """Agirlik merkezi. Piksel merkezinden daha iyi bir konum verir."""
    bg, _ = estimate_background(plane)
    h, w = plane.shape
    y0, y1 = max(0, y - box), min(h, y + box + 1)
    x0, x1 = max(0, x - box), min(w, x + box + 1)
    sub = plane[y0:y1, x0:x1] - bg
    sub = np.clip(sub, 0, None)
    total = sub.sum()
    if total <= 0:
        return float(y), float(x)
    yy, xx = np.mgrid[y0:y1, x0:x1]
    return float((sub * yy).sum() / total), float((sub * xx).sum() / total)


def aperture_flux(
    plane: np.ndarray,
    cy: float,
    cx: float,
    radius: float,
    sky_inner: float | None = None,
    sky_outer: float | None = None,
) -> tuple[float, float, int]:
    """Dairesel aciklik fotometrisi.

    (akis, piksel_basina_fon, aciklik_piksel_sayisi) doner. Akis fon
    cikarilmis toplamdir.

    Fon, yildizin etrafindaki halkadan olculur — karenin genelinden
    degil. Genis acida gokyuzu fonu cerceve boyunca degisir; yerel halka
    o degisimi izler.
    """
    if sky_inner is None:
        sky_inner = radius * 2.0
    if sky_outer is None:
        sky_outer = radius * 3.5
    h, w = plane.shape
    r = int(np.ceil(sky_outer)) + 1
    y0, y1 = max(0, int(cy) - r), min(h, int(cy) + r + 1)
    x0, x1 = max(0, int(cx) - r), min(w, int(cx) + r + 1)
    sub = plane[y0:y1, x0:x1]
    yy, xx = np.mgrid[y0:y1, x0:x1]
    d = np.hypot(yy - cy, xx - cx)

    ring = (d >= sky_inner) & (d <= sky_outer)
    sky = float(np.median(sub[ring])) if ring.sum() > 8 else float(np.median(sub))

    ap = d <= radius
    n = int(ap.sum())
    flux = float(sub[ap].sum() - sky * n)
    return flux, sky, n


def _gauss2d(params, yy, xx):
    amp, cy, cx, sigma, base = params
    r2 = (yy - cy) ** 2 + (xx - cx) ** 2
    return amp * np.exp(-r2 / (2 * sigma ** 2)) + base


def fit_gaussian_fwhm(
    plane: np.ndarray, cy: float, cx: float, box: int = 9
) -> float | None:
    """Yildiza 2B Gaussian uydurur, FWHM'i piksel cinsinden dondurur.

    FWHM = 2 * sqrt(2 ln 2) * sigma = 2.3548 * sigma.

    Genis acida yildiz bir pikselden kucuk olabilir (14 mm'de olcek
    54.8 yay saniyesi/piksel). O durumda uydurma sigma < 0.5 verir ve
    sonuc "az orneklenmis" demektir — hata degil, rejimin ozelligi.
    """
    h, w = plane.shape
    y0, y1 = max(0, int(cy) - box), min(h, int(cy) + box + 1)
    x0, x1 = max(0, int(cx) - box), min(w, int(cx) + box + 1)
    sub = plane[y0:y1, x0:x1].astype(float)
    if sub.size < 25:
        return None
    yy, xx = np.mgrid[y0:y1, x0:x1]
    base0 = float(np.median(sub))
    amp0 = float(sub.max() - base0)
    if amp0 <= 0:
        return None
    try:
        r = least_squares(
            lambda p: (_gauss2d(p, yy, xx) - sub).ravel(),
            [amp0, cy, cx, 1.5, base0],
            bounds=([0, cy - 3, cx - 3, 0.3, -np.inf],
                    [np.inf, cy + 3, cx + 3, 10.0, np.inf]),
        )
    except Exception:
        return None
    sigma = abs(r.x[3])
    return float(2.3548 * sigma)


def measure_star(
    plane: np.ndarray, y: int, x: int, radius: float | None = None
) -> dict | None:
    """Tek yildiz icin merkez, akis ve FWHM."""
    cy, cx = centroid(plane, y, x)
    fwhm = fit_gaussian_fwhm(plane, cy, cx)
    if radius is None:
        # Aciklik yaricapi FWHM'e baglanir; sabit yaricap, farkli
        # keskinlikteki karelerde farkli oranda isik toplar ve sonum
        # olcumune sahte egilim sokar.
        radius = max(3.0, 1.5 * (fwhm or 2.0))
    flux, sky, npix = aperture_flux(plane, cy, cx, radius)
    if flux <= 0:
        return None
    return {
        "y": cy, "x": cx, "flux_adu": flux, "sky_adu": sky,
        "aperture_px": npix, "aperture_radius": radius,
        "fwhm_px": fwhm,
        "instrumental_mag": -2.5 * float(np.log10(flux)),
    }
