using System;
using Kaitai;

namespace Oscum.Design.Mock;

public class SquareCom : DesignCom
{

    public required float Amp { get; set; }
    public required float Duty { get; set; }
    public required float Freq { get; set; }

    private readonly DataStreamMock mock = new();
    protected override void Tick()
    {
        float period = 1 / Freq;
        
        mock[DataStream.RealtimeEnum.Freq] = Freq;
        mock[DataStream.RealtimeEnum.Amp] = Amp;
        mock[DataStream.RealtimeEnum.Duty] = Duty;
        mock[DataStream.RealtimeEnum.Period] = period ;
        
        float clampedDuty = Math.Clamp(Duty/100f, 0.0f, 1.0f);
        float timeInCycle = t % period;
        mock[DataStream.RealtimeEnum.Volt] = (timeInCycle < period * clampedDuty) ? Amp : -Amp;
        OnDataReceived(mock.build());
    }
}