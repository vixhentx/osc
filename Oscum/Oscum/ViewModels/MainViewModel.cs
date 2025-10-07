using CommunityToolkit.Mvvm.ComponentModel;

namespace Oscum.ViewModels;

public partial class MainViewModel : ViewModelBase
{
    public RealTimeViewModel RealTimeVM { get; } = new();

    public TestViewModel TestVM { get; } = new();
    
    public SettingViewModel SettingsVM { get; } = new();
}