using System;
using System.Collections.Generic;
using CommunityToolkit.Mvvm.ComponentModel;
using Kaitai;

using RealTimeEnum = Kaitai.DataStream.RealtimeEnum;
using SettingEnum = Kaitai.DataStream.SettingEnum;

namespace Oscum.Models;

public class OscData : ObservableObject
{

    #region 属性管理

    private byte magic;
    private readonly Dictionary<RealTimeEnum, double> realTimeDatas = [];
    private readonly Dictionary<SettingEnum, ushort> settings = [];
    private Dictionary<SettingEnum, ushort> outputBuffer = [];
    public double this[RealTimeEnum realtimeData] 
    {
        get => realTimeDatas.GetValueOrDefault(realtimeData, 0);
        set
        {
            double oldValue = this[realtimeData];
            if (Math.Abs(oldValue - value) < 0.001) return;

            OnPropertyChanging(realtimeData.ToString());
            realTimeDatas[realtimeData] = value;
            OnPropertyChanged(realtimeData.ToString());
        }
    }
    public ushort this[SettingEnum setting]
    {
        get => settings[setting];
        set
        {
            ushort oldValue = this[setting];
            if (oldValue == value) return;

            OnPropertyChanging(setting.ToString());
            settings[setting] = value;
            OnPropertyChanged(setting.ToString());
            if (ShouldNotifyOutputBuffer)
                outputBuffer[setting] = value;
        }
    }

    #endregion

    #region 数据流处理

    //属性变更时是否通知输出缓冲
    public bool ShouldNotifyOutputBuffer { get; set; }

    public void Parse(byte[] rawDataStream)
    {
        ShouldNotifyOutputBuffer = false;
        using KaitaiStream ks = new(rawDataStream);
        DataStream data = new(ks);
        magic = data.StartMagic;
        foreach (var realtimeData in data.RealtimeDatas)
        {
            this[realtimeData.Id] = realtimeData.Value;
        }
        foreach (var setting in data.Settings)
        {
            this[setting.Id] = setting.Value;
        }
        ShouldNotifyOutputBuffer = true;
    }

    public byte[] ToBytes()
    {
        List<byte> bytes = [magic,0, (byte)outputBuffer.Count];   //固定帧头,没有实时数据,设置数据
        foreach (var (e, v) in outputBuffer)
        {
            bytes.Add((byte)e);
            bytes.AddRange(BitConverter.GetBytes(v));
        }
        outputBuffer = [];
        return bytes.ToArray();
    }

    #endregion

}