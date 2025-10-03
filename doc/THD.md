# THD模块
## 大致实现

## 交互协议

1.  **复位**: 在系统启动时, 将 **reset** 信号置为高电平至少一个时钟周期以初始化模块。
2.  **启动**: 在 **start\_analysis** 端口上发送一个单周期的启动脉冲, 命令模块开始新一轮的参数计算。
3.  **运行**: 模块启动后, 它会自动控制 **bram\_read\_address** 来扫描整个BRAM中的波形数据。这个过程是自动的, 无需外部干预。
4.  **等待完成**: 持续监视 **done** 信号。模块完成所有计算后, 会将此信号拉高一个时钟周期。
5.  **读取结果**: 当 **done** 信号为高电平时, 在该时钟周期从 `frequency`, `amplitude`, `dc_offset`, 和 `phase_shift` 端口上读取有效的计算结果。

-----

## 模块框图

```mermaid
graph TD
subgraph "参数计算模块 (IC Datasheet 视图)"
    direction LR
    subgraph " "
        Logic(参数计算核心<br/>峰值检测, 零点交叉等)
    end

    subgraph "输入 (Inputs)"
        clk["<b>clk</b><br/>系统时钟"] --> Logic
        reset["<b>reset</b><br/>高电平复位"] --> Logic
        start_analysis["<b>start_analysis</b><br/>启动分析信号"] --> Logic
        bram_data_in["<b>bram_data_in[...]</b><br/>BRAM主通道数据"] --> Logic
        ref_bram_data_in["<b>ref_bram_data_in[...]</b><br/>BRAM参考通道数据"] --> Logic
    end
    
    subgraph "输出 (Outputs)"
        Logic --> bram_read_address["<b>bram_read_address[...]</b><br/>BRAM读取地址"]
        Logic --> frequency["<b>frequency[31:0]</b><br/>频率结果 (Hz)"]
        Logic --> amplitude["<b>amplitude[...]</b><br/>幅度结果"]
        Logic --> dc_offset["<b>dc_offset[...]</b><br/>直流偏置结果"]
        Logic --> phase_shift["<b>phase_shift[...]</b><br/>相位差结果 (度)"]
        Logic --> done["<b>done</b><br/>分析完成标志"]
    end
end
```