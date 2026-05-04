import serial
import time
import numpy as np

# ser = serial.Serial('COM4', 9600, timeout = 0.1)
ser = serial.Serial('COM4', 115200, timeout=0.1)

samples = []
cnt = 0

try:
    while cnt < 20:
        data = ser.read(6)

        if len(data) == 6:
            raw = int.from_bytes(data, byteorder='big', signed=False)

            samples.append(raw)
            cnt += 1
            print(raw)

except KeyboardInterrupt:
    print("Đã dừng chương trình")

finally:
    samples = np.array(samples, dtype=np.int32)
    np.savetxt("audio_data_MEL1.txt", samples, fmt="%d")

    print("Đã lưu file thành công")

    if ser.is_open:
        ser.close()
        print("Đã đóng COM")
        time.sleep(0.3)