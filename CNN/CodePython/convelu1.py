# from pathlib import Path

# import numpy as np
# from PIL import Image


# # ============================================================
# # CẤU HÌNH
# # ============================================================

# IMAGE_FILE = "C:/Users/DELL/Desktop/CNN/CodePython/17.png"

# WEIGHT_FILE = "C:/Users/DELL/Desktop/CNN/CodePython/conv1_w.txt"
# BIAS_FILE = "C:/Users/DELL/Desktop/CNN/CodePython/conv1_b.txt"

# IMAGE_HEIGHT = 28
# IMAGE_WIDTH = 28

# KERNEL_SIZE = 5
# OUT_CHANNELS = 3

# STRIDE = 1
# FRAC_BITS = 8
# SCALE = 1 << FRAC_BITS       # 256

# # True nếu ảnh là số màu đen trên nền trắng.
# # MNIST tiêu chuẩn là số trắng trên nền đen.
# INVERT_IMAGE = False


# # ============================================================
# # ĐỌC ẢNH 28x28 GRAYSCALE
# # ============================================================

# def load_image_q88(filename: str) -> tuple[np.ndarray, np.ndarray]:
#     """
#     Đọc ảnh grayscale 28x28.

#     Trả về:
#         pixel_u8: pixel gốc 0...255
#         pixel_q88: pixel chuẩn hóa về 0...1 và chuyển sang Q8.8
#     """
#     image = Image.open(filename).convert("L")

#     if image.size != (IMAGE_WIDTH, IMAGE_HEIGHT):
#         image = image.resize(
#             (IMAGE_WIDTH, IMAGE_HEIGHT),
#             Image.Resampling.BILINEAR
#         )

#     pixel_u8 = np.asarray(image, dtype=np.int32)

#     if INVERT_IMAGE:
#         pixel_u8 = 255 - pixel_u8

#     # Python train:
#     # pixel_float = pixel / 255.0
#     #
#     # FPGA Q8.8:
#     # pixel_q88 = round(pixel_float * 256)
#     pixel_q88 = np.rint(
#         pixel_u8.astype(np.float64) * SCALE / 255.0
#     ).astype(np.int32)

#     return pixel_u8, pixel_q88


# # ============================================================
# # ĐỌC KERNEL CONV1
# # ============================================================

# def load_conv1_weights(filename: str) -> np.ndarray:
#     """
#     Đọc 75 trọng số Q8.8.

#     TensorFlow/Keras lưu Conv2D theo thứ tự:
#         [kernel_row][kernel_col][input_channel][output_channel]

#     Conv1 có input_channel = 1 nên kernel trả về có dạng:
#         [5][5][3]
#     """
#     values = np.loadtxt(filename, dtype=np.int32).reshape(-1)

#     expected_count = KERNEL_SIZE * KERNEL_SIZE * OUT_CHANNELS

#     if values.size != expected_count:
#         raise ValueError(
#             f"File kernel phải có {expected_count} giá trị, "
#             f"nhưng hiện có {values.size}."
#         )

#     kernel = np.zeros(
#         (KERNEL_SIZE, KERNEL_SIZE, OUT_CHANNELS),
#         dtype=np.int32
#     )

#     # Thứ tự khi Python xuất bằng reshape(-1):
#     # kh, kw, input_channel, output_channel
#     for kh in range(KERNEL_SIZE):
#         for kw in range(KERNEL_SIZE):
#             for out_ch in range(OUT_CHANNELS):
#                 address = (
#                     (kh * KERNEL_SIZE + kw) * OUT_CHANNELS
#                     + out_ch
#                 )

#                 kernel[kh, kw, out_ch] = values[address]

#     return kernel


# # ============================================================
# # ĐỌC BIAS
# # ============================================================

# def load_conv1_bias(filename: str) -> np.ndarray:
#     """
#     Đọc 3 bias Conv1 dạng Q8.8.

