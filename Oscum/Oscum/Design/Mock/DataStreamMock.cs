using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using Kaitai;

namespace Oscum.Design.Mock;

public class DataStreamMock
{
    private readonly ConcurrentDictionary<DataStream.RealtimeEnum, float> pending = [];
    public byte[] build()
    {
        List<byte> data = [0b01101011, (byte)pending.Count];
        foreach (var (key, value) in pending)
        {
            data.Add((byte)key);
            data.AddRange(BitConverter.GetBytes(value));
        }
        //没有设置数组
        data.Add(0);
        return data.ToArray();
    }
    public float this[DataStream.RealtimeEnum key]
    {
        get => pending[key];
        set => pending[key] = value;
    }
}