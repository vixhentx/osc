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
    
  - id: num_properties
    doc: 属性数量
    type: u1
    
  - id: properties
    doc: 属性数组
    type: property
    repeat: expr
    repeat-expr: num_properties
  
types:
  property:
    seq:
      - id: id
        doc: 属性id
        doc-ref: property_enum
        type: u1
        enum: property_enum
        
      - id: value
        doc: 属性值
        type:
          switch-on: id
          cases:
            'property_enum::adc': s2
            'property_enum::freq': f4
            'property_enum::peroid': f4
            'property_enum::duty': f4
            'property_enum::amp': f4
enums:
  property_enum:
    1: adc
    2: freq
    3: peroid
    4: duty
    5: amp