using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Kaitai;
using Oscum.Models;
using Oscum.Service;

namespace Oscum.ViewModels;

public partial class TestViewModel(ComUnitService comUnitService) : ViewModelBase
{
    
    [ObservableProperty]
    [NotifyCanExecuteChangedFor(nameof(RemoveItemCommand))]
    public int selectedIndex = -1;
    
    [ObservableProperty]
    public ObservableCollection<TestItem> items = [];

    [RelayCommand]
    public void AppendItem() => 
        Items.Add(new ());
    
    [RelayCommand(CanExecute = nameof(CanRemoveItem))]
    public void RemoveItem() => 
        Items.RemoveAt(SelectedIndex);
    
    private bool CanRemoveItem() => 
        SelectedIndex >= 0 && SelectedIndex < Items.Count;
    
    public ComUnitService ComUnitService { get; } = comUnitService;
}