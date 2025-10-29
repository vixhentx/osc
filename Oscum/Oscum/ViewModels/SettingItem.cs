using System;
using CommunityToolkit.Mvvm.ComponentModel;

namespace Oscum.ViewModels;

public partial class SettingItem<T>(string displayName, Action<T> setter) : ObservableObject
{
    [ObservableProperty]
    private T? value;

    public string DisplayName { get; } = displayName;

    partial void OnValueChanged(T? newValue)
    {
        if (newValue != null)
            setter(newValue);
    }
}