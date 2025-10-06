using System;
using System.Collections.Generic;
using Avalonia.Data;
using CommunityToolkit.Mvvm.ComponentModel;
using Kaitai;
using PropertyEnum = Kaitai.DataStream.PropertyEnum;

namespace Oscum.Models;

public class OscData : ObservableObject
{

    #region 属性管理

    private readonly Dictionary<PropertyEnum, double> properties = [];
    public double GetProperty(PropertyEnum property) => properties[property];
    public void SetProperty(PropertyEnum property, double value)
    {
        var oldValue = GetProperty(property);
        if (Math.Abs(oldValue - value) < 0.001) return;
        
        OnPropertyChanging(property.ToString());
        properties[property] = value;
        OnPropertyChanged(property.ToString());
    }
    public double this[PropertyEnum property] 
    {
        get => GetProperty(property);
        set => SetProperty(property, value);
    }
    public double this[string property]
    {
        get => GetProperty(Enum.Parse<PropertyEnum>(property));
        set => SetProperty(Enum.Parse<PropertyEnum>(property), value);
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
        foreach (DataStream.Property property in data.Properties)
        {
            this[property.Id] = property.Value;
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