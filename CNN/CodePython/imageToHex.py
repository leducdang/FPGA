import cv2
import numpy as np


def convert_image_to_hex(image_path, output_hex_path):
    # ============================================================
    # 1. Đọc ảnh grayscale
    # ============================================================
    img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)

    if img is None:
        print(
            f"Lỗi: Không tìm thấy hoặc không thể mở ảnh tại:\n"
            f"{image_path}"
        )
        return

    # ============================================================
    # 2. Resize về đúng 28x28
    # ============================================================
    if img.shape != (28, 28):
        img = cv2.resize(
            img,
            (28, 28),
            interpolation=cv2.INTER_AREA
        )

        print("Ảnh đã được resize về 28x28.")

    # ============================================================
    # 3. ĐẢO ẢNH
    #
    # Ảnh ban đầu:
    #       nền trắng = 255
    #       số đen     = 0
    #
    # Sau khi đảo:
    #       nền đen    = 0
    #       số trắng   = 255
    #
    # Đây là dạng giống MNIST
    # ============================================================
    img = 255 - img

    # ============================================================
    # OPTIONAL:
    # Nếu muốn ép nền thật sự về 0 và nét số rõ hơn,
    # có thể bật threshold phía dưới.
    #
    # Nếu chưa cần thì để comment.
    # ============================================================

    # _, img = cv2.threshold(
    #     img,
    #     30,
    #     255,
    #     cv2.THRESH_TOZERO
    # )

    # ============================================================
    # 4. Flatten theo thứ tự:
    #
    # pixel[0]   = row 0, col 0
    # pixel[1]   = row 0, col 1
    # ...
    # pixel[27]  = row 0, col 27
    # pixel[28]  = row 1, col 0
    # ...
    # pixel[783] = row 27, col 27
    #
    # Khớp với:
    # idx_image = row * 28 + col
    # ============================================================
    flattened_img = img.flatten()

    # ============================================================
    # 5. Ghi HEX
    #
    # Mỗi pixel:
    #       8-bit
    #       00 -> 0
    #       FF -> 255
    #
    # Ví dụ:
    #       00
    #       00
    #       15
    #       A4
    #       FF
    # ============================================================
    with open(output_hex_path, "w", encoding="utf-8") as f:
        for pixel in flattened_img:
            f.write(f"{int(pixel):02X}\n")

    # ============================================================
    # 6. Thông báo
    # ============================================================
    print("\n========================================")
    print("CHUYỂN ẢNH -> HEX THÀNH CÔNG")
    print("========================================")
    print(f"Input : {image_path}")
    print(f"Output: {output_hex_path}")
    print(f"Kích thước: {img.shape}")
    print(f"Số pixel : {len(flattened_img)}")
    print(f"Min pixel: {img.min()}")
    print(f"Max pixel: {img.max()}")
    print("========================================")

    # ============================================================
    # 7. Hiển thị ảnh sau khi đảo để kiểm tra
    # ============================================================
    preview = cv2.resize(
        img,
        (280, 280),
        interpolation=cv2.INTER_NEAREST
    )

    cv2.imshow("CNN input - 28x28 inverted", preview)

    print("\nNhấn phím bất kỳ trên cửa sổ ảnh để thoát.")

    cv2.waitKey(0)
    cv2.destroyAllWindows()


# ================================================================
# MAIN
# ================================================================

INPUT_IMAGE = (
    "C:/Users/DELL/Desktop/CNN/CodePython/6_test.png"
)

OUTPUT_HEX = "image_6_28x28.hex"

convert_image_to_hex(
    INPUT_IMAGE,
    OUTPUT_HEX
)




# import cv2
# import numpy as np

# def convert_image_to_hex(image_path, output_hex_path):
#     # 1. Đọc ảnh dưới dạng ảnh xám (Grayscale)
#     # Vì ảnh MNIST bản chất là ảnh xám 1 kênh (0-255)
#     img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    
#     if img is None:
#         print(f"Lỗi: Không tìm thấy hoặc không thể mở ảnh tại đường dẫn '{image_path}'")
#         return

#     # 2. Đảm bảo kích thước ảnh chuẩn 28x28 pixel
#     # Nếu ảnh gốc chưa đúng kích thước, hàm này sẽ tự động resize về 28x28
#     if img.shape != (28, 28):
#         img = cv2.resize(img, (28, 28), interpolation=cv2.INTER_AREA)
#         print("Lưu ý: Ảnh đã được tự động thay đổi kích thước về 28x28 pixel.")

#     # 3. Làm phẳng ma trận 2D (28x28) thành mảng 1D (784 phần tử)
#     flattened_img = img.flatten()

#     # 4. Ghi dữ liệu ra file .hex theo chuẩn dòng lệnh $readmemh của Verilog
#     # Mỗi dòng chứa đúng 2 ký tự Hex (mỗi ký tự đại diện cho 1 pixel 8-bit)
#     with open(output_hex_path, "w", encoding="utf-8") as f:
#         for pixel in flattened_img:
#             # Định dạng: "02x" -> điền số 0 nếu giá trị nhỏ hơn 16, định dạng hex viết thường
#             # Thêm dấu xuống dòng \n chuẩn để Quartus/Vivado đọc chính xác từng dòng
#             f.write(f"{pixel:02x}\n")
            
#     print(f"Thành công! Đã tạo file Hex tại: {output_hex_path}")
#     print(f"Tổng số phần tử đã ghi: {len(flattened_img)} dòng (tương ứng 784 pixels).")

# # --- HƯỚNG DẪN CHẠY ---
# # Thay đổi tên file ảnh đầu vào và file hex đầu ra theo đúng dự án của bạn
# INPUT_IMAGE = "C:/Users/DELL/Desktop/CNN/CodePython/9_test.png"  # Đường dẫn tới bức ảnh số 3 bạn vừa gửi
# OUTPUT_HEX = "image_9_28x28.hex"    # Tên file hex cần tạo ra

# convert_image_to_hex(INPUT_IMAGE, OUTPUT_HEX)
