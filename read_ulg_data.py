#!/usr/bin/env python3
"""
PX4 ULG日志文件读取器
从ULG文件中提取所有数据主题，并保存为MAT文件供MATLAB使用
支持提取所有可用的传感器数据和飞行控制数据
"""
import pyulog
from scipy.io import savemat
import os
import subprocess

# log_name = "log_0_2025-9-20-21-44-46"
log_name = "log_1_2025-9-20-22-10-26"

file_path = "./data/" + log_name + "/"
# ULG文件路径
ulg_file = file_path +  log_name + ".ulg"

# 使用ulog2csv将ULG文件转为CSV，输出到 file_path/csv 文件夹
csv_dir = os.path.join(file_path, 'csv')
os.makedirs(csv_dir, exist_ok=True)
try:
    print(f"正在将ULG转换为CSV，输出路径: {csv_dir}")
    subprocess.run(['ulog2csv', '-o', csv_dir, ulg_file], check=True)
    print("ULG转换为CSV完成")
except Exception as e:
    print(f"转换CSV时出错: {e}")

def sanitize_variable_name(name):
    """
    清理变量名，使其符合MATLAB变量命名规则
    
    Args:
        name: 原始变量名
    
    Returns:
        str: 清理后的变量名
    """
    import re
    
    # 替换特殊字符
    # 方括号替换为下划线
    name = re.sub(r'\[(\d+)\]', r'_\1', name)  # [0] -> _0
    name = re.sub(r'\[\]', '_array', name)     # [] -> _array
    
    # 其他特殊字符替换为下划线
    name = re.sub(r'[^a-zA-Z0-9_]', '_', name)
    
    # 确保不以数字开头
    if name and name[0].isdigit():
        name = 'var_' + name
    
    # 确保不为空
    if not name:
        name = 'unnamed_var'
    
    # 移除连续的下划线
    name = re.sub(r'_+', '_', name)
    
    # 移除开头和结尾的下划线
    name = name.strip('_')
    
    # MATLAB字段名长度限制为31个字符
    if len(name) > 31:
        # 尝试智能截断：保留开头和结尾，中间用下划线连接
        if '_' in name:
            parts = name.split('_')
            if len(parts) >= 2:
                # 保留第一部分和最后一部分
                first_part = parts[0]
                last_part = parts[-1]
                
                # 计算可用长度（减去一个下划线）
                available_len = 31 - 1
                
                # 如果第一部分和最后一部分的总长度超过可用长度
                if len(first_part) + len(last_part) >= available_len:
                    # 平均分配长度
                    first_len = available_len // 2
                    last_len = available_len - first_len
                    name = first_part[:first_len] + '_' + last_part[-last_len:]
                else:
                    # 中间部分用数字或缩写替代
                    middle_len = available_len - len(first_part) - len(last_part) - 1
                    if middle_len > 0:
                        name = first_part + '_' + last_part
                    else:
                        name = first_part + '_' + last_part
            else:
                # 简单截断
                name = name[:31]
        else:
            # 没有下划线，直接截断
            name = name[:31]
    
    return name

