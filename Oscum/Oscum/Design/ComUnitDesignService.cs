using System.Collections.Generic;
using Oscum.Design.Mock;
using Oscum.Service;

namespace Oscum.Design
{
    public class ComUnitDesignService : ComUnitService
    {
        private static readonly SineCom sine = new() { Name = "Sine (Mock)", Amp = 3.3f, Freq = 100 };
        private static readonly SquareCom square = new() { Name = "Square (Mock)", Freq = 1000, Amp = 3.3f, Duty = 70 };
        private static readonly TriangleCom triangle = new() { Name = "Triangle (Mock)", Freq = 500, Amp = 2.5f };
        private static readonly NoisyCom noisy = new() { Name = "Noisy DC (Mock)", BaseAmp = 1.5f, NoiseLevel = 0.5f };

        
        public ComUnitDesignService()
        {
            // Set the CurrentCom property from the base class
            CurrentCom = sine;
        }
        
        public override List<ICom> GetComs()
        {
            return 
            [
                sine,
                square,
                triangle,
                noisy
            ];
        }
    }
}