using System.Collections.Generic;
using System.IO;
using Oscum.Models.Kaitai;

namespace Oscum.Design.Mock
{
    public static class MockDataHelper
    {
        /// <summary>
        /// Creates a byte array for a RealtimeReportData frame,
        /// matching the fpga_protocol.ksy specification.
        /// </summary>
        public static byte[] BuildRealtimeFrame(
            List<ushort> wave, float freq, float period, float duty, float amp)
        {
            // Use a MemoryStream and BinaryWriter for easy, little-endian writing.
            using var ms = new MemoryStream();
            using var writer = new BinaryWriter(ms);

            // 1. FrameHeader
            writer.Write((byte)FpgaProtocol.FrameType.RealtimeReport);

            // 2. WaveCount (u2le)
            writer.Write((ushort)wave.Count);

            // 3. Wave (array of u2le)
            foreach (var point in wave)
            {
                writer.Write(point);
            }

            // 4. Freq (f4le)
            writer.Write(freq);

            // 5. Period (f4le)
            writer.Write(period);

            // 6. Duty (f4le)
            writer.Write(duty);

            // 7. Amp (f4le)
            writer.Write(amp);

            return ms.ToArray();

        }
    }
}