import serial
import time
import numpy as np
# 
# ser = serial.Serial('COM4', 9600, timeout = 0.1)
ser = serial.Serial('COM4', 115200, timeout=0.1)

samples = []
cnt = 0

try:
    while cnt < 256:
        data = ser.read(4)

        if len(data) == 4:
            raw = int.from_bytes(data, byteorder='big', signed=False)

            # # sign extend 24-bit
            # if raw & 0x800000:
            #     raw -= 0x1000000

            samples.append(raw)
            cnt += 1
            print(raw)

except KeyboardInterrupt:
    print("Đã dừng chương trình")

finally:
    samples = np.array(samples, dtype=np.int32)
    np.savetxt("audio_data_mag2.txt", samples, fmt="%d")

    print("Đã lưu file thành công")

    if ser.is_open:
        ser.close()
        print("Đã đóng COM")
        time.sleep(0.3)