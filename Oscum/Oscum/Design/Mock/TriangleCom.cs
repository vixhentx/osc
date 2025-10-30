using System.Collections.Generic;

namespace Oscum.Design.Mock
{
    public class TriangleCom : DesignCom
    {
        public required float Amp { get; init; }
        public required float Freq { get; init; }
        private const int WavePointCount = 20;
        private readonly List<ushort> _wave = new(WavePointCount);

        protected override void Tick()
        {
            float period = 1 / Freq;
            
            // Simulating a 0-3.3V ADC (12-bit = 4095)
            float maxAdc = (Amp / 3.3f) * 4095;
            
            _wave.Clear();
            for (int i = 0; i < WavePointCount; i++)
            {
                float t_wave = (float)i / WavePointCount; // 0 to 1
                float val;
                if (t_wave < 0.5f)
                {
                    // Ramp up
                    val = t_wave * 2;
                }
                else
                {
                    // Ramp down
                    val = 1.0f - ((t_wave - 0.5f) * 2);
                }
                _wave.Add((ushort)(val * maxAdc));
            }

            // Build the frame using the new helper
            byte[] mockData = MockDataHelper.BuildRealtimeFrame(
                _wave, Freq, period, 50.0f, Amp // 50% duty
            );
            
            OnDataReceived(mockData);
        }
    }
}