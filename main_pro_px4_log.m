%% PX4 ULG日志文件分析和可视化脚本
% 读取PX4的ULG格式日志文件，提取IMU和GPS位置数据，并绘制轨迹图
% 作者: GitHub Copilot
% 日期: 2025-09-20
clear; clc; close all;
%% 参数设置
file_path = "./data/"
mat_filename = 'px4_flight_data.mat';

uwb_filename = file_path + 'exp_data_20250920_221238.csv'; % UWB数据文件名

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
    
    % 检查数据结构
    if isfield(data, 'imu_time')
        % Python生成的数据格式
        imu_time = data.imu_time;
        imu_x = data.imu_x;
        imu_y = data.imu_y;
        imu_z = data.imu_z;
        gps_time = data.gps_time;
        gps_lat = data.gps_lat;
        gps_lon = data.gps_lon;
        gps_alt = data.gps_alt;
    else
        % 示例数据格式
        imu_time = data.t;
        imu_x = data.imu_x;
        imu_y = data.imu_y;
        imu_z = data.imu_z;
        gps_time = data.t;
        gps_lat = data.gps_lat;
        gps_lon = data.gps_lon;
        gps_alt = data.gps_alt;
    end
    
    % 将IMU时间戳从0开始（减去初始值）
    if ~isempty(imu_time) && length(imu_time) > 0
        imu_time = imu_time - imu_time(1);
        fprintf('IMU time normalized to start from 0\n');
    end
    
    % 将GPS时间戳从0开始（减去初始值）
    if ~isempty(gps_time) && length(gps_time) > 0
        gps_time = gps_time - gps_time(1);
        fprintf('GPS time normalized to start from 0\n');
    end
    
    fprintf('Data loading completed\n');
    fprintf('IMU data points: %d\n', length(imu_x));
    fprintf('GPS data points: %d\n', length(gps_lat));
    
else
    error('Cannot find data file: %s', mat_filename);
end

%% Data Visualization
fprintf('Starting to plot charts...\n');

% 创建主图窗
figure('Name', 'PX4飞行轨迹分析', 'Position', [100, 100, 1600, 1200]);

