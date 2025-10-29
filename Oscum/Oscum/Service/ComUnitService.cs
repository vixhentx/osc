using System;
using System.Collections.Generic;
using CommunityToolkit.Mvvm.ComponentModel;
using System.IO.Ports;    // Example for GetComs
using System.Linq;        // Example for GetComs
using System.Diagnostics; // Example for GetComs

namespace Oscum.Service
{
    /// <summary>
    /// Singleton service to hold the currently active ICom port.
    /// Other services (like DataParsingService) listen to changes on this service.
    /// </summary>
    public partial class ComUnitService : ObservableObject
    {
        [ObservableProperty]
        private ICom? _currentCom;

        /// <summary>
        /// Scans the system for available serial ports.
        /// </summary>
        public virtual List<ICom> GetComs()
        {
            try
            {
                string[] portNames = SerialPort.GetPortNames();
                
                // You can add more logic here to check if ports are busy
                // or add other communication types (e.g., TCP)
                
                return portNames
                    .Select(ICom (name) => new SerialCom { Name = name, BaudRate = 115200 }) // Default BaudRate
                    .ToList();
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[ComUnitService] Error scanning for ports: {ex.Message}");
                return [];
            }
        }
    }
}