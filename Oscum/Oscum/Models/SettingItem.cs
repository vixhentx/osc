using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Oscum.Models.Kaitai; // Use Kaitai models directly

namespace Oscum.Models
{
    /// <summary>
    /// Represents a single setting in the SettingView UI.
    /// </summary>
    public partial class SettingItem(FpgaProtocol.SettingItemEnum id, string displayName) : ObservableObject
    {
        public FpgaProtocol.SettingItemEnum Id { get; } = id;

        public string DisplayName { get; } = displayName;

        [ObservableProperty]
        private ushort _nowValue;

        [ObservableProperty]
        private ushort _newValue;
        
        public bool IsDirty => NowValue != NewValue;
    }
}