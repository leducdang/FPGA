# import numpy as np

# FRAC = 10
# N = 256

# with open("log_lut.hex","w") as f:
#     for i in range(N):

#         m = 1 + i/N
#         v = np.log2(m)

#         q = int(v * (1<<FRAC))

#         f.write("{:03x}\n".format(q))

import numpy as np

FRAC = 10
N = 256

with open("log_lut.mif","w") as f:

    f.write("WIDTH=10;\n")
    f.write("DEPTH=256;\n\n")

    f.write("ADDRESS_RADIX=HEX;\n")
    f.write("DATA_RADIX=HEX;\n\n")

    f.write("CONTENT BEGIN\n")

    for i in range(N):

        m = 1 + i/N
        v = np.log2(m)

        q = int(v * (1<<FRAC))

        f.write("{:02X} : {:03X};\n".format(i,q))

    f.write("END;\n")