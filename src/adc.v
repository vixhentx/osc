module top_adc_system (
    // 输入端口声明
    input wire clk_50m,
    input wire rst_n,
    input wire adc_start,
    input wire adc_sdo,
    
    // 输出端口声明  
    output wire adc_sclk,
    output wire adc_cs_n,
    output wire [7:0] adc_data,
    output wire adc_ready,
    output wire [7:0] led
);

// 内部连线声明
wire [11:0] adc_raw;
wire adc_done;
wire fifo_full;
wire fifo_empty;

// ADC控制器实例化
adc_controller u_adc (
    .clk(clk_50m),
    .rst_n(rst_n),
    .start(adc_start),
    .adc_data(adc_raw),
    .adc_done(adc_done),
    .adc_sclk(adc_sclk),
    .adc_cs_n(adc_cs_n),
    .adc_sdo(adc_sdo)
);

// FIFO缓存实例化
fifo_adc u_fifo (
    .clk(clk_50m),
    .rst_n(rst_n),
    .wr_en(adc_done),
    .din(adc_raw),
    .rd_en(~fifo_empty),
    .dout(adc_data),
    .full(fifo_full),
    .empty(fifo_empty)
);

// 连续赋值
assign adc_ready = ~fifo_empty;
assign led = adc_data;

endmodule


#
module adc_controller (
    input wire clk,
    input wire rst_n,
    input wire start,
    output reg [11:0] adc_data,
    output reg adc_done,
    output reg adc_sclk,
    output reg adc_cs_n,
    input wire adc_sdo
);

// 状态机定义
localparam S_IDLE   = 3'b000;
localparam S_CS_LOW = 3'b001;
localparam S_CONV   = 3'b010;
localparam S_DONE   = 3'b011;

reg [2:0] state;
reg [7:0] clk_div;
reg [3:0] bit_count;
reg [11:0] shift_reg;
reg sclk_enable;

// 时钟分频逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_div <= 8'b0;
        adc_sclk <= 1'b0;
    end else if (sclk_enable) begin
        if (clk_div == 8'd9) begin
            clk_div <= 8'b0;
            adc_sclk <= ~adc_sclk;
        end else begin
            clk_div <= clk_div + 1;
        end
    end else begin
        clk_div <= 8'b0;
        adc_sclk <= 1'b0;
    end
end

// 主状态机
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE;
        adc_data <= 12'b0;
        adc_done <= 1'b0;
        adc_cs_n <= 1'b1;
        sclk_enable <= 1'b0;
        bit_count <= 4'b0;
        shift_reg <= 12'b0;
    end else begin
        adc_done <= 1'b0;
        
        case (state)
            S_IDLE: begin
                adc_cs_n <= 1'b1;
                sclk_enable <= 1'b0;
                if (start) begin
                    state <= S_CS_LOW;
                    adc_cs_n <= 1'b0;
                    bit_count <= 4'b0;
                    shift_reg <= 12'b0;
                end
            end
            
            S_CS_LOW: begin
                if (clk_div == 8'd20) begin
                    state <= S_CONV;
                    sclk_enable <= 1'b1;
                end
            end
            
            S_CONV: begin
                if (adc_sclk && (clk_div == 8'd4)) begin
                    shift_reg <= {shift_reg[10:0], adc_sdo};
                    bit_count <= bit_count + 1;
                    
                    if (bit_count == 4'd11) begin
                        state <= S_DONE;
                        sclk_enable <= 1'b0;
                    end
                end
            end
            
            S_DONE: begin
                adc_data <= shift_reg;
                adc_done <= 1'b1;
                state <= S_IDLE;
            end
            
            default: begin
                state <= S_IDLE;
            end
        endcase
    end
end

endmodule

#
module fifo_adc (
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire [11:0] din,
    input wire rd_en,
    output reg [11:0] dout,
    output wire full,
    output wire empty
);

parameter DEPTH = 1024;
parameter WIDTH = 12;
parameter ADDR_WIDTH = 10;

reg [WIDTH-1:0] mem [0:DEPTH-1];
reg [ADDR_WIDTH-1:0] wr_ptr;
reg [ADDR_WIDTH-1:0] rd_ptr;
reg [ADDR_WIDTH:0] count;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        count <= 0;
        dout <= 0;
    end else begin
        if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
        end
        
        if (rd_en && !empty) begin
            dout <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
        
        case ({wr_en && !full, rd_en && !empty})
            2'b01: count <= count - 1;
            2'b10: count <= count + 1;
            default: count <= count;
        endcase
    end
end

assign full = (count == DEPTH);
assign empty = (count == 0);

endmodule


#约束条件
# 时钟约束 - 27MHz系统时钟
create_clock -name clk_27m -period 37.037 [get_ports clk_50m]

# 输入端口约束
set_property PACKAGE_PIN D18 [get_ports clk_50m]
set_property IOSTANDARD LVCMOS33 [get_ports clk_50m]

set_property PACKAGE_PIN P15 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

set_property PACKAGE_PIN J14 [get_ports adc_start]
set_property IOSTANDARD LVCMOS33 [get_ports adc_start]

set_property PACKAGE_PIN K17 [get_ports adc_sdo]
set_property IOSTANDARD LVCMOS33 [get_ports adc_sdo]

# 输出端口约束 - ADC控制
set_property PACKAGE_PIN K15 [get_ports adc_sclk]
set_property IOSTANDARD LVCMOS33 [get_ports adc_sclk]

set_property PACKAGE_PIN K16 [get_ports adc_cs_n]
set_property IOSTANDARD LVCMOS33 [get_ports adc_cs_n]

# 输出端口约束 - ADC数据输出
set_property PACKAGE_PIN A10 [get_ports {adc_data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[0]}]

set_property PACKAGE_PIN A11 [get_ports {adc_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[1]}]

set_property PACKAGE_PIN B10 [get_ports {adc_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[2]}]

set_property PACKAGE_PIN B11 [get_ports {adc_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[3]}]

set_property PACKAGE_PIN C10 [get_ports {adc_data[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[4]}]

set_property PACKAGE_PIN C11 [get_ports {adc_data[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[5]}]

set_property PACKAGE_PIN D10 [get_ports {adc_data[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[6]}]

set_property PACKAGE_PIN D11 [get_ports {adc_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[7]}]

# ADC就绪标志
set_property PACKAGE_PIN G12 [get_ports adc_ready]
set_property IOSTANDARD LVCMOS33 [get_ports adc_ready]

# LED显示输出
set_property PACKAGE_PIN A20 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN C18 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN C19 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

set_property PACKAGE_PIN E18 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

set_property PACKAGE_PIN A17 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]

set_property PACKAGE_PIN A18 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]

set_property PACKAGE_PIN C17 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]

set_property PACKAGE_PIN B17 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]

# 输入输出延迟约束
set_input_delay -clock clk_27m -max 5 [get_ports adc_sdo]
set_input_delay -clock clk_27m -max 5 [get_ports adc_start]
set_input_delay -clock clk_27m -max 5 [get_ports rst_n]

set_output_delay -clock clk_27m -max 5 [get_ports adc_sclk]
set_output_delay -clock clk_27m -max 5 [get_ports adc_cs_n]
set_output_delay -clock clk_27m -max 5 [get_ports adc_data[*]]
set_output_delay -clock clk_27m -max 5 [get_ports adc_ready]
set_output_delay -clock clk_27m -max 5 [get_ports led[*]]

# 虚假路径
set_false_path -from [get_ports rst_n]