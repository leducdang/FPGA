import numpy as np
import wave

SAMPLE_RATE = 16000

# Đọc file txt
samples = np.loadtxt("audio_data1.txt", dtype=np.int16)

# Tạo file wav
with wave.open("output1.wav", "w") as wf:
    wf.setnchannels(1)        # mono
    wf.setsampwidth(2)        # 16-bit = 2 byte
    wf.setframerate(SAMPLE_RATE)
    wf.writeframes(samples.tobytes())

print("Đã tạo file output.wav")