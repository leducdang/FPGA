import os
import random
import numpy as np
import tensorflow as tf

from tensorflow.keras import layers, models


# ============================================================
# 0. CONFIG
# ============================================================

SEED = 1234

random.seed(SEED)
np.random.seed(SEED)
tf.random.set_seed(SEED)

# Q8.8
FRAC_BITS = 8
SCALE = 1 << FRAC_BITS

BIT_WIDTH = 16

SIGNED_MIN = -(1 << (BIT_WIDTH - 1))
SIGNED_MAX = (1 << (BIT_WIDTH - 1)) - 1

EPOCHS = 5
BATCH_SIZE = 64
LEARNING_RATE = 0.001

FLOAT_FOLDER = "weights_float_8_16"
FIXED_FOLDER = "weights_fixed_8_16"

MODEL_FILE = "mnist_cnn_8_16.keras"


# ============================================================
# 1. LOAD MNIST
# ============================================================

print("\n========================================")
print("LOAD MNIST")
print("========================================")

(x_train, y_train), (x_test, y_test) = (
    tf.keras.datasets.mnist.load_data()
)

# Normalize 0..255 -> 0..1
x_train = x_train.astype(np.float32) / 255.0
x_test = x_test.astype(np.float32) / 255.0

# 28x28 -> 28x28x1
x_train = x_train.reshape(-1, 28, 28, 1)
x_test = x_test.reshape(-1, 28, 28, 1)

print("x_train:", x_train.shape)
print("y_train:", y_train.shape)
print("x_test :", x_test.shape)
print("y_test :", y_test.shape)


# ============================================================
# 2. MODEL 8 -> 16 FILTER
# ============================================================

model = models.Sequential([

    # Input: 28x28x1
    layers.Input(
        shape=(28, 28, 1),
        name="input_image"
    ),

    # Conv1:
    # 28x28x1 -> 24x24x8
    layers.Conv2D(
        filters=8,
        kernel_size=(5, 5),
        strides=(1, 1),
        padding="valid",
        activation="relu",
        name="conv1"
    ),

    # Pool1:
    # 24x24x8 -> 12x12x8
    layers.MaxPooling2D(
        pool_size=(2, 2),
        strides=(2, 2),
        padding="valid",
        name="pool1"
    ),

    # Conv2:
    # 12x12x8 -> 8x8x16
    layers.Conv2D(
        filters=16,
        kernel_size=(5, 5),
        strides=(1, 1),
        padding="valid",
        activation="relu",
        name="conv2"
    ),

    # Pool2:
    # 8x8x16 -> 4x4x16
    layers.MaxPooling2D(
        pool_size=(2, 2),
        strides=(2, 2),
        padding="valid",
        name="pool2"
    ),

    # 4x4x16 = 256
    layers.Flatten(
        name="flatten"
    ),

    # FC:
    # 256 -> 10
    # Không cần softmax khi train nếu dùng from_logits=True
    layers.Dense(
        units=10,
        activation=None,
        name="fc"
    )
])


print("\n========================================")
print("MODEL SUMMARY")
print("========================================")

model.summary()


# ============================================================
# 3. COMPILE
# ============================================================

model.compile(

    optimizer=tf.keras.optimizers.Adam(
        learning_rate=LEARNING_RATE
    ),

    loss=tf.keras.losses.SparseCategoricalCrossentropy(
        from_logits=True
    ),

    metrics=["accuracy"]
)


# ============================================================
# 4. TRAIN
# ============================================================

print("\n========================================")
print("TRAIN")
print("========================================")

model.fit(
    x_train,
    y_train,
    epochs=EPOCHS,
    batch_size=BATCH_SIZE,
    validation_data=(x_test, y_test),
    shuffle=True
)


# ============================================================
# 5. EVALUATE FLOAT MODEL
# ============================================================

print("\n========================================")
print("FLOAT MODEL RESULT")
print("========================================")

test_loss, test_accuracy = model.evaluate(
    x_test,
    y_test,
    verbose=1
)

print("Test loss:", test_loss)
print("Test accuracy:", test_accuracy)
print("Test accuracy (%):", test_accuracy * 100.0)


