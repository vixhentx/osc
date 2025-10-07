meta:
  id: data_stream
  title: 与FPGA通信的数据流接口
  endian: le
  file-extension: oscds
  ks-version: 0.11
seq:
  - id: start_magic
    doc: 固定帧头
    type: u1
    valid: 0b0110_1011
    
  - id: num_realtime_data
    doc: 实时数据数量
    type: u1
    
  - id: realtime_datas
    doc: 实时数据数组
    type: realtime_data
    repeat: expr
    repeat-expr: num_realtime_data
  
  - id: num_settings
    doc: 设置数量
    type: u1

  - id: settings
    doc: 设置数组
    type: setting
    repeat: expr
    repeat-expr: num_settings

types:
  realtime_data:
    seq:
      - id: id
        doc: 实时数据id
        doc-ref: realtime_enum
        type: u1
        enum: realtime_enum
        
      - id: value
        doc: 属性值
        type: f4
  setting:
    seq:
      - id: id
        doc: 设置id
        doc-ref: setting_enum
        type: u1
        enum: setting_enum

      - id: value
        doc: 设置值
        type: u2

enums:
  realtime_enum:
    1: volt
    2: freq
    3: period
    4: duty
    5: amp
  
  setting_enum:
    1: cycle