using System;
using System.Collections.Generic;
using CommunityToolkit.Mvvm.ComponentModel;
using Oscum.Models.Kaitai; // Use Kaitai models directly

namespace Oscum.Models
{
    /// <summary>
    /// Represents a single test item in the TestView UI.
    /// </summary>
    public partial class TestItem : ObservableObject
    {
        [ObservableProperty]
        private FpgaProtocol.TestItemEnum _property;

        [ObservableProperty]
        private float _target;

        [ObservableProperty]
        private float _tolerance = 1.0f; // Default 1%

        [ObservableProperty]
        private bool _isPassed;

        /// <summary>
        /// Provides the list of all possible enum values for the ComboBox.
        /// </summary>
        public IEnumerable<FpgaProtocol.TestItemEnum> AllProperties { get; } = Enum.GetValues<FpgaProtocol.TestItemEnum>();
    }
}