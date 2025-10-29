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
        public ComUnitService _comUnitService;

        [ObservableProperty]
        private IList<ICom> _coms = [];

        [ObservableProperty]
        private ICom? _comSelected;

        [RelayCommand]
        private void RefreshComPorts() =>
            Coms = _comUnitService.GetComs();

        public ComViewModel(ComUnitService comUnitService)
        {
            _comUnitService = comUnitService;
            RefreshComPorts(); // Load ports on startup
            PropertyChanged += OnPropertyChanged;
        }

        private void OnPropertyChanged(object? sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == nameof(ComSelected))
            {
                // Close old port if it exists
                if (_comUnitService.CurrentCom is { IsRunning: true })
                {
                    _comUnitService.CurrentCom.Close();
                }

                // Set new port
                _comUnitService.CurrentCom = ComSelected;

                // Open new port if it exists
                if (_comUnitService.CurrentCom is { IsRunning: false })
                {
                    try
                    {
                        _comUnitService.CurrentCom.Open();
                    }
                    catch (System.Exception ex)
                    {
                        // Handle open error (e.g., show a dialog to the user)
                        Debug.WriteLine($"Failed to open port: {ex.Message}");
                        _comUnitService.CurrentCom = null;
                        ComSelected = null; // Reset selection
                    }
                }
            }
        }
    }
}