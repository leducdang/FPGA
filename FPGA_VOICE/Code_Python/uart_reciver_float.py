import serial
import struct
import time
import numpy as np

# ser = serial.Serial('COM4', 9600, timeout = 0.1)
ser = serial.Serial('COM4', 115200, timeout = 0.1)

samples = []
cnt = 0

try:
    while cnt < 47999:
        data = ser.read(3)

        if len(data) == 3:
            # sample = struct.unpack('>h', data)[0]
            sample = int.from_bytes(data, byteorder='big', signed=False)
        
            cnt = cnt + 1
            # print(sample)
            val = sample /1024
            samples.append( val)
            print(f"{cnt:6d} | raw={sample:6d} | q6.10={val:.6f}")
            # if(sample != -1):
            #     print(sample)
            #     samples.append(sample)
            #     cnt = cnt + 1

except KeyboardInterrupt:
    print("Đã dừng chương trình")

finally:
    # samples = np.array(samples, dtype=np.int16)
    float_arr = np.array(samples, dtype=np.float32)

    # np.savetxt("audio_data3.txt", samples, fmt="%d")
    np.savetxt("q610_float5.txt", float_arr, fmt="%.6f")

    print("Đã lưu file thành công")

    if ser.is_open:
        ser.close()
        print("Đã đóng COM")
        time.sleep(0.3)  # 🔥 cho Windows thời gian release



# import serial
# import struct
# import time
# import numpy as np

# PORT = "COM4"
# BAUD = 115200
# TIMEOUT = 0.1

# FRAC = 10
# SCALE = 1 << FRAC  # 1024

# MAX_SAMPLES = 80000

# # Nếu FPGA gửi MSB trước (big-endian) dùng '>h'
# # Nếu FPGA gửi LSB trước (little-endian) đổi thành '<h'
# FMT = '>h'


# # ser = serial.Serial('COM4', 9600, timeout = 0.1)
# ser = serial.Serial('COM4', 115200, timeout = 0.1)

# ser = serial.Serial(PORT, BAUD, timeout=TIMEOUT)

# raw_samples = []
# float_samples = []
# cnt = 0

# try:
#     while cnt < MAX_SAMPLES:
#         data = ser.read(2)

#         if len(data) != 2:
#             continue

#         raw = struct.unpack(FMT, data)[0]          # int16
#         val = raw / float(SCALE)                   # Q6.10 -> float

#         raw_samples.append(raw)
#         float_samples.append(val)

#         cnt += 1
#         print(f"{cnt:6d} | raw={raw:6d} | q6.10={val:.6f}")

# except KeyboardInterrupt:
#     print("Đã dừng chương trình")

# finally:
#     # raw_arr = np.array(raw_samples, dtype=np.int16)
#     # float_arr = np.array(float_samples, dtype=np.float32)

#     # np.savetxt("q610_raw.txt", raw_arr, fmt="%d")
#     # np.savetxt("q610_float.txt", float_arr, fmt="%.6f")

#     # # (tuỳ chọn) lưu chung 2 cột: raw và float
#     # both = np.column_stack([raw_arr.astype(np.int32), float_arr.astype(np.float64)])
#     # np.savetxt("q610_both.txt", both, fmt=["%d", "%.6f"], header="raw_int16 q6_10_float", comments="")

#     # print("Đã lưu file thành công")

#     if ser.is_open:
#         ser.close()
#         print("Đã đóng COM")
#         time.sleep(0.3)