using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Kaitai;

namespace Oscum.Models;

public partial class SettingItem : ObservableObject
{
    [ObservableProperty]
    public DataStream.SettingEnum id;
    
    [ObservableProperty]
    public ushort nowValue;

    [ObservableProperty]
    public ushort newValue;

    [RelayCommand]
    public void Apply() => NowValue = NewValue;
}