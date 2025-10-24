using Oscum.Service;

namespace Oscum.ViewModels;

public class MainViewModel(
    ComUnitService    comUnitService,
    RealTimeViewModel realTimeVm,
    TestViewModel     testVm,
    SettingViewModel  settingsVm,
    ComViewModel      comVm
)
    : ViewModelBase
{
    public ComUnitService ComUnitService { get; } = comUnitService;

    public RealTimeViewModel RealTimeVM { get; } = realTimeVm;

    public TestViewModel TestVM { get; } = testVm;

    public SettingViewModel SettingsVM { get; } = settingsVm;

    public ComViewModel ComVM { get; } = comVm;


}