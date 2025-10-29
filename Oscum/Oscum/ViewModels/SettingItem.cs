using System;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Kaitai;

namespace Oscum.Models;

public partial class SettingItem<T>(string displayName, Action<T> setter) : ObservableObject
{
    [ObservableProperty]
    private T? nowValue;

    [ObservableProperty]
    private T? newValue;

    public string DisplayName { get; } = displayName;

    [RelayCommand]
    private void Apply()
    {
        if (NewValue != null)
            setter(NewValue);
    }
}