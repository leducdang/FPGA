from pathlib import Path
from typing import Tuple

import matplotlib.pyplot as plt
import numpy as np
from PIL import Image


# ============================================================
# ĐƯỜNG DẪN FILE
# ============================================================

IMAGE_FILE = Path(
    r"C:\Users\DELL\Desktop\CNN\CodePython\6_test.png"
)

# Thư mục trọng số được tạo bởi chương trình train mạng 8 -> 16 filter
WEIGHTS_FOLDER = Path(
    r"C:\Users\DELL\Desktop\CNN\weights_float_8_16"
)

CONV1_WEIGHT_FILE = WEIGHTS_FOLDER / "conv1_w.txt"
CONV1_BIAS_FILE   = WEIGHTS_FOLDER / "conv1_b.txt"

CONV2_WEIGHT_FILE = WEIGHTS_FOLDER / "conv2_w.txt"
CONV2_BIAS_FILE   = WEIGHTS_FOLDER / "conv2_b.txt"

FC_WEIGHT_FILE = WEIGHTS_FOLDER / "fc_w.txt"
FC_BIAS_FILE   = WEIGHTS_FOLDER / "fc_b.txt"


# ============================================================
# CẤU HÌNH MẠNG 8 -> 16 FILTER
# ============================================================

IMAGE_HEIGHT = 28
IMAGE_WIDTH = 28

CONV1_KERNEL_SIZE = 5
CONV1_INPUT_CHANNELS = 1
CONV1_OUTPUT_CHANNELS = 8

CONV2_KERNEL_SIZE = 5
CONV2_INPUT_CHANNELS = 8
CONV2_OUTPUT_CHANNELS = 16

CONV_STRIDE = 1

POOL_SIZE = 2
POOL_STRIDE = 2

# Pool2: 4 × 4 × 16
FLATTEN_SIZE = 4 * 4 * 16
NUMBER_OF_CLASSES = 10

# True: ảnh gốc là số đen trên nền trắng
# False: ảnh đã là số trắng trên nền đen giống MNIST
INVERT_IMAGE = True


# ============================================================
# ĐỌC ẢNH VÀ CHUẨN HÓA
# ============================================================

def load_image_float(
    filename: Path
) -> Tuple[np.ndarray, np.ndarray]:

    filename = Path(filename)

    if not filename.exists():
        raise FileNotFoundError(
            f"Không tìm thấy ảnh: {filename}"
        )

    image = Image.open(filename).convert("L")

    if image.size != (IMAGE_WIDTH, IMAGE_HEIGHT):
        if hasattr(Image, "Resampling"):
            resize_mode = Image.Resampling.BILINEAR
        else:
            resize_mode = Image.BILINEAR

        image = image.resize(
            (IMAGE_WIDTH, IMAGE_HEIGHT),
            resize_mode
        )

    pixel_u8 = np.asarray(
        image,
        dtype=np.uint8
    )

    if INVERT_IMAGE:
        pixel_u8 = 255 - pixel_u8

    pixel_float = (
        pixel_u8.astype(np.float64) / 255.0
    )

    return pixel_u8, pixel_float


# ============================================================
# ĐỌC TRỌNG SỐ CONVOLUTION
# ============================================================

def load_conv_weights(
    filename: Path,
    kernel_size: int,
    input_channels: int,
    output_channels: int
) -> np.ndarray:

    filename = Path(filename)

    if not filename.exists():
        raise FileNotFoundError(
            f"Không tìm thấy file trọng số: {filename}"
        )

    values = np.loadtxt(
        filename,
        dtype=np.float64
    ).reshape(-1)

    expected_count = (
        kernel_size
        * kernel_size
        * input_channels
        * output_channels
    )

    if values.size != expected_count:
        raise ValueError(
            f"File {filename.name} phải có "
            f"{expected_count} giá trị, "
            f"nhưng hiện có {values.size}."
        )

    # Shape Keras:
    # [kernel_row, kernel_col, input_channel, output_channel]
    return values.reshape(
        kernel_size,
        kernel_size,
        input_channels,
        output_channels
    )


