using Oscum.Models;
using Oscum.Models.Kaitai;
using Oscum.Service;
using System;
using System.Collections.ObjectModel;
using System.Linq;

namespace Oscum.ViewModels
{
    public partial class SettingViewModel : ViewModelBase, IDisposable
    {
        private readonly DataParsingService _dataParser;
        public ComUnitService ComUnitService { get; }

        public ObservableCollection<SettingItem> Items { get; } = [];

        public SettingViewModel(ComUnitService comUnitService, DataParsingService dataParser)
        {
            ComUnitService = comUnitService;
            _dataParser = dataParser;
            
            // Initialize settings using the Kaitai enum
            Items.Add(new(FpgaProtocol.SettingItemEnum.Baud, "波特率"));
            Items.Add(new(FpgaProtocol.SettingItemEnum.FrameRate, "帧率"));
            
            _dataParser.OnSettingsDataReceived += OnSettingsDataReceived;
        }

        private void OnSettingsDataReceived(FpgaProtocol.SettingsData data)
        {
            // This runs on the UI thread
            // No cast needed
            var uiItem = Items.FirstOrDefault(i => i.Id == data.Item);
            if (uiItem != null)
            {
                uiItem.NowValue = data.Value;
                if (uiItem.NewValue == 0) // Init NewValue on first receive
                {
                    uiItem.NewValue = data.Value;
                }
            }
        }

        public void Dispose()
        {
            _dataParser.OnSettingsDataReceived -= OnSettingsDataReceived;
            GC.SuppressFinalize(this);
        }
    }
}