using System.Collections.Generic;
using Oscum.Design.Mock;
using Oscum.Service;

namespace Oscum.Design;

public class ComUnitDesignService : ComUnitService
{
    private static SineCom sine = new() { Name = "Sine",Amp = 3.3f, Freq = 100};
    private static SquareCom square = new() { Name = "Square",Freq = 100, Amp = 3.3f, Duty = 70};
    public ComUnitDesignService()
    {
        ComUnit = new(sine);
    }
    public override List<ICom> GetComs()
    {
        return 
        [
            sine,
            square
        ];
    }
}