# ============================================================
# ĐỌC BIAS
# ============================================================

def load_bias(
    filename: Path,
    output_size: int
) -> np.ndarray:

    filename = Path(filename)

    if not filename.exists():
        raise FileNotFoundError(
            f"Không tìm thấy file bias: {filename}"
        )

    bias = np.loadtxt(
        filename,
        dtype=np.float64
    ).reshape(-1)

    if bias.size != output_size:
        raise ValueError(
            f"File {filename.name} phải có "
            f"{output_size} bias, "
            f"nhưng hiện có {bias.size}."
        )

    return bias


# ============================================================
# CONVOLUTION NHIỀU KÊNH
# ============================================================

def convolution_float(
    input_tensor: np.ndarray,
    kernel: np.ndarray,
    bias: np.ndarray,
    stride: int = 1
) -> np.ndarray:

    input_height = input_tensor.shape[0]
    input_width = input_tensor.shape[1]
    input_channels = input_tensor.shape[2]

    kernel_height = kernel.shape[0]
    kernel_width = kernel.shape[1]
    kernel_input_channels = kernel.shape[2]
    output_channels = kernel.shape[3]

    if input_channels != kernel_input_channels:
        raise ValueError(
            f"Input có {input_channels} kênh, "
            f"kernel cần {kernel_input_channels} kênh."
        )

    if bias.shape != (output_channels,):
        raise ValueError(
            f"Bias phải có shape ({output_channels},), "
            f"nhưng hiện là {bias.shape}."
        )

    output_height = (
        input_height - kernel_height
    ) // stride + 1

    output_width = (
        input_width - kernel_width
    ) // stride + 1

    output = np.zeros(
        (
            output_height,
            output_width,
            output_channels
        ),
        dtype=np.float64
    )

    for out_ch in range(output_channels):
        for out_row in range(output_height):
            for out_col in range(output_width):

                accumulator = 0.0

                for kh in range(kernel_height):
                    for kw in range(kernel_width):
                        for in_ch in range(input_channels):

                            input_row = out_row * stride + kh
                            input_col = out_col * stride + kw

                            accumulator += (
                                input_tensor[
                                    input_row,
                                    input_col,
                                    in_ch
                                ]
                                *
                                kernel[
                                    kh,
                                    kw,
                                    in_ch,
                                    out_ch
                                ]
                            )

                output[
                    out_row,
                    out_col,
                    out_ch
                ] = accumulator + bias[out_ch]

    return output


# ============================================================
# RELU
# ============================================================

def relu_float(
    input_tensor: np.ndarray
) -> np.ndarray:

    return np.maximum(
        input_tensor,
        0.0
    )


# ============================================================
# MAX POOLING
# ============================================================

def max_pooling_float(
    input_tensor: np.ndarray,
    pool_size: int = 2,
    stride: int = 2
) -> np.ndarray:

    input_height = input_tensor.shape[0]
    input_width = input_tensor.shape[1]
    channels = input_tensor.shape[2]

    output_height = (
        input_height - pool_size
    ) // stride + 1

    output_width = (
        input_width - pool_size
    ) // stride + 1

    output = np.zeros(
        (
            output_height,
            output_width,
            channels
        ),
        dtype=np.float64
    )

    for channel in range(channels):
        for out_row in range(output_height):
            for out_col in range(output_width):

                row_start = out_row * stride
                col_start = out_col * stride

                pooling_window = input_tensor[
                    row_start:row_start + pool_size,
                    col_start:col_start + pool_size,
                    channel
                ]

                output[
                    out_row,
                    out_col,
                    channel
                ] = np.max(pooling_window)

    return output


# ============================================================
# FLATTEN
# ============================================================