#     Nếu chưa có file bias, chương trình tạm dùng bias = 0.
#     Khi so sánh chính xác với model đã train, bắt buộc phải dùng bias thật.
#     """
#     path = Path(filename)

#     if not path.exists():
#         print(
#             f"Cảnh báo: không tìm thấy {filename}. "
#             "Tạm thời sử dụng bias = 0."
#         )
#         return np.zeros(OUT_CHANNELS, dtype=np.int32)

#     bias = np.loadtxt(filename, dtype=np.int32).reshape(-1)

#     if bias.size != OUT_CHANNELS:
#         raise ValueError(
#             f"File bias phải có {OUT_CHANNELS} giá trị, "
#             f"nhưng hiện có {bias.size}."
#         )

#     return bias


# # ============================================================
# # TÍNH CONV1
# # ============================================================

# def calculate_conv1_q88(
#     image_q88: np.ndarray,
#     kernel_q88: np.ndarray,
#     bias_q88: np.ndarray
# ) -> tuple[np.ndarray, np.ndarray]:
#     """
#     Thực hiện:

#         Vùng ảnh × kernel
#               ↓
#         Cộng dồn
#               ↓
#         Dịch phải 8 bit
#               ↓
#         Cộng bias
#               ↓
#         ReLU

#     Input:
#         image_q88:  28x28, Q8.8
#         kernel_q88: 5x5x3, Q8.8
#         bias_q88:   3, Q8.8

#     Output:
#         conv_before_relu: 24x24x3, Q8.8
#         conv_after_relu:  24x24x3, Q8.8
#     """
#     output_height = (
#         IMAGE_HEIGHT - KERNEL_SIZE
#     ) // STRIDE + 1

#     output_width = (
#         IMAGE_WIDTH - KERNEL_SIZE
#     ) // STRIDE + 1

#     conv_before_relu = np.zeros(
#         (output_height, output_width, OUT_CHANNELS),
#         dtype=np.int64
#     )

#     conv_after_relu = np.zeros(
#         (output_height, output_width, OUT_CHANNELS),
#         dtype=np.int64
#     )

#     for out_ch in range(OUT_CHANNELS):
#         for out_row in range(output_height):
#             for out_col in range(output_width):

#                 accumulator = 0

#                 # Tính một vị trí trên feature map
#                 for kh in range(KERNEL_SIZE):
#                     for kw in range(KERNEL_SIZE):

#                         image_row = out_row * STRIDE + kh
#                         image_col = out_col * STRIDE + kw

#                         pixel = int(
#                             image_q88[image_row, image_col]
#                         )

#                         kernel_value = int(
#                             kernel_q88[kh, kw, out_ch]
#                         )

#                         # Q8.8 × Q8.8 = Q16.16
#                         product = pixel * kernel_value

#                         accumulator += product

#                 # Q16.16 → Q8.8
#                 value_q88 = accumulator >> FRAC_BITS

#                 # Cộng bias Q8.8
#                 value_q88 += int(bias_q88[out_ch])

#                 conv_before_relu[
#                     out_row,
#                     out_col,
#                     out_ch
#                 ] = value_q88

#                 # ReLU
#                 if value_q88 < 0:
#                     conv_after_relu[
#                         out_row,
#                         out_col,
#                         out_ch
#                     ] = 0
#                 else:
#                     conv_after_relu[
#                         out_row,
#                         out_col,
#                         out_ch
#                     ] = value_q88

#     return conv_before_relu, conv_after_relu


# # ============================================================
# # LƯU KẾT QUẢ
# # ============================================================

# def save_feature_maps(
#     feature_maps_q88: np.ndarray,
#     prefix: str
# ) -> None:
#     """
#     Lưu riêng 3 feature map:
#         - dạng số nguyên Q8.8
#         - dạng số thực sau khi chia 256
#     """
#     for channel in range(OUT_CHANNELS):
#         matrix_q88 = feature_maps_q88[:, :, channel]

#         matrix_float = (
#             matrix_q88.astype(np.float64) / SCALE
#         )

