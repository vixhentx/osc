using System.Collections.Generic;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Oscum.Service;

namespace Oscum.ViewModels;

public partial class ComViewModel : ViewModelBase
{
    public ComUnitService ComUnitService { get; }
    
    [ObservableProperty]
    public IList<ICom> coms = [];

    [ObservableProperty]
    private ICom? comSelected;

    [RelayCommand]
    public void RefreshComPorts() =>
        Coms = ComUnitService.GetComs();
    
    public ComViewModel(ComUnitService comUnitServiceService)
    {
        ComUnitService = comUnitServiceService;
        PropertyChanged += (sender, e) =>
        {
            if (e.PropertyName == nameof(ComSelected))
                ComUnitService.ComUnit = ComSelected == null? null : new(ComSelected);
        };
    }
}