# ============================================================
# 6. GET WEIGHTS
# ============================================================

conv1_w, conv1_b = model.get_layer("conv1").get_weights()
conv2_w, conv2_b = model.get_layer("conv2").get_weights()
fc_w, fc_b = model.get_layer("fc").get_weights()


print("\n========================================")
print("WEIGHT SHAPES")
print("========================================")

print("conv1_w:", conv1_w.shape)
print("conv1_b:", conv1_b.shape)

print("conv2_w:", conv2_w.shape)
print("conv2_b:", conv2_b.shape)

print("fc_w:", fc_w.shape)
print("fc_b:", fc_b.shape)


# Kiểm tra kiến trúc
assert conv1_w.shape == (5, 5, 1, 8)
assert conv1_b.shape == (8,)

assert conv2_w.shape == (5, 5, 8, 16)
assert conv2_b.shape == (16,)

assert fc_w.shape == (256, 10)
assert fc_b.shape == (10,)

print("Weight shapes OK.")


# ============================================================
# 7. SAVE FLOAT WEIGHTS
# ============================================================

os.makedirs(
    FLOAT_FOLDER,
    exist_ok=True
)

# NPY
np.save(
    os.path.join(FLOAT_FOLDER, "conv1_w.npy"),
    conv1_w
)

np.save(
    os.path.join(FLOAT_FOLDER, "conv1_b.npy"),
    conv1_b
)

np.save(
    os.path.join(FLOAT_FOLDER, "conv2_w.npy"),
    conv2_w
)

np.save(
    os.path.join(FLOAT_FOLDER, "conv2_b.npy"),
    conv2_b
)

np.save(
    os.path.join(FLOAT_FOLDER, "fc_w.npy"),
    fc_w
)

np.save(
    os.path.join(FLOAT_FOLDER, "fc_b.npy"),
    fc_b
)


# TXT FLOAT
np.savetxt(
    os.path.join(FLOAT_FOLDER, "conv1_w.txt"),
    conv1_w.reshape(-1),
    fmt="%.10f"
)

np.savetxt(
    os.path.join(FLOAT_FOLDER, "conv1_b.txt"),
    conv1_b.reshape(-1),
    fmt="%.10f"
)

np.savetxt(
    os.path.join(FLOAT_FOLDER, "conv2_w.txt"),
    conv2_w.reshape(-1),
    fmt="%.10f"
)

np.savetxt(
    os.path.join(FLOAT_FOLDER, "conv2_b.txt"),
    conv2_b.reshape(-1),
    fmt="%.10f"
)

np.savetxt(
    os.path.join(FLOAT_FOLDER, "fc_w.txt"),
    fc_w.reshape(-1),
    fmt="%.10f"
)

np.savetxt(
    os.path.join(FLOAT_FOLDER, "fc_b.txt"),
    fc_b.reshape(-1),
    fmt="%.10f"
)

print("\nFloat weights saved to:")
print(FLOAT_FOLDER)


# ============================================================
# 8. QUANTIZE Q8.8
# ============================================================

def quantize_q88(array):
    """
    Q8.8:
        q = round(float * 256)
    """

    q = np.round(
        array * SCALE
    ).astype(np.int64)

    q = np.clip(
        q,
        SIGNED_MIN,
        SIGNED_MAX
    )

    return q


conv1_w_q88 = quantize_q88(conv1_w)
conv1_b_q88 = quantize_q88(conv1_b)

conv2_w_q88 = quantize_q88(conv2_w)
conv2_b_q88 = quantize_q88(conv2_b)

fc_w_q88 = quantize_q88(fc_w)
fc_b_q88 = quantize_q88(fc_b)


# ============================================================
# 9. PRINT Q8.8 ERROR
# ============================================================

def print_quantization_error(
    name,
    original,
    quantized
):

    reconstructed = (
        quantized.astype(np.float64)
        / SCALE
    )

    error = np.abs(
        original - reconstructed
    )

    print(
        f"{name:<15} "
        f"max_error={error.max():.10f} "
        f"mean_error={error.mean():.10f}"
    )


print("\n========================================")
print("Q8.8 QUANTIZATION ERROR")
print("========================================")

