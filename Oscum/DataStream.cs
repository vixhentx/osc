// This is a generated file! Please edit source .ksy file and use kaitai-struct-compiler to rebuild

using System.Collections.Generic;

namespace Kaitai
{
    public partial class DataStream : KaitaiStruct
    {
        public static DataStream FromFile(string fileName)
        {
            return new DataStream(new KaitaiStream(fileName));
        }


        public enum PropertyEnum
        {
            Volt = 1,
            Freq = 2,
            Peroid = 3,
            Duty = 4,
            Amp = 5,
        }
        public DataStream(KaitaiStream p__io, KaitaiStruct p__parent = null, DataStream p__root = null) : base(p__io)
        {
            m_parent = p__parent;
            m_root = p__root ?? this;
            _read();
        }
        private void _read()
        {
            _startMagic = m_io.ReadU1();
            if (!(_startMagic == 107))
            {
                throw new ValidationNotEqualError(107, _startMagic, m_io, "/seq/0");
            }
            _numProperties = m_io.ReadU1();
            _properties = new List<Property>();
            for (var i = 0; i < NumProperties; i++)
            {
                _properties.Add(new Property(m_io, this, m_root));
            }
        }
        public partial class Property : KaitaiStruct
        {
            public static Property FromFile(string fileName)
            {
                return new Property(new KaitaiStream(fileName));
            }

            public Property(KaitaiStream p__io, DataStream p__parent = null, DataStream p__root = null) : base(p__io)
            {
                m_parent = p__parent;
                m_root = p__root;
                _read();
            }
            private void _read()
            {
                _id = ((DataStream.PropertyEnum) m_io.ReadU1());
                switch (Id) {
                case DataStream.PropertyEnum.Amp: {
                    _value = m_io.ReadF4le();
                    break;
                }
                case DataStream.PropertyEnum.Duty: {
                    _value = m_io.ReadF4le();
                    break;
                }
                case DataStream.PropertyEnum.Freq: {
                    _value = m_io.ReadF4le();
                    break;
                }
                case DataStream.PropertyEnum.Peroid: {
                    _value = m_io.ReadF4le();
                    break;
                }
                case DataStream.PropertyEnum.Volt: {
                    _value = m_io.ReadS2le();
                    break;
                }
                }
            }
            private PropertyEnum _id;
            private double _value;
            private DataStream m_root;
            private DataStream m_parent;

            /// <summary>
            /// 属性id
            /// </summary>
            /// <remarks>
            /// Reference: property_enum
            /// </remarks>
            public PropertyEnum Id { get { return _id; } }

            /// <summary>
            /// 属性值
            /// </summary>
            public double Value { get { return _value; } }
            public DataStream M_Root { get { return m_root; } }
            public DataStream M_Parent { get { return m_parent; } }
        }
        private byte _startMagic;
        private byte _numProperties;
        private List<Property> _properties;
        private DataStream m_root;
        private KaitaiStruct m_parent;

        /// <summary>
        /// 固定帧头
        /// </summary>
        public byte StartMagic { get { return _startMagic; } }

        /// <summary>
        /// 属性数量
        /// </summary>
        public byte NumProperties { get { return _numProperties; } }

        /// <summary>
        /// 属性数组
        /// </summary>
        public List<Property> Properties { get { return _properties; } }
        public DataStream M_Root { get { return m_root; } }
        public KaitaiStruct M_Parent { get { return m_parent; } }
    }
}
