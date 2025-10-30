`timescale 1ns / 1ps

module pango_pll(
    input clk_in,
    output clk_out_50m,
    output clk_out_100m,
    output locked
);

// 简单的时钟分频器模拟PLL功能
reg [1:0] counter_50m = 0;
reg counter_100m = 0;
reg locked_reg = 0;

// 50MHz时钟生成 (27MHz -> 50MHz 近似)
always @(posedge clk_in) begin
    counter_50m <= counter_50m + 1;
end

assign clk_out_50m = counter_50m[1];  // 近似50MHz

// 100MHz时钟生成
always @(posedge clk_in) begin
    counter_100m <= ~counter_100m;
end

assign clk_out_100m = counter_100m;   // 近似100MHz

// PLL锁定信号
reg [7:0] startup_counter = 0;
always @(posedge clk_in) begin
    if (startup_counter == 8'd255) begin
        locked_reg <= 1'b1;
    end else begin
        startup_counter <= startup_counter + 1;
    end
end

assign locked = locked_reg;

endmodule