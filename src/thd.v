module thd_calculator (
    input wire clk,
    input wire reset_n,
    input wire [15:0] fft_real_in [0:1023],
    input wire [15:0] fft_imag_in [0:1023],
    input wire fft_valid,
    output reg [31:0] thd_result,
    output reg thd_valid
);

    localparam HARMONIC_BINS = 3;  // 测试用：计算2~4次谐波（此处实际只注入2、3次）
    localparam FFT_SIZE = 1024;
    
    // 内部寄存器
    reg [31:0] fundamental_power;
    reg [31:0] harmonic_power;
    reg [31:0] thd_temp;
    reg [2:0] calc_state;
    reg [10:0] bin_counter;
    reg [10:0] fundamental_bin;
    reg [31:0] max_power;
    reg [3:0] harmonic_counter;
    reg calculating;
    
    // 状态定义
    localparam IDLE = 3'b000;
    localparam DETECT_FUNDAMENTAL = 3'b001;
    localparam CALC_FUNDAMENTAL = 3'b010;
    localparam CALC_HARMONICS = 3'b011;
    localparam COMPUTE_THD = 3'b100;
    localparam DONE = 3'b101;
    
    // 计算功率（带符号）
    function [31:0] calculate_power;
        input [15:0] real_part;
        input [15:0] imag_part;
        reg [31:0] real_sq, imag_sq;
        begin
            real_sq = $signed(real_part) * $signed(real_part);
            imag_sq = $signed(imag_part) * $signed(imag_part);
            calculate_power = real_sq + imag_sq;
        end
    endfunction
    
    // 牛顿迭代法开方（32位输入→16位输出，Q16格式）
    function [15:0] sqrt_fixed;
        input [31:0] x;
        reg [15:0] guess;
        reg [15:0] guess_next;
        integer i;
    begin
        if (x == 0) begin
            sqrt_fixed = 0;
        end else begin
            guess = 16'h4000;  // 初始猜测值=1.0（Q16格式：0x4000=1.0）
            for (i = 0; i < 8; i = i + 1) begin  // 8次迭代提高精度
                guess_next = (guess + (x / guess)) >> 1;
                guess = guess_next;
            end
            sqrt_fixed = guess;
        end
    endfunction
    
    // 主状态机
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
                    if (fft_valid && !calculating) begin
                        calculating <= 1;
                        bin_counter <= 0;
                        max_power <= 0;
                        fundamental_bin <= 0;
                        calc_state <= DETECT_FUNDAMENTAL;
                    end
                end
                
                DETECT_FUNDAMENTAL: begin
                    if (bin_counter < FFT_SIZE) begin
                        reg [31:0] current_power;
                        current_power = calculate_power(fft_real_in[bin_counter], fft_imag_in[bin_counter]);
                        if (current_power > max_power) begin
                            max_power <= current_power;
                            fundamental_bin <= bin_counter;
                        end
                        bin_counter <= bin_counter + 1;
                    end else begin
                        bin_counter <= 0;
                        calc_state <= CALC_FUNDAMENTAL;
                    end
                end
                
                CALC_FUNDAMENTAL: begin
                    fundamental_power <= calculate_power(fft_real_in[fundamental_bin], fft_imag_in[fundamental_bin]);
                    harmonic_counter <= 2;
                    harmonic_power <= 0;
                    calc_state <= CALC_HARMONICS;
                end
                
                CALC_HARMONICS: begin
                    if (harmonic_counter <= HARMONIC_BINS) begin
                        reg [10:0] harmonic_bin;
                        harmonic_bin = fundamental_bin * harmonic_counter;
                        if (harmonic_bin < FFT_SIZE) begin
                            harmonic_power <= harmonic_power + calculate_power(fft_real_in[harmonic_bin], fft_imag_in[harmonic_bin]);
                        end
                        harmonic_counter <= harmonic_counter + 1;
                    end else begin
                        calc_state <= COMPUTE_THD;
                    end
                end
                
                COMPUTE_THD: begin  // 精确计算THD = sqrt(谐波功率)/sqrt(基波功率)
                    if (fundamental_power != 0 && harmonic_power != 0) begin
                        reg [15:0] sqrt_harmonic, sqrt_fundamental;
                        sqrt_harmonic = sqrt_fixed(harmonic_power);       // 谐波功率开方
                        sqrt_fundamental = sqrt_fixed(fundamental_power); // 基波功率开方
                        // 结果为Q16.16格式：(sqrt_harmonic / sqrt_fundamental) << 16
                        thd_temp = ({16'd0, sqrt_harmonic} << 16) / sqrt_fundamental;
                    end else begin
                        thd_temp = 0;
                    end
                    calc_state <= DONE;
                end
                
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