#         np.savetxt(
#             f"{prefix}_channel_{channel}_q88.txt",
#             matrix_q88,
#             fmt="%d"
#         )

#         np.savetxt(
#             f"{prefix}_channel_{channel}_float.txt",
#             matrix_float,
#             fmt="%.6f"
#         )


# # ============================================================
# # CHƯƠNG TRÌNH CHÍNH
# # ============================================================

# def main() -> None:
#     pixel_u8, pixel_q88 = load_image_q88(IMAGE_FILE)

#     kernel_q88 = load_conv1_weights(WEIGHT_FILE)
#     bias_q88 = load_conv1_bias(BIAS_FILE)

#     conv_before_relu, conv_after_relu = calculate_conv1_q88(
#         image_q88=pixel_q88,
#         kernel_q88=kernel_q88,
#         bias_q88=bias_q88
#     )

#     print("Kích thước ảnh đầu vào:", pixel_q88.shape)
#     print("Kích thước kernel:", kernel_q88.shape)
#     print("Kích thước đầu ra Conv1:", conv_after_relu.shape)

#     print("\nBias Conv1 Q8.8:")
#     print(bias_q88)

#     for channel in range(OUT_CHANNELS):
#         print(f"\nKernel {channel + 1} dạng Q8.8:")
#         print(kernel_q88[:, :, channel])

#     print("\n5x5 giá trị đầu của feature map 1 trước ReLU:")
#     print(conv_before_relu[0:5, 0:5, 0])

#     print("\n5x5 giá trị đầu của feature map 1 sau ReLU:")
#     print(conv_after_relu[0:5, 0:5, 0])

#     save_feature_maps(
#         conv_before_relu,
#         "conv1_before_relu"
#     )

#     save_feature_maps(
#         conv_after_relu,
#         "conv1_after_relu"
#     )

#     print("\nĐã lưu 3 feature map Conv1 thành các file TXT.")


# if __name__ == "__main__":
#     main()






from pathlib import Path
from typing import Union

import matplotlib.pyplot as plt
import numpy as np
from PIL import Image


# ============================================================
# CẤU HÌNH
# ============================================================

IMAGE_FILE = Path(
    r"C:\Users\DELL\Desktop\CNN\CodePython\17.png"
)

# Đây là các file trọng số FLOAT được xuất từ Keras:
# np.savetxt("conv1_w.txt", conv1_w.reshape(-1), fmt="%.8f")
# np.savetxt("conv1_b.txt", conv1_b.reshape(-1), fmt="%.8f")
WEIGHT_FILE = Path(
    r"C:\Users\DELL\Desktop\CNN\CodePython\conv1_w.txt"
)

BIAS_FILE = Path(
    r"C:\Users\DELL\Desktop\CNN\CodePython\conv1_b.txt"
)

IMAGE_HEIGHT = 28
IMAGE_WIDTH = 28

KERNEL_SIZE = 5
IN_CHANNELS = 1
OUT_CHANNELS = 3

STRIDE = 1

# True: đảo ảnh nếu số đen trên nền trắng.
# False: số trắng trên nền đen giống MNIST.
INVERT_IMAGE = False


# ============================================================
# ĐỌC ẢNH VÀ CHUẨN HÓA SANG FLOAT
# ============================================================

def load_image_float(
    filename: Union[str, Path]
) -> tuple[np.ndarray, np.ndarray]:
    """
    Đọc ảnh grayscale, resize về 28x28 và chuẩn hóa pixel sang float.

    Trả về:
        pixel_u8:
            Ma trận uint8 kích thước 28x28, giá trị 0...255.

        pixel_float:
            Ma trận float64 kích thước 28x28, giá trị 0.0...1.0.
            Cách chuẩn hóa giống lúc train MNIST:
                pixel_float = pixel_u8 / 255.0
    """
    filename = Path(filename)

    if not filename.exists():
        raise FileNotFoundError(
            f"Không tìm thấy ảnh: {filename}"
        )

    image = Image.open(filename).convert("L")

    if image.size != (IMAGE_WIDTH, IMAGE_HEIGHT):
        image = image.resize(
            (IMAGE_WIDTH, IMAGE_HEIGHT),
            Image.Resampling.BILINEAR
        )

    pixel_u8 = np.asarray(image, dtype=np.uint8)

    if INVERT_IMAGE:
        pixel_u8 = 255 - pixel_u8

    pixel_float = (
        pixel_u8.astype(np.float64) / 255.0
    )

    return pixel_u8, pixel_float


