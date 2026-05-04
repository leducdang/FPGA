import numpy as np
import matplotlib.pyplot as plt

SAMPLE_RATE = 16000

# Đọc dữ liệu
samples = np.loadtxt("audio_data1.txt", dtype=np.int16)
# samples = np.loadtxt("audio_data1_pre.txt", dtype=np.int16)

# Tạo trục thời gian
time = np.arange(len(samples)) / SAMPLE_RATE

plt.figure()
plt.plot(time, samples)
plt.xlabel("Time (seconds)")
plt.ylabel("Amplitude")
plt.title("Waveform - 5 seconds")
plt.show()