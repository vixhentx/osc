using System;
using System.ComponentModel;
using CommunityToolkit.Mvvm.ComponentModel;
using Oscum.Service;

namespace Oscum.ViewModels;

public partial class MainViewModel : ViewModelBase,IDisposable
{
    public ComUnitService ComUnitService { get; }

    public RealTimeViewModel RealTimeVM { get; }

    public TestViewModel TestVM { get; }

    public SettingViewModel SettingsVM { get; }

    public ComViewModel ComVM { get; }

    [ObservableProperty]
    private int selectedTabIndex = 3;

    /// <inheritdoc/>
    public MainViewModel(ComUnitService    comUnitService,
                         RealTimeViewModel realTimeVm,
                         TestViewModel     testVm,
                         SettingViewModel  settingsVm,
                         ComViewModel      comVm)
    {
        ComUnitService = comUnitService;
        RealTimeVM = realTimeVm;
        TestVM = testVm;
        SettingsVM = settingsVm;
        ComVM = comVm;
        ComUnitService.PropertyChanged += OnComUnitServicePropertyChanged;
    }

    private void OnComUnitServicePropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(ComUnitService.ComUnit) && ComUnitService.ComUnit != null)
        {
            SelectedTabIndex = 0;
        }
    }
    public void Dispose()
    {
        ComUnitService.PropertyChanged -= OnComUnitServicePropertyChanged;
    }
}