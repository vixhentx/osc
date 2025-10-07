// 模块定义: 总谐波失真 (THD) 计算器
// 待办: 由团队成员实现内部逻辑 (通常是FFT及后续计算)
module thd_calculator #(
    // 参数: ADC数据的位宽
    parameter DATA_WIDTH      = 12,
    // 参数: 缓存区地址的位宽
    parameter BUFFER_ADDR_WIDTH = 10
) (
    // -- 输入端口 --
    input wire                      clk,                // 输入: 系统主时钟信号
    input wire                      reset,              // 输入: 高电平有效的复位信号
    input wire                      start_analysis,     // 输入: 来自顶层模块的单周期脉冲, 用于启动一次THD分析
    input wire [DATA_WIDTH-1:0]     bram_data_in,       // 输入: 从共享BRAM读出的数据

    // -- 输出端口 --
    output reg [BUFFER_ADDR_WIDTH-1:0] bram_read_address, // 输出: 需要从BRAM读取的数据地址
    output reg [15:0]               thd_result,         // 输出: 16位定点数表示的THD计算结果
    output reg                      done                // 输出: 单周期脉冲, 表示THD计算完成, thd_result有效
);

    // -- 内部逻辑 --
    // 在此实现THD计算逻辑
    // 1. 接收到 start_analysis 信号后开始运行
    // 2. 通过控制 bram_read_address 来从BRAM中读取整个波形数据
    // 3. 对数据进行FFT (快速傅里叶变换)
    // 4. 根据FFT结果计算基波和谐波的能量
    // 5. 计算THD值并赋给 thd_result
    // 6. 计算完成后, 将 done 信号置为高电平一个时钟周期
      // 状态定义
typedef enum logic [3:0] {
    IDLE,
    LOAD_DATA,
    WAIT_FFT,
    CALC_ENERGY,
    CALC_THD,
    OUTPUT_RESULT
} state_t;
 
state_t state, next_state;
 
// 内部寄存器
reg [DATA_WIDTH-1:0] waveform_buffer [0:FFT_POINTS-1];
reg [15:0] fft_real [0:FFT_POINTS/2-1];  // FFT实部结果
reg [15:0] fft_imag [0:FFT_POINTS/2-1];  // FFT虚部结果
reg [31:0] fundamental_power;           // 基波能量
reg [31:0] harmonic_power;              // 谐波总能量
reg [9:0] sample_counter;               // 采样计数器
reg [15:0] max_magnitude;               // 用于基波检测
reg [9:0] fundamental_index;            // 基波索引位置
reg fft_done;                           // FFT完成标志
 
// 状态机转移
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        bram_read_address <= 0;
        done <= 1'b0;
        thd_result <= 16'd0;
        sample_counter <= 0;
        fft_done <= 1'b0;
    end else begin
        state <= next_state;
        
        // 默认值
        done <= 1'b0;
        
        case (state)
            IDLE: begin
                sample_counter <= 0;
                if (start_analysis) begin
                    bram_read_address <= 0;
                end
            end
            
            LOAD_DATA: begin
                // 加载数据到波形缓冲区
                waveform_buffer[sample_counter] <= bram_data_in;
                sample_counter <= sample_counter + 1;
                bram_read_address <= bram_read_address + 1;
            end
            
            WAIT_FFT: begin
                // 等待FFT计算完成
                if (fft_done) begin
                    // 解析FFT结果（这里假设已有FFT模块输出实部和虚部）
                    for (int i=0; i<FFT_POINTS/2; i++) begin
                        // 计算幅度平方 (magnitude^2 = real^2 + imag^2)
                        // 这里简化为绝对值相加，实际应根据FFT输出格式调整
                        fft_real[i] <= /* FFT实部输出 */;
                        fft_imag[i] <= /* FFT虚部输出 */;
                    end
                end
            end
            
            CALC_ENERGY: begin
                // 1. 检测基波位置（最大能量峰）
                max_magnitude <= 0;
                fundamental_index <= 0;
                for (int i=1; i<FFT_POINTS/4; i++) begin  // 搜索1/4频点范围
                    // 计算幅度（简化计算，实际应使用CORDIC或查表求平方根）
                    reg [31:0] magnitude_sq = fft_real[i]*fft_real[i] + fft_imag[i]*fft_imag[i];
                    if (magnitude_sq > max_magnitude) begin
                        max_magnitude <= magnitude_sq;
                        fundamental_index <= i;
                    end
                end
                
                // 2. 计算基波能量（使用检测到的基波索引）
                fundamental_power <= fft_real[fundamental_index]*fft_real[fundamental_index] + 
                                    fft_imag[fundamental_index]*fft_imag[fundamental_index];
                
                // 3. 计算谐波能量（2-10次谐波，可根据标准调整）
                harmonic_power <= 0;
                for (int h=2; h<=10; h++) begin
                    int harmonic_idx = fundamental_index * h;
                    if (harmonic_idx < FFT_POINTS/2) begin
                        harmonic_power <= harmonic_power + 
                                        fft_real[harmonic_idx]*fft_real[harmonic_idx] + 
                                        fft_imag[harmonic_idx]*fft_imag[harmonic_idx];
                    end
                end
            end
            
            CALC_THD: begin
                // THD = sqrt(harmonic_power) / sqrt(fundamental_power)
                // 使用线性近似避免开方运算：
                // THD(%) ≈ 100 * sqrt(harmonic_power / fundamental_power)
                // 这里使用线性近似：sqrt(x) ≈ x * 0.5 (在x接近0时)
                // 实际实现中应使用更精确的方法
                
                if (fundamental_power > 0) begin
                    // 计算比值（使用定点数运算）
                    reg [31:0] ratio = (harmonic_power << 16) / fundamental_power;  // Q16.16格式
                    
                    // 近似计算平方根（牛顿迭代法或查表法更精确）
                    reg [15:0] sqrt_ratio = ratio[23:8];  // 简单截断近似
                    
                    // 计算THD百分比（放大100倍）
                    thd_result <= (sqrt_ratio * 100) >> 8;
                end else begin
                    thd_result <= 16'hFFFF;  // 错误值（除零保护）
                end
            end
            
            OUTPUT_RESULT: begin
                done <= 1'b1;  // 产生完成脉冲
            end
        endcase
    end
end
 
// 状态机组合逻辑
always @(*) begin
    next_state = state;
    case (state)
        IDLE: if (start_analysis) next_state = LOAD_DATA;
        LOAD_DATA: if (sample_counter == FFT_POINTS-1) next_state = WAIT_FFT;
        WAIT_FFT: if (fft_done) next_state = CALC_ENERGY;
        CALC_ENERGY: next_state = CALC_THD;
        CALC_THD: next_state = OUTPUT_RESULT;
        OUTPUT_RESULT: next_state = IDLE;
        default: next_state = IDLE;
    endcase
end
 
// FFT模块实例化（需根据实际FFT实现调整）
fft_module #(
    .POINT_WIDTH(BUFFER_ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) u_fft (
    .clk(clk),
    .reset(reset),
    .start(state == LOAD_DATA && sample_counter == FFT_POINTS-1),
    .data_in(waveform_buffer),
    .real_out(fft_real),
    .imag_out(fft_imag),
    .done(fft_done)
);
 
endmodule