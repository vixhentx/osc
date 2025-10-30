`timescale 1ns / 1ps

module result_processor(
    input clk,
    input rst_n,
    input [31:0] fft_real,
    input [31:0] fft_imag,
    input fft_valid,
    input [9:0] bin_index,
    output reg [31:0] magnitude,
    output reg [15:0] frequency,
    output reg data_valid
);

// 频率计算参数
parameter SAMPLE_RATE = 1000000;  // 1MHz采样率
parameter FFT_POINTS = 1024;

// 幅值计算
reg [63:0] magnitude_squared;
reg [31:0] calculated_magnitude;

// 频率计算
reg [15:0] calculated_frequency;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        magnitude <= 32'b0;
        frequency <= 16'b0;
        data_valid <= 1'b0;
        magnitude_squared <= 64'b0;
        calculated_magnitude <= 32'b0;
        calculated_frequency <= 16'b0;
    end else if (fft_valid) begin
        // 计算幅值：sqrt(real^2 + imag^2)
        magnitude_squared <= (fft_real * fft_real) + (fft_imag * fft_imag);
        
        // 使用近似开方计算（为了节省资源）
        calculated_magnitude <= magnitude_squared[63:32] + magnitude_squared[31:16];
        magnitude <= calculated_magnitude;
        
        // 计算频率：bin_index * (sample_rate / fft_points)
        calculated_frequency <= (bin_index * SAMPLE_RATE) / FFT_POINTS;
        frequency <= calculated_frequency;
        
        data_valid <= 1'b1;
    end else begin
        data_valid <= 1'b0;
    end
end

endmodule