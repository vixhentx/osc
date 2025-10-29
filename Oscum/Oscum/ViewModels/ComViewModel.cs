using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Oscum.Service;

namespace Oscum.ViewModels
{
    public partial class ComViewModel : ViewModelBase
    {
        public ComUnitService ComUnitService { get; }

        [ObservableProperty]
        private IList<ICom> _coms = [];

        [ObservableProperty]
        private ICom? _comSelected;

        [RelayCommand]
        private void RefreshComPorts() =>
            Coms = ComUnitService.GetComs();

        public ComViewModel(ComUnitService comUnitService)
        {
            ComUnitService = comUnitService;
            RefreshComPorts(); // Load ports on startup
            PropertyChanged += OnPropertyChanged;
        }

        private void OnPropertyChanged(object? sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == nameof(ComSelected))
            {
                // Close old port if it exists
                if (ComUnitService.CurrentCom is { IsOpen: true })
                {
                    ComUnitService.CurrentCom.Close();
                }

                // Set new port
                ComUnitService.CurrentCom = ComSelected;

                // Open new port if it exists
                if (ComUnitService.CurrentCom is { IsOpen: false })
                {
                    try
                    {
                        ComUnitService.CurrentCom.Open();
                    }
                    catch (System.Exception ex)
                    {
                        // Handle open error (e.g., show a dialog to the user)
                        Debug.WriteLine($"Failed to open port: {ex.Message}");
                        ComUnitService.CurrentCom = null;
                        ComSelected = null; // Reset selection
                    }
                }
            }
        }
    }
}