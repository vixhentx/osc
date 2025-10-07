using System;
using System.Collections.Generic;
using CommunityToolkit.Mvvm.ComponentModel;
using Kaitai;

namespace Oscum.Models;

public partial class TestItem : ObservableObject
{
    [ObservableProperty]
    public DataStream.RealtimeEnum property = 0;

    [ObservableProperty]
    public double target = 0.0;

    //容差,单位为百分比
    [ObservableProperty]
    public double tolerance = 0.01;

    [ObservableProperty]
    public bool isPassed = false;
    
    public static IEnumerable<DataStream.RealtimeEnum> AllProperties { get; } = Enum.GetValues<DataStream.RealtimeEnum>();
}