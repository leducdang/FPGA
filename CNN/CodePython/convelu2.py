from pathlib import Path
from typing import Tuple

import matplotlib.pyplot as plt
import numpy as np
from PIL import Image


# ============================================================
# ĐƯỜNG DẪN DỮ LIỆU
# ============================================================

IMAGE_FILE = Path(
    r"C:\Users\DELL\Desktop\CNN\CodePython\17.png"
)

CONV1_WEIGHT_FILE = Path(
    r"C:\Users\DELL\Desktop\CNN\CodePython\conv1_w.txt"
)

CONV1_BIAS_FILE = Path(
    r"C:\Users\DELL\Desktop\CNN\CodePython\conv1_b.txt"
)

CONV2_WEIGHT_FILE = Path(
    r"C:\Users\DELL\Desktop\CNN\CodePython\conv2_w.txt"
)

CONV2_BIAS_FILE = Path(
    r"C:\Users\DELL\Desktop\CNN\CodePython\conv2_b.txt"
)


# ============================================================
# CẤU HÌNH MẠNG CNN
# ============================================================

IMAGE_HEIGHT = 28
IMAGE_WIDTH = 28

CONV1_KERNEL_SIZE = 5
CONV1_INPUT_CHANNELS = 1
CONV1_OUTPUT_CHANNELS = 3

CONV2_KERNEL_SIZE = 5
CONV2_INPUT_CHANNELS = 3
CONV2_OUTPUT_CHANNELS = 3

CONV_STRIDE = 1

POOL_SIZE = 2
POOL_STRIDE = 2

# False: số trắng trên nền đen giống MNIST
# True: số đen trên nền trắng
INVERT_IMAGE = False


# ============================================================
# ĐỌC ẢNH VÀ CHUẨN HÓA 0...1
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

    # Chuẩn hóa giống lúc train MNIST
    pixel_float = (
        pixel_u8.astype(np.float64) / 255.0
    )

    return pixel_u8, pixel_float


# ============================================================
# ĐỌC TRỌNG SỐ CONVOLUTION DẠNG FLOAT
# ============================================================

def load_conv_weights(
    filename: Path,
    kernel_size: int,
    input_channels: int,
    output_channels: int
) -> np.ndarray:
    """
    Keras lưu trọng số Conv2D theo dạng:

        [kernel_row,
         kernel_col,
         input_channel,
         output_channel]

    Conv1:
        5×5×1×3 = 75 trọng số

    Conv2:
        5×5×3×3 = 225 trọng số
    """

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

    kernel = values.reshape(
        kernel_size,
        kernel_size,
        input_channels,
        output_channels
    )

    return kernel


# ============================================================
# ĐỌC BIAS FLOAT
# ============================================================

def load_bias(
    filename: Path,
    output_channels: int
) -> np.ndarray:

    filename = Path(filename)

    if not filename.exists():
        print(
            f"Cảnh báo: không tìm thấy {filename}."
        )
        print("Tạm thời sử dụng bias bằng 0.")

        return np.zeros(
            output_channels,
            dtype=np.float64
        )

    bias = np.loadtxt(
        filename,
        dtype=np.float64
    ).reshape(-1)

    if bias.size != output_channels:
        raise ValueError(
            f"File bias phải có {output_channels} giá trị, "
            f"nhưng hiện có {bias.size}."
        )

    return bias


# ============================================================
# TÍNH CONVOLUTION NHIỀU KÊNH
# ============================================================

