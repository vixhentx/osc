
using System;
using Kaitai;

namespace Oscum.Design.Mock;

public class SineCom : DesignCom
{
    public required float Amp { get; set; }
    public required float Freq { get; set; }

    private readonly DataStreamMock mock = new();
    protected override void Tick()
    {
        mock[DataStream.RealtimeEnum.Freq] = Freq;
        mock[DataStream.RealtimeEnum.Amp] = Amp;
        mock[DataStream.RealtimeEnum.Duty] = 0.5f;
        mock[DataStream.RealtimeEnum.Period] = 1.0f / Freq;
        mock[DataStream.RealtimeEnum.Volt] = Amp * MathF.Sin(2 * MathF.PI * Freq * t);
        OnDataReceived(mock.build());
    }
}