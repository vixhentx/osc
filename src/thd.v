// 模块定义: 总谐波失真 (THD) 计算器
// 待办: 由团队成员实现内部逻辑 (通常是FFT及后续计算)
module thd_calculator #(
    // 参数: ADC数据的位宽
    parameter DATA_WIDTH      = 12,
    // 参数: 缓存区地址的位宽
    parameter BUFFER_ADDR_WIDTH = 10
) (
    // -- 输入端口 --
    input wire                      clk,                // 输入: 系统主时钟信号
    input wire                      reset,              // 输入: 高电平有效的复位信号
    input wire                      start_analysis,     // 输入: 来自顶层模块的单周期脉冲, 用于启动一次THD分析
    input wire [DATA_WIDTH-1:0]     bram_data_in,       // 输入: 从共享BRAM读出的数据

    // -- 输出端口 --
    output reg [BUFFER_ADDR_WIDTH-1:0] bram_read_address, // 输出: 需要从BRAM读取的数据地址
    output reg [15:0]               thd_result,         // 输出: 16位定点数表示的THD计算结果
    output reg                      done                // 输出: 单周期脉冲, 表示THD计算完成, thd_result有效
);

    // -- 内部逻辑 --
    // 在此实现THD计算逻辑
    // 1. 接收到 start_analysis 信号后开始运行
    // 2. 通过控制 bram_read_address 来从BRAM中读取整个波形数据
    // 3. 对数据进行FFT (快速傅里叶变换)
    // 4. 根据FFT结果计算基波和谐波的能量
    // 5. 计算THD值并赋给 thd_result
    // 6. 计算完成后, 将 done 信号置为高电平一个时钟周期

endmodule