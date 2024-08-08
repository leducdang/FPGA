import cv2
image = cv2.imread("D:/2024\FPGA\Thu Vien/320-240/Cute-Kittens--80748.jpg")
# image = cv2.resize(image,(320,240))
data = image[0,5]
file = open("convert.txt", "a")


for x in range(0,240):
    for y in range(0, 320):
        data = image[x,y]
        blue  = hex(data[0])
        green = hex(data[1])
        red   = hex(data[2])
        vitri = hex(x*320+y)
        
        
        if(data[0]<16):
            str_blue   = "0"+ str(blue)[2:4]
        else: 
            str_blue = str(blue)[2:4]
        if(data[1]<16):
            str_green  = "0"+ str(green)[2:4]
        else:
            str_green  = str(green)[2:4]  
        if(data[2]<16):   
            str_red    = "0"+ str(red)[2:4]
        else:
            str_red    = str(red)[2:4]
            
        data_write = str(vitri)[2:]+":"+ str_red + str_green + str_blue+";"+"\n"
       
        file.write(data_write)
        print(data[0],data[1],data[2])
        
        
        
        
# print(data)
# blue = hex(data[0])
# print(blue)
# str_blue = str(blue)[2:4]
# print(str_blue)
# print(data[2]+data[3])


cv2.imshow("window", image)
cv2.waitKey()