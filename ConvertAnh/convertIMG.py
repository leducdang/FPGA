import cv2
image = cv2.imread("D:/2024/FPGA/codeFPGAL_LIB/VGA/hinh-nen-hoa-la.jpg")
image = cv2.resize(image,(640,480))
data = image[0,5]
file = open("convert.txt", "a")
for x in range(0,480):
    for y in range(0, 640):
        data = image[x,y]
        # data_write = str(data[0])+","+ str(data[1])+","+str(data[2])+","
        data_write = "data"+"["+str(x*480+y)+"]"+"="+ str(data[0])+","
        file.write(data_write)
        print(data[0],data[1],data[2])
# print(data)

# data = hex(255)
# print(data[2]+data[3])


cv2.imshow("window", image)
cv2.waitKey()