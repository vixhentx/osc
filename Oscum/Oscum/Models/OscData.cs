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

    private readonly Dictionary<RealTimeEnum, double> realTimeDatas = [];
    private readonly Dictionary<SettingEnum, ushort> settings = [];
    public double this[RealTimeEnum realtimeData] 
    {
        get => realTimeDatas[realtimeData];
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
        foreach (DataStream.RealtimeData realtimeData in data.RealtimeDatas)
        {
            this[realtimeData.Id] = realtimeData.Value;
        }
        foreach (DataStream.Setting setting in data.Settings)
        {
            this[setting.Id] = setting.Value;
        }
        ShouldNotifyOutputBuffer = true;
    }
    public static OscData operator <<(OscData target, byte[] rawDataStream)
    {
        target.Parse(rawDataStream);
        return target;
    }

    #endregion

}