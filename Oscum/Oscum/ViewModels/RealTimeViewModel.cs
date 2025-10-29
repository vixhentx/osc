using System;
using System.Diagnostics;
using CommunityToolkit.Mvvm.ComponentModel;
using Oscum.Service;
using Oscum.Models.Kaitai;
using LiveChartsCore;
using LiveChartsCore.Defaults;
using LiveChartsCore.SkiaSharpView;
using System.Collections.ObjectModel;
using System.Linq;
using Oscum.Utils; // Assuming you have this from your original file

namespace Oscum.ViewModels
{
    public partial class RealTimeViewModel : ViewModelBase, IDisposable
    {
        private readonly DataParsingService _dataParser;

        #region Chart Data
        [ObservableProperty]
        private ObservableCollection<ISeries> _waveSeries;
        #endregion

        #region Real-Time Value Properties
        [ObservableProperty]
        private float _freq;

        [ObservableProperty]
        private float _period;
        
        [ObservableProperty]
        private float _duty;
        
        [ObservableProperty]
        private float _amp;
        #endregion

        #region Axis Properties
        [ObservableProperty]
        private string _xAxisName = "";

        [ObservableProperty]
        private string _yAxisName = "";
        
        //电压单位
        private static readonly string[] voltageUnitTable = ["mV","V"];

        [ObservableProperty]
        private string _voltUnit = "";
	
        //时间单位
        private static readonly string[] timeUnitTable = ["ns","us","ms","s"];
        private static readonly string[] freqUnitTable = ["GHz", "MHz", "KHz", "Hz"];
	
        [ObservableProperty]
        private string _timeUnit = "";

        [ObservableProperty]
        private string _freqUnit = "";
	
        //每一格的时间跨度,单位ns
        [ObservableProperty]
        private double _gridXScale;
        partial void OnGridXScaleChanged(double value)
        {
            Debug.Assert(timeUnitTable.Length == freqUnitTable.Length);
		
            (double showVale, int index) = UnitUtils.AutoAdaptUnit(value, timeUnitTable.Length);
            TimeUnit = timeUnitTable[index];
            FreqUnit = freqUnitTable[index];
            XAxisName = $"时间/{showVale}";
        }

        //每一格的电压跨度,单位mV
        [ObservableProperty]
        protected double _gridYScale;
        partial void OnGridYScaleChanged(double value)
        {
            (double showValue, int index) = UnitUtils.AutoAdaptUnit(value, timeUnitTable.Length);
            VoltUnit = voltageUnitTable[index];
            YAxisName = $"电压/{showValue}";
        }
        #endregion

        public ComUnitService ComUnitService { get; }

        protected RealTimeViewModel(ComUnitService comUnitService, DataParsingService dataParser)
        {
            ComUnitService = comUnitService; // Store injected service
            _dataParser = dataParser;
            _dataParser.OnRealtimeDataReceived += OnRealtimeDataReceived;
            
            // Initialize chart
            _waveSeries =
            [
                new LineSeries<ObservablePoint>
                {
                    Values = new ObservableCollection<ObservablePoint>(),
                    Fill = null,
                    GeometrySize = 0,
                    LineSmoothness = 0,
                    Name = "Waveform"
                }
            ];

            // Set some default axis values from your original code if needed
            GridXScale = 1000; // 1us
            GridYScale = 1000; // 1V
        }

        private void OnRealtimeDataReceived(FpgaProtocol.RealtimeReportData data)
        {
            // This is now running on the UI thread, safe to update properties
            Freq = data.Freq;
            Period = data.Period;
            Duty = data.Duty;
            Amp = data.Amp;

            // Update chart
            if (WaveSeries.FirstOrDefault()?.Values is ObservableCollection<ObservablePoint> points)
            {
                points.Clear();
                for (int i = 0; i < data.Wave.Count; i++)
                {
                    // Assuming X-axis is just the index for now
                    // You might want to use Period/WaveCount to calculate time
                    points.Add(new(i, data.Wave[i]));
                }
            }
        }

        public void Dispose()
        {
            // Unsubscribe from the event to prevent memory leaks
            _dataParser.OnRealtimeDataReceived -= OnRealtimeDataReceived;
            GC.SuppressFinalize(this);
        }
    }
}

