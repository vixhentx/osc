using System;
using System.ComponentModel;
using CommunityToolkit.Mvvm.ComponentModel;
using Oscum.Service;

namespace Oscum.ViewModels
{
    public partial class MainViewModel : ViewModelBase, IDisposable
    {
        public ComUnitService ComUnitService { get; }
        public RealTimeViewModel RealTimeVM { get; }
        public TestViewModel TestVM { get; }
        public SettingViewModel SettingsVM { get; }
        public ComViewModel ComVM { get; }

        [ObservableProperty]
        private int _selectedTabIndex = 3; // Start on "Connection" tab

        /// <inheritdoc/>
        public MainViewModel(ComUnitService comUnitService,
                             RealTimeViewModel realTimeVm,
                             TestViewModel testVm,
                             SettingViewModel settingsVm,
                             ComViewModel comVm)
        {
            ComUnitService = comUnitService;
            RealTimeVM = realTimeVm;
            TestVM = testVm;
            SettingsVM = settingsVm;
            ComVM = comVm;

            // Listen for a connection to be established
            ComUnitService.PropertyChanged += OnComUnitServicePropertyChanged;
        }

        private void OnComUnitServicePropertyChanged(object? sender, PropertyChangedEventArgs e)
        {
            // Check if the CurrentCom property changed and is now not null
            if (e.PropertyName == nameof(ComUnitService.CurrentCom) && ComUnitService.CurrentCom != null)
            {
                // Switch to the "RealTime" tab (index 0)
                SelectedTabIndex = 0;
            }
        }

        public void Dispose()
        {
            ComUnitService.PropertyChanged -= OnComUnitServicePropertyChanged;
            
            // Dispose of other ViewModels if they implement IDisposable
            if (RealTimeVM is IDisposable rtvm) rtvm.Dispose();
            if (TestVM is IDisposable tvm) tvm.Dispose();
            if (SettingsVM is IDisposable svm) svm.Dispose();
            // ComVM doesn't currently implement IDisposable

            GC.SuppressFinalize(this);
        }
    }
}
