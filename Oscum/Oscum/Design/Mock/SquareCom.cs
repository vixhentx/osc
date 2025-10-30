using System.Collections.Generic;

namespace Oscum.Design.Mock
{
    public class SquareCom : DesignCom
    {
        public required float Amp { get; set; }
        public required float Duty { get; set; }
        public required float Freq { get; set; }
        private const int WavePointCount = 10; // Generate a small wave
        private List<ushort> _wave = new(WavePointCount);

        protected override void Tick()
        {
            float period = 1 / Freq;
            
            // Simulating a 0-3.3V ADC (12-bit = 4096)
            ushort highValue = (ushort)((Amp / 3.3f) * 4095);
            ushort lowValue = 0;
            
            // Generate a simple wave
            _wave.Clear();
            float dutyPoint = WavePointCount * (Duty / 100f);
            for (int i = 0; i < WavePointCount; i++)
            {
                _wave.Add(i < dutyPoint ? highValue : lowValue);
            }

            // Build the frame using the new helper
            byte[] mockData = MockDataHelper.BuildRealtimeFrame(
                _wave, Freq, period, Duty, Amp
            );
            
            OnDataReceived(mockData);
        }
    }
}
