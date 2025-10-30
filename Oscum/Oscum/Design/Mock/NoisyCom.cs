using System;
using System.Collections.Generic;

namespace Oscum.Design.Mock
{
    public class NoisyCom : DesignCom
    {
        public required float BaseAmp { get; init; }
        public required float NoiseLevel { get; init; }
        private const int WavePointCount = 20; // Generate a small wave
        private readonly List<ushort> _wave = new(WavePointCount);
        private readonly Random _random = new();

        protected override void Tick()
        {
            // Simulating a noisy DC signal
            float freq = 0;
            float period = 0;
            float duty = 0;
            
            // Simulating a 0-3.3V ADC (12-bit = 4095)
            float baseAdc = (BaseAmp / 3.3f) * 4095;
            float noiseAdc = (NoiseLevel / 3.3f) * 4095;

            _wave.Clear();
            for (int i = 0; i < WavePointCount; i++)
            {
                float noise = (float)(_random.NextDouble() * 2 - 1) * noiseAdc;
                float val = Math.Clamp(baseAdc + noise, 0, 4095);
                _wave.Add((ushort)val);
            }

            // Build the frame using the new helper
            byte[] mockData = MockDataHelper.BuildRealtimeFrame(
                _wave, freq, period, duty, BaseAmp
            );
            
            OnDataReceived(mockData);
        }
    }
}