# ============================================================
# ĐỌC KERNEL CONV1 DẠNG FLOAT
# ============================================================

def load_conv1_weights(
    filename: Union[str, Path]
) -> np.ndarray:
    """
    Đọc 75 hệ số kernel Conv1 dạng số thực float.

    Keras lưu kernel Conv2D theo shape:
        [kernel_row, kernel_col, input_channel, output_channel]

    Với Conv1:
        shape gốc = (5, 5, 1, 3)

    Vì input_channel = 1 nên chương trình trả về:
        kernel.shape = (5, 5, 3)

    Lưu ý:
        Đây là phép cross-correlation giống cách Conv2D của Keras tính,
        tức là không lật kernel.
    """
    filename = Path(filename)

    if not filename.exists():
        raise FileNotFoundError(
            f"Không tìm thấy file kernel: {filename}"
        )

    values = np.loadtxt(
        filename,
        dtype=np.float64
    ).reshape(-1)

    expected_count = (
        KERNEL_SIZE
        * KERNEL_SIZE
        * IN_CHANNELS
        * OUT_CHANNELS
    )

    if values.size != expected_count:
        raise ValueError(
            f"File kernel phải có {expected_count} giá trị, "
            f"nhưng hiện có {values.size}."
        )

    kernel_keras = values.reshape(
        KERNEL_SIZE,
        KERNEL_SIZE,
        IN_CHANNELS,
        OUT_CHANNELS
    )

    kernel = kernel_keras[:, :, 0, :]

    return kernel


# ============================================================
# ĐỌC BIAS CONV1 DẠNG FLOAT
# ============================================================

def load_conv1_bias(
    filename: Union[str, Path]
) -> np.ndarray:
    """
    Đọc 3 giá trị bias Conv1 dạng số thực float.
    """
    filename = Path(filename)

    if not filename.exists():
        print(
            f"Cảnh báo: không tìm thấy file bias: {filename}"
        )
        print("Tạm thời sử dụng bias = 0.")

        return np.zeros(
            OUT_CHANNELS,
            dtype=np.float64
        )

    bias = np.loadtxt(
        filename,
        dtype=np.float64
    ).reshape(-1)

    if bias.size != OUT_CHANNELS:
        raise ValueError(
            f"File bias phải có {OUT_CHANNELS} giá trị, "
            f"nhưng hiện có {bias.size}."
        )

    return bias


# ============================================================
# TÍNH CONV1 BẰNG FLOAT
# ============================================================

