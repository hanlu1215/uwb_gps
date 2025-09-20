#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import serial,binascii
import time
from time import sleep
import os,csv
from collections import deque
import threading,sys
import my_fun as my
import numpy as np
import struct
import random
# 宏定义参数
isrun = True
maxlen = 10
serial_num = 'COM6'
# obsdata=deque(maxlen=maxlen)
my.obsT=deque(maxlen=maxlen)
my.obsX=deque(maxlen=maxlen)
my.obsY=deque(maxlen=maxlen)
## my.obsV=deque(maxlen=maxlen)
my.RUN_FLAG = True
time_start = time.time()
dt_str = time.strftime("%Y%m%d_%H%M%S", time.localtime())
csv_filename = f"exp_data_{dt_str}.csv"
csvfile = open(csv_filename, "a+", newline='')
writer = csv.writer(csvfile)
def read_data(serial):
    while True:
        data = serial.read()
        if data == b'\x01':
            data = data + serial.read(2)
            if data == b'\x01\x03\x28':
                data = data + serial.read(42)
                data = str(binascii.b2a_hex(data))[2:-1]
                time_data = time.time()-time_start
                return data,time_data
            else:
                continue
        else:
            continue 
def updata():
    # 开始定位：
    cmd_str = '01 10 00 28 00 01 02 00 04 A1 BB' #命令的字符串格式
    cmd_=bytes.fromhex(cmd_str)# 数据转换
    serial.write(cmd_) #命令发送
    while isrun:
        serial.flushInput()
        serial.flushOutput()
        data,time_data =read_data(serial)
        if data != '' :
            data_x_str = data[14:18]
            data_x = ((int(data_x_str,16)+0x8000)&0xFFFF)-0x8000
            data_y_str = data[18:22]
            data_y = ((int(data_y_str,16)+0x8000)&0xFFFF)-0x8000
            my.obsX.append(data_x)
            my.obsY.append(data_y)
            my.obsT.append(time_data)
            # sleep(0.002)
            if len(my.obsT)>=maxlen:
                writer.writerow([my.obsT[-1],my.obsX[-1],my.obsY[-1]])
    # 结束定位：
    cmd_str = '01 10 00 28 00 01 02 00 00 A0 78'
    cmd_=bytes.fromhex(cmd_str)
    serial.write(cmd_) #数据写回
    csvfile.close()
    print("close uwb")
if __name__ == '__main__':
    exp_lable = input("输入实验组的标签:")
    writer.writerow(["time","x","y"])
    serial = serial.Serial(serial_num, 115200,8, timeout=0.5,stopbits=1)  #/dev/ttyUSB0
    if serial.isOpen() :
        print("open success")
    else :
        print("open failed")
    time_start = time.time()
    tr = threading.Thread(target=updata)
    tr.start()
    print("wait!")
    while len(my.obsT)<maxlen:
        time.sleep(1)
    print("start")
    # 主线程直接调用绘图，避免GUI线程警告
    my.plota()
    isrun = False
    print(f"已停止，数据已保存到 {csv_filename}，程序退出。")