def flatten_float(
    input_tensor: np.ndarray
) -> np.ndarray:
    """
    Pool2:
        4×4×16

    Kết quả:
        256 giá trị.
    """

    flatten_vector = input_tensor.reshape(-1)

    if flatten_vector.size != FLATTEN_SIZE:
        raise ValueError(
            f"Flatten phải có {FLATTEN_SIZE} phần tử, "
            f"nhưng hiện có {flatten_vector.size}."
        )

    return flatten_vector


# ============================================================
# ĐỌC TRỌNG SỐ FULLY CONNECTED
# ============================================================

def load_fc_weights(
    filename: Path
) -> np.ndarray:
    """
    Dense Keras:
        [input_size, output_size]

    Với mạng 8 -> 16 filter:
        [256, 10]
    """

    filename = Path(filename)

    if not filename.exists():
        raise FileNotFoundError(
            f"Không tìm thấy file FC: {filename}"
        )

    values = np.loadtxt(
        filename,
        dtype=np.float64
    ).reshape(-1)

    expected_count = (
        FLATTEN_SIZE
        * NUMBER_OF_CLASSES
    )

    if values.size != expected_count:
        raise ValueError(
            f"File {filename.name} phải có "
            f"{expected_count} trọng số, "
            f"nhưng hiện có {values.size}."
        )

    return values.reshape(
        FLATTEN_SIZE,
        NUMBER_OF_CLASSES
    )


# ============================================================
# FULLY CONNECTED
# ============================================================

def fully_connected_float(
    flatten_vector: np.ndarray,
    fc_weights: np.ndarray,
    fc_bias: np.ndarray
) -> np.ndarray:

    if flatten_vector.shape != (FLATTEN_SIZE,):
        raise ValueError(
            f"Flatten phải có shape ({FLATTEN_SIZE},), "
            f"nhưng hiện là {flatten_vector.shape}."
        )

    if fc_weights.shape != (
        FLATTEN_SIZE,
        NUMBER_OF_CLASSES
    ):
        raise ValueError(
            f"FC weight phải có shape "
            f"({FLATTEN_SIZE}, {NUMBER_OF_CLASSES}), "
            f"nhưng hiện là {fc_weights.shape}."
        )

    logits = np.zeros(
        NUMBER_OF_CLASSES,
        dtype=np.float64
    )

    for output_class in range(
        NUMBER_OF_CLASSES
    ):

        accumulator = 0.0

        for input_index in range(
            FLATTEN_SIZE
        ):

            accumulator += (
                flatten_vector[input_index]
                *
                fc_weights[
                    input_index,
                    output_class
                ]
            )

        logits[output_class] = (
            accumulator + fc_bias[output_class]
        )

    return logits


# ============================================================
# SOFTMAX
# ============================================================

def softmax_float(
    logits: np.ndarray
) -> np.ndarray:

    shifted_logits = logits - np.max(logits)
    exponential = np.exp(shifted_logits)

    return (
        exponential / np.sum(exponential)
    )


# ============================================================
# HIỂN THỊ 16 FEATURE MAP POOL2
# ============================================================

def display_pool2_maps(
    pool2: np.ndarray
) -> None:

    figure, axes = plt.subplots(
        4,
        4,
        figsize=(14, 12)
    )

    axes_flat = axes.reshape(-1)

    for channel in range(
        CONV2_OUTPUT_CHANNELS
    ):

        image_plot = axes_flat[channel].imshow(
            pool2[:, :, channel]
        )

        axes_flat[channel].set_title(
            f"Pool2 - Kênh {channel + 1}\n4×4"
        )

        axes_flat[channel].axis("off")

        figure.colorbar(
            image_plot,
            ax=axes_flat[channel],
            fraction=0.046,
            pad=0.04
        )

    figure.suptitle(
        "16 feature map sau Max Pooling 2",
        fontsize=15
    )

    figure.tight_layout()
    plt.show()


# ============================================================
# HIỂN THỊ KẾT QUẢ
# ============================================================