def convolution_float(
    input_tensor: np.ndarray,
    kernel: np.ndarray,
    bias: np.ndarray,
    stride: int = 1
) -> np.ndarray:
    """
    input_tensor:
        [height, width, input_channels]

    kernel:
        [kernel_height,
         kernel_width,
         input_channels,
         output_channels]

    output:
        [output_height,
         output_width,
         output_channels]

    Cách tính giống Conv2D của Keras:
    không lật kernel.
    """

    if input_tensor.ndim != 3:
        raise ValueError(
            "Input phải có dạng [height, width, channels]."
        )

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
            f"nhưng kernel yêu cầu "
            f"{kernel_input_channels} kênh."
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

    # Mỗi out_ch tạo ra một feature map
    for out_ch in range(output_channels):

        for out_row in range(output_height):

            for out_col in range(output_width):

                accumulator = 0.0

                # Quét kernel trên tất cả kênh đầu vào
                for kh in range(kernel_height):

                    for kw in range(kernel_width):

                        for in_ch in range(input_channels):

                            input_row = (
                                out_row * stride + kh
                            )

                            input_col = (
                                out_col * stride + kw
                            )

                            pixel_value = input_tensor[
                                input_row,
                                input_col,
                                in_ch
                            ]

                            kernel_value = kernel[
                                kh,
                                kw,
                                in_ch,
                                out_ch
                            ]

                            accumulator += (
                                pixel_value * kernel_value
                            )

                # Cộng bias của output filter
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
    """
    Max Pooling áp dụng độc lập trên từng kênh.
    """

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
# HIỂN THỊ FEATURE MAP
# ============================================================

