import numpy as np

# Hệ số pre-emphasis
alpha = 0.95

# Đọc dữ liệu từ file (mỗi dòng 1 số)
with open("audio_data1.txt", "r") as f:
    x = np.array([int(line.strip()) for line in f if line.strip() != ""])

# Khởi tạo mảng output
y = np.zeros_like(x, dtype=float)

# Tính pre-emphasis
y[0] = 0  # hoặc có thể để x[0] nếu muốn
for n in range(1, len(x)):
    y[n] = x[n] - alpha * x[n-1]

# Làm tròn về số nguyên (giống FPGA)
y_int = np.round(y).astype(int)

# Lưu kết quả ra file
with open("audio_data1_pre.txt", "w") as f:
    for value in y_int:
        f.write(f"{value}\n")

print("Đã tính xong Pre-emphasis và lưu vào audio_data1_pre.txt")