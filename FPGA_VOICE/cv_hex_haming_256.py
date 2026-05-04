# import numpy as np

# N = 256
# w = 0.54 - 0.46*np.cos(2*np.pi*np.arange(N)/(N-1))

# w_q15 = np.round(w * 32767).astype(int)

# for v in w_q15:
#     print(f"{v:04X}")

import numpy as np

N = 256
w = 0.54 - 0.46*np.cos(2*np.pi*np.arange(N)/(N-1))
w_q15 = np.round(w * 32767).astype(int)

with open("hamming256.mif", "w") as f:
    f.write("WIDTH=16;\n")
    f.write("DEPTH=256;\n\n")
    f.write("ADDRESS_RADIX=UNS;\n")
    f.write("DATA_RADIX=HEX;\n\n")
    f.write("CONTENT BEGIN\n")

    for addr in range(N):
        f.write(f"{addr} : {w_q15[addr]:04X};\n")

    f.write("END;\n")

print("File hamming256.mif generated successfully.")