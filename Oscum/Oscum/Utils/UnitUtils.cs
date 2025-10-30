using System;

namespace Oscum.Utils;

public static class UnitUtils
{
    //自动适应单位
    public static (double value, int index) AutoAdaptUnit(double value,int tableLength,int unitSpan = 3,int offset = 0)
    {
        double baseIndex = Math.Log10(value);
        int index = (int) (baseIndex / unitSpan) + offset;
        if (index < 0 || index >= tableLength)
            throw new ArgumentOutOfRangeException();

        return (
            value: value / Math.Pow(10, baseIndex),
            index
        );
    }
}