def read_ulg_file(ulg_filename):
    """
    读取ULG文件并提取所有数据
    
    Args:
        ulg_filename: ULG文件路径
    
    Returns:
        dict: 包含所有数据主题的字典，按dataset组织
    """
    try:
        # 读取ULG文件
        print(f"正在读取ULG文件: {ulg_filename}")
        ulog = pyulog.ULog(ulg_filename)
        # 将可用的数据主题保存到txt文件
        topic_names = [dataset.name for dataset in ulog.data_list]
        txt_filename = os.path.splitext(os.path.basename(ulg_filename))[0] + '.txt'
        txt_path = os.path.join(os.path.dirname(ulg_filename), txt_filename)
        try:
            with open(txt_path, 'w') as f:
                for name in topic_names:
                    f.write(name + '\n')
            print(f"可用的数据主题已保存到: {txt_path}")
        except Exception as e:
            print(f"保存主题列表到txt文件时出错: {e}")
        
        data = {}
        topic_name_counter = {}  # 用于跟踪重复的topic名称
        
        # 遍历所有数据主题并保存
        for dataset in ulog.data_list:
            topic_name = dataset.name
            print(f"正在提取主题: {topic_name}")
            try:
                # 获取数据集
                # topic_data = ulog.get_dataset(topic_name)
                topic_data = dataset  # 直接使用dataset对象
                
                # 为每个主题创建子字典
                original_topic_name = topic_name
                topic_name_clean = sanitize_variable_name(topic_name)
                
                # 处理重复的topic名称
                if topic_name_clean in topic_name_counter:
                    topic_name_counter[topic_name_clean] += 1
                    topic_name_clean = f"{topic_name_clean}_{topic_name_counter[topic_name_clean]}"
                    print(f"  检测到重复主题，重命名为: {topic_name_clean}")
                else:
                    topic_name_counter[topic_name_clean] = 1
                
                # 如果主题名被截断，显示警告
                if len(original_topic_name) > 31:
                    print(f"  警告: 主题名被截断 '{original_topic_name}' -> '{topic_name_clean}'")
                
                data[topic_name_clean] = {}
                
                # 遍历该主题的所有字段
                for field_name, field_data in topic_data.data.items():
                    # 清理字段名
                    original_field_name = field_name
                    field_name_clean = sanitize_variable_name(field_name)
                    
                    # 如果字段名被截断，显示警告
                    if len(original_field_name) > 31:
                        print(f"    警告: 字段名被截断 '{original_field_name}' -> '{field_name_clean}'")
                    
                    # 将时间戳转换为秒
                    if field_name == 'timestamp':
                        data[topic_name_clean][field_name_clean] = field_data * 1e-6
                    else:
                        data[topic_name_clean][field_name_clean] = field_data
                
                print(f"  - 成功提取 {len(topic_data.data)} 个字段，{len(field_data)} 个数据点")
                
            except Exception as e:
                print(f"  - 提取主题 {topic_name} 时出错: {e}")
                continue
        
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
        print(f"保存了 {len(data)} 个变量")
        
        # 打印保存的变量名（前20个）
        var_names = list(data.keys())
        print("保存的变量包括:")
        for i, name in enumerate(var_names[:20]):
            print(f"  - {name}")
        if len(var_names) > 20:
            print(f"  ... 还有 {len(var_names)-20} 个变量")
            
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
    
    # 生成输出文件路径（与ULG文件在同一文件夹，同名但扩展名为.mat）
    ulg_dir = os.path.dirname(ulg_file)
    ulg_basename = os.path.splitext(os.path.basename(ulg_file))[0]
    output_file = os.path.join(ulg_dir, f"{ulg_basename}.mat")
    
    # 保存为MAT文件
    save_to_mat(data, output_file)
    
    # 打印数据摘要
    print(f"\n=== 数据摘要 ===")
    print(f"总共提取的主题数: {len(data)}")
    print(f"输出文件: {output_file}")
    
    # 显示各主题的字段数和数据点数
    print(f"\n各主题详细信息:")
    for topic_name, topic_data in data.items():
        if isinstance(topic_data, dict) and topic_data:
            # 获取第一个字段的长度作为数据点数
            first_field = next(iter(topic_data.values()))
            if hasattr(first_field, '__len__'):
                print(f"  {topic_name}: {len(topic_data)} 个字段, {len(first_field)} 个数据点")
            else:
                print(f"  {topic_name}: {len(topic_data)} 个字段")
    
    # 显示一些关键主题的字段（如果存在）
    key_topics = ['vehicle_local_position', 'vehicle_global_position', 
                  'sensor_combined', 'actuator_outputs']
    print(f"\n关键主题字段信息:")
    for topic in key_topics:
        if topic in data and isinstance(data[topic], dict):
            fields = list(data[topic].keys())
            print(f"  {topic}: {fields[:5]}")  # 显示前5个字段
            if len(fields) > 5:
                print(f"    ... 还有 {len(fields)-5} 个字段")

if __name__ == "__main__":
    main()