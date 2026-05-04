# import numpy as np
# import matplotlib.pyplot as plt

# # =========================
# # 1. Đọc dữ liệu từ file txt
# # =========================
# # data = np.loadtxt("audio_data1_pre.txt")
# data = np.loadtxt("audio_data3.txt")

# # Nếu dữ liệu là int (VD: 16-bit ADC), chuyển sang float
# data = data.astype(np.float32)

# # Chuẩn hóa nếu cần (giống PCM 16bit)
# if np.max(np.abs(data)) > 1:
#     data = data / 32768.0

# # =========================
# # 2. Frame Blocking
# # =========================
# fs = 16000
# N = 256

# frame = data[0:N]   # lấy 1 frame đầu

# # =========================
# # 3. Hamming Window
# # =========================
# window = np.hamming(N)
# frame_win = frame * window

# # =========================
# # 4. FFT
# # =========================
# X = np.fft.fft(frame_win)

# # Lấy nửa phổ
# X_real = np.real(X[:N//2])
# X_imag = np.imag(X[:N//2])

# # Magnitude giống FPGA
# X_mag = np.sqrt(X_real**2 + X_imag**2)

# # Tạo trục tần số
# freq = np.fft.fftfreq(N, 1/fs)[:N//2]

# # =========================
# # 5. Vẽ phổ
# # =========================
# plt.figure()
# plt.plot(freq, X_mag)
# plt.title("FFT Spectrum from Pre-emphasis Data")
# plt.xlabel("Frequency (Hz)")
# plt.ylabel("Magnitude")
# plt.grid()
# plt.show()



# import numpy as np
# import matplotlib.pyplot as plt

# # =========================
# # 1. Đọc dữ liệu
# # =========================
# data = np.loadtxt("audio_data3.txt")
# data = data.astype(np.float32)

# if np.max(np.abs(data)) > 1:
#     data = data / 32768.0

# # =========================
# # 2. Frame Blocking
# # =========================
# fs = 16000
# N = 256
# frame = data[0:N]

# # =========================
# # 3. Hamming Window
# # =========================
# window = np.hamming(N)
# frame_win = frame * window

# # =========================
# # 4. FFT
# # =========================
# X = np.fft.fft(frame_win)

# X_real = np.real(X)
# X_imag = np.imag(X)

# # =========================
# # 5. LƯU FILE
# # =========================

# # Lưu riêng từng file
# np.savetxt("fft_real_pc.txt", X_real, fmt="%.6f")
# np.savetxt("fft_imag_pc.txt", X_imag, fmt="%.6f")

# # Hoặc lưu chung 1 file (real imag từng dòng)
# # fft_out = np.column_stack((X_real, X_imag))
# # np.savetxt("fft_complex_pc.txt", fft_out, fmt="%.6f")

# print("Đã lưu FFT ra file thành công")

# # =========================
# # 6. Vẽ phổ
# # =========================
# X_mag = np.sqrt(X_real[:N//2]**2 + X_imag[:N//2]**2)
# freq = np.fft.fftfreq(N, 1/fs)[:N//2]

# plt.figure()
# plt.plot(freq, X_mag)
# plt.title("FFT Spectrum from Pre-emphasis Data")
# plt.xlabel("Frequency (Hz)")
# plt.ylabel("Magnitude")
# plt.grid()
# plt.show()


# import numpy as np

# data = np.loadtxt("audio_data3.txt")

# # KHÔNG normalize
# # KHÔNG window
# frame = data[:256]

# X = np.fft.fft(frame)

# X_real = np.real(X)
# X_imag = np.imag(X)


# np.savetxt("fft_real_no_scale.txt", X_real, fmt="%.0f")
# np.savetxt("fft_imag_no_scale.txt", X_imag, fmt="%.0f")

# print("Done")

import numpy as np

# =========================
# 1. Đọc dữ liệu
# =========================
data = np.loadtxt("audio_data3.txt")

# Không normalize
# Không window
frame = data[:256]

N = 256

# =========================
# 2. FFT
# =========================
X = np.fft.fft(frame)

# =========================
# 3. Lưu FFT không scale
# =========================
np.savetxt("fft_real_no_scale.txt", np.real(X), fmt="%.0f")
np.savetxt("fft_imag_no_scale.txt", np.imag(X), fmt="%.0f")

# =========================
# 4. Lưu FFT scale /256 (giống FPGA nếu shift mỗi stage)
# =========================
X_scaled = X / 256

np.savetxt("fft_real_scaled.txt", np.real(X_scaled), fmt="%.0f")
np.savetxt("fft_imag_scaled.txt", np.imag(X_scaled), fmt="%.0f")

# =========================
# 5. Hàm bit-reverse
# =========================
def bit_reverse_indices(n):
    bits = int(np.log2(n))
    indices = np.arange(n)
    reversed_indices = np.array([
        int(f"{i:0{bits}b}"[::-1], 2)
        for i in indices
    ])
    return reversed_indices

# =========================
# 6. Reorder theo bit-reversed
# =========================
rev = bit_reverse_indices(N)

X_bitrev = X[rev]
X_scaled_bitrev = X_scaled[rev]

# Lưu kết quả bit-reversed
np.savetxt("fft_real_bitrev.txt", np.real(X_bitrev), fmt="%.0f")
np.savetxt("fft_imag_bitrev.txt", np.imag(X_bitrev), fmt="%.0f")

np.savetxt("fft_real_scaled_bitrev.txt", np.real(X_scaled_bitrev), fmt="%.0f")
np.savetxt("fft_imag_scaled_bitrev.txt", np.imag(X_scaled_bitrev), fmt="%.0f")

print("Done!")