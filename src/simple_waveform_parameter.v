module signal_analyzer (
    input clk,               // 采样时钟（例如 1MHz）
    input reset,             // 异步复位
    input [11:0] adc_data,   // ADC 数据（12位）
    input [11:0] threshold,  // 判断高低电平的阈值（例如 12'h800）
    
    output reg [11:0] amplitude,  // 幅值（峰峰值的一半）
    output reg [31:0] frequency,  // 频率（Hz）
    output reg [31:0] duty_cycle  // 占空比（百分比 × 100，例如 50.00% → 5000）
);

// ====== 幅值计算（峰值检测） ======
reg [11:0] max_val, min_val;
always @(posedge clk or posedge reset) begin
    if (reset) begin
        max_val <= 12'd0;
        min_val <= 12'hFFF;
        amplitude <= 12'd0;
    end else begin
        if (adc_data > max_val) max_val <= adc_data;
        if (adc_data < min_val) min_val <= adc_data;
        amplitude <= (max_val - min_val) >> 1; // 峰峰值的一半
    end
end

// ====== 频率 & 占空比计算（过零检测 + 定时） ======
reg [31:0] counter;          // 当前采样计数器
reg [31:0] last_crossing;    // 上一次过零时刻
reg [31:0] high_time;        // 高电平持续时间
reg [31:0] period;           // 信号周期
reg prev_state;              // 上一次电平状态（用于边沿检测）

always @(posedge clk or posedge reset) begin
    if (reset) begin
        counter <= 32'd0;
        last_crossing <= 32'd0;
        high_time <= 32'd0;
        period <= 32'd0;
        frequency <= 32'd0;
        duty_cycle <= 32'd0;
        prev_state <= 1'b0;
    end else begin
        counter <= counter + 1;
        
        // 检测上升沿（过零或阈值交叉）
        if (!prev_state && (adc_data > threshold)) begin
            if (last_crossing != 0) begin
                period <= counter - last_crossing; // 计算周期
                frequency <= 1_000_000 / (counter - last_crossing); // 假设 clk=1MHz
            end
            last_crossing <= counter;
            high_time <= 0; // 重置高电平计时
            prev_state <= 1'b1;
        end
        // 检测下降沿
        else if (prev_state && (adc_data <= threshold)) begin
            prev_state <= 1'b0;
        end
        
        // 统计高电平时间（用于占空比计算）
        if (prev_state) high_time <= high_time + 1;
        
        // 计算占空比（在周期结束时更新）
        if (period > 0 && counter >= last_crossing + period) begin
            duty_cycle <= (high_time * 10000) / period; // 百分比 × 100（例如 50.00% → 5000）
        end
    end
end

endmodule