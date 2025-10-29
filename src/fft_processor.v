`timescale 1ns / 1ps

module fft_processor(
    input clk,
    input rst_n,
    input [15:0] time_domain_data,
    input data_valid,
    output reg [31:0] fft_real,
    output reg [31:0] fft_imag,
    output reg fft_valid,
    output reg [9:0] dominant_bin
);

// FFT参数
parameter FFT_LENGTH = 1024;
parameter DATA_WIDTH = 16;

// 状态机定义
reg [2:0] state;
localparam IDLE = 3'b000;
localparam COLLECT = 3'b001;
localparam SEND_DATA = 3'b010;
localparam PROCESS = 3'b011;
localparam OUTPUT = 3'b100;

// 数据缓冲和控制
reg [15:0] sample_buffer [0:FFT_LENGTH-1];
reg [9:0] sample_count;
reg buffer_full;
reg [9:0] send_count;

// AXI4-Stream接口信号
wire [31:0] i_axi4s_data_tdata;
reg i_axi4s_data_tvalid;
reg i_axi4s_data_tlast;
wire o_axi4s_data_tready;

wire [31:0] o_axi4s_data_tdata;
wire o_axi4s_data_tvalid;
wire o_axi4s_data_tlast;
wire [23:0] o_axi4s_data_tuser;

// 配置接口
reg i_axi4s_cfg_tvalid;
wire [7:0] i_axi4s_cfg_tdata;

// FFT输出处理
reg [31:0] magnitude [0:511];
reg [31:0] max_magnitude;
reg [9:0] max_index;
reg [9:0] output_bin_count;

// 输入数据格式化：实部+虚部(0)
assign i_axi4s_data_tdata = {time_domain_data, 16'b0};

// 配置数据：设置FFT参数
assign i_axi4s_cfg_tdata = 8'h03; // 示例配置，根据FFT核文档调整

// 主状态机
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        sample_count <= 10'b0;
        send_count <= 10'b0;
        buffer_full <= 1'b0;
        i_axi4s_data_tvalid <= 1'b0;
        i_axi4s_data_tlast <= 1'b0;
        i_axi4s_cfg_tvalid <= 1'b0;
        fft_valid <= 1'b0;
        max_magnitude <= 32'b0;
        max_index <= 10'b0;
        output_bin_count <= 10'b0;
    end else begin
        case (state)
            IDLE: begin
                sample_count <= 10'b0;
                send_count <= 10'b0;
                buffer_full <= 1'b0;
                i_axi4s_data_tvalid <= 1'b0;
                i_axi4s_data_tlast <= 1'b0;
                fft_valid <= 1'b0;
                max_magnitude <= 32'b0;
                max_index <= 10'b0;
                output_bin_count <= 10'b0;
                
                // 发送配置
                i_axi4s_cfg_tvalid <= 1'b1;
                if (data_valid) begin
                    state <= COLLECT;
                    i_axi4s_cfg_tvalid <= 1'b0;
                end
            end
            
            COLLECT: begin
                if (data_valid) begin
                    sample_buffer[sample_count] <= time_domain_data;
                    sample_count <= sample_count + 1;
                    
                    if (sample_count == FFT_LENGTH - 1) begin
                        buffer_full <= 1'b1;
                        state <= SEND_DATA;
                        send_count <= 10'b0;
                    end
                end
            end
            
            SEND_DATA: begin
                if (o_axi4s_data_tready) begin
                    i_axi4s_data_tvalid <= 1'b1;
                    
                    if (send_count == FFT_LENGTH - 1) begin
                        i_axi4s_data_tlast <= 1'b1;
                        state <= PROCESS;
                    end
                    
                    send_count <= send_count + 1;
                end else begin
                    i_axi4s_data_tvalid <= 1'b0;
                end
            end
            
            PROCESS: begin
                i_axi4s_data_tvalid <= 1'b0;
                i_axi4s_data_tlast <= 1'b0;
                
                if (o_axi4s_data_tvalid) begin
                    // 解析FFT输出：实部和虚部
                    fft_real <= o_axi4s_data_tdata[31:16];
                    fft_imag <= o_axi4s_data_tdata[15:0];
                    
                    // 计算幅值
                    magnitude[output_bin_count] <= (o_axi4s_data_tdata[31:16] * o_axi4s_data_tdata[31:16]) + 
                                                 (o_axi4s_data_tdata[15:0] * o_axi4s_data_tdata[15:0]);
                    
                    // 寻找最大幅值对应的bin
                    if (magnitude[output_bin_count] > max_magnitude && output_bin_count > 0) begin
                        max_magnitude <= magnitude[output_bin_count];
                        max_index <= output_bin_count;
                    end
                    
                    output_bin_count <= output_bin_count + 1;
                    
                    if (o_axi4s_data_tlast) begin
                        state <= OUTPUT;
                        dominant_bin <= max_index;
                    end
                end
            end
            
            OUTPUT: begin
                fft_valid <= 1'b1;
                state <= IDLE;
            end
            
            default: state <= IDLE;
        endcase
    end
end

// Pango FFT IP核实例化 (AXI4-Stream接口)
u_pango_fft u_pango_fft_inst (
    // 输入数据接口
    .i_axi4s_data_tdata(i_axi4s_data_tdata),      // input [31:0] - 实部[31:16] + 虚部[15:0]
    .i_axi4s_data_tvalid(i_axi4s_data_tvalid),    // input
    .i_axi4s_data_tlast(i_axi4s_data_tlast),      // input
    .o_axi4s_data_tready(o_axi4s_data_tready),    // output
    
    // 配置接口
    .i_axi4s_cfg_tdata(i_axi4s_cfg_tdata),        // input [7:0]
    .i_axi4s_cfg_tvalid(i_axi4s_cfg_tvalid),      // input
    
    // 时钟
    .i_aclk(clk),                                 // input
    
    // 输出数据接口
    .o_axi4s_data_tdata(o_axi4s_data_tdata),      // output [31:0] - 实部[31:16] + 虚部[15:0]
    .o_axi4s_data_tvalid(o_axi4s_data_tvalid),    // output
    .o_axi4s_data_tlast(o_axi4s_data_tlast),      // output
    .o_axi4s_data_tuser(o_axi4s_data_tuser),      // output [23:0]
    
    // 状态输出
    .o_alm(o_alm),                                // output
    .o_stat(o_stat)                               // output
);

endmodule