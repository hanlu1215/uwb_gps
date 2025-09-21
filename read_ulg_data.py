#!/usr/bin/env python3
"""
PX4 ULG日志文件读取器
从ULG文件中提取IMU位置估计和GPS位置数据，并保存为MAT文件供MATLAB使用
"""

import pyulog
import numpy as np
import pandas as pd
from scipy.io import savemat
import os
file_path = "./data/"
# ULG文件路径
# ulg_file = "log_0_2025-9-20-19-02-52.ulg"
# ulg_file = "log_0_2025-9-20-21-44-46.ulg"
ulg_file = file_path + "log_1_2025-9-20-22-10-26.ulg"



def read_ulg_file(ulg_filename):
    """
    读取ULG文件并提取位置数据
    
    Args:
        ulg_filename: ULG文件路径
    
    Returns:
        dict: 包含IMU和GPS位置数据的字典
    """
    try:
        # 读取ULG文件
        print(f"正在读取ULG文件: {ulg_filename}")
        ulog = pyulog.ULog(ulg_filename)
        
        # 获取可用的数据主题
        print("可用的数据主题:")
        for dataset in ulog.data_list:
            print(f"  - {dataset.name}")
        
        data = {}
        
        # 提取车辆本地位置信息 (IMU估计的本地坐标)
        try:
            vehicle_local_position = ulog.get_dataset('vehicle_local_position')
            imu_data = vehicle_local_position.data
            
            data['imu_time'] = imu_data['timestamp'] * 1e-6  # 转换为秒
            data['imu_x'] = imu_data['x']  # 本地坐标系X位置
            data['imu_y'] = imu_data['y']  # 本地坐标系Y位置
            data['imu_z'] = imu_data['z']  # 本地坐标系Z位置
            
            print(f"提取到 {len(data['imu_x'])} 个IMU位置数据点")
            
        except Exception as e:
            print(f"无法提取vehicle_local_position数据: {e}")
            # 如果无法获取vehicle_local_position，尝试其他替代方案
            try:
                estimator_local_position = ulog.get_dataset('estimator_local_position')
                imu_data = estimator_local_position.data
                
                data['imu_time'] = imu_data['timestamp'] * 1e-6
                data['imu_x'] = imu_data['x']
                data['imu_y'] = imu_data['y']
                data['imu_z'] = imu_data['z']
                
                print(f"从estimator_local_position提取到 {len(data['imu_x'])} 个IMU位置数据点")
                
            except Exception as e2:
                print(f"也无法提取estimator_local_position数据: {e2}")
                data['imu_time'] = np.array([])
                data['imu_x'] = np.array([])
                data['imu_y'] = np.array([])
                data['imu_z'] = np.array([])
        
        # 提取GPS全球位置信息
        try:
            vehicle_global_position = ulog.get_dataset('vehicle_global_position')
            gps_data = vehicle_global_position.data
            
            data['gps_time'] = gps_data['timestamp'] * 1e-6  # 转换为秒
            data['gps_lat'] = gps_data['lat']  # 纬度 (度)
            data['gps_lon'] = gps_data['lon']  # 经度 (度)
            data['gps_alt'] = gps_data['alt']  # 高度 (米)
            
            print(f"提取到 {len(data['gps_lat'])} 个GPS位置数据点")
            
        except Exception as e:
            print(f"无法提取vehicle_global_position数据: {e}")
            # 尝试其他GPS数据源
            try:
                sensor_gps = ulog.get_dataset('sensor_gps')
                gps_data = sensor_gps.data
                
                data['gps_time'] = gps_data['timestamp'] * 1e-6
                data['gps_lat'] = gps_data['latitude_deg']
                data['gps_lon'] = gps_data['longitude_deg']
                data['gps_alt'] = gps_data['altitude_msl_m']
                
                print(f"从sensor_gps提取到 {len(data['gps_lat'])} 个GPS位置数据点")
                
            except Exception as e2:
                print(f"也无法提取sensor_gps数据: {e2}")
                data['gps_time'] = np.array([])
                data['gps_lat'] = np.array([])
                data['gps_lon'] = np.array([])
                data['gps_alt'] = np.array([])
        
        return data
        
    except Exception as e:
        print(f"读取ULG文件时发生错误: {e}")
        return None

def save_to_mat(data, output_filename):
    """
    将数据保存为MAT文件供MATLAB使用
    """
    try:
        savemat(output_filename, data)
        print(f"数据已保存到: {output_filename}")
    except Exception as e:
        print(f"保存MAT文件时发生错误: {e}")

def main():
    # 检查文件是否存在
    if not os.path.exists(ulg_file):
        print(f"错误: 找不到文件 {ulg_file}")
        return
    
    # 读取ULG数据
    data = read_ulg_file(ulg_file)
    
    if data is None:
        print("无法读取ULG文件")
        return
    
    # 保存为MAT文件
    output_file = "px4_flight_data.mat"
    save_to_mat(data, output_file)
    
    # 打印数据摘要
    print("\n数据摘要:")
    print(f"IMU数据点: {len(data['imu_x'])}")
    print(f"GPS数据点: {len(data['gps_lat'])}")
    
    if len(data['imu_x']) > 0:
        print(f"IMU位置范围:")
        print(f"  X: {np.min(data['imu_x']):.2f} ~ {np.max(data['imu_x']):.2f} m")
        print(f"  Y: {np.min(data['imu_y']):.2f} ~ {np.max(data['imu_y']):.2f} m")
        print(f"  Z: {np.min(data['imu_z']):.2f} ~ {np.max(data['imu_z']):.2f} m")
    
    if len(data['gps_lat']) > 0:
        print(f"GPS位置范围:")
        print(f"  纬度: {np.min(data['gps_lat']):.6f} ~ {np.max(data['gps_lat']):.6f} 度")
        print(f"  经度: {np.min(data['gps_lon']):.6f} ~ {np.max(data['gps_lon']):.6f} 度")
        print(f"  高度: {np.min(data['gps_alt']):.2f} ~ {np.max(data['gps_alt']):.2f} m")

if __name__ == "__main__":
    main()