def calculate_conv1_float(
    image_float: np.ndarray,
    kernel_float: np.ndarray,
    bias_float: np.ndarray
) -> tuple[np.ndarray, np.ndarray]:
    """
    Tính Conv1 hoàn toàn bằng số thực float:

        vùng ảnh 5x5
             x
        kernel 5x5
             ↓
        nhân từng phần tử
             ↓
        cộng dồn 25 tích
             ↓
        cộng bias
             ↓
        ReLU

    Cấu hình:
        input:   28x28x1
        kernel:  5x5
        filter:  3
        stride:  1
        padding: valid

    Kết quả:
        conv_before_relu.shape = (24, 24, 3)
        conv_after_relu.shape  = (24, 24, 3)
    """
    if image_float.shape != (IMAGE_HEIGHT, IMAGE_WIDTH):
        raise ValueError(
            "Ảnh đầu vào phải có shape "
            f"({IMAGE_HEIGHT}, {IMAGE_WIDTH}), "
            f"nhưng hiện là {image_float.shape}."
        )

    expected_kernel_shape = (
        KERNEL_SIZE,
        KERNEL_SIZE,
        OUT_CHANNELS
    )

    if kernel_float.shape != expected_kernel_shape:
        raise ValueError(
            "Kernel phải có shape "
            f"{expected_kernel_shape}, "
            f"nhưng hiện là {kernel_float.shape}."
        )

    if bias_float.shape != (OUT_CHANNELS,):
        raise ValueError(
            f"Bias phải có shape ({OUT_CHANNELS},), "
            f"nhưng hiện là {bias_float.shape}."
        )

    output_height = (
        IMAGE_HEIGHT - KERNEL_SIZE
    ) // STRIDE + 1

    output_width = (
        IMAGE_WIDTH - KERNEL_SIZE
    ) // STRIDE + 1

    conv_before_relu = np.zeros(
        (output_height, output_width, OUT_CHANNELS),
        dtype=np.float64
    )

    for out_ch in range(OUT_CHANNELS):
        for out_row in range(output_height):
            for out_col in range(output_width):

                accumulator = 0.0

                for kh in range(KERNEL_SIZE):
                    for kw in range(KERNEL_SIZE):

                        image_row = (
                            out_row * STRIDE + kh
                        )

                        image_col = (
                            out_col * STRIDE + kw
                        )

                        pixel = image_float[
                            image_row,
                            image_col
                        ]

                        kernel_value = kernel_float[
                            kh,
                            kw,
                            out_ch
                        ]

                        accumulator += pixel * kernel_value

                conv_before_relu[
                    out_row,
                    out_col,
                    out_ch
                ] = accumulator + bias_float[out_ch]

    conv_after_relu = np.maximum(
        conv_before_relu,
        0.0
    )

    return conv_before_relu, conv_after_relu


# ============================================================
# HIỂN THỊ ẢNH VÀ FEATURE MAP
# ============================================================

def display_results(
    pixel_u8: np.ndarray,
    kernel_float: np.ndarray,
    conv_before_relu: np.ndarray,
    conv_after_relu: np.ndarray
) -> None:
    """
    Hiển thị trong một cửa sổ:
        Hàng 1: ảnh đầu vào và 3 kernel.
        Hàng 2: 3 feature map trước ReLU.
        Hàng 3: 3 feature map sau ReLU.
    """
    figure, axes = plt.subplots(
        3,
        4,
        figsize=(15, 11)
    )

    axes[0, 0].imshow(
        pixel_u8,
        cmap="gray",
        vmin=0,
        vmax=255
    )
    axes[0, 0].set_title("Ảnh đầu vào 28x28")
    axes[0, 0].axis("off")

    for channel in range(OUT_CHANNELS):
        kernel_map = kernel_float[:, :, channel]

        kernel_image = axes[0, channel + 1].imshow(
            kernel_map
        )

        axes[0, channel + 1].set_title(
            f"Kernel Conv1 - Filter {channel + 1}"
        )
        axes[0, channel + 1].axis("off")

        figure.colorbar(
            kernel_image,
            ax=axes[0, channel + 1],
            fraction=0.046,
            pad=0.04
        )

    axes[1, 0].axis("off")
    axes[1, 0].text(
        0.5,
        0.5,
        "Sau Convolution\n+ Bias\nTrước ReLU",
        ha="center",
        va="center",
        fontsize=14
    )

    for channel in range(OUT_CHANNELS):
        feature_map = conv_before_relu[:, :, channel]

        before_image = axes[1, channel + 1].imshow(
            feature_map
        )

        axes[1, channel + 1].set_title(
            f"Filter {channel + 1} - Trước ReLU"
        )
        axes[1, channel + 1].axis("off")

        figure.colorbar(
            before_image,
            ax=axes[1, channel + 1],
            fraction=0.046,
            pad=0.04
        )

    axes[2, 0].axis("off")
    axes[2, 0].text(
        0.5,
        0.5,
        "Sau ReLU\nGiá trị âm → 0",
        ha="center",
        va="center",
        fontsize=14
    )

    for channel in range(OUT_CHANNELS):
        feature_map = conv_after_relu[:, :, channel]

        after_image = axes[2, channel + 1].imshow(
            feature_map
        )

        axes[2, channel + 1].set_title(
            f"Filter {channel + 1} - Sau ReLU"
        )
        axes[2, channel + 1].axis("off")

        figure.colorbar(
            after_image,
            ax=axes[2, channel + 1],
            fraction=0.046,
            pad=0.04
        )

    figure.suptitle(
        "So sánh ảnh đầu vào, kernel, Conv1 và ReLU",
        fontsize=16
    )

    figure.tight_layout()
    plt.show()