def display_feature_maps(
    pixel_u8: np.ndarray,
    conv1_after_relu: np.ndarray,
    pool1: np.ndarray,
    conv2_before_relu: np.ndarray,
    conv2_after_relu: np.ndarray,
    pool2: np.ndarray
) -> None:

    # --------------------------------------------------------
    # Hiển thị ảnh đầu vào
    # --------------------------------------------------------

    plt.figure(figsize=(4, 4))

    plt.imshow(
        pixel_u8,
        cmap="gray",
        vmin=0,
        vmax=255
    )

    plt.title("Ảnh đầu vào 28×28")
    plt.axis("off")
    plt.tight_layout()

    # --------------------------------------------------------
    # Hiển thị các giai đoạn CNN
    # --------------------------------------------------------

    stage_tensors = [
        conv1_after_relu,
        pool1,
        conv2_before_relu,
        conv2_after_relu,
        pool2
    ]

    stage_names = [
        "Conv1 sau ReLU\n24×24×3",
        "Max Pooling 1\n12×12×3",
        "Conv2 trước ReLU\n8×8×3",
        "Conv2 sau ReLU\n8×8×3",
        "Max Pooling 2\n4×4×3"
    ]

    number_of_stages = len(stage_tensors)

    figure, axes = plt.subplots(
        number_of_stages,
        CONV2_OUTPUT_CHANNELS,
        figsize=(13, 17)
    )

    for stage_index in range(number_of_stages):

        tensor = stage_tensors[stage_index]

        for channel in range(
            CONV2_OUTPUT_CHANNELS
        ):

            feature_map = tensor[:, :, channel]

            image_plot = axes[
                stage_index,
                channel
            ].imshow(feature_map)

            axes[
                stage_index,
                channel
            ].set_title(
                f"{stage_names[stage_index]}\n"
                f"Kênh {channel + 1}"
            )

            axes[
                stage_index,
                channel
            ].axis("off")

            figure.colorbar(
                image_plot,
                ax=axes[stage_index, channel],
                fraction=0.046,
                pad=0.04
            )

    figure.suptitle(
        "Luồng xử lý Conv1 → Pool1 → Conv2 → Pool2",
        fontsize=16
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

def main() -> None:

    # --------------------------------------------------------
    # 1. Đọc ảnh 28×28
    # --------------------------------------------------------

    pixel_u8, pixel_float = load_image_float(
        IMAGE_FILE
    )

    # Thêm chiều channel:
    # 28×28 → 28×28×1
    input_tensor = pixel_float[:, :, np.newaxis]

    # --------------------------------------------------------
    # 2. Đọc trọng số Conv1
    # --------------------------------------------------------

    conv1_kernel = load_conv_weights(
        filename=CONV1_WEIGHT_FILE,
        kernel_size=CONV1_KERNEL_SIZE,
        input_channels=CONV1_INPUT_CHANNELS,
        output_channels=CONV1_OUTPUT_CHANNELS
    )

    conv1_bias = load_bias(
        filename=CONV1_BIAS_FILE,
        output_channels=CONV1_OUTPUT_CHANNELS
    )

    # --------------------------------------------------------
    # 3. Conv1: 28×28×1 → 24×24×3
    # --------------------------------------------------------

    conv1_before_relu = convolution_float(
        input_tensor=input_tensor,
        kernel=conv1_kernel,
        bias=conv1_bias,
        stride=CONV_STRIDE
    )

    conv1_after_relu = relu_float(
        conv1_before_relu
    )

    # --------------------------------------------------------
    # 4. Pool1: 24×24×3 → 12×12×3
    # --------------------------------------------------------

    pool1 = max_pooling_float(
        input_tensor=conv1_after_relu,
        pool_size=POOL_SIZE,
        stride=POOL_STRIDE
    )

    # --------------------------------------------------------
    # 5. Đọc trọng số Conv2
    # --------------------------------------------------------

    conv2_kernel = load_conv_weights(
        filename=CONV2_WEIGHT_FILE,
        kernel_size=CONV2_KERNEL_SIZE,
        input_channels=CONV2_INPUT_CHANNELS,
        output_channels=CONV2_OUTPUT_CHANNELS
    )

    conv2_bias = load_bias(
        filename=CONV2_BIAS_FILE,
        output_channels=CONV2_OUTPUT_CHANNELS
    )

    # --------------------------------------------------------
    # 6. Conv2: 12×12×3 → 8×8×3
    # --------------------------------------------------------

    conv2_before_relu = convolution_float(
        input_tensor=pool1,
        kernel=conv2_kernel,
        bias=conv2_bias,
        stride=CONV_STRIDE
    )

    # --------------------------------------------------------
    # 7. ReLU2
    # --------------------------------------------------------

    conv2_after_relu = relu_float(
        conv2_before_relu
    )

    # --------------------------------------------------------
    # 8. Pool2: 8×8×3 → 4×4×3
    # --------------------------------------------------------

    pool2 = max_pooling_float(
        input_tensor=conv2_after_relu,
        pool_size=POOL_SIZE,
        stride=POOL_STRIDE
    )

    # --------------------------------------------------------
    # 9. In kích thước và giá trị
    # --------------------------------------------------------

    print("========================================")
    print("KẾT QUẢ CÁC LỚP CNN")
    print("========================================")

    print_tensor_info(
        "Ảnh đầu vào",
        input_tensor
    )

    print_tensor_info(
        "Conv1 trước ReLU",
        conv1_before_relu
    )

    print_tensor_info(
        "Conv1 sau ReLU",
        conv1_after_relu
    )

    print_tensor_info(
        "Pool1",
        pool1
    )

    print_tensor_info(
        "Conv2 trước ReLU",
        conv2_before_relu
    )

    print_tensor_info(
        "Conv2 sau ReLU",
        conv2_after_relu
    )

    print_tensor_info(
        "Pool2",
        pool2
    )

    print("\nConv1 kernel shape:")
    print(conv1_kernel.shape)

    print("\nConv2 kernel shape:")
    print(conv2_kernel.shape)

    print("\nConv2 bias:")
    print(conv2_bias)

    # --------------------------------------------------------
    # 10. Hiển thị feature map
    # --------------------------------------------------------

    display_feature_maps(
        pixel_u8=pixel_u8,
        conv1_after_relu=conv1_after_relu,
        pool1=pool1,
        conv2_before_relu=conv2_before_relu,
        conv2_after_relu=conv2_after_relu,
        pool2=pool2
    )


if __name__ == "__main__":
    main()

    