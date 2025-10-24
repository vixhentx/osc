using System.ComponentModel;
using CommunityToolkit.Mvvm.ComponentModel;
using Kaitai;
using Oscum.Service;

namespace Oscum.Models;

/*
 * 简要封装了一下通信口和数据解析功能
 * 能够自动接受com口数据并解析,产生UI更新事件
 * 发送数据也只需要简单调用一下Send()方法即可
 */
public partial class ComUnit : ObservableObject
{
    private ICom Com { get; }

    [ObservableProperty]
    private OscData data;

    public ComUnit(ICom com)
    {
        Com = com;
        data = new();
        Com.DataReceived += (sender,bytes) => data.Parse(bytes);
        Data.PropertyChanged += OnDataPropertyChanged;
        com.Open();
    }
    private void OnDataPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        OnPropertyChanged($"Item[{e.PropertyName}]");
    }
    public  void Send() => Com.Send(Data.ToBytes());
    public double this[DataStream.RealtimeEnum realtimeEntry] => Data[realtimeEntry];
    
}