%% 子图1: IMU本地坐标系3D轨迹
subplot(4, 3, 1);
if ~isempty(imu_x) && length(imu_x) > 1
    plot3(imu_x, imu_y, imu_z, 'b-', 'LineWidth', 2);
    hold on;
    plot3(imu_x(1), imu_y(1), imu_z(1), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g'); % 起点
    plot3(imu_x(end), imu_y(end), imu_z(end), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r'); % 终点
    grid on;
    xlabel('X (m)');
    ylabel('Y (m)');
    zlabel('Z (m)');
    title('IMU local 3D trajectory');
    legend('trajectory', 'start', 'end', 'Location', 'best');
    axis equal;
else
    text(0.5, 0.5, 'No IMU Data', 'HorizontalAlignment', 'center');
    title('IMU local 3D trajectory - No Data');
end

%% 子图2: IMU本地坐标系XY平面轨迹
subplot(4, 3, 2);
if ~isempty(imu_x) && length(imu_x) > 1
    plot(imu_x, imu_y, 'b-', 'LineWidth', 2);
    hold on;
    plot(imu_x(1), imu_y(1), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g'); % 起点
    plot(imu_x(end), imu_y(end), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r'); % 终点
    grid on;
    xlabel('X (m)');
    ylabel('Y (m)');
    title('IMU local XY trajectory');
    legend('trajectory', 'start', 'end', 'Location', 'best');
    axis equal;
else
    text(0.5, 0.5, 'No IMU Data', 'HorizontalAlignment', 'center');
    title('IMU local XY trajectory - No Data');
end

%% 子图3: UWB XY平面轨迹
subplot(4, 3, 3);
if ~isempty(uwb_data) && height(uwb_data) > 1
    uwb_x = uwb_data.x;
    uwb_y = uwb_data.y;
    plot(uwb_x, uwb_y, 'm-', 'LineWidth', 2);
    hold on;
    plot(uwb_x(1), uwb_y(1), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g'); % 起点
    plot(uwb_x(end), uwb_y(end), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r'); % 终点
    grid on;
    xlabel('X (m)');
    ylabel('Y (m)');
    title('UWB XY Trajectory');
    legend('trajectory', 'start', 'end', 'Location', 'best');
    axis equal;
else
    text(0.5, 0.5, 'No UWB Data', 'HorizontalAlignment', 'center');
    title('UWB XY Trajectory - No Data');
end

%% 子图4: IMU高度变化
subplot(4, 3, 4);
if ~isempty(imu_z) && length(imu_time) > 1
    plot(imu_time, imu_z, 'b-', 'LineWidth', 2);
    grid on;
    xlabel('time (s)');
    ylabel('Altitude Z (m)');
    title('IMU Altitude Variation');
else
    text(0.5, 0.5, 'No IMU Altitude Data', 'HorizontalAlignment', 'center');
    title('IMU altitude variation - No Data');
end

%% 子图5: GPS全球坐标轨迹
subplot(4, 3, 5);
if ~isempty(gps_lat) && length(gps_lat) > 1
    plot(gps_lon, gps_lat, 'r-', 'LineWidth', 2);
    hold on;
    plot(gps_lon(1), gps_lat(1), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g'); % 起点
    plot(gps_lon(end), gps_lat(end), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r'); % 终点
    grid on;
    xlabel('Longitude (°)');
    ylabel('Latitude (°)');
    title('GPS Global Coordinate Trajectory');
    legend('Trajectory', 'Start', 'End', 'Location', 'best');
else
    text(0.5, 0.5, 'No GPS Data', 'HorizontalAlignment', 'center');
    title('GPS Global Coordinate Trajectory - No Data');
end

%% 子图6: GPS高度变化
subplot(4, 3, 6);
if ~isempty(gps_alt) && length(gps_time) > 1
    plot(gps_time, gps_alt, 'r-', 'LineWidth', 2);
    grid on;
    xlabel('Time (s)');
    ylabel('Altitude (m)');
    title('GPS Altitude Variation');
else
    text(0.5, 0.5, 'No GPS Altitude Data', 'HorizontalAlignment', 'center');
    title('GPS Altitude Variation - No Data');
end

%% 子图7: IMU vs UWB轨迹对比
subplot(4, 3, 7);
if ~isempty(imu_x) && ~isempty(uwb_data) && length(imu_x) > 1 && height(uwb_data) > 1
    % 绘制IMU轨迹
    plot(imu_x, imu_y, 'b-', 'LineWidth', 2, 'DisplayName', 'IMU Trajectory');
    hold on;
    
    % 绘制UWB轨迹（已转换为米）
    uwb_x = uwb_data.x;
    uwb_y = uwb_data.y;
    
    % 可选：进行坐标对齐（将UWB原点对齐到IMU起点）
    uwb_x_aligned = uwb_x - uwb_x(1) + imu_x(1);
    uwb_y_aligned = uwb_y - uwb_y(1) + imu_y(1);
    
    plot(uwb_x_aligned, uwb_y_aligned, 'm--', 'LineWidth', 2, 'DisplayName', 'UWB Trajectory');
    
    grid on;
    xlabel('X (m)');
    ylabel('Y (m)');
    title('IMU vs UWB Trajectory Comparison');
    legend('Location', 'best');
    axis equal;
else
    text(0.5, 0.5, 'Insufficient Data for Comparison', 'HorizontalAlignment', 'center');
    title('IMU vs UWB Comparison - Insufficient Data');
end

%% 子图8: UWB时间序列
subplot(4, 3, 8);
if ~isempty(uwb_data) && height(uwb_data) > 1
    uwb_time = uwb_data.time;
    uwb_x = uwb_data.x;
    uwb_y = uwb_data.y;
    
    yyaxis left;
    plot(uwb_time, uwb_x, 'r-', 'LineWidth', 1.5);
    ylabel('UWB X (m)');
    xlabel('Time (s)');
    
    yyaxis right;
    plot(uwb_time, uwb_y, 'b-', 'LineWidth', 1.5);
    ylabel('UWB Y (m)');
    
    title('UWB Position Time Series');
    grid on;
else
    text(0.5, 0.5, 'No UWB Time Data', 'HorizontalAlignment', 'center');
    title('UWB Time Series - No Data');
end

%% 子图9: IMU X坐标时间序列对比
subplot(4, 3, 9);
if ~isempty(imu_x) && ~isempty(uwb_data) && length(imu_time) > 1 && height(uwb_data) > 1
    plot(imu_time, imu_x, 'b-', 'LineWidth', 2, 'DisplayName', 'IMU X');
    hold on;
    
    uwb_time = uwb_data.time;
    uwb_x = uwb_data.x;
    
    % 将UWB X坐标对齐到IMU起点
    uwb_x_aligned = uwb_x - uwb_x(1) + imu_x(1);
    
    plot(uwb_time, uwb_x_aligned, 'm--', 'LineWidth', 2, 'DisplayName', 'UWB X');
    
    xlabel('Time (s)');
    ylabel('X Position (m)');
    title('X Position Comparison vs Time');
    legend('Location', 'best');
    grid on;
else
    text(0.5, 0.5, 'Insufficient Data', 'HorizontalAlignment', 'center');
    title('X Position Comparison - No Data');
end

%% 子图10: IMU Y坐标时间序列对比
subplot(4, 3, 10);
if ~isempty(imu_y) && ~isempty(uwb_data) && length(imu_time) > 1 && height(uwb_data) > 1
    plot(imu_time, imu_y, 'b-', 'LineWidth', 2, 'DisplayName', 'IMU Y');
    hold on;
    
    uwb_time = uwb_data.time;
    uwb_y = uwb_data.y;
    
    % 将UWB Y坐标对齐到IMU起点
    uwb_y_aligned = uwb_y - uwb_y(1) + imu_y(1);
    
    plot(uwb_time, uwb_y_aligned, 'm--', 'LineWidth', 2, 'DisplayName', 'UWB Y');
    
    xlabel('Time (s)');
    ylabel('Y Position (m)');
    title('Y Position Comparison vs Time');
    legend('Location', 'best');
    grid on;
else
    text(0.5, 0.5, 'Insufficient Data', 'HorizontalAlignment', 'center');
    title('Y Position Comparison - No Data');
end

%% 子图11: 综合轨迹对比
subplot(4, 3, 11);
if ~isempty(imu_x) && ~isempty(gps_lat) && length(imu_x) > 1 && length(gps_lat) > 1
    % 将GPS坐标转换为本地坐标进行对比
    if length(gps_lat) > 1
        % 定义坐标转换系数
        lat_scale = 1/111320; % 1米对应的纬度变化（度）
        lon_scale = 1/(111320*cos(deg2rad(mean(gps_lat)))); % 1米对应的经度变化（度）
        
        % 计算GPS轨迹的本地坐标偏移
        lat_offset = (gps_lat - gps_lat(1)) / lat_scale;
        lon_offset = (gps_lon - gps_lon(1)) / lon_scale;
        
        plot(imu_x, imu_y, 'b-', 'LineWidth', 2, 'DisplayName', 'IMU Trajectory');
        hold on;
        plot(lon_offset, lat_offset, 'r--', 'LineWidth', 2, 'DisplayName', 'GPS Trajectory');
        
        % 如果UWB数据也存在，添加到对比中
        if ~isempty(uwb_data) && height(uwb_data) > 1
            uwb_x = uwb_data.x;
            uwb_y = uwb_data.y;
            % UWB数据已转换为米，进行坐标对齐
            uwb_x_aligned = uwb_x - uwb_x(1) + imu_x(1);
            uwb_y_aligned = uwb_y - uwb_y(1) + imu_y(1);
            plot(uwb_x_aligned, uwb_y_aligned, 'm:', 'LineWidth', 2, 'DisplayName', 'UWB Trajectory');
        end
        
        grid on;
        xlabel('X Offset (m)');
        ylabel('Y Offset (m)');
        title('All Trajectory Comparison');
        legend('Location', 'best');
        axis equal;
    end
else
    text(0.5, 0.5, 'Insufficient Data for Comparison', 'HorizontalAlignment', 'center');
    title('All Trajectory Comparison - Insufficient Data');
end

%% 子图12: 位置误差分析
subplot(4, 3, 12);
if ~isempty(imu_x) && ~isempty(uwb_data) && length(imu_x) > 1 && height(uwb_data) > 1
    % 对时间进行插值以便比较
    uwb_time = uwb_data.time;
    uwb_x = uwb_data.x;
    uwb_y = uwb_data.y;
    
    % 将UWB数据插值到IMU时间点
    if length(uwb_time) > 1 && length(imu_time) > 1
        % 确保时间范围重叠
        time_start = max(min(imu_time), min(uwb_time));
        time_end = min(max(imu_time), max(uwb_time));
        
        if time_end > time_start
            % 选择重叠时间范围内的数据
            imu_mask = (imu_time >= time_start) & (imu_time <= time_end);
            uwb_x_interp = interp1(uwb_time, uwb_x, imu_time(imu_mask), 'linear', 'extrap');
            uwb_y_interp = interp1(uwb_time, uwb_y, imu_time(imu_mask), 'linear', 'extrap');
            
            % 计算位置误差
            error_x = imu_x(imu_mask) - uwb_x_interp;
            error_y = imu_y(imu_mask) - uwb_y_interp;
            error_total = sqrt(error_x.^2 + error_y.^2);
            
            plot(imu_time(imu_mask), error_total, 'k-', 'LineWidth', 2);
            grid on;
            xlabel('Time (s)');
            ylabel('Position Error (m)');
            title('IMU-UWB Position Error');
        else
            text(0.5, 0.5, 'No Time Overlap', 'HorizontalAlignment', 'center');
            title('Position Error - No Time Overlap');
        end
    else
        text(0.5, 0.5, 'Insufficient Time Data', 'HorizontalAlignment', 'center');
        title('Position Error - Insufficient Data');
    end
else
    text(0.5, 0.5, 'Insufficient Data', 'HorizontalAlignment', 'center');
    title('Position Error - No Data');
end

%% Data Statistics
fprintf('\n=== Flight Data Statistics ===\n');
if ~isempty(imu_x)
    fprintf('IMU Local Coordinate Statistics:\n');
    fprintf('  X Range: %.2f ~ %.2f m\n', min(imu_x), max(imu_x));
    fprintf('  Y Range: %.2f ~ %.2f m\n', min(imu_y), max(imu_y));
    fprintf('  Z Range: %.2f ~ %.2f m\n', min(imu_z), max(imu_z));
    fprintf('  Flight Distance: %.2f m\n', sum(sqrt(diff(imu_x).^2 + diff(imu_y).^2)));
end

if ~isempty(gps_lat)
    fprintf('\nGPS Global Coordinate Statistics:\n');
    fprintf('  Latitude Range: %.6f ~ %.6f °\n', min(gps_lat), max(gps_lat));
    fprintf('  Longitude Range: %.6f ~ %.6f °\n', min(gps_lon), max(gps_lon));
    fprintf('  Altitude Range: %.2f ~ %.2f m\n', min(gps_alt), max(gps_alt));
end

if ~isempty(uwb_data) && height(uwb_data) > 1
    uwb_x = uwb_data.x;
    uwb_y = uwb_data.y;
    uwb_time = uwb_data.time;
    fprintf('\nUWB Position Statistics:\n');
    fprintf('  X Range: %.3f ~ %.3f m\n', min(uwb_x), max(uwb_x));
    fprintf('  Y Range: %.3f ~ %.3f m\n', min(uwb_y), max(uwb_y));
    fprintf('  Time Range: %.3f ~ %.3f s\n', min(uwb_time), max(uwb_time));
    fprintf('  Total UWB points: %d\n', height(uwb_data));
    fprintf('  UWB Distance: %.3f m\n', sum(sqrt(diff(uwb_x).^2 + diff(uwb_y).^2)));
end

fprintf('\nChart rendering completed!\n');

%% Save Image
print('px4_flight_analysis', '-dpng', '-r300');
fprintf('Image saved as: px4_flight_analysis.png\n');