module thd_calculator (
    input wire clk,
    input wire reset_n,
    input wire [15:0] fft_real_in [0:1023],  // 1024点FFT实部输入
    input wire [15:0] fft_imag_in [0:1023],  // 1024点FFT虚部输入
    input wire fft_valid,                    // FFT数据有效信号
    output reg [31:0] thd_result,            // THD计算结果
    output reg thd_valid                     // THD结果有效信号
);

    // THD计算参数
    localparam HARMONIC_BINS = 5;            // 计算前5次谐波（2~6次）
    localparam FFT_SIZE = 1024;              // FFT点数
    
    // 内部寄存器
    reg [31:0] fundamental_power;            // 基波功率
    reg [31:0] harmonic_power;               // 谐波总功率
    reg [31:0] thd_temp;                     // THD临时结果
    
    reg [2:0] calc_state;                    // 主状态机
    reg [10:0] bin_counter;                  // FFT频点计数器（0~1023）
    reg [10:0] fundamental_bin;              // 动态检测到的基波频点
    reg [31:0] max_power;                    // 最大功率（用于基波检测）
    reg [3:0] harmonic_counter;              // 谐波次数计数器（2~6）
    reg calculating;                         // 计算标志
    
    // 状态定义
    localparam IDLE = 3'b000;                // 空闲状态
    localparam DETECT_FUNDAMENTAL = 3'b001;  // 检测基波位置
    localparam CALC_FUNDAMENTAL = 3'b010;    // 计算基波功率
    localparam CALC_HARMONICS = 3'b011;      // 计算谐波功率
    localparam COMPUTE_THD = 3'b100;         // 计算THD
    localparam DONE = 3'b101;                // 计算完成
    
    // 计算复数幅度的平方（功率）
    function [31:0] calculate_power;
        input [15:0] real_part;
        input [15:0] imag_part;
        reg [31:0] real_sq, imag_sq;
        begin
            real_sq = $signed(real_part) * $signed(real_part);  // 带符号运算
            imag_sq = $signed(imag_part) * $signed(imag_part);
            calculate_power = real_sq + imag_sq;
        end
    endfunction
    
    // 主状态机逻辑
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            calc_state <= IDLE;
            thd_valid <= 0;
            calculating <= 0;
            fundamental_power <= 0;
            harmonic_power <= 0;
            thd_result <= 0;
            bin_counter <= 0;
            fundamental_bin <= 0;
            max_power <= 0;
            harmonic_counter <= 0;
        end else begin
            case (calc_state)
                IDLE: begin
                    thd_valid <= 0;
                    // 当FFT数据有效且未在计算时，启动基波检测
                    if (fft_valid && !calculating) begin
                        calculating <= 1;
                        bin_counter <= 0;          // 从0号频点开始检测
                        max_power <= 0;            // 最大功率清零
                        fundamental_bin <= 0;      // 基波位置清零
                        calc_state <= DETECT_FUNDAMENTAL;
                    end
                end
                
                // 遍历所有FFT频点，找到最大功率对应的频点（基波）
                DETECT_FUNDAMENTAL: begin
                    if (bin_counter < FFT_SIZE) begin
                        // 计算当前频点的功率
                        reg [31:0] current_power;
                        current_power = calculate_power(fft_real_in[bin_counter], 
                                                       fft_imag_in[bin_counter]);
                        
                        // 如果当前功率大于历史最大值，更新基波位置
                        if (current_power > max_power) begin
                            max_power <= current_power;
                            fundamental_bin <= bin_counter;
                        end
                        
                        bin_counter <= bin_counter + 1;  // 下一个频点
                    end else begin
                        // 所有频点遍历完成，进入基波功率计算
                        bin_counter <= 0;
                        calc_state <= CALC_FUNDAMENTAL;
                    end
                end
                
                // 计算基波功率（使用检测到的基波位置）
                CALC_FUNDAMENTAL: begin
                    fundamental_power <= calculate_power(fft_real_in[fundamental_bin], 
                                                       fft_imag_in[fundamental_bin]);
                    harmonic_counter <= 2;  // 从2次谐波开始计算
                    harmonic_power <= 0;    // 谐波功率累加器清零
                    calc_state <= CALC_HARMONICS;
                end
                
                // 计算各次谐波功率并累加
                CALC_HARMONICS: begin
                    if (harmonic_counter <= HARMONIC_BINS) begin
                        // 计算当前次谐波的频点（基波频点 × 谐波次数）
                        reg [10:0] harmonic_bin;
                        harmonic_bin = fundamental_bin * harmonic_counter;
                        
                        // 确保谐波频点不超过FFT范围（防止越界）
                        if (harmonic_bin < FFT_SIZE) begin
                            harmonic_power <= harmonic_power + 
                                            calculate_power(fft_real_in[harmonic_bin],
                                                          fft_imag_in[harmonic_bin]);
                        end
                        
                        harmonic_counter <= harmonic_counter + 1;
                    end else begin
                        // 所有谐波计算完成，进入THD计算
                        calc_state <= COMPUTE_THD;
                    end
                end
                
                // 计算THD（采用定点数运算，Q16.16格式）
                COMPUTE_THD: begin
                    if (fundamental_power != 0) begin
                        // THD ≈ sqrt(谐波总功率) / sqrt(基波功率)
                        // 简化为：(谐波功率 << 16) / 基波功率（保留16位小数）
                        thd_temp <= (harmonic_power << 16) / fundamental_power;
                    end else begin
                        thd_temp <= 0;  // 避免除以0
                    end
                    calc_state <= DONE;
                end
                
                // 输出结果并回到空闲状态
                DONE: begin
                    thd_result <= thd_temp;
                    thd_valid <= 1;
                    calculating <= 0;
                    calc_state <= IDLE;
                end
            endcase
        end
    end

endmodule