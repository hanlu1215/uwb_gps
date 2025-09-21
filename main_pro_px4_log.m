%% PX4 ULG日志文件分析和可视化脚本
% 读取PX4的ULG格式日志文件，提取IMU和GPS位置数据，并绘制轨迹图
% 作者: GitHub Copilot
% 日期: 2025-09-20
clear; clc; close all;
%% 参数设置
% log_name = "log_0_2025-9-20-21-44-46";
log_name = "log_1_2025-9-20-22-10-26";

file_path = "./data/" + log_name + "/";
%% 数据文件路径
% 在 file_path 目录下查找唯一的 MAT 文件
mat_files = dir(fullfile(file_path, '*.mat'));
if isempty(mat_files)
    error('No MAT file found in %s', file_path);
elseif numel(mat_files) > 1
    error('Multiple MAT files found in %s', file_path);
else
    mat_filename = fullfile(file_path, mat_files(1).name);
    fprintf('Found MAT file: %s\n', mat_filename);
end
% 在 file_path 目录下查找唯一的 CSV 文件，文件名以 “exp” 开头
csv_files = dir(fullfile(file_path, 'exp*.csv'));
if isempty(csv_files)
    error('No CSV file starting with "exp" found in %s', file_path);
elseif numel(csv_files) > 1
    error('Multiple CSV files starting with "exp" found in %s', file_path);
else
    uwb_filename = fullfile(file_path, csv_files(1).name);
    fprintf('Found UWB CSV file: %s\n', uwb_filename);
end

%% 读取数据
% 读取UWB数据
if exist(uwb_filename, 'file')
    fprintf('Loading UWB data file: %s\n', uwb_filename);
    uwb_data = readtable(uwb_filename);
    
    % 将UWB数据从厘米转换为米
    uwb_data.x = uwb_data.x / 100;  % cm to m
    uwb_data.y = uwb_data.y / 100;  % cm to m
    
    % 将UWB时间戳从0开始（减去初始值）
    if height(uwb_data) > 0 && ~isempty(uwb_data.time)
        uwb_data.time = uwb_data.time - uwb_data.time(1);
        fprintf('UWB time normalized to start from 0\n');
    end
    
    fprintf('UWB data loading completed\n');
    fprintf('UWB data points: %d\n', height(uwb_data));
    fprintf('UWB data converted from cm to m\n');
else
    warning('Cannot find UWB data file: %s', uwb_filename);
    uwb_data = [];
end

% 读取PX4数据
if exist(mat_filename, 'file')
    fprintf('Loading data file: %s\n', mat_filename);
    data = load(mat_filename);
    
    % 从vehicle_local_position主题提取IMU数据
    if isfield(data, 'vehicle_local_position')
        fprintf('Using vehicle_local_position data\n');
        local_pos_time = data.vehicle_local_position.timestamp;
        local_pos_x = data.vehicle_local_position.x;
        local_pos_y = data.vehicle_local_position.y;
        local_pos_z = data.vehicle_local_position.z;
    else
        fprintf('Warning: vehicle_local_position data not found\n');
        local_pos_time = [];
        local_pos_x = [];
        local_pos_y = [];
        local_pos_z = [];
    end
    
    % 从vehicle_gps_position主题提取GPS数据
    if isfield(data, 'vehicle_gps_position')
        fprintf('Using vehicle_gps_position data\n');
        gps_time = data.vehicle_gps_position.timestamp;
        gps_lat = data.vehicle_gps_position.latitude_deg;
        gps_lon = data.vehicle_gps_position.longitude_deg;
        gps_alt = data.vehicle_gps_position.altitude_ellipsoid_m;
    elseif isfield(data, 'vehicle_global_position')
        fprintf('Using vehicle_global_position data\n');
        gps_time = data.vehicle_global_position.timestamp;
        gps_lat = data.vehicle_global_position.latitude_deg;
        gps_lon = data.vehicle_global_position.longitude_deg;
        gps_alt = data.vehicle_global_position.altitude_ellipsoid_m;
    else
        fprintf('Warning: GPS data not found\n');
        gps_time = [];
        gps_lat = [];
        gps_lon = [];
        gps_alt = [];
    end
    
    % 将Local position时间戳从0开始（减去初始值）
    if ~isempty(local_pos_time) && length(local_pos_time) > 0
        local_pos_time = local_pos_time - local_pos_time(1);
        fprintf('Local position time normalized to start from 0\n');
    end
    
    % 将GPS时间戳从0开始（减去初始值）
    if ~isempty(gps_time) && length(gps_time) > 0
        gps_time = gps_time - gps_time(1);
        fprintf('GPS time normalized to start from 0\n');
    end
    
    fprintf('Data loading completed\n');
    fprintf('Local position data points: %d\n', length(local_pos_x));
    fprintf('GPS data points: %d\n', length(gps_lat));
    
else
    error('Cannot find data file: %s', mat_filename);
end

%% Data Visualization
fprintf('Starting to plot charts...\n');

% 创建结果文件夹
result_path = fullfile(file_path, 'result');
if ~exist(result_path, 'dir')
    mkdir(result_path);
    fprintf('Created result directory: %s\n', result_path);
end

