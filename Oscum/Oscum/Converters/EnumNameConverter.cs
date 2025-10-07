using System;
using System.Globalization;
using Avalonia.Data.Converters;

namespace Oscum.Converters;

public class EnumNameConverter : IValueConverter
{

    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture) =>
        value is Enum e ? e.ToString() : null;
    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture) =>
        throw new NotImplementedException();
}