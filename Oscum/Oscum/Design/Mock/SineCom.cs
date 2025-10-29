using System;
using System.Collections.Generic;

namespace Oscum.Design.Mock
{
    public class SineCom : DesignCom
    {
        public required float Amp { get; set; }
        public required float Freq { get; set; }
        private const int WavePointCount = 10; // Generate a small wave
        private List<ushort> _wave = new(WavePointCount);

        protected override void Tick()
        {
            float period = 1.0f / Freq;
            float duty = 0.5f; // Sine wave has 50% duty

            // Generate a simple wave
            _wave.Clear();
            for (int i = 0; i < WavePointCount; i++)
            {
                float phase = (2 * MathF.PI * i) / WavePointCount;
                // Simulating a 0-3.3V ADC (12-bit = 4096)
                float voltage = (Amp / 2) * MathF.Sin(phase + (t * 0.1f)) + (Amp / 2);
                ushort adcValue = (ushort)((voltage / 3.3f) * 4095);
                _wave.Add(adcValue);
            }

            // Build the frame using the new helper
            byte[] mockData = MockDataHelper.BuildRealtimeFrame(
                _wave, Freq, period, duty, Amp
            );
            
            OnDataReceived(mockData);
        }
    }
}
