using System;
using System.Globalization;
using Avalonia.Data.Converters;
using Avalonia.Media;

namespace Oscum.Converters;

public class TureToGreenConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture) =>
        value is true ? Colors.Green : Colors.Red;
    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture) =>
        throw new NotImplementedException();
}