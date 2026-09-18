import os
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models

# ==============================
# 1. Tải dữ liệu MNIST
# ==============================
(x_train, y_train), (x_test, y_test) = tf.keras.datasets.mnist.load_data()

# Chuẩn hóa ảnh từ 0-255 về 0-1
x_train = x_train.astype("float32") / 255.0
x_test  = x_test.astype("float32") / 255.0

# Thêm chiều kênh: 28x28 -> 28x28x1
x_train = x_train.reshape(-1, 28, 28, 1)
x_test  = x_test.reshape(-1, 28, 28, 1)

# ==============================
# 2. Tạo mô hình CNN giống hình
# ==============================
model = models.Sequential([
    layers.Input(shape=(28, 28, 1)),

    # Conv1: 5x5, 3 kernel
    layers.Conv2D(
        filters=3,
        kernel_size=(5, 5),
        strides=(1, 1),
        padding="valid",
        activation="relu",
        name="conv1"
    ),

    # Max Pooling 1: 2x2
    layers.MaxPooling2D(
        pool_size=(2, 2),
        strides=(2, 2),
        name="pool1"
    ),

    # Conv2: 5x5, 3 kernel
    layers.Conv2D(
        filters=3,
        kernel_size=(5, 5),
        strides=(1, 1),
        padding="valid",
        activation="relu",
        name="conv2"
    ),

    # Max Pooling 2: 2x2
    layers.MaxPooling2D(
        pool_size=(2, 2),
        strides=(2, 2),
        name="pool2"
    ),

    layers.Flatten(name="flatten"),

    # Fully Connected: 48 -> 10
    layers.Dense(10, activation="softmax", name="fc")
])

model.summary()

# ==============================
# 3. Compile và train
# ==============================
model.compile(
    optimizer="adam",
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"]
)

model.fit(
    x_train,
    y_train,
    epochs=5,
    batch_size=64,
    validation_data=(x_test, y_test)
)

# Đánh giá
loss, acc = model.evaluate(x_test, y_test)
print("Test accuracy:", acc)

# ==============================
# 4. Xuất trọng số dạng float
# ==============================
os.makedirs("weights_float", exist_ok=True)

conv1_w, conv1_b = model.get_layer("conv1").get_weights()
conv2_w, conv2_b = model.get_layer("conv2").get_weights()
fc_w, fc_b       = model.get_layer("fc").get_weights()

print("conv1_w shape:", conv1_w.shape)
print("conv1_b shape:", conv1_b.shape)
print("conv2_w shape:", conv2_w.shape)
print("conv2_b shape:", conv2_b.shape)
print("fc_w shape:", fc_w.shape)
print("fc_b shape:", fc_b.shape)

np.save("weights_float/conv1_w.npy", conv1_w)
np.save("weights_float/conv1_b.npy", conv1_b)
np.save("weights_float/conv2_w.npy", conv2_w)
np.save("weights_float/conv2_b.npy", conv2_b)
np.save("weights_float/fc_w.npy", fc_w)
np.save("weights_float/fc_b.npy", fc_b)

np.savetxt("weights_float/conv1_w.txt", conv1_w.reshape(-1), fmt="%.8f")
np.savetxt("weights_float/conv1_b.txt", conv1_b.reshape(-1), fmt="%.8f")
np.savetxt("weights_float/conv2_w.txt", conv2_w.reshape(-1), fmt="%.8f")
np.savetxt("weights_float/conv2_b.txt", conv2_b.reshape(-1), fmt="%.8f")
np.savetxt("weights_float/fc_w.txt", fc_w.reshape(-1), fmt="%.8f")
np.savetxt("weights_float/fc_b.txt", fc_b.reshape(-1), fmt="%.8f")

print("Đã xuất trọng số float.")

# ==============================
# 5. Lượng tử hóa sang số nguyên cho FPGA
# ==============================
os.makedirs("weights_fixed", exist_ok=True)

# Q8.8: giá trị thực x 256
SCALE = 256
BIT_WIDTH = 16

def quantize_q88(x):
    q = np.round(x * SCALE).astype(np.int32)

    # Giới hạn signed 16-bit
    q = np.clip(q, -32768, 32767)

    return q

conv1_w_q = quantize_q88(conv1_w)
conv1_b_q = quantize_q88(conv1_b)
conv2_w_q = quantize_q88(conv2_w)
conv2_b_q = quantize_q88(conv2_b)
fc_w_q    = quantize_q88(fc_w)
fc_b_q    = quantize_q88(fc_b)

# Lưu dạng decimal
np.savetxt("weights_fixed/conv1_w_q88_dec.txt", conv1_w_q.reshape(-1), fmt="%d")
np.savetxt("weights_fixed/conv1_b_q88_dec.txt", conv1_b_q.reshape(-1), fmt="%d")
np.savetxt("weights_fixed/conv2_w_q88_dec.txt", conv2_w_q.reshape(-1), fmt="%d")
np.savetxt("weights_fixed/conv2_b_q88_dec.txt", conv2_b_q.reshape(-1), fmt="%d")
np.savetxt("weights_fixed/fc_w_q88_dec.txt", fc_w_q.reshape(-1), fmt="%d")
np.savetxt("weights_fixed/fc_b_q88_dec.txt", fc_b_q.reshape(-1), fmt="%d")

# ==============================
# 6. Xuất dạng HEX bù 2 cho Verilog ROM
# ==============================
def signed_to_hex(value, bit_width=16):
    if value < 0:
        value = (1 << bit_width) + value
    return format(value, "04X")

def save_hex(filename, array):
    flat = array.reshape(-1)
    with open(filename, "w") as f:
        for v in flat:
            f.write(signed_to_hex(int(v), BIT_WIDTH) + "\n")

save_hex("weights_fixed/conv1_w_q88.hex", conv1_w_q)
save_hex("weights_fixed/conv1_b_q88.hex", conv1_b_q)
save_hex("weights_fixed/conv2_w_q88.hex", conv2_w_q)
save_hex("weights_fixed/conv2_b_q88.hex", conv2_b_q)
save_hex("weights_fixed/fc_w_q88.hex", fc_w_q)
save_hex("weights_fixed/fc_b_q88.hex", fc_b_q)

print("Đã xuất trọng số Q8.8 dạng DEC và HEX cho FPGA.")

# ==============================
# 7. Lưu toàn bộ model
# ==============================
model.save("mnist_cnn_model.keras")
print("Đã lưu model mnist_cnn_model.keras")

