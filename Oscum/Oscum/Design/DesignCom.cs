using System;
using Oscum.Service;

namespace Oscum.Design;

public class DesignCom : ICom
{

    public void Dispose() =>
        Console.WriteLine($"Disposing {Name}");

    public string Type => "DesignCom";

    public required string Name { get; init; }

    public bool IsOpen { get; private set; }

    public void Open()
    {
        IsOpen = true;
        Console.WriteLine($"Opening {Name}");
    }
    public void Close()
    {
        IsOpen = false;
        Console.WriteLine($"Closing {Name}");
    }

    public event EventHandler<byte[]>? DataReceived;

    public void Send(byte[] data)
    {
        if (!IsOpen) Console.Error.WriteLine($"Cannot send data, {Name} is not open");
        // Console.WriteLine($"Sending data to {Name}: {BitConverter.ToString(data)}");
    }
}