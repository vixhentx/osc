module dds_signal_generator(
    input wire clk,
    input wire rst_n,
    input wire [1:0] wave_sel,   // 波形选择
    input wire [15:0] freq_ctrl, // 频率控制字
    output reg [7:0] dout,       // 输出数据
    output reg valid             // 数据有效
);

// 相位累加器
reg [31:0] phase_accum;
wire [9:0] phase_addr;

// 波形ROM
reg [7:0] sine_rom [0:1023];
reg [7:0] triangle_rom [0:1023];
reg [7:0] sawtooth_rom [0:1023];

// 初始化波形ROM
integer i;
initial begin
    for (i = 0; i < 1024; i = i + 1) begin
        // 正弦波 (10位地址，8位数据)
        sine_rom[i] = 128 + 127 * $sin(2.0 * 3.1415926 * i / 1024.0);
        // 三角波
        triangle_rom[i] = (i < 512) ? (i / 2) : (255 - (i - 512) / 2);
        // 锯齿波
        sawtooth_rom[i] = i / 4;
    end
end

// 相位累加
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phase_accum <= 32'd0;
    end else begin
        phase_accum <= phase_accum + {freq_ctrl, 16'd0};
    end
end

assign phase_addr = phase_accum[31:22]; // 使用高10位作为ROM地址

// 波形生成
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout <= 8'd128; // 中间值
        valid <= 1'b0;
    end else begin
        valid <= 1'b1;
        case (wave_sel)
            2'b00: dout <= sine_rom[phase_addr];              // 正弦波
            2'b01: dout <= (phase_accum[31]) ? 8'hFF : 8'h00; // 方波
            2'b10: dout <= triangle_rom[phase_addr];          // 三角波
            2'b11: dout <= sawtooth_rom[phase_addr];          // 锯齿波
            default: dout <= sine_rom[phase_addr];
        endcase
    end
end

endmodule