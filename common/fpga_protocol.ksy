meta:
  id: fpga_protocol
  title: FPGA/Host Communication Protocol
  file-extension: bin
  endian: le

enums:
  frame_type:
    0x6B: realtime_report
    0xCA: test_report
    0xCB: test_set
    0xF4: settings

  test_item_enum:
    1: freq
    2: period
    3: duty
    4: amp

  setting_item_enum:
    1: baud
    2: frame_rate

# 顶级解析器
seq:
  - id: frame_header
    type: u1
    enum: frame_type
    doc: "帧头 (Frame Header)"
  - id: body
    type:
      switch-on: frame_header
      cases:
        'frame_type::realtime_report': realtime_report_data
        'frame_type::test_report': test_report_data
        'frame_type::test_set': test_set_data
        'frame_type::settings': settings_data
    doc: "数据体, 其结构取决于帧头"

types:
  # -----------------------------------------------
  # 1. 实时上报数据 (帧头: 0x6B)
  # -----------------------------------------------
  realtime_report_data:
    doc: "实时上报数据 (Real-time Report Data)"
    seq:
      - id: num_wave
        type: u2le
        doc: "波形数据点的数量"
      - id: wave
        type: u2le
        repeat: expr
        repeat-expr: num_wave
        doc: "波形各处的电压 (16位整数)."
      - id: freq
        type: f4le
        doc: "频率 (Frequency), 32-bit float"
      - id: period
        type: f4le
        doc: "周期 (Period), 32-bit float"
      - id: duty
        type: f4le
        doc: "占空比 (Duty Cycle), 32-bit float"
      - id: amp
        type: f4le
        doc: "幅值 (Amplitude), 32-bit float"

  # -----------------------------------------------
  # 2a. 测试相关数据 - 上报时 (帧头: 0xCA)
  # -----------------------------------------------
  test_report_data:
    doc: "测试相关数据 - 上报时 (Test Data - Report)"
    seq:
      - id: items
        type: test_report_item
        repeat: eos
        doc: "测试项目列表"

  test_report_item:
    doc: "单个测试项目 (上报), 共 1 字节. 假设位字段按 MSB (高位) -> LSB (低位) 顺序打包: [IIIIIII S] (I=项目, S=状态)"
    meta:
      endian: be
    seq:
      - id: item
        type: b7
        enum: test_item_enum
        doc: "项目 (Item), 7-bit enum"
      - id: status
        type: b1
        doc: "状态 (Status), 1-bit boolean (1 = 通过)"

  # -----------------------------------------------
  # 2b. 测试相关数据 - 下发时 (帧头: 0xCB)
  # -----------------------------------------------
  test_set_data:
    doc: "测试相关数据 - 下发时 (Test Data - Set)"
    seq:
      - id: items
        type: test_set_item
        repeat: eos
        doc: "要设置的测试项目列表"

  test_set_item:
    doc: "单个测试项目 (下发), 共 6 字节 (1 + 1 + 4)"
    seq:
      - id: item
        type: u1
        enum: test_item_enum
        doc: "项目 (Item), 8-bit enum"
      - id: tolerance
        type: u1
        doc: "容差 (Tolerance), 8-bit unsigned, 百分比"
      - id: target_value
        type: f4le
        doc: "目标值 (Target Value), 32-bit float, 类型与上报数据相同"

  # -----------------------------------------------
  # 3. 设定相关数据 (帧头: 0xF4)
  # -----------------------------------------------
  settings_data:
    doc: "设定相关数据 (Settings Data), 共 3 字节 (1 + 2)"
    seq:
      - id: item
        type: u1
        enum: setting_item_enum
        doc: "项目 (Item), 8-bit enum"
      - id: value
        type: u2le
        doc: "值 (Value), 16-bit integer"

