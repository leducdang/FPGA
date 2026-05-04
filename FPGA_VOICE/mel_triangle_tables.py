import math
import csv

# =========================
# CONFIG
# =========================
FS   = 16000
NFFT = 256
FMIN = 0.0
FMAX = 4000.0
NMEL = 20

# Weight fixed-point for FPGA
Q = 15
W_ONE = (1 << Q) - 1   # 32767 (Q0.15)

# Bins we care about in 0..FMAX
# Using MFCC-style mapping: bin = floor((NFFT+1) * f / FS)
KMAX = int(math.floor((NFFT + 1) * FMAX / FS))  # expect 64 for 0..4000Hz with NFFT=256, FS=16k

# =========================
# MEL CONVERSIONS
# =========================
def hz_to_mel(f_hz: float) -> float:
    return 2595.0 * math.log10(1.0 + f_hz / 700.0)

def mel_to_hz(m_mel: float) -> float:
    return 700.0 * (10.0 ** (m_mel / 2595.0) - 1.0)

def hz_to_bin(f_hz: float) -> int:
    return int(math.floor((NFFT + 1) * f_hz / FS))

def float_to_q15(x: float) -> int:
    if x <= 0.0:
        return 0
    if x >= 1.0:
        return W_ONE
    return int(round(x * W_ONE))

# =========================
# 1) Compute 22 mel points
# =========================
mel_min = hz_to_mel(FMIN)
mel_max = hz_to_mel(FMAX)

mel_points = [mel_min + i * (mel_max - mel_min) / (NMEL + 1) for i in range(NMEL + 2)]
hz_points  = [mel_to_hz(m) for m in mel_points]
bin_points = [hz_to_bin(f) for f in hz_points]

# Optional: ensure bin points are non-decreasing (usually yes)
# If you want strictly increasing to avoid degenerate triangles, uncomment:
# for i in range(1, len(bin_points)):
#     if bin_points[i] <= bin_points[i-1]:
#         bin_points[i] = bin_points[i-1] + 1

# =========================
# 2) Triangles: (left, center, right) per mel filter
# =========================
triangles = []
for m in range(NMEL):
    left  = bin_points[m]
    center= bin_points[m + 1]
    right = bin_points[m + 2]
    triangles.append((left, center, right))

print("FS =", FS, "NFFT =", NFFT, "FMIN =", FMIN, "FMAX =", FMAX, "NMEL =", NMEL)
print("KMAX (0..KMAX bins used) =", KMAX)
print("bin_points (22):", bin_points)
print("triangles (left,center,right):")
for m,(l,c,r) in enumerate(triangles):
    print(f"  mel {m:02d}: left={l:3d} center={c:3d} right={r:3d}")

# =========================
# 3) Full weight matrix W[m][k]
# =========================
W_float = [[0.0 for _ in range(KMAX + 1)] for _ in range(NMEL)]
W_q15   = [[0   for _ in range(KMAX + 1)] for _ in range(NMEL)]

for m,(l,c,r) in enumerate(triangles):
    # Skip degenerate triangles (can occur if bin points duplicate)
    if l == c or c == r:
        continue

    for k in range(KMAX + 1):
        w = 0.0
        if k < l or k > r:
            w = 0.0
        elif k <= c:
            w = (k - l) / (c - l)
        else:
            w = (r - k) / (r - c)

        if w < 0.0:
            w = 0.0
        W_float[m][k] = w
        W_q15[m][k]   = float_to_q15(w)

# =========================
# 4) Sparse map per bin: (f0,w0,f1,w1)  (max 2 filters per bin)
# =========================
f0 = [0] * (KMAX + 1)
w0 = [0] * (KMAX + 1)
f1 = [0] * (KMAX + 1)
w1 = [0] * (KMAX + 1)

for k in range(KMAX + 1):
    contrib = []
    for m in range(NMEL):
        w = W_float[m][k]
        if w > 0.0:
            contrib.append((m, w))
    # sort by weight descending (usually 1 or 2 entries)
    contrib.sort(key=lambda x: x[1], reverse=True)
    contrib = contrib[:2]

    if len(contrib) >= 1:
        f0[k] = contrib[0][0]
        w0[k] = float_to_q15(contrib[0][1])
    if len(contrib) == 2:
        f1[k] = contrib[1][0]
        w1[k] = float_to_q15(contrib[1][1])

# =========================
# 5) Export tables
# =========================

# 5.1 Export triangle table (left/center/right) with Hz approx
with open("mel_triangles_bins.csv", "w", newline="", encoding="utf-8") as fp:
    wr = csv.writer(fp)
    wr.writerow(["mel_index", "left_bin", "center_bin", "right_bin"])
    for m,(l,c,r) in enumerate(triangles):
        wr.writerow([m, l, c, r])

# 5.2 Export full weight matrix (Q15) as CSV: rows=mel, cols=k
with open("mel_weights_q15_matrix.csv", "w", newline="", encoding="utf-8") as fp:
    wr = csv.writer(fp)
    header = ["mel\\k"] + [str(k) for k in range(KMAX + 1)]
    wr.writerow(header)
    for m in range(NMEL):
        wr.writerow([m] + W_q15[m])

# 5.3 Export sparse map per bin (best for FPGA): CSV
with open("mel_bin_map_sparse.csv", "w", newline="", encoding="utf-8") as fp:
    wr = csv.writer(fp)
    wr.writerow(["k", "f0", "w0_q15", "f1", "w1_q15"])
    for k in range(KMAX + 1):
        wr.writerow([k, f0[k], w0[k], f1[k], w1[k]])

# 5.4 Export sparse map packed to HEX (48-bit per line) for ROM
# Layout (MSB..LSB):
# [47:42]=0
# [41:37]=f0 (5b)
# [36:21]=w0 (16b)
# [20:16]=f1 (5b)
# [15:0] =w1 (16b)
def pack48(ff0, ww0, ff1, ww1):
    return ((ff0 & 0x1F) << 37) | ((ww0 & 0xFFFF) << 21) | ((ff1 & 0x1F) << 16) | (ww1 & 0xFFFF)

with open("mel_bin_map_sparse.hex", "w", encoding="utf-8") as fp:
    for k in range(KMAX + 1):
        word = pack48(f0[k], w0[k], f1[k], w1[k])
        fp.write(f"{word:012X}\n")  # 48-bit = 12 hex digits

print("\nExported files:")
print("  mel_triangles_bins.csv          (left/center/right per mel)")
print("  mel_weights_q15_matrix.csv      (full 20x(KMAX+1) Q15 matrix)")
print("  mel_bin_map_sparse.csv          (per-bin sparse mapping)")
print("  mel_bin_map_sparse.hex          (ROM-ready packed hex, 65 lines)")