# ============================================================
# IN THÔNG TIN KIỂM TRA
# ============================================================

def print_debug_information(
    pixel_float: np.ndarray,
    kernel_float: np.ndarray,
    bias_float: np.ndarray,
    conv_before_relu: np.ndarray,
    conv_after_relu: np.ndarray
) -> None:
    print("============================================")
    print("THÔNG TIN DỮ LIỆU")
    print("============================================")

    print("Ảnh float shape:", pixel_float.shape)
    print(
        "Ảnh float min/max:",
        float(pixel_float.min()),
        float(pixel_float.max())
    )

    print("Kernel shape:", kernel_float.shape)
    print(
        "Kernel min/max:",
        float(kernel_float.min()),
        float(kernel_float.max())
    )
    print(
        "Số hệ số kernel khác 0:",
        int(np.count_nonzero(kernel_float))
    )

    print("Bias:", bias_float)

    print("Conv1 trước ReLU shape:", conv_before_relu.shape)
    print(
        "Conv1 trước ReLU min/max:",
        float(conv_before_relu.min()),
        float(conv_before_relu.max())
    )

    print(
        "Conv1 sau ReLU min/max:",
        float(conv_after_relu.min()),
        float(conv_after_relu.max())
    )

    negative_count = int(
        np.count_nonzero(conv_before_relu < 0)
    )

    zero_after_relu_count = int(
        np.count_nonzero(conv_after_relu == 0)
    )

    total_values = int(conv_before_relu.size)

    print(
        "Số giá trị âm trước ReLU:",
        negative_count,
        "/",
        total_values
    )

    print(
        "Số giá trị bằng 0 sau ReLU:",
        zero_after_relu_count,
        "/",
        total_values
    )

    for channel in range(OUT_CHANNELS):
        print("\n--------------------------------------------")
        print(f"KERNEL FILTER {channel + 1}")
        print("--------------------------------------------")
        print(kernel_float[:, :, channel])

        print(
            f"Feature map {channel + 1} trước ReLU min/max:",
            float(conv_before_relu[:, :, channel].min()),
            float(conv_before_relu[:, :, channel].max())
        )

        print(
            f"Feature map {channel + 1} sau ReLU min/max:",
            float(conv_after_relu[:, :, channel].min()),
            float(conv_after_relu[:, :, channel].max())
        )


# ============================================================
# CHƯƠNG TRÌNH CHÍNH
# ============================================================

def main() -> None:
    pixel_u8, pixel_float = load_image_float(
        IMAGE_FILE
    )

    kernel_float = load_conv1_weights(
        WEIGHT_FILE
    )

    bias_float = load_conv1_bias(
        BIAS_FILE
    )

    conv_before_relu, conv_after_relu = (
        calculate_conv1_float(
            image_float=pixel_float,
            kernel_float=kernel_float,
            bias_float=bias_float
        )
    )

    print_debug_information(
        pixel_float=pixel_float,
        kernel_float=kernel_float,
        bias_float=bias_float,
        conv_before_relu=conv_before_relu,
        conv_after_relu=conv_after_relu
    )

    display_results(
        pixel_u8=pixel_u8,
        kernel_float=kernel_float,
        conv_before_relu=conv_before_relu,
        conv_after_relu=conv_after_relu
    )


if __name__ == "__main__":
    main()




