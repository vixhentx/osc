module signal_generator_adc_top(
    input wire clk_27m,          // 27MHz系统时钟
    input wire rst_n,            // 复位信号
    // DA输出接口 (MS9708)
    output wire [7:0] dac_data,  // DA数据输出
    output wire dac_clk,         // DA时钟
    output wire dac_oe_n,        // DA输出使能(低有效)
    // AD输入接口 (MS9280)  
    input wire [7:0] adc_data,   // AD数据输入(使用高8位)
    output wire adc_clk,         // AD时钟
    input wire adc_otr,          // AD超量程指示
    // 控制接口
    input wire [1:0] wave_sel,   // 波形选择: 00-正弦, 01-方波, 10-三角波, 11-锯齿波
    input wire [15:0] freq_ctrl, // 频率控制字
    // 状态指示
    output reg [7:0] led         // LED状态显示
);

// 时钟管理
wire clk_100m;
wire clk_125m;
wire pll_locked;

// 实例化PLL IP核
clk_pll u_clk_pll (
    .clkin1(clk_27m),    // 输入27MHz时钟
    .clkout0(clk_100m),  // 输出100MHz时钟
    .clkout1(clk_125m),  // 输出125MHz时钟
    .lock(pll_locked)    // PLL锁定信号
);

// 数字信号发生器
wire [7:0] dds_data;

dds_signal_generator u_dds(
    .clk(clk_100m),
    .rst_n(rst_n & pll_locked),
    .wave_sel(wave_sel),
    .freq_ctrl(freq_ctrl),
    .dout(dds_data),
    .valid()
);

// DA控制器
dac_controller u_dac(
    .clk_100m(clk_100m),
    .clk_125m(clk_125m),
    .rst_n(rst_n & pll_locked),
    .dac_data_in(dds_data),
    .dac_data_out(dac_data),
    .dac_clk(dac_clk),
    .dac_oe_n(dac_oe_n)
);

// AD控制器  
adc_controller u_adc(
    .clk(clk_100m),
    .rst_n(rst_n & pll_locked),
    .adc_data_in(adc_data),
    .adc_clk(adc_clk),
    .adc_otr(adc_otr),
    .adc_data_out(),
    .adc_valid()
);

// 状态显示逻辑
always @(posedge clk_100m or negedge rst_n) begin
    if (!rst_n) begin
        led <= 8'h00;
    end else begin
        led <= {wave_sel, 2'b00, adc_otr, 3'b000};
    end
end

endmodule