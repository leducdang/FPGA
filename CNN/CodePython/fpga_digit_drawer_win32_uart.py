import tkinter as tk
from tkinter import ttk, messagebox
import threading
import winreg
import win32file
import win32con

IMG_W = 28
IMG_H = 28
SCALE = 10
PIXEL_OFF = 0
PIXEL_ON = 255


class Win32UART:
    def __init__(self):
        self.handle = None
        self.port = None

    @property
    def is_open(self):
        return self.handle is not None

    def open(self, port):
        if self.is_open:
            self.close()

        self.handle = win32file.CreateFile(
            rf"\\.\{port}",
            win32con.GENERIC_READ | win32con.GENERIC_WRITE,
            0,
            None,
            win32con.OPEN_EXISTING,
            0,
            None
        )
        self.port = port

    def write(self, data):
        if not self.is_open:
            raise RuntimeError("COM chưa được mở")

        if isinstance(data, bytearray):
            data = bytes(data)

        err, written = win32file.WriteFile(self.handle, data)

        if isinstance(written, int):
            return written

        return len(data)

    def close(self):
        if self.handle is not None:
            try:
                win32file.CloseHandle(self.handle)
            except Exception:
                pass
        self.handle = None
        self.port = None


def list_com_ports():
    ports = []

    try:
        key = winreg.OpenKey(
            winreg.HKEY_LOCAL_MACHINE,
            r"HARDWARE\DEVICEMAP\SERIALCOMM"
        )

        i = 0
        while True:
            try:
                _, value, _ = winreg.EnumValue(key, i)
                ports.append(value)
                i += 1
            except OSError:
                break

        winreg.CloseKey(key)

    except OSError:
        pass

    def key_func(name):
        try:
            return int(name.upper().replace("COM", ""))
        except Exception:
            return 9999

    return sorted(set(ports), key=key_func)


