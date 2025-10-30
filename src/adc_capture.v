`timescale 1ns / 1ps

module adc_capture(
    input clk,
    input rst_n,
    input adc_input,
    output reg [11:0] adc_data,
    output reg data_ready
);

// APB接口信号 - 根据实际IP核端口
reg [7:0] i_apb_paddr;
reg i_apb_psel;
reg i_apb_enable;
reg i_apb_pwrite;
reg [15:0] i_apb_pwdata;
wire [15:0] o_apb_prdata;
wire o_apb_pready;

// ADC控制信号
reg i_adc_loadsc_n;
wire o_over_temp;
wire o_logic_done_a;
wire o_logic_done_b;
wire o_adc_clk_out;
wire o_adc_dmodified;

// 状态机定义
reg [2:0] state;
localparam IDLE = 3'b000;
localparam INIT = 3'b001;
localparam CONFIG = 3'b010;
localparam WAIT_READY = 3'b011;
localparam READ_DATA = 3'b100;
localparam OUTPUT = 3'b101;

// 配置寄存器地址
localparam ADC_CTRL_REG = 8'h00;
localparam ADC_DATA_REG = 8'h04;
localparam ADC_STATUS_REG = 8'h08;

// 控制变量
reg [3:0] config_step;
reg [15:0] read_data;
reg [7:0] timeout_counter;

// 主状态机
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        i_apb_psel <= 1'b0;
        i_apb_enable <= 1'b0;
        i_apb_pwrite <= 1'b0;
        i_apb_paddr <= 8'b0;
        i_apb_pwdata <= 16'b0;
        i_adc_loadsc_n <= 1'b1;
        adc_data <= 12'b0;
        data_ready <= 1'b0;
        config_step <= 4'b0;
        timeout_counter <= 8'b0;
    end else begin
        case (state)
            IDLE: begin
                i_apb_psel <= 1'b0;
                i_apb_enable <= 1'b0;
                data_ready <= 1'b0;
                config_step <= 4'b0;
                timeout_counter <= 8'b0;
                state <= INIT;
            end
            
            INIT: begin
                // 释放ADC负载开关
                i_adc_loadsc_n <= 1'b0;
                timeout_counter <= timeout_counter + 1;
                if (timeout_counter == 8'd100) begin
                    state <= CONFIG;
                    timeout_counter <= 8'b0;
                end
            end
            
            CONFIG: begin
                case (config_step)
                    4'd0: begin
                        // 配置ADC控制寄存器
                        i_apb_psel <= 1'b1;
                        i_apb_enable <= 1'b1;
                        i_apb_pwrite <= 1'b1;
                        i_apb_paddr <= ADC_CTRL_REG;
                        i_apb_pwdata <= 16'h0003; // 使能ADC，设置采样率等
                        config_step <= 4'd1;
                    end
                    4'd1: begin
                        if (o_apb_pready) begin
                            i_apb_psel <= 1'b0;
                            i_apb_enable <= 1'b0;
                            config_step <= 4'd2;
                            timeout_counter <= 8'b0;
                        end
                    end
                    4'd2: begin
                        // 等待配置完成
                        timeout_counter <= timeout_counter + 1;
                        if (timeout_counter == 8'd50) begin
                            state <= WAIT_READY;
                            config_step <= 4'b0;
                        end
                    end
                    default: config_step <= 4'b0;
                endcase
            end
            
            WAIT_READY: begin
                // 检查ADC是否就绪
                i_apb_psel <= 1'b1;
                i_apb_enable <= 1'b1;
                i_apb_pwrite <= 1'b0;
                i_apb_paddr <= ADC_STATUS_REG;
                
                if (o_apb_pready) begin
                    read_data <= o_apb_prdata;
                    i_apb_psel <= 1'b0;
                    i_apb_enable <= 1'b0;
                    
                    // 检查状态寄存器就绪位
                    if (read_data[0] && o_adc_dmodified) begin
                        state <= READ_DATA;
                    end
                end
                
                timeout_counter <= timeout_counter + 1;
                if (timeout_counter == 8'd255) begin
                    // 超时，重新初始化
                    state <= INIT;
                end
            end
            
            READ_DATA: begin
                // 读取ADC数据
                i_apb_psel <= 1'b1;
                i_apb_enable <= 1'b1;
                i_apb_pwrite <= 1'b0;
                i_apb_paddr <= ADC_DATA_REG;
                
                if (o_apb_pready) begin
                    read_data <= o_apb_prdata;
                    i_apb_psel <= 1'b0;
                    i_apb_enable <= 1'b0;
                    state <= OUTPUT;
                end
            end
            
            OUTPUT: begin
                // 输出ADC数据
                adc_data <= read_data[11:0]; // 提取12位ADC数据
                data_ready <= 1'b1;
                state <= WAIT_READY;
                
                // 短暂保持数据就绪信号
                timeout_counter <= timeout_counter + 1;
                if (timeout_counter == 8'd10) begin
                    data_ready <= 1'b0;
                    timeout_counter <= 8'b0;
                end
            end
            
            default: state <= IDLE;
        endcase
    end
end

// Pango ADC IP核实例化 - 使用正确的端口名称
u_pango_adc u_pango_adc_inst (
    .i_rst_n(rst_n),                    // input
    .i_apb_clk(clk),                    // input - 注意：这里是i_apb_clk，不是i_apb_pclk
    .i_apb_paddr(i_apb_paddr),          // input [7:0]
    .i_apb_psel(i_apb_psel),            // input
    .i_apb_enable(i_apb_enable),        // input
    .i_apb_pwrite(i_apb_pwrite),        // input
    .i_apb_pwdata(i_apb_pwdata),        // input [15:0]
    .o_apb_prdata(o_apb_prdata),        // output [15:0]
    .o_apb_pready(o_apb_pready),        // output
    
    .i_adc_loadsc_n(i_adc_loadsc_n),    // input
    .o_over_temp(o_over_temp),          // output
    .o_logic_done_a(o_logic_done_a),    // output
    .o_logic_done_b(o_logic_done_b),    // output
    .o_adc_clk_out(o_adc_clk_out),      // output
    .o_adc_dmodified(o_adc_dmodified)   // output
);

endmodule