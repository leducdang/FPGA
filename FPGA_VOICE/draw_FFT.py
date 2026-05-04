import numpy as np
import matplotlib.pyplot as plt

# =========================
# 1. Đọc dữ liệu FFT từ file
# File gồm:
# 256 giá trị đầu: real
# 256 giá trị sau: imag
# =========================
data = np.loadtxt("audio_data4.txt")

N = 255

real = data[:N]
imag = data[N:2*N]

# =========================
# 2. Tính magnitude spectrum
# =========================
magnitude = np.sqrt(real**2 + imag**2)

# Chỉ lấy nửa phổ (0 → 127)
# magnitude_half = magnitude[:N//2]

# =========================
# 3. Vẽ biểu đồ
# =========================
plt.figure()
plt.plot(magnitude)
# plt.plot(magnitude_half)

plt.title("FFT Magnitude Spectrum (FPGA)")
plt.xlabel("Frequency Bin")
plt.ylabel("Magnitude")

plt.grid(True)
plt.show()