class App:
    def __init__(self, root):
        self.root = root
        self.root.title("FPGA Digit Drawer 28x28 - Win32 UART")
        self.root.geometry("780x620")

        self.uart = Win32UART()
        self.connected = False
        self.image = [[0] * IMG_W for _ in range(IMG_H)]

        self.brush_radius = tk.IntVar(value=1)
        self.send_mode = tk.StringVar(value="raw")
        self.invert_var = tk.BooleanVar(value=False)

        self.last_x = None
        self.last_y = None

        self.build_ui()
        self.refresh_ports()
        self.root.protocol("WM_DELETE_WINDOW", self.on_close)

    def build_ui(self):
        main = ttk.Frame(self.root, padding=12)
        main.pack(fill="both", expand=True)

        left = ttk.LabelFrame(main, text="Vẽ số 28 x 28", padding=10)
        left.grid(row=0, column=0, sticky="nsew", padx=(0, 12))

        self.canvas = tk.Canvas(
            left,
            width=IMG_W * SCALE,
            height=IMG_H * SCALE,
            bg="black",
            highlightthickness=1,
            highlightbackground="#777"
        )
        self.canvas.pack()

        self.canvas.bind("<Button-1>", self.mouse_down)
        self.canvas.bind("<B1-Motion>", self.mouse_drag)
        self.canvas.bind("<ButtonRelease-1>", self.mouse_up)

        self.canvas.bind("<Button-3>", self.erase_down)
        self.canvas.bind("<B3-Motion>", self.erase_drag)
        self.canvas.bind("<ButtonRelease-3>", self.mouse_up)

        ctrl = ttk.Frame(left)
        ctrl.pack(fill="x", pady=(10, 0))

        ttk.Button(ctrl, text="Xóa ảnh", command=self.clear_image).pack(side="left")
        ttk.Label(ctrl, text="Brush:").pack(side="left", padx=(10, 0))
        ttk.Combobox(
            ctrl,
            textvariable=self.brush_radius,
            values=[0, 1, 2, 3],
            state="readonly",
            width=4
        ).pack(side="left", padx=5)

        ttk.Label(
            left,
            text="Chuột trái: vẽ | Chuột phải: xóa"
        ).pack(anchor="w", pady=(8, 0))

        right = ttk.Frame(main)
        right.grid(row=0, column=1, sticky="nsew")

        uart_box = ttk.LabelFrame(right, text="UART / CH340", padding=10)
        uart_box.pack(fill="x")

        row = ttk.Frame(uart_box)
        row.pack(fill="x")

        ttk.Label(row, text="COM:").pack(side="left")

        self.port_var = tk.StringVar()

        self.port_combo = ttk.Combobox(
            row,
            textvariable=self.port_var,
            state="readonly",
            width=12
        )
        self.port_combo.pack(side="left", padx=6)

        ttk.Button(row, text="Quét", command=self.refresh_ports).pack(side="left")

        self.connect_btn = ttk.Button(
            row,
            text="Kết nối",
            command=self.toggle_connection
        )
        self.connect_btn.pack(side="right")

        ttk.Label(
            uart_box,
            text="COM phải được cấu hình sẵn: 115200, 8N1, Flow Control OFF"
        ).pack(anchor="w", pady=(8, 0))

        self.status_var = tk.StringVar(value="Chưa kết nối")
        ttk.Label(uart_box, textvariable=self.status_var).pack(anchor="w", pady=(5, 0))

        test_box = ttk.LabelFrame(right, text="Test", padding=10)
        test_box.pack(fill="x", pady=(12, 0))

        ttk.Button(
            test_box,
            text="Gửi 0x55",
            command=self.send_test
        ).pack(fill="x")

        send_box = ttk.LabelFrame(right, text="Gửi ảnh", padding=10)
        send_box.pack(fill="x", pady=(12, 0))

        ttk.Radiobutton(
            send_box,
            text="RAW: gửi đúng 784 byte",
            variable=self.send_mode,
            value="raw"
        ).pack(anchor="w")

        ttk.Radiobutton(
            send_box,
            text="Header AA 55 + 784 byte",
            variable=self.send_mode,
            value="header"
        ).pack(anchor="w", pady=(4, 0))

        ttk.Checkbutton(
            send_box,
            text="Đảo màu trước khi gửi",
            variable=self.invert_var
        ).pack(anchor="w", pady=(8, 0))

        ttk.Button(
            send_box,
            text="GỬI ẢNH 28x28 XUỐNG FPGA",
            command=self.send_image
        ).pack(fill="x", pady=(10, 0))

        log_box = ttk.LabelFrame(right, text="Log", padding=10)
        log_box.pack(fill="both", expand=True, pady=(12, 0))

        self.log_text = tk.Text(
            log_box,
            width=42,
            height=14,
            font=("Consolas", 9),
            state="disabled"
        )
        self.log_text.pack(fill="both", expand=True)

        self.log(
            "Không dùng pyserial.\n"
            "Dùng Win32 CreateFile + WriteFile.\n\n"
            "Ảnh: 28x28 = 784 pixel\n"
            "0 = đen, 255 = trắng\n"
            "Thứ tự gửi: row-major\n"
        )

        bottom = ttk.Frame(main)
        bottom.grid(row=1, column=0, columnspan=2, sticky="ew", pady=(12, 0))

        self.pixel_count_var = tk.StringVar(value="Pixel sáng: 0 / 784")
        ttk.Label(bottom, textvariable=self.pixel_count_var).pack(side="left")

        main.columnconfigure(1, weight=1)
        main.rowconfigure(0, weight=1)

    def canvas_to_pixel(self, cx, cy):
        x = max(0, min(IMG_W - 1, cx // SCALE))
        y = max(0, min(IMG_H - 1, cy // SCALE))
        return int(x), int(y)

    def mouse_down(self, event):
        x, y = self.canvas_to_pixel(event.x, event.y)
        self.last_x, self.last_y = x, y
        self.paint_pixel(x, y, PIXEL_ON)

    def mouse_drag(self, event):
        x, y = self.canvas_to_pixel(event.x, event.y)
        if self.last_x is not None:
            self.draw_line(self.last_x, self.last_y, x, y, PIXEL_ON)
        self.last_x, self.last_y = x, y

    def erase_down(self, event):
        x, y = self.canvas_to_pixel(event.x, event.y)
        self.last_x, self.last_y = x, y
        self.paint_pixel(x, y, PIXEL_OFF)

    def erase_drag(self, event):
        x, y = self.canvas_to_pixel(event.x, event.y)
        if self.last_x is not None:
            self.draw_line(self.last_x, self.last_y, x, y, PIXEL_OFF)
        self.last_x, self.last_y = x, y

    def mouse_up(self, event=None):
        self.last_x = None
        self.last_y = None

    def draw_line(self, x0, y0, x1, y1, value):
        dx = abs(x1 - x0)
        dy = -abs(y1 - y0)
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        err = dx + dy

        while True:
            self.paint_pixel(x0, y0, value)

            if x0 == x1 and y0 == y1:
                break

            e2 = 2 * err

            if e2 >= dy:
                err += dy
                x0 += sx

            if e2 <= dx:
                err += dx
                y0 += sy

    def paint_pixel(self, x, y, value):
        r = self.brush_radius.get()

        for yy in range(y - r, y + r + 1):
            for xx in range(x - r, x + r + 1):
                if 0 <= xx < IMG_W and 0 <= yy < IMG_H:
                    if (xx - x) ** 2 + (yy - y) ** 2 <= r ** 2 + 1:
                        self.image[yy][xx] = value
                        self.draw_cell(xx, yy, value)

        self.update_pixel_count()

    def draw_cell(self, x, y, value):
        x0 = x * SCALE
        y0 = y * SCALE
        x1 = x0 + SCALE
        y1 = y0 + SCALE

        color = f"#{value:02x}{value:02x}{value:02x}"

        self.canvas.create_rectangle(
            x0, y0, x1, y1,
            fill=color,
            outline=color
        )

    def clear_image(self):
        self.image = [[0] * IMG_W for _ in range(IMG_H)]
        self.canvas.delete("all")
        self.update_pixel_count()
        self.log("Đã xóa ảnh.\n")

    def update_pixel_count(self):
        count = sum(1 for row in self.image for p in row if p != 0)
        self.pixel_count_var.set(f"Pixel sáng: {count} / 784")

    def refresh_ports(self):
        ports = list_com_ports()
        self.port_combo["values"] = ports

        if ports:
            if self.port_var.get() not in ports:
                self.port_var.set(ports[0])
            self.log("COM: " + ", ".join(ports) + "\n")
        else:
            self.port_var.set("")
            self.log("Không tìm thấy COM.\n")

    def toggle_connection(self):
        if self.connected:
            self.disconnect_uart()
        else:
            self.connect_uart()

    def connect_uart(self):
        port = self.port_var.get().strip()

        if not port:
            messagebox.showwarning("UART", "Chưa chọn COM.")
            return

        try:
            self.uart.open(port)
            self.connected = True
            self.connect_btn.config(text="Ngắt kết nối")
            self.status_var.set(f"Đã mở {port}")
            self.log(f"OPEN {port} OK\n")

        except Exception as e:
            self.connected = False
            messagebox.showerror("UART Error", str(e))

    def disconnect_uart(self):
        self.uart.close()
        self.connected = False
        self.connect_btn.config(text="Kết nối")
        self.status_var.set("Chưa kết nối")
        self.log("Đã đóng COM.\n")

    def build_pixel_data(self):
        data = bytearray()

        for y in range(IMG_H):
            for x in range(IMG_W):
                value = self.image[y][x]

                if self.invert_var.get():
                    value = 255 - value

                data.append(value & 0xFF)

        return data

    def build_packet(self):
        data = self.build_pixel_data()

        if self.send_mode.get() == "raw":
            return data

        return bytearray([0xAA, 0x55]) + data

    def send_test(self):
        if not self.connected:
            messagebox.showwarning("UART", "Hãy kết nối COM trước.")
            return

        try:
            written = self.uart.write(bytes([0x55]))
            self.status_var.set("Đã gửi 0x55")
            self.log(f"SEND 0x55 OK ({written} byte)\n")

        except Exception as e:
            messagebox.showerror("UART Send Error", str(e))

    def send_image(self):
        if not self.connected:
            messagebox.showwarning("UART", "Hãy kết nối COM trước.")
            return

        packet = self.build_packet()

        threading.Thread(
            target=self._send_thread,
            args=(packet,),
            daemon=True
        ).start()

    def _send_thread(self,  packet):
        try:
            self.root.after(
                0,
                lambda: self.status_var.set("Đang gửi...")
            )

            written = self.uart.write(packet)

            self.root.after(
                0,
                lambda: self.status_var.set(f"Đã gửi {written} byte")
            )

            self.root.after(
                0,
                lambda: self.log(
                    f"SEND IMAGE OK: {written} byte\n"
                )
            )

        except Exception as e:
            self.root.after(
                0,
                lambda: messagebox.showerror(
                    "UART Send Error",
                    str(e)
                )
            )

    def log(self, text):
        self.log_text.config(state="normal")
        self.log_text.insert("end", text)
        self.log_text.see("end")
        self.log_text.config(state="disabled")

    def on_close(self):
        try:
            self.uart.close()
        except Exception:
            pass
        self.root.destroy()


def main():
    root = tk.Tk()

    try:
        style = ttk.Style()
        if "vista" in style.theme_names():
            style.theme_use("vista")
    except Exception:
        pass

    App(root)
    root.mainloop()


if __name__ == "__main__":
    main()
