module adc_controller(
    input wire clk,
    input wire rst_n,
    input wire [7:0] adc_data_in,
    output reg adc_clk,
    output reg [7:0] adc_data_out,
    output reg adc_valid,
    input wire adc_otr
);

reg [3:0] adc_clk_divider;
reg [7:0] adc_data_sync;
reg adc_clk_reg;

// 生成AD采样时钟 (约12.5MHz = 100MHz/8)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        adc_clk_divider <= 4'd0;
        adc_clk_reg <= 1'b0;
        adc_clk <= 1'b0;
    end else begin
        adc_clk_divider <= adc_clk_divider + 1;
        if (adc_clk_divider == 4'd7) begin
            adc_clk_reg <= ~adc_clk_reg;
            adc_clk_divider <= 4'd0;
        end
        adc_clk <= adc_clk_reg;
    end
end

// AD数据采集
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        adc_data_sync <= 8'd0;
        adc_data_out <= 8'd0;
        adc_valid <= 1'b0;
    end else begin
        // 在AD时钟下降沿采样数据
        if (adc_clk_divider == 4'd3 && !adc_clk_reg) begin
            adc_data_sync <= adc_data_in;
            adc_data_out <= adc_data_sync;
            adc_valid <= 1'b1;
        end else begin
            adc_valid <= 1'b0;
        end
    end
end

endmodule