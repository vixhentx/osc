using System;
using System.Collections.ObjectModel;
using System.Linq;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Oscum.Models;
using Oscum.Models.Kaitai;
using Oscum.Service;

namespace Oscum.ViewModels
{
    public partial class TestViewModel : ViewModelBase, IDisposable
    {
        private readonly DataParsingService _dataParser;
        public ComUnitService ComUnitService { get; }

        [ObservableProperty]
        [NotifyCanExecuteChangedFor(nameof(RemoveItemCommand))]
        private int _selectedIndex = -1;
        
        [ObservableProperty]
        private ObservableCollection<TestItem> _items = [];

        protected TestViewModel(ComUnitService comUnitService, DataParsingService dataParser)
        {
            ComUnitService = comUnitService;
            _dataParser = dataParser;
            _dataParser.OnTestReportReceived += OnTestReportReceived;
        }

        private void OnTestReportReceived(FpgaProtocol.TestReportData data)
        {
            // This runs on the UI thread
            foreach (var reportItem in data.Items)
            {
                // Find the matching test item(s) in our UI list
                // No cast needed as both are now the same Kaitai enum
                var uiItem = Items.FirstOrDefault(i => i.Property == reportItem.Item);

                if (uiItem != null)
                {
                    uiItem.IsPassed = reportItem.Status;
                }
            }
        }

        [RelayCommand]
        private void AppendItem() => 
            Items.Add(new());
        
        [RelayCommand(CanExecute = nameof(CanRemoveItem))]
        private void RemoveItem() =>
                Items.RemoveAt(SelectedIndex);
        
        private bool CanRemoveItem() => 
            SelectedIndex >= 0 && SelectedIndex < Items.Count;
        
        public void Dispose()
        {
            _dataParser.OnTestReportReceived -= OnTestReportReceived;
            GC.SuppressFinalize(this);
        }
    }
}

