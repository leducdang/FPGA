from tensorflow.keras.datasets import mnist
from PIL import Image
import os

# Tải dữ liệu MNIST
(x_train, y_train), (x_test, y_test) = mnist.load_data()

# Tạo thư mục lưu ảnh
base_dir = "mnist_images"

for split_name, images, labels in [
    ("train", x_train, y_train),
    ("test", x_test, y_test)
]:
    for digit in range(10):
        os.makedirs(f"{base_dir}/{split_name}/{digit}", exist_ok=True)

    for i, (img, label) in enumerate(zip(images, labels)):
        image = Image.fromarray(img)  # ảnh 28x28 grayscale
        image.save(f"{base_dir}/{split_name}/{label}/{i}.png")

print("Đã tải và lưu MNIST thành ảnh PNG.")