def display_result(
    pixel_u8: np.ndarray,
    flatten_vector: np.ndarray,
    logits: np.ndarray,
    probabilities: np.ndarray,
    predicted_digit: int
) -> None:

    digits = np.arange(
        NUMBER_OF_CLASSES
    )

    figure, axes = plt.subplots(
        2,
        2,
        figsize=(12, 9)
    )

    axes[0, 0].imshow(
        pixel_u8,
        cmap="gray",
        vmin=0,
        vmax=255
    )

    axes[0, 0].set_title(
        f"Ảnh đầu vào\nKết quả: số {predicted_digit}",
        fontsize=14
    )

    axes[0, 0].axis("off")

    axes[0, 1].plot(
        np.arange(FLATTEN_SIZE),
        flatten_vector,
        marker=".",
        markersize=3
    )

    axes[0, 1].set_title(
        "Vector Flatten - 256 giá trị"
    )

    axes[0, 1].set_xlabel(
        "Chỉ số"
    )

    axes[0, 1].set_ylabel(
        "Giá trị đặc trưng"
    )

    axes[0, 1].grid(
        alpha=0.3
    )

    axes[1, 0].bar(
        digits,
        logits
    )

    axes[1, 0].set_xticks(
        digits
    )

    axes[1, 0].set_xlabel(
        "Chữ số"
    )

    axes[1, 0].set_ylabel(
        "Điểm Fully Connected"
    )

    axes[1, 0].set_title(
        "10 điểm đầu ra trước Softmax"
    )

    axes[1, 0].grid(
        axis="y",
        alpha=0.3
    )

    axes[1, 1].bar(
        digits,
        probabilities * 100.0
    )

    axes[1, 1].set_xticks(
        digits
    )

    axes[1, 1].set_ylim(
        0,
        100
    )

    axes[1, 1].set_xlabel(
        "Chữ số"
    )

    axes[1, 1].set_ylabel(
        "Xác suất (%)"
    )

    axes[1, 1].set_title(
        f"Dự đoán số {predicted_digit}\n"
        f"Độ tin cậy "
        f"{probabilities[predicted_digit] * 100.0:.2f}%"
    )

    axes[1, 1].grid(
        axis="y",
        alpha=0.3
    )

    figure.suptitle(
        "CNN 8 → 16 filter: "
        "Pool2 → Flatten → Fully Connected → Softmax",
        fontsize=15
    )

    figure.tight_layout()
    plt.show()


# ============================================================
# IN THÔNG TIN TENSOR
# ============================================================

def print_tensor_info(
    name: str,
    tensor: np.ndarray
) -> None:

    print(
        f"{name}: "
        f"shape={tensor.shape}, "
        f"min={tensor.min():.6f}, "
        f"max={tensor.max():.6f}"
    )


# ============================================================
# CHƯƠNG TRÌNH CHÍNH
# ============================================================

def print_architecture() -> None:
    print("============================================")
    print("CNN ARCHITECTURE 8 -> 16")
    print("============================================")
    print("Input : 28x28x1")
    print("Conv1 : 24x24x8")
    print("Pool1 : 12x12x8")
    print("Conv2 : 8x8x16")
    print("Pool2 : 4x4x16")
    print("Flatten:", FLATTEN_SIZE)
    print("FC    : 256 -> 10")
    print("============================================")


