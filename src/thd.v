module thd_calculator #(//著述
    parameter DATA_WIDTH      = 12,
    parameter BUFFER_ADDR_WIDTH = 10
) (
    input wire                      clk,
    input wire                      reset,
    input wire                      start_analysis,
    input wire [DATA_WIDTH-1:0]     bram_data_in,
    
    output reg [BUFFER_ADDR_WIDTH-1:0] bram_read_address,
    output reg [15:0]               thd_result,
    output reg                      done
);

    // 定义状态机状态
    localparam IDLE          = 3'd0;
    localparam READ_DATA     = 3'd1;
    localparam FFT_PROCESS   = 3'd2;
    localparam CALC_ENERGY   = 3'd3;
    localparam CALC_THD      = 3'd4;
    localparam DONE_STATE    = 3'd5;
    
    reg [2:0] state, next_state;
    
    // 样本数量 (2^BUFFER_ADDR_WIDTH)
    localparam SAMPLE_NUM = 1 << BUFFER_ADDR_WIDTH;
    
    // 寄存器用于存储FFT结果
    reg signed [DATA_WIDTH:0] fft_real [0:SAMPLE_NUM/2-1];
    reg signed [DATA_WIDTH:0] fft_imag [0:SAMPLE_NUM/2-1];
    reg [BUFFER_ADDR_WIDTH-1:0] sample_count;
    
    // 存储原始数据的寄存器
    reg [DATA_WIDTH-1:0] waveform_data [0:SAMPLE_NUM-1];
    
    // 能量计算寄存器
    reg [31:0] fundamental_energy;
    reg [31:0] harmonic_energy;
    reg [31:0] total_energy;
    
    // FFT模块接口 (假设使用一个IP核)
    wire fft_done;
    wire [DATA_WIDTH-1:0] fft_real_out, fft_imag_out;
    wire [BUFFER_ADDR_WIDTH-1:0] fft_index;
    reg fft_start;
    
    // 实例化FFT模块 (这里假设有一个FFT IP核)
    // 实际实现中需要根据使用的FFT IP进行调整
    fft_ip fft_inst (
        .clk(clk),
        .reset(reset),
        .start(fft_start),
        .data_in(waveform_data[sample_count]),
        .data_valid(/* 需要连接 */),
        .real_out(fft_real_out),
        .imag_out(fft_imag_out),
        .index(fft_index),
        .done(fft_done)
    );
    
    // 状态寄存器更新
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 下一状态逻辑
    always @(*) begin
        case (state)
            IDLE: next_state = start_analysis ? READ_DATA : IDLE;
            READ_DATA: next_state = (sample_count == SAMPLE_NUM-1) ? FFT_PROCESS : READ_DATA;
            FFT_PROCESS: next_state = fft_done ? CALC_ENERGY : FFT_PROCESS;
            CALC_ENERGY: next_state = (sample_count == SAMPLE_NUM/2-1) ? CALC_THD : CALC_ENERGY;
            CALC_THD: next_state = DONE_STATE;
            DONE_STATE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 输出逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            done <= 1'b0;
            thd_result <= 16'd0;
        end else begin
            done <= (state == DONE_STATE);
            // thd_result将在CALC_THD状态中赋值
        end
    end
    
    // 读取数据和FFT处理
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            bram_read_address <= {BUFFER_ADDR_WIDTH{1'b0}};
            sample_count <= 0;
            fft_start <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    bram_read_address <= {BUFFER_ADDR_WIDTH{1'b0}};
                    sample_count <= 0;
                    fft_start <= 1'b0;
                end
                
                READ_DATA: begin
                    // 存储从BRAM读取的数据
                    waveform_data[sample_count] <= bram_data_in;
                    
                    // 增加地址和计数器
                    if (sample_count < SAMPLE_NUM-1) begin
                        sample_count <= sample_count + 1;
                        bram_read_address <= bram_read_address + 1;
                    end
                    
                    // 当读取完所有数据后，准备启动FFT
                    if (sample_count == SAMPLE_NUM-1) begin
                        fft_start <= 1'b1;
                        sample_count <= 0; // 重置计数器用于FFT过程
                    end
                end
                
                FFT_PROCESS: begin
                    fft_start <= 1'b0;
                    
                    // 存储FFT结果 (这里简化处理，实际需要根据FFT IP的接口调整)
                    if (fft_done) begin
                        fft_real[fft_index] <= fft_real_out;
                        fft_imag[fft_index] <= fft_imag_out;
                    end
                end
                
                default: begin
                    // 保持当前值
                end
            endcase
        end
    end
    
    // 能量计算
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            fundamental_energy <= 32'd0;
            harmonic_energy <= 32'd0;
            total_energy <= 32'd0;
            sample_count <= 0;
        end else begin
            case (state)
                CALC_ENERGY: begin
                    if (sample_count == 0) begin
                        // 初始化能量计算
                        fundamental_energy <= 32'd0;
                        harmonic_energy <= 32'd0;
                        total_energy <= 32'd0;
                    end
                    
                    // 计算每个频率分量的能量 (实部^2 + 虚部^2)
                    if (sample_count < SAMPLE_NUM/2) begin
                        reg [31:0] energy;
                        energy = (fft_real[sample_count] * fft_real[sample_count]) + 
                                 (fft_imag[sample_count] * fft_imag[sample_count]);
                        
                        // 基波能量 (假设第一个非零频率分量是基波)
                        if (sample_count == 1) begin
                            fundamental_energy <= energy;
                        end
                        // 谐波能量 (2次及以上谐波)
                        else if (sample_count > 1) begin
                            harmonic_energy <= harmonic_energy + energy;
                        end
                        
                        // 总能量 (可选，用于验证)
                        total_energy <= total_energy + energy;
                        
                        sample_count <= sample_count + 1;
                    end
                end
                
                IDLE: begin
                    // 重置计数器
                    sample_count <= 0;
                end
                
                default: begin
                    // 保持当前值
                end
            endcase
        end
    end
    
    // THD计算和结果输出
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            thd_result <= 16'd0;
        end else begin
            if (state == CALC_THD) begin
                // THD = sqrt(harmonic_energy) / sqrt(fundamental_energy)
                // 由于我们使用定点数，这里简化计算
                
                // 防止除以零
                if (fundamental_energy == 0) begin
                    thd_result <= 16'h7FFF; // 最大值表示错误
                end else begin
                    // 计算谐波能量与基波能量的比值 (放大1000倍表示百分比*10)
                    // 这样0.1%的THD可以表示为1，1%表示为10，10%表示为100等
                    reg [31:0] thd_squared;
                    reg [15:0] thd_temp;
                    
                    // 计算THD平方 (harmonic_energy / fundamental_energy)
                    thd_squared = (harmonic_energy * 10000) / fundamental_energy;
                    
                    // 开平方近似 (这里简化处理，实际可能需要更精确的方法)
                    thd_temp = sqrt_approx(thd_squared);
                    
                    thd_result <= thd_temp;
                end
            end
        end
    end
    
    // 简单的开平方近似函数 (可以替换为更精确的实现)
    function [15:0] sqrt_approx;
        input [31:0] value;
        reg [31:0] rem, root;
        reg [15:0] res;
        integer i;
    begin
        if (value == 0) begin
            sqrt_approx = 0;
        end else begin
            rem = 0;
            root = 0;
            
            for (i = 15; i >= 0; i = i - 1) begin
                root = root << 1;
                rem = (rem << 2) | ((value >> (i+i)) & 3);
                if (rem >= (root << 1) + 1) begin
                    rem = rem - ((root << 1) + 1);
                    root = root + 1;
                end
            end
            
            sqrt_approx = root;
        end
    end
    endfunction

endmodule