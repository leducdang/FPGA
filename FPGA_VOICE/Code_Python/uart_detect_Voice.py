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
        data = ser.read(2)

        if len(data) == 2:
            sample = struct.unpack('>h', data)[0]
            samples.append(sample)
            cnt = cnt + 1
            print(sample)
            # if(sample != -1):
            #     print(sample)
            #     samples.append(sample)
            #     cnt = cnt + 1

except KeyboardInterrupt:
    print("Đã dừng chương trình")

finally:
    samples = np.array(samples, dtype=np.int16)

    np.savetxt("audio_data1.txt", samples, fmt="%d")

    print("Đã lưu file thành công")

    if ser.is_open:
        ser.close()
        print("Đã đóng COM")
        time.sleep(0.3)  # 🔥 cho Windows thời gian release