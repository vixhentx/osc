module dac_controller(
    input wire clk_100m,
    input wire clk_125m,
    input wire rst_n,
    input wire [7:0] dac_data_in,
    output reg [7:0] dac_data_out,
    output reg dac_clk,
    output reg dac_oe_n
);

// 跨时钟域同步
reg [7:0] dac_data_sync;
reg dac_clk_reg;

// 生成DA时钟 (62.5MHz = 125MHz/2)
always @(posedge clk_125m or negedge rst_n) begin
    if (!rst_n) begin
        dac_clk_reg <= 1'b0;
        dac_clk <= 1'b0;
    end else begin
        dac_clk_reg <= ~dac_clk_reg;
        dac_clk <= dac_clk_reg;
    end
end

// 数据同步到DA时钟域
always @(posedge clk_125m or negedge rst_n) begin
    if (!rst_n) begin
        dac_data_sync <= 8'd0;
        dac_data_out <= 8'd0;
        dac_oe_n <= 1'b0;
    end else begin
        // 在DA时钟的下降沿更新数据
        if (!dac_clk_reg) begin
            dac_data_sync <= dac_data_in;
            dac_data_out <= dac_data_sync;
        end
        dac_oe_n <= 1'b0;  // 始终使能DA输出
    end
end

endmodule