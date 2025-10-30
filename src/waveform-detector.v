// 波形检测模块
module waveform_detector #(
    // ADC 数据分辨率
    parameter DATA_WIDTH          = 12,
    // 缓存区大小 (通过地址位宽定义, 10 => 2^10 = 1024 个采样点)
    parameter BUFFER_ADDR_WIDTH   = 10,
    // 判断斜率为“平坦”(接近零)的阈值
    parameter FLAT_THRESHOLD      = 5,
    // 判断斜率为“陡峭”(急剧变化)的阈值
    parameter STEEP_THRESHOLD     = 500,
    // 判断三角波恒定斜率的容差
    parameter TRIANGLE_SLOPE_TOLERANCE = 10
) (
    // -- 端口定义 --
    // 输入端口
    input wire                      clk,                // 系统主时钟(高电平有效)
    input wire                      reset,              // 高电平有效复位
    input wire                      start_analysis,     // 启动分析信号
    input wire [DATA_WIDTH-1:0]     bram_data_in,       // BRAM读出的数据

    // 输出端口
    output reg [BUFFER_ADDR_WIDTH-1:0] bram_read_address, // BRAM读取地址
    output reg [1:0]                waveform_type,      // 检测出的波形类型(00:正弦,01:方波:10:三角)
    output reg                      done                // 分析完成标志
);

    // -- 波形类型编码 --
    localparam SINE     = 2'b00; // 正弦波
    localparam SQUARE   = 2'b01; // 方波
    localparam TRIANGLE = 2'b10; // 三角波

    // -- 状态机状态编码 --
    localparam FSM_IDLE     = 2'b00; // 空闲状态
    localparam FSM_ANALYZE  = 2'b01; // 分析状态
    localparam FSM_CLASSIFY = 2'b10; // 分类状态
    localparam FSM_DONE     = 2'b11; // 完成状态

    localparam BUFFER_SIZE = 2**BUFFER_ADDR_WIDTH;
    // 计算缓存区大小的75%作为检测阈值
    localparam MAJORITY_THRESHOLD = (BUFFER_SIZE >> 2) * 3;


    // -- 内部寄存器定义 --
    // 状态机状态寄存器
    reg [1:0] state, next_state;

    // 数据分析寄存器
    reg [DATA_WIDTH-1:0] max_val;
    reg [DATA_WIDTH-1:0] min_val;
    reg [DATA_WIDTH-1:0] prev_sample;
    reg signed [DATA_WIDTH:0] slope;

    // 特征计数寄存器
    reg [31:0] flat_count;
    reg [31:0] steep_count;
    reg [31:0] positive_slope_count;
    reg [31:0] negative_slope_count;
    reg [31:0] slope_inversion_count;

    // 三角波斜率分析寄存器
    reg signed [DATA_WIDTH:0] avg_positive_slope;
    reg signed [DATA_WIDTH:0] avg_negative_slope;
    reg prev_slope_was_positive;

    // -- 组合逻辑 --
    // 计算当前采样点和前一个采样点之间的斜率
    assign slope = bram_data_in - prev_sample;

    // -- 时序逻辑 (寄存器逻辑) --

    // 状态机状态寄存器
    always @(posedge clk) begin
        if (reset) begin
            state <= FSM_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // 状态机状态转移和数据路径控制
    always @(*) begin
        // 默认值, 防止生成锁存器
        next_state = state;
        done = 1'b0;

        case (state)
            FSM_IDLE: begin
                if (start_analysis) begin
                    next_state = FSM_ANALYZE;
                end
            end
            FSM_ANALYZE: begin
                // 当读指针到达缓存区末尾时, 进入分类状态
                if (bram_read_address == BUFFER_SIZE - 1) begin
                    next_state = FSM_CLASSIFY;
                end
            end
            FSM_CLASSIFY: begin
                // 分类需要一个时钟周期, 然后进入完成状态
                next_state = FSM_DONE;
            end
            FSM_DONE: begin
                // 将 done 信号置高一个周期, 然后返回空闲状态
                done = 1'b1;
                next_state = FSM_IDLE;
            end
        endcase
    end

    // 数据路径逻辑 (计算部分)
    always @(posedge clk) begin
        if (reset) begin
            // 复位所有分析和输出寄存器
            bram_read_address <= 0;
            max_val <= 0;
            min_val <= {(DATA_WIDTH){1'b1}};
            prev_sample <= 0;
            flat_count <= 0;
            steep_count <= 0;
            positive_slope_count <= 0;
            negative_slope_count <= 0;
            slope_inversion_count <= 0;
            waveform_type <= SINE;
            prev_slope_was_positive <= 0;
        end else begin
            case (state)
                FSM_IDLE: begin
                    if (start_analysis) begin
                        // 在开始分析前, 清零所有计数器和指针
                        bram_read_address <= 0;
                        max_val <= 0;
                        min_val <= {(DATA_WIDTH){1'b1}};
                        prev_sample <= 0;
                        flat_count <= 0;
                        steep_count <= 0;
                        positive_slope_count <= 0;
                        negative_slope_count <= 0;
                        slope_inversion_count <= 0;
                        prev_slope_was_positive <= 0;
                    end
                end
                FSM_ANALYZE: begin
                    // 地址指针递增, 扫描BRAM
                    bram_read_address <= bram_read_address + 1;

                    // 为下一个周期的斜率计算更新前一个采样点的值
                    prev_sample <= bram_data_in;

                    // 寻找缓存区中的最大值和最小值
                    if (bram_data_in > max_val) max_val <= bram_data_in;
                    if (bram_data_in < min_val) min_val <= bram_data_in;

                    // 更新斜率计数器 (忽略第一个点的无效斜率)
                    if (bram_read_address > 0) begin
                        // 平坦斜率检查
                        if (slope < FLAT_THRESHOLD && slope > -FLAT_THRESHOLD) begin
                            flat_count <= flat_count + 1;
                        end
                        // 陡峭斜率检查
                        if (slope > STEEP_THRESHOLD || slope < -STEEP_THRESHOLD) begin
                            steep_count <= steep_count + 1;
                        end

                        // 三角波斜率检查
                        // 检查恒为正的斜率
                        if (slope > TRIANGLE_SLOPE_TOLERANCE) begin
                            positive_slope_count <= positive_slope_count + 1;
                            if(~prev_slope_was_positive) slope_inversion_count <= slope_inversion_count + 1;
                            prev_slope_was_positive <= 1'b1;
                        end
                        // 检查恒为负的斜率
                        if (slope < -TRIANGLE_SLOPE_TOLERANCE) begin
                            negative_slope_count <= negative_slope_count + 1;
                            if(prev_slope_was_positive) slope_inversion_count <= slope_inversion_count + 1;
                            prev_slope_was_positive <= 1'b0;
                        end
                    end else begin
                         // 对第一个采样点, 判断初始斜率是正还是负
                         if (slope > TRIANGLE_SLOPE_TOLERANCE) prev_slope_was_positive <= 1'b1;
                         if (slope < -TRIANGLE_SLOPE_TOLERANCE) prev_slope_was_positive <= 1'b0;
                    end
                end
                FSM_CLASSIFY: begin
                    // -- 波形分类逻辑 (使用参数化阈值) --
                    // 方波检查: >75%的点是平坦的, 且至少有一个陡峭点
                    if (flat_count > MAJORITY_THRESHOLD && steep_count >= 1 && steep_count < 10) begin
                        waveform_type <= SQUARE;
                    end
                    // 三角波检查: >75%的点斜率恒定, 且只有少数几个转折点
                    else if ((positive_slope_count + negative_slope_count > MAJORITY_THRESHOLD || positive_slope_count + negative_slope_count < -MAJORITY_THRESHOLD) && (slope_inversion_count > 0 && slope_inversion_count < 5) ) begin
                        waveform_type <= TRIANGLE;
                    end
                    // 默认情况
                    else begin
                        waveform_type <= SINE;
                    end
                end
            endcase
        end
    end

endmodule