%% 图1: PX4 Local Position 3D轨迹
figure('Name', 'PX4 Local Position 3D Trajectory', 'Position', [100, 100, 800, 600]);
if ~isempty(local_pos_x) && length(local_pos_x) > 1
    plot3(local_pos_x, local_pos_y, local_pos_z, 'b-', 'LineWidth', 2);
    hold on;
    plot3(local_pos_x(1), local_pos_y(1), local_pos_z(1), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g'); % 起点
    plot3(local_pos_x(end), local_pos_y(end), local_pos_z(end), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r'); % 终点
    grid on;
    xlabel('X (m)');
    ylabel('Y (m)');
    zlabel('Z (m)');
    title('PX4 Local Position 3D Trajectory', 'FontSize', 14);
    legend('Trajectory', 'Start', 'End', 'Location', 'best');
    axis equal;
else
    text(0.5, 0.5, 'No PX4 Local Position Data', 'HorizontalAlignment', 'center');
    title('PX4 Local Position 3D Trajectory - No Data');
end
saveas(gcf, fullfile(result_path, '01_PX4_3D_trajectory.png'));
fprintf('Saved: 01_PX4_3D_trajectory.png\n');

%% 图2: PX4 vs UWB轨迹对比
figure('Name', 'PX4 vs UWB Trajectory Comparison', 'Position', [400, 400, 800, 600]);
if ~isempty(local_pos_x) && ~isempty(uwb_data) && length(local_pos_x) > 1 && height(uwb_data) > 1
    % 绘制PX4轨迹
    plot(local_pos_x, local_pos_y, 'b-', 'LineWidth', 2, 'DisplayName', 'PX4 Local Position');
    hold on;
    
    % 绘制UWB轨迹
    uwb_x = uwb_data.x;
    uwb_y = uwb_data.y;
    
    % 进行坐标对齐（将UWB原点对齐到PX4起点）
    uwb_x_aligned = uwb_x - uwb_x(1) + local_pos_x(1);
    uwb_y_aligned = uwb_y - uwb_y(1) + local_pos_y(1);
    
    plot(uwb_x_aligned, uwb_y_aligned, 'm--', 'LineWidth', 2, 'DisplayName', 'UWB Position (Aligned)');
    
    grid on;
    xlabel('X (m)');
    ylabel('Y (m)');
    title('PX4 vs UWB Trajectory Comparison', 'FontSize', 14);
    legend('Location', 'best');
    axis equal;
else
    text(0.5, 0.5, 'Insufficient Data for Comparison', 'HorizontalAlignment', 'center');
    title('PX4 vs UWB Trajectory Comparison - Insufficient Data');
end
saveas(gcf, fullfile(result_path, '02_PX4_vs_UWB_trajectory_comparison.png'));
fprintf('Saved: 02_PX4_vs_UWB_trajectory_comparison.png\n');

%% 图3: PX4 vs UWB X坐标对比
figure('Name', 'PX4 vs UWB X Coordinate Comparison', 'Position', [300, 300, 800, 600]);
if ~isempty(local_pos_x) && ~isempty(uwb_data) && length(local_pos_time) > 1 && height(uwb_data) > 1
    plot(local_pos_time, local_pos_x, 'b-', 'LineWidth', 2, 'DisplayName', 'PX4 Local X');
    hold on;
    
    uwb_time = uwb_data.time;
    uwb_x = uwb_data.x;
    
    % 将UWB X坐标对齐到PX4起点
    uwb_x_aligned = uwb_x - uwb_x(1) + local_pos_x(1);
    
    plot(uwb_time, uwb_x_aligned, 'm--', 'LineWidth', 2, 'DisplayName', 'UWB X (Aligned)');
    
    xlabel('Time (s)');
    ylabel('X Position (m)');
    title('PX4 vs UWB X Coordinate Comparison', 'FontSize', 14);
    legend('Location', 'best');
    grid on;
else
    text(0.5, 0.5, 'Insufficient Data', 'HorizontalAlignment', 'center');
    title('PX4 vs UWB X Coordinate Comparison - Insufficient Data');
end
saveas(gcf, fullfile(result_path, '03_PX4_vs_UWB_X_comparison.png'));
fprintf('Saved: 03_PX4_vs_UWB_X_comparison.png\n');

%% 图4: PX4 vs UWB Y坐标对比
figure('Name', 'PX4 vs UWB Y Coordinate Comparison', 'Position', [400, 400, 800, 600]);
if ~isempty(local_pos_y) && ~isempty(uwb_data) && length(local_pos_time) > 1 && height(uwb_data) > 1
    plot(local_pos_time, local_pos_y, 'b-', 'LineWidth', 2, 'DisplayName', 'PX4 Local Y');
    hold on;
    
    uwb_time = uwb_data.time;
    uwb_y = uwb_data.y;
    
    % 将UWB Y坐标对齐到PX4起点
    uwb_y_aligned = uwb_y - uwb_y(1) + local_pos_y(1);
    
    plot(uwb_time, uwb_y_aligned, 'm--', 'LineWidth', 2, 'DisplayName', 'UWB Y (Aligned)');
    
    xlabel('Time (s)');
    ylabel('Y Position (m)');
    title('PX4 vs UWB Y Coordinate Comparison', 'FontSize', 14);
    legend('Location', 'best');
    grid on;
else
    text(0.5, 0.5, 'Insufficient Data', 'HorizontalAlignment', 'center');
    title('PX4 vs UWB Y Coordinate Comparison - Insufficient Data');
end
saveas(gcf, fullfile(result_path, '04_PX4_vs_UWB_Y_comparison.png'));
fprintf('Saved: 04_PX4_vs_UWB_Y_comparison.png\n');

