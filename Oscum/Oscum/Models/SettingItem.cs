using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Oscum.Models.Kaitai; // Use Kaitai models directly

namespace Oscum.Models
{
    /// <summary>
    /// Represents a single setting in the SettingView UI.
    /// </summary>
    public partial class SettingItem : ObservableObject
    {
        public FpgaProtocol.SettingItemEnum Id { get; }
        public string DisplayName { get; }

        [ObservableProperty]
        private ushort _nowValue;

        [ObservableProperty]
        private ushort _newValue;
        
        // This command would be wired up to send data back to the device
        // It needs a way to access the ICom port (e.g., via a service)
        [RelayCommand]
        private void Apply()
        {
            NowValue = NewValue;
        }

        public SettingItem(FpgaProtocol.SettingItemEnum id, string displayName)
        {
            Id = id;
            DisplayName = displayName;
        }
    }
}