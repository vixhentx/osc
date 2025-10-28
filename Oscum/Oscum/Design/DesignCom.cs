using System;
using System.Timers;
using Oscum.Service;

namespace Oscum.Design;

public class DesignCom : ICom
{

    #region 模拟数据生成&定时器
    
    private readonly Timer timer = new(100);
    protected long t = 0;
    protected virtual void Tick(){}
    public DesignCom()
    {
        timer.Elapsed += (sender, e) =>
        {
            t++;
            Tick();
        };
    }

    #endregion
    
    public void Dispose() 
    {
        timer.Dispose();
        Console.WriteLine($"Disposing {Name}");
    }

    public string Type => "DesignCom";

    public required string Name { get; init; }

    public bool IsOpen { get; private set; }
    
    public virtual void Open()
    {
        IsOpen = true;
        timer.Start();
        Console.WriteLine($"Opening {Name}");
    }
    public virtual void Close()
    {
        IsOpen = false;
        timer.Stop();
        Console.WriteLine($"Closing {Name}");
    }

    public event EventHandler<byte[]>? DataReceived;
    protected void OnDataReceived(byte[] data) => DataReceived?.Invoke(this, data);

    public void Send(byte[] data)
    {
        if (!IsOpen) Console.Error.WriteLine($"Cannot send data, {Name} is not open");
        // Console.WriteLine($"Sending data to {Name}: {BitConverter.ToString(data)}");
    }
}