print_quantization_error(
    "Conv1 weight",
    conv1_w,
    conv1_w_q88
)

print_quantization_error(
    "Conv1 bias",
    conv1_b,
    conv1_b_q88
)

print_quantization_error(
    "Conv2 weight",
    conv2_w,
    conv2_w_q88
)

print_quantization_error(
    "Conv2 bias",
    conv2_b,
    conv2_b_q88
)

print_quantization_error(
    "FC weight",
    fc_w,
    fc_w_q88
)

print_quantization_error(
    "FC bias",
    fc_b,
    fc_b_q88
)


# ============================================================
# 10. SAVE Q8.8 DECIMAL
# ============================================================

os.makedirs(
    FIXED_FOLDER,
    exist_ok=True
)

np.savetxt(
    os.path.join(FIXED_FOLDER, "conv1_w_q88_dec.txt"),
    conv1_w_q88.reshape(-1),
    fmt="%d"
)

np.savetxt(
    os.path.join(FIXED_FOLDER, "conv1_b_q88_dec.txt"),
    conv1_b_q88.reshape(-1),
    fmt="%d"
)

np.savetxt(
    os.path.join(FIXED_FOLDER, "conv2_w_q88_dec.txt"),
    conv2_w_q88.reshape(-1),
    fmt="%d"
)

np.savetxt(
    os.path.join(FIXED_FOLDER, "conv2_b_q88_dec.txt"),
    conv2_b_q88.reshape(-1),
    fmt="%d"
)

np.savetxt(
    os.path.join(FIXED_FOLDER, "fc_w_q88_dec.txt"),
    fc_w_q88.reshape(-1),
    fmt="%d"
)

np.savetxt(
    os.path.join(FIXED_FOLDER, "fc_b_q88_dec.txt"),
    fc_b_q88.reshape(-1),
    fmt="%d"
)


# ============================================================
# 11. SIGNED -> HEX 16-BIT
# ============================================================

def signed_to_hex(
    value,
    bit_width=16
):

    mask = (
        (1 << bit_width)
        - 1
    )

    unsigned_value = (
        int(value)
        & mask
    )

    hex_digits = (
        bit_width + 3
    ) // 4

    return format(
        unsigned_value,
        f"0{hex_digits}X"
    )


def save_hex(
    filename,
    array
):

    flat = array.reshape(-1)

    with open(
        filename,
        "w",
        encoding="utf-8"
    ) as f:

        for value in flat:

            f.write(
                signed_to_hex(value)
                + "\n"
            )


# ============================================================
# 12. SAVE Q8.8 HEX
# ============================================================

save_hex(
    os.path.join(FIXED_FOLDER, "conv1_w_q88.hex"),
    conv1_w_q88
)

save_hex(
    os.path.join(FIXED_FOLDER, "conv1_b_q88.hex"),
    conv1_b_q88
)

save_hex(
    os.path.join(FIXED_FOLDER, "conv2_w_q88.hex"),
    conv2_w_q88
)

save_hex(
    os.path.join(FIXED_FOLDER, "conv2_b_q88.hex"),
    conv2_b_q88
)

save_hex(
    os.path.join(FIXED_FOLDER, "fc_w_q88.hex"),
    fc_w_q88
)

save_hex(
    os.path.join(FIXED_FOLDER, "fc_b_q88.hex"),
    fc_b_q88
)

print("\nQ8.8 weights saved to:")
print(FIXED_FOLDER)


# ============================================================
# 13. SAVE MODEL
# ============================================================

model.save(
    MODEL_FILE
)


# ============================================================
# 14. DONE
# ============================================================

print("\n========================================")
print("DONE")
print("========================================")

print("Model:", MODEL_FILE)
print("Float weights:", FLOAT_FOLDER)
print("Q8.8 weights:", FIXED_FOLDER)

print("\nExpected weight counts:")
print("Conv1 weight:", conv1_w.size)  # 200
print("Conv1 bias  :", conv1_b.size)  # 8
print("Conv2 weight:", conv2_w.size)  # 3200
print("Conv2 bias  :", conv2_b.size)  # 16
print("FC weight   :", fc_w.size)     # 2560
print("FC bias     :", fc_b.size)     # 10
