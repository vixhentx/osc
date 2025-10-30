`timescale 1ns / 1ps

module data_preprocessor(
    input clk,
    input rst_n,
    input [11:0] raw_data,
    input raw_data_valid,
    output reg [15:0] processed_data,
    output reg processed_data_valid
);

// 数据缓冲器
reg [11:0] data_buffer [0:15];
reg [3:0] write_ptr;
reg buffer_ready;

// 移动平均滤波器
reg [15:0] moving_sum;
reg [3:0] filter_counter;

// DC偏移移除
reg [11:0] dc_offset;
reg [19:0] dc_sum;
reg [15:0] dc_sample_count;

// 数据缓冲
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        write_ptr <= 4'b0;
        buffer_ready <= 1'b0;
        moving_sum <= 16'b0;
        filter_counter <= 4'b0;
        dc_offset <= 12'b100000000000; // 中间值2.5V对应2048
        dc_sum <= 20'b0;
        dc_sample_count <= 16'b0;
    end else if (raw_data_valid) begin
        // 更新DC偏移估计
        dc_sum <= dc_sum + raw_data;
        dc_sample_count <= dc_sample_count + 1;
        
        if (dc_sample_count == 16'd1024) begin
            dc_offset <= dc_sum[19:8]; // 平均值
            dc_sum <= 20'b0;
            dc_sample_count <= 16'b0;
        end
        
        // 移动平均滤波 (4点平均)
        data_buffer[write_ptr] <= raw_data - dc_offset; // 移除DC偏移
        
        if (filter_counter == 4'd3) begin
            moving_sum <= data_buffer[0] + data_buffer[1] + 
                         data_buffer[2] + data_buffer[3];
            processed_data <= {moving_sum[13:0], 2'b00}; // 16位输出
            processed_data_valid <= 1'b1;
            filter_counter <= 4'b0;
        end else begin
            filter_counter <= filter_counter + 1;
            processed_data_valid <= 1'b0;
        end
        
        write_ptr <= write_ptr + 1;
        if (write_ptr == 4'd15) write_ptr <= 4'b0;
    end else begin
        processed_data_valid <= 1'b0;
    end
end

endmodule