def main() -> None:

    print_architecture()

    # 1. Đọc ảnh
    pixel_u8, pixel_float = load_image_float(
        IMAGE_FILE
    )

    input_tensor = pixel_float[:, :, np.newaxis]

    # 2. Conv1: 28×28×1 → 24×24×8
    conv1_weights = load_conv_weights(
        filename=CONV1_WEIGHT_FILE,
        kernel_size=CONV1_KERNEL_SIZE,
        input_channels=CONV1_INPUT_CHANNELS,
        output_channels=CONV1_OUTPUT_CHANNELS
    )

    conv1_bias = load_bias(
        filename=CONV1_BIAS_FILE,
        output_size=CONV1_OUTPUT_CHANNELS
    )

    conv1_before_relu = convolution_float(
        input_tensor=input_tensor,
        kernel=conv1_weights,
        bias=conv1_bias,
        stride=CONV_STRIDE
    )

    conv1_after_relu = relu_float(
        conv1_before_relu
    )

    # 3. Pool1: 24×24×8 → 12×12×8
    pool1 = max_pooling_float(
        input_tensor=conv1_after_relu,
        pool_size=POOL_SIZE,
        stride=POOL_STRIDE
    )

    # 4. Conv2: 12×12×8 → 8×8×16
    conv2_weights = load_conv_weights(
        filename=CONV2_WEIGHT_FILE,
        kernel_size=CONV2_KERNEL_SIZE,
        input_channels=CONV2_INPUT_CHANNELS,
        output_channels=CONV2_OUTPUT_CHANNELS
    )

    conv2_bias = load_bias(
        filename=CONV2_BIAS_FILE,
        output_size=CONV2_OUTPUT_CHANNELS
    )

    conv2_before_relu = convolution_float(
        input_tensor=pool1,
        kernel=conv2_weights,
        bias=conv2_bias,
        stride=CONV_STRIDE
    )

    conv2_after_relu = relu_float(
        conv2_before_relu
    )

    # 5. Pool2: 8×8×16 → 4×4×16
    pool2 = max_pooling_float(
        input_tensor=conv2_after_relu,
        pool_size=POOL_SIZE,
        stride=POOL_STRIDE
    )

    # 6. Flatten: 4×4×16 → 256
    flatten_vector = flatten_float(
        pool2
    )

    # 7. Fully Connected: 256 → 10
    fc_weights = load_fc_weights(
        FC_WEIGHT_FILE
    )

    fc_bias = load_bias(
        filename=FC_BIAS_FILE,
        output_size=NUMBER_OF_CLASSES
    )

    logits = fully_connected_float(
        flatten_vector=flatten_vector,
        fc_weights=fc_weights,
        fc_bias=fc_bias
    )

    # 8. Softmax và Argmax
    probabilities = softmax_float(
        logits
    )

    predicted_digit = int(
        np.argmax(logits)
    )

    # 9. In kết quả
    print("============================================")
    print("KẾT QUẢ CNN 8 -> 16 FILTER")
    print("============================================")

    print_tensor_info("Input", input_tensor)
    print_tensor_info("Conv1 sau ReLU", conv1_after_relu)
    print_tensor_info("Pool1", pool1)
    print_tensor_info("Conv2 sau ReLU", conv2_after_relu)
    print_tensor_info("Pool2", pool2)

    print("Flatten shape:", flatten_vector.shape)
    print("Conv1 weight shape:", conv1_weights.shape)
    print("Conv2 weight shape:", conv2_weights.shape)
    print("FC weight shape:", fc_weights.shape)

    print("\n10 điểm Fully Connected:")

    for digit in range(NUMBER_OF_CLASSES):
        print(
            f"Số {digit}: "
            f"logit = {logits[digit]:.6f}"
        )

    print("\nXác suất Softmax:")

    for digit in range(NUMBER_OF_CLASSES):
        print(
            f"Số {digit}: "
            f"{probabilities[digit] * 100.0:.4f}%"
        )

    print("\n============================================")
    print(
        f"KẾT QUẢ NHẬN DẠNG: SỐ {predicted_digit}"
    )
    print(
        f"ĐỘ TIN CẬY: "
        f"{probabilities[predicted_digit] * 100.0:.2f}%"
    )
    print("============================================")

    # 10. Hiển thị
    display_pool2_maps(
        pool2
    )

    display_result(
        pixel_u8=pixel_u8,
        flatten_vector=flatten_vector,
        logits=logits,
        probabilities=probabilities,
        predicted_digit=predicted_digit
    )


if __name__ == "__main__":
    main()
