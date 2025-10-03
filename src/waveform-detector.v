// 模块定义: 波形检测器 (最终实现版 - 修正了三角波检测逻辑)
module waveform_detector #(
    // 参数: ADC数据的位宽
    parameter DATA_WIDTH          = 12,
    // 参数: 缓存区地址的位宽 (10 => 1024个采样点)
    parameter BUFFER_ADDR_WIDTH   = 10,
    // 参数: 判断斜率为“平坦”的阈值
    parameter FLAT_THRESHOLD      = 5,
    // 参数: 判断斜率为“陡峭”的阈值
    parameter STEEP_THRESHOLD     = 500
) (
    // -- 输入端口 --
    input wire                      clk,
    input wire                      reset,
    input wire                      start_analysis,
    input wire [DATA_WIDTH-1:0]     bram_data_in,

    // -- 输出端口 --
    output reg [BUFFER_ADDR_WIDTH-1:0] bram_read_address,
    output reg [1:0]                waveform_type,
    output reg                      done
);

    // 状态机定义
    localparam FSM_IDLE     = 2'b00;
    localparam FSM_ANALYZE  = 2'b01;
    localparam FSM_CLASSIFY = 2'b10;
    localparam FSM_DONE     = 2'b11;
    reg [1:0] state, next_state;

    // 内部数据分析寄存器
    reg [DATA_WIDTH-1:0] prev_sample;
    wire signed [DATA_WIDTH:0] slope;
    reg [31:0] flat_count;
    reg [31:0] steep_count;
    
    // 三角波检测逻辑的寄存器
    reg signed [DATA_WIDTH:0] target_slope;
    reg [31:0] positive_slope_count;
    reg [31:0] negative_slope_count;
    reg [7:0]  slope_inversion_count;
    // -- 新增: 寄存器用于存储上一个周期的斜率 --
    reg signed [DATA_WIDTH:0] prev_slope;

    // 组合逻辑
    assign slope = bram_data_in - prev_sample;

    // 状态机时序逻辑
    always @(posedge clk) begin
        if (reset) state <= FSM_IDLE;
        else state <= next_state;
    end

    // 状态机组合逻辑
    always @(*) begin
        next_state = state;
        done = 1'b0;
        case (state)
            FSM_IDLE:     if (start_analysis) next_state = FSM_ANALYZE;
            FSM_ANALYZE:  if (bram_read_address == (2**BUFFER_ADDR_WIDTH) - 1) next_state = FSM_CLASSIFY;
            FSM_CLASSIFY: next_state = FSM_DONE;
            FSM_DONE: begin
                done = 1'b1;
                next_state = FSM_IDLE;
            end
        endcase
    end

    // 数据分析的时序逻辑
    always @(posedge clk) begin
        if (reset) begin
            bram_read_address <= 0;
            prev_sample <= 0;
            waveform_type <= 2'b00;
            flat_count <= 0;
            steep_count <= 0;
            target_slope <= 0;
            positive_slope_count <= 0;
            negative_slope_count <= 0;
            slope_inversion_count <= 0;
            prev_slope <= 0;
        end else begin
            case (state)
                FSM_IDLE: begin
                    if (start_analysis) begin
                        // 复位所有分析寄存器
                        bram_read_address <= 0;
                        prev_sample <= 0;
                        flat_count <= 0;
                        steep_count <= 0;
                        target_slope <= 0;
                        positive_slope_count <= 0;
                        negative_slope_count <= 0;
                        slope_inversion_count <= 0;
                        prev_slope <= 0;
                    end
                end
                FSM_ANALYZE: begin
                    bram_read_address <= bram_read_address + 1;
                    prev_sample <= bram_data_in;
                    prev_slope <= slope; // 在每个周期更新上一个斜率

                    if (bram_read_address > 0) begin
                        if (slope < FLAT_THRESHOLD && slope > -FLAT_THRESHOLD) flat_count <= flat_count + 1;
                        if (slope > STEEP_THRESHOLD || slope < -STEEP_THRESHOLD) steep_count <= steep_count + 1;
                        
                        if (bram_read_address > 10 && target_slope == 0 && (slope > FLAT_THRESHOLD || slope < -FLAT_THRESHOLD)) begin
                            target_slope <= (slope > 0) ? slope : -slope;
                        end
                        
                        if (target_slope > 0) begin
                            if (slope > (target_slope - target_slope/2) && slope < (target_slope + target_slope/2)) begin
                                positive_slope_count <= positive_slope_count + 1;
                            end
                            if (slope < (-target_slope + target_slope/2) && slope > (-target_slope - target_slope/2)) begin
                                negative_slope_count <= negative_slope_count + 1;
                            end
                        end
                        
                        // -- 修正: 检测斜率符号是否翻转的逻辑 --
                        if ((slope > FLAT_THRESHOLD && prev_slope < -FLAT_THRESHOLD) || (slope < -FLAT_THRESHOLD && prev_slope > FLAT_THRESHOLD)) begin
                            slope_inversion_count <= slope_inversion_count + 1;
                        end
                    end
                end
                FSM_CLASSIFY: begin
                    // -- 波形分类判决逻辑 --
                    if (flat_count > 800 && steep_count > 1 && steep_count < 10) begin
                        waveform_type <= 2'b01; // 方波
                    end else if ( (positive_slope_count + negative_slope_count > 800) &&
                                  (positive_slope_count > 300) &&
                                  (negative_slope_count > 300) &&
                                  (slope_inversion_count >= 1 && slope_inversion_count < 5) ) begin
                        waveform_type <= 2'b10; // 三角波
                    end else begin
                        waveform_type <= 2'b00; // 正弦波
                    end
                end
            endcase
        end
    end

endmodule

