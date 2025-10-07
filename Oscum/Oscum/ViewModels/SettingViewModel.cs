using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using Kaitai;
using Oscum.Models;

namespace Oscum.ViewModels;

public partial class SettingViewModel : ViewModelBase
{
    [ObservableProperty]
    public ObservableCollection<SettingItem> items;

    public SettingViewModel()
    {
        List<SettingItem> list = [];
        foreach (var e in Enum.GetValues<DataStream.SettingEnum>())
        {
            
            list.Add(new()
            {
                Id = e
            });
        }
        Items = new(list);
    }
}