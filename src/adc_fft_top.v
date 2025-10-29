`timescale 1ns / 1ps

module adc_fft_top(
    // 时钟和复位
    input clk_27m,
    input rst_n,
    
    // ADC接口
    input adc_input_signal,
    
    // FFT结果输出
    output [31:0] fft_magnitude,
    output [15:0] dominant_frequency,
    output fft_data_valid,
    
    // 状态指示
    output [7:0] status_leds
);

// 内部信号定义
wire [11:0] adc_raw_data;
wire adc_data_ready;
wire [15:0] processed_adc_data;
wire sample_valid;
wire [31:0] fft_real_out;
wire [31:0] fft_imag_out;
wire fft_processing_done;
wire [9:0] max_bin_index;

// ADC状态信号
wire o_adc_dmodified;
wire o_logic_done_a;
wire o_logic_done_b;
wire o_over_temp;
wire o_adc_clk_out;

// 使用单一时钟简化设计
wire sys_clk = clk_27m;
wire sys_rst_n = rst_n;

// ADC采集模块实例化
adc_capture u_adc_capture(
    .clk(sys_clk),           // 使用27MHz时钟
    .rst_n(sys_rst_n),
    .adc_input(adc_input_signal),
    .adc_data(adc_raw_data),
    .data_ready(adc_data_ready)
);

// 数据预处理模块
data_preprocessor u_data_preprocessor(
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .raw_data(adc_raw_data),
    .raw_data_valid(adc_data_ready),
    .processed_data(processed_adc_data),
    .processed_data_valid(sample_valid)
);

// FFT处理模块
fft_processor u_fft_processor(
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .time_domain_data(processed_adc_data),
    .data_valid(sample_valid),
    .fft_real(fft_real_out),
    .fft_imag(fft_imag_out),
    .fft_valid(fft_processing_done),
    .dominant_bin(max_bin_index)
);

// 结果处理模块
result_processor u_result_processor(
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .fft_real(fft_real_out),
    .fft_imag(fft_imag_out),
    .fft_valid(fft_processing_done),
    .bin_index(max_bin_index),
    .magnitude(fft_magnitude),
    .frequency(dominant_frequency),
    .data_valid(fft_data_valid)
);

// 状态指示逻辑
reg [7:0] led_status;
assign status_leds = led_status;

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        led_status <= 8'h00;
    end else begin
        led_status[0] <= adc_data_ready;           // ADC数据就绪
        led_status[1] <= sample_valid;             // 预处理数据有效
        led_status[2] <= fft_processing_done;      // FFT处理完成
        led_status[3] <= fft_data_valid;           // 结果数据有效
        led_status[4] <= 1'b1;                     // 系统运行状态
        led_status[5] <= o_adc_dmodified;          // ADC数据修改标志
        led_status[6] <= o_logic_done_a;           // ADC逻辑完成A
        led_status[7] <= o_over_temp;              // ADC过温警告
    end
end

endmodule