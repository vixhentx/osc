using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using Kaitai;
using Oscum.Models;
using Oscum.Service;

namespace Oscum.ViewModels;

public partial class SettingViewModel : ViewModelBase
{
    [ObservableProperty]
    public ObservableCollection<SettingItem> items;

    public SettingViewModel(ComUnitService comUnitService)
    {
        ComUnitService = comUnitService;
        List<SettingItem> list = [];
        foreach (var e in Enum.GetValues<DataStream.SettingEnum>())
        {
            SettingItem item = new()
            {
                Id = e
            };
            item.PropertyChanged += (sender, e) =>
            {
                if(ComUnitService.ComUnit == null) return;
                if (e.PropertyName == nameof(item.NowValue))
                {
                    ComUnitService.ComUnit.Data[item.Id] = item.NowValue;
                }
            };
            list.Add(item);
        }
        Items = new(list);
    }

    public ComUnitService ComUnitService { get; }
}